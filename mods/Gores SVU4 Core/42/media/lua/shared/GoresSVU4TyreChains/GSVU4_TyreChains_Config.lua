-- =============================================================================
-- Gore's SVU4 Core - Tyre Chains Upgrade Config / Helpers
-- Project Zomboid B42.19 integrated Core upgrade
-- =============================================================================

GSVU4_TyreChains = GSVU4_TyreChains or {}
GSVU4_TyreChains.Config = GSVU4_TyreChains.Config or {}

local Config = GSVU4_TyreChains.Config

-- Core balance
Config.Enabled = true
Config.CheckIntervalHours = 0.0167          -- approximately one in-game minute
Config.IdleSpeedKmh = 5
Config.LowSpeedLimitKmh = 45
Config.AbuseSpeedLimitKmh = 70

-- Install / uninstall / repair balance
Config.RequiredMechanicsInstall = 5
Config.RequiredMechanicsRemove = 5
Config.RequiredMechanicsRepair = 2

Config.InstallTime = 240                    -- total time, split across four tyre points
Config.RemoveTime = 180                     -- total time, split across four tyre points
Config.LightRepairTime = 120
Config.HeavyRepairTime = 180
Config.ActionTyrePointCount = 4

-- Uses noisy welding-style action/sound for risk, but does not require Welding/Metalworking skill.
Config.WeldingStyleNoiseRadius = 16
Config.WeldingStyleNoiseVolume = 22
Config.WeldingStyleNoisePulseChance = 100

Config.InstallMaterials = {
    { fullType = "Base.HeavyChain", count = 4 },
    { fullType = "Base.Wire", count = 4 },
    { fullType = "Base.Screws", count = 16 },
    { fullType = "Base.DuctTape", count = 1 }
}

Config.InstallTools = {
    all = { "Base.LugWrench" },
    any = { "Base.Wrench", "Base.RatchetWrench" }
}

Config.CraftTools = {
    all = { "Base.Screwdriver", "Base.Pliers" },
    any = { "Base.Wrench", "Base.RatchetWrench" }
}

Config.RemoveTools = {
    all = { "Base.LugWrench" },
    any = { "Base.Wrench", "Base.RatchetWrench" }
}

Config.ReturnConditionThreshold = 50
Config.ReturnAboveThresholdFraction = 0.75
Config.ReturnAtOrBelowThresholdFraction = 0.25
Config.ReturnExclude = {
    ["Base.DuctTape"] = true
}

-- Repairs: no propane/welding rods. Uses the same noisy timed-action style for gameplay risk.
Config.LightRepairAmount = 25
Config.HeavyRepairAmount = 50
Config.LightRepairMaterials = {
    { fullType = "Base.Wire", count = 1 },
    { fullType = "Base.Screws", count = 4 }
}
Config.LightRepairTools = {
    all = { "Base.Pliers", "Base.Screwdriver" },
    any = {}
}
Config.HeavyRepairMaterials = {
    { fullType = "Base.HeavyChain", count = 1 },
    { fullType = "Base.Wire", count = 2 },
    { fullType = "Base.Screws", count = 8 }
}
Config.HeavyRepairTools = {
    all = { "Base.Pliers" },
    any = { "Base.Wrench", "Base.RatchetWrench" }
}

-- Weather detection
Config.SnowIntensityMin = 0.05
Config.SnowGroundFracMin = 0.15

-- Snow benefit. This is deliberately soft: it can restore tiny recent tyre-condition losses,
-- rather than directly editing live vehicle handling every tick.
Config.SnowTyreRestoreChance = 45           -- % chance per damaged tyre per throttled check
Config.SnowTyreRestoreAmount = 1
Config.SnowChainWearChance = 3

-- Dry/normal road penalties. These values are chances per throttled check, not per frame.
Config.LowSpeedTyreDamageChance = 5
Config.LowSpeedChainWearChance = 12
Config.LowSpeedNoiseChance = 20
Config.LowSpeedNoiseRadius = 8
Config.LowSpeedNoiseVolume = 8

