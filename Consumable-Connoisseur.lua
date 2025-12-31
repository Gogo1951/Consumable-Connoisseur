local addonName, addon = ...
local frame = CreateFrame("Frame")

----------------------------------------------------------------------
-- Consumable Items
----------------------------------------------------------------------

local itemCategories = {
    -- Only including food sold by Inn Keepers for now.
    -- Inn Keepers
    -- https://www.wowhead.com/tbc/npc=16618/innkeeper-velandra
    -- https://www.wowhead.com/tbc/npc=16739/caregiver-breel
    -- https://www.wowhead.com/tbc/npc=17630/innkeeper-jovia
    -- https://www.wowhead.com/tbc/npc=19232/innkeeper-haelthol
    -- https://www.wowhead.com/tbc/npc=5111/innkeeper-firebrew
    -- https://www.wowhead.com/tbc/npc=6736/innkeeper-keldamyr
    -- https://www.wowhead.com/tbc/npc=6740/innkeeper-allison
    -- https://www.wowhead.com/tbc/npc=6741/innkeeper-norman
    -- https://www.wowhead.com/tbc/npc=6746/innkeeper-pala
    -- https://www.wowhead.com/tbc/npc=6929/innkeeper-gryshka

    ["- Food"] = {
        34062, -- Conjured Manna Biscuit
        34780, -- Naaru Ration
        22019, -- Conjured Croissant
        29449, -- Bladespire Bagel
        29451, -- Clefthoof Ribs
        33254, -- Forest Strider Drumstick
        35285, -- Giant Sunfish
        30355, -- Grilled Shadowmoon Tuber
        29394, -- Lyribread
        29448, -- Mag'har Mild Cheese
        32685, -- Ogri'la Chicken Fingers
        38428, -- Rock-Salted Pretzel
        29453, -- Sporeggar Mushroom
        33048, -- Stewed Trout
        29450, -- Telaari Grapes
        29452, -- Zangar Trout
        19301, -- Alterac Manna Biscuit
        22895, -- Conjured Cinnamon Roll
        27661, -- Blackened Trout
        29393, -- Diamond Berries
        24408, -- Edible Stalks
        33246, -- Funnel Cake
        27857, -- Garadar Sharp
        29412, -- Jessen's Special Slop
        27855, -- Mag'har Grainbread
        28486, -- Moser's Magnificent Muffin
        38427, -- Pickled Egg
        27856, -- Skethyl Berries
        30610, -- Smoked Black Bear Meat
        27854, -- Smoked Talbuk Venison
        30458, -- Stromgarde Muenster
        27858, -- Sunspring Carp
        27859, -- Zangar Caps
        8076, -- Conjured Sweet Roll
        13724, -- Enriched Manna Biscuit
        8932, -- Alterac Swiss
        13935, -- Baked Salmon
        21031, -- Cabbage Kimchi
        19225, -- Deep Fried Candybar
        8953, -- Deep Fried Plantains
        8948, -- Dried King Bolete
        11444, -- Grim Guzzler Boar
        24338, -- Hellfire Spineleaf
        8950, -- Homemade Cherry Pie
        13933, -- Lobster Stew
        11415, -- Mixed Berries
        21033, -- Radish Kimchi
        8952, -- Roasted Quail
        16171, -- Shinsollo
        8957, -- Spinefin Halibut
        12763, -- Un'Goro Etherfruit
        22324, -- Winter Kimchi
        8075, -- Conjured Sourdough
        18635, -- Bellara's Nutterbar
        13546, -- Bloodbelly Fish
        19306, -- Crunchy Frog
        4599, -- Cured Ham Steak
        13888, -- Darkclaw Lobster
        21030, -- Darnassus Kimchi Pie
        13930, -- Filet of Redgill
        3927, -- Fine Aged Cheddar
        9681, -- Grilled King Crawler Legs
        16168, -- Heaven Peach
        13893, -- Large Raw Mightfish
        4602, -- Moon Harvest Pumpkin
        4608, -- Raw Black Truffle
        8959, -- Raw Spinefin Halibut
        13889, -- Raw Whitescale Salmon
        18255, -- Runn Tum Tuber
        4601, -- Soft Banana Bread
        17408, -- Spicy Beefstick
        6887, -- Spotted Yellowtail
        21552, -- Striped Yellowtail
        16766, -- Undermine Clam Chowder
        1487, -- Conjured Pumpernickel
        4607, -- Delicious Cave Mold
        6807, -- Frog Leg Stew
        4539, -- Goldenbark Apple
        17407, -- Graccu's Homemade Meat Pie
        8364, -- Mithril Head Trout
        18632, -- Moonbrook Riot Taffy
        4544, -- Mulgore Spice Bread
        13754, -- Raw Glossy Mightfish
        13759, -- Raw Nightfin Snapper
        13758, -- Raw Redgill
        4603, -- Raw Spotted Yellowtail
        13756, -- Raw Summer Bass
        13760, -- Raw Sunscale Salmon
        19224, -- Red Hot Wings
        4594, -- Rockscale Cod
        1707, -- Stormwind Brie
        8543, -- Underwater Mushroom Cap
        3771, -- Wild Hog Shank
        16169, -- Wild Ricecake
        13755, -- Winter Squid
        1114, -- Conjured Rye
        1119, -- Bottled Spirits
        4593, -- Bristle Whisker Catfish
        5526, -- Clam Chowder
        5478, -- Dig Rat Stew
        422, -- Dwarven Mild
        5845, -- Flank of Meat
        4542, -- Moist Cornbread
        3770, -- Mutton Chop
        19305, -- Pickled Kodo Foot
        8365, -- Raw Mithril Head Trout
        6362, -- Raw Rockscale Cod
        4538, -- Snapvine Watermelon
        4606, -- Spongy Morel
        16170, -- Steamed Mandu
        2685, -- Succulent Pork Ribs
        7228, -- Tigule's Strawberry Ice Cream
        733, -- Westfall Stew
        1113, -- Conjured Bread
        414, -- Dalaran Sharp
        12238, -- Darkshore Grouper
        17119, -- Deeprun Rat Kabob
        5066, -- Fissure Plant
        4541, -- Freshly Baked Bread
        2287, -- Haunch of Meat
        17406, -- Holiday Cheesewheel
        6316, -- Loch Frenzy Delight
        4592, -- Longjaw Mud Snapper
        5095, -- Rainbow Fin Albacore
        6308, -- Raw Bristle Whisker Catfish
        4605, -- Red-speckled Mushroom
        24072, -- Sand Pear Pie
        1326, -- Sauteed Sunfish
        6890, -- Smoked Bear Meat
        19304, -- Spiced Beef Jerky
        18633, -- Styleen's Sour Suckerpop
        4537, -- Tel'Abim Banana
        16167, -- Versicolor Treat
        5349, -- Conjured Muffin
        16166, -- Bean Soup
        6290, -- Brilliant Smallfish
        17344, -- Candy Cane
        2679, -- Charred Wolf Meat
        19223, -- Darkmoon Dog
        2070, -- Darnassian Bleu
        4604, -- Forest Mushroom Cap
        961, -- Healing Herb
        20857, -- Honey Bread
        7097, -- Leg Meat
        6458, -- Oil Covered Fish
        6317, -- Raw Loch Frenzy
        6289, -- Raw Longjaw Mud Snapper
        6361, -- Raw Rainbow Fin Albacore
        5057, -- Ripe Watermelon
        2681, -- Roasted Boar Meat
        4536, -- Shiny Red Apple
        787, -- Slitherskin Mackerel
        4656, -- Small Pumpkin
        30816, -- Spice Bread
        23495, -- Springpaw Appetizer
        4540, -- Tough Hunk of Bread
        117, -- Tough Jerky
    },
    ["- Water"] = {
        34062, -- Conjured Manna Biscuit
        34780, -- Naaru Ration
        22018, -- Conjured Glacier Water
        33042, -- Black Coffee
        38431, -- Blackrock Fortified Water
        32668, -- Dos Ogris
        29395, -- Ethermead
        30457, -- Gilneas Sparkling Water
        27860, -- Purified Draenic Water
        29401, -- Sparkling Southshore Cider
        32453, -- Star's Tears
        30703, -- Conjured Mountain Spring Water
        38430, -- Blackrock Mineral Water
        28399, -- Filtered Draenic Water
        33236, -- Fizzy Faire Drink "Classic"
        29454, -- Silverwine
        19301, -- Alterac Manna Biscuit
        13724, -- Enriched Manna Biscuit
        8078, -- Conjured Sparkling Water
        23585, -- Stouthammer Lite
        38429, -- Blackrock Spring Water
        8766, -- Morning Glory Dew
        8077, -- Conjured Mineral Water
        19300, -- Bottled Winterspring Water
        1645, -- Moonberry Juice
        3772, -- Conjured Spring Water
        4791, -- Enchanted Water
        10841, -- Goldthorn Tea
        17405, -- Green Garden Tea
        1708, -- Sweet Nectar
        2136, -- Conjured Purified Water
        9451, -- Bubbling Water
        19299, -- Fizzy Faire Drink
        1205, -- Melon Juice
        2288, -- Conjured Fresh Water
        17404, -- Blended Bean Brew
        1179, -- Ice Cold Milk
        5350, -- Conjured Water
        159, -- Refreshing Spring Water
    },
    ["- Health Potion"] = {
        -- https://www.wowhead.com/tbc/item=929/healing-potion#shared-cooldown;q=heal
        33092, -- (2500) Healing Potion Injector
        31838, -- (2500) Major Combat Healing Potion
        32948, -- (2500) Major Healing Draught
        32947, -- (2500) Auchenai Healing Potion
        32909, -- (2500) Crystal Healing Potion
        32904, -- (2500) Cenarion Healing Salve
        32905, -- (2500) Bottled Nethergon Vapor
        22829, -- (2500) Super Healing Potion
        17351, -- (1750) Superior Healing Draught
        18839, -- (1500) Combat Healing Potion
        13446, -- (1750) Major Healing Potion
        3928, -- (900) Superior Healing Potion
        1710, -- (585) Greater Healing Potion
        929, -- (360) Healing Potion
        858, -- (180) Lesser Healing Potion
        118, -- (90) Minor Healing Potion
    },
    ["- Mana Potion"] = {
        -- https://www.wowhead.com/tbc/item=929/healing-potion#shared-cooldown;q=mana
        33093, -- (3000) Mana Potion Injector
        32902, -- (3000) Bottled Nethergon Energy
        32903, -- (3000) Cenarion Mana Salve
        32904, -- (3000) Auchenai Mana Potion
        32905, -- (3000) Crystal Mana Potion
        22832, -- (3000) Super Mana Potion
        32948, -- (2250) Major Mana Draught
        31840, -- (2250) Major Combat Mana Potion
        32906, -- (2250) Unstable Mana Potion
        13444, -- (2250) Major Mana Potion
        18841, -- (1500) Combat Mana Potion
        17352, -- (1500) Superior Mana Draught
        13443, -- (1500) Superior Mana Potion
        6149, -- (900) Greater Mana Potion
        3827, -- (585) Mana Potion
        3385, -- (360) Lesser Mana Potion
        2455, -- (180) Minor Mana Potion
    },
    ["- Healthstone"] = {
        -- https://www.wowhead.com/tbc/item=5509/healthstone#shared-cooldown;q=healthstone
        22105, -- Master Healthstone (2496)
        22104, -- Master Healthstone (2288)
        22103, -- Master Healthstone (2080)
        19013, -- Major Healthstone (1440)
        19012, -- Major Healthstone (1320)
        9421, -- Major Healthstone (1200)
        19011, -- Greater Healthstone (960)
        19010, -- Greater Healthstone (880)
        5510, -- Greater Healthstone (800)
        19009, -- Healthstone (600)
        19008, -- Healthstone (550)
        5509, -- Healthstone (500)
        19007, -- Lesser Healthstone (300)
        19006, -- Lesser Healthstone (275)
        5511, -- Lesser Healthstone (250)
        19005, -- Minor Healthstone (120)
        19004, -- Minor Healthstone (110)
        5512, -- Minor Healthstone (100)
    },
    ["- Bandage"] = {
        -- https://www.wowhead.com/tbc/item=14530/heavy-runecloth-bandage#shared-cooldown;0-3+1-2;q=bandage
        21991, -- (2800) Heavy Netherweave Bandage
        21990, -- (2000) Netherweave Bandage
        19060, -- (2000) Alterac Heavy Runecloth Bandage
        20066, -- (2000) Arathi Basin Runecloth Bandage
        20232, -- (2000) Warsong Gulch Runecloth Bandage
        14530, -- (2000) Heavy Runecloth Bandage
        19061, -- (1360) Alterac Runecloth Bandage
        14529, -- (1360) Runecloth Bandage
        19062, -- (1104) Alterac Heavy Mageweave Bandage
        20067, -- (1104) Arathi Basin Mageweave Bandage
        20234, -- (1104) Warsong Gulch Mageweave Bandage
        8545, -- (1104) Heavy Mageweave Bandage
        19063, -- (800) Alterac Mageweave Bandage
        8544, -- (800) Mageweave Bandage
        19064, -- (640) Alterac Heavy Silk Bandage
        20068, -- (640) Arathi Basin Silk Bandage
        20236, -- (640) Warsong Gulch Silk Bandage
        6451, -- (640) Heavy Silk Bandage
        6450, -- (400) Silk Bandage
        3531, -- (301) Heavy Wool Bandage
        3530, -- (161) Wool Bandage
        2581, -- (114) Heavy Linen Bandage
        1251, -- (66) Linen Bandage
    }
}

