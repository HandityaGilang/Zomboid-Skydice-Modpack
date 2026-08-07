require 'NPCs/ZombiesZoneDefinition'
-- Code to add sandbox settings for spawnchances

local function DoIt() --It does the thing
	local Trauma_ResponderSpawnrate = SandboxVars.JordanalSpawns.Trauma_ResponderChance;

	if Trauma_ResponderSpawnrate > 0.00 then
        table.insert(ZombiesZoneDefinition.Army, {name = "Trauma_Responder", chance = Trauma_ResponderSpawnrate});
        table.insert(ZombiesZoneDefinition.SecretBase,{name = "Trauma_Responder", chance = Trauma_ResponderSpawnrate});
	end
	
	local Trauma_ResponderSpawnrate_General = SandboxVars.JordanalSpawns.Trauma_ResponderChance_General;

	if Trauma_ResponderSpawnrate_General > 0.00 then
		table.insert(ZombiesZoneDefinition.Default,{name = "Trauma_Responder", chance = Trauma_ResponderSpawnrate_General});
	end

	local Trauma_ResponderSpawnrate_Medical = SandboxVars.JordanalSpawns.Trauma_ResponderChance_Medical;

	if Trauma_ResponderSpawnrate_Medical > 0.00 then 
        table.insert(ZombiesZoneDefinition.Doctor,{name = "Trauma_Responder", chance = Trauma_ResponderSpawnrate_Medical});
		table.insert(ZombiesZoneDefinition.Pharmacist,{name = "Trauma_Responder", chance = Trauma_ResponderSpawnrate_Medical});
	end
end
Events.OnPostDistributionMerge.Add(DoIt);