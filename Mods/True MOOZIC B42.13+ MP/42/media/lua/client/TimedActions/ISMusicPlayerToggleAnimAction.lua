ISMusicPlayerToggleAnimAction = ISBaseTimedAction:derive("ISMusicPlayerToggleAnimAction")

function ISMusicPlayerToggleAnimAction:isValid()
    return self.item and self.character and not self.character:isDead()
end

function ISMusicPlayerToggleAnimAction:start()
    local slotIndex = self.slotIndex or 2
    local attachType = "belt left"
    if slotIndex == 3 then
        attachType = "belt right"
    end
    self.character:setVariable("AttachAnim", attachType)
    self:setActionAnim("AttachItem")
    self.item:setJobType("Toggle Music Player")
    self.item:setJobDelta(0.0)
end

function ISMusicPlayerToggleAnimAction:perform()
    self.item:setActivated(self.targetState)
    if self.targetState then
        if self.onOpen then self.onOpen(self.character, self.item) end
    else
        if self.onClose then self.onClose(self.character, self.item) end
    end
    self.character:setVariable("AttachAnim", nil)
    ISBaseTimedAction.perform(self)
end

function ISMusicPlayerToggleAnimAction:getDuration()
    return 45
end

function ISMusicPlayerToggleAnimAction:new(character, item, targetState, onOpen, onClose, slotIndex)
    local o = ISBaseTimedAction.new(self, character)
    o.item = item
    o.character = character
    o.targetState = targetState
    o.onOpen = onOpen
    o.onClose = onClose
    o.maxTime = o:getDuration()
    o.slotIndex = slotIndex
    o.useProgressBar = false
    o.stopOnWalk = false
    o.stopOnRun = false
    return o
end 