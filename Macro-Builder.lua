local _, ns = ...
local L = ns.L
local GetColor = ns.GetColor
local Config = ns.Config

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------

-- WoW caps macro bodies at 255 characters. We use this when truncating
-- the additive scroll block so we never write a body that would be
-- silently rejected by the client.
local MACRO_MAX_LENGTH = 255

--------------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------------

local currentMacroState = {}
local currentPetFoodState = nil

local conjuredGemItemIDBySpell = {
    [27101] = 22044,
    [10054] = 8008,
    [10053] = 8007,
    [3552]  = 5513,
    [759]   = 5514,
}

--------------------------------------------------------------------------------
-- Target Helpers
--
-- Single source of truth for "is the current target a friendly player." Used
-- by both GetSmartSpell (for conjure rank downranking) and the scroll block
-- builder (which drops scrolls so a Mage can right-click to conjure food
-- for a friend without firing scrolls on themselves).
--------------------------------------------------------------------------------

local function HasFriendlyPlayerTarget()
    return UnitExists("target")
        and UnitIsFriend("player", "target")
        and UnitIsPlayer("target")
end

--------------------------------------------------------------------------------
-- Smart Spell Resolution
--
-- Picks the highest-rank spell the player knows that the target (or player)
-- can still receive. Targeting a friendly player of lower level drops the
-- rank down so the conjured item matches their level cap.
--------------------------------------------------------------------------------

