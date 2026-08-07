-- PIPWaterSystem.lua (SERVER) - coeur : arrosage automatique des cultures.
-- Adapte de ClusterBarrelSystem.lua (qui marche en B42) + smart/classic pipes de l'original.
--
-- Tick EveryOneMinute : si l'intervalle est atteint, pour chaque pipe ayant des plantes dans son
-- radius, arroser depuis les barrels du MEME groupe (group ID), puis (option) equilibrer le pool.
--
-- API B42 (verifiees) : sq:hasFarmingPlant()/getFarmingPlant() ; SFarmingSystem.instance:newLuaObject(obj)
-- -> plant.waterLvl / plant:water(nil, uses) ; ZomboidGlobals.farmingFluidContainerMillilitresPerUse ;
-- barrel:getFluidContainer() -> getPrimaryFluidAmount()/adjustAmount()/Empty()/addFluid(FluidType.TaintedWater,n).

require "PIP/PIPShared"
require "PIP/PIPBarrelRegistry"
require "PIP/PIPNetwork"

PIP = PIP or {}
PIP.Water = PIP.Water or {}

local function isSrv() return not (isClient() and not isServer()) end

local lastWaterMinute = nil
local function shouldWaterNow(cfg)
    if not cfg.enableAutoWatering then return false end
    if not getGameTime then return false end
    local nowMin = math.floor(getGameTime():getWorldAgeHours() * 60)
    if lastWaterMinute == nil then lastWaterMinute = nowMin; return false end
    if (nowMin - lastWaterMinute) >= cfg.wateringInterval then lastWaterMinute = nowMin; return true end
    return false
end

-- Plantes (sq -> plante Java) dans le radius autour d'une case. radius 0 = case exacte.
local function collectPlants(x, y, z, radius)
    local plants, any = {}, false
    local function add(sq)
        if sq and sq:hasFarmingPlant() then
            local p = sq:getFarmingPlant()
            if p then plants[sq] = p; any = true end
        end
    end
    if radius == 0 then
        add(getSquare(x, y, z))
    else
        for xi = -radius, radius do
            for yi = -radius, radius do add(getSquare(x + xi, y + yi, z)) end
        end
    end
    return plants, any
end

-- Consomme `liters` d'eau des barrels (premier servi). Sync via setWater.
function PIP.Water.consume(barrels, liters)
    local rem = liters
    for _, barrel in ipairs(barrels) do
        if rem <= 0 then break end
        local amt = PIP.Barrels.getFluidAmount(barrel)
        if amt and amt > 0 then
            local c = math.min(rem, amt)
            PIP.Barrels.setWater(barrel, amt - c)
            rem = rem - c
        end
    end
end

