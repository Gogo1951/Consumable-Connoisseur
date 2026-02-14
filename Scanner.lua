local _, ns = ...

ns.BestFoodID = nil
ns.BestFoodLink = nil

local currentFASkill = 0

ns.RawData = ns.RawData or {}
ns.RawData.Bandage = ns.RawData.Bandage or {}
ns.RawData.FoodAndWater = ns.RawData.FoodAndWater or {}
ns.RawData.Healthstone = ns.RawData.Healthstone or {}
ns.RawData.ManaGem = ns.RawData.ManaGem or {}
ns.RawData.Potions = ns.RawData.Potions or {}

local itemCache = {}

local itemCounts = {}
local checked = {}

-- Fix 3: Non-food/water best entries only need id/val/price/count.
-- Food and Water keep their extra fields for buff food and percent tracking.
local best = {
    ["Food"] = {
        id = nil,
        val = 0,
        price = 0,
        isBuffFood = false,
        isPercent = false,
        isHybrid = false,
        count = 0,
        link = nil
    },
    ["Water"] = {
        id = nil,
        val = 0,
        price = 0,
        isBuffFood = false,
        isPercent = false,
        isHybrid = false,
        count = 0
    },
    ["Health Potion"] = {id = nil, val = 0, price = 0, count = 0},
    ["Mana Potion"] = {id = nil, val = 0, price = 0, count = 0},
    ["Mana Gem"] = {id = nil, val = 0, price = 0, count = 0},
    ["Healthstone"] = {id = nil, val = 0, price = 0, count = 0},
    ["Bandage"] = {id = nil, val = 0, price = 0, count = 0}
}

local function ResetBest(t)
    t.id = nil
    t.val = 0
    t.price = 0
    t.count = 0
    t.link = nil
    -- Food/Water-only fields (nil-safe: no-ops on other types)
    if t.isBuffFood ~= nil then
        t.isBuffFood = false
    end
    if t.isPercent ~= nil then
        t.isPercent = false
    end
    if t.isHybrid ~= nil then
        t.isHybrid = false
    end
end

function ns.HasWellFedBuff()
    local TARGET_ICON_ID = 136000
    local TARGET_ICON_ID_2 = 133943
    for i = 1, 40 do
        local name, icon, _, _, _, _, _, _, _, spellID = UnitAura("player", i, "HELPFUL")
        if not name then
            break
        end
        if icon == TARGET_ICON_ID or icon == TARGET_ICON_ID_2 then
            return true
        end
        if ns.WellFedBuffIDs and ns.WellFedBuffIDs[spellID] then
            return true
        end
    end
    return false
end

function ns.UpdateFASkill()
    local faName = GetSpellInfo(3273)
    if not faName then
        currentFASkill = 0
        return
    end

    for i = 1, GetNumSkillLines() do
        local skillName, isHeader, _, skillRank = GetSkillLineInfo(i)
        if not isHeader and skillName == faName then
            currentFASkill = skillRank
            return
        end
    end

    currentFASkill = 0
end

