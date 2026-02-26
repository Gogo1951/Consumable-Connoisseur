local _, ns = ...

ns.BestFoodID = nil
ns.BestFoodLink = nil

ns.CachedPlayerLevel = 1
ns.CachedMapID = nil

ns.WellFedState = false

local currentFirstAidSkill = 0
local currentAlchemySkill = 0

ns.RawData = ns.RawData or {}
ns.RawData.Bandage = ns.RawData.Bandage or {}
ns.RawData.FoodAndWater = ns.RawData.FoodAndWater or {}
ns.RawData.Healthstone = ns.RawData.Healthstone or {}
ns.RawData.Soulstone = ns.RawData.Soulstone or {}
ns.RawData.ManaGem = ns.RawData.ManaGem or {}
ns.RawData.Potions = ns.RawData.Potions or {}

function ns.KnowsAny(spellList)
    if not spellList then
        return false
    end
    for _, data in ipairs(spellList) do
        if IsSpellKnown(data[1]) then
            return true
        end
    end
    return false
end

function ns.ClearItemCache()
    if CC_ItemCache then
        wipe(CC_ItemCache)
    end
end

function ns.IsKnownConsumable(itemID)
    if CC_ItemCache and CC_ItemCache[itemID] and CC_ItemCache[itemID] ~= "IGNORE" then
        return true
    end
    return ns.RawData.FoodAndWater[itemID] ~= nil or ns.RawData.Potions[itemID] ~= nil or
        ns.RawData.Healthstone[itemID] ~= nil or
        ns.RawData.Soulstone[itemID] ~= nil or
        ns.RawData.Bandage[itemID] ~= nil or
        ns.RawData.ManaGem[itemID] ~= nil
end

local best = {
    ["Bandage"] = {
        id = nil,
        value = 0,
        price = 0,
        count = 0,
        link = nil,
        isBuffFood = false,
        isPercent = false,
        isHybrid = false
    },
    ["Food"] = {
        id = nil,
        value = 0,
        price = 0,
        count = 0,
        link = nil,
        isBuffFood = false,
        isPercent = false,
        isHybrid = false
    },
    ["Health Potion"] = {
        id = nil,
        value = 0,
        price = 0,
        count = 0,
        link = nil,
        isBuffFood = false,
        isPercent = false,
        isHybrid = false
    },
    ["Healthstone"] = {
        id = nil,
        value = 0,
        price = 0,
        count = 0,
        link = nil,
        isBuffFood = false,
        isPercent = false,
        isHybrid = false
    },
    ["Mana Gem"] = {
        id = nil,
        value = 0,
        price = 0,
        count = 0,
        link = nil,
        isBuffFood = false,
        isPercent = false,
        isHybrid = false
    },
    ["Mana Potion"] = {
        id = nil,
        value = 0,
        price = 0,
        count = 0,
        link = nil,
        isBuffFood = false,
        isPercent = false,
        isHybrid = false
    },
    ["Soulstone"] = {
        id = nil,
        value = 0,
        price = 0,
        count = 0,
        link = nil,
        isBuffFood = false,
        isPercent = false,
        isHybrid = false
    },
    ["Water"] = {
        id = nil,
        value = 0,
        price = 0,
        count = 0,
        link = nil,
        isBuffFood = false,
        isPercent = false,
        isHybrid = false
    }
}

local function ResetBest(entry)
    entry.id = nil
    entry.value = 0
    entry.price = 0
    entry.count = 0
    entry.link = nil
    entry.isBuffFood = false
    entry.isPercent = false
    entry.isHybrid = false
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

function ns.UpdateFirstAidSkill()
    local firstAidSpellName = GetSpellInfo(3273)
    if not firstAidSpellName then
        currentFirstAidSkill = 0
        return
    end

    for i = 1, GetNumSkillLines() do
        local skillName, isHeader, _, skillRank = GetSkillLineInfo(i)
        if not isHeader and skillName == firstAidSpellName then
            currentFirstAidSkill = skillRank
            return
        end
    end

    currentFirstAidSkill = 0
end

function ns.UpdateAlchemySkill()
    local alchemySpellName = GetSpellInfo(2259) -- Spell ID for Alchemy
    if not alchemySpellName then
        currentAlchemySkill = 0
        return
    end

    for i = 1, GetNumSkillLines() do
        local skillName, isHeader, _, skillRank = GetSkillLineInfo(i)
        if not isHeader and skillName == alchemySpellName then
            currentAlchemySkill = skillRank
            return
        end
    end

    currentAlchemySkill = 0
