-- FirefighterUniform_SwapAxeTypeAction
-- written by Jusblazm
require "TimedActions/ISBaseTimedAction"

FirefighterUniform_SwapAxeTypeAction = ISBaseTimedAction:derive("FirefighterUniform_SwapAxeTypeAction")

function FirefighterUniform_SwapAxeTypeAction:isValid()
    return self.weapon and self.character:getInventory():contains(self.weapon)
end

function FirefighterUniform_SwapAxeTypeAction:perform()
    ISBaseTimedAction.perform(self)
end

function FirefighterUniform_SwapAxeTypeAction:complete()
    local inv = self.character:getInventory()
    local oldAxe = self.weapon
    local oldType = oldAxe:getFullType()
    
    local newType
    if oldType == "Base.Emergency_Axe_HeavySwing" then
        newType = "Base.Emergency_Axe_QuickSwing"
    elseif oldType == "Base.Emergency_Axe_QuickSwing" then
        newType = "Base.Emergency_Axe_HeavySwing"
    end

    if not newType then return false end

    local newAxe = instanceItem(newType)

    newAxe:setCondition(oldAxe:getCondition())
    newAxe:setHaveBeenRepaired(oldAxe:getHaveBeenRepaired())
    newAxe:setBloodLevel(oldAxe:getBloodLevel())
    newAxe:getModData().fromSwap = true

    self.character:removeFromHands(oldAxe)
    inv:Remove(oldAxe)
    sendRemoveItemFromContainer(inv, oldAxe)

    inv:AddItem(newAxe)
    sendAddItemToContainer(inv, newAxe)

    syncItemFields(self.character, newAxe)
    syncItemModData(self.character, newAxe)
    syncHandWeaponFields(self.character, newAxe)

    return true
end

function FirefighterUniform_SwapAxeTypeAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 75
end

function FirefighterUniform_SwapAxeTypeAction:new(character, weapon)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.weapon = weapon
    o.maxTime = o:getDuration()
    return o
end