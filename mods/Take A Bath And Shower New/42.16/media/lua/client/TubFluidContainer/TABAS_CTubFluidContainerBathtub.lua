
local TFC_Base = require("TubFluidContainer/TABAS_CTubFluidContainer")
local TABAS_Iso = require("TABAS_Iso")

local CTubFluidContainerBathtub = TFC_Base:derive("CTubFluidContainerBathtub")

function CTubFluidContainerBathtub:new(x, y, z, bathObject)
    local square = getCell():getGridSquare(x, y, z)
    if not square then return end

    local isoObject = bathObject or TABAS_Iso.getBathObjectOnSquare(square)
    if not isoObject or not TABAS_Iso.isBathFaucet(isoObject) then return end

    local o = TFC_Base.new(self, x, y, z, isoObject)
    if not o:confirmLinkedObject() then
        print("TFC - Linked object is invlid!")
    end
    return o
end

function CTubFluidContainerBathtub:addLinked()
    local dir = IsoDirections[self.facing]
    local mainSquare = self:getSquare()
    local square = mainSquare and mainSquare:getAdjacentSquare(dir) or nil
    if not square then return false end
    self.linkedX = square:getX()
    self.linkedY = square:getY()
    self.linkedBathObject = TABAS_Iso.getBathObjectOnSquare(square)
    return self.linkedBathObject ~= nil
end

function CTubFluidContainerBathtub:initNew()
    -- self.sprites.tableKey = "BathWater" -- not uses clients.
    if self:hasLinked() then
        self:resolveLinkedBathObject()
    else
        self:addLinked()
    end
end



return CTubFluidContainerBathtub
