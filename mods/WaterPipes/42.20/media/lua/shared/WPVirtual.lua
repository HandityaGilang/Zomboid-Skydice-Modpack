WPVirtual = WPVirtual or {}

WPVirtual.PumpGet = function(x, y, z)
    local gmd = GetWPModData()
    local k = WPUtils.Coords2Id(x, y, z)
    return gmd.Pumps[k]
end

WPVirtual.PumpAdd = function(x, y, z)
    local args = {
        x = x,
        y = y,
        z = z,
        efficiency = 100,
        filter = 0,
        active = false,
        burn = false
    }
    sendClientCommand(getSpecificPlayer(0), "Commands", "PumpAdd", args)
end

WPVirtual.PumpRemove = function(x, y, z)
    local args = {
        x = x,
        y = y,
        z = z,
    }
    sendClientCommand(getSpecificPlayer(0), "Commands", "PumpRemove", args)
end

WPVirtual.PumpActivate = function(x, y, z, activated)
    local args = {
        x = x,
        y = y,
        z = z,
        active = activated
    }
    sendClientCommand(getSpecificPlayer(0), "Commands", "PumpMod", args)
end

WPVirtual.PumpAddFilter = function(x, y, z)
    local args = {
        x = x,
        y = y,
        z = z,
        filter = 100
    }
    sendClientCommand(getSpecificPlayer(0), "Commands", "PumpMod", args)
end

WPVirtual.PipeGet = function(x, y, z)
    local gmd = GetWPModData()
    local k = WPUtils.Coords2Id(x, y, z)
    return gmd.Pipes[k]
end

WPVirtual.PipeAdd = function(x, y, z, spriteKey)
    local args = {
        x = x,
        y = y,
        z = z,
        s = spriteKey,   -- shape key
        v = 0,           -- valve bits,
        m = nil,         -- medium type
        w = 0,           -- medium amount
    }
    sendClientCommand(getSpecificPlayer(0), "Commands", "PipeAdd", args)
end

WPVirtual.PipeRemove = function(x, y, z)
    local args = {
        x = x,
        y = y,
        z = z,
    }
    sendClientCommand(getSpecificPlayer(0), "Commands", "PipeRemove", args)
end

WPVirtual.ValveGet = function(x, y, z)
    local gmd = GetWPModData()
    local k = WPUtils.Coords2Id(x, y, z)
    return gmd.Valves[k]
end

WPVirtual.ValveAdd = function(x, y, z)
    local args = {
        x = x,
        y = y,
        z = z,
        c = false,
    }
    sendClientCommand(getSpecificPlayer(0), "Commands", "ValveAdd", args)
end

WPVirtual.ValveRemove = function(x, y, z)
    local args = {
        x = x,
        y = y,
        z = z,
    }
    sendClientCommand(getSpecificPlayer(0), "Commands", "ValveRemove", args)
end

WPVirtual.ValveSwitch = function(x, y, z, c)
    local args = {
        x = x,
        y = y,
        z = z,
        c = c
    }
    sendClientCommand(getSpecificPlayer(0), "Commands", "ValveMod", args)
end

WPVirtual.FlowmeterGet = function(x, y, z)
    local gmd = GetWPModData()
    local k = WPUtils.Coords2Id(x, y, z)
    return gmd.Flowmeters[k]
end

WPVirtual.FlowmeterAdd = function(x, y, z)
    local args = {
        x = x,
        y = y,
        z = z,
        f = 0,
    }
    sendClientCommand(getSpecificPlayer(0), "Commands", "FlowmeterAdd", args)
end

WPVirtual.FlowmeterMod = function(x, y, z, f)
    local args = {
        x = x,
        y = y,
        z = z,
        f = f,
    }
    sendClientCommand(getSpecificPlayer(0), "Commands", "FlowmeterMod", args)
end

WPVirtual.FlowmeterRemove = function(x, y, z)
    local args = {
        x = x,
        y = y,
        z = z,
    }
    sendClientCommand(getSpecificPlayer(0), "Commands", "FlowmeterRemove", args)
end

WPVirtual.BarrelGet = function(x, y, z)
    local gmd = GetWPModData()
    local k = WPUtils.Coords2Id(x, y, z)
    return gmd.Barrels[k]
