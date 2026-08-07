local TABAS_WaterReader = {}

local TABAS_GameTimes = require("TABAS_GameTimes")

local function isWaterInfinite(obj)
    local sprite = obj:getSprite()
    if not sprite then return false end
    
    local props = sprite:getProperties()
    if props:has("waterAmount") and tonumber(props:get("waterAmount")) >= 9999 then
        return true
    elseif obj:getSquare() and obj:getSquare():getRoom() then
        if not props:has(IsoFlagType.waterPiped) then
            return false
        elseif obj:getSquare():isNoWater() then
            return false
        elseif TABAS_GameTimes.getWorldAgeHours() / 24 + ((getSandboxOptions():getOptionByName("TimeSinceApo"):getValue() - 1) * 30) >= getSandboxOptions():getWaterShutModifier() then
            return false
        else
            return not obj:hasModData() or not obj:getModData().canBeWaterPiped
        end
    else
        return false
    end
end

local function findWaterSourceOnSquare(square)
    if not square then return end
    for i=1, square:getObjects():size() do
        local obj = square:getObjects():get(i-1)
        if instanceof(obj, "IsoThumpable") and (not obj:getSprite() or not obj:getSprite().solidfloor) and not obj:getUsesExternalWaterSource() and obj:getFluidCapacity() > 0 then
            return obj
        end
    end
end

-- Return all containers in the top 3x3 square of coordinates
local function findExternalWaterSource(x, y, z, availableNoWater)
    local square = getCell():getGridSquare(x, y, z +1)
    local containers = {}
    local container = findWaterSourceOnSquare(square)
    if container then
        if availableNoWater or container:hasWater() then
            table.insert(containers, container)
        end
    end
    for i=-1, 1 do
        for j=-1, 1 do
            if i ~= 0 or j ~= 0 then
                local _square = getCell():getGridSquare(x + i, y + j, z +1)
                local _container = findWaterSourceOnSquare(_square)
                if _container then
                    if availableNoWater or _container:hasWater() then
                        table.insert(containers, _container)
                    end
                end
            end
        end
    end
    return containers
end

-- Returns the counts of all the piped containers.
function TABAS_WaterReader.getExternalContainerCount(obj)
    if not obj:getSprite() then return 0 end
    if obj:getUsesExternalWaterSource() then
        if isWaterInfinite(obj) then -- if is use the water supply or natural water tiles
            return 0
        end
        local square = obj:getSquare()
        local containers = findExternalWaterSource(square:getX(), square:getY(), square:getZ(), true)
        return #containers
    end
    return 0
end

function TABAS_WaterReader.getExternalContainer(obj)
    if not obj:getSprite() then return 0 end
    if obj:getUsesExternalWaterSource() then
        if isWaterInfinite(obj) then -- if is use the water supply or natural water tiles
            return nil
        end
        local square = obj:getSquare()
        return findExternalWaterSource(square:getX(), square:getY(), square:getZ(), true)
    end
    return nil
end

-- Returns the water amount of all piped containers.
function TABAS_WaterReader.getWaterAmount(obj)
    if not obj:getSprite() then return 0 end
    if obj:getUsesExternalWaterSource() then
        if isWaterInfinite(obj) then
            return 10000
        else
            local square = obj:getSquare()
            local total = 0
            local containers = findExternalWaterSource(square:getX(), square:getY(), square:getZ())
            if #containers > 0 then
                for i=1, #containers do
                    local container = containers[i]
                    if container and container:getFluidContainer() then
                        local amount = container:getFluidAmount()
                        total = total + amount
                    end
                end
            end
            return total
        end
    else
        return obj:getFluidAmount()
    end
end

-- Read the total capacity of all piped containers.
function TABAS_WaterReader.getWaterCapacity(obj)
    if not obj:getSprite() then return 0 end
    if obj:getUsesExternalWaterSource() then
        if isWaterInfinite(obj) then
            return 10000
        else
            local square = obj:getSquare()
            local total = 0
            local containers = findExternalWaterSource(square:getX(), square:getY(), square:getZ())
            if #containers > 0 then
                for i=1, #containers do
                    local container = containers[i]
                    if container and container:getFluidCapacity() then
                        local capacity = container:getFluidCapacity()
                        total = total + capacity
                    end
                end
            end
            return total
        end
    end
    return obj:getFluidCapacity()
end

-- Use water from all piped containers.
-- This is done one by one from lowest coordinate to highest coordinate until there are no fluid left.
function TABAS_WaterReader.consume(obj, amount)
    if amount <= 0 then return 0 end
    if not obj or not obj:getSprite() then return 0 end

    if obj:getUsesExternalWaterSource() then
        if isWaterInfinite(obj) then
            return amount
        end

        local sq = obj:getSquare()
        if not sq then return 0 end

        local containers = findExternalWaterSource(sq:getX(), sq:getY(), sq:getZ())
        local remaining = amount
        local consumedTotal = 0

        for i=1, #containers do
            if remaining <= 0 then break end
            local cont = containers[i]
            if cont and cont:getFluidContainer() then
                local used = cont:useFluid(remaining)
                consumedTotal = consumedTotal + used
                remaining = remaining - used
                cont:sync()
            end
        end

        return consumedTotal
    end

    return obj:useFluid(amount)
end

return TABAS_WaterReader
