local _, ns = ...
local frame = CreateFrame("Frame")

--[[ 
    =======================================================================
                            CONFIGURATION
    =======================================================================
]]

local BRAND_COLOR = "|cff00BBFF" -- Cyan
local SEP_COLOR = "|cffAAAAAA" -- Grey
local TEXT_COLOR = "|cffffffff" -- White

local hasPrintedLimitError = false

CC_LastID = nil
CC_LastTime = 0

local ItemConfiguration = {
    ["Food"] = {
        macro = "- Food",
        defaultID = 5349,
        overrides = {}
    },
    ["Water"] = {
        macro = "- Water",
        defaultID = 5350,
        overrides = {}
    },
    ["Health Potion"] = {
        macro = "- Health Potion",
        defaultID = 118,
        overrides = {}
    },
    ["Mana Potion"] = {
        macro = "- Mana Potion",
        defaultID = 2455,
        overrides = {}
    },
    ["Healthstone"] = {
        macro = "- Healthstone",
        defaultID = 5512,
        overrides = {}
    },
    ["Bandage"] = {
        macro = "- Bandage",
        defaultID = 1251,
        overrides = {}
    }
}

local ZoneRestrictions = {
    [32902] = {1555, 266, 267, 268, 269, 270, 271, 334}, -- Bottled Nethergon Energy
    [32905] = {1555, 266, 267, 268, 269, 270, 271, 334}, -- Bottled Nethergon Vapor
    [17349] = {1459, 1460, 1461, 1956}, -- Superior Healing Draught
    [17352] = {1459, 1460, 1461, 1956}, -- Superior Mana Draught
    [17348] = {1459, 1460, 1461, 1956}, -- Major Healing Draught
    [17351] = {1459, 1460, 1461, 1956}, -- Major Mana Draught
    [19062] = {1460}, -- Warsong Gulch Field Ration
    [19061] = {1460}, -- Warsong Gulch Iron Ration
    [19060] = {1460}, -- Warsong Gulch Enriched Ration
    [20232] = {1461}, -- Defiler's Mageweave Bandage
    [20066] = {1461}, -- Arathi Basin Runecloth Bandage
    [20234] = {1461}, -- Defiler's Runecloth Bandage
    [20067] = {1461}, -- Arathi Basin Silk Bandage
    [32904] = {332, 1554, 263, 264, 262, 265}, -- Cenarion Healing Salve
    [32903] = {332, 1554, 263, 264, 262, 265}, -- Cenarion Mana Salve
    [32784] = {1949}, -- Red Ogre Brew
    [32910] = {1949}, -- Red Ogre Brew Special
    [32783] = {1949}, -- Blue Ogre Brew
    [32909] = {1949}, -- Blue Ogre Brew Special
}

--[[ 
    =======================================================================
                            HELPER FUNCTIONS
    =======================================================================
]]

local scannerTooltip = CreateFrame("GameTooltip", "CC_ScannerTooltip", UIParent, "GameTooltipTemplate")
scannerTooltip:SetOwner(UIParent, "ANCHOR_NONE")

local currentMacroState = {}

-- Generate fast lookup tables
local Overrides = {
    ["Food"] = {},
    ["Water"] = {},
    ["Health Potion"] = {},
    ["Mana Potion"] = {},
    ["Healthstone"] = {},
    ["Bandage"] = {}
}

for typeName, data in pairs(ItemConfiguration) do
    if data.overrides then
        for _, id in ipairs(data.overrides) do
            Overrides[typeName][id] = true
        end
    end
end

local function Print(msg)
    print(BRAND_COLOR .. "Connoisseur|r " .. SEP_COLOR .. "//|r " .. TEXT_COLOR .. msg .. "|r")
end

local function CleanText(text)
    if not text then
        return ""
    end
    -- Strip colors and lowercase
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    return text:lower()
end

-- Helper to parse "2,148" or "100" from a string
local function ParseFirstNumber(text)
    if not text then
        return 0
    end
    local match = text:match("([%d,]+)")
    if match then
        return tonumber((match:gsub(",", "")))
    end
    return 0
end

local function IsItemAllowedInZone(itemID)
    if not ZoneRestrictions[itemID] then
        return true
    end

    local currentMapID = C_Map.GetBestMapForUnit("player")
    if not currentMapID then
        return false
    end

    for _, allowedMap in ipairs(ZoneRestrictions[itemID]) do
        if allowedMap == currentMapID then
            return true
        end
    end

    return false
end

-- NEW HELPER: Get First Aid Rank
local function GetPlayerFirstAidRank()
    local profs = {GetProfessions()}
    for _, index in ipairs(profs) do
        local name, _, rank = GetProfessionInfo(index)
        if name == "First Aid" then
            return rank
        end
    end
    return 0
end

