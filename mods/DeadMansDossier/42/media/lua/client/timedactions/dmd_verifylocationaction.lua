--
-- Dead Man's Dossier — Timed Action: Verify Stash Location
-- Short progress bar before sending proximity check to server.
--

require "TimedActions/ISBaseTimedAction"
require "deadmansdossier_shared"

local TAG = "[DeadMansDossier]"

DMD_VerifyLocationAction = ISBaseTimedAction:derive("DMD_VerifyLocationAction")

function DMD_VerifyLocationAction:isValid()
    if isClient() and self.item then
        return self.character:getInventory():getItemById(self.item:getID()) ~= nil
    end
    return true
end

function DMD_VerifyLocationAction:start()
    if isClient() and self.item then
        self.item = self.character:getInventory():getItemById(self.item:getID())
    end
    self.item:setJobType(getText("IGUI_DMD_JobVerifying"))
    self.item:setJobDelta(0.0)
    self:setActionAnim("Read")
    self:setOverrideHandModels(nil, nil)
end

function DMD_VerifyLocationAction:update()
    self.item:setJobDelta(self:getJobDelta())
end

function DMD_VerifyLocationAction:stop()
    if self.item then
        self.item:setJobDelta(0.0)
    end
    ISBaseTimedAction.stop(self)
end

function DMD_VerifyLocationAction:perform()
    if self.item then
        self.item:setJobDelta(0.0)
    end

    local x = math.floor(self.character:getX())
    local y = math.floor(self.character:getY())
    local z = math.floor(self.character:getZ())

    print(TAG .. " Verify location sent (" .. x .. ", " .. y .. ", " .. z .. ")")

    -- 4-arg form with the player: the 3-arg version sends playerIndex=-1 and
    -- relies on GameServer.getAnyPlayerFromConnection, which can return null in
    -- Host & Play ("receiveClientCommand: player is null") — see LESSONS.
    sendClientCommand(
        self.character,
        DeadMansDossier.MOD_ID,
        DeadMansDossier.CMD_CHECK_PROXIMITY,
        { x = x, y = y, z = z }
    )
    ISBaseTimedAction.perform(self)
end

function DMD_VerifyLocationAction:new(character, item)
    local o = ISBaseTimedAction.new(self, character)
    o.item = item
    o.maxTime = 30  -- ~1 second at 30 fps
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
