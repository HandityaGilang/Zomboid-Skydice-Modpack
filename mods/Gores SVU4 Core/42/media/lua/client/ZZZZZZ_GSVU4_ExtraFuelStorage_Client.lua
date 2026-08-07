--========================================================
-- Gore's SVU4 Core - Extra Fuel Storage Client
-- 1. Wraps ISAddGasolineToVehicle:perform to route overflow
--    into the auxiliary reserve after the main tank is full.
-- 2. Adds a radial menu slice to manually refuel the reserve.
--========================================================

require "GoresSVU4Core/GSVU4_Upgrades_Config"

-- ── 1. Wrap ISAddGasolineToVehicle:perform ───────────────────────────
-- After the vanilla perform fills the main tank, if:
--   a) the vehicle has ExtraFuelStorage installed
--   b) the reserve isn't full
--   c) the source item still has fuel remaining
-- then route that remaining fuel into the reserve (up to reserve capacity).

-- Wrap ISFluidTransferAction:perform to catch overflow into the aux reserve.
-- B42 uses ISFluidTransferAction for all fluid transfers including vehicle refuelling.
-- When the vehicle GasTank is the target and is now full, route remaining source
-- fuel into the EFS reserve via setContainerContentAmount (which works server-side).
if ISFluidTransferAction then
    local oldFluidTransferPerform = ISFluidTransferAction.perform
    function ISFluidTransferAction:perform()
        -- Run vanilla transfer first
        oldFluidTransferPerform(self)

        -- Only care about transfers targeting a vehicle part
        if not self.targetOwner then return end

        -- Check if targetOwner is a vehicle part (VehiclePart)
        local vehicle = nil
        if self.targetOwner.getVehicle then
            local ok, v = pcall(function() return self.targetOwner:getVehicle() end)
            if ok and v then vehicle = v end
        end
        if not vehicle or not vehicle.getModData then return end

        local vdata = vehicle:getModData()
        local upgrade = vdata.gUpgrades and vdata.gUpgrades.ExtraFuelStorage
        if not upgrade then return end

        local cfg = GSVU4UpgradesConfig.getGradeConfig("ExtraFuelStorage", upgrade.grade)
        local maxReserve = cfg and (tonumber(cfg.fuelBonus) or 0) or 0
        local reserve    = tonumber(vdata.GSVU4_fuelReserve) or 0
        if reserve >= maxReserve - 0.001 then return end

        -- Check: is the source still has fluid remaining after transfer?
        local sourceAmt = 0
        if self.source then
            if self.source.getFluidContainer then
                local ok, fc = pcall(function() return self.source:getFluidContainer() end)
                if ok and fc and fc.getAmount then
                    sourceAmt = tonumber(fc:getAmount()) or 0
                end
            end
        end
        if sourceAmt < 0.001 then return end  -- source empty, nothing to overflow

        -- Check: is the target tank now full?
        local gasPart = vehicle.getPartById and vehicle:getPartById("GasTank")
        if not gasPart then return end
        local current = gasPart.getContainerContentAmount and tonumber(gasPart:getContainerContentAmount()) or 0
        local cap     = gasPart.getContainerCapacity and tonumber(gasPart:getContainerCapacity()) or 0
        if cap <= 0 or current < cap - 0.5 then return end  -- tank not full, no overflow

        -- Tank is full and source still has fuel - route to reserve
        local toReserve = math.min(sourceAmt, maxReserve - reserve)
        if toReserve < 0.001 then return end

        vdata.GSVU4_fuelReserve = math.min(maxReserve, reserve + toReserve)
        vehicle:transmitModData()
        if self.character then
            self.character:Say(string.format(
                "Aux tank: +%.1fL (%.1fL / %dL)",
                toReserve, vdata.GSVU4_fuelReserve, maxReserve))
        end
    end
end  -- if ISFluidTransferAction


-- ── 2. Timed action: manually refuel the reserve with jerry cans ──────

GSVU4RefuelAuxTank = ISBaseTimedAction:derive("GSVU4RefuelAuxTank")

function GSVU4RefuelAuxTank:isValid()
    if not self.character or not self.vehicle then return false end
    local vdata = self.vehicle:getModData()
    local upgrade = vdata.gUpgrades and vdata.gUpgrades.ExtraFuelStorage
    if not upgrade then return false end
    local cfg = GSVU4UpgradesConfig.getGradeConfig("ExtraFuelStorage", upgrade.grade)
    local maxReserve = cfg and (tonumber(cfg.fuelBonus) or 0) or 0
    local reserve = tonumber(vdata.GSVU4_fuelReserve) or 0
    return reserve < maxReserve - 0.001 and self.amount > 0.001
end

function GSVU4RefuelAuxTank:start()
    if self.character.setActionAnim then
        pcall(function() self.character:setActionAnim("Pour") end)
    end
end

function GSVU4RefuelAuxTank:stop()
    ISBaseTimedAction.stop(self)
end

