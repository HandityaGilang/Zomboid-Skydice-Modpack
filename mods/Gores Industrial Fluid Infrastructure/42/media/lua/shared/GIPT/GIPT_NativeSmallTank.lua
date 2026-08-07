require "GIPT/GIPT_Constants"
require "GIPT/GIPT_Objects"

GIPT.FLUID_NATIVE = GIPT.FLUID_NATIVE or "NATIVE"
GIPT.NATIVE_SMALL_STORAGE_VERSION = 1

local EPSILON = 0.0001

-- Empty native FluidContainer components must not be copied into the single
-- inventory item used by a multi-square moveable. Vanilla logs a component
-- transfer warning for that combination. These weak references suppress
-- component recreation only while an empty compact tank is being picked up or
-- rotated.
local moveCleanupDepth = 0
local moveCleanupObjects = setmetatable({}, { __mode = "k" })

local function descriptorFor(obj)
    if not obj or GIPT.getTankClass(obj) ~= "SMALL" or not obj:getSquare() then return nil end
    local descriptor = GIPT.getInstallationDescriptor(obj:getX(), obj:getY(), obj:getZ())
    if descriptor and descriptor.tankClass == "SMALL" then return descriptor end
    return nil
end

local function getController(obj)
    local descriptor = descriptorFor(obj)
    return descriptor and descriptor.controller or obj
end

GIPT.getSmallTankController = getController

function GIPT.getNativeSmallTankCapacity()
    local multiplier = 8
    if SandboxVars and SandboxVars.GIPT and SandboxVars.GIPT.SmallTankCapacity then
        multiplier = tonumber(SandboxVars.GIPT.SmallTankCapacity) or multiplier
    end
    multiplier = math.max(1, math.floor(multiplier))
    return multiplier * 50
end

local function syncEntity(obj)
    if not obj then return end
    if obj.sync then
        pcall(function() obj:sync() end)
    elseif obj.sendSyncEntity then
        pcall(function() obj:sendSyncEntity(nil) end)
    end
end

local function transmitData(obj)
    if obj and obj.transmitModData and not isClient() then
        pcall(function() obj:transmitModData() end)
    end
end

local function amountOf(container)
    if not container or not container.getAmount then return 0 end
    local ok, value = pcall(function() return container:getAmount() end)
    return ok and math.max(0, tonumber(value) or 0) or 0
end

local function capacityOf(container)
    if not container or not container.getCapacity then return GIPT.getNativeSmallTankCapacity() end
    local ok, value = pcall(function() return container:getCapacity() end)
    return ok and math.max(0, tonumber(value) or GIPT.getNativeSmallTankCapacity()) or GIPT.getNativeSmallTankCapacity()
end

local function configureContainer(container, capacity)
    if not container then return end
    if container.setInputLocked then pcall(function() container:setInputLocked(false) end) end
    if container.setOutputLocked then pcall(function() container:setOutputLocked(false) end) end
    if container.setCapacity then
        pcall(function() container:setCapacity(math.max(capacity, amountOf(container))) end)
    end
end

local function createContainer(controller, capacity)
    if not controller or isClient() then return nil end
    if not ComponentType or not ComponentType.FluidContainer or not GameEntityFactory then return nil end

    local okComponent, component = pcall(function()
        return ComponentType.FluidContainer:CreateComponent()
    end)
    if not okComponent or not component then return nil end

    configureContainer(component, capacity)
    local okAdd = pcall(function()
        GameEntityFactory.AddComponent(controller, true, component)
    end)
    if not okAdd then return nil end

    local container = controller:getFluidContainer() or component
    configureContainer(container, capacity)
    syncEntity(controller)
    return container
end

local function removeContainer(obj)
    if not obj or isClient() or not GameEntityFactory or not ComponentType then return false end
    local ok = pcall(function()
        GameEntityFactory.RemoveComponentType(obj, ComponentType.FluidContainer)
    end)
    if ok then syncEntity(obj) end
    return ok
end

local function detachContainerForMove(obj)
    if not obj or not GameEntityFactory or not ComponentType or not ComponentType.FluidContainer then return false end
    local container = obj.getFluidContainer and obj:getFluidContainer() or nil
    if not container then return true end
    if amountOf(container) > EPSILON then return false end
    -- Do not sync an intermediate empty-component removal. The world object is
    -- immediately picked up or replaced by vanilla's rotation pipeline.
    return pcall(function()
        GameEntityFactory.RemoveComponentType(obj, ComponentType.FluidContainer)
    end)
end

function GIPT.isNativeSmallTankMoveCleanup(obj)
    if moveCleanupDepth <= 0 or not obj then return false end
    if moveCleanupObjects[obj] then return true end
    local controller = getController(obj)
    return controller and moveCleanupObjects[controller] == true or false
end

