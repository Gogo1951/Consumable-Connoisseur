local _, ns = ...
local L = ns.L

-- [[ SPANISH (esES) ]] --
if GetLocale() == "esES" then
    L["BRAND"] = "Connoisseur"

    -- Macro Names Can't Exceed 16 Total Characters
    L["MACRO_BANDAGE"] = "- Venda"
    L["MACRO_FOOD"]    = "- Comida"
    L["MACRO_HPOT"]    = "- Poc. Salud"
    L["MACRO_HS"]      = "- Piedra"
    L["MACRO_MGEM"]    = "- Gema de maná"
    L["MACRO_MPOT"]    = "- Poc. Maná"
    L["MACRO_SS"]      = "- Piedra de alma"
    L["MACRO_WATER"]   = "- Agua"

    L["ERR_ZONE"] = "No puedes usar eso aquí."
    L["RANK"]     = "Rango"

    L["MSG_BUG_REPORT"] = "¡Parece que encontraste un error! %s (%s) no se puede usar en %s > %s (%s). Por favor repórtalo para que podamos arreglarlo. ¡Gracias! https://discord.gg/eh8hKq992Q"
    L["MSG_NO_ITEM"]    = "No se encontró ningún %s adecuado en tus bolsas."

    L["MENU_BUFF_FOOD"]      = "Priorizar comida con beneficios"
    L["MENU_BUFF_FOOD_DESC"] = "Prioriza la comida que otorga el beneficio \"Bien alimentado\" cuando te falta."
    L["MENU_CLEAR_IGNORE"]   = "Borrar lista de ignorados"
    L["MENU_IGNORE"]         = "Ignorar"
    L["MENU_RESET"]          = "Reiniciar"
    L["MENU_SCAN"]           = "Forzar escaneo"
    L["MENU_TITLE"]          = "Consumibles"

    L["MENU_SCROLL_BUFFS"]      = "Beneficios de pergaminos"
    L["MENU_SCROLL_BUFFS_DESC"] = "Usa pergaminos de atributos como parte de tu macro de Comida cuando falta el beneficio."
    L["MENU_OPTIONS_HINT"]      = "Opciones adicionales disponibles en Opciones > Accesorios > Connoisseur."

    L["PREFIX_MAGE"]    = "Atención Magos"
    L["PREFIX_WARLOCK"] = "Atención Brujos"

    L["TIP_DOWNRANK"]        = "Seleccionar a un jugador de menor nivel hará que la macro conjure objetos apropiados para su nivel."
    L["TIP_MAGE_CONJURE"]    = "Clic derecho en tus macros de Comida o Agua para crear Comida o Agua."
    L["TIP_MAGE_GEM"]        = "Clic derecho en tu macro de Gema de maná para conjurar una nueva gema. Vuelve a hacer clic derecho para conjurar una gema de rango inferior como respaldo."
    L["TIP_MAGE_TABLE"]      = "Clic central para lanzar Ritual de refrigerio."
    L["TIP_WARLOCK_CONJURE"] = "Clic derecho en tus macros de Piedra de salud o Piedra de alma para crear una Piedra de salud o Piedra de alma."
    L["TIP_WARLOCK_SOUL"]    = "Clic central para lanzar Ritual de almas."

    L["UI_BEST_FOOD"]    = "Mejor comida actual"
    L["UI_DISABLED"]     = "Desactivado"
    L["UI_ENABLED"]      = "Activado"
    L["UI_IGNORE_LIST"]  = "Lista de ignorados"
    L["UI_LEFT_CLICK"]   = "Clic izquierdo"
    L["UI_MIDDLE_CLICK"] = "Clic central"
    L["UI_RIGHT_CLICK"]  = "Clic derecho"
    L["UI_SHIFT_LEFT"]   = "Shift + Clic izquierdo"
    L["UI_TOGGLE"]       = "Alternar"

    -- Options Panel
    L["OPTIONS_DESC"]              = "Crea macros para usar la mejor comida, agua, pociones, piedras de salud, piedras de alma, gemas de maná o vendas que tengas disponibles."
    L["OPTIONS_BUFF_FOOD"]         = "Priorizar comida con beneficios"
    L["OPTIONS_BUFF_FOOD_DESC"]    = "Prioriza la comida que otorga el beneficio \"Bien alimentado\" cuando te falta."
    L["OPTIONS_SCROLL_HEADER"]     = "Beneficios de pergaminos"
    L["OPTIONS_USE_SCROLLS"]       = "Incluir beneficios de pergaminos"
    L["OPTIONS_USE_SCROLLS_DESC"]  = "Usa pergaminos, cuando falta el beneficio del pergamino, como parte de tu macro de Comida."
    L["OPTIONS_SCROLL_TYPES"]      = "Incluir tipos de pergaminos en la comprobación"
    L["OPTIONS_SCROLL_AGILITY"]    = "Agilidad"
    L["OPTIONS_SCROLL_INTELLECT"]  = "Intelecto"
    L["OPTIONS_SCROLL_PROTECTION"] = "Protección"
    L["OPTIONS_SCROLL_SPIRIT"]     = "Espíritu"
    L["OPTIONS_SCROLL_STAMINA"]    = "Aguante"
    L["OPTIONS_SCROLL_STRENGTH"]   = "Fuerza"

    L["OPTIONS_RESET_HEADER"]      = "Reiniciar"
    L["OPTIONS_RESET_IGNORE_DESC"] = "Eliminar todos los objetos de la lista de ignorados."
    L["OPTIONS_RESET_IGNORE_CONFIRM"] = "¿Estás seguro de que quieres borrar la lista de ignorados?"
    L["OPTIONS_COMMUNITY_HEADER"]  = "Comentarios y soporte"
end