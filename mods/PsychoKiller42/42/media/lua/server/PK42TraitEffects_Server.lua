-- PK42TraitEffects_Server.lua
-- Lógica autoritativa de frenzy/streak/dano e registro de eventos server-side.

local SU = require "Utils/PK42SharedUtils"

local function getSandboxCFG()
    local opts = SandboxVars.PK42
    return {
        -- Frenzy: ativação e comportamento
        ALLOW_FRENZY               = opts and opts.AllowFrenzy               ~= false,
        ENABLE_FRENZY_DAMAGE_BONUS = opts and opts.EnableFrenzyDamageBonus   ~= false,

        -- Frenzy: thresholds e cooldown
        FRENZY_FATIGUE_THRESHOLD   = (opts and opts.FrenzyFatigueThreshold   or 60)  / 100,
        FRENZY_ENDURANCE_THRESHOLD = (opts and opts.FrenzyEnduranceThreshold or 70)  / 100,
        FRENZY_STREAK_THRESHOLD    = opts and opts.FrenzyStreakThreshold      or 2,
        FRENZY_COOLDOWN_HOURS      = opts and opts.FrenzyCooldownHours        or 12,
        FRENZY_MAX_HOURS           = opts and opts.FrenzyMaxTime               or 2,
        FRENZY_RESTORE_HOURS       = 2, -- tempo em horas para restaurar stats após frenzy encerrar
        FRENZY_PENALTY             = 0.20, -- penalidade pós-frenzy: +20% fatigue/pain, -20% endurance
        FRENZY_MAX_DMG_BONUS       = (opts and opts.FrenzyMaxDamageBonus or 80) / 100, -- bônus máximo de dano em frenzy

        -- Streak: intervalos de decay
        STREAK_DECAY_INTERVAL      = 2, -- time in minutes without kills to decay streak by 1
        STREAK_ZERO_INTERVAL       = opts and opts.FrenzyStreakChainMaxTime or 15, -- time in minutes to break the kill chain and reset streak to 0
        STREAK_MAX                 = 100, -- maximum streak value

        -- Boredom: horas sem kill para penalidade de stress
        BOREDOM_THRESHOLD_HOURS    = opts and opts.BoredomThresholdHours     or 12,

        -- XP por kills
        XP_KILL_ZOMBIE             = opts and opts.XPOnKillZombie            or 1, -- It gives 0.25 XP due to internal engine calculation (profession & perks boosts)
        XP_KILL_ZOMBIE_FRENZY      = opts and opts.XPOnKillZombieOnFrenzy    or 2,
        XP_KILL_PLAYER             = opts and opts.XPOnKillPlayer            or 200,
        XP_KILL_BANDIT             = opts and opts.BanditsXP                 or 50,

        -- Cap diário de XP de kills
        ENABLE_XP_DAILY_CAP        = opts and opts.EnableXPDailyCap          ~= false,
        DAILY_XP_CAP               = opts and opts.XPDailyCap            or 200,

        -- Cannibal unlock
        CANNIBAL_UNLOCK_LEVEL      = opts and opts.CannibalUnlockThreshold   or 7,
        CANNIBAL_MEAT_THRESHOLD    = opts and opts.CannibalAmountThreshold or 100,

        -- Álcool: janela de debuff pós-intoxicação
        ALCOHOL_DEBUFF_HOURS       = opts and opts.AlcoholDebuffHours        or 24,

        -- Nicotina: simula uso de nicotina ao matar/atacar
        SIMULATE_NICOTINE_ON_KILL = opts and opts.SimulateNicotineOnKill    ~= false,
    }
end

-- Chaves de ModData
local MD_XP_TODAY          = SU.MD.XP_KILL_TODAY
local MD_XP_FRENZY_TODAY   = SU.MD.XP_FRENZY_TODAY
local MD_LAST_RESET        = SU.MD.LAST_KILL_RESET
local MD_LAST_FRENZY_RESET = SU.MD.LAST_FRENZY_RESET

-- Chave local: snapshot de stiffness (rigidez/fadiga muscular) por parte do corpo.
local MD_FRENZY_REAL_STIFFNESS = "PK42FrenzyRealStiffness"

