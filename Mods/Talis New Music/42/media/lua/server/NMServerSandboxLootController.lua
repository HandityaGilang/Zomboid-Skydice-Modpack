require "loot/NMManagedSpawnCatalog"

-- Sandbox-driven loot scaling and child-pack distribution ownership controller.
local BASE_MEDIA_DEFAULT = 0.6
local BASE_DEVICE_DEFAULT = 0.6
local DEVICE_INTENSITY_MULTIPLIER = 0.25
local DISTRIBUTION_AUDIT_ENABLED = false

local CATEGORY_ORDER = {
    "cassettes",
    "vinyl",
    "cds",
    "walkman",
    "boombox",
    "cdplayer",
    "recordplayer"
}

local MEDIA_CATEGORY_ORDER = {
    "cassettes",
    "vinyl",
    "cds"
}

local DEVICE_CATEGORY_ORDER = {
    "walkman",
    "boombox",
    "cdplayer",
    "recordplayer"
}

local VEHICLE_ROLE_ORDER = {
    "glovebox",
    "seatrear",
    "cargo"
}

local VEHICLE_RESPONSE_BASE = 0.18
local VEHICLE_RESPONSE_EXPONENT = 0.72
local MEDIA_DIRECT_SPAWN_SCALE_BASE = 0.5
local DEVICE_DIRECT_SPAWN_SCALE_BASE = 0.35

local VEHICLE_ROLE_WEIGHT_CURVES = {
    cassettes = {
        glovebox = { low = 30.00, high = 40.00 },
        seatrear = { low = 0.20, high = 0.90 },
        cargo = { low = 0.24, high = 1.80 }
    },
    vinyl = {
        glovebox = { low = 0.0, high = 0.0 },
        seatrear = { low = 0.0, high = 0.0 },
        cargo = { low = 0.10, high = 1.30 }
    },
    cds = {
        glovebox = { low = 1.20, high = 2.40 },
        seatrear = { low = 0.22, high = 0.95 },
        cargo = { low = 0.22, high = 1.60 }
    },
    walkman = {
        glovebox = { low = 0.10, high = 1.00 },
        seatrear = { low = 0.05, high = 0.55 },
        cargo = { low = 0.08, high = 0.85 }
    },
    boombox = {
        glovebox = { low = 0.0, high = 0.0 },
        seatrear = { low = 0.0, high = 0.0 },
        cargo = { low = 0.08, high = 0.75 }
    },
    cdplayer = {
        glovebox = { low = 0.10, high = 0.95 },
        seatrear = { low = 0.05, high = 0.50 },
        cargo = { low = 0.08, high = 0.80 }
    },
    recordplayer = {
        glovebox = { low = 0.0, high = 0.0 },
        seatrear = { low = 0.0, high = 0.0 },
        cargo = { low = 0.03, high = 0.24 }
    }
}

local MEDIA_PROCEDURAL_TARGETS = {
    cassettes = {
        { name = "MusicStoreCDs", weight = 18.0 },
        { name = "MusicStoreShelves", weight = 12.0 },
        { name = "MusicStoreCounter", weight = 10.0 },
        { name = "MusicStoreSpeaker", weight = 10.0 },
        { name = "MusicStoreOthers", weight = 8.0 },
        { name = "ElectronicStoreMusic", weight = 6.0 },
        { name = "CrateElectronics", weight = 4.0 },
        { name = "ElectronicStoreCases", weight = 4.0 },
        { name = "ElectronicStoreMisc", weight = 3.0 },
        { name = "GigamartHouseElectronics", weight = 2.0 },
        { name = "CrateCompactDiscs", weight = 6.0 },
        { name = "BookstoreMusic", weight = 2.0 },
        { name = "LibraryMusic", weight = 1.5 },
        { name = "UniversityLibraryMusic", weight = 1.5 },
        { name = "RecRoomShelf", weight = 1.5 },
        { name = "SchoolLockers", weight = 6.0 },
        { name = "SchoolLockersBad", weight = 6.0 },
        { name = "SchoolDesk", weight = 3.0 },
        { name = "LivingRoomShelf", weight = 4.0 },
        { name = "LivingRoomShelfClassy", weight = 4.0 },
        { name = "LivingRoomShelfRedneck", weight = 4.0 },
        { name = "LivingRoomShelfNoTapes", weight = 3.0 },
        { name = "LivingRoomSideTable", weight = 2.5 },
        { name = "LivingRoomCabinet", weight = 2.5 },
        { name = "BedroomDresser", weight = 3.0 },
        { name = "BedroomDresserClassy", weight = 3.0 },
        { name = "StoreShelfCombo", weight = 1.5 },
    },
    vinyl = {
        { name = "MusicStoreCases", weight = 1080.0 },
        { name = "MusicStoreCDs", weight = 720.0 },
        { name = "MusicStoreShelves", weight = 960.0 },
        { name = "MusicStoreCounter", weight = 560.0 },
        { name = "MusicStoreSpeaker", weight = 600.0 },
        { name = "ElectronicStoreMusic", weight = 5.0 },
        { name = "CrateElectronics", weight = 3.0 },
        { name = "ElectronicStoreCases", weight = 3.0 },
        { name = "ElectronicStoreMisc", weight = 2.0 },
        { name = "GigamartHouseElectronics", weight = 1.5 },
        { name = "CrateCompactDiscs", weight = 4.0 },
        { name = "BookstoreMusic", weight = 1.5 },
        { name = "LibraryMusic", weight = 1.0 },
        { name = "UniversityLibraryMusic", weight = 1.0 },
        { name = "RecRoomShelf", weight = 1.0 },
        { name = "SchoolLockers", weight = 1.0 },
        { name = "SchoolLockersBad", weight = 1.0 },
        { name = "LivingRoomShelf", weight = 3.0 },
        { name = "LivingRoomShelfClassy", weight = 3.0 },
        { name = "LivingRoomShelfRedneck", weight = 2.0 },
        { name = "LivingRoomSideTable", weight = 1.5 },
        { name = "LivingRoomCabinet", weight = 2.0 },
        { name = "BedroomDresser", weight = 2.0 },
        { name = "StoreShelfCombo", weight = 1.0 },
    },
    cds = {
        { name = "MusicStoreCDs", weight = 18.0 },
        { name = "MusicStoreShelves", weight = 12.0 },
        { name = "MusicStoreCounter", weight = 10.0 },
        { name = "MusicStoreSpeaker", weight = 10.0 },
        { name = "MusicStoreOthers", weight = 8.0 },
        { name = "ElectronicStoreMusic", weight = 6.0 },
        { name = "CrateElectronics", weight = 4.0 },
        { name = "ElectronicStoreCases", weight = 4.0 },
        { name = "ElectronicStoreMisc", weight = 3.0 },
        { name = "GigamartHouseElectronics", weight = 2.0 },
        { name = "CrateCompactDiscs", weight = 6.0 },
        { name = "BookstoreMusic", weight = 2.0 },
        { name = "LibraryMusic", weight = 1.5 },
        { name = "UniversityLibraryMusic", weight = 1.5 },
        { name = "RecRoomShelf", weight = 1.5 },
        { name = "SchoolLockers", weight = 6.0 },
        { name = "SchoolLockersBad", weight = 6.0 },
        { name = "SchoolDesk", weight = 3.0 },
        { name = "LivingRoomShelf", weight = 6.0 },
        { name = "LivingRoomShelfClassy", weight = 6.0 },
        { name = "LivingRoomShelfRedneck", weight = 4.0 },
        { name = "LivingRoomShelfNoTapes", weight = 3.0 },
        { name = "LivingRoomSideTable", weight = 2.5 },
        { name = "LivingRoomCabinet", weight = 3.0 },
        { name = "BedroomDresser", weight = 3.0 },
        { name = "BedroomDresserClassy", weight = 3.0 },
        { name = "StoreShelfCombo", weight = 1.5 },
    }
}

