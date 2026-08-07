--//////////////////////////////////////////////////--
--    Reactive Sound Events - Player Reactions
--    Player reaction system (wake up, panic)
--//////////////////////////////////////////////////--

local Utils                      = require "ReactiveSE/ReactiveSE_Utils"
local Constants                  = require "ReactiveSE/ReactiveSE_Constants"
local Config                     = require "ReactiveSE/ReactiveSE_Config"

local ReactiveSE_PlayerReactions = {}

--//////////////////////////////////////////////////--
--          Trait & Decay Modifiers               --
--//////////////////////////////////////////////////--

---Checks if player has a specific trait (using CharacterTrait)
local function hasTrait(player, traitData)
    if not player or not traitData then return false end
    -- Fallback getTraits()
    local traits = player:getCharacterTraits()
    if not traits then
        traits = player:getTraits()
    end

    if traits then
        if traits.size then
            for i = 0, traits:size() - 1 do
                if traits:get(i) == traitData then
                    return true
                end
            end
        elseif type(traits) == "table" then
            for i = 1, #traits do
                local t = traits[i]
                if t == traitData then return true end
            end
        end
    end
    return false
end

---Calculates combined trait modifier
---@param player IsoPlayer
---@param reactionType string "wakeUp" or "panic"
---@param eventData table (optional, for specific events)
---@return number
local function getTraitModifier(player, reactionType, eventData)
    local modifier = 1.0
    local config = Constants.PlayerReactions[reactionType == "wakeUp" and "WakeUp" or "Panic"]

    -- Apply modifiers (reduce)
    if config.TraitModifiers then
        for trait, mod in pairs(config.TraitModifiers) do
            if hasTrait(player, trait) then
                modifier = modifier * mod
            end
        end
    end

    -- Apply penalties (increase)
    if config.TraitPenalties then
        for trait, penalty in pairs(config.TraitPenalties) do
            -- Special case: Pacifist only with violent events
            if trait == CharacterTrait.PACIFIST and eventData then
                if config.ViolentEvents and config.ViolentEvents[eventData.eventType] then
                    if hasTrait(player, trait) then
                        modifier = modifier * penalty
                    end
                end
            else
                if hasTrait(player, trait) then
                    modifier = modifier * penalty
                end
            end
        end
    end

    return modifier
end

---Calculates exponential decay modifier by world age
---@param worldAge number
---@param reactionType string "wakeUp" or "panic"
---@return number
local function getWorldAgeModifier(worldAge, reactionType)
    local config = Constants.PlayerReactions[reactionType == "wakeUp" and "WakeUp" or "Panic"]
    local decay = config.Decay

    if not decay then
        return 1.0
    end

    -- Formula: minimum + (1 - minimum) * e^(-ln(2) * age / halfLife)
    local exponent = -0.693147 * worldAge / decay.halfLife
    local decayFactor = math.exp(exponent)
    local modifier = decay.minimum + (1.0 - decay.minimum) * decayFactor

    return modifier
end

--//////////////////////////////////////////////////--
--          Distance to Sound                      --
--//////////////////////////////////////////////////--

---Checks if player is within reaction range
---@param player IsoPlayer
---@param eventData table
---@return boolean
local function isPlayerInRange(player, eventData)
    local config = Config.Get()

    -- Get event position
    local eventX = eventData.x
    local eventY = eventData.y

    -- Calculate distance to player
    local playerX = player:getX()
    local playerY = player:getY()
    local distance = Utils.GetDistance(eventX, eventY, playerX, playerY)

    return distance <= config.reactionRange
end

--//////////////////////////////////////////////////--
--          Wake Up Reaction                      --
--//////////////////////////////////////////////////--

---Applies wake up reaction
---@param player IsoPlayer
---@param eventData table
local function applyWakeUpReaction(player, eventData)
    local config = Config.Get()

    -- Check if enabled
    if not config.playerWakeUp then return end

    -- Only if player is asleep
    if not player:isAsleep() then return end

    -- If not an event that causes wake up, exit
    if Constants.NoReactionEvents[eventData.eventType] then return end

    local worldAge = eventData.worldAge or Utils.GetWorldAge()

    -- Base chance
    local wakeUpChance = Constants.PlayerReactions.WakeUp.base

    -- Apply trait modifier
    local traitMod = getTraitModifier(player, "wakeUp", eventData)
    wakeUpChance = wakeUpChance * traitMod

    -- Apply exponential decay by world age
    local ageMod = getWorldAgeModifier(worldAge, "wakeUp")
    wakeUpChance = wakeUpChance * ageMod

    -- Floor
    wakeUpChance = Utils.Floor(wakeUpChance)

    -- Roll
    if wakeUpChance > 0 and Utils.RollProbability(wakeUpChance) then
        player:setAsleep(false)
        player:setAsleepTime(0.0)
        UIManager.FadeIn(player:getPlayerNum(), 1)

        Utils.LogInfo(string.format(
            "Player woken up by %s (chance: %d%%, age mod: %.2f, trait mod: %.2f)",
            eventData.eventType, wakeUpChance, ageMod, traitMod
        ))
    end
end

--//////////////////////////////////////////////////--
--          Panic Reaction                        --
--//////////////////////////////////////////////////--

---Applies panic reaction
---@param player IsoPlayer
---@param eventData table
local function applyPanicReaction(player, eventData)
    local config = Config.Get()

    -- Check if enabled
    if not config.playerPanic then return end

    -- Do not apply if asleep
    if player:isAsleep() then return end

    -- If not an event that causes panic, exit
    if Constants.NoReactionEvents[eventData.eventType] then return end

    local worldAge = eventData.worldAge or Utils.GetWorldAge()
    local panicAmount = 0

    -- Calculate base amount by world age
    if worldAge <= Constants.PlayerReactions.Panic.VeryEarly.threshold then
        panicAmount = Constants.PlayerReactions.Panic.VeryEarly.base
    elseif worldAge <= Constants.PlayerReactions.Panic.Early.threshold then
        panicAmount = Constants.PlayerReactions.Panic.Early.base
    else
        -- After Early threshold, use Early base
        panicAmount = Constants.PlayerReactions.Panic.Early.base
    end

    -- Apply trait modifier
    local traitMod = getTraitModifier(player, "panic", eventData)
    panicAmount = panicAmount * traitMod

    -- Apply exponential decay by world age
    local ageMod = getWorldAgeModifier(worldAge, "panic")
    panicAmount = panicAmount * ageMod

    -- Floor
    panicAmount = Utils.Floor(panicAmount)

    -- Apply panic
    if panicAmount > 0 then
        local stats = player:getStats()
        if stats then
            local currentPanic = stats:get(CharacterStat.PANIC)
            stats:set(CharacterStat.PANIC, currentPanic + panicAmount)

            Utils.LogInfo(string.format(
                "Player panic increased by %d from %s (age mod: %.2f, trait mod: %.2f)",
                panicAmount, eventData.eventType, ageMod, traitMod
            ))
        end
    end
end

--//////////////////////////////////////////////////--
--          Public Functions                      --
--//////////////////////////////////////////////////--

---Applies all relevant reactions to the player
---@param player IsoPlayer
---@param eventData table
function ReactiveSE_PlayerReactions.Apply(player, eventData)
    if not player or not eventData then
        return
    end

    if not isPlayerInRange(player, eventData) then
        -- If out of range, execute nothing further
        return
    end

    -- Apply reactions
    applyWakeUpReaction(player, eventData)
    applyPanicReaction(player, eventData)
end

return ReactiveSE_PlayerReactions
