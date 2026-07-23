require "DAMN_Parts";
require "DAMN_Spawns";

--***********************************************************
--**                   KI5 / bikinihorst                   **
--***********************************************************

DAMN.Parts:processConfigV2("LP400", {
	["BumperFront"] = {
		partId = "DAMNBumperFront",
		itemToModel = {
			["Base.78lamboCountachBumperFront"] = "BumperFront0",
            ["Base.78lamboCountachSBumperFront"] = "BumperFront1",
			["Base.78lamboCountachBumperFrontA"] = "BumperFrontA",
            ["Base.78lamboCountachSBumperFrontB"] = "BumperFrontB",
			["Base.78lamboCountachBullbarA"] = "BullbarFrontA",
		},
		default = "Base.78lamboCountachBumperFront",
	},
    ["BumperFrontS"] = {
		partId = "DAMNBumperFront",
		itemToModel = {
			["Base.78lamboCountachBumperFront"] = "BumperFront0",
            ["Base.78lamboCountachSBumperFront"] = "BumperFront1",
			["Base.78lamboCountachBumperFrontA"] = "BumperFrontA",
            ["Base.78lamboCountachSBumperFrontB"] = "BumperFrontB",
			["Base.78lamboCountachBullbarA"] = "BullbarFrontA",
		},
		default = "Base.78lamboCountachSBumperFront",
	},
    ["BumperRear"] = {
		partId = "DAMNBumperRear",
		itemToModel = {
			["Base.78lamboCountachSBumperRear"] = "BumperRear0",
		},
		default = "trve_random",
		noPartChance = 75,
	},
	["WindshieldArmor"] = {
		partId = "DAMNWindshieldArmor",
		itemToModel = {
			["Base.78lamboCountachWindshieldArmor"] = "winda0",
		},
	},
	["WindshieldRearArmor"] = {
		partId = "DAMNWindshieldRearArmor",
		itemToModel = {
			["Base.78lamboCountachWindshieldRearArmor"] = "windra",
		},
		default = "first",
	},
	["FrontLeftArmor"] = {
		partId = "DAMNFrontLeftArmor",
		itemToModel = {
			["Base.78lamboCountachFrontWindowArmor"] = "leftdoora",
		},
	},
	["FrontRightArmor"] = {
		partId = "DAMNFrontRightArmor",
		itemToModel = {
			["Base.78lamboCountachFrontWindowArmor"] = "rightdoora",
		},
	},
	["RearLeftArmor"] = {
		partId = "DAMNRearLeftArmor",
		itemToModel = {
			["Base.78lamboCountachRearWindowArmor"] = "leftdoorra",
		},
	},
	["RearRightArmor"] = {
		partId = "DAMNRearRightArmor",
		itemToModel = {
			["Base.78lamboCountachRearWindowArmor"] = "rightdoorra",
		},
	},
	["SpareTire"] = {
		partId = "DAMNSpareTire",
		itemToModel = {
			["Base.78lamboCountachTire3"] = "Spare0",
            ["damnCraft.SmallTire1"] = "Spare1",
		},
		default = "trve_random",
		noPartChance = 25,
	},
    ["SpareTireS"] = {
		partId = "DAMNSpareTire",
		itemToModel = {
			["Base.78lamboCountachSTire3"] = "Spare0",
            ["damnCraft.SmallTire1"] = "Spare1",
		},
		default = "trve_random",
		noPartChance = 25,
	},
    ["Spoiler"] = {
		partId = "DAMNSpoiler",
		itemToModel = {
			["Base.78lamboCountachRearSpoiler3"] = "Spoiler0",
            ["Base.78lamboCountachRearSpoilerTwo3"] = "Spoiler1",
		},
		default = "trve_random",
		noPartChance = 85,
	},
    ["SpoilerS"] = {
		partId = "DAMNSpoiler",
		itemToModel = {
			["Base.78lamboCountachRearSpoiler3"] = "Spoiler0",
            ["Base.78lamboCountachRearSpoilerTwo3"] = "Spoiler1",
		},
		default = "trve_random",
		noPartChance = 15,
	},
    ["SpoilerC"] = {
		partId = "DAMNSpoiler",
		itemToModel = {
			["Base.78lamboCountachRearSpoiler3"] = "Spoiler0",
            ["Base.78lamboCountachRearSpoilerTwo3"] = "Spoiler1",
		},
		default = "Base.78lamboCountachRearSpoiler3",
	},
    ["SpoilerF"] = {
		partId = "LP400SpoilerFront",
		itemToModel = {
			["Base.78lamboCountachFrontSpoiler3"] = "Spoilerf",
		},
		default = "trve_random",
		noPartChance = 85,
	},
    ["Vent"] = {
		partId = "LP400HoodVent",
		itemToModel = {
			["Base.78lamboCountachEngineDoorVent3"] = "Vent",
		},
		default = "trve_random",
		noPartChance = 15,
	},
    ["TireFrontLeft"] = {
		partId = "TireFrontLeft",
		itemToModel = {
			["Base.78lamboCountachTire3"] = "tire1",
            ["damnCraft.SmallTire1"] = "tire2",
		},
        default = "Base.78lamboCountachTire3",
	},
	["TireFrontRight"] = {
		partId = "TireFrontRight",
		itemToModel = {
			["Base.78lamboCountachTire3"] = "tire1",
            ["damnCraft.SmallTire1"] = "tire2",
		},
        default = "Base.78lamboCountachTire3",
	},
	["TireRearLeft"] = {
		partId = "TireRearLeft",
		itemToModel = {
			["Base.78lamboCountachTire3"] = "tire1",
            ["damnCraft.SmallTire1"] = "tire2",
		},
        default = "Base.78lamboCountachTire3",
	},
	["TireRearRight"] = {
		partId = "TireRearRight",
		itemToModel = {
			["Base.78lamboCountachTire3"] = "tire1",
            ["damnCraft.SmallTire1"] = "tire2",
		},
        default = "Base.78lamboCountachTire3",
	},
    ["TireFrontLeftS"] = {
		partId = "TireFrontLeft",
		itemToModel = {
			["Base.78lamboCountachSTire3"] = "tire1",
            ["damnCraft.SmallTire1"] = "tire2",
		},
        default = "Base.78lamboCountachSTire3",
	},
	["TireFrontRightS"] = {
		partId = "TireFrontRight",
		itemToModel = {
			["Base.78lamboCountachSTire3"] = "tire1",
            ["damnCraft.SmallTire1"] = "tire2",
		},
        default = "Base.78lamboCountachSTire3",
	},
	["TireRearLeftS"] = {
		partId = "TireRearLeft",
		itemToModel = {
			["Base.78lamboCountachSTire3"] = "tire1",
            ["damnCraft.SmallTire1"] = "tire2",
		},
        default = "Base.78lamboCountachSTire3",
	},
	["TireRearRightS"] = {
		partId = "TireRearRight",
		itemToModel = {
			["Base.78lamboCountachSTire3"] = "tire1",
            ["damnCraft.SmallTire1"] = "tire2",
		},
        default = "Base.78lamboCountachSTire3",
	},
});

