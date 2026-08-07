--//////////////////////////////////////////////////--
--    Reactive Sound Events - Constants
--    Constants and hardcoded values
--//////////////////////////////////////////////////--

local ReactiveSE_Constants = {}

-- Mod information
ReactiveSE_Constants.MOD_ID = "ReactiveSE"
ReactiveSE_Constants.MOD_VERSION = "1.1.1"
ReactiveSE_Constants.MOD_NAME = "Reactive Sound Events"

-- Default configuration values
ReactiveSE_Constants.Defaults = {
    MIN_COOLDOWN_HOURS = 48,  -- 48 hours
    MAX_COOLDOWN_HOURS = 240, -- 240 hours (10 days)
    EVENT_CHANCE = 4,         -- 4% flat chance per 10-min check
    MAX_PROBABILITY_CAP = 20, -- Cap for exponential mode
    MIN_RANGE = 200,          -- Minimum sound distance
    MAX_RANGE = 600,          -- Maximum sound distance
    REACTION_RANGE = 300,     -- Distance at which zombies react
    MAX_DISTANCE_CAP = 1000,  -- Absolute distance cap

    -- Probabilities
    WEATHER_EVENT_CHANCE = 10,

    -- Player style
    AGGRESSIVE_KILLS = 40,
    PASSIVE_DAYS = 2,

    -- Ticks
    TICK_INTERVAL = 10,     -- Minutes between checks
    UPDATE_INTERVAL = 1440, -- Minutes between updates (1 day)

    -- Event Scenes
    SCENE_CHANCE = 100,
    SCENE_CLEANUP_HOURS = 72,
    SCENE_ACTIVATION_DISTANCE = 90, -- Meters/Tiles

    -- Scene Details
    SCENE_LOOT_QUALITY = 1, -- Enum index
    SCENE_WEAPON_MAX_CONDITION = 100,
    SCENE_RANGED_CHANCE = 30,
    SCENE_BACKPACK_MIN_STEAL_CHANCE = 0,
    SCENE_BACKPACK_MAX_STEAL_CHANCE = 70,
    SCENE_AMMO_SCARCITY = 2, -- Enum index
    SCENE_SUBKIT_COUNT_MIN = 1,
    SCENE_SUBKIT_COUNT_MAX = 3,
    SCENE_CORPSE_COUNT = 3,
    SCENE_SCREAM_ZOMBIE_COUNT = 3,
    SCENE_VEHICLE_MAX_CONDITION = 2, -- Enum index
    SCENE_VEHICLE_KEY_CHANCE = 25,
    SCENE_WORLD_TIER_EARLY_END = 7,
    SCENE_WORLD_TIER_MID_END = 30,
    SCENE_WORLD_TIER_LATE_END = 90,

    -- Scream Scene (Resurrection)
    SCREAM_ACTIVATION_DISTANCE = 4, -- Tiles, very close
    SCREAM_REANIMATE_DELAY_MIN = 2, -- Minutes before resurrection
    SCREAM_REANIMATE_DELAY_MAX = 5, -- Minutes before resurrection
    SCREAM_ZOMBIE_MIN = 3,          -- Min zombies to spawn with scream
    SCREAM_ZOMBIE_MAX = 5,          -- Max zombies to spawn with scream

    -- Resurrection (Non-Scream Scenes)
    RESURRECTION_CHANCE = 25, -- Flat 25% chance for non-scream corpses

    -- Zombie Scene
    ZOMBIE_SCENE_MIN = 8,    -- Default min zombies
    ZOMBIE_SCENE_MAX = 16,   -- Default max zombies
    ZOMBIE_SCENE_RADIUS = 5, -- Spawn radius in tiles
}

-- Distance distribution (probabilities)
ReactiveSE_Constants.DistanceDistribution = {
    CLOSE_CHANCE = 20,  -- 20% close
    MEDIUM_CHANCE = 40, -- 40% medium
    FAR_CHANCE = 40,    -- 40% far

    CLOSE_RATIO = 0.3,  -- 30% of total range
    MEDIUM_START = 0.3, -- Starts at 30%
    MEDIUM_END = 0.7,   -- Ends at 70%
    FAR_START = 0.7,    -- Starts at 70%
}

-- Event types
ReactiveSE_Constants.EventTypes = {
    ANIMAL = "Animal",
    GUNFIGHT = "Gunfight",
    GUNSHOT = "Gunshot",
    SCREAM = "Scream",
    VEHICLE_CRASH = "VehicleCrash",
    WEATHER = "Weather",
    ZOMBIE = "Zombie",
}

