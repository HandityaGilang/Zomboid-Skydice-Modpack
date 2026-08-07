VFX = VFX or {}

VFX.AgingStatsDebug = false

VFX.AgingItems = {}
VFX.ManagerRunning = false

local function VFXAgingStatsDebug(message)
    if VFX.AgingStatsDebug then
        print("[VFX Age Stats Tracking] " .. tostring(message))
    end
end

local function VFXFormatAgingStat(value)
    if value == nil then
        return "N/A"
    end

    return string.format("%.2f", value)
end

local function VFXDebugAgingItem(cheeseItem, cheeseType, age)
    local fullType = cheeseItem:getFullType() or cheeseType
    local stress = cheeseItem:getStressChange()
    local boredom = cheeseItem:getBoredomChange()
    local unhappiness = cheeseItem:getUnhappyChange()

    VFXAgingStatsDebug(
        tostring(fullType) ..
        " | Age: " .. VFXFormatAgingStat(age) ..
        " | Stress: " .. VFXFormatAgingStat(stress) ..
        " | Boredom: " .. VFXFormatAgingStat(boredom) ..
        " | Unhappiness: " .. VFXFormatAgingStat(unhappiness)
    )
end

local function VFXSetAgingStatsTracked(item, cheeseType, stageIndex)
    if not item then
        return
    end

    item:getModData().VFX_AgingStats = {
        tracked = true,
        type = cheeseType,
        stageIndex = stageIndex or 0
    }

    VFXAgingStatsDebug("Saved mod data: " .. tostring(item:getFullType()) .. " | Type: " .. tostring(cheeseType) .. " | Stage: " .. tostring(stageIndex or 0))
end

local function VFXClearAgingStatsTracked(item)
    if not item then
        return
    end

    item:getModData().VFX_AgingStats = {
        tracked = false
    }
end

local function VFXAgingStatsListHasItem(item)
    for _, cheeseData in ipairs(VFX.AgingItems) do
        if cheeseData.cheeseItem == item then
            return true
        end
    end

    return false
end

local function VFXGetUpdatedAgingStatsAge(item)
    if item and item.updateAge then
        item:updateAge()
    end

    return item:getAge()
end

VFX.CheeseConfigs = {

    Brie = {
        ripeAge = 14.0,
        staleAge = 28.0,
        unhappyMax = -20,
        boredMax = -10,
        stressMax = -5,
        stages = {
            { age = 14.0, name = "Brie Cheese - Homemade (Aged)" }
        }
    },

    Camembert = {
        ripeAge = 10.0,
        staleAge = 20.0,
        unhappyMax = -15,
        boredMax = -8,
        stressMax = -4,
        stages = {
            { age = 10.0, name = "Camembert Cheese - Homemade (Aged)" }
        }
    },

    Swiss = {
        ripeAge = 60.0,
        staleAge = 120.0,
        unhappyMax = -60,
        boredMax = -30,
        stressMax = -15,
        stages = {
            { age = 60.0, name = "Swiss Cheese - Homemade (Aged)" }
        }
    },

    Cheddar = {
        ripeAge = 168.0,
        staleAge = 336.0,
        unhappyMax = -100,
        boredMax = -50,
        stressMax = -25,
        stages = {
            { age = 14.0, name = "Cheddar Cheese - Homemade (Mild)" },
            { age = 28.0, name = "Cheddar Cheese - Homemade (Medium)" },
            { age = 84.0, name = "Cheddar Cheese - Homemade (Sharp)" },
            { age = 168.0, name = "Cheddar Cheese - Homemade (Extra Sharp)" }
        }
    },
	
	BlueCheese = {
		ripeAge = 28.0,
		staleAge = 56.0,
		unhappyMax = -30,
		boredMax = -15,
		stressMax = -8,
		stages = {
			{ age = 28.0, name = "Blue Cheese - Homemade (Aged)" }
		}
	},
	
	Feta = {
		ripeAge = 28.0,
		staleAge = 56.0,
		unhappyMax = -30,
		boredMax = -15,
		stressMax = -8,
		stages = {
			{ age = 14.0, name = "Feta Cheese - Homemade (Soft)" },
			{ age = 28.0, name = "Feta Cheese - Homemade (Firm)" }
		}
	},
	
	Parmesan = {
		ripeAge = 180.0,
		staleAge = 360.0,
		unhappyMax = -80,
		boredMax = -40,
		stressMax = -20,
		stages = {
			{ age = 180.0, name = "Parmesan Cheese - Homemade (Aged)" }
		}
	}
}

