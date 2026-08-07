require 'NPCs/ZombiesZoneDefinition'
-- Code to add sandbox settings for spawnchances

local function DoIt() --It does the thing
	local SWAT_UnitSpawnrate = SandboxVars.JordanalSpawns.SWAT_UnitChance;

	if SWAT_UnitSpawnrate > 0.00 then
        table.insert(ZombiesZoneDefinition.Police,{name = "SWAT_Unit", chance = SWAT_UnitSpawnrate});
        table.insert(ZombiesZoneDefinition.Prison,{name = "SWAT_Unit", chance = SWAT_UnitSpawnrate});
	end
	
    local SWAT_UnitSpawnrate_General = SandboxVars.JordanalSpawns.SWAT_UnitChance_General;

	if SWAT_UnitSpawnrate_General > 0.00 then
		table.insert(ZombiesZoneDefinition.Default,{name = "SWAT_Unit", chance = SWAT_UnitSpawnrate_General});
	end

end
Events.OnPostDistributionMerge.Add(DoIt);