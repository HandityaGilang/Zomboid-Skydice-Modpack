VFX = VFX or {}

VFX.CookedNutritionDebug = false

VFX.CookedNutritionStore = VFX.CookedNutritionStore or {}
VFX.CookedNutritionManagerRunning = VFX.CookedNutritionManagerRunning or false
VFX.CookedNutritionCaptureDelayTicks = 1

VFX.CookedNutritionReplaceItems = {
    ["VFX.EvaporatedMilkPreparationPot"] = "VFX.EvaporatedMilkPot",
    ["VFX.EvaporatedMilkPreparationPotForged"] = "EvaporatedMilkPotForged",
    ["VFX.CottageCheesePreparationPot"] = "VFX.CottageCheeseCurdPot",
    ["VFX.CottageCheesePreparationPotForged"] = "VFX.CottageCheeseCurdPotForged",
    ["VFX.SugarBeetPulpPot"] = "VFX.SugarBeetSyrupPot",
    ["VFX.SugarBeetPulpPotForged"] = "VFX.SugarBeetSyrupPotForged",
    ["VFX.SugarBeetSyrupPot"] = "VFX.SugarBeetMolassesPot",
    ["VFX.SugarBeetSyrupPotForged"] = "VFX.SugarBeetMolassesPotForged",
}

local function VFXReplaceOnCookedDebug(message)
    if VFX.CookedNutritionDebug then
        print("[VFX.CookedNutrition] " .. tostring(message))
    end
end

local function VFXStoreNutrition(prefix, item, storedNutrition)
    local function formatNutritionNumber(value)
        value = tonumber(value) or 0
        return string.format("%.2f", math.floor(value * 100) / 100)
    end

    if item and storedNutrition then
        storedNutrition.hunger = item:getHungerChange()
        storedNutrition.baseHunger = item:getBaseHunger()
        storedNutrition.thirst = item:getThirstChange()
        storedNutrition.calories = item:getCalories()
        storedNutrition.carbohydrates = item:getCarbohydrates()
        storedNutrition.lipids = item:getLipids()
        storedNutrition.proteins = item:getProteins()
        storedNutrition.captured = true

        VFXReplaceOnCookedDebug("Captured nutrition for: " .. tostring(storedNutrition.itemType))
    end

    VFXReplaceOnCookedDebug(tostring(prefix)
        .. " hunger=" .. formatNutritionNumber(storedNutrition.hunger)
        .. " | thirst=" .. formatNutritionNumber(storedNutrition.thirst)
        .. " | cal=" .. formatNutritionNumber(storedNutrition.calories)
        .. " | carbs=" .. formatNutritionNumber(storedNutrition.carbohydrates)
        .. " | fat=" .. formatNutritionNumber(storedNutrition.lipids)
        .. " | protein=" .. formatNutritionNumber(storedNutrition.proteins))
end

local function VFXApplyNutrition(item, storedNutrition)
    if not item or not storedNutrition then
        return
    end

    item:setCalories(storedNutrition.calories)
    item:setCarbohydrates(storedNutrition.carbohydrates)
    item:setLipids(storedNutrition.lipids)
    item:setProteins(storedNutrition.proteins)
    item:setBaseHunger(storedNutrition.baseHunger)
    item:setHungChange(storedNutrition.hunger)
    item:setThirstChange(storedNutrition.thirst)

    VFXReplaceOnCookedDebug("Applied nutrition to: " .. tostring(item:getFullType()))
    VFXStoreNutrition("Nutrition:", nil, storedNutrition)
end

