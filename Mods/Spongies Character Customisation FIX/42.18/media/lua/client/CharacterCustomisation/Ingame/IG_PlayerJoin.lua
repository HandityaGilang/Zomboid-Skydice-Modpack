local FaceManager_Local = require("CharacterCustomisation/FaceManager_Local")

local function _useLocalSingleplayerPath()
	return not isClient() and not isServer()
end

	-- -----------------------------------------
	-- -- SET UP MOD DATA AFTER CHARACTER CREATION
	-- -----------------------------------------
local OnNewCharacterTimer
local function OnNewCharacter()
	OnNewCharacterTimer = OnNewCharacterTimer - 1
	if OnNewCharacterTimer > 0 then return end
	Events.OnPlayerUpdate.Remove(OnNewCharacter)

	local player = getPlayer()
	if not player then return end

	local clientData = require("CharacterCustomisation/CharacterCreation/StoredCharacterData")

	if _useLocalSingleplayerPath() then
		FaceManager_Local.SetCustomisationNewCharacter(player, clientData)
	else
		sendClientCommand(player, "SPNCC", "SetCustomisationNewCharacter", { data = clientData })
	end
end

local function onNewGame(player)
	OnNewCharacterTimer = 3
	Events.OnPlayerUpdate.Add(OnNewCharacter)
end

	-- -----------------------------------------------
	-- -- OPEN CHARACTER CUSTOMISATION FOR OLD CHARACTERS
	-- -----------------------------------------------
local OnPlayerJoinTimer
local function OnPlayerJoin()
	OnPlayerJoinTimer = OnPlayerJoinTimer - 1
	if OnPlayerJoinTimer > 0 then return end
	Events.OnPlayerUpdate.Remove(OnPlayerJoin)

	local player = getPlayer()
	if not player then return end

	if _useLocalSingleplayerPath() then
		FaceManager_Local.OnPlayerJoin(player)
	else
		sendClientCommand(player, "SPNCC", "OnPlayerJoin", {})
	end
end

local function onCreatePlayer(playerNum, player)
	OnPlayerJoinTimer = 6
	Events.OnPlayerUpdate.Add(OnPlayerJoin)
end

Events.OnNewGame.Add(onNewGame)
Events.OnCreatePlayer.Add(onCreatePlayer)