require "ISUI/ISUIHandler"

-- CleanUI workaround for a vanilla B42.19 issue where the loot panel can remain hidden
-- after opening the ESC menu and returning to the game while the player inventory stays visible.
-- The fix stores direct inventory/loot panel visibility state before all UI is hidden and
-- restores those exact panel references after vanilla UI visibility restoration runs.
CleanUI_EscapeLootVisibilityFix = CleanUI_EscapeLootVisibilityFix or {}
CleanUI_EscapeLootVisibilityFix.snapshots = CleanUI_EscapeLootVisibilityFix.snapshots or {}

local function CleanUI_getMaxPlayerSlots()
    -- Project Zomboid normally supports up to four local players; keep this defensive for API changes.
    if type(getMaxActivePlayers) == "function" then
        local ok, maxPlayers = pcall(getMaxActivePlayers)
        if ok and type(maxPlayers) == "number" and maxPlayers > 0 then
            return maxPlayers
        end
    end
    return 4
end

local function CleanUI_captureInventoryLootVisibility()
    local snapshots = {}
    for playerNum = 0, CleanUI_getMaxPlayerSlots() - 1 do
        local inv = getPlayerInventory and getPlayerInventory(playerNum) or nil
        local loot = getPlayerLoot and getPlayerLoot(playerNum) or nil
        if inv or loot then
            snapshots[playerNum] = {
                inventory = inv,
                loot = loot,
                inventoryVisible = inv and inv:getIsVisible() or false,
                lootVisible = loot and loot:getIsVisible() or false,
            }
        end
    end
    CleanUI_EscapeLootVisibilityFix.snapshots = snapshots
end

local function CleanUI_restoreInventoryLootVisibility()
    local snapshots = CleanUI_EscapeLootVisibilityFix.snapshots
    if not snapshots then return end

    for _, snapshot in pairs(snapshots) do
        local inv = snapshot.inventory
        local loot = snapshot.loot

        if inv then
            inv:setVisible(snapshot.inventoryVisible == true)
        end
        if loot then
            loot:setVisible(snapshot.lootVisible == true)
        end

        -- Keep the expected inventory/loot ordering when both panels were visible before ESC.
        if inv and loot and snapshot.inventoryVisible and snapshot.lootVisible then
            inv:bringToTop()
            loot:bringToTop()
        end
    end

    CleanUI_EscapeLootVisibilityFix.snapshots = {}
end

if ISUIHandler and not ISUIHandler.CleanUI_setVisibleAllUI_escapeLootFix then
    ISUIHandler.CleanUI_setVisibleAllUI_escapeLootFix = ISUIHandler.setVisibleAllUI

    ISUIHandler.setVisibleAllUI = function(visible)
        if not visible then
            CleanUI_captureInventoryLootVisibility()
        end

        ISUIHandler.CleanUI_setVisibleAllUI_escapeLootFix(visible)

        if visible then
            CleanUI_restoreInventoryLootVisibility()
        end
    end
end
