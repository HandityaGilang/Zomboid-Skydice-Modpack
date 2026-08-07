if isClient() then return end

local TFC_SyncManager = {}

local TFC_Utils = require("TubFluidContainer/TABAS_TubFluidContainerSystemUtils")
local TABAS_Iso = require("TABAS_Iso")

local TFC_WATCHERS = {}  -- [id] = expireMs

local SYNC_FAST = 10
local SYNC_SLOW = 60

local TRANSMIT_COOLDOWN_MS = 250
local _lastTransmitMs = 0

function TFC_SyncManager.addWatcher(id, ttlMs)
    local exp = getTimestampMs() + ttlMs
    local cur = TFC_WATCHERS[id]
    if (not cur) or (cur < exp) then
        TFC_WATCHERS[id] = exp
    end
end

local function cleanupWatchers(nowMs)
    for id, exp in pairs(TFC_WATCHERS) do
        if exp <= nowMs then
            TFC_WATCHERS[id] = nil
        end
    end
end

function TFC_SyncManager.transmitThrottled(nowMs)
    nowMs = nowMs or getTimestampMs()
    if nowMs - _lastTransmitMs < TRANSMIT_COOLDOWN_MS then
        return
    end
    _lastTransmitMs = nowMs
    TransmitTFCSystemData("syncManager")
end

function TFC_SyncManager.updateRegisteredSnapshot(x, y, z, facing)
    local gData = GetTFCSystemData()
    local id = TFC_Utils.getIdByCoords(x, y, z)

    local data = gData.Registered[id]
    if not data then
        data = { x=x, y=y, z=z, facing=facing }
        gData.Registered[id] = data
    else
        if data.facing ~= facing then data.facing = facing end
    end

    local bath = TABAS_Iso.getBathObjectAt(x, y, z)
    if not bath or bath:isDestroyed() then return false end

    local tfc = TFC_Utils.getTfcBaseOnServer(x, y, z, bath)
    if not tfc then return false end

    local changed = false

    local amount      = tfc:getWaterData("amount") or 0
    local temperature = tfc:getWaterData("temperature") or TFC_Utils.DefaultTemperature
    local capacity    = tfc:getWaterData("capacity") or data.capacity
    local lastUpdate  = tfc:getWaterData("lastUpdate") or data.lastUpdate
    local dirtyLevel  = tfc:getWaterData("dirtyLevel") or 0
    local bathSalt    = tfc:getWaterData("bathSalt") or false

    local fluid = tfc.fluidContainer and tfc.fluidContainer:getPrimaryFluid()
    local isWater = fluid and fluid:isCategory(FluidCategory.Water) or false

    if data.amount ~= amount then data.amount = amount; changed = true end
    if data.temperature ~= temperature then data.temperature = temperature; changed = true end
    if data.capacity ~= capacity then data.capacity = capacity; changed = true end
    if data.lastUpdate ~= lastUpdate then data.lastUpdate = lastUpdate; changed = true end
    if data.dirtyLevel ~= dirtyLevel then data.dirtyLevel = dirtyLevel; changed = true end
    if data.bathSalt ~= bathSalt then data.bathSalt = bathSalt; changed = true end
    if data.isWater ~= isWater then data.isWater = isWater; changed = true end

    local faucetAmount = bath:getFluidAmount() or 0
    local idealTemperature = tfc:getBathData("idealTemperature") or 40.0
    if data.faucetAmount ~= faucetAmount then data.faucetAmount = faucetAmount; changed = true end
    if data.idealTemperature ~= idealTemperature then data.idealTemperature = idealTemperature; changed = true end

    return changed
end

local syncTick = 0

local function syncRegisteredTick()
    if isClient() then return end

    syncTick = syncTick + 1
    local nowMs = getTimestampMs()

    if (syncTick % 30) == 0 then
        cleanupWatchers(nowMs)
    end

    local gData = GetTFCSystemData()
    local dirty = false
    local t = syncTick

    for id, v in pairs(gData.Activated) do
        local expireMs = TFC_WATCHERS[id]
        local expired = expireMs and (expireMs > nowMs)
        local interval = expired and SYNC_FAST or SYNC_SLOW
        if (t % interval) == 0 then
            if TFC_SyncManager.updateRegisteredSnapshot(v.x, v.y, v.z, v.facing) then
                dirty = true
            end
        end
    end

    if dirty then
        TFC_SyncManager.transmitThrottled(nowMs)
    end
end
Events.OnTick.Add(syncRegisteredTick)

return TFC_SyncManager
