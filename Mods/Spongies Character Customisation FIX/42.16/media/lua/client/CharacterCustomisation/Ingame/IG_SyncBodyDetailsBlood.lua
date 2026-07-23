local FaceManager_Shared = require("CharacterCustomisation/FaceManager_Shared")
local FaceManager_Local = require("CharacterCustomisation/FaceManager_Local")

local function _useLocalSingleplayerPath()
	return not isClient() and not isServer()
end

local BloodWasJustSynced = false
local pending = false
local pendingTicks = 0

local function _runSync()
	pending = false
	pendingTicks = 0

	local player = getPlayer()
	if not player then return end

	local item = FaceManager_Shared.GetFirstWornItemWithTag(player, SPNCC.ItemTag.CanHaveBlood)
	if not item then return end

	if _useLocalSingleplayerPath() then
		BloodWasJustSynced = true
		FaceManager_Local.SyncBlood(player)
	else
		sendClientCommand(player, "SPNCC", "SyncBlood", {})
	end
end

local function _tick()
	if not pending then
		Events.OnPlayerUpdate.Remove(_tick)
		return
	end

	pendingTicks = pendingTicks - 1
	if pendingTicks > 0 then return end

	Events.OnPlayerUpdate.Remove(_tick)
	_runSync()
end

local function SyncBloodOnClothingUpdated(player)
	if BloodWasJustSynced then
		BloodWasJustSynced = false
		return
	end

	if pending then return end
	pending = true
	pendingTicks = 10
	Events.OnPlayerUpdate.Add(_tick)
end

Events.OnClothingUpdated.Add(SyncBloodOnClothingUpdated)