local function VFXReplaceOnCooked(item, storedNutrition)
    if not item or not storedNutrition then
        return false
    end

    local replaceType = VFX.CookedNutritionReplaceItems[storedNutrition.itemType]

    if not replaceType then
        VFXReplaceOnCookedDebug("No replacement table entry for: " .. tostring(storedNutrition.itemType))
        return false
    end

    VFXReplaceOnCookedDebug("Replacing cooked item: " .. tostring(storedNutrition.itemType) .. " -> " .. tostring(replaceType))

    local container = item:getContainer()

    if container then
        local newItem = instanceItem(replaceType)

        if not newItem then
            VFXReplaceOnCookedDebug("Failed to replace: " .. tostring(replaceType))
            return false
        end

        VFXApplyNutrition(newItem, storedNutrition)

        container:AddItem(newItem)
        container:Remove(item)

        VFXReplaceOnCookedDebug("Replaced in container: " .. tostring(container))
        return true
    end

    local worldItem = item:getWorldItem()

    if worldItem then
        local square = worldItem:getSquare()

        if square then
            local newItem = instanceItem(replaceType)

            if not newItem then
                VFXReplaceOnCookedDebug("Failed to instance replacement: " .. tostring(replaceType))
                return false
            end

            VFXApplyNutrition(newItem, storedNutrition)

            square:transmitRemoveItemFromSquare(worldItem)
            square:AddWorldInventoryItem(newItem, 0.5, 0.5, 0)

            VFXReplaceOnCookedDebug("Replaced on ground at square: " .. tostring(square))
            return true
        end
    end

    VFXReplaceOnCookedDebug("Could not replace item, no container or world square found: " .. tostring(storedNutrition.itemType))
    return false
end

function VFX.ReplaceOnCookedTrackingManager()
    local trackedCount = 0

    for _ in pairs(VFX.CookedNutritionStore) do
        trackedCount = trackedCount + 1
    end

    VFXReplaceOnCookedDebug("Tracking tick | Tracking: " .. tostring(trackedCount))

    if trackedCount == 0 then
        Events.EveryOneMinute.Remove(VFX.ReplaceOnCookedTrackingManager)
        VFX.CookedNutritionManagerRunning = false
        VFXReplaceOnCookedDebug("Manager stopped (no items left)")
        return
    end

    for item, storedNutrition in pairs(VFX.CookedNutritionStore) do
        if not item or (not item:getContainer() and not item:getWorldItem()) then
            VFXReplaceOnCookedDebug("Tracked item removed before replacement: " .. tostring(storedNutrition.itemType))
            VFX.CookedNutritionStore[item] = nil
        else
            if not storedNutrition.captured then
                storedNutrition.captureDelay = storedNutrition.captureDelay - 1

                VFXReplaceOnCookedDebug("Capture delay: " .. tostring(storedNutrition.itemType)
                    .. " | ticks remaining=" .. tostring(storedNutrition.captureDelay))

                if storedNutrition.captureDelay <= 0 then
                    VFXStoreNutrition("Nutrition:", item, storedNutrition)
                end
            end

            if storedNutrition.captured and item:isCooked() then
                VFXReplaceOnCookedDebug("Cooked threshold reached: " .. tostring(storedNutrition.itemType))

                if VFXReplaceOnCooked(item, storedNutrition) then
                    VFX.CookedNutritionStore[item] = nil
                end
            end
        end
    end
end

function VFX.ReplaceOnCooked(item)
    if not item then
        VFXReplaceOnCookedDebug("OnCreate called with nil item")
        return
    end

    local itemType = item:getFullType()
    local replaceType = VFX.CookedNutritionReplaceItems[itemType]

    if not replaceType then
        VFXReplaceOnCookedDebug("Skipping: " .. tostring(itemType))
        return
    end

    if VFX.CookedNutritionStore[item] then
        VFXReplaceOnCookedDebug("Already tracking: " .. tostring(itemType))
        return
    end

    local replaceOnCooked = nil

    if item.getReplaceOnCooked then
        replaceOnCooked = item:getReplaceOnCooked()
    end

    local storedNutrition = {
        itemType = itemType,
        replaceType = replaceType,
        replaceOnCooked = replaceOnCooked,
        captured = false,
        captureDelay = VFX.CookedNutritionCaptureDelayTicks,
    }

    VFX.CookedNutritionStore[item] = storedNutrition

    VFXReplaceOnCookedDebug("Tracking: " .. tostring(itemType))
    VFXReplaceOnCookedDebug("Replacement Table: " .. tostring(itemType) .. " -> " .. tostring(replaceType))
    VFXReplaceOnCookedDebug("ReplaceOnCooked: " .. tostring(replaceOnCooked))
    VFXReplaceOnCookedDebug("Capture delay ticks: " .. tostring(storedNutrition.captureDelay))

    if not VFX.CookedNutritionManagerRunning then
        Events.EveryOneMinute.Add(VFX.ReplaceOnCookedTrackingManager)
        VFX.CookedNutritionManagerRunning = true
        VFXReplaceOnCookedDebug("Manager started")
    end
end
