local AE_MasterConfig = {}

------------------------------------------------------------------------------------------------------------------------------------
-------------------
-- CORE SYSTEMS: --
-------------------
-- Set to false to completely disable a system --

AE_MasterConfig.Systems = {
    TamingSystem = true,           -- Enable/disable the taming system entirely
    FriendlinessSystem = true,     -- Enable/disable friendliness/XP system
    HungerSystem = false,           -- Enable/disable custom hunger/thirst system
    CommandSystem = true,          -- Enable/disable animal command system
    CombatProtection = true,       -- Enable/disable damage protection for tamed animals
    LivesSystem = true,            -- Enable/disable respawn/lives system
    EquipmentSystem = false,        -- Enable/disable equipment system
    InventorySystem = true,        -- Enable/disable backpack/inventory system
    StatusMenu = true,             -- Enable/disable status menu UI
    SummoningItem = true,          -- Enable/disable summoning item system
    ForagingSystem = true,         -- Enable/disable foraging/hunting command system
    RidingSystem = false,          -- Enable/disable animal riding system
}

------------------------------------------------------------------------------------------------------------------------------------
-----------------------------
-- ANIMAL REGISTRY CONFIG: --
-----------------------------
--- Define which animal categories are handled by this framework instance ---
--- Each category maps to specific IsoAnimal types and has a CoreUtilities module ---
--- This allows multiple animal mods to coexist without conflicts ---

AE_MasterConfig.RegisteredAnimals = {
    {
        category = "cat",                                        -- Display name/category identifier
        coreUtilitiesPath = "AnimalsEssentials/ForModders/AE_CoreUtilities",  -- Path to animal-specific CoreUtilities module
        isoTypes = {"kttr", "kttrmanx", "smokeykttr"},    -- Actual IsoAnimal types from definitions
    },
    -- Example for future modding:
    -- {
    --     category = "dog",
    --     coreUtilitiesPath = "DogMod/DogCoreUtilities",
    --     isoTypes = {"puppy", "dogMale", "dogFemale"},
    -- },
}

------------------------------------------------------------------------------------------------------------------------------------
------------------------------------
-- PER-ANIMAL CONFIGURATION: --
------------------------------------
--- This section contains all settings that can vary by animal type ---
--- Each animal category has its own subsection with complete configuration ---

