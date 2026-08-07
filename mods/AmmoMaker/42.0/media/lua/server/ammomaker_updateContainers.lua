--Ammo Maker by STIMP_TM

--update container contents on server

local function ammoMakerUpdateContainers()

    --check if multipayer server or singleplayer

    if getWorld():getGameMode() == "Multiplayer" and isServer() or getWorld():getGameMode() ~= "Multiplayer" then

        local gameTime = getGameTime():getTimeOfDay();

        --check if mod data available and daytime

        if ModData.get("birdFeeder") and gameTime < 21 and gameTime > 5 then

            --get bird feeder mod data and set accepted seed types

            local birdFeederTable = ModData.get("birdFeeder");

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
                                        local birdFeederContainerItemType = birdFeederContainerItem:getType();

                                        if birdFeederContainerItem:hasTag("isSeed") and containedSeed == false then

                                            containedSeed = true;

                                            birdFeederContainer:RemoveOneOf(birdFeederContainerItemType);
                                            birdFeederContainer:AddItems("ammomaker.ammomaker_BirdExcrement", SandboxVars.ammomakerOptions.BirdExYield);

                                            if birdFeederContainer:getItemCount(birdFeederContainerItemType) % 5 == 0 then

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

                                        birdFeederUpdateData = ammoMakerTableArrayConcat(birdFeederLocation, birdFeederItems);
                                        
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