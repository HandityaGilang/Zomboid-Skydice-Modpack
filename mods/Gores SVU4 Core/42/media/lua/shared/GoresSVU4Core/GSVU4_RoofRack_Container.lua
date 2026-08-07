--========================================================
-- Gore's SVU4 Core - Roof Rack Native Container
--
-- Injects a GSVU4RoofRack part into every vehicle script at game boot
-- via vehicleScript:Load().
-- The part surfaces as a native loot container and now uses the vanilla
-- TruckBed/rear access area, so players stand where they would stand to
-- access the trunk. No entering the vehicle required.
-- The native container type is deliberately TruckBed to avoid B42.19
-- ItemPickInfo custom-container ID warnings while keeping the part id
-- and installed upgrade state as GSVU4RoofRack.
--
-- Key B42 API facts (from DAMN Library source):
--   instanceItem("Full.Type")      → Java InventoryItem from string
--   part:setInventoryItem(item)    → install item into part slot
--   part:setInventoryItem(nil)     → clear the slot
--   vehicle:transmitPartItem(part) → sync slot to server/clients
--                                    AND triggers loot panel refresh
--========================================================

GSVU4 = GSVU4 or {}
GSVU4.ContainerAccess = GSVU4.ContainerAccess or {}
GSVU4.RoofRack = GSVU4.RoofRack or {}

function GSVU4.ContainerAccess.Roofrack(vehicle, part, chr)
    if chr:getVehicle() then return false end
    if not vehicle:isInArea(part:getArea(), chr) then return false end
    local item = part:getInventoryItem()
    if not item then return false end
    local maxCap = item.getMaxCapacity and item:getMaxCapacity() or 0
    return maxCap and maxCap > 0
end

-- ── Grade → item full type ────────────────────────────────────────────
GSVU4.RoofRack.GRADE_ITEM = {
    Basic    = "Base.GSVU4RoofRackBasic",
    Standard = "Base.GSVU4RoofRackStandard",
    Military = "Base.GSVU4RoofRackMilitary",
}

function GSVU4.RoofRack.gradeToItemType(grade)
    return GSVU4.RoofRack.GRADE_ITEM[grade] or GSVU4.RoofRack.GRADE_ITEM.Basic
end


-- ── Optional roof-rack 3D visual bridge ─────────────────────────────
-- Core owns the native roof rack container part. Optional visual packs,
-- such as Gore's SVU4 Vanilla Cars, can register model names here before
-- OnGameBoot. If no visual pack is loaded, the roof rack remains fully
-- functional but has no 3D model attached.
GSVU4.RoofRack.VisualModelByScriptName = GSVU4.RoofRack.VisualModelByScriptName or {}
GSVU4.RoofRack.VisualModelPatterns = GSVU4.RoofRack.VisualModelPatterns or {}

local function GSVU4_RoofRackIsMPClient()
    return isClient and isClient() == true
end

function GSVU4.RoofRack.registerVisualModels(map, patterns)
    if type(map) == "table" then
        for scriptName, modelSpec in pairs(map) do
            if scriptName and modelSpec then
                -- A visual pack may register either a legacy model-name string
                -- or a table such as:
                -- { model = "GSVU4_Rack_SmallCar02",
                --   offset = "0.0000 0.0800 0.0400" }
                if type(modelSpec) == "table" then
                    GSVU4.RoofRack.VisualModelByScriptName[tostring(scriptName)] = {
                        model = modelSpec.model or modelSpec.file or modelSpec[1],
                        offset = modelSpec.offset,
                        rotate = modelSpec.rotate,
                        scale = modelSpec.scale,
                    }
                else
                    GSVU4.RoofRack.VisualModelByScriptName[tostring(scriptName)] =
                        tostring(modelSpec)
                end
            end
        end
    end

    if type(patterns) == "table" then
        for _, row in ipairs(patterns) do
            if type(row) == "table" and row[1] and row[2] then
                local spec = row[2]
                if type(spec) == "table" then
                    spec = {
                        model = spec.model or spec.file or spec[1],
                        offset = spec.offset,
                        rotate = spec.rotate,
                        scale = spec.scale,
                    }
                else
                    spec = tostring(spec)
                end
                GSVU4.RoofRack.VisualModelPatterns[
                    #GSVU4.RoofRack.VisualModelPatterns + 1
                ] = { tostring(row[1]), spec }
            end
        end
    end
