--
-- Dead Man's Dossier — Shared Constants
-- Used by both client and server to avoid typo mismatches.
--

DeadMansDossier = DeadMansDossier or {}

DeadMansDossier.MOD_ID = "DeadMansDossier"

-- Network command names
DeadMansDossier.CMD_ASSEMBLE        = "Assemble"
DeadMansDossier.CMD_CHECK_PROXIMITY = "CheckProximity"
DeadMansDossier.CMD_ASSEMBLE_RESULT = "AssembleResult"
DeadMansDossier.CMD_MISSION_UPDATE  = "MissionUpdate"
DeadMansDossier.CMD_REWARD_GRANTED  = "RewardGranted"
DeadMansDossier.CMD_NOT_CLOSE       = "NotCloseEnough"
DeadMansDossier.CMD_PROXIMITY_HINT  = "ProximityHint"
DeadMansDossier.CMD_REQUEST_MISSIONS = "RequestMissions"
DeadMansDossier.CMD_SYNC_MISSIONS   = "SyncMissions"
DeadMansDossier.CMD_CLEAR_TEST_DATA          = "ClearTestData"
DeadMansDossier.CMD_TEST_SIMULATE_DEATH      = "TestSimulateDeath"
DeadMansDossier.CMD_TEST_VERIFY_STASH        = "TestVerifyStash"
DeadMansDossier.CMD_PLAYER_DIED        = "PlayerDied"
DeadMansDossier.CMD_ABANDON_MISSION   = "AbandonMission"
DeadMansDossier.CMD_ABANDON_RESULT    = "AbandonResult"
DeadMansDossier.CMD_TEST_CHECK_DISTRIBUTIONS = "TestCheckDistributions"
DeadMansDossier.CMD_TEST_DISTRIBUTIONS_RESULT = "TestDistributionsResult"
DeadMansDossier.CMD_TEST_CUSTOM_REWARDS      = "TestCustomRewards"
DeadMansDossier.CMD_TEST_CUSTOM_REWARDS_RESULT = "TestCustomRewardsResult"

-- Tier definitions: each tier has page items and a completed dossier item
DeadMansDossier.TIERS = {
    Police = {
        label = "Police",
        pages = { "Base.PoliceDossierPage1", "Base.PoliceDossierPage2" },
        result = "Base.PoliceDossierComplete",
    },
    Military = {
        label = "Military",
        pages = { "Base.MilitaryDossierPage1", "Base.MilitaryDossierPage2", "Base.MilitaryDossierPage3" },
        result = "Base.MilitaryDossierComplete",
    },
    Medical = {
        label = "Medical",
        pages = { "Base.MedicalDossierPage1", "Base.MedicalDossierPage2" },
        result = "Base.MedicalDossierComplete",
    },
    Firefighter = {
        label = "Firefighter",
        pages = { "Base.FirefighterDossierPage1", "Base.FirefighterDossierPage2" },
        result = "Base.FirefighterDossierComplete",
    },
    Ranger = {
        label = "Ranger",
        pages = { "Base.RangerDossierPage1", "Base.RangerDossierPage2" },
        result = "Base.RangerDossierComplete",
    },
}

-- Reverse lookup: page item full type -> tier key
DeadMansDossier.PAGE_TO_TIER = {}
for tierKey, tier in pairs(DeadMansDossier.TIERS) do
    for _, pageType in ipairs(tier.pages) do
        DeadMansDossier.PAGE_TO_TIER[pageType] = tierKey
    end
end

