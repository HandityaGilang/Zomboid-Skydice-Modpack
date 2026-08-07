if isClient() then return end

local TFC_Base = require("TubFluidContainer/TABAS_STubFluidContainer")
local TABAS_Iso = require("TABAS_Iso")

local STubFluidContainerBathtub = TFC_Base:derive("STubFluidContainerBathtub")

function STubFluidContainerBathtub:new(x, y, z, bathObject)
    local square = getCell():getGridSquare(x, y, z)
    if not square then return end

    local isoObject = bathObject or TABAS_Iso.getBathObjectOnSquare(square)
    if not isoObject or not TABAS_Iso.isBathFaucet(isoObject) then return end

    local o = TFC_Base.new(self, x, y, z, isoObject)
    if not o:confirmLinkedObject() then
        o:remove()
    end
    return o
end

function STubFluidContainerBathtub:addLinked()
    local dir = IsoDirections[self.facing]
    local square = self:getSquare():getAdjacentSquare(dir)
    self.linkedX = square:getX()
    self.linkedY = square:getY()
    self.linkedBathObject = TABAS_Iso.getBathObjectOnSquare(square)
end

function STubFluidContainerBathtub:initNew()
    self.sprites.tableKey = "BathWater"
    self:addLinked()
end

return STubFluidContainerBathtub