end

function GSVU4.RoofRack.resolveVisualModel(vehicleScriptFullName)
    if not vehicleScriptFullName then return nil end

    local scriptName = tostring(vehicleScriptFullName):gsub("^[^%.]+%.", "")
    local direct = GSVU4.RoofRack.VisualModelByScriptName[scriptName]
    if direct then return direct end

    local lower = string.lower(scriptName)
    for _, row in ipairs(GSVU4.RoofRack.VisualModelPatterns or {}) do
        if row and row[1] and row[2]
        and string.find(lower, tostring(row[1]), 1, true) then
            return row[2]
        end
    end

    return nil
end

function GSVU4.RoofRack.setVisualVisible(vehicle, part, visible)
    if not part or not part.setModelVisible then return false end

    local ok = pcall(function()
        part:setModelVisible("Default", visible == true)
    end)

    -- Cosmetic model visibility is client-local in MP.
    if ok
    and not GSVU4_RoofRackIsMPClient()
    and vehicle
    and vehicle.transmitPartModData then
        pcall(function()
            vehicle:transmitPartModData(part)
        end)
    end

    return ok
end

function GSVU4.RoofRack.setPartItem(vehicle, part, fullType)
    if not part then return false end

    -- MP clients never create, clear or transmit native part items.
    -- The server sends the authoritative rack item/container packet.
    if GSVU4_RoofRackIsMPClient() then
        return GSVU4.RoofRack.setVisualVisible(
            vehicle,
            part,
            fullType ~= nil
        )
    end

    if not fullType then
        pcall(function()
            part:setInventoryItem(nil)
        end)
        GSVU4.RoofRack.setVisualVisible(vehicle, part, false)

        if vehicle and vehicle.transmitPartItem then
            pcall(function()
                vehicle:transmitPartItem(part)
            end)
        end
        return true
    end

    if not instanceItem then return false end
    local ok, item = pcall(function()
        return instanceItem(fullType)
    end)
    if not ok or not item then return false end

    pcall(function()
        part:setInventoryItem(item)
    end)
    GSVU4.RoofRack.setVisualVisible(vehicle, part, true)

    if vehicle and vehicle.transmitPartItem then
        pcall(function()
            vehicle:transmitPartItem(part)
        end)
    end

    return true
end


-- Keep the real PZ container picker type vanilla-safe even though the SVU4 part
-- id remains GSVU4RoofRack. This also migrates already-saved rack containers
local function GSVU4_RoofRackForceTruckBedContainerType(part)
    if not part then return end

    local okContainer, container = pcall(function()
        if part.getItemContainer then
            return part:getItemContainer()
        end
        return nil
    end)
    if not okContainer or not container then return end

    -- B42 exposes this as a Java method in normal vehicle containers. Keep this
    -- fully pcall-wrapped so older/odd contexts simply skip it.
    pcall(function()
        if container.setType then
            container:setType("TruckBed")
        end
    end)
end

-- ── Part callbacks ────────────────────────────────────────────────────
GSVU4.RoofRack.Create = {}
GSVU4.RoofRack.Init   = {}

-- Called when a new vehicle is first created — start with empty slot.
function GSVU4.RoofRack.Create.GSVU4RoofRack(vehicle, part)
    pcall(function() part:setInventoryItem(nil) end)
    GSVU4_RoofRackForceTruckBedContainerType(part)
end

