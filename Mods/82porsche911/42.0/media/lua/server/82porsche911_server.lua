require "DAMN_Parts";
require "DAMN_Spawns";

--***********************************************************
--**                   KI5 / bikinihorst                   **
--***********************************************************

DAMN.Parts:processConfigV2("PRS82", {
	["FrontBumper"] = {
		partId = "DAMNBumperFront",
		itemToModel = {
			["Base.82porsche911turboBumperFront0"] = "FrontBumper0",
			["Base.82porsche911turboBumperFrontA"] = "FrontBumper1",
			["Base.82porsche911BullbarFrontA"] = "FrontBumper2",
		},
		default = "first",
	},
    ["FrontBumperRWB"] = {
		partId = "DAMNBumperFront",
		itemToModel = {
			["Base.82porsche911RWBBumperFront1"] = "FrontBumper0",
			["Base.82porsche911RWBBumperFrontA"] = "FrontBumper1",
			["Base.82porsche911BullbarFrontA"] = "FrontBumper2",
		},
		default = "first",
	},
    ["FrontBumperSC"] = {
		partId = "DAMNBumperFront",
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
		partId = "DAMNBumperRear",
		itemToModel = {
			["Base.82porsche911turboBumperRear0"] = "RearBumper0",
		},
		default = "trve_random",
		noPartChance = 2,
	},
    ["RearBumperRWB"] = {
		partId = "DAMNBumperRear",
		itemToModel = {
			["Base.82porsche911RWBBumperRear1"] = "RearBumper0",
		},
		default = "trve_random",
		noPartChance = 2,
	},
    ["RearBumperSC"] = {
		partId = "DAMNBumperRear",
		itemToModel = {
			["Base.82porsche911SCBumperRear0"] = "RearBumper0",
            ["Base.82porsche911SCBumperRear1"] = "RearBumper1",
		},
		default = "trve_random",
		noPartChance = 2,
	},
	["WindshieldArmor"] = {
		partId = "DAMNWindshieldArmor",
		itemToModel = {
			["Base.82porsche911WindshieldArmor"] = "winda",
		},
	},
	["WindshieldRearArmor"] = {
		partId = "DAMNWindshieldRearArmor",
		itemToModel = {
			["Base.82porsche911WindshieldRearArmor"] = "windra",
		},
	},
    ["WindshieldRearArmorTA"] = {
		partId = "DAMNWindshieldRearArmor",
		itemToModel = {
			["Base.82porsche911taWindshieldRearArmor"] = "windra",
		},
	},
	["FrontLeftArmor"] = {
		partId = "DAMNFrontLeftArmor",
		itemToModel = {
			["Base.82porsche911FrontWindowArmor"] = "fla",
		},
	},
	["FrontRightArmor"] = {
		partId = "DAMNFrontRightArmor",
		itemToModel = {
			["Base.82porsche911FrontWindowArmor"] = "fra",
		},
	},
	["RearLeftArmor"] = {
		partId = "DAMNRearLeftArmor",
		itemToModel = {
			["Base.82porsche911RearWindowArmor"] = "rla",
		},
	},
	["RearRightArmor"] = {
		partId = "DAMNRearRightArmor",
		itemToModel = {
			["Base.82porsche911RearWindowArmor"] = "rra",
		},
	},
	["SpareTire"] = {
		partId = "DAMNSpareTireTrunk",
		itemToModel = {
			["Base.82porsche911TurboTire"] = "na0",
            ["damnCraft.SmallTire1"] = "na1",
            ["Base.82porsche911SCTire"] = "na2",
		},
		default = "trve_random",
		noPartChance = 10,
	},
    ["SpareTireRWB"] = {
		partId = "DAMNSpareTireTrunk",
		itemToModel = {
			["Base.82porsche911RWBTire"] = "na0",
            ["damnCraft.SmallTire1"] = "na1",
		},
		default = "trve_random",
		noPartChance = 10,
	},
    ["SpoilerRWB"] = {
		partId = "DAMNSpoiler",
		itemToModel = {
			["Base.82porsche911RWBSpoiler0"] = "Spoiler0",
		},
		default = "trve_random",
		noPartChance = 20,
	},
    ["SpoilerSC"] = {
		partId = "DAMNSpoiler",
		itemToModel = {
			["Base.82porsche911SCSpoiler1"] = "Spoiler0",
		},
		default = "trve_random",
		noPartChance = 80,
	},
    ["TireFrontLeft"] = {
		partId = "TireFrontLeft",
		itemToModel = {
			["Base.82porsche911TurboTire"] = "PRSTireFL",
			["damnCraft.SmallTire1"] = "PRSTireUNFL",
            ["Base.82porsche911SCTire"] = "PRSTire2FL",
		},
	},
	["TireFrontRight"] = {
		partId = "TireFrontRight",
		itemToModel = {
            ["Base.82porsche911TurboTire"] = "PRSTireFR",
			["damnCraft.SmallTire1"] = "PRSTireUNFR",
            ["Base.82porsche911SCTire"] = "PRSTire2FR",
		},
	},
	["TireRearLeft"] = {
		partId = "TireRearLeft",
		itemToModel = {
            ["Base.82porsche911TurboTire"] = "PRSTireRL",
			["damnCraft.SmallTire1"] = "PRSTireUNRL",
            ["Base.82porsche911SCTire"] = "PRSTire2FL",
		},
	},
	["TireRearRight"] = {
		partId = "TireRearRight",
		itemToModel = {
            ["Base.82porsche911TurboTire"] = "PRSTireRR",
			["damnCraft.SmallTire1"] = "PRSTireUNRR",
            ["Base.82porsche911SCTire"] = "PRSTire2FR",
		},
	},
    ["TireFrontLeftSC"] = {
		partId = "TireFrontLeft",
		itemToModel = {
			["Base.82porsche911SCTire"] = "PRSTireFL",
			["damnCraft.SmallTire1"] = "PRSTireUNFL",
            ["Base.82porsche911TurboTire"] = "PRSTire2FL",
		},
	},
	["TireFrontRightSC"] = {
		partId = "TireFrontRight",
		itemToModel = {
            ["Base.82porsche911SCTire"] = "PRSTireFR",
			["damnCraft.SmallTire1"] = "PRSTireUNFR",
            ["Base.82porsche911TurboTire"] = "PRSTire2FR",
		},
	},
	["TireRearLeftSC"] = {
		partId = "TireRearLeft",
		itemToModel = {
            ["Base.82porsche911SCTire"] = "PRSTireRL",
			["damnCraft.SmallTire1"] = "PRSTireUNRL",
            ["Base.82porsche911TurboTire"] = "PRSTire2FL",
		},
	},
	["TireRearRightSC"] = {
		partId = "TireRearRight",
		itemToModel = {
            ["Base.82porsche911SCTire"] = "PRSTireRR",
			["damnCraft.SmallTire1"] = "PRSTireUNRR",
            ["Base.82porsche911TurboTire"] = "PRSTire2FR",
		},
	},
    ["TireFrontLeftRWB"] = {
		partId = "TireFrontLeft",
		itemToModel = {
			["Base.82porsche911RWBTire"] = "PRSTireFL",
			["damnCraft.SmallTire1"] = "PRSTireUNFL",
		},
	},
	["TireFrontRightRWB"] = {
		partId = "TireFrontRight",
		itemToModel = {
            ["Base.82porsche911RWBTire"] = "PRSTireFR",
			["damnCraft.SmallTire1"] = "PRSTireUNFR",
		},
	},
	["TireRearLeftRWB"] = {
		partId = "TireRearLeft",
		itemToModel = {
            ["Base.82porsche911RWBTire"] = "PRSTireRL",
			["damnCraft.SmallTire1"] = "PRSTireUNRL",
		},
	},
	["TireRearRightRWB"] = {
		partId = "TireRearRight",
		itemToModel = {
            ["Base.82porsche911RWBTire"] = "PRSTireRR",
			["damnCraft.SmallTire1"] = "PRSTireUNRR",
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