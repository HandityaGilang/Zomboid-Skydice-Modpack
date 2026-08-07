--Ammo Maker by STIMP_TM

local function onFiring(player, weapon)

    if player and player:isAlive() then

        if weapon and weapon:isRanged() then

            local ammoItemType = weapon:getAmmoType():getItemKey();

            if ammoMakerAmmoTypes[ammoItemType] then

                local weaponReloadType = weapon:getWeaponReloadType();

                if weaponReloadType ~= "revolver" and weaponReloadType ~= "doublebarrelshotgunsawn" and weaponReloadType ~= "doublebarrelshotgun" then

                    sendClientCommand(player, "ammomaker", "returnCasingsOnAttack", { weapon });

                elseif weaponReloadType == "doublebarrelshotgunsawn" or weaponReloadType == "doublebarrelshotgun" or (weaponReloadType == "revolver" and ammoMakerCompatibleMods["\\Real Firearms"]) then

                    sendClientCommand(player, "ammomaker", "incrementSpendtRoundCount", { weapon });

                end

            end

        end

    end

end

Events.OnPlayerAttackFinished.Add(onFiring);