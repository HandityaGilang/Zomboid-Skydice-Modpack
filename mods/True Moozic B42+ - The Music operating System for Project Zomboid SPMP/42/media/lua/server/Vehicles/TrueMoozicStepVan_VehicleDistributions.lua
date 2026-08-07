--[[
    TrueMoozicStepVan_VehicleDistributions.lua  (server)

    Loot for the TrueMoozic StepVan: finding the van is a jackpot.
    The trunk (TruckBed) and glovebox are stuffed with:
      - devices from this mod (boomboxes, walkmans, CD players,
        vinyl players, HiFi, media cases)
      - batteries, loose and boxed
      - music media (cassettes / vinyl / CDs) from the base mod AND
        every installed music add-on pack, injected dynamically at
        distribution-merge time so any pack automatically qualifies.
]]

VehicleDistributions.TrueMoozicStepVanTruckBed = {
    rolls = 25,
    items = {
        -- Devices (all colours)
        "Tsarcraft.TCBoombox", 3,
        "Tsarcraft.TCBoomboxBlue", 2,
        "Tsarcraft.TCBoomboxCamo", 2,
        "Tsarcraft.TCBoomboxBlack", 2,
        "Tsarcraft.TCBoomboxGreen", 2,
        "Tsarcraft.TCBoomboxPink", 2,
        "Tsarcraft.TCBoomboxRed", 2,
        "Tsarcraft.TCWalkman", 3,
        "Tsarcraft.TCWalkmanPurple", 2,
        "Tsarcraft.TCWalkmanRed", 2,
        "Tsarcraft.TCWalkmanBlack", 2,
        "Tsarcraft.TCWalkmanPink", 2,
        "Tsarcraft.TCWalkmanGreen", 2,
        "Tsarcraft.TCWalkmanCamoGreen", 2,
        "Tsarcraft.TM_CDPlayer_Blue", 2,
        "Tsarcraft.TM_CDPlayer_Purple", 2,
        "Tsarcraft.TM_CDPlayer_Red", 2,
        "Tsarcraft.TM_CDPlayer_Black", 2,
        "Tsarcraft.TM_CDPlayer_Green", 2,
        "Tsarcraft.TM_CDPlayer_Orange", 2,
        "Tsarcraft.TM_CDPlayer_White", 2,
        "Tsarcraft.TM_CDPlayer_TrueMoozic", 3,
        "Tsarcraft.TCVinylplayer", 2,
        "Tsarcraft.TCVinylplayerBlack", 2,
        "Tsarcraft.TM_HiFiStereo", 1.5,
        -- Media cases
        "Tsarcraft.CassetteCase", 2,
        "Tsarcraft.TM_CDCase", 2,
        "Tsarcraft.TM_CDCarryingCase", 2,
        -- Accessories
        "Tsarcraft.WireBundle", 2,
        "Base.Headphones", 3,
        "Base.Earbuds", 3,
        -- Batteries: loose and boxed
        "Base.Battery", 8,
        "Base.BatteryBox", 4,
    },
    junk = {
        rolls = 5,
        items = {
            "Base.Battery", 8,
            "Base.BatteryBox", 2,
            "WaterRationCan_Box", 4,
            "ProduceBox_Large", 4,
        },
    }
}

VehicleDistributions.TrueMoozicStepVanGloveBox = {
    rolls = 8,
    items = {
        "Base.Battery", 8,
        "Base.BatteryBox", 2,
        "Tsarcraft.TCWalkman", 1,
        "Tsarcraft.TM_CDPlayer_TrueMoozic", 1,
        "Base.Earbuds", 2,
        "Crisps", 4,
    },
    junk = {
        rolls = 5,
        items = {
            "Base.Battery", 6,
            "Money", 10,
        },
    },
}

VehicleDistributions.TrueMoozicStepVan = {
    TruckBed = VehicleDistributions.TrueMoozicStepVanTruckBed,
    GloveBox = VehicleDistributions.TrueMoozicStepVanGloveBox,
}

VehicleDistributions[1] = VehicleDistributions[1] or {}
VehicleDistributions[1]["TrueMoozicStepVan"] = {
    Normal = VehicleDistributions.TrueMoozicStepVan,
}

------------------------------------------------------------------------
--  Dynamic media injection
--
--  Scan every script item and add all playable music media (cassettes,
--  vinyl records/albums, CD albums) from non-Base modules to the van's
--  trunk and glovebox. This picks up the base mod's media AND every
--  installed add-on music pack without needing the pack detector.
------------------------------------------------------------------------

local TRUNK_MEDIA_WEIGHT    = 3
local GLOVEBOX_MEDIA_WEIGHT = 1

local function isMediaTypeName(typeName)
    local lower = string.lower(typeName)
    -- Exclude devices and containers that contain the media words.
    if string.find(lower, "player", 1, true)
        or string.find(lower, "case", 1, true)
        or string.find(lower, "bag", 1, true)
        or string.find(lower, "boombox", 1, true)
        or string.find(lower, "walkman", 1, true) then
        return false
    end
    if string.find(lower, "cassette", 1, true) then return true end
    if string.find(lower, "vinyl", 1, true) then return true end
    if string.sub(typeName, 1, 3) == "CD_" then return true end
    if string.len(typeName) > 2 and string.sub(typeName, -2) == "CD" then return true end
    return false
end

local function distContains(items, fullType)
    for i = 1, #items, 2 do
        if items[i] == fullType then return true end
    end
    return false
end

local function addMedia(dist, fullType, weight)
    if not distContains(dist.items, fullType) then
        table.insert(dist.items, fullType)
        table.insert(dist.items, weight)
    end
end

local function injectAllMediaIntoStepVan()
    local allItems = getAllItems()
    if not allItems then return end
    local trunk    = VehicleDistributions.TrueMoozicStepVanTruckBed
    local glovebox = VehicleDistributions.TrueMoozicStepVanGloveBox
    local count = 0
    for i = 0, allItems:size() - 1 do
        local item = allItems:get(i)
        if item then
            local fullType = item:getFullName()
            local module = fullType and string.match(fullType, "^([^%.]+)%.") or nil
            local typeName = fullType and string.match(fullType, "%.(.+)$") or nil
            if module and module ~= "Base" and typeName and isMediaTypeName(typeName) then
                addMedia(trunk, fullType, TRUNK_MEDIA_WEIGHT)
                addMedia(glovebox, fullType, GLOVEBOX_MEDIA_WEIGHT)
                count = count + 1
            end
        end
    end
    print("[TrueMoozic] StepVan loot: injected " .. count .. " media items")
end

-- OnPostDistributionMerge runs before world generation / container fills.
Events.OnPostDistributionMerge.Add(injectAllMediaIntoStepVan)