local DEVICE_PROCEDURAL_TARGETS = {
    walkman = {
        { name = "MusicStoreCDs", weight = 16.0 },
        { name = "MusicStoreShelves", weight = 18.0 },
        { name = "MusicStoreCounter", weight = 12.0 },
        { name = "MusicStoreOthers", weight = 16.0 },
        { name = "ElectronicStoreMusic", weight = 4.0 },
        { name = "ElectronicStoreSpeaker", weight = 4.0 },
        { name = "CrateElectronics", weight = 4.0 },
        { name = "ElectronicStoreCases", weight = 2.0 },
        { name = "ElectronicStoreMisc", weight = 2.0 },
        { name = "GigamartHouseElectronics", weight = 1.0 },
        { name = "StoreShelfElectronics", weight = 1.5 },
        { name = "BookstoreMusic", weight = 1.0 },
        { name = "LibraryMusic", weight = 0.5 },
        { name = "UniversityLibraryMusic", weight = 0.5 },
        { name = "RecRoomShelf", weight = 0.5 },
        { name = "SchoolLockers", weight = 3.0 },
        { name = "SchoolLockersBad", weight = 3.0 },
        { name = "SchoolDesk", weight = 1.5 },
        { name = "LivingRoomShelf", weight = 3.0 },
        { name = "LivingRoomShelfClassy", weight = 3.0 },
        { name = "LivingRoomShelfRedneck", weight = 3.0 },
        { name = "LivingRoomShelfNoTapes", weight = 2.0 },
        { name = "LivingRoomSideTable", weight = 1.5 },
        { name = "LivingRoomCabinet", weight = 1.5 },
        { name = "BedroomDresser", weight = 3.0 },
        { name = "BedroomDresserClassy", weight = 3.0 },
        { name = "StoreShelfCombo", weight = 0.5 },
    },
    boombox = {
        { name = "MusicStoreCDs", weight = 10.0 },
        { name = "MusicStoreShelves", weight = 12.0 },
        { name = "MusicStoreCounter", weight = 8.0 },
        { name = "MusicStoreOthers", weight = 10.0 },
        { name = "ElectronicStoreMusic", weight = 3.0 },
        { name = "ElectronicStoreSpeaker", weight = 3.0 },
        { name = "CrateElectronics", weight = 3.0 },
        { name = "ElectronicStoreCases", weight = 1.5 },
        { name = "ElectronicStoreMisc", weight = 1.5 },
        { name = "GigamartHouseElectronics", weight = 0.75 },
        { name = "StoreShelfElectronics", weight = 1.0 },
        { name = "BookstoreMusic", weight = 0.5 },
        { name = "LibraryMusic", weight = 0.25 },
        { name = "UniversityLibraryMusic", weight = 0.25 },
        { name = "RecRoomShelf", weight = 0.25 },
        { name = "SchoolLockers", weight = 1.5 },
        { name = "SchoolLockersBad", weight = 1.5 },
        { name = "LivingRoomShelf", weight = 3.0 },
        { name = "LivingRoomShelfClassy", weight = 3.0 },
        { name = "LivingRoomShelfRedneck", weight = 3.0 },
        { name = "LivingRoomSideTable", weight = 0.75 },
        { name = "LivingRoomCabinet", weight = 1.0 },
        { name = "StoreShelfCombo", weight = 0.25 },
    },
    cdplayer = {
        { name = "MusicStoreCDs", weight = 18.0 },
        { name = "MusicStoreShelves", weight = 20.0 },
        { name = "MusicStoreCounter", weight = 14.0 },
        { name = "ElectronicStoreMusic", weight = 5.0 },
        { name = "ElectronicStoreSpeaker", weight = 4.0 },
        { name = "CrateElectronics", weight = 5.0 },
        { name = "ElectronicStoreCases", weight = 3.0 },
        { name = "ElectronicStoreMisc", weight = 3.0 },
        { name = "GigamartHouseElectronics", weight = 1.5 },
        { name = "StoreShelfElectronics", weight = 2.0 },
        { name = "BookstoreMusic", weight = 1.0 },
        { name = "LibraryMusic", weight = 0.75 },
        { name = "UniversityLibraryMusic", weight = 0.75 },
        { name = "RecRoomShelf", weight = 0.75 },
        { name = "SchoolLockers", weight = 4.0 },
        { name = "SchoolLockersBad", weight = 4.0 },
        { name = "SchoolDesk", weight = 2.0 },
        { name = "LivingRoomShelf", weight = 2.0 },
        { name = "LivingRoomShelfClassy", weight = 2.0 },
        { name = "LivingRoomShelfRedneck", weight = 2.0 },
        { name = "LivingRoomShelfNoTapes", weight = 1.5 },
        { name = "LivingRoomSideTable", weight = 1.0 },
        { name = "LivingRoomCabinet", weight = 1.0 },
        { name = "BedroomDresser", weight = 1.0 },
        { name = "BedroomDresserClassy", weight = 1.0 },
        { name = "StoreShelfCombo", weight = 0.5 },
    },
    recordplayer = {
        { name = "MusicStoreSpeaker", weight = 4480.0 },
        { name = "MusicStoreShelves", weight = 11520.0 },
        { name = "MusicStoreCounter", weight = 7680.0 },
        { name = "ElectronicStoreMusic", weight = 2.0 },
        { name = "CrateElectronics", weight = 2.0 },
        { name = "ElectronicStoreCases", weight = 1.0 },
        { name = "ElectronicStoreMisc", weight = 1.0 },
        { name = "GigamartHouseElectronics", weight = 0.5 },
        { name = "StoreShelfElectronics", weight = 0.75 },
        { name = "BookstoreMusic", weight = 0.25 },
        { name = "LibraryMusic", weight = 0.15 },
        { name = "UniversityLibraryMusic", weight = 0.15 },
        { name = "RecRoomShelf", weight = 0.15 },
        { name = "LivingRoomShelfClassy", weight = 1.0 },
        { name = "LivingRoomShelf", weight = 0.5 },
        { name = "LivingRoomCabinet", weight = 0.75 },
        { name = "StoreShelfCombo", weight = 0.15 },
    }
}

local MEDIA_VEHICLE_ROLE_WEIGHTS = {
    cassettes = { glovebox = 0.04, seatrear = 0.03, cargo = 0.10 },
    vinyl = { glovebox = 0.0, seatrear = 0.0, cargo = 0.07 },
    cds = { glovebox = 0.04, seatrear = 0.03, cargo = 0.07 }
}

local DEVICE_VEHICLE_ROLE_WEIGHTS = {
    walkman = { glovebox = 0.015, seatrear = 0.02, cargo = 0.03 },
    boombox = { glovebox = 0.0, seatrear = 0.0, cargo = 0.03 },
    cdplayer = { glovebox = 0.012, seatrear = 0.015, cargo = 0.03 },
    recordplayer = { glovebox = 0.0, seatrear = 0.0, cargo = 0.015 }
}

local MEDIA_MAIL_TARGETS = {
    cassettes = {
        { kind = "suburbs", name = "Bag_Mail", weight = 0.003 },
        { kind = "suburbs", name = "Bag_Satchel_Mail", weight = 0.003 },
        { kind = "procedural", name = "PostOfficeParcels", weight = 0.01 }
    },
    vinyl = {
        { kind = "procedural", name = "PostOfficeParcels", weight = 0.004 }
    },
    cds = {
        { kind = "suburbs", name = "Bag_Mail", weight = 0.003 },
        { kind = "suburbs", name = "Bag_Satchel_Mail", weight = 0.003 },
        { kind = "procedural", name = "PostOfficeParcels", weight = 0.01 }
    }
}

local DEVICE_MAIL_TARGETS = {
    walkman = {
        { kind = "procedural", name = "PostOfficeParcels", weight = 0.008 }
    },
    boombox = {
        { kind = "procedural", name = "PostOfficeParcels", weight = 0.003 }
    },
    cdplayer = {
        { kind = "procedural", name = "PostOfficeParcels", weight = 0.008 }
    },
    recordplayer = {
        { kind = "procedural", name = "PostOfficeParcels", weight = 0.0015 }
    }
}

local BASE_ZOMBOID_OST_MEDIA = {
    ["NewMusic.CassettePZOSTA"] = true,
    ["NewMusic.CassettePZOSTB"] = true,
    ["NewMusic.CassettePZOSTCaseEmpty"] = true,
    ["NewMusic.CassettePZOSTCaseFull"] = true,
    ["NewMusic.CDPZOSTA"] = true,
    ["NewMusic.CDPZOSTB"] = true,
    ["NewMusic.CDPZOSTCoverEmpty"] = true,
    ["NewMusic.CDPZOSTCoverFull"] = true,
    ["NewMusic.VinylPZOSTA"] = true,
    ["NewMusic.VinylPZOSTB"] = true,
    ["NewMusic.JacketPZOSTEmpty"] = true,
    ["NewMusic.JacketPZOSTFull"] = true,
}

local function toLower(value)
    return string.lower(tostring(value or ""))
end

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function splitFullType(fullType)
    local raw = tostring(fullType or "")
    local dot = string.find(raw, "%.")
    if not dot then
        return "", raw
    end
    return string.sub(raw, 1, dot - 1), string.sub(raw, dot + 1)
end

local function countItemsInMap(itemMap)
    local n = 0
    for _ in pairs(itemMap or {}) do
        n = n + 1
    end
    return n
end

local function countTrueEntries(map)
    local n = 0
    for _, enabled in pairs(map or {}) do
        if enabled == true then
            n = n + 1
        end
    end
    return n
end

local function clamp(value, minValue, maxValue)
    local n = tonumber(value) or 0
    if n < minValue then
        return minValue
    end
    if n > maxValue then
        return maxValue
    end
    return n
end

