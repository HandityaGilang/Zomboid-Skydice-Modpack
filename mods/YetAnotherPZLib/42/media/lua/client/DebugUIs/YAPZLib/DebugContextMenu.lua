local ISRVSBase = require("YAPZLib/RVSBase")
local __getGlobalObject = require("YAPZLib/Utils").getGlobalObject

local doYAPZVehicleStory = function(square, _type, zone)
	if isClient() then
		sendClientCommand("YAPZLib", "doVehicleStory", { zone = "nil", _type = _type, sqX = square:getX(), sqY = square:getY(), sqZ = square:getZ() })
	else
		local story = __getGlobalObject(_type):new()
		if story then
			ISRVSBase.doStory(story, square:getChunk(), nil, true)
		end
	end
end

local doDebugMenu = function(player, context, worldobjects, test)
	local playerObj = getSpecificPlayer(player)

	if isClient() then
		if not playerObj:getRole():hasCapability(Capability.UseDebugContextMenu) then
			return true
		end
	elseif not isDebugEnabled() then
		return true
	end

	if test and ISWorldObjectContextMenu.Test then return true end
	
	local mainOption = context:addDebugOption(getText("[YAPZLib] Randomized Road Story"), worldobjects, nil);
	local mainSubMenu = ISContextMenu:getNew(context)
	context:addSubMenu(mainOption, mainSubMenu)

	local square = nil
	for _, obj in ipairs(worldobjects) do
		square = obj:getSquare()
		break
	end
	
	if square and square:getZone() then
		if isClient() and not playerObj:getRole():hasCapability(Capability.CreateStory) then return end
		
		local storiesList = ISRVSBase.getVehicleStoriesList()

		for _, storyType in ipairs(storiesList) do
			local story = __getGlobalObject(storyType)
			if story then
				local zone = story:getValidZone(square:getChunk(), true)
				local rbOption = mainSubMenu:addOption(story.name, square, doYAPZVehicleStory, story.Type, zone)
				if not zone then
					rbOption.notAvailable = true
					local tooltip = ISWorldObjectContextMenu.addToolTip()
					tooltip:setName("Zone not valid")
					rbOption.toolTip = tooltip
				end
			end
		end
	end
end

Events.OnFillWorldObjectContextMenu.Add(doDebugMenu)

print(ISRVSBase.getVehicleFromZone)