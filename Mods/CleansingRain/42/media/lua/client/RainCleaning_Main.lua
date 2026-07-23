require "RainCleaning_Constants"

local checkTimer = 0

local function GetItemDirt(item)
    if item.getDirtiness then return item:getDirtiness() end
    if item.getDirtyness then return item:getDirtyness() end
    return 0
end

local function GetMaterialRate(item)
    local settings = RainCleaning.Settings
    if item and instanceof(item, "Clothing") and item.getFabricType then
        local fabric = item:getFabricType()
        if fabric == "Leather" then
            return settings.Rates.Character_Leather
        end
    end
    return settings.Rates.Character_Cloth
end

local function GetRainCurve(rainIntensity)
    return rainIntensity + 0.5
end

local function CleanWeapon(item, rainCurve, settings)
    if not item or not instanceof(item, "HandWeapon") then return false end
    local currentBlood = 0
    if item.getBloodLevel then currentBlood = item:getBloodLevel() end
    if currentBlood > 0 then
        local drop = settings.Rates.Character_Leather * rainCurve
        local newBlood = math.max(0, currentBlood - drop)
        if item.setBloodLevel then item:setBloodLevel(newBlood) end
        return true
    end
    return false
end

local function CleanPlayer(player, rainIntensity)
    local isUpdated = false
    local settings = RainCleaning.Settings
    local rainCurve = GetRainCurve(rainIntensity)

    local visual = player:getHumanVisual()
    if visual then
        for i=1, BloodBodyPartType.MAX:index() do
            local part = BloodBodyPartType.FromIndex(i-1)
            if visual:getBlood(part) > 0 then
                local drop = settings.Rates.Character_Skin * rainCurve
                visual:setBlood(part, math.max(0, visual:getBlood(part) - drop))
                isUpdated = true
            end
            if visual:getDirt(part) > 0 then
                local drop = settings.Rates.Character_Skin * rainCurve * settings.DirtMultiplier
                visual:setDirt(part, math.max(0, visual:getDirt(part) - drop))
                isUpdated = true
            end
        end
    end

    local wornItems = player:getWornItems()
    if wornItems then
        for i=0, wornItems:size()-1 do
            local item = wornItems:get(i):getItem()
            if item then
                if instanceof(item, "Clothing") then
                    local itemVisual = item:getVisual()
                    if itemVisual then
                        local materialRate = GetMaterialRate(item)
                        local itemUpdated = false
                        for j=1, BloodBodyPartType.MAX:index() do
                            local part = BloodBodyPartType.FromIndex(j-1)
                            if itemVisual:getBlood(part) > settings.CleaningLimit then
                                itemVisual:setBlood(part, math.max(settings.CleaningLimit, itemVisual:getBlood(part) - (materialRate * rainCurve)))
                                itemUpdated, isUpdated = true, true
                            end
                            if itemVisual:getDirt(part) > settings.CleaningLimit then
                                itemVisual:setDirt(part, math.max(settings.CleaningLimit, itemVisual:getDirt(part) - (materialRate * rainCurve * settings.DirtMultiplier)))
                                itemUpdated, isUpdated = true, true
                            end
                        end
                        if itemUpdated and BloodClothingType then
                            BloodClothingType.calcTotalBloodLevel(item)
                            BloodClothingType.calcTotalDirtLevel(item)
                        end
                    end
                elseif instanceof(item, "InventoryContainer") then
                    local currentBlood = item:getBloodLevel()
                    local currentDirt = GetItemDirt(item)
                    local bagRate = settings.Rates.Character_Cloth * settings.BagMultiplier

                    if currentBlood > settings.CleaningLimit then
                        item:setBloodLevel(math.max(settings.CleaningLimit, currentBlood - (bagRate * rainCurve)))
                        isUpdated = true
                    end
                    if currentDirt > settings.CleaningLimit then
                        local newDirt = math.max(0, currentDirt - (bagRate * rainCurve * settings.DirtMultiplier))
                        if item.setDirtiness then item:setDirtiness(newDirt)
                        elseif item.setDirtyness then item:setDirtyness(newDirt) end
                        isUpdated = true
                    end
                end
            end
        end
    end

    if CleanWeapon(player:getPrimaryHandItem(), rainCurve, settings) then isUpdated = true end
    if CleanWeapon(player:getSecondaryHandItem(), rainCurve, settings) then isUpdated = true end

    if isUpdated then
        player:resetModelNextFrame()
        if sendVisual then sendVisual(player) end
    end
end

local function CleanWorldVehicles(rainIntensity)
    local cell = getCell()
    if not cell then return end

    local vehicleList = cell:getVehicles()
    if not vehicleList or vehicleList:size() == 0 then return end

    local size = vehicleList:size()
    local vehicleArray = vehicleList:toArray()
    if not vehicleArray then return end

    local settings = RainCleaning.Settings
    local rainCurve = GetRainCurve(rainIntensity)
    local zones = {"Front", "Rear", "Left", "Right", "Top"}

    for i = 0, size - 1 do
        local vehicle = vehicleArray[i]
        if vehicle and vehicle.getSquare then
            local vSquare = vehicle:getSquare()
            if vSquare and vSquare.isOutside and vSquare:isOutside() then
                local vehicleUpdated = false
                for j = 1, #zones do
                    local zone = zones[j]
                    if vehicle.getBloodIntensity and vehicle.setBloodIntensity then
                        local currentBlood = vehicle:getBloodIntensity(zone)
                        if currentBlood > 0 then
                            local drop = settings.Rates.Vehicle_Blood * rainCurve
                            vehicle:setBloodIntensity(zone, math.max(0, currentBlood - drop))
                            vehicleUpdated = true
                        end
                    end
                end
                
                if vehicleUpdated and vehicle.updateHasBlood then
                    vehicle:updateHasBlood()
                end
            end
        end
    end
end

local function onRainCheck()
    local player = getPlayer()
    if not player then return end
    local climateMan = getClimateManager()
    if not climateMan then return end
    local rainIntensity = climateMan:getRainIntensity()
    if rainIntensity < RainCleaning.Settings.RainThreshold then return end

    CleanWorldVehicles(rainIntensity)

    local square = player:getSquare()
    if square and square:isOutside() then
        CleanPlayer(player, rainIntensity)
    end
end

local function updateRainCleaning()
    checkTimer = checkTimer + getGameTime():getMultiplier()
    if checkTimer >= (RainCleaning.Settings.UpdateFrequency * 60) then
        onRainCheck()
        checkTimer = 0
    end
end

Events.OnTick.Add(updateRainCleaning)