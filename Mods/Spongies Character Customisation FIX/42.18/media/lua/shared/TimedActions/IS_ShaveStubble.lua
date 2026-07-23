
require("TimedActions/ISBaseTimedAction")

IS_ShaveStubble = ISBaseTimedAction:derive("IS_ShaveStubble");

function IS_ShaveStubble:isValid()
	return self.character:getInventory():contains(self.item);
end

function IS_ShaveStubble:update()
	if self.item then
		self.item:setJobDelta(self:getJobDelta());
	end
end

function IS_ShaveStubble:start()
	self:setActionAnim(CharacterActionAnims.Shave)
	self:setOverrideHandModels(self.item:getStaticModel() or "DisposableRazor", nil)

	if self.item then
		self.item:setJobType(getText("UI_characreation_shave"))
		self.item:setJobDelta(0.0)
	end
	self.sound = self.character:playSound("ShaveRazor")
end

function IS_ShaveStubble:stop()
	self:stopSound()
	if self.item then
		self.item:setJobDelta(0.0)
	end
    ISBaseTimedAction.stop(self)
end

function IS_ShaveStubble:perform()
	self:stopSound()
	if self.item then
		self.item:setJobDelta(0.0)
	end

	-- triggerEvent("OnClothingUpdated", self.character)

    -- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end

local function _resetStubbleGrowthIfNeeded(character, isBeard)
    if not character or not character.getHumanVisual then return end

    local visual = character:getHumanVisual()
    if not visual then return end

    if isBeard then
        if visual:getBeardModel() == "" then
            character:resetBeardGrowingTime()
        end
    else
        if visual:getHairModel() == "Bald" then
            character:resetHairGrowingTime()
        end
    end
end

function IS_ShaveStubble:complete()
    if not isClient() and not isServer() then
        local FaceManager_Local = require("CharacterCustomisation/FaceManager_Local")
        FaceManager_Local.RemovePlayerStubble(self.character, self.isBeard, true)
        FaceManager_Local.SyncRemoveCustomisation(self.character)
        FaceManager_Local.OnClothingUpdated(self.character)

        _resetStubbleGrowthIfNeeded(self.character, self.isBeard)

    elseif isClient() then
        sendClientCommand(self.character, "SPNCC", "RemovePlayerStubble", { isBeard = self.isBeard })

    else
        local FaceManager_Server = require("CharacterCustomisation/FaceManager_Server")
        FaceManager_Server.RemovePlayerStubble(self.character, self.isBeard, true)
        FaceManager_Server.SyncRemoveCustomisation(self.character)
        FaceManager_Server.OnClothingUpdated(self.character)

        _resetStubbleGrowthIfNeeded(self.character, self.isBeard)
    end

    return true
end


function IS_ShaveStubble:getDuration()
	if self.character:isTimedActionInstant() then
		return 1
	end

	return 50
end

function IS_ShaveStubble:stopSound()
	if self.sound and self.character:getEmitter():isPlaying(self.sound) then
		self.character:stopOrTriggerSound(self.sound);
	end
end

function IS_ShaveStubble:new(character, isBeard, item)
	local o = ISBaseTimedAction.new(self, character);
	o.item = item;
	o.isBeard = isBeard;
	o.maxTime = o:getDuration();
	return o;
end


return IS_ShaveStubble