local function formatCountMap(map, order)
    local parts = {}
    local keys = order or CATEGORY_ORDER
    for i = 1, #keys do
        local key = keys[i]
        parts[#parts + 1] = key .. "=" .. tostring(tonumber(map and map[key]) or 0)
    end
    return table.concat(parts, " ")
end

local function formatNameSet(nameSet)
    local names = {}
    for name, enabled in pairs(nameSet or {}) do
        if enabled == true then
            names[#names + 1] = tostring(name)
        end
    end
    table.sort(names)
    return table.concat(names, ",")
end

local function formatStringArray(values)
    local out = {}
    for i = 1, #(values or {}) do
        out[i] = tostring(values[i])
    end
    table.sort(out)
    return table.concat(out, ",")
end

local function logLoot(tag, detail)
    if NMCore and NMCore.logChannel then
        NMCore.logChannel("lootDiagnostics", tostring(tag or "sandbox.loot"), tostring(detail or ""))
    end
end

local function legacyLooseCategoryMatch(typeName)
    local lower = toLower(typeName)
    if lower == "" then
        return nil
    end
    if string.find(lower, "walkman", 1, true) then
        return "walkman"
    end
    if string.find(lower, "boombox", 1, true) then
        return "boombox"
    end
    if string.find(lower, "cdplayer", 1, true) then
        return "cdplayer"
    end
    if string.find(lower, "vinylplayer", 1, true) or string.find(lower, "recordplayer", 1, true) then
        return "recordplayer"
    end
    if string.find(lower, "cassette", 1, true) then
        if string.find(lower, "case", 1, true) or string.find(lower, "cover", 1, true) then
            return nil
        end
        return "cassettes"
    end
    if string.find(lower, "vinyl", 1, true) then
        if string.find(lower, "cover", 1, true) or string.find(lower, "jacket", 1, true) then
            return nil
        end
        return "vinyl"
    end
    if lower == "cd" or lower == "nm_cd" then
        return "cds"
    end
    if string.find(lower, "cd", 1, true) and not string.find(lower, "cover", 1, true) and not string.find(lower, "case", 1, true) then
        return "cds"
    end
    return nil
end

local function resolveMediaCategoryFromCarrier(carrier)
    local c = tostring(carrier or "")
    if not (NMMediaContract and NMMediaContract.getLegacyCarriers) then
        return nil
    end
    local carriers = NMMediaContract.getLegacyCarriers()
    if c == tostring(carriers.cassette or "") then
        return "cassettes"
    end
    if c == tostring(carriers.vinyl or "") then
        return "vinyl"
    end
    if c == tostring(carriers.cd or "") then
        return "cds"
    end
    return nil
end

local function resolveRegisteredMediaCarrier(fullType)
    local _, itemType = splitFullType(fullType)
    local mapped = type(GlobalMusic) == "table" and GlobalMusic[itemType] or nil
    if mapped and tostring(mapped) ~= "" then
        return tostring(mapped)
    end
    return nil
end

local function resolveDeviceCategoryFromProfile(profile)
    local deviceType = toLower(profile and profile.deviceType or "")
    if deviceType == "walkman" then
        return "walkman"
    end
    if deviceType == "boombox" then
        return "boombox"
    end
    if deviceType == "cdplayer" then
        return "cdplayer"
    end
    if deviceType == "vinylplayer" or deviceType == "recordplayer" then
        return "recordplayer"
    end
    return nil
end

local function isTargetModId(modId)
    local lower = toLower(modId)
    return lower == "newmusic" or lower == "talisnewmusic"
end

local function valueContainsRequiredMod(value, expectedModId)
    local expected = toLower(expectedModId)
    if expected == "" or value == nil then
        return false
    end

    if type(value) == "string" then
        local lower = toLower(value)
        for token in string.gmatch(lower, "[^,;]+") do
            if trim(token) == expected then
                return true
            end
        end
        return trim(lower) == expected
    end

    if type(value) == "table" then
        for _, entry in pairs(value) do
            if valueContainsRequiredMod(entry, expected) then
                return true
            end
        end
        return false
    end

    if type(value) == "userdata" then
        local okSize, size = pcall(function()
            return value:size()
        end)
        if okSize and type(size) == "number" then
            for i = 0, size - 1 do
                local okEntry, entry = pcall(function()
                    return value:get(i)
                end)
                if okEntry and valueContainsRequiredMod(entry, expected) then
                    return true
                end
            end
        end
    end

    return false
end

local function buildCompatibleChildModSet()
    local compatible = {}
    if not (getActivatedMods and getModInfoByID) then
        return compatible
    end

    local activated = getActivatedMods()
    if not activated then
        return compatible
    end

    local okSize, size = pcall(function()
        return activated:size()
    end)
    if not okSize or type(size) ~= "number" then
        return compatible
    end

    local candidateMethods = {
        "getRequire",
        "getRequireString",
        "getRequireValue",
        "getRequireList"
    }

    for i = 0, size - 1 do
        local modId = tostring(activated:get(i) or "")
        if modId ~= "" and not isTargetModId(modId) then
            local modInfo = getModInfoByID(modId)
            if modInfo then
                for _, methodName in ipairs(candidateMethods) do
                    local method = modInfo[methodName]
                    if method then
                        local okValue, value = pcall(method, modInfo)
                        if okValue and valueContainsRequiredMod(value, "NewMusic") then
                            compatible[toLower(modId)] = true
                            break
                        end
                    end
                end
            end
        end
    end

    return compatible
end

local function listHasItem(items, fullType)
    if type(items) ~= "table" then
        return false
    end
    for i = 1, #items, 2 do
        if tostring(items[i]) == fullType then
            return true
        end
    end
    return false
end

local function addItemIfMissing(items, fullType, weight)
    if type(items) ~= "table" then
        return false
    end
    if listHasItem(items, fullType) then
        return false
    end
    table.insert(items, fullType)
    table.insert(items, weight)
    return true
end

local function applyItemMultiplierInList(items, fullType, multiplier)
    if type(items) ~= "table" then
        return 0
    end
    local touched = 0
    for i = 1, #items, 2 do
        if tostring(items[i]) == fullType and type(items[i + 1]) == "number" then
            items[i + 1] = math.max(0, items[i + 1] * multiplier)
            touched = touched + 1
        end
    end
    return touched
end

local function removeItemFromListByType(items, fullType)
    if type(items) ~= "table" then
        return nil
    end
    for i = #items - 1, 1, -2 do
        if tostring(items[i]) == fullType and type(items[i + 1]) == "number" then
            local weight = items[i + 1]
            table.remove(items, i + 1)
            table.remove(items, i)
            return tonumber(weight) or 0
        end
    end
    return nil
end

local function replaceItemInList(items, oldFullType, newFullType)
    if type(items) ~= "table" then
        return 0
    end
    if tostring(oldFullType or "") == "" or tostring(newFullType or "") == "" then
        return 0
    end
    local touched = 0
    while true do
        local weight = removeItemFromListByType(items, oldFullType)
        if weight == nil then
            break
        end
        local replaced = false
        for i = 1, #items, 2 do
            if tostring(items[i]) == newFullType and type(items[i + 1]) == "number" then
                items[i + 1] = math.max(0, items[i + 1] + weight)
                replaced = true
                break
            end
        end
        if not replaced then
            table.insert(items, newFullType)
            table.insert(items, math.max(0, weight))
        end
        touched = touched + 1
    end
    return touched
end

local function resolveVehicleContainerRole(key)
    local lower = toLower(key)
    if lower == "glovebox" then
        return "glovebox"
    end
    if lower == "seatrear" or lower == "seatrearleft" or lower == "seatrearright" or lower == "seatrearcenter" then
        return "seatrear"
    end
    if lower == "trunk" or lower == "trailertrunk" or lower == "truckbed" or lower == "truckbedopen" or lower == "truckbed2" then
        return "cargo"
    end
    return nil
end

local function visitVehicleDistributionTables(callback)
    if not VehicleDistributions then
        return
    end

    local visited = {}
    local function visit(node)
        if type(node) ~= "table" or visited[node] then
            return
        end
        visited[node] = true

        if type(node.items) == "table" then
            callback(node.items)
        end

        for key, value in pairs(node) do
            if key ~= "items" and key ~= "junk" and key ~= "rolls" and type(value) == "table" then
                visit(value)
            end
        end
    end

    visit(VehicleDistributions)
end

local function collectAllowedVehicleTargets()
    local targets = {}
    if not VehicleDistributions then
        return targets
    end

    local visited = {}
    local seenItems = {}

    local function addTarget(role, items)
        if not role or type(items) ~= "table" then
            return
        end
        seenItems[role] = seenItems[role] or {}
        if seenItems[role][items] then
            return
        end
        seenItems[role][items] = true
        targets[#targets + 1] = { role = role, items = items }
    end

    local function visit(node, activeRole)
        if type(node) ~= "table" then
            return
        end

        local visitKey = tostring(activeRole or "__none")
        visited[node] = visited[node] or {}
        if visited[node][visitKey] then
            return
        end
        visited[node][visitKey] = true

        if activeRole and type(node.items) == "table" then
            addTarget(activeRole, node.items)
        end

        for key, value in pairs(node) do
            if key ~= "items" and key ~= "junk" and key ~= "rolls" and type(value) == "table" then
                local nextRole = activeRole or resolveVehicleContainerRole(key)
                visit(value, nextRole)
            end
        end
    end

    visit(VehicleDistributions, nil)
    return targets
end

local function visitDistributionTables(callback)
    if type(callback) ~= "function" then
        return
    end
    if ProceduralDistributions and ProceduralDistributions.list then
        for _, dist in pairs(ProceduralDistributions.list) do
            if type(dist) == "table" and type(dist.items) == "table" then
                callback(dist.items)
            end
            if type(dist) == "table" and type(dist.junk) == "table" and type(dist.junk.items) == "table" then
                callback(dist.junk.items)
            end
        end
    end
    if SuburbsDistributions then
        for _, location in pairs(SuburbsDistributions) do
            if type(location) == "table" then
                for _, room in pairs(location) do
                    if type(room) == "table" then
                        if type(room.items) == "table" then callback(room.items) end
                        if type(room.counter) == "table" and type(room.counter.items) == "table" then callback(room.counter.items) end
                        if type(room.metal_shelves) == "table" and type(room.metal_shelves.items) == "table" then callback(room.metal_shelves.items) end
                        if type(room.shelves) == "table" and type(room.shelves.items) == "table" then callback(room.shelves.items) end
                        if type(room.crate) == "table" and type(room.crate.items) == "table" then callback(room.crate.items) end
                    end
                end
            end
        end
    end
    visitVehicleDistributionTables(callback)
end

local function buildLoadedContainerOverrideRegistry(allItems)
    local overrides = {
        mediaToContainer = {},
        canonicalToLoadedContainer = {},
        loadedRepresentatives = {}
    }
    if not (NMMediaContract and NMMediaContract.resolveContainerMediaBinding and NMMediaContract.isContainerLoadedFullType) then
        return overrides
    end
    if not allItems then
        return overrides
    end

    for i = 0, allItems:size() - 1 do
        local item = allItems:get(i)
        if item then
            local containerFullType = tostring(item:getFullName() or "")
            local boundMedia = NMMediaContract.resolveContainerMediaBinding(containerFullType)
            if boundMedia and boundMedia ~= "" and NMMediaContract.isContainerLoadedFullType(containerFullType) == true then
                local canonical = NMMediaContract.resolveMediaCanonical and NMMediaContract.resolveMediaCanonical(boundMedia) or boundMedia
                canonical = tostring(canonical or boundMedia)
                if canonical ~= "" then
                    overrides.mediaToContainer[canonical] = containerFullType
                    overrides.canonicalToLoadedContainer[canonical] = containerFullType
                    overrides.loadedRepresentatives[containerFullType] = true
                end
            end
        end
    end

    return overrides
end

local function getRawSandboxLootSettings()
    local page = type(SandboxVars) == "table" and type(SandboxVars.NewMusic) == "table" and SandboxVars.NewMusic or nil
    return {
        cassettes = page and page.CassettesSpawnRate or nil,
        vinyl = page and page.VinylRecordsSpawnRate or nil,
        cds = page and page.CDsSpawnRate or nil,
        walkman = page and page.WalkmanSpawnRate or nil,
        boombox = page and page.BoomboxSpawnRate or nil,
        cdplayer = page and page.CDPlayerSpawnRate or nil,
        recordplayer = page and page.RecordPlayerSpawnRate or nil
    }
end

local function resolveCategoryRate(category)
    if category == "cassettes" then
        return NMRuntimeConfig.getCassettesSpawnRate() or BASE_MEDIA_DEFAULT
    end
    if category == "vinyl" then
        return NMRuntimeConfig.getVinylRecordsSpawnRate() or BASE_MEDIA_DEFAULT
    end
    if category == "cds" then
        return NMRuntimeConfig.getCDsSpawnRate() or BASE_MEDIA_DEFAULT
    end
    if category == "walkman" then
        return NMRuntimeConfig.getWalkmanSpawnRate() or BASE_DEVICE_DEFAULT
    end
    if category == "boombox" then
        return NMRuntimeConfig.getBoomboxSpawnRate() or BASE_DEVICE_DEFAULT
    end
    if category == "cdplayer" then
        return NMRuntimeConfig.getCDPlayerSpawnRate() or BASE_DEVICE_DEFAULT
    end
    if category == "recordplayer" then
        return NMRuntimeConfig.getRecordPlayerSpawnRate() or BASE_DEVICE_DEFAULT
    end
    return BASE_MEDIA_DEFAULT
end

local function resolveCategoryMultiplier(category)
    local rate = clamp(resolveCategoryRate(category), 0.0, 4.0)
    local baseRate = BASE_MEDIA_DEFAULT
    if category == "walkman" or category == "boombox" or category == "cdplayer" or category == "recordplayer" then
        baseRate = BASE_DEVICE_DEFAULT
    end
    if tonumber(baseRate) == nil or baseRate <= 0 then
        baseRate = BASE_MEDIA_DEFAULT
    end
    return rate / baseRate
end

local function resolveDirectSpawnScalar(rate, defaultRate, baseScale)
    local r = clamp(rate, 0.0, 4.0)
    if r <= 0 then
        return 0
    end
    local base = tonumber(defaultRate) or BASE_MEDIA_DEFAULT
    if base <= 0 then
        base = BASE_MEDIA_DEFAULT
    end
    return (tonumber(baseScale) or 0.25) * (r / base)
end

local function normalizePlayableRate(rate)
    local r = clamp(rate, 0.0, 4.0)
    if r <= 0 then
        return 0
    end
    if r <= BASE_MEDIA_DEFAULT then
        return (r / BASE_MEDIA_DEFAULT) * VEHICLE_RESPONSE_BASE
    end
    local t = (r - BASE_MEDIA_DEFAULT) / (4.0 - BASE_MEDIA_DEFAULT)
    return clamp(VEHICLE_RESPONSE_BASE + ((1.0 - VEHICLE_RESPONSE_BASE) * math.pow(t, VEHICLE_RESPONSE_EXPONENT)), 0.0, 1.0)
end

local function resolveLoadedSpawnRepresentative(fullType, canonicalMedia, overrides)
    local current = tostring(fullType or "")
    local canonical = tostring(canonicalMedia or "")
    local loaded = overrides and overrides.canonicalToLoadedContainer and overrides.canonicalToLoadedContainer[canonical] or nil
    if loaded and loaded ~= "" then
        return loaded
    end

    if NMMediaContract and NMMediaContract.resolveContainerMediaBinding then
        local boundMedia = NMMediaContract.resolveContainerMediaBinding(current)
        if boundMedia and boundMedia ~= "" then
            if NMMediaContract.resolveContainerSwapFullType then
                local swapLoaded = NMMediaContract.resolveContainerSwapFullType(current, true)
                if swapLoaded and swapLoaded ~= "" then
                    return swapLoaded
                end
            end
            if NMMediaContract.isContainerLoadedFullType and NMMediaContract.isContainerLoadedFullType(current) == true then
                return current
            end
            return nil
        end
    end

    return nil
end

local function resolveManagedMediaUnit(fullType, overrides)
    local current = tostring(fullType or "")
    if current == "" then
        return nil
    end

    local boundMedia = NMMediaContract and NMMediaContract.resolveContainerMediaBinding and NMMediaContract.resolveContainerMediaBinding(current) or nil
    if boundMedia and boundMedia ~= "" then
        local canonical = NMMediaContract and NMMediaContract.resolveMediaCanonical and NMMediaContract.resolveMediaCanonical(boundMedia) or boundMedia
        canonical = tostring(canonical or boundMedia)
        local category = resolveMediaCategoryFromCarrier(resolveRegisteredMediaCarrier(canonical))
        local loaded = resolveLoadedSpawnRepresentative(current, canonical, overrides)
        if category and loaded and loaded ~= "" then
            return {
                category = category,
                canonicalKey = canonical,
                spawnFullType = loaded,
                loadedOnly = true
            }
        end
        return nil
    end

    local canonical = NMMediaContract and NMMediaContract.resolveMediaCanonical and NMMediaContract.resolveMediaCanonical(current) or current
    canonical = tostring(canonical or current)
    local category = resolveMediaCategoryFromCarrier(resolveRegisteredMediaCarrier(canonical))
    if not category then
        return nil
    end

    local loaded = resolveLoadedSpawnRepresentative(current, canonical, overrides)
    if loaded and loaded ~= "" then
        return {
            category = category,
            canonicalKey = canonical,
            spawnFullType = loaded,
            loadedOnly = true
        }
    end

    return {
        category = category,
        canonicalKey = canonical,
        spawnFullType = canonical,
        loadedOnly = false
    }
end

local function resolveManagedDeviceUnit(fullType)
    if not (NMDeviceProfiles and NMDeviceProfiles.getForFullType) then
        return nil
    end
    local profile = NMDeviceProfiles.getForFullType(fullType)
    if not profile or profile.isMediaContainerOnly == true then
        return nil
    end
    local category = resolveDeviceCategoryFromProfile(profile)
    if not category then
        return nil
    end
    return {
        category = category,
        key = tostring(fullType or ""),
        spawnFullType = tostring(fullType or "")
    }
end

local function newCategoryMaps()
    local out = {}
    for i = 1, #CATEGORY_ORDER do
        out[CATEGORY_ORDER[i]] = {}
    end
    return out
end

local function newUnitPools()
    return {
        media = newCategoryMaps(),
        devices = newCategoryMaps()
    }
end

local function addMediaUnit(targetPools, unit, metadata)
    if not unit or not unit.category or not unit.canonicalKey then
        return false
    end
    local category = tostring(unit.category)
    local bucket = targetPools.media[category]
    if type(bucket) ~= "table" then
        return false
    end
    local key = tostring(unit.canonicalKey)
    local existing = bucket[key]
    local loadedOnly = metadata and metadata.loadedOnly == true
    if existing then
        if loadedOnly and existing.loadedOnly ~= true and tostring(unit.spawnFullType or "") ~= "" then
            existing.spawnFullType = tostring(unit.spawnFullType)
            existing.loadedOnly = true
        end
        return false
    end
    bucket[key] = {
        key = key,
        canonical = key,
        spawnFullType = tostring(unit.spawnFullType or ""),
        loadedOnly = loadedOnly,
        modId = metadata and metadata.modId or "",
        owner = metadata and metadata.owner or ""
    }
    return true
end

local function addDeviceUnit(targetPools, unit, metadata)
    if not unit or not unit.category or not unit.key then
        return false
    end
    local category = tostring(unit.category)
    local bucket = targetPools.devices[category]
    if type(bucket) ~= "table" then
        return false
    end
    local key = tostring(unit.key)
    if bucket[key] then
        return false
    end
    bucket[key] = {
        key = key,
        spawnFullType = tostring(unit.spawnFullType or ""),
        modId = metadata and metadata.modId or "",
        owner = metadata and metadata.owner or ""
    }
    return true
end

local function flattenUnitMap(unitMap)
    local out = {}
    for _, category in ipairs(CATEGORY_ORDER) do
        for _, unit in pairs(unitMap[category] or {}) do
            local spawnFullType = tostring(unit.spawnFullType or "")
            if spawnFullType ~= "" then
                out[spawnFullType] = category
            end
        end
    end
    return out
end

local function countUnitPool(unitMap, order)
    local counts = {}
    for i = 1, #(order or CATEGORY_ORDER) do
        local category = (order or CATEGORY_ORDER)[i]
        counts[category] = countItemsInMap(unitMap and unitMap[category] or nil)
    end
    return counts
end

local function appendUnitArray(out, unitMap, category)
    for _, unit in pairs(unitMap and unitMap[category] or {}) do
        out[#out + 1] = unit
    end
end

local function orderedUnitsForCategory(unitMap, category)
    local values = {}
    appendUnitArray(values, unitMap, category)
    table.sort(values, function(a, b)
        return tostring(a.key or a.canonical or a.spawnFullType or "") < tostring(b.key or b.canonical or b.spawnFullType or "")
    end)
    return values
end

local function buildManagedPools(allItems, overrides, compatibleChildMods)
    local basePools = newUnitPools()
    local childPools = {}
    local skippedMods = {}
    local skippedFalsePositives = {}
    local bareMediaRepresentatives = {}

    if not allItems then
        return basePools, childPools, skippedMods, skippedFalsePositives, bareMediaRepresentatives
    end

    for i = 0, allItems:size() - 1 do
        local item = allItems:get(i)
        if item then
            local modId = tostring(item:getModID() or "")
            local fullType = tostring(item:getFullName() or "")
            local _, typeName = splitFullType(fullType)
            local mediaUnit = resolveManagedMediaUnit(fullType, overrides)
            local deviceUnit = resolveManagedDeviceUnit(fullType)
            local legacyCategory = DISTRIBUTION_AUDIT_ENABLED and legacyLooseCategoryMatch(typeName) or nil

            if not mediaUnit and not deviceUnit and legacyCategory then
                skippedFalsePositives[fullType] = true
            end

            if mediaUnit then
                if mediaUnit.loadedOnly ~= true then
                    bareMediaRepresentatives[mediaUnit.spawnFullType] = true
                end
                local metadata = { modId = modId, owner = isTargetModId(modId) and "base" or "child", loadedOnly = mediaUnit.loadedOnly == true }
                if isTargetModId(modId) then
                    addMediaUnit(basePools, mediaUnit, metadata)
                elseif compatibleChildMods[toLower(modId)] then
                    childPools[modId] = childPools[modId] or newUnitPools()
                    addMediaUnit(childPools[modId], mediaUnit, metadata)
                elseif modId ~= "" and modId ~= "Base" and modId ~= "pz-vanilla" then
                    skippedMods[modId] = true
                end
            elseif deviceUnit then
                if isTargetModId(modId) then
                    addDeviceUnit(basePools, deviceUnit, { modId = modId, owner = "base" })
                end
            end
        end
    end

    return basePools, childPools, skippedMods, skippedFalsePositives, bareMediaRepresentatives
end

local function markListItems(indexMap, items)
    if type(items) ~= "table" then
        return
    end
    for i = 1, #items, 2 do
        indexMap[tostring(items[i])] = true
    end
end

local function buildDistributionPresenceIndex(vehicleTargets)
    local index = {
        procedural = {},
        suburbs = {},
        vehicle = {}
    }

    if ProceduralDistributions and ProceduralDistributions.list then
        for _, dist in pairs(ProceduralDistributions.list) do
            if type(dist) == "table" and type(dist.items) == "table" then
                markListItems(index.procedural, dist.items)
            end
            if type(dist) == "table" and type(dist.junk) == "table" and type(dist.junk.items) == "table" then
                markListItems(index.procedural, dist.junk.items)
            end
        end
    end

    if SuburbsDistributions then
        for _, location in pairs(SuburbsDistributions) do
            if type(location) == "table" then
                for _, room in pairs(location) do
                    if type(room) == "table" then
                        markListItems(index.suburbs, room.items)
                        if type(room.counter) == "table" then markListItems(index.suburbs, room.counter.items) end
                        if type(room.metal_shelves) == "table" then markListItems(index.suburbs, room.metal_shelves.items) end
                        if type(room.shelves) == "table" then markListItems(index.suburbs, room.shelves.items) end
                        if type(room.crate) == "table" then markListItems(index.suburbs, room.crate.items) end
                    end
                end
            end
        end
    end

    for i = 1, #(vehicleTargets or {}) do
        markListItems(index.vehicle, vehicleTargets[i].items)
    end

    return index
end

local function distributionPresenceForItems(itemSet, presenceIndex)
    local presence = { procedural = false, suburbs = false, vehicle = false }
    for fullType in pairs(itemSet or {}) do
        if presenceIndex.procedural[fullType] then
            presence.procedural = true
        end
        if presenceIndex.suburbs[fullType] then
            presence.suburbs = true
        end
        if presenceIndex.vehicle[fullType] then
            presence.vehicle = true
        end
        if presence.procedural and presence.suburbs and presence.vehicle then
            break
        end
    end
    return presence
end

local function hasAnyPresence(presence)
    return (presence and (presence.procedural or presence.suburbs or presence.vehicle)) == true
end

local function splitPresentAndMissingItems(itemSet, presenceIndex)
    local present = {}
    local missing = {}
    for fullType, category in pairs(itemSet or {}) do
        local found = presenceIndex.procedural[fullType] or presenceIndex.suburbs[fullType] or presenceIndex.vehicle[fullType]
        if found then
            present[fullType] = category
        else
            missing[fullType] = category
        end
    end
    return present, missing
end

local function applyMultipliersForItems(itemSet)
    local touched = 0
    visitDistributionTables(function(items)
        for fullType, category in pairs(itemSet or {}) do
            local multiplier = resolveCategoryMultiplier(category)
            touched = touched + applyItemMultiplierInList(items, fullType, multiplier)
        end
    end)
    return touched
end

local function injectIntoProcedural(listName, fullType, weight)
    if not (ProceduralDistributions and ProceduralDistributions.list) then
        return false
    end
    local list = ProceduralDistributions.list[listName]
    if not (type(list) == "table" and type(list.items) == "table") then
        return false
    end
    return addItemIfMissing(list.items, fullType, weight)
end

local function injectIntoSuburbsTopLevel(listName, fullType, weight)
    if not SuburbsDistributions then
        return false
    end
    local list = SuburbsDistributions[listName]
    if not (type(list) == "table" and type(list.items) == "table") then
        return false
    end
    return addItemIfMissing(list.items, fullType, weight)
end

local function rewriteBoundMediaSpawnsToContainers(mediaToContainer)
    local touched = 0
    visitDistributionTables(function(items)
        for mediaFullType, containerFullType in pairs(mediaToContainer or {}) do
            touched = touched + replaceItemInList(items, mediaFullType, containerFullType)
        end
    end)
    return touched
end

local function newInjectionSummary()
    local roles = {}
    for i = 1, #VEHICLE_ROLE_ORDER do
        roles[VEHICLE_ROLE_ORDER[i]] = 0
    end
    return {
        total = 0,
        byCategory = {},
        byRole = roles
    }
end

local function mergeInjectionSummary(into, from)
    if type(into) ~= "table" or type(from) ~= "table" then
        return into
    end
    into.total = (tonumber(into.total) or 0) + (tonumber(from.total) or 0)
    into.byCategory = into.byCategory or {}
    into.byRole = into.byRole or {}
    for category, count in pairs(from.byCategory or {}) do
        into.byCategory[category] = (tonumber(into.byCategory[category]) or 0) + (tonumber(count) or 0)
    end
    for role, count in pairs(from.byRole or {}) do
        into.byRole[role] = (tonumber(into.byRole[role]) or 0) + (tonumber(count) or 0)
    end
    return into
end

local function countVehicleTargetsByRole(vehicleTargets)
    local counts = {
        glovebox = 0,
        seatrear = 0,
        cargo = 0
    }
    for i = 1, #(vehicleTargets or {}) do
        local role = tostring(vehicleTargets[i].role or "")
        counts[role] = (tonumber(counts[role]) or 0) + 1
    end
    return counts
end

local function countPoolsByCategory(pools)
    local counts = newCategoryMaps()
    for _, category in ipairs(CATEGORY_ORDER) do
        counts[category] = countItemsInMap(pools and pools.media and pools.media[category] or nil)
            + countItemsInMap(pools and pools.devices and pools.devices[category] or nil)
    end
    return counts
end

local function countVehicleTargetsByRoleMap(vehicleTargets)
    local grouped = {
        glovebox = {},
        seatrear = {},
        cargo = {}
    }
    for i = 1, #(vehicleTargets or {}) do
        local target = vehicleTargets[i]
        local role = tostring(target.role or "")
        grouped[role] = grouped[role] or {}
        grouped[role][#grouped[role] + 1] = target
    end
    return grouped
end

local function resolveVehicleRoleTargetWeight(category, role, rate)
    local curve = VEHICLE_ROLE_WEIGHT_CURVES[category] and VEHICLE_ROLE_WEIGHT_CURVES[category][role] or nil
    if not curve then
        return 0
    end
    local low = tonumber(curve.low) or 0
    local high = tonumber(curve.high) or low
    if high <= 0 then
        return 0
    end
    local normalized = normalizePlayableRate(rate)
    return low + ((high - low) * normalized)
end

local function recordInjected(summary, category, role)
    if type(summary) ~= "table" then
        return
    end
    summary.total = (tonumber(summary.total) or 0) + 1
    if category then
        summary.byCategory[category] = (tonumber(summary.byCategory[category]) or 0) + 1
    end
    if role then
        summary.byRole[role] = (tonumber(summary.byRole[role]) or 0) + 1
    end
end

local function ensureCategoryDiagnostics(diag, category)
    diag[category] = diag[category] or {
        poolSize = 0,
        budget = 0,
        rate = 0,
        multiplier = 0,
        laneAmplifier = 1.0,
        estimatedWeight = 0,
        laneWeight = { procedural = 0, vehicle = 0, mail = 0 },
        eligibleTargets = { procedural = 0, vehicle = 0, mail = 0 },
        averageTargetWeight = { procedural = 0, vehicle = 0, mail = 0 },
        averageEntryWeight = { procedural = 0, vehicle = 0, mail = 0 },
        selectedUnits = {},
        strongProceduralAssigned = {},
        assignmentCounts = {}
    }
    return diag[category]
end

local function recordSelectedUnits(categoryDiag, picks)
    for i = 1, #(picks or {}) do
        local unit = picks[i]
        local key = tostring(unit and (unit.key or unit.canonical or unit.spawnFullType) or "")
        if key ~= "" then
            categoryDiag.selectedUnits[key] = true
            categoryDiag.assignmentCounts[key] = (tonumber(categoryDiag.assignmentCounts[key]) or 0) + 1
        end
    end
end

local function isMusicStoreTarget(listName)
    local name = tostring(listName or "")
    return string.sub(name, 1, #"MusicStore") == "MusicStore"
end

local function resolveProceduralNormalizationCount(category, listName, unitCount)
    local count = math.max(1, tonumber(unitCount) or 1)
    if not isMusicStoreTarget(listName) then
        return count
    end
    if category == "vinyl" then
        return math.min(count, 8)
    end
    if category == "recordplayer" then
        return math.min(count, 3)
    end
    return count
end

local function injectUnitsIntoProceduralBudget(category, units, targets, effectiveBudget, summary, diagnostics)
    if #units < 1 or effectiveBudget <= 0 then
        return
    end
    local categoryDiag = ensureCategoryDiagnostics(diagnostics, category)
    local activeTargets = targets or {}
    categoryDiag.eligibleTargets.procedural = #activeTargets
    if #activeTargets < 1 then
        return
    end

    for i = 1, #activeTargets do
        local cfg = activeTargets[i]
        local targetBudget = (tonumber(cfg.weight) or 0) * effectiveBudget
        local normalizationCount = resolveProceduralNormalizationCount(category, cfg.name, #units)
        local perUnitWeight = targetBudget / math.max(1, normalizationCount)
        recordSelectedUnits(categoryDiag, units)
        categoryDiag.estimatedWeight = categoryDiag.estimatedWeight + targetBudget
        categoryDiag.laneWeight.procedural = categoryDiag.laneWeight.procedural + targetBudget
        if tonumber(cfg.weight) and tonumber(cfg.weight) >= 0.8 then
            for j = 1, #units do
                local unit = units[j]
                local key = tostring(unit and (unit.key or unit.canonical or unit.spawnFullType) or "")
                if key ~= "" then
                    categoryDiag.strongProceduralAssigned[key] = true
                end
            end
        end
        for j = 1, #units do
            local spawnFullType = tostring(units[j].spawnFullType or "")
            if spawnFullType ~= "" and perUnitWeight > 0 and injectIntoProcedural(cfg.name, spawnFullType, perUnitWeight) then
                recordInjected(summary, category, nil)
            end
        end
    end
    categoryDiag.averageTargetWeight.procedural = categoryDiag.laneWeight.procedural / math.max(1, categoryDiag.eligibleTargets.procedural)
    categoryDiag.averageEntryWeight.procedural = categoryDiag.laneWeight.procedural / math.max(1, categoryDiag.eligibleTargets.procedural * #units)
end

local function injectUnitsIntoVehicleBudget(category, units, groupedVehicleTargets, effectiveBudget, summary, diagnostics)
    if #units < 1 or effectiveBudget <= 0 then
        return
    end
    local rate = resolveCategoryRate(category)
    local categoryDiag = ensureCategoryDiagnostics(diagnostics, category)
    local totalTargets = 0
    for i = 1, #VEHICLE_ROLE_ORDER do
        totalTargets = totalTargets + #(groupedVehicleTargets[VEHICLE_ROLE_ORDER[i]] or {})
    end
    categoryDiag.eligibleTargets.vehicle = totalTargets
    if totalTargets < 1 then
        return
    end

    for i = 1, #VEHICLE_ROLE_ORDER do
        local role = VEHICLE_ROLE_ORDER[i]
        local targets = groupedVehicleTargets[role] or {}
        local perTargetWeight = resolveVehicleRoleTargetWeight(category, role, rate)
        if perTargetWeight > 0 then
            for j = 1, #targets do
                local perUnitWeight = perTargetWeight / math.max(1, #units)
                recordSelectedUnits(categoryDiag, units)
                for k = 1, #units do
                    local spawnFullType = tostring(units[k].spawnFullType or "")
                    if spawnFullType ~= "" and perUnitWeight > 0 and addItemIfMissing(targets[j].items, spawnFullType, perUnitWeight) then
                        recordInjected(summary, category, role)
                    end
                end
                categoryDiag.estimatedWeight = categoryDiag.estimatedWeight + perTargetWeight
                categoryDiag.laneWeight.vehicle = categoryDiag.laneWeight.vehicle + perTargetWeight
            end
        end
    end
    categoryDiag.averageTargetWeight.vehicle = categoryDiag.laneWeight.vehicle / math.max(1, categoryDiag.eligibleTargets.vehicle)
    categoryDiag.averageEntryWeight.vehicle = categoryDiag.laneWeight.vehicle / math.max(1, categoryDiag.eligibleTargets.vehicle * #units)
end

local function injectUnitsIntoMailBudget(category, units, targets, effectiveBudget, summary, diagnostics)
    if #units < 1 or effectiveBudget <= 0 then
        return
    end
    local categoryDiag = ensureCategoryDiagnostics(diagnostics, category)
    categoryDiag.eligibleTargets.mail = #(targets or {})
    if categoryDiag.eligibleTargets.mail < 1 then
        return
    end

    for i = 1, #targets do
        local cfg = targets[i]
        local targetBudget = (tonumber(cfg.weight) or 0) * effectiveBudget
        local perUnitWeight = targetBudget / math.max(1, #units)
        recordSelectedUnits(categoryDiag, units)
        categoryDiag.estimatedWeight = categoryDiag.estimatedWeight + targetBudget
        categoryDiag.laneWeight.mail = categoryDiag.laneWeight.mail + targetBudget
        for j = 1, #units do
            local spawnFullType = tostring(units[j].spawnFullType or "")
            local injected = false
            if spawnFullType ~= "" and perUnitWeight > 0 then
                if cfg.kind == "procedural" then
                    injected = injectIntoProcedural(cfg.name, spawnFullType, perUnitWeight)
                elseif cfg.kind == "suburbs" then
                    injected = injectIntoSuburbsTopLevel(cfg.name, spawnFullType, perUnitWeight)
                end
            end
            if injected then
                recordInjected(summary, category, nil)
            end
        end
    end
    categoryDiag.averageTargetWeight.mail = categoryDiag.laneWeight.mail / math.max(1, categoryDiag.eligibleTargets.mail)
    categoryDiag.averageEntryWeight.mail = categoryDiag.laneWeight.mail / math.max(1, categoryDiag.eligibleTargets.mail * #units)
end

local function injectBudgetedPools(mediaPool, devicePool, vehicleTargets)
    local injected = newInjectionSummary()
    local diagnostics = {}
    local groupedVehicleTargets = countVehicleTargetsByRoleMap(vehicleTargets)

    for i = 1, #MEDIA_CATEGORY_ORDER do
        local category = MEDIA_CATEGORY_ORDER[i]
        local units = orderedUnitsForCategory(mediaPool, category)
        local categoryDiag = ensureCategoryDiagnostics(diagnostics, category)
        local rate = clamp(resolveCategoryRate(category), 0.0, 4.0)
        local multiplier = resolveDirectSpawnScalar(rate, BASE_MEDIA_DEFAULT, MEDIA_DIRECT_SPAWN_SCALE_BASE)
        local effectiveBudget = multiplier
        categoryDiag.poolSize = #units
        categoryDiag.rate = rate
        categoryDiag.multiplier = multiplier
        categoryDiag.budget = effectiveBudget
        categoryDiag.laneAmplifier = 1.0
        injectUnitsIntoProceduralBudget(category, units, MEDIA_PROCEDURAL_TARGETS[category], effectiveBudget, injected, diagnostics)
        injectUnitsIntoVehicleBudget(category, units, groupedVehicleTargets, 1, injected, diagnostics)
        injectUnitsIntoMailBudget(category, units, MEDIA_MAIL_TARGETS[category], effectiveBudget, injected, diagnostics)
    end

    for i = 1, #DEVICE_CATEGORY_ORDER do
        local category = DEVICE_CATEGORY_ORDER[i]
        local units = orderedUnitsForCategory(devicePool, category)
        local categoryDiag = ensureCategoryDiagnostics(diagnostics, category)
        local rate = clamp(resolveCategoryRate(category), 0.0, 4.0)
        local multiplier = resolveDirectSpawnScalar(rate, BASE_DEVICE_DEFAULT, DEVICE_DIRECT_SPAWN_SCALE_BASE)
        local effectiveBudget = multiplier
        categoryDiag.poolSize = #units
        categoryDiag.rate = rate
        categoryDiag.multiplier = multiplier
        categoryDiag.budget = effectiveBudget
        injectUnitsIntoProceduralBudget(category, units, DEVICE_PROCEDURAL_TARGETS[category], effectiveBudget, injected, diagnostics)
        injectUnitsIntoVehicleBudget(category, units, groupedVehicleTargets, 1, injected, diagnostics)
        injectUnitsIntoMailBudget(category, units, DEVICE_MAIL_TARGETS[category], effectiveBudget, injected, diagnostics)
    end

    return injected, diagnostics
end

local function mergePoolsInto(target, source, includeDevices)
    for _, category in ipairs(MEDIA_CATEGORY_ORDER) do
        for key, unit in pairs(source and source.media and source.media[category] or {}) do
            target.media[category][key] = unit
        end
    end
    if includeDevices == true then
        for _, category in ipairs(DEVICE_CATEGORY_ORDER) do
            for key, unit in pairs(source and source.devices and source.devices[category] or {}) do
                target.devices[category][key] = unit
            end
        end
    end
end

local function isBaseZomboidOSTMediaUnit(unit)
    if type(unit) ~= "table" then
        return false
    end
    local key = tostring(unit.key or unit.canonical or "")
    local spawnFullType = tostring(unit.spawnFullType or "")
    return BASE_ZOMBOID_OST_MEDIA[key] == true or BASE_ZOMBOID_OST_MEDIA[spawnFullType] == true
end

local function filterBaseZomboidOSTMedia(basePools)
    if NMRuntimeConfig and NMRuntimeConfig.getZomboidOSTEnabled and NMRuntimeConfig.getZomboidOSTEnabled() == true then
        return 0
    end

    local removed = 0
    for i = 1, #MEDIA_CATEGORY_ORDER do
        local category = MEDIA_CATEGORY_ORDER[i]
        local bucket = basePools and basePools.media and basePools.media[category] or nil
        if type(bucket) == "table" then
            for key, unit in pairs(bucket) do
                if isBaseZomboidOSTMediaUnit(unit) then
                    bucket[key] = nil
                    removed = removed + 1
                end
            end
        end
    end
    return removed
end

local function formatRawSandboxLootSettings(raw)
    return string.format(
        "cassettes=%s vinyl=%s cds=%s walkman=%s boombox=%s cdplayer=%s recordplayer=%s",
        tostring(raw and raw.cassettes),
        tostring(raw and raw.vinyl),
        tostring(raw and raw.cds),
        tostring(raw and raw.walkman),
        tostring(raw and raw.boombox),
        tostring(raw and raw.cdplayer),
        tostring(raw and raw.recordplayer)
    )
end

local function formatCategoryFloatMap(order, resolver)
    local parts = {}
    for i = 1, #order do
        local key = order[i]
        parts[#parts + 1] = string.format("%s=%.2f", tostring(key), tonumber(resolver(key)) or 0)
    end
    return table.concat(parts, " ")
end

local function applySandboxLootControl()
    local allItems = getAllItems and getAllItems() or nil
    local compatibleChildMods = NMManagedSpawnCatalog.buildCompatibleChildModSet()
    local overrides = NMManagedSpawnCatalog.buildLoadedContainerOverrideRegistry(allItems)
    local rewrites = rewriteBoundMediaSpawnsToContainers(overrides.mediaToContainer)
    local vehicleTargets = collectAllowedVehicleTargets()
    local vehicleRoleCounts = countVehicleTargetsByRole(vehicleTargets)
    local presenceIndex = buildDistributionPresenceIndex(vehicleTargets)
    local basePools, childPools, skippedMods, skippedFalsePositives, bareMediaRepresentatives =
        NMManagedSpawnCatalog.buildManagedPools(
            allItems,
            overrides,
            compatibleChildMods,
            { distributionAuditEnabled = DISTRIBUTION_AUDIT_ENABLED }
        )
    local rawSandboxLoot = getRawSandboxLootSettings()
    local filteredBaseZomboidOST = filterBaseZomboidOSTMedia(basePools)

    if DISTRIBUTION_AUDIT_ENABLED then
        logLoot(
            "sandbox.loot audit bindings",
            string.format(
                "boundMedia=%s rewrites=%s compatibleChildMods=%s vehicleTargets=%s",
                tostring(countItemsInMap(overrides.mediaToContainer)),
                tostring(rewrites),
                tostring(countTrueEntries(compatibleChildMods)),
                tostring(#vehicleTargets)
            )
        )
    end

    logLoot("sandbox.loot raw sandbox settings", formatRawSandboxLootSettings(rawSandboxLoot))
    logLoot(
        "sandbox.loot resolved rates",
        formatCategoryFloatMap(CATEGORY_ORDER, function(category)
            return resolveCategoryRate(category)
        end)
    )
    logLoot("sandbox.loot bound-media rewrites", tostring(rewrites))
    logLoot(
        "sandbox.loot compatible child mods",
        string.format("count=%s mods=%s", tostring(countTrueEntries(compatibleChildMods)), formatNameSet(compatibleChildMods))
    )
    logLoot(
        "sandbox.loot allowed vehicle targets",
        string.format(
            "total=%s glovebox=%s seatrear=%s cargo=%s",
            tostring(#vehicleTargets),
            tostring(vehicleRoleCounts.glovebox),
            tostring(vehicleRoleCounts.seatrear),
            tostring(vehicleRoleCounts.cargo)
        )
    )
    logLoot("sandbox.loot base zomboid ost filtered", tostring(filteredBaseZomboidOST))

    local baseAllMap = flattenUnitMap(basePools.media)
    for fullType, category in pairs(flattenUnitMap(basePools.devices)) do
        baseAllMap[fullType] = category
    end
    local basePresentMap, baseMissingMap = splitPresentAndMissingItems(baseAllMap, presenceIndex)
    local baseTouched = applyMultipliersForItems(baseAllMap)

    local fallbackMediaPool = newCategoryMaps()
    local fallbackDevicePool = newCategoryMaps()
    local baseMissingCounts = newCategoryMaps()
    local basePresentCounts = newCategoryMaps()
    local childPoolCounts = newCategoryMaps()
    local fallbackChildCounts = newCategoryMaps()
    local childTouched = 0

    for _, category in ipairs(MEDIA_CATEGORY_ORDER) do
        for key, unit in pairs(basePools.media[category] or {}) do
            local spawnFullType = tostring(unit.spawnFullType or "")
            if basePresentMap[spawnFullType] then
                basePresentCounts[category] = (tonumber(basePresentCounts[category]) or 0) + 1
            elseif baseMissingMap[spawnFullType] then
                fallbackMediaPool[category][key] = unit
                baseMissingCounts[category] = (tonumber(baseMissingCounts[category]) or 0) + 1
            end
        end
    end

    for _, category in ipairs(DEVICE_CATEGORY_ORDER) do
        for key, unit in pairs(basePools.devices[category] or {}) do
            local spawnFullType = tostring(unit.spawnFullType or "")
            if basePresentMap[spawnFullType] then
                basePresentCounts[category] = (tonumber(basePresentCounts[category]) or 0) + 1
            elseif baseMissingMap[spawnFullType] then
                fallbackDevicePool[category][key] = unit
                baseMissingCounts[category] = (tonumber(baseMissingCounts[category]) or 0) + 1
            end
        end
    end

    for modId, pools in pairs(childPools or {}) do
        local itemSet = flattenUnitMap(pools.media)
        local counts = countUnitPool(pools.media, MEDIA_CATEGORY_ORDER)
        for category, count in pairs(counts) do
            childPoolCounts[category] = (tonumber(childPoolCounts[category]) or 0) + (tonumber(count) or 0)
        end
        local presence = distributionPresenceForItems(itemSet, presenceIndex)
        local presentMap, missingMap = splitPresentAndMissingItems(itemSet, presenceIndex)
        childTouched = childTouched + applyMultipliersForItems(itemSet)
        if not hasAnyPresence(presence) then
            for _, category in ipairs(MEDIA_CATEGORY_ORDER) do
                for key, unit in pairs(pools.media[category] or {}) do
                    if missingMap[tostring(unit.spawnFullType or "")] then
                        fallbackMediaPool[category][key] = unit
                        fallbackChildCounts[category] = (tonumber(fallbackChildCounts[category]) or 0) + 1
                    end
                end
            end
        end
        logLoot(
            "sandbox.loot child pack",
            string.format(
                "modId=%s ownsAny=%s presence={proc=%s,suburbs=%s,vehicle=%s} present=%s missing=%s eligibleFallback=%s byCategory={%s}",
                tostring(modId),
                tostring(hasAnyPresence(presence)),
                tostring(presence.procedural),
                tostring(presence.suburbs),
                tostring(presence.vehicle),
                tostring(countItemsInMap(presentMap)),
                tostring(countItemsInMap(missingMap)),
                tostring(hasAnyPresence(presence) ~= true),
                formatCountMap(counts, MEDIA_CATEGORY_ORDER)
            )
        )
    end

    local injected, budgetDiagnostics = injectBudgetedPools(fallbackMediaPool, fallbackDevicePool, vehicleTargets)

    logLoot("sandbox.loot base category counts", formatCountMap(countPoolsByCategory(basePools)))
    logLoot("sandbox.loot child category counts", formatCountMap(childPoolCounts, MEDIA_CATEGORY_ORDER))
    logLoot("sandbox.loot base present counts", formatCountMap(basePresentCounts))
    logLoot("sandbox.loot base missing counts", formatCountMap(baseMissingCounts))
    logLoot("sandbox.loot fallback media pool", formatCountMap(countUnitPool(fallbackMediaPool, MEDIA_CATEGORY_ORDER), MEDIA_CATEGORY_ORDER))
    logLoot("sandbox.loot fallback device pool", formatCountMap(countUnitPool(fallbackDevicePool, DEVICE_CATEGORY_ORDER), DEVICE_CATEGORY_ORDER))
    logLoot("sandbox.loot fallback child pool", formatCountMap(fallbackChildCounts, MEDIA_CATEGORY_ORDER))
    logLoot(
        "sandbox.loot loaded representatives",
        string.format(
            "loadedOnly=%s loadedCount=%s bareCount=%s bareItems=%s",
            tostring(countTrueEntries(bareMediaRepresentatives) == 0),
            tostring(countTrueEntries(overrides.loadedRepresentatives)),
            tostring(countTrueEntries(bareMediaRepresentatives)),
            formatNameSet(bareMediaRepresentatives)
        )
    )
    logLoot(
        "sandbox.loot skipped child mods",
        string.format("count=%s mods=%s", tostring(countTrueEntries(skippedMods)), formatNameSet(skippedMods))
    )
    if DISTRIBUTION_AUDIT_ENABLED then
        logLoot(
            "sandbox.loot false-positive candidates",
            string.format("count=%s items=%s", tostring(countTrueEntries(skippedFalsePositives)), formatNameSet(skippedFalsePositives))
        )
    end

    if DISTRIBUTION_AUDIT_ENABLED then
        logLoot(
            "sandbox.loot audit summary",
            string.format(
                "baseTouched=%s childTouched=%s injected=%s",
                tostring(baseTouched),
                tostring(childTouched),
                tostring(injected.total)
            )
        )
    end

    logLoot("sandbox.loot base touch count", tostring(baseTouched))
    logLoot("sandbox.loot child touch count", tostring(childTouched))
    for i = 1, #CATEGORY_ORDER do
        local category = CATEGORY_ORDER[i]
        local diag = budgetDiagnostics and budgetDiagnostics[category] or nil
        if diag then
            logLoot(
                "sandbox.loot category budget",
                string.format(
                    "category=%s rate=%.2f scalar=%.2f scale=%.2f laneAmp=%.2f poolSize=%s estWeight=%.2f targets={proc:%s vehicle:%s mail:%s} laneWeight={proc:%.2f vehicle:%.2f mail:%.2f} avgTargetWeight={proc:%.3f vehicle:%.3f mail:%.3f} avgEntryWeight={proc:%.4f vehicle:%.4f mail:%.4f}",
                    tostring(category),
                    tonumber(diag.rate) or 0,
                    tonumber(diag.multiplier) or 0,
                    tonumber(diag.budget) or 0,
                    tonumber(diag.laneAmplifier) or 1.0,
                    tostring(tonumber(diag.poolSize) or 0),
                    tonumber(diag.estimatedWeight) or 0,
                    tostring(diag.eligibleTargets and diag.eligibleTargets.procedural or 0),
                    tostring(diag.eligibleTargets and diag.eligibleTargets.vehicle or 0),
                    tostring(diag.eligibleTargets and diag.eligibleTargets.mail or 0),
                    tonumber(diag.laneWeight and diag.laneWeight.procedural) or 0,
                    tonumber(diag.laneWeight and diag.laneWeight.vehicle) or 0,
                    tonumber(diag.laneWeight and diag.laneWeight.mail) or 0,
                    tonumber(diag.averageTargetWeight and diag.averageTargetWeight.procedural) or 0,
                    tonumber(diag.averageTargetWeight and diag.averageTargetWeight.vehicle) or 0,
                    tonumber(diag.averageTargetWeight and diag.averageTargetWeight.mail) or 0,
                    tonumber(diag.averageEntryWeight and diag.averageEntryWeight.procedural) or 0,
                    tonumber(diag.averageEntryWeight and diag.averageEntryWeight.vehicle) or 0,
                    tonumber(diag.averageEntryWeight and diag.averageEntryWeight.mail) or 0
                )
            )
        end
    end
    logLoot(
        "sandbox.loot injection summary",
        string.format(
            "total=%s byCategory={%s} byRole={%s}",
            tostring(injected.total),
            formatCountMap(injected.byCategory),
            formatCountMap(injected.byRole, VEHICLE_ROLE_ORDER)
        )
    )
end

if Events and Events.OnPostDistributionMerge and Events.OnPostDistributionMerge.Add then
    Events.OnPostDistributionMerge.Add(applySandboxLootControl)
end
