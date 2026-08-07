--Ammo Maker by STIMP_TM

local spentRoundCountsSaveID = "spentRoundCounts";
local HBVCEF = false;
local SpentCasingPhysics;

if getActivatedMods():contains('HBVCEFb42') then
    HBVCEF = true
    SpentCasingPhysics = require("SpentCasingPhysics/Init");
end

--get ammo maker spent round count for specific weapon by id

local function getSpendtRoundCount(weaponID)

    local spentRoundTable = ModData.get(spentRoundCountsSaveID);

    if spentRoundTable and spentRoundTable[weaponID] then

        return spentRoundTable[weaponID]

    else

        return 0

    end

end

--set ammo maker spent round count for specific weapon by id

local function setSpendtRoundCount(weaponID, count)

    local spentRoundTable = ModData.getOrCreate(spentRoundCountsSaveID);

    spentRoundTable[weaponID] = count;

    ModData.add(spentRoundCountsSaveID, spentRoundTable);

end

--increment ammo maker spent round count for specific weapon

local function incrementSpendtRoundCount(weapon)

    local weaponID = weapon:getID();
    local count = getSpendtRoundCount(weaponID);

    count = count + 1;

    setSpendtRoundCount(weaponID, count);

end

--add casing (and optional item) to the world inventory at player location

local function addCasingToWorld(player, weapon, casing, optional)

    if HBVCEF == true then

        local params = SpentCasingPhysics.WeaponEjectionPortParams[weapon:getFullType()] or SpentCasingPhysics.DefaultEjectionPortParams[weapon:getWeaponReloadType()];

        SpentCasingPhysics.doSpawnCasing(player, weapon, params, false, casing)

        if optional then

            SpentCasingPhysics.doSpawnCasing(player, weapon, params, false, optional)

        end

    else

        local square = player:getCurrentSquare();

        ammoMakerAddItemTypeToWorld(square, casing);

        if optional then

            ammoMakerAddItemTypeToWorld(square, optional);

        end

    end

end

--add casing (and optional item) to specific inventory (e.g. brass catcher)

local function addCasingToInventory(inventory, casing, optional)

    ammoMakerAddItemTypeToInventory(inventory, casing, 1);

    if optional then

        ammoMakerAddItemTypeToInventory(inventory, optional, 1);

    end

end

--randomly return item types of fired casings and old variants (average ratio 9:1) and return optional item types for given weapon

local function getItemTypesForSpawn(weapon)

    local ammoItemType = weapon:getAmmoType():getItemKey();
    local casingItemTypeFired = ammoMakerAmmoParts[ammoMakerGetCasingType(ammoItemType)].partFired;
    local casingItemTypeOld = ammoMakerAmmoParts[ammoMakerGetCasingType(ammoItemType)].partOld;

    local weaponType = weapon:getModule() .. "." .. weapon:getType();
    local optionalItemType = ammoMakerGetDropExtraDataItemType(ammoItemType, weaponType);

    local randomInstance = newrandom();
    local randomInt = randomInstance:random(10);

    if randomInt == 5 then

        return casingItemTypeOld, optionalItemType

    else

        return casingItemTypeFired, optionalItemType

    end

end

--return casings (and optional items) for all firearms to world or player inventories, dependent on brass catchers, inventory space, and reload or attack actions

local function handleCasingSpawn(player, weapon, reload)

    local inventory = player:getInventory();

    local casing, optional = getItemTypesForSpawn(weapon);

    local weight = getScriptManager():FindItem(casing):getActualWeight();
    if optional then
        weight = weight + getScriptManager():FindItem(optional):getActualWeight();
    end

    if inventory:getCapacity() > inventory:getCapacityWeight() + weight then

        local brassCatcherAdvanced = ammoMakerGetContainerWithSpace(inventory:FindAll("ammomaker_BrassCatcherAdvanced"), weight);
        local brassCatcherImprovised = ammoMakerGetContainerWithSpace(inventory:FindAll("ammomaker_BrassCatcherImprovised"), weight);

        if brassCatcherAdvanced then

            addCasingToInventory(brassCatcherAdvanced, casing, optional);

        elseif brassCatcherImprovised then

            local randomInstance = newrandom();
            local randomInt = randomInstance:random(2);

            if randomInt == 1 or reload then

                addCasingToInventory(brassCatcherImprovised, casing, optional);

            else

                addCasingToWorld(player, weapon, casing, optional);

            end

        elseif reload then

            addCasingToInventory(inventory, casing, optional);

        else

            addCasingToWorld(player, weapon, casing, optional);

        end

    else

        addCasingToWorld(player, weapon, casing, optional);

    end

end

--return casings on reload for revolvers and break action firearms, and reset ammo maker spent round count for weapons without native counter

local function returnCasingsOnUnload(player, weapon, action)

    local weaponID = weapon:getID();
    local ammoItemType = weapon:getAmmoType():getItemKey();
	local inventoryRoundCount = ammoMakerItemCountInInventory(player:getInventory(), ammoItemType);
    local spendtRoundCount = getSpendtRoundCount(weaponID);

	if (spendtRoundCount > 0 and inventoryRoundCount > 0 and action == "reloading") or (spendtRoundCount > 0 and action == "racking") then

		for i=1,spendtRoundCount do

            handleCasingSpawn(player, weapon, true);

		end

        setSpendtRoundCount(weaponID, 0);

	end

end

--call server functions on client command, to return casings (and optional items) on reload or attack actions, and to update ammo maker spent round count

local function handleCasings(module, command, player, args)

    if module == "ammomaker" then

        if command == "returnCasingsOnAttack" then

            handleCasingSpawn(player, args[1], nil);

        elseif command == "incrementSpendtRoundCount" then

            incrementSpendtRoundCount(args[1]);

        elseif command == "returnCasingsOnReloading" then

            returnCasingsOnUnload(player, args[1], "reloading");

        elseif command == "returnCasingsOnRacking" then

            returnCasingsOnUnload(player, args[1], "racking");

        end

    end

end

Events.OnClientCommand.Add(handleCasings)