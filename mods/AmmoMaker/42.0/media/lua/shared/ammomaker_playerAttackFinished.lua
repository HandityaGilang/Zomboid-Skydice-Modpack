--Ammo Maker by STIMP_TM

local function spawnCasing(character, weapon)

	if character and character:isAlive() then

        if weapon and weapon:isRanged() then

            local weaponReloadType = weapon:getWeaponReloadType();
            local ammoItemType = weapon:getAmmoType();

            if weaponReloadType ~= "revolver" and weaponReloadType ~= "doublebarrelshotgunsawn" and weaponReloadType ~= "doublebarrelshotgun" and ammoMakerAmmoTypes[ammoItemType] then

                local weaponType = weapon:getModule() .. "." .. weapon:getType();
                local casingItemTypeFired = ammoMakerAmmoParts[ammoMakerGetCasingType(ammoItemType)].partFired;
                local casingItemTypeOld = ammoMakerAmmoParts[ammoMakerGetCasingType(ammoItemType)].partOld;
                local optionalItemType = ammoMakerGetDropExtraDataItemType(ammoItemType, weaponType);

                local function handleSpawn(casing, optional)

                    local characterInventory = character:getInventory();
                    local characterSquare = character:getCurrentSquare();
                    local brassCatcherImprovised = characterInventory:FindAll("ammomaker_BrassCatcherImprovised");
                    local brassCatcherAdvanced = characterInventory:FindAll("ammomaker_BrassCatcherAdvanced");

                    if brassCatcherAdvanced:size() > 0 then

                        ammoMakerAddCasingToInventory(characterSquare, characterInventory, brassCatcherImprovised, brassCatcherAdvanced, casing, optional);

                    elseif brassCatcherImprovised:size() > 0 then

                        local randomInstance = newrandom();
                        local randomInt = randomInstance:random(2);

                        if randomInt == 1 then

                            ammoMakerAddCasingToInventory(characterSquare, characterInventory, brassCatcherImprovised, brassCatcherAdvanced, casing, optional);

                        else

                            ammoMakerAddCasingToWorld(characterSquare, casing, optional);

                        end

                    else

                        ammoMakerAddCasingToWorld(characterSquare, casing, optional);

                    end

                end

                if ammoMakerAmmoTypes[ammoItemType] then

                    local randomInstance = newrandom();
                    local randomInt = randomInstance:random(10);

                    if optionalItemType then

                        if randomInt == 5 then

                            handleSpawn(casingItemTypeOld, optionalItemType);

                        else

                            handleSpawn(casingItemTypeFired, optionalItemType);

                        end

                    else

                        if randomInt == 5 then

                            handleSpawn(casingItemTypeOld, "");

                        else

                            handleSpawn(casingItemTypeFired, "");

                        end

                    end

                end

            --fix for break action firearms and revolvers that aren't incrementing the spent round count by standard
            elseif weaponReloadType == "doublebarrelshotgunsawn" or weaponReloadType == "doublebarrelshotgun" or (weaponReloadType == "revolver" and ammoMakerCompatibleMods["\\Real Firearms"]) then

                local weaponSpentRoundCount = weapon:getSpentRoundCount() + 1;
                weapon:setSpentRoundCount(weaponSpentRoundCount);

            end

        end

    end

end

Events.OnPlayerAttackFinished.Add(spawnCasing);