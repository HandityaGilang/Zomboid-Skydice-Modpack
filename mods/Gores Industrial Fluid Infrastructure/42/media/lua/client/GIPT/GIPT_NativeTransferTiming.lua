require "Fluids/ISFluidTransferAction"
require "GIPT/GIPT_Constants"

local function getOwner(container)
    if not container or not container.getOwner then return nil end
    local ok, owner = pcall(function() return container:getOwner() end)
    return ok and owner or nil
end

local function isCompactTankOwner(owner)
    return owner
        and instanceof(owner, "IsoObject")
        and GIPT.getTankClass(owner) == "SMALL"
end

local function containsPetrol(container)
    if not container or not container.getFluidContainer or not Fluid or not Fluid.Petrol then return false end
    local okFluid, fluidContainer = pcall(function() return container:getFluidContainer() end)
    if not okFluid or not fluidContainer then return false end
    local okContains, result = pcall(function() return fluidContainer:contains(Fluid.Petrol) end)
    return okContains and result == true
end

if ISFluidTransferAction and not ISFluidTransferAction.GIPT_CompactGasTimingPatched then
    ISFluidTransferAction.GIPT_CompactGasTimingPatched = true

    local originalNew = ISFluidTransferAction.new
    ISFluidTransferAction.new = function(self, character, sourceContainer, sourceFluidObject, targetContainer, targetFluidObject, amount)
        local action = originalNew(self, character, sourceContainer, sourceFluidObject, targetContainer, targetFluidObject, amount)
        if not action or not character or character:isTimedActionInstant() then return action end

        local sourceOwner = getOwner(action.source)
        local targetOwner = getOwner(action.target)
        local involvesCompactTank = isCompactTankOwner(sourceOwner) or isCompactTankOwner(targetOwner)
        local transfersGasoline = containsPetrol(action.source) or containsPetrol(action.target)

        if involvesCompactTank and transfersGasoline then
            local transferAmount = math.max(0, tonumber(amount) or 0)
            local propaneMatchedTime = math.max(
                GIPT.COMPACT_GAS_TRANSFER_MIN_TIME,
                math.floor(transferAmount * GIPT.COMPACT_GAS_TRANSFER_TIME_PER_LITRE + 0.5)
            )
            action.maxTime = math.max(tonumber(action.maxTime) or 0, propaneMatchedTime)
        end

        return action
    end
end
