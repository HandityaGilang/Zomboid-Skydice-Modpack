--Ammo Maker by STIMP_TM

local birdFeederSaveID = "birdFeeder";

--function that runs every ten minutes (in-game) on the server and updates the contents of specific containers (e.g. bird feeders)

local function ammoMakerUpdateContainers()

    --check if multipayer server or singleplayer

    if getWorld():getGameMode() == "Multiplayer" and isServer() or getWorld():getGameMode() ~= "Multiplayer" then

        local gameTime = getGameTime():getTimeOfDay();

        --check if mod data available and daytime

        if ModData.get(birdFeederSaveID) and gameTime < 21 and gameTime > 5 then

            --get bird feeder mod data and set accepted seed types

            local birdFeederTable = ModData.get(birdFeederSaveID);

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
                                    local birdFeederContainerItems = birdFeederContainer:getItems();
                                    local containedSeed = false;

                                    for j=0,birdFeederContainerItems:size()-1 do

                                        local birdFeederContainerItem = birdFeederContainerItems:get(j);

                                        if birdFeederContainerItem:hasTag(ItemTag.IS_SEED) and containedSeed == false then

                                            containedSeed = true;

                                            ammoMakerRemoveItemFromInventory(birdFeederContainer, birdFeederContainerItem)
                                            ammoMakerAddItemTypeToInventory(birdFeederContainer, "ammomaker.ammomaker_BirdExcrement", SandboxVars.ammomakerOptions.BirdExYield);

                                            local randomInstance = newrandom();
                                            local randomInt = randomInstance:random(10);

                                            if randomInt == 5 then

                                                ammoMakerAddItemTypeToInventory(birdFeederContainer, "ammomaker.ammomaker_BirdFeather", 1);

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

    end

end

Events.EveryTenMinutes.Add(ammoMakerUpdateContainers);