require "TimedActions/ISBaseTimedAction"

TABAS_ImprovedShowerAction = ISBaseTimedAction:derive("TABAS_ImprovedShowerAction")

local TABAS_Iso = require("TABAS_Iso")
local MODE_UPGRADE = "upgrade"
local MODE_UNINSTALL = "uninstall"
local MODE_IMPROVE = "improve"
local TARGET_MODEL = "Improved Deluxe"

local function refreshTrackedItem(character, item)
    if not item then return nil end
    if isClient() and character then
        item = character:getInventory():getItemById(item:getID())
    end
    if item and item:getContainer() == nil then
        item = nil
    end
    return item
end

local function getJobItem(character, items)
    if not character or not items then return nil end
    local playerInv = character:getInventory()
    if not playerInv then return nil end

    for name, count in pairs(items) do
        if count and count > 0 then
            local item = playerInv:getFirstTypeRecurse(name)
            if item then
                return item
            end
        end
    end
    return nil
end

local function hasRequiredItems(character, items)
    if not items then return true end
    local playerInv = character:getInventory()
    if not playerInv then return false end
    for name, count in pairs(items) do
        if playerInv:getCountTypeRecurse(name) < count then
            return false
        end
    end
    return true
end

function TABAS_ImprovedShowerAction:isValid()
    if self.newSpriteName ~= nil and self.newSpriteName == "" then
        return false
    end
	local item = self.character:getPrimaryHandItem()
    if not item then
        return false
    end
    local hasTag = false
    if self.mode == MODE_IMPROVE then
        hasTag = item:hasTag(ItemTag.SAW)
    elseif self.mode == MODE_UNINSTALL then
        hasTag = item:hasTag(ItemTag.PIPE_WRENCH)
    else
        hasTag = item:hasTag(ItemTag.HAMMER)
    end
    if item:isBroken() or not hasTag then
        return false
    end
    if self.mode == MODE_UPGRADE then
        return hasRequiredItems(self.character, self.items)
    end
	return true
end

function TABAS_ImprovedShowerAction:waitToStart()
    self.character:faceDirection(self.faceDir)
	return self.character:shouldBeTurning()
end

function TABAS_ImprovedShowerAction:update()
    self.jobItem = refreshTrackedItem(self.character, self.jobItem)
    if self.jobItem then
        self.jobItem:setJobDelta(self:getJobDelta())
        if self.jobItem:getContainer() == nil then
            self.jobItem = nil
        end
    end
    self.character:faceDirection(self.faceDir)
    self.character:setMetabolicTarget(Metabolics.HeavyWork)
end

function TABAS_ImprovedShowerAction:start()
    local primaryItem = self.character:getPrimaryHandItem()
    self:setOverrideHandModels(primaryItem, nil)
    self.jobItem = refreshTrackedItem(self.character, self.jobItem)
    if self.jobItem then
        self.jobItem:setJobType(getText("ContextMenu_TABAS_UpgradeShower"))
        self.jobItem:setJobDelta(0.0)
    end
    if self.mode == MODE_IMPROVE then
        self:setActionAnim("SawLog")
        self:setAnimVariable("LootPosition", "")
        self.sound = self.character:playSound("Sawing")
    elseif self.mode == MODE_UNINSTALL then
        self:setActionAnim("Loot")
        self:setAnimVariable("LootPosition", "")
        self.character:reportEvent("EventLootItem")
        self.sound = self.character:playSound("RepairWithWrench")
    else
        self:setActionAnim("BuildLow")
    end
end

function TABAS_ImprovedShowerAction:stop()
    if self.sound then
        self.character:stopOrTriggerSound(self.sound)
    end
    self.jobItem = refreshTrackedItem(self.character, self.jobItem)
    if self.jobItem then
        self.jobItem:setJobDelta(0.0)
    end
	ISBaseTimedAction.stop(self)
end

