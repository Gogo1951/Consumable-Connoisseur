local _, ns = ...
local L = ns.L

-- [[ STATE VARIABLES ]] --
ns.BestFoodID = nil
ns.BestFoodLink = nil

local itemCache = {} 
local scannerTooltip = CreateFrame("GameTooltip", "CC_ScannerTooltip", UIParent, "GameTooltipTemplate")
scannerTooltip:SetOwner(UIParent, "ANCHOR_NONE")

-- [[ HELPER FUNCTIONS ]] --
local function ParseNumber(text)
    if not text then return 0 end
    local clean = text:gsub("%D", "")
    return tonumber(clean) or 0
end

local function CacheItemData(itemID)
    local name, _, _, _, _, classType, subType, _, _, _, iPrice, classID = GetItemInfo(itemID)
    if not name then return nil end 

    if classID ~= 0 then
        itemCache[itemID] = "IGNORE"
        return "IGNORE"
    end

    scannerTooltip:ClearLines()
    scannerTooltip:SetHyperlink("item:"..itemID)
    if scannerTooltip:NumLines() == 0 then return nil end 

    local data = {
        id = itemID, valHealth = 0, valMana = 0, reqLvl = 0, reqFA = 0, price = iPrice or 0,
        isFood = false, isWater = false, isBandage = false, 
        isPotion = false, isHealthstone = false, isBuffFood = false, isPercent = false,
        incomplete = false
    }

    local foundSeated = false
    local isStrictHealth, isStrictMana = false, false
    
    -- Load Patterns (with safety fallbacks)
    local txtLevel = L["SCAN_REQ_LEVEL"]
    local txtFA = L["SCAN_REQ_FA"]
    local txtSeated = L["SCAN_SEATED"]
    local txtWellFed = L["SCAN_WELL_FED"]

    for i = 1, scannerTooltip:NumLines() do
        local line = _G["CC_ScannerTooltipTextLeft"..i]
        local text = line and line:GetText()
        
        if text then
            text = text:lower()

            text = text:gsub("([%d])[,%.]", "%1")

            if txtLevel then
                local lvl = text:match(txtLevel)
                if lvl then data.reqLvl = tonumber(lvl) end
            end

            if txtFA then
                local fa = text:match(txtFA)
                if fa then 
                    data.reqFA = tonumber(fa) 
                    local r, g, b = line:GetTextColor()
                    if g < 0.5 then
                        itemCache[itemID] = "IGNORE"
                        return "IGNORE"
                    end
                end
            end

            if txtSeated and text:find(txtSeated) then foundSeated = true end
            if txtWellFed and text:find(txtWellFed) then data.isBuffFood = true end
            
            if not isStrictHealth and not isStrictMana then
                local hMin = L["SCAN_HPOT_STRICT"] and text:match(L["SCAN_HPOT_STRICT"])
                if hMin then
                    data.valHealth = ParseNumber(hMin)
                    isStrictHealth = true
                    data.isPotion = true
                end

                local mMin = L["SCAN_MPOT_STRICT"] and text:match(L["SCAN_MPOT_STRICT"])
                if mMin and not (L["SCAN_HYBRID"] and text:find(L["SCAN_HYBRID"])) then
                    data.valMana = ParseNumber(mMin)
                    isStrictMana = true
                    data.isPotion = true
                end
            end

            if not isStrictHealth and not isStrictMana then
                local pVal = 0
                if L["SCAN_PERCENT"] then
                     pVal = ParseNumber(text:match(L["SCAN_PERCENT"]))
                end

                if pVal > 0 then
                    data.isPercent = true
                    if L["SCAN_MANA"] and text:find(L["SCAN_MANA"]) then data.valMana = 999999 end
                    if (L["SCAN_HEALTH"] and text:find(L["SCAN_HEALTH"])) or (L["SCAN_MANA"] and not text:find(L["SCAN_MANA"])) then 
                        data.valHealth = 999999 
                    end
                else
                    local rVal = L["SCAN_RESTORES"] and ParseNumber(text:match(L["SCAN_RESTORES"])) or 0
                    local hVal = L["SCAN_HEALS"] and ParseNumber(text:match(L["SCAN_HEALS"])) or 0
                    
                    if rVal > 0 or hVal > 0 then
                        local val = (rVal > hVal) and rVal or hVal
                        if L["SCAN_MANA"] and text:find(L["SCAN_MANA"]) then data.valMana = val end
                        
                        -- Check for Health keywords (including Life)
                        local isHealth = false
                        if L["SCAN_HEALTH"] and text:find(L["SCAN_HEALTH"]) then isHealth = true end
                        if L["SCAN_HEALS"] and text:find(L["SCAN_HEALS"]) then isHealth = true end
                        if L["SCAN_LIFE"] and text:find(L["SCAN_LIFE"]) then isHealth = true end
                        
                        if isHealth then data.valHealth = val end
                    end
                end
            end
        end
    end

    local nameLower = name:lower()
    if foundSeated then
        if data.valMana > 0 then data.isWater = true end
        if data.valHealth > 0 then data.isFood = true end
        if not data.isWater and not data.isFood then data.isFood = true end
    elseif (subType == "Bandage" or (L["SCAN_BANDAGE"] and nameLower:find(L["SCAN_BANDAGE"]))) and data.valHealth > 0 then
        data.isBandage = true
    elseif (L["SCAN_HEALTHSTONE"] and nameLower:find(L["SCAN_HEALTHSTONE"])) and data.valHealth > 0 then
        data.isHealthstone = true
    end

    if data.valHealth == 0 and data.valMana == 0 and not data.isBuffFood then
        data.incomplete = true
        return data
    end

    itemCache[itemID] = data
    return data
