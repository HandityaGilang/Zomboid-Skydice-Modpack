--Ammo Maker by STIMP_TM

local function onFiring(player, weapon)

    if player and player:isAlive() then

        if weapon and weapon:isRanged() then

            local ammoItemType = weapon:getAmmoType():getItemKey();

            if ammoMakerAmmoTypes[ammoItemType] then

                local weaponReloadType = weapon:getWeaponReloadType();

                if weaponReloadType ~= WeaponReloadType.REVOLVER and weaponReloadType ~= WeaponReloadType.DOUBLE_BARREL_SHOTGUN_SAWN and weaponReloadType ~= WeaponReloadType.DOUBLE_BARREL_SHOTGUN then

                    sendClientCommand(player, "ammomaker", "returnCasingsOnAttack", { weapon });

                elseif weaponReloadType == WeaponReloadType.DOUBLE_BARREL_SHOTGUN_SAWN or weaponReloadType == WeaponReloadType.DOUBLE_BARREL_SHOTGUN or (weaponReloadType == WeaponReloadType.REVOLVER and ammoMakerCompatibleMods["RealFirearms"]) then
                    
                    sendClientCommand(player, "ammomaker", "incrementSpendtRoundCount", { weapon });

                end

            end

        end

    end

end

Events.OnPlayerAttackFinished.Add(onFiring);