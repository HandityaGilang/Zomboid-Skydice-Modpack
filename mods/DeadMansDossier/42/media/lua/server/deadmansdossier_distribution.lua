--
-- Dead Man's Dossier — Loot Distribution
-- Injects dossier pages into relevant containers.
-- Police pages in police containers, military pages in military containers,
-- medical pages in hospital containers, firefighter pages in fire dept containers,
-- ranger pages in ranger containers.
--

require "deadmansdossier_shared"

print("[DeadMansDossier] Distribution module loaded")

-- Spawn rate multipliers indexed by ContainerSpawnRate sandbox enum value
local SPAWN_RATE_MULTIPLIERS = {
    [1] = 2.0,   -- Common
    [2] = 1.0,   -- Uncommon (default)
    [3] = 0.4,   -- Rare
    [4] = 0.15,  -- Very Rare
}

local function injectDossierPages()
    local procDist = ProceduralDistributions
    if not procDist or not procDist.list then
        print("[DeadMansDossier] WARNING: ProceduralDistributions.list not found, skipping loot injection")
        return
    end

    -- Read spawn rate setting
    local rateEnum = 2
    if SandboxVars and SandboxVars.DeadMansDossier and SandboxVars.DeadMansDossier.ContainerSpawnRate then
        rateEnum = SandboxVars.DeadMansDossier.ContainerSpawnRate
    end
    local multiplier = SPAWN_RATE_MULTIPLIERS[rateEnum] or 1.0

    print("[DeadMansDossier] Container spawn rate: " .. tostring(rateEnum) .. " (multiplier " .. tostring(multiplier) .. "x)")

    -- Distribution definitions per tier
    local distributions = {
        Police = {
            { name = "PoliceStorageGuns",    baseChance = 1.5 },
            { name = "PoliceLockers",        baseChance = 1.0 },
            { name = "PoliceStorageOutfit",  baseChance = 0.8 },
            { name = "PoliceDesk",           baseChance = 0.5 },
            { name = "PoliceEvidence",       baseChance = 0.8 },
            { name = "PoliceFileBox",        baseChance = 1.0 },
            { name = "PoliceFilingCabinet",  baseChance = 0.6 },
        },
        Military = {
            { name = "ArmyHangarTools",      baseChance = 1.0 },
            { name = "ArmySurplusTools",     baseChance = 1.0 },
            { name = "ArmyHangarOutfit",     baseChance = 0.8 },
            { name = "ArmySurplusOutfit",    baseChance = 0.5 },
            { name = "ArmyStorageGuns",      baseChance = 1.5 },
            { name = "ArmyStorageOutfit",    baseChance = 0.6 },
            { name = "ArmyBunkerStorage",    baseChance = 1.0 },
            { name = "ArmyBunkerLockers",    baseChance = 0.8 },
        },
        Medical = {
            { name = "MedicalStorageDrugs",  baseChance = 1.0 },
            { name = "MedicalStorageTools",  baseChance = 0.8 },
            { name = "MedicalClinicDrugs",   baseChance = 0.6 },
            { name = "HospitalLockers",      baseChance = 0.5 },
        },
        Firefighter = {
            { name = "FireDeptLockers",      baseChance = 1.2 },
            { name = "FireStorageOutfit",    baseChance = 0.8 },
        },
        Ranger = {
            { name = "RangerOutfit",         baseChance = 1.0 },
            { name = "RangerTools",          baseChance = 0.8 },
        },
    }

    local injected = 0

    for tierKey, distList in pairs(distributions) do
        local tier = DeadMansDossier.TIERS[tierKey]
        if tier then
            local pages = tier.pages
            for _, dist in ipairs(distList) do
                if procDist.list[dist.name] and procDist.list[dist.name].items then
                    local chance = dist.baseChance * multiplier
                    for _, pageItem in ipairs(pages) do
                        table.insert(procDist.list[dist.name].items, pageItem)
                        table.insert(procDist.list[dist.name].items, chance)
                    end
                    injected = injected + 1
                else
                    print("[DeadMansDossier] WARNING: Distribution '" .. dist.name .. "' not found, skipping")
                end
            end
        end
    end

    print("[DeadMansDossier] Loot distribution injected into " .. injected .. " location(s)")
end

Events.OnPreDistributionMerge.Add(injectDossierPages)
