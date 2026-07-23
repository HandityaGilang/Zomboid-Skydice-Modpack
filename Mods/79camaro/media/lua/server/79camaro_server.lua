require "DAMN_Parts";
require "DAMN_Spawns";

--***********************************************************
--**                   KI5 / bikinihorst                   **
--***********************************************************

DAMN.Parts:processConfigV2("CAM79", {
	["BumperFront"] = {
		partId = "DAMNBumperFront",
		itemToModel = {
			["Base.79camaroBumperFront0"] = "BumperFront0",
			["Base.79camaroBumperFrontA"] = "BumperFrontA",
            ["Base.79camaroGhostBumperFrontB"] = "BullbarFrontA",
		},
		default = "first",
	},
    ["BumperFrontGhost"] = {
		partId = "DAMNBumperFront",
		itemToModel = {
			["Base.79camaroBumperFront0"] = "BumperFront0",
			["Base.79camaroBumperFrontA"] = "BumperFrontA",
            ["Base.79camaroGhostBumperFrontB"] = "BullbarFrontA",
		},
		default = "Base.79camaroGhostBumperFrontB",
	},
	["BumperRear"] = {
		partId = "DAMNBumperRear",
		itemToModel = {
			["Base.79camaroBumperRear"] = "BumperRear0",
		},
		default = "first",
	},
	["WindshieldArmor"] = {
		partId = "DAMNWindshieldArmor",
		itemToModel = {
			["Base.79camaroWindshieldArmor"] = "winda0",
		},
	},
	["WindshieldRearArmor"] = {
		partId = "DAMNWindshieldRearArmor",
		itemToModel = {
			["Base.79camaroWindshieldRearArmor"] = "windra",
		},
	},
	["FrontLeftArmor"] = {
		partId = "DAMNFrontLeftArmor",
		itemToModel = {
			["Base.79camaroFrontWindowArmor"] = "leftdoora",
		},
	},
	["FrontRightArmor"] = {
		partId = "DAMNFrontRightArmor",
		itemToModel = {
			["Base.79camaroFrontWindowArmor"] = "rightdoora",
		},
	},
    ["Spoiler"] = {
		partId = "DAMNSpoiler",
		itemToModel = {
			["Base.79camaroSpoiler3"] = "Spoiler0",
            ["Base.79camaroGhostSpoiler3"] = "Spoiler1",
		},
		default = "first",
	},
    ["SpoilerOFF"] = {
		partId = "DAMNSpoiler",
		itemToModel = {
			["Base.79camaroSpoiler3"] = "Spoiler0",
            ["Base.79camaroGhostSpoiler3"] = "Spoiler1",
		},
	},
    ["SpoilerGhost"] = {
		partId = "DAMNSpoiler",
		itemToModel = {
			["Base.79camaroSpoiler3"] = "Spoiler0",
            ["Base.79camaroGhostSpoiler3"] = "Spoiler1",
		},
		default = "Base.79camaroGhostSpoiler3",
	},
    ["TireFrontLeft"] = {
		partId = "TireFrontLeft",
		itemToModel = {
			["Base.79camaroTire3"] = "Tire1",
			["Base.79camaroGhostTire3"] = "Tire2",
		},
        default = "Base.79camaroTire3",
	},
	["TireFrontRight"] = {
		partId = "TireFrontRight",
		itemToModel = {
			["Base.79camaroTire3"] = "Tire1",
			["Base.79camaroGhostTire3"] = "Tire2",
		},
        default = "Base.79camaroTire3",
	},
	["TireRearLeft"] = {
		partId = "TireRearLeft",
		itemToModel = {
			["Base.79camaroTire3"] = "Tire1",
			["Base.79camaroGhostTire3"] = "Tire2",
		},
        default = "Base.79camaroTire3",
	},
	["TireRearRight"] = {
		partId = "TireRearRight",
		itemToModel = {
			["Base.79camaroTire3"] = "Tire1",
			["Base.79camaroGhostTire3"] = "Tire2",
		},
        default = "Base.79camaroTire3",
	},
    ["TireFrontLeftGhost"] = {
		partId = "TireFrontLeft",
		itemToModel = {
			["Base.79camaroTire3"] = "Tire1",
			["Base.79camaroGhostTire3"] = "Tire2",
		},
        default = "Base.79camaroGhostTire3",
	},
	["TireFrontRightGhost"] = {
		partId = "TireFrontRight",
		itemToModel = {
			["Base.79camaroTire3"] = "Tire1",
			["Base.79camaroGhostTire3"] = "Tire2",
		},
        default = "Base.79camaroGhostTire3",
	},
	["TireRearLeftGhost"] = {
		partId = "TireRearLeft",
		itemToModel = {
			["Base.79camaroTire3"] = "Tire1",
			["Base.79camaroGhostTire3"] = "Tire2",
		},
        default = "Base.79camaroGhostTire3",
	},
	["TireRearRightGhost"] = {
		partId = "TireRearRight",
		itemToModel = {
			["Base.79camaroTire3"] = "Tire1",
			["Base.79camaroGhostTire3"] = "Tire2",
		},
        default = "Base.79camaroGhostTire3",
	},
});