----------------------------------------------------------------------
-- Logic
----------------------------------------------------------------------

local updateFrame = CreateFrame("Frame")
updateFrame:Hide()

local function FindBestItemInBag(idList)
    local playerLevel = UnitLevel("player")

    for _, targetID in ipairs(idList) do
        local count = GetItemCount(targetID)
        if count > 0 then
            local isUsable, _ = IsUsableItem(targetID)
            
            if isUsable then
                local _, _, _, _, itemMinLevel = GetItemInfo(targetID)
                
                if itemMinLevel then
                    if playerLevel >= itemMinLevel then
                        return targetID
                    end
                end
            end
        end
    end
    return nil
end

local function UpdateMacros()
    if InCombatLockdown() then return end

    local numAccount, numChar = GetNumMacros()
    local limitAccount = MAX_ACCOUNT_MACROS or 120
    local limitChar = MAX_CHARACTER_MACROS or 18

    for macroName, idList in pairs(itemCategories) do
        local bestID = FindBestItemInBag(idList)
        local newBody = ""
        local icon = "INV_Misc_QuestionMark" 

        if bestID then
            newBody = "#showtooltip item:" .. bestID .. "\n/use item:" .. bestID
        else
            local defaultID = idList[#idList] 
            newBody = "#showtooltip item:" .. defaultID .. "\n/run print('"..macroName.." not found!')"
        end

        local macId = GetMacroIndexByName(macroName)
        
        if macId == 0 then
            if numChar < limitChar then
                CreateMacro(macroName, icon, newBody, 1)
                numChar = numChar + 1
            
            elseif numAccount < limitAccount then
                CreateMacro(macroName, icon, newBody, nil)
                numAccount = numAccount + 1
            else
                print("|cffCC3333" .. addonName .. ": Macro limit reached! Could not create '" .. macroName .. "'.|r")
            end
        else
            local _, _, currentBody = GetMacroBody(macId)
            if currentBody ~= newBody then
                EditMacro(macId, macroName, icon, newBody)
            end
        end
    end
    
    updateFrame:Hide()
end

local THROTTLE_TIME = 0.5
local timeSinceLast = 0

updateFrame:SetScript("OnUpdate", function(self, elapsed)
    timeSinceLast = timeSinceLast + elapsed
    if timeSinceLast >= THROTTLE_TIME then
        if InCombatLockdown() then
            self:Hide()
            timeSinceLast = 0
            return 
        end
        
        UpdateMacros()
        timeSinceLast = 0
    end
end)

local function RequestUpdate()
    if InCombatLockdown() then
        return 
    else
        updateFrame:Show()
    end
end

----------------------------------------------------------------------
-- Events
----------------------------------------------------------------------

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_REGEN_ENABLED" then
        UpdateMacros()
    else
        RequestUpdate()
    end
end)

frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("BAG_UPDATE_DELAYED")
frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_LEVEL_UP")
frame:RegisterEvent("ZONE_CHANGED")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