-- Zombie outfit name -> tier key
--
-- Names MUST match an <m_Name> in the game's media/clothing/clothing.xml
-- (265 outfits in 42.20). A name that doesn't match simply never fires, so a
-- typo or a stale B41 name silently removes a whole zombie type from the drop
-- pool with no error. PoliceDesert / PoliceFemale / ArmyGreen / ArmyDesert were
-- all dead this way until 2026-08-01 — verify against clothing.xml when editing.
DeadMansDossier.OUTFIT_MAP = {
    -- Police outfits
    Police              = "Police",
    PoliceState         = "Police",
    PoliceRiot          = "Police",
    Police_SWAT         = "Police",
    Sheriff_Deputy      = "Police",
    PrisonGuard         = "Police",
    -- Military outfits
    ArmyCamoDesert      = "Military",
    ArmyCamoGreen       = "Military",
    ArmyInstructor      = "Military",
    ArmyServiceUniform  = "Military",
    Veteran             = "Military",
    -- Medical outfits
    Doctor              = "Medical",
    Nurse               = "Medical",
    -- Firefighter outfits
    Fireman             = "Firefighter",
    FiremanFullSuit     = "Firefighter",
    -- Ranger outfits
    Ranger              = "Ranger",
}

-- Preset stash locations in Knox County (x, y, z, label)
-- Coordinates sourced from community maps — some may need adjustment for B42.
-- If a stash spawns in an invalid location, remove or fix the entry.
DeadMansDossier.STASH_LOCATIONS = {
    -- Muldraugh (10)
    { x = 10570, y = 9590,  z = 0, label = "Muldraugh Hardware Store" },
    { x = 10666, y = 9886,  z = 0, label = "Muldraugh Gas Station South" },
    { x = 10684, y = 9829,  z = 0, label = "Muldraugh Storage Lots" },
    { x = 10611, y = 9308,  z = 0, label = "Muldraugh Warehouse" },
    { x = 10605, y = 9406,  z = 0, label = "Muldraugh Auto Shop" },
    { x = 10631, y = 10405, z = 0, label = "Muldraugh Police Station" },
    { x = 10876, y = 10028, z = 0, label = "Cortman Medical" },
    { x = 10317, y = 9290,  z = 0, label = "McCoy Logging Corp" },
    { x = 10619, y = 9967,  z = 0, label = "Muldraugh Elementary School" },
    { x = 10482, y = 10078, z = 0, label = "Muldraugh Ranch" },

    -- West Point (10)
    { x = 12095, y = 6905,  z = 0, label = "West Point Warehouse" },
    { x = 12170, y = 6960,  z = 0, label = "West Point Storage Lot" },
    { x = 12040, y = 6810,  z = 0, label = "West Point Pharmacy" },
    { x = 11898, y = 6940,  z = 0, label = "West Point Police Station" },
    { x = 12064, y = 6758,  z = 0, label = "West Point Gun Shop" },
    { x = 11819, y = 6865,  z = 0, label = "West Point Gas Station" },
    { x = 11898, y = 6807,  z = 0, label = "West Point Auto Shop" },
    { x = 12137, y = 7024,  z = 0, label = "West Point Storage Units" },
    { x = 11978, y = 6911,  z = 0, label = "West Point Food Market" },
    { x = 11345, y = 6784,  z = 0, label = "West Point School" },

    -- Riverside (8)
    { x = 6450,  y = 5480,  z = 0, label = "Riverside Church Basement" },
    { x = 6560,  y = 5510,  z = 0, label = "Riverside School Storage" },
    { x = 6700,  y = 5400,  z = 0, label = "Riverside Factory" },
    { x = 6082,  y = 5261,  z = 0, label = "Riverside Police Station" },
    { x = 6084,  y = 5309,  z = 0, label = "Riverside Gas Station" },
    { x = 6363,  y = 5327,  z = 0, label = "Riverside Hardware Store" },
    { x = 6505,  y = 5346,  z = 0, label = "Riverside Gigamart" },
    { x = 6470,  y = 5266,  z = 0, label = "Riverside Pharmacy" },

    -- Rosewood (10)
    { x = 8200,  y = 11500, z = 0, label = "Rosewood Fire Station" },
    { x = 8050,  y = 11350, z = 0, label = "Rosewood Community Center" },
    { x = 8164,  y = 11267, z = 0, label = "Rosewood Gas Station North" },
    { x = 8063,  y = 11735, z = 0, label = "Rosewood Police Station" },
    { x = 8075,  y = 11456, z = 0, label = "Rosewood Diner" },
    { x = 8087,  y = 11512, z = 0, label = "Rosewood Bookstore" },
    { x = 7752,  y = 11886, z = 0, label = "Rosewood Penitentiary" },
    { x = 9118,  y = 11814, z = 0, label = "Rosewood Army Quarters" },
    { x = 9202,  y = 11840, z = 0, label = "Rosewood East Warehouse" },
    { x = 8297,  y = 12225, z = 0, label = "Rosewood Gas Station South" },

    -- March Ridge (6)
    { x = 10320, y = 12440, z = 0, label = "March Ridge Gas Station" },
    { x = 10400, y = 12540, z = 0, label = "March Ridge Self-Storage" },
    { x = 10420, y = 12380, z = 0, label = "March Ridge Church" },
    { x = 10360, y = 12490, z = 0, label = "March Ridge Pharmacy" },
    { x = 10440, y = 12550, z = 0, label = "March Ridge Grill" },
    { x = 10470, y = 12470, z = 0, label = "March Ridge Mini Mall" },

    -- Louisville (32)
    { x = 12444, y = 1609,  z = 0, label = "Louisville Police Department" },
    { x = 12458, y = 3702,  z = 0, label = "St. Peregrin Hospital" },
    { x = 12574, y = 2567,  z = 0, label = "Louisville Gigamart" },
    { x = 13218, y = 3086,  z = 0, label = "Louisville Southern Police" },
    { x = 12515, y = 4267,  z = 0, label = "Louisville Military Checkpoint" },
    { x = 13685, y = 1780,  z = 0, label = "Louisville Fire Station" },
    { x = 13956, y = 3269,  z = 0, label = "Louisville Gas Station East" },
    { x = 12040, y = 2590,  z = 0, label = "Louisville Residential Garage" },
    { x = 12840, y = 1690,  z = 0, label = "Louisville General Hospital" },
    { x = 12224, y = 2757,  z = 0, label = "Chapelmount Downs Racetrack" },
    { x = 12406, y = 2255,  z = 0, label = "University of Louisville" },
    { x = 12608, y = 3384,  z = 0, label = "Holy Haven Cemetery" },
    { x = 13026, y = 1581,  z = 0, label = "Fossoil Baseball Field" },
    { x = 12338, y = 3254,  z = 0, label = "Louisville Elementary School" },
    { x = 12967, y = 3183,  z = 0, label = "Louisville School East" },
    { x = 12096, y = 2105,  z = 0, label = "Louisville Gas Station North" },
    { x = 13945, y = 3050,  z = 0, label = "Louisville Small Fire Station" },
    { x = 13100, y = 5315,  z = 0, label = "Louisville Outskirts Hunting Cabin" },
    { x = 12740, y = 5030,  z = 0, label = "Louisville Outskirts Gas Station" },
    { x = 14533, y = 4022,  z = 0, label = "Louisville South Military Checkpoint" },
    { x = 13795, y = 1236,  z = 0, label = "Grand Ohio Mall" },
    { x = 12302, y = 2527,  z = 0, label = "Louisville Shopping District" },
    { x = 12670, y = 1900,  z = 0, label = "Louisville Downtown Warehouse" },
    { x = 13400, y = 2200,  z = 0, label = "Louisville Auto Dealership" },
    { x = 12200, y = 1400,  z = 0, label = "Louisville North Pharmacy" },
    { x = 13550, y = 2800,  z = 0, label = "Louisville Industrial Park" },
    { x = 12800, y = 3900,  z = 0, label = "Louisville South Warehouse" },
    { x = 13300, y = 1300,  z = 0, label = "Louisville Convention Center" },
    { x = 12100, y = 3200,  z = 0, label = "Louisville West Side Clinic" },
    { x = 12050, y = 1800,  z = 0, label = "Louisville River District" },
    { x = 14200, y = 3600,  z = 0, label = "Louisville Highway Patrol" },
    { x = 13000, y = 3800,  z = 0, label = "Louisville South Parking Garage" },

    -- Dixie (5)
    { x = 11512, y = 8832,  z = 0, label = "Dixie Gas Station" },
    { x = 11655, y = 9985,  z = 0, label = "Dixie Railyard Office" },
    { x = 11560, y = 9150,  z = 0, label = "Dixie Trailer Park" },
    { x = 11490, y = 9050,  z = 0, label = "Dixie Warehouse South" },
    { x = 11620, y = 8900,  z = 0, label = "Dixie Auto Salvage" },

    -- Scenic Grove / West of Riverside (3)
    { x = 5570,  y = 5899,  z = 0, label = "Scenic Grove Factory" },
    { x = 5615,  y = 5972,  z = 0, label = "Scenic Grove Warehouse" },
    { x = 5418,  y = 5870,  z = 0, label = "Scenic Grove Gas Station" },

    -- Ekron (3)
    { x = 13780, y = 5800,  z = 0, label = "Ekron Farm Cellar" },
    { x = 13600, y = 6200,  z = 0, label = "Ekron General Store" },
    { x = 13700, y = 6050,  z = 0, label = "Ekron Church" },

    -- Rural / Highway / Isolated (13)
    { x = 8440,  y = 8720,  z = 0, label = "Rural Cabin off Highway" },
    { x = 12470, y = 8920,  z = 0, label = "Lakeside Campsite Cabin" },
    { x = 9200,  y = 8500,  z = 0, label = "Highway 43 Rest Stop" },
    { x = 9800,  y = 10500, z = 0, label = "Crossroads Trailer Park" },
    { x = 7600,  y = 9800,  z = 0, label = "Abandoned Church" },
    { x = 7200,  y = 7500,  z = 0, label = "Rural Farm North" },
    { x = 6800,  y = 6100,  z = 0, label = "Riverside Country Club" },
    { x = 8800,  y = 7200,  z = 0, label = "Isolated Lodge" },
    { x = 10900, y = 8200,  z = 0, label = "Highway Motel" },
    { x = 6200,  y = 4800,  z = 0, label = "Riverside North Cabin" },
    { x = 9500,  y = 12800, z = 0, label = "Southern Farmstead" },
    { x = 9200,  y = 6500,  z = 0, label = "Valley Bridge Gas Station" },
    { x = 10200, y = 7200,  z = 0, label = "Highway Diner" },
}

