--========================================================
-- VEHICLE ARMOR RADIAL MENU  (B42.19)
-- Single file for ALL radial menu hooks.
-- Covers both inside-vehicle and outside-vehicle contexts.
--
-- The old VehicleArmor_UI.lua had a duplicate hook at the
-- bottom; it has been removed from that file.  All menu
-- wiring lives here exclusively.
--========================================================

local function GAA_EnsureISVehicleMenu()
    if ISVehicleMenu then return true end
    if pcall then pcall(require, "ISUI/ISVehicleMenu") end
    return ISVehicleMenu ~= nil
end

require "VehicleArmor_Config"

if not VehicleArmorWindow then
    require "VehicleArmor_UI"
end

local GAA_IsValidArmorVehicle

----------------------------------------------------------
-- Opens, populates, and shows the armor window.
-- Must be called the same way regardless of whether the
-- player is inside or outside the vehicle.
----------------------------------------------------------
local function openArmorUI(playerObj, vehicle)
    if not VehicleArmorWindow then
        return
    end
    if not vehicle then return end
    if GAA_IsValidArmorVehicle and not GAA_IsValidArmorVehicle(vehicle) then return end

    local sw = getCore():getScreenWidth()
    local sh = getCore():getScreenHeight()
    local W, H = 540, 400

    local ui = VehicleArmorWindow:new(
        math.floor((sw - W) / 2),
        math.floor((sh - H) / 2),
        W, H,
        playerObj, vehicle)

    ui:initialise()
    ui:addToUIManager()
    ui:setVisible(true)
    ui:populateParts(vehicle)                       -- fills the part list

    -- Phase 1d: do not force the UI back to Scrap every time it opens.
    -- VehicleArmorWindow:createChildren() resolves the remembered grade
    -- from the player modData / global fallback, so we simply reselect
    -- the current value here to refresh the tab highlight.
    ui:selectGrade(ui.currentGrade or VehicleArmorConfig.Grades[1])
end

----------------------------------------------------------
-- Vehicle lookup
-- playerObj:getNearVehicle() is quite strict and often only
-- works when the "key" icon appears. Vanilla maintenance can
-- be opened from a wider interaction box, so we mirror that
-- behaviour by falling back to vanilla helper functions and
-- then a small square scan around the player.
----------------------------------------------------------
local function GAA_IsVehicleObject(obj)
    if not obj then return false end

    if instanceof then
        local ok, result = pcall(function()
            return instanceof(obj, "BaseVehicle")
        end)

        if ok and result then return true end
    end

    return obj.getScript ~= nil
       and obj.getPartById ~= nil
       and obj.getModData ~= nil
end

local function GAA_SafeVehicleString(vehicle, methodName)
    if not vehicle or not methodName or not vehicle[methodName] then return "" end
    local ok, result = pcall(function()
        return vehicle[methodName](vehicle)
    end)
    if ok and result then return tostring(result) end
    return ""
end

local function GAA_IsWreckedVehicle(vehicle)
    if not vehicle then return true end

    -- Burned-out / wrecked map vehicles can still be BaseVehicle objects,
    -- which made our wider radial scan show the armor button on non-usable wrecks.
    -- Use known script-name patterns plus safe runtime checks where available.
    local names = table.concat({
        GAA_SafeVehicleString(vehicle, "getScriptName"),
        GAA_SafeVehicleString(vehicle, "getName"),
    }, " "):lower()

    local script = nil
    if vehicle.getScript then
        local ok, result = pcall(function() return vehicle:getScript() end)
        if ok then script = result end
    end

    if script then
        if script.getName then
            local ok, result = pcall(function() return script:getName() end)
            if ok and result then names = names .. " " .. tostring(result):lower() end
        end
        if script.getFullName then
            local ok, result = pcall(function() return script:getFullName() end)
            if ok and result then names = names .. " " .. tostring(result):lower() end
        end
    end

    if names:find("wreck")
    or names:find("burnt")
    or names:find("burned")
    or names:find("smashed")
    or names:find("destroyed")
    then
        return true
    end

    local boolMethods = { "isBurnt", "isBurned", "isDestroyed", "isSmashed" }
    for _, methodName in ipairs(boolMethods) do
        if vehicle[methodName] then
            local ok, result = pcall(function()
                return vehicle[methodName](vehicle)
            end)
            if ok and result == true then return true end
        end
    end

    return false
