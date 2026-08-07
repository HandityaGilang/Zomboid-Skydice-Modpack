local SU = require "Utils/PK42SharedUtils"
-- PK42Hallucinations.lua (Client)
-- Alucinações auditivas, visuais e risos por nível de insanidade.

local function getSandboxCFG()
    local opts       = SandboxVars.PK42
    local audioBase  = opts and opts.AudioHallucinationStartingChance  or 10
    local speechBase = opts and opts.IntrusiveThoughtsStartingChance   or 20
    local visualBase = opts and opts.VisualHallucinationStartingChance or 10
    return {
        -- Níveis de gatilho
        LEVEL_SPEECH_START  = 3,
        LEVEL_AUDIO_START   = 4,
        LEVEL_VISUAL_START  = 5,
        LEVEL_INTENSIFY     = 6,
        LEVEL_CEASE         = opts and opts.HallucinationCeaseLevel or 10,

        -- Sandbox options para desabilitar tipos de alucinação
        DISABLE_VISUAL_HAL   = opts and opts.DisableVisualHal == true,
        DISABLE_AUDIO_HAL    = opts and opts.DisableAudioHal == true,
        DISABLE_SPEECH_HAL   = opts and opts.DisableSpeechHal == true,

        -- Chances de alucinação
        AUDIO_CHANCE_LVL4   = audioBase  + 5,
        AUDIO_CHANCE_LVL6   = audioBase  + 10,

        SPEECH_CHANCE_LVL4  = speechBase,
        SPEECH_CHANCE_LVL6  = speechBase + 15,

        VISUAL_CHANCE_LVL5  = visualBase,
        VISUAL_CHANCE_LVL6  = visualBase + 15,

        -- Chances de eventos
        ZOMBIE_SOUND_CHANCE      = 40,
        HIT_JUMPSCARE_CHANCE     = 3,
        VISUAL_HAL_SCREAM_CHANCE = 80,

        -- Chances de eventos
        LAUGH_CHANCE             = opts and opts.LaughChance            or 10,
        VEHICLE_JUMPSCARE_CHANCE = opts and opts.VehicleJumpscareChance or 10,

        -- Modificadores de álcool e spawn
        ALCOHOL_BOOST          = 2.0,   -- multiplicador enquanto estiver bêbado
        ALCOHOL_DEBUFF         = 0.40,  -- multiplicador nas 24h após sobriedade
        ALCOHOL_DEBUFF_HOURS   = opts and opts.AlcoholDebuffHours or 24,
        HAL_SPAWN_DIST_INDOOR  = 2, -- distância de spawn do halucinação visual em ambientes internos
        HAL_SPAWN_DIST_OUTDOOR = 8, -- distância de spawn do halucinação visual em ambientes externos

        -- Efeitos de pânico/stress 
        RESOLVE_PANIC   = 100, -- Psicopata não sofre pânico, mas players comuns podem, com muito custo, obter níveis de insanidade altos o suficiente para ter alucinações.
        RESOLVE_STRESS  = 0.30, 
        RESOLVE_UNHAPPY = 5,
        AUDIO_PANIC     = 25,
        AUDIO_STRESS    = 0.10,

        CANNIBAL_MEAT_THRESHOLD = opts and opts.CannibalAmountThreshold or 100,
    }
end

local MD_TOTAL_MEAT           = "totalMeatConsumed"

local fakeZombie = nil
local oldHalPos = { X = nil, Y = nil, Z = nil }

local SOUNDS_ZOMBIE_ATTACK = {
    "z_male_C_Attack_01",
    "z_male_C_Attack_04",
    "z_male_C_Attack_05",
    "z_male_C_Attack_06",
    "z_male_vocal_A_attack_01b",
    "z_male_vocal_A_attack_03b",
    "z_male_vocal_A_attack_05b",
    "z_male_vocal_B_attack_08",
    "z_sprinter_female_vocal_A_aggro_03",
    "z_sprinter_female_vocal_A_aggro_05",
    "z_sprinter_female_vocal_A_aggro_06",
    "z_sprinter_female_vocal_A_aggro_07",
    "z_sprinter_female_vocal_A_attack_long_05",
    "z_sprinter_female_vocal_A_attack_long_08",
    "z_sprinter_female_vocal_B_aggro_01",
    "z_sprinter_female_vocal_B_aggro_02",
    "z_sprinter_female_vocal_B_attack_long_01",
    "z_sprinter_female_vocal_B_attack_long_02",
    "z_sprinter_female_vocal_B_attack_long_04",
    "z_sprinter_female_vocal_B_attack_long_07",
    "z_sprinter_male_vocal_A_aggro_01",
    "z_sprinter_male_vocal_A_attack_long_02",
    "z_sprinter_male_vocal_B_attack_long_01",
    "z_sprinter_male_vocal_B_attack_long_02",
}

