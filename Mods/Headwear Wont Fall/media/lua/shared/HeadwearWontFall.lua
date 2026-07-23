

function HeadwearWontFall()
local items = getAllItems()

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local Chance = item:getChanceToFall() 
              
        if Chance then
          
    if SandboxVars.HeadWearWontFall.Chance == 1 then  -- ChanceToFall = 0

        item:DoParam("ChanceToFall = 0")


   end
  end
 end
end
Events.OnSpawnRegionsLoaded.Add(HeadwearWontFall)
Events.OnLoad.Add(HeadwearWontFall)
Events.OnInitWorld.Add(HeadwearWontFall)
Events.OnPreMapLoad.Add(HeadwearWontFall)
Events.OnGameBoot.Add(HeadwearWontFall)