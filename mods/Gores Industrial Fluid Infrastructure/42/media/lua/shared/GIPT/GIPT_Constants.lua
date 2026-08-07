GIPT = GIPT or {}
GIPT.MODULE = "GIPT"
GIPT.VERSION = 19
GIPT.SPRITE_PREFIX = "melos_tiles_random_props_industry_05_"
GIPT.TRANSACTION_TIMEOUT_SECONDS = 45

-- Native gasoline transfers involving the compact tank use the same visible
-- timing envelope as the proven propane adapter: at least 120 action ticks,
-- scaling to 350 ticks for 20 litres. Vanilla may choose a longer duration.
GIPT.COMPACT_GAS_TRANSFER_MIN_TIME = 120
GIPT.COMPACT_GAS_TRANSFER_TIME_PER_LITRE = 350 / 20

GIPT.FLUID_EMPTY = "EMPTY"
GIPT.FLUID_PROPANE = "PROPANE"
GIPT.FLUID_GASOLINE = "GASOLINE"
GIPT.FLUID_WATER = "WATER"
GIPT.FLUID_NATIVE = "NATIVE"

GIPT.POINTS_PER_PORTABLE_TANK = 10000
GIPT.LITRES_PER_PORTABLE_PROPANE_TANK = 20
GIPT.PROPANE_ADAPTERS = {
    ["Base.PropaneTank"] = { fullPoints = 10000, label = "Propane Tank", duration = 350 },
    ["Base.BlowTorch"] = { fullPoints = 1250, label = "Welding Torch", duration = 120 },
    ["Base.Propane_Refill"] = { fullPoints = 1250, label = "Propane Refill", duration = 120 },
}
GIPT.ADAPTERS = GIPT.PROPANE_ADAPTERS

function GIPT.isPropaneSpriteName(name)
    return name and string.find(name, GIPT.SPRITE_PREFIX, 1, true) == 1
end

