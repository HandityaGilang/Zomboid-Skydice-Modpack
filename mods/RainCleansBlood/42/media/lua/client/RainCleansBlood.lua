RainCleansBlood = RainCleansBlood or { id = "RainCleansBlood" }

-- -------------------------------------------------------------------------- --
--                                 Hook events                                --
-- -------------------------------------------------------------------------- --
Events.OnServerCommand.Add(function(module, command, args)
    if module ~= RainCleansBlood.id or command ~= "applyClean" then
        return
    end

    local player = getSpecificPlayer(0)
    if not player then
        return
    end

    local items = player:getInventory():getItems()

    for _, change in ipairs(args) do
        for j = 0, items:size() - 1 do
            local item = items:get(j)

            if item and tonumber(item:getID()) == tonumber(change.id) then
                item:setBloodLevel(change.blood or 0)

                if change.dirt ~= nil then
                    item:setDirtiness(change.dirt)
                end

                break
            end
        end
    end

    player:resetModelNextFrame()
end)
