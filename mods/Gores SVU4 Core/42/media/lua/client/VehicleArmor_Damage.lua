--========================================================
-- VEHICLE ARMOR DAMAGE  (B42.19)
-- Client only.  Polls part condition each player update
-- to detect hits and apply armour absorption.
-- Sets the GasTank leak flag when GasTank armour is destroyed. Fuel leaking itself is processed server-side.
--
-- Must be in /client (not /shared) because isLocalPlayer()
-- and OnPlayerUpdate are client-side only.
--
-- Changes from previous version:
--   • Damage absorption formula fixed — previously the
--     Protection multiplier was applied to armorDamage
--     (making high-protection armour nearly indestructible)
--     Now: passthrough = hit * Protection[grade]
--          armorDamage = (hit - passthrough) * ArmorDurability[grade]
--     Requires new VehicleArmorConfig.ArmorDurability table.
--   • gArmorGasLeak flag is now SET when GasTank armour
--     reaches 0 HP (previously it was only ever read,
--     so the gas leak mechanic never fired).
--   • Minor nil-guards added throughout.
--========================================================

require "VehicleArmor_Config"
pcall(require, "GoresSVU4Core/GSVU4_BullBarImpact")

VehicleArmorDamage            = {}
VehicleArmorDamage.ConditionCache = {}
VehicleArmorDamage.BullBarConditionCache = {}
VehicleArmorDamage.BullBarEventSequence = 0

local GAA_BullBarImpact = GSVU4 and GSVU4.BullBarImpact or nil

----------------------------------------------------------
-- Stable key for the condition cache
----------------------------------------------------------
local function getVehicleKey(vehicle)
    if not vehicle then return nil end
    local uid
    if vehicle.getUniqueId then
        uid = tostring(vehicle:getUniqueId())
    elseif vehicle.getId then
        uid = tostring(vehicle:getId())
    else
        uid = "0"
    end
    return "veh_"
        .. math.floor(vehicle:getX()) .. "_"
        .. math.floor(vehicle:getY()) .. "_"
        .. uid
end


----------------------------------------------------------
-- BULLBAR FRONT-CONDITION OBSERVER
--
-- Integrity wear is based on real condition loss at the front of the
-- vehicle, following the reliable condition-delta pattern used by other
-- vehicle armour systems. Unlike defensive armour, this observer never
-- restores the lost condition. The offensive collision scanner remains
-- responsible only for guaranteed zombie kills and bonus vehicle damage.
----------------------------------------------------------
local GAA_BullBarAllObservedParts = {
    "EngineDoor", "Hood", "HeadlightLeft", "HeadlightRight", "Engine",
}

local function GAA_GetBullBarCacheKey(vehicle)
    if GAA_BullBarImpact and GAA_BullBarImpact.getVehicleKey then
        return GAA_BullBarImpact.getVehicleKey(vehicle)
    end
    if vehicle and vehicle.getUniqueId then
        local ok, value = pcall(function() return vehicle:getUniqueId() end)
        if ok and value ~= nil then return "uid:" .. tostring(value) end
    end
    if vehicle and vehicle.getId then
        local ok, value = pcall(function() return vehicle:getId() end)
        if ok and value ~= nil then return "id:" .. tostring(value) end
    end
    return vehicle and tostring(vehicle) or nil
end

local function GAA_IsLocalDriver(player, vehicle)
    if not player or not vehicle then return false end
    if vehicle.getDriver then
        local ok, driver = pcall(function() return vehicle:getDriver() end)
        if ok then return driver == player end
    end
    return true
end

local function GAA_GetCondition(vehicle, partId)
    if not vehicle or not partId then return nil end
    local part = vehicle:getPartById(partId)
    if not part or not part.getCondition then return nil end
    return tonumber(part:getCondition()), part
end

-- The vehicle's front-end durability is the engine's own frontal-impact pool.
-- Zombie and scenery impacts can lower this even when no individual hood or
-- headlight condition delta survives long enough for Lua to observe. B42.19
-- exposes it as a public field; a guarded getter fallback is retained.
local function GAA_GetFrontEndDurability(vehicle)
    if not vehicle then return nil end

    local okField, fieldValue = pcall(function()
        return vehicle.currentFrontEndDurability
    end)
    if okField and tonumber(fieldValue) ~= nil then
        return tonumber(fieldValue)
    end

    if vehicle.getCurrentFrontEndDurability then
        local okGetter, getterValue = pcall(function()
            return vehicle:getCurrentFrontEndDurability()
        end)
        if okGetter and tonumber(getterValue) ~= nil then
            return tonumber(getterValue)
        end
    end

    return nil
end

