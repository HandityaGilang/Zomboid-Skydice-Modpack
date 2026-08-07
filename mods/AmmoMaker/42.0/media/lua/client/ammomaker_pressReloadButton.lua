--Ammo Maker by STIMP_TM

local function spawnCasingsOnReload(character, weapon)

	local weaponReloadType = weapon:getWeaponReloadType();
	local ammoItemType = weapon:getAmmoType();

	if weaponReloadType == "revolver" or weaponReloadType == "doublebarrelshotgunsawn" or weaponReloadType == "doublebarrelshotgun" and ammoMakerAmmoTypes[ammoItemType] then

		local weaponSpentRoundCount = weapon:getSpentRoundCount();
		local characterInventory = character:getInventory();
		local inventoryRoundCount = ammoMakerItemCountInInventory(characterInventory, ammoItemType);

		if weaponSpentRoundCount > 0 and inventoryRoundCount > 0 then

			local characterSquare = character:getCurrentSquare();
    		local brassCatcherImprovised = characterInventory:FindAll("ammomaker_BrassCatcherImprovised");
    		local brassCatcherAdvanced = characterInventory:FindAll("ammomaker_BrassCatcherAdvanced");
			local casingItemTypeOld = ammoMakerAmmoParts[ammoMakerGetCasingType(ammoItemType)].partOld;
			local casingItemTypeFired = ammoMakerAmmoParts[ammoMakerGetCasingType(ammoItemType)].partFired;

			for i=1,weaponSpentRoundCount do

				local randomInstance = newrandom();
				local randomInt = randomInstance:random(10);

				if randomInt == 5 then

					ammoMakerAddCasingToInventory(characterSquare, characterInventory, brassCatcherImprovised, brassCatcherAdvanced, casingItemTypeOld, "");

				else

					ammoMakerAddCasingToInventory(characterSquare, characterInventory, brassCatcherImprovised, brassCatcherAdvanced, casingItemTypeFired, "");

				end

    		end

		end

	end

end

Events.OnPressReloadButton.Add(spawnCasingsOnReload);