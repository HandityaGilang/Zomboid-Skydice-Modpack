local TABAS_Patches = {}

TABAS_Patches.applied = false

require "TimedActions/TABAS_DrySelf"

------------------------ Furry Shake TimedAction ----------------------------

local function washFurClothing(character)
    local item = FurManager.getPlayerWornFur(character)
    if item == nil then return 0, false end

    local changed = false
    local mul = 1
    local decTotal = 0
    if item:IsClothing() then
        local coveredParts = BloodClothingType.getCoveredParts(item:getBloodClothingType())
        if coveredParts then
            local psize = coveredParts:size()
            for j=0, psize-1 do
                local part = coveredParts:get(j)
                local value = item:getBlood(part)
                if value > 0 then
                    local decrease = value * mul
                    item:setBlood(part, (value - decrease))
                    decTotal = decTotal + decrease
                    changed = true
                end
                value = item:getDirt(part)
                if value > 0 then
                    local decrease = value * mul
                    item:setDirt(part, (value - decrease))
                    decTotal = decTotal + decrease
                    changed = true
                end
            end
        end
        if item:getWetness() > 0 then
            item:setWetness(0)
            changed = true
        end
        local dirty = item:getDirtiness()
        if dirty > 0 then
            local decrease = dirty * mul
            item:setDirtiness(dirty - decrease)
            decTotal = decTotal + decrease * 0.01
            changed = true
        end
    end
    local blood = item:getBloodLevel()
    if blood > 0 then
        local decrease = blood * mul
        item:setBloodLevel(blood - decrease)
        decTotal = decTotal + decrease * 0.01
        changed = true
    end

    if changed then
        syncItemFields(character, item)
        if FurCompatibilityWrappers and FurCompatibilityWrappers.sendClothing then
            FurCompatibilityWrappers.sendClothing(character, item:getBodyLocation(), item)
        else
            triggerEvent("OnClothingUpdated", character)
        end
    end
    return decTotal, changed
end

function TABAS_Patches.apply()
    if TABAS_Patches.applied then return true end

    local TABAS_BathingUtils = require("Bathing/TABAS_BathingUtils")
    
    local TABAS_BodyLocations = require("NPCs/TABAS_BodyLocations")
    table.insert(TABAS_BodyLocations.Exclude.BodyLocations, "Fur")

    local function hasFur(playerObj)
        if not FurManager or not FurManager.getPlayerWornFur then return false end
        return FurManager.getPlayerWornFur(playerObj) ~= nil
    end

    -- TimedAction
    TABAS_FurryShakeAction = ISBaseTimedAction:derive("TABAS_FurryShakeAction")

    function TABAS_FurryShakeAction:isValid()
        return true
    end

    function TABAS_FurryShakeAction:update()
        self.character:setMetabolicTarget(Metabolics.LightDomestic)
    end
    
    function TABAS_FurryShakeAction:start()
        self:setActionAnim("Furry_ShakeDry")
    end
    
    function TABAS_FurryShakeAction:stop()
        ISBaseTimedAction.stop(self)
    end
    
    function TABAS_FurryShakeAction:perform()
        ISBaseTimedAction.perform(self)
    end
    
    function TABAS_FurryShakeAction:complete()
        local fur = self.fur
        if fur ~= nil then
            local curWet = fur:getWetness() or 0
            if curWet and curWet > 0 then
                fur:setWetness(0)
                syncItemFields(self.character, fur)
                triggerEvent("OnClothingUpdated", self.character)
            end
        end
    end
    
    function TABAS_FurryShakeAction:getDuration()
        if self.character:isTimedActionInstant() then
            return 1
        end
        return self.time
    end
    
    function TABAS_FurryShakeAction:new(character, time)
        local o = ISBaseTimedAction.new(self, character)
        o.fur = FurManager.getPlayerWornFur(character)
        o.time = time
        o.stopOnAim = true
        o.stopOnWalk = true
        o.stopOnRun = true
        o.maxTime = o:getDuration()
        o.ignoreHandsWounds = true
        o.caloriesModifier = 4
        return o
    end
    
    function TABAS_FurryShakeAction.doShakeAction(player, square)
        -- Shake dry
        local shakeAction = TABAS_FurryShakeAction:new(player, 200)
        ISTimedActionQueue.add(shakeAction)
    end
    
    -- Shake menu durring bathing wet.
    function TABAS_FurryShakeAction.furShakeMenu(player, context, worldObjects, test)
        if test then return end
    
        local playerObj = getSpecificPlayer(player)
        if not hasFur(playerObj) then return end
        if not TABAS_DrySelf.hasBathingWet(playerObj) then return end
    
        local modData = playerObj:getModData()
        local fur = FurManager.getPlayerWornFur(playerObj)
        if fur ~= nil and not playerObj:getVehicle() and not modData.tabas_IsBathing then
            context:addOption("Shake Dry", playerObj, TABAS_FurryShakeAction.doShakeAction, playerObj:getSquare())
        end
    end

    -- TABAS_FurryPatches.OnTakeShower 
    local context_shower = require("ContextMenu/TABAS_ContextMenuShower")
    local old_OnTakeShower = context_shower.onTakeShower
    function context_shower.onTakeShower(player, object, soapList1, soapList2, comsumeSoap, towel, keepClothes, makeOff, useHot)
        local playerObj = getSpecificPlayer(player)
        if hasFur(playerObj) then
            towel = nil
        end
        old_OnTakeShower(player, object, soapList1, soapList2, comsumeSoap, towel, keepClothes, makeOff, useHot)
    end

    -- TABAS_FurryPatches.OnTakeBath
    local context_bath = require("ContextMenu/TABAS_ContextMenuBathtub")
    local old_OnTakeBath = context_bath.onTakeBath
    function context_bath.onTakeBath(player, tfc_Base, towel, keepClothes, makeOff, bathTime, isAutoMode)
        local playerObj = getSpecificPlayer(player)
        if hasFur(playerObj) then
            towel = nil
        end
        old_OnTakeBath(player, tfc_Base, towel, keepClothes, makeOff, bathTime, isAutoMode)
    end

    -- Fur wet to 0 durring shower and cleansed body
    -- TABAS_FurryPatches.washCleansedBody
    local old_washCleansedBody = TABAS_BathingUtils.cleaningBody
    function TABAS_BathingUtils.cleaningBody(character, pct, factor)
        local decTotal = old_washCleansedBody(character, pct, factor)
        if hasFur(character) then
            local furCleansed = washFurClothing(character)
            decTotal = decTotal + furCleansed
        end
        return decTotal
    end

    -- Shake action after bathing.
    -- TABAS_FurryPatches.DrySelfStart 
    local old_DrySelfStart = TABAS_DrySelf.start
    function TABAS_DrySelf.start(self)
        if hasFur(self.character) then
            local altAction = TABAS_FurryShakeAction:new(self.character, 200)
            self:addAfter(altAction)
        end
        old_DrySelfStart(self)
    end

    Events.OnFillWorldObjectContextMenu.Add(TABAS_FurryShakeAction.furShakeMenu)
    TABAS_Patches.applied = true
    return true
end

return TABAS_Patches
