-- Prevent Vanilla crash "getBottom on nil" when no container buttons exist.
-- Adds a dummy container (no icon, no border) so ISInventoryPage has at least one button.
-- Hooks:
-- 1) OnRefreshInventoryWindowContainers at stage "buttonsAdded" (inside refreshBackpacks, BEFORE getBottom()).
-- 2) Also at "end" as a safety net (other builds may differ).
-- 3) ISInventoryPage.update as a final guard.

local DUMMY_CAP = 0  -- dummy capacity

local dummyByPlayer = {}

local function getOrCreateDummyContainer(playerIndex)
    if dummyByPlayer[playerIndex] then return dummyByPlayer[playerIndex] end
    local c = ItemContainer.new("dummy", nil, nil)
    c:setExplored(true) -- Vanilla won't try to request/fill
    dummyByPlayer[playerIndex] = c
    return c
end

local function isDummyContainerForPage(page, inv)
    return inv ~= nil and dummyByPlayer[page.player] ~= nil and inv == dummyByPlayer[page.player]
end

local function ensureFallbackButton(page)
    if not page or not page.backpacks or #page.backpacks > 0 then return end

    local playerObj = getSpecificPlayer(page.player)
    local dummyContainer = getOrCreateDummyContainer(page.player)

    -- Try to set capacity on the container (may be ignored by getEffectiveCapacity in some builds)
    if type(dummyContainer.setCapacity) == "function" then
        pcall(function() dummyContainer:setCapacity(DUMMY_CAP) end)
    end

    local title = getTextOrNull("IGUI_NoContainers") or "No Containers"
    local btn = page:addContainerButton(dummyContainer, nil, title, title)

    -- Hide icon and border to keep it "iconless"
    if btn.setTextureRGBA then btn:setTextureRGBA(0, 0, 0, 0) end
    if btn.setBorderRGBA then btn:setBorderRGBA(0, 0, 0, 0) end

    -- Setze die Button-Kapazität explizit (für alle Stellen, die button.capacity nutzen)
    btn.capacity = DUMMY_CAP

    -- Make dummy active; Vanilla update will assign capacity, we'll correct it afterwards
    page.inventoryPane.inventory = btn.inventory
end

-- Insert dummy during refreshBackpacks, before Vanilla accesses :getBottom()
Events.OnRefreshInventoryWindowContainers.Add(function(page, stage)
    if stage == "buttonsAdded" or stage == "end" then
        ensureFallbackButton(page)
    end
end)

-- Final guard: after original update() runs, enforce capacity in UI for the dummy
local function applyPatch()
    if not ISInventoryPage or ISInventoryPage._fallbackPatched then return end
    local original_update = ISInventoryPage.update

    ISInventoryPage.update = function(self, ...)
        -- Ensure there is at least one button
        ensureFallbackButton(self)

        -- Run Vanilla update
        local ret = original_update(self, ...)

        -- If current inventory is our dummy, override the UI capacity value
        if isDummyContainerForPage(self, self.inventoryPane and self.inventoryPane.inventory) then
            self.capacity = DUMMY_CAP
            -- optional: korrigiere auch den letzten Button-Eintrag, falls benötigt
            for i = 1, #self.backpacks do
                local b = self.backpacks[i]
                if b and b.inventory == self.inventoryPane.inventory then
                    b.capacity = DUMMY_CAP
                    break
                end
            end
        end

        return ret
    end

    ISInventoryPage._fallbackPatched = true
end

Events.OnGameStart.Add(applyPatch)
applyPatch()

AMCTickControl = AMCTickControl or {}

-- SAFE HELPERS (replace your existing helper block with this one)

-- Helpers: safe number conversion and safe reflection calls
local function Num(v, d) local n = tonumber(v); return n and n or (d or 0) end

function AMCTickControl.getGeneralCondition(vehicle)
    local front, rear = AMC_Durability.readRaw(vehicle)
    return (front or 0) + (rear or 0)
end

