require "TimedActions/ISBaseTimedAction"
require "TimedActions/TABAS_ImprovedTubAction"

TABAS_ImprovedShowerAction = ISBaseTimedAction:derive("TABAS_ImprovedShowerAction")

local TABAS_BathTransformDefs = require("TABAS_BathTransformDefs")
local TABAS_Iso = require("TABAS_Iso")

local SHOWER_MODE = TABAS_BathTransformDefs.SHOWER_MODE

local function resolveTrackedItem(character, item)
    if not item then return nil end
    if isClient() and character then
        item = character:getInventory():getItemById(item:getID())
    end
    return item
end

local function hasRequiredItems(character, items)
    if not items then return true end

    local playerInv = character:getInventory()
    for name, count in pairs(items) do
        if playerInv:getCountTypeRecurse(name) < count then
            return false
        end
    end
    return true
end

function TABAS_ImprovedShowerAction:isValid()
    if not self.object or not TABAS_Iso.isShowerObject(self.object, false) then return false end

    local modeDef = TABAS_BathTransformDefs.getShowerModeDef(self.mode)
    if not modeDef then return false end

    local item = self.character:getPrimaryHandItem()
    if not item or item:isBroken() or not item:hasTag(modeDef.toolTag) then
        return false
    end

    if self.mode == SHOWER_MODE.UNINSTALL then
        return true
    end

    if self.mode == SHOWER_MODE.UPGRADE then
        return hasRequiredItems(self.character, self.items)
    end

    return true
end

function TABAS_ImprovedShowerAction:waitToStart()
    self.character:faceDirection(self.faceDir)
    return self.character:shouldBeTurning()
end

function TABAS_ImprovedShowerAction:update()
    if self.progressItem then
        self.progressItem:setJobDelta(self:getJobDelta())
    end
    self.character:faceDirection(self.faceDir)
    local modeDef = TABAS_BathTransformDefs.getShowerModeDef(self.mode)
    if modeDef and modeDef.metabolicTarget then
        self.character:setMetabolicTarget(modeDef.metabolicTarget)
    end
end

function TABAS_ImprovedShowerAction:start()
    if isClient() then
        self.progressItem = resolveTrackedItem(self.character, self.progressItem)
    end

    local primaryItem = self.character:getPrimaryHandItem()
    local modeDef = TABAS_BathTransformDefs.getShowerModeDef(self.mode)
    if not modeDef then return end

    self:setOverrideHandModels(primaryItem, nil)
    if self.progressItem and modeDef.jobTypeKey then
        self.progressItem:setJobType(getText(modeDef.jobTypeKey))
        self.progressItem:setJobDelta(0.0)
    end

    self:setActionAnim(modeDef.actionAnim)
    if modeDef.actionAnim == "Loot" then
        self:setAnimVariable("LootPosition", "")
        self.character:reportEvent("EventLootItem")
    end

    if modeDef.sound then
        self.sound = self.character:playSound(modeDef.sound)
    end
end

function TABAS_ImprovedShowerAction:stop()
    if self.sound then
        self.character:stopOrTriggerSound(self.sound)
    end
    if self.progressItem then
        self.progressItem:setJobDelta(0.0)
    end
    ISBaseTimedAction.stop(self)
end

function TABAS_ImprovedShowerAction:perform()
    if self.sound then
        self.character:stopOrTriggerSound(self.sound)
    end
    if self.progressItem then
        self.progressItem:setJobDelta(0.0)
    end
    local modeDef = TABAS_BathTransformDefs.getShowerModeDef(self.mode)
    if modeDef and modeDef.dirtyUI then
        ISInventoryPage.dirtyUI()
    end
    ISBaseTimedAction.perform(self)
end

