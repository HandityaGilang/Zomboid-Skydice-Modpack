--Ammo Maker by STIMP_TM

--store mod data on server

local function ammoMakerUpdateModData(key, modData)

    local droppedCasingsSaveID = "droppedCasings";

    --check if dropped casings data

    if key == droppedCasingsSaveID then

        --check if multipayer server or singleplayer

        if getWorld():getGameMode() == "Multiplayer" and isServer() or getWorld():getGameMode() ~= "Multiplayer" then

            --add new dropped casing data to server mod data

            local droppedCasingsTableServer = ModData.getOrCreate(droppedCasingsSaveID);

            for _, droppedCasingDataClient in ipairs(modData) do

                local isPartOf = false;

                for _, droppedCasingDataServer in ipairs(droppedCasingsTableServer) do

                    if droppedCasingDataClient == droppedCasingDataServer then

                        isPartOf = true;

                    end

                end

                if isPartOf == false then

                    table.insert(droppedCasingsTableServer, droppedCasingDataClient);

                end

            end

            ModData.add(droppedCasingsSaveID, droppedCasingsTableServer);

            --send updated server mod data to multiplayer clients

            if getWorld():getGameMode() == "Multiplayer" then

                ModData.transmit(droppedCasingsSaveID);

            end

        elseif getWorld():getGameMode() == "Multiplayer" and isClient() then

            ModData.add(droppedCasingsSaveID, modData);

        end

    end

end

Events.OnReceiveGlobalModData.Add(ammoMakerUpdateModData);