local function GAA_GetConditionDrop(cache, vehicle, partId)
    local current, part = GAA_GetCondition(vehicle, partId)
    if current == nil then return 0, nil, nil end
    local previous = tonumber(cache[partId])
    if previous == nil then
        cache[partId] = current
        return 0, current, part
    end
    if current < previous then
        return previous - current, current, part
    end
    return 0, current, part
end

local function GAA_CalculateBullBarWear(cfg, damageTaken)
    local multiplier = math.max(0, tonumber(cfg and cfg.frontWearPerDamage) or 0.3)
    local minimum = math.max(1, math.floor(tonumber(cfg and cfg.frontWearMin) or 1))
    local maximum = math.max(minimum, math.floor(tonumber(cfg and cfg.frontWearMax) or 100))
    local wear = math.ceil(math.max(0, tonumber(damageTaken) or 0) * multiplier)
    return math.max(minimum, math.min(maximum, wear))
end

local function GAA_ApplyBullBarWearLocal(player, vehicle, upgrade, cfg, damageTaken, sourcePartId)
    local oldHealth = tonumber(upgrade and upgrade.health) or tonumber(cfg and cfg.health) or 100
    local wear = GAA_CalculateBullBarWear(cfg, damageTaken)
    if wear <= 0 then return end

    upgrade.health = math.max(0, oldHealth - wear)
    if vehicle and vehicle.transmitModData then vehicle:transmitModData() end


    if oldHealth > 0 and (tonumber(upgrade.health) or 0) <= 0
    and player and player.Say then
        player:Say("Bull bar destroyed!")
    end
end

local function GAA_SendBullBarFrontDamage(player, vehicle, damageTaken, sourcePartId, previousCondition, currentCondition)
    if not GAA_BullBarImpact then return end
    local upgrade, cfg = GAA_BullBarImpact.getFunctional(vehicle)
    if not upgrade or not cfg then return end

    damageTaken = math.max(0, math.min(100, tonumber(damageTaken) or 0))
    if damageTaken <= 0 then return end


    -- Single-player does not route client commands through a multiplayer
    -- server event. Apply locally there, matching the Core's existing local
    -- install/repair behaviour. Multiplayer remains server-authoritative.
    local multiplayerClient = isClient and isClient()
    if not multiplayerClient then
        GAA_ApplyBullBarWearLocal(
            player, vehicle, upgrade, cfg, damageTaken, sourcePartId
        )
        return
    end

    if not sendClientCommand then return end
    VehicleArmorDamage.BullBarEventSequence = (VehicleArmorDamage.BullBarEventSequence or 0) + 1
    local args = GAA_BullBarImpact.addVehicleArgs({}, vehicle, "vehicle")
    args.damageTaken = damageTaken
    args.sourcePartId = sourcePartId
    args.previousCondition = previousCondition
    args.currentCondition = currentCondition
    args.speedKph = GAA_BullBarImpact.getSpeedKph(vehicle)
    args.rawSpeedKph = GAA_BullBarImpact.getRawSpeedKph(vehicle)
    args.clientStamp = GAA_BullBarImpact.nowMs()
    args.sequence = VehicleArmorDamage.BullBarEventSequence
    sendClientCommand(GAA_BullBarImpact.Module, GAA_BullBarImpact.FrontDamageCommand, args)
end

local function GAA_DetectBullBarFrontDamage(player, vehicle, key)
    if not GAA_BullBarImpact or not GAA_IsLocalDriver(player, vehicle) then return end
    local upgrade = GAA_BullBarImpact.getFunctional(vehicle)
    if not upgrade then return end

    VehicleArmorDamage.BullBarConditionCache[key] =
        VehicleArmorDamage.BullBarConditionCache[key] or {}
    local cache = VehicleArmorDamage.BullBarConditionCache[key]

    local bestDamage, bestPartId, bestCurrent, bestPrevious = 0, nil, nil, nil

    -- Primary signal: the engine-level front-end durability pool. This is
    -- changed by frontal physics impacts even when individual vehicle-part
    -- condition changes are absent, delayed or immediately restored.
    local currentFront = GAA_GetFrontEndDurability(vehicle)
    if currentFront ~= nil then
        local previousFront = tonumber(cache.__FrontEndDurability)
        if previousFront == nil then
            cache.__FrontEndDurability = currentFront
        elseif currentFront < previousFront then
            bestDamage = previousFront - currentFront
            bestPartId = "FrontEndDurability"
            bestCurrent = currentFront
            bestPrevious = previousFront
        end
    end

    -- Part-condition fallbacks. Engine is observed even when a hood exists,
    -- because some vehicle scripts route zombie impacts directly to it. The
    -- largest single delta is used so one collision is not charged repeatedly.
    for _, partId in ipairs(GAA_BullBarAllObservedParts) do
        local previous = tonumber(cache[partId])
        local damage, current = GAA_GetConditionDrop(cache, vehicle, partId)
        if damage > bestDamage then
            bestDamage, bestPartId = damage, partId
            bestCurrent, bestPrevious = current, previous
        end
    end


    if bestDamage > 0 then
        GAA_SendBullBarFrontDamage(
            player, vehicle, bestDamage, bestPartId, bestPrevious, bestCurrent
        )
    end
