--
-- Knox Detection Kit — Blood Test Timed Action
-- Progress bar + bandage animation while drawing blood.
-- On completion, sends RunTest to the server.
--

require "TimedActions/ISBaseTimedAction"
require "KnoxDetectionKit_Shared"

KnoxDetectionKitBloodTestAction = ISBaseTimedAction:derive("KnoxDetectionKitBloodTestAction")

local TAG = "[KnoxDetectionKit]"

function KnoxDetectionKitBloodTestAction:isValid()
    if isClient() and self.item then
        return self.character:getInventory():containsID(self.item:getID())
    else
        return self.character:getInventory():contains(self.item)
    end
end

function KnoxDetectionKitBloodTestAction:start()
    if isClient() and self.item then
        self.item = self.character:getInventory():getItemById(self.item:getID())
    end
    self.item:setJobType(getText("ContextMenu_RunBloodTest"))
    self.item:setJobDelta(0.0)
    self:setActionAnim(CharacterActionAnims.Bandage)
    self:setAnimVariable("BandageType", "LeftArm")
    self:setOverrideHandModels(nil, self.item)
end

function KnoxDetectionKitBloodTestAction:update()
    self.item:setJobDelta(self:getJobDelta())
end

function KnoxDetectionKitBloodTestAction:stop()
    self.item:setJobDelta(0.0)
    ISBaseTimedAction.stop(self)
end

function KnoxDetectionKitBloodTestAction:perform()
    self.item:setJobDelta(0.0)

    print(TAG .. " Blood test complete, sending RunTest (itemID=" .. tostring(self.item:getID()) .. ")")

    sendClientCommand(self.character, KnoxDetectionKit.MOD_ID, KnoxDetectionKit.CMD_RUN_TEST, {
        itemID = self.item:getID()
    })

    ISBaseTimedAction.perform(self)
end

function KnoxDetectionKitBloodTestAction:new(character, item)
    local o = ISBaseTimedAction.new(self, character)
    o.item = item
    o.stopOnWalk = false
    o.stopOnRun = true
    o.stopOnAim = false
    o.maxTime = 90
    if character:isTimedActionInstant() then
        o.maxTime = 1
    end
    return o
end