function TABAS_ImprovedShowerAction.replaceObject(oldObj, sq, newSpriteName, customModData)
    if not oldObj or not sq or not newSpriteName or newSpriteName == "" then
        return nil
    end

    local newObj = IsoObject.new(getCell(), sq, newSpriteName)
    local newModData = newObj:getModData()
    if oldObj:hasModData() then
        local md = oldObj:getModData()
        for k, v in pairs(md) do
            newModData[k] = v
        end
    end

    if customModData and type(customModData) == "table" then
        for k, v in pairs(customModData) do
            newModData[k] = v
        end
    end

    local overlay = oldObj:getOverlaySprite()
    if overlay then
        newObj:setOverlaySprite(overlay:getName(), true)
    end

    local attached = oldObj:getAttachedAnimSprite()
    if attached and not attached:isEmpty() then
        newObj:setAttachedAnimSprite(attached)
    end

    if oldObj:getUsesExternalWaterSource() and not oldObj:getModData().canBeWaterPiped then
        newModData.canBeWaterPiped = false
        newObj:setUsesExternalWaterSource(true)
        newObj:sendObjectChange(IsoObjectChange.USES_EXTERNAL_WATER_SOURCE, { value = true })
    end

    sq:transmitRemoveItemFromSquareOnClients(oldObj)
    if oldObj:isExistInTheWorld() then
        sq:RemoveTileObject(oldObj)
    end

    sq:AddTileObject(newObj)
    newObj:transmitCompleteItemToClients()
    newObj:transmitModData()
    triggerEvent("OnObjectAdded", newObj)
    sq:RecalcPropertiesIfNeeded()

    return newObj
end

function TABAS_ImprovedShowerAction:complete()
    if isClient() then return true end

    local showerObj = TABAS_Iso.getShowerObjectOnSquare(self.square, false)
    if not showerObj then return false end

    if self.mode == SHOWER_MODE.UNINSTALL then
        self.square:transmitRemoveItemFromSquareOnClients(showerObj)
        self.square:RemoveTileObject(showerObj)
        self.square:RecalcPropertiesIfNeeded()

        local playerInv = self.character:getInventory()
        local item = instanceItem("TABAS.WallShowerPacked")
        if item then
            playerInv:AddItem(item)
            sendAddItemToContainer(playerInv, item)
            playerInv:Remove(item)
            sendRemoveItemFromContainer(playerInv, item)
            self.square:AddWorldInventoryItem(item, ZombRandFloat(0.1, 0.9), ZombRandFloat(0.1, 0.9), 0)
        end

        TABAS_ImprovedTubAction.spawnScrapFromSpriteName(self.character, self.square, showerObj:getSpriteName())
        return true
    end

    local defsBySprite = TABAS_Iso.getSpritesTable("Index", "ShowerDefBySprite")
    local currentDef = defsBySprite and defsBySprite[showerObj:getSpriteName()]
    local targetDef = TABAS_BathTransformDefs.resolveShowerTargetModelDef(self.mode, currentDef)
    local facing = TABAS_Iso.getObjectFacing(showerObj)
    local targetSpriteName = targetDef and facing and targetDef["sprite" .. facing]
    if not currentDef or not targetDef or not targetSpriteName or targetSpriteName == "" then
        return false
    end

    if self.mode == SHOWER_MODE.UPGRADE then
        local playerInv = self.character:getInventory()
        for name, count in pairs(self.items) do
            for i = 1, count do
                local item = playerInv:getFirstTypeRecurse(name)
                if item then
                    playerInv:Remove(item)
                    sendRemoveItemFromContainer(playerInv, item)
                end
            end
        end
        addXpNoMultiplier(self.character, Perks.Woodwork, 6)
    end

    TABAS_ImprovedShowerAction.replaceObject(showerObj, self.square, targetSpriteName, {
        isImproved = targetDef.isImproved,
    })
    return true
end

function TABAS_ImprovedShowerAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end

    local modeDef = TABAS_BathTransformDefs.getShowerModeDef(self.mode)
    return modeDef and modeDef.duration or 400
end

function TABAS_ImprovedShowerAction:new(character, square, mode, progressItem, materials)
    local o = ISBaseTimedAction.new(self, character)
    o.square = square
    o.object = TABAS_Iso.getShowerObjectOnSquare(square, false)
    local dir = o.object and o.object:getFacing()
    o.faceDir = dir and dir:Rot180() or IsoDirections.E
    o.mode = mode
    o.items = materials
    o.progressItem = progressItem
    o.maxTime = o:getDuration()
    return o
end

return TABAS_ImprovedShowerAction