function LP400.PopupLights(player)
    local vehicle = player.getVehicle and player:getVehicle() or nil
    if (vehicle and string.find( vehicle:getScriptName(), "78lamboCountachLP400" )) or (vehicle and string.find( vehicle:getScriptName(), "78lamboCountachLP400S" )) then

        local part = vehicle:getPartById("LP400PopupLights")
        local opened = part:getDoor():isOpen()
        local active = vehicle:getHeadlightsOn()

        if active and opened then return
            elseif not active and opened then
                vehicle:playPartAnim(part, "Close")
                vehicle:playPartSound(part, player, "Close")
                part:getDoor():setOpen(false)
                vehicle:transmitPartDoor(part)
            elseif active and not opened then
                vehicle:playPartAnim(part, "Open")
                vehicle:playPartSound(part, player, "Open")
                part:getDoor():setOpen(true)
                vehicle:transmitPartDoor(part)
        end
    end
end

Events.OnPlayerUpdate.Add(LP400.PopupLights);

function LP400.ContainerAccess.TrunkFront(vehicle, part, chr)
	if chr:getVehicle() then return false end
	if not vehicle:isInArea(part:getArea(), chr) then return false end
	local doorPart = vehicle:getPartById("LP400TrunkDoorFront")
	if doorPart and doorPart:getDoor() then
		if not doorPart:getInventoryItem() then return true end
		if not doorPart:getDoor():isOpen() then return false end
	end
	--
	return true
end