local function worldHour()
    return SU.worldHour()
end

-- Retorna o multiplicador de XP baseado no nível atual de Insanity.
local function getInsanityXPMultiplier(player)
    local level = player:getPerkLevel(Perks.Insanity) or 0
    return 1.0 + (level * 0.05)
end

-- Concede XP de Insanity via cap usando um bucket específico (kill normal ou frenzy).
-- Aplica o multiplicador de nível de Insanity antes de repassar a SU.gainInsanityXP.
local function gainKillXPFromBucket(player, amount, bucketKey)
    if amount <= 0 then return end
    local cfg        = getSandboxCFG()
    local multiplier = getInsanityXPMultiplier(player)
    local scaled     = amount * multiplier
    SU.gainInsanityXP(
        player, scaled,
        bucketKey, MD_LAST_RESET,
        cfg.DAILY_XP_CAP, cfg.ENABLE_XP_DAILY_CAP
    )
end

-- XP de kills normais (fora do frenzy), limitado por MD_XP_TODAY.
local function gainNormalKillXP(player, amount)
    gainKillXPFromBucket(player, amount, MD_XP_TODAY)
end

-- XP de kills em frenzy, limitado por MD_XP_FRENZY_TODAY com timestamp próprio.
local function gainFrenzyKillXP(player, amount)
    if amount <= 0 then return end
    local cfg        = getSandboxCFG()
    local multiplier = getInsanityXPMultiplier(player)
    local scaled     = amount * multiplier
    SU.gainInsanityXP(
        player, scaled,
        MD_XP_FRENZY_TODAY, MD_LAST_FRENZY_RESET,
        cfg.DAILY_XP_CAP, cfg.ENABLE_XP_DAILY_CAP
    )
end

-- STAT FLAGS: bitmask dinâmico gerado em runtime
local PK42SF = {}
do
    local statNames = {
        "Anger", "Boredom", "Discomfort", "Endurance", "Fatigue",
        "Fitness", "FoodSickness", "Hunger", "Idleness", "Intoxication",
        "Morale", "NicotineWithdrawal", "Pain", "Panic", "Poison",
        "Sanity", "Sickness", "Stress", "Temperature", "Thirst",
        "Unhappiness", "Wetness", "ZombieFever", "ZombieInfection",
    }
    for _, name in ipairs(statNames) do
        local charStat = CharacterStat.getById(name)
        if charStat then
            PK42SF[name] = SyncPlayerStatsPacket.getBitMaskForStat(charStat)
        end
    end
end

local MASK_COMMON = PK42SF.Fatigue
                  + PK42SF.Endurance
                  + PK42SF.Pain
                  + PK42SF.Stress
                  + PK42SF.Boredom
                  + PK42SF.Unhappiness
                  + PK42SF.NicotineWithdrawal

local MASK_RESTORE = PK42SF.Fatigue
                   + PK42SF.Endurance
                   + PK42SF.Pain

local function syncStats(player)
    if isServer() then
        syncPlayerStats(player, MASK_COMMON)
    end
end

-- Retorna o bônus de dano baseado no streak atual (escala de 10 em 10, máximo +80%)
local function PK42GetStreakDamageBonus(streak)
    local cfg = getSandboxCFG()
    local FRENZY_DMG_BONUS = cfg.FRENZY_MAX_DMG_BONUS / 8

    streak = tonumber(streak) or 0
    if streak >= 80 then return FRENZY_DMG_BONUS * 8
    elseif streak >= 70 then return FRENZY_DMG_BONUS * 7
    elseif streak >= 60 then return FRENZY_DMG_BONUS * 6
    elseif streak >= 50 then return FRENZY_DMG_BONUS * 5
    elseif streak >= 40 then return FRENZY_DMG_BONUS * 4
    elseif streak >= 30 then return FRENZY_DMG_BONUS * 3
    elseif streak >= 20 then return FRENZY_DMG_BONUS * 2
    elseif streak >= 10 then return FRENZY_DMG_BONUS
    else return 0.0
    end
end

local function isSmoker(player)
    return player:hasTrait(CharacterTrait.SMOKER)