end

local function GAA_HasAllowedArmorPart(vehicle)
    if not vehicle or not vehicle.getScript then return false end

    local script = nil
    local okScript, result = pcall(function() return vehicle:getScript() end)
    if okScript then script = result end
    if not script or not script.getPartCount then return false end

    local found = false
    pcall(function()
        for i = 0, script:getPartCount() - 1 do
            local sp = script:getPart(i)
            if sp then
                local id = (sp.getPartId and sp:getPartId()) or (sp.getId and sp:getId()) or nil
                if id and VehicleArmorConfig and VehicleArmorConfig.isAllowedPart and VehicleArmorConfig.isAllowedPart(id) then
                    found = true
                    return
                end
            end
        end
    end)

    return found
end

function GAA_IsValidArmorVehicle(vehicle)
    if not GAA_IsVehicleObject(vehicle) then return false end
    if GAA_IsWreckedVehicle(vehicle) then return false end
    if not GAA_HasAllowedArmorPart(vehicle) then return false end
    return true
end

local function GAA_GetDistanceSqToPlayer(playerObj, obj)
    if not playerObj or not obj then return 999999 end
    if not playerObj.getX or not playerObj.getY then return 999999 end
    if not obj.getX or not obj.getY then return 999999 end

    local px, py = playerObj:getX(), playerObj:getY()
    local ox, oy = obj:getX(), obj:getY()
    local dx, dy = px - ox, py - oy

    return (dx * dx) + (dy * dy)
end

local function GAA_ConsiderVehicleCandidate(playerObj, candidate, state)
    if not state then state = {} end
    if GAA_IsValidArmorVehicle(candidate) then
        local dist = GAA_GetDistanceSqToPlayer(playerObj, candidate)
        if dist < (state.bestDist or 999999) then
            state.bestDist = dist
            state.bestVehicle = candidate
        end
    end
    return state
end

local function GAA_ConsiderConnectedVehicles(playerObj, candidate, state)
    state = GAA_ConsiderVehicleCandidate(playerObj, candidate, state)

    -- Trailers can be missed by getNearVehicle(), especially when hitched.
    -- Check both sides of the tow relationship when those B42 methods exist.
    local towMethods = { "getVehicleTowing", "getVehicleTowedBy" }
    for _, methodName in ipairs(towMethods) do
        if candidate and candidate[methodName] then
            local ok, linked = pcall(function()
                return candidate[methodName](candidate)
            end)
            if ok and linked and linked ~= candidate then
                state = GAA_ConsiderVehicleCandidate(playerObj, linked, state)
            end
        end
    end

    return state
end

local function GAA_IterateVehicleCollection(collection, callback)
    if not collection or not callback then return end

    if type(collection) == "table" then
        for _, vehicle in pairs(collection) do
            callback(vehicle)
        end
        return
    end

    if collection.size and collection.get then
        local okSize, count = pcall(function() return collection:size() end)
        if okSize and tonumber(count) then
            for i = 0, tonumber(count) - 1 do
                local okGet, vehicle = pcall(function() return collection:get(i) end)
                if okGet then callback(vehicle) end
            end
        end
        return
    end

    if collection.getCount and collection.get then
        local okCount, count = pcall(function() return collection:getCount() end)
        if okCount and tonumber(count) then
            for i = 0, tonumber(count) - 1 do
                local okGet, vehicle = pcall(function() return collection:get(i) end)
                if okGet then callback(vehicle) end
            end
        end
    end
end

