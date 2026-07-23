
local SPNCC_Commands = {}
local Commands = {}
local function _isBlank(value)
    return value == nil or tostring(value) == ""
end

local function _safeBool(callback)
    local ok, value = pcall(callback)
    return ok and value == true
end

local function _getFullType(item)
    if not item or not item.getFullType then return nil end

    local ok, value = pcall(function()
        return item:getFullType()
    end)

    if ok and value then
        return tostring(value)
    end

    return nil
end

local function _getBodyLocation(item)
    if not item then return nil end

    if item.getBodyLocation then
        local ok, value = pcall(function()
            return item:getBodyLocation()
        end)

        if ok and value ~= nil and tostring(value) ~= "" then
            return value
        end
    end

    local scriptItem = item.getScriptItem and item:getScriptItem() or nil
    if scriptItem and scriptItem.getBodyLocation then
        local ok, value = pcall(function()
            return scriptItem:getBodyLocation()
        end)

        if ok and value ~= nil and tostring(value) ~= "" then
            return value
        end
    end

    return nil
end

local function _findWornItemByFullType(player, fullType)
    local wornItems = player and player.getWornItems and player:getWornItems() or nil
    if not wornItems then return nil end

    for i = 0, wornItems:size() - 1 do
        local item = wornItems:getItemByIndex(i)
        if _getFullType(item) == fullType then
            return item
        end
    end

    return nil
end

local function _findInventoryItemByFullType(player, fullType)
    local inventory = player and player.getInventory and player:getInventory() or nil
    local items = inventory and inventory.getItems and inventory:getItems() or nil
    if not items then return nil end

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if _getFullType(item) == fullType then
            return item
        end
    end

    return nil
end

local function _createItem(fullType)
    local ok, item = pcall(function()
        return instanceItem(fullType)
    end)

    if ok and item then return item end

    if InventoryItemFactory and InventoryItemFactory.CreateItem then
        ok, item = pcall(function()
            return InventoryItemFactory.CreateItem(fullType)
        end)

        if ok and item then return item end
    end

    return nil
end

local function _wearHiddenWoundItem(player, fullType)
    if not player or _isBlank(fullType) then return false end
    fullType = tostring(fullType)

    if _findWornItemByFullType(player, fullType) then
        return false
    end

    local inventory = player:getInventory()
    if not inventory then return false end

    local item = _findInventoryItemByFullType(player, fullType)
    local created = false

    if not item then
        item = _createItem(fullType)
        if not item then return false end

        inventory:AddItem(item)
        created = true
    end

    local bodyLocation = _getBodyLocation(item)
    if _isBlank(bodyLocation) then
        if created then inventory:Remove(item) end
        return false
    end

    local ok = pcall(function()
        player:setWornItem(bodyLocation, item)
    end)

    if not ok then
        if created then inventory:Remove(item) end
        return false
    end

    return true
end

local function _getWoundModel(bodyPart, woundType, gender)
    if not bodyPart or not gender then return nil end

    local partType = bodyPart:getType()
    if not partType then return nil end

    local ok, value

    if woundType == "bite" then
        ok, value = pcall(function()
            return partType:getBiteWoundModel(gender)
        end)
    elseif woundType == "scratch" then
        ok, value = pcall(function()
            return partType:getScratchWoundModel(gender)
        end)
    elseif woundType == "cut" then
        ok, value = pcall(function()
            return partType:getCutWoundModel(gender)
        end)
    end

    if ok and not _isBlank(value) then
        return tostring(value)
    end

    return nil
end

local function _ensureVanillaWoundModels(player)
    if not player or not player.getBodyDamage then return false end

    local bodyDamage = player:getBodyDamage()
    if not bodyDamage or not bodyDamage.getBodyParts then return false end

    local okGender, gender = pcall(function()
        return player:getCharacterGender()
    end)

    if not okGender or not gender then return false end

    local bodyParts = bodyDamage:getBodyParts()
    if not bodyParts then return false end

    local changed = false

    for i = 0, bodyParts:size() - 1 do
        local bodyPart = bodyParts:get(i)

        if bodyPart then
            if _safeBool(function() return bodyPart:bitten() end) then
                changed = _wearHiddenWoundItem(player, _getWoundModel(bodyPart, "bite", gender)) or changed
            end

            if _safeBool(function() return bodyPart:scratched() end) then
                changed = _wearHiddenWoundItem(player, _getWoundModel(bodyPart, "scratch", gender)) or changed
            end

            if _safeBool(function() return bodyPart:isCut() end) then
                changed = _wearHiddenWoundItem(player, _getWoundModel(bodyPart, "cut", gender)) or changed
            end
        end
    end

    return changed
end

local function _resetModelAfterBodyDamageVisuals(player)
    if not player then return end

    _ensureVanillaWoundModels(player)

    if player.resetModelNextFrame then
        player:resetModelNextFrame()
    elseif player.resetModel then
        player:resetModel()
    end
end
	-------------------------------------
	-- COMMANDS
	-------------------------------------

function Commands.SetPlayerModData(args)
	local player = getPlayer()
	player:getModData().SPNCharCustom = args.data
	player:resetModel()
	triggerEvent("OnClothingUpdated", player)
end

function Commands.SetPlayerModDataValues(args)
	local player = getPlayer()
	local data = player:getModData().SPNCharCustom
    for k, v in pairs(args.values) do
        data[k] = v
    end
	player:resetModel()
	triggerEvent("OnClothingUpdated", player)
end

function Commands.OpenCharacterCustomisationWindow(args)
	local FaceManager_Shared = require("CharacterCustomisation/FaceManager_Shared")
	FaceManager_Shared.OpenCharacterCustomisationWindow(getPlayer(), true)
end

function Commands.OnClothingUpdated(args)
	local player = getPlayer()
	triggerEvent("OnClothingUpdated", player)
	player:resetModel()
end

function Commands.ResetModelOnly(args)
    local player = getPlayer()
    if not player then return end

    _resetModelAfterBodyDamageVisuals(player)
end

	-------------------------------------
	-- SETUP
	-------------------------------------
local DEBUG_SPNCC_COMMANDS = false

local function _debugCommand(command)
	if not DEBUG_SPNCC_COMMANDS then return end
	print("[SPNCC] Server command received: " .. tostring(command))
end

local function onServerCommand(module, command, args)
	if module ~= "SPNCC" then return end

	local handler = Commands[command]
	if not handler then return end

	_debugCommand(command)
	handler(args or {})
end

Events.OnServerCommand.Add(onServerCommand)
