require "LifestyleCore/LSK_Features"

LifestyleSecure = LifestyleSecure or {}
LifestyleSecure.SystemContracts = LifestyleSecure.SystemContracts or {}

local Contracts = LifestyleSecure.SystemContracts

Contracts.ByName = {
    Music = {
        authority = "server",
        tickLane = "slow",
        syncRadius = 45,
        maxActionSeconds = 1800,
        persistence = { "music", "learnedTracks", "musicPreferences" },
    },
    Dancing = {
        authority = "server",
        tickLane = "normal",
        syncRadius = 35,
        maxActionSeconds = 900,
        persistence = { "dance", "danceMoves" },
    },
    Meditation = {
        authority = "server",
        tickLane = "slow",
        syncRadius = 12,
        maxActionSeconds = 1800,
        persistence = { "wellness", "hiddenSkills" },
    },
    Hygiene = {
        authority = "server",
        tickLane = "slow",
        syncRadius = 20,
        maxActionSeconds = 900,
        persistence = { "hygiene", "needs", "cooldowns" },
    },
    Art = {
        authority = "server",
        tickLane = "slow",
        syncRadius = 25,
        maxActionSeconds = 3600,
        persistence = { "art", "beauty", "artworks" },
    },
    Ambitions = {
        authority = "server",
        tickLane = "minute",
        syncRadius = 0,
        maxActionSeconds = 0,
        persistence = { "ambitions" },
    },
    Inventions = {
        authority = "server",
        tickLane = "slow",
        syncRadius = 25,
        maxActionSeconds = 3600,
        persistence = { "inventions", "hiddenSkills" },
    },
    Comfort = {
        authority = "server",
        tickLane = "slow",
        syncRadius = 8,
        maxActionSeconds = 0,
        persistence = { "comfort", "wardrobe" },
    },
    Social = {
        authority = "server",
        tickLane = "normal",
        syncRadius = 20,
        maxActionSeconds = 600,
        persistence = { "social" },
    },
}

Contracts.ActionRewards = {
    { prefix = "PlayInstrument", perks = { Music = 1.5 } },
    { prefix = "PlayDJ", perks = { Music = 1.5 } },
    { prefix = "PlayerIsDancing", perks = { Dancing = 1.5, Fitness = 0.75 } },
    { prefix = "CleanRoom", perks = { Cleaning = 2.0 } },
    { prefix = "LSClean", perks = { Cleaning = 2.0 } },
    -- Unclog grants a large one-shot Cleaning reward; rate must cover a typical action length.
    { prefix = "LSUnclog", perks = { Cleaning = 3.0 } },
    -- Meditation is the player-facing yoga skill (UI "Медитация"); Fitness/Nimble are side gains.
    { prefix = "LSYoga", perks = { Yoga = 1.5, Fitness = 0.75, Nimble = 0.5, Meditation = 1.5 } },
    { prefix = "LSMeditate", perks = { Meditation = 1.5 } },
    { prefix = "LSCanvas", perks = { Art = 1.5 } },
    { prefix = "LSSculpt", perks = { Art = 1.5 } },
    { prefix = "LSFix", perks = { Maintenance = 1.0 } },
    { prefix = "LSIW", perks = { Inventing = 1.0 } },
}

function Contracts.GetActionRewardRate(actionName, perkName)
    if type(actionName) ~= "string" or type(perkName) ~= "string" then
        return nil
    end
    for i = 1, #Contracts.ActionRewards do
        local entry = Contracts.ActionRewards[i]
        if string.sub(actionName, 1, string.len(entry.prefix)) == entry.prefix then
            return entry.perks[perkName]
        end
    end
    return nil
end

function Contracts.Get(name)
    return Contracts.ByName[name]
end

function Contracts.IsEnabled(name)
    return Contracts.ByName[name] ~= nil and LifestyleSecure.Features.IsEnabled(name)
end

function Contracts.GetSyncRadius(name)
    local contract = Contracts.ByName[name]
    return contract and contract.syncRadius or 0
end

function Contracts.GetMaxActionSeconds(name)
    local contract = Contracts.ByName[name]
    return contract and contract.maxActionSeconds or 0
end

return Contracts