end

-- Reduz NicotineWithdrawal
local function applyNicotineRelief(player, stats, amount)
    local cfg = getSandboxCFG()
    if not cfg.SIMULATE_NICOTINE_ON_KILL then return end
    if not isSmoker(player) then return end

    local nicotineWithdrawal = stats:get(CharacterStat.NICOTINE_WITHDRAWAL)
    if nicotineWithdrawal > 0.2 then
        stats:add(CharacterStat.NICOTINE_WITHDRAWAL, -math.abs(amount))
    end
end

-- Itera todas as partes do corpo do player, chamando fn(bodyPart, index) para cada uma.
local function forEachBodyPart(player, fn)
    local bodyDamage = player:getBodyDamage()
    if not bodyDamage then return end
    local parts = bodyDamage:getBodyParts()
    for i = 0, parts:size() - 1 do
        fn(parts:get(i), i)
    end
end

-- Trava a stiffness (fadiga muscular) de todas as partes do corpo em um valor fixo.
local function setAllStiffness(player, value)
    forEachBodyPart(player, function(part)
        part:setStiffness(value)
    end)
end

local function applyPanicValues(player, increaseValue, reductionValue)
    local bd = player:getBodyDamage()
    if not bd then return end
    bd:setPanicIncreaseValue(increaseValue)
    bd:setPanicReductionValue(reductionValue)
end

local function isOnCooldown(player)
    local md    = player:getModData()
    local start = md[SU.MD.COOLDOWN_START]
    if not start then return false end
    return (getGameTime():getWorldAgeHours() - start) < getSandboxCFG().FRENZY_COOLDOWN_HOURS
end

-- Mantém os stats fixos enquanto o frenzy estiver ativo.
-- Chamado via EveryOneMinute para rodar server-side no MP.
local function applyFrenzyHold(player)
    local md = player:getModData()
    if md[SU.MD.FRENZY_FIXED_FATIGUE] == nil or md[SU.MD.FRENZY_FIXED_ENDUR] == nil then
        return
    end
    local stats = player:getStats()
    stats:set(CharacterStat.FATIGUE,   0)
    stats:set(CharacterStat.ENDURANCE, 1)
    stats:set(CharacterStat.PAIN,      0)
    setAllStiffness(player, 0)
    syncStats(player)
end

-- Restaura gradualmente os stats após o frenzy encerrar, interpolando ao longo de FRENZY_RESTORE_HOURS.
local function applyFrenzyRestore(player)
    local md = player:getModData()
    if md[SU.MD.FRENZY_RESTORE_DONE] == true then return end
    if md[SU.MD.FRENZY_END_HOUR] == nil then return end

    local cfg      = getSandboxCFG()
    local elapsed  = getGameTime():getWorldAgeHours() - md[SU.MD.FRENZY_END_HOUR]
    local progress = math.min(elapsed / cfg.FRENZY_RESTORE_HOURS, 1.0)
    local penalty  = cfg.FRENZY_PENALTY

    local stats  = player:getStats()
    local realF  = md[SU.MD.FRENZY_REAL_FATIGUE]  or 0
    local realE  = md[SU.MD.FRENZY_REAL_ENDUR]    or 1
    local realP  = md[SU.MD.FRENZY_REAL_PAIN]     or 0
    local fixedF = md[SU.MD.FRENZY_FIXED_FATIGUE] or realF
    local fixedE = md[SU.MD.FRENZY_FIXED_ENDUR]   or realE

    -- Alvos penalizados: fatigue/pain sobem, endurance desce
    local targetF = math.min(realF * (1 + penalty), 1)
    local targetE = math.max(realE * (1 - penalty), 0)
    local targetP = math.min(realP * (1 + penalty), 1)

    stats:set(CharacterStat.FATIGUE,   math.max(0, math.min(fixedF + (targetF - fixedF) * progress, 1)))
    stats:set(CharacterStat.ENDURANCE, math.max(0, math.min(fixedE + (targetE - fixedE) * progress, 1)))
    stats:set(CharacterStat.PAIN,      math.max(0, math.min(targetP * progress, 1)))

    -- Fadiga muscular (stiffness): mesma interpolação de fixed(0) -> alvo penalizado, por parte do corpo.
    local realStiffness = md[MD_FRENZY_REAL_STIFFNESS]
    if realStiffness then
        forEachBodyPart(player, function(part, i)
            local real   = realStiffness[i] or 0
            local target = math.min(real * (1 + penalty), 100)
            part:setStiffness(math.max(0, math.min(target * progress, 100)))
        end)
    end

    if progress >= 1.0 then
        md[SU.MD.FRENZY_RESTORE_DONE]  = true
        md[SU.MD.FRENZY_REAL_FATIGUE]  = nil
        md[SU.MD.FRENZY_REAL_ENDUR]    = nil
        md[SU.MD.FRENZY_REAL_PAIN]     = nil
        md[SU.MD.FRENZY_FIXED_FATIGUE] = nil
        md[SU.MD.FRENZY_FIXED_ENDUR]   = nil
        md[SU.MD.FRENZY_END_HOUR]      = nil
        md[MD_FRENZY_REAL_STIFFNESS]   = nil
        if isServer() then player:transmitModData() end
    end
