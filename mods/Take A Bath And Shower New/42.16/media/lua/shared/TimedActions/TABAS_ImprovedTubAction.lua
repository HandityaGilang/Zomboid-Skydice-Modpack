require "TimedActions/ISBaseTimedAction"

TABAS_ImprovedTubAction = ISBaseTimedAction:derive("TABAS_ImprovedTubAction")

local TABAS_BathTransformDefs = require("TABAS_BathTransformDefs")
local TABAS_Iso = require("TABAS_Iso")
local TABAS_Utils = require("TABAS_Utils")

local TUB_MODE = TABAS_BathTransformDefs.TUB_MODE

function TABAS_ImprovedTubAction:isValid()
    if not self.faucetObj or not TABAS_Iso.isBathFaucet(self.faucetObj) then return false end

    local modeDef = TABAS_BathTransformDefs.getBathtubModeDef(self.mode)
    if not modeDef then return false end

    local item = self.character:getPrimaryHandItem()
    if not item or item:isBroken() then return false end

    if self.mode == TUB_MODE.CLEAN then
        local playerInv = self.character:getInventory()
        if not TABAS_Utils.predicateCleanStainsTool(item) then
            return false
        end
        return (playerInv:containsEvalRecurse(TABAS_Utils.predicateBleach) or playerInv:containsEvalRecurse(TABAS_Utils.predicateCleaningLiquid))
    end

    if not item:hasTag(ItemTag.PIPE_WRENCH) then return false end

    if self.mode == TUB_MODE.INSTALL then
        return self.consumeItem ~= nil and self.consumeItem:getContainer() ~= nil
    end
    return true
end

function TABAS_ImprovedTubAction:waitToStart()
    self.character:faceThisObject(self.faucetObj)
    return self.character:shouldBeTurning()
end

function TABAS_ImprovedTubAction:update()
    if self.progressItem then
        self.progressItem:setJobDelta(self:getJobDelta())
    end

    if self.mode == TUB_MODE.CLEAN then
        local jobDelta = self:getJobDelta()
        if jobDelta < 0.5 then
            self.character:faceLocation(self.faucetSq:getX() + 0.5, self.faucetSq:getY() + 0.5)
        else
            self.character:faceLocation(self.tubSq:getX() + 0.5, self.tubSq:getY() + 0.5)
        end
    end

    local modeDef = TABAS_BathTransformDefs.getBathtubModeDef(self.mode)
    if modeDef and modeDef.metabolicTarget then
        self.character:setMetabolicTarget(modeDef.metabolicTarget)
    end
end

function TABAS_ImprovedTubAction:start()
    if isClient() then
        local playerInv = self.character:getInventory()
        if self.consumeItem then self.consumeItem = playerInv:getItemById(self.consumeItem:getID()) end
        if self.cleaner then self.cleaner = playerInv:getItemById(self.cleaner:getID()) end
        if self.progressItem then self.progressItem = playerInv:getItemById(self.progressItem:getID()) end
    end

    local primaryItem = self.character:getPrimaryHandItem()
    local modeDef = TABAS_BathTransformDefs.getBathtubModeDef(self.mode)
    if not modeDef then return end

    if self.mode == TUB_MODE.CLEAN then
        local twoHanded = false
        local toiletBrush = false
        if primaryItem then
            twoHanded = (instanceof(primaryItem, "HandWeapon") and primaryItem:isTwoHandWeapon())
            toiletBrush = primaryItem:hasTag(ItemTag.TOILET_BRUSH)
        end
        if twoHanded then
            self:setActionAnim("ScrubFloor_Mop")
            self:setOverrideHandModels(primaryItem, nil)
            self.sound = self.character:playSound("CleanBloodScrub")
        elseif toiletBrush then
            self:setActionAnim("ScrubFloor_ToiletBrush")
            self:setOverrideHandModels(primaryItem, nil)
            self.sound = self.character:playSound("CleanBloodScrub")
        else
            self:setActionAnim("ScrubFloor")
            self:setOverrideHandModels(primaryItem, self.cleaner)
            self.sound = self.character:playSound("CleanBloodBleach")
        end
        self.character:reportEvent("EventCleanBlood")
    else
        self:setActionAnim(modeDef.actionAnim)
        self:setAnimVariable("LootPosition", "")
        self:setOverrideHandModels(primaryItem, nil)
        self.character:reportEvent("EventLootItem")
        if modeDef.sound then
            self.sound = self.character:playSound(modeDef.sound)
        end
    end

    if self.progressItem and modeDef.jobTypeKey then
        self.progressItem:setJobType(getText(modeDef.jobTypeKey))
        self.progressItem:setJobDelta(0.0)
    end
end

function TABAS_ImprovedTubAction:stop()
    if self.sound then
        self.character:stopOrTriggerSound(self.sound)
    end
    if self.progressItem then
        self.progressItem:setJobDelta(0.0)
    end
    ISBaseTimedAction.stop(self)
end

