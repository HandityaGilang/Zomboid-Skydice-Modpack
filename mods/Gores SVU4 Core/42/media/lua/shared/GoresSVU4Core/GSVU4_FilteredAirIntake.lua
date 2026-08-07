--========================================================
-- Gore's SVU4 Core - Filtered Air Intake shared helpers
--========================================================

GSVU4FilteredAirIntake = GSVU4FilteredAirIntake or {}
local M = GSVU4FilteredAirIntake
local safeCall

M.UPGRADE_ID = "FilteredAirIntake"
M.CORPSE_THRESHOLD = 5
M.FILTER_CAPACITY = {
    ["Base.GasmaskFilter"] = 50,
    ["Base.RespiratorFilters"] = 50,
    ["Base.GasmaskFilterCrafted"] = 25,
    ["Base.RespiratorFiltersRecharged"] = 25,
}
M.FILTER_LABELS = {
    ["Base.GasmaskFilter"] = "Gas-mask Filter",
    ["Base.RespiratorFilters"] = "Respirator Filter",
    ["Base.GasmaskFilterCrafted"] = "Crafted Gas-mask Filter",
    ["Base.RespiratorFiltersRecharged"] = "Recharged Respirator Filter",
}

-- A Filtered Air Intake can only protect a cab that is physically capable of
-- being sealed. Keep this registry extensible so vehicle integrations can add
-- unusual open-top scripts that do not use an obvious Cabrio/Convertible name.
M.OPEN_TOP_SCRIPT_NAMES = M.OPEN_TOP_SCRIPT_NAMES or {
    ["pzkcosettecabrio"] = true,
    ["pzkdashranchercabrio"] = true,
    ["pzkmercialang4000cabrio"] = true,
}
M.OPEN_TOP_NAME_MARKERS = M.OPEN_TOP_NAME_MARKERS or {
    "cabrio",
    "convertible",
    "roadster",
    "topless",
    "roofless",
    "opentop",
    "open_top",
    "softtop",
    "soft_top",
}

local function normaliseVehicleScriptName(value)
    value = string.lower(tostring(value or ""))
    value = value:gsub("^base%.", "")
    return value
end

function M.getVehicleScriptName(vehicle)
    if not vehicle then return "" end
    local scriptName = nil
    if vehicle.getScriptName then
        scriptName = safeCall(function() return vehicle:getScriptName() end, nil)
    end
    if (not scriptName or tostring(scriptName) == "") and vehicle.getScript then
        local script = safeCall(function() return vehicle:getScript() end, nil)
        if script then
            if script.getFullName then
                scriptName = safeCall(function() return script:getFullName() end, nil)
            end
            if (not scriptName or tostring(scriptName) == "") and script.getName then
                scriptName = safeCall(function() return script:getName() end, nil)
            end
        end
    end
    return normaliseVehicleScriptName(scriptName)
end

function M.registerOpenTopScript(scriptName)
    scriptName = normaliseVehicleScriptName(scriptName)
    if scriptName == "" then return false end
    M.OPEN_TOP_SCRIPT_NAMES[scriptName] = true
    return true
end

function M.isOpenTopVehicle(vehicle)
    local scriptName = M.getVehicleScriptName(vehicle)
    if scriptName == "" then return false, nil end
    if M.OPEN_TOP_SCRIPT_NAMES[scriptName] == true then return true, scriptName end
    for _, marker in ipairs(M.OPEN_TOP_NAME_MARKERS or {}) do
        if scriptName:find(marker, 1, true) then return true, scriptName end
    end
    return false, scriptName
end

function M.canInstallOnVehicle(vehicle)
    local openTop = M.isOpenTopVehicle(vehicle)
    if openTop then
        return false, "Filtered Air Intake requires a fully enclosed cab. Open-top and cabrio vehicles cannot form a sealed cabin."
    end
    return true, nil
end

safeCall = function(fn, default)
    local ok, value = pcall(fn)
    if ok then return value end
    return default
end

local function clamp(value, minimum, maximum)
    value = tonumber(value) or 0
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

