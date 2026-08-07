-- PK42ModOptions.lua (Client)
-- Opções de fala do mod

require "PZAPI/ModOptions"

local MOD_ID   = "PsychoKiller42"
local MOD_NAME = "Psychopath Trait"

PK42Options = {}

local function initOptions()
    local options = PZAPI.ModOptions:create(MOD_ID, MOD_NAME)

    options:addTickBox("enableSpeech",         getText("Sandbox_PK42_EnablePlayerSpeech"),        true,  getText("Sandbox_PK42_EnablePlayerSpeech_tooltip"))
    options:addSlider("speechCooldown",         getText("Sandbox_PK42_SpeechCooldown"),            0, 60,  1, 10,  getText("Sandbox_PK42_SpeechCooldown_tooltip"))
    options:addSlider("speechChanceHitZombie",  getText("Sandbox_PK42_SpeechChanceOnHitZombie"),   0, 100, 1, 1,   getText("Sandbox_PK42_SpeechChanceOnHitZombie_tooltip"))
    options:addSlider("speechChanceKillZombie", getText("Sandbox_PK42_SpeechChanceOnKillZombie"),  0, 100, 1, 5,   getText("Sandbox_PK42_SpeechChanceOnKillZombie_tooltip"))
    options:addSlider("speechChanceKillPlayer", getText("Sandbox_PK42_SpeechChanceOnKillPlayer"),  0, 100, 1, 100, getText("Sandbox_PK42_SpeechChanceOnKillPlayer_tooltip"))
    options:addSlider("speechChanceFrenzy",     getText("Sandbox_PK42_SpeechChanceOnFrenzyStart"), 0, 100, 1, 100, getText("Sandbox_PK42_SpeechChanceOnFrenzyStart_tooltip"))

    PK42Options.options = options
end

function PK42Options.isSpeechEnabled()
    if not PK42Options.options then return true end
    local opt = PK42Options.options:getOption("enableSpeech")
    return opt and opt:getValue()
end

function PK42Options.getSpeechChance(key)
    if not PK42Options.options then return 100 end
    local opt = PK42Options.options:getOption(key)
    return opt and opt:getValue() or 100
end

--- Retorna o cooldown de fala em milissegundos.
--- O slider armazena segundos (0–60); convertemos para ms aqui.
function PK42Options.getSpeechCooldownMs()
    if not PK42Options.options then return 10000 end
    local opt = PK42Options.options:getOption("speechCooldown")
    local seconds = opt and opt:getValue() or 10
    return seconds * 1000
end

Events.OnGameBoot.Add(initOptions)