Config.HighSpeedTyreDamageChance = 15
Config.HighSpeedChainWearChance = 30
Config.HighSpeedNoiseChance = 60
Config.HighSpeedNoiseRadius = 18
Config.HighSpeedNoiseVolume = 25

Config.AbuseTyreDamageChance = 30
Config.AbuseChainWearChance = 60
Config.AbuseBreakChance = 8
Config.AbuseNoiseChance = 90
Config.AbuseNoiseRadius = 28
Config.AbuseNoiseVolume = 40

-- Chain wear/damage
Config.ChainInstallCondition = 100
Config.ChainWearPerHit = 1
Config.BrokenChainExtraTyreDamage = 1

-- Deterministic dry-road wear safety net: random chance remains the main balance,
-- while preserving visible condition changes over short journeys.
Config.DryRoadGuaranteedTyreWearCheckCount = 3
Config.DryRoadGuaranteedChainWearCheckCount = 2
Config.VisualRefreshRetryFrames = 240

-- Standard vanilla car tyre IDs plus a couple of possible extended/rear axle names.
Config.TyrePartIds = {
    "TireFrontLeft",
    "TireFrontRight",
    "TireRearLeft",
    "TireRearRight",
    "TireRearLeft2",
    "TireRearRight2"
}

Config.TyreActionPoints = {
    { id = "TireFrontLeft", label = "front-left tyre" },
    { id = "TireFrontRight", label = "front-right tyre" },
    { id = "TireRearLeft", label = "rear-left tyre" },
    { id = "TireRearRight", label = "rear-right tyre" }
}

-- Visual bridge. These are likely model IDs. If the Vanilla Cars mod has matching
-- model slots, the Vanilla Cars visual bridge will toggle them. Missing names are ignored safely.
Config.VisualModelNames = {
    "GSVU4_TyreChains_FL",
    "GSVU4_TyreChains_FR",
    "GSVU4_TyreChains_RL",
    "GSVU4_TyreChains_RR",
    "GSVU4_TireChains_FL",
    "GSVU4_TireChains_FR",
    "GSVU4_TireChains_RL",
    "GSVU4_TireChains_RR",
    "SVU_TyreChains_FL",
    "SVU_TyreChains_FR",
    "SVU_TyreChains_RL",
    "SVU_TyreChains_RR",
    "SVU_TireChains_FL",
    "SVU_TireChains_FR",
    "SVU_TireChains_RL",
    "SVU_TireChains_RR",
    "GSVU4_SVU3_SportsCar_TireChains_Left",
    "GSVU4_SVU3_SportsCar_TireChains_Right",
    "SVU_Chains_FL_CarModern",
    "SVU_Chains_FR_CarModern",
    "SVU_Chains_RL_CarModern",
    "SVU_Chains_RR_CarModern",
    "SVU_Chains_FL_CarModern2",
    "SVU_Chains_FR_CarModern2",
    "SVU_Chains_RL_CarModern2",
    "SVU_Chains_RR_CarModern2",
    "SVU_Chains_FL_CarNormal",
    "SVU_Chains_FR_CarNormal",
    "SVU_Chains_RL_CarNormal",
    "SVU_Chains_RR_CarNormal",
    "SVU_Chains_FL_CarWagon",
    "SVU_Chains_FR_CarWagon",
    "SVU_Chains_RL_CarWagon",
    "SVU_Chains_RR_CarWagon",
    "SVU_Chains_FL_LuxuryCar",
    "SVU_Chains_FR_LuxuryCar",
    "SVU_Chains_RL_LuxuryCar",
    "SVU_Chains_RR_LuxuryCar",
    "SVU_Chains_FL_OffRoad",
    "SVU_Chains_FR_OffRoad",
    "SVU_Chains_RL_OffRoad",
    "SVU_Chains_RR_OffRoad",
    "SVU_Chains_FL_PickUp",
    "SVU_Chains_FR_PickUp",
    "SVU_Chains_RL_PickUp",
    "SVU_Chains_RR_PickUp",
    "SVU_Chains_FL_SUV",
    "SVU_Chains_FR_SUV",
    "SVU_Chains_RL_SUV",
    "SVU_Chains_RR_SUV",
    "SVU_Chains_FL_StepVan",
    "SVU_Chains_FR_StepVan",
    "SVU_Chains_RL_StepVan",
    "SVU_Chains_RR_StepVan",
    "SVU_Chains_FL_Van",
    "SVU_Chains_FR_Van",
    "SVU_Chains_RL_Van",
    "SVU_Chains_RR_Van",
    "SVU_Chains_FL_DashRoamer",
    "SVU_Chains_FR_DashRoamer",
    "SVU_Chains_RL_DashRoamer",
    "SVU_Chains_RR_DashRoamer",
    "SVU_Chains_FL_GMCVan",
    "SVU_Chains_FR_GMCVan",
    "SVU_Chains_RL_GMCVan",
    "SVU_Chains_RR_GMCVan",
}