function GSVU4RefuelAuxTank:perform()
    local vehicle = self.vehicle
    local vdata   = vehicle:getModData()
    local upgrade = vdata.gUpgrades and vdata.gUpgrades.ExtraFuelStorage
    if not upgrade then do end; ISBaseTimedAction.perform(self); return end

    local cfg = GSVU4UpgradesConfig.getGradeConfig("ExtraFuelStorage", upgrade.grade)
    local maxReserve = cfg and (tonumber(cfg.fuelBonus) or 0) or 0
    local reserve    = tonumber(vdata.GSVU4_fuelReserve) or 0
    local space      = maxReserve - reserve
    if space < 0.001 then ISBaseTimedAction.perform(self); return end

    -- Read effective source amount - modData is authoritative when present
    local src    = self.sourceItem
    local srcAmt = 0
    if src then
        local imd = src.getModData and src:getModData() or nil
        if imd and imd.GSVU4_FluidRemaining ~= nil then
            -- modData set: use it (even if 0 = empty)
            srcAmt = tonumber(imd.GSVU4_FluidRemaining) or 0
        elseif src.getFluidContainer then
            -- No modData: first-time item, read native FC
            local fc = src:getFluidContainer()
            if fc and fc.getAmount then
                local iname = src.getName and tostring(src:getName()) or ""
                if not iname:lower():find("^empty") then
                    srcAmt = tonumber(fc:getAmount()) or 0
                end
            end
        end
    end

    local transfer = math.min(srcAmt, space, self.amount)
    if transfer < 0.001 then ISBaseTimedAction.perform(self); return end

    -- Read the item's full type before removing (needed to give back an empty version)
    local srcFullType = nil
    if src and src.getFullType then
        local okFT, ft = pcall(function() return src:getFullType() end)
        if okFT and ft then srcFullType = tostring(ft) end
    end
    -- Remove the filled can from inventory
    local inv = self.character and self.character.getInventory and self.character:getInventory()
    if src and inv and inv.Remove then
        pcall(function() inv:Remove(src) end)
        local imd = src.getModData and src:getModData() or nil
        if imd then imd.GSVU4_FluidRemaining = nil end
    end

    -- Ask the server to give back an empty version of the same container
    if srcFullType and sendClientCommand then
        sendClientCommand("GoresSVU4Core", "GiveEmptyContainer", {
            fullType = srcFullType,
            vehicleX = self.vehicle and self.vehicle.getX and self.vehicle:getX() or nil,
            vehicleY = self.vehicle and self.vehicle.getY and self.vehicle:getY() or nil,
        })
        if self.character then
            self.character:Say("Empty container returned to inventory.")
        end
    end

    vdata.GSVU4_fuelReserve = math.min(maxReserve, reserve + transfer)
    vehicle:transmitModData()

    if self.character then
        self.character:Say(string.format(
            "Aux tank refuelled: %.1fL / %dL",
            vdata.GSVU4_fuelReserve, maxReserve))
    end

    ISBaseTimedAction.perform(self)
end

function GSVU4RefuelAuxTank:new(character, vehicle, sourceItem, amount)
    local o = ISBaseTimedAction.new(self, character)
    setmetatable(o, self)
    self.__index = self
    o.character  = character
    o.vehicle    = vehicle
    o.sourceItem = sourceItem
    o.amount     = tonumber(amount) or 20
    -- ~4 seconds per 20L (slower than main tank to feel deliberate)
    o.maxTime    = math.max(20, math.floor((o.amount / 5) * 30))
    o.stopOnWalk = true
    o.stopOnRun  = true
    return o
end

-- ── 3. Radial menu: "Refuel Aux Tank" slice (inside vehicle) ─────────
-- Adds a slice when EFS is installed and reserve isn't full and player
-- has a jerry can with fuel.

local function GSVU4_FindFuelSource(character)
    if not character or not character.getInventory then return nil end
    local inv = character:getInventory()
    if not inv or not inv.getItems then return nil end
    local items = inv:getItems()
    for i = 0, (items and items:size() or 0) - 1 do
        local item = items:get(i)
        if item then
            local imd = item.getModData and item:getModData() or nil

            -- If we have modData tracking, it is authoritative - never fall through
            -- to native FC for this item, even if the tracked amount is 0
            if imd and imd.GSVU4_FluidRemaining ~= nil then
                local tracked = tonumber(imd.GSVU4_FluidRemaining) or 0
                if tracked > 0.01 then
                    return item, tracked
                end
                -- tracked == 0: we know this can is empty, skip entirely
            else
                -- No modData: first-time item, read native FluidContainer
                if item.getFluidContainer then
                    local fc = item:getFluidContainer()
                    if fc and fc.getAmount then
                        local amt = tonumber(fc:getAmount()) or 0
                        local iname = item.getName and tostring(item:getName()) or ""
                        if amt > 0.01 and not iname:lower():find("^empty") then
                            return item, amt
                        end
                    end
                end
            end
        end
    end
    return nil, 0