local SOUNDS_SCRATCH = {
    "z_scratch_gore_short_01",
    "z_scratch_gore_short_02",
    "z_scratch_gore_short_03",
    "z_scratch_gore_short_04",
    "z_scratch_gore_short_05",
    "z_scratch_gore_short_06",
    "z_scratch_gore_short_07",
    "z_scratch_gore_short_08",
}

local SOUNDS_AMBIENT_INDOOR = {
    "obj_door_break_01",
    "obj_door_thump_wood_no_detail_01",
    "obj_door_thump_wood_no_detail_05",
    "obj_door_unlock_01",
    "obj_door_unlock_02",
    "obj_window_smash_light_v2_01",
    "obj_window_smash_light_v2_02",
    "obj_window_smash_light_v2_03",
    "obj_window_smash_light_v2_04",
    "obj_window_thump_thick_squeak_08",
    "obj_window_thump_thick_squeak_09",
    "obj_window_thump_thick_squeak_10",
    "obj_animal_in_trap_metal_01",
    "obj_animal_in_trap_metal_02",
    "obj_animal_in_trap_metal_03",
    "obj_animal_in_trap_metal_04",
    "obj_animal_in_trap_wood_01",
    "obj_animal_in_trap_wood_02",
    "obj_animal_in_trap_wood_03",
    "obj_animal_in_trap_wood_04",
}

local SOUNDS_AMBIENT_OUTDOOR = {
    "obj_door_break_01",
    "obj_window_smash_light_v2_01",
    "obj_window_smash_light_v2_02",
    "obj_window_smash_light_v2_03",
    "obj_window_smash_light_v2_04",
    "m_gunshots_FAL_02",
    "m_gunshots_GAU5A_02",
    "m_gunshots_M16A2_02",
}

local SOUNDS_HELI = {
    "m_heli_hover_loop_close",
    "m_heli_hover_loop_distant",
}

local LAUGHS_FEMALE = {
    "female_laugh_01",
    "female_laugh_02",
    "female_laugh_03",
    "female_laugh_04",
    "female_laugh_05",
    "female_laugh_06",
    "female_laugh_07",
    "female_laugh_08",
}

local LAUGHS_MALE = {
    "male_laugh_01",
    "male_laugh_02",
    "male_laugh_03",
    "male_laugh_04",
}

local SCREAMS_FEMALE = {
    "FemalePlayer_DeathScreams_02_01",
    "FemalePlayer_DeathScreams_02_02",
    "FemalePlayer_DeathScreams_02_03",
    "FemalePlayer_DeathScreams_02_04",
    "FemalePlayer_DeathScreams_06",
}

local SCREAMS_MALE = {
    "MalePlayer_DeathScreams_03",
    "MalePlayer_DeathScreams_04",
    "MalePlayer_DeathScreams_07",
}

local DIRECTIONS = { "", "_L", "_R" }

local SPAWN_OFFSETS = {
    { X = -1, Y = -1 }, { X = 0, Y = -1 }, { X = 1, Y = -1 },
    { X =  1, Y =  0 },
    { X =  1, Y =  1 }, { X = 0, Y =  1 }, { X = -1, Y =  1 },
    { X = -1, Y =  0 },
}

local function getLocalPlayer()
    return getSpecificPlayer(0)
end

local function getInsanityLevel(player)
    return player:getPerkLevel(Perks.Insanity)
end

local function isDrunk(player)
    return player:getStats():get(CharacterStat.INTOXICATION) > 0
end

local function applyAlcohol(player, baseChance)
    local cfg = getSandboxCFG()
    local md  = player:getModData()
    if isDrunk(player) then
        return baseChance * cfg.ALCOHOL_BOOST
    end
    if md.PK42LastDrankHour then
        return baseChance * cfg.ALCOHOL_DEBUFF
    end
    return baseChance
end

