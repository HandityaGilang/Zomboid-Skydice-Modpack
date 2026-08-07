--========================================================
-- Gore's SVU4 Core - Roof Rack ItemPickInfo Shared Shim
--
-- Keeps the native GSVU4RoofRack vehicle container as its own container type,
-- but registers it as an empty loot/container distribution early enough for
-- B42 MP ItemPickInfo/container ID lookups.
--
-- This does NOT add roof-rack loot to vehicles. rolls = 0 and items = {} are
-- only used as an ID/valid-container shim for the vanilla picker path.
--========================================================

GSVU4 = GSVU4 or {}
GSVU4.RoofRack = GSVU4.RoofRack or {}

local CONTAINER_ID = "GSVU4RoofRack"

local function ensureEmptyDistribution(root, key)
    if type(root) ~= "table" or not key then return false end

    local existing = root[key]
    if existing == nil then
        root[key] = { rolls = 0, items = {} }
        return true
    end

    if type(existing) == "table" then
        existing.rolls = existing.rolls or 0
        existing.items = existing.items or {}
        return true
    end

    return false
end

function GSVU4.RoofRack.RegisterEmptyItemPickInfo()
    -- Some PZ paths look for the container directly under SuburbsDistributions.
    SuburbsDistributions = SuburbsDistributions or {}
    ensureEmptyDistribution(SuburbsDistributions, CONTAINER_ID)

    -- Other versions/mod stacks merge through the "all" bucket first.
    SuburbsDistributions.all = SuburbsDistributions.all or {}
    ensureEmptyDistribution(SuburbsDistributions.all, CONTAINER_ID)

    -- Vehicle-style containers can also be inspected through VehicleDistributions.
    VehicleDistributions = VehicleDistributions or {}
    ensureEmptyDistribution(VehicleDistributions, CONTAINER_ID)

    -- Procedural distributions may not exist yet on every load path, so guard it.
    if ProceduralDistributions then
        ProceduralDistributions.list = ProceduralDistributions.list or {}
        ensureEmptyDistribution(ProceduralDistributions.list, CONTAINER_ID)
    end
end

GSVU4.RoofRack.RegisterEmptyItemPickInfo()

if Events and Events.OnPreDistributionMerge and not GSVU4.RoofRack._itemPickInfoPreMergeHooked then
    GSVU4.RoofRack._itemPickInfoPreMergeHooked = true
    Events.OnPreDistributionMerge.Add(GSVU4.RoofRack.RegisterEmptyItemPickInfo)
end

if Events and Events.OnGameBoot and not GSVU4.RoofRack._itemPickInfoGameBootHooked then
    GSVU4.RoofRack._itemPickInfoGameBootHooked = true
    Events.OnGameBoot.Add(GSVU4.RoofRack.RegisterEmptyItemPickInfo)
end
