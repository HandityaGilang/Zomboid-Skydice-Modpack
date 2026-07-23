
local FaceManager_Server = require("CharacterCustomisation/FaceManager_Server")

local Commands = {}


	-- -------------------------------------
	-- -- COMMANDS
	-- -------------------------------------

function Commands.SetCustomisation(player, args)
	FaceManager_Server.SetCustomisation(player, args.data)
end

function Commands.SetCustomisationNewCharacter(player, args)
	FaceManager_Server.SetCustomisationNewCharacter(player, args.data)
end

function Commands.AddPlayerStubble(player, args)
	FaceManager_Server.AddPlayerStubble(player, args.isBeard, true)
end

function Commands.AddPlayerBodyHair(player, args)
	FaceManager_Server.AddPlayerBodyHair(player, true)
end

function Commands.SetPlayerMuscle(player, args)
	FaceManager_Server.SetPlayerMuscle(player)
	FaceManager_Server.SyncRemoveCustomisation(player)
	FaceManager_Server.OnClothingUpdated(player)
end

function Commands.RefreshCustomisation(player, args)
	FaceManager_Server.RefreshCustomisation(player)
end

function Commands.RequestPlayerModData(player, args)
	sendServerCommand(player, "SPNCC", "SetPlayerModData", {data = player:getModData().SPNCharCustom})
end

function Commands.OnPlayerJoin(player, args)
	FaceManager_Server.OnPlayerJoin(player)
end

function Commands.SyncBlood(player, args)
    args = args or {}
    FaceManager_Server.SyncBlood(player, args.bodyVisual)
end

local function _resetStubbleGrowthIfNeeded(player, isBeard)
    if not player or not player.getHumanVisual then return end

    local visual = player:getHumanVisual()
    if not visual then return end

    if isBeard then
        if visual:getBeardModel() == "" then
            player:resetBeardGrowingTime()
        end
    else
        if visual:getHairModel() == "Bald" then
            player:resetHairGrowingTime()
        end
    end
end

function Commands.RemovePlayerStubble(player, args)
    args = args or {}

    FaceManager_Server.RemovePlayerStubble(player, args.isBeard == true, true)
    FaceManager_Server.SyncRemoveCustomisation(player)
    FaceManager_Server.OnClothingUpdated(player)

    _resetStubbleGrowthIfNeeded(player, args.isBeard == true)
end

function Commands.RemovePlayerBodyHair(player, args)
    FaceManager_Server.RemovePlayerBodyHair(player, true)
    FaceManager_Server.SyncRemoveCustomisation(player)
    FaceManager_Server.OnClothingUpdated(player)
end


	-- -------------------------------------
	-- -- SETUP
	-- -------------------------------------
local DEBUG_SPNCC_COMMANDS = false

local function _debugCommand(command)
	if not DEBUG_SPNCC_COMMANDS then return end
	print("[SPNCC] Client command received: " .. tostring(command))
end

local function OnClientCommand(module, command, player, args)
	if module ~= "SPNCC" then return end

	local handler = Commands[command]
	if not handler then return end

	_debugCommand(command)
	handler(player, args or {})
end

Events.OnClientCommand.Add(OnClientCommand)
