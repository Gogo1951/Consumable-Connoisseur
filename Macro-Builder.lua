local _, ns = ...
local L = ns.L
local GetColor = ns.GetColor
local Config = ns.Config

--------------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------------

local currentMacroState = {}

local conjuredGemItemIDBySpell = {
    [27101] = 22044,
    [10054] = 8008,
    [10053] = 8007,
    [3552]  = 5513,
    [759]   = 5514,
}

--------------------------------------------------------------------------------
-- Smart Spell Resolution
--------------------------------------------------------------------------------

local function GetSmartSpell(spellList, ignoreTarget, checkUnique)
    if not spellList then return nil, 0 end

    local levelCap = UnitLevel("player")

    if not ignoreTarget and UnitExists("target") and UnitIsFriend("player", "target") and UnitIsPlayer("target") then
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
    -- but none matched the level cap (targeting a low-level friend)
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

--------------------------------------------------------------------------------
-- Macro Update Loop
--------------------------------------------------------------------------------

function ns.UpdateMacros(forced)
    if InCombatLockdown() then
        ns.RequestUpdate()
        return
    end
    if not ns.ConjureSpells then return end

    if forced then
        wipe(currentMacroState)
    end

    local best, dataRetry = ns.ScanBags()

    if dataRetry then
        ns.RegisterDataRetry()
    else
        ns.UnregisterDataRetry()
    end

    for typeName, cfg in pairs(Config) do
        local itemID = best[typeName] and best[typeName].id

        -- Scroll override: when a scroll should be used, replace the Food macro item
        local scrollOverride = false
        if typeName == "Food" and ns.ScrollOverrideID then
            itemID = ns.ScrollOverrideID
            scrollOverride = true
        end

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
            rightClickSpellName, rightClickSpellID = GetSmartSpell(ns.ConjureSpells.WarlockCreateSoulstone, true, false)
        elseif typeName == "Mana Gem" and ns.KnowsAny(ns.ConjureSpells.MageCreateManaGem) then
            rightClickSpellName, rightClickSpellID = GetSmartSpell(ns.ConjureSpells.MageCreateManaGem, true, true)
        end

        local appendShadowmeld = ShouldAppendShadowmeld(typeName)

        local stateParts = { itemID and tostring(itemID) or "none" }
        if scrollOverride then
            stateParts[#stateParts + 1] = "S:" .. tostring(ns.ScrollOverrideID)
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
            local tooltipLine, actionBlock, icon

            if itemID then
                tooltipLine = "#showtooltip item:" .. itemID .. "\n"

                -- Scrolls target the player to avoid buffing the current target
                if scrollOverride then
                    actionBlock = "/run CC_LastID=" .. itemID .. ";CC_LastTime=GetTime()\n" .. "/use [@player] item:" .. itemID
                else
                    actionBlock = "/run CC_LastID=" .. itemID .. ";CC_LastTime=GetTime()\n" .. "/use item:" .. itemID
                end

                icon = C_Item.GetItemIconByID(itemID)
            else
                local message = string.format(L["MSG_NO_ITEM"], typeName)
                tooltipLine = "#showtooltip item:" .. cfg.defaultID .. "\n"
                actionBlock = string.format(
                    "/run print('%s%s%s // %s%s')",
                    GetColor("INFO"), L["BRAND"], GetColor("MUTED"), GetColor("TEXT"), message
                )
                icon = C_Item.GetItemIconByID(cfg.defaultID)
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

            local body = tooltipLine .. conjureBlock .. actionBlock .. shadowmeldBlock

            WriteMacro(cfg.macro, icon, body, stateID, typeName)
        end
    end

    if ns.UpdateLDB then
        ns.UpdateLDB()
    end
end

function ns.ResetMacroState()
    wipe(currentMacroState)
end
