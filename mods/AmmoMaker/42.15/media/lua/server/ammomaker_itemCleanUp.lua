--Ammo Maker by STIMP_TM

local droppedCasingsSaveID = "droppedCasings";

--public function to add an item to the ammo maker clean up table, with full item type (e.g. "Base.Pot") and square coordinates

function ammoMakerItemCleanUpAddModData(itemType, squareX, squareY, squareZ)

    local currentTime = getWorld():getWorldAgeDays();

    local droppedCasingsTable = ModData.getOrCreate(droppedCasingsSaveID);

    --[1]item type; [2]square X; [3]square Y; [4]square Z; [5]drop time

    local droppedCasingDataNew = itemType .. ";" .. squareX .. ";" .. squareY .. ";" .. squareZ .. ";" .. currentTime;

    table.insert(droppedCasingsTable, droppedCasingDataNew);

    ModData.add(droppedCasingsSaveID, droppedCasingsTable);

end

--function that runs every ten minutes (in-game) on the server and cleans up items that have exceeded their lifetime

local function itemCleanUp()

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

                --check if current dropped casing data isn't nil

                if droppedCasingData ~= nil then

                    --map current dropped casing data fields to table: [1]item type; [2]square X; [3]square Y; [4]square Z; [5]drop time

                    local droppedCasingFields = {};
                    for droppedCasingField in string.gmatch(droppedCasingData, '([^;]+)') do
                        droppedCasingFields[#droppedCasingFields+1] = droppedCasingField;
                    end

                    --check if current dropped casing has exceeded lifetime

                    local dropTime = tonumber(droppedCasingFields[5]);
                    local itemAge = currentTime - dropTime;

                    if itemAge > droppedCasingsLifetime then

                        --check if current grid square is loaded

                        local tileX = tonumber(droppedCasingFields[2]);
                        local tileY = tonumber(droppedCasingFields[3]);
                        local tileZ = tonumber(droppedCasingFields[4]);

                        if cell:getGridSquare(tileX, tileY, tileZ) then

                            --check if current grid square contains world objects

                            local gridSquare = cell:getGridSquare(tileX, tileY, tileZ);

                            if gridSquare:getWorldObjects():size() > 0 then

                                --go through all world objects on the current grid square

                                local itemType = droppedCasingFields[1];

                                local gridSquareObjects = gridSquare:getWorldObjects();
                                local gridSquareObjectsSize = gridSquareObjects:size();

                                local foundCasingOfType = false;

                                for j=gridSquareObjectsSize-1,0,-1 do

                                    --check if the current world object item type matches the current dropped casing type

                                    local gridSquareObject = gridSquareObjects:get(j);
                                    local gridSquareItem = gridSquareObject:getItem();
                                    local gridSquareItemType = gridSquareItem:getType();
                                    local gridSquareItemTypeFull = "ammomaker." .. gridSquareItemType;

                                    if itemType == gridSquareItemTypeFull and foundCasingOfType == false then

                                        --remove current world object and add current dropped casing to the mod data removal table

                                        foundCasingOfType = true;

                                        gridSquare:transmitRemoveItemFromSquare(gridSquareObject);
                                        gridSquareObject:removeFromWorld();
                                        gridSquareObject:removeFromSquare();

                                        modDataRemovals[#modDataRemovals+1] = i;
                                        modDataRemovalsFound = true;

                                    end

                                end

                            else

                                --if current grid square doesn't contain world objects add current dropped casing to the mod data removal table

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

            end

        end

    end

end

Events.EveryTenMinutes.Add(itemCleanUp);