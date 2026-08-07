require "VehicleArmor_Config"
--========================================================
-- VEHICLE ARMOR CONSUME HELPERS  (B42.19)
-- Client — required by all timed action files.
--
-- Provides shared helpers for:
--   • safe PZ Java-object null checks
--   • recipe material counting / validation
--   • recipe consumption
--   • B42 BlowTorch uses handling
--   • mod-owned fractional WeldingRods handling
--========================================================

VehicleArmorHelpers = VehicleArmorHelpers or {}

----------------------------------------------------------
-- Safe null check for PZ Java objects
----------------------------------------------------------
local function notNull(item)
    if item == nil then return false end
    if item.getType == nil then return false end
    return true
end

VehicleArmorHelpers.notNull = notNull

----------------------------------------------------------
-- findItem
-- Tries each full type string in order and returns the
-- first real item found, or nil.
----------------------------------------------------------
local function findItem(inv, ...)
    if not inv then return nil end

    for _, fullType in ipairs({...}) do
        local item = inv:FindAndReturn(fullType)
        if notNull(item) then return item end
    end

    return nil
end

VehicleArmorHelpers.findItem = findItem

----------------------------------------------------------
-- getItemFullType
----------------------------------------------------------
local function getItemFullType(item)
    if not item then return nil end

    if item.getFullType then
        local ok, ft = pcall(function()
            return item:getFullType()
        end)
        if ok and ft then return ft end
    end

    return nil
end


local function removeGroundItem(item)
    if not item then return false end

    if item.getWorldItem then
        local okWorld, worldItem = pcall(function()
            return item:getWorldItem()
        end)

        if okWorld and worldItem then
            local square = nil

            if worldItem.getSquare then
                local okSquare, foundSquare = pcall(function()
                    return worldItem:getSquare()
                end)
                if okSquare then square = foundSquare end
            end

            if square and square.transmitRemoveItemFromSquare then
                square:transmitRemoveItemFromSquare(worldItem)
                return true
            end

            if worldItem.removeFromWorld then
                worldItem:removeFromWorld()
                if worldItem.removeFromSquare then
                    worldItem:removeFromSquare()
                end
                return true
            end
        end
    end

    if item.removeFromWorld then
        item:removeFromWorld()
        if item.removeFromSquare then
            item:removeFromSquare()
        end
        return true
    end

    return false
end

----------------------------------------------------------
-- Accessible inventory scope
-- Includes main inventory, nested bags, and nearby containers.
----------------------------------------------------------
local function addInventory(list, seen, inv)
    if not inv then return end
    local key = tostring(inv)
    if seen[key] then return end

    seen[key] = true
    table.insert(list, inv)

    if not inv.getItems then return end

    local okItems, items = pcall(function()
        return inv:getItems()
    end)
    if not okItems or not items then return end

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and item.getInventory then
            local okInv, childInv = pcall(function()
                return item:getInventory()
            end)
            if okInv and childInv then
                addInventory(list, seen, childInv)
            end
        end
    end
end

local function addSquareContainers(list, seen, square)
    if not square or not square.getObjects then return end

    local okObjects, objects = pcall(function()
        return square:getObjects()
    end)
    if not okObjects or not objects then return end

    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        if obj and obj.getContainer then
            local okContainer, container = pcall(function()
                return obj:getContainer()
            end)
            if okContainer and container then
                addInventory(list, seen, container)
            end
        end
    end
end


local function addGroundItems(items, seen, square)
    if not square then return end

    local function addFromList(list)
        if not list then return end

        for i = 0, list:size() - 1 do
            local obj = list:get(i)
            local item = nil

            if obj then
                if obj.getItem then
                    local okItem, found = pcall(function()
                        return obj:getItem()
                    end)
                    if okItem then item = found end
                elseif obj.getType then
                    item = obj
                end
            end

            if item and item.getType then
                local key = tostring(item)
                if not seen[key] then
                    seen[key] = true
                    table.insert(items, item)
                end
            end
        end
    end

    if square.getWorldObjects then
        local okWorld, worldObjects = pcall(function()
            return square:getWorldObjects()
        end)
        if okWorld then addFromList(worldObjects) end
    end

    if square.getStaticMovingObjects then
        local okMoving, movingObjects = pcall(function()
            return square:getStaticMovingObjects()
        end)
        if okMoving then addFromList(movingObjects) end
    end