function AMCTickControl.setLocalVariables(playerObj, vehicle, vehicleInfo)
    playerObj:setHideWeaponModel(true)
    local seatId = vehicle:getSeat(playerObj)
    if playerObj:getVariableString("ATVehicleType") ~= vehicleInfo.type .. seatId then
        playerObj:setVariable("ATVehicleType", vehicleInfo.type .. seatId);
        if isClient() and playerObj:isLocalPlayer() then
            ModData.getOrCreate("tsaranimations")[playerObj:getOnlineID()] = true
            ModData.transmit("tsaranimations")
        end
    end
    if vehicle:isDriver(playerObj) then
        local playerStatus = nil
        if vehicle:getPartForSeatContainer(0) then
            playerStatus = vehicle:getPartForSeatContainer(0):getModData()["tsaranimation"]
        end
        local passengerStatus = nil
        if vehicle:getPartForSeatContainer(1) then
            passengerStatus = vehicle:getPartForSeatContainer(1):getModData()["tsaranimation"]
        end
        if not passengerStatus then
            passengerStatus = "none"
        end
        playerObj:setVariable("ATPassengerStatus", passengerStatus)
        if playerStatus and playerStatus ~= "enter" and playerStatus ~= "exit" then
            local vehicleSpeedKPH = vehicle:getCurrentSpeedKmHour()
            if vehicleSpeedKPH > tonumber(vehicleInfo.speedDelta) then 
                if playerObj:getVariableString("ATVehicleStatus") ~= "forward" then
                    playerObj:setVariable("ATVehicleStatus", "forward");
                    sendClientCommand(playerObj, 'autotsaranim', 'updateVariables', {vehicle = vehicle:getId(), seatId = seatId, status = "forward",})
                end
            elseif vehicleSpeedKPH < (0 - tonumber(vehicleInfo.speedDelta)) then
                if playerObj:getVariableString("ATVehicleStatus") ~= "backward" then
                    playerObj:setVariable("ATVehicleStatus", "backward");
                    sendClientCommand(playerObj, 'autotsaranim', 'updateVariables', {vehicle = vehicle:getId(), seatId = seatId, status = "backward",})
                end
            else
                if playerObj:getVariableString("ATVehicleStatus") ~= "stop" then
                    playerObj:setVariable("ATVehicleStatus", "stop");
                    sendClientCommand(playerObj, 'autotsaranim', 'updateVariables', {vehicle = vehicle:getId(), seatId = seatId, status = "stop",})
                end
            end
        end
    else
        local passengerStatus = nil
        if vehicle:getPartForSeatContainer(0) then
            passengerStatus = vehicle:getPartForSeatContainer(0):getModData()["tsaranimation"]
        end
        if not passengerStatus then
            passengerStatus = "none"
        end
        playerObj:setVariable("ATPassengerStatus", passengerStatus);
        
        if isClient() and passengerStatus == "crash" then
            sendClientCommand(playerObj, 'autotsaranim', 'updateVariables', {vehicle = vehicle:getId(), seatId = 0, status = "none",})
            sendClientCommand(playerObj, 'autotsaranim', 'updateVariables', {vehicle = vehicle:getId(), seatId = seatId, status = "none",})
            vehicle:exit(playerObj)
            triggerEvent("OnExitVehicle", playerObj)
            playerObj:setKnockedDown(true)
            return
        end
        if vehicle:getDriver() then
            if passengerStatus and passengerStatus ~= "exit" and passengerStatus ~= "enter" then
                playerObj:setVariable("ATVehicleStatus", passengerStatus);
            else
                playerObj:setVariable("ATVehicleStatus", "stop");
            end
        else
            if passengerStatus == "none" then
                if playerObj:getVariableString("ATVehicleStatus") ~= "stop" then
                    playerObj:setVariable("ATVehicleStatus", "stop");
                    sendClientCommand(playerObj, 'autotsaranim', 'updateVariables', {vehicle = vehicle:getId(), seatId = seatId, status = "stop",})
                end
            end
        end
    end
end


