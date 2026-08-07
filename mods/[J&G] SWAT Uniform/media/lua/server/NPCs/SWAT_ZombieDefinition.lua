require 'NPCs/ZombiesZoneDefinition'
-- Code to add sandbox settings for spawnchances

local function DoIt() --It does the thing
	local SWAT_UnitSpawnrate = SandboxVars.JordanalSpawns.SWAT_UnitChance;

	if SWAT_UnitSpawnrate > 0.00 then
        table.insert(ZombiesZoneDefinition.Police,{name = "SWAT_Unit", chance = SWAT_UnitSpawnrate});
        table.insert(ZombiesZoneDefinition.Prison,{name = "SWAT_Unit", chance = SWAT_UnitSpawnrate});
		table.insert(ZombiesZoneDefinition.Default,{name = "SWAT_Unit", chance = 0.04});
        table.insert(ZombiesZoneDefinition.Army, {name = "SWAT_Unit", chance = 0.02});
        table.insert(ZombiesZoneDefinition.SecretBase,{name = "SWAT_Unit", chance= 0.01});
	end
	
end
Events.OnPostDistributionMerge.Add(DoIt);
