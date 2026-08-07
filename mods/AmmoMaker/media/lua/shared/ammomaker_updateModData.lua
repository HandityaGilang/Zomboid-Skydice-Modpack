--Ammo Maker by STIMP_TM

--store mod data on server

local function ammoMakerUpdateModData(key, modData)

    local birdFeederSaveID = "birdFeeder";

    --check if bird feeder data

    if key == birdFeederSaveID then

        --check if multipayer server or singleplayer

        if getWorld():getGameMode() == "Multiplayer" and isServer() or getWorld():getGameMode() ~= "Multiplayer" then

            --add new bird feeder locations to server mod data

            local birdFeederTableServer = ModData.getOrCreate(birdFeederSaveID);

            for _, birdFeederLocationClient in ipairs(modData) do

                local isPartOf = false;

                for _, birdFeederLocationServer in ipairs(birdFeederTableServer) do

                    if birdFeederLocationClient == birdFeederLocationServer then

                        isPartOf = true;

                    end

                end

                if isPartOf == false then

                    table.insert(birdFeederTableServer, birdFeederLocationClient);

                    --add and remove item to new bird feeder to init container

                    local coordinates = {};
                    for coordinate in string.gmatch(birdFeederLocationClient, '([^,]+)') do
                        coordinates[#coordinates+1] = coordinate;
                    end
                    local birdFeederX = tonumber(coordinates[1]);
                    local birdFeederY = tonumber(coordinates[2]);
                    local birdFeederZ = tonumber(coordinates[3]);
    
                    local cell = getWorld():getCell();
    
                    if cell:getGridSquare(birdFeederX, birdFeederY, birdFeederZ) then
    
                        local gridSquare = cell:getGridSquare(birdFeederX, birdFeederY, birdFeederZ);
                        local gridSquareObjects = gridSquare:getObjects();
    
                        for i=0,gridSquareObjects:size()-1 do
    
                            local gridSquareObject = gridSquareObjects:get(i);
    
                            if gridSquareObject and gridSquareObject:getContainer() then
    
                                if gridSquareObject:getContainer():getType() == "ammomaker_BirdFeeder" then
    
                                    local birdFeederContainer = gridSquareObject:getContainer();
                                    birdFeederContainer:AddItem("ammomaker.ammomaker_BirdExcrement");
                                    birdFeederContainer:removeAllItems();
                                
                                end

                            end

                        end

                    end

                end
                
            end

            ModData.add(birdFeederSaveID, birdFeederTableServer);

            --send updated server mod data to multiplayer clients

            if getWorld():getGameMode() == "Multiplayer" then

                ModData.transmit(birdFeederSaveID);

            end
        
        --store updated mod data on multiplayer clients
        
        elseif getWorld():getGameMode() == "Multiplayer" and isClient() then

            ModData.add(birdFeederSaveID, modData);

        end

    end

end

Events.OnReceiveGlobalModData.Add(ammoMakerUpdateModData);