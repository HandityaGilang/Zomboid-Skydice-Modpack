local getVehicleStoriesList = require("YAPZLib/RVSBase").getVehicleStoriesList

local stories = {}
stories["MilitaryBlockade"] = true
stories["MilitaryBlockpost"] = true
stories["MilitaryConvoy"] = true
stories["BiohazardCrash"] = true

local function doRoadStoriesSandbox()
	if not SandboxVars.VMZ.RoadStories then
		local list = getVehicleStoriesList()
		for i = #list, 1, -1 do
			local storyType = list[i]
			if stories[storyType] then
				table.remove(list, i)
			end
		end
	end
end

Events.OnInitGlobalModData.Add(doRoadStoriesSandbox)