-- Event type to configuration mapping
ReactiveSE_Constants.EventConfigMap = {
    [ReactiveSE_Constants.EventTypes.ANIMAL]        = "EnableAnimalEvents",
    [ReactiveSE_Constants.EventTypes.GUNFIGHT]      = "EnableGunfightEvents",
    [ReactiveSE_Constants.EventTypes.GUNSHOT]       = "EnableGunshotEvents",
    [ReactiveSE_Constants.EventTypes.SCREAM]        = "EnableScreamEvents",
    [ReactiveSE_Constants.EventTypes.VEHICLE_CRASH] = "EnableVehicleCrashEvents",
    [ReactiveSE_Constants.EventTypes.WEATHER]       = "EnableWeatherEvents",
    [ReactiveSE_Constants.EventTypes.ZOMBIE]        = "EnableZombieEvents",
}

-- Event type to scene configuration mapping
ReactiveSE_Constants.SceneConfigMap = {
    [ReactiveSE_Constants.EventTypes.GUNFIGHT]      = "EnableGunfightScene",
    [ReactiveSE_Constants.EventTypes.GUNSHOT]       = "EnableGunshotScene",
    [ReactiveSE_Constants.EventTypes.SCREAM]        = "EnableScreamScene",
    [ReactiveSE_Constants.EventTypes.VEHICLE_CRASH] = "EnableVehicleCrashScene",
    [ReactiveSE_Constants.EventTypes.ZOMBIE]        = "EnableZombieScene",
}

-- Event selection probabilities
ReactiveSE_Constants.EventSelection = {
    FAVORITE_CHANCE = 50, -- 50% for highest priority
    SECOND_CHANCE = 30,   -- 30% for second priority
    RANDOM_CHANCE = 20,   -- 20% random from the rest
}

-- Priority modifiers by time of day
ReactiveSE_Constants.TimeModifiers = {
    Day = {
        Animal = 2,
        Gunfight = 1,
        VehicleCrash = 1,
    },
    Night = {
        Gunshot = 2,
        Scream = 3,
        VehicleCrash = -3,
        Zombie = 4,
    }
}

-- Modifiers by world age (days)
ReactiveSE_Constants.WorldAgeModifiers = {
    Early = { -- 0-30 days
        threshold = 30,
        modifiers = {
            Animal = 1,
            Gunfight = -1,
            Gunshot = 2,
            VehicleCrash = 2,
        }
    },
    Mid = { -- 31-90 days
        threshold = 90,
        modifiers = {
            Animal = -4,
            Scream = 2,
            Zombie = 2,
        }
    },
    Late = { -- 91+ days
        threshold = 999999,
        modifiers = {
            Animal = -10,
            Gunfight = 1,
            Gunshot = 1,
            VehicleCrash = -5,
            Zombie = 3,
        }
    }
}

-- Weather modifiers
ReactiveSE_Constants.ClimateModifiers = {
    extreme = {
        Animal = -2,
        Scream = 2,
        VehicleCrash = 2,
    }
}

-- Location modifiers
ReactiveSE_Constants.LocationModifiers = {
    City = {
        Animal = 1,
        Gunfight = 3,
        Scream = 2,
        VehicleCrash = 2,
    },
    Rural = {
        Gunfight = -3,
        Gunshot = 3,
        Scream = -2,
        VehicleCrash = -3,
        Zombie = 2,
    }
}

-- Player style modifiers
ReactiveSE_Constants.PlayerStyleModifiers = {
    Passive = {
        Gunfight = 2,
        Gunshot = 3,
        Scream = 2,
        Zombie = 2,
    },
    Aggressive = {
        Animal = -1,
        Gunfight = -1,
        Gunshot = 2,
        Scream = -1,
        Zombie = -2,
    }
}

-- Base priority for disabled events
ReactiveSE_Constants.DISABLED_EVENT_PRIORITY = 20

-- Base priority for enabled events
ReactiveSE_Constants.ENABLED_EVENT_PRIORITY = 100

-- Minimum threshold for a valid event
ReactiveSE_Constants.MIN_VALID_PRIORITY = 100

