-- Own mod data, kept separate from WPModData so we never touch the base
-- mod's real barrel/pipe fluid sync (which only understands Water/TaintedWater).
PFAModData = {}

function InitPFAModData(isNewGame)
    local modData = ModData.getOrCreate("PlumbingFuelAddonB42")

    if isClient() then
        ModData.request("PlumbingFuelAddonB42")
    end

    if not modData.FuelPipes then modData.FuelPipes = {} end
    if not modData.FuelBarrels then modData.FuelBarrels = {} end

    PFAModData = modData
end

function LoadPFAModData(key, modData)
    if isClient() then
        if key and key == "PlumbingFuelAddonB42" and modData then
            PFAModData = modData
        end
    end
end

function GetPFAModData()
    return PFAModData
end

function TransmitPFAModData()
    ModData.transmit("PlumbingFuelAddonB42")
end

Events.OnInitGlobalModData.Add(InitPFAModData)
Events.OnReceiveGlobalModData.Add(LoadPFAModData)