--[[ 
    =======================================================================
                            ITEM SCANNING
    =======================================================================
]]
local function GetItemProperties(bag, slot)
    local info = C_Container.GetContainerItemInfo(bag, slot)
    if not info then
        return nil
    end

    local itemID = info.itemID
    if not itemID then
        return nil
    end

    -- 1. Zone Check
    if not IsItemAllowedInZone(itemID) then
        return nil
    end

    -- 2. Fast Fail & Info Retrieval

    -- FIX: Use GetItemInfoInstant to get numeric Class IDs (0, 1, etc.)
    local _, _, _, _, _, classID, subclassID = GetItemInfoInstant(itemID)

    -- FIX: Use GetItemInfo ONLY for the Item Level (4th return)
    local _, _, _, itemLevel = GetItemInfo(itemID)
    if not itemLevel then
        itemLevel = 1
    end

    local isOverride =
        (Overrides["Healthstone"][itemID] or Overrides["Bandage"][itemID] or Overrides["Mana Potion"][itemID] or
        Overrides["Health Potion"][itemID] or
        Overrides["Food"][itemID] or
        Overrides["Water"][itemID])

    -- Class 0 is Consumable. We allow that, or overrides.
    if (not classID) or (classID ~= 0 and not isOverride) then
        return nil
    end

    -- 3. DETERMINE TYPE & VALUE
    local foundType = nil
    local foundValue = 0

    -- A. Check Overrides first (Fastest)
    if Overrides["Bandage"][itemID] then
        foundType = "Bandage"
        foundValue = 50000
    elseif Overrides["Healthstone"][itemID] then
        foundType = "Healthstone"
        foundValue = 50000
    elseif Overrides["Mana Potion"][itemID] then
        foundType = "Mana Potion"
        foundValue = 50000
    elseif Overrides["Health Potion"][itemID] then
        foundType = "Health Potion"
        foundValue = 50000
    elseif Overrides["Food"][itemID] then
        foundType = "Food"
        foundValue = 50000
    elseif Overrides["Water"][itemID] then
        foundType = "Water"
        foundValue = 50000
    end

    -- B. Scan Tooltip (The "IzC" Logic)
    if not foundType then
        -- Use Link + UIParented Tooltip for 100% read reliability
        local link = C_Container.GetContainerItemLink(bag, slot)
        if not link then
            return nil
        end

        scannerTooltip:ClearLines()
        scannerTooltip:SetHyperlink(link)

        for i = 1, scannerTooltip:NumLines() do
            local rawText = _G["CC_ScannerTooltipTextLeft" .. i]:GetText()
            local text = CleanText(rawText)

            if text ~= "" then
                -- [[ CHECK 1: Bandage Skill Requirement ]]
                if text:find("requires first aid") then
                    local reqLevel = tonumber(text:match("%((%d+)%)"))
                    if reqLevel and reqLevel > GetPlayerFirstAidRank() then
                        return nil
                    end
                end

                -- [[ CHECK 2: Level Requirement (Potions) ]]
                if text:find("requires level") then
                    local reqLevel = tonumber(text:match("requires level (%d+)"))
                    if reqLevel and reqLevel > UnitLevel("player") then
                        return nil
                    end
                end

                -- LOGIC 1: Bandage
                if text:find("heals") and text:find("damage") and (classID == 0 and subclassID == 0) then
                
                -- LOGIC 2: Potions (Health/Mana)
                -- Looks for "restores X to Y" or just "restores X"
                    foundType = "Bandage"
                    foundValue = ParseFirstNumber(text)
                    break
                
                elseif text:find("restores") and (text:find("health") or text:find("mana")) and not text:find("seated") then
                    -- LOGIC 3: Food / Water
                    -- If it says "Must remain seated", it IS food or water.
                    local val = ParseFirstNumber(text)
                    if text:find("mana") then
                        foundType = "Mana Potion"
                        foundValue = val
                        break
                    elseif text:find("health") then
                        foundType = "Health Potion"
                        foundValue = val
                        break
                    end
                elseif text:find("must remain seated") then
                    local val = ParseFirstNumber(text)
                    if val == 0 then
                        val = itemLevel * 10
                    end -- Fallback if number parsing fails

                    -- If it explicitly mentions stats, ignore it (based on your request)
                    if not (text:find("increases your") or text:find("gain") or text:find("well fed")) then
                        if text:find("mana") then
                            foundType = "Water"
                            foundValue = val
                            break
                        else
                            -- Default to Food if not mana
                            foundType = "Food"
                            foundValue = val
                            break
                        end
                    end
                end

                -- LOGIC 4: Healthstone (Name check is safest)
                if foundType == nil then
                    local name = GetItemInfo(itemID)
                    if name and name:find("Healthstone") then
                        foundType = "Healthstone"
                        foundValue = ParseFirstNumber(text) or (itemLevel * 10)
                        break
                    end
                end
            end
        end
    end

    -- 4. BUILD TABLE (Only if valid)
    if foundType then
        local _, _, _, _, _, _, _, _, _, _, itemSellPrice = GetItemInfo(itemID)
        return {
            id = itemID,
            bag = bag,
            slot = slot,
            stack = info.stackCount,
            price = itemSellPrice or 0,
            value = foundValue or (itemLevel * 10),
            type = foundType
        }
    end

    return nil
end

