--***********************************************************
--**                    ROBERT JOHNSON                     **
--***********************************************************

require "TimedActions/ISBaseTimedAction"

ISCreateGOAction = ISBaseTimedAction:derive("ISCreateGOAction");

function ISCreateGOAction:isValid()
    return true;
end

function ISCreateGOAction:waitToStart()
    self.character:faceLocation(self.gridSquare:getX(), self.gridSquare:getY())
    return self.character:shouldBeTurning()
end

function ISCreateGOAction:update()
    self.character:faceLocation(self.gridSquare:getX(), self.gridSquare:getY())
    self.character:setMetabolicTarget(self.metabolic);
end

function ISCreateGOAction:start()
    self.sound = self.character:playSound(self.soundStr);

    addSound(self.character, self.character:getX(), self.character:getY(), self.character:getZ(), 10, 1)
    self:setActionAnim(ISFarmingMenu.getShovelAnim(nil))
    self:setOverrideHandModels(nil, nil)
end

function ISCreateGOAction:stop()
    if self.sound and self.sound ~= 0 then
        self.character:getEmitter():stopOrTriggerSound(self.sound)
    end
    ISBaseTimedAction.stop(self);
end

function ISCreateGOAction:perform()
    if self.sound and self.sound ~= 0 then
        self.character:getEmitter():stopOrTriggerSound(self.sound)
    end

    ShGO.createCGO(self.key,self.gridSquare,self.character,self.param)

    ISBaseTimedAction.perform(self);
end

function ISCreateGOAction:new(character, square, key, param, time)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character;
    o.key = key;
    o.param = param or {};
    o.maxTime = character:isTimedActionInstant() and 1 or time or 50;
    o.gridSquare = square
    
    --you can override those after new call
    o.stopOnWalk = true;
    o.stopOnRun = true;
    o.stopOnAim = false;
    o.soundStr = "DigFurrowWithHands";
    o.metabolic = Metabolics.DiggingSpade;
    
    return o
end