local function fullType(item)
    if not item then return "" end
    if item.getFullType then
        local value = safeCall(function() return item:getFullType() end, nil)
        if value then return tostring(value) end
    end
    local module = item.getModule and safeCall(function() return item:getModule() end, nil) or nil
    local typ = item.getType and safeCall(function() return item:getType() end, nil) or nil
    if module and typ then return tostring(module) .. "." .. tostring(typ) end
    return ""
end
M.getItemFullType = fullType

function M.getFilterItemCapacity(item, itemType)
    itemType = itemType or fullType(item)
    local nominal = tonumber(M.FILTER_CAPACITY[itemType]) or 0
    if nominal <= 0 or not item then return 0 end

    local md = item.getModData and safeCall(function() return item:getModData() end, nil) or nil
    if md and md.GSVU4FilterCapacity ~= nil then
        return clamp(md.GSVU4FilterCapacity, 0, nominal)
    end

    if item.getItemCapacity then
        local capacity = tonumber(safeCall(function() return item:getItemCapacity() end, nil))
        local maximum = item.getMaxCapacity and tonumber(safeCall(function() return item:getMaxCapacity() end, nil)) or nil
        if capacity ~= nil and (capacity > 0 or (maximum ~= nil and maximum > 0)) then
            return clamp(capacity, 0, nominal)
        end
    end

    local drainable = item.IsDrainable and safeCall(function() return item:IsDrainable() end, false) == true
    if drainable and item.getUsedDelta then
        local ratio = tonumber(safeCall(function() return item:getUsedDelta() end, nil))
        if ratio ~= nil then return clamp(ratio, 0, 1) * nominal end
    end

    return nominal
end

local function addInventoryItems(inv, out, seenInv)
    if not inv or seenInv[inv] then return end
    seenInv[inv] = true
    local items = inv.getItems and safeCall(function() return inv:getItems() end, nil) or nil
    if not items or not items.size or not items.get then return end
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item then
            local ft = fullType(item)
            local nominal = tonumber(M.FILTER_CAPACITY[ft]) or 0
            if nominal > 0 then
                local value = M.getFilterItemCapacity(item, ft)
                if value > 0.001 then
                    out[#out + 1] = {
                        item = item,
                        container = inv,
                        fullType = ft,
                        value = value,
                        nominal = nominal,
                        factory = nominal >= 50,
                    }
                end
            end
            if item.getInventory then
                local child = safeCall(function() return item:getInventory() end, nil)
                if child then addInventoryItems(child, out, seenInv) end
            end
        end
    end
end

function M.getFilterItems(character)
    local out, seenInv = {}, {}
    if not character or not character.getInventory then return out end
    local inv = safeCall(function() return character:getInventory() end, nil)
    addInventoryItems(inv, out, seenInv)
    return out
end

function M.getAvailableFilterCapacity(character)
    local total = 0
    for _, entry in ipairs(M.getFilterItems(character)) do total = total + (entry.value or 0) end
    return math.floor(total + 0.5)
end

local function cloneSelection(selection)
    local copy = {}
    for i = 1, #selection do copy[i] = selection[i] end
    return copy
end

local function betterState(candidate, existing)
    if not existing then return true end
    if candidate.count ~= existing.count then return candidate.count < existing.count end
    if candidate.factory ~= existing.factory then return candidate.factory > existing.factory end
    return false
end