function TABAS_ImprovedShowerAction:perform()
    if self.sound then
        self.character:stopOrTriggerSound(self.sound)
    end
    self.jobItem = refreshTrackedItem(self.character, self.jobItem)
    if self.jobItem then
        self.jobItem:setJobDelta(0.0)
    end
    if self.mode ~= MODE_IMPROVE then
        ISInventoryPage.dirtyUI()
    end
	-- needed to remove from queue / start next.
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
        for k,v in pairs(md) do
            newModData[k] = v
        end
    end

    if customModData and type(customModData) == "table" then
        for k,v in pairs(customModData) do
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

    -- piping if need.
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
    if self.mode == MODE_IMPROVE then
        TABAS_ImprovedShowerAction.replaceObject(self.object, self.square, self.newSpriteName, { isImproved = true })

    elseif self.mode == MODE_UNINSTALL then
        self.square:transmitRemoveItemFromSquareOnClients(self.object)
        self.square:RemoveTileObject(self.object)
        self.square:RecalcPropertiesIfNeeded()

        -- ISMoveableSpriteProps.addOrDropItem(nil, self.character, item)
        local playerInv = self.character:getInventory()
        local item = instanceItem("TABAS.WallShowerPacked")
        if item then
            playerInv:AddItem(item)
            sendAddItemToContainer(playerInv, item)
            
            playerInv:Remove(item)
            sendRemoveItemFromContainer(playerInv, item);
            self.square:AddWorldInventoryItem(item, ZombRandFloat(0.1,0.9), ZombRandFloat(0.1,0.9), 0)
        end

        local spriteName = self.object:getSpriteName()
        TABAS_ImprovedTubAction.spawnScrapFromSpriteName(self.character, self.square, spriteName)

    elseif self.mode == MODE_UPGRADE and self.items then
        local playerInv = self.character:getInventory()
        for name, count in pairs(self.items) do
            for i=1, count do
                local item = playerInv:getFirstTypeRecurse(name)
                if item then
                    playerInv:Remove(item)
                    sendRemoveItemFromContainer(playerInv, item)
                end
            end
        end
        addXpNoMultiplier(self.character, Perks.Woodwork, 6)
        TABAS_ImprovedShowerAction.replaceObject(self.object, self.square, self.newSpriteName, { isImproved = true })
    end

	return true
end

function TABAS_ImprovedShowerAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end

    return 400
end

function TABAS_ImprovedShowerAction.getSameIndexSprite(oldSprite, newSpriteKey)
    local index = oldSprite and tonumber(oldSprite:match("(%d+)$"))
    if not index or not getSprite(newSpriteKey .. "_" .. index) then
        print("[TABAS] ImprovedShowerAction: Invalid sprite index!", oldSprite)
        return nil
    end
    return newSpriteKey .. "_" .. index
end

function TABAS_ImprovedShowerAction.getNewSpriteName(obj, spriteKey)
    local facing = TABAS_Iso.getObjectFacing(obj)
    if not facing then
        print("[TABAS] ImprovedShowerAction: Missing facing for object!")
        return ""
    end
    local spritesTable = TABAS_Iso.getSpritesTable("Shower", spriteKey)
    if not spritesTable then
        print("[TABAS] ImprovedShowerAction: Invalid shower sprites table!", spriteKey)
        return ""
    end
    return spritesTable["sprite" .. facing]
end

local function getFaceDirection(obj)
    if not obj then return IsoDirections.E end
    local facing = TABAS_Iso.getObjectFacing(obj)
    if facing == "N" then
        return IsoDirections.S
    elseif facing == "S" then
        return IsoDirections.N
    elseif facing == "E" then
        return IsoDirections.W
    else
        return IsoDirections.E
    end
end

function TABAS_ImprovedShowerAction:new(character, object, mode, items)
    local o = ISBaseTimedAction.new(self, character)
    o.object = object
    o.square = object:getSquare()
    o.faceDir = getFaceDirection(object)
    o.mode = mode
    o.items = items
    o.jobItem = mode == MODE_UPGRADE and getJobItem(character, items) or nil
    if mode == MODE_IMPROVE or mode == MODE_UPGRADE then
        o.newSpriteName = TABAS_ImprovedShowerAction.getNewSpriteName(object, TARGET_MODEL)
    end

    o.maxTime = o:getDuration()
    -- o.caloriesModifier = 5
    return o
end