function GIPT.getSpriteIndex(name)
    if not GIPT.isPropaneSpriteName(name) then return nil end
    return tonumber(string.sub(name, #GIPT.SPRITE_PREFIX + 1))
end

function GIPT.getObjectRole(obj)
    local sprite = obj and obj:getSprite()
    local index = sprite and GIPT.getSpriteIndex(sprite:getName())
    if index and index >= 0 and index <= 63 then return "tankTile" end
    if index and index >= 64 and index <= 71 then return "dispenser" end
    if index and index >= 72 and index <= 75 then return "smallTank" end
    return nil
end

function GIPT.getTankClass(obj)
    local role = GIPT.getObjectRole(obj)
    if role == "smallTank" then return "SMALL" end
    if role == "tankTile" or role == "dispenser" then return "LARGE" end
    return nil
end

function GIPT.isSmallTankObject(obj)
    return GIPT.getObjectRole(obj) == "smallTank"
end

function GIPT.isLargeInstallationObject(obj)
    local role = GIPT.getObjectRole(obj)
    return role == "tankTile" or role == "dispenser"
end

function GIPT.getLargeTankSpriteInfo(objOrName)
    local name = objOrName
    local sprite
    if type(objOrName) ~= "string" then
        sprite = objOrName and objOrName:getSprite()
        name = sprite and sprite:getName()
    end
    local index = GIPT.getSpriteIndex(name)
    if not index or index < 0 or index > 63 then return nil end

    local relative = index % 16
    local info = {
        index = index,
        family = math.floor(index / 16),
        gridX = math.floor(relative / 4),
        gridY = 3 - (relative % 4),
        width = 4,
        height = 4,
    }
    if sprite and sprite.getSpriteGrid then
        local okGrid, grid = pcall(function() return sprite:getSpriteGrid() end)
        if okGrid and grid then
            local okX, gridX = pcall(function() return grid:getSpriteGridPosX(sprite) end)
            local okY, gridY = pcall(function() return grid:getSpriteGridPosY(sprite) end)
            local okW, width = pcall(function() return grid:getWidth() end)
            local okH, height = pcall(function() return grid:getHeight() end)
            if okX and gridX ~= nil then info.gridX = tonumber(gridX) or info.gridX end
            if okY and gridY ~= nil then info.gridY = tonumber(gridY) or info.gridY end
            if okW and width ~= nil then info.width = math.max(1, tonumber(width) or info.width) end
            if okH and height ~= nil then info.height = math.max(1, tonumber(height) or info.height) end
            info.spriteGrid = grid
        end
    end
    return info
end

function GIPT.getAdapter(item)
    if not item or not item.getFullType then return nil end
    return GIPT.PROPANE_ADAPTERS[item:getFullType()]
end

function GIPT.clamp(value, low, high)
    value = tonumber(value) or low
    return math.max(low, math.min(high, value))
end

function GIPT.getItemFraction(item)
    if not item then return nil end
    if item.getCurrentUsesFloat then
        local ok, value = pcall(function() return item:getCurrentUsesFloat() end)
        if ok and value ~= nil then return GIPT.clamp(value, 0, 1) end
    end
    if item.getUsedDelta then
        local ok, value = pcall(function() return item:getUsedDelta() end)
        if ok and value ~= nil then return GIPT.clamp(value, 0, 1) end
    end
    return nil
end

function GIPT.setItemFraction(item, fraction)
    if not item then return false end
    fraction = GIPT.clamp(fraction, 0, 1)
    if item.setCurrentUsesFloat then
        local ok = pcall(function() item:setCurrentUsesFloat(fraction) end)
        if ok then return true end
    end
    if item.setUsedDelta then
        local ok = pcall(function() item:setUsedDelta(fraction) end)
        if ok then return true end
    end
    return false
end

function GIPT.getFluidContainer(item)
    if not item or not item.getFluidContainer then return nil end
    local ok, container = pcall(function() return item:getFluidContainer() end)
    if ok then return container end
    return nil
end

function GIPT.isCleanWaterContainer(item)
    local container = GIPT.getFluidContainer(item)
    if not container or container:getFreeCapacity() <= 0.0001 then return false end
    if container:isEmpty() then return true end
    return container:contains(Fluid.Water) and not container:contains(Fluid.TaintedWater)
end

function GIPT.isAdmin(player)
    if not player then return false end
    if not isMultiplayer() then return true end
    local level = string.lower(tostring(player:getAccessLevel() or ""))
    return level == "admin" or level == "moderator" or level == "overseer"
end

GIPT.BULK_SOURCE_ADAPTERS = GIPT.BULK_SOURCE_ADAPTERS or {}
function GIPT.RegisterBulkFluidSource(adapter)
    if type(adapter) ~= "table" or type(adapter.id) ~= "string" or type(adapter.fluidType) ~= "string" then return false end
    if type(adapter.findNearby) ~= "function" or type(adapter.getAmount) ~= "function" or type(adapter.removeAmount) ~= "function" then return false end
    GIPT.BULK_SOURCE_ADAPTERS[adapter.id] = adapter
    return true
end
function GIPT.RegisterBulkPropaneSource(adapter)
    adapter.fluidType = GIPT.FLUID_PROPANE
    return GIPT.RegisterBulkFluidSource(adapter)
end
function GIPT.getBulkDeliveryRange()
    local range = 4
    if SandboxVars and SandboxVars.GIPT and SandboxVars.GIPT.BulkDeliveryRange then
        range = tonumber(SandboxVars.GIPT.BulkDeliveryRange) or range
    end
    return GIPT.clamp(range, 1, 12)
end

function GIPT.fluidDisplayName(fluidType)
    if fluidType == GIPT.FLUID_PROPANE then return "Propane" end
    if fluidType == GIPT.FLUID_GASOLINE then return "Gasoline" end
    if fluidType == GIPT.FLUID_WATER then return "Clean water" end
    if fluidType == GIPT.FLUID_NATIVE then return "Stored liquid" end
    return "Empty"
end

function GIPT.amountToLitres(amount, fluidType)
    amount = tonumber(amount) or 0
    if fluidType == GIPT.FLUID_PROPANE then
        return amount * GIPT.LITRES_PER_PORTABLE_PROPANE_TANK / GIPT.POINTS_PER_PORTABLE_TANK
    end
    return amount
end

function GIPT.formatLitres(amount, fluidType)
    local litres = GIPT.amountToLitres(amount, fluidType)
    if math.abs(litres - math.floor(litres + 0.5)) < 0.05 then
        return string.format("%d L", math.floor(litres + 0.5))
    end
    return string.format("%.1f L", litres)
end
