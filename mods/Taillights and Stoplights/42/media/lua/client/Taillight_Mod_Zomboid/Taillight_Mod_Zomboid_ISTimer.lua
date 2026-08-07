require "ISBaseObject"

local ISTimer = ISBaseObject:derive("ISTimer");

ISTimer.IDMax = 1;
ISTimer.Timers = {};

function ISTimer:initialise()
	self:reset();
	self.data.ID = ISTimer.IDMax;
	ISTimer.IDMax = ISTimer.IDMax + 1;
	self.data.realWorldTime = false;
	self.data.repeats = false;
	self.data.shouldStop = nil;
end

function ISTimer:reset()
	self.data.elapsed = 0;
	self.data.active = false;
end

function ISTimer:start()
	self.data.active = true;
	ISTimer.Timers[self.data.ID] = self;
end

function ISTimer:stop()
	self.data.active = false;
	ISTimer.Timers[self.data.ID] = nil;
end

function ISTimer:new (name, objectOnExpire, funcOnExpire, timeInSeconds, repeats, realWorldTime)
    local o = {}
	o.data = {};
    setmetatable(o, self)
    self.__index = self
	o:initialise();
	o.data.name = name;
	if objectOnExpire ~= nil then
		o.data.classOnExpire = objectOnExpire;
	end
	if funcOnExpire ~= nil then
		o.data.funcOnExpire = funcOnExpire;
	end
	if timeInSeconds ~= nil then
		o.data.timeInSeconds = timeInSeconds;
	end
	if repeats ~= nil then
		o.data.repeats = repeats;
	end
	if realWorldTime ~= nil then
		o.data.realWorldTime = realWorldTime;
	end
   return o
end

ISTimer.updateTimers = function(ticks)

	for i,v in pairs(ISTimer.Timers) do		
		if v.data.active then
			if v.data.realWorldTime then
				v.data.elapsed = v.data.elapsed + GameTime.getInstance():getRealworldSecondsSinceLastUpdate();	
			else
				v.data.elapsed = v.data.elapsed + GameTime.getInstance():getMultipliedSecondsSinceLastUpdate();	
			end
			if v.data.timeInSeconds ~= nil and v.data.elapsed >= v.data.timeInSeconds then
				if v.data.funcOnExpire ~= nil then
					v.data.funcOnExpire(v.data.classOnExpire);
				end
				if not v.data.repeats or v.data.shouldStop then
					v.data.shouldStop = nil
					v:stop();
					ISTimer.Timers[i] = nil;
				else
					v:reset();
					v:start();
				end
			end
		end
	end
end
Events.OnTick.Remove(ISTimer.updateTimers);
Events.OnRenderTick.Remove(ISTimer.updateTimers);
Events.OnPlayerUpdate.Add(ISTimer.updateTimers);

return ISTimer