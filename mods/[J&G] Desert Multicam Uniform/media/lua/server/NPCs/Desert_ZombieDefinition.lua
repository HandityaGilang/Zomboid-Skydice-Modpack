require 'NPCs/ZombiesZoneDefinition'
-- Code to add sandbox settings for spawnchances

local function DoIt() --It does the thing
	local DesertCamoSpawnrate = SandboxVars.JordanalSpawns.Desert_Camo_UnitChance;

	if DesertCamoSpawnrate > 0.00 then
        table.insert(ZombiesZoneDefinition.Army, {name = "Desert_Camo_Unit", chance = DesertCamoSpawnrate});
        table.insert(ZombiesZoneDefinition.SecretBase,{name = "Desert_Camo_Unit", chance= DesertCamoSpawnrate});
		table.insert(ZombiesZoneDefinition.Default,{name = "Desert_Camo_Unit", chance = 0.04});
	end
	
end
Events.OnPostDistributionMerge.Add(DoIt);
