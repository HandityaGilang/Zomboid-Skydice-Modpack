require "LifestyleSystems/LSK_SystemDefinitions"

LifestyleSecure = LifestyleSecure or {}
local Hygiene = {}
local Defs = LifestyleSecure.SystemDefinitions
local Limits = Defs.Hygiene

Hygiene.cleaningQueues = {}

function Hygiene.sanitizeNeeds(needs)
    needs = type(needs) == "table" and needs or {}
    return {
        hygiene = Defs.clamp(needs.hygiene, Limits.needMin, Limits.needMax) or Limits.needMin,
        bathroom = Defs.clamp(needs.bathroom, Limits.needMin, Limits.needMax) or Limits.needMin,
    }
end

function Hygiene.setNeeds(player, needs)
    local state = Defs.systemState(player, "Hygiene")
    if not state then
        return false, "invalid_player"
    end
    state.needs = Hygiene.sanitizeNeeds(needs)
    return true, state.needs
end

function Hygiene.validateResources(resources)
    if type(resources) ~= "table" or #resources > Limits.maxResources then
        return false, "invalid_resources"
    end
    local clean = {}
    for i = 1, #resources do
        local entry = resources[i]
        local itemType = type(entry) == "table" and Defs.identifier(entry.type) or nil
        local count = type(entry) == "table" and Defs.clamp(entry.count, 1, 100) or nil
        if not itemType or not count then
            return false, "invalid_resource"
        end
        clean[#clean + 1] = { type = itemType, count = math.floor(count) }
    end
    return true, clean
end

function Hygiene.validateFluid(request, availableAmount, allowedFluids)
    if type(request) ~= "table" then
        return false, "invalid_fluid"
    end
    local fluid = Defs.identifier(request.fluid)
    local amount = Defs.clamp(request.amount, 0.01, Limits.maxFluidUnits)
    local available = Defs.clamp(availableAmount, 0, 100000)
    if not fluid or not amount or not available or type(allowedFluids) ~= "table"
        or allowedFluids[fluid] ~= true or amount > available then
        return false, "fluid_unavailable"
    end
    return true, { fluid = fluid, amount = amount }
end

function Hygiene.objectKey(object)
    if not object or not object.getSquare or not object:getSquare() then
        return nil
    end
    local square = object:getSquare()
    local index = object.getObjectIndex and object:getObjectIndex() or -1
    return tostring(square:getX()) .. ":" .. tostring(square:getY()) .. ":"
        .. tostring(square:getZ()) .. ":" .. tostring(index)
end

function Hygiene.validateFixture(player, object, fixtureType, requireOwner)
    if fixtureType ~= "Toilet" and fixtureType ~= "Outhouse" then
        return false, "invalid_fixture_type"
    end
    local square = object and object.getSquare and object:getSquare() or nil
    if not player or not square then
        return false, "invalid_fixture"
    end
    local dx = player:getX() - square:getX()
    local dy = player:getY() - square:getY()
    if math.abs((player:getZ() or 0) - square:getZ()) > 1
        or dx * dx + dy * dy > Limits.interactionRadius * Limits.interactionRadius then
        return false, "too_far"
    end
    local data = object.getModData and object:getModData() or {}
    local ownerKey = data.LSKFixtureOwner
    if requireOwner and ownerKey and ownerKey ~= Defs.playerKey(player) and not Defs.isAdmin(player) then
        return false, "not_owner"
    end
    return true, {
        key = Hygiene.objectKey(object),
        fixtureType = fixtureType,
        ownerKey = ownerKey,
    }
end

function Hygiene.claimFixture(player, object, fixtureType)
    local valid, contract = Hygiene.validateFixture(player, object, fixtureType, false)
    if not valid then
        return false, contract
    end
    local data = object:getModData()
    local ownerKey = data.LSKFixtureOwner
    if ownerKey and ownerKey ~= Defs.playerKey(player) and not Defs.isAdmin(player) then
        return false, "already_owned"
    end
    data.LSKFixtureOwner = Defs.playerKey(player)
    if object.transmitModData then
        object:transmitModData()
    end
    contract.ownerKey = data.LSKFixtureOwner
    return true, contract
end

function Hygiene.enqueueCleaning(player, object, cleaningType)
    local playerKey = Defs.playerKey(player)
    local objectKey = Hygiene.objectKey(object)
    cleaningType = Defs.identifier(cleaningType)
    if not playerKey or not objectKey or not cleaningType then
        return false, "invalid_cleaning_job"
    end
    local queue = Hygiene.cleaningQueues[playerKey] or {}
    if #queue >= Limits.maxCleaningQueue then
        return false, "queue_full"
    end
    for i = 1, #queue do
        if queue[i].objectKey == objectKey then
            return false, "already_queued"
        end
    end
    queue[#queue + 1] = {
        objectKey = objectKey,
        cleaningType = cleaningType,
        queuedAt = Defs.now(),
    }
    Hygiene.cleaningQueues[playerKey] = queue
    return true, queue[#queue]
end

function Hygiene.dequeueCleaning(player, objectKey)
    local key = Defs.playerKey(player)
    local queue = key and Hygiene.cleaningQueues[key] or nil
    if not queue or queue[1].objectKey ~= objectKey then
        return false, "queue_order"
    end
    return true, table.remove(queue, 1)
end

function Hygiene.cleanupPlayer(player)
    local key = Defs.playerKey(player)
    if key then
        Hygiene.cleaningQueues[key] = nil
    end
end

return Hygiene
