local _, ns = ...
local L = ns.L
local C = ns.Colors
local Config = ns.Config

local currentMacroState = {}

-- Map Spell IDs to the Item IDs they create
local manaGemMap = {
    [27101] = 22044, -- Emerald
    [10054] = 8008,  -- Ruby
    [10053] = 8007,  -- Citrine
    [3552]  = 5513,  -- Jade
    [759]   = 5514   -- Agate
}

local function GetSmartSpell(spellList, ignoreTarget, checkUnique)
    if not spellList then
        return nil, 0
    end
    local levelCap = UnitLevel("player")

    if not ignoreTarget and UnitExists("target") and UnitIsFriend("player", "target") and UnitIsPlayer("target") then
        local tLvl = UnitLevel("target")
        if tLvl > 0 then
            levelCap = tLvl
        end
    end

    for _, data in ipairs(spellList) do
        local id, req, rankNum = data[1], data[2], data[3]
        local known = IsSpellKnown(id)
        if not known and IsPlayerSpell then
            known = IsPlayerSpell(id)
        end

        if known and req <= levelCap then
            local skip = false
            
            -- If we are checking for unique items (Mana Gems), scan the bags
            if checkUnique and manaGemMap[id] then
                if C_Item.GetItemCount(manaGemMap[id]) > 0 then
                    skip = true
                end
            end

            if not skip then
                local name = GetSpellInfo(id)
                if name then
                    -- Only append Rank if rankNum exists (Mage Water/Food), 
                    -- otherwise use the name as-is (Mana Gems)
                    if rankNum then
                        return name .. "(" .. L["RANK"] .. " " .. rankNum .. ")", id
                    end
                    return name, id
                end
            end
        end
    end
    
    -- If we have all gems, default to the lowest rank spell (last in the list)
    -- This ensures the click still casts something, resulting in the game error "Item already exists"
    local lowest = spellList[#spellList]
    local name = GetSpellInfo(lowest[1])
    if lowest[3] then
        return name .. "(" .. L["RANK"] .. " " .. lowest[3] .. ")", lowest[1]
    end
    return name, lowest[1]
end

function ns.UpdateMacros(forced)
    if InCombatLockdown() then
        ns.RequestUpdate()
        return
    end
    if not ns.ConjureSpells then
        return
    end

    local best, dataRetry = ns.ScanBags()

    if dataRetry then
        ns.RegisterDataRetry()
    else
        ns.UnregisterDataRetry()
    end

    for typeName, cfg in pairs(Config) do
        local itemID = best[typeName].id
        local stateID = itemID and tostring(itemID) or "none"

        local rightSpellName, rightSpellID, midSpellName, midSpellID

        if typeName == "Water" and ns.ConjureSpells.MageWater then
            rightSpellName, rightSpellID = GetSmartSpell(ns.ConjureSpells.MageWater)
            midSpellName, midSpellID = GetSmartSpell(ns.ConjureSpells.MageTable)
        elseif typeName == "Food" and ns.ConjureSpells.MageFood then
            rightSpellName, rightSpellID = GetSmartSpell(ns.ConjureSpells.MageFood)
            midSpellName, midSpellID = GetSmartSpell(ns.ConjureSpells.MageTable)
        elseif typeName == "Healthstone" and ns.ConjureSpells.WarlockHS then
            rightSpellName, rightSpellID = GetSmartSpell(ns.ConjureSpells.WarlockHS)
            midSpellName, midSpellID = GetSmartSpell(ns.ConjureSpells.WarlockSoul)
        elseif typeName == "Mana Gem" and ns.ConjureSpells.MageManaGem then
            -- Pass true for ignoreTarget (gems are self-only) and true for checkUnique
            rightSpellName, rightSpellID = GetSmartSpell(ns.ConjureSpells.MageManaGem, true, true)
        end

        if rightSpellName or midSpellName then
            stateID = stateID .. "_C"
            if midSpellName then
                stateID = stateID .. "_M:" .. midSpellID
            end
            if rightSpellName then
                stateID = stateID .. "_R:" .. rightSpellID
            end
        end

        if currentMacroState[typeName] ~= stateID or forced then
            local tooltipLine, actionBlock, icon

            if itemID then
                tooltipLine = "#showtooltip item:" .. itemID .. "\n"
                actionBlock = "/run CC_LastID=" .. itemID .. ";CC_LastTime=GetTime()\n/use item:" .. itemID
                icon = GetItemIcon(itemID)
            else
                local msg = string.format(L["MSG_NO_ITEM"], typeName)
                tooltipLine = "#showtooltip item:" .. cfg.defaultID .. "\n"
                actionBlock = string.format("/run print('%s%s%s // %s%s')", C.INFO, L["BRAND"], C.MUTED, C.TEXT, msg)
                icon = GetItemIcon(cfg.defaultID)
            end

            local conjureBlock = ""
            if rightSpellName or midSpellName then
                local castLine = ""
                local stopConditions = ""

                if midSpellName then
                    castLine = castLine .. "[btn:3] " .. midSpellName .. "; "
                    stopConditions = stopConditions .. "[btn:3]"
                end
                if rightSpellName then
                    castLine = castLine .. "[btn:2] " .. rightSpellName .. "; "
                    stopConditions = stopConditions .. "[btn:2]"
                end

                if castLine ~= "" then
                    conjureBlock = "/cast " .. castLine .. "\n/stopmacro " .. stopConditions .. "\n"
                end
            end

            local body = tooltipLine .. conjureBlock .. actionBlock

            local index = GetMacroIndexByName(cfg.macro)
            if index == 0 then
                CreateMacro(cfg.macro, icon, body, 1)
            else
                EditMacro(index, cfg.macro, icon, body)
            end
            currentMacroState[typeName] = stateID
        end
    end

    if forced then
        wipe(currentMacroState)
    end
    if ns.UpdateLDB then
        ns.UpdateLDB()
    end
end

function ns.ResetMacroState()
    wipe(currentMacroState)
end