local function GAA_FindInteractableVehicle(playerObj)
    if not playerObj then return nil end

    local state = {
        bestVehicle = nil,
        bestDist = 999999,
    }

    if playerObj.getNearVehicle then
        local ok, vehicle = pcall(function()
            return playerObj:getNearVehicle()
        end)

        if ok then
            state = GAA_ConsiderConnectedVehicles(playerObj, vehicle, state)
        end
    end

    if ISVehicleMenu and ISVehicleMenu.getVehicleToInteractWith then
        local ok, vehicle = pcall(function()
            return ISVehicleMenu.getVehicleToInteractWith(playerObj)
        end)

        if ok then
            state = GAA_ConsiderConnectedVehicles(playerObj, vehicle, state)
        end
    end

    if ISVehicleMenu and ISVehicleMenu.getVehicleToInteractWith2 then
        local ok, vehicle = pcall(function()
            return ISVehicleMenu.getVehicleToInteractWith2(playerObj)
        end)

        if ok then
            state = GAA_ConsiderConnectedVehicles(playerObj, vehicle, state)
        end
    end

    local square = playerObj.getSquare and playerObj:getSquare() or nil
    if square and getCell then
        local cell = getCell()
        if cell and cell.getGridSquare then
            local sx, sy, sz = square:getX(), square:getY(), square:getZ()
            local radius = 5

            for x = sx - radius, sx + radius do
                for y = sy - radius, sy + radius do
                    local sq = cell:getGridSquare(x, y, sz)
                    if sq and sq.getMovingObjects then
                        local objects = sq:getMovingObjects()
                        if objects then
                            for i = 0, objects:size() - 1 do
                                local obj = objects:get(i)
                                state = GAA_ConsiderConnectedVehicles(playerObj, obj, state)
                            end
                        end
                    end
                end
            end
        end
    end

    -- One-shot fallback when pressing V only. This is not a periodic scan.
    -- It helps with trailers that are loaded vehicles but not returned by
    -- getNearVehicle() or square moving-objects.
    if not state.bestVehicle and getCell then
        local cell = getCell()
        if cell and cell.getVehicles then
            local ok, vehicles = pcall(function() return cell:getVehicles() end)
            if ok and vehicles then
                local maxDistSq = 64 -- 8 tiles
                GAA_IterateVehicleCollection(vehicles, function(vehicle)
                    if GAA_GetDistanceSqToPlayer(playerObj, vehicle) <= maxDistSq then
                        state = GAA_ConsiderConnectedVehicles(playerObj, vehicle, state)
                    end
                end)
            end
        end
    end

    return state.bestVehicle
end

if not GAA_EnsureISVehicleMenu() then
    return
end

----------------------------------------------------------
-- Hook: player presses V while OUTSIDE (near) a vehicle
----------------------------------------------------------
local orig_outside = ISVehicleMenu.showRadialMenuOutside

function ISVehicleMenu.showRadialMenuOutside(playerObj)
    orig_outside(playerObj)

    local menu = getPlayerRadialMenu(playerObj:getPlayerNum())
    local vehicle = GAA_FindInteractableVehicle(playerObj)

    if menu and vehicle and GAA_IsValidArmorVehicle(vehicle) then
        menu:addSlice(
            "Upgrades",
            getTexture("Item_WeldingMask"),
            openArmorUI,
            playerObj, vehicle)
    end
end

----------------------------------------------------------
-- Hook: player presses V while INSIDE a vehicle
----------------------------------------------------------
local orig_inside = ISVehicleMenu.showRadialMenu

function ISVehicleMenu.showRadialMenu(playerObj)
    orig_inside(playerObj)
    local menu    = getPlayerRadialMenu(playerObj:getPlayerNum())
    local vehicle = playerObj:getVehicle()
    if menu and vehicle and GAA_IsValidArmorVehicle(vehicle) then
        menu:addSlice(
            "Upgrades",
            getTexture("Item_WeldingMask"),
            openArmorUI,
            playerObj, vehicle)
    end
end
