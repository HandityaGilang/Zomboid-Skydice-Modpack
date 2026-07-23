local function enableBicycleFix()
    if PZAPI and PZAPI.ModOptions then
        local bicycleOptions = PZAPI.ModOptions:getOptions("BicycleMod")
        if bicycleOptions then
            local fixOption = bicycleOptions:getOption("BicycleBetterInvFix")
            if fixOption and not fixOption:getValue() then
                fixOption:setValue(true)
                PZAPI.ModOptions:save("BicycleMod")
            end
        end
    end
end

Events.OnGameStart.Add(enableBicycleFix)