end

function VehicleArmorHelpers.getAccessibleInventories(character)
    local list = {}
    local seen = {}

    if not character then return list end

    if character.getInventory then
        local okInv, inv = pcall(function()
            return character:getInventory()
        end)
        if okInv and inv then
            addInventory(list, seen, inv)
        end
    end

    if character.getSquare and getCell then
        local okSquare, square = pcall(function()
            return character:getSquare()
        end)

        if okSquare and square then
            local z = square:getZ()
            local x = square:getX()
            local y = square:getY()

            for dx = -1, 1 do
                for dy = -1, 1 do
                    local near = getCell():getGridSquare(x + dx, y + dy, z)
                    addSquareContainers(list, seen, near)
                end
            end
        end
    end

    return list
end


function VehicleArmorHelpers.getAccessibleGroundItems(character)
    local items = {}
    local seen = {}

    if not character or not character.getSquare or not getCell then
        return items
    end

    local okSquare, square = pcall(function()
        return character:getSquare()
    end)

    if not okSquare or not square then
        return items
    end

    local z = square:getZ()
    local x = square:getX()
    local y = square:getY()

    for dx = -1, 1 do
        for dy = -1, 1 do
            local near = getCell():getGridSquare(x + dx, y + dy, z)
            addGroundItems(items, seen, near)
        end
    end

    return items
end

local function forEachAccessibleItem(character, fn)
    local snapshot = {}
    local inventories = VehicleArmorHelpers.getAccessibleInventories(character)

    -- Snapshot first. Some callbacks consume/remove items, which mutates
    -- the Java item list and can otherwise cause index errors.
    for _, inv in ipairs(inventories) do
        if inv and inv.getItems then
            local items = inv:getItems()
            if items then
                for i = 0, items:size() - 1 do
                    local item = items:get(i)
                    if item then
                        table.insert(snapshot, {item=item, inv=inv})
                    end
                end
            end
        end
    end

    if VehicleArmorHelpers.getAccessibleGroundItems then
        for _, item in ipairs(VehicleArmorHelpers.getAccessibleGroundItems(character)) do
            table.insert(snapshot, {item=item, inv=nil})
        end
    end

    for _, entry in ipairs(snapshot) do
        if entry and entry.item then
            fn(entry.item, entry.inv)
        end
    end
end

----------------------------------------------------------
-- Inventory material counting
----------------------------------------------------------
local SHEET_VALUES = {
    SheetMetal      = 1.00,
    SteelSheet      = 1.00,
    SmallSheetMetal = 0.25,
}

local BAR_VALUES = {
    MetalBar         = 1.00,
    SteelBar         = 1.00,
    IronBar          = 1.00,
    SteelBarHalf     = 0.50,
    IronBarHalf      = 0.50,
    SteelBarQuarter  = 0.25,
    IronBarQuarter   = 0.25,
}

----------------------------------------------------------
-- getRodAmount
-- WeldingRods use mod-owned fractional tracking.
-- Recipe rod values are fractions of one full rods item:
--   0.1 = 10% of one WeldingRods item
--   0.5 = 50% of one WeldingRods item
--   1.0 = one full WeldingRods item
----------------------------------------------------------
local function getRodAmount(item)
    if not item then return 0 end

    if item.getModData then
        local md = item:getModData()
        if md then
            if md.GAA_RodAmount == nil then
                md.GAA_RodAmount = 1.0
            end

            local amount = tonumber(md.GAA_RodAmount) or 0
            if amount > 0 then
                return amount
            end
        end
    end

    if item.getUsedDelta then
        local okDelta, delta = pcall(function()
            return item:getUsedDelta()
        end)

        if okDelta and delta and delta > 0 then
            return delta
        end
    end

    return 1.0
end

VehicleArmorHelpers.getRodAmount = getRodAmount

