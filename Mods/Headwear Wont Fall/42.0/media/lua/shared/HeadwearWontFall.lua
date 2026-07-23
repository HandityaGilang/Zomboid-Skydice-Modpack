function HeadwearWontFall()
    local items = getAllItems()

    for i = 0, items:size() - 1 do
        local item = items:get(i)

        if item:getChanceToFall() > 0 then
            item:DoParam("ChanceToFall = 0")
        end
    end
end
Events.OnSpawnRegionsLoaded.Add(HeadwearWontFall)
Events.OnLoad.Add(HeadwearWontFall)
Events.OnInitWorld.Add(HeadwearWontFall)
Events.OnPreMapLoad.Add(HeadwearWontFall)
Events.OnGameBoot.Add(HeadwearWontFall)
