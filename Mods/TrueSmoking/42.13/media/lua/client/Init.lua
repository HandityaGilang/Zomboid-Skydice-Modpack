--[[
    Init.lua - Client-Side Initialization

    Handles player creation events, loads sandbox options,
    and registers event handlers. This is the main client entry point.
]]

require 'ISUI/ISInventoryPaneContextMenu'
require 'MF_ISMoodle'
require 'Core'
require 'Data'
require 'Visuals'
require 'Input'
require 'Network'
require 'DebugUI'

--------------------------------------------------------------------------------
-- Player Initialization
--------------------------------------------------------------------------------

--- Initialize TrueSmoking for a player
-- Called on OnCreatePlayer event
-- @param playerNum number Player index
-- @param player IsoPlayer
function TrueSmoking.initPlayer(playerNum, player)
    -- Ensure moodles are created for this player's session (fixes MP reconnect issues)
    if MF and MF.createMoodle then
        MF.createMoodle('TS_Smoking_New')
        MF.createMoodle('TS_Smoking_Old')
        MF.createMoodle('TS_Nicotine')
        MF.createMoodle('TS_Nicotine_Old')
    end

    local data = TrueSmoking.Data.getSmoking(player)
    local ref = TrueSmoking.getPlayerRef(player)

    -- Reset state
    data.eatSound = ''
    data.lightingEatSound = ''
    data.isSmoking = false

    ref.smokable = { smokeLit = false }

    -- Compatibility with SmokingSoundsOverhaul
    TrueSmoking.lightTime = getActivatedMods():contains('\\SmokingSoundsOverhaul') and 460 or 220

    -- Register per-player event handlers
    ref.keyHandler = function(key)
        TrueSmoking.onKeyPressed(key)
    end

    ref.contextHandler = function(pNum, context, items)
        TrueSmoking.onContextMenu(pNum, context, items)
    end

    Events.OnKeyStartPressed.Add(ref.keyHandler)
    Events.OnFillInventoryObjectContextMenu.Add(ref.contextHandler)

    -- Initialize nicotine system
    if TrueSmoking.Options.UseNicotineSystem and NicotineSystem then
        NicotineSystem:initialize(player)
        NicotineSystem:UpdateDynamicConfig(player)
    end

    -- Sync initial state to server
    sendClientCommand(player, 'TrueSmoking', 'updatePlayerData', {
        isSmoking = false,
        eatSound = '',
        lightingEatSound = '',
    })

    -- Request server-side state validation (clears stale isSmoking from previous session)
    sendClientCommand(player, 'TrueSmoking', 'validateState', {})
end

--- Clean up when player dies
-- @param player IsoPlayer
function TrueSmoking.cleanupPlayer(player)
    local ref = TrueSmoking.getPlayerRef(player)

    if ref.smokable and ref.smokable.smokeLit then
        ref.smokable:stop()
    end

    if ref.keyHandler then
        Events.OnKeyStartPressed.Remove(ref.keyHandler)
        ref.keyHandler = nil
    end

    if ref.contextHandler then
        Events.OnFillInventoryObjectContextMenu.Remove(ref.contextHandler)
        ref.contextHandler = nil
    end
end

--------------------------------------------------------------------------------
-- Sandbox Options Loading (now in shared/Core.lua for MP server compatibility)
--------------------------------------------------------------------------------

