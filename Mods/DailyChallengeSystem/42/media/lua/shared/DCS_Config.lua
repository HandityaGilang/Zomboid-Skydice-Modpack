--! DO NOT SET DCS_Config.USE_NPC = true // IT IS ENTRIELY EXPERIMENTAL, YOU WILL HAVE ISSUES WITH IT !--

DCS_Config = DCS_Config or {}

DCS_Config.USE_NPC = false
DCS_Config.USE_OBJECTS = true

--! DO NOT SET DCS_Config.DEBUG = true // USED BY THE MOD AUTHOR FOR BUG FIXING - IT WILL FLOOD YOUR SERVER AND CLIENTS WITH LOTS OF PRINTS AND HINDER PERFORMANCE !--

DCS_Config.DEBUG = false
function DCS_dprint(...)
    if DCS_Config.DEBUG then print(...) end
end

DCS_Config.RESET_INTERVAL_HOURS = 24

DCS_Config.TEXT = {
    OBJECT = {
        CONTEXT_OPEN_SHOP = "IGUI_DCS_Config_Context_OpenShop",
        CONTEXT_CHALLENGE_DONE = "IGUI_DCS_Config_Context_ChallengeDone",
        CONTEXT_VISIT_COMPLETE = "IGUI_DCS_Config_Context_VisitComplete",
        CONTEXT_QUEST_COMPLETE = "IGUI_DCS_Config_Context_QuestComplete",
        CONTEXT_QUEST_NEED = "IGUI_DCS_Config_Context_QuestNeed",
    },
    NPC = {
        CONTEXT_OPEN_SHOP = "IGUI_DCS_Config_Context_OpenShopNPC",
        CONTEXT_CHALLENGE_DONE = "IGUI_DCS_Config_Context_ChallengeDone",
        CONTEXT_VISIT_COMPLETE = "IGUI_DCS_Config_Context_VisitCompleteNPC",
        CONTEXT_QUEST_COMPLETE = "IGUI_DCS_Config_Context_QuestCompleteNPC",
        CONTEXT_QUEST_NEED = "IGUI_DCS_Config_Context_QuestNeed",
    },
}

function DCS_Config.getText()
    if DCS_Config.USE_OBJECTS then
        return DCS_Config.TEXT.OBJECT
    else
        return DCS_Config.TEXT.NPC
    end
end

return DCS_Config