end

-- Escreve os dados de início do frenzy no modData e aplica os stats iniciais.
-- Retorna false se não puder ativar (já ativo, cooldown ou thresholds não atingidos).
local function activateFrenzyState(player)
    if SU.IsFrenzyActive(player) then return false end
    if isOnCooldown(player) then return false end

    local cfg       = getSandboxCFG()
    local stats     = player:getStats()
    local fatigue   = stats:get(CharacterStat.FATIGUE)   or 0
    local endurance = stats:get(CharacterStat.ENDURANCE) or 1
    local pain      = stats:get(CharacterStat.PAIN)      or 0

    if fatigue <= cfg.FRENZY_FATIGUE_THRESHOLD and endurance >= cfg.FRENZY_ENDURANCE_THRESHOLD then
        return false
    end

    local md = player:getModData()
    md[SU.MD.FRENZY_ACTIVE]        = true
    md[SU.MD.FRENZY_START_HOUR]    = getGameTime():getWorldAgeHours()
    md[SU.MD.FRENZY_REAL_FATIGUE]  = fatigue
    md[SU.MD.FRENZY_REAL_ENDUR]    = endurance
    md[SU.MD.FRENZY_REAL_PAIN]     = pain
    md[SU.MD.FRENZY_FIXED_FATIGUE] = 0
    md[SU.MD.FRENZY_FIXED_ENDUR]   = 1
    md[SU.MD.FRENZY_END_HOUR]      = nil
    md[SU.MD.FRENZY_RESTORE_DONE]  = false

    -- Fadiga muscular (stiffness): snapshot por parte do corpo antes de zerar tudo.
    local stiffnessSnapshot = {}
    forEachBodyPart(player, function(part, i)
        stiffnessSnapshot[i] = part:getStiffness()
    end)
    md[MD_FRENZY_REAL_STIFFNESS] = stiffnessSnapshot
    setAllStiffness(player, 0)

    stats:set(CharacterStat.FATIGUE,   0)
    stats:set(CharacterStat.ENDURANCE, 1)
    stats:set(CharacterStat.PAIN,      0)

    syncStats(player)
    return true
end

-- Escreve os dados de encerramento do frenzy no modData e inicia o cooldown.
local function endFrenzyState(player)
    if not SU.IsFrenzyActive(player) then return end
    local currentHour = getGameTime():getWorldAgeHours()
    local md = player:getModData()
    md[SU.MD.FRENZY_ACTIVE]       = false
    md[SU.MD.FRENZY_END_HOUR]     = currentHour
    md[SU.MD.FRENZY_RESTORE_DONE] = false
    md[SU.MD.COOLDOWN_START]      = currentHour
end

-- Armazena o dano base da arma no modData na primeira vez que é chamado.
local function getOrStoreBaseDamage(weapon)
    if not SU.IsHandWeapon(weapon) then return nil, nil end
    local md = weapon:getModData()
    if not md.baseMinDmg then
        md.baseMinDmg = weapon:getMinDamage()
        md.baseMaxDmg = weapon:getMaxDamage()
    end
    return md.baseMinDmg, md.baseMaxDmg