function GIPT.beginNativeSmallTankMoveCleanup(objects)
    if type(objects) ~= "table" or #objects == 0 then return false end

    for _, obj in ipairs(objects) do
        if not obj or GIPT.getTankClass(obj) ~= "SMALL" then return false end
        local container = obj.getFluidContainer and obj:getFluidContainer() or nil
        if container and amountOf(container) > EPSILON then return false end
    end

    moveCleanupDepth = moveCleanupDepth + 1
    for _, obj in ipairs(objects) do
        moveCleanupObjects[obj] = true
        local md = obj:getModData()
        md.GIPT = nil
        md.GIPT_Protected = nil
        md.GIPT_Indestructible = nil
    end
    for _, obj in ipairs(objects) do
        detachContainerForMove(obj)
    end
    return true
end

function GIPT.endNativeSmallTankMoveCleanup()
    moveCleanupDepth = math.max(0, moveCleanupDepth - 1)
    if moveCleanupDepth == 0 then
        for obj in pairs(moveCleanupObjects) do moveCleanupObjects[obj] = nil end
    end
end

local function consolidatePair(descriptor, controllerContainer)
    if isClient() or not descriptor or not descriptor.objects or not controllerContainer then return end
    for _, member in ipairs(descriptor.objects) do
        if member ~= descriptor.controller and member.getFluidContainer then
            local other = member:getFluidContainer()
            if other then
                local otherAmount = amountOf(other)
                if otherAmount > EPSILON and FluidContainer and FluidContainer.CanTransfer and FluidContainer.Transfer then
                    local compatible = false
                    local okCompatible, canTransfer = pcall(function()
                        return FluidContainer.CanTransfer(other, controllerContainer)
                    end)
                    compatible = okCompatible and canTransfer == true
                    if compatible then
                        pcall(function() FluidContainer.Transfer(other, controllerContainer, otherAmount) end)
                        syncEntity(descriptor.controller)
                        syncEntity(member)
                    end
                end
                if amountOf(other) <= EPSILON then removeContainer(member) end
            end
        end
    end
end

function GIPT.ensureNativeSmallTank(obj, allowCreate)
    local descriptor = descriptorFor(obj)
    local controller = descriptor and descriptor.controller or getController(obj)
    if not controller then return nil, nil end
    if GIPT.isNativeSmallTankMoveCleanup(controller) then
        local existing = controller.getFluidContainer and controller:getFluidContainer() or nil
        return existing, controller
    end

    local capacity = GIPT.getNativeSmallTankCapacity()
    local container = controller.getFluidContainer and controller:getFluidContainer() or nil
    if not container and allowCreate ~= false then
        container = createContainer(controller, capacity)
    end
    if container then
        configureContainer(container, capacity)
        consolidatePair(descriptor, container)
    end

    return container, controller
end

function GIPT.getNativeSmallTankAmount(container)
    return amountOf(container)
end

function GIPT.getNativeSmallTankContainerCapacity(container)
    return capacityOf(container)
end

function GIPT.getNativeFluidDisplayName(container)
    if not container or amountOf(container) <= EPSILON then return "Empty" end

    if container.isMixture then
        local ok, mixed = pcall(function() return container:isMixture() end)
        if ok and mixed then return "Mixed liquids" end
    end

    if container.getPrimaryFluid then
        local okPrimary, primary = pcall(function() return container:getPrimaryFluid() end)
        if okPrimary and primary and primary.getFluidTypeString then
            local okName, token = pcall(function() return primary:getFluidTypeString() end)
            if okName and token then
                local key = "Fluid_Name_" .. tostring(token)
                local translated = getText and getText(key) or nil
                if translated and translated ~= key then return translated end
                return tostring(token)
            end
        end
    end
    return "Stored liquid"
end

local function migrateLegacySmallData(controller, data, container)
    if not data or data.nativeStorageVersion == GIPT.NATIVE_SMALL_STORAGE_VERSION then return false end
    -- World fluid components are server authoritative. Clients wait for the
    -- component/state sync rather than recreating legacy contents locally.
    if isClient() then return false end
    local amount = math.max(0, tonumber(data.amount) or 0)
    local migrated = false

    -- The stable v1.0.14 compact-tank state stored clean water and gasoline as
    -- numeric modData. Convert only those two proven fluids into the live native
    -- component. Propane intentionally stays on the drainable-item adapter path.
    if container and amountOf(container) <= EPSILON and amount > EPSILON then
        if data.fluidType == GIPT.FLUID_WATER and Fluid and Fluid.Water then
            local moved = math.min(amount, capacityOf(container))
            local ok = pcall(function() container:addFluid(Fluid.Water, moved) end)
            migrated = ok or migrated
        elseif data.fluidType == GIPT.FLUID_GASOLINE and Fluid and Fluid.Petrol then
            local moved = math.min(amount, capacityOf(container))
            local ok = pcall(function() container:addFluid(Fluid.Petrol, moved) end)
            migrated = ok or migrated
        end
    end

    data.nativeStorageVersion = GIPT.NATIVE_SMALL_STORAGE_VERSION
    syncEntity(controller)
    transmitData(controller)
    return migrated
end

