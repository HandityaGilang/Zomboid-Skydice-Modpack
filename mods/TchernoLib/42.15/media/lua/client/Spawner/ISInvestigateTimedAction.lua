
require "TimedActions/ISBaseTimedAction"

ISInvestigateTimedAction = ISBaseTimedAction:derive("ISInvestigateTimedAction");

function ISInvestigateTimedAction:isValid()
    return true;
end

function ISInvestigateTimedAction:waitToStart()
    self.character:faceLocation(self.gridSquare:getX(), self.gridSquare:getY())
    return self.character:shouldBeTurning()
end

function ISInvestigateTimedAction:update()
    self.character:faceLocation(self.gridSquare:getX(), self.gridSquare:getY())
    self.character:setMetabolicTarget(Metabolics.DiggingSpade);
end

function ISInvestigateTimedAction:start()
    self.sound = self.character:playSound("DigFurrowWithHands");
    addSound(self.character, self.character:getX(), self.character:getY(), self.character:getZ(), 10, 1)
    self:setActionAnim(BuildingHelper.getShovelAnim(nil))
    self:setOverrideHandModels(nil, nil)
    self.character:Say(getText('IGUI_Spawn_InvestigateStart'))
end

function ISInvestigateTimedAction:stop()
    if self.sound and self.sound ~= 0 then
        self.character:getEmitter():stopOrTriggerSound(self.sound)
    end
    ISBaseTimedAction.stop(self);
end

function ISInvestigateTimedAction:perform()
    if self.sound and self.sound ~= 0 then
        self.character:getEmitter():stopOrTriggerSound(self.sound)
    end

    Spawn.investigate(self.character, self.gridSquare)

    ISBaseTimedAction.perform(self);
end

function ISInvestigateTimedAction:new (character, square, time)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character;
    o.stopOnWalk = true;
    o.stopOnRun = true;
    o.maxTime = time;
    if character:isTimedActionInstant() then
        o.maxTime = 1;
    end
    o.gridSquare = square
    return o
end