----------------------------------------------------------
-- setRodAmount
-- Writes remaining WeldingRods fraction. Removes the item
-- only when the tracked amount reaches zero.
----------------------------------------------------------
local function setRodAmount(inv, item, amount)
    if not inv or not item then return end

    local remaining = tonumber(amount) or 0

    if remaining > 0.0001 then
        if item.getModData then
            local md = item:getModData()
            if md then
                md.GAA_RodAmount = remaining
                return
            end
        end

        if item.setUsedDelta then
            local okSet = pcall(function()
                item:setUsedDelta(remaining)
            end)

            if okSet then return end
        end

        return
    end

    inv:Remove(item)
end

VehicleArmorHelpers.setRodAmount = setRodAmount

----------------------------------------------------------
-- countMaterials
-- Returns the same material fields used by recipe tables.
----------------------------------------------------------
function VehicleArmorHelpers.countMaterials(inv)
    local report = {
        scrap  = 0,
        sheets = 0,
        bars   = 0,
        screws = 0,
        wire   = 0,
        electricWire = 0,
        bulbs = 0,
        autoTuneMilitaryRadio = 0,
        rods   = 0,
    }

    if not inv then return report end

    local items = inv:getItems()
    if not items then return report end

    for i = 0, items:size() - 1 do
        local item = items:get(i)

        if item then
            local t  = item.getType and item:getType() or nil
            local ft = getItemFullType(item)

            if t == "ScrapMetal" then
                report.scrap = report.scrap + 1
            elseif t == "Screws" then
                report.screws = report.screws + 1
            elseif t == "Wire" or ft == "Base.Wire" then
                report.wire = report.wire + 1
            elseif t == "ElectricWire" or ft == "Base.ElectricWire" then
                report.electricWire = (report.electricWire or 0) + 1
            elseif t == "LightBulb" or ft == "Base.LightBulb" then
                report.bulbs = (report.bulbs or 0) + 1
            elseif t == "GSVU4AutoTuneMilitaryRadio" or ft == "Base.GSVU4AutoTuneMilitaryRadio" then
                report.autoTuneMilitaryRadio = (report.autoTuneMilitaryRadio or 0) + 1
            elseif t == "WeldingRods" or ft == "Base.WeldingRods" then
                report.rods = report.rods + getRodAmount(item)
            end

            if SHEET_VALUES[t] then
                report.sheets = report.sheets + SHEET_VALUES[t]
            end

            if BAR_VALUES[t] then
                report.bars = report.bars + BAR_VALUES[t]
            end
        end
    end

    return report
end


function VehicleArmorHelpers.countMaterialsForCharacter(character)
    local report = {
        scrap  = 0,
        sheets = 0,
        bars   = 0,
        screws = 0,
        wire   = 0,
        electricWire = 0,
        bulbs = 0,
        autoTuneMilitaryRadio = 0,
        rods   = 0,
    }

    forEachAccessibleItem(character, function(item)
        local t  = item.getType and item:getType() or nil
        local ft = getItemFullType(item)

        if t == "ScrapMetal" then
            report.scrap = report.scrap + 1
        elseif t == "Screws" then
            report.screws = report.screws + 1
        elseif t == "Wire" or ft == "Base.Wire" then
            report.wire = report.wire + 1
        elseif t == "ElectricWire" or ft == "Base.ElectricWire" then
            report.electricWire = (report.electricWire or 0) + 1
        elseif t == "LightBulb" or ft == "Base.LightBulb" then
            report.bulbs = (report.bulbs or 0) + 1
        elseif t == "GSVU4AutoTuneMilitaryRadio" or ft == "Base.GSVU4AutoTuneMilitaryRadio" then
            report.autoTuneMilitaryRadio = (report.autoTuneMilitaryRadio or 0) + 1
        elseif t == "WeldingRods" or ft == "Base.WeldingRods" then
            report.rods = report.rods + getRodAmount(item)
        end

        if SHEET_VALUES[t] then
            report.sheets = report.sheets + SHEET_VALUES[t]
        end

        if BAR_VALUES[t] then
            report.bars = report.bars + BAR_VALUES[t]
        end
    end)

    return report
end

