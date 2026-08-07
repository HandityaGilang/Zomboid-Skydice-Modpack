local SU = require "Utils/PK42SharedUtils"
-- PK42TraitEffects_Client.lua (Client)
-- Recebe comandos do server via OnServerCommand e aplica efeitos locais.

local function getSandboxCFG()
    local opts = SandboxVars.PK42
    return {
        ENABLE_FRENZY_SPEED_BONUS  = opts and opts.EnableFrenzySpeedBonus ~= false,
        FRENZY_COMBAT_SPEED_BONUS  = 1 + ((opts and opts.FrenzyCombatSpeedBonus or 50) / 100),
        FRENZY_MOVE_SPEED_BONUS    = 1 + ((opts and opts.FrenzyMoveSpeedBonus   or 10) / 100),
    }
end

-- Handlers de OnServerCommand
local ServerCommandHandlers = {}

-- FrenzyStarted: dispara falas.
ServerCommandHandlers["FrenzyStarted"] = function(args)
    local player = getPlayer()
    if not player then return end
    triggerEvent("OnFrenzyStart", player)
end

-- FrenzyEnded: dispara efeitos visuais/sonoros locais.
ServerCommandHandlers["FrenzyEnded"] = function(args)
    local player = getPlayer()
    if not player then return end
    triggerEvent("OnFrenzyEnd", player)
end

local function onServerCommand(module, command, args)
    if module ~= "PK42" then return end
    local handler = ServerCommandHandlers[command]
    if handler then handler(args) end
end

-- Aplica CombatSpeed boost durante o frenzy.
-- Chamado a cada swing pois o valor é resetado para o padrão do XML entre swings.
local function onWeaponSwing(character, weapon)
    if not character then return end
    if not instanceof(character, "IsoPlayer") then return end
    if not SU.hasPsychopathTrait(character) then return end
    if not SU.IsHandWeapon(weapon) or weapon:isRanged() or SU.IsBareHands(weapon) then return end
    if not SU.IsFrenzyActive(character) then return end

    local cfg = getSandboxCFG()
    if not cfg.ENABLE_FRENZY_SPEED_BONUS then return end

    local base    = character:getVariableFloat("CombatSpeed", 1.0)
    local boosted = base * cfg.FRENZY_COMBAT_SPEED_BONUS
    character:setVariable("CombatSpeed", boosted)
end

-- Aplica WalkSpeed boost durante o frenzy.
local function onPlayerUpdate(player)
    if not SU.hasPsychopathTrait(player) then return end
    if not SU.IsFrenzyActive(player) then return end

    local cfg = getSandboxCFG()
    if not cfg.ENABLE_FRENZY_SPEED_BONUS then return end

    if player:isRunning() or player:isSprinting() then
        local currentWalkSpeed = player:getVariableFloat("WalkSpeed", 0.0)
        local newSpeed = math.min(currentWalkSpeed * cfg.FRENZY_MOVE_SPEED_BONUS, 1.0)
        player:setVariable("WalkSpeed", newSpeed)
    end
end

-- Registro de eventos
Events.OnServerCommand.Add(onServerCommand)
Events.OnWeaponSwing.Add(onWeaponSwing)
Events.OnPlayerUpdate.Add(onPlayerUpdate)