local VFXAgingStatsLegacyItemTypes = {
    ["VFX.BrieCheeseHomemade"] = "Brie",
    ["VFX.CamembertCheeseHomemade"] = "Camembert",
    ["VFX.WheelSwissCheeseHomemade"] = "Swiss",
    ["VFX.WheelParmesanCheeseHomemade"] = "Parmesan",
    ["VFX.WheelCheddarCheeseHomemade"] = "Cheddar",
    ["VFX.WheelBlueCheeseHomemade"] = "BlueCheese",
    ["VFX.FetaCheeseHomemade"] = "Feta"
}

local function VFXGetLegacyAgingStatsType(item)
    if not item then
        return nil
    end

    return VFXAgingStatsLegacyItemTypes[item:getFullType()]
end

local function VFXApplyAgingStats(cheeseItem, cheeseType, stageIndex)
    local cheeseConfig = VFX.CheeseConfigs[cheeseType]
    if not cheeseItem or not cheeseConfig then
        return stageIndex or 0, false
    end

    local age = VFXGetUpdatedAgingStatsAge(cheeseItem)

    if age < cheeseConfig.staleAge then
        local scriptItem = cheeseItem:getScriptItem()
        if scriptItem then
            local baseHunger = scriptItem:getHungerChange()
            local currentHunger = cheeseItem:getHungerChange()
            local ratioHunger = 1.0
            if baseHunger ~= 0 then
                ratioHunger = currentHunger / baseHunger
            end

            local ratioTime = math.min(math.floor(age + 0.5) / cheeseConfig.ripeAge, 1.0)

            cheeseItem:setUnhappyChange(cheeseConfig.unhappyMax * ratioTime * ratioHunger * 100)
            cheeseItem:setBoredomChange(cheeseConfig.boredMax * ratioTime * ratioHunger * 100)
            cheeseItem:setStressChange(cheeseConfig.stressMax * ratioTime * ratioHunger)
        end
    end

    VFXDebugAgingItem(cheeseItem, cheeseType, age)

    local appliedStageIndex = stageIndex or 0
    for stageNumber, stageConfig in ipairs(cheeseConfig.stages) do
        if age >= stageConfig.age and appliedStageIndex < stageNumber then
            cheeseItem:setName(stageConfig.name)
            appliedStageIndex = stageNumber
            VFXSetAgingStatsTracked(cheeseItem, cheeseType, stageNumber)
            VFXAgingStatsDebug(cheeseType .. " advanced to stage: " .. stageConfig.name .. " (age " .. tostring(age) .. ")")
        end
    end

    if age >= cheeseConfig.staleAge then
        VFXAgingStatsDebug(cheeseType .. " removed after reaching stale age (age " .. tostring(age) .. ")")
        VFXClearAgingStatsTracked(cheeseItem)
        return appliedStageIndex, true
    end

    return appliedStageIndex, false
end

function VFX.StartAging(_item, cheeseType)

    if not _item then
        VFXAgingStatsDebug("StartAging called with nil item")
        return
    end

    local cheeseConfig = VFX.CheeseConfigs[cheeseType]
    if not cheeseConfig then
        VFXAgingStatsDebug("Invalid cheese type: " .. tostring(cheeseType))
        return
    end

    VFXSetAgingStatsTracked(_item, cheeseType, 0)

    table.insert(VFX.AgingItems, {
        cheeseItem = _item,
        type = cheeseType,
        stageIndex = 0 -- track last applied stage
    })

    VFXAgingStatsDebug("Started aging: " .. cheeseType .. " | Age: " .. tostring(VFXGetUpdatedAgingStatsAge(_item)))

    if not VFX.ManagerRunning then
        Events.EveryDays.Add(VFX.AgingManager)
        VFX.ManagerRunning = true
        VFXAgingStatsDebug("AgingManager started")
    end

end

