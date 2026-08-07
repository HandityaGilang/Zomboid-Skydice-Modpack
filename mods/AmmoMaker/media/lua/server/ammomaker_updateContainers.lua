--Ammo Maker by STIMP_TM

--add array data to lua table

local function tableArrayConcat(t1, a1)

    for i=0,a1:size()-1 do

        table.insert(t1, a1:get(i))

    end

    return t1

end

--update container contents on server

local function ammoMakerUpdateContainers()

    --check if multipayer server or singleplayer

    if getWorld():getGameMode() == "Multiplayer" and isServer() or getWorld():getGameMode() ~= "Multiplayer" then

        local gameTime = getGameTime():getTimeOfDay();

        --check if mod data available and daytime

        if ModData.get("birdFeeder") and gameTime < 21 and gameTime > 5 then

            --get bird feeder mod data and set accepted seed types

            local birdFeederTable = ModData.get("birdFeeder");

            local seedTypes = {
                [1] = "farming.BroccoliSeed",
                [2] = "farming.CabbageSeed",
                [3] = "farming.CarrotSeed",
                [4] = "farming.PotatoSeed",
                [5] = "farming.RedRadishSeed",
                [6] = "farming.StrewberrieSeed",
                [7] = "Base.SunflowerSeeds",
                [8] = "farming.TomatoSeed",
                --Sprout SGFarming:
                [9] = "Sprout.TeaSeed",
                [10] = "Sprout.CoffeeSeed",
                [11] = "Sprout.RubberSeed",
                [12] = "Sprout.AppleSeed",
                [13] = "Sprout.BananaSeed",
                [14] = "Sprout.BellPepperSeed",
                [15] = "Sprout.BerryBlackSeed",
                [16] = "Sprout.BerryBlueSeed",
                [17] = "Sprout.CherrySeed",
                [18] = "Sprout.CornSeed",
                [19] = "Sprout.EggplantSeed",
                [20] = "Sprout.GingerSeed",
                [21] = "Sprout.GinsengSeed",
                [22] = "Sprout.GrapefruitSeed",
                [23] = "Sprout.GrapeSeed",
                [24] = "Sprout.LeekSeed",
                [25] = "Sprout.LemongrassSeed",
                [26] = "Sprout.LemonSeed",
                [27] = "Sprout.LettuceSeed",
                [28] = "Sprout.LimeSeed",
                [29] = "Sprout.OliveSeed",
                [30] = "Sprout.OnionSeed",
                [31] = "Sprout.OrangeSeed",
                [32] = "Sprout.PineappleSeed",
                [33] = "Sprout.PumpkinSeed",
                [34] = "Sprout.SoyBeanSeed",
                [35] = "Sprout.SugarCaneSeed",
                [36] = "Sprout.WatermelonSeed",
                [37] = "Sprout.WheatSeed",
                [38] = "Sprout.ZucchiniSeed",
                --Sprout SGFarming More Seeds:
                [39] = "Sprout.RiceSeed",
                [40] = "Sprout.PepperPlantSeed",
                [41] = "Sprout.CottonSeed",
                [42] = "Sprout.HopsSeed",
                --Sprout AddonSeeds:
                [43] = "Sprout.PearSeeds",
                [44] = "Sprout.CommonMallowSeeds",
                [45] = "Sprout.PlantainSeeds",
                [46] = "Sprout.ComfreySeeds",
                [47] = "Sprout.GarlicSeeds",
                [48] = "Sprout.BlackSageSeeds",
                --Sprout SFGFarming:
                [49] = "Sprout.BlackGeraniumSeed",
                [50] = "Sprout.BlueDelphiniumSeed",
                [51] = "Sprout.MagentaPentaSeed",
                [52] = "Sprout.OrangeDahliaSeed",
                [53] = "Sprout.PinkCarnationSeed",
                [54] = "Sprout.RedRoseSeed",
                [55] = "Sprout.WhiteLarkspurSeed",
                [56] = "Sprout.YellowDaisySeed",
                --Sprout WeedItems:
                [57] = "Sprout.SativaSeeds",
                [58] = "Sprout.IndicaSeeds",
                [59] = "Sprout.TobaccoSeeds",
                --Sprout not in use:
                    --Sprout.AvocadoSeed
                    --Sprout.MangoSeed
                    --Sprout.MushroomSpores
                    --Sprout.PeachSeed
            };

            --check if bird feeder exists at mod data location

            for _, birdFeederLocation in ipairs(birdFeederTable) do

                local coordinates = {};
                for coordinate in string.gmatch(birdFeederLocation, '([^,]+)') do
                    coordinates[#coordinates+1] = coordinate;
                end
                local birdFeederX = tonumber(coordinates[1]);
                local birdFeederY = tonumber(coordinates[2]);
                local birdFeederZ = tonumber(coordinates[3]);

                local cell = getWorld():getCell();

                if cell:getGridSquare(birdFeederX, birdFeederY, birdFeederZ) then

                    local gridSquare = cell:getGridSquare(birdFeederX, birdFeederY, birdFeederZ);
                    local gridSquareObjects = gridSquare:getObjects();

                    if gridSquare:isOutside() then

                        for i=0,gridSquareObjects:size()-1 do

                            local gridSquareObject = gridSquareObjects:get(i);

                            if gridSquareObject and gridSquareObject:getContainer() then

                                if gridSquareObject:getContainer():getType() == "ammomaker_BirdFeeder" then

                                    --replace seeds with bird excrement and bird feathers in bird feeder container

                                    local birdFeederContainer = gridSquareObject:getContainer();
                                    local containedSeed = false;

                                    for _, seedType in ipairs(seedTypes) do

                                        if birdFeederContainer:getItemCount(seedType) > 0 and containedSeed == false then

                                            containedSeed = true;

                                            birdFeederContainer:RemoveOneOf(seedType);
                                            birdFeederContainer:AddItems("ammomaker.ammomaker_BirdExcrement", SandboxVars.ammomakerOptions.BirdExYield);

                                            if birdFeederContainer:getItemCount(seedType) % 5 == 0 and (SandboxVars.ammomakerOptions.ActivateArchery == true or getActivatedMods():contains("Arsenal(26)GunFighter") or getActivatedMods():contains("Arsenal(26)GunFighter[MAIN MOD 2.0]")) then

                                                birdFeederContainer:AddItem("ammomaker.ammomaker_BirdFeather");

                                            end

                                        end

                                    end

                                    --send coordinates and updated bird feeder container contents to multiplayer clients

                                    if getWorld():getGameMode() == "Multiplayer" then

                                        local birdFeederLocation = {
                                            birdFeederX,
                                            birdFeederY,
                                            birdFeederZ,
                                        };

                                        local birdFeederItems = birdFeederContainer:getItems();

                                        birdFeederUpdateData = tableArrayConcat(birdFeederLocation, birdFeederItems);
                                        
                                        sendServerCommand("ammomaker", "updateBirdFeederClient", birdFeederUpdateData);

                                    end

                                end

                            end

                        end

                    end
                
                end

            end

        end

    end

end

Events.EveryTenMinutes.Add(ammoMakerUpdateContainers);