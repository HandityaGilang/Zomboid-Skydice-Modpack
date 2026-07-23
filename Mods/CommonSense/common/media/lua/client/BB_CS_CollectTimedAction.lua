-- ************************************************************************
-- **        ██████  ██████   █████  ██    ██ ███████ ███    ██          **
-- **        ██   ██ ██   ██ ██   ██ ██    ██ ██      ████   ██          **
-- **        ██████  ██████  ███████ ██    ██ █████   ██ ██  ██          **
-- **        ██   ██ ██   ██ ██   ██  ██  ██  ██      ██  ██ ██          **
-- **        ██████  ██   ██ ██   ██   ████   ███████ ██   ████          **
-- ************************************************************************
-- ** All rights reserved. This content is protected by © Copyright law. **
-- ************************************************************************

require "TimedActions/ISBaseTimedAction"

---@class BB_CS_CollectTimedAction : ISBaseTimedAction
---@field typeTimeAction string
---@field playerObj IsoPlayer
---@field clickedSquare IsoGridSquare
---@field spriteName string
---@field itemsList string "Item1_Name:Value", "Item2_Name:Value"...
---@field stopOnWalk boolean
---@field stopOnRun boolean
---@field fromHotbar boolean
BB_CS_CollectTimedAction = ISBaseTimedAction:derive("BB_CS_CollectTimedAction")

---@param playerObj IsoPlayer
---@param spriteName string
local function playSound(playerObj, spriteName)
    if string.find(spriteName, "trash") then
        BB_CS_Utils.TryPlaySoundClip(playerObj, "FoleyTrash")
    else
        BB_CS_Utils.TryPlaySoundClip(playerObj, "FoleyForage")
    end
end

---@param playerObj IsoPlayer
---@param spriteName string
local function stopSound(playerObj, spriteName)
    if string.find(spriteName, "trash") then
        BB_CS_Utils.TryStopSoundClip(playerObj, "FoleyTrash")
    else
        BB_CS_Utils.TryStopSoundClip(playerObj, "FoleyForage")
    end
end

function BB_CS_CollectTimedAction.isValid()
    return true --[[@diagnostic disable-line: return-type-mismatch, redundant-return-value]]
end

function BB_CS_CollectTimedAction:start()
    if self.typeTimeAction == "Collect" then
        self:setActionAnim("Loot")
        self:setAnimVariable("LootPosition", "Low")
        playSound(self.playerObj, self.spriteName)
    end
end

function BB_CS_CollectTimedAction:stop()
    ISBaseTimedAction.stop(self)
    stopSound(self.playerObj, self.spriteName)
end

function BB_CS_CollectTimedAction:perform()

    if self.typeTimeAction == "Collect" then

        if not SandboxVars.CommonSense.DisableLoot then

            local items = BB_CS_CollectDatabase.GetItems(self.itemsList)
            for _, item in ipairs(items) do
                for _=1, item.value do
                    sendClientCommand(self.playerObj, "CommonSense", "GiveItem", {itemName = item.name})
                end
            end
        end

        local args = {
            square = { x = self.clickedSquare:getX(), y = self.clickedSquare:getY(), z = self.clickedSquare:getZ() },
            spriteName = self.spriteName
        }
        sendClientCommand(self.playerObj, "CommonSense", "RemoveResources", args)
        stopSound(self.playerObj, self.spriteName)
    end

    ISBaseTimedAction.perform(self)
end

---@param playerObj IsoPlayer
---@param clickedSquare IsoGridSquare
---@param spriteName string
---@param itemsList string "Item1_Name:Value", "Item2_Name:Value"...
function BB_CS_CollectTimedAction:CollectItem(playerObj, clickedSquare, spriteName, itemsList)

    ---@type BB_CS_CollectTimedAction
    local action = ISBaseTimedAction.new(self, playerObj)
    action.typeTimeAction = "Collect"
    action.playerObj = playerObj
    action.clickedSquare = clickedSquare
    action.spriteName = spriteName
    action.itemsList = itemsList
    action.stopOnWalk = true
    action.stopOnRun = true
    action.maxTime = 100
    action.fromHotbar = false

    if action.character:isTimedActionInstant() then action.maxTime = 1; end
    return action
end