end

-- Restaura o dano original da arma e limpa o modData.
local function cleanWeaponModData(weapon)
    if not SU.IsHandWeapon(weapon) then return end
    local md = weapon:getModData()
    if md.baseMinDmg then
        weapon:setMinDamage(md.baseMinDmg)
        weapon:setMaxDamage(md.baseMaxDmg)
        md.baseMinDmg = nil
        md.baseMaxDmg = nil
    end
end

local function syncWeapon(player, weapon)
    if not SU.IsHandWeapon(weapon) then return end
    if isServer() then
        syncHandWeaponFields(player, weapon)
        syncItemModData(player, weapon)
    end
end

local function cleanAndSyncWeapon(player, weapon)
    cleanWeaponModData(weapon)
    syncWeapon(player, weapon)
end

local function restoreWeaponBaseDamage(player)
    local weapon = player:getPrimaryHandItem()
    if not SU.IsHandWeapon(weapon) then return end
    if weapon:isRanged() then return end
    cleanAndSyncWeapon(player, weapon)
end

local function activateFrenzy(player)
    local cfg = getSandboxCFG()
    if not cfg.ALLOW_FRENZY then return end
    local activated = activateFrenzyState(player)
    if not activated then return end

    if isServer() then
        player:transmitModData()
    end

    syncStats(player)

    if isServer() then
        sendServerCommand(player, "PK42", "FrenzyStarted", {})
    else
        -- SP: dispara evento customizado diretamente para PK42SpeechControl
        triggerEvent("OnFrenzyStart", player)
    end
end

local function endFrenzy(player)
    endFrenzyState(player)
    if isServer() then
        player:transmitModData()
        sendServerCommand(player, "PK42", "FrenzyEnded", {})
    else
        triggerEvent("OnFrenzyEnd", player)
    end
end

-- verifica se o jogador consumiu carne suficiente para desbloquear a trait Cannibalist, e concede a trait se necessário.
local function checkCannibalUnlock(player)
    if not SU.hasPsychopathTrait(player) then return end
    if SU.hasCannibalistTrait(player) then return end

    local cfg = getSandboxCFG()
    local level = player:getPerkLevel(Perks.Insanity)
    if level < cfg.CANNIBAL_UNLOCK_LEVEL then return end

    local totalMeat = player:getModData()[SU.MD.TOTAL_MEAT] or 0
    if totalMeat < cfg.CANNIBAL_MEAT_THRESHOLD then return end

    PK42ServerLogic.AcquireTrait(player, { trait = "pk42:cannibalist" })
end

-- Tabela de handlers indexados pelo nome do comando recebido via OnClientCommand
local ClientCommandHandlers = {}

ClientCommandHandlers["DrankAlcohol"] = function(player, args)
    local md = player:getModData()
    md[SU.MD.LAST_DRANK_HOUR] = args.hour or getGameTime():getWorldAgeHours()
    if isServer() then player:transmitModData() end
end

-- Detecta se um IsoZombie e um bandit NPC via textura de skin.
local function PK42IsBanditZombie(zombie)
    return SU.IsBanditNPC(zombie)
end

--[[ Marca NPC bandit no ModData.
-- aqui apenas para referência, não está mais sendo utilizada a marcação como moddata
-- A ideia central agora é apenas ler se o isoZombie é um NPC bandit através da textura
local function PK42BanditMark(zombie)
    if isClient() then return end
    if PK42IsBanditZombie(zombie) then
        local md = zombie:getModData()
        if md.PK42_isBandit ~= true then
            md.PK42_isBandit = true
            zombie:transmitModData()
        end
    end
end]]

local function onClientCommand(module, command, player, args)
    if module ~= "PK42" then return end
    local handler = ClientCommandHandlers[command]
    if handler then
        handler(player, args)
    end
end

