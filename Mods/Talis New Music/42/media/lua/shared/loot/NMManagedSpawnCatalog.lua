-- Shared managed media/device spawn catalog for sandbox loot and zombie features.
NMManagedSpawnCatalog = NMManagedSpawnCatalog or {}

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

local function isBaseZomboidOSTMediaUnit(unit)
    if type(unit) ~= "table" then
        return false
    end
    local key = tostring(unit.key or unit.canonical or "")
    local spawnFullType = tostring(unit.spawnFullType or "")
    return BASE_ZOMBOID_OST_MEDIA[key] == true or BASE_ZOMBOID_OST_MEDIA[spawnFullType] == true
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
            existing.emptyCompanionFullType = tostring(unit.emptyCompanionFullType or "") ~= "" and tostring(unit.emptyCompanionFullType) or nil
            existing.hasCompanionCase = unit.hasCompanionCase == true
            existing.looseZombieRepresentativeFullType = tostring(unit.looseZombieRepresentativeFullType or unit.spawnFullType or existing.canonicalMediaFullType or "") ~= ""
                and tostring(unit.looseZombieRepresentativeFullType or unit.spawnFullType or existing.canonicalMediaFullType or "")
                or nil
            existing.insertedZombieMediaFullType = tostring(unit.insertedZombieMediaFullType or unit.insertedMediaFullType or existing.canonicalMediaFullType or "") ~= ""
                and tostring(unit.insertedZombieMediaFullType or unit.insertedMediaFullType or existing.canonicalMediaFullType or "")
                or nil
            existing.companionZombieCaseFullType = tostring(unit.companionZombieCaseFullType or unit.emptyCompanionFullType or "") ~= ""
                and tostring(unit.companionZombieCaseFullType or unit.emptyCompanionFullType or "")
                or nil
        end
        return false
    end
    bucket[key] = {
        key = key,
        canonical = key,
        canonicalMediaFullType = tostring(unit.canonicalMediaFullType or key),
        insertedMediaFullType = tostring(unit.insertedMediaFullType or key),
        spawnFullType = tostring(unit.spawnFullType or ""),
        loadedOnly = loadedOnly,
        carrier = tostring(unit.carrier or ""),
        emptyCompanionFullType = tostring(unit.emptyCompanionFullType or "") ~= "" and tostring(unit.emptyCompanionFullType) or nil,
        hasCompanionCase = unit.hasCompanionCase == true,
        looseZombieRepresentativeFullType = tostring(unit.looseZombieRepresentativeFullType or unit.spawnFullType or unit.canonicalMediaFullType or key),
        insertedZombieMediaFullType = tostring(unit.insertedZombieMediaFullType or unit.insertedMediaFullType or unit.canonicalMediaFullType or key),
        companionZombieCaseFullType = tostring(unit.companionZombieCaseFullType or unit.emptyCompanionFullType or "") ~= "" and tostring(unit.companionZombieCaseFullType or unit.emptyCompanionFullType) or nil,
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
        deviceType = tostring(unit.deviceType or ""),
        supportedCarrier = tostring(unit.supportedCarrier or ""),
        modId = metadata and metadata.modId or "",
        owner = metadata and metadata.owner or ""
    }
    return true
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

local function resolveEmptyCompanionFullType(loadedFullType)
    local current = tostring(loadedFullType or "")
    if current == "" then
        return nil
    end
    if not (NMMediaContract and NMMediaContract.resolveContainerSwapFullType) then
        return nil
    end
    local empty = NMMediaContract.resolveContainerSwapFullType(current, false)
    empty = tostring(empty or "")
    if empty == "" or empty == current then
        return nil
    end
    return empty
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
        local carrier = resolveRegisteredMediaCarrier(canonical)
        local category = resolveMediaCategoryFromCarrier(carrier)
        local loaded = resolveLoadedSpawnRepresentative(current, canonical, overrides)
        if category and loaded and loaded ~= "" then
            local emptyCompanionFullType = resolveEmptyCompanionFullType(loaded)
            return {
                category = category,
                carrier = carrier,
                canonicalKey = canonical,
                canonicalMediaFullType = canonical,
                insertedMediaFullType = canonical,
                spawnFullType = loaded,
                loadedOnly = true,
                emptyCompanionFullType = emptyCompanionFullType,
                hasCompanionCase = emptyCompanionFullType ~= nil,
                looseZombieRepresentativeFullType = loaded,
                insertedZombieMediaFullType = canonical,
                companionZombieCaseFullType = emptyCompanionFullType
            }
        end
        return nil
    end

    local canonical = NMMediaContract and NMMediaContract.resolveMediaCanonical and NMMediaContract.resolveMediaCanonical(current) or current
    canonical = tostring(canonical or current)
    local carrier = resolveRegisteredMediaCarrier(canonical)
    local category = resolveMediaCategoryFromCarrier(carrier)
    if not category then
        return nil
    end

    local loaded = resolveLoadedSpawnRepresentative(current, canonical, overrides)
    if loaded and loaded ~= "" then
        local emptyCompanionFullType = resolveEmptyCompanionFullType(loaded)
        return {
            category = category,
            carrier = carrier,
            canonicalKey = canonical,
            canonicalMediaFullType = canonical,
            insertedMediaFullType = canonical,
            spawnFullType = loaded,
            loadedOnly = true,
            emptyCompanionFullType = emptyCompanionFullType,
            hasCompanionCase = emptyCompanionFullType ~= nil,
            looseZombieRepresentativeFullType = loaded,
            insertedZombieMediaFullType = canonical,
            companionZombieCaseFullType = emptyCompanionFullType
        }
    end

    return {
        category = category,
        carrier = carrier,
        canonicalKey = canonical,
        canonicalMediaFullType = canonical,
        insertedMediaFullType = canonical,
        spawnFullType = canonical,
        loadedOnly = false,
        emptyCompanionFullType = nil,
        hasCompanionCase = false,
        looseZombieRepresentativeFullType = canonical,
        insertedZombieMediaFullType = canonical,
        companionZombieCaseFullType = nil
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
        spawnFullType = tostring(fullType or ""),
        deviceType = tostring(profile.deviceType or ""),
        supportedCarrier = tostring(profile.supportedCarrier or "")
    }
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
    local useOrder = order or CATEGORY_ORDER
    for i = 1, #useOrder do
        local category = useOrder[i]
        counts[category] = countItemsInMap(unitMap and unitMap[category] or nil)
    end
    return counts