function GIPT.ensureSmallTankStorageData(obj, data)
    local controller = getController(obj) or obj
    if not controller then return data end
    if GIPT.isNativeSmallTankMoveCleanup(controller) then return data or {} end

    local md = controller:getModData()
    md.GIPT = md.GIPT or data or {}
    data = md.GIPT

    local container = GIPT.ensureNativeSmallTank(controller, true)
    migrateLegacySmallData(controller, data, container)

    local nativeAmount = amountOf(container)
    local propaneAmount = data.fluidType == GIPT.FLUID_PROPANE and math.max(0, tonumber(data.amount) or 0) or 0

    if propaneAmount > EPSILON then
        -- The modes are mutually exclusive. A compact tank containing propane
        -- cannot simultaneously expose native liquid contents.
        if container and nativeAmount > EPSILON and not isClient() then
            pcall(function() container:Empty() end)
            syncEntity(controller)
        end
        data.fluidType = GIPT.FLUID_PROPANE
        data.amount = propaneAmount
        data.capacity = GIPT.getTankCapacity and GIPT.getTankCapacity(GIPT.FLUID_PROPANE, "SMALL") or 80000
        data.nativeFluidName = nil
    elseif nativeAmount > EPSILON then
        data.fluidType = GIPT.FLUID_NATIVE
        data.amount = nativeAmount
        data.capacity = capacityOf(container)
        data.nativeFluidName = GIPT.getNativeFluidDisplayName(container)
    else
        data.fluidType = GIPT.FLUID_EMPTY
        data.amount = 0
        data.capacity = capacityOf(container)
        data.nativeFluidName = nil
    end

    data.nativeStorageVersion = GIPT.NATIVE_SMALL_STORAGE_VERSION
    data.fluidComposition = nil
    data.version = GIPT.VERSION
    data.initialized = true
    data.tankClass = "SMALL"
    return data
end

function GIPT.getSmallTankStorageState(obj)
    local controller = getController(obj)
    if not controller then return nil end
    local md = controller:getModData()
    md.GIPT = md.GIPT or {}
    local storage = GIPT.ensureSmallTankStorageData(controller, md.GIPT)
    local container = controller.getFluidContainer and controller:getFluidContainer() or nil

    if storage.fluidType == GIPT.FLUID_PROPANE and (tonumber(storage.amount) or 0) > EPSILON then
        return {
            mode = "PROPANE",
            controller = controller,
            data = storage,
            amount = tonumber(storage.amount) or 0,
            capacity = tonumber(storage.capacity) or 0,
            name = "Propane",
        }
    end

    local nativeAmount = amountOf(container)
    return {
        mode = nativeAmount > EPSILON and "NATIVE" or "EMPTY",
        controller = controller,
        data = storage,
        fluidContainer = container,
        amount = nativeAmount,
        capacity = capacityOf(container),
        name = GIPT.getNativeFluidDisplayName(container),
    }
end

function GIPT.smallTankHasAnyFluid(obj)
    local state = GIPT.getSmallTankStorageState(obj)
    return state and (tonumber(state.amount) or 0) > EPSILON or false
end

function GIPT.emptySmallTank(obj)
    local controller = getController(obj)
    if not controller then return false end
    local container = GIPT.ensureNativeSmallTank(controller, true)
    if container and not isClient() then pcall(function() container:Empty() end) end
    local md = controller:getModData()
    md.GIPT = md.GIPT or {}
    md.GIPT.fluidType = GIPT.FLUID_EMPTY
    md.GIPT.amount = 0
    md.GIPT.capacity = capacityOf(container)
    md.GIPT.nativeStorageVersion = GIPT.NATIVE_SMALL_STORAGE_VERSION
    md.GIPT.nativeFluidName = nil
    syncEntity(controller)
    transmitData(controller)
    return true
end

function GIPT.setSmallTankAdminFluid(obj, fluidType, percent)
    local controller = getController(obj)
    if not controller then return false end
    local container = GIPT.ensureNativeSmallTank(controller, true)
    if container and not isClient() then pcall(function() container:Empty() end) end

    local md = controller:getModData()
    md.GIPT = md.GIPT or {}
    local data = md.GIPT
    percent = GIPT.clamp(percent or 0, 0, 100)

    if fluidType == GIPT.FLUID_PROPANE and percent > 0 then
        data.fluidType = GIPT.FLUID_PROPANE
        data.capacity = GIPT.getTankCapacity(GIPT.FLUID_PROPANE, "SMALL")
        data.amount = data.capacity * percent / 100
    elseif fluidType == GIPT.FLUID_WATER and container and Fluid and Fluid.Water and percent > 0 then
        pcall(function() container:addFluid(Fluid.Water, capacityOf(container) * percent / 100) end)
        data.fluidType = GIPT.FLUID_NATIVE
    elseif fluidType == GIPT.FLUID_GASOLINE and container and Fluid and Fluid.Petrol and percent > 0 then
        pcall(function() container:addFluid(Fluid.Petrol, capacityOf(container) * percent / 100) end)
        data.fluidType = GIPT.FLUID_NATIVE
    else
        data.fluidType = GIPT.FLUID_EMPTY
        data.amount = 0
    end

    data.nativeStorageVersion = GIPT.NATIVE_SMALL_STORAGE_VERSION
    GIPT.ensureSmallTankStorageData(controller, data)
    syncEntity(controller)
    transmitData(controller)
    return true
end
