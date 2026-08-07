--
-- Dead Man's Dossier — Timed Action: Assemble Dossier
-- Player reads and assembles torn pages into a complete dossier.
-- Progress bar driven by item:setJobType/setJobDelta (same as vanilla).
--

require "TimedActions/ISBaseTimedAction"
require "deadmansdossier_shared"

local TAG = "[DeadMansDossier]"

DMD_AssembleDossierAction = ISBaseTimedAction:derive("DMD_AssembleDossierAction")

function DMD_AssembleDossierAction:isValid()
    -- Re-fetch item by ID in case inventory shifted
    if isClient() and self.item then
        return self.character:getInventory():getItemById(self.item:getID()) ~= nil
    end
    local tier = DeadMansDossier.TIERS[self.tierKey]
    if not tier then return false end
    local inv = self.character:getInventory()
    for _, pageType in ipairs(tier.pages) do
        if not inv:containsTypeRecurse(pageType) then
            return false
        end
    end
    return true
end

function DMD_AssembleDossierAction:start()
    -- Re-fetch item reference for MP safety
    if isClient() and self.item then
        self.item = self.character:getInventory():getItemById(self.item:getID())
    end
    -- Drive the progress bar via the item's job system
    self.item:setJobType(getText("IGUI_DMD_JobAssembling"))
    self.item:setJobDelta(0.0)
    self:setActionAnim("Read")
    self:setOverrideHandModels(nil, nil)
end

function DMD_AssembleDossierAction:update()
    self.item:setJobDelta(self:getJobDelta())
end

function DMD_AssembleDossierAction:stop()
    if self.item then
        self.item:setJobDelta(0.0)
    end
    ISBaseTimedAction.stop(self)
end

function DMD_AssembleDossierAction:perform()
    if self.item then
        self.item:setJobDelta(0.0)
    end

    print(TAG .. " Assemble action completed, sending command to server for tier: " .. tostring(self.tierKey))
    -- 4-arg form with the player: the 3-arg version sends playerIndex=-1 and
    -- relies on GameServer.getAnyPlayerFromConnection, which can return null in
    -- Host & Play ("receiveClientCommand: player is null") — see LESSONS.
    sendClientCommand(
        self.character,
        DeadMansDossier.MOD_ID,
        DeadMansDossier.CMD_ASSEMBLE,
        { tierKey = self.tierKey }
    )
    ISBaseTimedAction.perform(self)
end

function DMD_AssembleDossierAction:new(character, tierKey, item)
    local o = ISBaseTimedAction.new(self, character)
    o.tierKey = tierKey
    o.item = item
    o.maxTime = 200  -- ~6.7 seconds at 30 fps
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
    print(TAG .. " Queueing assemble action for tier: " .. tostring(tierKey))
    return o
end