local function IsItemBetter(newItem, currentBest)
    if not currentBest then
        return true
    end
    if newItem.value > currentBest.value then
        return true
    end
    if newItem.value < currentBest.value then
        return false
    end
    if newItem.price < currentBest.price then
        return true
    end
    if newItem.price > currentBest.price then
        return false
    end
    if newItem.stack < currentBest.stack then
        return true
    end
    return false
end

--[[ 
    =======================================================================
                            CORE LOOP
    =======================================================================
]]
local function UpdateMacros()
    if InCombatLockdown() then
        return
    end

    local bestItems = {
        ["Food"] = nil,
        ["Water"] = nil,
        ["Health Potion"] = nil,
        ["Mana Potion"] = nil,
        ["Healthstone"] = nil,
        ["Bandage"] = nil
    }

    -- Find best item
    -- Use NUM_BAG_SLOTS constant which is safer
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local item = GetItemProperties(bag, slot)
            if item then
                if item.type == "Dual" then
                    if IsItemBetter(item, bestItems["Food"]) then
                        bestItems["Food"] = item
                    end
                    if IsItemBetter(item, bestItems["Water"]) then
                        bestItems["Water"] = item
                    end
                else
                    if IsItemBetter(item, bestItems[item.type]) then
                        bestItems[item.type] = item
                    end
                end
            end
        end
    end

    -- Macro Safety Check
    local numAccount, numChar = GetNumMacros()
    local limitAccount = MAX_ACCOUNT_MACROS or 120
    local limitChar = MAX_CHARACTER_MACROS or 18

    -- Update Macros
    for typeName, config in pairs(ItemConfiguration) do
        local macroName = config.macro
        local item = bestItems[typeName]
        local body = ""
        local icon = "INV_Misc_QuestionMark"
        local finalID = "empty"

        if item then
            -- CASE 1: Item Found (This adds the LastID feature)
            body =
                "#showtooltip item:" ..
                item.id .. "\n/run CC_LastID=" .. item.id .. ";CC_LastTime=GetTime()\n/use item:" .. item.id
            icon = GetItemIcon(item.id)
            finalID = tostring(item.id)
        else
            -- CASE 2: No Item Found
            local defID = config.defaultID
            local errorMsg =
                BRAND_COLOR ..
                "Connoisseur|r " ..
                    SEP_COLOR .. "//|r " .. TEXT_COLOR .. "No suitable " .. typeName .. " found in your bags.|r"

            if defID then
                body = "#showtooltip item:" .. defID .. "\n/run print('" .. errorMsg .. "')"
                icon = GetItemIcon(defID) or "INV_Misc_QuestionMark"
            else
                body = "#showtooltip INV_Misc_QuestionMark\n/run print('" .. errorMsg .. "')"
                icon = "INV_Misc_QuestionMark"
            end
            finalID = "error_" .. (defID or "none")
        end

        if currentMacroState[macroName] ~= finalID then
            local macId = GetMacroIndexByName(macroName)
            if macId == 0 then
                if numChar < limitChar then
                    CreateMacro(macroName, icon, body, 1)
                elseif numAccount < limitAccount then
                    CreateMacro(macroName, icon, body, nil)
                else
                    if not hasPrintedLimitError then
                        Print("|cffFF0000Error: Macro limit reached. Could not create '" .. macroName .. "'.|r")
                        hasPrintedLimitError = true
                    end
                end
            else
                EditMacro(macId, macroName, icon, body)
            end
            currentMacroState[macroName] = finalID
        end
    end
end

--[[ EVENTS ]]
local updateFrame = CreateFrame("Frame")
updateFrame:Hide()
updateFrame:SetScript(
    "OnUpdate",
    function(self, elapsed)
        self.timer = (self.timer or 0) + elapsed

        -- Throttled to 1.0 second
        if self.timer > 1.0 then
            self:Hide()
            self.timer = 0
            UpdateMacros()
        end
    end
)

local function RequestUpdate()
    if not InCombatLockdown() then
        updateFrame:Show()
    end
end

frame:SetScript(
    "OnEvent",
    function(self, event, ...)
        if event == "ZONE_CHANGED_NEW_AREA" then
            currentMacroState = {}
            RequestUpdate()
        elseif event == "UI_ERROR_MESSAGE" then
            local errorType = ...
            if errorType == 51 then
                if CC_LastTime and (GetTime() - CC_LastTime) < 1.0 then
                    local mapID = C_Map.GetBestMapForUnit("player") or "Unknown"
                    local itemName = "this item"
                    if CC_LastID then
                        local name, link = GetItemInfo(CC_LastID)
                        itemName = link or name or ("Item #" .. CC_LastID)
                    end
                    print(
                        BRAND_COLOR ..
                            "Connoisseur|r " ..
                                SEP_COLOR ..
                                    "//|r " ..
                                        TEXT_COLOR ..
                                            "Looks like you found a bug! Please report that " ..
                                                itemName ..
                                                    " can't be used in Map ID " ..
                                                        mapID ..
                                                            " so we can get it fixed. Thanks! https://discord.gg/eh8hKq992Q|r"
                    )
                    CC_LastTime = 0
                end
            end
        else
            RequestUpdate()
        end
    end
)

frame:RegisterEvent("BAG_UPDATE_DELAYED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("UI_ERROR_MESSAGE")
