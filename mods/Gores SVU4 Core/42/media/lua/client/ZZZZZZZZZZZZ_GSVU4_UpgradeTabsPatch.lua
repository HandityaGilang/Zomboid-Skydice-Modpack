--========================================================
-- Gore's SVU4 Core - Armor / Upgrades / External Storage UI Tabs
--========================================================

require "VehicleArmor_UI"
require "GoresSVU4Core/GSVU4_Upgrades_Config"
require "GoresSVU4Core/GSVU4_FilteredAirIntake"
require "GoresSVU4Core/GSVU4_EngineScoop"
pcall(require, "GoresSVU4TyreChains/GSVU4_TyreChains_Config")
pcall(require, "GSVU4_TyreChains_TimedActions")
pcall(require, "GSVU4_TyreChains_ContextMenu")
require "TimedActions/ISInstallVehicleUpgrade"
require "TimedActions/ISUninstallVehicleUpgrade"
require "TimedActions/ISTimedActionQueue"
require "VehicleArmor_ConsumeHelpers"

local PREFIX = "[Gore's SVU4 Core Upgrades] "

local function getTextH(font)
    if getTextManager and UIFont then
        local ok, h = pcall(function() return getTextManager():getFontHeight(font or UIFont.Small) end)
        if ok and h then return tonumber(h) or 14 end
    end
    return 14
end

local function setVisible(ctrl, visible)
    if ctrl and ctrl.setVisible then ctrl:setVisible(visible == true) end
end

local function getInstalledRoofRack(vehicle)
    return GSVU4UpgradesConfig.getInstalledUpgrade(vehicle, "RoofRack")
end

local function getPerkLevel(character, perk)
    if not character or not perk or not character.getPerkLevel then return 0 end
    local ok, value = pcall(function() return character:getPerkLevel(perk) end)
    if ok and value then return tonumber(value) or 0 end
    return 0
end

local function hasSkills(character, cfg)
    local mwNeed = cfg and cfg.skills and cfg.skills.MetalWelding or 0
    local meNeed = cfg and cfg.skills and cfg.skills.Mechanics or 0
    local elNeed = cfg and cfg.skills and cfg.skills.Electricity or 0
    local mw = Perks and Perks.MetalWelding and getPerkLevel(character, Perks.MetalWelding) or 0
    local me = Perks and Perks.Mechanics and getPerkLevel(character, Perks.Mechanics) or 0
    local el = Perks and Perks.Electricity and getPerkLevel(character, Perks.Electricity) or 0
    return mw >= mwNeed and me >= meNeed and el >= elNeed, mw, me, mwNeed, meNeed, el, elNeed
end

local function getItemFullTypeSafe(item)
    if not item then return "" end
    if item.getFullType then
        local ok, value = pcall(function() return item:getFullType() end)
        if ok and value then return tostring(value) end
    end
    if item.getModule and item.getType then
        local ok, module, typ = pcall(function() return item:getModule(), item:getType() end)
        if ok and module and typ then return tostring(module) .. "." .. tostring(typ) end
    end
    return ""
end

local function isScrewdriverItem(item)
    if not item then return false end
    local t  = item.getType and tostring(item:getType()) or ""
    local ft = getItemFullTypeSafe(item)
    local lowT = string.lower(t)
    local lowFt = string.lower(ft)
    return lowT == "screwdriver"
        or lowFt == "base.screwdriver"
        or string.find(lowT, "screwdriver", 1, true) ~= nil
        or string.find(lowFt, "screwdriver", 1, true) ~= nil
end

local function isHammerItemLocal(item)
    if VehicleArmorHelpers and VehicleArmorHelpers.isHammerItem and VehicleArmorHelpers.isHammerItem(item) then
        return true
    end
    local t  = item and item.getType and tostring(item:getType()) or ""
    local ft = getItemFullTypeSafe(item)
    return t == "Hammer"
        or t == "BallPeenHammer"
        or ft == "Base.Hammer"
        or ft == "Base.BallPeenHammer"
        or string.find(t, "Hammer") ~= nil
        or string.find(ft, "Hammer") ~= nil
end

local function scanInventoryRecursive(inv, callback, seen)
    if not inv or not callback then return end
    seen = seen or {}
    if seen[inv] then return end
    seen[inv] = true

    local items = inv.getItems and inv:getItems() or nil
    if not items then return end

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item then
            callback(item)
            if item.getInventory then
                local ok, childInv = pcall(function() return item:getInventory() end)
                if ok and childInv then scanInventoryRecursive(childInv, callback, seen) end
            end
        end
    end
end

local function forEachAccessibleUpgradeItem(character, callback)
    if not character or not callback then return end

    if character.getInventory then
        local ok, inv = pcall(function() return character:getInventory() end)
        if ok and inv then scanInventoryRecursive(inv, callback) end
    end

    if character.getSquare then
        local okSq, square = pcall(function() return character:getSquare() end)
        if okSq and square and square.getObjects then
            local objects = square:getObjects()
            if objects then
                for i = 0, objects:size() - 1 do
                    local obj = objects:get(i)
                    if obj and obj.getContainer then
                        local okC, container = pcall(function() return obj:getContainer() end)
                        if okC and container then scanInventoryRecursive(container, callback) end
                    end
                end
            end
        end
    end
end

local function getUpgradeToolReport(character, upgradeId)
    local report = {
        mask = false,
        blowTorch = false,
        hammer = false,
        screwdriver = false,
    }

    if not character then return report end

    local totalFuel = VehicleArmorHelpers and VehicleArmorHelpers.getTotalTorchFuel
        and VehicleArmorHelpers.getTotalTorchFuel(character) or 0
    report.blowTorch = totalFuel > 0

    forEachAccessibleUpgradeItem(character, function(item)
        local ft = getItemFullTypeSafe(item)
        local t  = item.getType and tostring(item:getType()) or ""

        if t == "WeldingMask" or ft == "Base.WeldingMask" then report.mask = true end
        if isHammerItemLocal(item) then report.hammer = true end
        if isScrewdriverItem(item) then report.screwdriver = true end
    end)

    return report
end

local function hasUpgradeTools(character, upgradeId, grade)
    local tools = getUpgradeToolReport(character, upgradeId)
    local upgDef = GSVU4UpgradesConfig and GSVU4UpgradesConfig.getUpgrade and GSVU4UpgradesConfig.getUpgrade(upgradeId) or nil
    local cfg = GSVU4UpgradesConfig and GSVU4UpgradesConfig.getGradeConfig and GSVU4UpgradesConfig.getGradeConfig(upgradeId, grade) or nil
    local req = (cfg and cfg.tools) or (upgDef and upgDef.tools) or { weldingMask = true, blowTorch = true, hammer = true, screwdriver = true }
    if req.weldingMask and not tools.mask then return false, tools end
    if req.blowTorch and not tools.blowTorch then return false, tools end
    if req.hammer and not tools.hammer then return false, tools end
    if req.screwdriver and not tools.screwdriver then return false, tools end
    return true, tools
end

local function drawRequirementLine(window, label, ok, text, x, y)
    local r, g, b = 0.95, 0.35, 0.25
    if ok then r, g, b = 0.25, 0.85, 0.25 end
    local prefix = ""
    if label and label ~= "" then prefix = label .. ": " end
    window:drawText(prefix .. text, x, y, r, g, b, 1, UIFont.Small)
end

local function drawToolRequirementLine(window, ok, text, x, y)
    local r, g, b = 0.95, 0.35, 0.25
    if ok then r, g, b = 0.25, 0.85, 0.25 end
    local prefix = ok and "[OK] " or "[-] "
    window:drawText(prefix .. text, x, y, r, g, b, 1, UIFont.Small)
end

local function formatOneDecimal(value)
    return string.format("%.1f", tonumber(value) or 0)
end