local function playHallucinationSound(name, hasDirectional)
    local dir   = hasDirectional and DIRECTIONS[ZombRand(#DIRECTIONS) + 1] or ""
    local final = name .. dir
    getPlayer():playSoundLocal(final)
    return final
end

local function playRandomHallucinationSound(soundList)
    local name = soundList[ZombRand(#soundList) + 1]
    return playHallucinationSound(name, true)
end

local function playHeliSound()
    playRandomHallucinationSound(SOUNDS_HELI)
end

local function emitPlayerSound(player, forceScream)
    if player:isAsleep() then return end

    local indoor = player:getBuilding() ~= nil

    if forceScream then
        local list   = player:isFemale() and SCREAMS_FEMALE or SCREAMS_MALE
        local name   = list[ZombRand(#list) + 1]
        local radius = indoor and 6 or 14
        player:getEmitter():playSound(name)
        addSound(player, player:getX(), player:getY(), player:getZ(), radius, radius)
        return
    end

    local list   = player:isFemale() and LAUGHS_FEMALE or LAUGHS_MALE
    local name   = list[ZombRand(#list) + 1]
    local radius = indoor and 4 or 8
    player:getEmitter():playSound(name)
    addSound(player, player:getX(), player:getY(), player:getZ(), radius, radius)
end

local function doAudioHallucination(player)
    local cfg       = getSandboxCFG()
    local indoor    = player:getBuilding() ~= nil
    local useZombie = ZombRand(100) < cfg.ZOMBIE_SOUND_CHANCE
    local useHeli   = not useZombie and ZombRand(100) < 15

    if useZombie then
        playRandomHallucinationSound(SOUNDS_ZOMBIE_ATTACK)
    elseif useHeli then
        playHeliSound()
    else
        local list = indoor and SOUNDS_AMBIENT_INDOOR or SOUNDS_AMBIENT_OUTDOOR
        playRandomHallucinationSound(list)
    end

    local stats = player:getStats()
    stats:add(CharacterStat.PANIC, cfg.AUDIO_PANIC)
    stats:add(CharacterStat.STRESS, cfg.AUDIO_STRESS)
    syncPlayerStats(player, 0x00000100)
end

local function findSpawnSquare(player, distance)
    local start = ZombRand(8) + 1
    local cur   = start

    repeat
        local off = SPAWN_OFFSETS[cur]
        local mx  = math.floor(player:getX() + off.X * distance)
        local my  = math.floor(player:getY() + off.Y * distance)
        local sq  = player:getCell():getGridSquare(mx, my, player:getZ())

        if sq and not sq:isSolidTrans() and sq:TreatAsSolidFloor() then
            local indoor = player:getBuilding() ~= nil
            if indoor and not sq:isOutside() then
                return { X = mx, Y = my }
            elseif not indoor and sq:isOutside() then
                return { X = mx, Y = my }
            end
        end

        cur = (cur % 8) + 1
    until cur == start

    return nil
end

function makeHallucinationUseless(zombie)
    if zombie ~= fakeZombie then return end
    if oldHalPos.X ~= fakeZombie:getX() or oldHalPos.Y ~= fakeZombie:getY() then
        fakeZombie:setHealth(100000)
        oldHalPos = { X = nil, Y = nil, Z = nil }
        Events.OnZombieUpdate.Remove(makeHallucinationUseless)
    end
end

local function resolveHallucination(player, reason)
    if fakeZombie then
        fakeZombie:removeFromWorld()
        fakeZombie:removeFromSquare()
        fakeZombie = nil
    end
    Events.OnTick.Remove(seenCheck)
    Events.OnHitZombie.Remove(hitCheck)
    Events.OnZombieUpdate.Remove(makeHallucinationUseless)

    local cfg   = getSandboxCFG()
    local stats = player:getStats()
    stats:add(CharacterStat.PANIC, cfg.RESOLVE_PANIC)
    stats:add(CharacterStat.STRESS, cfg.RESOLVE_STRESS)
    stats:add(CharacterStat.UNHAPPINESS, cfg.RESOLVE_UNHAPPY)
    syncPlayerStats(player, 0x00000100)

    player:playSoundLocal("ZombieSurprisedPlayer")

    if ZombRand(100) < cfg.VISUAL_HAL_SCREAM_CHANCE then
        emitPlayerSound(player, true)
    end
end

function seenCheck()
    local player = getLocalPlayer()
    if not player then return end
    if fakeZombie == nil then
        Events.OnTick.Remove(seenCheck)
        Events.OnHitZombie.Remove(hitCheck)
        return
    end
    local dist = fakeZombie:DistTo(player)
    if dist <= 1.5 and player:CanSee(fakeZombie) then
        resolveHallucination(player, "CanSeeCheck")
    end
end

function hitCheck(zombie)
    if zombie ~= fakeZombie then return end
    local player = getLocalPlayer()
    if not player then return end
    resolveHallucination(player, "HitZombie")
end

local function createVisualHallucination(player)
    if fakeZombie then
        fakeZombie:removeFromWorld()
        fakeZombie:removeFromSquare()
        fakeZombie = nil
        Events.OnTick.Remove(seenCheck)
        Events.OnHitZombie.Remove(hitCheck)
        Events.OnZombieUpdate.Remove(makeHallucinationUseless)
    end

    local cfg    = getSandboxCFG()
    local dist   = player:getBuilding() and cfg.HAL_SPAWN_DIST_INDOOR or cfg.HAL_SPAWN_DIST_OUTDOOR
    local square = findSpawnSquare(player, dist)
    if not square then return end

    local outfits = { "Generic01", "Generic02", "Generic03", "Generic04", "Generic05" }
    local outfit  = outfits[ZombRand(#outfits) + 1]

    local zombies = addZombiesInOutfit(square.X, square.Y, player:getZ(), 1, outfit, nil)
    if not zombies or zombies:size() == 0 then return end

    local z = zombies:get(0)

    z:makeInactive(false)
    z:doSprinter() -- new method in B42.18, doesn't require z:setWalkType('sprint1') anymore
    z:setTarget(player)

    oldHalPos = { X = z:getX(), Y = z:getY(), Z = z:getZ() }

    z:pathToCharacter(player)

    fakeZombie = z

    Events.OnHitZombie.Add(hitCheck)
    Events.OnZombieUpdate.Add(makeHallucinationUseless)
    Events.OnTick.Add(seenCheck)
end

local function playJumpscare(player)
    if ZombRand(2) == 1 then
        player:playSoundLocal("ZombieSurprisedPlayer")
    end

    local dir         = DIRECTIONS[ZombRand(#DIRECTIONS) + 1]
    local attackSound = SOUNDS_ZOMBIE_ATTACK[ZombRand(#SOUNDS_ZOMBIE_ATTACK) + 1]
    player:playSoundLocal(attackSound .. dir)

    if ZombRand(2) == 1 then
        local scratchSound = SOUNDS_SCRATCH[ZombRand(#SOUNDS_SCRATCH) + 1]
        player:playSoundLocal(scratchSound .. dir)
    end
end

local function onExitVehicle(vehicle, player)
    if not player or not player:isLocalPlayer() or player:getPlayerNum() ~= 0 then return end
    if not SU.hasPsychopathTrait(player) then return end

    local cfg   = getSandboxCFG()
    local level = getInsanityLevel(player)
    if level < cfg.LEVEL_AUDIO_START then return end
    if cfg.DISABLE_AUDIO_HAL then return end

    local chance = applyAlcohol(player, cfg.VEHICLE_JUMPSCARE_CHANCE)
    local roll   = ZombRand(100)

    if roll < chance then
        playJumpscare(player)

        local stats = player:getStats()
        stats:add(CharacterStat.PANIC, cfg.AUDIO_PANIC)
        stats:add(CharacterStat.STRESS, cfg.AUDIO_STRESS)
        syncPlayerStats(player, 0x00000100)
    end
end

local function onHitZombieJumpscare(zombie)
    local player = getLocalPlayer()
    if not player or not player:isLocalPlayer() or player:getPlayerNum() ~= 0 then return end

    local weapon = player:getPrimaryHandItem()
    if not SU.IsBareHands(weapon) then return end

    if not SU.hasPsychopathTrait(player) then return end
    if zombie == fakeZombie then return end

    local cfg   = getSandboxCFG()
    local level = getInsanityLevel(player)
    if level < cfg.LEVEL_AUDIO_START then return end
    if cfg.DISABLE_AUDIO_HAL then return end

    local chance = applyAlcohol(player, cfg.HIT_JUMPSCARE_CHANCE)
    local roll   = ZombRand(100)

    if roll < chance then
        local dir          = DIRECTIONS[ZombRand(#DIRECTIONS) + 1]
        local scratchSound = SOUNDS_SCRATCH[ZombRand(#SOUNDS_SCRATCH) + 1]
        player:playSoundLocal(scratchSound .. dir)

        local stats = player:getStats()
        stats:add(CharacterStat.PANIC, cfg.AUDIO_PANIC)
        stats:add(CharacterStat.STRESS, cfg.AUDIO_STRESS)
        syncPlayerStats(player, 0x00000100)
    end
end

local function onHourEvent()
    local player = getLocalPlayer()
    if not player then return end
    if not SU.hasPsychopathTrait(player) then return end
    if not player:isLocalPlayer() or player:getPlayerNum() ~= 0 then return end
    if player:isAsleep() then return end

    local level = getInsanityLevel(player)
    local cfg   = getSandboxCFG()

    if level >= cfg.LEVEL_CEASE then
        local totalMeat = player:getModData()[MD_TOTAL_MEAT] or 0
        if totalMeat >= cfg.CANNIBAL_MEAT_THRESHOLD then
            local chance = applyAlcohol(player, cfg.LAUGH_CHANCE)
            local roll   = ZombRand(100)
            if roll < chance then emitPlayerSound(player, false) end
        end
        return
    end

    -- Alucinações mutuamente exclusivas: monta a lista dos tipos elegíveis no
    -- nível atual, sorteia um único tipo por tick e só dispara esse.
    -- A ordem na tabela define prioridade de elegibilidade, não de ocorrência
    -- (o sorteio é uniforme entre os elegíveis).
    local eligible = {}

    if not cfg.DISABLE_SPEECH_HAL and level >= cfg.LEVEL_SPEECH_START then
        eligible[#eligible + 1] = "speech"
    end
    if not cfg.DISABLE_AUDIO_HAL and level >= cfg.LEVEL_AUDIO_START then
        eligible[#eligible + 1] = "audio"
    end
    if not cfg.DISABLE_VISUAL_HAL and level >= cfg.LEVEL_VISUAL_START then
        eligible[#eligible + 1] = "visual"
    end

    if #eligible == 0 then return end

    local chosen = eligible[ZombRand(1, #eligible + 1)]

    if chosen == "speech" then
        local sc   = level >= cfg.LEVEL_INTENSIFY and cfg.SPEECH_CHANCE_LVL6 or cfg.SPEECH_CHANCE_LVL4
        sc         = applyAlcohol(player, sc)
        if ZombRand(100) < sc then
            local idx  = ZombRand(1, 12)
            player:Say(getText("IGUI_PK42_IntrusiveThought" .. idx))
        end

    elseif chosen == "audio" then
        local ac = level >= cfg.LEVEL_INTENSIFY and cfg.AUDIO_CHANCE_LVL6 or cfg.AUDIO_CHANCE_LVL4
        ac       = applyAlcohol(player, ac)
        if ZombRand(100) < ac then
            doAudioHallucination(player)
        end

    elseif chosen == "visual" then
        local vc = level >= cfg.LEVEL_INTENSIFY and cfg.VISUAL_CHANCE_LVL6 or cfg.VISUAL_CHANCE_LVL5
        vc       = applyAlcohol(player, vc)
        if ZombRand(100) < vc then
            createVisualHallucination(player)
        end
    end

    local totalMeat = player:getModData()[MD_TOTAL_MEAT] or 0
    if totalMeat >= cfg.CANNIBAL_MEAT_THRESHOLD then
        local lc   = applyAlcohol(player, cfg.LAUGH_CHANCE)
        local roll = ZombRand(100)
        if roll < lc then
            emitPlayerSound(player, false)
        end
    end
end

local function onPlayerDeath(deadPlayer)
    local player = getLocalPlayer()
    if deadPlayer ~= player then return end
    if fakeZombie then
        fakeZombie:removeFromWorld()
        fakeZombie:removeFromSquare()
        fakeZombie = nil
    end
    Events.OnTick.Remove(seenCheck)
    Events.OnHitZombie.Remove(hitCheck)
    Events.OnZombieUpdate.Remove(makeHallucinationUseless)
end

local function onEveryTenMinutes()
    local player = getLocalPlayer()
    if not player then return end
    if not SU.hasPsychopathTrait(player) then return end

    local md    = player:getModData()
    local drunk = isDrunk(player)

    if drunk and not md.PK42LastDrankHour then
        sendClientCommand(player, "PK42", "DrankAlcohol", {
            hour = getGameTime():getWorldAgeHours()
        })
    end
end

-- Remove zumbi alucinatório ao sair do jogo no SP
-- Ocorre que se o jogador sair com o zumbi alucinatório spawnado no mundo, quando retornar ao jogo ele não é mais uma alucinação e sim um zumbi real
-- Isso poderia causar a morte do jogador de maneira indesejada.
local function clearFakeZombies()
    if fakeZombie then
        fakeZombie:removeFromWorld()
        fakeZombie:removeFromSquare()
        fakeZombie = nil
    end
end

Events.OnSave.Add(clearFakeZombies)

Events.EveryHours.Add(onHourEvent)
Events.OnPlayerDeath.Add(onPlayerDeath)
Events.OnExitVehicle.Add(onExitVehicle)
Events.OnHitZombie.Add(onHitZombieJumpscare)
Events.EveryTenMinutes.Add(onEveryTenMinutes)