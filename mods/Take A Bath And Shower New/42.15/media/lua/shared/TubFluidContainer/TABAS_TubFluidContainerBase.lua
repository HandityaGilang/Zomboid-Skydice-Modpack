require "ISBaseObject"
require "TubFluidContainer/TABAS_TubFluidContainerSystemData"

local TFC_Base = ISBaseObject:derive("TFC_Base")

local TFC_Utils = require("TubFluidContainer/TABAS_TubFluidContainerSystemUtils")
local TABAS_Iso = require("TABAS_Iso")

function TFC_Base:new(x, y, z, _isoBathObject)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.x = x
    o.y = y
    o.z = z
    o.bathObject = _isoBathObject or TABAS_Iso.getBathObjectAt(x,y,z)
    if not o.bathObject then
        TFC_Utils.noise("Not found bath object!", tostring(x), tostring(y), tostring(z))
    end

    o.facing = TABAS_Iso.getObjectFacing(o.bathObject)
    o.linkedBathObject = nil
    o.linkedX = 0
    o.linkedY = 0
    o.sprites = {}
    o:init()

    return o
end


--------------------- init ---------------------

function TFC_Base:init()
    self:initNew()
    self.tfcObject, self.linkedTfcObject = self:getTfcObject()
    if self.tfcObject then
       self.fluidContainer = self:getTubFluidContainer()
    end
end

function TFC_Base:initNew()
    -- Check and assign the sprite table name. And set Linked if necessary.
    -- self.sprites.tableKey = "BathWater"
end

function TFC_Base:confirmLinkedObject()
    if not self.linkedBathObject or ((self.tfcObject and not self.linkedTfcObject) or (not self.tfcObject and self.linkedTfcObject)) then
        return false
    end
    return true
end

--------------------- Basic Getter ---------------------

function TFC_Base:getSquare()
    if not self.square then
        self.square = getCell():getGridSquare(self.x, self.y, self.z)
    end
    return self.square
end

function TFC_Base:getLinkedSquare()
    if not self:hasLinked() then return nil end
    if not self.linkedSquare then
        self.linkedSquare = getCell():getGridSquare(self.linkedX, self.linkedY, self.z)
    end
    return self.linkedSquare
end

function TFC_Base:getTfcObject()
    local mainObj = TFC_Utils.getTfcObject(self.x, self.y, self.z)
    local linkedObj = TFC_Utils.getTfcObject(self.linkedX, self.linkedY, self.z)
    return mainObj, linkedObj
end

function TFC_Base:refreshTfcRefs()
    local mainObj, linkedObj = self:getTfcObject()

    if mainObj ~= self.tfcObject then
        self.tfcObject = mainObj
        self.linkedTfcObject = linkedObj
        self.fluidContainer = nil
    end
end

--------------------- Handle Global Data  ---------------------

function TFC_Base:getRegisteredData()
    return TFC_Utils.getTFCData(self.x, self.y, self.z, "Registered")
end

function TFC_Base:updateRegisteredField(key, value, bTransmit)
    if isClient() then return false end
    if not TFC_Utils.isRegisteredKey(key) then return false end
    return TFC_Utils.syncData(self.x, self.y, self.z, TFC_Utils.Registered, key, value, bTransmit)
end

function TFC_Base:shouldDeferRegisteredSync(key)
    if isClient() then return false end
    if not TFC_Utils.shouldDeferRegisteredKeySync(key) then
        return false
    end
    -- During fill/empty/reheat, SyncManager refreshes the client snapshot.
    -- Skip per-tick Registered transmit for the hottest fields.
    return self:isActivated()
end

--------------------- TFC Activate  ---------------------
-- @prams string state - 'fill' or 'empty' or 'reheat'
-- state is nil then any activated.
function TFC_Base:isActivated(state)
    local data = self:getActivatedData()
    if not data or not data.activate then return false end
    if not state then return true end
    return data.state == state
end

function TFC_Base:getActivatedData()
    return TFC_Utils.getTFCData(self.x, self.y, self.z, "Activated")
end

--------------------- Object Mod Data  ---------------------

function TFC_Base:getWaterData(key)
    if not self:hasTfc() then return end
    local md = self.tfcObject:getModData()
    if md[key] ~= nil then
        return md[key]
    end
    return nil
end

function TFC_Base:setWaterData(key, value, bTransmit)
    if not self:hasTfc() then return end
    local md = self.tfcObject:getModData()
    if md[key] == value then
        return false
    end
    md[key] = value
    self.tfcObject:setModData(md)

    self:updateRegisteredField(key, value, not self:shouldDeferRegisteredSync(key))
    if bTransmit then
        self.tfcObject:transmitModData()
    end
    return true
