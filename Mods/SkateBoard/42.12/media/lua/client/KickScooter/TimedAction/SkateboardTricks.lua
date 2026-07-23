require "TimedActions/ISBaseTimedAction"

SkateboardTrickOllie = ISBaseTimedAction:derive("SkateboardTrickOllie")

function SkateboardTrickOllie:waitToStart()
	return false
end

function SkateboardTrickOllie:update()

end

function TinyTimer(milliseconds, callback)
    local OnTick
    local startMs = getTimestampMs()
    local stopMs = startMs + milliseconds
    OnTick = function()
        if getTimestampMs() < stopMs then
            return
        end
        callback()  -- Execute the callback when time has elapsed.
        Events.OnTick.Remove(OnTick)
    end
    Events.OnTick.Add(OnTick)
end

local lastAddSoundTimestamp = 0

local function updateSkateboardFlag(player)
    local skateboardActive = player:getVariableBoolean("SkateboardActive")
    if not skateboardActive then return end
    local ollieStarted = player:getVariableBoolean("SkateboardOllieStarted")
    local ollie = player:getVariableBoolean("SkateboardOllie")
    local emitter = player:getEmitter()
    local options = PZAPI.ModOptions:getOptions("SkateboardMod")
    local soundVolume = options:getOption("SkateboardSoundVolume"):getValue()
    local soundRange = options:getOption("SkateboardSoundRange"):getValue()

    if ollie == true then
        if ollieStarted == true then
            player:setIgnoreMovement(true)
            -- If SkateboardRolling is playing, stop it with a delay
            if emitter:isPlaying('SkateboardRolling') then
                TinyTimer(300, function()
                    if emitter:isPlaying('SkateboardRolling') then
                        emitter:stopSoundByName('SkateboardRolling')
                    end
                end)
            end
            -- If SkateboardOllie isn't already playing, delay its start.
            if not emitter:isPlaying('SkateboardOllie') then
                TinyTimer(150, function()
                    if not emitter:isPlaying('SkateboardOllie') then
                        local sound = emitter:playSound('SkateboardOllie')
                        emitter:setVolume(sound, soundVolume)
                        lastAddSoundTimestamp = ThrottleAddSound(lastAddSoundTimestamp, player, soundRange)
                    end
                end)
            else
                lastAddSoundTimestamp = ThrottleAddSound(lastAddSoundTimestamp, player, soundRange)
            end
        end
        return
    end

    -- When both ollie and ollieStarted are false,
    -- stop the SkateboardOllie sound with a delay and allow movement.
    if ollie == false and ollieStarted == false then
        player:setIgnoreMovement(false)
        if emitter:isPlaying('SkateboardOllie') then
            if not emitter:isPlaying('SkateboardRolling') then
                local sound = emitter:playSound('SkateboardRolling')
                emitter:setVolume(sound, soundVolume)
            end
            emitter:stopSoundByName('SkateboardOllie')
        end
    end
end

Events.OnPlayerUpdate.Add(updateSkateboardFlag)



function SkateboardTrickOllie:start()
	self.character:setVariable("SkateboardOllieStarted", "true")
	updateSkateboardFlag(self.character)
end

function SkateboardTrickOllie:stop()

end

function SkateboardTrickOllie:perform()
    local inventoryItem = self.item:getItem()
end

function SkateboardTrickOllie:new(player)

	local o = {}
	setmetatable( o, self)
	self.__index = self
	o.maxTime = 15
	o.character = player
	o.stopOnWalk = false
	o.stopOnRun = false
    o.options = PZAPI.ModOptions:getOptions("SkateboardMod")
    o.speedMultSlow = o.options:getOption("SpeedMultSlow"):getValue()
    o.speedMultFast = o.options:getOption("SpeedMultFast"):getValue()

	o.character:setVariable("SkateboardOllie", "true")
    o.character:setVariable("SkateboardOllieStarted", "false")

	return o
end

Events.OnPlayerUpdate.Add(updateSkateboardFlag)