Distributions = Distributions or {};

local function AddKATTAJ1FlashlightToLoot(proc_name, item_name, chance)
	local data = ProceduralDistributions.list
	if not data then
		 return print('KATTAJ1 Tactical Flashlight ERROR: procedure distributions not found!')
	end
	local c = data[proc_name];
	if not c then
		 return print('KATTAJ1 Tactical Flashlight ERROR: cant add KATTAJ1 Tactical Flashlight')
	end
	table.insert(c.items, item_name);
	table.insert(c.items, chance);
end


AddKATTAJ1FlashlightToLoot("ArmyStorageElectronics",	"KATTAJ1_TacticalFlashlight", 1.0); 
AddKATTAJ1FlashlightToLoot("ArmySurplusTools",		"KATTAJ1_TacticalFlashlight", 0.1); 			 		 
AddKATTAJ1FlashlightToLoot("ToolStoreMisc",			"KATTAJ1_TacticalFlashlight", 0.1);               		        		
AddKATTAJ1FlashlightToLoot("LockerArmyBedroom",		"KATTAJ1_TacticalFlashlight", 0.3);    		    	 
AddKATTAJ1FlashlightToLoot("ToolStoreTools",			"KATTAJ1_TacticalFlashlight", 0.1);      		    	 
AddKATTAJ1FlashlightToLoot("CrateCamping",			"KATTAJ1_TacticalFlashlight", 0.05);       			 	
AddKATTAJ1FlashlightToLoot("GarageTools",			"KATTAJ1_TacticalFlashlight", 0.1);         			 	
AddKATTAJ1FlashlightToLoot("GunStoreCounter",		"KATTAJ1_TacticalFlashlight", 0.2);      	    		
AddKATTAJ1FlashlightToLoot("GigamartTools",			"KATTAJ1_TacticalFlashlight", 0.1); 
AddKATTAJ1FlashlightToLoot("PoliceStorageGuns",		"KATTAJ1_TacticalFlashlight", 0.3); 
AddKATTAJ1FlashlightToLoot("PoliceLockers",			"KATTAJ1_TacticalFlashlight", 0.3); 
AddKATTAJ1FlashlightToLoot("PrisonGuardLockers",		"KATTAJ1_TacticalFlashlight", 0.4); 
AddKATTAJ1FlashlightToLoot("ArmyHangarTools",		"KATTAJ1_TacticalFlashlight", 0.2); 