local function CacheItemData(itemID)
    local name, link, rarity, iLevel, minLevel, class, subclass, stackCount, equipLoc, icon, iPrice =
        GetItemInfo(itemID)
    if not name then
        return nil
    end

    local rawFood = ns.RawData.FoodAndWater[itemID]
    local rawPotion = ns.RawData.Potions[itemID]
    local rawHS = ns.RawData.Healthstone[itemID]
    local rawBandage = ns.RawData.Bandage[itemID]
    local rawMGem = ns.RawData.ManaGem[itemID]

    if not (rawFood or rawPotion or rawHS or rawBandage or rawMGem) then
        itemCache[itemID] = "IGNORE"
        return "IGNORE"
    end

    -- Fix 2: single itemType string replaces 6 boolean flags (isFood, isWater,
    -- isBandage, isPotion, isHealthstone, isManaGem), saving ~5 fields per entry.
    local data = {
        id = itemID,
        itemType = "", -- "food"|"water"|"foodwater"|"bandage"|"potion"|"healthstone"|"managem"
        valHealth = 0,
        valMana = 0,
        reqLvl = minLevel or 0,
        reqFA = 0,
        price = iPrice or 0,
        isBuffFood = false,
        isPercent = false,
        zones = nil
    }

    if rawFood then
        local isBuff = (rawFood[1] == 1)
        data.isBuffFood = isBuff
        data.zones = rawFood[6]

        local hasFood = false
        local hasWater = false

        if rawFood[2] > 0 then
            hasFood = true
            data.valHealth = 99999
            data.isPercent = true
        elseif rawFood[3] > 0 then
            hasFood = true
            data.valHealth = rawFood[3]
        end

        if rawFood[4] > 0 then
            hasWater = true
            data.valMana = 99999
            data.isPercent = true
        elseif rawFood[5] > 0 then
            hasWater = true
            data.valMana = rawFood[5]
        end

        if isBuff and not hasFood and not hasWater then
            hasFood = true
        end

        if hasFood and hasWater then
            data.itemType = "foodwater"
        elseif hasFood then
            data.itemType = "food"
        else
            data.itemType = "water"
        end
    elseif rawPotion then
        data.itemType = "potion"
        data.valHealth = rawPotion[1]
        data.valMana = rawPotion[2]
        data.zones = rawPotion[3]
    elseif rawHS then
        data.itemType = "healthstone"
        data.valHealth = rawHS[1]
    elseif rawBandage then
        data.itemType = "bandage"
        data.valHealth = rawBandage[1]
        data.reqFA = rawBandage[2]
        data.zones = rawBandage[3]
    elseif rawMGem then
        data.itemType = "managem"
        data.valMana = rawMGem[1]
    end

    itemCache[itemID] = data

    -- Fix 1: free raw data now that it's been processed into itemCache.
    -- itemCache is permanent so this will never be needed again.
    if rawFood then
        ns.RawData.FoodAndWater[itemID] = nil
    elseif rawPotion then
        ns.RawData.Potions[itemID] = nil
    elseif rawHS then
        ns.RawData.Healthstone[itemID] = nil
    elseif rawBandage then
        ns.RawData.Bandage[itemID] = nil
    elseif rawMGem then
        ns.RawData.ManaGem[itemID] = nil
    end

    return data
end

local function IsBetter(itemData, itemCount, itemPrice, currentBest, score, allowBuffFood)
    if not currentBest.id then
        return true
    end

    if allowBuffFood and itemData.isBuffFood ~= currentBest.isBuffFood then
        return itemData.isBuffFood
    end
    if itemData.isPercent ~= currentBest.isPercent then
        return itemData.isPercent
    end

    local bVal = currentBest.val
    if score ~= bVal then
        return score > bVal
    end
    if itemPrice ~= currentBest.price then
        return itemPrice < currentBest.price
    end

    local iHyb = (itemData.valHealth > 0 and itemData.valMana > 0)
    if iHyb ~= currentBest.isHybrid then
        return iHyb
    end

    return itemCount < currentBest.count
end

