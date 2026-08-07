--Ammo Maker by STIMP_TM

--update container contents on client

local function ammoMakerUpdateContainer(module, command, containerUpdateData)

    --check if multipayer client

    if getWorld():getGameMode() == "Multiplayer" and isClient() then

        if command == "updateBirdFeederClient" then

            local birdFeederX = containerUpdateData[1];
            local birdFeederY = containerUpdateData[2];
            local birdFeederZ = containerUpdateData[3];

            local cell = getWorld():getCell();

            --check if bird feeder exists at given location

            if cell:getGridSquare(birdFeederX, birdFeederY, birdFeederZ) then

                local gridSquare = cell:getGridSquare(birdFeederX, birdFeederY, birdFeederZ);
                local gridSquareObjects = gridSquare:getObjects();

                for i=0,gridSquareObjects:size()-1 do

                    local gridSquareObject = gridSquareObjects:get(i);

                    if gridSquareObject and gridSquareObject:getContainer() then

                        if gridSquareObject:getContainer():getType() == "ammomaker_BirdFeeder" then

                            --set bird feeder container contents on client

                            local birdFeederContainer = gridSquareObject:getContainer();

                            table.remove(containerUpdateData, 1);
                            table.remove(containerUpdateData, 1);
                            table.remove(containerUpdateData, 1);

                            birdFeederContainer:removeAllItems();

                            for _, birdFeederItem in ipairs(containerUpdateData) do

                                birdFeederContainer:AddItem(birdFeederItem);

                            end

                        end

                    end

                end

            end

        end

    end

end

Events.OnServerCommand.Add(ammoMakerUpdateContainer)