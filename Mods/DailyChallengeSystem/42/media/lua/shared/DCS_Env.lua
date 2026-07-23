DCS_Env = DCS_Env or {}

function DCS_Env.isDedicated()
    return isServer() and not isClient()
end

function DCS_Env.isHost()
    return isServer() and isClient()
end

function DCS_Env.isCoopClient()
    return isClient() and not isServer()
end

function DCS_Env.isSP()
    return not isServer() and not isClient()
end

function DCS_Env.runsServerLogic()
    return isServer() or DCS_Env.isSP()
end

function DCS_Env.players()
    if DCS_Env.isSP() then
        local p = getSpecificPlayer(0)
        if p then return { p } end
        return {}
    end

    local result = {}
    local list = getOnlinePlayers()
    if list then
        local n = list:size()
        for i = 0, n - 1 do
            local p = list:get(i)
            if p then result[#result + 1] = p end
        end
    end

    if DCS_Env.isHost() then
        local hostPlayer = getSpecificPlayer(0)
        if hostPlayer then
            local already = false
            for _, p in ipairs(result) do
                if p == hostPlayer then already = true; break end
            end
            if not already then result[#result + 1] = hostPlayer end
        end
    end

    return result
end

DCS_Env._networkReady = false
function DCS_Env.isServerNetworkReady() return DCS_Env._networkReady == true end
Events.OnServerStarted.Add(function() DCS_Env._networkReady = true end)

return DCS_Env