local function recipeText(recipe)
    if not recipe then return "None" end
    local labels = {scrap="Scrap", sheets="Sheets", bars="Bars", screws="Screws", electricWire="Electrical Wire", wire="Wire", bulbs="Light Bulbs", rods="Welding Rods", autoTuneMilitaryRadio="Auto Tune Military Radio", heavyChain="Heavy Chain", ductTape="Duct Tape"}
    local order = {"autoTuneMilitaryRadio","heavyChain","sheets","bars","screws","electricWire","wire","ductTape","bulbs","rods","scrap"}
    local bits = {}
    for _, key in ipairs(order) do
        local value = recipe[key]
        if value and value > 0 then bits[#bits + 1] = tostring(labels[key] or key) .. ": " .. tostring(value) end
    end
    return #bits > 0 and table.concat(bits, ", ") or "None"
end

local function recipeLines(recipe)
    local labels = {scrap="Scrap Metal", sheets="Sheets", bars="Bars", screws="Screws", electricWire="Electrical Wire", wire="Wire", bulbs="Light Bulbs", rods="Welding Rods", autoTuneMilitaryRadio="Auto Tune Military Radio", heavyChain="Heavy Chain", ductTape="Duct Tape"}
    local order = {"autoTuneMilitaryRadio","heavyChain","sheets","bars","screws","electricWire","wire","ductTape","bulbs","rods","scrap"}
    local lines = {}

    if not recipe then return lines end

    for _, key in ipairs(order) do
        local value = recipe[key]
        if value and value > 0 then
            lines[#lines + 1] = {
                key = key,
                label = labels[key] or tostring(key),
                amount = value,
            }
        end
    end

    return lines
end

local function getReportMaterialAmount(report, key)
    if not report or not key then return 0 end
    return tonumber(report[key]) or 0
end

local function installedRoofRackLabel(current)
    if not current or not current.grade then return nil end
    return tostring(current.grade) .. " Roof Rack Installed"
end

local function getInstalledUpgradeHealth(upgrade)
    if not upgrade then return 0 end
    return tonumber(upgrade.health or upgrade.condition) or 100
end

local function getInstalledUpgradeMaxHealth(upgradeId, upgrade)
    if not upgrade then return 100 end
    local cfg = GSVU4UpgradesConfig.getGradeConfig(upgradeId, upgrade.grade)
    return tonumber(upgrade.maxHealth) or tonumber(cfg and cfg.health) or 100
end

local function getTyreChainsInstalledForUI(vehicle)
    if not GSVU4_TyreChains or not vehicle then return nil end
    local data = GSVU4_TyreChains.getData and GSVU4_TyreChains.getData(vehicle) or nil
    if data and data.installed == true and (tonumber(data.condition) or 0) > 0 then
        return { grade = "Standard", installed = true, condition = tonumber(data.condition) or 0, health = tonumber(data.condition) or 0 }
    end
    return nil
end

local function getInstalledUpgradeForUI(vehicle, upgradeId)
    if upgradeId == "TyreChains" then
        return getTyreChainsInstalledForUI(vehicle) or (GSVU4UpgradesConfig.getInstalledUpgrade and GSVU4UpgradesConfig.getInstalledUpgrade(vehicle, upgradeId) or nil)
    end
    return GSVU4UpgradesConfig.getInstalledUpgrade and GSVU4UpgradesConfig.getInstalledUpgrade(vehicle, upgradeId) or nil
end

local function getUpgradeReturnText(upgradeId, grade, health)
    local cfg = GSVU4UpgradesConfig.getGradeConfig(upgradeId, grade)
    if not cfg then return "Unknown" end
    local recipe = cfg.recipe or {}
    local hp = tonumber(health) or 0
    local maxHealth = tonumber(cfg.health) or 100
    local hpPercent = maxHealth > 0 and (hp / maxHealth) * 100 or 0

    if upgradeId == "TyreChains" then
        local fraction = hp > 50 and 0.75 or 0.25
        local heavyChain = math.floor(4 * fraction + 0.0001)
        local wire = math.floor(4 * fraction + 0.0001)
        local screws = math.floor(16 * fraction + 0.0001)
        local bits = {}
        if heavyChain > 0 then bits[#bits + 1] = "Heavy Chain: " .. tostring(heavyChain) end
        if wire > 0 then bits[#bits + 1] = "Wire: " .. tostring(wire) end
        if screws > 0 then bits[#bits + 1] = "Screws: " .. tostring(screws) end
        return #bits > 0 and table.concat(bits, ", ") or "None"
    end

    if hpPercent < 50 then
        return "Scrap Metal: 2"
    end

    local bits = {}
    local labels = {scrap="Scrap Metal", sheets="Sheets", bars="Bars", screws="Screws", electricWire="Electrical Wire", wire="Wire", bulbs="Light Bulbs", rods="Welding Rods", autoTuneMilitaryRadio="Auto Tune Military Radio", heavyChain="Heavy Chain", ductTape="Duct Tape"}
    local order = {"autoTuneMilitaryRadio","heavyChain","sheets","bars","screws","electricWire","wire","ductTape","bulbs","rods","scrap"}
    for _, key in ipairs(order) do
        local v = tonumber(recipe[key]) or 0
        if v > 0 then
            local ret = math.floor(v * 0.5)
            if key == "autoTuneMilitaryRadio" then ret = math.floor(v) end
            if key == "rods" then ret = 0 end
            if ret > 0 then bits[#bits + 1] = (labels[key] or key) .. ": " .. tostring(ret) end
        end
    end
    if #bits == 0 then return "Scrap Metal: 2" end
    return table.concat(bits, ", ")
end

local function getRoofRackStorage(vehicle)
    local vdata = vehicle and vehicle.getModData and vehicle:getModData() or nil
    local ext = vdata and vdata.gExternalStorage or nil
    return ext and ext.RoofRack or nil
end

local function getRoofRackUsed(vehicle)
    local storage = getRoofRackStorage(vehicle)
    if not storage then return 0 end
    if storage.used ~= nil then return tonumber(storage.used) or 0 end
    local used = 0
    for _, entry in ipairs(storage.items or {}) do used = used + (tonumber(entry.weight) or 0) end
    storage.used = used
    return used
end

local function getSelectedListItemData(list)
    if not list or not list.selected or list.selected <= 0 then return nil end
    local row = list.items and list.items[list.selected] or nil
    return row and row.item or nil
end

local function addVehicleCommandArgs(args, vehicle)
    args = args or {}
    if vehicle then
        if vehicle.getId then local ok, value = pcall(function() return vehicle:getId() end); if ok and value ~= nil then args.vehicleId = tonumber(value) or tostring(value) end end
        if vehicle.getOnlineID then local ok, value = pcall(function() return vehicle:getOnlineID() end); if ok and value ~= nil then args.vehicleOnlineId = tonumber(value) or tostring(value) end end
        if vehicle.getX then local ok, value = pcall(function() return vehicle:getX() end); if ok and value ~= nil then args.vehicleX = tonumber(value) end end
        if vehicle.getY then local ok, value = pcall(function() return vehicle:getY() end); if ok and value ~= nil then args.vehicleY = tonumber(value) end end
        if vehicle.getZ then local ok, value = pcall(function() return vehicle:getZ() end); if ok and value ~= nil then args.vehicleZ = tonumber(value) end end
    end
    return args
end

local function sendRoofRackCommand(command, window, args)
    if not sendClientCommand or not window or not window.vehicle then return false end
    args = addVehicleCommandArgs(args or {}, window.vehicle)
    sendClientCommand("GoresSVU4Core", command, args)
    return true
end

local function formatWeight2(value)
    return string.format("%.2f", tonumber(value) or 0)
end

local function getItemFullTypeForStack(item)
    if not item then return "" end
    if item.getFullType then
        local ok, value = pcall(function() return item:getFullType() end)
        if ok and value then return tostring(value) end
    end
    if item.getModule and item.getType then
        local ok, module, typ = pcall(function() return item:getModule(), item:getType() end)
        if ok and module and typ then return tostring(module) .. "." .. tostring(typ) end
    end
    if item.getType then
        local ok, typ = pcall(function() return item:getType() end)
        if ok and typ then return tostring(typ) end
    end
    return ""
end

local function getItemCategoryForStack(item)
    if not item then return "" end

    if type(item) == "table" and item.category then
        return tostring(item.category)
    end

    if item.getDisplayCategory then
        local ok, value = pcall(function() return item:getDisplayCategory() end)
        if ok and value then return tostring(value) end
    end

    if item.getCategory then
        local ok, value = pcall(function() return item:getCategory() end)
        if ok and value then return tostring(value) end
    end

    return ""
end

local function stackLabel(baseLabel, count)
    count = tonumber(count) or 1
    if count > 1 then return tostring(baseLabel) .. " (x" .. tostring(count) .. ")" end
    return tostring(baseLabel)
end

local function isClientEquippedOrWornItem(character, item)
    if not character or not item then return false end

    if item.isEquipped then
        local ok, value = pcall(function() return item:isEquipped() end)
        if ok and value == true then return true end
    end

    if character.getPrimaryHandItem then
        local ok, value = pcall(function() return character:getPrimaryHandItem() end)
        if ok and value == item then return true end
    end

    if character.getSecondaryHandItem then
        local ok, value = pcall(function() return character:getSecondaryHandItem() end)
        if ok and value == item then return true end
    end

    if character.getClothingItem_Back then
        local ok, value = pcall(function() return character:getClothingItem_Back() end)
        if ok and value == item then return true end
    end

    if character.getWornItems then
        local ok, worn = pcall(function() return character:getWornItems() end)
        if ok and worn then
            local size = 0
            if worn.size then size = worn:size()
            elseif worn.getSize then size = worn:getSize() end

            for i = 0, size - 1 do
                local wi = worn.get and worn:get(i) or nil
                if wi then
                    local okItem, wornItem = pcall(function()
                        if wi.getItem then return wi:getItem() end
                        return nil
                    end)
                    if okItem and wornItem == item then return true end
                end
            end
        end
    end

    return false
end

local function getListSelectedText(list)
    if not list or not list.selected or list.selected <= 0 then return nil end
    local row = list.items and list.items[list.selected] or nil
    return row and row.text or nil
end

local function restoreListSelectionByText(list, selectedText)
    if not list or not selectedText or not list.items then return end
    for i, row in ipairs(list.items) do
        if row and row.text == selectedText then
            list.selected = i
            return
        end
    end
end

local function clearList(list)
    if list and list.clear then list:clear() end
end

local function getItemWeight(item)
    -- For fluid containers the total weight = empty weight + fluid weight.
    -- item:getWeight() in B42 returns the total (container + contents), which
    -- matches what the vanilla inventory shows.  We just need to call it safely.
    if not item then return 0 end
    if item.getWeight then
        local ok, w = pcall(function() return item:getWeight() end)
        if ok and w then return tonumber(w) or 0 end
    end
    return 0
end

local function getItemDisplayName(item)
    if not item then return "?" end
    if item.getDisplayName then
        local ok, n = pcall(function() return item:getDisplayName() end)
        if ok and n and tostring(n) ~= "" then return tostring(n) end
    end
    if item.getName then
        local ok, n = pcall(function() return item:getName() end)
        if ok and n and tostring(n) ~= "" then return tostring(n) end
    end
    if item.getType then
        local ok, t = pcall(function() return item:getType() end)
        if ok and t then return tostring(t) end
    end
    return "Item"
end

local function addInventoryToList(list, inv, prefix, character)
    if not list or not inv then return end
    if not inv.getItems then return end

    prefix = prefix or ""

    local okItems, items = pcall(function() return inv:getItems() end)
    if not okItems or not items then return end

    local order  = {}
    local groups = {}

    for i = 0, items:size() - 1 do
        local ok, item = pcall(function() return items:get(i) end)
        if ok and item then
            -- Only check equipped status when we have a character (player inv).
            -- For trunk containers the character check would always be false anyway,
            -- but skipping it avoids any pcall overhead on trunk items.
            local equipped = false
            if character then
                equipped = isClientEquippedOrWornItem(character, item) == true
            end

            local fullType = getItemFullTypeForStack(item)
            local category = getItemCategoryForStack(item)
            local weight   = getItemWeight(item)

            -- Use fullType+category+equipped as stack key.
            -- Weight is intentionally NOT part of the key so that partially-filled
            -- fluid containers of the same type still stack in the display list.
            local key = tostring(fullType) .. "|" .. tostring(category) .. "|" .. tostring(equipped)

            if not groups[key] then
                groups[key] = {
                    item      = item,
                    label     = getItemDisplayName(item),
                    category  = category,
                    equipped  = equipped,
                    count     = 0,
                    totalWeight = 0,
                }
                order[#order + 1] = key
            end

            groups[key].count       = groups[key].count + 1
            groups[key].totalWeight = groups[key].totalWeight + weight
        end
    end

    for _, key in ipairs(order) do
        local group = groups[key]
        local label = stackLabel(group.label, group.count)
        if group.equipped then label = tostring(label) .. " (e)" end
        list:addItem(prefix .. tostring(label), {
            item     = group.item,
            category = group.category,
            weight   = group.totalWeight,
        })
    end
end

-- B42 vehicle cargo part IDs to probe. Fridge supports refrigerated PZK vans.
local TRUNK_PART_IDS = {"TrunkBag", "TruckBed", "TrunkBag2", "TrunkBag3", "Trunk", "Fridge"}

-- Returns true if the ItemContainer ic belongs to one of the trunk parts
-- on the given vehicle. Used to validate ISInventoryPage containers.
local function containerBelongsToVehicleTrunk(ic, vehicle)
    if not ic or not vehicle or not vehicle.getPartById then return false end
    for _, partId in ipairs(TRUNK_PART_IDS) do
        local okP, part = pcall(function() return vehicle:getPartById(partId) end)
        if okP and part then
            -- Compare by object identity: does this part's container === ic?
            if part.getItemContainer then
                local okC, c = pcall(function() return part:getItemContainer() end)
                if okC and c and c == ic then return true end
            end
            if part.getContainer then
                local okC, c = pcall(function() return part:getContainer() end)
                if okC and c and c == ic then return true end
            end
        end
    end
    return false
end

local function getVehicleTrunkContainer(vehicle)
    if not vehicle then return nil end

    -- Primary: direct part-based access. In B42 the vehicle Java object is
    -- live when the mod window is open (player stands next to it). For
    -- vehicles whose trunk was already opened in the vanilla UI, getItemContainer()
    -- returns the populated, item-iterable container immediately.
    if vehicle.getPartById then
        for _, partId in ipairs(TRUNK_PART_IDS) do
            local okP, part = pcall(function() return vehicle:getPartById(partId) end)
            if okP and part then
                local ic = nil
                if part.getItemContainer then
                    local okC, c = pcall(function() return part:getItemContainer() end)
                    if okC and c then ic = c end
                end
                if not ic and part.getContainer then
                    local okC, c = pcall(function() return part:getContainer() end)
                    if okC and c then ic = c end
                end
                if ic then return ic end
            end
        end
    end

    -- Secondary: ISInventoryPage.GetFloorContainer holds the container that
    -- the currently open vanilla loot/trunk window is showing. If the player
    -- has their trunk open alongside our window, this will be the trunk
    -- container — verify it actually belongs to OUR vehicle to avoid returning
    -- a ground/floor container by mistake.
    if ISInventoryPage and ISInventoryPage.GetFloorContainer then
        for pNum = 0, 3 do
            local okF, ic = pcall(function() return ISInventoryPage.GetFloorContainer(pNum) end)
            if okF and ic and containerBelongsToVehicleTrunk(ic, vehicle) then
                return ic
            end
        end
    end

    -- Tertiary: vehicle as IsoObject (single container, no part lookup needed).
    if vehicle.getContainer then
        local ok, ic = pcall(function() return vehicle:getContainer() end)
        if ok and ic then return ic end
    end

    return nil
end

-- refreshExternalStorageLists removed: Car Storage now uses the vanilla loot
-- window for trunk access and a native IsoObject container for the roof rack.
-- See onGSVU4OpenTrunk / onGSVU4OpenRoofRack below.


local function getInventoryItemCategory(item)
    if not item then return "" end
    -- Unwrap table wrappers produced by addInventoryToList: {item=javaItem, category=...}
    if type(item) == "table" and item.category ~= nil then return tostring(item.category) end
    -- If the wrapper has a Java item inside, recurse on that
    if type(item) == "table" and item.item then return getInventoryItemCategory(item.item) end

    if getItemCategoryForStack then
        local value = getItemCategoryForStack(item)
        if value and value ~= "" then return value end
    end

    if item.getDisplayCategory then
        local ok, value = pcall(function() return item:getDisplayCategory() end)
        if ok and value then return tostring(value) end
    end

    if item.getCategory then
        local ok, value = pcall(function() return item:getCategory() end)
        if ok and value then return tostring(value) end
    end

    return ""
end

local function drawInventoryStyleRow(list, y, item, alt)
    if not item then return y + list.itemheight end

    if item.index and list.selected == item.index then
        list:drawRect(0, y, list.width, list.itemheight, 0.30, 0.20, 0.35, 0.55)
    elseif alt then
        list:drawRect(0, y, list.width, list.itemheight, 0.12, 0.08, 0.08, 0.08)
    end

    local data = item.item
    local label = item.text or ""
    local category = getInventoryItemCategory(data)
    if type(data) == "table" and data.weight then
        label = tostring(label) .. " (" .. formatWeight2(data.weight) .. ")"
    end

    list:drawText(tostring(label), 8, y + 3, 0.86,0.86,0.86,1, list.font or UIFont.Small)

    if category and category ~= "" then
        local catX = math.max(160, list.width - 112)
        list:drawText(tostring(category), catX, y + 3, 0.65,0.65,0.90,1, list.font or UIFont.Small)
    end

    return y + list.itemheight
end

local function drawStorageColumnHeader(window, x, y, w, title, rightText, rightColor)
    window:drawRect(x, y, w, 28, 0.35, 0.05, 0.05, 0.05)
    window:drawRectBorder(x, y, w, 28, 0.55, 0.70, 0.70, 0.70)
    window:drawText(title, x + 8, y + 7, 0.95,0.95,0.95,1,UIFont.Small)
    if rightText and tostring(rightText) ~= "" then
        local label = tostring(rightText)
        local textW = 0
        if getTextManager and UIFont then
            local ok, value = pcall(function() return getTextManager():MeasureStringX(UIFont.Small, label) end)
            if ok and value then textW = tonumber(value) or 0 end
        end
        local tx = math.max(x + math.floor(w * 0.45), x + w - textW - 8)
        local rc = rightColor or {r=0.88, g=0.88, b=0.88}
        window:drawText(label, tx, y + 7, rc.r or 0.88, rc.g or 0.88, rc.b or 0.88, 1, UIFont.Small)
    end
end


local function tyreChainsItemCount(character, fullType)
    if GSVU4_TyreChains and GSVU4_TyreChains.countItem then
        return tonumber(GSVU4_TyreChains.countItem(character, fullType)) or 0
    end
    return 0
end

local function tyreChainsHasAny(character, fullTypes)
    for _, fullType in ipairs(fullTypes or {}) do
        if tyreChainsItemCount(character, fullType) > 0 then return true end
    end
    return false
end

local function reportForTyreChains(window, grade)
    local cfg = GSVU4UpgradesConfig.getGradeConfig("TyreChains", grade or "Standard")
    local report = { ok = false, reasons = {} }
    if not cfg or not GSVU4_TyreChains or not GSVU4_TyreChains.Config then
        report.reasons[#report.reasons + 1] = "Tyre chain upgrade not loaded."
        return report
    end

    local current = getInstalledUpgradeForUI(window.vehicle, "TyreChains")
    report.current = current
    report.installedSameGrade = current ~= nil
    report.installedDifferentGrade = false
    if current then
        report.reasons[#report.reasons + 1] = "Tyre Chains already installed."
    end

    local _, mw, me, mwNeed, meNeed, el, elNeed = hasSkills(window.character, cfg)
    report.mw, report.me, report.mwNeed, report.meNeed = mw, me, mwNeed, meNeed
    report.el, report.elNeed = el or 0, elNeed or 0
    report.skillsOk = (me or 0) >= (meNeed or 0)
    if not report.skillsOk then report.reasons[#report.reasons + 1] = "Skill requirement not met." end

    report.toolReport = {
        lugWrench = tyreChainsItemCount(window.character, "Base.LugWrench") > 0,
        wrenchOrRatchet = tyreChainsHasAny(window.character, {"Base.Wrench", "Base.RatchetWrench"}),
    }
    report.toolsOk = report.toolReport.lugWrench and report.toolReport.wrenchOrRatchet
    if not report.toolsOk then report.reasons[#report.reasons + 1] = "Missing required tools." end

    report.heavyChain = tyreChainsItemCount(window.character, "Base.HeavyChain")
    report.wire = tyreChainsItemCount(window.character, "Base.Wire")
    report.screws = tyreChainsItemCount(window.character, "Base.Screws")
    report.ductTape = tyreChainsItemCount(window.character, "Base.DuctTape")
    report.recipeOk = report.heavyChain >= 4 and report.wire >= 4 and report.screws >= 16 and report.ductTape >= 1
    if not report.recipeOk then report.reasons[#report.reasons + 1] = "Missing materials." end

    report.fuel = 0
    report.fuelOk = true
    report.ok = #report.reasons == 0
    return report
end

local function queueTyreChainUpgradeAction(character, vehicle, command)
    if not GSVU4_TyreChains or not GSVU4_TyreChains.Config then return end
    local cfg = GSVU4_TyreChains.Config
    local totalTime = cfg.InstallTime or 240
    local label = "Installing tyre chains"
    if command == "Remove" then
        totalTime = cfg.RemoveTime or 180
        label = "Removing tyre chains"
    elseif command == "RepairHeavy" then
        totalTime = cfg.HeavyRepairTime or 180
        label = "Repairing tyre chains"
    elseif command == "RepairLight" then
        totalTime = cfg.LightRepairTime or 120
        label = "Repairing tyre chains"
    end

    if GSVU4_TyreChains.queueTimedVehicleAction then
        GSVU4_TyreChains.queueTimedVehicleAction(character, vehicle, command, totalTime, label)
    elseif GSVU4_TyreChains.sendVehicleCommand then
        GSVU4_TyreChains.sendVehicleCommand(command, character, vehicle)
    end
end

local function reportForUpgrade(window, upgradeId, grade)
    local cfg = GSVU4UpgradesConfig.getGradeConfig(upgradeId, grade)
    local report = {ok=false, reasons={}}
    if not cfg then report.reasons[#report.reasons+1] = "Invalid upgrade."; return report end
    if upgradeId == "TyreChains" then return reportForTyreChains(window, grade) end

    local current = getInstalledUpgradeForUI(window.vehicle, upgradeId)
    report.current = current
    report.installedDifferentGrade = current and current.grade and tostring(current.grade) ~= tostring(grade)
    report.installedSameGrade = current and current.grade and tostring(current.grade) == tostring(grade)

    if GSVU4UpgradesConfig.canInstallFrontFixture then
        local fixtureOk, fixtureReason = GSVU4UpgradesConfig.canInstallFrontFixture(window.vehicle, upgradeId)
        if not fixtureOk then report.reasons[#report.reasons + 1] = fixtureReason end
    end

    if upgradeId == "FilteredAirIntake"
    and GSVU4FilteredAirIntake
    and GSVU4FilteredAirIntake.canInstallOnVehicle then
        local vehicleOk, vehicleReason = GSVU4FilteredAirIntake.canInstallOnVehicle(window.vehicle)
        report.vehicleSupported = vehicleOk == true
        if not vehicleOk then
            report.reasons[#report.reasons + 1] = vehicleReason or "Filtered Air Intake requires a fully enclosed cab."
        end
    end

    if upgradeId == "EngineScoop"
    and GSVU4EngineScoop
    and GSVU4EngineScoop.canInstallOnVehicle then
        local vehicleOk, vehicleReason = GSVU4EngineScoop.canInstallOnVehicle(window.vehicle)
        report.vehicleSupported = vehicleOk == true
        if not vehicleOk then
            report.reasons[#report.reasons + 1] = vehicleReason or "No fitted Engine Scoop model is available for this vehicle."
        end
    end

    local upgDefForReport = GSVU4UpgradesConfig.getUpgrade and GSVU4UpgradesConfig.getUpgrade(upgradeId) or nil
    local upgLabelForReport = upgDefForReport and upgDefForReport.label or "Upgrade"
    if report.installedSameGrade then
        report.reasons[#report.reasons+1] = tostring(current.grade) .. " " .. upgLabelForReport .. " already installed."
    elseif report.installedDifferentGrade then
        if upgradeId == "RoofRack" then
            report.reasons[#report.reasons+1] = installedRoofRackLabel(current) or "Another Roof Rack grade is already installed."
        else
            report.reasons[#report.reasons+1] = "Another " .. upgLabelForReport .. " grade is already installed."
        end
    end

    if GSVU4UpgradesConfig.isUpgradePrerequisiteMet and not GSVU4UpgradesConfig.isUpgradePrerequisiteMet(window.vehicle, upgradeId) then
        local label = GSVU4UpgradesConfig.getUpgradePrerequisiteLabel and GSVU4UpgradesConfig.getUpgradePrerequisiteLabel(upgradeId) or "required upgrade"
        report.reasons[#report.reasons+1] = tostring(label) .. " must be installed first."
    end

    local skillsOk, mw, me, mwNeed, meNeed, el, elNeed = hasSkills(window.character, cfg)
    report.skillsOk = skillsOk
    report.mw, report.me, report.mwNeed, report.meNeed = mw, me, mwNeed, meNeed
    report.el, report.elNeed = el or 0, elNeed or 0
    if not skillsOk then report.reasons[#report.reasons+1] = "Skill requirement not met." end

    if VehicleArmorHelpers then
        report.toolsOk, report.toolReport = hasUpgradeTools(window.character, upgradeId, grade)
        report.recipeOk = VehicleArmorHelpers.hasRecipeForCharacter and VehicleArmorHelpers.hasRecipeForCharacter(window.character, cfg.recipe) or false
        if VehicleArmorHelpers.countMaterialsForCharacter then
            local mats = VehicleArmorHelpers.countMaterialsForCharacter(window.character)
            if mats then
                report.scrap = mats.scrap or report.scrap or 0
                report.sheets = mats.sheets or report.sheets or 0
                report.bars = mats.bars or report.bars or 0
                report.screws = mats.screws or report.screws or 0
                report.wire = mats.wire or report.wire or 0
                report.electricWire = mats.electricWire or report.electricWire or 0
                report.bulbs = mats.bulbs or report.bulbs or 0
                report.autoTuneMilitaryRadio = mats.autoTuneMilitaryRadio or report.autoTuneMilitaryRadio or 0
                report.rods = mats.rods or report.rods or 0
            end
        end
        if window.forceInventoryReportRefresh then
            local armorReport = window:forceInventoryReportRefresh()
            if armorReport then
                report.scrap = armorReport.scrap or 0
                report.sheets = armorReport.sheets or 0
                report.bars = armorReport.bars or 0
                report.screws = armorReport.screws or 0
                report.wire = armorReport.wire or 0
                report.electricWire = armorReport.electricWire or report.electricWire or 0
                report.bulbs = armorReport.bulbs or report.bulbs or 0
                report.autoTuneMilitaryRadio = report.autoTuneMilitaryRadio or 0
                report.rods = armorReport.rods or 0
            end
        end
        report.fuel = VehicleArmorHelpers.getTotalTorchFuel and VehicleArmorHelpers.getTotalTorchFuel(window.character) or 0
        report.fuelOk = (tonumber(cfg.fuelUse) or 0) <= 0 or report.fuel >= (cfg.fuelUse or 0)
    else
        report.toolsOk, report.recipeOk, report.fuelOk = false, false, false
        report.toolReport = getUpgradeToolReport(nil, upgradeId)
        report.fuel = 0
    end

    if not report.toolsOk then report.reasons[#report.reasons+1] = "Missing required tools." end
    if not report.recipeOk then report.reasons[#report.reasons+1] = "Missing materials." end
    if not report.fuelOk then report.reasons[#report.reasons+1] = "Missing blowtorch fuel." end

    if upgradeId == "FilteredAirIntake" and not current and GSVU4FilteredAirIntake then
        report.filterNeed = tonumber(cfg.filterCapacityMax) or tonumber(cfg.capacity) or 0
        report.filterAvailable = GSVU4FilteredAirIntake.getAvailableFilterCapacity(window.character)
        local selectedFilters = GSVU4FilteredAirIntake.selectFilterItems(window.character, report.filterNeed)
        report.filterOk = report.filterAvailable >= report.filterNeed and selectedFilters ~= nil
        if not report.filterOk then
            report.reasons[#report.reasons+1] = "Insufficient filter media. Factory filters provide 50; crafted/recharged filters provide 25."
        end
    else
        report.filterOk = true
    end

    -- Trunk space check for ExtraFuelStorage
    if upgradeId == "ExtraFuelStorage" and GSVU4UpgradesConfig.canAffordTrunkPenalty then
        local trunkOk, trunkReason = GSVU4UpgradesConfig.canAffordTrunkPenalty(
            window.vehicle, upgradeId, grade)
        if not trunkOk then
            report.reasons[#report.reasons+1] = trunkReason or "Cargo compartment is too small."
        end
    end

    report.ok = #report.reasons == 0
    return report
end

local function syncModeVisibility(window)
    local mode = window.gsvu4Mode or "Armor"
    local armorVisible = mode == "Armor"
    local upgradesVisible = mode == "Upgrades"

    if window.gradeButtons then for _, btn in pairs(window.gradeButtons) do setVisible(btn, armorVisible) end end
    if window.partFilterButtons then for _, btn in pairs(window.partFilterButtons) do setVisible(btn, armorVisible) end end
    if window.partSortButtons then for _, btn in pairs(window.partSortButtons) do setVisible(btn, armorVisible) end end

    for _, ctrl in ipairs({
        window.partListBox, window.partList, window.actionButton, window.repairButton,
        window.installAllButton, window.repairAllButton, window.uninstallAllButton,
        window.clearInstallSelectionButton, window.clearSelectionButton,
    }) do setVisible(ctrl, armorVisible) end
    setVisible(window.materialHelpButton, armorVisible)


    setVisible(window.gsvu4UpgradeListBox, upgradesVisible)
    setVisible(window.gsvu4UpgradeList, upgradesVisible)
    setVisible(window.gsvu4InstallUpgradeButton, upgradesVisible)
    setVisible(window.gsvu4RepairUpgradeButton, upgradesVisible)
    setVisible(window.gsvu4RemoveUpgradeButton, upgradesVisible)

    setVisible(window.gsvu4ExternalListBox, false)
    setVisible(window.gsvu4ExternalList, false)
    -- Hide armor panels when in upgrades mode
    setVisible(window.detailBox,   armorVisible)
    setVisible(window.overviewBox, armorVisible)

    if window.gsvu4ModeButtons then
        for key, btn in pairs(window.gsvu4ModeButtons) do
            if key == mode then
                btn.backgroundColor = {r=0.20, g=0.35, b=0.55, a=0.90}
            else
                btn.backgroundColor = {r=0.10, g=0.10, b=0.10, a=0.75}
            end
        end
    end
end

function VehicleArmorWindow:setGSVU4Mode(mode)
    self.gsvu4Mode = mode or "Armor"
    syncModeVisibility(self)
end

local function createUpgradeControls(window)
    window.gsvu4Mode = window.gsvu4Mode or "Armor"
    window.gsvu4ModeButtons = window.gsvu4ModeButtons or {}

    -- Mode buttons sit in a new row at y=90, between the grade buttons (y=56+28=84)
    -- and the filter controls. We push filter/sort/list/panels down by 36px to make room.
    local modeY   = 90
    local modeH   = 26
    local modeGap = 6
    local btnDefs = {
        { key="Armor",    title="Armor",    w=80  },
        { key="Upgrades", title="Upgrades", w=100 },
    }
    local totalW = 0
    for _, d in ipairs(btnDefs) do totalW = totalW + d.w + modeGap end
    totalW = totalW - modeGap
    local startX = 10

    for _, d in ipairs(btnDefs) do
        local key = d.key
        local btn = ISButton:new(startX, modeY, d.w, modeH, d.title, window, function()
            window:setGSVU4Mode(key)
        end)
        btn:initialise()
        window:addChild(btn)
        window.gsvu4ModeButtons[key] = btn
        startX = startX + d.w + modeGap
    end

    -- Shift existing filter/sort controls and panels down by 36px so mode buttons
    -- don't overlap them.
    local SHIFT = 36
    local function shiftDown(ctrl)
        if ctrl and ctrl.getY and ctrl.setY then
            ctrl:setY(ctrl:getY() + SHIFT)
        end
    end
    local function shiftAndShrink(ctrl)
        if ctrl and ctrl.getY and ctrl.setY and ctrl.getHeight and ctrl.setHeight then
            ctrl:setY(ctrl:getY() + SHIFT)
            ctrl:setHeight(math.max(40, ctrl:getHeight() - SHIFT))
        end
    end
    -- Filter and sort button rows
    if window.partFilterButtons then for _, b in pairs(window.partFilterButtons) do shiftDown(b) end end
    if window.partSortButtons   then for _, b in pairs(window.partSortButtons)   do shiftDown(b) end end
    -- Part list box and scroll list
    shiftDown(window.partListBox)
    shiftDown(window.partList)
    if window.partList and window.partList.getHeight and window.partList.setHeight then
        window.partList:setHeight(math.max(40, window.partList:getHeight() - SHIFT))
    end
    -- Detail and overview panels
    shiftAndShrink(window.detailBox)
    shiftAndShrink(window.overviewBox)
    -- Filter/sort background panel (drawn via drawRect in prerender - no widget to move)
    -- Clear-selection and other bottom buttons don't need shifting (they use height-based Y)
    shiftDown(window.clearSelectionButton)
    shiftDown(window.materialHelpButton)

    local listY = 154
    local listW = 272
    local listH = window.height - listY - 88

    window.gsvu4UpgradeListBox = ISPanel:new(10, listY, listW, listH)
    window.gsvu4UpgradeListBox:initialise()
    window.gsvu4UpgradeListBox.backgroundColor = {r=0, g=0, b=0, a=0.5}
    window:addChild(window.gsvu4UpgradeListBox)

    window.gsvu4UpgradeList = ISScrollingListBox:new(14, listY + 4, listW - 8, listH - 8)
    window.gsvu4UpgradeList:initialise()
    window.gsvu4UpgradeList:instantiate()
    window.gsvu4UpgradeList.itemheight = math.max(24, getTextH(UIFont.Small) + 8)
    window.gsvu4UpgradeList.font = UIFont.Small
    window.gsvu4UpgradeList.doDrawItem = function(list, y, item, alt)
        if not item then return y + list.itemheight end
        if item.index and list.selected == item.index then
            list:drawRect(0, y, list.width, list.itemheight, 0.30, 0.20, 0.35, 0.55)
        end
        local data = item.item
        local label = item.text or "Upgrade"
        -- Check if THIS specific upgrade+grade is installed
        local installedForType = data and data.upgradeId and
            getInstalledUpgradeForUI(window.vehicle, data.upgradeId)
        local isInstalled = installedForType and installedForType.grade == (data and data.grade)
        local r, g, b = 0.75, 0.75, 0.75
        if isInstalled then r,g,b = 0.30, 0.85, 0.35 end
        list:drawText(label, 8, y + 4, r, g, b, 1, list.font or UIFont.Small)
        return y + list.itemheight
    end
    window.gsvu4UpgradeList.onmousedown = function()
        local list = window.gsvu4UpgradeList
        local row = list.selected
        if row and row > 0 and list.items[row] then window.gsvu4SelectedUpgrade = list.items[row].item end
    end
    window:addChild(window.gsvu4UpgradeList)

    window.gsvu4UpgradeList:clear()
    for _, grade in ipairs(GSVU4UpgradesConfig.RoofRackGrades) do
        local cfg = GSVU4UpgradesConfig.getGradeConfig("RoofRack", grade)
        window.gsvu4UpgradeList:addItem(cfg.label, {upgradeId="RoofRack", grade=grade})
    end
    for _, grade in ipairs(GSVU4UpgradesConfig.ExtraFuelStorageGrades or {}) do
        local cfg = GSVU4UpgradesConfig.getGradeConfig("ExtraFuelStorage", grade)
        if cfg then
            window.gsvu4UpgradeList:addItem(cfg.label, {upgradeId="ExtraFuelStorage", grade=grade})
        end
    end
    local openTopIntake = false
    if GSVU4FilteredAirIntake and GSVU4FilteredAirIntake.isOpenTopVehicle then
        openTopIntake = GSVU4FilteredAirIntake.isOpenTopVehicle(window.vehicle) == true
    end
    local installedOpenTopIntake = openTopIntake and getInstalledUpgradeForUI(window.vehicle, "FilteredAirIntake") or nil

    if not openTopIntake then
        for _, grade in ipairs(GSVU4UpgradesConfig.FilteredAirIntakeGrades or {}) do
            local cfg = GSVU4UpgradesConfig.getGradeConfig("FilteredAirIntake", grade)
            if cfg then
                window.gsvu4UpgradeList:addItem(cfg.label, {upgradeId="FilteredAirIntake", grade=grade})
            end
        end
    elseif installedOpenTopIntake then
        -- Legacy safety valve: do not expose installation/grade choices on an
        -- open-top vehicle, but keep one removal-only row so old saves cannot
        -- trap the fitted intake or its installed filter media.
        local legacyGrade = installedOpenTopIntake.grade or "Basic"
        local legacyCfg = GSVU4UpgradesConfig.getGradeConfig("FilteredAirIntake", legacyGrade)
        local legacyLabel = (legacyCfg and legacyCfg.label or "Filtered Air Intake") .. " [Remove Only]"
        window.gsvu4UpgradeList:addItem(legacyLabel, {
            upgradeId="FilteredAirIntake",
            grade=legacyGrade,
            openTopRemovalOnly=true,
        })
    end
    local installedEngineScoop = getInstalledUpgradeForUI(window.vehicle, "EngineScoop")
    local engineScoopSupported = false
    local engineScoopReason = nil
    if GSVU4EngineScoop and GSVU4EngineScoop.canInstallOnVehicle then
        engineScoopSupported, engineScoopReason = GSVU4EngineScoop.canInstallOnVehicle(window.vehicle)
    end

    if engineScoopSupported then
        for _, grade in ipairs(GSVU4UpgradesConfig.EngineScoopGrades or {}) do
            local cfg = GSVU4UpgradesConfig.getGradeConfig("EngineScoop", grade)
            if cfg then
                window.gsvu4UpgradeList:addItem(cfg.label, {upgradeId="EngineScoop", grade=grade})
            end
        end
    elseif installedEngineScoop then
        local legacyGrade = installedEngineScoop.grade or "Small"
        local legacyCfg = GSVU4UpgradesConfig.getGradeConfig("EngineScoop", legacyGrade)
        local legacyLabel = (legacyCfg and legacyCfg.label or "Engine Scoop") .. " [Remove Only]"
        window.gsvu4UpgradeList:addItem(legacyLabel, {
            upgradeId="EngineScoop",
            grade=legacyGrade,
            engineScoopRemovalOnly=true,
            engineScoopReason=engineScoopReason,
        })
    end

    for _, grade in ipairs(GSVU4UpgradesConfig.BullBarGrades or {}) do
        local cfg = GSVU4UpgradesConfig.getGradeConfig("BullBar", grade)
        if cfg then
            window.gsvu4UpgradeList:addItem(cfg.label, {upgradeId="BullBar", grade=grade})
        end
    end
    for _, grade in ipairs(GSVU4UpgradesConfig.PlowGrades or {}) do
        local cfg = GSVU4UpgradesConfig.getGradeConfig("Plow", grade)
        if cfg then
            window.gsvu4UpgradeList:addItem(cfg.label, {upgradeId="Plow", grade=grade})
        end
    end
    for _, grade in ipairs(GSVU4UpgradesConfig.AutoTuneMilitaryRadioGrades or {}) do
        local cfg = GSVU4UpgradesConfig.getGradeConfig("AutoTuneMilitaryRadio", grade)
        if cfg then
            window.gsvu4UpgradeList:addItem(cfg.label, {upgradeId="AutoTuneMilitaryRadio", grade=grade})
        end
    end
    for _, grade in ipairs(GSVU4UpgradesConfig.TyreChainsGrades or {}) do
        local cfg = GSVU4UpgradesConfig.getGradeConfig("TyreChains", grade)
        if cfg then
            window.gsvu4UpgradeList:addItem(cfg.label, {upgradeId="TyreChains", grade=grade})
        end
    end
    for _, upgradeId in ipairs(GSVU4UpgradesConfig.RoofLightOptionIds or {"RoofLights"}) do
        for _, grade in ipairs(GSVU4UpgradesConfig.RoofLightsGrades or {"Basic"}) do
            local cfg = GSVU4UpgradesConfig.getGradeConfig(upgradeId, grade)
            if cfg then
                window.gsvu4UpgradeList:addItem(cfg.label, {upgradeId=upgradeId, grade=grade})
            end
        end
    end
    window.gsvu4UpgradeList.selected = 1
    window.gsvu4SelectedUpgrade = window.gsvu4UpgradeList.items[1].item

    window.gsvu4ExternalListBox = ISPanel:new(10, listY, listW, listH)
    window.gsvu4ExternalListBox:initialise()
    window.gsvu4ExternalListBox.backgroundColor = {r=0, g=0, b=0, a=0.5}
    window:addChild(window.gsvu4ExternalListBox)

    window.gsvu4ExternalList = ISScrollingListBox:new(14, listY + 4, listW - 8, listH - 8)
    window.gsvu4ExternalList:initialise()
    window.gsvu4ExternalList:instantiate()
    window.gsvu4ExternalList.itemheight = math.max(24, getTextH(UIFont.Small) + 8)
    window.gsvu4ExternalList.font = UIFont.Small
    window.gsvu4ExternalList.doDrawItem = function(list, y, item, alt)
        if not item then return y + list.itemheight end
        if item.index and list.selected == item.index then list:drawRect(0, y, list.width, list.itemheight, 0.30, 0.20, 0.35, 0.55) end
        local installed = getInstalledRoofRack(window.vehicle)
        local label = installed and ("Roof Rack [" .. tostring(installed.grade) .. "]") or "Roof Rack [Not Installed]"
        local r,g,b = installed and 0.30 or 0.75, installed and 0.85 or 0.75, installed and 0.35 or 0.75
        list:drawText(label, 8, y + 4, r,g,b,1, list.font or UIFont.Small)
        return y + list.itemheight
    end
    window:addChild(window.gsvu4ExternalList)

    local btnH = math.max(30, getTextH(UIFont.Small) + 14)
    local bottomY = window.height - btnH - 8
    local btnW = 150
    local gap = 10
    local actionX = window.width - ((btnW * 3) + (gap * 2)) - 10

    window.gsvu4RepairUpgradeButton = ISButton:new(actionX, bottomY, btnW, btnH, "Repair Upgrade", window, function()
        window:onGSVU4RepairUpgradeClick()
    end)
    window.gsvu4RepairUpgradeButton:initialise()
    window:addChild(window.gsvu4RepairUpgradeButton)

    window.gsvu4RemoveUpgradeButton = ISButton:new(actionX + btnW + gap, bottomY, btnW, btnH, "Remove Upgrade", window, function()
        window:onGSVU4RemoveUpgradeClick()
    end)
    window.gsvu4RemoveUpgradeButton:initialise()
    window:addChild(window.gsvu4RemoveUpgradeButton)

    window.gsvu4InstallUpgradeButton = ISButton:new(actionX + ((btnW + gap) * 2), bottomY, btnW, btnH, "Install Upgrade", window, function()
        window:onGSVU4InstallUpgradeClick()
    end)
    window.gsvu4InstallUpgradeButton:initialise()
    window:addChild(window.gsvu4InstallUpgradeButton)

    syncModeVisibility(window)
end
function VehicleArmorWindow:onGSVU4InstallUpgradeClick()
    local selected = self.gsvu4SelectedUpgrade
    if not selected then return end
    local cfg = GSVU4UpgradesConfig.getGradeConfig(selected.upgradeId, selected.grade)
    if not cfg then return end

    local report = reportForUpgrade(self, selected.upgradeId, selected.grade)
    if not report.ok then
        if self.character then self.character:Say(report.reasons[1] or "Cannot install upgrade.") end
        return
    end

    if selected.upgradeId == "TyreChains" then
        queueTyreChainUpgradeAction(self.character, self.vehicle, "Install")
        return
    end

    if GSVU4Core
    and GSVU4Core.QueueUpgradeInstallTimedAction
    and GSVU4Core.QueueUpgradeInstallTimedAction(
        self.character,
        self.vehicle,
        selected.upgradeId,
        selected.grade,
        cfg.time or 200
    ) then
        self:close()
    elseif self.character then
        self.character:Say("Unable to queue upgrade installation.")
    end
end

function VehicleArmorWindow:onGSVU4RepairUpgradeClick()
    local selected = self.gsvu4SelectedUpgrade
    if not selected then return end
    local upgradeId = selected.upgradeId
    local current = getInstalledUpgradeForUI(self.vehicle, upgradeId)
    if not current then
        local upgDef = GSVU4UpgradesConfig.getUpgrade(upgradeId)
        local label = upgDef and upgDef.label or upgradeId
        if self.character then self.character:Say("No " .. label .. " installed.") end
        return
    end
    if upgradeId == "TyreChains" then
        local condition = getInstalledUpgradeHealth(current)
        local command = condition <= 50 and "RepairHeavy" or "RepairLight"
        queueTyreChainUpgradeAction(self.character, self.vehicle, command)
        return
    end
    if upgradeId == "FilteredAirIntake" and GSVU4FilteredAirIntake then
        if isClient and isClient() and sendClientCommand then
            sendClientCommand("GoresSVU4Core", "ReplaceFilteredAirIntakeFilters", {
                vehicleId = self.vehicle and self.vehicle.getId and self.vehicle:getId() or nil,
                vehicleOnlineId = self.vehicle and self.vehicle.getOnlineID and self.vehicle:getOnlineID() or nil,
                vehicleX = self.vehicle and self.vehicle.getX and self.vehicle:getX() or nil,
                vehicleY = self.vehicle and self.vehicle.getY and self.vehicle:getY() or nil,
                vehicleZ = self.vehicle and self.vehicle.getZ and self.vehicle:getZ() or nil,
            })
            if self.character then self.character:Say("Filter replacement requested.") end
        else
            local ok, added, consumed, reason = GSVU4FilteredAirIntake.replaceFilterSetFromCharacter(self.character, self.vehicle)
            if ok then
                if self.vehicle and self.vehicle.transmitModData then pcall(function() self.vehicle:transmitModData() end) end
                if self.character then self.character:Say("Filtered Air Intake filters replaced.") end
            elseif self.character then
                self.character:Say(reason or "Unable to replace filters.")
            end
        end
        self:close()
        return
    end
    if isClient and isClient() and sendClientCommand then
        sendClientCommand("GoresSVU4Core", "RepairUpgrade", {
            upgradeId = upgradeId,
            vehicleId = self.vehicle and self.vehicle.getId and self.vehicle:getId() or nil,
            vehicleOnlineId = self.vehicle and self.vehicle.getOnlineID and self.vehicle:getOnlineID() or nil,
            vehicleX = self.vehicle and self.vehicle.getX and self.vehicle:getX() or nil,
            vehicleY = self.vehicle and self.vehicle.getY and self.vehicle:getY() or nil,
            vehicleZ = self.vehicle and self.vehicle.getZ and self.vehicle:getZ() or nil,
        })
    else
        local maxHealth = getInstalledUpgradeMaxHealth(upgradeId, current)
        current.health = maxHealth
        current.maxHealth = maxHealth
        current.wearRemainder = 0
        if self.vehicle and self.vehicle.transmitModData then pcall(function() self.vehicle:transmitModData() end) end
    end
end

function VehicleArmorWindow:onGSVU4RemoveUpgradeClick()
    local selected = self.gsvu4SelectedUpgrade
    if not selected then return end
    local upgradeId = selected.upgradeId
    local current = getInstalledUpgradeForUI(self.vehicle, upgradeId)
    if not current then
        local upgDef = GSVU4UpgradesConfig.getUpgrade(upgradeId)
        local label = upgDef and upgDef.label or upgradeId
        if self.character then self.character:Say("No " .. label .. " installed.") end
        return
    end
    if upgradeId == "TyreChains" then
        queueTyreChainUpgradeAction(self.character, self.vehicle, "Remove")
        return
    end
    if GSVU4Core
    and GSVU4Core.QueueUpgradeUninstallTimedAction
    and GSVU4Core.QueueUpgradeUninstallTimedAction(self.character, self.vehicle, upgradeId) then
        self:close()
    elseif self.character then
        self.character:Say("Unable to queue upgrade removal.")
    end
end

function VehicleArmorWindow:onGSVU4MoveItemToRoofRack()
    local item = getSelectedListItemData(self.gsvu4MainInventoryList)
    if not item or item.system then
        if self.character then self.character:Say("Select an item to move.") end
        return
    end

    local fullType = getItemFullTypeSafe(item)
    if not fullType or fullType == "" then
        if self.character then self.character:Say("Unable to identify selected item.") end
        return
    end

    sendRoofRackCommand("MoveItemToRoofRack", self, { fullType = fullType })
    self.gsvu4ExternalStorageDirty = true
end

function VehicleArmorWindow:onGSVU4MoveItemFromRoofRack()
    local data = getSelectedListItemData(self.gsvu4RoofRackInventoryList)
    if not data or data.system or not data.storageIndex then
        if self.character then self.character:Say("Select a roof rack item to retrieve.") end
        return
    end

    sendRoofRackCommand("MoveItemFromRoofRack", self, { storageIndex = data.storageIndex })
    self.gsvu4ExternalStorageDirty = true
end

function VehicleArmorWindow:onGSVU4MoveAllToRoofRack()
    sendRoofRackCommand("MoveAllItemsToRoofRack", self, {})
    self.gsvu4ExternalStorageDirty = true
end

function VehicleArmorWindow:onGSVU4MoveAllFromRoofRack()
    sendRoofRackCommand("MoveAllItemsFromRoofRack", self, {})
    self.gsvu4ExternalStorageDirty = true
end

local function isUpgradeKI5Blocked(vehicle)
    if not GSVU4_KI5FullBlock or not GSVU4_KI5FullBlock.IsKI5Vehicle then return false end
    return GSVU4_KI5FullBlock.IsKI5Vehicle(vehicle) == true
end

local function drawModeHeader(window, title, subtitle)
    window:drawText(title, 300, 100, 0.95, 0.95, 0.95, 1, UIFont.Medium)
    if subtitle then window:drawText(subtitle, 300, 126, 0.70, 0.82, 0.95, 1, UIFont.Small) end
end

local function drawUpgradeScreen(window)
    local selected = window.gsvu4SelectedUpgrade or {upgradeId="RoofRack", grade="Basic"}
    local cfg = GSVU4UpgradesConfig.getGradeConfig(selected.upgradeId, selected.grade)
    if not cfg then return end

    local current = getInstalledUpgradeForUI(window.vehicle, selected.upgradeId)
    local report = reportForUpgrade(window, selected.upgradeId, selected.grade)

    drawModeHeader(window, "Vehicle Upgrades", "Install non-armour vehicle upgrades.")

    local listY = 154
    local listH = window.height - listY - 88
    local detailX, detailY, detailW, detailH = 300, listY, 330, listH
    local helpX, helpY = detailX + detailW + 18, listY
    local helpW, helpH = window.width - helpX - 10, listH

    window:drawRectBorder(detailX, detailY, detailW, detailH, 0.55, 0.70, 0.70, 0.70)
    window:drawRectBorder(helpX, helpY, helpW, helpH, 0.55, 0.70, 0.70, 0.70)

    local x, y = detailX + 12, detailY + 12
    window:drawText("PLANNED UPGRADE:", x, y, 1,1,1,1, UIFont.Small); y = y + 22
    window:drawText(cfg.label, x, y, 0.55,0.88,1.00,1,UIFont.Medium); y = y + 26
    if selected.upgradeId == "RoofRack" then
        window:drawText("Purpose: External storage frame above the vehicle.", x, y, 0.97,0.97,0.97,1,UIFont.Small); y = y + 18
        window:drawText("Capacity: +"..tostring(cfg.capacity or 0).." storage units", x, y, 0.40,1.00,0.40,1,UIFont.Small); y = y + 18
    elseif selected.upgradeId == "ExtraFuelStorage" then
        window:drawText("Purpose: Adds a separate auxiliary fuel reserve.", x, y, 0.97,0.97,0.97,1,UIFont.Small); y = y + 18
        window:drawText("Fuel reserve: +"..tostring(cfg.fuelBonus or 0).." L", x, y, 0.40,1.00,0.40,1,UIFont.Small); y = y + 18
        local cargoInfo = GSVU4UpgradesConfig.getTrunkInfo and GSVU4UpgradesConfig.getTrunkInfo(window.vehicle) or nil
        local cargoLabel = cargoInfo and cargoInfo.label or "Cargo Compartment"
        local originalCap = cargoInfo and tonumber(cargoInfo.capacity) or nil
        local vdata = window.vehicle and window.vehicle.getModData and window.vehicle:getModData() or nil
        if vdata and vdata.GSVU4_trunkPartId == (cargoInfo and cargoInfo.partId) then
            originalCap = tonumber(vdata.GSVU4_origTrunkCap) or originalCap
        end
        local targetCap = originalCap and math.max(10, originalCap - (tonumber(cfg.trunkPenalty) or 0)) or nil
        window:drawText("Cargo compartment: "..cargoLabel, x, y, 0.95,0.70,0.40,1,UIFont.Small); y = y + 18
        if originalCap and targetCap then
            window:drawText("Capacity: "..tostring(math.floor(originalCap)).." -> "..tostring(math.floor(targetCap))..
                " (-"..tostring(cfg.trunkPenalty or 0)..")", x, y, 0.95,0.70,0.40,1,UIFont.Small); y = y + 18
        else
            window:drawText("Capacity cost: -"..tostring(cfg.trunkPenalty or 0), x, y, 0.95,0.70,0.40,1,UIFont.Small); y = y + 18
        end
        window:drawText("Installation requirement: compartment completely empty", x, y, 1.00,0.55,0.35,1,UIFont.Small); y = y + 18
    elseif selected.upgradeId == "FilteredAirIntake" then
        window:drawText("Purpose: Filters corpse fumes from sealed cabin air.", x, y, 0.97,0.97,0.97,1,UIFont.Small); y = y + 18
        window:drawText("Filter capacity: "..tostring(cfg.filterCapacityMax or cfg.capacity or 0), x, y, 0.40,1.00,0.40,1,UIFont.Small); y = y + 18
        window:drawText("Requires engine running and every door/window sealed.", x, y, 1.00,0.65,0.45,1,UIFont.Small); y = y + 18
    elseif selected.upgradeId == "EngineScoop" then
        local power = math.floor(((tonumber(cfg.engineForceMultiplier) or 1.0) - 1.0) * 100 + 0.5)
        local fuel = math.floor((tonumber(cfg.extraFuelFraction) or 0) * 100 + 0.5)
        window:drawText("Purpose: Improvised hood-fed forced induction.", x, y, 0.97,0.97,0.97,1,UIFont.Small); y = y + 18
        window:drawText("Engine force: +"..tostring(power).."%", x, y, 0.40,1.00,0.40,1,UIFont.Small); y = y + 18
        window:drawText("Fuel consumption: +"..tostring(fuel).."%", x, y, 1.00,0.65,0.45,1,UIFont.Small); y = y + 18
        window:drawText("Passive wear: -1 engine condition per "..tostring(cfg.wearHoursPerCondition or 0).." running hours", x, y, 1.00,0.55,0.35,1,UIFont.Small); y = y + 18
        window:drawText("Stress: over "..tostring(cfg.stressSpeedMph or 0).." mph for "..tostring(cfg.stressGraceSeconds or 0).." sec", x, y, 1.00,0.55,0.35,1,UIFont.Small); y = y + 18
        window:drawText("Then -1 engine condition every "..tostring(cfg.stressDamageIntervalSeconds or 0).." sec", x, y, 1.00,0.45,0.35,1,UIFont.Small); y = y + 18
    elseif selected.upgradeId == "BullBar" then
        window:drawText("Purpose: Offensive frontal ramming equipment.", x, y, 0.97,0.97,0.97,1,UIFont.Small); y = y + 18
        window:drawText("Vehicle protection: None", x, y, 1.00,0.65,0.45,1,UIFont.Small); y = y + 18
        window:drawText("Guaranteed zombie kill: "..tostring(cfg.zombieKillSpeedMph or 0).." mph / "..tostring(math.floor((cfg.zombieKillSpeedKph or 0) + 0.5)).." km/h", x, y, 0.40,1.00,0.40,1,UIFont.Small); y = y + 18
        window:drawText("Vehicle impact bonus: up to +"..tostring(math.floor((cfg.vehicleBonusMax or 0) * 100)).."% from "..tostring(cfg.vehicleBonusStartMph or 15).." mph.", x, y, 0.40,1.00,0.40,1,UIFont.Small); y = y + 18
    elseif selected.upgradeId == "Plow" then
        window:drawText("Purpose: Defensive crowd displacement.", x, y, 0.97,0.97,0.97,1,UIFont.Small); y = y + 18
        window:drawText("Scripted zombie damage: None", x, y, 0.40,1.00,0.40,1,UIFont.Small); y = y + 18
        window:drawText("Push power: Vehicle mass + forward speed", x, y, 0.40,1.00,0.40,1,UIFont.Small); y = y + 18
        window:drawText("Minimum active speed: "..tostring(cfg.minPushKph or 10).." km/h", x, y, 0.40,1.00,0.40,1,UIFont.Small); y = y + 18
    elseif selected.upgradeId == "AutoTuneMilitaryRadio" then
        window:drawText("Purpose: Auto-tunes vehicle radio to AEBS when engine is running.", x, y, 0.97,0.97,0.97,1,UIFont.Small); y = y + 18
        window:drawText("2-way range: Unlimited for large custom maps.", x, y, 0.40,1.00,0.40,1,UIFont.Small); y = y + 18
    elseif selected.upgradeId == "TyreChains" then
        window:drawText("Purpose: Improves tyre survivability in snow; risky on dry roads.", x, y, 0.97,0.97,0.97,1,UIFont.Small); y = y + 18
        window:drawText("Install/remove happens at all four tyre points.", x, y, 0.40,1.00,0.40,1,UIFont.Small); y = y + 18
    elseif (GSVU4UpgradesConfig.isRoofLightUpgradeId and GSVU4UpgradesConfig.isRoofLightUpgradeId(selected.upgradeId)) then
        window:drawText("Purpose: Roof-mounted auxiliary lighting hardware.", x, y, 0.97,0.97,0.97,1,UIFont.Small); y = y + 18
        window:drawText("Each light position installs separately; the V-radial toggle controls installed lights.", x, y, 0.40,1.00,0.40,1,UIFont.Small); y = y + 18
    end
    window:drawText("Added Weight: +"..tostring(cfg.weight or 0).." kg", x, y, 0.97,0.97,0.97,1,UIFont.Small); y = y + 24

    window:drawText("SKILL REQUIREMENTS:", x, y, 1.00,0.88,0.50,1,UIFont.Small); y = y + 18
    if selected.upgradeId == "AutoTuneMilitaryRadio" then
        report.mwNeed = 0
    end
    local shownSkill = false
    if (report.mwNeed or 0) > 0 then
        drawRequirementLine(window, "MetalWelding", (report.mw or 0) >= (report.mwNeed or 0), tostring(report.mw or 0) .. " / " .. tostring(report.mwNeed or 0), x, y); y = y + 16
        shownSkill = true
    end
    if (report.meNeed or 0) > 0 then
        drawRequirementLine(window, "Mechanics", (report.me or 0) >= (report.meNeed or 0), tostring(report.me or 0) .. " / " .. tostring(report.meNeed or 0), x, y); y = y + 16
        shownSkill = true
    end
    if (report.elNeed or 0) > 0 then
        drawRequirementLine(window, "Electrical", (report.el or 0) >= (report.elNeed or 0), tostring(report.el or 0) .. " / " .. tostring(report.elNeed or 0), x, y); y = y + 16
        shownSkill = true
    end
    if not shownSkill then
        drawRequirementLine(window, "", true, "None", x, y); y = y + 16
    end
    y = y + 6

    window:drawText("REQUIRED TOOLS:", x, y, 1.00,0.88,0.50,1,UIFont.Small); y = y + 18
    local upgDefForReport = GSVU4UpgradesConfig.getUpgrade(selected.upgradeId)
    local toolReq = (cfg and cfg.tools) or (upgDefForReport and upgDefForReport.tools) or { weldingMask = true, blowTorch = true, hammer = true, screwdriver = true }
    if selected.upgradeId == "AutoTuneMilitaryRadio" then
        toolReq = { screwdriver = true }
    end
    if selected.upgradeId == "TyreChains" then
        drawToolRequirementLine(window, report.toolReport and report.toolReport.lugWrench, "Lug Wrench", x, y); y = y + 16
        drawToolRequirementLine(window, report.toolReport and report.toolReport.wrenchOrRatchet, "Wrench or Ratchet Wrench", x, y); y = y + 16
    else
        if toolReq.hammer then drawToolRequirementLine(window, report.toolReport and report.toolReport.hammer, "Hammer", x, y); y = y + 16 end
        if toolReq.screwdriver then drawToolRequirementLine(window, report.toolReport and report.toolReport.screwdriver, "Screwdriver", x, y); y = y + 16 end
        if toolReq.weldingMask then drawToolRequirementLine(window, report.toolReport and report.toolReport.mask, "Welding Mask", x, y); y = y + 16 end
        if toolReq.blowTorch then drawToolRequirementLine(window, (report.toolReport and report.toolReport.blowTorch) and report.fuelOk, "Blowtorch (" .. formatOneDecimal(report.fuel or 0) .. " / " .. formatOneDecimal(cfg.fuelUse or 0) .. " units)", x, y); y = y + 16 end
    end
    y = y + 6

    window:drawText("REQUIRED MATERIALS:", x, y, 1.00,0.88,0.50,1,UIFont.Small); y = y + 18
    local materialLines = recipeLines(cfg.recipe)
    if #materialLines == 0 then
        drawRequirementLine(window, "", true, "None", x, y); y = y + 16
    else
        for _, mat in ipairs(materialLines) do
            local have = getReportMaterialAmount(report, mat.key)
            local need = tonumber(mat.amount) or 0
            local ok = have + 0.0001 >= need
            drawRequirementLine(window, mat.label, ok, tostring(have) .. " / " .. tostring(need), x, y)
            y = y + 16
        end
    end
    if selected.upgradeId == "FilteredAirIntake" and not current then
        local available = tonumber(report.filterAvailable) or 0
        local needed = tonumber(report.filterNeed) or tonumber(cfg.filterCapacityMax) or 0
        drawRequirementLine(window, "Filter Media Capacity", available >= needed, tostring(available) .. " / " .. tostring(needed), x, y)
        y = y + 16
        window:drawText("Factory filter = 50; crafted/recharged filter = 25", x, y, 0.75,0.75,0.75,1,UIFont.Small); y = y + 16
    end

    local hx, hy = helpX + 12, helpY + 12
    local upgDef = GSVU4UpgradesConfig.getUpgrade(selected.upgradeId)
    local uLabel = upgDef and upgDef.label or "Upgrade"
    local uDesc  = upgDef and upgDef.description or ""

    window:drawText("UPGRADE INFO:", hx, hy, 1,1,1,1,UIFont.Small); hy = hy + 22
    window:drawText(uLabel, hx, hy, 0.95,0.95,0.95,1,UIFont.Medium); hy = hy + 28

    -- Description (wrap at ~50 chars)
    if #uDesc > 50 then
        window:drawText(uDesc:sub(1,50), hx, hy, 0.97,0.97,0.97,1,UIFont.Small); hy = hy + 18
        window:drawText(uDesc:sub(51), hx, hy, 0.97,0.97,0.97,1,UIFont.Small); hy = hy + 24
    else
        window:drawText(uDesc, hx, hy, 0.97,0.97,0.97,1,UIFont.Small); hy = hy + 24
    end

    -- Show installed status for THIS upgrade type only
    local installedAny = getInstalledUpgradeForUI(window.vehicle, selected.upgradeId)
    window:drawText("Installed " .. uLabel .. ":", hx, hy, 1.00,0.88,0.50,1,UIFont.Small); hy = hy + 18
    if installedAny then
        if selected.upgradeId == "FilteredAirIntake" and GSVU4FilteredAirIntake then
            local status = GSVU4FilteredAirIntake.getStatus(window.vehicle)
            local runtime = GSVU4FilteredAirIntake.getRuntimeStatus and GSVU4FilteredAirIntake.getRuntimeStatus(window.vehicle) or nil
            local runtimeCapacity = runtime and tonumber(runtime.capacity) or nil
            local statusCapacity = tonumber(status and status.capacity) or 0
            if status and status.active
            and GSVU4FilteredAirIntake.refreshProtectionRuntime
            and (not runtime or runtimeCapacity == nil or math.abs(runtimeCapacity - statusCapacity) > 0.001)
            then
                local refreshed = GSVU4FilteredAirIntake.refreshProtectionRuntime(window.character, window.vehicle)
                if refreshed then runtime = refreshed end
            end
            window:drawText(tostring(installedAny.grade) .. " Filtered Air Intake",
                hx, hy, 0.40,1.00,0.40,1,UIFont.Small); hy = hy + 18
            window:drawText("Filter Capacity: " .. tostring(math.floor((status.capacity or 0) + 0.5)) .. " / " .. tostring(math.floor((status.maximum or 0) + 0.5)),
                hx, hy, 0.97,0.97,0.97,1,UIFont.Small); hy = hy + 18
            local mediaKnown = GSVU4FilteredAirIntake.hasRecordedFilterMedia(installedAny)
            window:drawText("Installed filters: " .. GSVU4FilteredAirIntake.getFilterMediaSummary(installedAny),
                hx, hy, mediaKnown and 0.85 or 1.00, mediaKnown and 0.85 or 0.70, mediaKnown and 0.85 or 0.35,1,UIFont.Small); hy = hy + 18
            local seal = status.seal and status.seal.sealed
            window:drawText("Cabin Seal: " .. (seal and "SEALED" or "BREACHED"),
                hx, hy, seal and 0.40 or 1.00, seal and 1.00 or 0.40, 0.40,1,UIFont.Small); hy = hy + 18
            window:drawText("Engine: " .. (status.engineRunning and "Running" or "Stopped"),
                hx, hy, 0.97,0.97,0.97,1,UIFont.Small); hy = hy + 18
            local protectionActive = runtime and runtime.active == true
            window:drawText("Corpse-fume Protection: " .. (protectionActive and "ACTIVE" or "INACTIVE"),
                hx, hy, protectionActive and 0.40 or 1.00, protectionActive and 1.00 or 0.55, 0.40,1,UIFont.Small); hy = hy + 18
            if not status.active and status.reason then
                window:drawText("Reason: " .. tostring(status.reason), hx, hy, 1.00,0.55,0.35,1,UIFont.Small); hy = hy + 18
            elseif status.active and not protectionActive then
                window:drawText(runtime and "Waiting for corpse exposure." or "Protection status pending.",
                    hx, hy, 0.80,0.80,0.80,1,UIFont.Small); hy = hy + 18
            end
        elseif selected.upgradeId == "EngineScoop" then
            local icfg = GSVU4UpgradesConfig.getGradeConfig("EngineScoop", installedAny.grade) or cfg
            local power = math.floor(((tonumber(icfg.engineForceMultiplier) or 1.0) - 1.0) * 100 + 0.5)
            local fuel = math.floor((tonumber(icfg.extraFuelFraction) or 0) * 100 + 0.5)
            window:drawText(tostring(icfg.label or "Engine Scoop"),
                hx, hy, 0.40,1.00,0.40,1,UIFont.Small); hy = hy + 18
            window:drawText("Engine force: +" .. tostring(power) .. "%",
                hx, hy, 0.40,1.00,0.40,1,UIFont.Small); hy = hy + 18
            window:drawText("Fuel consumption: +" .. tostring(fuel) .. "%",
                hx, hy, 1.00,0.65,0.45,1,UIFont.Small); hy = hy + 18
            window:drawText("Passive wear: 1 condition / " .. tostring(icfg.wearHoursPerCondition or 0) .. " running hours",
                hx, hy, 1.00,0.55,0.35,1,UIFont.Small); hy = hy + 18
            window:drawText("High-speed stress: " .. tostring(icfg.stressSpeedMph or 0) .. " mph, " .. tostring(icfg.stressGraceSeconds or 0) .. " sec grace",
                hx, hy, 1.00,0.55,0.35,1,UIFont.Small); hy = hy + 18
            local vdata = window.vehicle and window.vehicle.getModData and window.vehicle:getModData() or nil
            local runtime = vdata and vdata.gEngineScoopRuntime or nil
            if runtime and tonumber(runtime.wearHours) then
                window:drawText(string.format("Wear progress: %.2f / %.2f hours",
                    tonumber(runtime.wearHours) or 0,
                    tonumber(icfg.wearHoursPerCondition) or 0),
                    hx, hy, 0.80,0.80,0.80,1,UIFont.Small); hy = hy + 18
            end
            if runtime and tonumber(runtime.stressSeconds) and tonumber(runtime.stressSeconds) > 0 then
                window:drawText(string.format("Stress exposure: %.0f / %.0f sec",
                    tonumber(runtime.stressSeconds) or 0,
                    tonumber(icfg.stressGraceSeconds) or 0),
                    hx, hy, 1.00,0.65,0.45,1,UIFont.Small); hy = hy + 18
            end
        elseif selected.upgradeId == "ExtraFuelStorage" then
            local icfg = GSVU4UpgradesConfig.getGradeConfig("ExtraFuelStorage", installedAny.grade)
            local bonus = icfg and icfg.fuelBonus or 0
            local pen   = icfg and icfg.trunkPenalty or 0
            window:drawText(installedAny.grade ..
                " (+" .. bonus .. " L fuel, -" .. pen .. " cargo capacity)",
                hx, hy, 0.40,1.00,0.40,1,UIFont.Small); hy = hy + 18
            local cargoInfo = GSVU4UpgradesConfig.getTrunkInfo and GSVU4UpgradesConfig.getTrunkInfo(window.vehicle) or nil
            local cargoLabel = cargoInfo and cargoInfo.label or "Cargo Compartment"
            local vdata = window.vehicle and window.vehicle.getModData and window.vehicle:getModData() or nil
            local originalCap = vdata and tonumber(vdata.GSVU4_origTrunkCap) or nil
            local targetCap = vdata and tonumber(vdata.GSVU4_targetTrunkCap) or (cargoInfo and tonumber(cargoInfo.capacity) or nil)
            if originalCap and targetCap then
                window:drawText("Cargo compartment: " .. cargoLabel,
                    hx, hy, 0.97,0.97,0.97,1,UIFont.Small); hy = hy + 18
                window:drawText(string.format("Capacity: %d -> %d (-%d)",
                    originalCap, targetCap, pen),
                    hx, hy, 0.97,0.97,0.97,1,UIFont.Small); hy = hy + 18
            else
                window:drawText("Cargo compartment: " .. cargoLabel,
                    hx, hy, 0.97,0.97,0.97,1,UIFont.Small); hy = hy + 18
            end
            local fuelInfo = GSVU4UpgradesConfig.getEffectiveFuelCapacity(window.vehicle)
            if fuelInfo then
                -- Read current live fuel amount
                local gasPart = window.vehicle and window.vehicle.getPartById
                    and window.vehicle:getPartById("GasTank")
                local currentFuel = 0
                if gasPart and gasPart.getContainerContentAmount then
                    currentFuel = tonumber(gasPart:getContainerContentAmount()) or 0
                end
                local effectiveCap = fuelInfo.effective

                local reserve    = fuelInfo.reserve   -- aux reserve remaining
                local totalFuel  = currentFuel + reserve
                local totalCap   = effectiveCap
                local totalPct   = math.floor((totalFuel / math.max(totalCap, 1)) * 100 + 0.5)

                -- Total label
                window:drawText(
                    string.format("Total Fuel: %.1fL / %dL  (%d%%)",
                        totalFuel, totalCap, totalPct),
                    hx, hy, 0.97,0.97,0.97,1,UIFont.Small); hy = hy + 18

                -- Combined progress bar (main tank shown first, reserve shown after)
                local barW = helpW - 24
                local barH = 12
                -- Background
                window:drawRect(hx, hy, barW, barH, 0.9, 0.10, 0.10, 0.10)

                -- Main tank portion (orange-yellow)
                local mainPct = currentFuel / math.max(totalCap, 1)
                local mainW   = math.max(0, math.floor(barW * mainPct + 0.5))
                if mainW > 0 then
                    window:drawRect(hx, hy, mainW, barH, 0.9, 0.95, 0.70, 0.15)
                end

                -- Reserve portion (blue-teal, stacked after main)
                if reserve > 0.001 then
                    local resPct = reserve / math.max(totalCap, 1)
                    local resW   = math.max(0, math.floor(barW * resPct + 0.5))
                    if resW > 0 then
                        window:drawRect(hx + mainW, hy, resW, barH, 0.9, 0.20, 0.65, 0.90)
                    end
                end

                -- Divider between main and reserve
                if mainW > 0 and mainW < barW then
                    window:drawRect(hx + mainW, hy, 1, barH, 1.0, 1.0, 1.0, 1.0)
                end

                window:drawRectBorder(hx, hy, barW, barH, 0.9, 0.55, 0.55, 0.55)
                hy = hy + barH + 8

                -- Legend
                window:drawRect(hx,     hy+2, 10, 8, 0.9, 0.95, 0.70, 0.15)  -- main swatch
                window:drawText(string.format("Main: %.1fL", currentFuel),
                    hx+14, hy, 0.97,0.97,0.97,1,UIFont.Small)
                window:drawRect(hx+100, hy+2, 10, 8, 0.9, 0.20, 0.65, 0.90)  -- reserve swatch
                window:drawText(string.format("Reserve: %.1fL / %dL", reserve, fuelInfo.bonus),
                    hx+114, hy, 0.97,0.97,0.97,1,UIFont.Small)
                hy = hy + 20

                window:drawText(
                    "Reserve tops up main tank automatically while driving.",
                    hx, hy, 0.85,0.85,0.85,1,UIFont.Small); hy = hy + 16
                window:drawText(
                    "* Mechanics gauge shows main tank only",
                    hx, hy, 0.85,0.85,0.85,1,UIFont.Small); hy = hy + 18
            else
                hy = hy + 4
            end
        elseif (GSVU4UpgradesConfig.isRoofLightUpgradeId and GSVU4UpgradesConfig.isRoofLightUpgradeId(selected.upgradeId)) then
            window:drawText(installedAny.grade .. " " .. uLabel,
                hx, hy, 0.40,1.00,0.40,1,UIFont.Small); hy = hy + 22
        elseif selected.upgradeId == "AutoTuneMilitaryRadio" then
            window:drawText("Auto Tune Military Radio installed",
                hx, hy, 0.40,1.00,0.40,1,UIFont.Small); hy = hy + 22
        elseif selected.upgradeId == "TyreChains" then
            local chainHp = getInstalledUpgradeHealth(installedAny)
            window:drawText("Installed - condition " .. tostring(chainHp) .. "%",
                hx, hy, 0.40,1.00,0.40,1,UIFont.Small); hy = hy + 22
        elseif selected.upgradeId == "EngineScoop" then
            local scoopCfg = GSVU4UpgradesConfig.getGradeConfig("EngineScoop", installedAny.grade)
            window:drawText(tostring(scoopCfg and scoopCfg.label or "Engine Scoop"),
                hx, hy, 0.40,1.00,0.40,1,UIFont.Small); hy = hy + 22
        else
            window:drawText(installedAny.grade ..
                " (Capacity +" .. tostring(installedAny.capacity or 0) .. ")",
                hx, hy, 0.40,1.00,0.40,1,UIFont.Small); hy = hy + 22
        end
    else
        window:drawText("None", hx, hy, 0.97,0.97,0.97,1,UIFont.Small); hy = hy + 22
    end

    window:drawText("Progression:", hx, hy, 1.00,0.88,0.50,1,UIFont.Small); hy = hy + 18
    if (GSVU4UpgradesConfig.isRoofLightUpgradeId and GSVU4UpgradesConfig.isRoofLightUpgradeId(selected.upgradeId)) then
        window:drawText("Single-stage light option", hx, hy, 0.97,0.97,0.97,1,UIFont.Small); hy = hy + 24
    elseif selected.upgradeId == "AutoTuneMilitaryRadio" then
        window:drawText("Single-stage radio module", hx, hy, 0.97,0.97,0.97,1,UIFont.Small); hy = hy + 24
    elseif selected.upgradeId == "TyreChains" then
        window:drawText("Single-stage tyre chain set", hx, hy, 0.97,0.97,0.97,1,UIFont.Small); hy = hy + 24
    elseif selected.upgradeId == "Plow" then
        window:drawText("Standard or Reinforced Toothed (remove to swap)", hx, hy, 0.97,0.97,0.97,1,UIFont.Small); hy = hy + 24
    elseif selected.upgradeId == "EngineScoop" then
        window:drawText("Six alternative scoop shapes (remove to swap)", hx, hy, 0.97,0.97,0.97,1,UIFont.Small); hy = hy + 24
    else
        window:drawText("Basic -> Standard -> Military", hx, hy, 0.97,0.97,0.97,1,UIFont.Small); hy = hy + 24
    end
    if window.gsvu4RepairUpgradeButton then window.gsvu4RepairUpgradeButton:setTitle("Repair Upgrade") end
    if window.gsvu4RemoveUpgradeButton then window.gsvu4RemoveUpgradeButton:setTitle("Remove Upgrade") end

    if current then
        window.gsvu4InstallUpgradeButton:setEnable(false)
        window.gsvu4InstallUpgradeButton:setTitle(uLabel .. " Installed")
        local currentHealth = getInstalledUpgradeHealth(current)
        local maximumHealth = getInstalledUpgradeMaxHealth(selected.upgradeId, current)
        window.gsvu4RepairUpgradeButton:setEnable(currentHealth < maximumHealth)
        window.gsvu4RemoveUpgradeButton:setEnable(true)
        if selected.upgradeId == "TyreChains" then
            window.gsvu4RepairUpgradeButton:setTitle("Repair Tyre Chains")
            window.gsvu4RemoveUpgradeButton:setTitle("Remove Tyre Chains")
        elseif selected.upgradeId == "FilteredAirIntake" and GSVU4FilteredAirIntake then
            local isOpenTop = GSVU4FilteredAirIntake.isOpenTopVehicle
                and GSVU4FilteredAirIntake.isOpenTopVehicle(window.vehicle) == true
            local filterStatus = GSVU4FilteredAirIntake.getStatus(window.vehicle)
            window.gsvu4RemoveUpgradeButton:setTitle("Remove Air Intake")
            if isOpenTop then
                window.gsvu4InstallUpgradeButton:setTitle("Open-Top Vehicle")
                window.gsvu4RepairUpgradeButton:setTitle("Filter Use Unavailable")
                window.gsvu4RepairUpgradeButton:setEnable(false)
            else
                window.gsvu4RepairUpgradeButton:setTitle("Replace Filters")
                local replacementNeed = tonumber(filterStatus.maximum) or 0
                local replacementAvailable = GSVU4FilteredAirIntake.getAvailableFilterCapacity(window.character)
                window.gsvu4RepairUpgradeButton:setEnable(
                    (tonumber(filterStatus.capacity) or 0) < replacementNeed
                    and replacementAvailable >= replacementNeed
                )
            end
        end

        local installedText = current.grade .. " " .. uLabel .. " Installed"
        window:drawText("Status:", hx, hy, 1.00,0.88,0.50,1,UIFont.Small); hy = hy + 18
        window:drawText(installedText, hx, hy, 0.40,1.00,0.40,1,UIFont.Small); hy = hy + 18
        local healthPercent = math.floor((currentHealth / math.max(1, maximumHealth)) * 100 + 0.5)
        if selected.upgradeId == "FilteredAirIntake" and GSVU4FilteredAirIntake then
            local filterStatus = GSVU4FilteredAirIntake.getStatus(window.vehicle)
            local replacementAvailable = GSVU4FilteredAirIntake.getAvailableFilterCapacity(window.character)
            window:drawText("Filter: " .. tostring(math.floor((filterStatus.capacity or 0) + 0.5)) .. " / " .. tostring(math.floor((filterStatus.maximum or 0) + 0.5)), hx, hy, 0.97,0.97,0.97,1,UIFont.Small); hy = hy + 18
            if (tonumber(filterStatus.capacity) or 0) < (tonumber(filterStatus.maximum) or 0) then
                window:drawText("Available replacement media: " .. tostring(replacementAvailable) .. " / " .. tostring(math.floor((filterStatus.maximum or 0) + 0.5)), hx, hy, replacementAvailable >= (filterStatus.maximum or 0) and 0.40 or 1.00, replacementAvailable >= (filterStatus.maximum or 0) and 1.00 or 0.55, 0.40,1,UIFont.Small); hy = hy + 18
            end
            window:drawText(GSVU4FilteredAirIntake.hasRecordedFilterMedia(current) and "Removed filters return with their remaining charge." or "Legacy install: filter types will be tracked after replacement.", hx, hy, 0.80,0.80,0.80,1,UIFont.Small); hy = hy + 18
        end
        window:drawText("Health: " .. tostring(currentHealth) .. " / " .. tostring(maximumHealth) .. " (" .. tostring(healthPercent) .. "%)", hx, hy, 0.97,0.97,0.97,1,UIFont.Small); hy = hy + 18
        window:drawText("Uninstall returns: " .. getUpgradeReturnText(selected.upgradeId, current.grade, getInstalledUpgradeHealth(current)), hx, hy, 0.97,0.97,0.97,1,UIFont.Small)
    elseif report.ok then
        window.gsvu4InstallUpgradeButton:setEnable(true)
        window.gsvu4InstallUpgradeButton:setTitle("Install " .. uLabel)
        window.gsvu4RepairUpgradeButton:setEnable(false)
        window.gsvu4RemoveUpgradeButton:setEnable(false)
        window:drawText("Ready to install.", hx, hy, 0.40,1.00,0.40,1,UIFont.Small)
    else
        window.gsvu4InstallUpgradeButton:setEnable(false)
        window.gsvu4InstallUpgradeButton:setTitle("Missing Requirements")
        window.gsvu4RepairUpgradeButton:setEnable(false)
        window.gsvu4RemoveUpgradeButton:setEnable(false)

        window:drawText("Blocked:", hx, hy, 1.00,0.88,0.50,1,UIFont.Small); hy = hy + 18
        for i = 1, math.min(4, #report.reasons) do
            window:drawText("- " .. tostring(report.reasons[i]), hx, hy, 1.00,0.40,0.40,1,UIFont.Small)
            hy = hy + 16
        end
    end
end

if VehicleArmorWindow and not VehicleArmorWindow.GSVU4_UpgradeTabsWrapped then
    local oldCreateChildren = VehicleArmorWindow.createChildren
    function VehicleArmorWindow:createChildren()
        if oldCreateChildren then oldCreateChildren(self) end
        createUpgradeControls(self)
    end

    local oldPrerender = VehicleArmorWindow.prerender
    function VehicleArmorWindow:prerender()
        if (self.gsvu4Mode or "Armor") == "Armor" then
            if oldPrerender then oldPrerender(self) else ISPanel.prerender(self) end
            syncModeVisibility(self)
            return
        end

        ISPanel.prerender(self)
        self:drawRect(0, 52, self.width, self.height - 52, 0.92, 0.03, 0.03, 0.03)
        self:drawText("Gore's SVU4", 338, 18, 0.97,0.97,0.97,1,UIFont.Large)
        syncModeVisibility(self)

        if self.gsvu4Mode == "Upgrades" then
            drawUpgradeScreen(self)
        end
    end

    VehicleArmorWindow.GSVU4_UpgradeTabsWrapped = true
end
