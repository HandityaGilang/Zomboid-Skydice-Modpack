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

    else

        return nil

    end

end

function ammoMakerAddCasingToInventory(square, inventory, brassCatcherImprovised, brassCatcherAdvanced, casing, optional)

    local targetInventory = nil;

    local addWeight = getScriptManager():FindItem(casing):getActualWeight();
    if optional ~= "" then
        addWeight = addWeight + getScriptManager():FindItem(optional):getActualWeight();
    end

    if inventory:getCapacity() > inventory:getCapacityWeight() + addWeight then

        targetInventory = ammoMakerGetContainerWithSpace(brassCatcherAdvanced, addWeight);

        if not targetInventory then
            targetInventory = ammoMakerGetContainerWithSpace(brassCatcherImprovised, addWeight);
        end

        if not targetInventory then
            targetInventory = inventory;
        end

        targetInventory:AddItems(casing, 1);
        if optional ~= "" then
            targetInventory:AddItems(optional, 1);
        end

    else

        ammoMakerAddCasingToWorld(square, casing, optional);

    end

end

function ammoMakerAddCasingToWorld(square, casing, optional)

    local squareX = square:getX();
    local squareY = square:getY();
    local squareZ = square:getZ();

    local function addCasingToModDataClient(item, squareX, squareY, squareZ)

        local currentTime = getWorld():getWorldAgeDays();

        local droppedCasingsSaveID = "droppedCasings";
        local droppedCasingsTable = ModData.getOrCreate(droppedCasingsSaveID);

        local droppedCasingDataNew = item .. ";" .. squareX .. ";" .. squareY .. ";" .. squareZ .. ";" .. currentTime;

        table.insert(droppedCasingsTable, droppedCasingDataNew);

        ModData.add(droppedCasingsSaveID, droppedCasingsTable);

        if getWorld():getGameMode() == "Multiplayer" then

            ModData.transmit(droppedCasingsSaveID);

        end

    end
                    
    square:AddWorldInventoryItem(casing, 0.0, 0.0, 0.0);
    addCasingToModDataClient(casing, squareX, squareY, squareZ);
    if optional ~= "" then
        square:AddWorldInventoryItem(optional, 0.0, 0.0, 0.0);
        addCasingToModDataClient(optional, squareX, squareY, squareZ);
    end
                    
end

function ammoMakerIsValueInTable(table, value)

    for _, v in ipairs(table) do

        if v == value then

            return true

        end

    end

    return false

end

function ammoMakerWorldAddItemAtItemPos(addItem, posItem)

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

end

function ammoMakerTableArrayConcat(t1, a1)

    for i=0,a1:size()-1 do

        table.insert(t1, a1:get(i))

    end

    return t1

end