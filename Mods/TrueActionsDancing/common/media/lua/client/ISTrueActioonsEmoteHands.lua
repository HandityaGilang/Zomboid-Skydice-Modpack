--remove hands equipped items during the dance --Code by IbrRus
--add them back afterwards --Code by TwistOnFire
--Note: this is local only. items remain in hands in MP.
--TODO make MP reliable stuff for both remove and reequip.


local old_ISEmoteRadialMenu_emote = ISEmoteRadialMenu.emote

local TAD_DanceHandRestore = {
	players = {},
	activeCount = 0,
}

local function TAD_isDanceEmote(emote)
	return type(emote) == "string" and string.sub(emote, 1, string.len("BobTA")) == "BobTA"
end

local function TAD_getPlayerKey(playerObj)
	if not playerObj then return nil end
	if playerObj.getPlayerNum then
		return playerObj:getPlayerNum()
	end
	return 0
end

local function TAD_inventoryContainsItem(playerObj, item)
	if not playerObj or not item then return false end

	local inv = playerObj:getInventory()
	if not inv then return false end

	if inv.contains then
		local ok, result = pcall(function()
			return inv:contains(item, true)
		end)

		if ok and result then
			return true
		end

		ok, result = pcall(function()
			return inv:contains(item)
		end)

		if ok and result then
			return true
		end
	end

	if inv.containsID and item.getID then
		local ok, result = pcall(function()
			return inv:containsID(item:getID())
		end)

		if ok and result then
			return true
		end
	end

	return false
end

local function TAD_beginDanceHandRestore(playerObj, emote)
	local playerKey = TAD_getPlayerKey(playerObj)
	if playerKey == nil then return end

	local existing = TAD_DanceHandRestore.players[playerKey]
	if existing then
		existing.emote = emote
		return
	end

	local primary = playerObj:getPrimaryHandItem()
	local secondary = playerObj:getSecondaryHandItem()

	if not primary and not secondary then
		return
	end

	TAD_DanceHandRestore.players[playerKey] = {
		player = playerObj,
		emote = emote,
		primary = primary,
		secondary = secondary,
	}

	TAD_DanceHandRestore.activeCount = TAD_DanceHandRestore.activeCount + 1

	playerObj:setPrimaryHandItem(nil)
	playerObj:setSecondaryHandItem(nil)
end

local function TAD_restoreDanceHands(playerKey, state)
	if not state then return end

	local playerObj = state.player
	if not playerObj or playerObj:isDead() then
		TAD_DanceHandRestore.players[playerKey] = nil
		TAD_DanceHandRestore.activeCount = math.max(0, TAD_DanceHandRestore.activeCount - 1)
		return
	end

	local currentPrimary = playerObj:getPrimaryHandItem()
	local currentSecondary = playerObj:getSecondaryHandItem()

	local primary = state.primary
	local secondary = state.secondary

	local playerChangedHands =
		(currentPrimary and currentPrimary ~= primary and currentPrimary ~= secondary) or
		(currentSecondary and currentSecondary ~= primary and currentSecondary ~= secondary)

	if not playerChangedHands then
		if primary and not currentPrimary and TAD_inventoryContainsItem(playerObj, primary) then
			playerObj:setPrimaryHandItem(primary)
			currentPrimary = primary
		end

		if secondary and not currentSecondary and TAD_inventoryContainsItem(playerObj, secondary) then
			if secondary ~= primary or playerObj:getPrimaryHandItem() == primary then
				playerObj:setSecondaryHandItem(secondary)
			end
		end
	end

	TAD_DanceHandRestore.players[playerKey] = nil
	TAD_DanceHandRestore.activeCount = math.max(0, TAD_DanceHandRestore.activeCount - 1)
end

local function TAD_isStillPlayingTrackedDance(playerObj, state)
	if not playerObj or not state then return false end
	if playerObj:isDead() then return false end

	local isPlaying = playerObj:getVariableBoolean("EmotePlaying")
	if not isPlaying then return false end

	local currentEmote = playerObj:getVariableString("emote")
	if not TAD_isDanceEmote(currentEmote) then return false end

	return true
end

local function TAD_onPlayerUpdate_RestoreDanceHands(playerObj)
	if TAD_DanceHandRestore.activeCount <= 0 then return end
	if not playerObj then return end

	local playerKey = TAD_getPlayerKey(playerObj)
	if playerKey == nil then return end

	local state = TAD_DanceHandRestore.players[playerKey]
	if not state then return end

	if not TAD_isStillPlayingTrackedDance(playerObj, state) then
		TAD_restoreDanceHands(playerKey, state)
	end
end

if _G.TAD_onPlayerUpdate_RestoreDanceHands then
	Events.OnPlayerUpdate.Remove(_G.TAD_onPlayerUpdate_RestoreDanceHands)
end

_G.TAD_onPlayerUpdate_RestoreDanceHands = TAD_onPlayerUpdate_RestoreDanceHands
Events.OnPlayerUpdate.Add(_G.TAD_onPlayerUpdate_RestoreDanceHands)

function ISEmoteRadialMenu:emote(emote)
	if TAD_isDanceEmote(emote) then
		TAD_beginDanceHandRestore(self.character, emote)
	end

	old_ISEmoteRadialMenu_emote(self, emote)
end
