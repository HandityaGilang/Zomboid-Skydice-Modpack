--[[
    CookingSync - Client-side component (v7.2)

    Handles UI refresh and sync requests for cooking appliances.

    v7.2: Simplified client - just mark containers dirty and refresh UI.
          Server handles the actual sync via sendItemStats().
    v6.0: Server now uses sendItemStats() for proper world container sync.
    v5.0: Fixed multiplayer cooking bug - ingredients now properly sync
          when added to pots/pans via evolved recipes.
    v4.0: Optimized scanning, reduced overhead
]]

if isServer() then return end

CookingSyncClient = CookingSyncClient or {}

CookingSyncClient.syncIntervalTicks = 90  -- ~3 sec between UI refreshes
CookingSyncClient.uiRefreshCooldown = 500 -- ms between UI refreshes
CookingSyncClient.scanRadius = 6          -- Only need nearby (interaction range)
CookingSyncClient.postActionSyncDelay = 10 -- Ticks to wait after action before sync

local tickCounter = 0
local lastUIRefresh = 0
local initialized = false
local pendingSyncs = {}  -- Track containers needing delayed sync

---------------------------------------------------------------------------
-- SHARED UTILITIES
---------------------------------------------------------------------------

local isCookingAppliance = CookingSyncShared.isCookingAppliance
local isApplianceActive = CookingSyncShared.isApplianceActive

local function refreshUI()
    local now = getTimestampMs()
    if not now then return end

    if (now - lastUIRefresh) < CookingSyncClient.uiRefreshCooldown then
        return
    end
    lastUIRefresh = now

    pcall(function()
        if ISInventoryPage and ISInventoryPage.dirtyUI then
            ISInventoryPage.dirtyUI()
        end
    end)
end

---------------------------------------------------------------------------
-- CONTAINER DIRTY MARKING (no aggressive sync requests)
---------------------------------------------------------------------------

local function markContainerDirty(container)
    if not container then return end

    pcall(function()
        if container.setDirty then
            container:setDirty(true)
        end
    end)
end

local function queueContainerSync(container, delayTicks)
    if not container then return end
    table.insert(pendingSyncs, {
        container = container,
        ticksRemaining = delayTicks or CookingSyncClient.postActionSyncDelay
    })
end

local function processPendingSyncs()
    local i = 1
    while i <= #pendingSyncs do
        local entry = pendingSyncs[i]
        entry.ticksRemaining = entry.ticksRemaining - 1

        if entry.ticksRemaining <= 0 then
            markContainerDirty(entry.container)
            refreshUI()
            table.remove(pendingSyncs, i)
        else
            i = i + 1
        end
    end
end

local function scanAndRefreshNearby()
    pcall(function()
        local player = getPlayer()
        if not player then return end

        local cell = player:getCell()
        if not cell then return end

        local px = math.floor(player:getX())
        local py = math.floor(player:getY())
        local pz = math.floor(player:getZ())
        local radius = CookingSyncClient.scanRadius

        local foundActive = false

        -- Only scan player's Z level (can't interact with other floors anyway)
        for dx = -radius, radius do
            for dy = -radius, radius do
                local sq = cell:getGridSquare(px + dx, py + dy, pz)
                if sq then
                    local objects = sq:getObjects()
                    if objects then
                        local count = objects:size()
                        for i = 0, count - 1 do
                            local obj = objects:get(i)
                            if obj and isCookingAppliance(obj) and isApplianceActive(obj) then
                                local container = obj:getContainer()
                                if container then
                                    markContainerDirty(container)
                                    foundActive = true
                                end
                            end
                        end
                    end
                end
            end
        end

        if foundActive then
            refreshUI()
        end
    end)
end

local function onTick()
    tickCounter = tickCounter + 1

    -- Process any pending container syncs (from evolved recipe actions)
    if #pendingSyncs > 0 then
        processPendingSyncs()
    end

    if tickCounter >= CookingSyncClient.syncIntervalTicks then
        tickCounter = 0
        scanAndRefreshNearby()
    end
end

local function onContainerUpdate(container)
    if not container then return end
    if type(container) ~= "userdata" then return end

    pcall(function()
        if not container.getParent then return end
        local parent = container:getParent()
        if parent and isCookingAppliance(parent) then
            refreshUI()
        end
    end)
end

---------------------------------------------------------------------------
-- HOOK: ISAddItemInRecipe (Evolved Recipe Ingredient Adding)
-- This fixes the multiplayer bug where ingredients are taken from
-- containers but not visually added to the cooking pot.
---------------------------------------------------------------------------

local function hookISAddItemInRecipe()
    -- Only hook if ISAddItemInRecipe exists (it's in shared/TimedActions)
    if not ISAddItemInRecipe then return end

    -- Store original complete function
    local originalComplete = ISAddItemInRecipe.complete

    ISAddItemInRecipe.complete = function(self)
        -- Call original function first
        local result = originalComplete(self)

        -- After ingredient is added, mark container dirty and notify server
        pcall(function()
            if not self.baseItem then return end

            local container = self.baseItem:getContainer()
            if not container then return end

            -- Check if this container belongs to a cooking appliance
            local parent = container:getParent()
            if parent and isCookingAppliance(parent) then
                -- Mark dirty and queue refresh
                markContainerDirty(container)
                queueContainerSync(container, 15)
                queueContainerSync(container, 45)

                -- Refresh UI
                refreshUI()

                -- Send sync request to server for other clients
                if isClient() then
                    local x, y, z
                    if parent.getX then x = parent:getX() end
                    if parent.getY then y = parent:getY() end
                    if parent.getZ then z = parent:getZ() end

                    if x and y and z then
                        sendClientCommand("CookingSync", "syncContainer", {
                            x = x, y = y, z = z
                        })
                    end
                end
            end
        end)

        return result
    end
end

---------------------------------------------------------------------------
-- HOOK: ISInventoryTransferAction (Item Transfer Completion)
-- Sync containers when items are transferred to/from cooking appliances
---------------------------------------------------------------------------

local function hookISInventoryTransferAction()
    if not ISInventoryTransferAction then return end

    local originalPerform = ISInventoryTransferAction.perform

    ISInventoryTransferAction.perform = function(self)
        -- Call original first
        originalPerform(self)

        -- Check if source or dest is a cooking appliance container
        pcall(function()
            local containers = {self.srcContainer, self.destContainer}

            for _, container in ipairs(containers) do
                if container then
                    local parent = container:getParent()
                    if parent and isCookingAppliance(parent) then
                        -- Queue sync after transfer completes
                        queueContainerSync(container, 5)
                        queueContainerSync(container, 30)
                    end
                end
            end
        end)
    end
end

---------------------------------------------------------------------------
-- INIT
---------------------------------------------------------------------------

local function init()
    if initialized then return end
    initialized = true

    Events.OnTick.Add(onTick)

    if Events.OnContainerUpdate then
        Events.OnContainerUpdate.Add(onContainerUpdate)
    end

    -- Apply hooks after game starts (ensure classes are loaded)
    hookISAddItemInRecipe()
    hookISInventoryTransferAction()
end

Events.OnGameStart.Add(init)