-- OnHitZombie
local function onHitZombie(zombie, attacker, bodyPart, weapon)
    if isClient() then return end
    if not attacker then return end
    if not instanceof(attacker, "IsoPlayer") then return end

    if not SU.hasPsychopathTrait(attacker) then return end

    --PK42BanditMark(zombie)
    
    local stats = attacker:getStats()
    stats:add(CharacterStat.UNHAPPINESS, -0.40)
    stats:add(CharacterStat.BOREDOM,     -0.10)
    stats:add(CharacterStat.STRESS,      -0.10)
    applyNicotineRelief(attacker, stats, 0.10)

    if SU.IsHandWeapon(weapon) and not weapon:isRanged() and not SU.IsBareHands(weapon) then
        local streak = SU.GetStreak(attacker)
        local bonus  = PK42GetStreakDamageBonus(streak)
        local cfg    = getSandboxCFG()

        if cfg.ENABLE_FRENZY_DAMAGE_BONUS and SU.IsFrenzyActive(attacker) then
            local baseMin, baseMax = getOrStoreBaseDamage(weapon)
            if baseMin and baseMax then
                weapon:setMinDamage(baseMin * (1 + bonus))
                weapon:setMaxDamage(baseMax * (1 + bonus))
                syncWeapon(attacker, weapon)
            end
        end

        if streak >= cfg.FRENZY_STREAK_THRESHOLD then
            activateFrenzy(attacker)
        end
    end

    syncStats(attacker)
end

-- OnZombieDead
local function onZombieDead(zombie)
    if isClient() then return end
    local killer = zombie:getAttackedBy()
    if not killer then return end
    if not instanceof(killer, "IsoPlayer") then return end
    if not SU.hasPsychopathTrait(killer) then return end

    -- Detecção de bandit
    local isBandit = PK42IsBanditZombie(zombie)
    --print("PK42: Zombie killed by player " .. killer:getUsername() .. (isBandit and " (bandit)" or ""))
    local md       = zombie:getModData()

    local weapon  = killer:getPrimaryHandItem()
    local isMelee = SU.IsHandWeapon(weapon)
                 and not weapon:isRanged()
                 and not SU.IsBareHands(weapon)

    local cfg    = getSandboxCFG()
    local streak = math.min(SU.GetStreak(killer) + 1, cfg.STREAK_MAX)
    SU.SetStreak(killer, streak)
    SU.SetLastKill(killer, getGameTime():getWorldAgeHours())

    if isServer() then
        killer:transmitModData()
    end

    local stats = killer:getStats()
    if SU.IsFrenzyActive(killer) then
        stats:add(CharacterStat.UNHAPPINESS, -4.00)
        stats:add(CharacterStat.BOREDOM,     -0.60)
        stats:add(CharacterStat.STRESS,      -0.40)
        applyNicotineRelief(killer, stats, 0.10)
    else
        stats:add(CharacterStat.UNHAPPINESS, -2.00)
        stats:add(CharacterStat.BOREDOM,     -0.30)
        stats:add(CharacterStat.STRESS,      -0.20)
        applyNicotineRelief(killer, stats, 0.05)
    end

    syncStats(killer)

    if isMelee then
        if isBandit then
            -- NPC humano: XP de bandit (separado de player real)
            gainNormalKillXP(killer, cfg.XP_KILL_BANDIT)
        elseif SU.IsFrenzyActive(killer) then
            gainFrenzyKillXP(killer, cfg.XP_KILL_ZOMBIE_FRENZY)
        else
            gainNormalKillXP(killer, cfg.XP_KILL_ZOMBIE)
        end
    end
end

-- Helper que itera players em SP e MP server.
local function forEachValidPlayer(callback)
    if isServer() then
        local players = getOnlinePlayers()
        if not players then return end
        for i = 0, players:size() - 1 do
            local player = players:get(i)
            if player then callback(player) end
        end
    else
        local player = getPlayer()
        if player then callback(player) end
    end
end

local restoreSyncCounter = {}

