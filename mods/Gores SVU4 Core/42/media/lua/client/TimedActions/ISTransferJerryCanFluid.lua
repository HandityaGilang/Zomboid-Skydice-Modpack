--========================================================
-- Gore's SVU4 Core - Jerry Can Fluid Transfer Timed Action
-- Handles Fill Tank and Drain Tank as a timed action.
-- Transfer rate: 5L per second (same as vanilla barrel fill).
--========================================================

require "TimedActions/ISBaseTimedAction"
require "GoresSVU4Core/GSVU4_Upgrades_Config"

ISTransferJerryCanFluid = ISBaseTimedAction:derive("ISTransferJerryCanFluid")

-- Transfer rate in litres per second (vanilla barrel fill is ~5L/s)
local LITRES_PER_SECOND = 5.0
-- Ticks per second in PZ (30)
local TICKS_PER_SECOND = 30

local function calcTime(amount)
    -- Minimum 20 ticks (~0.7s), scale with volume
    return math.max(20, math.floor((amount / LITRES_PER_SECOND) * TICKS_PER_SECOND))
end

function ISTransferJerryCanFluid:isValid()
    if not self.character or not self.vehicle then return false end
    if VehicleArmor_IsCharacterInVehicle and VehicleArmor_IsCharacterInVehicle(self.character) then return false end
    if VehicleArmor_IsCharacterNearVehicle and not VehicleArmor_IsCharacterNearVehicle(self.character, self.vehicle, 5.5) then return false end

    local tanks = GSVU4UpgradesConfig.getJerryCanTanks(self.vehicle)
    if not tanks or not tanks[self.tankIndex] then return false end

    local tank = tanks[self.tankIndex]

    if self.direction == "fill" then
        if (tonumber(tank.capacity) or 20) - (tonumber(tank.amount) or 0) < 0.01 then return false end
    else
        if (tonumber(tank.amount) or 0) < 0.01 then return false end
    end

    return true
end

function ISTransferJerryCanFluid:start()
    -- Use the pump/pour animation (ActionAnim.Pour if available, else default)
    if self.character.setActionAnim then
        local ok = pcall(function()
            self.character:setActionAnim("Pour")
        end)
        if not ok then
            pcall(function() self.character:setActionAnim(CharacterActionAnims.Pour) end)
        end
    end
end

function ISTransferJerryCanFluid:stop()
    ISBaseTimedAction.stop(self)
end

