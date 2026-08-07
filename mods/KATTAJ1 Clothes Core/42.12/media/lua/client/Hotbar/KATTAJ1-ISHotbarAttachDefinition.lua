require "Hotbar/ISHotbarAttachDefinition"

if not ISHotbarAttachDefinition then
    return
end

local getActivatedMods = getActivatedMods
local size = size
local get = get

local function isMod(mod_Name)
    local mods = getActivatedMods();
    for i=0, mods:size()-1, 1 do
        if mods:get(i) == mod_Name then
            return true;
        end
    end
    return false;
end

if isMod("Better Belts") and (isMod("AuthenticZBackpacks+") or isMod("Authentic Z - Current")) then

	print("KATTAJ1 Tactical Flashlight: Better Belts and AuthenicZ installed")

	local MOD_DATA = {
		SmallBeltLeft = {
			FlashlightKATTAJ1 				= "KATTAJ1BeltLeft",
		},
		SmallBeltRight = {
			FlashlightKATTAJ1				= "KATTAJ1BeltRight",
		},
		SchoolbagFlashlight = {
			FlashlightKATTAJ1				= "Schoolbag Military Flashlight",
		},
		DufflebagFlashlight = {
			FlashlightKATTAJ1				= "Dufflebag Military Flashlight",
		},
		HikingBagFlashlight = {
			FlashlightKATTAJ1				= "HikingBag Military Flashlight",
		},
		BigHikingbagFlashlight = {
			FlashlightKATTAJ1				= "BigHikingBag Military Flashlight",
		},
		AlicepackFlashlight = {
			FlashlightKATTAJ1				= "Alicepack Military Flashlight",
		},
		ARVNFlashlight = {
			FlashlightKATTAJ1				= "Alicepack Military Flashlight",
		},
	}
	for _,t in pairs(ISHotbarAttachDefinition) do
		if t.type and MOD_DATA[t.type] then
			for k,v in pairs(MOD_DATA[t.type]) do
				if v == 0 and t.replacement then
					t.replacement[k] = nil
				elseif t.attachments then
					t.attachments[k] = v ~= 0 and v or nil
				else
					print('ERROR: Unknown mod data option.')
				end
			end
		end
	end
	
elseif isMod("Better Belts") then

	print("KATTAJ1 Tactical Flashlight: Better Belts installed")
	
	local MOD_DATA = {
		SmallBeltLeft = {
			FlashlightKATTAJ1 			= "KATTAJ1BeltLeft",
		},
		SmallBeltRight = {
			FlashlightKATTAJ1			= "KATTAJ1BeltRight",
		},
	}
	for _,t in pairs(ISHotbarAttachDefinition) do
		if t.type and MOD_DATA[t.type] then
			for k,v in pairs(MOD_DATA[t.type]) do
				if v == 0 and t.replacement then
					t.replacement[k] = nil
				elseif t.attachments then
					t.attachments[k] = v ~= 0 and v or nil
				else
					print('KATTAJ1 Tactical Flashlight: ERROR: Unknown mod data option.')
				end
			end
		end
	end
	
elseif isMod("AuthenticZBackpacks+") or isMod("Authentic Z - Current") then

	print("KATTAJ1 Tactical Flashlight: AuthenicZ installed")

	local MOD_DATA = {
		SmallBeltLeft = {
			FlashlightKATTAJ1 				= "KATTAJ1BeltLeft",
		},
		SmallBeltRight = {
			FlashlightKATTAJ1				= "KATTAJ1BeltRight",
		},
		SchoolbagFlashlight = {
			FlashlightKATTAJ1				= "Schoolbag Military Flashlight",
		},
		DufflebagFlashlight = {
			FlashlightKATTAJ1				= "Dufflebag Military Flashlight",
		},
		HikingBagFlashlight = {
			FlashlightKATTAJ1				= "HikingBag Military Flashlight",
		},
		BigHikingbagFlashlight = {
			FlashlightKATTAJ1				= "BigHikingBag Military Flashlight",
		},
		AlicepackFlashlight = {
			FlashlightKATTAJ1				= "Alicepack Military Flashlight",
		},
		ARVNFlashlight = {
			FlashlightKATTAJ1				= "Alicepack Military Flashlight",
		},
	}
	for _,t in pairs(ISHotbarAttachDefinition) do
		if t.type and MOD_DATA[t.type] then
			for k,v in pairs(MOD_DATA[t.type]) do
				if v == 0 and t.replacement then
					t.replacement[k] = nil
				elseif t.attachments then
					t.attachments[k] = v ~= 0 and v or nil
				else
					print('KATTAJ1 Tactical Flashlight:ERROR: Unknown mod data option.')
				end
			end
		end
	end

else

	print("KATTAJ1 Tactical Flashlight: No Mods installed")
	
	local MOD_DATA = {
		SmallBeltLeft = {
			FlashlightKATTAJ1 			= "KATTAJ1BeltLeft",
		},
		SmallBeltRight = {
			FlashlightKATTAJ1			= "KATTAJ1BeltRight",
		},
	}
	for _,t in pairs(ISHotbarAttachDefinition) do
		if t.type and MOD_DATA[t.type] then
			for k,v in pairs(MOD_DATA[t.type]) do
				if v == 0 and t.replacement then
					t.replacement[k] = nil
				elseif t.attachments then
					t.attachments[k] = v ~= 0 and v or nil
				else
					print('KATTAJ1 Tactical Flashlight:ERROR: Unknown mod data option.')
				end
			end
		end
	end
end

local KATTAJ1HelmetWithMount = {
	type = "KATTAJ1HelmetWithMount",
	name = "KATTAJ1 Helmet Mount",
	animset = "back",
	attachments = {
		FlashlightKATTAJ1				= "KATTAJ1HelmetMountRight",
	},
}
table.insert(ISHotbarAttachDefinition, KATTAJ1HelmetWithMount);