-- Called each time the vehicle chunk loads — sync slot to modData.
-- transmitPartItem is called so the top inventory panel picks up the
-- container immediately without the player needing to enter the vehicle.
function GSVU4.RoofRack.Init.GSVU4RoofRack(vehicle, part)
    if not vehicle or not part then return end
    GSVU4_RoofRackForceTruckBedContainerType(part)
    local vdata = vehicle:getModData()
    local rack  = vdata and vdata.gUpgrades and vdata.gUpgrades.RoofRack

    if not rack or not rack.grade then
        pcall(function() part:setInventoryItem(nil) end)
        GSVU4.RoofRack.setVisualVisible(vehicle, part, false)
        -- No transmit needed when clearing — engine handles nil natively.
        return
    end

    local wantedType  = GSVU4.RoofRack.gradeToItemType(rack.grade)
    local current     = part:getInventoryItem()
    local currentType = current and current.getFullType and current:getFullType() or nil

    if currentType ~= wantedType then
        if instanceItem then
            local ok, item = pcall(function() return instanceItem(wantedType) end)
            if ok and item then
                pcall(function() part:setInventoryItem(item) end)
                GSVU4.RoofRack.setVisualVisible(vehicle, part, true)
                -- transmitPartItem forces the loot panel to notice this container.
                if vehicle.transmitPartItem then
                    pcall(function() vehicle:transmitPartItem(part) end)
                end
            end
        end
    else
        GSVU4.RoofRack.setVisualVisible(vehicle, part, true)
        -- Item already correct — still transmit once so the panel registers
        -- it on fresh load without requiring enter/exit.
        if vehicle.transmitPartItem then
            pcall(function() vehicle:transmitPartItem(part) end)
        end
    end
end