function TABAS_ImprovedTubAction:perform()
    if self.sound then
        self.character:stopOrTriggerSound(self.sound)
    end
    if self.progressItem then
        self.progressItem:setJobDelta(0.0)
    end
    local modeDef = TABAS_BathTransformDefs.getBathtubModeDef(self.mode)
    if modeDef and modeDef.dirtyUI then
        ISInventoryPage.dirtyUI()
    end
    ISBaseTimedAction.perform(self)
end

function TABAS_ImprovedTubAction.replaceObject(oldObj, sq, newSpriteKey, customModData)
    if not oldObj or not sq then return nil end
    local oldSprite = oldObj:getSprite() and oldObj:getSprite():getName()
    if not oldSprite then return nil end

    local newSpriteName
    local targetDef = customModData and customModData.targetDef or nil
    if targetDef then
        local facing = TABAS_Iso.getObjectFacing(oldObj)
        local partBySprite = TABAS_Iso.getSpritesTable("Index", "BathPartBySprite")
        local part = partBySprite and partBySprite[oldSprite] or nil
        local dir = facing and targetDef["sprite" .. facing] or nil
        newSpriteName = type(dir) == "table" and part and dir[part] or nil
        if not newSpriteName or not getSprite(newSpriteName) then
            print("[TABAS] BathtubTransformAction: Invalid target sprite!", oldSprite)
            return nil
        end
    else
        local index = oldSprite and tonumber(oldSprite:match("(%d+)$"))
        if not index or not getSprite(newSpriteKey .. "_" .. index) then
            print("[TABAS] BathtubTransformAction: Invalid sprite index!", oldSprite)
            return nil
        end
        newSpriteName = newSpriteKey .. "_" .. index
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
            if k ~= "targetDef" then
                newModData[k] = v
            end
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
    if isClient() then return true end

    local faucetObj = TABAS_Iso.getBathObjectOnSquare(self.faucetSq)
    local tubObj = TABAS_Iso.getBathObjectOnSquare(self.tubSq)
    if not faucetObj or not tubObj then return true end

    local defsBySprite = TABAS_Iso.getSpritesTable("Index", "BathtubDefBySprite")
    local currentDef = defsBySprite and defsBySprite[faucetObj:getSpriteName()]
    local targetDef = TABAS_BathTransformDefs.resolveBathtubTargetModelDef(self.mode, currentDef)
    if not currentDef or not targetDef or not targetDef.spriteKey then
        return false
    end

    if self.mode == TUB_MODE.INSTALL then
        local playerInv = self.character:getInventory()
        playerInv:Remove(self.consumeItem)
        sendRemoveItemFromContainer(playerInv, self.consumeItem)
    elseif self.mode == TUB_MODE.UNINSTALL then
        local playerInv = self.character:getInventory()
        local square = self.character:getCurrentSquare()
        local item = square and instanceItem("TABAS.WallShowerPacked")
        if item then
            playerInv:AddItem(item)
            sendAddItemToContainer(playerInv, item)
            playerInv:Remove(item)
            sendRemoveItemFromContainer(playerInv, item)
            square:AddWorldInventoryItem(item, ZombRandFloat(0.1, 0.9), ZombRandFloat(0.1, 0.9), 0)
        end
    elseif self.mode == TUB_MODE.DISASSEMBLE then
        TABAS_ImprovedTubAction.spawnScrapFromSpriteName(self.character, self.character:getCurrentSquare(), "fixtures_bathroom_01_30")
    elseif self.mode == TUB_MODE.CLEAN then
        local container = self.cleaner:getFluidContainer()
        if container then
            container:adjustAmount(container:getAmount() - ZomboidGlobals.CleanBloodBleachAmount)
        end
    end

    local modData = {
        isClean = targetDef.isClean,
        isImproved = targetDef.isImproved,
        targetDef = targetDef,
    }
    TABAS_ImprovedTubAction.replaceObject(faucetObj, self.faucetSq, targetDef.spriteKey, modData)
    TABAS_ImprovedTubAction.replaceObject(tubObj, self.tubSq, targetDef.spriteKey, modData)
    return true
end

function TABAS_ImprovedTubAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end

    local modeDef = TABAS_BathTransformDefs.getBathtubModeDef(self.mode)
    return modeDef and modeDef.duration or 400
end

function TABAS_ImprovedTubAction:new(character, faucetSq, tubSq, mode, tool, consumeItem, cleaner)
    local o = ISBaseTimedAction.new(self, character)
    o.faucetSq = faucetSq
    o.faucetObj = TABAS_Iso.getBathObjectOnSquare(faucetSq)
    o.tubSq = tubSq
    o.tubObj = TABAS_Iso.getBathObjectOnSquare(tubSq)
    o.mode = mode
    o.tool = tool
    o.consumeItem = consumeItem
    o.cleaner = cleaner
    o.progressItem = tool or consumeItem or cleaner
    o.maxTime = o:getDuration()
    return o
end

return TABAS_ImprovedTubAction