end

local function GSVU4_OpenAuxRefuelUI(playerObj, vehicle)
    if not vehicle or not playerObj then return end
    local vdata = vehicle:getModData()
    local upgrade = vdata.gUpgrades and vdata.gUpgrades.ExtraFuelStorage
    if not upgrade then return end

    local cfg = GSVU4UpgradesConfig.getGradeConfig("ExtraFuelStorage", upgrade.grade)
    local maxReserve = cfg and (tonumber(cfg.fuelBonus) or 0) or 0
    local reserve    = tonumber(vdata.GSVU4_fuelReserve) or 0

    if reserve >= maxReserve - 0.001 then
        if playerObj.Say then playerObj:Say("Aux tank is already full.") end
        return
    end

    local src, srcAmt = GSVU4_FindFuelSource(playerObj)
    if not src or srcAmt < 0.01 then
        if playerObj.Say then
            playerObj:Say("No fuel available. Containers may be empty - refill them first.")
        end
        return
    end

    local transfer = math.min(srcAmt, maxReserve - reserve)
    local action = GSVU4RefuelAuxTank:new(playerObj, vehicle, src, transfer)
    ISTimedActionQueue.add(action)
end

-- Hook into ISVehicleMenu.showRadialMenu (inside vehicle, V key).
-- This file is named ZZZZZZ_* so it loads AFTER VehicleArmor_RadialMenu.lua,
-- ensuring we wrap the already-patched showRadialMenu correctly.
if ISVehicleMenu and ISVehicleMenu.showRadialMenu then
    local orig_showRadialMenu_EFS = ISVehicleMenu.showRadialMenu
    function ISVehicleMenu.showRadialMenu(playerObj)
        orig_showRadialMenu_EFS(playerObj)

        local vehicle = playerObj and playerObj.getVehicle and playerObj:getVehicle()
        if not vehicle then return end

        local vdata = vehicle:getModData()
        local upgrade = vdata.gUpgrades and vdata.gUpgrades.ExtraFuelStorage
        if not upgrade then return end

        local cfg = GSVU4UpgradesConfig.getGradeConfig("ExtraFuelStorage", upgrade.grade)
        local maxReserve = cfg and (tonumber(cfg.fuelBonus) or 0) or 0
        local reserve    = tonumber(vdata.GSVU4_fuelReserve) or 0
        if reserve >= maxReserve - 0.001 then
            do end; return
        end

        local _, srcAmt = GSVU4_FindFuelSource(playerObj)
        if srcAmt < 0.01 then
            do end; return
        end

        local menu = getPlayerRadialMenu(playerObj:getPlayerNum())
        if not menu then return end

        menu:addSlice(
            string.format("Refuel Aux (%.0f%%)", (reserve / maxReserve) * 100),
            getTexture("Item_Screwdriver"),
            GSVU4_OpenAuxRefuelUI,
            playerObj, vehicle)
    end
end  -- if ISVehicleMenu.showRadialMenu

-- Also hook showRadialMenuOutside so the slice appears when outside the vehicle
if ISVehicleMenu and ISVehicleMenu.showRadialMenuOutside then
    local orig_showRadialMenuOutside_EFS = ISVehicleMenu.showRadialMenuOutside
    function ISVehicleMenu.showRadialMenuOutside(playerObj)
        orig_showRadialMenuOutside_EFS(playerObj)

        -- Find nearby vehicle to interact with
        local vehicle = nil
        if ISVehicleMenu.getVehicleToInteractWith then
            local ok, v = pcall(function() return ISVehicleMenu.getVehicleToInteractWith(playerObj) end)
            if ok and v then vehicle = v end
        end
        if not vehicle and ISVehicleMenu.getVehicleToInteractWith2 then
            local ok, v = pcall(function() return ISVehicleMenu.getVehicleToInteractWith2(playerObj) end)
            if ok and v then vehicle = v end
        end
        if not vehicle then return end

        local vdata = vehicle:getModData()
        local upgrade = vdata.gUpgrades and vdata.gUpgrades.ExtraFuelStorage
        if not upgrade then return end

        local cfg = GSVU4UpgradesConfig.getGradeConfig("ExtraFuelStorage", upgrade.grade)
        local maxReserve = cfg and (tonumber(cfg.fuelBonus) or 0) or 0
        local reserve    = tonumber(vdata.GSVU4_fuelReserve) or 0
        if reserve >= maxReserve - 0.001 then return end

        local _, srcAmt = GSVU4_FindFuelSource(playerObj)
        if srcAmt < 0.01 then return end

        local menu = getPlayerRadialMenu(playerObj:getPlayerNum())
        if not menu then return end

        menu:addSlice(
            string.format("Refuel Aux (%.0f%%)", (reserve / maxReserve) * 100),
            getTexture("Item_Screwdriver"),
            GSVU4_OpenAuxRefuelUI,
            playerObj, vehicle)
    end
end  -- if ISVehicleMenu.showRadialMenuOutside
