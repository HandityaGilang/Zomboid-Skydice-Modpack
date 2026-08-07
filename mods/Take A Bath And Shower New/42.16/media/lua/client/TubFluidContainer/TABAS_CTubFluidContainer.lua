local TFC_Base = require("TubFluidContainer/TABAS_TubFluidContainerBase")
local CTubFluidContainer = TFC_Base:derive("CTubFluidContainer")

local TABAS_Utils = require("TABAS_Utils")
local TFC_Utils = require("TubFluidContainer/TABAS_TubFluidContainerSystemUtils")

function CTubFluidContainer:new(x, y, z, _bathObject)
    local o = TFC_Base.new(self, x, y, z, _bathObject)
    return o
end

function CTubFluidContainer:init()
    TFC_Base.init(self)
end

function CTubFluidContainer:initNew()
    -- Check and assign the sprite table name. And set Linked if necessary.
end

--------------------- Misc (Client only) ---------------------

function CTubFluidContainer:getTfcName()
    if not self.tfcObject then return nil end
    if self.tfcObject:getSprite() then
        local props = self.tfcObject:getSprite():getProperties()
        if props and props:get("GroupName") then
            local gName = props:get("GroupName")
            local cName = props:get("CustomName")
            return gName .. " " .. cName
        end
    end
    return nil
end

function CTubFluidContainer:getDirtyLevelString()
    local dirtyLevel = self:getWaterData("dirtyLevel")
    if dirtyLevel and not self:isEmpty() then
        if not TABAS_Utils.ModOptionsValue("DisplayTubWaterDirtyLevel") then
            if dirtyLevel >= 50 then
                return getText("IGUI_TABAS_BathtubInfo_WaterFilthy")
            elseif dirtyLevel >= 20 then
                return getText("IGUI_TABAS_BathtubInfo_WaterDirty")
            else
                return getText("IGUI_TABAS_BathtubInfo_WaterClean")
            end
        else
            return tostring(dirtyLevel or 0)
        end
    else
        return "-"
    end
end

function CTubFluidContainer:getTakeBathWarningText(firstLine)
    local text = ""
    local notAvailable = false
    local lineBreak = firstLine or " <LINE> "
    if not self:canTakeBath() then
        text = lineBreak .. "*<RGB:1,0.5,0.5>" .. getText("ContextMenu_TABAS_NotEnoughWater")
        return text, true
    end

    if self:isDirtyWater() then
        text = text .. lineBreak .. "*" .. getText("ContextMenu_TABAS_TubWaterDirty")
        lineBreak = " <LINE> "
    end

    if self:isLowWater() then
        text = text .. lineBreak .. "*" .. getText("ContextMenu_TABAS_NotEnoughWaterTakeBath")
        lineBreak = " <LINE> "
    end

    local temperature = self:getWaterTemperature()
    if temperature > 45 then
        text = text .. lineBreak .. "*" .. getText("ContextMenu_TABAS_TooHot")
        notAvailable = true
    end

    return text, notAvailable
end

function CTubFluidContainer:canTakeBath()
    local levelKey = self:getWaterLevelKey()
    return levelKey and levelKey ~= "empty" and levelKey ~= "low"
end

function CTubFluidContainer:canAddBathSalt(bathSaltType)
    if not self:hasFluid() then return false end
    local cur = self:getWaterData("bathSalt")
    if not cur then return true end

    if cur == bathSaltType then
        local fluidContainer = self:getTubFluidContainer()
        if fluidContainer and fluidContainer:isMixture() then
            return true
        end
    end
    return false
end

return CTubFluidContainer