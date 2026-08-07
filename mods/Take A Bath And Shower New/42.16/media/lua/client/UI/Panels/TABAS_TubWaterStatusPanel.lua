require("ISUI/ISPanel")
require("UI/TABAS_PanelConst")

TABAS_TubWaterStatusPanel = ISPanel:derive("TABAS_TubWaterStatusPanel")

local TABAS_Utils = require("TABAS_Utils")
local TABAS_Panel = require("UI/TABAS_PanelUtils")

local CONST = require("UI/TABAS_PanelConst")
local FONT_HGT_SMALL = CONST.SCALE.HGT_SMALL
local HGT_BUTTON = CONST.SCALE.HGT_BUTTON
local BORDER_SPACING = CONST.SCALE.BORDER_SPACING

function TABAS_TubWaterStatusPanel:initialise()
    ISPanel.initialise(self)
end

function TABAS_TubWaterStatusPanel:createChildren()
    self.status = {
        capacity = {
            texture = CONST.TEXTURE.tub_capacity,
            tooltip = getText("IGUI_TABAS_BathtubInfo_Capacity"),
            func = TABAS_TubWaterStatusPanel.getCapacity
        },
        amount = {
            texture = CONST.TEXTURE.tub_amount,
            tooltip = getText("IGUI_TABAS_BathtubInfo_Amount"),
            func = TABAS_TubWaterStatusPanel.getAmount
        },
        lastUpdate = {
            texture = CONST.TEXTURE.tub_lastUpdate,
            tooltip = getText("IGUI_TABAS_BathtubInfo_LastUpdate"),
            func = TABAS_TubWaterStatusPanel.getLastUpdate
        },
        dirtyLevel = {
            texture = CONST.TEXTURE.tub_dirtyLevel,
            tooltip = getText("IGUI_TABAS_BathtubInfo_Dirty"),
            func = TABAS_TubWaterStatusPanel.getDirtyLevel
        },
    }
    self.statusY = FONT_HGT_SMALL + BORDER_SPACING*2
    local y = self.statusY + BORDER_SPACING
    local x = BORDER_SPACING + self.btnScale/2

    TABAS_Panel.addStatusButtonAndLabel(self, x, y)
    self:setHeight(y + self.btnScale + FONT_HGT_SMALL + BORDER_SPACING*4)
end

function TABAS_TubWaterStatusPanel.getCapacity(tfc)
    if not tfc:hasFluidContainer() then
        return "-"
    end
    return tostring(tfc:getCapacity()) .. " L"
end

function TABAS_TubWaterStatusPanel.getAmount(tfc)
    if not tfc:hasFluidContainer() then
        return "-"
    end
    return tostring(round(tfc:getAmount(), 1)) .. " L"
end

function TABAS_TubWaterStatusPanel.getLastUpdate(tfc)
    if not tfc:hasFluidContainer() or not tfc:hasFluid() then
        return "-", ""
    end

    local value = "-"
    local tooltip = ""
    local lastUpdate =  tfc:getWaterData("lastUpdate")
    local min, hour, day = TABAS_Utils.getDifferentialTime(lastUpdate)

    if hour and hour > 48 then
        return "48 h", getText("IGUI_TABAS_BathtubInfo_LastUpdateMoreThanHours", hour)
    else
        if min and min > 0 then
            min = math.ceil(min / 10) * 10
            value = min .. " m"
        end
        if hour and hour > 0 then
            value = hour .. " h"
            if hour > 1 then
                tooltip = getText("IGUI_TABAS_BathtubInfo_LastUpdateTimes", hour, min)
            else
                tooltip = getText("IGUI_TABAS_BathtubInfo_LastUpdateTime", hour, min)
            end
        else
            tooltip = getText("IGUI_TABAS_BathtubInfo_LastUpdateMinutes", min)
        end
        return tostring(value), tooltip
    end
end

function TABAS_TubWaterStatusPanel.getDirtyLevel(tfc)
    return tfc:getDirtyLevelString()
end

function TABAS_TubWaterStatusPanel:prerender()
    -- ISPanel.prerender(self)
    self:drawTextCentre(self.title, self:getWidth() / 2, BORDER_SPACING, self.labelColor.r, self.labelColor.g, self.labelColor.b, self.labelColor.a, UIFont.Small)
    for k, v in pairs(self.status) do
        TABAS_Panel.prerenderStatusBox(self, v)
    end
end

function TABAS_TubWaterStatusPanel:update()
    if self._managedByParent then return end
    TABAS_Panel.refreshStatusTable(self.status, self.tfc_Base, false)
end

function TABAS_TubWaterStatusPanel:render()
    ISPanel.render(self)
    for _, v in pairs(self.status) do
        TABAS_Panel.renderStatusValue(self, v)
    end
end

function TABAS_TubWaterStatusPanel:refreshStatus(force)
    TABAS_Panel.refreshStatusTable(self.status, self.tfc_Base, force == true)
end

function TABAS_TubWaterStatusPanel:refreshNow()
    TABAS_Panel.refreshStatusTable(self.status, self.tfc_Base, true)
end

function TABAS_TubWaterStatusPanel:new (x, y, player, tfc_Base)
    local btnScale = HGT_BUTTON * 1.5
    local width = btnScale * 8 + BORDER_SPACING*2
    local height = btnScale + FONT_HGT_SMALL + BORDER_SPACING * 4 + BORDER_SPACING * 2
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.x = x
    o.y = y
    o.labelColor = {r=0.8,g=0.8,b=0.5,a=1}
    o.title = getText("IGUI_TABAS_BathtubInfo_TubWaterStatus")
    o.width = width
    o.height = height
    o.btnScale = btnScale
    o.playerObj = player
    o.tfc_Base = tfc_Base
    return o
end
