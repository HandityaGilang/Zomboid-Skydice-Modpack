require "Fluids/ISFluidTransferAction"

local TABAS_Patches = {}

TABAS_Patches.applied = false

local ACTION_SYNC_COOLDOWN_MS = 350

local function getTfcBaseFromOwner(owner)
    local TFC_Utils = require("TubFluidContainer/TABAS_TubFluidContainerSystemUtils")
    if not owner or not TFC_Utils.isValidTfcObject(owner) then return nil end

    local square = owner:getSquare()
    local id = TFC_Utils.getRegisterdIdFromSquare(square, true)
    if not id then return nil end

    local x, y, z = TFC_Utils.getCoordsById(id)
    if not x then return nil end

    local TABAS_Iso = require("TABAS_Iso")
    local bathObject = TABAS_Iso.getBathObjectAt(x, y, z)
    if not bathObject then return nil end

    return TFC_Utils.getTfcBaseOnServer(x, y, z, bathObject)
end

local function syncTfcFromFluidContainer(owner)
    local tfc = getTfcBaseFromOwner(owner)
    if not tfc or not tfc:hasFluidContainer() then return false end

    local TFC_Utils = require("TubFluidContainer/TABAS_TubFluidContainerSystemUtils")
    local amount = round(tfc:getAmount(), 2)
    local oldAmount = tfc:getWaterData("amount") or 0
    if amount == oldAmount then return false end

    tfc:setWaterData("amount", amount, false)
    if amount <= 0 then
        tfc:setWaterData("dirtyLevel", 0, false)
        tfc:setWaterData("bathSalt", nil, false)
    end

    tfc:updateWaterSprite()
    tfc:syncWaterState(amount <= 0)
    TFC_Utils.noise("Fluid transfer sync", tostring(oldAmount) .. " >> " .. tostring(amount))
    return true
end

local function syncActionTfc(action, force)
    if not action then return end
    if not force then
        local nowMs = getTimestampMs()
        if action.TABAS_lastTfcSyncMs and (nowMs - action.TABAS_lastTfcSyncMs < ACTION_SYNC_COOLDOWN_MS) then
            return
        end
        action.TABAS_lastTfcSyncMs = nowMs
    end

    syncTfcFromFluidContainer(action.sourceOwner)
    syncTfcFromFluidContainer(action.targetOwner)
end

function TABAS_Patches.apply()
    if TABAS_Patches.applied then return true end
    if isClient() or not ISFluidTransferAction then
        TABAS_Patches.applied = true
        return true
    end

    local originalUpdate = ISFluidTransferAction.update
    function ISFluidTransferAction:update()
        originalUpdate(self)
        syncActionTfc(self, false)
    end

    local originalComplete = ISFluidTransferAction.complete
    function ISFluidTransferAction:complete()
        local result = originalComplete(self)
        syncActionTfc(self, true)
        return result
    end

    local originalStop = ISFluidTransferAction.stop
    function ISFluidTransferAction:stop()
        originalStop(self)
        syncActionTfc(self, true)
    end

    TABAS_Patches.applied = true
    return true
end

return TABAS_Patches