local function safeCall(fn, ...)
    if not fn then return nil end
    local ok, result = pcall(fn, ...)
    if ok then return result end
    return nil
end

local function getInventory(character)
    if not character or not character.getInventory then return nil end
    return character:getInventory()
end

local function getPerkLevel(character, perk)
    if not character or not character.getPerkLevel or not perk then return 0 end
    local ok, result = pcall(function() return character:getPerkLevel(perk) end)
    if ok and result then return result end
    return 0
end


function GSVU4_TyreChains.markVisualDirty(vehicle)
    if GSVU4_TyreChains.requestVisualRefresh then
        pcall(function() GSVU4_TyreChains.requestVisualRefresh(vehicle, Config.VisualRefreshRetryFrames or 240) end)
    end

    -- Let external visual packs such as Gore's SVU4 PZK Cars reassert their
    -- own tyre-chain/extra-wheel visuals without depending on the Vanilla Cars
    -- visual bridge.  Safe on servers and ignored when no external pack exists.
    if GSVU4Core and GSVU4Core.ApplyExternalUpgradeVisualPacks then
        pcall(function() GSVU4Core.ApplyExternalUpgradeVisualPacks(vehicle, "TyreChains", "Standard") end)
    elseif GSVU4Core and GSVU4Core.ApplyExternalVisualPacks then
        pcall(function() GSVU4Core.ApplyExternalVisualPacks(vehicle, nil) end)
    end
end

function GSVU4_TyreChains.getVehicleKey(vehicle)
    if not vehicle then return "unknown" end
    if vehicle.getId then
        local id = safeCall(function() return vehicle:getId() end)
        if id ~= nil then return tostring(id) end
    end
    if vehicle.getUniqueId then
        local uid = safeCall(function() return vehicle:getUniqueId() end)
        if uid ~= nil then return tostring(uid) end
    end
    return tostring(math.floor(vehicle:getX() or 0)) .. "_" .. tostring(math.floor(vehicle:getY() or 0))
end

function GSVU4_TyreChains.getData(vehicle)
    if not vehicle or not vehicle.getModData then return nil end
    local md = vehicle:getModData()
    md.GSVU4_TyreChains = md.GSVU4_TyreChains or {}
    return md.GSVU4_TyreChains
end

function GSVU4_TyreChains.isInstalled(vehicle)
    local data = GSVU4_TyreChains.getData(vehicle)
    if data and data.installed == true and (tonumber(data.condition) or 0) > 0 then return true end

    -- Compatibility fallback: some SVU4 UI/upgrade flows mirror chain state into
    -- gUpgrades first.  Treat that as installed so visual packs can reassert
    -- chain models after MP sync / save reload.
    if vehicle and vehicle.getModData then
        local md = vehicle:getModData()
        local entry = md and md.gUpgrades and md.gUpgrades.TyreChains
        if type(entry) == "table" and entry.installed ~= false then
            local hp = tonumber(entry.condition or entry.health or entry.hp or 0) or 0
            if hp > 0 or entry.grade ~= nil then return true end
        end
    end

    return false
end

function GSVU4_TyreChains.install(vehicle, condition)
    local data = GSVU4_TyreChains.getData(vehicle)
    if not data then return false end
    data.installed = true
    data.condition = condition or Config.ChainInstallCondition
    data.state = "INSTALLED"
    data.lastCheckHours = nil
    data.lastTyreConditions = nil

    -- Mirror into the existing SVU4-style upgrade table for later UI integration.
    local md = vehicle:getModData()
    md.gUpgrades = md.gUpgrades or {}
    md.gUpgrades.TyreChains = {
        installed = true,
        grade = "Standard",
        condition = data.condition
    }

    if vehicle.transmitModData then vehicle:transmitModData() end
    GSVU4_TyreChains.markVisualDirty(vehicle)
    return true
