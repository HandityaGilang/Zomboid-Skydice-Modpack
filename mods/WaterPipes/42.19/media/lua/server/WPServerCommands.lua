WPServer = {}
WPServer.Commands = {}

WPServer.Commands.PumpAdd = function(player, args)
    local gmd = GetWPModData()
    local k = WPUtils.Coords2Id(args.x, args.y, args.z)
    gmd.Pumps[k] = args
end

WPServer.Commands.PumpRemove = function(player, args)
    local gmd = GetWPModData()
    local k = WPUtils.Coords2Id(args.x, args.y, args.z)
    gmd.Pumps[k] = nil
end

WPServer.Commands.PumpMod = function(player, args)
    local gmd = GetWPModData()
    local k = WPUtils.Coords2Id(args.x, args.y, args.z)
    if not gmd.Pumps[k] then return end

    for p, v in pairs(args) do
        gmd.Pumps[k][p] = v
    end
end

WPServer.Commands.PipeAdd = function(player, args)
    local gmd = GetWPModData()
    local k = WPUtils.Coords2Id(args.x, args.y, args.z)
    gmd.Pipes[k] = args
end

WPServer.Commands.PipeRemove = function(player, args)
    local gmd = GetWPModData()
    local k = WPUtils.Coords2Id(args.x, args.y, args.z)
    gmd.Pipes[k] = nil
end

WPServer.Commands.ValveAdd = function(player, args)
    local gmd = GetWPModData()
    local k = WPUtils.Coords2Id(args.x, args.y, args.z)
    gmd.Valves[k] = args
end

WPServer.Commands.ValveRemove = function(player, args)
    local gmd = GetWPModData()
    local k = WPUtils.Coords2Id(args.x, args.y, args.z)
    gmd.Valves[k] = nil
end

WPServer.Commands.ValveMod = function(player, args)
    local gmd = GetWPModData()
    local k = WPUtils.Coords2Id(args.x, args.y, args.z)
    if not gmd.Valves[k] then return end

    for p, v in pairs(args) do
        gmd.Valves[k][p] = v
    end
end

WPServer.Commands.FlowmeterAdd = function(player, args)
    local gmd = GetWPModData()
    local k = WPUtils.Coords2Id(args.x, args.y, args.z)
    gmd.Flowmeters[k] = args
end

WPServer.Commands.FlowmeterRemove = function(player, args)
    local gmd = GetWPModData()
    local k = WPUtils.Coords2Id(args.x, args.y, args.z)
    gmd.Flowmeters[k] = nil
end

WPServer.Commands.FlowmeterMod = function(player, args)
    local gmd = GetWPModData()
    local k = WPUtils.Coords2Id(args.x, args.y, args.z)
    if not gmd.Flowmeters[k] then return end

    for p, v in pairs(args) do
        gmd.Flowmeters[k][p] = v
    end
end

WPServer.Commands.BarrelAdd = function(player, args)
    local gmd = GetWPModData()
    local k = WPUtils.Coords2Id(args.x, args.y, args.z)
    gmd.Barrels[k] = args
end

WPServer.Commands.BarrelRemove = function(player, args)
    local gmd = GetWPModData()
    local k = WPUtils.Coords2Id(args.x, args.y, args.z)
    gmd.Barrels[k] = nil
end

WPServer.Commands.BarrelMod = function(player, args)
    local gmd = GetWPModData()
    local k = WPUtils.Coords2Id(args.x, args.y, args.z)
    if not gmd.Barrels[k] then return end

    for p, v in pairs(args) do
        gmd.Barrels[k][p] = v
    end
end

WPServer.Commands.SprinklerAdd = function(player, args)
    local gmd = GetWPModData()
    local k = WPUtils.Coords2Id(args.x, args.y, args.z)
    gmd.Sprinklers[k] = args
end

WPServer.Commands.SprinklerRemove = function(player, args)
    local gmd = GetWPModData()
    local k = WPUtils.Coords2Id(args.x, args.y, args.z)
    gmd.Sprinklers[k] = nil
end

WPServer.Commands.SprinklerMod = function(player, args)
    local gmd = GetWPModData()
    local k = WPUtils.Coords2Id(args.x, args.y, args.z)
    if not gmd.Sprinklers[k] then return end

    for p, v in pairs(args) do
        gmd.Sprinklers[k][p] = v
    end
end

WPServer.Commands.BuildingAdd = function(player, args)
    local gmd = GetWPModData()
    local k = WPUtils.Coords2Id(args.x, args.y, args.z)
    gmd.Buildings[k] = args
end

local onClientCommand = function(mod, command, player, args)
    if mod ~= "Commands" then return end
    if not WPServer.Commands[command] then return end
    local argStr = ""
    for k, v in pairs(args) do
        argStr = argStr .. " " .. k .. "=" .. tostring(v)
    end
    print ("[SERVER][" .. mod .. "][" .. command .. "] ARGS:" .. argStr)
    local ok, err = pcall(WPServer.Commands[command], player, args)
    if ok then
        TransmitWPModData()
    end
end

Events.OnClientCommand.Add(onClientCommand)