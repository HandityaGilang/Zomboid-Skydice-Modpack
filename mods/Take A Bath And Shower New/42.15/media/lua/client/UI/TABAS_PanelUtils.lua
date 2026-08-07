local TABAS_PanelUtils = {}

local TABAS_GameTimes = require("TABAS_GameTimes")

local CONST = require("UI/TABAS_PanelConst")
local FONT_HGT_SMALL = CONST.SCALE.HGT_SMALL
local FONT_HGT_MEDIUM = CONST.SCALE.HGT_MEDIUM
local HGT_BUTTON = CONST.SCALE.HGT_BUTTON
local blankColor = CONST.COLOR.blankColor
local TEXTURE = CONST.TEXTURE

function TABAS_PanelUtils.addButton(x, y, width, height, image, title, tooltip, panel, onClick, background)
    local button = ISButton:new(x, y, width, height, title, panel, onClick)
    button.image = image
    button.tooltip = tooltip
    if not background then
        button.displayBackground = false
        button.borderColor = blankColor
        button.backgroundColor = blankColor
        button.backgroundColorMouseOver = blankColor
    end
    button:initialise()
    button:instantiate()
    panel:addChild(button)
    return button, x + width, y + height
end

function TABAS_PanelUtils.addStatusButtonAndLabel(panel, x, y)
    if not panel.status then return x, y end

    local button, label, labelX
    local btnScale = panel.btnScale or FONT_HGT_SMALL
    local labelY = y + btnScale * 1.25
    local index = 1
    for name, status in pairs(panel.status) do
        button = ISButton:new(x, y, btnScale, btnScale, "")
        button:initialise()
        button:setImage(status.texture)
        button:setTooltip(status.tooltip)
        button.displayBackground = false
        panel:addChild(button)

        labelX = x + btnScale/2

        label = ISLabel:new(labelX, labelY, FONT_HGT_SMALL, "", 1, 1, 1, 1, UIFont.Small, false)
        label:initialise()
        label:instantiate()
        label.displayBackground = false
        label.center = true
        label.customData = {x = labelX, y = labelY, value = "-"}
        panel:addChild(label)

        status.button = button
        status.label = label
        status.index = index
        index = index + 1
        x = button:getRight() + btnScale
    end
    return x, y + btnScale + FONT_HGT_SMALL
end

-- function TABAS_PanelUtils.setStatusValue(status, target)
--     if status.label then
--         local label = status.label
--         local value, tooltip = status.func(target)
--         if label.customData.value ~= value then
--             label.customData.value = value
--             label.customData.tooltip = tooltip
--         end
--     end
-- end

function TABAS_PanelUtils.prerenderStatusBox(panel, status)
    local label = status.label
    if not label then return end

    local borderW = panel.btnScale * 1.5
    local borderH = panel.btnScale * 2.2
    local labelW = panel.btnScale * 1.45

    local data = label.customData
    panel:drawTextureScaled(TEXTURE.bg_label, data.x - labelW/2, data.y, labelW, FONT_HGT_SMALL, 0.3, 0.6, 0.6, 0.6)
    panel:drawTextureScaled(TEXTURE.bg_frame, data.x - borderW/2, panel.statusY, borderW, borderH, 1, 0.8, 0.8, 0.8)
end

function TABAS_PanelUtils.renderStatusValue(panel, status)
    local label = status.label
    if not label then return end

    local value = label.customData.value
    local tooltip = label.customData.tooltip
    if value == "true" or value == "false" then
        label:setName("")
        local icon = TEXTURE[value .. "Icon"]
        panel:drawTextureScaled(icon, label.customData.x-FONT_HGT_SMALL/2, label.customData.y, FONT_HGT_SMALL, FONT_HGT_SMALL, 1,1,1,1)
    elseif value == "inf" then
        label:setName("")
        panel:drawTextureScaled(TEXTURE.infinityIcon, label.customData.x-FONT_HGT_SMALL/2, label.customData.y, FONT_HGT_SMALL, FONT_HGT_SMALL, 1,1,1,1)
    else
        label:setName(tostring(value))
    end
    -- if not tooltip then
    --     tooltip = value
    -- end
    -- status.button:setTooltip(status.tooltip .. ": " .. tooltip)
    if not tooltip then tooltip = value end
    local merged = status.tooltip .. ": " .. tostring(tooltip)
    if status._lastBtnTooltip ~= merged then
        status._lastBtnTooltip = merged
        status.button:setTooltip(merged)
    end
end

function TABAS_PanelUtils.renderStatusCached(panel, status)
    local label = status.label
    if not label then return end

    local value = label.customData.value
    if value == "true" or value == "false" then
        label:setName("")
        local icon = TEXTURE[value .. "Icon"]
        panel:drawTextureScaled(icon, label.customData.x-FONT_HGT_SMALL/2, label.customData.y, FONT_HGT_SMALL, FONT_HGT_SMALL, 1,1,1,1)
    elseif value == "inf" then
        label:setName("")
        panel:drawTextureScaled(TEXTURE.infinityIcon, label.customData.x-FONT_HGT_SMALL/2, label.customData.y, FONT_HGT_SMALL, FONT_HGT_SMALL, 1,1,1,1)
    else
        label:setName(value or "")
    end
end

TABAS_PanelUtils.tooltipPool = {}
TABAS_PanelUtils.tooltipsUsed = {}
function TABAS_PanelUtils.addItemTooltip()
    local pool = TABAS_PanelUtils.tooltipPool
    if #pool == 0 then
        table.insert(pool, ISToolTip:new())
    end
    local tooltip = table.remove(pool, #pool)
    tooltip:reset()
    table.insert(TABAS_PanelUtils.tooltipsUsed, tooltip)
    return tooltip
end

function TABAS_PanelUtils.releaseTooltips()
    for _, tooltip in ipairs(TABAS_PanelUtils.tooltipsUsed) do
        table.insert(TABAS_PanelUtils.tooltipPool, tooltip)
    end
    TABAS_PanelUtils.tooltipsUsed = {}
end


local function nowSec()
    return TABAS_GameTimes.getWorldAgeHours() * 3600
end

function TABAS_PanelUtils.refreshStatus(status, target, force, t)
    local label = status.label
    if not label then return false end

    t = t or nowSec()

    local interval = status.interval or 0.25
    status._nextRefresh = status._nextRefresh or 0

    if not force and t < status._nextRefresh then
        return false
    end
    status._nextRefresh = t + interval

    local value, tooltip = status.func(target)
    local data = label.customData
    if data.value ~= value or data.tooltip ~= tooltip then
        data.value = value
        data.tooltip = tooltip
        return true
    end
    return false
end

-- refresh all status in table
function TABAS_PanelUtils.refreshStatusTable(statusTable, target, force)
    local t = nowSec()
    local changed = false
    for _, st in pairs(statusTable) do
        if TABAS_PanelUtils.refreshStatus(st, target, force, t) then
            changed = true
        end
    end
    return changed
end

return TABAS_PanelUtils