-- checa e corrige o estado da arma ao ser equipada.
local function handleEquippedWeapon(character, item)
    if isClient() then return end
    if not character then return end
    if not instanceof(character, "IsoPlayer") then return end
    if not SU.IsHandWeapon(item) then return end
    if item:isRanged() then return end

    local md      = item:getModData()
    local hasData = md.baseMinDmg ~= nil

    -- Não é psicopata: qualquer modData de bônus deve ser limpo
    if not SU.hasPsychopathTrait(character) then
        if hasData then cleanAndSyncWeapon(character, item) end
        return
    end

    local cfg         = getSandboxCFG()
    local frenzyActive = SU.IsFrenzyActive(character)

    -- Psicopata sem frenzy: limpa qualquer bônus gravado
    if not frenzyActive then
        if hasData then cleanAndSyncWeapon(character, item) end
        return
    end

    -- Psicopata em frenzy: verifica se o bônus gravado está correto
    local streak       = SU.GetStreak(character)
    local fixedBonus = PK42GetStreakDamageBonus(streak)

    if not cfg.ENABLE_FRENZY_DAMAGE_BONUS then
        -- Bônus desabilitado: limpa qualquer modData que possa ter ficado
        if hasData then cleanAndSyncWeapon(character, item) end
        return
    end

    if not hasData then
        -- Arma sem modData: grava o valor original e aplica bônus
        local baseMin = item:getMinDamage()
        local baseMax = item:getMaxDamage()
        md.baseMinDmg = baseMin
        md.baseMaxDmg = baseMax
        item:setMinDamage(baseMin * (1 + fixedBonus))
        item:setMaxDamage(baseMax * (1 + fixedBonus))
        syncWeapon(character, item)
    else
        -- Arma já tem modData: verifica se o bônus aplicado está correto.
        -- O bônus é sempre calculado sobre o valor original (baseMinDmg), não sobre o atual.
        local expectedMin = md.baseMinDmg * (1 + fixedBonus)
        local expectedMax = md.baseMaxDmg * (1 + fixedBonus)
        local curMin      = item:getMinDamage()
        local curMax      = item:getMaxDamage()

        -- Tolerância de float para comparação
        local minOk = math.abs(curMin - expectedMin) < 0.001
        local maxOk = math.abs(curMax - expectedMax) < 0.001

        if not minOk or not maxOk then
            item:setMinDamage(expectedMin)
            item:setMaxDamage(expectedMax)
            syncWeapon(character, item)
        end
    end
end

-- OnEquipPrimary: dispara em ambos, guardado por isClient() dentro de handleEquippedWeapon
local function onEquipPrimary(character, item)
    handleEquippedWeapon(character, item)
end

-- OnEquipSecondary: mesma lógica, arma secundária pode ter bônus sujo também
local function onEquipSecondary(character, item)
    handleEquippedWeapon(character, item)
end

-- OnWeaponHitCharacter
-- Aplica efeitos de stats ao atacar um player vivo.
local function onWeaponHitCharacter(attacker, target, weapon, damage)
    if isClient() then return end
    if not attacker then return end
    if not instanceof(attacker, "IsoPlayer") then return end
    if not SU.hasPsychopathTrait(attacker) then return end
    if not SU.IsHandWeapon(weapon) then return end
    if SU.IsBareHands(weapon) then return end
    if not instanceof(target, "IsoPlayer") then return end

    local stats = attacker:getStats()
    if not weapon:isRanged() then
        stats:add(CharacterStat.STRESS,      -0.20)
        stats:add(CharacterStat.UNHAPPINESS, -0.50)
        stats:add(CharacterStat.BOREDOM,     -0.20)
        applyNicotineRelief(attacker, stats, 0.20)
    else
        stats:add(CharacterStat.STRESS,      -0.10)
        stats:add(CharacterStat.UNHAPPINESS, -0.25)
        stats:add(CharacterStat.BOREDOM,     -0.10)
        applyNicotineRelief(attacker, stats, 0.10)
    end
    syncStats(attacker)
end