----------------------------------------------------------
-- getAdjustedRecipe
-- Applies sandbox material-cost multiplier to install/repair
-- recipes. Uninstall returns are intentionally not scaled.
----------------------------------------------------------
function VehicleArmorHelpers.getAdjustedRecipe(recipe)
    if not recipe then return recipe end

    local mult = 1.0
    if VehicleArmorConfig and VehicleArmorConfig.getMaterialCostMultiplier then
        mult = VehicleArmorConfig.getMaterialCostMultiplier()
    end

    local adjusted = {}

    for mat, req in pairs(recipe) do
        local value = tonumber(req) or 0

        if value <= 0 then
            adjusted[mat] = 0
        elseif mat == "autoTuneMilitaryRadio" then
            adjusted[mat] = math.max(1, math.ceil(value))
        elseif mat == "rods" then
            adjusted[mat] = math.max(0.01, math.floor((value * mult * 100) + 0.5) / 100)
        else
            adjusted[mat] = math.max(1, math.ceil(value * mult))
        end
    end

    return adjusted
end

----------------------------------------------------------
-- hasRecipe
-- Checks whether the inventory currently has enough of
-- every material in a recipe table.
----------------------------------------------------------
function VehicleArmorHelpers.hasRecipe(inv, recipe)
    if not recipe then return true end

    local have = VehicleArmorHelpers.countMaterials(inv)
    local adjusted = VehicleArmorHelpers.getAdjustedRecipe(recipe)

    for mat, req in pairs(adjusted) do
        if (have[mat] or 0) + 0.0001 < (req or 0) then
            return false
        end
    end

    return true
end


function VehicleArmorHelpers.hasRecipeForCharacter(character, recipe)
    if not recipe then return true end

    local have = VehicleArmorHelpers.countMaterialsForCharacter(character)
    local adjusted = VehicleArmorHelpers.getAdjustedRecipe(recipe)

    for mat, req in pairs(adjusted) do
        if (have[mat] or 0) + 0.0001 < (req or 0) then
            return false
        end
    end

    return true
end


----------------------------------------------------------
-- isHammerItem
-- Accepts standard, forged, and modded hammer variants.
----------------------------------------------------------

function VehicleArmorHelpers.isScrewdriverItem(item)
    if not item then return false end
    local t  = item.getType and item:getType() or ""
    local ft = getItemFullType(item) or ""
    local lowT = string.lower(tostring(t))
    local lowFt = string.lower(tostring(ft))
    return lowT == "screwdriver"
        or lowFt == "base.screwdriver"
        or string.find(lowT, "screwdriver", 1, true) ~= nil
        or string.find(lowFt, "screwdriver", 1, true) ~= nil
end

function VehicleArmorHelpers.getInstallToolRequirements(grade)
    if tostring(grade or "") == "Scrap" then
        return { hammer = true, screwdriver = true, weldingMask = false, blowTorch = false }
    end
    return { hammer = true, screwdriver = false, weldingMask = true, blowTorch = true }
end

function VehicleArmorHelpers.isHammerItem(item)
    if not item then return false end

    local t  = item.getType and item:getType() or ""
    local ft = getItemFullType(item) or ""

    return t == "Hammer"
        or t == "BallPeenHammer"
        or ft == "Base.Hammer"
        or ft == "Base.BallPeenHammer"
        or string.find(t, "Hammer") ~= nil
        or string.find(ft, "Hammer") ~= nil
end

----------------------------------------------------------
-- hasRequiredTools
----------------------------------------------------------
function VehicleArmorHelpers.hasRequiredTools(inv)
    if not inv then return false end

    local hasMask = findItem(inv, "Base.WeldingMask") ~= nil
    local hasHammer = false

    local items = inv:getItems()
    if items then
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if VehicleArmorHelpers.isHammerItem(item) then
                hasHammer = true
                break
            end
        end
    end

    return hasMask and hasHammer
end


function VehicleArmorHelpers.hasRequiredToolsForCharacter(character, grade)
    local hasMask = false
    local hasHammer = false
    local hasScrewdriver = false
    local req = VehicleArmorHelpers.getInstallToolRequirements and VehicleArmorHelpers.getInstallToolRequirements(grade) or { hammer = true, weldingMask = true }

    forEachAccessibleItem(character, function(item)
        local ft = getItemFullType(item)
        local t  = item.getType and item:getType() or ""

        if t == "WeldingMask" or ft == "Base.WeldingMask" then
            hasMask = true
        end

        if VehicleArmorHelpers.isHammerItem(item) then
            hasHammer = true
        end

        if VehicleArmorHelpers.isScrewdriverItem and VehicleArmorHelpers.isScrewdriverItem(item) then
            hasScrewdriver = true
        end
    end)

    if req.hammer and not hasHammer then return false end
    if req.screwdriver and not hasScrewdriver then return false end
    if req.weldingMask and not hasMask then return false end
    return true
