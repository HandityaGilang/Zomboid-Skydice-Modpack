if not isServer() then return end

local StormMoodCore = require("HGTS_StormMoodCore")

local function StormMood_ServerTick()
    local cm = getClimateManager()
    if not cm then return end

    local ok, changed = pcall(function()
        return StormMoodCore.TickServer()
    end)

    -- Si hubo cambios reales (o lock on/off), sincronizamos a clientes
    if ok and changed and cm.transmitClientChangeAdminVars then
        pcall(function()
            cm:transmitClientChangeAdminVars()
        end)
    end
end

-- Tick 1 vez por minuto (suave y barato)
Events.EveryOneMinute.Add(StormMood_ServerTick)
