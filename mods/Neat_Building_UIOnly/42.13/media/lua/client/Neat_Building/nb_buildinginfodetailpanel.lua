require "ISUI/ISPanel"

NB_BuildingInfoDetailPanel = ISPanel:derive("NB_BuildingInfoDetailPanel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingInfoDetailPanel:initialise()
    ISPanel.initialise(self)
end

function NB_BuildingInfoDetailPanel:new(x, y, width, height, BuildingInfoPanel)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.BuildingInfoPanel = BuildingInfoPanel
    o.logic = BuildingInfoPanel.logic
    o.player = BuildingInfoPanel.player
    o.padding = BuildingInfoPanel.padding
    o.minimumHeight = FONT_HGT_SMALL * 3 + o.padding * 4
    o.minimumWidth = BuildingInfoPanel.minimumWidth
    
    return o
end

function NB_BuildingInfoDetailPanel:calculateLayout(_preferredWidth, _preferredHeight)
    local width = math.max(self.minimumWidth, _preferredWidth or 0)
    local height = math.max(self.minimumHeight, 0)

    local infoheight = self.padding
    local tooltipInfo = self:getTooltipInfo()
    if tooltipInfo then
        local textWidth = width - self.padding * 2
        local wrappedText = getTextManager():WrapText(UIFont.Small, tooltipInfo.text, textWidth)
        local lineCount = 0
        for _ in string.gmatch(wrappedText, "[^\n]+") do
            lineCount = lineCount + 1
        end
        infoheight = infoheight + lineCount * FONT_HGT_SMALL + self.padding
    end

    local skills = self:getSkillRequirements()
    infoheight = infoheight + FONT_HGT_SMALL * #skills + self.padding

    height = math.max(infoheight, height)

    self:setWidth(width)
    self:setHeight(height)
end

-- ----------------------------------------------------------------------------------------------------- --
-- Recipe Info
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingInfoDetailPanel:getSkillRequirements()

    if not self.logic:getRecipe() then return {} end
    local recipe = self.logic:getRecipe()
    
    local skills = {}
    local requiredSkillCount = recipe:getRequiredSkillCount()
    
    for i = 0, requiredSkillCount - 1 do
        local requiredSkill = recipe:getRequiredSkill(i)
        local skillName = requiredSkill:getPerk():getName()
        local skillLevel = requiredSkill:getLevel()
        local playerLevel = self.player:getPerkLevel(requiredSkill:getPerk())
        local isMet = playerLevel >= skillLevel
        
        table.insert(skills, {
            name = skillName,
            requiredLevel = skillLevel,
            isMet = isMet
        })
    end
    
    return skills
end

function NB_BuildingInfoDetailPanel:getTooltipInfo()
    if not self.logic:getRecipe() then return {} end
    local recipe = self.logic:getRecipe()
    
    local tooltipKey = recipe:getTooltip()
    if not tooltipKey then return nil end

    local tooltipText = getText(tooltipKey)
    if not tooltipText or tooltipText == "" then return nil end
    
    return {
        text = tooltipText,
        key = tooltipKey
    }
end

-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingInfoDetailPanel:prerender()
    local panelBG = NinePatchTexture.getSharedTexture("media/ui/Neat_Building/Panel/InnerPanel_BG.png")
    local spacing = self.padding / 2
    if panelBG then
        panelBG:render(self:getAbsoluteX() + spacing, self:getAbsoluteY() + spacing, self.width - spacing*2, self.height - spacing*2, 0.1, 0.1, 0.1, 0.5)
    end
end

function NB_BuildingInfoDetailPanel:render()
    if not self.logic:getRecipe() then return end
    local recipe = self.logic:getRecipe()

    local currentY = self.padding
    if recipe:getTooltip() then
        local tooltipText = getText(recipe:getTooltip())
        local textWidth = self.width - self.padding * 2
        local wrappedText = getTextManager():WrapText(UIFont.Small, tooltipText, textWidth)

        local lines = {}
        for line in string.gmatch(wrappedText, "[^\n]+") do
            table.insert(lines, line)
        end
        
        for _, line in ipairs(lines) do
            self:drawText(line, self.padding, currentY, 1, 1, 1, 1, UIFont.Small)
            currentY = currentY + FONT_HGT_SMALL
        end

        currentY = currentY + self.padding
    end

    -- draw skills require
    local skills = self:getSkillRequirements()
    if #skills == 0 then return end

    local maxTextWidth = self.width - self.padding *2

    for _, skill in ipairs(skills) do
        local x = self.padding
        local r, g, b = skill.isMet and 0.2 or 1.0, skill.isMet and 0.8 or 0.2, 0.2

        local textX = x
        local skillText = string.format("LV%d %s", skill.requiredLevel, skill.name)
        local truncatedText = NeatTool.truncateText(skillText, maxTextWidth, UIFont.Small, "...")
        
        self:drawText(truncatedText, textX, currentY, r, g, b, 1, UIFont.Small)
        currentY = currentY + FONT_HGT_SMALL
    end
end

return NB_BuildingInfoDetailPanel