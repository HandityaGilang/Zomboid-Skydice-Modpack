require "TimedActions/ISBaseTimedAction"
require "BasementBuilder/BasementBuilder_Core"

BasementBuilderDigAction = ISBaseTimedAction:derive("BasementBuilderDigAction")

function BasementBuilderDigAction:isValid()
    if not self.character or not self.character:getCurrentSquare() then
        return false
    end
    if self.mode == "start" then
        local valid = BasementBuilder._safeCanStartBasement(self.square)
        return valid == true
    end
    local valid = BasementBuilder._safeCanExpandFrom(self.square, self.targetX, self.targetY)
    return valid == true
end

function BasementBuilderDigAction:start()
    self:setActionAnim("Dig")
    if self.shovel then
        self:setOverrideHandModels(self.shovel, nil)
    end
    if self.mode == "start" then
        self.shovel:setJobType("Dig Basement")
    else
        self.shovel:setJobType("Expand Basement")
    end
end

function BasementBuilderDigAction:update()
    if self.shovel then
        self.shovel:setJobDelta(self:getJobDelta())
    end
end

function BasementBuilderDigAction:stop()
    if self.shovel then
        self.shovel:setJobDelta(0.0)
    end
    ISBaseTimedAction.stop(self)
end

function BasementBuilderDigAction:perform()
    if self.shovel then
        self.shovel:setJobDelta(0.0)
    end

    local args = {
        mode = self.mode,
        x = self.square:getX(),
        y = self.square:getY(),
        z = self.square:getZ(),
        tx = self.targetX,
        ty = self.targetY,
        styleId = self.styleId,
        palette = self.palette,
    }

    if isServer() then
        BasementBuilder_Server.onDigCommand(self.character, args)
    else
        sendClientCommand(self.character, BasementBuilder.MODULE, "dig", args)
    end

    ISBaseTimedAction.perform(self)
end

function BasementBuilderDigAction:new(character, square, mode, targetX, targetY, shovel, styleId, palette)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.square = square
    o.mode = mode
    o.targetX = targetX
    o.targetY = targetY
    o.shovel = shovel
    o.styleId = styleId
    o.palette = palette
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = mode == "start" and 250 or 180
    return o
end