function TrueSmoking.loadSandboxOptions()
    -- Call shared implementation from Core.lua
    if not SandboxVars or not SandboxVars.TrueSmoking then return end
    
    local sandbox = SandboxVars.TrueSmoking
    local opt = TrueSmoking.Options

    -- Core options
    opt.ManageHeadGear = sandbox.ManageHeadGear
    opt.SmokeRelighting = sandbox.SmokeRelighting
    opt.UseNewMoodle = sandbox.UseNewMoodle

    -- Dropping options
    opt.Dropping = sandbox.Dropping or true
    opt.DroppingChanceSmoker = (sandbox.DropChanceSmoker or 6) / 100
    opt.DroppingChanceNonSmoker = (sandbox.DropChanceNonSmoker or 35) / 100

    -- Coughing options
    opt.Coughing = sandbox.Coughing
    opt.CoughingChanceSmoker = (sandbox.CoughingChanceSmoker or 4) / 100
    opt.CoughingChanceNonSmoker = (sandbox.CoughingChanceNonSmoker or 15) / 100

    -- Nicotine system options
    opt.UseNicotineSystem = sandbox.UseNicotineSystem
    opt.DynamicSmokerTrait = sandbox.DynamicSmokerTrait
    opt.DaysToDetox = sandbox.DaysToDetox or 30
    opt.DaysToAddiction = sandbox.DaysToAddiction or 42
    opt.DaysToPeakWithdrawal = sandbox.DaysToPeakWithdrawal or 3
    opt.SmokerTraitDecayMultiplier = sandbox.SmokerTraitDecayMultiplier or 0.6

    -- Speed/strength modifiers
    local smokingSpeed = sandbox.SmokingSpeed or 1.0
    local puffStrength = sandbox.PuffStrength or 1.0
    local movementBurn = sandbox.MovementBurn or 1.0
    local idleBurnOut = sandbox.IdleBurnOut or 1.0
    local effectMult = sandbox.EffectMultiplier or 1.0

    -- Global burn parameters
    opt.Global = {
        burnMin = 0.000125 * smokingSpeed,
        burnMax = 0.000300 * smokingSpeed,
        burnSpeed = 0.0025,
        burnSpeedDecay = 0.10,
        puffFactor = 1.35 * puffStrength,
        walkingFactor = 1.0 + (movementBurn - 1) * 0.5,
        runningFactor = 1.15 + (movementBurn - 1) * 0.8,
        sprintingFactor = 1.35 + (movementBurn - 1) * 1.2,
        decayRate = 0.995 + (0.998 - 0.995) * (1 - idleBurnOut),
    }

    -- Category multipliers
    opt.Category = {
        Cigarette = smokingSpeed,
        RolledCigarette = smokingSpeed * 0.9,
        Cigarillo = smokingSpeed * 0.75,
        Cigar = smokingSpeed * 0.50,
        Pipe = smokingSpeed * 0.40,
        Can = smokingSpeed * 0.60,
    }

    -- Build category configs
    local lengthRatios = {
        Cigarette = 1.0,
        RolledCigarette = 1.0,
        Cigarillo = 1.5,
        Cigar = 3.0,
        Pipe = 2.5,
        Can = 1.25,
    }

    opt.SmokeLength = 1.0

    for catName, ratio in pairs(lengthRatios) do
        local mult = opt.Category[catName] or 1.0
        opt[catName] = {
            length = opt.SmokeLength * ratio,
            burnMin = opt.Global.burnMin * mult,
            burnMax = opt.Global.burnMax * mult,
            burnSpeed = opt.Global.burnSpeed,
            burnSpeedDecay = opt.Global.burnSpeedDecay,
            decayRate = opt.Global.decayRate,
            effectMultiplier = ratio * effectMult,
            puffFactor = opt.Global.puffFactor,
            walkingFactor = opt.Global.walkingFactor,
            runningFactor = opt.Global.runningFactor,
            sprintingFactor = opt.Global.sprintingFactor,
        }
    end

    -- Nicotine system options
    opt.UseNicotineSystem = sandbox.UseNicotineSystem
    opt.DynamicSmokerTrait = sandbox.DynamicSmokerTrait

    if NicotineSystem then
        local nic = NicotineSystem.Options
        nic.DaysToAddiction = sandbox.DaysToAddiction
        nic.DaysToDetox = sandbox.DaysToDetox
        nic.DaysToPeakWithdrawal = sandbox.DaysToPeakWithdrawal
        nic.SmokerTraitDecayMultiplier = sandbox.SmokerTraitDecayMultiplier
    end
end

--------------------------------------------------------------------------------
-- Item Replacement on Use
--------------------------------------------------------------------------------

--- Add replacement item when smoke is consumed
-- @param player IsoPlayer
function TrueSmoking.addOnUseItem(player)
    local ref = TrueSmoking.getPlayerRef(player)
    if not ref or not ref.smokable then return end

    local fullType = ref.smokable.fullType
    local replaceItem = ref.smokable.replaceOnUse
    if not replaceItem or replaceItem == '' then return end

    local base = fullType:match('^[^.]+')
    if base then
        local newItem = base .. '.' .. replaceItem
        player:getInventory():AddItem(newItem)
        ref.smokable.replaceOnUse = ''
    end
end

--------------------------------------------------------------------------------
-- Event Registration
--------------------------------------------------------------------------------

Events.OnCreatePlayer.Add(TrueSmoking.initPlayer)
Events.OnPlayerDeath.Add(TrueSmoking.cleanupPlayer)
Events.OnInitGlobalModData.Add(TrueSmoking.loadSandboxOptions)
