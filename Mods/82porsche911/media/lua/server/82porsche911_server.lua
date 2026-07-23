require "DAMN_Parts";
require "DAMN_Spawns";

--***********************************************************
--**                   KI5 / bikinihorst                   **
--***********************************************************

DAMN.Parts:processConfigV2("PRS82", {
	["FrontBumper"] = {
		partId = "PRS82FrontBumper",
		itemToModel = {
			["Base.82porsche911turboBumperFront0"] = "FrontBumper0",
			["Base.82porsche911turboBumperFrontA"] = "FrontBumper1",
			["Base.82porsche911BullbarFrontA"] = "FrontBumper2",
		},
		default = "first",
	},
    ["FrontBumperRWB"] = {
		partId = "PRS82FrontBumper",
		itemToModel = {
			["Base.82porsche911RWBBumperFront1"] = "FrontBumper0",
			["Base.82porsche911RWBBumperFrontA"] = "FrontBumper1",
			["Base.82porsche911BullbarFrontA"] = "FrontBumper2",
		},
		default = "first",
	},
    ["FrontBumperSC"] = {
		partId = "PRS82FrontBumper",
		itemToModel = {
			["Base.82porsche911SCBumperFront0"] = "FrontBumper0",
			["Base.82porsche911SCBumperFrontA"] = "FrontBumper1",
			["Base.82porsche911BullbarFrontA"] = "FrontBumper2",
		},
		default = "first",
	},
    ["FrontBumperLip"] = {
		partId = "PRS82FrontLip",
		itemToModel = {
			["Base.82porsche911SClip"] = "FrontBumperLip",
		},
		default = "trve_random",
		noPartChance = 50,
	},
    ["FrontBumperFogs"] = {
		partId = "PRS82FrontFogs",
		itemToModel = {
			["Base.82porsche911SCfogs"] = "FrontBumperFogs",
		},
		default = "trve_random",
		noPartChance = 50,
	},
	["RearBumper"] = {
		partId = "PRS82RearBumper",
		itemToModel = {
			["Base.82porsche911turboBumperRear0"] = "RearBumper0",
		},
		default = "trve_random",
		noPartChance = 2,
	},
    ["RearBumperRWB"] = {
		partId = "PRS82RearBumper",
		itemToModel = {
			["Base.82porsche911RWBBumperRear1"] = "RearBumper0",
		},
		default = "trve_random",
		noPartChance = 2,
	},
    ["RearBumperSC"] = {
		partId = "PRS82RearBumper",
		itemToModel = {
			["Base.82porsche911SCBumperRear0"] = "RearBumper0",
            ["Base.82porsche911SCBumperRear1"] = "RearBumper1",
		},
		default = "trve_random",
		noPartChance = 2,
	},
	["WindshieldArmor"] = {
		partId = "PRS82WindshieldArmor",
		itemToModel = {
			["Base.82porsche911WindshieldArmor"] = "PRS82winda",
		},
	},
	["WindshieldRearArmor"] = {
		partId = "PRS82WindshieldRearArmor",
		itemToModel = {
			["Base.82porsche911WindshieldRearArmor"] = "PRS82windra",
		},
	},
    ["WindshieldRearArmorTA"] = {
		partId = "PRS82WindshieldRearArmor",
		itemToModel = {
			["Base.82porsche911taWindshieldRearArmor"] = "PRS82windra",
		},
	},
	["FrontLeftArmor"] = {
		partId = "PRS82FrontLeftArmor",
		itemToModel = {
			["Base.82porsche911FrontWindowArmor"] = "PRS82fla",
		},
	},
	["FrontRightArmor"] = {
		partId = "PRS82FrontRightArmor",
		itemToModel = {
			["Base.82porsche911FrontWindowArmor"] = "PRS82fra",
		},
	},
	["RearLeftArmor"] = {
		partId = "PRS82RearLeftArmor",
		itemToModel = {
			["Base.82porsche911RearWindowArmor"] = "PRS82rla",
		},
	},
	["RearRightArmor"] = {
		partId = "PRS82RearRightArmor",
		itemToModel = {
			["Base.82porsche911RearWindowArmor"] = "PRS82rra",
		},
	},
	["SpareTire"] = {
		partId = "PRS82Spare",
		itemToModel = {
			["Base.82porsche911TurboTire"] = "na0",
            ["Base.82porsche911SCTire"] = "na2",
		},
		default = "trve_random",
		noPartChance = 10,
	},
    ["SpareTireRWB"] = {
		partId = "PRS82Spare",
		itemToModel = {
			["Base.82porsche911RWBTire"] = "na0",
		},
		default = "trve_random",
		noPartChance = 10,
	},
    ["SpoilerRWB"] = {
		partId = "PRS82Spoiler",
		itemToModel = {
			["Base.82porsche911RWBSpoiler0"] = "PRS82Spoiler0",
		},
		default = "trve_random",
		noPartChance = 20,
	},
    ["SpoilerSC"] = {
		partId = "PRS82Spoiler",
		itemToModel = {
			["Base.82porsche911SCSpoiler1"] = "PRS82Spoiler0",
		},
		default = "trve_random",
		noPartChance = 80,
	},
    ["TireFrontLeft"] = {
		partId = "TireFrontLeft",
		itemToModel = {
			["Base.82porsche911TurboTire"] = "PRSTireFL",
            ["Base.82porsche911SCTire"] = "PRSTire2FL",
		},
	},
	["TireFrontRight"] = {
		partId = "TireFrontRight",
		itemToModel = {
            ["Base.82porsche911TurboTire"] = "PRSTireFR",
            ["Base.82porsche911SCTire"] = "PRSTire2FR",
		},
	},
	["TireRearLeft"] = {
		partId = "TireRearLeft",
		itemToModel = {
            ["Base.82porsche911TurboTire"] = "PRSTireRL",
            ["Base.82porsche911SCTire"] = "PRSTire2FL",
		},
	},
	["TireRearRight"] = {
		partId = "TireRearRight",
		itemToModel = {
            ["Base.82porsche911TurboTire"] = "PRSTireRR",
            ["Base.82porsche911SCTire"] = "PRSTire2FR",
		},
	},
    ["TireFrontLeftSC"] = {
		partId = "TireFrontLeft",
		itemToModel = {
			["Base.82porsche911SCTire"] = "PRSTireFL",
            ["Base.82porsche911TurboTire"] = "PRSTire2FL",
		},
	},
	["TireFrontRightSC"] = {
		partId = "TireFrontRight",
		itemToModel = {
            ["Base.82porsche911SCTire"] = "PRSTireFR",
            ["Base.82porsche911TurboTire"] = "PRSTire2FR",
		},
	},
	["TireRearLeftSC"] = {
		partId = "TireRearLeft",
		itemToModel = {
            ["Base.82porsche911SCTire"] = "PRSTireRL",
            ["Base.82porsche911TurboTire"] = "PRSTire2FL",
		},
	},
	["TireRearRightSC"] = {
		partId = "TireRearRight",
		itemToModel = {
            ["Base.82porsche911SCTire"] = "PRSTireRR",
            ["Base.82porsche911TurboTire"] = "PRSTire2FR",
		},
	},
});


function PRS82.ContainerAccess.RearSeat(vehicle, part, chr)
	if chr:getVehicle() == vehicle then
		local seat = vehicle:getSeat(chr)
		return seat == 1 or seat == 0;
	elseif chr:getVehicle() then
		return false
	else
		if not vehicle:isInArea(part:getArea(), chr) then return false end
		local doorPart = vehicle:getPartById("DoorFrontLeft")
		if doorPart and doorPart:getDoor() and not doorPart:getDoor():isOpen() then
			return false
		end
		return true
	end
end