-- Equilibre l'eau entre les barrels d'un groupe (pool partage). Sync via setWater.
-- Garde epsilon : ne re-ecrit (et donc ne re-transmet) un barrel que s'il s'ecarte de la moyenne
-- (sinon emptyFluid+addFluid+transmit a CHAQUE tick meme deja equilibre = spam reseau).
function PIP.Water.average(barrels)
    local total, valid = 0, {}
    for _, barrel in ipairs(barrels) do
        local amt = PIP.Barrels.getFluidAmount(barrel)
        if amt then total = total + amt; valid[#valid + 1] = { b = barrel, amt = amt } end
    end
    if total <= 0 or #valid == 0 then return end
    local ave = total / #valid
    local changed = 0
    for _, it in ipairs(valid) do
        if math.abs(it.amt - ave) > 0.05 then
            PIP.Barrels.setWater(it.b, ave)
            changed = changed + 1
        end
    end
    if changed > 0 then PIP.dbg(string.format("average gid: %d barrels -> %.1f L (total %.1f, %d ajustes)", #valid, ave, total, changed)) end
end

-- FERTIGATION (v1.2) : fertilise les plantes du radius depuis les CHARGES du groupe (engrais/compost
-- versés dans un barrel connecté). Priorite COMPOST (renouvelable, ne tue jamais : auto-garde
-- `not plant.compost`) > ENGRAIS (one-shot a vie : garde stricte `plant.fertilizer == 0`). 1 dose PIP
-- par plante par etape de pousse (tag `PIP_fertCycle` sur l'IsoObject) -> pas de double-dip cross-tick.
-- Utilise `getLuaObjectAt` (instance canonique a l'etat courant) comme la vanilla ISFertilizeAction :
-- un newLuaObject "frais" lirait fertilizer=0/compost=false et pourrait sur-fertiliser/tuer. Jamais
-- nuisible. Pas de benefice en hiver (saisons ON) -> on s'abstient pour ne pas gaspiller une dose.
function PIP.Water.fertigate(plants, cfg, gid)
    if not (cfg.enableFertigation and gid and SFarmingSystem and SFarmingSystem.instance) then return end
    local ch = PIP.Barrels.getGroupCharges(gid)
    if ch.c <= 0 and ch.f <= 0 then return end

    local noBenefit = false
    pcall(function()
        if getClimateManager and getClimateManager():getSeasonName() == "Winter" then
            local seasonsOn = true
            if getSandboxOptions then
                local opt = getSandboxOptions():getOptionByName("PlantGrowingSeasons")
                if opt then seasonsOn = opt:getValue() end
            end
            if seasonsOn then noBenefit = true end
        end
    end)
    if noBenefit then return end

    local skill = cfg.fertigationSkill or 5
    local consumed = false
    for sq in pairs(plants) do
        if ch.c <= 0 and ch.f <= 0 then break end
        local plant = SFarmingSystem.instance:getLuaObjectAt(sq:getX(), sq:getY(), sq:getZ())
        if plant and plant.isAlive and plant:isAlive() and plant.state ~= "plow" then
            local iso = plant.getIsoObject and plant:getIsoObject() or nil
            local imd = iso and iso:getModData() or nil
            local cycleKey = plant.nbOfGrow
            local alreadyThisCycle = imd and imd.PIP_fertCycle ~= nil and imd.PIP_fertCycle == cycleKey
            if not alreadyThisCycle then
                local kind = nil
                if ch.c > 0 and not plant.compost then
                    kind = "compost"
                elseif ch.f > 0 and ((plant.fertilizer or 0) == 0) then
                    kind = "fert"
                end
                if kind then
                    -- Applique D'ABORD (pcall), ne consomme/marque que si l'application a reussi -> pas de
                    -- charge gaspillee si fertilize() throw (pcall ne refund pas la charge). [audit]
                    local okF = pcall(function() plant:fertilize({ compost = (kind == "compost"), skill = skill }) end)
                    if okF and PIP.Barrels.consumeCharge(gid, kind) then
                        if kind == "compost" then ch.c = ch.c - 1 else ch.f = ch.f - 1 end
                        if imd then imd.PIP_fertCycle = cycleKey end
                        consumed = true
                        PIP.dbg(string.format("fertigated (%d,%d) via %s", sq:getX(), sq:getY(), kind))
                    end
                end
            end
        end
    end
    if consumed then PIP.Barrels.transmit() end
end

-- Arrose les plantes du radius d'une pipe depuis les barrels (du meme groupe).
function PIP.Water.waterFromPipe(px, py, pz, barrels, cfg, gid)
    if not barrels or #barrels == 0 then return end
    local plants, any = collectPlants(px, py, pz, cfg.wateringRadius)
    if not any then return end
    local total = 0
    for _, barrel in ipairs(barrels) do
        local amt = PIP.Barrels.getFluidAmount(barrel)
        if amt then total = total + amt end
    end
    if total <= 0 then return end
    local waterMl = total * 1000
    local perUse = (ZomboidGlobals and ZomboidGlobals.farmingFluidContainerMillilitresPerUse) or 100
    if perUse <= 0 then perUse = 100 end
    for sq, obj in pairs(plants) do
        if waterMl < perUse then break end
        local plant = SFarmingSystem and SFarmingSystem.instance and SFarmingSystem.instance:newLuaObject(obj) or nil
        if plant and type(plant.waterLvl) == "number" and plant.waterLvl < 90 then
            local totalUse = math.floor(waterMl / perUse)
            local needUse
            if cfg.smartPipes then
                needUse = math.floor((100 - plant.waterLvl) / 10)          -- viser ~100
                local capUse = math.floor((cfg.smartPipesFillMax or 20) / 10)
                if capUse > 0 and needUse > capUse then needUse = capUse end
            else
                needUse = 1                                                -- classic : +1 use / cycle
            end
            local use = math.min(totalUse, needUse)
            if use > 0 then
                pcall(function() plant:water(nil, use) end)
                waterMl = waterMl - use * perUse
                PIP.Water.consume(barrels, use * perUse / 1000)
                PIP.dbg(string.format("watered plant (%d,%d) use=%d wlvl=%.0f", sq:getX(), sq:getY(), use, plant.waterLvl))
            end
        end
    end

    -- Fertigation : memes plantes du radius, depuis les charges du groupe (jamais nuisible).
    PIP.Water.fertigate(plants, cfg, gid)
end

-- Tick principal.
function PIP.Water.tick()
    if not isSrv() then return end
    local cfg = PIP.getConfig()
    if not shouldWaterNow(cfg) then return end

    local marked = PIP.Barrels.getAllMarked()
    -- index : barrels (avec eau) par group id
    local byGid = {}
    for _, barrel in ipairs(marked) do
        local gid = PIP.Barrels.groupId(barrel)
        local amt = PIP.Barrels.getFluidAmount(barrel)
        if gid and amt and amt > 0 then
            byGid[gid] = byGid[gid] or {}
            table.insert(byGid[gid], barrel)
        end
    end
    -- arroser depuis chaque pipe (avec les barrels de son groupe)
    local n = 0
    for _, pipe in ipairs(PIP.Network.pipes) do
        if pipe.id and byGid[pipe.id] then
            PIP.Water.waterFromPipe(pipe.x, pipe.y, pipe.z, byGid[pipe.id], cfg, pipe.id)
            n = n + 1
        end
    end
    -- pool partage : equilibrer tous les barrels marques (meme vides) par groupe
    if cfg.sharedWaterPool then
        local groups = {}
        for _, barrel in ipairs(marked) do
            local gid = PIP.Barrels.groupId(barrel)
            if gid then groups[gid] = groups[gid] or {}; table.insert(groups[gid], barrel) end
        end
        for _, list in pairs(groups) do PIP.Water.average(list) end
    end
    PIP.dbg("water tick: " .. n .. " pipes with barrels processed")
end

if Events.EveryOneMinute then Events.EveryOneMinute.Add(PIP.Water.tick) end
