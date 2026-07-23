--[[
    CookingSync - Server-side component (v7.2)

    Fixes Build 42 multiplayer cooking sync bug where food items
    don't update visually in ovens/stoves/campfires.

    v7.2: Reverted aggressive sync - was interrupting active cooking UI.
          Back to simple item stat syncing only.
    v6.0: Fixed sync mechanism - use sendItemStats() instead of
          syncItemFields() which only works for player inventory.
    v5.0: Added client command handling for immediate sync requests
    v4.0: Added campfire support via SCampfireSystem
]]

if not isServer() then return end

CookingSync = CookingSync or {}

---------------------------------------------------------------------------
-- CONFIGURATION
---------------------------------------------------------------------------

CookingSync.syncIntervalTicks = 60   -- ~2 seconds at 30 ticks/sec
CookingSync.scanRadius = 12          -- Reduced from 25 (appliances are close)
CookingSync.maxZLevel = 3            -- Reduced from 8 (most bases are 0-2)

---------------------------------------------------------------------------
-- STATE
---------------------------------------------------------------------------

local tickCounter = 0
local serverReady = false

---------------------------------------------------------------------------
-- COOKING SYNC (uses shared utilities)
---------------------------------------------------------------------------

local isCookingAppliance = CookingSyncShared.isCookingAppliance
local isApplianceActive = CookingSyncShared.isApplianceActive

--[[
    Sync cooking appliance items to all clients.
    Uses sendItemStats() to update item properties (cooked%, temperature, etc.)
    without disrupting the cooking UI or appliance state.
]]
local function syncCookingAppliance(obj)
    if not obj then return false end
    if not obj.getContainer then return false end

    local container = obj:getContainer()
    if not container then return false end

    local ok = pcall(function()
        local items = container:getItems()
        if not items then return end

        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if item and item.sendItemStats then
                item:sendItemStats()
            end
        end
    end)

    return ok
end

---------------------------------------------------------------------------
-- CAMPFIRE SYNC (uses SCampfireSystem global object system)
---------------------------------------------------------------------------

local function syncAllCampfires()
    if not SCampfireSystem or not SCampfireSystem.instance then return 0 end

    local ok, count = pcall(function()
        local system = SCampfireSystem.instance
        local campfireCount = system:getLuaObjectCount()
        local synced = 0

        local cell = getCell()

        for i = 1, campfireCount do
            local campfire = system:getLuaObjectByIndex(i)
            if campfire and campfire.isLit then
                local isoObj = nil

                -- Try direct access first
                if campfire.isoObject then
                    isoObj = campfire.isoObject
                elseif campfire.getIsoObject then
                    local okObj, obj = pcall(function() return campfire:getIsoObject() end)
                    if okObj then isoObj = obj end
                end

				-- Fallback: find the object on the square
				if not isoObj then
					local sq = nil
					if campfire.getSquare then
						local okSq, s = pcall(function() return campfire:getSquare() end)
						if okSq then sq = s end
					end

					if not sq and cell then
						local x = campfire.x
						local y = campfire.y
						local z = campfire.z

						if (not x) and campfire.getX then
							local okX, v = pcall(function() return campfire:getX() end)
							if okX then x = v end
						end
						if (not y) and campfire.getY then
							local okY, v = pcall(function() return campfire:getY() end)
							if okY then y = v end
						end
						if (not z) and campfire.getZ then
							local okZ, v = pcall(function() return campfire:getZ() end)
							if okZ then z = v end
						end

						if x and y and z then
							local okSq, s = pcall(function()
								return cell:getGridSquare(x, y, z)
							end)
							if okSq then sq = s end
						end
					end

					if sq then
						local objects = sq:getObjects()
						if objects then
							for oIdx = 0, objects:size() - 1 do
								local obj = objects:get(oIdx)
								if obj and isCookingAppliance(obj) then
									isoObj = obj
									break
								end
							end
						end
					end
				end

                if isoObj and syncCookingAppliance(isoObj) then
                    synced = synced + 1
                end
            end
        end

        return synced
    end)

    return ok and count or 0
end

---------------------------------------------------------------------------
-- APPLIANCE SCAN (optimized: smaller radius, player Z only +/-1)
---------------------------------------------------------------------------

local function scanNearbyAppliances()
    if not serverReady then return 0 end

    local ok, count = pcall(function()
        local players = getOnlinePlayers()
        if not players then return 0 end

        local playerCount = players:size()
        if playerCount == 0 then return 0 end

        local checkedPositions = {}
        local totalSynced = 0
        local radius = CookingSync.scanRadius

        for pIdx = 0, playerCount - 1 do
            local player = players:get(pIdx)
            if player then
                local cell = player:getCell()
                if cell then
                    local px = math.floor(player:getX())
                    local py = math.floor(player:getY())
                    local pz = math.floor(player:getZ())

                    -- Only scan Z levels near player (pz-1 to pz+maxZLevel)
                    local minZ = math.max(0, pz - 1)
                    local maxZ = math.min(7, pz + CookingSync.maxZLevel)

                    for z = minZ, maxZ do
                        for dx = -radius, radius do
                            for dy = -radius, radius do
                                local checkX = px + dx
                                local checkY = py + dy
                                local posKey = checkX .. "_" .. checkY .. "_" .. z

                                if not checkedPositions[posKey] then
                                    checkedPositions[posKey] = true

                                    local sq = cell:getGridSquare(checkX, checkY, z)
                                    if sq then
                                        local objects = sq:getObjects()
                                        if objects then
                                            local objCount = objects:size()
                                            for oIdx = 0, objCount - 1 do
                                                local obj = objects:get(oIdx)
                                                if obj and isCookingAppliance(obj) and isApplianceActive(obj) then
                                                    if syncCookingAppliance(obj) then
                                                        totalSynced = totalSynced + 1
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        return totalSynced
    end)

    return ok and count or 0
end

---------------------------------------------------------------------------
-- TICK HANDLER
---------------------------------------------------------------------------

local function onServerTick()
    if not serverReady then
        serverReady = true
    end

    tickCounter = tickCounter + 1

    if tickCounter >= CookingSync.syncIntervalTicks then
        tickCounter = 0
        -- Sync campfires via global system (very efficient)
        syncAllCampfires()
        -- Sync stoves/ovens/BBQs near players
        scanNearbyAppliances()
    end
end

---------------------------------------------------------------------------
-- CLIENT COMMAND HANDLER
-- Handles sync requests from clients when ingredients are added
---------------------------------------------------------------------------

local function syncContainerAtPosition(x, y, z)
    if not x or not y or not z then return end

    local ok = pcall(function()
        local cell = getCell()
        if not cell then return end

        local sq = cell:getGridSquare(x, y, z)
        if not sq then return end

        local objects = sq:getObjects()
        if not objects then return end

        for i = 0, objects:size() - 1 do
            local obj = objects:get(i)
            if obj and isCookingAppliance(obj) then
                syncCookingAppliance(obj)
            end
        end
    end)
end

local function onClientCommand(module, command, player, args)
    if module ~= "CookingSync" then return end

    if command == "syncContainer" then
        if args and args.x and args.y and args.z then
            syncContainerAtPosition(args.x, args.y, args.z)
        end
    end
end

---------------------------------------------------------------------------
-- INIT
---------------------------------------------------------------------------

local function init()
    Events.OnTick.Add(onServerTick)
    Events.OnClientCommand.Add(onClientCommand)
end

init()