function ISTransferJerryCanFluid:perform()
    local tanks = GSVU4UpgradesConfig.getJerryCanTanks(self.vehicle)
    if not tanks or not tanks[self.tankIndex] then
        ISBaseTimedAction.perform(self); return
    end

    local tank = tanks[self.tankIndex]
    local inv   = self.character and self.character.getInventory and self.character:getInventory()

    if self.direction == "fill" then
        local cap   = tonumber(tank.capacity) or 20
        local amt   = tonumber(tank.amount)   or 0
        local space = cap - amt
        local src   = self.sourceItem
        local srcFC = self.sourceFC

        if not src or not srcFC then
            if self.character then self.character:Say("Source container missing.") end
            ISBaseTimedAction.perform(self); return
        end

        -- Calculate effective amount from source
        local srcAmt = 0
        local md = src.getModData and src:getModData() or nil
        if md and md.GSVU4_FluidRemaining ~= nil then
            -- modData is the authoritative amount - NEVER fall back to native FC
            -- (native FC always shows original amount since we can't modify it)
            srcAmt = tonumber(md.GSVU4_FluidRemaining) or 0
        else
            -- No modData: read native FluidContainer (first-time use of this can)
            local iname = src.getName and tostring(src:getName()) or ""
            if not iname:lower():find("^empty") then
                local okA, a = pcall(function() return srcFC:getAmount() end)
                srcAmt = okA and (tonumber(a) or 0) or 0
            end
        end

        local take   = math.min(srcAmt, space)
        local newSrc = srcAmt - take

        -- Update source item's fluid amount via modData.
        -- We never remove the physical can - it stays in inventory.
        -- Setting GSVU4_FluidRemaining=0 makes getEffectiveFluidAmount return 0,
        -- treating it as empty for future fill/drain operations.
        local smd = src.getModData and src:getModData() or nil
        if smd then
            smd.GSVU4_FluidRemaining = math.max(0, newSrc)
            if newSrc < 0.001 then smd.GSVU4_FluidType = nil end
        end
        tank.amount = math.min(cap, amt + take)
        if self.fluidName and self.fluidName ~= "" then tank.fluidType = self.fluidName end

        if self.vehicle.transmitModData then self.vehicle:transmitModData() end
        if self.character then
            self.character:Say(string.format("Filled %.1fL of %s into tank %d.",
                take, self.fluidName or "fluid", self.tankIndex))
        end

    else -- drain
        local amt  = tonumber(tank.amount) or 0
        local poured = 0

        if inv and inv.getItems then
            local items = inv:getItems()
            for i = 0, (items and items:size() or 0) - 1 do
                if poured >= amt - 0.001 then break end
                local item = items:get(i)
                if item and item.getFluidContainer then
                    local okFC, fc = pcall(function() return item:getFluidContainer() end)
                    if okFC and fc then
                        -- Determine effective current amount and capacity
                        local dstAmt = 0
                        local imd = item.getModData and item:getModData() or nil
                        if imd and imd.GSVU4_FluidRemaining ~= nil then
                            dstAmt = tonumber(imd.GSVU4_FluidRemaining) or 0
                        else
                            local iname = item.getName and tostring(item:getName()) or ""
                            if iname:lower():find("^empty") then
                                dstAmt = 0
                            else
                                local okA, a = pcall(function() return fc:getAmount() end)
                                dstAmt = okA and (tonumber(a) or 0) or 0
                            end
                        end
                        local okC, dstCap = pcall(function() return fc:getCapacity() end)
                        local dstCapN = okC and (tonumber(dstCap) or 20) or 20
                        local space = dstCapN - dstAmt
                        if space > 0.01 then
                            -- Check fluid compatibility
                            local compatible = true
                            if dstAmt > 0.01 and tank.fluidType then
                                -- Don't mix fluid types in same container
                                local dstFluid = nil
                                if fc.getPrimaryFluid then
                                    local okF, f = pcall(function() return fc:getPrimaryFluid() end)
                                    if okF and f and f.getName then
                                        local okN, n = pcall(function() return f:getName() end)
                                        if okN and n and tostring(n) ~= "" then dstFluid = tostring(n) end
                                    end
                                end
                                if not dstFluid then
                                    local imd2 = item.getModData and item:getModData() or nil
                                    if imd2 and imd2.GSVU4_FluidType then dstFluid = imd2.GSVU4_FluidType end
                                end
                                if dstFluid and dstFluid ~= "" and dstFluid ~= tank.fluidType then
                                    compatible = false
                                end
                            end
                            if compatible then
                                local pour = math.min(space, amt - poured)
                                if pour > 0.001 then
                                    local imd2 = item.getModData and item:getModData() or nil
                                    if imd2 then
                                        imd2.GSVU4_FluidRemaining = dstAmt + pour
                                        -- Store fluid type so Fill Tank can identify this can
                                        if tank.fluidType then
                                            imd2.GSVU4_FluidType = tank.fluidType
                                        end
                                        -- Clear the "empty" modData marker if previously set
                                        imd2.GSVU4_IsEmpty = nil
                                    end
                                    poured = poured + pour
                                end
                            end
                        end
                    end
                end
            end
        end

        if poured > 0.001 then
            tank.amount = math.max(0, amt - poured)
            if tank.amount < 0.01 then tank.fluidType = nil end
            if self.vehicle.transmitModData then self.vehicle:transmitModData() end
            if self.character then
                self.character:Say(string.format("Drained %.1fL from tank %d.", poured, self.tankIndex))
            end
        else
            if self.character then self.character:Say("No suitable container found for draining.") end
        end
    end

    ISBaseTimedAction.perform(self)
end

function ISTransferJerryCanFluid:new(character, vehicle, tankIndex, direction, amount, sourceItem, sourceFC, fluidName)
    local o = ISBaseTimedAction:new(character)
    setmetatable(o, self)
    self.__index   = self
    o.character   = character
    o.vehicle     = vehicle
    o.tankIndex   = tankIndex   or 1
    o.direction   = direction   or "fill"  -- "fill" or "drain"
    o.amount      = amount      or 20
    o.sourceItem  = sourceItem  -- item to drain FROM (fill direction only)
    o.sourceFC    = sourceFC
    o.fluidName   = fluidName
    o.maxTime     = calcTime(amount or 20)
    o.stopOnWalk  = true
    o.stopOnRun   = true
    o.stopOnAim   = false
    return o
end
