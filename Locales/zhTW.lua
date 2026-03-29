local _, ns = ...
local L = ns.L

-- [[ TRADITIONAL CHINESE (zhTW) ]] --
if GetLocale() == "zhTW" then
    L["BRAND"] = "Connoisseur"
    
    -- Macro Names Can't Exceed 16 Total Characters
    L["MACRO_BANDAGE"] = "- 繃帶"
    L["MACRO_FOOD"]    = "- 食物"
    L["MACRO_HPOT"]    = "- 治療藥水"
    L["MACRO_HS"]      = "- 治療石"
    L["MACRO_MGEM"]    = "- 法力寶石"
    L["MACRO_MPOT"]    = "- 法力藥水"
    L["MACRO_SS"]      = "- 靈魂石"
    L["MACRO_WATER"]   = "- 水"

    L["ERR_ZONE"] = "你不能在這裡使用這個。"
    L["RANK"]     = "等級"

    L["MSG_BUG_REPORT"] = "看來你發現了一個錯誤！ %s (%s) 無法在 %s > %s (%s) 使用。請回報此問題以便我們修正。謝謝！ https://discord.gg/eh8hKq992Q"
    L["MSG_NO_ITEM"]    = "在你的背包中找不到合適的 %s。"

    L["MENU_BUFF_FOOD"]      = "優先使用增益食物"
    L["MENU_BUFF_FOOD_DESC"] = "當缺少 \"進食充分\" 增益時，優先使用會給予該增益的食物。"
    L["MENU_CLEAR_IGNORE"]   = "清除忽略清單"
    L["MENU_IGNORE"]         = "忽略"
    L["MENU_RESET"]          = "重置"
    L["MENU_SCAN"]           = "強制掃描"
    L["MENU_TITLE"]          = "消耗品"

    L["MENU_SCROLL_BUFFS"]      = "卷軸增益"
    L["MENU_SCROLL_BUFFS_DESC"] = "當缺少卷軸增益時，在你的食物巨集中使用屬性卷軸。"
    L["MENU_OPTIONS_HINT"]      = "在 選項 > 插件 > Connoisseur 中有更多選項可用。"

    L["PREFIX_MAGE"]    = "法師注意"
    L["PREFIX_WARLOCK"] = "術士注意"

    L["TIP_DOWNRANK"]        = "選取低等級玩家為目標時，巨集會製造適合該等級的物品。"
    L["TIP_MAGE_CONJURE"]    = "右鍵點擊你的食物或水巨集以製造食物或水。"
    L["TIP_MAGE_GEM"]        = "右鍵點擊你的法力寶石巨集以製造一顆新的寶石。再次右鍵點擊以製造一顆低等級備用寶石。"
    L["TIP_MAGE_TABLE"]      = "中鍵點擊以施放召喚餐桌。"
    L["TIP_WARLOCK_CONJURE"] = "右鍵點擊你的治療石或靈魂石巨集以製造治療石或靈魂石。"
    L["TIP_WARLOCK_SOUL"]    = "中鍵點擊以施放靈魂儀式。"

    L["UI_BEST_FOOD"]    = "當前最佳食物"
    L["UI_DISABLED"]     = "已停用"
    L["UI_ENABLED"]      = "已啟用"
    L["UI_IGNORE_LIST"]  = "忽略清單"
    L["UI_LEFT_CLICK"]   = "左鍵點擊"
    L["UI_MIDDLE_CLICK"] = "中鍵點擊"
    L["UI_RIGHT_CLICK"]  = "右鍵點擊"
    L["UI_SHIFT_LEFT"]   = "Shift + 左鍵點擊"
    L["UI_TOGGLE"]       = "切換"

    -- Options Panel
    L["OPTIONS_DESC"]              = "建立巨集以使用你可用的最佳食物、水、藥水、治療石、靈魂石、法力寶石或繃帶。"
    L["OPTIONS_BUFF_FOOD"]         = "優先使用增益食物"
    L["OPTIONS_BUFF_FOOD_DESC"]    = "當缺少 \"進食充分\" 增益時，優先使用會給予該增益的食物。"
    L["OPTIONS_SCROLL_HEADER"]     = "卷軸增益"
    L["OPTIONS_USE_SCROLLS"]       = "包含卷軸增益"
    L["OPTIONS_USE_SCROLLS_DESC"]  = "當缺少卷軸增益時，在你的食物巨集中使用卷軸。"
    L["OPTIONS_SCROLL_TYPES"]      = "在檢查中包含卷軸類型"
    L["OPTIONS_SCROLL_AGILITY"]    = "敏捷"
    L["OPTIONS_SCROLL_INTELLECT"]  = "智力"
    L["OPTIONS_SCROLL_PROTECTION"] = "防護"
    L["OPTIONS_SCROLL_SPIRIT"]     = "精神"
    L["OPTIONS_SCROLL_STAMINA"]    = "耐力"
    L["OPTIONS_SCROLL_STRENGTH"]   = "力量"

    L["OPTIONS_RESET_HEADER"]      = "重置"
    L["OPTIONS_RESET_IGNORE_DESC"] = "從忽略清單中移除所有物品。"
    L["OPTIONS_RESET_IGNORE_CONFIRM"] = "你確定要清除忽略清單嗎？"
    L["OPTIONS_COMMUNITY_HEADER"]  = "回饋與支援"
end