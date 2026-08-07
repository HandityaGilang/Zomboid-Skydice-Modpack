--Ammo Maker by STIMP_TM

function ammoMakerAddAmmoTypesApi()

    local ammoMaps = {
        ammoMakerAddAmmoTypesMap0,
        ammoMakerAddAmmoTypesMap1,
        ammoMakerAddAmmoTypesMap2,
        ammoMakerAddAmmoTypesMap3,
        ammoMakerAddAmmoTypesMap4,
        ammoMakerAddAmmoTypesMap5,
        ammoMakerAddAmmoTypesMap6,
        ammoMakerAddAmmoTypesMap7,
        ammoMakerAddAmmoTypesMap8,
        ammoMakerAddAmmoTypesMap9
    };

    for _, ammoMap in pairs(ammoMaps) do

        if ammoMap ~= nil then

            if type(ammoMap) == "table" then

                for i, ammoDef in ipairs(ammoMap) do

                    local modId = ammoDef.modId;
                    modId = modId:gsub("^\\", ""); --Remove '\\' in front of modId if there
                    local itemType = ammoDef.itemType;
                    local ammoType = ammoDef.ammoType;

                    ammoMakerCompatibleMods[modId] = true;

                    if not ammoMakerAmmoTypes[itemType] then

                        ammoMakerAmmoTypes[itemType] = { 
                            modIds = {modId},
                            ammoTypes = {ammoType},
                        };

                    else

                        table.insert(ammoMakerAmmoTypes[itemType].modIds, modId);
                        table.insert(ammoMakerAmmoTypes[itemType].ammoTypes, ammoType);

                    end

                end

            end

        end

    end

end

function ammoMakerAddDropExtraItemsApi()

    local dropExtraMaps = {
        ammoMakerAddDropExtraItemsMap0,
        ammoMakerAddDropExtraItemsMap1,
        ammoMakerAddDropExtraItemsMap2,
        ammoMakerAddDropExtraItemsMap3,
        ammoMakerAddDropExtraItemsMap4,
        ammoMakerAddDropExtraItemsMap5,
        ammoMakerAddDropExtraItemsMap6,
        ammoMakerAddDropExtraItemsMap7,
        ammoMakerAddDropExtraItemsMap8,
        ammoMakerAddDropExtraItemsMap9
    };

    for _, dropExtraMap in pairs(dropExtraMaps) do

        if ammoMap ~= nil then

            if type(dropExtraMap) == "table" then

                for i, dropExtraDef in ipairs(dropExtraMap) do

                    local modId = dropExtraDef.modId;
                    modId = modId:gsub("^\\", ""); --Remove '\\' in front of modId if there
                    local weaponType = dropExtraDef.weaponType;
                    local itemType = dropExtraDef.itemType;
                    local ammoType = dropExtraDef.ammoType;

                    ammoMakerCompatibleMods[modId] = true;

                    if ammoMakerAmmoData[ammoType] then

                        ammoMakerAmmoData[ammoType].extraData[weaponType] = {
                            modId = {id},
                            itemType = {itemType},
                        };

                    end

                end

            end

        end

    end

end