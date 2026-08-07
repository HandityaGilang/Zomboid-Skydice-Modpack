--========================================================
-- Gore's SVU4 Core - MP Inventory Mirror / UI Refresh
--
-- Server remains authoritative for material and fuel consumption.
-- On some B42.19 MP stacks the server-side inventory removal is not
-- reflected in the client inventory UI until reconnect. After the server
-- confirms an action, this mirror removes the same local ghost items so
-- the player's inventory/material totals update immediately.
--========================================================

require "VehicleArmor_Config"
require "VehicleArmor_ConsumeHelpers"
require "GoresSVU4Core/GSVU4_Upgrades_Config"

GSVU4 = GSVU4 or {}
GSVU4.MPInventoryMirror = GSVU4.MPInventoryMirror or {}

local Mirror = GSVU4.MPInventoryMirror
Mirror.Seen = Mirror.Seen or {}

local function isMPClient()
    return isClient and isClient()
end

local function localPlayer()
    if not getPlayer then return nil end
    local ok, player = pcall(getPlayer)
    if ok then return player end
    return nil
end

local function getKey(args)
    if not args then return nil end
    return table.concat({
        tostring(args.action or "Upgrade"),
        tostring(args.upgradeId or ""),
        tostring(args.partId or ""),
        tostring(args.grade or ""),
        tostring(args.vehicleOnlineId or args.vehicleId or ""),
    }, "|")
end

local function markInventoryDirty()
    GSVU4Core = GSVU4Core or {}
    GSVU4Core.UIState = GSVU4Core.UIState or {}
    GSVU4Core.UIState.InventoryDirty = true
    GSVU4Core.UIState.InventoryDirtyStamp = (GSVU4Core.UIState.InventoryDirtyStamp or 0) + 1

    if ISInventoryPage and ISInventoryPage.dirtyUI then
        pcall(function() ISInventoryPage.dirtyUI() end)
    end

    local player = localPlayer()
    local inv = player and player.getInventory and player:getInventory() or nil
    if inv and inv.setDrawDirty then pcall(function() inv:setDrawDirty(true) end) end
end

local function stripJerry(recipe)
    local out = {}
    for k, v in pairs(recipe or {}) do
        if k ~= "jerrycans" then out[k] = v end
    end
    return out
end

local function removeLocalEmptyJerryCans(player, needed)
    needed = math.floor(tonumber(needed) or 0)
    if needed <= 0 or not player or not player.getInventory then return end
    local inv = player:getInventory()
    if not inv or not inv.getItems then return end
    local items = inv:getItems()
    local remove = {}
    for i = 0, (items and items:size() or 0) - 1 do
        if #remove >= needed then break end
        local item = items:get(i)
        if item and item.getFullType then
            local ok, ft = pcall(function() return item:getFullType() end)
            local low = ok and ft and tostring(ft):lower() or ""
            if string.find(low, "petrolcan", 1, true) or string.find(low, "jerrycan", 1, true) then
                remove[#remove + 1] = item
            end
        end
    end
    for _, item in ipairs(remove) do
        local container = item.getContainer and item:getContainer() or inv
        if container and container.Remove then pcall(function() container:Remove(item) end) end
    end
end

local function consumeRecipeAndFuel(player, recipe, fuelUse, grade)
    if not player or not VehicleArmorHelpers then return end
    if VehicleArmorHelpers.consumeTorchFuelFromCharacter then
        pcall(function() VehicleArmorHelpers.consumeTorchFuelFromCharacter(player, tonumber(fuelUse) or 0) end)
    end
    if VehicleArmorHelpers.consumeRecipeForCharacter and recipe then
        pcall(function() VehicleArmorHelpers.consumeRecipeForCharacter(player, recipe) end)
    end
    markInventoryDirty()
end

function Mirror.consumeForArmorAction(args)
    if not isMPClient() or not args then return end
    local action = tostring(args.action or "")
    if action ~= "InstallArmor" and action ~= "RepairArmor" then return end
    local key = getKey(args)
    if key and Mirror.Seen[key] then return end
    if key then Mirror.Seen[key] = true end

    local player = localPlayer()
    local partId = args.partId
    local grade = args.grade or "Scrap"
    local recipe, fuelUse = nil, 0

    if action == "InstallArmor" then
        recipe = VehicleArmorConfig and VehicleArmorConfig.getInstallRecipe and VehicleArmorConfig.getInstallRecipe(partId, grade) or nil
        fuelUse = VehicleArmorConfig and VehicleArmorConfig.getInstallFuelUse and VehicleArmorConfig.getInstallFuelUse(partId, grade) or (VehicleArmorConfig and VehicleArmorConfig.FuelUse and VehicleArmorConfig.FuelUse.Install and VehicleArmorConfig.FuelUse.Install[grade]) or 0
    elseif action == "RepairArmor" then
        recipe = VehicleArmorConfig and VehicleArmorConfig.getRepairRecipe and VehicleArmorConfig.getRepairRecipe(partId, grade) or nil
        fuelUse = VehicleArmorConfig and VehicleArmorConfig.getRepairFuelUse and VehicleArmorConfig.getRepairFuelUse(partId, grade) or (VehicleArmorConfig and VehicleArmorConfig.FuelUse and VehicleArmorConfig.FuelUse.Repair and VehicleArmorConfig.FuelUse.Repair[grade]) or 0
    end

    consumeRecipeAndFuel(player, recipe, fuelUse, grade)
end

function Mirror.consumeForUpgradeAction(args)
    if not isMPClient() or not args then return end
    if tostring(args.grade or "") == "Removed" then return end
    local key = getKey(args)
    if key and Mirror.Seen[key] then return end
    if key then Mirror.Seen[key] = true end

    local player = localPlayer()
    local cfg = GSVU4UpgradesConfig and GSVU4UpgradesConfig.getGradeConfig and GSVU4UpgradesConfig.getGradeConfig(args.upgradeId, args.grade) or nil
    if not cfg then return end
    consumeRecipeAndFuel(player, stripJerry(cfg.recipe), cfg.fuelUse or 0, args.grade)
    removeLocalEmptyJerryCans(player, (cfg.recipe or {}).jerrycans)
    markInventoryDirty()
end