end

function GSVU4_TyreChains.remove(vehicle)
    local data = GSVU4_TyreChains.getData(vehicle)
    if not data then return false end
    data.installed = false
    data.condition = 0
    data.state = "REMOVED"
    data.lastCheckHours = nil
    data.lastTyreConditions = nil

    local md = vehicle:getModData()
    if md.gUpgrades then
        md.gUpgrades.TyreChains = nil
    end

    if vehicle.transmitModData then vehicle:transmitModData() end
    GSVU4_TyreChains.markVisualDirty(vehicle)
    return true
end

function GSVU4_TyreChains.damageChains(vehicle, amount)
    local data = GSVU4_TyreChains.getData(vehicle)
    if not data or not data.installed then return false end

    local newCondition = math.max(0, (data.condition or Config.ChainInstallCondition) - (amount or Config.ChainWearPerHit))
    data.condition = newCondition

    local md = vehicle:getModData()
    if md.gUpgrades and md.gUpgrades.TyreChains then
        md.gUpgrades.TyreChains.condition = newCondition
    end

    if newCondition <= 0 then
        data.installed = false
        data.state = "BROKEN"
        if md.gUpgrades then md.gUpgrades.TyreChains = nil end
    end

    if vehicle.transmitModData then vehicle:transmitModData() end
    GSVU4_TyreChains.markVisualDirty(vehicle)
    return true
end

function GSVU4_TyreChains.repairChains(vehicle, amount)
    local data = GSVU4_TyreChains.getData(vehicle)
    if not data then return false end
    if data.installed ~= true then return false end

    data.condition = math.min(Config.ChainInstallCondition, (data.condition or 0) + (amount or 0))
    data.state = "REPAIRED"

    local md = vehicle:getModData()
    md.gUpgrades = md.gUpgrades or {}
    md.gUpgrades.TyreChains = {
        installed = true,
        grade = "Standard",
        condition = data.condition
    }

    if vehicle.transmitModData then vehicle:transmitModData() end
    GSVU4_TyreChains.markVisualDirty(vehicle)
    return true
end

function GSVU4_TyreChains.getWorldAgeHours()
    if getGameTime and getGameTime() and getGameTime().getWorldAgeHours then
        return getGameTime():getWorldAgeHours()
    end
    return 0
end

function GSVU4_TyreChains.isSnowCondition()
    local cm = nil
    if getClimateManager then cm = getClimateManager() end
    if not cm then return false end

    local fallingSnow = false
    local snowOnGround = false

    if cm.isSnowing and cm.getSnowIntensity then
        fallingSnow = cm:isSnowing() and (cm:getSnowIntensity() or 0) > Config.SnowIntensityMin
    end

    if cm.getSnowFracNow then
        snowOnGround = (cm:getSnowFracNow() or 0) > Config.SnowGroundFracMin
    end

    return fallingSnow or snowOnGround
end

function GSVU4_TyreChains.getSpeedKmh(vehicle)
    if not vehicle or not vehicle.getCurrentSpeedKmHour then return 0 end
    local speed = vehicle:getCurrentSpeedKmHour() or 0
    if speed < 0 then speed = -speed end
    return speed
end

function GSVU4_TyreChains.getTyreParts(vehicle)
    local parts = {}
    if not vehicle or not vehicle.getPartById then return parts end

    for _, id in ipairs(Config.TyrePartIds) do
        local part = vehicle:getPartById(id)
        if part then table.insert(parts, part) end
    end

    return parts
end

function GSVU4_TyreChains.syncPartCondition(vehicle, part)
    if not vehicle or not part then return end
    if vehicle.transmitPartCondition then
        vehicle:transmitPartCondition(part)
    elseif part.transmitCondition then
        part:transmitCondition()
    end
end

