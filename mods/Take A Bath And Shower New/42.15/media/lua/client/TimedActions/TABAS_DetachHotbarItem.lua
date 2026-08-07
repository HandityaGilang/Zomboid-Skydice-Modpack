require "TimedActions/ISBaseTimedAction"

TABAS_DetachHotbarItem = ISBaseTimedAction:derive("TABAS_DetachHotbarItem")

function TABAS_DetachHotbarItem:isValid()
    return self.item ~= nil
end

function TABAS_DetachHotbarItem:waitToStart()
    return false
end

function TABAS_DetachHotbarItem:start()
end

function TABAS_DetachHotbarItem:update()
end

function TABAS_DetachHotbarItem:stop()
    ISBaseTimedAction.stop(self)
end

function TABAS_DetachHotbarItem:perform()
    local hotbar = getPlayerHotbar(self.playerNum)
    if hotbar and self.item and hotbar:isItemAttached(self.item) then
        hotbar:removeItem(self.item, false)
    end
    ISBaseTimedAction.perform(self)
end

function TABAS_DetachHotbarItem:new(character, item)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.playerNum = character:getPlayerNum()
    o.item = item
    o.maxTime = 1
    return o
end
