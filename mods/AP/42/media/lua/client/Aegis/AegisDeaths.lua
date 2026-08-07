-- Death dossier, client half: OnPlayerDeath fires only for the local
-- player, so the dying client collects everything it can still read and
-- ships it to the server. Every Java read is guarded on its own, a nil
-- object or missing method must not cost the rest of the report.
require "Aegis/AegisTheme"

AegisDeaths = AegisDeaths or {}

local function grab(fn)
    local ok, res = pcall(fn)
    if ok then return res end
    return nil
end

local function round2(v)
    v = tonumber(v)
    if not v then return nil end
    return math.floor(v * 100 + 0.5) / 100
end

local function stat(player, name)
    return round2(grab(function() return player:getStats():get(CharacterStat[name]) end))
end

local SPEED_NAMES = { [1] = "sprinter", [2] = "fast shambler", [3] = "shambler", [4] = "random" }

-- IsoAnimal extends IsoPlayer in B42, so the order matters:
-- zombie first, then animal, only then player
local function attackerInfo(victim)
    local a = grab(function() return victim:getAttackedBy() end)
    if not a then return nil end
    local info = {}
    if grab(function() return a:isZombie() end) == true then
        info.kind = "zombie"
        local traits = {}
        local speed = SPEED_NAMES[grab(function() return a:getSpeedType() end)]
        if speed then table.insert(traits, speed) end
        if grab(function() return a:isCrawling() end) == true then table.insert(traits, "crawling") end
        if grab(function() return a:isBecomeCrawler() end) == true then table.insert(traits, "crawler") end
        if grab(function() return a:isSkeleton() end) == true then table.insert(traits, "skeleton") end
        if grab(function() return a:isReanimatedPlayer() end) == true then table.insert(traits, "reanimated player") end
        if #traits > 0 then info.detail = table.concat(traits, ", ") end
    elseif grab(function() return a:isAnimal() end) == true
        or grab(function() return instanceof(a, "IsoAnimal") end) == true then
        info.kind = "animal"
        info.name = grab(function() return a:getFullName() end)
        local traits = {}
        local typ = grab(function() return a:getAnimalType() end)
        if typ then table.insert(traits, tostring(typ)) end
        local breedObj = grab(function() return a:getBreed() end)
        local breed = breedObj and grab(function() return breedObj:getName() end)
        if breed then table.insert(traits, tostring(breed)) end
        if #traits > 0 then info.detail = table.concat(traits, ", ") end
    elseif grab(function() return instanceof(a, "IsoPlayer") end) == true then
        info.kind = "player"
        info.name = grab(function() return a:getUsername() end)
        -- the engine attributes kills via getUseHandWeapon, primary item is
        -- the same fallback IsoZombie.onKilled uses
        local w = grab(function() return a:getUseHandWeapon() end)
            or grab(function() return a:getPrimaryHandItem() end)
        if w then
            info.weapon = grab(function() return w:getDisplayName() end)
                or grab(function() return w:getName() end)
        end
    else
        info.kind = "unknown"
    end
    return info
end

local function woundLines(bd)
    local lines = {}
    local parts = grab(function() return bd:getBodyParts() end)
    if not parts then return lines end
    local n = grab(function() return parts:size() end) or 0
    for i = 0, n - 1 do
        local part = grab(function() return parts:get(i) end)
        if part then
            local flags = {}
            local function flag(label, fn)
                if grab(fn) == true then table.insert(flags, label) end
            end
            flag("bitten", function() return part:bitten() end)
            flag("scratched", function() return part:scratched() end)
            flag("cut", function() return part:isCut() end)
            flag("deep wound", function() return part:deepWounded() end)
            flag("bleeding", function() return part:bleeding() end)
            flag("burnt", function() return part:isBurnt() end)
            flag("bullet", function() return part:haveBullet() end)
            flag("glass", function() return part:haveGlass() end)
            flag("wound infection", function() return part:isInfectedWound() end)
            flag("zombie infection", function() return part:IsInfected() end)
            -- no isFractured in B42, fracture time is the proof
            if (grab(function() return part:getFractureTime() end) or 0) > 0 then
                local splinted = grab(function() return part:isSplint() end) == true
                table.insert(flags, splinted and "fracture (splinted)" or "fracture")
            end
            if #flags > 0 then
                local name = grab(function() return BodyPartType.ToString(part:getType()) end)
                    or ("part " .. tostring(i))
                local line = tostring(name) .. ": " .. table.concat(flags, ", ")
                local hp = round2(grab(function() return part:getHealth() end))
                if hp then line = line .. " (health " .. hp .. ")" end
                table.insert(lines, line)
                if #lines >= 25 then break end
            end
        end
    end
    return lines