local function GetSmartSpell(spellList, ignoreTarget, checkUnique)
    if not spellList then
        return nil, 0
    end

    local levelCap = UnitLevel("player")

    if not ignoreTarget and HasFriendlyPlayerTarget() then
        local targetLevel = UnitLevel("target")
        if targetLevel > 0 then
            levelCap = targetLevel
        end
    end

    for _, data in ipairs(spellList) do
        local spellID, requiredLevel, rankNumber = data[1], data[2], data[3]

        local known = IsSpellKnown(spellID)
        if not known and IsPlayerSpell then
            known = IsPlayerSpell(spellID)
        end

        if known and requiredLevel <= levelCap then
            local shouldSkip = false

            if checkUnique and conjuredGemItemIDBySpell[spellID] then
                if C_Item.GetItemCount(conjuredGemItemIDBySpell[spellID]) > 0 then
                    shouldSkip = true
                end
            end

            if not shouldSkip then
                local spellName = GetSpellInfo(spellID)
                if spellName then
                    if rankNumber then
                        return spellName .. "(" .. L["RANK"] .. " " .. rankNumber .. ")", spellID
                    end
                    return spellName, spellID
                end
            end
        end
    end

    -- Fallback only when the player knows at least one spell in the list
    -- but none matched the level cap (targeting a low-level friend).
    if not ns.KnowsAny(spellList) then
        return nil, 0
    end

    local lowestRank = spellList[#spellList]
    local fallbackName = GetSpellInfo(lowestRank[1])
    if lowestRank[3] then
        return fallbackName .. "(" .. L["RANK"] .. " " .. lowestRank[3] .. ")", lowestRank[1]
    end
    return fallbackName, lowestRank[1]
end

--------------------------------------------------------------------------------
-- Shadowmeld Suffix
--------------------------------------------------------------------------------

local function ShouldAppendShadowmeld(typeName)
    if typeName ~= "Water" then
        return false
    end
    if not ns.IsNightElf then
        return false
    end
    local settings = ConnoisseurCharDB and ConnoisseurCharDB.settings
    if not settings or not settings.enableShadowmeldDrinking then
        return false
    end
    return ns.ShadowmeldSpellName ~= nil
end

--------------------------------------------------------------------------------
-- Macro Enablement
--------------------------------------------------------------------------------

local function IsMacroEnabled(typeName)
    local settings = ConnoisseurCharDB and ConnoisseurCharDB.settings
    local enabled = settings and settings.enabledMacros
    if not enabled then
        return true
    end
    return enabled[typeName] ~= false
end

local function DeleteMacroIfExists(macroName, typeName)
    local index = GetMacroIndexByName(macroName)
    if index and index > 0 then
        DeleteMacro(index)
    end
    currentMacroState[typeName] = nil
end

--------------------------------------------------------------------------------
-- Macro Writing
--------------------------------------------------------------------------------

local function WriteMacro(macroName, icon, body, stateKey, typeName)
    local index = GetMacroIndexByName(macroName)
    if index == 0 then
        CreateMacro(macroName, icon, body, 1)
    else
        local existingBody = GetMacroBody(macroName)
        if existingBody ~= body then
            EditMacro(index, macroName, icon, body)
        end
    end
    currentMacroState[typeName] = stateKey
end

-- Builds the line that records macro-fire context to ConnoisseurState via
-- the global helper defined in Core.lua. The Core UI_ERROR_MESSAGE handler
-- reads lastID and lastTime to correlate a zone-restriction error with the
-- item that triggered it.
--
-- Using the global helper instead of an inline /run snippet keeps the macro
-- body short — important for the Food macro when stacking scroll uses
-- against the 255-character limit. The helper name is deliberately short
-- but distinctive (Conn... prefix) to minimize collision risk with other
-- addons while saving characters in every consumable macro.
local function StateWriteLine(itemID)
    return "/run ConnFire(" .. itemID .. ")\n"
end

--------------------------------------------------------------------------------
-- Scroll Block (additive)
--
-- Returns a string of /use [@player] item:NNN lines, one per scroll, in
-- ns.SCROLL_CHECK_ORDER priority. If the resulting body would exceed the
-- 255-character macro limit, drops scrolls from the back of the list
-- (lowest priority) until it fits. Also returns the list of IDs actually
-- included, so the state encoding reflects only what was written.
--
-- baseBodyLength is the length of every other line in the macro body
-- combined — tooltip, conjure block, state-write, action block, suffix.
--------------------------------------------------------------------------------

local function BuildScrollBlock(scrollList, baseBodyLength)
    if not scrollList or #scrollList == 0 then
        return "", nil
    end

    -- Build full block first, then trim from the back if too long.
    local lines = {}
    for _, scrollID in ipairs(scrollList) do
        lines[#lines + 1] = "/use [@player] item:" .. scrollID
    end

    local block = table.concat(lines, "\n") .. "\n"
    local includedIDs = { unpack(scrollList) }

    while baseBodyLength + #block > MACRO_MAX_LENGTH and #lines > 0 do
        lines[#lines] = nil
        includedIDs[#includedIDs] = nil
        if #lines == 0 then
            block = ""
            break
        end
        block = table.concat(lines, "\n") .. "\n"
    end

    if #includedIDs == 0 then
        return "", nil
    end

    return block, includedIDs
end

--------------------------------------------------------------------------------
-- Macro Update Loop
--------------------------------------------------------------------------------

function ns.UpdateMacros(forced)
    if InCombatLockdown() then
        ns.RequestUpdate()
        return
    end
    if not ns.ConjureSpells then
        return
    end

    if forced then
        wipe(currentMacroState)
    end

    local best, dataRetry = ns.ScanBags()

    if dataRetry then
        ns.RegisterDataRetry()
    else
        ns.UnregisterDataRetry()
    end

    -- Scrolls are dropped from the macro when targeting a friendly player so
    -- the macro reads cleanly as a conjure-for-friend action (Mage food).
    local friendlyPlayerTarget = HasFriendlyPlayerTarget()
    local activeScrollIDs = (not friendlyPlayerTarget) and ns.ScrollOverrideIDs or nil

    for typeName, config in pairs(Config) do
        -- Feed Pet is handled separately below
        if typeName == "Feed Pet" then
            -- skip, handled by UpdateFeedPetMacro
        elseif not IsMacroEnabled(typeName) then
            DeleteMacroIfExists(config.macro, typeName)
        else
            local itemID = best[typeName] and best[typeName].id

            -- Pet buff override: replaces the Food slot item with pet food.
            -- Scrolls are still allowed alongside (they target the player,
            -- pet food targets the pet — no conflict).
            local petBuffOverride = false

            if typeName == "Food" and ns.PetBuffOverrideID then
                itemID = ns.PetBuffOverrideID
                petBuffOverride = true
            end

            -- Scrolls only apply to the Food macro
            local scrollIDsForThisMacro = (typeName == "Food") and activeScrollIDs or nil

            local rightClickSpellName, rightClickSpellID
            local middleClickSpellName, middleClickSpellID

            if typeName == "Water" and ns.KnowsAny(ns.ConjureSpells.MageCreateWater) then
                rightClickSpellName, rightClickSpellID = GetSmartSpell(ns.ConjureSpells.MageCreateWater)
                middleClickSpellName, middleClickSpellID = GetSmartSpell(ns.ConjureSpells.MageCreateTable)
            elseif typeName == "Food" and ns.KnowsAny(ns.ConjureSpells.MageCreateFood) then
                rightClickSpellName, rightClickSpellID = GetSmartSpell(ns.ConjureSpells.MageCreateFood)
                middleClickSpellName, middleClickSpellID = GetSmartSpell(ns.ConjureSpells.MageCreateTable)
            elseif typeName == "Healthstone" and ns.KnowsAny(ns.ConjureSpells.WarlockCreateHealthstone) then
                rightClickSpellName, rightClickSpellID = GetSmartSpell(ns.ConjureSpells.WarlockCreateHealthstone)
                middleClickSpellName, middleClickSpellID = GetSmartSpell(ns.ConjureSpells.WarlockCreateSoulwell)
            elseif typeName == "Soulstone" and ns.KnowsAny(ns.ConjureSpells.WarlockCreateSoulstone) then
                rightClickSpellName, rightClickSpellID =
                    GetSmartSpell(ns.ConjureSpells.WarlockCreateSoulstone, true, false)
            elseif typeName == "Mana Gem" and ns.KnowsAny(ns.ConjureSpells.MageCreateManaGem) then
                rightClickSpellName, rightClickSpellID = GetSmartSpell(ns.ConjureSpells.MageCreateManaGem, true, true)
            end

            local appendShadowmeld = ShouldAppendShadowmeld(typeName)

            ----------------------------------------------------------------
            -- Build the conjure block first — its length feeds into the
            -- scroll block builder, which uses it to enforce 255 chars.
            ----------------------------------------------------------------

            local actionBlock, icon

            -- Conservative tooltip line used only for budget math — long
            -- form (item:NNNNN) so BuildScrollBlock under-allocates rather
            -- than over-allocates. The real tooltipLine is picked further
            -- down once we know which scrolls survived truncation.
            local budgetTooltipLine
            local fallbackTooltipLine

            if itemID then
                budgetTooltipLine = "#showtooltip item:" .. itemID .. "\n"
                fallbackTooltipLine = budgetTooltipLine

                if petBuffOverride then
                    -- Pet food buffs target the pet
                    actionBlock = StateWriteLine(itemID) .. "/use [@pet] item:" .. itemID
                else
                    actionBlock = StateWriteLine(itemID) .. "/use item:" .. itemID
                end

                icon = ns.QUESTION_MARK_ICON
            else
                local message = string.format(L["MSG_NO_ITEM"], typeName)
                budgetTooltipLine = "#showtooltip item:" .. config.defaultID .. "\n"
                fallbackTooltipLine = budgetTooltipLine
                actionBlock = string.format(
                    "/run print('%s%s%s // %s%s')",
                    GetColor("INFO"),
                    L["BRAND"],
                    GetColor("MUTED"),
                    GetColor("TEXT"),
                    message
                )
                icon = ns.QUESTION_MARK_ICON
            end

            local conjureBlock = ""
            if rightClickSpellName or middleClickSpellName then
                local castLine = ""
                local stopConditions = ""

                if middleClickSpellName then
                    castLine = castLine .. "[btn:3] " .. middleClickSpellName .. "; "
                    stopConditions = stopConditions .. "[btn:3]"
                end
                if rightClickSpellName then
                    castLine = castLine .. "[btn:2] " .. rightClickSpellName .. "; "
                    stopConditions = stopConditions .. "[btn:2]"
                end

                if castLine ~= "" then
                    conjureBlock = "/cast " .. castLine .. "\n" .. "/stopmacro " .. stopConditions .. "\n"
                end
            end

            local shadowmeldBlock = ""
            if appendShadowmeld and ns.ShadowmeldSpellName then
                shadowmeldBlock = "\n/cast [nostealth] " .. ns.ShadowmeldSpellName
            end

            ----------------------------------------------------------------
            -- Scroll block: built last because it consumes whatever
            -- character budget the rest of the macro left behind.
            ----------------------------------------------------------------

            local scrollBlock = ""
            local appliedScrollIDs

            if scrollIDsForThisMacro then
                local baseLength = #budgetTooltipLine + #conjureBlock + #actionBlock + #shadowmeldBlock
                scrollBlock, appliedScrollIDs = BuildScrollBlock(scrollIDsForThisMacro, baseLength)
            end

            ----------------------------------------------------------------
            -- Tooltip line: now that we know which scrolls actually
            -- survived truncation, pick the icon source. Bare
            -- #showtooltip lets the action bar resolve the icon from the
            -- first usable line in the body — for non-Mages with scrolls,
            -- that's the scroll itself; for Mages, the conjure spell on
            -- the line above the scroll. Either way, the bar shows
            -- something contextually useful for the click that's about
            -- to happen.
            ----------------------------------------------------------------

            local tooltipLine
            if appliedScrollIDs and #appliedScrollIDs > 0 then
                tooltipLine = "#showtooltip\n"
            else
                tooltipLine = fallbackTooltipLine
            end

            ----------------------------------------------------------------
            -- State encoding — must reflect everything that affects the
            -- written body so we know when to rewrite. Format:
            --   ITEMID(_S:s1,s2,...)?(_C(_M:mid)?(_R:rid)?)?(_SM)?
            -- The _S segment also implicitly captures the bare-vs-item
            -- tooltip choice: bare #showtooltip is used iff scrolls
            -- survived, and that's exactly when _S is present.
            ----------------------------------------------------------------

            local stateParts = { itemID and tostring(itemID) or "none" }
            if appliedScrollIDs then
                local pieces = {}
                for _, id in ipairs(appliedScrollIDs) do
                    pieces[#pieces + 1] = tostring(id)
                end
                stateParts[#stateParts + 1] = "S:" .. table.concat(pieces, ",")
            end
            if rightClickSpellName or middleClickSpellName then
                stateParts[#stateParts + 1] = "C"
                if middleClickSpellName then
                    stateParts[#stateParts + 1] = "M:" .. tostring(middleClickSpellID)
                end
                if rightClickSpellName then
                    stateParts[#stateParts + 1] = "R:" .. tostring(rightClickSpellID)
                end
            end
            if appendShadowmeld then
                stateParts[#stateParts + 1] = "SM"
            end
            local stateID = table.concat(stateParts, "_")

            if currentMacroState[typeName] ~= stateID or forced then
                local body = tooltipLine .. conjureBlock .. scrollBlock .. actionBlock .. shadowmeldBlock
                WriteMacro(config.macro, icon, body, stateID, typeName)
            end
        end
    end

    -- Feed Pet (Hunter only)
    if ns.IsHunter and ns.FeedPetSpellName then
        if IsMacroEnabled("Feed Pet") then
            ns.UpdateFeedPetMacro(forced)
        else
            local config = Config["Feed Pet"]
            if config then
                local index = GetMacroIndexByName(config.macro)
                if index and index > 0 then
                    DeleteMacro(index)
                end
                currentPetFoodState = nil
            end
        end
    end

    if ns.UpdateLDB then
        ns.UpdateLDB()
    end
end

function ns.ResetMacroState()
    wipe(currentMacroState)
    currentPetFoodState = nil
end

--------------------------------------------------------------------------------
-- Feed Pet Macro (Hunter)
--
-- Logic flow prioritizes modifier inputs first, then pet state, then combat.
-- By combining multiple conditions into bracket groups (e.g., [btn:2][combat]),
-- we save a massive amount of string characters ensuring the macro stays well
-- under the 255 character limit even in highly localized clients (German, etc).
--
-- Modifier actions:
--   [mod:ctrl]                 → Dismiss Pet
--   [mod:shift] OR [@pet,dead] → Revive Pet
--   [nopet]                    → Call Pet (or Revive Pet when dead-dismissed)
--   [btn:2] OR [combat]        → Mend Pet
--   default                    → Feed Pet + /use food
--------------------------------------------------------------------------------

function ns.UpdateFeedPetMacro(forced)
    if InCombatLockdown() then
        ns.RequestUpdate()
        return
    end

    if forced then
        currentPetFoodState = nil
    end

    ns.ScanPetFood()

    local feedName = ns.FeedPetSpellName
    local reviveName = ns.RevivePetSpellName
    local mendName = ns.MendPetSpellName
    local callName = ns.CallPetSpellName
    local dismissName = ns.DismissPetSpellName

    if not feedName or not reviveName or not mendName or not callName or not dismissName then
        return
    end

    local config = Config["Feed Pet"]
    if not config then
        return
    end
    local macroName = config.macro

    local itemID = ns.BestPetFoodID

    -- When we know the pet is dead but dismissed, [nopet] uses Revive Pet
    local nopetSpell = ns.PetDeadDismissed and reviveName or callName

    local stateID = (itemID and tostring(itemID) or "none") .. "_" .. (ns.PetDeadDismissed and "DD" or "ND")

    if currentPetFoodState == stateID and not forced then
        return
    end

    local modifiers = "[mod:ctrl] " .. dismissName .. "; [mod:shift][@pet,dead] " .. reviveName

    local body
    if itemID then
        body = table.concat({
            "#showtooltip",
            "/cast " .. modifiers
                .. "; [nopet] " .. nopetSpell
                .. "; [btn:2][combat] " .. mendName
                .. "; " .. feedName,
            "/stopmacro [mod][btn:2][nopet][@pet,dead][combat]",
            "/use item:" .. itemID,
        }, "\n")
    else
        -- No food: default action is Mend Pet, no /use line needed
        body = table.concat({
            "#showtooltip",
            "/cast " .. modifiers .. "; [nopet] " .. nopetSpell .. "; " .. mendName,
        }, "\n")
    end

    local icon = ns.QUESTION_MARK_ICON

    local index = GetMacroIndexByName(macroName)
    if index == 0 then
        CreateMacro(macroName, icon, body, 1)
    else
        local existingBody = GetMacroBody(macroName)
        if existingBody ~= body then
            EditMacro(index, macroName, icon, body)
        end
    end

    currentPetFoodState = stateID
end