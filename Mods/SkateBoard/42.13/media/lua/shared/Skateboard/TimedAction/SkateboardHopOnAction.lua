require("TimedActions/ISBaseTimedAction")
require("TimedActions/ISInventoryTransferUtil")
require("Skateboard/SkateboardCore")

SkateboardHopOnAction = ISBaseTimedAction:derive("SkateboardHopOnAction")
SkateboardHopOnAction.instance = nil

local Core = Skateboard.Core

---@return number, number
local function getSkateboardSpeedMultipliers()
    local speedSlow = 1.7
    local speedFast = 2.5

    if isClient() then
        -- this code is ran client side in multiplayer
        if SandboxVars and SandboxVars.Skateboard then
            if SandboxVars.Skateboard.skateboardWalkSpeedMultiplier then
                speedSlow = SandboxVars.Skateboard.skateboardWalkSpeedMultiplier
            end
            if SandboxVars.Skateboard.skateboardRunSpeedMultiplier then
                speedFast = SandboxVars.Skateboard.skateboardRunSpeedMultiplier
            end
        end
    elseif isServer() then
        -- this code is ran server side in multiplayer
        if SandboxVars and SandboxVars.Skateboard then
            if SandboxVars.Skateboard.skateboardWalkSpeedMultiplier then
                speedSlow = SandboxVars.Skateboard.skateboardWalkSpeedMultiplier
            end
            if SandboxVars.Skateboard.skateboardRunSpeedMultiplier then
                speedFast = SandboxVars.Skateboard.skateboardRunSpeedMultiplier
            end
        end
    else
        -- this code is ran in singleplayer
        if Skateboard and Skateboard.Options and Skateboard.Options.get and Skateboard.Options.Key then
            local options = Skateboard.Options.get()
            if options then
                local walkOption = options:getOption(Skateboard.Options.Key.WalkSpeedMultiplier)
                local runOption = options:getOption(Skateboard.Options.Key.RunSpeedMultiplier)
                if walkOption then
                    speedSlow = walkOption:getValue()
                end
                if runOption then
                    speedFast = runOption:getValue()
                end
            end
        end
    end

    return speedSlow, speedFast
end

---@return boolean
function SkateboardHopOnAction:isValid()
    local item = Core.getInventoryItem(self.item)
    return item ~= nil and Core.isSkateboardItem(item)
end


---@return boolean
function SkateboardHopOnAction:complete()
    if isServer() then
        sendEquip(self.character)
    end

    return true
end

---@nodiscard
---@param square IsoGridSquare
---@return boolean, IsoObject|nil
function SkateboardHopOnAction.squareHasObject(square)
    if not square then
        return false, nil
    end

    local objects = square:getObjects()
    for index = 0, objects:size() - 1 do
        local obj = objects:get(index)
        if obj and obj.isHoppable and obj:isHoppable() then
            return true, obj
        end
    end

    return false, nil
end

---@nodiscard
---@param square IsoGridSquare
---@return boolean
function SkateboardHopOnAction.squareIsRough(square)
    if not square then
        return false
    end

    local roughMaterials = {
        Sand = true,
        Grass = true,
        Gravel = true,
        Dirt = true
    }

    local objects = square:getObjects()
    for index = 0, objects:size() - 1 do
        local obj = objects:get(index)
        if obj then
            local material = obj:getProperties():get("FootstepMaterial")
            if material and roughMaterials[material] then
                return true
            end
        end
    end

    return false
end

---@nodiscard
---@param square IsoGridSquare
---@return boolean, IsoObject|nil
function SkateboardHopOnAction.nearbySquareHasObject(square)
    local squares = {
        square,
        square:getN(),
        square:getS(),
        square:getE(),
        square:getW()
    }

    for _, checkSquare in ipairs(squares) do
        if checkSquare then
            local found, obj = SkateboardHopOnAction.squareHasObject(checkSquare)
            if found then
                return true, obj
            end
        end
    end

    return false, nil
end

---@return nil
function SkateboardHopOnAction:start()
end

---@return nil
function SkateboardHopOnAction:stop()
end

---@return nil
function SkateboardHopOnAction:perform()
    if Skateboard and Skateboard.Client then
        Events.OnPlayerUpdate.Remove(Skateboard.Client.updateSkateboardFlag)
        Events.OnPlayerUpdate.Remove(Skateboard.Client.updateSkateboardAudio)
        Events.OnPlayerUpdate.Add(Skateboard.Client.updateSkateboardFlag)
        Events.OnPlayerUpdate.Add(Skateboard.Client.updateSkateboardAudio)
        Skateboard.Client.updateSkateboardFlag(self.character)
        Skateboard.Client.syncState(self.character, true)
    end
    ISBaseTimedAction.perform(self)
end

---@param character IsoPlayer
---@param item InventoryItem|IsoWorldInventoryObject
---@return SkateboardHopOnAction
function SkateboardHopOnAction:new(character, item)
    local o = ISBaseTimedAction.new(self, character)
    o.maxTime = o:getDuration()
    o.useProgressBar = false
    o.item = item
    o.stopOnWalk = false
    o.stopOnRun = false
    o.stopOnAim = false
    o.speedMultSlow, o.speedMultFast = getSkateboardSpeedMultipliers()

    o.character:setVariable(Core.PlayerVars.IdleToAimPlaying, false)
    o.character:setVariable(Core.PlayerVars.WalkSpeed, o.speedMultSlow)
    o.character:setVariable(Core.PlayerVars.RunSpeed, o.speedMultFast)

    SkateboardHopOnAction.instance = o
    return o
end

---@return number
function SkateboardHopOnAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end

    return 1
end

return SkateboardHopOnAction
