LifestyleSecure = LifestyleSecure or {}
LifestyleSecure.SystemDefinitions = LifestyleSecure.SystemDefinitions or {}

local Defs = LifestyleSecure.SystemDefinitions

-- Hard limits are shared for deterministic validation; only the server mutates state.
Defs.LIMITS = {
    identifier = 64,
    list = 64,
    map = 128,
    requestTtlMs = 30000,
    actionTtlMs = 3600000,
}

Defs.Music = {
    instruments = {
        Piano = true, Trumpet = true, GuitarA = true, Banjo = true,
        Keytar = true, Saxophone = true, GuitarEB = true, GuitarE = true,
        Flute = true, Harmonica = true, Violin = true,
    },
    maxLearnedPerInstrument = 128,
    listenerRadius = 45,
    maxRewardPerMinute = 3,
    maxRewardPerAction = 90,
}

Defs.Dance = { requestRadius = 3, requestTtlMs = 30000, maxSessionMs = 900000 }
Defs.Wellness = {
    actions = { Meditation = true, Yoga = true },
    maxSessionMs = 1800000,
    maxHeal = 10,
    maxStiffnessReduction = 25,
    maxXp = 90,
    -- Yoga Fitness/Nimble are granted via Wellness.complete (not LSK AddXP proof).
    maxFitnessXp = 250,
    maxNimbleXp = 120,
    teachingRadius = 4,
}
Defs.Hygiene = {
    needMin = 0,
    needMax = 100,
    interactionRadius = 3,
    maxFluidUnits = 100,
    maxResources = 16,
    maxCleaningQueue = 12,
}
Defs.Art = {
    spritePrefixes = { "LS_Artwork", "LSArtwork", "LS_Painting", "LS_Sculpture" },
    styles = { Painting = true, Sculpture = true, Sketch = true },
    sizes = { Small = true, Medium = true, Large = true },
    beautyMin = -100,
    beautyMax = 1000,
    maxKnownArtworks = 128,
}
Defs.Ambition = {
    ids = {
        LSBladeMaster = true, LSTerminator = true, LSMasterPainter = true,
        LSJuryRigger = true, LSBrushmaster = true, LSGrimeFighter = true,
        LSElDorado = true, LSCommando = true, LSTheProfessional = true,
        LSLordDeath = true, LSUnstoppable = true, LSGoodEating = true,
        LSRockstar = true, LSExplorer = true, LSWanderer = true,
        LSLumberjack = true, LSKnockdown = true, LSPlushies = true,
        LSDietOfGods = true,
    },
    maxGoals = 6,
    maxProgress = 100000000,
}
Defs.Invention = {
    ids = {
        Hygienator = true,
        FoodSynthesizer = true,
        Harvester = true,
        PowerAxe = true,
        NeuralHat = true,
    },
    maxUpgradeLevel = 10,
    maxIngredients = 32,
    maxOutputs = 8,
    maxQuantity = 1000,
}
Defs.Comfort = {
    presetNames = {
        CasualClothes = true, FormalClothes = true, GymClothes = true,
        SleepClothes = true, PartyClothes = true, SummerClothes = true,
        WinterClothes = true, WorkClothes = true, CombatClothes = true,
        ShowerClothes = true,
    },
    needMin = 0,
    needMax = 100,
    maxPresetItems = 32,
}
Defs.Social = {
    actions = {
        Praise = true, Boo = true, Shoo = true, Hug = true,
        HighFive = true, PlushieTalk = true,
    },
    requestRadius = 4,
    requestTtlMs = 30000,
    cooldownMs = 10000,
}

function Defs.now()
    return getTimestampMs and getTimestampMs() or 0
end

function Defs.finite(value)
    value = tonumber(value)
    if not value or value ~= value or value == math.huge or value == -math.huge then
        return nil
    end
    return value
end

function Defs.clamp(value, minimum, maximum)
    value = Defs.finite(value)
    if not value then
        return nil
    end
    return math.max(minimum, math.min(maximum, value))
end

function Defs.identifier(value)
    if type(value) ~= "string" or string.len(value) < 1
        or string.len(value) > Defs.LIMITS.identifier
        or not string.match(value, "^[%w_%.%-]+$") then
        return nil
    end
    return value
end

function Defs.playerKey(player)
    if not player then
        return nil
    end
    if player.getOnlineID then
        local onlineId = tonumber(player:getOnlineID())
        if onlineId and onlineId >= 0 then
            return tostring(math.floor(onlineId))
        end
    end
    return player.getUsername and tostring(player:getUsername()) or nil
end

function Defs.samePlayer(left, right)
    local leftKey = Defs.playerKey(left)
    return leftKey ~= nil and leftKey == Defs.playerKey(right)
end

function Defs.inRange(left, right, radius)
    if not left or not right or left.isDead and (left:isDead() or right:isDead()) then
        return false
    end
    if math.abs((left:getZ() or 0) - (right:getZ() or 0)) > 1 then
        return false
    end
    local dx = left:getX() - right:getX()
    local dy = left:getY() - right:getY()
    return dx * dx + dy * dy <= radius * radius
end

function Defs.isAdmin(player)
    if not player or not player.getAccessLevel then
        return false
    end
    local level = string.lower(tostring(player:getAccessLevel() or ""))
    return level == "admin" or level == "moderator" or level == "overseer"
end

function Defs.systemState(player, systemName)
    if not player or not player.getModData or not Defs.identifier(systemName) then
        return nil
    end
    local modData = player:getModData()
    modData.LifestyleSecureSystems = type(modData.LifestyleSecureSystems) == "table"
        and modData.LifestyleSecureSystems or {}
    local state = modData.LifestyleSecureSystems[systemName]
    if type(state) ~= "table" then
        state = {}
        modData.LifestyleSecureSystems[systemName] = state
    end
    return state
end

function Defs.boundedIdList(source, allow, maximum)
    local result = {}
    local seen = {}
    if type(source) ~= "table" then
        return result
    end
    for i = 1, math.min(#source, maximum) do
        local id = Defs.identifier(source[i])
        if id and (not allow or allow[id]) and not seen[id] then
            result[#result + 1] = id
            seen[id] = true
        end
    end
    return result
end

function Defs.findOnlinePlayer(key)
    key = tostring(key or "")
    local players = getOnlinePlayers and getOnlinePlayers() or nil
    if not players then
        return nil
    end
    for i = 0, players:size() - 1 do
        local player = players:get(i)
        if player and Defs.playerKey(player) == key then
            return player
        end
    end
    return nil
end

function Defs.ownsInventoryItem(player, itemId)
    itemId = Defs.identifier(itemId)
    local inventory = player and player.getInventory and player:getInventory() or nil
    if not inventory or not itemId then
        return false, nil
    end
    local items = inventory:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local id = item and item.getID and tostring(item:getID()) or nil
        if id == itemId then
            return true, item
        end
    end
    return false, nil
end

return Defs
