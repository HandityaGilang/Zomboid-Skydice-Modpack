-- True Music Spawn Rate Controller
-- Dynamically adjusts spawn rates for all music items based on sandbox settings

require 'Items/ProceduralDistributions'
require 'Items/SuburbsDistributions'
require 'Vehicles/VehicleDistributions'

local DEBUG = false
local function dlog(msg)
    if DEBUG then
        print(msg)
    end
end

-- Safely require other modules
local sandboxLoaded = pcall(require, "TCMusicSandbox")
if not sandboxLoaded then
    dlog("TCSpawnController: Warning - TCMusicSandbox not loaded")
end

local detectorLoaded = pcall(require, "TCMusicModDetector")
if not detectorLoaded then
    dlog("TCSpawnController: Warning - TCMusicModDetector not loaded")
end

local startWithLoaded = pcall(require, "TCStartWithDevice")
if not startWithLoaded then
    dlog("TCSpawnController: Warning - TCStartWithDevice not loaded")
end

TCSpawnController = TCSpawnController or {}

local function getTypeNameFromFullType(fullType)
    if type(fullType) ~= "string" then return nil end
    local dot = string.find(fullType, "%.")
    if not dot then return fullType end
    return string.sub(fullType, dot + 1)
end

local function isCassetteLikeType(typeName)
    if type(typeName) ~= "string" then return false end
    local lower = string.lower(typeName)
    return string.find(lower, "cassette", 1, true) ~= nil
        and string.find(lower, "cassettecase", 1, true) == nil
end

local function isVinylAlbumType(typeName)
    if type(typeName) ~= "string" then return false end
    return string.sub(typeName, 1, 10) == "VinylAlbum"
end

local function isVinylRecordType(typeName)
    if type(typeName) ~= "string" then return false end
    return string.sub(typeName, 1, 5) == "Vinyl" and not isVinylAlbumType(typeName)
end