end

local function IsBetter(itemData, itemStack, itemPrice, best)
    if not best.id then return true end
    if ns.AllowBuffFood then
        if itemData.isBuffFood ~= best.isBuffFood then return itemData.isBuffFood end
    end
    if itemData.isPercent ~= best.isPercent then return itemData.isPercent end
    local iVal = itemData.valHealth + itemData.valMana
    local bVal = best.val
    if iVal ~= bVal then return iVal > bVal end
    if itemPrice ~= best.price then return itemPrice < best.price end
    local iHyb = (itemData.valHealth > 0 and itemData.valMana > 0)
    local bHyb = best.isHybrid
    if iHyb ~= bHyb then return iHyb end
    return itemStack < best.stack
end

-- [[ PUBLIC SCAN FUNCTION ]] --
function ns.ScanBags()
    local playerLevel = UnitLevel("player")
    local currentMap = C_Map.GetBestMapForUnit("player")
    local wellFedName = GetSpellInfo(19705)
    local hasWellFed = false
    
    if CC_Settings.UseBuffFood and wellFedName then
        for i = 1, 40 do
            local name = UnitAura("player", i, "HELPFUL")
            if not name then break end
            if name == wellFedName then hasWellFed = true; break end
        end
    end

    ns.AllowBuffFood = CC_Settings.UseBuffFood and not hasWellFed

    local best = {
        ["Food"] =          { id = nil, val = 0, price = 0, isBuffFood = false, isPercent = false, isHybrid = false, stack = 0, link = nil },
        ["Water"] =         { id = nil, val = 0, price = 0, isBuffFood = false, isPercent = false, isHybrid = false, stack = 0 },
        ["Health Potion"] = { id = nil, val = 0, price = 0, isBuffFood = false, isPercent = false, isHybrid = false, stack = 0 },
        ["Mana Potion"] =   { id = nil, val = 0, price = 0, isBuffFood = false, isPercent = false, isHybrid = false, stack = 0 },
        ["Healthstone"] =   { id = nil, val = 0, price = 0, isBuffFood = false, isPercent = false, isHybrid = false, stack = 0 },
        ["Bandage"] =       { id = nil, val = 0, price = 0, isBuffFood = false, isPercent = false, isHybrid = false, stack = 0 }
    }
    
    local dataRetry = false
    
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID then
                local id = info.itemID
                
                if CC_IgnoreList[id] or ns.Excludes[id] then
                    -- Skipped
                else
                    local data = itemCache[id]
                    if not data then data = CacheItemData(id) end

                    if not data then
                        GetItemInfo(id) 
                        dataRetry = true
                    elseif data == "IGNORE" then
                    else
                        if data.incomplete then
                            dataRetry = true
                        end

                        local usable = true
                        if data.reqLvl > playerLevel then usable = false end
                        
                        if usable and ns.ItemZoneRestrictions[id] then
                            usable = false
                            if currentMap then
                                for _, mapID in ipairs(ns.ItemZoneRestrictions[id]) do
                                    if mapID == currentMap then usable = true; break end
                                end
                            end
                        end

                        if usable then
                            local typeToUpdate = nil
                            if data.isBandage then typeToUpdate = "Bandage"
                            elseif data.isHealthstone then typeToUpdate = "Healthstone"
                            elseif data.isPotion then
                                if data.valHealth > 0 and IsBetter(data, info.stackCount, data.price, best["Health Potion"]) then
                                    best["Health Potion"].id = id
                                    best["Health Potion"].val = data.valHealth + data.valMana
                                    best["Health Potion"].price = data.price
                                    best["Health Potion"].stack = info.stackCount
                                end
                                if data.valMana > 0 and IsBetter(data, info.stackCount, data.price, best["Mana Potion"]) then
                                    best["Mana Potion"].id = id
                                    best["Mana Potion"].val = data.valHealth + data.valMana
                                    best["Mana Potion"].price = data.price
                                    best["Mana Potion"].stack = info.stackCount
                                end
                            elseif data.isFood or data.isWater then
                                if not (data.isBuffFood and not ns.AllowBuffFood) then
                                    if data.isFood then typeToUpdate = "Food" end
                                    if data.isWater and typeToUpdate == "Food" then
                                        if IsBetter(data, info.stackCount, data.price, best["Water"]) then
                                            best["Water"].id = id
                                            best["Water"].val = data.valHealth + data.valMana
                                            best["Water"].price = data.price
                                            best["Water"].stack = info.stackCount
                                            best["Water"].isBuffFood = data.isBuffFood
                                            best["Water"].isPercent = data.isPercent
                                            best["Water"].isHybrid = (data.valHealth > 0 and data.valMana > 0)
                                        end
                                    elseif data.isWater then
                                        typeToUpdate = "Water"
                                    end
                                end
                            end

                            if typeToUpdate then
                                local b = best[typeToUpdate]
                                if IsBetter(data, info.stackCount, data.price, b) then
                                    b.id = id
                                    b.val = data.valHealth + data.valMana
                                    b.price = data.price
                                    b.stack = info.stackCount
                                    b.isBuffFood = data.isBuffFood
                                    b.isPercent = data.isPercent
                                    b.isHybrid = (data.valHealth > 0 and data.valMana > 0)
                                    if typeToUpdate == "Food" then b.link = info.hyperlink end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    ns.BestFoodID = best["Food"].id
    ns.BestFoodLink = best["Food"].link
    
    return best, dataRetry
end
