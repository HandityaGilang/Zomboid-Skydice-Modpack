if getActivatedMods():contains('\\N&CsNarcotics') then
    function OnEat_WeedSmoke_OverTime(smokable)
        --Use the smokable player ref to ensure we are affecting the right local player (splitscreen)
        local player = smokable.player
        local WeedEffect = 19 --Max weed effect we can accumulate
        local PotHead = player:HasTrait("PotHead") and 216 or 100
        --This is how much of the smoke (%) is consumed per tick, scale our changes by this
        local percent = smokable.puffPercent
        if player:getModData().NnCTenMinutesPotHead == nil then
            player:getModData().NnCTenMinutesPotHead = 0
        end
        if player:getModData().NnCWeeeeedEffect == nil then
            player:getModData().NnCWeeeeedEffect = 0
        end
        if player:getModData().NnCWeeeeedEffect < WeedEffect and player:getModData().NnCWeeeeedEffect >= 0 then
            -- print('weedEfffect: ' .. player:getModData().NnCWeeeeedEffect)
            player:getModData().NnCWeeeeedEffect = player:getModData().NnCWeeeeedEffect + WeedEffect * percent;
        end
        player:getModData().NnCTenMinutesPotHead = player:getModData().NnCTenMinutesPotHead - (PotHead * percent)
    end

    function WeedSmoke_Callback(smokable)
        if smokable.item:getOnEat() == 'OnEat_WeedSmoke' then
            OnEat_WeedSmoke_OverTime(smokable)
        end
    end

    local NnC_Items = {
        'NnC.BluntAK',
        'NnC.JointAK',
        'NnC.Bong1GreenAK',
        'NnC.Bong1PurpleAK',
        'NnC.Bong1RedAK',
        'NnC.Bong2PinkAK',
        'NnC.Bong2RainbowAK',
        'NnC.Bong2RedAK',
        'NnC.BongPokeAK',
        'NnC.Pipe1GreenAK',
        'NnC.Pipe1OrangeAK',
        'NnC.Pipe1YellowAK',
        'NnC.CanPipeAK',
        'NnC.SmokingPipeAK',
        'NnC.BluntNorthernLights',
        'NnC.JointNorthernLights',
        'NnC.Bong1GreenNL',
        'NnC.Bong1PurpleNL',
        'NnC.Bong1RedNL',
        'NnC.Bong2PinkNL',
        'NnC.Bong2RainbowNL',
        'NnC.Bong2RedNL',
        'NnC.BongPokeNL',
        'NnC.Pipe1GreenNL',
        'NnC.Pipe1OrangeNL',
        'NnC.Pipe1YellowNL',
        'NnC.CanPipeNorthernLights',
        'NnC.SmokingPipeNorthernLights',
        'NnC.BluntSourDiesel',
        'NnC.JointSourDiesel',
        'NnC.Bong1GreenSD',
        'NnC.Bong1PurpleSD',
        'NnC.Bong1RedSD',
        'NnC.Bong2PinkSD',
        'NnC.Bong2RainbowSD',
        'NnC.Bong2RedSD',
        'NnC.BongPokeSD',
        'NnC.Pipe1GreenSD',
        'NnC.Pipe1OrangeSD',
        'NnC.Pipe1YellowSD',
        'NnC.CanPipeSourDiesel',
        'NnC.SmokingPipeSourDiesel',
        'NnC.BluntKief',
        'NnC.JointKief',
        'NnC.Bong1GreenKief',
        'NnC.Bong1PurpleKief',
        'NnC.Bong1RedKief',
        'NnC.Bong2PinkKief',
        'NnC.Bong2RainbowKief',
        'NnC.Bong2RedKief',
        'NnC.BongPokeKief',
        'NnC.Pipe1GreenKief',
        'NnC.Pipe1OrangeKief',
        'NnC.Pipe1YellowKief',
        'NnC.CanPipeKief',
        'NnC.SmokingPipeKief'
    }

    Events.OnCreatePlayer.Add(function()
        local smokableObjects = {}

        local bluntSettings = {
            visualItem = 'Mask_Cigarillo',
            smokeLength = 1.9,
            burnMin = 0.000165,
            burnMax = 0.000295,
            burnSpeed = 0.0030,
            burnSpeedDecay = 0.20,
            decayRate = 0.994,
            callback = WeedSmoke_Callback,
            conditions = { idle = true, walking = true, running = true, sprinting = true, strafing = true, canDrop = true },
            idleFactor = TrueSmoking.Options.IdleFactor,
            walkingFactor = TrueSmoking.Options.WalkingFactor,
            runningFactor = TrueSmoking.Options.RunningFactor,
            sprintingFactor = TrueSmoking.Options.SprintingFactor,
            puffFactor = TrueSmoking.Options.PuffFactor
        }
        local jointSettings = {
            visualItem = 'Mask_Cigarette',
            smokeLength = 1.3,
            burnMin = 0.000165,
            burnMax = 0.000295,
            burnSpeed = 0.0030,
            burnSpeedDecay = 0.20,
            decayRate = 0.994,
            callback = WeedSmoke_Callback,
            conditions = { idle = true, walking = true, running = true, sprinting = true, strafing = true, canDrop = true },
            idleFactor = TrueSmoking.Options.IdleFactor,
            walkingFactor = TrueSmoking.Options.WalkingFactor,
            runningFactor = TrueSmoking.Options.RunningFactor,
            sprintingFactor = TrueSmoking.Options.SprintingFactor,
            puffFactor = TrueSmoking.Options.PuffFactor
        }
        local pipeSettings = {
            visualItem = false,
            smokeLength = 0.65,
            burnMin = 0.000125,
            burnMax = 0.000500,
            burnSpeed = 0.0040,
            burnSpeedDecay = 0.20,
            decayRate = 0.99,
            callback = WeedSmoke_Callback,
            conditions = { idle = true, walking = false, running = false, sprinting = false, strafing = false, canDrop = false },
            idleFactor = TrueSmoking.Options.IdleFactor,
            walkingFactor = TrueSmoking.Options.WalkingFactor,
            runningFactor = TrueSmoking.Options.RunningFactor,
            sprintingFactor = TrueSmoking.Options.SprintingFactor,
            puffFactor = TrueSmoking.Options.PuffFactor
        }
        local bongSettings = {
            visualItem = false,
            smokeLength = 0.65,
            burnMin = 0.000125,
            burnMax = 0.000500,
            burnSpeed = 0.0040,
            burnSpeedDecay = 0.20,
            decayRate = 0.99,
            callback = WeedSmoke_Callback,
            conditions = { idle = true, walking = false, running = false, sprinting = false, strafing = false, canDrop = false },
            idleFactor = TrueSmoking.Options.IdleFactor,
            walkingFactor = TrueSmoking.Options.WalkingFactor,
            runningFactor = TrueSmoking.Options.RunningFactor,
            sprintingFactor = TrueSmoking.Options.SprintingFactor,
            puffFactor = TrueSmoking.Options.PuffFactor
        }

        for _, item in ipairs(NnC_Items) do
            -- print('Building Item for: '..item)
            if string.match(item:lower(), 'joint') then
                smokableObjects[item] = jointSettings
            elseif string.match(item:lower(), 'blunt') then
                smokableObjects[item] = bluntSettings
            elseif string.match(item:lower(), 'pipe') then
                smokableObjects[item] = pipeSettings
            elseif string.match(item:lower(), 'bong') then
                smokableObjects[item] = bongSettings
            end
        end

        -- smokableObjects['someItem'] = {
        --     ...
        -- }

        TrueSmoking:setSmokableObjects(smokableObjects)
    end)
end
