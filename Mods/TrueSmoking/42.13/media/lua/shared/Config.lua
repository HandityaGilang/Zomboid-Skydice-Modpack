--[[
    Config.lua - Smokable Object Definitions and Script Fixes
    
    Defines all smokable items with their burn rates, visual items,
    and nicotine content. Also patches vanilla item scripts.
]]

require 'Core'

--------------------------------------------------------------------------------
-- Smokable Object Registration
--------------------------------------------------------------------------------

Events.OnCreatePlayer.Add(function()
    --[[
        Each smokable object defines settings and properties for items hooked into TrueSmoking.
        
        Properties:
        - visualItem: Face mask to display ('Mask_Cigarette', 'Mask_Cigar', etc. or false)
        - smokeLength: Duration in ticks before depleted
        - burnMin/burnMax: Burn rate range based on player state
        - burnSpeed: Acceleration toward burnMax when puffing
        - burnSpeedDecay: Decay rate after reaching burnMax
        - decayRate: Passive decay when idle
        - effectMultiplier: Multiplier for stat effects
        - nicotineContent: Amount affecting addiction system
        - walkingFactor/runningFactor/sprintingFactor/puffFactor: Burn rate multipliers
        - conditions: Behavior flags (idle, walking, running, sprinting, strafing, canDrop)
    ]]
    
    local opts = TrueSmoking.Options
    
    local smokableObjects = {
        ['Base.CigaretteSingle'] = {
            visualItem = 'Mask_Cigarette',
            conditions = { idle = true, walking = true, running = true, sprinting = true, strafing = true, canDrop = true },
            smokeLength = opts.Cigarette.length,
            burnMin = opts.Cigarette.burnMin,
            burnMax = opts.Cigarette.burnMax,
            burnSpeed = opts.Cigarette.burnSpeed,
            burnSpeedDecay = opts.Cigarette.burnSpeedDecay,
            decayRate = opts.Cigarette.decayRate,
            effectMultiplier = opts.Cigarette.effectMultiplier,
            walkingFactor = opts.Cigarette.walkingFactor,
            runningFactor = opts.Cigarette.runningFactor,
            sprintingFactor = opts.Cigarette.sprintingFactor,
            puffFactor = opts.Cigarette.puffFactor,
            nicotineContent = 100,
        },
        ['Base.CigaretteRolled'] = {
            visualItem = 'Mask_Cigarette',
            conditions = { idle = true, walking = true, running = true, sprinting = true, strafing = true, canDrop = true },
            smokeLength = opts.RolledCigarette.length,
            burnMin = opts.RolledCigarette.burnMin,
            burnMax = opts.RolledCigarette.burnMax,
            burnSpeed = opts.RolledCigarette.burnSpeed,
            burnSpeedDecay = opts.RolledCigarette.burnSpeedDecay,
            decayRate = opts.RolledCigarette.decayRate,
            effectMultiplier = opts.RolledCigarette.effectMultiplier,
            walkingFactor = opts.RolledCigarette.walkingFactor,
            runningFactor = opts.RolledCigarette.runningFactor,
            sprintingFactor = opts.RolledCigarette.sprintingFactor,
            puffFactor = opts.RolledCigarette.puffFactor,
            nicotineContent = 85,
        },
        ['Base.Cigarillo'] = {
            visualItem = 'Mask_Cigarillo',
            conditions = { idle = true, walking = true, running = true, sprinting = true, strafing = true, canDrop = true },
            smokeLength = opts.Cigarillo.length,
            burnMin = opts.Cigarillo.burnMin,
            burnMax = opts.Cigarillo.burnMax,
            burnSpeed = opts.Cigarillo.burnSpeed,
            burnSpeedDecay = opts.Cigarillo.burnSpeedDecay,
            decayRate = opts.Cigarillo.decayRate,
            effectMultiplier = opts.Cigarillo.effectMultiplier,
            walkingFactor = opts.Cigarillo.walkingFactor,
            runningFactor = opts.Cigarillo.runningFactor,
            sprintingFactor = opts.Cigarillo.sprintingFactor,
            puffFactor = opts.Cigarillo.puffFactor,
            nicotineContent = 150,
        },
        ['Base.Cigar'] = {
            visualItem = 'Mask_Cigar',
            conditions = { idle = true, walking = true, running = true, sprinting = true, strafing = true, canDrop = true },
            smokeLength = opts.Cigar.length,
            burnMin = opts.Cigar.burnMin,
            burnMax = opts.Cigar.burnMax,
            burnSpeed = opts.Cigar.burnSpeed,
            burnSpeedDecay = opts.Cigar.burnSpeedDecay,
            decayRate = opts.Cigar.decayRate,
            effectMultiplier = opts.Cigar.effectMultiplier,
            walkingFactor = opts.Cigar.walkingFactor,
            runningFactor = opts.Cigar.runningFactor,
            sprintingFactor = opts.Cigar.sprintingFactor,
            puffFactor = opts.Cigar.puffFactor,
            nicotineContent = 300,
        },
        ['Base.SmokingPipe_Tobacco'] = {
            visualItem = 'Mask_Pipe',
            conditions = { idle = true, walking = true, running = true, sprinting = true, strafing = true, canDrop = true },
            smokeLength = opts.Pipe.length,
            burnMin = opts.Pipe.burnMin,
            burnMax = opts.Pipe.burnMax,
            burnSpeed = opts.Pipe.burnSpeed,
            burnSpeedDecay = opts.Pipe.burnSpeedDecay,
            decayRate = opts.Pipe.decayRate,
            effectMultiplier = opts.Pipe.effectMultiplier,
            walkingFactor = opts.Pipe.walkingFactor,
            runningFactor = opts.Pipe.runningFactor,
            sprintingFactor = opts.Pipe.sprintingFactor,
            puffFactor = opts.Pipe.puffFactor,
            nicotineContent = 350,
        },
        ['Base.CanPipe_Tobacco'] = {
            visualItem = false,
            conditions = { idle = true, walking = true, running = true, sprinting = true, strafing = true, canDrop = true },
            smokeLength = opts.Can.length,
            burnMin = opts.Can.burnMin,
            burnMax = opts.Can.burnMax,
            burnSpeed = opts.Can.burnSpeed,
            burnSpeedDecay = opts.Can.burnSpeedDecay,
            decayRate = opts.Can.decayRate,
            effectMultiplier = opts.Can.effectMultiplier,
            walkingFactor = opts.Can.walkingFactor,
            runningFactor = opts.Can.runningFactor,
            sprintingFactor = opts.Can.sprintingFactor,
            puffFactor = opts.Can.puffFactor,
            nicotineContent = 125,
        }
    }

    TrueSmoking.registerSmokables(smokableObjects)

    -- Hotkey packs for quick smoke
    TrueSmoking.hotkeyPacks = {
        ['Base.CigarettePack'] = 'TakeACigarette',
    }
end)

