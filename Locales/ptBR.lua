local _, ns = ...
local L = ns.L

-- [[ PORTUGUESE (ptBR) ]] --
if GetLocale() == "ptBR" then
    L["BRAND"] = "Connoisseur"
    
    -- Macro Names Can't Exceed 16 Total Characters
    L["MACRO_BANDAGE"] = "- Bandagem"
    L["MACRO_FOOD"]    = "- Comida"
    L["MACRO_HPOT"]    = "- Poção de Cura"
    L["MACRO_HS"]      = "- Pedra"
    L["MACRO_MGEM"]    = "- Gema de Mana"
    L["MACRO_MPOT"]    = "- Poção de Mana"
    L["MACRO_SS"]      = "- Pedra da Alma"
    L["MACRO_WATER"]   = "- Água"

    L["ERR_ZONE"] = "Você não pode usar isso aqui."
    L["RANK"]     = "Grau"

    L["MSG_BUG_REPORT"] = "Parece que você encontrou um erro! %s (%s) não pode ser usado em %s > %s (%s). Por favor reporte isso para que possamos consertar. Obrigado! https://discord.gg/eh8hKq992Q"
    L["MSG_NO_ITEM"]    = "Nenhum %s adequado encontrado em suas bolsas."

    L["MENU_BUFF_FOOD"]      = "Priorizar comida com bônus"
    L["MENU_BUFF_FOOD_DESC"] = "Prioriza comida que concede o bônus \"Bem Alimentado\" quando ele está ausente."
    L["MENU_CLEAR_IGNORE"]   = "Limpar lista de ignorados"
    L["MENU_IGNORE"]         = "Ignorar"
    L["MENU_RESET"]          = "Redefinir"
    L["MENU_SCAN"]           = "Forçar verificação"
    L["MENU_TITLE"]          = "Consumíveis"

    L["MENU_SCROLL_BUFFS"]      = "Bônus de Pergaminho"
    L["MENU_SCROLL_BUFFS_DESC"] = "Usa pergaminhos de atributos como parte de sua macro de Comida quando o bônus do pergaminho está ausente."
    L["MENU_OPTIONS_HINT"]      = "Opções adicionais disponíveis em Opções > AddOns > Connoisseur."

    L["PREFIX_MAGE"]    = "Atenção Magos"
    L["PREFIX_WARLOCK"] = "Atenção Bruxos"

    L["TIP_DOWNRANK"]        = "Selecionar um jogador de nível mais baixo fará a macro conjurar itens apropriados para o nível dele."
    L["TIP_MAGE_CONJURE"]    = "Clique com o botão direito nas macros de Comida ou Água para criar Comida ou Água."
    L["TIP_MAGE_GEM"]        = "Clique com o botão direito na macro de Gema de Mana para conjurar uma nova gema. Clique com o botão direito novamente para conjurar uma gema de grau inferior como reserva."
    L["TIP_MAGE_TABLE"]      = "Clique com o botão do meio para lançar Ritual de Refeição."
    L["TIP_WARLOCK_CONJURE"] = "Clique com o botão direito nas macros de Pedra de Vida ou Pedra da Alma para criar uma Pedra de Vida ou Pedra da Alma."
    L["TIP_WARLOCK_SOUL"]    = "Clique com o botão do meio para lançar Ritual das Almas."

    L["UI_BEST_FOOD"]    = "Melhor comida atual"
    L["UI_DISABLED"]     = "Desativado"
    L["UI_ENABLED"]      = "Ativado"
    L["UI_IGNORE_LIST"]  = "Lista de ignorados"
    L["UI_LEFT_CLICK"]   = "Clique Esquerdo"
    L["UI_MIDDLE_CLICK"] = "Clique do Meio"
    L["UI_RIGHT_CLICK"]  = "Clique Direito"
    L["UI_SHIFT_LEFT"]   = "Shift + Clique Esquerdo"
    L["UI_TOGGLE"]       = "Alternar"

    -- Options Panel
    L["OPTIONS_DESC"]              = "Cria macros para usar a melhor comida, água, poções, pedras de vida, pedras da alma, gemas de mana ou bandagens disponíveis para você."
    L["OPTIONS_BUFF_FOOD"]         = "Priorizar comida com bônus"
    L["OPTIONS_BUFF_FOOD_DESC"]    = "Prioriza comida que concede o bônus \"Bem Alimentado\" quando ele está ausente."
    L["OPTIONS_SCROLL_HEADER"]     = "Bônus de Pergaminho"
    L["OPTIONS_USE_SCROLLS"]       = "Incluir Bônus de Pergaminho"
    L["OPTIONS_USE_SCROLLS_DESC"]  = "Usa pergaminhos, quando o bônus do pergaminho está ausente, como parte de sua macro de Comida."
    L["OPTIONS_SCROLL_TYPES"]      = "Incluir Tipos de Pergaminho na Verificação"
    L["OPTIONS_SCROLL_AGILITY"]    = "Agilidade"
    L["OPTIONS_SCROLL_INTELLECT"]  = "Intelecto"
    L["OPTIONS_SCROLL_PROTECTION"] = "Proteção"
    L["OPTIONS_SCROLL_SPIRIT"]     = "Espírito"
    L["OPTIONS_SCROLL_STAMINA"]    = "Vigor"
    L["OPTIONS_SCROLL_STRENGTH"]   = "Força"

    L["OPTIONS_RESET_HEADER"]      = "Redefinir"
    L["OPTIONS_RESET_IGNORE_DESC"] = "Remove todos os itens da lista de ignorados."
    L["OPTIONS_RESET_IGNORE_CONFIRM"] = "Tem certeza de que deseja limpar a lista de ignorados?"
    L["OPTIONS_COMMUNITY_HEADER"]  = "Feedback e Suporte"
end