function GSVU4_TyreChains.damageRandomTyre(vehicle, amount)
    local tyres = GSVU4_TyreChains.getTyreParts(vehicle)
    if not tyres or #tyres <= 0 then return false end

    local part = tyres[ZombRand(#tyres) + 1]
    if not part or not part.getCondition then return false end

    local current = tonumber(part:getCondition()) or 0
    if current <= 0 then return false end

    local damageAmount = math.max(1, tonumber(amount) or 1)
    local newCondition = math.max(0, current - damageAmount)

    -- Prefer direct condition changes for this upgrade. VehiclePart:damage() is not consistent
    -- across B42 vehicle-part contexts and can make the dry-road penalty look like it did nothing.
    if part.setCondition then
        part:setCondition(newCondition)
    elseif part.damage then
        part:damage(damageAmount)
    else
        return false
    end

    GSVU4_TyreChains.syncPartCondition(vehicle, part)
    return true
end

function GSVU4_TyreChains.setTyreCondition(part, value)
    if not part or not part.setCondition then return false end
    part:setCondition(math.max(0, math.min(100, value or 0)))
    return true
end

function GSVU4_TyreChains.getPenaltyTier(vehicle)
    local speed = GSVU4_TyreChains.getSpeedKmh(vehicle)

    if speed < Config.IdleSpeedKmh then
        return "IDLE"
    elseif speed <= Config.LowSpeedLimitKmh then
        return "LOW"
    elseif speed <= Config.AbuseSpeedLimitKmh then
        return "HIGH"
    end

    return "ABUSE"
end

function GSVU4_TyreChains.shouldRunForVehicle(vehicle)
    if not Config.Enabled then return false end
    if not vehicle then return false end
    if not GSVU4_TyreChains.isInstalled(vehicle) then return false end

    local data = GSVU4_TyreChains.getData(vehicle)
    if not data then return false end

    local now = GSVU4_TyreChains.getWorldAgeHours()
    local last = data.lastCheckHours or -999
    if (now - last) < Config.CheckIntervalHours then return false end

    data.lastCheckHours = now
    return true
end

function GSVU4_TyreChains.hasMechanics(character, level)
    if not Perks or not Perks.Mechanics then return true end
    return getPerkLevel(character, Perks.Mechanics) >= (level or 0)
end

local function getShortType(fullType)
    if not fullType then return nil end
    return string.match(fullType, "%.([^%.]+)$") or fullType
end

function GSVU4_TyreChains.countItem(character, fullType)
    local inv = getInventory(character)
    if not inv or not fullType then return 0 end

    local shortType = getShortType(fullType)

    if inv.getCountTypeRecurse then
        local ok, result = pcall(function() return inv:getCountTypeRecurse(fullType) end)
        if ok and result and result > 0 then return result end
        ok, result = pcall(function() return inv:getCountTypeRecurse(shortType) end)
        if ok and result then return result end
    end

    if inv.getItemCount then
        local ok, result = pcall(function() return inv:getItemCount(fullType, true) end)
        if ok and result and result > 0 then return result end
        ok, result = pcall(function() return inv:getItemCount(shortType, true) end)
        if ok and result then return result end
    end

    if inv.getItemsFromFullType then
        local ok, items = pcall(function() return inv:getItemsFromFullType(fullType, true) end)
        if ok and items then return items:size() end
    end

    return 0
end

function GSVU4_TyreChains.hasItem(character, fullType)
    return GSVU4_TyreChains.countItem(character, fullType) > 0
end

function GSVU4_TyreChains.hasTools(character, toolSet)
    if not toolSet then return true end

    if toolSet.all then
        for _, fullType in ipairs(toolSet.all) do
            if not GSVU4_TyreChains.hasItem(character, fullType) then return false end
        end
    end

    if toolSet.any and #toolSet.any > 0 then
        local found = false
        for _, fullType in ipairs(toolSet.any) do
            if GSVU4_TyreChains.hasItem(character, fullType) then found = true end
        end
        if not found then return false end
    end

    return true
end

function GSVU4_TyreChains.hasMaterials(character, materials)
    if not materials then return true end
    for _, req in ipairs(materials) do
        if GSVU4_TyreChains.countItem(character, req.fullType) < (req.count or 1) then
            return false
        end
    end
    return true
end

local function removeOneItem(inv, fullType)
    if not inv or not fullType then return false end

    local shortType = getShortType(fullType)

    if inv.RemoveOneOf then
        local ok, result = pcall(function() return inv:RemoveOneOf(fullType) end)
        if ok and result ~= false then return true end
        ok, result = pcall(function() return inv:RemoveOneOf(shortType) end)
        if ok and result ~= false then return true end
    end

    local item = nil
    if inv.getFirstTypeRecurse then
        local ok, result = pcall(function() return inv:getFirstTypeRecurse(fullType) end)
        if ok then item = result end
        if not item then
            ok, result = pcall(function() return inv:getFirstTypeRecurse(shortType) end)
            if ok then item = result end
        end
    end

    if not item and inv.getItemsFromFullType then
        local ok, items = pcall(function() return inv:getItemsFromFullType(fullType, true) end)
        if ok and items and items:size() > 0 then item = items:get(0) end
    end

    if item and inv.Remove then
        inv:Remove(item)
        return true
    end

    return false
end

function GSVU4_TyreChains.consumeMaterials(character, materials)
    local inv = getInventory(character)
    if not inv or not materials then return false end
    if not GSVU4_TyreChains.hasMaterials(character, materials) then return false end

    for _, req in ipairs(materials) do
        for i = 1, (req.count or 1) do
            removeOneItem(inv, req.fullType)
        end
    end

    return true
end

function GSVU4_TyreChains.addItem(character, fullType, count)
    local inv = getInventory(character)
    if not inv or not fullType then return false end

    for i = 1, (count or 1) do
        if inv.AddItem then inv:AddItem(fullType) end
    end

    return true
end

function GSVU4_TyreChains.getUninstallReturnMaterials(vehicle)
    local data = GSVU4_TyreChains.getData(vehicle)
    local condition = data and (data.condition or 0) or 0
    local fraction = Config.ReturnAtOrBelowThresholdFraction

    if condition > Config.ReturnConditionThreshold then
        fraction = Config.ReturnAboveThresholdFraction
    end

    local returns = {}
    for _, req in ipairs(Config.InstallMaterials) do
        if not Config.ReturnExclude[req.fullType] then
            local count = math.floor(((req.count or 0) * fraction) + 0.0001)
            if count > 0 then table.insert(returns, { fullType = req.fullType, count = count }) end
        end
    end

    return returns, fraction
end

function GSVU4_TyreChains.giveReturnMaterials(character, vehicle)
    local returns = GSVU4_TyreChains.getUninstallReturnMaterials(vehicle)
    for _, item in ipairs(returns) do
        GSVU4_TyreChains.addItem(character, item.fullType, item.count)
    end
end

function GSVU4_TyreChains.addMechanicsXP(character, amount)
    if not character or not amount or amount <= 0 then return end
    if not Perks or not Perks.Mechanics then return end
    if character.getXp then
        local xp = character:getXp()
        if xp and xp.AddXP then xp:AddXP(Perks.Mechanics, amount) end
    end
end

function GSVU4_TyreChains.getRequirementText(action, vehicle)
    if action == "Install" then
        return "Mechanics 5; Lug Wrench; Wrench or Ratchet Wrench; 4 Heavy Chain, 4 Wire, 16 Screws, 1 Duct Tape"
    elseif action == "Remove" then
        local returns = GSVU4_TyreChains.getUninstallReturnMaterials(vehicle)
        local parts = {}
        for _, item in ipairs(returns) do table.insert(parts, tostring(item.count) .. "x " .. tostring(item.fullType)) end
        return "Mechanics 5; Lug Wrench; Wrench or Ratchet Wrench; returns " .. table.concat(parts, ", ")
    elseif action == "RepairLight" then
        return "Mechanics 2; Pliers; Screwdriver; 1 Wire, 4 Screws"
    elseif action == "RepairHeavy" then
        return "Mechanics 2; Pliers; Wrench or Ratchet Wrench; 1 Heavy Chain, 2 Wire, 8 Screws"
    end
    return ""
end