end


----------------------------------------------------------
-- B42 BlowTorch helpers
----------------------------------------------------------
function VehicleArmorHelpers.getTorchFuel(item)
    if not item then return 0 end
    if not item.getCurrentUses then return 0 end

    local ok, uses = pcall(function()
        return item:getCurrentUses()
    end)

    if ok and uses and uses > 0 then
        return uses
    end

    return 0
end

function VehicleArmorHelpers.findTorch(character)
    if not character then return nil end

    local best, bestAmt = nil, 0

    forEachAccessibleItem(character, function(item)
        local t  = item.getType and item:getType() or nil
        local ft = getItemFullType(item)

        if t == "BlowTorch" or ft == "Base.BlowTorch" then
            local amt = VehicleArmorHelpers.getTorchFuel(item)
            if amt > bestAmt then
                best    = item
                bestAmt = amt
            end
        end
    end)

    return best
end


function VehicleArmorHelpers.getTotalTorchFuel(character)
    if not character then return 0 end
    local total = 0
    forEachAccessibleItem(character, function(item)
        local t  = item.getType and item:getType() or nil
        local ft = getItemFullType(item)
        if t == "BlowTorch" or ft == "Base.BlowTorch" then
            total = total + (VehicleArmorHelpers.getTorchFuel(item) or 0)
        end
    end)
    return total
end

function VehicleArmorHelpers.consumeTorchFuelFromCharacter(character, amount)
    local remaining = tonumber(amount) or 0
    if not character or remaining <= 0 then return 0 end
    local consumed = 0

    while remaining > 0.0001 do
        local torch = VehicleArmorHelpers.findTorch(character)
        if not torch or (VehicleArmorHelpers.getTorchFuel(torch) or 0) <= 0 then
            break
        end
        VehicleArmorHelpers.consumeTorchFuel(torch, 1)
        remaining = remaining - 1
        consumed = consumed + 1
    end

    return consumed
end

function VehicleArmorHelpers.consumeTorchFuel(item, amount)
    if not item then return end
    if not item.Use then return end

    local useCount = math.floor((amount or 0) + 0.5)
    if useCount <= 0 then return end

    for _ = 1, useCount do
        if VehicleArmorHelpers.getTorchFuel(item) <= 0 then
            break
        end

        item:Use()
    end
end

----------------------------------------------------------
-- consumeSheets
-- Consumes 'needed' full-sheet equivalents.
--   Base.SheetMetal / Base.SteelSheet  = 1.0 each
--   Base.SmallSheetMetal               = 0.25 each
----------------------------------------------------------
function VehicleArmorHelpers.consumeSheets(inv, needed)
    local remaining = tonumber(needed) or 0

    while remaining > 0.0001 do
        local full = findItem(inv, "Base.SheetMetal", "Base.SteelSheet")
        if full then
            inv:Remove(full)
            remaining = remaining - 1
        else
            local small = findItem(inv, "Base.SmallSheetMetal")
            if small then
                inv:Remove(small)
                remaining = remaining - 0.25
            else
                break
            end
        end
    end
end

----------------------------------------------------------
-- consumeBars
-- Consumes 'needed' full-bar equivalents.
--   Base.MetalBar / Base.SteelBar / Base.IronBar = 1.0
--   Base.SteelBarHalf / Base.IronBarHalf         = 0.5
--   Base.SteelBarQuarter / Base.IronBarQuarter   = 0.25
----------------------------------------------------------
function VehicleArmorHelpers.consumeBars(inv, needed)
    local remaining = tonumber(needed) or 0

    while remaining > 0.0001 do
        local full = findItem(inv,
            "Base.MetalBar", "Base.SteelBar", "Base.IronBar")
        if full then
            inv:Remove(full)
            remaining = remaining - 1
        else
            local half = findItem(inv,
                "Base.SteelBarHalf", "Base.IronBarHalf")
            if half then
                inv:Remove(half)
                remaining = remaining - 0.5
            else
                local qtr = findItem(inv,
                    "Base.SteelBarQuarter", "Base.IronBarQuarter")
                if qtr then
                    inv:Remove(qtr)
                    remaining = remaining - 0.25
                else
                    break
                end
            end
        end
    end
