-- ************************************************************************
-- **        ██████  ██████   █████  ██    ██ ███████ ███    ██          **
-- **        ██   ██ ██   ██ ██   ██ ██    ██ ██      ████   ██          **
-- **        ██████  ██████  ███████ ██    ██ █████   ██ ██  ██          **
-- **        ██   ██ ██   ██ ██   ██  ██  ██  ██      ██  ██ ██          **
-- **        ██████  ██   ██ ██   ██   ████   ███████ ██   ████          **
-- ************************************************************************
-- ** All rights reserved. This content is protected by © Copyright law. **
-- ************************************************************************

---@param container string
---@param itemDistro table
local function addToProceduralDistribution(container, itemDistro)
    local list = ProceduralDistributions.list
	if not list or not list[container] then return end

	for _, value in ipairs(itemDistro) do
		 table.insert(ProceduralDistributions.list[container].items, value)
	end
end

local function onInitWorld()
	
	addToProceduralDistribution("BedroomDresser", {"WristWatch_Left_ClassicBlack", 1})
	addToProceduralDistribution("BedroomSideTable", {"WristWatch_Left_ClassicBlack", 1})
	addToProceduralDistribution("WardrobeChild", {"WristWatch_Left_ClassicBlack", 1})
	addToProceduralDistribution("WardrobeMan", {"WristWatch_Left_ClassicBlack", 1})
	addToProceduralDistribution("WardrobeManClassy", {"WristWatch_Left_ClassicBlack", 1})
	addToProceduralDistribution("WardrobeRedneck", {"WristWatch_Left_ClassicBlack", 1})
	addToProceduralDistribution("WardrobeWoman", {"WristWatch_Left_ClassicBlack", 1})
	addToProceduralDistribution("WardrobeWomanClassy", {"WristWatch_Left_ClassicBlack", 1})

	addToProceduralDistribution("BedroomDresser", {"WristWatch_Left_ClassicBrown", 1})
	addToProceduralDistribution("BedroomSideTable", {"WristWatch_Left_ClassicBrown", 1})
	addToProceduralDistribution("WardrobeChild", {"WristWatch_Left_ClassicBrown", 1})
	addToProceduralDistribution("WardrobeMan", {"WristWatch_Left_ClassicBrown", 1})
	addToProceduralDistribution("WardrobeManClassy", {"WristWatch_Left_ClassicBrown", 1})
	addToProceduralDistribution("WardrobeRedneck", {"WristWatch_Left_ClassicBrown", 1})
	addToProceduralDistribution("WardrobeWoman", {"WristWatch_Left_ClassicBrown", 1})
	addToProceduralDistribution("WardrobeWomanClassy", {"WristWatch_Left_ClassicBrown", 1})

	addToProceduralDistribution("BedroomDresser", {"WristWatch_Left_ClassicMilitary", 1})
	addToProceduralDistribution("BedroomSideTable", {"WristWatch_Left_ClassicMilitary", 1})
	addToProceduralDistribution("WardrobeChild", {"WristWatch_Left_ClassicMilitary", 1})
	addToProceduralDistribution("WardrobeMan", {"WristWatch_Left_ClassicMilitary", 1})
	addToProceduralDistribution("WardrobeManClassy", {"WristWatch_Left_ClassicMilitary", 1})
	addToProceduralDistribution("WardrobeRedneck", {"WristWatch_Left_ClassicMilitary", 1})
	addToProceduralDistribution("WardrobeWoman", {"WristWatch_Left_ClassicMilitary", 1})
	addToProceduralDistribution("WardrobeWomanClassy", {"WristWatch_Left_ClassicMilitary", 1})

	addToProceduralDistribution("BedroomDresser", {"WristWatch_Left_ClassicGold", 1})
	addToProceduralDistribution("BedroomSideTable", {"WristWatch_Left_ClassicGold", 1})
	addToProceduralDistribution("WardrobeChild", {"WristWatch_Left_ClassicGold", 1})
	addToProceduralDistribution("WardrobeMan", {"WristWatch_Left_ClassicGold", 1})
	addToProceduralDistribution("WardrobeManClassy", {"WristWatch_Left_ClassicGold", 1})
	addToProceduralDistribution("WardrobeRedneck", {"WristWatch_Left_ClassicGold", 1})
	addToProceduralDistribution("WardrobeWoman", {"WristWatch_Left_ClassicGold", 1})
	addToProceduralDistribution("WardrobeWomanClassy", {"WristWatch_Left_ClassicGold", 1})

	addToProceduralDistribution("BedroomDresser", {"WristWatch_Left_DigitalBlack", 1})
	addToProceduralDistribution("BedroomSideTable", {"WristWatch_Left_DigitalBlack", 1})
	addToProceduralDistribution("WardrobeChild", {"WristWatch_Left_DigitalBlack", 1})
	addToProceduralDistribution("WardrobeMan", {"WristWatch_Left_DigitalBlack", 1})
	addToProceduralDistribution("WardrobeManClassy", {"WristWatch_Left_DigitalBlack", 1})
	addToProceduralDistribution("WardrobeRedneck", {"WristWatch_Left_DigitalBlack", 1})
	addToProceduralDistribution("WardrobeWoman", {"WristWatch_Left_DigitalBlack", 1})
	addToProceduralDistribution("WardrobeWomanClassy", {"WristWatch_Left_DigitalBlack", 1})

	addToProceduralDistribution("BedroomDresser", {"WristWatch_Left_DigitalRed", 1})
	addToProceduralDistribution("BedroomSideTable", {"WristWatch_Left_DigitalRed", 1})
	addToProceduralDistribution("WardrobeChild", {"WristWatch_Left_DigitalRed", 1})
	addToProceduralDistribution("WardrobeMan", {"WristWatch_Left_DigitalRed", 1})
	addToProceduralDistribution("WardrobeManClassy", {"WristWatch_Left_DigitalRed", 1})
	addToProceduralDistribution("WardrobeRedneck", {"WristWatch_Left_DigitalRed", 1})
	addToProceduralDistribution("WardrobeWoman", {"WristWatch_Left_DigitalRed", 1})
	addToProceduralDistribution("WardrobeWomanClassy", {"WristWatch_Left_DigitalRed", 1})

	addToProceduralDistribution("BedroomDresser", {"WristWatch_Left_DigitalDress", 1})
	addToProceduralDistribution("BedroomSideTable", {"WristWatch_Left_DigitalDress", 1})
	addToProceduralDistribution("WardrobeChild", {"WristWatch_Left_DigitalDress", 1})
	addToProceduralDistribution("WardrobeMan", {"WristWatch_Left_DigitalDress", 1})
	addToProceduralDistribution("WardrobeManClassy", {"WristWatch_Left_DigitalDress", 1})
	addToProceduralDistribution("WardrobeRedneck", {"WristWatch_Left_DigitalDress", 1})
	addToProceduralDistribution("WardrobeWoman", {"WristWatch_Left_DigitalDress", 1})
	addToProceduralDistribution("WardrobeWomanClassy", {"WristWatch_Left_DigitalDress", 1})
end

Events.OnInitWorld.Add(onInitWorld)