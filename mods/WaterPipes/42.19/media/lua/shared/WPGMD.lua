WPModData = {}

function InitWPModData(isNewGame)

    local modData = ModData.getOrCreate("WaterPipes")

    if isClient() then
        ModData.request("WaterPipes")
    end

    -- register virtual object tables
    if not modData.Pumps then modData.Pumps = {} end
    if not modData.Pipes then modData.Pipes = {} end
    if not modData.Valves then modData.Valves = {} end
    if not modData.Flowmeters then modData.Flowmeters = {} end
    if not modData.Barrels then modData.Barrels = {} end
    if not modData.Sprinklers then modData.Sprinklers = {} end
    if not modData.Buildings then modData.Buildings = {} end

    WPModData = modData
end

function LoadWPModData(key, modData)
    if isClient() then
        if key and key == "WaterPipes" and modData then
            WPModData = modData
        end
    end
end

function GetWPModData()
    return WPModData
end

function TransmitWPModData()
    ModData.transmit("WaterPipes")
end

Events.OnInitGlobalModData.Add(InitWPModData)
Events.OnReceiveGlobalModData.Add(LoadWPModData)