-- Player reactions
ReactiveSE_Constants.PlayerReactions = {
    WakeUp = {
        base = 25,

        -- Traits that REDUCE wake up probability
        TraitModifiers = {
            [CharacterTrait.BRAVE] = 0.8,            -- -20%
            [CharacterTrait.HARD_OF_HEARING] = 0.6,  -- -40%
            [CharacterTrait.NEEDS_MORE_SLEEP] = 0.7, -- -30% (duerme más profundo)
        },

        -- Traits that INCREASE wake up probability
        TraitPenalties = {
            [CharacterTrait.COWARDLY] = 1.5,  -- +50%
            [CharacterTrait.INSOMNIAC] = 1.6, -- +60% (duerme ligero)
        },

        -- Exponential decay by world age
        Decay = {
            halfLife = 30,  -- 50% at day 30
            minimum = 0.02, -- Minimum 2% (never reaches 0)
        },
    },

    Panic = {
        VeryEarly = {
            threshold = 15, -- 0-15 días
            base = 100,
        },
        Early = {
            threshold = 30, -- 16-30 días
            base = 50,
        },

        -- Traits that REDUCE panic
        TraitModifiers = {
            [CharacterTrait.BRAVE] = 0.5,           -- -50%
            [CharacterTrait.DESENSITIZED] = 0.3,    -- -70%
            [CharacterTrait.HARD_OF_HEARING] = 0.7, -- -30%
        },

        -- Traits that INCREASE panic
        TraitPenalties = {
            [CharacterTrait.COWARDLY] = 1.8, -- +80%
            [CharacterTrait.PACIFIST] = 1.4, -- +40% (solo eventos violentos)
        },

        -- Violent events (for Pacifist trait)
        ViolentEvents = {
            Gunfight = true,
            Gunshot = true,
        },

        -- Exponential decay by world age
        Decay = {
            halfLife = 30,  -- 50% at day 30
            minimum = 0.02, -- Minimum 2% (never reaches 0)
        },
    },
}

-- Events that don't cause wake up or panic
ReactiveSE_Constants.NoReactionEvents = {
    [ReactiveSE_Constants.EventTypes.ANIMAL] = true,
    [ReactiveSE_Constants.EventTypes.WEATHER] = true,
}

-- Urban zones
ReactiveSE_Constants.UrbanZones = {
    ["TownZone"] = true,
    ["Town"] = true,
    ["TrailerPark"] = true,
    ["Nav"] = true,
}

-- Blocked zones to prevent events
ReactiveSE_Constants.BlockedZones = {
    ["Water"] = true,
    ["FarmLand"] = true,
}

-- Extreme weather IDs
ReactiveSE_Constants.ExtremeWeatherIDs = {
    [3] = true, -- Storm
    [7] = true, -- Blizzard
    [8] = true, -- Tropical Storm
}

-- Rain storm IDs
ReactiveSE_Constants.RainStormIDs = {
    [3] = true, -- Storm
    [8] = true, -- Tropical Storm
}

-- Rain intensity threshold
ReactiveSE_Constants.EXTREME_RAIN_THRESHOLD = 0.75

-- Day/night schedules by season (months 0-11)
ReactiveSE_Constants.DayNightSchedule = {
    Spring = { -- Marzo, Abril, Mayo (2-4)
        months = { 2, 3, 4 },
        nightStart = 22,
        nightEnd = 6,
    },
    Summer = { -- Junio, Julio, Agosto (5-7)
        months = { 5, 6, 7 },
        nightStart = 21,
        nightEnd = 6,
    },
    Autumn = { -- Septiembre, Octubre, Noviembre (8-10)
        months = { 8, 9, 10 },
        nightStart = 22,
        nightEnd = 6,
    },
    Winter = { -- Diciembre, Enero, Febrero (11, 0, 1)
        months = { 11, 0, 1 },
        nightStart = 23,
        nightEnd = 6,
    }
}

-- Network commands for multiplayer
ReactiveSE_Constants.NetworkCommands = {
    PLAY_SOUND_EVENT = "PlaySoundEvent",
    SYNC_MODDATA = "SyncModData",
    RADIO_INTEL = "RadioIntel",
}

-- Attempt limit to avoid infinite loops
ReactiveSE_Constants.MAX_ATTEMPTS = 20

-- Number of clips to remember to avoid repetition
ReactiveSE_Constants.CLIP_HISTORY_SIZE = 3

--//////////////////////////////////////////////////--
--          Knox Relay Radio Station              --
--//////////////////////////////////////////////////--

-- Radio Station Configuration
ReactiveSE_Constants.Radio = {
    NEW_FREQ = 112400, -- 112.4 MHz
    OLD_FREQ = 99800,  -- 99.8 MHz
    UUID = "KNOX-RELAY-001",
    NAME = "Knox Relay",
    CATEGORY = "Bandit",
    BROADCAST_HOURS = { 7, 13, 19 }, -- 7AM, 1PM, 7PM
}

-- Host Rotation
ReactiveSE_Constants.RadioHosts = {
    MARCUS = "Marcus",
    JENNA = "Jenna",
    RAY = "Ray",
}

-- Story Timeline
ReactiveSE_Constants.RadioTimeline = {
    JENNA_LAST_DAY = 30,            -- Jenna leaves on Day 30
    RAY_LAST_DAY = 90,              -- Ray dies on Day 90
    MARCUS_FINAL_DAYS = { 91, 92 }, -- Marcus's final morning shows
    STATIC_INTEL_DAYS = { 30, 90 }, -- Days with no dynamic scene reports
}

return ReactiveSE_Constants
