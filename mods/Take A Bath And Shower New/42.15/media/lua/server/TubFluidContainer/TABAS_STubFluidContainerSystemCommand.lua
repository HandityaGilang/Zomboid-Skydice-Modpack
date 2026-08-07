if isClient() then return end

local TABAS_STubFluidContainerSystemCommand = {}

local TABAS_Iso = require("TABAS_Iso")
local TFC_Utils = require("TubFluidContainer/TABAS_TubFluidContainerSystemUtils")
local TFC_Sync = require("TubFluidContainer/TABAS_STubFluidContainerSyncManager")

local function tfcAt(x, y, z)
    local gData = GetTFCSystemData()
    local id = TFC_Utils.getIdByCoords(x, y, z)
    local data = gData.Registered[id]
    if not data then return end
    local bathObj = TABAS_Iso.getBathObjectAt(x, y, z)
    if not bathObj then
        TFC_Utils.noise("TFC At", "Bath object is invalid!")
        return
    end
    local tfc_Base = TFC_Utils.getTfcBaseOnServer(x, y, z, bathObj)
    return tfc_Base
end

--------------------- For TFC Data ---------------------

TABAS_STubFluidContainerSystemCommand.tabas_tfc = {}

-- TFC_Commands.tabas_tfc.RegistPendedRemove = function(player, args)
--     local gData = GetTFCSystemData()
--     local id = TFC_Utils.getIdByCoords(args.x, args.y, args.z)
--     gData.PendedRemove[id] = true
--     TransmitTFCSystemData()
-- end

-- TFC_Commands.tabas_tfc.UnregistPendedRemove = function(player, args)
--     local gData = GetTFCSystemData()
--     local id = TFC_Utils.getIdByCoords(args.x, args.y, args.z)
--     if gData.PendedRemove[id] then
--         gData.PendedRemove[id] = nil
--         TransmitTFCSystemData()
--     end
-- end

TABAS_STubFluidContainerSystemCommand.tabas_tfc.Activate = function(player, args)
    local gData = GetTFCSystemData()
    local id = TFC_Utils.getIdByCoords(args.x, args.y, args.z)
    local v = gData.Activated[id] or {}
    v.x = args.x
    v.y = args.y
    v.z = args.z
    v.facing = args.facing
    v._lastState = v.state or nil
    v.state = args.state
    v.activate = args.activate
    v.owner = player:getOnlineID()
    v.ownerName = player:getUsername()
    gData.Activated[id] = v
    TransmitTFCSystemData("command.Activate")
end

TABAS_STubFluidContainerSystemCommand.tabas_tfc.ActivatedClear = function(player, args)
    local gData = GetTFCSystemData()
    local id = TFC_Utils.getIdByCoords(args.x, args.y, args.z)
    if gData.Activated[id] then
        gData.Activated[id] = nil
        TransmitTFCSystemData("command.ActivatedClear")
    end
end

TABAS_STubFluidContainerSystemCommand.tabas_tfc.clearThisTfc = function(player, args)
    local tfc_Base = tfcAt(args.x, args.y, args.z)
    if not tfc_Base then return end

    if tfc_Base:hasTfc() then
        tfc_Base:remove()
    end
end

TABAS_STubFluidContainerSystemCommand.tabas_tfc.clearAllActivate = function(player, args)
    local gData = GetTFCSystemData()
    for k, v in pairs(gData.Activated) do
        gData.Activated[k] = nil
    end
    TransmitTFCSystemData("command.clearAllActivate")
end

TABAS_STubFluidContainerSystemCommand.tabas_tfc.clearAllTfc = function(player, args)
    local gData = GetTFCSystemData()
    if not gData or not gData.Registered then return end

    for id, _ in pairs(gData.Registered) do
        local x,y,z = TFC_Utils.getCoordsById(id)
        local square = getCell():getGridSquare(x, y, z)
        if square then
            local bathObj = TABAS_Iso.getBathObjectOnSquare(square)
            if bathObj then
                local tfc_Base = TFC_Utils.getTfcBaseOnServer(x, y, z, bathObj)
                if tfc_Base and tfc_Base:hasTfc() then
                    tfc_Base:remove()
                    TFC_Utils.noise("Object removed", tostring(id))
                end
            end
        else
            gData.Registered[id].pendedRemove = true
            TFC_Utils.noise("Pended object remove", tostring(id))
        end
    end