end

local function BuildZoneSet(rawZoneArray)
    if not rawZoneArray then
        return nil
    end
    local set = {}
    for _, mapID in ipairs(rawZoneArray) do
        set[mapID] = true
    end
    return set
end

local function CacheItemData(itemID)
    local name, _, _, _, minLevel, _, _, _, _, _, vendorPrice = GetItemInfo(itemID)
    if not name then
        return nil
    end

    local rawFoodAndWater = ns.RawData.FoodAndWater[itemID]
    local rawPotion = ns.RawData.Potions[itemID]
    local rawHealthstone = ns.RawData.Healthstone[itemID]
    local rawSoulstone = ns.RawData.Soulstone[itemID]
    local rawBandage = ns.RawData.Bandage[itemID]
    local rawManaGem = ns.RawData.ManaGem[itemID]

    if not (rawFoodAndWater or rawPotion or rawHealthstone or rawSoulstone or rawBandage or rawManaGem) then
        CC_ItemCache[itemID] = "IGNORE"
        return "IGNORE"
    end

    local data = {
        id = itemID,
        itemType = "",
        healthValue = 0,
        manaValue = 0,
        requiredLevel = minLevel or 0,
        requiredFirstAid = 0,
        requiredAlchemy = 0,
        price = vendorPrice or 0,
        isBuffFood = false,
        isPercent = false,
        zones = nil
    }

    if rawFoodAndWater then
        local isBuffFoodType = (rawFoodAndWater[1] == 1)
        data.isBuffFood = isBuffFoodType
        data.zones = BuildZoneSet(rawFoodAndWater[6])

        local hasFood = false
        local hasWater = false

        if rawFoodAndWater[2] > 0 then
            hasFood = true
            data.healthValue = 99999
            data.isPercent = true
        elseif rawFoodAndWater[3] > 0 then
            hasFood = true
            data.healthValue = rawFoodAndWater[3]
        end

        if rawFoodAndWater[4] > 0 then
            hasWater = true
            data.manaValue = 99999
            data.isPercent = true
        elseif rawFoodAndWater[5] > 0 then
            hasWater = true
            data.manaValue = rawFoodAndWater[5]
        end

        if isBuffFoodType and not hasFood and not hasWater then
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
        data.healthValue = rawPotion[1]
        data.manaValue = rawPotion[2]
        data.zones = BuildZoneSet(rawPotion[3])
        data.requiredAlchemy = rawPotion[4] or 0
    elseif rawHealthstone then
        data.itemType = "healthstone"
        data.healthValue = rawHealthstone[1]
    elseif rawSoulstone then
        data.itemType = "soulstone"
        data.healthValue = rawSoulstone[1]
    elseif rawBandage then
        data.itemType = "bandage"
        data.healthValue = rawBandage[1]
        data.requiredFirstAid = rawBandage[2] or 0
        data.zones = BuildZoneSet(rawBandage[3])
    elseif rawManaGem then
        data.itemType = "managem"
        data.manaValue = rawManaGem[1]
    end

    CC_ItemCache[itemID] = data
    return data
end

local function IsBetter(candidate, candidateCount, candidatePrice, currentBest, score, allowBuffFood, preferHybrid)
    if not currentBest.id then
        return true
    end

    if allowBuffFood and candidate.isBuffFood ~= currentBest.isBuffFood then
        return candidate.isBuffFood
    end

    if candidate.isPercent ~= currentBest.isPercent then
        return candidate.isPercent
    end

    if score ~= currentBest.value then
        return score > currentBest.value
    end

    if candidatePrice ~= currentBest.price then
        return candidatePrice < currentBest.price
    end

    local candidateIsHybrid = (candidate.healthValue > 0 and candidate.manaValue > 0)
    if candidateIsHybrid ~= currentBest.isHybrid then
        if preferHybrid then
            return candidateIsHybrid
        else
            return not candidateIsHybrid
        end
    end

    return candidateCount < currentBest.count
end

local itemCounts = {}
local slotItems = {}

