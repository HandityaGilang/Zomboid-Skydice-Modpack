require("ISUI/ISPanel")

TABAS_TubStatusPanel = ISPanel:derive("TABAS_TubStatusPanel")

local TABAS_Iso = require("TABAS_Iso")
local WaterReader = require("TABAS_WaterReader")
local TABAS_Panel = require("UI/TABAS_PanelUtils")

local CONST = require("UI/TABAS_PanelConst")
local FONT_HGT_SMALL = CONST.SCALE.HGT_SMALL
local HGT_BUTTON = CONST.SCALE.HGT_BUTTON
local BORDER_SPACING = CONST.SCALE.BORDER_SPACING


function TABAS_TubStatusPanel:initialise()
    ISPanel.initialise(self)
end

function TABAS_TubStatusPanel:createChildren()
    self.status = {
        powered = {
            texture =  CONST.TEXTURE.powerdIcon,
            tooltip = getText("IGUI_TABAS_BathtubInfo_Powered"),
            func = TABAS_TubStatusPanel.getPowered,
        },
        piped = {
            texture =  CONST.TEXTURE.pipedIcon,
            tooltip = getText("IGUI_TABAS_BathtubInfo_Piped"),
            func = TABAS_TubStatusPanel.getPiped
        },
        -- totalCapacity = {
        --     texture =  getTexture("media/ui/Icons/tabas_totalCapacity.png"),
        --     tooltip = getText("IGUI_TABAS_BathtubInfo_Capacity"),
        --     func = TABAS_TubStatusPanel.getTotalCapacity
        -- },
        faucet = {
            texture =  CONST.TEXTURE.faucetIcon,
            tooltip = getText("IGUI_TABAS_BathtubInfo_FaucetAmount"),
            func = TABAS_TubStatusPanel.getFaucetAmount
        },
    }
    self.statusY = FONT_HGT_SMALL + BORDER_SPACING*2
    local y = self.statusY + BORDER_SPACING
    local x = BORDER_SPACING + self.btnScale/2

    TABAS_Panel.addStatusButtonAndLabel(self, x, y)
    self:setHeight(y + self.btnScale + FONT_HGT_SMALL + BORDER_SPACING*4)
end

function TABAS_TubStatusPanel.getPowered(bathObj)
    return tostring(TABAS_Iso.canHot(bathObj))
end

function TABAS_TubStatusPanel.getPiped(bathObj)
    local waterSourceCount = WaterReader.getExternalContainerCount(bathObj)
    if bathObj:getFluidAmount() >= 9999 and (waterSourceCount == 0 and not bathObj:getModData().canBeWaterPiped) then
        return "true"
    elseif waterSourceCount == 0 then
        return "false", "0"
    else
        return tostring(waterSourceCount)
    end
end

-- function TABAS_TubStatusPanel.getTotalCapacity(bathObj)
--     local capacity = WaterReader.getWaterCapacity(bathObj)
--     return tostring(capacity) .. " L"
-- end

function TABAS_TubStatusPanel.getFaucetAmount(bathObj)
    local amount =  WaterReader.getWaterAmount(bathObj)
    if amount >= 9999 then
        return "inf", getText("Tooltip_WaterUnlimited")
    end
    return tostring(round(amount,1)) .. " L"
end

function TABAS_TubStatusPanel:isCanHot()
    return TABAS_Iso.canHot(self.bathObject)
end

function TABAS_TubStatusPanel:isPiped()
    local waterSourceCount = WaterReader.getExternalContainerCount(self.bathObject)
    if self.bathObject:getFluidAmount() >= 9999
    and waterSourceCount == 0
    and not self.bathObject:getModData().canBeWaterPiped then
        return true
    end
    return waterSourceCount > 0
end

function TABAS_TubStatusPanel:getFaucetWater()
    return WaterReader.getWaterAmount(self.bathObject) or 0
end

function TABAS_TubStatusPanel:prerender()
    -- ISPanel.prerender(self)
    self:drawTextCentre(self.title, self:getWidth() / 2, BORDER_SPACING, self.labelColor.r, self.labelColor.g, self.labelColor.b, self.labelColor.a, UIFont.Small)
    for k, v in pairs(self.status) do
        TABAS_Panel.prerenderStatusBox(self, v)
    end
end

function TABAS_TubStatusPanel:update()
    if self._managedByParent then return end
    TABAS_Panel.refreshStatusTable(self.status, self.bathObject, false)
end

function TABAS_TubStatusPanel:render()
    ISPanel.render(self)
    for _, v in pairs(self.status) do
        TABAS_Panel.renderStatusValue(self, v)
    end
end

function TABAS_TubStatusPanel:refreshStatus(force)
    if not self.status then return end
    TABAS_Panel.refreshStatusTable(self.status, self.bathObject, force == true)
end


function TABAS_TubStatusPanel:new (x, y, player, tfc_Base)
    local btnScale = HGT_BUTTON * 1.5
    local width = btnScale * 8 + BORDER_SPACING*2
    local height = btnScale + FONT_HGT_SMALL + BORDER_SPACING * 4 + BORDER_SPACING * 2
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.x = x
    o.y = y
    o.labelColor = CONST.COLOR.labelColor
    o.title = getText("IGUI_TABAS_BathtubInfo_TubStatus")
    o.width = width
    o.height = height
    o.btnScale = btnScale
    o.player = player
    o.tfc_Base = tfc_Base
    o.bathObject = tfc_Base.bathObject
    return o
end