-- Reward tables per tier: { item, chance (0-1) }
DeadMansDossier.REWARDS = {
    Police = {
        -- Weapons
        { item = "Base.Pistol",              chance = 0.40 },
        { item = "Base.Pistol2",             chance = 0.40 },
        { item = "Base.Pistol3",             chance = 0.40 },
        { item = "Base.Shotgun",             chance = 0.25 },
        { item = "Base.DoubleBarrelShotgun", chance = 0.30 },
        { item = "Base.ShotgunSawnoff",      chance = 0.30 },
        -- Ammo
        { item = "Base.Bullets9mmBox",       chance = 0.50 },
        { item = "Base.ShotgunShellsBox",    chance = 0.50 },
        -- Clothing
        { item = "Base.Hat_Police",          chance = 0.60 },
        { item = "Base.Jacket_Police",       chance = 0.60 },
        { item = "Base.Shirt_PoliceBlue",    chance = 0.60 },
        { item = "Base.Shirt_OfficerWhite",  chance = 0.60 },
        { item = "Base.Trousers_Police",     chance = 0.60 },
        { item = "Base.Trousers_PoliceGrey", chance = 0.60 },
        -- Armor
        { item = "Base.Vest_BulletPolice",   chance = 0.10 },
        -- Accessories
        { item = "Base.HolsterSimple",       chance = 0.70 },
        { item = "Base.WalkieTalkie4",       chance = 0.70 },
        { item = "Base.FlashLight_AngleHead", chance = 0.70 },
    },
    Military = {
        -- Weapons
        { item = "Base.AssaultRifle",            chance = 0.05 },
        { item = "Base.AssaultRifle2",           chance = 0.05 },
        { item = "Base.Pistol",                  chance = 0.50 },
        { item = "Base.Pistol2",                 chance = 0.50 },
        { item = "Base.Pistol3",                 chance = 0.50 },
        -- Magazines. M1AClip does not exist in B42; the rest are real.
        { item = "Base.556Clip",                 chance = 0.05 },
        { item = "Base.M14Clip",                 chance = 0.05 },
        { item = "Base.JS14_Clip",               chance = 0.05 },
        { item = "Base.9mmClip",                 chance = 0.50 },
        { item = "Base.45Clip",                  chance = 0.50 },
        { item = "Base.44Clip",                  chance = 0.50 },
        -- Ammo Boxes. 223Box does not exist in B42; 308Box does.
        { item = "Base.308Box",                  chance = 0.30 },
        { item = "Base.Bullets9mmBox",           chance = 0.40 },
        { item = "Base.Bullets45Box",            chance = 0.40 },
        { item = "Base.Bullets44Box",            chance = 0.40 },
        -- Weapon Accessories
        { item = "Base.TritiumSights",           chance = 0.20 },
        { item = "Base.x2Scope",                 chance = 0.20 },
        { item = "Base.x4Scope",                 chance = 0.20 },
        { item = "Base.x8Scope",                 chance = 0.20 },
        { item = "Base.RedDot",                  chance = 0.20 },
        { item = "Base.Laser",                   chance = 0.20 },
        -- Clothing
        { item = "Base.Hat_Army",                chance = 0.60 },
        { item = "Base.Hat_ArmyDesert",          chance = 0.60 },
        { item = "Base.Jacket_ArmyCamoDesert",   chance = 0.60 },
        { item = "Base.Jacket_ArmyCamoGreen",    chance = 0.60 },
        { item = "Base.Jacket_ArmyCamoUrban",    chance = 0.60 },
        { item = "Base.Trousers_CamoDesert",     chance = 0.60 },
        { item = "Base.Trousers_CamoGreen",      chance = 0.60 },
        { item = "Base.Trousers_CamoUrban",      chance = 0.60 },
        -- Armor
        { item = "Base.Vest_BulletArmy",         chance = 0.10 },
        -- Gear
        { item = "Base.Bag_Military",            chance = 0.20 },
        { item = "Base.Bag_ALICE_BeltSus_Camo",  chance = 0.20 },
        { item = "Base.WalkieTalkie4",           chance = 0.50 },
        { item = "Base.CompassDirectional",      chance = 0.50 },
        { item = "Base.HuntingKnife",            chance = 0.50 },
        -- Water & Light
        { item = "Base.Canteen",                 chance = 0.20 },
        { item = "Base.FlashLight_AngleHead_Army", chance = 0.20 },
        -- Cross-mod (silently skipped if mod not installed)
        { item = "Base.XVirus",                  chance = 0.02 },
    },
    Medical = {
        -- Medical Supplies
        { item = "Base.Antibiotics",         chance = 0.30 },
        { item = "Base.Bandage",             chance = 0.50 },
        { item = "Base.AlcoholBandage",      chance = 0.35 },
        { item = "Base.SutureNeedle",        chance = 0.40 },
        { item = "Base.SutureNeedleHolder",  chance = 0.40 },
        { item = "Base.Tweezers",            chance = 0.50 },
        { item = "Base.Forceps_Forged",      chance = 0.50 },
        { item = "Base.Splint",              chance = 0.50 },
        { item = "Base.CottonBalls",         chance = 0.50 },
        { item = "Base.AlcoholWipes",        chance = 0.50 },
        { item = "Base.Disinfectant",        chance = 0.50 },
        -- Medication — B42 renamed these (Painkillers/BetaBlockers/Antidepressants
        -- were B41 IDs and silently produced nothing).
        { item = "Base.Pills",               chance = 0.50 },
        { item = "Base.PillsBeta",           chance = 0.50 },
        { item = "Base.PillsAntiDep",        chance = 0.50 },
        -- Clothing
        { item = "Base.Shirt_Scrubs",        chance = 0.60 },
        { item = "Base.Tshirt_Scrubs",       chance = 0.60 },
        { item = "Base.Trousers_Scrubs",     chance = 0.60 },
        { item = "Base.Hat_SurgicalCap",     chance = 0.60 },
        { item = "Base.JacketLong_Doctor",   chance = 0.60 },
        { item = "Base.Gloves_Surgical",     chance = 0.60 },
        -- Cross-mod (silently skipped if mod not installed)
        { item = "Base.KnoxAntidote",       chance = 0.02 },
    },
    Firefighter = {
        -- Gear
        { item = "Base.Hat_Fireman",      chance = 0.30 },
        { item = "Base.Jacket_Fireman",   chance = 0.30 },
        { item = "Base.Trousers_Fireman", chance = 0.30 },
        { item = "Base.SCBA",            chance = 0.30 },
        -- Tools & Weapons
        { item = "Base.HandAxe",          chance = 0.50 },
        { item = "Base.Crowbar",          chance = 0.50 },
        { item = "Base.Extinguisher",     chance = 0.60 },
        { item = "Base.Axe",             chance = 0.20 },
        { item = "Base.Sledgehammer",    chance = 0.05 },
        -- Utility
        { item = "Base.WalkieTalkie4",   chance = 0.60 },
        { item = "Base.Rope",            chance = 0.60 },
        { item = "Base.WeldingMask",     chance = 0.60 },
        { item = "Base.BlowTorch",       chance = 0.60 },
        { item = "Base.BoltCutters",     chance = 0.60 },
        { item = "Base.DuctTape",        chance = 0.60 },
    },
    Ranger = {
        -- Weapons
        { item = "Base.HuntingRifle",        chance = 0.20 },
        { item = "Base.Shotgun",             chance = 0.20 },
        { item = "Base.DoubleBarrelShotgun", chance = 0.20 },
        { item = "Base.HuntingKnife",        chance = 0.35 },
        { item = "Base.HandAxe",             chance = 0.25 },
        -- Ammo. 308Clip does not exist in B42; 308Box does.
        { item = "Base.308Box",              chance = 0.20 },
        { item = "Base.ShotgunShellsBox",    chance = 0.20 },
        -- Weapon Accessories
        { item = "Base.x2Scope",             chance = 0.20 },
        { item = "Base.x4Scope",             chance = 0.20 },
        { item = "Base.x8Scope",             chance = 0.20 },
        -- Clothing
        { item = "Base.Hat_Ranger",          chance = 0.60 },
        { item = "Base.Jacket_Ranger",       chance = 0.60 },
        { item = "Base.Shirt_Ranger",        chance = 0.60 },
        { item = "Base.Tshirt_Ranger",       chance = 0.60 },
        { item = "Base.Trousers_Ranger",     chance = 0.60 },
        { item = "Base.Glasses_Aviators",    chance = 0.60 },
        -- Gear
        { item = "Base.CompassDirectional",  chance = 0.60 },
        { item = "Base.Rope",                chance = 0.65 },
        { item = "Base.TrapBox",             chance = 0.45 },
        { item = "Base.WalkieTalkie4",       chance = 0.60 },
        { item = "Base.FlashLight_AngleHead", chance = 0.60 },
        { item = "Base.Bag_LeatherWaterBag",  chance = 0.20 },
        { item = "Base.CanteenCowboy",       chance = 0.20 },
    },
}

-- Default proximity radius in tiles
DeadMansDossier.PROXIMITY_RADIUS = 15

-- Startup log with table counts
do
    local pageCount = 0
    for _ in pairs(DeadMansDossier.PAGE_TO_TIER) do pageCount = pageCount + 1 end
    local outfitCount = 0
    for _ in pairs(DeadMansDossier.OUTFIT_MAP) do outfitCount = outfitCount + 1 end
    local tierCount = 0
    for _ in pairs(DeadMansDossier.TIERS) do tierCount = tierCount + 1 end
    print("[DeadMansDossier] Shared module loaded — " .. tierCount .. " tiers, " .. pageCount .. " page mappings, " .. outfitCount .. " outfit mappings")
end