function AMCTickControl.setAvatarVariables(playerObj, vehicle, vehicleInfo)
-- print("setAvatarVariables")
    local seatId = vehicle:getSeat(playerObj)
    if playerObj:getVariableString("ATVehicleType") ~= vehicleInfo.type .. seatId then
        playerObj:setVariable("ATVehicleType", vehicleInfo.type .. seatId);
    end
    
    local vehicleSpeedKPH = vehicle:getCurrentSpeedKmHour()
    if vehicle:isDriver(playerObj) then
        if vehicle:getPartForSeatContainer(1) then
            playerObj:setVariable("ATPassengerStatus", vehicle:getPartForSeatContainer(1):getModData()["tsaranimation"]); -- passengerStatus
        else
            playerObj:setVariable("ATPassengerStatus", "none")
        end
        local driverStatus = nil
        if vehicle:getPartForSeatContainer(vehicle:getSeat(playerObj)) then
            driverStatus = vehicle:getPartForSeatContainer(vehicle:getSeat(playerObj)):getModData()["tsaranimation"]
        end
        if driverStatus == "exit" then
            playerObj:SetVariable("bExitingVehicle", "true")
        elseif driverStatus == "enter" then
            playerObj:SetVariable("bEnteringVehicle", "true")
        else
            if playerObj:GetVariable("ExitAnimationFinished") == "true" or 
                    playerObj:GetVariable("EnterAnimationFinished") == "true" then 
                playerObj:ClearVariable("ExitAnimationFinished")
                playerObj:ClearVariable("bExitingVehicle")
                playerObj:ClearVariable("EnterAnimationFinished")
                playerObj:ClearVariable("bEnteringVehicle")
            end
            playerObj:setVariable("ATVehicleStatus", driverStatus);
        end
    else
        if vehicle:getPartForSeatContainer(0) then
            playerObj:setVariable("ATPassengerStatus", vehicle:getPartForSeatContainer(0):getModData()["tsaranimation"]); -- passengerStatus
        else
            playerObj:setVariable("ATPassengerStatus", "none")
        end
        if vehicle:getDriver() then
            if vehicleSpeedKPH < (0 - tonumber(vehicleInfo.speedDelta)) then
                playerObj:setVariable("ATVehicleStatus", "backward");
            else
                playerObj:setVariable("ATVehicleStatus", "forward");
            end
        else
            -- playerObj:setVariable("ATPassengerStatus", "none");
            playerObj:setVariable("ATVehicleStatus", "stop");
        end
    end
end

function AMCTickControl.fallControl(playerObj, vehicle, fallDelta)
    local mdmototsar = playerObj:getModData()["mototsar"]
    if not mdmototsar then
        playerObj:getModData()["mototsar"] = {}
        mdmototsar = playerObj:getModData()["mototsar"]
    end
    
    if vehicle == nil then -- out of a vehicle, reset memo and quit
        mdmototsar.health = nil
        return
    end

    local generalCondition = AMCTickControl.getGeneralCondition(vehicle)
    
    if not mdmototsar.health then
        mdmototsar.health = generalCondition
    end
    
    if (mdmototsar.health - generalCondition) >= fallDelta then -- Eject player
        -- playerObj:setVariable("isMotoCrash", true);
        sendClientCommand(playerObj, 'autotsaranim', 'updateVariables', {vehicle = vehicle:getId(), seatId = vehicle:getSeat(playerObj), status = "crash",})
        mdmototsar.health = nil
        vehicle:exit(playerObj)
        triggerEvent("OnExitVehicle", playerObj)
        playerObj:setKnockedDown(true)
        return
    end
    mdmototsar = generalCondition -- update memo
end

local tickControl = 3 -- Reduces the number of script executions. Higher number = fewer executions
local tickStart = 0