end

local function GAA_UpdateBullBarConditionCache(vehicle, key)
    if not vehicle or not key then return end
    VehicleArmorDamage.BullBarConditionCache[key] =
        VehicleArmorDamage.BullBarConditionCache[key] or {}
    local cache = VehicleArmorDamage.BullBarConditionCache[key]
    local frontEnd = GAA_GetFrontEndDurability(vehicle)
    if frontEnd ~= nil then cache.__FrontEndDurability = frontEnd end
    for _, partId in ipairs(GAA_BullBarAllObservedParts) do
        local condition = GAA_GetCondition(vehicle, partId)
        if condition ~= nil then cache[partId] = condition end
    end
end

----------------------------------------------------------
-- GAS TANK LEAK
-- Fuel leaking is intentionally processed server-side in
-- VehicleArmor_Server.lua for multiplayer consistency.
-- This client file only sets vdata.gArmorGasLeak when the
-- GasTank armour reaches 0 HP.
----------------------------------------------------------
local function GAA_GetGasTankLeakClearCondition()
    if VehicleArmorConfig and VehicleArmorConfig.getGasTankLeakClearCondition then
        return VehicleArmorConfig.getGasTankLeakClearCondition()
    end

    return 90
end

local function GAA_GetGasTankPunctureDamage()
    if VehicleArmorConfig and VehicleArmorConfig.getGasTankPunctureDamage then
        return VehicleArmorConfig.getGasTankPunctureDamage()
    end

    return 20
end

local function GAA_ApplyGasTankPunctureDamage(vehicle, vdata, part)
    if not vehicle or not vdata or not part then return end

    -- Only apply the puncture damage once for this leak event.
    if vdata.gArmorGasLeakPunctureApplied then return end

    if not part.getCondition or not part.setCondition then return end

    local current = part:getCondition() or 100
    local damage = GAA_GetGasTankPunctureDamage()

    if damage <= 0 then
        vdata.gArmorGasLeakPunctureApplied = true
        return
    end

    local nextCondition = math.max(0, current - damage)
    part:setCondition(nextCondition)

    if vehicle.transmitPartCondition then
        vehicle:transmitPartCondition(part)
    end

    vdata.gArmorGasLeakPunctureApplied = true
end

local function GAA_ClearGasLeakIfTankRepaired(vehicle, vdata)
    if not vehicle or not vdata or not vdata.gArmorGasLeak then return end

    -- Do not clear a leak unless we know the vanilla GasTank was
    -- actually punctured. This prevents false-clears when entering
    if vdata.gArmorGasLeakPunctureApplied ~= true then return end

    local gasPart = vehicle:getPartById("GasTank")
    if not gasPart or not gasPart.getCondition then return end

    local condition = gasPart:getCondition() or 0
    local clearAt = GAA_GetGasTankLeakClearCondition()

    if condition >= clearAt then
        vdata.gArmorGasLeak = nil
        vdata.gArmorGasLeakPunctureApplied = nil
        vehicle:transmitModData()
    end
end