end

local function zombiesNear(player)
    local list = grab(function() return player:getCell():getZombieList() end)
    if not list then return nil end
    local px = grab(function() return player:getX() end)
    local py = grab(function() return player:getY() end)
    local n = grab(function() return list:size() end)
    if not px or not py or not n then return nil end
    local count = 0
    for i = 0, n - 1 do
        pcall(function()
            local z = list:get(i)
            if z then
                local dx, dy = z:getX() - px, z:getY() - py
                if dx * dx + dy * dy <= 225 then count = count + 1 end
            end
        end)
    end
    return count
end

local function collect(player)
    local d = {}
    d.igTime = grab(function()
        local gt = getGameTime()
        if not gt then return nil end
        return string.format("%04d-%02d-%02d %02d:%02d",
            gt:getYear(), gt:getMonth() + 1, gt:getDayPlusOne(), gt:getHour(), gt:getMinutes())
    end)
    d.x = grab(function() return math.floor(player:getX()) end)
    d.y = grab(function() return math.floor(player:getY()) end)
    d.z = grab(function() return math.floor(player:getZ()) end)
    local sq = grab(function() return player:getCurrentSquare() end)
    if sq then
        -- getRoom is nil on every outdoor death and pcall does not stop
        -- the engine popup on nil method calls, split the chain
        local room = grab(function() return sq:getRoom() end)
        if room then d.room = grab(function() return room:getName() end) end
        d.zone = grab(function() return sq:getZoneType() end)
    end
    local veh = grab(function() return player:getVehicle() end)
    if veh then d.vehicle = grab(function() return veh:getScriptName() end) end
    d.attacker = attackerInfo(player)
    d.onFire = grab(function() return player:isOnFire() end) == true

    local bd = grab(function() return player:getBodyDamage() end)
    if bd then
        d.burnt = grab(function() return bd:isBurntToDeath() end) == true
            or grab(function() return bd:WasBurntToDeath() end) == true
        d.infected = grab(function() return bd:isInfected() end) == true
        local it = round2(grab(function() return bd:getInfectionTime() end))
        if it and it >= 0 then d.infectionTime = it end
        d.coreTemp = round2(grab(function()
            local thermo = bd:getThermoregulator()
            if not thermo then return nil end
            return thermo:getCoreTemperature()
        end))
        d.wounds = woundLines(bd)
    end

    d.infectionLevel = stat(player, "ZOMBIE_INFECTION")
    d.fever = stat(player, "ZOMBIE_FEVER")
    d.poison = stat(player, "POISON")
    d.foodSickness = stat(player, "FOOD_SICKNESS")
    d.hunger = stat(player, "HUNGER")
    d.thirst = stat(player, "THIRST")

    d.hoursSurvived = round2(grab(function() return player:getHoursSurvived() end))
    d.zombieKills = grab(function() return player:getZombieKills() end)
    d.survivorKills = grab(function() return player:getSurvivorKills() end)
    d.zombiesNear = zombiesNear(player)
    return d
end

Events.OnPlayerDeath.Add(function(player)
    if not player then return end
    local ok, data = pcall(collect, player)
    if not ok or type(data) ~= "table" then data = { failed = true } end
    -- fires in-process in solo too, the server file listens either way
    pcall(function()
        sendClientCommand(player, AegisShared.MODULE, "deathReport", data)
    end)
end)

-- live notice for admins, translated only here (the dedicated server has
-- no UI texts and sends key plus parameter instead)
Events.OnServerCommand.Add(function(module, command, args)
    if module ~= AegisShared.MODULE or command ~= "deathNotice" then return end
    if not args or not args.key then return end
    local text = args.par ~= nil and getText(args.key, args.par) or getText(args.key)
    Aegis.showToast(text)
end)
