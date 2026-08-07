--
-- Dead Man's Dossier — Timed Action: Abandon Mission
-- Progress bar before sending abandon command to server.
-- Gives the player time to cancel by walking away.
--

require "TimedActions/ISBaseTimedAction"
require "deadmansdossier_shared"

local TAG = "[DeadMansDossier]"

DMD_AbandonMissionAction = ISBaseTimedAction:derive("DMD_AbandonMissionAction")

function DMD_AbandonMissionAction:isValid()
    if isClient() and self.item then
        return self.character:getInventory():getItemById(self.item:getID()) ~= nil
    end
    return true
end

function DMD_AbandonMissionAction:start()
    if isClient() and self.item then
        self.item = self.character:getInventory():getItemById(self.item:getID())
    end
    self.item:setJobType(getText("IGUI_DMD_JobAbandoning"))
    self.item:setJobDelta(0.0)
    self:setActionAnim("Read")
    self:setOverrideHandModels(nil, nil)
end

function DMD_AbandonMissionAction:update()
    self.item:setJobDelta(self:getJobDelta())
end

function DMD_AbandonMissionAction:stop()
    if self.item then
        self.item:setJobDelta(0.0)
    end
    ISBaseTimedAction.stop(self)
end

function DMD_AbandonMissionAction:perform()
    if self.item then
        self.item:setJobDelta(0.0)
    end

    print(TAG .. " Abandon mission sent for tier: " .. tostring(self.tierKey))

    -- 4-arg form with the player: the 3-arg version sends playerIndex=-1 and
    -- relies on GameServer.getAnyPlayerFromConnection, which can return null in
    -- Host & Play ("receiveClientCommand: player is null") — see LESSONS.
    sendClientCommand(
        self.character,
        DeadMansDossier.MOD_ID,
        DeadMansDossier.CMD_ABANDON_MISSION,
        { tierKey = self.tierKey }
    )
    ISBaseTimedAction.perform(self)
end

function DMD_AbandonMissionAction:new(character, tierKey, item)
    local o = ISBaseTimedAction.new(self, character)
    o.tierKey = tierKey
    o.item = item
    o.maxTime = 90  -- ~3 seconds at 30 fps
    o.stopOnWalk = true
    o.stopOnRun = true
    -- 42.20: ISTimedActionQueue.add/.addAfter silently drop any action while
    -- the local player drags a corpse unless it opts in. This is a
    -- document-reading action with no world interaction, so being blocked
    -- (e.g. arriving at the stash hauling a corpse) is a pointless dead end.
    o.allowedWhileDraggingCorpses = true
    if character:isTimedActionInstant() then
        o.maxTime = 1
    end
    return o
end