end

--------------------- For TFC Sync Manager ---------------------

TABAS_STubFluidContainerSystemCommand.tabas_tfc.watch = function(player, args)
    if not player or not args then return end
    if args.x == nil or args.y == nil or args.z == nil then return end

    local id = TFC_Utils.getIdByCoords(args.x, args.y, args.z)
    local ttlMs = args.ms or 4000
    TFC_Sync.addWatcher(id, ttlMs)
    -- if TFC_Sync.updateOneSnapshot(args.x, args.y, args.z, args.facing) then
    --     TFC_Sync.transmitThrottled()
    -- end
end


--------------------- For TFC Water ---------------------

TABAS_STubFluidContainerSystemCommand.tabas_tfc.removeFluid = function(player, args)
    local tfc_Base = tfcAt(args.x, args.y, args.z)
    if not tfc_Base then return end

    tfc_Base:removeFluid(args.amount)
end

TABAS_STubFluidContainerSystemCommand.tabas_tfc.fillFluid = function(player, args)
    local tfc_Base = tfcAt(args.x, args.y, args.z)
    if not tfc_Base then return end

    local fluid = Fluid.Get(args.fluidType)
    local temperature = tfc_Base:getBathData("idealTemperature") or TFC_Utils.DefaultTemperature
    tfc_Base:removeFluid()
    tfc_Base:addFluid(fluid, tfc_Base:getCapacity())
    tfc_Base:setWaterTemperature(temperature)
    TFC_Sync.updateRegisteredSnapshot(args.x, args.y, args.z)
end

TABAS_STubFluidContainerSystemCommand.tabas_tfc.filledWaterTo = function(player, args)
    local tfc_Base = tfcAt(args.x, args.y, args.z)
    if not tfc_Base then return end

    local newAmount = tfc_Base:getCapacity() * args.value
    if tfc_Base:isEmpty() then
        tfc_Base:addFluid(Fluid.Water, newAmount)
    else
        tfc_Base:adjustAmount(newAmount)
    end
    TFC_Sync.updateRegisteredSnapshot(args.x, args.y, args.z, args.facing)
end

TABAS_STubFluidContainerSystemCommand.tabas_tfc.setTemperature = function(player, args)
    local tfc_Base = tfcAt(args.x, args.y, args.z)
    if not tfc_Base then return end

    local value = args.value or TFC_Utils.DefaultTemperature
    tfc_Base:setWaterTemperature(value)
    TFC_Sync.updateRegisteredSnapshot(args.x, args.y, args.z, args.facing)
end

TABAS_STubFluidContainerSystemCommand.tabas_tfc.waterToDirt = function(player, args)
    local tfc_Base = tfcAt(args.x, args.y, args.z)
    if not tfc_Base then return end

    local value = args.value or 15
    tfc_Base:waterToDirt(value)
    TFC_Sync.updateRegisteredSnapshot(args.x, args.y, args.z, args.facing)
end

TABAS_STubFluidContainerSystemCommand.tabas_tfc.waterToClean = function(player, args)
    local tfc_Base = tfcAt(args.x, args.y, args.z)
    if not tfc_Base then return end

    local amount = args.value or tfc_Base:getAmount()
    tfc_Base:setWaterData("dirtyLevel", 0, true)
    tfc_Base:setWaterData("isDirty", false, true)
    tfc_Base:removeFluid()
    tfc_Base:addFluid(Fluid.Water, amount)
    TFC_Sync.updateRegisteredSnapshot(args.x, args.y, args.z, args.facing)
end

return TABAS_STubFluidContainerSystemCommand