function AMCTickControl.main()
    tickStart = tickStart + 1
    if tickStart % tickControl == 0 then
        tickStart = 0
        if isClient() then
            local playerLocal = getPlayer()
            local plLocX = playerLocal:getX()
            local plLocY = playerLocal:getY()
            local playersWithAnim = ModData.getOrCreate("tsaranimations")
            local vehicle = playerLocal:getVehicle()
            local amcConfig = vehicle and vehicle:getPartById("AMCConfig")
            if amcConfig then
                local vehicleInfo = amcConfig:getTable("AMCConfig")
                if vehicleInfo then
                    if vehicle:isDriver(playerLocal) and vehicleInfo.fallDelta then
                        AMCTickControl.fallControl(playerLocal, vehicle, tonumber(vehicleInfo.fallDelta))
                    end
                    AMCTickControl.setLocalVariables(playerLocal, vehicle, vehicleInfo)
                end
            else
                AMCTickControl.fallControl(playerLocal, nil, nil) -- reset when out of a vehicle
            end
            -- print(playersWithAnim)
            for playerId, _ in pairs(playersWithAnim) do -- other players
                player = getPlayerByOnlineID(playerId)
                if player and not player:isLocalPlayer() and not player:isDead() then
                    local vehicle = player:getVehicle()
                    local amcConfig = vehicle and vehicle:getPartById("AMCConfig")
                    if amcConfig then
                        local vehicleInfo = amcConfig:getTable("AMCConfig")
                        if vehicleInfo then
                            local x = player:getX()
                            local y = player:getY()
                            if ((plLocX >= x - 60 and plLocX <= x + 60 and
                                    plLocY >= y - 60 and plLocY <= y + 60)) then
                                AMCTickControl.setAvatarVariables(player, vehicle, vehicleInfo)
                            end
                        end
                    end
                    
                end
            end
        else
            local playersSum = getNumActivePlayers()
            for playerNum = 0, playersSum - 1 do
                -- print(playerNum)
                local playerObj = getSpecificPlayer(playerNum)
                if playerObj then
                    local vehicle = playerObj:getVehicle()
                    local amcConfig = vehicle and vehicle:getPartById("AMCConfig")
                    if amcConfig then
                        local vehicleInfo = amcConfig:getTable("AMCConfig")
                        if vehicleInfo then
                            if vehicleInfo.fallDelta then
                                AMCTickControl.fallControl(playerObj, vehicle, tonumber(vehicleInfo.fallDelta))
                            end
                            AMCTickControl.setLocalVariables(playerObj, vehicle, vehicleInfo)
                        end
                    else
                        AMCTickControl.fallControl(playerObj, nil, nil)--reset when out of a vehicle
                    end
                end
            end
        end
    end
end

local function onCreatePlayer(id)
    local playerObj = getSpecificPlayer(id)
    playerObj:getModData()["mototsar"] = {}
    playerObj:getModData()["mototsar"].health = nil
    if playerObj:getVehicle() then
        local motoInfo = playerObj:getVehicle():getPartById("AMCConfig"):getTable("AMCConfig")
        if motoInfo and (motoInfo.hideWeapon == "1") then
            playerObj:setHideWeaponModel(true)
            return
        end
    end
    playerObj:setHideWeaponModel(false)
end

-- Patch Durability
AMC_Durability = AMC_Durability or {}


-- Raw values directly from the Vehicle (APP preferred, otherwise Reflection)
function AMC_Durability.readRaw(vehicle)
    if not vehicle then return nil, nil end
    local vehicleInfo = getVehicleInfo(vehicle)
    local front = Num(vehicleInfo.currentFrontEndDurability, 0)
    local rear = Num(vehicleInfo.currentRearEndDurability, 0)
    return front, rear
end

-- Updates ModData when values change; returns (changed, f, r)
function AMC_Durability.updateModData(vehicle)
    local f, r = AMC_Durability.readRaw(vehicle)
    if f == nil or r == nil then return false end
    local md = vehicle:getModData()
    local changed = (md.currentFrontEndDurability ~= f) or (md.currentRearEndDurability ~= r)
    if changed then
        md.currentFrontEndDurability = f
        md.currentRearEndDurability = r
    end
    return changed, f, r
end

-- Patch Durability tick

local CONFIG = {
    -- Optional: only track specific vehicle (nil = all)
    scriptFullNameFilter = nil, -- e.g. "Base.SuperBulldozer"
    sendServerEvent      = false, -- set to true if server should be informed
}

local function matchesFilter(vehicle)
    if not CONFIG.scriptFullNameFilter then return true end
    local s = vehicle:getScript()
    local full = s and s:getFullName() or ""
    return full == CONFIG.scriptFullNameFilter
end

local function onPlayerUpdate(playerObj)
    if not playerObj or not playerObj:isLocalPlayer() then return end
    local v = playerObj:getVehicle()
    if not v then return end
    if v.getDriver and v:getDriver() ~= playerObj then return end
    if not matchesFilter(v) then return end

    local changed, f, r = AMC_Durability.updateModData(v)
    if changed and CONFIG.sendServerEvent then
        sendServerCommand(playerObj, "AMC", "DurabilityChanged", {
            vehicleId = v:getId(),
            front = f, rear = r
        })
    end
end

Events.OnPlayerUpdate.Add(onPlayerUpdate)
-- Events.OnTileRemoved.Add(AMCTickControl.checkWaterBuild)
Events.OnCreatePlayer.Add(onCreatePlayer)
Events.OnTick.Add(AMCTickControl.main)
-- Events.OnPlayerDeath.Add(onPlayerDeathStopSwimSound)
