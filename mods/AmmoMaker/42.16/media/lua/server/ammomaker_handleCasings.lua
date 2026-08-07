--Ammo Maker by STIMP_TM

local spentRoundCountsSaveID = "spentRoundCounts";

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

local function addCasingToWorld(player, casing, optional)

    local square = player:getCurrentSquare();

    ammoMakerAddItemTypeToWorld(square, casing);

    if optional then

        ammoMakerAddItemTypeToWorld(square, optional);

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

                addCasingToWorld(player, casing, optional);

            end

        elseif reload then

            addCasingToInventory(inventory, casing, optional);

        else

            addCasingToWorld(player, casing, optional);

        end

    else

        addCasingToWorld(player, casing, optional);

    end

end

--return casings on reload for revolvers and break action firearms, and reset ammo maker spent round count for weapons without native counter

local function returnCasingsOnReload(player, weapon, count)

    local weaponID = weapon:getID();
    local ammoItemType = weapon:getAmmoType():getItemKey();
	local inventoryRoundCount = ammoMakerItemCountInInventory(player:getInventory(), ammoItemType);

    if not count then

        count = getSpendtRoundCount(weaponID);
        setSpendtRoundCount(weaponID, 0);

    end

	if count > 0 and inventoryRoundCount > 0 then

		for i=1,count do

            handleCasingSpawn(player, weapon, true);

		end

	end

end

--call server functions on client command, to return casings (and optional items) on reload or attack actions, and to update ammo maker spent round count

local function handleCasings(module, command, player, args)

    if module == "ammomaker" then

        if command == "returnCasingsOnAttack" then

            handleCasingSpawn(player, args[1], nil);

        elseif command == "incrementSpendtRoundCount" then

            incrementSpendtRoundCount(args[1]);

        elseif command == "returnCasingsOnReload" then

            returnCasingsOnReload(player, args[1], args[2]);

        end

    end

end

Events.OnClientCommand.Add(handleCasings)