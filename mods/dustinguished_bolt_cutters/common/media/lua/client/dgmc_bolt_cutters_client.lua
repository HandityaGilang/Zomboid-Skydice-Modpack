local constants = require("dgmc_bolt_cutters_constants")
local logger = require("dgmc_bolt_cutters_logger")

local Client = DGMC_BoltCutterClient or {}

---@param module string
---@param command string
---@param args table
function Client.onServerCommand(module, command, args)
	if module ~= constants.module or args == nil or args.playerID == nil then
		return
	end

	local player = getPlayerByOnlineID(args.playerID)

	if player == nil then
		player = getSpecificPlayer(args.playerID)

		if player == nil then
			logger.error("Client.onServerCommand", "unable to get player from %s", tostring(args.playerID))
			return
		end
	end

	local emitter = player:getEmitter()
	emitter:playSound("BuildMetalStructureSmallPoleFence")

	if command == constants.commands.shutter then
		emitter:playSound("GarageDoorOpen")
	end

	local square = player:getSquare()
	local soundManager = getWorldSoundManager()
	soundManager:addSound(nil, square:getX(), square:getY(), square:getZ(), 20, 20)
end

Events.OnServerCommand.Add(Client.onServerCommand)

_G.DGMC_BoltCutterClient = Client
return Client