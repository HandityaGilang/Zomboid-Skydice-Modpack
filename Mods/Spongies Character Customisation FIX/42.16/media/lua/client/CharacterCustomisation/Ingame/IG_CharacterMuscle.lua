local FaceManager_Local = require("CharacterCustomisation/FaceManager_Local")

local function _useLocalSingleplayerPath()
	return not isClient() and not isServer()
end

local function onLevelPerk(player, perk, level)
	if perk:getType() ~= Perks.Strength:getType() then return end
	if not player then return end

	if _useLocalSingleplayerPath() then
		FaceManager_Local.SetPlayerMuscle(player)
		FaceManager_Local.SyncRemoveCustomisation(player)
		FaceManager_Local.OnClothingUpdated(player)
	else
		sendClientCommand(player, "SPNCC", "SetPlayerMuscle", {})
	end
end

Events.LevelPerk.Add(onLevelPerk)