function M.selectFilterItems(character, requested)
    requested = math.max(0, math.floor((tonumber(requested) or 0) + 0.5))
    if requested <= 0 then return {}, 0 end

    local items = M.getFilterItems(character)
    local limit = requested + 50
    local states = {
        [0] = { selection = {}, count = 0, factory = 0, actual = 0 }
    }

    for _, entry in ipairs(items) do
        local itemValue = math.max(1, math.floor((tonumber(entry.value) or 0) + 0.5))
        local snapshot = {}
        for total, state in pairs(states) do snapshot[#snapshot + 1] = { total = total, state = state } end
        for _, pair in ipairs(snapshot) do
            local newTotal = math.min(limit, pair.total + itemValue)
            local selection = cloneSelection(pair.state.selection)
            selection[#selection + 1] = entry
            local candidate = {
                selection = selection,
                count = pair.state.count + 1,
                factory = pair.state.factory + (entry.factory and 1 or 0),
                actual = pair.state.actual + itemValue,
            }
            if betterState(candidate, states[newTotal]) then states[newTotal] = candidate end
        end
    end

    local bestTotal, bestState = nil, nil
    for total, state in pairs(states) do
        if total >= requested then
            if not bestTotal or total < bestTotal or (total == bestTotal and betterState(state, bestState)) then
                bestTotal, bestState = total, state
            end
        end
    end
    if not bestState then return nil, 0 end
    return bestState.selection, bestState.actual
end

local function mediaFromSelection(selected, requested)
    local media, remaining = {}, math.max(0, tonumber(requested) or 0)
    for _, entry in ipairs(selected or {}) do
        if remaining <= 0 then break end
        local available = math.max(0, tonumber(entry.value) or 0)
        local installed = math.min(available, remaining)
        if installed > 0 then
            media[#media + 1] = {
                fullType = tostring(entry.fullType or ""),
                installedCapacity = installed,
                nominalCapacity = tonumber(entry.nominal) or tonumber(M.FILTER_CAPACITY[entry.fullType]) or installed,
            }
            remaining = remaining - installed
        end
    end
    return media
end

function M.setInstalledFilterMedia(upgrade, media)
    if not upgrade then return end
    upgrade.filterMedia = {}
    for _, entry in ipairs(media or {}) do
        local ft = tostring(entry.fullType or "")
        local installed = math.max(0, tonumber(entry.installedCapacity) or 0)
        local nominal = tonumber(entry.nominalCapacity) or tonumber(M.FILTER_CAPACITY[ft]) or installed
        if ft ~= "" and installed > 0 then
            upgrade.filterMedia[#upgrade.filterMedia + 1] = {
                fullType = ft,
                installedCapacity = installed,
                nominalCapacity = nominal,
            }
        end
    end
    upgrade.filterMediaVersion = 1
end

function M.hasRecordedFilterMedia(upgradeOrVehicle)
    local upgrade = upgradeOrVehicle
    if upgradeOrVehicle and upgradeOrVehicle.getModData then upgrade = M.getInstalled(upgradeOrVehicle) end
    return upgrade and type(upgrade.filterMedia) == "table" and #upgrade.filterMedia > 0
end

function M.getFilterMediaSummary(upgradeOrVehicle)
    local upgrade = upgradeOrVehicle
    if upgradeOrVehicle and upgradeOrVehicle.getModData then upgrade = M.getInstalled(upgradeOrVehicle) end
    if not M.hasRecordedFilterMedia(upgrade) then return "Legacy filter set" end
    local counts, order = {}, {}
    for _, entry in ipairs(upgrade.filterMedia) do
        local ft = tostring(entry.fullType or "")
        if ft ~= "" then
            if not counts[ft] then order[#order + 1] = ft; counts[ft] = 0 end
            counts[ft] = counts[ft] + 1
        end
    end
    local parts = {}
    for _, ft in ipairs(order) do
        parts[#parts + 1] = tostring(counts[ft]) .. "x " .. tostring(M.FILTER_LABELS[ft] or ft)
    end
    return table.concat(parts, ", ")
end

function M.consumeFilterCapacity(character, requested)
    local selected, total = M.selectFilterItems(character, requested)
    if not selected then return false, 0, 0, "Insufficient filter media.", nil end
    local media = mediaFromSelection(selected, requested)
    for _, entry in ipairs(selected) do
        local removed = false
        if entry.container and entry.container.Remove then
            removed = safeCall(function() entry.container:Remove(entry.item); return true end, false) == true
        end
        if not removed and character and character.getInventory then
            local inv = safeCall(function() return character:getInventory() end, nil)
            if inv and inv.Remove then
                removed = safeCall(function() inv:Remove(entry.item); return true end, false) == true
            end
        end
        if not removed then return false, 0, total, "A selected filter could not be consumed.", nil end
    end
    return true, math.min(requested, total), total, nil, media
end

function M.getInstalled(vehicle)
    if not vehicle or not vehicle.getModData then return nil end
    local md = safeCall(function() return vehicle:getModData() end, nil)
    local up = md and md.gUpgrades and md.gUpgrades[M.UPGRADE_ID] or nil
    return type(up) == "table" and up or nil
end

function M.getGradeCapacity(grade)
    if GSVU4UpgradesConfig and GSVU4UpgradesConfig.getGradeConfig then
        local cfg = GSVU4UpgradesConfig.getGradeConfig(M.UPGRADE_ID, grade)
        if cfg then return tonumber(cfg.filterCapacityMax) or tonumber(cfg.capacity) or 0 end
    end
    local fallback = { Basic = 50, Standard = 75, Military = 100 }
    return fallback[tostring(grade or "")] or 0
end

function M.initialiseUpgradeState(newUpgrade, cfg, previous)
    if not newUpgrade then return end
    local maximum = tonumber(cfg and cfg.filterCapacityMax) or M.getGradeCapacity(newUpgrade.grade)
    maximum = math.max(0, math.floor(maximum + 0.5))
    newUpgrade.filterMaxCapacity = maximum
    newUpgrade.capacity = maximum
    if previous then
        local oldMax = tonumber(previous.filterMaxCapacity) or M.getGradeCapacity(previous.grade)
        local oldCurrent = tonumber(previous.filterCapacity)
        if oldCurrent == nil then oldCurrent = oldMax end
        local ratio = oldMax > 0 and math.max(0, math.min(1, oldCurrent / oldMax)) or 0
        newUpgrade.filterCapacity = math.floor((maximum * ratio) + 0.5)
        if type(previous.filterMedia) == "table" then M.setInstalledFilterMedia(newUpgrade, previous.filterMedia) end
    else
        newUpgrade.filterCapacity = maximum
    end
end

local function setReturnedFilterCapacity(item, itemType, remaining)
    local nominal = tonumber(M.FILTER_CAPACITY[itemType]) or math.max(0, tonumber(remaining) or 0)
    remaining = clamp(remaining, 0, nominal)

    if item and item.setItemCapacity then safeCall(function() item:setItemCapacity(remaining) end, nil) end
    local drainable = item and item.IsDrainable and safeCall(function() return item:IsDrainable() end, false) == true
    if drainable then
        local ratio = nominal > 0 and remaining / nominal or 0
        if item.setUsedDelta then safeCall(function() item:setUsedDelta(ratio) end, nil) end
        if item.setDelta then safeCall(function() item:setDelta(ratio) end, nil) end
    end

    local md = item and item.getModData and safeCall(function() return item:getModData() end, nil) or nil
    if md then
        md.GSVU4FilterCapacity = remaining
        md.GSVU4FilterCapacityMax = nominal
        md.GSVU4SpentFilter = remaining <= 0.001
    end
end

function M.returnInstalledFilterMedia(character, upgrade)
    if not character or not character.getInventory then return false, 0, 0, false, "Inventory unavailable." end
    if not upgrade then return false, 0, 0, false, "No Filtered Air Intake is installed." end
    if not M.hasRecordedFilterMedia(upgrade) then return true, 0, 0, true, nil end

    local inv = safeCall(function() return character:getInventory() end, nil)
    if not inv or not inv.AddItem then return false, 0, 0, false, "Inventory unavailable." end

    local maximum = tonumber(upgrade.filterMaxCapacity) or M.getGradeCapacity(upgrade.grade)
    local current = tonumber(upgrade.filterCapacity)
    if current == nil then current = maximum end
    local ratio = maximum > 0 and clamp(current / maximum, 0, 1) or 0
    local returnedCount, returnedCapacity = 0, 0

    for _, entry in ipairs(upgrade.filterMedia) do
        local ft = tostring(entry.fullType or "")
        local installed = math.max(0, tonumber(entry.installedCapacity) or 0)
        if ft ~= "" and installed > 0 then
            local remaining = installed * ratio
            local item = safeCall(function() return inv:AddItem(ft) end, nil)
            if not item then return false, returnedCount, returnedCapacity, false, "A worn filter could not be returned." end
            setReturnedFilterCapacity(item, ft, remaining)
            returnedCount = returnedCount + 1
            returnedCapacity = returnedCapacity + remaining
        end
    end

    return true, returnedCount, returnedCapacity, false, nil
end

function M.replaceFilterSetFromCharacter(character, vehicle)
    local upgrade = M.getInstalled(vehicle)
    if not upgrade then return false, 0, 0, "No Filtered Air Intake is installed." end
    local maximum = tonumber(upgrade.filterMaxCapacity) or M.getGradeCapacity(upgrade.grade)
    local current = tonumber(upgrade.filterCapacity)
    if current == nil then current = maximum end
    if current >= maximum - 0.001 then return false, 0, 0, "The installed filters are still full." end

    local selected = M.selectFilterItems(character, maximum)
    if not selected then return false, 0, 0, "A complete replacement filter set is required." end

    local ok, added, consumed, reason, newMedia = M.consumeFilterCapacity(character, maximum)
    if not ok then return false, 0, consumed or 0, reason end

    local returnedOk, returnedCount, returnedCapacity, legacy, returnedReason = M.returnInstalledFilterMedia(character, upgrade)
    if not returnedOk then return false, 0, consumed or 0, returnedReason end

    M.setInstalledFilterMedia(upgrade, newMedia)
    upgrade.filterMaxCapacity = maximum
    upgrade.filterCapacity = maximum
    upgrade.filterMediaLegacyMigrated = legacy == true
    return true, added, consumed, nil, returnedCount, returnedCapacity, legacy
end

-- Kept as an alias so older client commands cannot break an updated server.
M.rechargeFromCharacter = M.replaceFilterSetFromCharacter

local function partId(part)
    if not part or not part.getId then return "Unknown" end
    return tostring(safeCall(function() return part:getId() end, "Unknown") or "Unknown")
end

local function partLabel(part)
    local id = partId(part)
    local spaced = id:gsub("(%l)(%u)", "%1 %2"):gsub("_", " ")
    return spaced
end

local function itemConditionOk(part)
    if not part or not part.getInventoryItem then return false, "state unreadable" end
    local item = safeCall(function() return part:getInventoryItem() end, nil)
    if not item then return false, "missing" end
    local condition = item.getCondition and tonumber(safeCall(function() return item:getCondition() end, 0)) or 0
    if condition <= 0 then return false, "destroyed" end
    return true, nil
end

local function objectIsOpen(obj)
    if not obj or not obj.isOpen then return nil end
    local value = safeCall(function() return obj:isOpen() end, nil)
    if value == nil then return nil end
    return value == true
end

local function addUniquePart(list, seen, part)
    if not part or seen[part] then return end
    seen[part] = true
    list[#list + 1] = part
end

function M.checkCabinSeal(vehicle)
    local doors, windows, seenDoors, seenWindows = {}, {}, {}, {}
    if not vehicle then return { sealed = false, reason = "Vehicle unavailable.", breaches = {"Vehicle unavailable."} } end

    local supported, unsupportedReason = M.canInstallOnVehicle(vehicle)
    if not supported then
        return {
            sealed = false,
            reason = unsupportedReason,
            breaches = { unsupportedReason },
            openTop = true,
            doorCount = 0,
            windowCount = 0,
        }
    end

    -- Passenger-door APIs avoid treating the bonnet and cargo hatch as cabin doors.
    local passengerCount = 0
    if vehicle.getMaxPassengers then
        passengerCount = tonumber(safeCall(function() return vehicle:getMaxPassengers() end, 0)) or 0
    end
    for seat = 0, math.max(0, passengerCount - 1) do
        if vehicle.getPassengerDoor then addUniquePart(doors, seenDoors, safeCall(function() return vehicle:getPassengerDoor(seat) end, nil)) end
        if vehicle.getPassengerDoor2 then addUniquePart(doors, seenDoors, safeCall(function() return vehicle:getPassengerDoor2(seat) end, nil)) end
    end

    local useFallbackDoors = #doors == 0
    local count = vehicle.getPartCount and tonumber(safeCall(function() return vehicle:getPartCount() end, 0)) or 0
    for i = 0, math.max(0, count - 1) do
        local part = safeCall(function() return vehicle:getPartByIndex(i) end, nil)
        if part then
            local id = string.lower(partId(part))
            local doorObj = part.getDoor and safeCall(function() return part:getDoor() end, nil) or nil
            local windowObj = part.getWindow and safeCall(function() return part:getWindow() end, nil) or nil
            local isWindowPart = windowObj ~= nil or id:find("window", 1, true) ~= nil or id:find("windshield", 1, true) ~= nil
            if isWindowPart and not windowObj and part.findWindow then
                windowObj = safeCall(function() return part:findWindow() end, nil)
            end

            if useFallbackDoors and doorObj and id:find("door", 1, true)
            and not id:find("engine", 1, true) and not id:find("trunk", 1, true)
            and not id:find("hood", 1, true) and not id:find("bonnet", 1, true)
            then addUniquePart(doors, seenDoors, part) end

            if isWindowPart then
                addUniquePart(windows, seenWindows, part)
            end
        end
    end

    local breaches = {}
    for _, part in ipairs(doors) do
        local label = partLabel(part)
        local itemOk, why = itemConditionOk(part)
        if not itemOk then
            breaches[#breaches + 1] = label .. " is " .. tostring(why) .. "."
        else
            local doorObj = part.getDoor and safeCall(function() return part:getDoor() end, nil) or nil
            if not doorObj then
                breaches[#breaches + 1] = label .. " state cannot be verified."
            else
                local open = objectIsOpen(doorObj)
                if open == nil then breaches[#breaches + 1] = label .. " state cannot be verified."
                elseif open then breaches[#breaches + 1] = label .. " is open." end
            end
        end
    end

    for _, part in ipairs(windows) do
        local label = partLabel(part)
        local itemOk, why = itemConditionOk(part)
        if not itemOk then
            breaches[#breaches + 1] = label .. " is " .. tostring(why) .. "."
        else
            local windowObj = part.getWindow and safeCall(function() return part:getWindow() end, nil) or nil
            if not windowObj and part.findWindow then windowObj = safeCall(function() return part:findWindow() end, nil) end
            if windowObj and windowObj.isOpen then
                local open = objectIsOpen(windowObj)
                if open == nil then breaches[#breaches + 1] = label .. " state cannot be verified."
                elseif open then breaches[#breaches + 1] = label .. " is open." end
            end
        end
    end

    if #doors == 0 then breaches[#breaches + 1] = "No cabin doors could be verified." end
    if #windows == 0 then breaches[#breaches + 1] = "No cabin glass could be verified." end

    return {
        sealed = #breaches == 0,
        reason = breaches[1],
        breaches = breaches,
        doorCount = #doors,
        windowCount = #windows,
    }
end

function M.isEngineRunning(vehicle)
    if not vehicle or not vehicle.isEngineRunning then return false end
    return safeCall(function() return vehicle:isEngineRunning() end, false) == true
end

function M.getStatus(vehicle)
    local upgrade = M.getInstalled(vehicle)
    if not upgrade then
        return { installed = false, active = false, reason = "Filtered Air Intake not installed." }
    end
    local maximum = tonumber(upgrade.filterMaxCapacity) or M.getGradeCapacity(upgrade.grade)
    local current = tonumber(upgrade.filterCapacity)
    if current == nil then current = maximum end
    local health = tonumber(upgrade.health) or tonumber(upgrade.maxHealth) or 100
    local seal = M.checkCabinSeal(vehicle)
    local engine = M.isEngineRunning(vehicle)
    local active, reason = true, nil
    if health <= 0 then active, reason = false, "Filtered Air Intake is destroyed."
    elseif current <= 0 then active, reason = false, "Filter exhausted."
    elseif seal.openTop then active, reason = false, seal.reason or "Filtered Air Intake requires a fully enclosed cab."
    elseif not engine then active, reason = false, "Engine is not running."
    elseif not seal.sealed then active, reason = false, seal.reason or "Cabin seal breached." end
    return {
        installed = true,
        active = active,
        reason = reason,
        grade = upgrade.grade,
        capacity = math.max(0, current),
        maximum = math.max(0, maximum),
        health = health,
        engineRunning = engine,
        seal = seal,
    }
end