function VFX.AgingManager()

    VFXAgingStatsDebug("Daily tick | Tracking: " .. tostring(#VFX.AgingItems))

    if #VFX.AgingItems == 0 then
        Events.EveryDays.Remove(VFX.AgingManager)
        VFX.ManagerRunning = false
        VFXAgingStatsDebug("AgingManager stopped (no items left)")
        return
    end

    for i = #VFX.AgingItems, 1, -1 do

        local cheeseData = VFX.AgingItems[i]
        local cheeseItem = cheeseData.cheeseItem
        local cheeseConfig = VFX.CheeseConfigs[cheeseData.type]
		
        if not cheeseItem or (not cheeseItem:getContainer() and not cheeseItem:getWorldItem()) then
            VFXAgingStatsDebug(cheeseData.type .. " removed (eaten/destroyed)")
            VFXClearAgingStatsTracked(cheeseItem)
            table.remove(VFX.AgingItems, i)

        else
            local stageIndex, removeItem = VFXApplyAgingStats(cheeseItem, cheeseData.type, cheeseData.stageIndex)
            cheeseData.stageIndex = stageIndex

            if removeItem then
                table.remove(VFX.AgingItems, i)
            end
        end
    end
end


function VFX.BrieAging(_item)
    VFX.StartAging(_item, "Brie")
end

function VFX.CamAging(_item)
    VFX.StartAging(_item, "Camembert")
end

function VFX.SwissAging(_item)
    VFX.StartAging(_item, "Swiss")
end

function VFX.ParmAging(_item)
    VFX.StartAging(_item, "Parmesan")
end

function VFX.CheddarAging(_item)
    VFX.StartAging(_item, "Cheddar")
end

function VFX.BlueCheeseAging(_item)
    VFX.StartAging(_item, "BlueCheese")
end

function VFX.FetaAging(_item)
    VFX.StartAging(_item, "Feta")
end

function VFX.HomemadeWineAging(_item)
    VFX.StartAging(_item, "HomemadeWine")
end

function VFX.RestoreAgingStatsTracking(item, source)
    if not item then
        return false
    end

    source = source or "unknown"
    local agingStats = item:getModData().VFX_AgingStats

    if agingStats and agingStats.tracked == false then
        return false
    end

    if not agingStats or not agingStats.tracked then
        local legacyType = VFXGetLegacyAgingStatsType(item)
        if not legacyType then
            return false
        end

        VFXAgingStatsDebug("Found legacy aging stats item during " .. source .. ": " .. tostring(item:getFullType()) .. " | Type: " .. tostring(legacyType))
        VFXSetAgingStatsTracked(item, legacyType, 0)
        agingStats = item:getModData().VFX_AgingStats
    else
        VFXAgingStatsDebug("Found saved mod data " .. source .. ": " .. tostring(item:getFullType()) .. " | Type: " .. tostring(agingStats.type) .. " | Stage: " .. tostring(agingStats.stageIndex or 0))
    end

    if not VFX.CheeseConfigs[agingStats.type] then
        VFXClearAgingStatsTracked(item)
        VFXAgingStatsDebug("Cleared invalid restored item: " .. tostring(item:getFullType()))
        return true
    end

    if VFXAgingStatsListHasItem(item) then
        VFXAgingStatsDebug("Already in Lua tracking table during " .. source .. ": " .. tostring(item:getFullType()))
        return true
    end

    local stageIndex, removeItem = VFXApplyAgingStats(item, agingStats.type, agingStats.stageIndex)
    if removeItem then
        return true
    end

    table.insert(VFX.AgingItems, {
        cheeseItem = item,
        type = agingStats.type,
        stageIndex = stageIndex or 0
    })

    if not VFX.ManagerRunning then
        Events.EveryDays.Add(VFX.AgingManager)
        VFX.ManagerRunning = true
        VFXAgingStatsDebug("AgingManager started")
    end

    VFXAgingStatsDebug("Re-tracked from mod data into Lua table during " .. source .. ": " .. tostring(agingStats.type) .. " | Age: " .. tostring(VFXGetUpdatedAgingStatsAge(item)))
    return true
end

local function VFXRestoreAgingStatsInventory(inventory, source)
    if not inventory then
        return 0
    end

    local foundCount = 0
    local items = inventory:getItems()
    for i = items:size() - 1, 0, -1 do
        local item = items:get(i)
        if VFX.RestoreAgingStatsTracking(item, source) then
            foundCount = foundCount + 1
        end

        if instanceof(item, "InventoryContainer") then
            foundCount = foundCount + VFXRestoreAgingStatsInventory(item:getInventory(), source .. " nested container")
        end
    end

    return foundCount
end

local function VFXRestoreAgingStatsGridSquare(square)
    if not square then
        return
    end

    local source = "LoadGridsquare " .. tostring(square:getX()) .. "," .. tostring(square:getY()) .. "," .. tostring(square:getZ())
    local foundCount = 0

    local worldObjects = square:getWorldObjects()
    if worldObjects then
        for i = worldObjects:size() - 1, 0, -1 do
            local worldObject = worldObjects:get(i)
            local item = worldObject and worldObject:getItem()
            if VFX.RestoreAgingStatsTracking(item, source .. " floor") then
                foundCount = foundCount + 1
            end
        end
    end

    local objects = square:getObjects()
    if objects then
        for i = objects:size() - 1, 0, -1 do
            local obj = objects:get(i)
            local container = obj and obj:getContainer()
            if container then
                foundCount = foundCount + VFXRestoreAgingStatsInventory(container, source .. " container " .. tostring(container:getType()))
            end
        end
    end

    if foundCount > 0 then
        VFXAgingStatsDebug("LoadGridsquare restore scan found mod data tracked items: " .. tostring(foundCount) .. " at " .. tostring(square:getX()) .. "," .. tostring(square:getY()) .. "," .. tostring(square:getZ()))
    end
end

Events.LoadGridsquare.Add(VFXRestoreAgingStatsGridSquare)