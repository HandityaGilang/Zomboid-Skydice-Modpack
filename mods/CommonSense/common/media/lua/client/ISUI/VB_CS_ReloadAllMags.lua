-- ************************************************************************
-- **                  ██  ██    ██ ██ ████████  █████                   **
-- **                ████  ██    ██ ██    ██   ██   ██                   **
-- **              ██  ██  ██    ██ ██    ██   ███████                   **
-- **                  ██   ██  ██  ██    ██   ██   ██                   **
-- **                  ██    ████   ██    ██   ██   ██                   **
-- **                https://steamcommunity.com/id/1vita                 **
-- ************************************************************************
-- **        The following content was crafted from the ground up,       **
-- **       writing my own lines, but also taking inspiration from       **
-- **       others' work to better understand the game's workflow.       **
-- **                So, as it should be with every mod,                 **
-- **                   >>> USE IT AS YOU PLEASE <<<                     **
-- ************************************************************************
-- **            Let's make Project Zomboid greater togheter!            **
-- ************************************************************************

local compatify = false
local compatifyIDs = {"ReloadAllMagazines"}

---@param objs InventoryItem[] | ContextMenuItemStack[]
---@return InventoryItem[]
local function getReloadableMagazines(objs)
    local magazines = {}
    for _, obj in ipairs(objs) do
        if instanceof(obj, "InventoryItem") then --[[@cast obj InventoryItem]]

            -- An array of inventory items is always >1 in length
            if #objs < 2 then return {} end
            local isMagazine = not obj:IsWeapon() and obj.getMaxAmmo
            if isMagazine and obj:getCurrentAmmoCount() < obj:getMaxAmmo() then
                table.insert(magazines, obj)
            end
        else --[[@cast obj ContextMenuItemStack]]
            -- Item stacks add a duplicate of the first item in the items array
            if obj.count > 2 then
                for i=2, #obj.items do
                    local mag = obj.items[i]
                    local isMagazine = not mag:IsWeapon() and mag.getMaxAmmo
                    if isMagazine and mag:getCurrentAmmoCount() < mag:getMaxAmmo() then
                        table.insert(magazines, obj.items[i])
                    end
                end
            end
        end
    end
    return magazines
end

---@param inventory ItemContainer
---@param magazines InventoryItem[]
---@return table<string, integer> map
local function getAvailableAmmoCounts(inventory, magazines)
    local map = {} --[[@as table<string, integer>]]
    for _, mag in ipairs(magazines) do
        local ammoType = mag:getAmmoType():getItemKey()
        if not map[ammoType] then
            local ammoCount = inventory:getItemsFromFullType(ammoType):size()
            if ammoCount > 0 then
                map[ammoType] = ammoCount
            end
        end
    end
    return map
end

---@param playerObj IsoPlayer
---@param magazines InventoryItem[]
---@param inventoryAmmoCountMap table<string, integer>
local function reloadAllMagazines(playerObj, magazines, inventoryAmmoCountMap)
    for _, mag in ipairs(magazines) do
        local ammoType = mag:getAmmoType():getItemKey()
        local availableAmmoCount = inventoryAmmoCountMap[ammoType]
        if availableAmmoCount > 0 then
            local neededAmmoCount = mag:getMaxAmmo() - mag:getCurrentAmmoCount()
            local reloadCount = math.min(availableAmmoCount, neededAmmoCount)
            inventoryAmmoCountMap[ammoType] = availableAmmoCount - neededAmmoCount
            ISTimedActionQueue.add(ISLoadBulletsInMagazine:new(playerObj, mag, reloadCount))
        end
    end
end

---@param playerNum integer
---@param context ISContextMenu
---@param objs InventoryItem[] | ContextMenuItemStack[]
local function addReloadAllMagazinesOption(playerNum, context, objs)

    if not SandboxVars.CommonSense.ReloadAllMags or compatify then return end
    local magazines = getReloadableMagazines(objs)
    if #magazines == 0 then return end
    local playerObj = getSpecificPlayer(playerNum)
    if not playerObj then return end
    local inventoryAmmoCountMap = getAvailableAmmoCounts(playerObj:getInventory(), magazines)
    if table.isempty(inventoryAmmoCountMap) then return end
    local _ = context:insertOptionAfter(
        getText("ContextMenu_Drop"), 
        getText("ContextMenu_CS_ReloadAllMags"), 
        playerObj,
        reloadAllMagazines,
        magazines,
        inventoryAmmoCountMap
    ) or context:addOption( 
        getText("ContextMenu_CS_ReloadAllMags"), 
        playerObj,
        reloadAllMagazines,
        magazines,
        inventoryAmmoCountMap
    )
end

Events.OnInitGlobalModData.Add(function()
    compatify = BB_CS_Utils.needToCompatify(compatifyIDs)
end)
Events.OnFillInventoryObjectContextMenu.Add(addReloadAllMagazinesOption)