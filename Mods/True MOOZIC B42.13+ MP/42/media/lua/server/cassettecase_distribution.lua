-- CassetteCase_Distribution.lua
-- Adds CassetteCase to select loot tables

require "Items/ProceduralDistributions"
require "Items/SuburbsDistributions"
require "Vehicles/VehicleDistributions"
require "TCMusicSandbox"
pcall(function() require "CassetteCase_OnCreate" end)
pcall(function() require "TCMusicModDetector" end)

local DEBUG = false
local function log(msg)
    if DEBUG then
        print("[TCCassetteCase] " .. msg)
    end
end

local function addToProcList(listName, itemName, weight)
    if weight <= 0 then return end
    if not ProceduralDistributions or not ProceduralDistributions.list then return end
    local list = ProceduralDistributions.list[listName]
    if not list or not list.items then
        log(string.format("Missing proc list: %s", tostring(listName)))
        return
    end
    table.insert(list.items, itemName)
    table.insert(list.items, weight)
    log(string.format("Added %s to %s weight=%.4f", itemName, listName, weight))
end

local function addToVehicleDist(distName, itemName, weight)
    if weight <= 0 then return end
    if not VehicleDistributions then return end
    local dist = VehicleDistributions[distName]
    if not dist or not dist.items then
        log(string.format("Missing vehicle dist: %s", tostring(distName)))
        return
    end
    table.insert(dist.items, itemName)
    table.insert(dist.items, weight)
    log(string.format("Added %s to %s weight=%.4f", itemName, distName, weight))
end

local function addToAllVehicleTrunks(itemName, weight)
    if weight <= 0 then return end
    if not VehicleDistributions then return end

    for distName, dist in pairs(VehicleDistributions) do
        if type(distName) == "string"
            and distName:find("Trunk")
            and type(dist) == "table"
            and type(dist.items) == "table"
        then
            addToVehicleDist(distName, itemName, weight)
        end
    end
end

local function buildCassetteCaseDistribution()
    if not Distributions or not Distributions[1] then
        log("Distributions table not available; skipping CassetteCase fill distribution.")
        return
    end

    if not TCMusicModDetector or not TCMusicModDetector.GetAllCassettes then
        log("TCMusicModDetector not available; skipping CassetteCase fill distribution.")
        return
    end

    local cassettePool = TCMusicModDetector.GetAllCassettes()
    if (not cassettePool or #cassettePool == 0) and TCMusicModDetector.DetectMusicMods then
        TCMusicModDetector.DetectMusicMods()
        cassettePool = TCMusicModDetector.GetAllCassettes()
    end
    if not cassettePool or #cassettePool == 0 then
        log("No cassette pool available for CassetteCase distribution.")
        return
    end

    local items = {}
    for _, cassette in ipairs(cassettePool) do
        local ft = cassette and cassette.fullType or nil
        if ft then
            local lower = ft:lower()
            if lower:find("cassette", 1, true) and not lower:find("cassettecase", 1, true) then
                if getScriptManager():FindItem(ft) then
                    table.insert(items, ft)
                    table.insert(items, 10)
                end
            end
        end
    end

    if #items == 0 then
        log("Cassette pool had no valid entries for distribution.")
        return
    end

    -- Vanilla-style: define contents for the container item itself so it serializes on spawn.
    local dist = {
        rolls = 4,
        items = items,
        junk = { rolls = 0, items = {} },
    }

    Distributions[1].CassetteCase = dist
    Distributions[1]["Tsarcraft.CassetteCase"] = dist
    log("Registered CassetteCase fill distribution with " .. tostring(#items / 2) .. " cassette entries.")
end

local applied = false
local function applyDistributions()
    if applied then return end
    applied = true

    local rate = 1.0
    if TCMusicSandbox and TCMusicSandbox.GetCassetteCaseSpawnRate then
        rate = TCMusicSandbox.GetCassetteCaseSpawnRate()
    end

    if rate <= 0 then
        log("Spawn rate <= 0; skipping cassette case distributions.")
        return
    end

    log(string.format("Applying cassette case distributions with rate=%.4f", rate))

    -- Build container-contents distribution now that mod detection has run.
    buildCassetteCaseDistribution()

    -- Music store shelves: effectively always one when enabled
    addToProcList("MusicStoreOthers", "Tsarcraft.CassetteCase", 40 * rate)
    addToProcList("MusicStoreCases", "Tsarcraft.CassetteCase", 40 * rate)
    addToProcList("MusicStoreCDs", "Tsarcraft.CassetteCase", 40 * rate)
    addToProcList("MusicStoreSpeaker", "Tsarcraft.CassetteCase", 40 * rate)

    -- Bedroom dressers: uncommon
    addToProcList("BedroomDresser", "Tsarcraft.CassetteCase", 0.3 * rate)
    addToProcList("BedroomDresserChild", "Tsarcraft.CassetteCase", 0.3 * rate)
    addToProcList("BedroomDresserClassy", "Tsarcraft.CassetteCase", 0.3 * rate)
    addToProcList("BedroomDresserRedneck", "Tsarcraft.CassetteCase", 0.3 * rate)

    -- Living room shelves: uncommon
    addToProcList("LivingRoomShelf", "Tsarcraft.CassetteCase", 0.3 * rate)
    addToProcList("LivingRoomShelfClassy", "Tsarcraft.CassetteCase", 0.3 * rate)
    addToProcList("LivingRoomShelfRedneck", "Tsarcraft.CassetteCase", 0.3 * rate)

    -- School lockers: half of shelves
    addToProcList("SchoolLockers", "Tsarcraft.CassetteCase", 0.15 * rate)
    addToProcList("SchoolLockersBad", "Tsarcraft.CassetteCase", 0.15 * rate)

    -- Gigamart / electronics: low chance
    addToProcList("GigamartHouseElectronics", "Tsarcraft.CassetteCase", 0.12 * rate)
    addToProcList("ElectronicStoreMisc", "Tsarcraft.CassetteCase", 0.10 * rate)
    addToProcList("ElectronicStoreMusic", "Tsarcraft.CassetteCase", 0.10 * rate)

    -- Garage-type shelves/crates: low chance
    addToProcList("GarageTools", "Tsarcraft.CassetteCase", 0.10 * rate)
    addToProcList("GarageMechanics", "Tsarcraft.CassetteCase", 0.10 * rate)
    addToProcList("GarageCarpentry", "Tsarcraft.CassetteCase", 0.08 * rate)
    addToProcList("GarageMetalwork", "Tsarcraft.CassetteCase", 0.08 * rate)
    addToProcList("CrateElectronics", "Tsarcraft.CassetteCase", 0.08 * rate)
    addToProcList("ShelfGeneric", "Tsarcraft.CassetteCase", 0.06 * rate)

    -- Any vehicle trunk-like container: rare
    addToAllVehicleTrunks("Tsarcraft.CassetteCase", 0.05 * rate)
end

if Events and Events.OnPostDistributionMerge then
    Events.OnPostDistributionMerge.Add(applyDistributions)
elseif Events and Events.OnGameStart then
    Events.OnGameStart.Add(applyDistributions)
else
    applyDistributions()
end

-- No OnFillContainer hook: rely on Distributions for loot, and OnCreate for admin/crafted cases.

