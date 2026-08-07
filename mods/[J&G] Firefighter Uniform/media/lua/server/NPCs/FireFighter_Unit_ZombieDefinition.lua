require 'NPCs/ZombiesZoneDefinition'
-- Code to add sandbox settings for spawnchances

local function DoIt() --It does the thing
	local FireFighter_UnitSpawnrate_FireDept = SandboxVars.JordanalSpawns.FireFighter_UnitChance_FireDept;

	if FireFighter_UnitSpawnrate_FireDept > 0.00 then 
        table.insert(ZombiesZoneDefinition.FireDept,{name = "FireFighter_Unit", chance = FireFighter_UnitSpawnrate_FireDept});
	end
end
Events.OnPostDistributionMerge.Add(DoIt);