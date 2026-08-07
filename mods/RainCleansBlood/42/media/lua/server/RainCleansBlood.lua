RainCleansBlood = RainCleansBlood or { id = "RainCleansBlood" }

-- -------------------------------------------------------------------------- --
--                                  Handlers                                  --
-- -------------------------------------------------------------------------- --
function RainCleansBlood:onEveryOneMinute()
    if not self:shouldClean() then
        return
    end

    local cell = getCell()
    if not cell then
        return
    end

    for _ = 1, (SandboxVars.RainCleansBlood.TilesPerMinute or 1) do
        local tile = self:getNextTile(cell)

        if tile then
            if tile:haveBlood() then
                tile:removeBlood(false, false)
            end

            if SandboxVars.RainCleansBlood.AlsoCleanAsh ~= false then
                local objects = tile:getObjects()

                for i = 0, objects:size() - 1 do
                    local object = objects:get(i)

                    if object and object:getName() == "burnedCorpse" then
                        object:removeFromSquare()
                    end
                end
            end

            if SandboxVars.RainCleansBlood.AlsoCleanDroppings ~= false and tile.checkHaveDung and tile:checkHaveDung() then
                tile:removeAllDung()
            end
        end
    end

    if SandboxVars.RainCleansBlood.AlsoCleanVehicles then
        self:cleanNearbyVehicles(cell)
    end

    if SandboxVars.RainCleansBlood.AlsoCleanClothes then
        self:cleanAllPlayersClothes()
    end
end


-- -------------------------------------------------------------------------- --
--                                   Methods                                  --
-- -------------------------------------------------------------------------- --
function RainCleansBlood:cleanNearbyVehicles(cell)
    local vehicles = cell:getVehicles()
    local speed = (SandboxVars.RainCleansBlood.VehicleCleanSpeed or 0.1) / 1000

    local iterator = vehicles:iterator()
    while iterator:hasNext() do
        local vehicle = iterator:next()

        if vehicle then
            local front = vehicle:getBloodIntensity("Front") or 0
            local rear  = vehicle:getBloodIntensity("Rear")  or 0
            local left  = vehicle:getBloodIntensity("Left")  or 0
            local right = vehicle:getBloodIntensity("Right") or 0

            if front > 0 then vehicle:setBloodIntensity("Front", front - speed) end
            if rear  > 0 then vehicle:setBloodIntensity("Rear",  rear  - speed) end
            if left  > 0 then vehicle:setBloodIntensity("Left",  left  - speed) end
            if right > 0 then vehicle:setBloodIntensity("Right", right - speed) end
        end
    end
end

function RainCleansBlood:cleanAllPlayersClothes()
    local players = getOnlinePlayers()
    if not players or players:size() == 0 then
        local player = getSpecificPlayer(0)
        if not player then
            return
        end

        local square = player:getCurrentSquare()
        if square and (square:isOutside() or SandboxVars.RainCleansBlood.AlsoCleanInside) then
            self:cleanAndSyncPlayer(player)
        end

        return
    end

    for i = 0, players:size() - 1 do
        local player = players:get(i)
        if player then
            local square = player:getCurrentSquare()
            if square and (square:isOutside() or SandboxVars.RainCleansBlood.AlsoCleanInside) then
                self:cleanAndSyncPlayer(player)
            end
        end
    end
end

function RainCleansBlood:cleanAndSyncPlayer(player)
    local changes = {}
    local speed = SandboxVars.RainCleansBlood.ClothesCleanSpeed or 0.1
    local items = player:getInventory():getItems()
    local wornItems = player:getWornItems()

    for j = 0, items:size() - 1 do
        local item = items:get(j)
        if instanceof(item, "Clothing") and wornItems:contains(item) then
            local blood = item:getBloodLevel()
            local dirt  = item:getDirtiness()

            if (blood and blood > 0) or (dirt and dirt > 0) then
                local newBlood = math.max(0, (blood or 0) - speed)
                local newDirt  = math.max(0, (dirt  or 0) - speed)
                item:setBloodLevel(newBlood)
                item:setDirtiness(newDirt)

                local coveredParts = BloodClothingType.getCoveredParts(item:getBloodClothingType())
                if coveredParts then
                    for k = 0, coveredParts:size() - 1 do
                        local part = coveredParts:get(k)
                        item:setBlood(part, newBlood / 100)
                        item:setDirt(part, newDirt / 100)
                    end
                end

                table.insert(changes, { id = item:getID(), blood = newBlood, dirt = newDirt })
            end
        end
    end

    for _, item in ipairs({ player:getPrimaryHandItem(), player:getSecondaryHandItem() }) do
        if item then
            local blood = tonumber(item:getBloodLevel())
            if blood and blood > 0 then
                local newBlood = math.max(0, blood - speed)
                item:setBloodLevel(newBlood)
                table.insert(changes, { id = item:getID(), blood = newBlood })
            end
        end
    end

    local visualChanged = false
    local humanVisual = player:getVisual()
    if humanVisual then
        for i = 0, BloodBodyPartType.MAX:index() - 1 do
            local part = BloodBodyPartType.FromIndex(i)
            local blood = humanVisual:getBlood(part)
            local dirt  = humanVisual:getDirt(part)

            if blood and blood > 0 then
                humanVisual:setBlood(part, math.max(0, blood - speed / 100))
                visualChanged = true
            end

            if dirt and dirt > 0 then
                humanVisual:setDirt(part, math.max(0, dirt - speed / 100))
                visualChanged = true
            end
        end
    end

    if visualChanged or #changes > 0 then
        syncVisuals(player)
        player:resetModelNextFrame()
    end

    if #changes > 0 then
        sendClientCommand(player, self.id, "applyClean", changes)
    end
end


-- -------------------------------------------------------------------------- --
--                                   Helpers                                  --
-- -------------------------------------------------------------------------- --
function RainCleansBlood:shouldClean()
    if SandboxVars.RainCleansBlood.AlwaysClean then
        return true
    end

    local climateManager = getClimateManager()
    if not climateManager then
        return false
    end

    local intensity = math.max(
        climateManager:getRainIntensity(),
        climateManager:getSnowIntensity()
    )

    return intensity > (SandboxVars.RainCleansBlood.WeatherThreshold or 0.25)
end

function RainCleansBlood:getNextTile(cell)
    local minX = cell:getMinX()
    local minY = cell:getMinY()
    local maxX = cell:getMaxX()
    local maxY = cell:getMaxY()

    for _ = 1, 10 do
        local x = ZombRand(minX, maxX)
        local y = ZombRand(minY, maxY)
        local tile = cell:getGridSquare(x, y, 0)

        if tile and (tile:isOutside() or SandboxVars.RainCleansBlood.AlsoCleanInside) then
            return tile
        end
    end

    return nil
end


-- -------------------------------------------------------------------------- --
--                                 Hook events                                --
-- -------------------------------------------------------------------------- --
Events.EveryOneMinute.Add(function() RainCleansBlood:onEveryOneMinute() end)