end

----------------------------------------------------------
-- consumeWhole
-- Consumes whole items only. Fractional whole-item recipe
-- values are rounded up so validation and consumption stay
-- conservative if config is accidentally fractional.
----------------------------------------------------------
function VehicleArmorHelpers.consumeWhole(inv, fullType, needed)
    local remaining = math.ceil(tonumber(needed) or 0)

    while remaining > 0 do
        local item = inv:FindAndReturn(fullType)
        if not notNull(item) then break end

        inv:Remove(item)
        remaining = remaining - 1
    end
end

----------------------------------------------------------
-- consumeRods
-- Consumes a fractional amount of Base.WeldingRods.
----------------------------------------------------------
function VehicleArmorHelpers.consumeRods(inv, needed)
    local remaining = tonumber(needed) or 0
    if remaining <= 0 then return end

    while remaining > 0.0001 do
        local rods = findItem(inv, "Base.WeldingRods")
        if not rods then break end

        local available = getRodAmount(rods)

        if available <= 0.0001 then
            inv:Remove(rods)
        else
            local take = math.min(available, remaining)
            local newAmount = available - take

            setRodAmount(inv, rods, newAmount)
            remaining = remaining - take
        end
    end
end

----------------------------------------------------------
-- consumeRecipe
-- Iterates a recipe table and calls the right consume
-- function for each material key.
-- Keys: scrap, sheets, bars, screws, wire, rods
----------------------------------------------------------
function VehicleArmorHelpers.consumeRecipe(inv, recipe)
    if not inv or not recipe then return end

    local adjusted = VehicleArmorHelpers.getAdjustedRecipe(recipe)

    for mat, req in pairs(adjusted) do
        if mat == "rods" then
            VehicleArmorHelpers.consumeRods(inv, req)
        elseif mat == "sheets" then
            VehicleArmorHelpers.consumeSheets(inv, req)
        elseif mat == "bars" then
            VehicleArmorHelpers.consumeBars(inv, req)
        elseif mat == "scrap" then
            VehicleArmorHelpers.consumeWhole(inv, "Base.ScrapMetal", req)
        elseif mat == "screws" then
            VehicleArmorHelpers.consumeWhole(inv, "Base.Screws", req)
        elseif mat == "wire" then
            VehicleArmorHelpers.consumeWhole(inv, "Base.Wire", req)
        elseif mat == "electricWire" then
            VehicleArmorHelpers.consumeWhole(inv, "Base.ElectricWire", req)
        elseif mat == "bulbs" then
            VehicleArmorHelpers.consumeWhole(inv, "Base.LightBulb", req)
        elseif mat == "autoTuneMilitaryRadio" then
            VehicleArmorHelpers.consumeWhole(inv, "Base.GSVU4AutoTuneMilitaryRadio", req)
        end
    end
end


-- The ground-capable resource consumer below is authoritative.

local function consumeGroundCapableWhole(character, fullType, needed)
    local remaining = math.ceil(tonumber(needed) or 0)

    forEachAccessibleItem(character, function(item, inv)
        if remaining <= 0 then return end

        local ft = getItemFullType(item)
        if ft == fullType then
            if inv then inv:Remove(item) else removeGroundItem(item) end
            remaining = remaining - 1
        end
    end)
end

local function consumeGroundCapableRods(character, needed)
    local remaining = tonumber(needed) or 0

    forEachAccessibleItem(character, function(item, inv)
        if remaining <= 0.0001 then return end

        local t = item.getType and item:getType() or nil
        local ft = getItemFullType(item)

        if t == "WeldingRods" or ft == "Base.WeldingRods" then
            local available = getRodAmount(item)
            local take = math.min(available, remaining)
            local left = available - take

            if left > 0.0001 then
                local md = item.getModData and item:getModData() or nil
                if md then md.GAA_RodAmount = left end
            else
                if inv then inv:Remove(item) else removeGroundItem(item) end
            end

            remaining = remaining - take
        end
    end)
