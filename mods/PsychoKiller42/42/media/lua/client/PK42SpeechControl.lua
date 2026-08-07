-- PK42SpeechControl.lua (Client)
-- Toda a lógica de fala do MOD.
local SU = require "Utils/PK42SharedUtils"

if isServer() then return end

local PKSpeechControl = {}

-- Declara evento customizado para SP
if not Events.OnFrenzyStart then
    LuaEventManager.AddEvent("OnFrenzyStart")
end

-- Chave de ModData necessária localmente
local MD_FRENZY_ACTIVE = "frenzyActive"

-- ============================================================
-- Sistema de Cooldown de Falas
-- ============================================================
local FIXED_NO_COOLDOWN = {
    trait = true,
}

-- Armazena o timestamp (ms) da última fala por categoria
local lastSpeechTime = {}

--- Verifica se o cooldown de uma categoria já passou, sem efeitos colaterais.
---@param category string
---@return boolean
local function isCooldownReady(category)
    if FIXED_NO_COOLDOWN[category] then return true end

    local cooldown = PK42Options.getSpeechCooldownMs()
    if cooldown == 0 then return true end

    local now  = getTimestampMs()
    local last = lastSpeechTime[category] or -1

    return last < 0 or (now - last) >= cooldown
end

--- Registra o timestamp de uma fala que de fato aconteceu, iniciando o cooldown da categoria.
---@param category string
local function markSpoke(category)
    lastSpeechTime[category] = getTimestampMs()
end

-- Helpers
local function rollSpeech(key, defaultChance)
    if not PK42Options.isSpeechEnabled() then return false end
    local chance = PK42Options.getSpeechChance(key)
    if chance == nil then chance = defaultChance or 100 end
    return ZombRand(100) < chance
end

-- Exporta para uso externo se necessário
PKSpeechControl.rollSpeech = rollSpeech

-- Feedback do servidor (MP)
local function onServerCommand(module, command, args)
    if module ~= "PK42" then return end

    local player = getPlayer()
    if not player then return end

    if command == "TraitAcquired" then
        if args and args.trait == "pk42:cannibalist" then
            if isCooldownReady("trait") and rollSpeech("speechChanceCannibalTrait", 100) then
                player:Say(getText("IGUI_PlayerText_BecameCannibalist"))
                markSpoke("trait")
            end
        end

    elseif command == "FrenzyStarted" then
        if isCooldownReady("frenzy") and rollSpeech("speechChanceFrenzy", 100) then
            player:Say(getText("IGUI_PlayerText_OnFrenzyStart" .. ZombRand(1, 12)))
            markSpoke("frenzy")
        end

    elseif command == "ButcherCorpseFeedback" then
        -- Expansível aqui se necessário
    end
end

-- Fala ao acertar zumbi (só durante frenzy)
-- Cooldown previne spam com multihit ou espingarda
local function onHitZombieClientSay(zombie, attacker, bodyPart, weapon)
    if not attacker then return end
    if not instanceof(attacker, "IsoPlayer") then return end
    if attacker ~= getPlayer() then return end
    if not SU.hasPsychopathTrait(attacker) then return end
    if SU.IsBareHands(weapon) then return end

    local md = attacker:getModData()
    if md and md[MD_FRENZY_ACTIVE] == true then
        if isCooldownReady("hitZombie") and rollSpeech("speechChanceHitZombie", 1) then
            attacker:Say(getText("IGUI_PlayerText_OnHitZombie" .. ZombRand(1, 21)))
            markSpoke("hitZombie")
        end
    end
end

-- Fala ao matar zumbi
-- Cooldown previne spam ao matar vários zumbis simultaneamente
local function onZombieDeadClientSay(zombie)
    local killer = zombie:getAttackedBy()
    if not killer then return end
    if killer ~= getPlayer() then return end
    if not SU.hasPsychopathTrait(killer) then return end

    if isCooldownReady("killZombie") and rollSpeech("speechChanceKillZombie", 5) then
        killer:Say(getText("IGUI_PlayerText_OnKillZombie" .. ZombRand(1, 21)))
        markSpoke("killZombie")
    end
end

-- Fala ao matar jogador
local function onWeaponHitCharacterClientSay(attacker, target, weapon, damage)
    if not attacker then return end
    if attacker ~= getPlayer() then return end
    if not SU.hasPsychopathTrait(attacker) then return end
    if not instanceof(target, "IsoPlayer") then return end

    if target:isDead() then
        if isCooldownReady("killPlayer") and rollSpeech("speechChanceKillPlayer", 100) then
            attacker:Say(getText("IGUI_PlayerText_OnKillPlayer" .. ZombRand(1, 21)))
            markSpoke("killPlayer")
        end
    end
end

-- Fala ao entrar em frenzy (SP via evento customizado)
local function onFrenzyStart(player)
    if not player then return end
    if isCooldownReady("frenzy") and rollSpeech("speechChanceFrenzy", 100) then
        player:Say(getText("IGUI_PlayerText_OnFrenzyStart" .. ZombRand(1, 12)))
        markSpoke("frenzy")
    end
end

-- Registro de eventos
Events.OnServerCommand.Add(onServerCommand)
Events.OnHitZombie.Add(onHitZombieClientSay)
Events.OnZombieDead.Add(onZombieDeadClientSay)
Events.OnWeaponHitCharacter.Add(onWeaponHitCharacterClientSay)
Events.OnFrenzyStart.Add(onFrenzyStart)

return PKSpeechControl