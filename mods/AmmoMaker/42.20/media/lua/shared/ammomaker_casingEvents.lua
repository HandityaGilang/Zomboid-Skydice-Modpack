--Ammo Maker by STIMP_TM

function ammoMakerHandleCasingEvents(player, weapon, action)

    if player and player:isAlive() then

        if weapon and weapon:isRanged() then

            local ammoItemType = weapon:getAmmoType():getItemKey();

            if ammoMakerAmmoTypes[ammoItemType] then

                local weaponReloadType = weapon:getWeaponReloadType();

                if weaponReloadType == WeaponReloadType.REVOLVER or weaponReloadType == WeaponReloadType.DOUBLE_BARREL_SHOTGUN_SAWN or weaponReloadType == WeaponReloadType.DOUBLE_BARREL_SHOTGUN then

                    if action == "firing" then

                        sendClientCommand(player, "ammomaker", "incrementSpendtRoundCount", { weapon });

                    elseif action == "reloading" then

                        sendClientCommand(player, "ammomaker", "returnCasingsOnReloading", { weapon });

                    elseif action == "racking" then

                        sendClientCommand(player, "ammomaker", "returnCasingsOnRacking", { weapon });

                    end

                else

                    if action == "firing" then

                        sendClientCommand(player, "ammomaker", "returnCasingsOnAttack", { weapon });

                    end

                end

            end

        end

    end

end

local function onFiring(player, weapon)

	ammoMakerHandleCasingEvents(player, weapon, "firing");

end

Events.OnPlayerAttackFinished.Add(onFiring);