end

function TFC_Base:setLinkedWaterData(key, value, bTransmit)
    if not self.linkedTfcObject then return end
    local md = self.linkedTfcObject:getModData()
    if md[key] == value then
        return false
    end
    md[key] = value
    self.linkedTfcObject:setModData(md)
    if bTransmit then
        self.linkedTfcObject:transmitModData()
    end
    return true
end

function TFC_Base:getBathData(key)
    if not self.bathObject:isExistInTheWorld() then return end
    local md = self.bathObject:getModData()
    if md[key] then
        return md[key]
    end
    return nil
end

function TFC_Base:setBathData(key, value, bTransmit)
    if not self.bathObject:isExistInTheWorld() then return end
    local md = self.bathObject:getModData()
    if md[key] == value then
        return false
    end
    md[key] = value
    self.bathObject:setModData(md)
    if bTransmit then
        self.bathObject:transmitModData()
    end
    return true
end

function TFC_Base:hasLinked()
    return self.linkedBathObject ~= nil and (self.linkedX ~= 0 and self.linkedY ~= 0)
end

--------------------- TFC Object  ---------------------

function TFC_Base:hasTfc()
    self:refreshTfcRefs()
    return self.tfcObject ~= nil
end

--------------------- Fluid Container  ---------------------

function TFC_Base:hasFluidContainer()
    return self:getTubFluidContainer() ~= nil
end

function TFC_Base:getTubFluidContainer()
    self:refreshTfcRefs()
    if not self.tfcObject or not self.tfcObject:isExistInTheWorld() then
        self.fluidContainer = nil
        return nil
    end
    local fluidContainer = self.tfcObject:getComponent(ComponentType.FluidContainer)
    self.fluidContainer = fluidContainer
    return fluidContainer
end

function TFC_Base:hasFluid()
    local fluidContainer = self:getTubFluidContainer()
    if not fluidContainer then return false end
    return fluidContainer:getAmount() > 0
end

function TFC_Base:getAmount()
    local fluidContainer = self:getTubFluidContainer()
    if not fluidContainer then return 0 end
    return fluidContainer:getAmount()
end

function TFC_Base:getPrimaryFluid()
    local fluidContainer = self:getTubFluidContainer()
    if not fluidContainer then return nil end
    return fluidContainer:getPrimaryFluid()
end

function TFC_Base:getPrimaryFluidAmount()
    local fluidContainer = self:getTubFluidContainer()
    if not fluidContainer then return 0 end
    return fluidContainer:getPrimaryFluidAmount()
end

function TFC_Base:isEmpty()
    local fluidContainer = self:getTubFluidContainer()
    if not fluidContainer then return false end
    return fluidContainer:isEmpty()
end

function TFC_Base:isFull()
    local fluidContainer = self:getTubFluidContainer()
    if not fluidContainer then return false end
    return fluidContainer:isFull()
end

function TFC_Base:getRatio()
    local fluidContainer = self:getTubFluidContainer()
    if not fluidContainer then return 0 end
    return fluidContainer:getFilledRatio()
end

function TFC_Base:getCapacity()
    local fluidContainer = self:getTubFluidContainer()
    if not fluidContainer then return 0 end
    return fluidContainer:getCapacity()
end

function TFC_Base:getFreeCapacity()
    local fluidContainer = self:getTubFluidContainer()
    if not fluidContainer then return 0 end
    return fluidContainer:getCapacity() - fluidContainer:getAmount()
end

function TFC_Base:canAddFluid(fluid)
    local fluidContainer = self:getTubFluidContainer()
    if not fluidContainer then return false end
    return fluidContainer:canAddFluid(fluid)
end

function TFC_Base:isDirtyWater()
    if not self:hasFluid() then return false end
    local dirtyLevel = self:getWaterData("dirtyLevel") or 0
    return dirtyLevel >= 20
end

function TFC_Base:getWaterTemperature()
    return self:getWaterData("temperature") or 0
end

function TFC_Base:getWaterLevelKey()
    local ratio = self:getRatio()
    return TFC_Utils.getWaterLevelKeyByRatio(ratio)
end

function TFC_Base:isLowWater()
    local waterLevel = TFC_Utils.getWaterLevelKeyByRatio(self:getRatio())
    return waterLevel == "low" or waterLevel == "empty"
end

function TFC_Base:isFullWater()
    local waterLevel = TFC_Utils.getWaterLevelKeyByRatio(self:getRatio())
    return waterLevel == "full"
end

function TFC_Base:isHotWater()
    return self:getWaterTemperature() >= TFC_Utils.HotWaterTemp
end


return TFC_Base
