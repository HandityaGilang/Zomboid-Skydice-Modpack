require "TimedActions/ISBaseTimedAction"

TABAS_ImprovedTubAction = ISBaseTimedAction:derive("TABAS_ImprovedTubAction")

local MODE_INSTALL = "install"
local MODE_UNINSTALL = "uninstall"
local MODE_DISASSEMBLE = "disassemble"

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

function TABAS_ImprovedTubAction:isValid()
    self.consumeItem = refreshTrackedItem(self.character, self.consumeItem)
	local item = self.character:getPrimaryHandItem()
    if item == nil or item:isBroken() or not item:hasTag(ItemTag.PIPE_WRENCH) then
        return false
    end
    if self.mode == MODE_INSTALL then
        return self.consumeItem ~= nil
    end
	return true
end

function TABAS_ImprovedTubAction:waitToStart()
    self.character:faceThisObject(self.faucetObj)
	return self.character:shouldBeTurning()
end

function TABAS_ImprovedTubAction:update()
    self.consumeItem = refreshTrackedItem(self.character, self.consumeItem)
    if self.consumeItem then
        self.consumeItem:setJobDelta(self:getJobDelta())
    end
    self.character:setMetabolicTarget(Metabolics.HeavyWork)
end

function TABAS_ImprovedTubAction:start()
    local primaryItem = self.character:getPrimaryHandItem()
	self:setActionAnim("Loot")
    self:setAnimVariable("LootPosition", "")
    self:setOverrideHandModels(primaryItem, nil)
	self.character:reportEvent("EventLootItem")
    self.sound = self.character:playSound("RepairWithWrench")
    self.consumeItem = refreshTrackedItem(self.character, self.consumeItem)
    if self.consumeItem then
        self.consumeItem:setJobType(getText("ContextMenu_TABAS_InstallShower"))
        self.consumeItem:setJobDelta(0.0)
    end
end

function TABAS_ImprovedTubAction:stop()
    self.character:stopOrTriggerSound(self.sound)
    self.consumeItem = refreshTrackedItem(self.character, self.consumeItem)
    if self.consumeItem then
        self.consumeItem:setJobDelta(0.0)
    end
	ISBaseTimedAction.stop(self)
end


function TABAS_ImprovedTubAction:perform()
   self.character:stopOrTriggerSound(self.sound)
   self.consumeItem = refreshTrackedItem(self.character, self.consumeItem)
   if self.consumeItem then
       self.consumeItem:setJobDelta(0.0)
   end
   ISInventoryPage.dirtyUI()
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end

function TABAS_ImprovedTubAction.replaceObject(oldObj, sq, newSpriteKey, customModData)
    if not oldObj or not sq then return nil end
    local oldSprite = oldObj:getSprite() and oldObj:getSprite():getName()
    if not oldSprite then return nil end

    local index = oldSprite and tonumber(oldSprite:match("(%d+)$"))
    if not index or not getSprite(newSpriteKey .. "_" .. index) then
        print("[TABAS] ImprovedTubAction: Invalid sprite index!", oldSprite)
        return nil
    end
    local newSpriteName = newSpriteKey .. "_" .. index

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
    triggerEvent("OnObjectAdded", newObj)

    sq:RecalcPropertiesIfNeeded()
    -- sq:RecalcAllWithNeighbours(true)
    return newObj
end

function TABAS_ImprovedTubAction.spawnScrapFromSpriteName(character, square, spriteName)
    if not spriteName then return 0 end

    local sprite = getSprite(spriteName)
    if not sprite then return 0 end

    local tmpObj = IsoObject.new(getCell(), square, sprite)

    local props = ISMoveableSpriteProps.fromObject(tmpObj)
    if not props or not props.canScrap then return 0 end

    local list = props:getScrapItemsList(character)
    if not list then return 0 end

    local added = props:addAllScrapItemsToSquare(square, list)
    if added == 0 then
        if instanceof(props.object, "IsoThumpable") then
            character:playSound(props.object:getBreakSound())
        elseif not props.customItem then
            character:playSound(IsoThumpable.GetBreakFurnitureSound(props.object:getSprite()))
        else
            local scrapDef = ISMoveableDefinitions:getInstance().getScrapDefinition(props.material)
            if scrapDef ~= nil and scrapDef.sound == "Dismantle" then
                character:playSound("DismantleFailed")
            end
        end
    end
end

function TABAS_ImprovedTubAction:complete()
    local playerInv = self.character:getInventory()
    local md = self.faucetObj:getModData()
    local newSpriteKey
    local improved = nil
    if self.mode == MODE_INSTALL then
        newSpriteKey = md.isClean and "tabas_fixtures_bathroom_01" or "fixtures_bathroom_01"
        if self.consumeItem then
            playerInv:Remove(self.consumeItem)
            sendRemoveItemFromContainer(playerInv, self.consumeItem)
        end
    else
        newSpriteKey = md.isClean and "tabas_fixtures_bathroom_03" or "tabas_fixtures_bathroom_02"
        improved = true
        local sq = self.character:getCurrentSquare()

        if self.mode == MODE_DISASSEMBLE then
            local spriteName = "fixtures_bathroom_01_30"
            TABAS_ImprovedTubAction.spawnScrapFromSpriteName(self.character, sq, spriteName)
        elseif self.mode == MODE_UNINSTALL then
            local item = instanceItem("TABAS.WallShowerPacked")
            if item then
                playerInv:AddItem(item)
                sendAddItemToContainer(playerInv, item)

                playerInv:Remove(item)
                sendRemoveItemFromContainer(playerInv, item);
                sq:AddWorldInventoryItem(item, ZombRandFloat(0.1,0.9), ZombRandFloat(0.1,0.9), 0)
            end
        end
    end
    local modData = { isImproved = improved }

    TABAS_ImprovedTubAction.replaceObject(self.faucetObj, self.faucetSq, newSpriteKey, modData)
    TABAS_ImprovedTubAction.replaceObject(self.tubObj, self.tubSq, newSpriteKey, modData)

	return true
end

function TABAS_ImprovedTubAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 400
end

function TABAS_ImprovedTubAction:new(character, faucetObj, tubObj, mode, consumeItem)
    local o = ISBaseTimedAction.new(self, character)
    o.faucetObj = faucetObj
    o.faucetSq = faucetObj:getSquare()
    o.fauccetSprite = faucetObj:getSpriteName()
    o.tubObj = tubObj
    o.tubSq = tubObj:getSquare()
    o.tubSprite = tubObj:getSpriteName()
    o.mode = mode
    o.consumeItem = consumeItem
    o.maxTime = o:getDuration()
    -- o.caloriesModifier = 5
    return o
end
