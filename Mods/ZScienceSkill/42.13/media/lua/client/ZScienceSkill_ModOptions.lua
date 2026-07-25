-- Mod Options for ZScienceSkill
require "PZAPI/ModOptions"

local MOD_ID = "ZScienceSkill"
local MOD_NAME = "Science, Bitch!"

ZScienceSkillOptions = {}

local function initOptions()
    local options = PZAPI.ModOptions:create(MOD_ID, MOD_NAME)
    
    options:addTickBox("showOverlay", getText("IGUI_ZScienceSkill_ShowOverlay"), true, getText("IGUI_ZScienceSkill_ShowOverlay_Tooltip"))
    options:addTickBox("showResearchedCheckmark", getText("IGUI_ZScienceSkill_ShowResearchedCheckmark"), false, getText("IGUI_ZScienceSkill_ShowResearchedCheckmark_Tooltip"))
    options:addTickBox("showTooltip", getText("IGUI_ZScienceSkill_ShowTooltip"), true, getText("IGUI_ZScienceSkill_ShowTooltip_Tooltip"))
    
    ZScienceSkillOptions.options = options
end

function ZScienceSkillOptions.isOverlayEnabled()
    if not ZScienceSkillOptions.options then return true end
    local opt = ZScienceSkillOptions.options:getOption("showOverlay")
    return opt and opt:getValue()
end

function ZScienceSkillOptions.isResearchedCheckmarkEnabled()
    if not ZScienceSkillOptions.options then return false end
    local opt = ZScienceSkillOptions.options:getOption("showResearchedCheckmark")
    return opt and opt:getValue()
end

function ZScienceSkillOptions.isTooltipEnabled()
    if not ZScienceSkillOptions.options then return true end
    local opt = ZScienceSkillOptions.options:getOption("showTooltip")
    return opt and opt:getValue()
end

Events.OnGameBoot.Add(initOptions)
