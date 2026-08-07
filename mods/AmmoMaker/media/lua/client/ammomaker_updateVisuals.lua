--Ammo Maker by STIMP_TM

local function ammoMakerEveryOneMinute()

    --update iso objects outline thickness

    if ModData.get("birdFeeder") then

        local birdFeederTable = ModData.get("birdFeeder");

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

                for i=0,gridSquareObjects:size()-1 do

                    local gridSquareObject = gridSquareObjects:get(i);

                    if gridSquareObject and gridSquareObject:getContainer() then

                        if gridSquareObject:getContainer():getType() == "ammomaker_BirdFeeder" then

                            gridSquareObject:setOutlineThickness(1);

                        end

                    end

                end
            
            end

        end

    end

end

Events.EveryOneMinute.Add(ammoMakerEveryOneMinute);