require "TimedActions/ISBaseTimedAction"

TABAS_AddBathSalt = ISBaseTimedAction:derive("TABAS_AddBathSalt")

local TFC_Utils = require("TubFluidContainer/TABAS_TubFluidContainerSystemUtils")

function TABAS_AddBathSalt:isValid()
    if isClient() and self.item then
	    return self.character:getInventory():containsID(self.item:getID()) and self.tfc_Base:canAddBathSalt(self.def.type)
	else
	    return self.character:getInventory():contains(self.item) and self.tfc_Base:canAddBathSalt(self.def.type)
	end
end

function TABAS_AddBathSalt:waitToStart()
    if self.character:isAiming() then
        self.character:nullifyAiming()
    end
    if self.character:isSneaking() then
        self.character:setSneaking(false)
    end
    self.character:faceThisObject(self.tfc_Base.bathObject)
    return self.character:shouldBeTurning()
end

function TABAS_AddBathSalt:update()
    self.item:setJobDelta(self:getJobDelta())
end

function TABAS_AddBathSalt:start()
    if isClient() and self.item then
        self.item = self.character:getInventory():getItemById(self.item:getID())
    end

    self.item:setJobDelta(0.0)
    self:setActionAnim("Pour")
    self:setOverrideHandModels(self.item:getStaticModel(), nil)
    self.sound = self.character:getEmitter():playSound("DropSoilFromSandBag")
end

function TABAS_AddBathSalt:stopSound()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:stopOrTriggerSound(self.sound)
    end
end

function TABAS_AddBathSalt:stop()
    self:stopSound()
    if self.item then
        self.item:setJobDelta(0.0)
    end
	ISBaseTimedAction.stop(self)
end

function TABAS_AddBathSalt:perform()
    self:stopSound()
    if self.item then
        self.item:setJobDelta(0.0)
    end
    if self.container then
        if luautils.walkToContainer(self.container, self.character:getPlayerNum()) then
            ISCraftingUI.ReturnItemToContainer(self.character, self.item, self.container)
        end
    end
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end

function TABAS_AddBathSalt:complete()
    self.item:UseAndSync()
    local tfc_Base = TFC_Utils.getTfcBaseOnServer(self.tfc_Base.x, self.tfc_Base.y, self.tfc_Base.z, self.tfc_Base.bathObject)
    if tfc_Base then
        tfc_Base:addBathSalt(self.def)
    end
    return true
end

function TABAS_AddBathSalt:adjustMaxTime(maxTime)
    return maxTime
end

function TABAS_AddBathSalt:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 160
end

function TABAS_AddBathSalt:new(character, tfc_Base, def, item, container)
    local o = ISBaseTimedAction.new(self, character)
    o.tfc_Base = tfc_Base
    o.item = item
    o.def = def
    o.container = container
    o.maxTime = o:getDuration()

    o.ignoreHandsWounds = true
    o.useProgressBar = true
    o.caloriesModifier = 0
    return o
end