local function splitDetectedModItems(mediaItems)
    local cassetteItems = {}
    local vinylItems = {}
    local suppressedRecordItems = {}
    local albumSuffixes = {}
    local albumSuffixList = {}
    local allRecords = {}

    if not mediaItems then
        return cassetteItems, vinylItems, suppressedRecordItems
    end

    for _, media in ipairs(mediaItems) do
        local fullType = media and media.fullType or nil
        local typeName = getTypeNameFromFullType(fullType)
        if typeName then
            if isCassetteLikeType(typeName) then
                table.insert(cassetteItems, media)
            elseif isVinylAlbumType(typeName) then
                local suffix = string.sub(typeName, 11)
                table.insert(vinylItems, media)
                if suffix and suffix ~= "" then
                    albumSuffixes[suffix] = true
                    table.insert(albumSuffixList, suffix)
                end
            elseif isVinylRecordType(typeName) then
                table.insert(allRecords, media)
            end
        end
    end

    for _, media in ipairs(allRecords) do
        local fullType = media and media.fullType or nil
        local typeName = getTypeNameFromFullType(fullType)
        local suffix = typeName and string.sub(typeName, 6) or nil
        local hasMatchingAlbum = false
        if suffix and suffix ~= "" then
            if albumSuffixes[suffix] then
                hasMatchingAlbum = true
            else
                for _, albumSuffix in ipairs(albumSuffixList) do
                    if string.sub(suffix, 1, #albumSuffix) == albumSuffix then
                        hasMatchingAlbum = true
                        break
                    end
                end
            end
        end

        if hasMatchingAlbum then
            table.insert(suppressedRecordItems, media)
        else
            table.insert(vinylItems, media)
        end
    end

    return cassetteItems, vinylItems, suppressedRecordItems
end

local function distContainsItem(items, fullType)
    if type(items) ~= "table" or type(fullType) ~= "string" then
        return false
    end
    local i = 1
    while i <= #items do
        if items[i] == fullType then
            return true
        end
        i = i + 2
    end
    return false
end

local function addItemToProcListIfMissing(listName, fullType, weight)
    if not ProceduralDistributions or not ProceduralDistributions.list then return end
    local list = ProceduralDistributions.list[listName]
    if not list or not list.items or weight <= 0 then return end
    if distContainsItem(list.items, fullType) then return end
    table.insert(list.items, fullType)
    table.insert(list.items, weight)
end

local function addItemToVehicleDistIfMissing(distName, fullType, weight)
    if not VehicleDistributions then return end
    local dist = VehicleDistributions[distName]
    if not dist or not dist.items or weight <= 0 then return end
    if distContainsItem(dist.items, fullType) then return end
    table.insert(dist.items, fullType)
    table.insert(dist.items, weight)
end

local function addItemToAllVehicleTrunksIfMissing(fullType, weight)
    if not VehicleDistributions or weight <= 0 then return end
    for distName, dist in pairs(VehicleDistributions) do
        if type(distName) == "string"
            and string.find(distName, "Trunk", 1, true)
            and type(dist) == "table"
            and type(dist.items) == "table"
        then
            addItemToVehicleDistIfMissing(distName, fullType, weight)
        end
    end
end

local function ensureDetectedMediaHasDistribution(cassetteItems, vinylItems)
    local cassetteLists = {
        {name = "MusicStoreCDs", weight = 2.5},
        {name = "MusicStoreSpeaker", weight = 1.5},
        {name = "MusicStoreOthers", weight = 2.0},
        {name = "ElectronicStoreMusic", weight = 1.0},
        {name = "CrateCompactDiscs", weight = 1.0},
        {name = "LivingRoomShelf", weight = 0.2},
        {name = "BedroomDresser", weight = 0.1},
        {name = "SchoolLockers", weight = 0.08},
    }
    local vinylLists = {
        {name = "MusicStoreCases", weight = 2.5},
        {name = "MusicStoreCDs", weight = 1.5},
        {name = "MusicStoreSpeaker", weight = 1.5},
        {name = "MusicStoreOthers", weight = 1.5},
        {name = "ElectronicStoreMusic", weight = 1.0},
        {name = "CrateCompactDiscs", weight = 1.0},
        {name = "LivingRoomShelf", weight = 0.2},
        {name = "BedroomDresser", weight = 0.1},
        {name = "SchoolLockers", weight = 0.08},
    }

    for _, media in ipairs(cassetteItems or {}) do
        local fullType = media and media.fullType or nil
        if fullType then
            for _, cfg in ipairs(cassetteLists) do
                addItemToProcListIfMissing(cfg.name, fullType, cfg.weight)
            end
            addItemToVehicleDistIfMissing("GloveBox", fullType, 0.05)
            addItemToAllVehicleTrunksIfMissing(fullType, 0.12)
        end
    end

    for _, media in ipairs(vinylItems or {}) do
        local fullType = media and media.fullType or nil
        if fullType then
            for _, cfg in ipairs(vinylLists) do
                addItemToProcListIfMissing(cfg.name, fullType, cfg.weight)
            end
            addItemToVehicleDistIfMissing("GloveBox", fullType, 0.03)
            addItemToAllVehicleTrunksIfMissing(fullType, 0.08)
        end
    end
end

local function scaleSpawnRate(rawRate)
    local r = tonumber(rawRate) or 1
    if r <= 0 then return 0 end
    if r <= 1 then return r end
    local scaled = math.pow(r, 0.65)
    if scaled > 40 then scaled = 40 end
    return scaled
end

local function buildItemLookup(items)
    local lookup = {}
    local count = 0
    for _, media in ipairs(items or {}) do
        local fullType = media and media.fullType or nil
        if type(fullType) == "string" and fullType ~= "" and not lookup[fullType] then
            lookup[fullType] = true
            count = count + 1
        end
    end
    return lookup, count
end

local function distHasAnyLookupItem(items, lookup)
    if type(items) ~= "table" then return false end
    local i = 1
    while i <= #items do
        local name = items[i]
        if type(name) == "string" and lookup[name] then
            return true
        end
        i = i + 2
    end
    return false
end

local function packDistributionPresence(lookup)
    local presence = { procedural = false, suburbs = false, vehicle = false }
    if not lookup then return presence end

    if ProceduralDistributions and ProceduralDistributions.list then
        for _, distTable in pairs(ProceduralDistributions.list) do
            if distTable and (distHasAnyLookupItem(distTable.items, lookup) or (distTable.junk and distHasAnyLookupItem(distTable.junk.items, lookup))) then
                presence.procedural = true
                break
            end
        end
    end

    if SuburbsDistributions then
        for _, location in pairs(SuburbsDistributions) do
            if type(location) == "table" then
                for _, room in pairs(location) do
                    if type(room) == "table" then
                        if distHasAnyLookupItem(room.items, lookup)
                            or (room.counter and distHasAnyLookupItem(room.counter.items, lookup))
                            or (room.metal_shelves and distHasAnyLookupItem(room.metal_shelves.items, lookup))
                            or (room.shelves and distHasAnyLookupItem(room.shelves.items, lookup))
                            or (room.crate and distHasAnyLookupItem(room.crate.items, lookup))
                        then
                            presence.suburbs = true
                            break
                        end
                    end
                end
            end
            if presence.suburbs then break end
        end
    end

    if VehicleDistributions then
        for _, vehicle in pairs(VehicleDistributions) do
            if type(vehicle) == "table" then
                for _, container in pairs(vehicle) do
                    if type(container) == "table" and distHasAnyLookupItem(container.items, lookup) then
                        presence.vehicle = true
                        break
                    end
                end
            end
            if presence.vehicle then break end
        end
    end

    return presence
end

local function hasAnyDistributionPresence(presence)
    return presence and (presence.procedural or presence.suburbs or presence.vehicle) or false
end

-- Function to apply spawn rate multipliers to items from a specific mod
function TCSpawnController.ApplyMultipliersToMod(modID, multiplier, cassetteItems)
    if not cassetteItems or #cassetteItems == 0 then return end
    
    -- Build a lookup table for fast checking
    local itemLookup = {}
    for _, cassette in ipairs(cassetteItems) do
        itemLookup[cassette.fullType] = true
    end
    
    local processedCount = 0
    local removedCount = 0
    
    -- Helper function to process any distribution table
    local function processDistTable(distTable, distName)
        if not distTable or not distTable.items then return end
        
        local items = distTable.items
        local i = 1
        
        while i <= #items do
            local itemName = items[i]
            
            -- Check if this item is from our mod
            if type(itemName) == "string" and itemLookup[itemName] then
                -- Next element should be spawn chance
                if i + 1 <= #items and type(items[i + 1]) == "number" then
                    -- If multiplier is 0, remove the item entirely from spawn table
                    if multiplier == 0 then
                        table.remove(items, i + 1) -- Remove spawn rate
                        table.remove(items, i)     -- Remove item name
                        removedCount = removedCount + 1
                        -- Don't increment i since we removed elements
                    else
                        -- Apply multiplier
                        items[i + 1] = items[i + 1] * multiplier
                        processedCount = processedCount + 1
                        i = i + 2
                    end
                else
                    i = i + 1
                end
            else
                i = i + 1
            end
        end
    end
    
    -- Process ProceduralDistributions
    for distName, distTable in pairs(ProceduralDistributions.list) do
        processDistTable(distTable, distName)
        -- Also process junk items
        if distTable.junk then
            processDistTable(distTable.junk, tostring(distName) .. "_junk")
        end
    end
    
    -- Process SuburbsDistributions (room-specific loot like music stores)
    if SuburbsDistributions then
        for locationName, location in pairs(SuburbsDistributions) do
            if type(location) == "table" then
                for roomName, room in pairs(location) do
                    if type(room) == "table" then
                        processDistTable(room, tostring(locationName) .. "." .. tostring(roomName))
                        -- Some have nested counters/containers
                        if room.counter then processDistTable(room.counter, tostring(locationName) .. "." .. tostring(roomName) .. ".counter") end
                        if room.metal_shelves then processDistTable(room.metal_shelves, tostring(locationName) .. "." .. tostring(roomName) .. ".metal_shelves") end
                        if room.shelves then processDistTable(room.shelves, tostring(locationName) .. "." .. tostring(roomName) .. ".shelves") end
                        if room.crate then processDistTable(room.crate, tostring(locationName) .. "." .. tostring(roomName) .. ".crate") end
                    end
                end
            end
        end
    end
    
    -- Process VehicleDistributions (items in car gloveboxes/trunks)
    if VehicleDistributions then
        for vehicleType, vehicle in pairs(VehicleDistributions) do
            if type(vehicle) == "table" then
                for containerName, container in pairs(vehicle) do
                    if type(container) == "table" then
                        processDistTable(container, tostring(vehicleType) .. "." .. tostring(containerName))
                    end
                end
            end
        end
    end
    
    if removedCount > 0 then
        dlog("TCSpawnController: REMOVED " .. removedCount .. " spawn entries for " .. modID)
    elseif processedCount > 0 then
        dlog("TCSpawnController: Applied multiplier to " .. processedCount .. " spawn entries for " .. modID)
    end
end

-- Function to apply multiplier to junk items
function TCSpawnController.ApplyMultiplierToJunk(distributionName, distribution, itemFullType, multiplier)
    if not distribution or not distribution.junk or not distribution.junk.items then return end
    
    TCSpawnController.ApplyMultiplierToDistribution(distributionName .. "_junk", distribution.junk, itemFullType, multiplier)
end

-- Function to scan and adjust all procedural distributions
function TCSpawnController.AdjustAllDistributions()
    dlog("=== TCSpawnController: Adjusting spawn rates ===")
    
    local masterRate = TCMusicSandbox.GetCassetteSpawnRate()
    dlog("TCSpawnController: Cassette spawn rate: " .. masterRate)
    
    -- If master rate is 0, disable all music items
    if masterRate == 0 then
        dlog("TCSpawnController: Cassette rate is 0, disabling cassette spawns")
    end

    -- Adjust True Music items (per-item sandbox rates, not affected by cassette master)
    local walkmanRate = TCMusicSandbox.GetWalkmanSpawnRate()
    local boomboxRate = TCMusicSandbox.GetBoomboxSpawnRate()
    local vinylRate = TCMusicSandbox.GetVinylSpawnRate()
    local vinylPlayerRate = TCMusicSandbox.GetVinylPlayerSpawnRate()

    dlog("TCSpawnController: Walkman final rate: " .. walkmanRate)
    dlog("TCSpawnController: Boombox final rate: " .. boomboxRate)
    dlog("TCSpawnController: Vinyl media final rate: " .. vinylRate)
    dlog("TCSpawnController: Vinyl player final rate: " .. vinylPlayerRate)
    
    TCSpawnController.ApplyMultipliersToMod("TrueMoozic_Walkman", scaleSpawnRate(walkmanRate), {
        {fullType = "Tsarcraft.TCWalkman", name = "TCWalkman"}
    })

    TCSpawnController.ApplyMultipliersToMod("TrueMoozic_Boombox", scaleSpawnRate(boomboxRate), {
        {fullType = "Tsarcraft.TCBoombox", name = "TCBoombox"}
    })

    TCSpawnController.ApplyMultipliersToMod("TrueMoozic_Vinyl", scaleSpawnRate(vinylPlayerRate), {
        {fullType = "Tsarcraft.TCVinylplayer", name = "TCVinylplayer"},
        {fullType = "Tsarcraft.TCVinylplayerBlack", name = "TCVinylplayerBlack"}
    })
    
    -- Adjust detected mod media:
    -- cassettes use master*cassette-mod rate, vinyl media use vinyl*mod rate.
    if TCMusicModDetector and TCMusicModDetector.CassetteItems and TCMusicModDetector.DetectedMods then
        for modID, mediaItems in pairs(TCMusicModDetector.CassetteItems) do
            local modRate = TCMusicSandbox.GetSpawnRateForMod(modID)
            local cassetteRate = scaleSpawnRate(masterRate * modRate)
            local vinylMediaRate = scaleSpawnRate(vinylRate * modRate)
            local modInfo = TCMusicModDetector.DetectedMods[modID]
        
            if modInfo then
                dlog(string.format("TCSpawnController: %s cassette rate: %.2f | vinyl media rate: %.2f", modInfo.name, cassetteRate, vinylMediaRate))

                local cassetteItems, vinylItems, suppressedRecordItems = splitDetectedModItems(mediaItems)

                local combined = {}
                for _, v in ipairs(cassetteItems) do table.insert(combined, v) end
                for _, v in ipairs(vinylItems) do table.insert(combined, v) end
                local lookup, detectedCount = buildItemLookup(combined)
                local presence = packDistributionPresence(lookup)
                local shouldInject = not hasAnyDistributionPresence(presence)

                if shouldInject then
                    ensureDetectedMediaHasDistribution(cassetteItems, vinylItems)
                end

                dlog(string.format(
                    "TCSpawnController: child-pack=%s detectedItems=%d families={proc=%s,suburbs=%s,vehicle=%s} injected=%s",
                    tostring(modID),
                    detectedCount,
                    tostring(presence.procedural),
                    tostring(presence.suburbs),
                    tostring(presence.vehicle),
                    tostring(shouldInject)
                ))

                if #cassetteItems > 0 then
                    TCSpawnController.ApplyMultipliersToMod(modID .. "_cassettes", cassetteRate, cassetteItems)
                end

                if #vinylItems > 0 then
                    TCSpawnController.ApplyMultipliersToMod(modID .. "_vinyl", vinylMediaRate, vinylItems)
                end

                if #suppressedRecordItems > 0 then
                    -- Auto mode: if a matching VinylAlbum exists, remove Vinyl* record distribution entries.
                    TCSpawnController.ApplyMultipliersToMod(modID .. "_vinyl_suppressed_records", 0, suppressedRecordItems)
                end
            end
        end
    end
end

-- Apply distribution authority only to detected child media packs.
-- Safe to run after startup when initial OnPostDistributionMerge missed pack detection.
function TCSpawnController.AdjustDetectedMediaDistributionsOnly()
    if not (TCMusicModDetector and TCMusicModDetector.CassetteItems and TCMusicModDetector.DetectedMods) then
        return
    end

    local masterRate = TCMusicSandbox.GetCassetteSpawnRate()
    local vinylRate = TCMusicSandbox.GetVinylSpawnRate()

    for modID, mediaItems in pairs(TCMusicModDetector.CassetteItems) do
        local modRate = TCMusicSandbox.GetSpawnRateForMod(modID)
        local cassetteRate = scaleSpawnRate(masterRate * modRate)
        local vinylMediaRate = scaleSpawnRate(vinylRate * modRate)

        local cassetteItems, vinylItems, suppressedRecordItems = splitDetectedModItems(mediaItems)

        local combined = {}
        for _, v in ipairs(cassetteItems) do table.insert(combined, v) end
        for _, v in ipairs(vinylItems) do table.insert(combined, v) end
        local lookup, detectedCount = buildItemLookup(combined)
        local presence = packDistributionPresence(lookup)
        local shouldInject = not hasAnyDistributionPresence(presence)

        if shouldInject then
            ensureDetectedMediaHasDistribution(cassetteItems, vinylItems)
        end

        dlog(string.format(
            "TCSpawnController: child-pack(retry)=%s detectedItems=%d families={proc=%s,suburbs=%s,vehicle=%s} injected=%s",
            tostring(modID),
            detectedCount,
            tostring(presence.procedural),
            tostring(presence.suburbs),
            tostring(presence.vehicle),
            tostring(shouldInject)
        ))

        if #cassetteItems > 0 then
            TCSpawnController.ApplyMultipliersToMod(modID .. "_cassettes", cassetteRate, cassetteItems)
        end

        if #vinylItems > 0 then
            TCSpawnController.ApplyMultipliersToMod(modID .. "_vinyl", vinylMediaRate, vinylItems)
        end

        if #suppressedRecordItems > 0 then
            TCSpawnController.ApplyMultipliersToMod(modID .. "_vinyl_suppressed_records", 0, suppressedRecordItems)
        end
    end
end

-- Initialize EARLY - must run before containers are populated
local postMergeDetectedCount = nil
local startupRetryApplied = false

local function OnPostDistributionMerge()
    dlog("TCSpawnController: OnPostDistributionMerge - Starting initialization")
    
    -- FIRST: Run detection to find all music mods
    if TCMusicModDetector and TCMusicModDetector.DetectMusicMods then
        dlog("TCSpawnController: Triggering mod detection")
        TCMusicModDetector.DetectMusicMods()
    else
        dlog("TCSpawnController: ERROR - TCMusicModDetector not available")
    end
    
    if TCMusicModDetector and TCMusicModDetector.GetDetectedModCount then
        postMergeDetectedCount = TCMusicModDetector.GetDetectedModCount()
    else
        postMergeDetectedCount = 0
    end

    -- SECOND: Now adjust spawn rates with detected mods
    dlog("TCSpawnController: Adjusting spawn rates NOW")
    TCSpawnController.AdjustAllDistributions()
end

-- Hook into OnPostDistributionMerge - runs BEFORE world generation
Events.OnPostDistributionMerge.Add(OnPostDistributionMerge)

-- Dedicated/MP fallback:
-- If OnPostDistributionMerge saw zero child packs but server startup has them,
-- apply only child-media distribution authority once.
local function OnServerStartedRetry()
    if startupRetryApplied then return end
    if postMergeDetectedCount ~= 0 then return end
    if not (TCMusicModDetector and TCMusicModDetector.DetectMusicMods) then return end

    TCMusicModDetector.DetectMusicMods()
    local detectedNow = TCMusicModDetector.GetDetectedModCount and TCMusicModDetector.GetDetectedModCount() or 0
    if detectedNow > 0 then
        TCSpawnController.AdjustDetectedMediaDistributionsOnly()
        startupRetryApplied = true
    end
end

Events.OnServerStarted.Add(OnServerStartedRetry)