-- OnCharacterDeath: concede XP quando um player é morto por outro player psicopata.
-- OnCharacterDeath dispara para qualquer personagem (zombies, animals, players),
-- filtramos apenas IsoPlayer como alvo
local function onCharacterDeath(character)
    if isClient() then return end
    if not instanceof(character, "IsoPlayer") then return end

    local killer = character:getAttackedBy()
    if not killer then return end
    if not instanceof(killer, "IsoPlayer") then return end
    if not SU.hasPsychopathTrait(killer) then return end

    local stats = killer:getStats()
    stats:add(CharacterStat.UNHAPPINESS, -40.00)
    stats:add(CharacterStat.BOREDOM,     -0.80)
    stats:add(CharacterStat.STRESS,      -0.60)
    applyNicotineRelief(killer, stats, 0.40)
    syncStats(killer)

    gainNormalKillXP(killer, getSandboxCFG().XP_KILL_PLAYER)
end

local function onEveryOneMinute()
    if isClient() then return end

    forEachValidPlayer(function(player)
        if not SU.hasPsychopathTrait(player) then return end

        local cfg         = getSandboxCFG()
        local streak      = SU.GetStreak(player)
        local lastKill    = SU.GetLastKill(player)
        local currentHour = getGameTime():getWorldAgeHours()

        -- Streak decay e encerramento de frenzy por timeout de kills.
        if streak > 0 and lastKill then
            local minutesSinceKill = (currentHour - lastKill) * 60

            if minutesSinceKill >= cfg.STREAK_ZERO_INTERVAL then
                -- Jogador ficou 10+ minutos sem matar: zera tudo e encerra frenzy.
                SU.SetStreak(player, 0)
                streak = 0
                restoreWeaponBaseDamage(player)
                if SU.IsFrenzyActive(player) then endFrenzy(player) end
                if isServer() then player:transmitModData() end

            elseif minutesSinceKill >= cfg.STREAK_DECAY_INTERVAL then
                -- A cada tick com 2+ minutos sem matar: decai 1 ponto de streak.
                local newStreak = math.max(streak - 1, 0)
                if newStreak ~= streak then
                    SU.SetStreak(player, newStreak)
                    streak = newStreak
                    if isServer() then player:transmitModData() end
                end
            end
        end

        -- Controle de frenzy
        if SU.IsFrenzyActive(player) then
            local startHour   = player:getModData()[SU.MD.FRENZY_START_HOUR]
            local frenzyHours = startHour and (currentHour - startHour) or 0
            if frenzyHours >= cfg.FRENZY_MAX_HOURS then
                endFrenzy(player)
            else
                applyFrenzyHold(player)
                syncStats(player)
            end
        else
            applyFrenzyRestore(player)
            local md = player:getModData()
            if md[SU.MD.FRENZY_END_HOUR] ~= nil then
                syncPlayerStats(player, MASK_RESTORE)
            elseif restoreSyncCounter[tostring(player:getOnlineID())] then
                restoreSyncCounter[tostring(player:getOnlineID())] = nil
                syncStats(player)
            end

        end

        -- Stress por falta de kills
        if lastKill then
            local hoursSinceKill = currentHour - lastKill
            if hoursSinceKill >= cfg.BOREDOM_THRESHOLD_HOURS then
                player:getStats():add(CharacterStat.STRESS, 0.1)
                syncStats(player)
            end
        end

        -- Cannibal unlock
        checkCannibalUnlock(player)
        -- Expira a janela de debuff pós-álcool após ALCOHOL_DEBUFF_HOURS
        local md = player:getModData()
        if md[SU.MD.LAST_DRANK_HOUR] then
            local elapsed = currentHour - md[SU.MD.LAST_DRANK_HOUR]
            if elapsed >= cfg.ALCOHOL_DEBUFF_HOURS then
                md[SU.MD.LAST_DRANK_HOUR] = nil
                if isServer() then player:transmitModData() end
            end
        end
    end)
end

-- Registro de eventos
Events.OnClientCommand.Add(onClientCommand)
--
Events.OnHitZombie.Add(onHitZombie)
--
Events.OnZombieDead.Add(onZombieDead)
Events.OnCharacterDeath.Add(onCharacterDeath)
Events.EveryOneMinute.Add(onEveryOneMinute)
Events.OnEquipPrimary.Add(onEquipPrimary)
Events.OnEquipSecondary.Add(onEquipSecondary)
Events.OnWeaponHitCharacter.Add(onWeaponHitCharacter)

-- Export global para uso externo
CheckCannibalUnlock = checkCannibalUnlock