--------------------------------------------------------------------------------
-- Item Script Fixes
--------------------------------------------------------------------------------

local CANT_SMOKE_HEADGEAR = {
    'Hat_NBCmask_nofilter',
    'Hat_NBCmask',
    'Hat_ShemaghFull',
    'Hat_ShemaghFull_Green',
    'Hat_Spiffo',
    'Hat_ShemaghFull_Burlap',
    'Hat_ShemaghFull_Cotton',
    'Hat_HeadSack_Burlap',
    'Hat_HeadSack_Cotton',
    'Hat_MetalHelmet',
    'Hat_MetalScrapHelmet',
    'ShemaghScarfFace',
    'ShemaghScarfFace_Green',
    'WeldingMask',
    'Hat_RiotHelmet',
    'Hat_CrashHelmetFULL',
    'Hat_CrashHelmetFULL_Black',
    'Hat_DustMask',
    'Hat_GasMask',
    'Hat_GasMask_nofilter',
    'Hat_HalloweenMaskDevil',
    'Hat_HalloweenMaskMonster',
    'Hat_HalloweenMaskPumpkin',
    'Hat_HalloweenMaskSkeleton',
    'Hat_HalloweenMaskVampire',
    'Hat_HalloweenMaskWitch',
    'Hat_HockeyMask',
    'Hat_BoneMask',
    'Hat_HockeyMask_Wood',
    'Hat_HockeyMask_Metal',
    'Hat_HockeyMask_Copper',
    'Hat_HockeyMask_Gold',
    'Hat_HockeyMask_Silver',
    'Hat_HockeyMask_MetalScrap',
    'Hat_SurgicalMask',
    'Hat_BuildersRespirator',
    'Hat_BandanaMask_Green',
    'Hat_BandanaMask',
    'Hat_BandanaMaskTINT',
    'Hat_BuildersRespirator_nofilter',
}

--- Add TrueSmoking:CantSmoke tag to blocking headgear
local function fixItemTags()
    if not ScriptManager.instance then return end

    for _, itemName in ipairs(CANT_SMOKE_HEADGEAR) do
        local item = ScriptManager.instance:getItem('Base.' .. itemName)
        if item then
            local currentTags = item:getTags()
            local tagsSet = {}

            -- Add existing tags
            if currentTags and not currentTags:isEmpty() then
                for i = 0, currentTags:size() - 1 do
                    local tag = currentTags[i]
                    if tag then
                        tagsSet[tag] = true
                    end
                end
            end
            
            -- Add our tag
            tagsSet['TrueSmoking:CantSmoke'] = true
            
            -- Apply merged tags
            local mergedTags = {}
            for tag in pairs(tagsSet) do
                table.insert(mergedTags, tag)
            end
            item:DoParam('Tags = ' .. table.concat(mergedTags, ';'))
        end
    end

    -- Fix lighter use deltas
    local lighterFixes = {
        ['Base.Lighter'] = 0.05,
        ['Base.DisposableLighter'] = 0.075,
        ['Base.LighterBBQ'] = 0.0875,
    }
    
    for itemType, useDelta in pairs(lighterFixes) do
        local item = ScriptManager.instance:getItem(itemType)
        if item then
            item:DoParam('UseDelta = ' .. useDelta)
        end
    end
end

--- Fix recipe inputs/outputs for cigarette pack
local function fixRecipes()
    local recipeList = {
        ['AddACigarette'] = {
            inputs = '{ inputs { item 1 [Base.CigaretteSingle] flags[AllowFavorite;InheritFavorite], item 1 [Base.CigarettePack] mode:keep flags[AllowFavorite;InheritFavorite], } }'
        },
        ['TakeACigarette'] = {
            inputs = '{ inputs { item 1 [Base.CigarettePack] flags[AllowFavorite;InheritFavorite], } }',
            outputs = '{ outputs { item 1 Base.CigaretteSingle, } }'
        }
    }

    for recipeName, script in pairs(recipeList) do
        local recipe = getScriptManager():getCraftRecipe(recipeName)
        if recipe then
            for key, value in pairs(script) do
                if key == 'inputs' then
                    recipe:getInputs():clear()
                    recipe:Load(recipeName, value)
                elseif key == 'outputs' then
                    recipe:getOutputs():clear()
                    recipe:Load(recipeName, value)
                end
            end
        end
    end
end

Events.OnGameBoot.Add(fixItemTags)
Events.OnInitWorld.Add(fixRecipes)