end

local function consumeGroundCapableSheets(character, needed)
    local remaining = tonumber(needed) or 0

    forEachAccessibleItem(character, function(item, inv)
        if remaining <= 0.0001 then return end

        local t = item.getType and item:getType() or nil
        local value = SHEET_VALUES[t]

        if value then
            if inv then inv:Remove(item) else removeGroundItem(item) end
            remaining = remaining - value
        end
    end)
end

local function consumeGroundCapableBars(character, needed)
    local remaining = tonumber(needed) or 0

    forEachAccessibleItem(character, function(item, inv)
        if remaining <= 0.0001 then return end

        local t = item.getType and item:getType() or nil
        local value = BAR_VALUES[t]

        if value then
            if inv then inv:Remove(item) else removeGroundItem(item) end
            remaining = remaining - value
        end
    end)
end

function VehicleArmorHelpers.consumeRecipeForCharacter(character, recipe)
    if not character or not recipe then return end

    local adjusted = VehicleArmorHelpers.getAdjustedRecipe(recipe)

    for mat, req in pairs(adjusted) do
        if mat == "rods" then
            consumeGroundCapableRods(character, req)
        elseif mat == "sheets" then
            consumeGroundCapableSheets(character, req)
        elseif mat == "bars" then
            consumeGroundCapableBars(character, req)
        elseif mat == "scrap" then
            consumeGroundCapableWhole(character, "Base.ScrapMetal", req)
        elseif mat == "screws" then
            consumeGroundCapableWhole(character, "Base.Screws", req)
        elseif mat == "wire" then
            consumeGroundCapableWhole(character, "Base.Wire", req)
        elseif mat == "electricWire" then
            consumeGroundCapableWhole(character, "Base.ElectricWire", req)
        elseif mat == "bulbs" then
            consumeGroundCapableWhole(character, "Base.LightBulb", req)
        elseif mat == "autoTuneMilitaryRadio" then
            consumeGroundCapableWhole(character, "Base.GSVU4AutoTuneMilitaryRadio", req)
        end
    end
end

----------------------------------------------------------
-- getPerkLevel
----------------------------------------------------------
function VehicleArmorHelpers.getPerkLevel(character, perk)
    if not character or not perk then return 0 end
    if not character.getPerkLevel then return 0 end

    local ok, level = pcall(function()
        return character:getPerkLevel(perk)
    end)

    if ok and level then
        return level
    end

    return 0
end

----------------------------------------------------------
-- getSkillRequirementReport
----------------------------------------------------------
function VehicleArmorHelpers.getSkillRequirementReport(character, grade)
    if VehicleArmorConfig
    and VehicleArmorConfig.areSkillRequirementsEnabled
    and not VehicleArmorConfig.areSkillRequirementsEnabled()
    then
        return {
            metalRequired = 0,
            mechRequired  = 0,
            metalLevel    = 0,
            mechLevel     = 0,
            hasSkills     = true,
        }
    end

    local reqs = VehicleArmorConfig.LevelRequirements
        and VehicleArmorConfig.LevelRequirements[grade]

    local report = {
        metalRequired = 0,
        mechRequired  = 0,
        metalLevel    = 0,
        mechLevel     = 0,
        hasSkills     = true,
    }

    if not reqs then
        return report
    end

    report.metalRequired = reqs.MetalWelding or 0
    report.mechRequired  = reqs.Mechanics or 0

    if Perks and Perks.MetalWelding then
        report.metalLevel = VehicleArmorHelpers.getPerkLevel(character, Perks.MetalWelding)
    end

    if Perks and Perks.Mechanics then
        report.mechLevel = VehicleArmorHelpers.getPerkLevel(character, Perks.Mechanics)
    end

    if report.metalLevel < report.metalRequired then
        report.hasSkills = false
    end

    if report.mechLevel < report.mechRequired then
        report.hasSkills = false
    end

    return report
end

----------------------------------------------------------
-- hasSkillRequirements
----------------------------------------------------------
function VehicleArmorHelpers.hasSkillRequirements(character, grade)
    local report = VehicleArmorHelpers.getSkillRequirementReport(character, grade)
    return report.hasSkills == true
end