end

local function orderedUnitsForCategory(unitMap, category)
    local values = {}
    for _, unit in pairs(unitMap and unitMap[category] or {}) do
        values[#values + 1] = unit
    end
    table.sort(values, function(a, b)
        return tostring(a.key or a.canonical or a.spawnFullType or "") < tostring(b.key or b.canonical or b.spawnFullType or "")
    end)
    return values
end

function NMManagedSpawnCatalog.buildCompatibleChildModSet()
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

function NMManagedSpawnCatalog.buildLoadedContainerOverrideRegistry(allItems)
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

function NMManagedSpawnCatalog.buildManagedPools(allItems, overrides, compatibleChildMods, options)
    local basePools = newUnitPools()
    local childPools = {}
    local skippedMods = {}
    local skippedFalsePositives = {}
    local bareMediaRepresentatives = {}
    local auditLooseLegacy = options and options.distributionAuditEnabled == true

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
            local legacyCategory = auditLooseLegacy and legacyLooseCategoryMatch(typeName) or nil

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
                elseif compatibleChildMods[toLower(modId)] then
                    childPools[modId] = childPools[modId] or newUnitPools()
                    addDeviceUnit(childPools[modId], deviceUnit, { modId = modId, owner = "child" })
                end
            end
        end
    end

    return basePools, childPools, skippedMods, skippedFalsePositives, bareMediaRepresentatives
end

function NMManagedSpawnCatalog.buildCatalog(allItems, options)
    local compatibleChildMods = NMManagedSpawnCatalog.buildCompatibleChildModSet()
    local overrides = NMManagedSpawnCatalog.buildLoadedContainerOverrideRegistry(allItems)
    local basePools, childPools, skippedMods, skippedFalsePositives, bareMediaRepresentatives =
        NMManagedSpawnCatalog.buildManagedPools(allItems, overrides, compatibleChildMods, options)

    return {
        compatibleChildMods = compatibleChildMods,
        overrides = overrides,
        basePools = basePools,
        childPools = childPools,
        skippedMods = skippedMods,
        skippedFalsePositives = skippedFalsePositives,
        bareMediaRepresentatives = bareMediaRepresentatives
    }
end

function NMManagedSpawnCatalog.filterBaseZomboidOSTMedia(basePools)
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

function NMManagedSpawnCatalog.newUnitPools()
    return newUnitPools()
end

function NMManagedSpawnCatalog.newCategoryMaps()
    return newCategoryMaps()
end

function NMManagedSpawnCatalog.flattenUnitMap(unitMap)
    return flattenUnitMap(unitMap)
end

function NMManagedSpawnCatalog.countUnitPool(unitMap, order)
    return countUnitPool(unitMap, order)
end

function NMManagedSpawnCatalog.orderedMediaUnitsForCategory(pools, category)
    return orderedUnitsForCategory(pools and pools.media or nil, category)
end

function NMManagedSpawnCatalog.orderedDeviceUnitsForCategory(pools, category)
    return orderedUnitsForCategory(pools and pools.devices or nil, category)
end

function NMManagedSpawnCatalog.getCategoryOrder()
    return CATEGORY_ORDER
end

function NMManagedSpawnCatalog.getMediaCategoryOrder()
    return MEDIA_CATEGORY_ORDER
end

function NMManagedSpawnCatalog.getDeviceCategoryOrder()
    return DEVICE_CATEGORY_ORDER
end

return NMManagedSpawnCatalog
