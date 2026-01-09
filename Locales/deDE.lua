local _, ns = ...
local L = ns.L

-- [[ GERMAN (deDE) ]] --
if GetLocale() == "deDE" then
    L["MACRO_FOOD"] = "- Food" -- Intentionally Not Translating These for Now.
    L["MACRO_WATER"] = "- Water" -- Intentionally Not Translating These for Now.
    L["MACRO_HPOT"] = "- Health Potion" -- Intentionally Not Translating These for Now.
    L["MACRO_MPOT"] = "- Mana Potion" -- Intentionally Not Translating These for Now.
    L["MACRO_HS"] = "- Healthstone" -- Intentionally Not Translating These for Now.
    L["MACRO_BANDAGE"] = "- Bandage" -- Intentionally Not Translating These for Now.
    L["MSG_NO_ITEM"] = "Kein geeignetes %s in deinen Taschen gefunden."
    L["ERR_ZONE"] = "Das kannst du hier nicht benutzen."
    L["RANK"] = "Rang"

    L["MSG_BUG_REPORT"] = "Du hast einen Bug gefunden! %s (%s) kann nicht in %s > %s (%s) benutzt werden. Bitte melde dies, damit wir es beheben können. Danke! https://discord.gg/eh8hKq992Q"

    L["MENU_TITLE"] = "Verbrauchsgüter"
    L["MENU_SCAN"] = "Scan erzwingen"
    L["MENU_IGNORE"] = "Ignorieren"
    L["MENU_RESET"] = "Zurücksetzen"
    L["MENU_CLEAR_IGNORE"] = "Ignorierliste löschen"

    L["MENU_BUFF_FOOD"] = "Buff-Essen bevorzugen"
    L["MENU_BUFF_FOOD_DESC"] = "Bevorzugt Essen, das den \"Satt\"-Buff gewährt, wenn der Buff fehlt."

    L["PREFIX_MAGE"] = "Achtung Magier"
    L["PREFIX_WARLOCK"] = "Achtung Hexenmeister"

    L["TIP_MAGE_CONJURE"] = "Rechtsklick auf dein Essen- oder Wasser-Makro, um Essen oder Wasser herbeizuzaubern."
    L["TIP_MAGE_TABLE"] = "Mittelklick, um Tischlein deck dich zu wirken."

    L["TIP_WARLOCK_CONJURE"] = "Rechtsklick auf dein Gesundheitsstein-Makro, um einen Gesundheitsstein herzustellen."
    L["TIP_WARLOCK_SOUL"] = "Mittelklick, um Ritual der Seelen zu wirken."

    L["TIP_DOWNRANK"] = "Wenn du einen Spieler mit niedrigerer Stufe anvisierst, wird das Makro Gegenstände herbeizaubern, die für dessen Stufe angemessen sind."

    L["UI_ENABLED"] = "Aktiviert"
    L["UI_DISABLED"] = "Deaktiviert"
    L["UI_TOGGLE"] = "Umschalten"
    L["UI_BEST_FOOD"] = "Aktuelles bestes Essen"
    L["UI_LEFT_CLICK"] = "Linksklick"
    L["UI_RIGHT_CLICK"] = "Rechtsklick"
    L["UI_MIDDLE_CLICK"] = "Mittelklick"
    L["UI_IGNORE_LIST"] = "Ignorierliste"

    L["SCAN_ALCOHOL"] = "alkoholisches getränk"
    L["SCAN_HEALS"] = "heilt.- ([%d%.]+) punkt"
    L["SCAN_HEALTH"] = "gesundheit"
    L["SCAN_MANA"] = "mana"
    L["SCAN_HYBRID"] = "mana und gesundheit"
    L["SCAN_RESTORES"] = "stellt.- ([%d%.]+) [pmg]"
    L["SCAN_PERCENT"] = "stellt.- (%d+)%%"
    L["SCAN_HPOT_STRICT"] = "stellt (%d+) bis (%d+) punkt.- gesundheit"
    L["SCAN_MPOT_STRICT"] = "stellt (%d+) bis (%d+) punkt.- mana"
    L["SCAN_REQ_FA"] = "benötigt erste hilfe %((%d+)%)"
    L["SCAN_REQ_LEVEL"] = "benötigt stufe (%d+)"
    L["SCAN_SEATED"] = "sitzen bleiben"
    L["SCAN_USE"] = "benutzen:"
    L["SCAN_WELL_FED"] = "satt"
    L["SCAN_LIFE"] = "leben"
end