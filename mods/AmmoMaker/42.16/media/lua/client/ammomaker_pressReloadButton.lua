--Ammo Maker by STIMP_TM

local function onReload(player, weapon)

	if player and player:isAlive() then

        if weapon and weapon:isRanged() then

            local ammoItemType = weapon:getAmmoType():getItemKey();

            if ammoMakerAmmoTypes[ammoItemType] then

				local weaponReloadType = weapon:getWeaponReloadType();

				if (weaponReloadType == WeaponReloadType.REVOLVER and not ammoMakerCompatibleMods["RealFirearms"]) then

					sendClientCommand(player, "ammomaker", "returnCasingsOnReload", { weapon, weapon:getSpentRoundCount() });

				elseif weaponReloadType == WeaponReloadType.DOUBLE_BARREL_SHOTGUN_SAWN or weaponReloadType == WeaponReloadType.DOUBLE_BARREL_SHOTGUN  or (weaponReloadType == WeaponReloadType.REVOLVER and ammoMakerCompatibleMods["RealFirearms"]) then

					sendClientCommand(player, "ammomaker", "returnCasingsOnReload", { weapon, nil });

				end

			end

		end

	end

end

Events.OnPressReloadButton.Add(onReload);