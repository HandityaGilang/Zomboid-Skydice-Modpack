require "Moveables/ISMoveableSpriteProps"

ComputerModMoveablePersistence = ComputerModMoveablePersistence or {}

local function isComputerSpriteName(spriteName)
    if not spriteName then return false end
    local value = string.lower(tostring(spriteName))
    return value == "appliances_com_01_72"
        or value == "appliances_com_01_73"
        or value == "appliances_com_01_74"
        or value == "appliances_com_01_75"
        or value == "appliances_com_01_76"
        or value == "appliances_com_01_77"
        or value == "appliances_com_01_78"
        or value == "appliances_com_01_79"
end

local computerMoveableSprites = {
    appliances_com_01_76 = "appliances_com_01_72",
    appliances_com_01_77 = "appliances_com_01_73",
    appliances_com_01_78 = "appliances_com_01_74",
    appliances_com_01_79 = "appliances_com_01_75"
}

local function getSpriteName(sprite)
    if type(sprite) == "string" then return sprite end
    return sprite and sprite.getName and sprite:getName() or nil
end

local function getMoveableSpriteName(sprite)
    local spriteName = getSpriteName(sprite)
    if not spriteName then return nil end
    return computerMoveableSprites[string.lower(tostring(spriteName))]
end

local function isComputerObject(object)
    if not object or not object.getSprite then return false end
    local sprite = object:getSprite()
    local spriteName = sprite and sprite.getName and sprite:getName() or nil
    return isComputerSpriteName(spriteName)
end

local function copyValue(value, seen)
    local valueType = type(value)
    if valueType ~= "table" then
        return value
    end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local result = {}
    seen[value] = result
    for k, v in pairs(value) do
        local keyType = type(k)
        if keyType == "string" or keyType == "number" or keyType == "boolean" then
            local copied = copyValue(v, seen)
            local copiedType = type(copied)
            if copiedType ~= "function" and copiedType ~= "thread" and copiedType ~= "userdata" then
                result[k] = copied
            end
        end
    end
    return result
end

local function copyComputerKeys(source, target)
    if type(source) ~= "table" or type(target) ~= "table" then return false end
    local copied = false
    for key, value in pairs(source) do
        if type(key) == "string"
            and string.sub(key, 1, 11) == "ComputerMod"
            and key ~= "ComputerModStoredData"
            and key ~= "ComputerModMovedComputer"
        then
            local copiedValue = copyValue(value)
            local copiedType = type(copiedValue)
            if copiedType ~= "function" and copiedType ~= "thread" and copiedType ~= "userdata" then
                target[key] = copiedValue
                copied = true
            end
        end
    end
    return copied
end

function ComputerModMoveablePersistence.copyObjectData(object)
    if not object or not object.getModData then return nil end
    if not isComputerObject(object) then return nil end
    local objectData = object:getModData()
    if type(objectData) ~= "table" then return nil end
    local savedData = {}
    if copyComputerKeys(objectData, savedData) then
        return savedData
    end
    return nil
end

function ComputerModMoveablePersistence.saveDataToItem(savedData, item)
    if type(savedData) ~= "table" or not item or not item.getModData then return end
    local itemData = item:getModData()
    if type(itemData) ~= "table" then return end
    copyComputerKeys(savedData, itemData)
    itemData.ComputerModMovedComputer = true
    itemData.ComputerModStoredData = copyValue(savedData)
    if item.transmitModData then
        pcall(function() item:transmitModData() end)
    end
end

function ComputerModMoveablePersistence.saveToItem(object, item)
    ComputerModMoveablePersistence.saveDataToItem(ComputerModMoveablePersistence.copyObjectData(object), item)
end

function ComputerModMoveablePersistence.restoreToObject(item, object)
    if not item or not object or not item.getModData or not object.getModData then return end
    if not isComputerObject(object) then return end
    local itemData = item:getModData()
    if type(itemData) ~= "table" then return end
    local objectData = object:getModData()
    if type(objectData) ~= "table" then return end
    local restored = false
    if type(itemData.ComputerModStoredData) == "table" then
        restored = copyComputerKeys(itemData.ComputerModStoredData, objectData) or restored
    end
    restored = copyComputerKeys(itemData, objectData) or restored
    if restored then
        objectData.ComputerModMetaInitialized = true
        objectData.ComputerModStoredData = nil
        objectData.ComputerModMovedComputer = nil
        if object.transmitModData then
            pcall(function() object:transmitModData() end)
        end
        if isServer and isServer() and object.transmitCompleteItemToClients then
            pcall(function() object:transmitCompleteItemToClients() end)
        end
    end
end

if ISMoveableSpriteProps and not ComputerModMoveablePersistencePatched then
    ComputerModMoveablePersistencePatched = true

    local originalNew = ISMoveableSpriteProps.new
    function ISMoveableSpriteProps.new(sprite)
        local moveableSpriteName = getMoveableSpriteName(sprite)
        if not moveableSpriteName then
            return originalNew(sprite)
        end
        local properties = originalNew(moveableSpriteName)
        local worldSprite = type(sprite) == "string" and getSprite and getSprite(sprite) or sprite
        if properties and worldSprite then
            properties.sprite = worldSprite
            properties.spriteName = getSpriteName(worldSprite)
            properties.computerModMoveableSprite = moveableSpriteName
        end
        return properties
    end

    local originalInstanceItem = ISMoveableSpriteProps.instanceItem
    function ISMoveableSpriteProps:instanceItem(_spriteNameOverride)
        local moveableSpriteName = self.computerModMoveableSprite or getMoveableSpriteName(_spriteNameOverride)
        local currentSpriteName = self.spriteName
        if moveableSpriteName then
            self.spriteName = moveableSpriteName
        end
        local item = originalInstanceItem(self, moveableSpriteName or _spriteNameOverride)
        self.spriteName = currentSpriteName
        ComputerModMoveablePersistence.saveDataToItem(ComputerModMoveablePersistence.pendingData, item)
        return item
    end

    local originalPickUpMoveableInternal = ISMoveableSpriteProps.pickUpMoveableInternal
    function ISMoveableSpriteProps:pickUpMoveableInternal(_character, _square, _object, _sprInstance, _spriteName, _createItem, _rotating)
        local previousPendingData = ComputerModMoveablePersistence.pendingData
        ComputerModMoveablePersistence.pendingData = ComputerModMoveablePersistence.copyObjectData(_object)
        local item = originalPickUpMoveableInternal(self, _character, _square, _object, _sprInstance, _spriteName, _createItem, _rotating)
        ComputerModMoveablePersistence.pendingData = previousPendingData
        ComputerModMoveablePersistence.saveToItem(_object, item)
        return item
    end

    local originalPlaceMoveableInternal = ISMoveableSpriteProps.placeMoveableInternal
    function ISMoveableSpriteProps:placeMoveableInternal(_square, _item, _spriteName)
        local object = originalPlaceMoveableInternal(self, _square, _item, _spriteName)
        ComputerModMoveablePersistence.restoreToObject(_item, object)
        return object
    end
end