function ns.ScanBags()
    local playerLevel = UnitLevel("player")
    local currentMap = C_Map.GetBestMapForUnit("player")

    local hasWellFed = false
    if CC_Settings.UseBuffFood then
        if ns.HasWellFedBuff then
            hasWellFed = ns.HasWellFedBuff()
        end
    end
    ns.AllowBuffFood = CC_Settings.UseBuffFood and not hasWellFed

    wipe(itemCounts)
    wipe(checked)
    for _, t in pairs(best) do
        ResetBest(t)
    end

    local dataRetry = false

    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemID = C_Container.GetContainerItemID(bag, slot)
            if itemID then
                local info = C_Container.GetContainerItemInfo(bag, slot)
                if info then
                    itemCounts[itemID] = (itemCounts[itemID] or 0) + info.stackCount
                end
            end
        end
    end

    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID then
                local id = info.itemID

                if not checked[id] then
                    checked[id] = true

                    if not CC_IgnoreList[id] then
                        local data = itemCache[id]
                        if not data then
                            data = CacheItemData(id)
                        end

                        if not data then
                            dataRetry = true
                        elseif data ~= "IGNORE" then
                            local usable = true
                            if data.reqLvl > playerLevel then
                                usable = false
                            end
                            if data.reqFA > 0 and data.reqFA > currentFASkill then
                                usable = false
                            end
                            if usable and data.zones then
                                usable = false
                                if currentMap then
                                    for _, mapID in ipairs(data.zones) do
                                        if mapID == currentMap then
                                            usable = true
                                            break
                                        end
                                    end
                                end
                            end

                            if usable then
                                local totalCount = itemCounts[id]
                                local t = data.itemType

                                if t == "bandage" then
                                    if
                                        IsBetter(
                                            data,
                                            totalCount,
                                            data.price,
                                            best["Bandage"],
                                            data.valHealth,
                                            ns.AllowBuffFood
                                        )
                                     then
                                        local b = best["Bandage"]
                                        b.id = id
                                        b.val = data.valHealth
                                        b.price = data.price
                                        b.count = totalCount
                                    end
                                elseif t == "healthstone" then
                                    if
                                        IsBetter(
                                            data,
                                            totalCount,
                                            data.price,
                                            best["Healthstone"],
                                            data.valHealth,
                                            ns.AllowBuffFood
                                        )
                                     then
                                        local b = best["Healthstone"]
                                        b.id = id
                                        b.val = data.valHealth
                                        b.price = data.price
                                        b.count = totalCount
                                    end
                                elseif t == "managem" then
                                    if
                                        IsBetter(
                                            data,
                                            totalCount,
                                            data.price,
                                            best["Mana Gem"],
                                            data.valMana,
                                            ns.AllowBuffFood
                                        )
                                     then
                                        local b = best["Mana Gem"]
                                        b.id = id
                                        b.val = data.valMana
                                        b.price = data.price
                                        b.count = totalCount
                                    end
                                elseif t == "potion" then
                                    if
                                        data.valHealth > 0 and
                                            IsBetter(
                                                data,
                                                totalCount,
                                                data.price,
                                                best["Health Potion"],
                                                data.valHealth,
                                                ns.AllowBuffFood
                                            )
                                     then
                                        local b = best["Health Potion"]
                                        b.id = id
                                        b.val = data.valHealth
                                        b.price = data.price
                                        b.count = totalCount
                                    end
                                    if
                                        data.valMana > 0 and
                                            IsBetter(
                                                data,
                                                totalCount,
                                                data.price,
                                                best["Mana Potion"],
                                                data.valMana,
                                                ns.AllowBuffFood
                                            )
                                     then
                                        local b = best["Mana Potion"]
                                        b.id = id
                                        b.val = data.valMana
                                        b.price = data.price
                                        b.count = totalCount
                                    end
                                elseif t == "food" or t == "water" or t == "foodwater" then
                                    if not (data.isBuffFood and not ns.AllowBuffFood) then
                                        if t == "food" or t == "foodwater" then
                                            if
                                                IsBetter(
                                                    data,
                                                    totalCount,
                                                    data.price,
                                                    best["Food"],
                                                    data.valHealth,
                                                    ns.AllowBuffFood
                                                )
                                             then
                                                local b = best["Food"]
                                                b.id = id
                                                b.val = data.valHealth
                                                b.price = data.price
                                                b.count = totalCount
                                                b.isBuffFood = data.isBuffFood
                                                b.isPercent = data.isPercent
                                                b.link = info.hyperlink
                                                b.isHybrid = (t == "foodwater")
                                            end
                                        end
                                        if t == "water" or t == "foodwater" then
                                            if
                                                IsBetter(
                                                    data,
                                                    totalCount,
                                                    data.price,
                                                    best["Water"],
                                                    data.valMana,
                                                    ns.AllowBuffFood
                                                )
                                             then
                                                local b = best["Water"]
                                                b.id = id
                                                b.val = data.valMana
                                                b.price = data.price
                                                b.count = totalCount
                                                b.isBuffFood = data.isBuffFood
                                                b.isPercent = data.isPercent
                                                b.isHybrid = (t == "foodwater")
                                            end
                                        end
                                    end
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