AE_MasterConfig.AnimalConfig = {
    ----------------------
    -- CAT CONFIGURATION:
    ----------------------
    ["cat"] = {
        -- Taming System Settings --
        Taming = {
            --- Taming Foods Whitelist: Food items and their taming values ---
            --- Format: ["ItemType"] = [taming value (1-100)] ---
            --- When animal eats this food, it gains this much tameness (1-100) ---
            AcceptedFoods = {
                ["Base.CatTreats"] = 100,
                ["Base.CatFoodBag"] = 100,
                ["Base.Caviar"] = 100,
                ["Base.Steak"] = 100,
                ["Base.Venison"] = 100,
                ["Base.Ham"] = 100,
                ["Base.ChickenWhole"] = 100,
                ["Base.RatKing"] = 100,
                ["Base.Walleye"] = 100,
                ["Base.WhiteBass"] = 100,
                ["Base.WhiteCrappie"] = 100,
                ["Base.YellowPerch"] = 100,
                ["Base.BlueCatfish"] = 100,
                ["Base.BlackCrappie"] = 100,
                ["Base.AligatorGar"] = 100,
                ["Base.FlatheadCatfish"] = 100,
                ["Base.FreshwaterDrum"] = 100,
                ["Base.GreenSunfish"] = 100,
                ["Base.LargemouthBass"] = 100,
                ["Base.Muskellunge"] = 100,
                ["Base.Paddlefish"] = 100,
                ["Base.RedearSunfish"] = 100,
                ["Base.Sauger"] = 100,
                ["Base.SmallmouthBass"] = 100,
                ["Base.SpottedBass"] = 100,
                ["Base.Squid"] = 85,
                ["Base.Salmon"] = 85,
                ["Base.DogFoodBag"] = 85,
                ["Base.CannedMilkOpen"] = 85,
                ["Base.MuttonChop"] = 85,
                ["Base.Burger"] = 85,
                ["Base.BurgerRecipe"] = 85,
                ["Base.Bacon"] = 75,
                ["Base.Rabbitmeat"] = 75,
                ["Base.DeadRabbit"] = 75,
                ["Base.SushiFish"] = 75,
                ["Base.CannedSardinesOpen"] = 75,
                ["Base.TunaTinOpened"] = 75,
                ["Base.PorkChop"] = 75,
                ["Base.ChickenNuggets"] = 35,
                ["Base.HamSlice"] = 15,
                ["Base.Pepperoni"] = 15,
                ["Base.TurkeyWings"] = 45,
                ["Base.TurkeyLegs"] = 65,
                ["Base.DeadRat"] = 35,
                ["Base.DeadSquirrel"] = 45,
                ["Base.FrogMeat"] = 35,
                ["Base.DeadRatBaby"] = 25,
                ["Base.DeadMousePups"] = 25,
                ["Base.DeadMouseSkinned"] = 35,
                ["Base.DeadMousePupsSkinned"] = 25,
                ["Base.DeadRatSkinned"] = 35,
                ["Base.DeadRatBabySkinned"] = 25,
                ["Base.DeadBird"] = 65,
                ["Base.FishFried"] = 65,
                ["Base.FishFillet"] = 65,
                ["Base.FishFingers"] = 55,
                ["Base.ShrimpFried"] = 35,
                ["Base.ShrimpFriedCraft"] = 35,
                ["Base.Hotdog_single"] = 35,
                ["Base.Mussels"] = 25,
                ["Base.Oysters"] = 15,
                ["Base.OystersFried"] = 25,
                ["Base.ShrimpDumpling"] = 35,
                ["Base.ChickenFoot"] = 35,
                ["Base.Corndog"] = 35,
                ["Base.SushiEgg"] = 25,
                ["Base.ChickenFried"] = 65,
                ["Base.PeanutButter"] = 55,
                ["Base.Shrimp"] = 25,
                ["Base.BaitFish"] = 15,
                ["Base.ChickenFillet"] = 45,
                ["Base.CannedCornedBeefOpen"] = 65,
                ["Base.BaconBits"] = 15,
                ["Base.BaloneySlice"] = 15,
                ["Base.BeefJerky"] = 55,
                ["Base.MeatPatty"] = 45,
                ["Base.CannedBologneseOpen"] = 65,
                ["Base.Hotdog"] = 55,
                ["Base.Chicken"] = 65,
                ["Base.Smallbirdmeat"] = 65,
                ["Base.Smallanimalmeat"] = 45,
                ["Base.MincedMeat"] = 45,
                ["Base.Baloney"] = 45,
                ["Base.Salami"] = 45,
                ["Base.DogfoodOpen"] = 25,
                ["Base.DeadMouse"] = 35,
            },
            --- Tameness required to fully tame (0-100) ---
            TamenessThreshold = 100,
        },

        -- Friendliness System Settings --
        Friendliness = {
            --- XP multipliers for different actions ---
            --- Higher values = more XP awarded to player ---
            XP_Multiplier_Petting = 0.5,   -- XP gained when petting animal
            XP_Multiplier_Feeding = 1.0,   -- XP gained when feeding animal
            XP_Multiplier_Watering = 1.0,  -- XP gained when giving water
            XP_Multiplier_Command = 0.3,   -- XP gained when animal obeys command

            --- Friendliness ranges (do not modify unless you know what you're doing) ---
            Max_Friendliness = 100.0,
            Min_Friendliness = 0.0,
        },

        -- Hunger/Thirst System Settings --
        HungerSystem = {
            --- Hunger/Thirst depletion rates (per game hour) ---
            HungerDecreaseRate = 0.05,      -- How fast hunger depletes
            ThirstDecreaseRate = 0.08,      -- How fast thirst depletes

            --- Starvation/Dehydration damage ---
            StarvationDamage = 0.1,         -- Health damage per hour when starving
            DehydrationDamage = 0.15,       -- Health damage per hour when dehydrated

            --- Critical thresholds ---
            StarvationThreshold = 5,        -- Start taking damage below this %
            DehydrationThreshold = 5,       -- Start taking damage below this %
        },

        -- Care/Feeding System Settings --
        CareUI = {
            --- Allowed Foods & Watering Whitelist: Acceptable food items for feeding animals ---
            --- Format: ["ItemType"] = [satiety value: 1-100] (how much hunger% restored) ---
            ----- NOTE: this exists as a separate table from the Taming AcceptedFoods if ... -----
            ----- ... modders would like to set different items for taming-vs-feeding -----
            AcceptableFoods = {
                ["Base.CatTreats"] = 100,
                ["Base.CatFoodBag"] = 100,
            },
        },

        -- Lives System Settings --
        Lives = {
            --- Maximum number of lives this animal has ---
            --- NOTE: Respawn timing and behavior settings are configured globally in AE_MasterConfig.Lives ---
            MaxLives = 9,
        },

        -- Combat Protection Settings --
        CombatProtection = {
            --- If true, tamed animals are completely invulnerable to damage ---
            --- If false, they can still take damage but won't die (requires LivesSystem) ---
            CompleteInvulnerability = true,

            --- Allow death from starvation/dehydration even with protection enabled? ---
            AllowStarvationDeath = true,
        },

        -- Commands System Settings --
        Commands = {
            --- Follow command constants ---
            FollowMinInterval = 1,          -- Min seconds between path updates
            FollowMaxInterval = 12,         -- Max seconds between path updates
            FollowMaxDistance = 20,         -- Max follow distance at 0 friendliness (tiles)
            FollowMinDistance = 5,          -- Min follow distance at 100 friendliness (tiles)
            FollowMaxSpeed = 10,            -- Max speed multiplier at 100 friendliness
            FollowMinSpeed = 1,             -- Min speed multiplier at 0 friendliness
            FollowCooldown = 10,            -- Pspspsps boost cooldown (seconds)

            --- Stay command constants ---
            StayMinDuration = 1,            -- Min stay duration at 0 friendliness (seconds)
            StayMaxDuration = 200,          -- Max stay duration at 100 friendliness (seconds)
            StayHungerBreak = 30,           -- Break stay if hunger below this %
            StayThirstBreak = 30,           -- Break stay if thirst below this %

            --- Go-To command constants ---
            GoToMinDelay = 1,               -- Min delay before executing go-to (seconds)
            GoToMaxDelay = 10,              -- Max delay before executing go-to (seconds)
            GoToCooldown = 30,              -- Cooldown between go-to commands (seconds)

            --- Pathfinding timeout ---
            PathfindTimeout = 16,           -- Timeout for stuck pathfinding (seconds)

            --- Command failure messages (rotates through these) ---
            FailureMessages = {
                "This is one stubborn animal!",
                "They're not listening to me!",
                "The animal isn't friendly enough",
                "Listen to me!!",
            },
        },

        -- Behavior System Settings --
        Behavior = {
            --- AI behavior settings ---
            FollowDistance = 2.0,           -- How close animal follows player
            WanderRadius = 10.0,            -- How far animal wanders when not following
            UpdateFrequency = 0.1,          -- How often AI updates (in game hours)

            --- WanderLust Behavior ---
            WanderLust = {
                Enabled = true,
                MinDistance = 3,           -- Minimum wander distance in tiles
                MaxDistance = 30,          -- Maximum wander distance in tiles
                MinCooldown = 10,          -- Minimum cooldown in game minutes
                MaxCooldown = 120,         -- Maximum cooldown in game minutes
                ScaleIncrement = 1.5,      -- How fast the wanderlust scale builds up
            },

            --- ReturnHome Behavior ---
            ReturnHome = {
                Enabled = true,
                MinWanderCount = 3,        -- Min wanders before returning home
                MaxWanderCount = 9,        -- Max wanders before returning home
                MinRestHours = 8,          -- Min rest time at home (game hours)
                MaxRestHours = 24,         -- Max rest time at home (game hours)
            },

            --- Flee Behavior ---
            Flee = {
                Enabled = true,
                MinDuration = 10,          -- Min flee duration in game minutes
                MaxDuration = 60,          -- Max flee duration in game minutes
                ZombieDetectionRadius = 15, -- Radius for zombie detection (tiles)
                ZombiePanicMin = 5,        -- Min panic increase per zombie per second
                ZombiePanicMax = 15,       -- Max panic increase per zombie per second
                PanicDecayRate = 2,        -- How fast panic decreases when safe
                GunshotMinDistance = 30,   -- Min gunshot detection distance
                GunshotMaxDistance = 70,   -- Max gunshot detection distance
            },

            --- Retaliatory Behavior (Fight/Flight response to damage) ---
            Retaliatory = {
                Enabled = true,
                FightEnabled = true,
                FlightEnabled = true,
                FightHPThreshold = 60,
                FightDurationMinutes = 30,
                FlightHPThreshold = 60,
                FlightDurationMinutes = 60,
                FlightMinRetriggers = 3,
                FlightMaxRetriggers = 12,
                FlightRetriggerCooldownMinutes = 60,
                FlightTriggerRadius = 15,
                DamageCheckInterval = 0.5,
                MinDamageThreshold = 1,
            },

            --- Hostility Behavior (Autonomous aggression) ---
            Hostility = {
                Enabled = true,
                PlayerHostility = false,
                PreyAnimals = {},
                MaleHostility = false,
                DetectionRadius = 30,
                ChaseRadius = 40,
                AttackCooldownSeconds = 5,
                EngageDurationMinutes = 60,
                OnlyWhenHungry = false,
                HungerThreshold = 50,
                AvoidStrongerTargets = false,
                DisengsageWhenInjured = false,
                InjuredThreshold = 10,
            },
        },

        -- Foraging System Settings --
        Foraging = {
            --- Foraging loot tables by friendliness tier ---
            --- Each tier has items with weight and quantity ranges ---
            --- Format: {item = "Base.ItemType", weight = number, quantity = {min = number, max = number}} ---
            
            tables = {
                --- Low tier foraging (0-35 friendliness, 50 weight points) ---
                LOW = {
                    {item = "Base.Worm", weight = 15, quantity = {min = 1, max = 2}},
                    {item = "Base.GrasshopperDead", weight = 10, quantity = {min = 1, max = 1}},
                    {item = "Base.Cockroach", weight = 8, quantity = {min = 1, max = 1}},
                    {item = "Base.Cricket", weight = 12, quantity = {min = 1, max = 2}},
                    {item = "Base.BugMeatCritical", weight = 5, quantity = {min = 1, max = 1}},
                },
                
                --- Medium tier foraging (36-68 friendliness, 100 weight points) ---
                MEDIUM = {
                    {item = "Base.Worm", weight = 20, quantity = {min = 1, max = 3}},
                    {item = "Base.GrasshopperDead", weight = 15, quantity = {min = 1, max = 2}},
                    {item = "Base.DeadMouse", weight = 8, quantity = {min = 1, max = 1}},
                    {item = "Base.Cricket", weight = 18, quantity = {min = 2, max = 4}},
                    {item = "Base.Berries", weight = 10, quantity = {min = 1, max = 2}},
                    {item = "Base.BugMeat", weight = 12, quantity = {min = 1, max = 2}},
                    {item = "Base.MushroomGeneric1", weight = 7, quantity = {min = 1, max = 1}},
                },
                
                --- High tier foraging (69-100 friendliness, 200 weight points) ---
                HIGH = {
                    {item = "Base.DeadMouse", weight = 25, quantity = {min = 1, max = 2}},
                    {item = "Base.DeadRat", weight = 15, quantity = {min = 1, max = 1}},
                    {item = "Base.DeadBird", weight = 12, quantity = {min = 1, max = 1}},
                    {item = "Base.Berries", weight = 20, quantity = {min = 2, max = 4}},
                    {item = "Base.Mushroom", weight = 18, quantity = {min = 1, max = 3}},
                    {item = "Base.WildEggs", weight = 8, quantity = {min = 1, max = 2}},
                    {item = "Base.BugMeat", weight = 15, quantity = {min = 2, max = 3}},
                    {item = "Base.MushroomGeneric2", weight = 10, quantity = {min = 1, max = 2}},
                    {item = "Base.BerriesBlack", weight = 12, quantity = {min = 1, max = 3}},
                    {item = "Base.BerriesBlue", weight = 10, quantity = {min = 1, max = 2}},
                },
            },
            
            --- Foraging behavior settings ---
            minForagingHours = 2,           -- Minimum foraging duration
            maxForagingHours = 6,           -- Maximum foraging duration  
            preyDetectionMultiplier = 2.0,  -- Detection radius multiplier while foraging
            playerInteractionDistance = 6,  -- Distance to trigger results UI
            renderDistance = 30,            -- Teleport distance when out of render
            
            --- Friendliness tier thresholds and points ---
            friendlinessTiers = {
                LOW = {min = 0, max = 35, points = 50},
                MEDIUM = {min = 36, max = 68, points = 100}, 
                HIGH = {min = 69, max = 100, points = 200}
            },
        },
    },
}

------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------
-- GLOBAL LIVES/RESPAWN CONFIGURATION:
-----------------------------------
-- These settings control the respawn system behavior for ALL animal types --
-- NOTE: MaxLives is configured per-animal in AnimalConfig["category"].Lives.MaxLives --

AE_MasterConfig.Lives = {
    --- Delay before respawning (in ticks, 60 ticks = 1 second) ---
    RespawnDelayTicks = 10,

    --- Respawn at death location or near player? ---
    RespawnAtDeathLocation = true,
    RespawnNearPlayer = false,

    --- If respawning near player, how far away? ---
    RespawnRadius = 5,
}

------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------
-- GLOBAL PETTING CONFIGURATION:
-----------------------------------
-- These settings apply to ALL animal types --

AE_MasterConfig.Petting = {
    --- Keybind to pet animal (Keyboard key code) ---
    --- Default: 18 = 'E' key ---
    KeyBind = 18,

    --- Detection radius (in tiles) ---
    DetectionRadius = 2,

    --- Cooldown between petting (in seconds) ---
    PettingCooldown = 5,
}

------------------------------------------------------------------------------------------------------------------------------------
------------------------------------
-- STATUS MENU & CARE UI CONFIGS: --
------------------------------------

AE_MasterConfig.StatusMenu = {
    ---- NOTE: there will be a separate setting for keybinds (in the game's keybind controls) ... ----
            ---- ... this keybind control here is used on a deeper level for the framework ----
    --- Keybind Config for opening the status menu (Keyboard key code) ---
    KeyBind = 44,
    --- Default: 44 = 'Z' key ---
    ---- Common keys: 18='E', 19='F', 20='G', 21='H', 44='Z', 46='C', 47='V', 48='B' ----

    --- Distance check for feeding/watering (in tiles) ---
    FeedDistance = 5,

    --- UI refresh rate (in ticks, 60 ticks = 1 second) ---
    RefreshRate = 30,
}

AE_MasterConfig.CareUI = {
    --- Distance check for feeding/watering (in tiles) ---
    FeedDistance = 5,

    --- Water container types (whitelist of items that can give water) ---
           ---- NOTE: these must be valid water container items ----
    WaterContainers = {
        "Base.WaterBottle", "Base.WaterBottleFull", "Base.Saucepan", "Base.Pot",
        "Base.Kettle", "Base.Bowl", "Base.BowlWhite", "Base.BowlRed",
        "Base.MugWhite", "Base.MugRed", "Base.MugBlue", "Base.MugSpiffo", "Base.Mugl",
        "Base.WaterGlass", "Base.GlassWater", "Base.WineGlass", "Base.GlassWine",
        "Base.PopBottle", "Base.PopBottleEmpty", "Base.PopEmpty", "Base.PlasticCup",
        "Base.BucketEmpty", "Base.BucketWaterFull", "Base.DrinkingGlass",
        "farming.WateringCan",
    },
}

------------------------------------------------------------------------------------------------------------------------------------
------------------------------
-- EQUIPMENT SYSTEM CONFIG: --
------------------------------
-- Main Equipment Stuffs: --

AE_MasterConfig.Equipment = {
    --- Enable/disable equipment system ---
    Enabled = true,

    --------------------------------------------------------------------------------
    -- PER-ANIMAL EQUIPMENT CONFIG:
    -- Each animal type has its own equipment slots, body locations, and data module
    --------------------------------------------------------------------------------

    --- CATEGORY: CAT EQUIPMENT ---
    ["cat"] = {
        --- Equipment slots for cats - positioned relative to 242px cat at (132,98) ---
        --- Cat boundaries: left=132, right=374, top=98, bottom=340 ---
        --- UI: 506x438 window. Back button at (10,403) ---
        Slots = {
            -- Top row (moved 10px higher: 50px above cat)
            {id = "backpack", name = "B.P", x = 143, y = 38, width = 40, height = 40},   -- Left-aligned with cat
            {id = "vest", name = "V", x = 233, y = 38, width = 40, height = 40},         -- Cat center-left  
            {id = "head", name = "H", x = 323, y = 38, width = 40, height = 40},         -- Cat center-right
            -- Right column (20px right of cat)
            {id = "face", name = "F", x = 394, y = 120, width = 40, height = 40},        -- Upper right
            {id = "accessory", name = "A", x = 394, y = 190, width = 40, height = 40},   -- Mid right
            {id = "socks", name = "S", x = 394, y = 260, width = 40, height = 40},       -- Lower right (corrected)
            -- Bottom row (20px below cat)
            {id = "fannypack", name = "F.P", x = 143, y = 370, width = 40, height = 40}, -- Left-aligned with cat (corrected)
            {id = "paws", name = "P", x = 253, y = 370, width = 40, height = 40},        -- Cat center (corrected)
        },

        --- Body location mappings (from AttachedLocations in game engine) ---
        --- Maps equipment slot IDs to IsoAnimal AttachedLocation strings ---
        BodyLocations = {
            head = "CAT_FORCE_ONE_VEST",
            face = "CAT_FORCE_ONE_VEST", 
            vest = "CAT_FORCE_ONE_VEST",
            backpack = "CAT_FORCE_ONE_BACKPACK",
            accessory = "CAT_FORCE_ONE_VEST",
            fannypack = "CAT_FORCE_ONE_BACKPACK",
            paws = "CAT_FORCE_ONE_VEST",
            socks = "CAT_FORCE_ONE_VEST",
        },
        --- Path to animal-specific equipment data module ---
        --- This module should export isItemAllowedInSlot(item, slotID) function ---
        --- NOTE: Path is relative to the mod's lua directory root
        DataModulePath = "KittyEquipmentData",
    },
}

---------------------------------
-- Equipment Technical Stuffs: --
AE_MasterConfig.EquipmentSystem = {

    --- Visual attachment restoration delay (in ticks) ---
    RestoreDelay = 20,

    --- Equipment persistence enabled ---
    SaveEquipment = true,
}

------------------------------------------------------------------------------------------------------------------------------------
---------------------------------
-- EQUIPMENT SYSTEM UI CONFIG: --
---------------------------------

AE_MasterConfig.EquipmentUI = {
    --- Texture paths for equipment UI, organized by animal type ---
    --- This allows different animals to have different UI appearances ---

    TexturePaths = {
        ["cat"] = {
            Background = "media/ui/animals/cat_equipment_bg.png",
            SlotHighlight = "media/ui/animals/slot_highlight.png",
            SlotEmpty = "media/ui/animals/slot_empty.png",
        },
        ---- Add more animal types as needed ----
    },

    --- Default textures if animal type not found above ---
    DefaultTextures = {
        Background = "media/ui/animals/default_equipment_bg.png",
        SlotHighlight = "media/ui/animals/slot_highlight.png",
        SlotEmpty = "media/ui/animals/slot_empty.png",
    },
}

------------------------------------------------------------------------------------------------------------------------------------
------------------------------
-- INVENTORY SYSTEM CONFIG: --
------------------------------
-- Main Inventory Stuffs: --

AE_MasterConfig.Inventory = {
    --- Grid size for backpack inventory ---
    DefaultGridWidth = 4,
    DefaultGridHeight = 4,

    --- Backpack capacities by item type ---
    BackpackCapacity = {
        ["Base.Bag_DuffelBag"] = {width = 5, height = 5},
        ["Base.Bag_FannyPackFront"] = {width = 3, height = 3},
        ---- Add more backpack types as needed ----
    },
}

------------------------------
-- Tamed Animal Bag Stuffs: --
AE_MasterConfig.InventorySystem = {
    --- Bag following behavior ---
    FollowUpdateInterval = 15,          -- How often bag position updates (ticks)
    BagMoveDistanceThreshold = 2.0,     -- Minimum distance before bag moves

    --- Bag item type (what bag item to use) ---
    BagType = "Base.Bag_BigHikingBag",

    --- Grid dimensions (standard inventory grid) ---
    GridWidth = 6,
    GridHeight = 8,

    --- Initialization timing ---
    InitializationDelay = 25,           -- Delay before activating bags on game start (ticks)
    DeferredCheckInterval = 60,         -- How often to check for deferred bags (ticks)

    --- Pathfinding for "Give Items" command ---
    PathfindDuration = 8000,            -- How long animal paths to player (ms)
}

------------------------------------------------------------------------------------------------------------------------------------

---------------------------------
-- ANIMAL DEFINITION CONTROLS: --
---------------------------------
-- Control boolean properties for all AnimalDefinitions globally --

AE_MasterConfig.DefinitionControls = {
    udder = nil,                    -- Control udder property (nil = use default, true/false = override)
    female = nil,                   -- Control female property
    male = nil,                     -- Control male property
    alwaysFleeHumans = nil,         -- Control alwaysFleeHumans property
    fleeZombies = nil,              -- Control fleeZombies property
    canBeAttached = nil,            -- Control canBeAttached property
    canBeTransported = nil,         -- Control canBeTransported property
    eatFromMother = nil,            -- Control eatFromMother property
    periodicRun = nil,              -- Control periodicRun property
    eatGrass = nil,                 -- Control eatGrass property
    sitRandomly = nil,              -- Control sitRandomly property
    canBeMilked = nil,              -- Control canBeMilked property
    canBePicked = nil,              -- Control canBePicked property
    dontAttackOtherMale = nil,      -- Control dontAttackOtherMale property
    canBeFeedByHand = nil,          -- Control canBeFeedByHand property
    canBePet = nil,                 -- Control canBePet property
    attackBack = nil,               -- Control attackBack property
    collidable = nil,               -- Control collidable property
    canThump = nil,                 -- Control canThump property
    wild = false,                   -- Control wild property (false = make all animals non-wild)
    canBeAlerted = nil,             -- Control canBeAlerted property
    attackIfStressed = nil,         -- Control attackIfStressed property
    stressAboveGround = nil,        -- Control stressAboveGround property
    canClimbStairs = nil,           -- Control canClimbStairs property
    stressUnderRain = nil,          -- Control stressUnderRain property
    canClimbFences = nil,           -- Control canClimbFences property
    needMom = nil,                  -- Control needMom property
    canBeDomesticated = nil,        -- Control canBeDomesticated property
    knockdownAttack = nil,          -- Control knockdownAttack property
    canDoLaceration = nil,          -- Control canDoLaceration property
    litterEatTogether = nil,        -- Control litterEatTogether property
    addTrackingXp = nil,            -- Control addTrackingXp property
    canBeKilledWithoutWeapon = nil, -- Control canBeKilledWithoutWeapon property
}

-- REMOVED: SUMMONING ITEM CONFIG
-- SummoningSystem now operates independently without Config dependencies

---------------------------------
-- GLOBAL TAMING CONFIGURATION:
---------------------------------
-- These settings apply to ALL animal types --

AE_MasterConfig.Taming = {
    --- Enable/disable the taming system (in addition to Systems.TamingSystem) ---
    Enabled = true,

    --- Maximum number of animals a player can tame ---
    MaxTamedSlots = 3,

    --- Allow taming of already-tamed animals by others? ---
    ---- NOTE: will become relevant when multiplayer comes out ----
    AllowRetaming = false,
}

----------------------------------
-- GLOBAL NAMING CONFIGURATION:
----------------------------------
-- These settings apply to ALL animal types --

AE_MasterConfig.Naming = {
    --- Maximum name length ---
    MaxNameLength = 18,

    --- Allow special characters in names? ---
    AllowSpecialCharacters = false,

    --- Force naming upon taming? ---
    ForceNamingOnTame = true,
}

------------------------------------------------------------------------------------------------------------------------------------
----------------------------------
--  HELPER FUNCTIONS CONFIGS:   --
----------------------------------
-- Check if a system is enabled --

function AE_MasterConfig.IsSystemEnabled(systemName)
    return AE_MasterConfig.Systems[systemName] == true
end

-- Get a configuration value safely --
function AE_MasterConfig.GetConfig(category, key)
    if AE_MasterConfig[category] then
        return AE_MasterConfig[category][key]
    end
    return nil
end

-- Get per-animal configuration for a specific category and system --
function AE_MasterConfig.GetAnimalConfig(animalCategory, systemName)
    if not animalCategory or not systemName then return nil end
    local animalConfig = AE_MasterConfig.AnimalConfig[animalCategory]
    if not animalConfig then
        print("[AE_MasterConfig] WARNING: No configuration found for animal category: " .. animalCategory)
        return nil
    end

    return animalConfig[systemName]
end

-- Get taming configuration for a specific animal --
function AE_MasterConfig.GetTamingConfig(animalCategory)
    return AE_MasterConfig.GetAnimalConfig(animalCategory, "Taming")
end

-- Get friendliness configuration for a specific animal --
function AE_MasterConfig.GetFriendlinessConfig(animalCategory)
    return AE_MasterConfig.GetAnimalConfig(animalCategory, "Friendliness")
end

-- Get hunger system configuration for a specific animal --
function AE_MasterConfig.GetHungerConfig(animalCategory)
    return AE_MasterConfig.GetAnimalConfig(animalCategory, "HungerSystem")
end

-- Get care UI configuration for a specific animal --
function AE_MasterConfig.GetCareConfig(animalCategory)
    return AE_MasterConfig.GetAnimalConfig(animalCategory, "CareUI")
end

-- Get lives configuration for a specific animal --
function AE_MasterConfig.GetLivesConfig(animalCategory)
    return AE_MasterConfig.GetAnimalConfig(animalCategory, "Lives")
end

-- Get combat protection configuration for a specific animal --
function AE_MasterConfig.GetCombatProtectionConfig(animalCategory)
    return AE_MasterConfig.GetAnimalConfig(animalCategory, "CombatProtection")
end

-- Get commands configuration for a specific animal --
function AE_MasterConfig.GetCommandsConfig(animalCategory)
    return AE_MasterConfig.GetAnimalConfig(animalCategory, "Commands")
end

-- Get behavior configuration for a specific animal --
function AE_MasterConfig.GetBehaviorConfig(animalCategory)
    return AE_MasterConfig.GetAnimalConfig(animalCategory, "Behavior")
end

-- Get hostility configuration for a specific animal --
function AE_MasterConfig.GetHostilityConfig(animalCategory)
    local behaviorConfig = AE_MasterConfig.GetBehaviorConfig(animalCategory)
    return behaviorConfig and behaviorConfig.Hostility
end

-- Get equipment configuration for a specific animal type --
function AE_MasterConfig.GetEquipmentConfig(animalType)
    if not animalType then return nil end
    return AE_MasterConfig.Equipment[animalType]
end

-- Get equipment slots for a specific animal type --
function AE_MasterConfig.GetEquipmentSlots(animalType)
    local config = AE_MasterConfig.GetEquipmentConfig(animalType)
    if config then
        return config.Slots
    end
    return nil
end

-- Get body location mapping for a specific animal type --
function AE_MasterConfig.GetBodyLocations(animalType)
    local config = AE_MasterConfig.GetEquipmentConfig(animalType)
    if config then
        return config.BodyLocations
    end
    return nil
end

-- Get data module path for a specific animal type --
function AE_MasterConfig.GetEquipmentDataModulePath(animalType)
    local config = AE_MasterConfig.GetEquipmentConfig(animalType)
    if config then
        return config.DataModulePath
    end
    return nil
end

-- Get all registered animal categories --
function AE_MasterConfig.GetRegisteredCategories()
    local categories = {}
    for _, animalConfig in ipairs(AE_MasterConfig.RegisteredAnimals) do
        table.insert(categories, animalConfig.category)
    end
    return categories
end

-- Get animal configuration by category --
function AE_MasterConfig.GetAnimalConfigByCategory(category)
    if not category then return nil end
    for _, animalConfig in ipairs(AE_MasterConfig.RegisteredAnimals) do
        if animalConfig.category == category then
            return animalConfig
        end
    end
    return nil
end

-- Get CoreUtilities path for a specific animal category --
function AE_MasterConfig.GetCoreUtilitiesPath(category)
    local config = AE_MasterConfig.GetAnimalConfigByCategory(category)
    if config then
        return config.coreUtilitiesPath
    end
    return nil
end

-- Get IsoAnimal types for a specific animal category --
function AE_MasterConfig.GetIsoTypes(category)
    local config = AE_MasterConfig.GetAnimalConfigByCategory(category)
    if config then
        return config.isoTypes
    end
    return nil
end

-- Find category by IsoAnimal type --
function AE_MasterConfig.GetCategoryByIsoType(isoType)
    if not isoType then return nil end
    for _, animalConfig in ipairs(AE_MasterConfig.RegisteredAnimals) do
        for _, registeredIsoType in ipairs(animalConfig.isoTypes) do
            if registeredIsoType == isoType then
                return animalConfig.category
            end
        end
    end
    return nil
end

-- Get Retaliatory configuration for a specific animal category --
function AE_MasterConfig.GetRetaliatoryConfig(category)
    if not category then return nil end
    local animalCfg = AE_MasterConfig.AnimalConfig[category]
    if animalCfg and animalCfg.Behavior then
        return animalCfg.Behavior.Retaliatory
    end
    return nil
end

-- Get Hostility configuration for a specific animal category --
function AE_MasterConfig.GetHostilityConfig(category)
    if not category then return nil end
    local animalCfg = AE_MasterConfig.AnimalConfig[category]
    if animalCfg and animalCfg.Behavior then
        return animalCfg.Behavior.Hostility
    end
    return nil
end

-- Get Foraging configuration for a specific animal category --
function AE_MasterConfig.GetForagingConfig(category)
    if not category then return nil end
    local animalCfg = AE_MasterConfig.AnimalConfig[category]
    if animalCfg and animalCfg.Foraging then
        return animalCfg.Foraging
    end
    return nil
end

-- Get Custom Foraging configuration for a specific animal category --
function AE_MasterConfig.GetCustomForagingConfig(category)
    if not category then return nil end
    local animalCfg = AE_MasterConfig.AnimalConfig[category]
    if animalCfg and animalCfg.CustomForaging then
        return animalCfg.CustomForaging
    end
    return nil
end

-- Get Custom Foraging profession bonuses (global) --
function AE_MasterConfig.GetCustomForagingProfessionBonuses()
    return AE_MasterConfig.CustomForagingProfessions
end

-- Get profession-specific foraging bonuses --
function AE_MasterConfig.GetProfessionForagingBonuses(professionName)
    if not professionName then return nil end
    return AE_MasterConfig.CustomForagingProfessions[professionName]
end

-- Get generalized loot pool for a specific animal category --
function AE_MasterConfig.GetGeneralizedLootPool(category)
    local customConfig = AE_MasterConfig.GetCustomForagingConfig(category)
    if customConfig and customConfig.GeneralizedLoot then
        return customConfig.GeneralizedLoot
    end
    return {}
end

-- Validate configuration (called on load) --
function AE_MasterConfig.Validate()
    --- Ensure at least one animal type is registered ---
    if #AE_MasterConfig.RegisteredAnimals == 0 then
        print("[AE_MasterConfig] WARNING: No animals registered! Add animal configurations to RegisteredAnimals.")
        return false
    end

    --- Validate each registered animal configuration ---
    for _, animalConfig in ipairs(AE_MasterConfig.RegisteredAnimals) do
        if not animalConfig.category then
            print("[AE_MasterConfig] ERROR: Animal config missing 'category' field")
            return false
        end
        if not animalConfig.coreUtilitiesPath then
            print("[AE_MasterConfig] ERROR: Animal config for '" .. animalConfig.category .. "' missing 'coreUtilitiesPath'")
            return false
        end
        if not animalConfig.isoTypes or #animalConfig.isoTypes == 0 then
            print("[AE_MasterConfig] ERROR: Animal config for '" .. animalConfig.category .. "' missing 'isoTypes'")
            return false
        end

        -- Validate that AnimalConfig exists for this category
        if not AE_MasterConfig.AnimalConfig[animalConfig.category] then
            print("[AE_MasterConfig] WARNING: No AnimalConfig defined for registered category: " .. animalConfig.category)
        end
    end

    --- Ensure max tamed slots is valid ---
    if AE_MasterConfig.Taming.MaxTamedSlots < 1 or AE_MasterConfig.Taming.MaxTamedSlots > 10 then
        print("[AE_MasterConfig] WARNING: MaxTamedSlots must be between 1-10. Defaulting to 3.")
        AE_MasterConfig.Taming.MaxTamedSlots = 3
    end

    --- Validate equipment configuration for registered animals ---
    if AE_MasterConfig.IsSystemEnabled("EquipmentSystem") then
        for _, animalConfig in ipairs(AE_MasterConfig.RegisteredAnimals) do
            local category = animalConfig.category
            local equipConfig = AE_MasterConfig.GetEquipmentConfig(category)
            if not equipConfig then
                print("[AE_MasterConfig] yo, the equipment system config failed for these animals: " .. category)
            else
                if not equipConfig.Slots or #equipConfig.Slots == 0 then
                    print("[AE_MasterConfig] yo, there are no equip slots for these animals: " .. category)
                end
                if not equipConfig.BodyLocations then
                    print("[AE_MasterConfig] ayo, these animals has no body locations set up: " .. category)
                end
                if not equipConfig.DataModulePath then
                    print("[AE_MasterConfig] ayo, it failed to find the Data module for these animals: " .. category)
                end
            end
        end
    end
    return true
end

------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------
-- X -- INITIALIZATION STUFFS: -- X --
------------ DO NOT EDIT -------------
--------------------------------------
-- Validate configuration on load --

AE_MasterConfig.Validate()

print("[AE_MasterConfig] the master config loaded, yo")
local categories = AE_MasterConfig.GetRegisteredCategories()
print("[AE_MasterConfig] yo, here's all of the animals being read by ze system: " .. table.concat(categories, ", "))

return AE_MasterConfig