end

WPVirtual.BarrelAdd = function(x, y, z, wmax, bid)
    local args = {
        x = x,
        y = y,
        z = z,
        m = nil,
        w = 0,
        wmax = wmax,
        bid = bid,
    }
    sendClientCommand(getSpecificPlayer(0), "Commands", "BarrelAdd", args)
end

WPVirtual.BarrelRemove = function(x, y, z)
    local args = {
        x = x,
        y = y,
        z = z,
    }
    sendClientCommand(getSpecificPlayer(0), "Commands", "BarrelRemove", args)
end

local barrelPourIn = function(barrel, m, w)
    local used = 0

    if not barrel.m or barrel.w == 0 then -- empty so fill with whatever is comming in
        barrel.m = m
    elseif m == "TaintedWater" or barrel.m == "TaintedWater" then -- mixed fluids
        barrel.m = "TaintedWater"
    elseif m == "Water" and barrel.m == "Water" then
        barrel.m = "Water"
    end

    if barrel.w + w < barrel.wmax then
        used = w
    else
        used = barrel.wmax - barrel.w
    end

    if used > 0 then
        barrel.w = barrel.w + used
    end

    return used
end

WPVirtual.BarrelPourIn = function(x, y, z, m, w)
    local gmd = GetWPModData()
    local k = WPUtils.Coords2Id(x, y, z)
    local barrel = gmd.Barrels[k]
    if not barrel then return 0 end

    local used = barrelPourIn(barrel, m, w)
    return used
end

WPVirtual.SprinklerAdd = function(x, y, z, wmax)
    local args = {
        x = x,
        y = y,
        z = z,
        w = 0,
        wmax = wmax
    }
    sendClientCommand(getSpecificPlayer(0), "Commands", "SprinklerAdd", args)
end

WPVirtual.SprinklerPourIn = function(x, y, z, w)
    local used = 0 
    local gmd = GetWPModData()
    local k = WPUtils.Coords2Id(x, y, z)
    local sprinkler = gmd.Sprinklers[k]
    if not sprinkler then return used end

    if not sprinkler.w then sprinkler.w = 0 end

    if sprinkler.w + w < sprinkler.wmax then
        used = w
    else
        used = sprinkler.wmax - sprinkler.w
    end

    if used > 0 then
        sprinkler.w = sprinkler.w + used
    end

    return used
end

WPVirtual.SprinklerRemove = function(x, y, z)
    local k = WPUtils.Coords2Id(x, y, z)
    WPSprinkler.Destroy(k)

    local args = {
        x = x,
        y = y,
        z = z,
    }
    sendClientCommand(getSpecificPlayer(0), "Commands", "SprinklerRemove", args)
end

WPVirtual.BuildingGet = function(x, y, z)
    local gmd = GetWPModData()
    local k = WPUtils.Coords2Id(x, y, z)
    return gmd.Buildings[k]
end

WPVirtual.BuildingAdd = function(x, y, z, bid)
    local args = {
        x = x,
        y = y,
        z = z,
        bid = bid,
    }
    sendClientCommand(getSpecificPlayer(0), "Commands", "BuildingAdd", args)
end

WPVirtual.BuildingPourIn = function(x, y, z, bid, medium, amount)
    local remaining = amount*1
    local gmd = GetWPModData()

    local cnt = 0
    for _, barrel in pairs(gmd.Barrels) do
        if barrel.bid == bid and barrel.w < barrel.wmax then
            cnt = cnt + 1
        end
    end

    if cnt > 0 then
        local amountParts = WPUtils.SplitIntToParts(amount, cnt)
        local i = 1
        for _, barrel in pairs(gmd.Barrels) do
            if barrel.bid == bid and barrel.w < barrel.wmax then
                local amountPart = amountParts[i]
                if amountPart > 0 then
                    barrelPourIn(barrel, medium, amountPart)
                    -- print ("USED BY X:" .. barrel.x .. " Y:" .. barrel.y .. " Z:" .. barrel.z ..  " W: " .. barrel.w .. " WMAX: " .. barrel.wmax .. " PART: " .. amountPart)
                end
                i = i + 1
            end
        end
    end
end