----------------------------------------------------------
-- MAIN DAMAGE CHECK  (runs every OnPlayerUpdate)
----------------------------------------------------------
function VehicleArmorDamage.Check(player)
    if not player or not player:isLocalPlayer() then return end

    local vehicle = player:getVehicle()
    if not vehicle then
        -- Clear stale cache when the player exits a vehicle
        VehicleArmorDamage.ConditionCache = {}
        VehicleArmorDamage.BullBarConditionCache = {}
        return
    end

    local key = getVehicleKey(vehicle)
    if not key then return end

    VehicleArmorDamage.ConditionCache[key] =
        VehicleArmorDamage.ConditionCache[key] or {}

    local vdata = vehicle:getModData()
    if not vdata then return end

    GAA_ClearGasLeakIfTankRepaired(vehicle, vdata)

    -- Capture the raw front-part condition drop before armour below restores
    -- any blocked damage. Use a stable vehicle identity rather than map-square
    -- coordinates so driving across tile boundaries cannot reset the observer.
    local bullbarKey = GAA_GetBullBarCacheKey(vehicle)
    if bullbarKey then GAA_DetectBullBarFrontDamage(player, vehicle, bullbarKey) end

    if not vdata.gArmor then
        if bullbarKey then GAA_UpdateBullBarConditionCache(vehicle, bullbarKey) end
        return
    end

    ----------------------------------------------------
    -- Loop all armoured parts
    ----------------------------------------------------
    for partId, armor in pairs(vdata.gArmor) do
        local part = vehicle:getPartById(partId)
        if part and part.getCondition then

            local currentCond = part:getCondition() or 100
            local prevCond    = VehicleArmorDamage.ConditionCache[key][partId]

            -- Already-broken armour should not spam destroyed feedback, but
            -- it must never abort the whole vehicle damage scan. Treat it as
            -- inactive for this part and let vanilla damage stand.
            local armorHP = type(armor) == "table" and (tonumber(armor.health) or 0) or 0
            local armorAlreadyBroken = armorHP <= 0
            if type(armor) == "table" and not armorAlreadyBroken then
                -- Repaired/reinstalled armour above 0 HP can notify once again
                -- if it breaks in the future.
                armor.gaaDestroyedNotified = nil
            end

            -- First time we see this part: seed the cache, nothing more
            if not prevCond then
                VehicleArmorDamage.ConditionCache[key][partId] = currentCond
                prevCond = currentCond
            end

            if currentCond < prevCond and not armorAlreadyBroken then
                ----------------------------------------
                -- Damage detected this tick and active armour is present
                ----------------------------------------
                local damageTaken = prevCond - currentCond

                local grade       = armor.grade or "Scrap"

                -- How much of the raw hit passes through to the vehicle part.
                -- Protection = 1.0 (Scrap)   → full damage passes through
                -- Protection = 0.2 (Apocalypse) → 20 % passes through
                local protMult   = VehicleArmorConfig.getProtectionMultiplier
                    and VehicleArmorConfig.getProtectionMultiplier(grade)
                    or (VehicleArmorConfig.Protection[grade] or 1.0)
                local passthrough = math.floor(damageTaken * protMult)

                -- How much damage the armour panel itself absorbs.
                -- ArmorDurability modifies how hard the panel is to destroy:
                -- > 1.0 = armour takes extra damage (Scrap degrades fast)
                -- < 1.0 = armour is tough to wear down (Apocalypse)
                local durMult    = VehicleArmorConfig.getArmorDurability and VehicleArmorConfig.getArmorDurability(grade) or (VehicleArmorConfig.ArmorDurability[grade] or 1.0)
                local absorbed   = math.max(0, damageTaken - passthrough)
                local armorDamage = math.floor(absorbed * durMult)
                if absorbed > 0 then armorDamage = math.max(1, armorDamage) end

                local newHP = (tonumber(armor.health) or 0) - armorDamage
                local bleed = passthrough   -- damage that reaches the vehicle part

                if newHP <= 0 then
                    -- Armour destroyed; any remaining absorbed hit also bleeds through
                    bleed  = bleed + math.max(0, -newHP)
                    newHP  = 0

                    -- Flag GasTank leak if that panel just broke and
                    -- puncture the vanilla Gas Tank once.
                    if partId == "GasTank" and not vdata.gArmorGasLeak then
                        vdata.gArmorGasLeak = true
                        vdata.gArmorGasLeakPunctureApplied = nil
                        GAA_ApplyGasTankPunctureDamage(vehicle, vdata, part)
                    elseif partId == "GasTank" then
                        vdata.gArmorGasLeak = true
                    end

                    -- Feedback: panel destroyed.
                    -- One-shot only; repeated collision checks can continue for
                    -- several seconds after a crash, especially in MP.
                    if not armor.gaaDestroyedNotified then
                        armor.gaaDestroyedNotified = true
                        local sq = vehicle:getSquare()
                        if sq then sq:playSound("BreakMetalItem") end
                        player:Say("Armor panel destroyed!")
                    end
                else
                    -- Feedback: panel took a hit but survived
                    local sq = vehicle:getSquare()
                    if sq then sq:playSound("MetalClang") end
                end

                armor.health = newHP

                -- Restore the part condition by the amount the armour blocked.
                -- bleed is what gets through; the rest was absorbed.
                local heal = damageTaken - bleed
                if heal > 0 then
                    local maxCond = (part.getConditionMax and part:getConditionMax()) or 100
                    part:setCondition(math.min(maxCond, currentCond + heal))
                end

                -- Update cache to the now-restored condition
                VehicleArmorDamage.ConditionCache[key][partId] = part:getCondition()

                -- Sync across network
                if vehicle.transmitPartCondition then
                    vehicle:transmitPartCondition(part)
                end
                vehicle:transmitModData()

            else
                -- No active armour processing this tick. This includes already
                -- broken armour panels; vanilla damage is left untouched.
                VehicleArmorDamage.ConditionCache[key][partId] = currentCond
            end
        end
    end

    -- Store the post-armour condition as the next baseline. The raw drop was
    -- already captured above, so restored hood condition cannot hide the hit.
    if bullbarKey then GAA_UpdateBullBarConditionCache(vehicle, bullbarKey) end
end

Events.OnPlayerUpdate.Add(VehicleArmorDamage.Check)