function ns.ScanBags()
    local playerLevel = ns.CachedPlayerLevel
    local currentMap = ns.CachedMapID

    ns.AllowBuffFood = CC_Settings.UseBuffFood and not ns.WellFedState

    for _, entry in pairs(best) do
        ResetBest(entry)
    end

    local dataRetry = false
    wipe(itemCounts)
    wipe(slotItems)

    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID then
                local id = info.itemID
                itemCounts[id] = (itemCounts[id] or 0) + info.stackCount
                if not slotItems[id] then
                    slotItems[id] = info.hyperlink
                end
            end
        end
    end

    for id, hyperlink in pairs(slotItems) do
        if not CC_IgnoreList[id] then
            local data = CC_ItemCache[id]
            if not data then
                data = CacheItemData(id)
            end

            if not data then
                dataRetry = true
            elseif data ~= "IGNORE" then
                local usable = true

                if data.requiredLevel > playerLevel then
                    usable = false
                end

                if usable and data.requiredFirstAid > 0 and data.requiredFirstAid > currentFirstAidSkill then
                    usable = false
                end

                if usable and (data.requiredAlchemy or 0) > 0 and (data.requiredAlchemy or 0) > currentAlchemySkill then
                    usable = false
                end

                if usable and data.zones then
                    usable = (currentMap ~= nil) and (data.zones[currentMap] == true) or false
                end

                if usable then
                    local totalCount = itemCounts[id]
                    local itemType = data.itemType

                    if itemType == "bandage" then
                        if IsBetter(data, totalCount, data.price, best["Bandage"], data.healthValue, false) then
                            local winner = best["Bandage"]
                            winner.id = id
                            winner.value = data.healthValue
                            winner.price = data.price
                            winner.count = totalCount
                        end
                    elseif itemType == "healthstone" then
                        if IsBetter(data, totalCount, data.price, best["Healthstone"], data.healthValue, false) then
                            local winner = best["Healthstone"]
                            winner.id = id
                            winner.value = data.healthValue
                            winner.price = data.price
                            winner.count = totalCount
                        end
                    elseif itemType == "soulstone" then
                        if IsBetter(data, totalCount, data.price, best["Soulstone"], data.healthValue, false) then
                            local winner = best["Soulstone"]
                            winner.id = id
                            winner.value = data.healthValue
                            winner.price = data.price
                            winner.count = totalCount
                        end
                    elseif itemType == "managem" then
                        if IsBetter(data, totalCount, data.price, best["Mana Gem"], data.manaValue, false) then
                            local winner = best["Mana Gem"]
                            winner.id = id
                            winner.value = data.manaValue
                            winner.price = data.price
                            winner.count = totalCount
                        end
                    elseif itemType == "potion" then
                        if
                            data.healthValue > 0 and
                                IsBetter(data, totalCount, data.price, best["Health Potion"], data.healthValue, false)
                         then
                            local winner = best["Health Potion"]
                            winner.id = id
                            winner.value = data.healthValue
                            winner.price = data.price
                            winner.count = totalCount
                        end
                        if
                            data.manaValue > 0 and
                                IsBetter(data, totalCount, data.price, best["Mana Potion"], data.manaValue, false)
                         then
                            local winner = best["Mana Potion"]
                            winner.id = id
                            winner.value = data.manaValue
                            winner.price = data.price
                            winner.count = totalCount
                        end
                    elseif itemType == "food" or itemType == "water" or itemType == "foodwater" then
                        if not (data.isBuffFood and not ns.AllowBuffFood) then
                            if itemType == "food" or itemType == "foodwater" then
                                if
                                    IsBetter(
                                        data,
                                        totalCount,
                                        data.price,
                                        best["Food"],
                                        data.healthValue,
                                        ns.AllowBuffFood,
                                        true
                                    )
                                 then
                                    local winner = best["Food"]
                                    winner.id = id
                                    winner.value = data.healthValue
                                    winner.price = data.price
                                    winner.count = totalCount
                                    winner.isBuffFood = data.isBuffFood
                                    winner.isPercent = data.isPercent
                                    winner.link = hyperlink
                                    winner.isHybrid = (itemType == "foodwater")
                                end
                            end
                            if itemType == "water" or itemType == "foodwater" then
                                if
                                    IsBetter(
                                        data,
                                        totalCount,
                                        data.price,
                                        best["Water"],
                                        data.manaValue,
                                        ns.AllowBuffFood,
                                        false
                                    )
                                 then
                                    local winner = best["Water"]
                                    winner.id = id
                                    winner.value = data.manaValue
                                    winner.price = data.price
                                    winner.count = totalCount
                                    winner.isBuffFood = data.isBuffFood
                                    winner.isPercent = data.isPercent
                                    winner.isHybrid = (itemType == "foodwater")
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
