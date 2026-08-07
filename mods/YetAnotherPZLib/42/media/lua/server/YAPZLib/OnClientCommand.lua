local ISRVSBase = require("YAPZLib/RVSBase")
local __getGlobalObject = require("YAPZLib/Utils").getGlobalObject

local __clientCommands = {}

__clientCommands.doVehicleStory = function(player, args)
	local square = getCell():getGridSquare(args.sqX, args.sqY, args.sqZ)
	if square then
		local chunk = square:getChunk()
		if not chunk then return end
		
		local story = __getGlobalObject(args._type):new()
		
		local zone = getZone(args.sqX, args.sqY, args.sqZ)
		if args.zone and args.zone == "nil" then
			zone = nil
		end
		
		if story then
			ISRVSBase.doStory(story, chunk, zone, true)
		end
	end
end

local onClientCommand = function(module, command, player, args)
	if module == "YAPZLib" and __clientCommands[command] then
		args = args or {}
		__clientCommands[command](player, args)
	end
end

Events.OnClientCommand.Add(onClientCommand)