-- ── Script injection ──────────────────────────────────────────────────
local function GSVU4_BuildRoofRackInjection(visualSpec)
    local lines = {
        "{",
            "part GSVU4RoofRack",
            "{",
                "category = Other,",
                "area = TruckBed,",
                "mechanicRequireKey = false,",
                "setAllModelsVisible = false,",
                "container",
                "{",
                    "type = TruckBed,",
                    "conditionAffectsCapacity = false,",
                    "test = GSVU4.ContainerAccess.Roofrack,",
                "}",
    }

    local modelName = visualSpec
    local offset = nil
    local rotate = nil
    local scale = nil

    if type(visualSpec) == "table" then
        modelName = visualSpec.model or visualSpec.file or visualSpec[1]
        offset = visualSpec.offset
        rotate = visualSpec.rotate
        scale = visualSpec.scale
    end

    if modelName and modelName ~= "" then
        lines[#lines + 1] = "model Default"
        lines[#lines + 1] = "{"
        lines[#lines + 1] = "file = " .. tostring(modelName) .. ","
        if offset and tostring(offset) ~= "" then
            lines[#lines + 1] = "offset = " .. tostring(offset) .. ","
        end
        if rotate and tostring(rotate) ~= "" then
            lines[#lines + 1] = "rotate = " .. tostring(rotate) .. ","
        end
        if scale and tostring(scale) ~= "" then
            lines[#lines + 1] = "scale = " .. tostring(scale) .. ","
        end
        lines[#lines + 1] = "}"
    end

    lines[#lines + 1] = "lua { create = GSVU4.RoofRack.Create.GSVU4RoofRack, init = GSVU4.RoofRack.Init.GSVU4RoofRack, }"
    lines[#lines + 1] = "}"
    lines[#lines + 1] = "}"
    return table.concat(lines, "\n")
end

local GSVU4_injectedScripts = {}

local function GSVU4_InjectRoofRackPart(vehicleScriptFullName)
    if GSVU4_injectedScripts[vehicleScriptFullName] then return false end
    GSVU4_injectedScripts[vehicleScriptFullName] = true

    local vscript = getScriptManager():getVehicle(vehicleScriptFullName)
    if not vscript then return false end
    if vscript:getPartById("GSVU4RoofRack") then return false end

    local scriptName = string.gsub(vehicleScriptFullName, "^[^%.]+%.", "")
    local visualModelName = GSVU4.RoofRack.resolveVisualModel(vehicleScriptFullName)
    local injection = GSVU4_BuildRoofRackInjection(visualModelName)
    local ok, err = pcall(function() vscript:Load(scriptName, injection) end)
    if not ok then
        return false
    end
    return true
end

Events.OnGameBoot.Add(function()
    local sm = getScriptManager()
    if not sm then return end

    local vehicles = nil
    if sm.getAllVehicleScripts then
        local ok, v = pcall(function() return sm:getAllVehicleScripts() end)
        if ok then vehicles = v end
    end
    if not vehicles and sm.getVehicles then
        local ok, v = pcall(function() return sm:getVehicles() end)
        if ok then vehicles = v end
    end
    if not vehicles then
        return
    end

    local total, injected = 0, 0
    if vehicles.size and vehicles.get then
        total = vehicles:size()
        for i = 0, total - 1 do
            local ok, vs = pcall(function() return vehicles:get(i) end)
            if ok and vs and vs.getFullName then
                local fn = vs:getFullName()
                if fn and GSVU4_InjectRoofRackPart(fn) then injected = injected + 1 end
            end
        end
    else
        for _, vs in pairs(vehicles) do
            total = total + 1
            local fn = vs.getFullName and vs:getFullName() or nil
            if fn and GSVU4_InjectRoofRackPart(fn) then injected = injected + 1 end
        end
    end
end)
--========================================================
-- Immediate native roof rack container refresh helpers
--
-- Installing the roof rack updates SVU4 modData immediately, but the vanilla
-- loot panel only sees the roof rack once the injected GSVU4RoofRack part has
-- a real MechanicsItem installed in its slot on the local vehicle object.
-- Entering/exiting the vehicle causes the game to rebuild that state naturally;
-- these helpers do the same sync on demand after install/upgrade/uninstall.
--========================================================

function GSVU4.RoofRack.getPart(vehicle)
    if not vehicle or not vehicle.getPartById then return nil end
    local ok, part = pcall(function() return vehicle:getPartById("GSVU4RoofRack") end)
    if ok then return part end
    return nil
end

function GSVU4.RoofRack.getContainer(vehicle)
    local part = GSVU4.RoofRack.getPart(vehicle)
    if not part then return nil end
    if part.getItemContainer then
        local ok, ic = pcall(function() return part:getItemContainer() end)
        if ok and ic then return ic end
    end
    if part.getContainer then
        local ok, ic = pcall(function() return part:getContainer() end)
        if ok and ic then return ic end
    end
    return nil
end

function GSVU4.RoofRack.SyncVisualOnly(vehicle)
    if not vehicle then return false end

    local part = GSVU4.RoofRack.getPart(vehicle)
    if not part then return false end

    local data =
        vehicle.getModData and vehicle:getModData() or nil
    local rack =
        data
        and data.gUpgrades
        and data.gUpgrades.RoofRack
        or nil

    local visible =
        rack ~= nil
        and rack.grade ~= nil
        and rack.grade ~= "Removed"

    GSVU4.RoofRack.setVisualVisible(
        vehicle,
        part,
        visible
    )

    if visible and GSVU4.RoofRack.getContainer then
        pcall(function()
            GSVU4.RoofRack.getContainer(vehicle)
        end)
    end

    return true
end

function GSVU4.RoofRack.SyncInstalledContainer(vehicle, transmitWhenUnchanged)
    if not vehicle then return false end

    if GSVU4_RoofRackIsMPClient() then
        return GSVU4.RoofRack.SyncVisualOnly(vehicle)
    end
    local part = GSVU4.RoofRack.getPart(vehicle)
    if not part then return false end

    local vdata = vehicle.getModData and vehicle:getModData() or nil
    local rack = vdata and vdata.gUpgrades and vdata.gUpgrades.RoofRack or nil

    if not rack or not rack.grade or rack.grade == "Removed" then
        local current = part.getInventoryItem and part:getInventoryItem() or nil
        if current then
            GSVU4.RoofRack.setPartItem(vehicle, part, nil)
        else
            GSVU4.RoofRack.setVisualVisible(vehicle, part, false)
        end
        if transmitWhenUnchanged and vehicle.transmitPartItem then
            pcall(function() vehicle:transmitPartItem(part) end)
        end
        return true
    end

    local wantedType = GSVU4.RoofRack.gradeToItemType(rack.grade)
    local current = part.getInventoryItem and part:getInventoryItem() or nil
    local currentType = current and current.getFullType and current:getFullType() or nil

    if currentType ~= wantedType then
        GSVU4.RoofRack.setPartItem(vehicle, part, wantedType)
    else
        GSVU4.RoofRack.setVisualVisible(vehicle, part, true)
    end
    if transmitWhenUnchanged and vehicle.transmitPartItem then
        pcall(function() vehicle:transmitPartItem(part) end)
    end

    -- Touch the container once. In B42 this helps force lazy container creation
    -- on the local vehicle object before the player has entered/exited the car.
    GSVU4.RoofRack.getContainer(vehicle)

    return true
end

function GSVU4.RoofRack.RefreshInventoryPages()
    -- Defensive UI nudge only. Method names differ between B42 builds/modded UI;
    -- every call is nil-checked and protected.
    local pages = {}
    local function addPage(page)
        if page and not pages[page] then pages[page] = true end
    end

    if getPlayerInventory then
        for i = 0, 3 do
            local ok, page = pcall(function() return getPlayerInventory(i) end)
            if ok then addPage(page) end
        end
    end
    if getPlayerLoot then
        for i = 0, 3 do
            local ok, page = pcall(function() return getPlayerLoot(i) end)
            if ok then addPage(page) end
        end
    end

    for page, _ in pairs(pages) do
        page.dirty = true
        page.needRefresh = true
        if page.refreshBackpacks then pcall(function() page:refreshBackpacks() end) end
        if page.refreshInventory then pcall(function() page:refreshInventory() end) end
        if page.update then pcall(function() page:update() end) end
        local pane = page.inventoryPane
        if pane then
            pane.dirty = true
            if pane.refreshContainer then pcall(function() pane:refreshContainer() end) end
            if pane.update then pcall(function() pane:update() end) end
        end
    end
end

local function GSVU4_RoofRackVehicleKey(vehicle)
    if not vehicle then return nil end
    local id = nil
    if vehicle.getOnlineID then
        local ok, value = pcall(function() return vehicle:getOnlineID() end)
        if ok and value ~= nil then id = "online_" .. tostring(value) end
    end
    if not id and vehicle.getId then
        local ok, value = pcall(function() return vehicle:getId() end)
        if ok and value ~= nil then id = "id_" .. tostring(value) end
    end
    if not id and vehicle.getX and vehicle.getY then
        local ok, x, y, z = pcall(function() return vehicle:getX(), vehicle:getY(), vehicle:getZ() end)
        if ok then id = "pos_" .. tostring(math.floor(tonumber(x) or 0)) .. "_" .. tostring(math.floor(tonumber(y) or 0)) .. "_" .. tostring(math.floor(tonumber(z) or 0)) end
    end
    return id
end

function GSVU4.RoofRack.QueueNativeRefresh(vehicle, attempts)
    if not vehicle then return false end

    if GSVU4_RoofRackIsMPClient() then
        GSVU4.RoofRack.SyncVisualOnly(vehicle)
        GSVU4.RoofRack.RefreshInventoryPages()
        return true
    end

    GSVU4.RoofRack.SyncInstalledContainer(vehicle, true)
    return true
end

-- Global wrappers used by older server code paths in this mod.  VehicleArmor_Server.lua
-- calls these names before its later local helper declarations are in scope, so keeping
-- globals here makes MP install/uninstall use the same native container sync as SP.
function GSVU4_ApplyRoofRackContainer(vehicle)
    if GSVU4 and GSVU4.RoofRack and GSVU4.RoofRack.SyncInstalledContainer then
        return GSVU4.RoofRack.SyncInstalledContainer(vehicle, true)
    end
    return false
end

function GSVU4_DrainRoofRackContainer(vehicle, player)
    if not GSVU4 or not GSVU4.RoofRack then return false end
    local ic = GSVU4.RoofRack.getContainer and GSVU4.RoofRack.getContainer(vehicle) or nil
    if ic and player and player.getInventory then
        local inv = player:getInventory()
        if inv then
            local okItems, items = pcall(function() return ic:getItems() end)
            if okItems and items then
                local toMove = {}
                for i = 0, items:size() - 1 do
                    local okItem, item = pcall(function() return items:get(i) end)
                    if okItem and item then toMove[#toMove + 1] = item end
                end
                for _, item in ipairs(toMove) do
                    pcall(function()
                        ic:Remove(item)
                        inv:AddItem(item)
                    end)
                end
            end
        end
    end

    local part = GSVU4.RoofRack.getPart and GSVU4.RoofRack.getPart(vehicle) or nil
    if part then
        GSVU4.RoofRack.setPartItem(vehicle, part, nil)
    end

    local vdata = vehicle and vehicle.getModData and vehicle:getModData() or nil
    if vdata and vdata.gExternalStorage then vdata.gExternalStorage.RoofRack = nil end
    return true
end
