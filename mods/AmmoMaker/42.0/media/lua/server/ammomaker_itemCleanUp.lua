--Ammo Maker by STIMP_TM

local function ammoMakerRemoveCasings()

    local droppedCasingsSaveID = "droppedCasings";

    if getWorld():getGameMode() == "Multiplayer" and isServer() or getWorld():getGameMode() ~= "Multiplayer" then

        if ModData.get(droppedCasingsSaveID) then

            --get dropped casings mod data, global variables, casing types for removal and sandbox options

            local droppedCasingsTableServer = ModData.get(droppedCasingsSaveID);

            local currentTime = getWorld():getWorldAgeDays();

            local cell = getWorld():getCell();

            local droppedCasingsLifetime = 1 / 24 * SandboxVars.ammomakerOptions.DroppedCasingsLifetime;

            local modDataRemovals = {};
            local modDataRemovalsFound = false;

            for i, droppedCasingData in pairs(droppedCasingsTableServer) do

                if droppedCasingData ~= nil then

                    --map dropped casing data fields to individual variables

                    local droppedCasingFields = {};
                    for droppedCasingField in string.gmatch(droppedCasingData, '([^;]+)') do
                        droppedCasingFields[#droppedCasingFields+1] = droppedCasingField;
                    end
                    local itemType = droppedCasingFields[1];
                    local tileX = tonumber(droppedCasingFields[2]);
                    local tileY = tonumber(droppedCasingFields[3]);
                    local tileZ = tonumber(droppedCasingFields[4]);
                    local dropTime = tonumber(droppedCasingFields[5]);

                    local itemAge = currentTime - dropTime;

                    --check for dropped casings that have exceeded their lifetime

                    if itemAge > droppedCasingsLifetime then

                        if cell:getGridSquare(tileX, tileY, tileZ) then

                            local gridSquare = cell:getGridSquare(tileX, tileY, tileZ);

                            if gridSquare:getWorldObjects():size() > 0 then

                                local gridSquareObjects = gridSquare:getWorldObjects();
                                local gridSquareObjectsSize = gridSquareObjects:size();

                                local foundCasingOfType = false;

                                for j=gridSquareObjectsSize-1,0,-1 do 

                                    local gridSquareObject = gridSquareObjects:get(j);
                                    local gridSquareItem = gridSquareObject:getItem();
                                    local gridSquareItemType = gridSquareItem:getType();
                                    local gridSquareItemTypeFull = "ammomaker." .. gridSquareItemType;

                                    if itemType == gridSquareItemTypeFull and foundCasingOfType == false then

                                        foundCasingOfType = true;

                                        gridSquareObject:removeFromSquare();
                                        gridSquareObject:removeFromWorld();

                                        modDataRemovals[#modDataRemovals+1] = i;
                                        modDataRemovalsFound = true;

                                    end

                                end

                            else

                                modDataRemovals[#modDataRemovals+1] = i;
                                modDataRemovalsFound = true;

                            end

                        end

                    end

                end

            end

            --update server mod data

            if modDataRemovalsFound == true then

                for _, removalIndex in ipairs(modDataRemovals) do

                    droppedCasingsTableServer[removalIndex] = nil;

                end

                ModData.add(droppedCasingsSaveID, droppedCasingsTableServer);

                --send updated server mod data to multiplayer clients

                if getWorld():getGameMode() == "Multiplayer" then

                    ModData.transmit(droppedCasingsSaveID);

                end

            end

        end

    end

end

Events.EveryTenMinutes.Add(ammoMakerRemoveCasings);