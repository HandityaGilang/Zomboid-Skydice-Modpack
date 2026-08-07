--Ammo Maker by STIMP_TM

function ammoMakerUpdateCompatibleMods()

    for modId, status in pairs(ammoMakerCompatibleMods) do

        if getActivatedMods():contains(modId) or modId == "Base" then

            ammoMakerCompatibleMods[modId] = true;

        else

            ammoMakerCompatibleMods[modId] = false;

        end

    end

end

function ammoMakerIsItemInInventory(inventory, itemType)

    local isInInventory = inventory:contains(itemType);

    for i=0,inventory:getItems():size()-1 do

        if inventory:getItems():get(i):IsInventoryContainer() == true and inventory:getItems():get(i):getInventory():contains(itemType) == true then

            isInInventory = true;

        end

    end

    return isInInventory

end

function ammoMakerItemCountInInventory(inventory, itemType)

    local itemCount = inventory:getCountType(itemType);

    for i=0,inventory:getItems():size()-1 do

        if inventory:getItems():get(i):IsInventoryContainer() == true then

            itemCount = itemCount + inventory:getItems():get(i):getInventory():getCountType(itemType);

        end

    end

    return itemCount

end

function ammoMakerGetContainerWithSpace(inventories, weight)

    if inventories:size() > 0 then

        for i=0,inventories:size()-1 do

            local inventory = inventories:get(i);

            if inventory:getCapacity() - inventory:getContentsWeight() > weight then

                return inventory:getItemContainer()

            end

        end

    end

    return nil

end

function ammoMakerIsValueInTable(table, value)

    for _, v in ipairs(table) do

        if v == value then

            return true

        end

    end

    return false

end

function ammoMakerWorldAddItemAtItemPos(origItem, posItem)

    local addItem = instanceItem(origItem:getFullType());

	local worldItem = posItem:getWorldItem();

	local worldOffX = worldItem:getOffX();
	local worldOffY = worldItem:getOffY();
	local worldOffZ = worldItem:getOffZ();

	local tileX = worldItem:getWorldPosX() - worldOffX;
	local tileY = worldItem:getWorldPosY() - worldOffY;
	local tileZ = worldItem:getWorldPosZ() - worldOffZ;

	addItem:setWorldXRotation(posItem:getWorldXRotation());
	addItem:setWorldYRotation(posItem:getWorldYRotation());
	addItem:setWorldZRotation(posItem:getWorldZRotation());

	local cell = getWorld():getCell();

	if cell:getGridSquare(tileX, tileY, tileZ) then

		local gridSquare = cell:getGridSquare(tileX, tileY, tileZ);

		gridSquare:AddWorldInventoryItem(addItem, worldOffX, worldOffY, worldOffZ);

	end

    origItem:Remove();

end

function ammoMakerAddItemToInventory(inventory, instance)

    inventory:AddItem(instance);
    sendAddItemToContainer(inventory, instance);

end

function ammoMakerAddItemTypeToInventory(inventory, itemType, count)

    for i=1,count do

        local instance = instanceItem(itemType);
        ammoMakerAddItemToInventory(inventory, instance);

    end

end

function ammoMakerRemoveItemFromInventory(inventory, instance)

    inventory:Remove(instance);
    sendRemoveItemFromContainer(inventory, instance);

end

function ammoMakerAddItemTypeToWorld(square, itemType)

    local squareX = square:getX();
    local squareY = square:getY();
    local squareZ = square:getZ();

    square:AddWorldInventoryItem(itemType, 0.0, 0.0, 0.0);
    ammoMakerItemCleanUpAddModData(itemType, squareX, squareY, squareZ);

end