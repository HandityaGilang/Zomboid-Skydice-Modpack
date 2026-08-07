require "GIPT/GIPT_Constants"
require "GIPT/GIPT_Objects"
require "GIPT/GIPT_NativeSmallTank"
function GIPT.getTankCapacity(fluidType,tankClass)
    local count
    if tankClass=="SMALL" then
        count=8; if SandboxVars and SandboxVars.GIPT and SandboxVars.GIPT.SmallTankCapacity then count=tonumber(SandboxVars.GIPT.SmallTankCapacity) or count end
    else
        count=100; if SandboxVars and SandboxVars.GIPT and SandboxVars.GIPT.LargeTankCapacity then count=tonumber(SandboxVars.GIPT.LargeTankCapacity) or count end
    end
    count=math.max(1,math.floor(count))
    if fluidType==GIPT.FLUID_GASOLINE then return count*100 end
    if fluidType==GIPT.FLUID_WATER then return count*50 end
    return count*GIPT.POINTS_PER_PORTABLE_TANK
end
function GIPT.ensureTankData(obj)
    if not obj then return nil end
    local md = obj:getModData()
    md.GIPT = md.GIPT or {}
    local data = md.GIPT
    data.tankClass = data.tankClass or GIPT.getTankClass(obj) or "LARGE"

    if data.tankClass == "SMALL" then
        data = GIPT.ensureSmallTankStorageData(obj, data)
        if not data.installationID and obj:getSquare() then
            local _, id = GIPT.ensureInstallation(obj:getX(), obj:getY(), obj:getZ())
            data.installationID = id
        end
        if obj.transmitModData and not isClient() then
            pcall(function() obj:transmitModData() end)
        end
        return data
    end

    local supported = {
        [GIPT.FLUID_EMPTY] = true,
        [GIPT.FLUID_PROPANE] = true,
        [GIPT.FLUID_GASOLINE] = true,
        [GIPT.FLUID_WATER] = true,
    }

    -- Rollback safety: universal or mixed-fluid state from v1.0.1-v1.0.13 is
    -- deliberately discarded. This build supports only the three proven fluids.
    if data.fluidType and not supported[data.fluidType] then
        data.fluidType = GIPT.FLUID_EMPTY
        data.amount = 0
    end
    data.fluidComposition = nil

    if data.fluidType == nil then data.fluidType = GIPT.FLUID_EMPTY end
    if data.amount == nil then data.amount = 0 end

    if data.fluidType == GIPT.FLUID_EMPTY or (tonumber(data.amount) or 0) <= 0 then
        data.fluidType = GIPT.FLUID_EMPTY
        data.amount = 0
        data.capacity = GIPT.getTankCapacity(GIPT.FLUID_PROPANE, data.tankClass)
    else
        data.capacity = GIPT.getTankCapacity(data.fluidType, data.tankClass)
        data.amount = GIPT.clamp(tonumber(data.amount) or 0, 0, data.capacity)
        if data.amount <= 0 then
            data.fluidType = GIPT.FLUID_EMPTY
            data.amount = 0
            data.capacity = GIPT.getTankCapacity(GIPT.FLUID_PROPANE, data.tankClass)
        end
    end

    data.version = GIPT.VERSION
    data.initialized = true
    if not data.installationID and obj:getSquare() then
        local _, id = GIPT.ensureInstallation(obj:getX(), obj:getY(), obj:getZ())
        data.installationID = id
    end
    if obj.transmitModData and not isClient() then
        pcall(function() obj:transmitModData() end)
    end
    return data
end

function GIPT.setTankFluid(data,fluidType,percent,obj)
    if data and data.tankClass == "SMALL" and obj then
        GIPT.setSmallTankAdminFluid(obj, fluidType, percent)
        return GIPT.ensureTankData(obj)
    end
    data.initialized=true; data.fluidComposition=nil
    fluidType=fluidType or GIPT.FLUID_EMPTY
    if fluidType==GIPT.FLUID_EMPTY then data.fluidType=fluidType; data.capacity=GIPT.getTankCapacity(GIPT.FLUID_PROPANE,data.tankClass); data.amount=0; return data end
    data.fluidType=fluidType; data.capacity=GIPT.getTankCapacity(fluidType,data.tankClass); data.amount=math.floor(data.capacity*GIPT.clamp(percent or 100,0,100)/100)
    return data
end
function GIPT.findInventoryItemByID(container,id)
    if not container then return nil end; local items=container:getItems()
    for i=0,items:size()-1 do local item=items:get(i); if item and item.getID and item:getID()==id then return item end; if item and item.getInventory then local f=GIPT.findInventoryItemByID(item:getInventory(),id); if f then return f end end end
end
function GIPT.calculatePropaneTransfer(item,data)
    if not data or data.fluidType~=GIPT.FLUID_PROPANE then return nil,"This tank does not contain propane." end
    local adapter,current=GIPT.getAdapter(item),GIPT.getItemFraction(item)
    if not adapter or current==nil then return nil,"That item cannot be refilled here." end
    if current>=0.999 then return nil,"That item is already full." end
    if data.amount<=0 then return nil,"The industrial tank is empty." end
    local missing=math.max(0,math.floor(adapter.fullPoints*(1-current)+0.5)); local transfer=math.min(missing,math.floor(data.amount))
    if transfer<=0 then return nil,"No propane can be transferred." end
    return {mode="PROPANE",adapter=adapter,current=current,transfer=transfer,newFraction=GIPT.clamp(current+transfer/adapter.fullPoints,0,1),duration=adapter.duration}
end
function GIPT.calculateWaterTransfer(item,data)
    if not data or data.fluidType~=GIPT.FLUID_WATER then return nil,"This tank does not contain clean water." end
    local cont=GIPT.getFluidContainer(item); if not cont or not GIPT.isCleanWaterContainer(item) then return nil,"That container cannot accept clean water." end
    local free=cont:getFreeCapacity(); local transfer=math.min(free,data.amount)
    if transfer<=0 then return nil,"No water can be transferred." end
    return {mode="WATER",transfer=transfer,duration=math.max(40,math.floor(transfer*35))}
end
function GIPT.calculateGasolineTransfer(item,data)
    if not data or data.fluidType~=GIPT.FLUID_GASOLINE then return nil,"This tank does not contain gasoline." end
    local cont=GIPT.getFluidContainer(item); if not cont or cont:getFreeCapacity()<=0.0001 then return nil,"That container cannot accept gasoline." end
    if not cont:isEmpty() and not cont:contains(Fluid.Petrol) then return nil,"That container already holds another fluid." end
    local transfer=math.min(cont:getFreeCapacity(),data.amount); if transfer<=0 then return nil,"No gasoline can be transferred." end
    return {mode="GASOLINE",transfer=transfer,duration=math.max(40,math.floor(transfer*35))}
end
function GIPT.calculateTransfer(item,data)
    if data and data.tankClass == "SMALL" and data.fluidType ~= GIPT.FLUID_PROPANE then
        return nil, "Use the compact tank's native liquid transfer option."
    end
    if data and data.fluidType==GIPT.FLUID_WATER then return GIPT.calculateWaterTransfer(item,data) end
    if data and data.fluidType==GIPT.FLUID_GASOLINE then return GIPT.calculateGasolineTransfer(item,data) end
    return GIPT.calculatePropaneTransfer(item,data)
end
function GIPT.commitTransfer(player,x,y,z,item,expectedInstallationID,maxTransfer)
    if not GIPT.distanceOkay(player,x,y,z) then return false,"Move closer to the fluid station." end
    local obj,id=GIPT.resolveTankObject(x,y,z); if not obj then return false,"Industrial tank not found." end
    if expectedInstallationID and id~=expectedInstallationID then return false,"The installation changed during refilling." end
    local data=GIPT.ensureTankData(obj); local calc,msg=GIPT.calculateTransfer(item,data); if not calc then return false,msg end
    local transfer=math.min(calc.transfer,tonumber(maxTransfer) or calc.transfer); if transfer<=0 then return false,"No fluid can be transferred." end
    if calc.mode=="PROPANE" then
        if not GIPT.setItemFraction(item,GIPT.clamp(calc.current+transfer/calc.adapter.fullPoints,0,1)) then return false,"Unable to update that item." end
    elseif calc.mode=="WATER" or calc.mode=="GASOLINE" then
        local cont=GIPT.getFluidContainer(item); if not cont then return false,"Fluid container was lost." end
        cont:addFluid(calc.mode=="WATER" and Fluid.Water or Fluid.Petrol,transfer); if item.syncItemFields then pcall(function() item:syncItemFields() end) end
    end
    data.amount=GIPT.clamp(data.amount-transfer,0,data.capacity); if data.amount<=0 then data.amount=0; data.fluidType=GIPT.FLUID_EMPTY end
    if data.tankClass == "SMALL" then data = GIPT.ensureSmallTankStorageData(obj, data) end
    if obj.transmitModData then pcall(function() obj:transmitModData() end) end
    return true,nil,data,transfer
end
function GIPT.syncGasolineCabinets(controller,data)
    if not controller or not data then return end
    local objects=GIPT.collectConnectedObjects(controller:getX(),controller:getY(),controller:getZ())
    for _,obj in ipairs(objects) do if GIPT.getObjectRole(obj)=="dispenser" and obj.setPipedFuelAmount then
        local amount=data.fluidType==GIPT.FLUID_GASOLINE and data.amount or 0
        pcall(function() obj:setPipedFuelAmount(amount) end)
    end end
end
function GIPT.reconcileGasoline(controller,data)
    if not controller or not data or data.fluidType~=GIPT.FLUID_GASOLINE then return end
    local objects=GIPT.collectConnectedObjects(controller:getX(),controller:getY(),controller:getZ())
    for _,obj in ipairs(objects) do if GIPT.getObjectRole(obj)=="dispenser" and obj.getPipedFuelAmount then
        local ok,v=pcall(function() return obj:getPipedFuelAmount() end); if ok and v~=nil then data.amount=GIPT.clamp(math.floor(v),0,data.capacity); if data.amount<=0 then data.fluidType=GIPT.FLUID_EMPTY end; return end
    end end
end

-- Returns a supported storage-fluid type and the amount currently carried by an item.
-- Large installations deliberately accept only the three fluids implemented by this mod.
function GIPT.getSourceFluid(item)
    local adapter=GIPT.getAdapter(item)
    local fraction=GIPT.getItemFraction(item)
    if adapter and fraction and fraction>0.0001 then
        return GIPT.FLUID_PROPANE, adapter.fullPoints*fraction, {mode="PROPANE",adapter=adapter,fraction=fraction}
    end
    local cont=GIPT.getFluidContainer(item)
    if not cont or cont:isEmpty() or cont:getAmount()<=0.0001 then return nil end
    if cont:contains(Fluid.Petrol) then return GIPT.FLUID_GASOLINE,cont:getAmount(),{mode="FLUID",container=cont,fluid=Fluid.Petrol} end
    if cont:contains(Fluid.Water) and not cont:contains(Fluid.TaintedWater) then return GIPT.FLUID_WATER,cont:getAmount(),{mode="FLUID",container=cont,fluid=Fluid.Water} end
    return nil
end
function GIPT.calculateDeposit(item,data)
    if not item or not data then return nil,"Storage tank not found." end
    local fluidType,available,source=GIPT.getSourceFluid(item)
    if data.tankClass == "SMALL" and fluidType ~= GIPT.FLUID_PROPANE then
        return nil, "Use the compact tank's native liquid transfer option."
    end
    if not fluidType then return nil,"That container does not hold a supported fluid." end
    if data.amount>0 and data.fluidType~=fluidType then return nil,"The storage tank already contains "..string.lower(GIPT.fluidDisplayName(data.fluidType)).."." end
    local capacity=GIPT.getTankCapacity(fluidType,data.tankClass)
    local current=(data.fluidType==fluidType) and data.amount or 0
    local free=math.max(0,capacity-current)
    if free<=0.0001 then return nil,"The storage tank is full." end
    local transfer=math.min(available,free)
    if transfer<=0.0001 then return nil,"No fluid can be transferred." end
    local duration=source.mode=="PROPANE" and math.max(80,math.floor(transfer/source.adapter.fullPoints*240)) or math.max(50,math.floor(transfer*20))
    return {fluidType=fluidType,transfer=transfer,source=source,duration=duration,capacity=capacity}
end
function GIPT.commitDeposit(player,x,y,z,item,expectedInstallationID,maxTransfer)
    if not GIPT.distanceOkay(player,x,y,z) then return false,"Move closer to the storage tank." end
    local obj,id=GIPT.resolveTankObject(x,y,z); if not obj then return false,"Industrial tank not found." end
    if expectedInstallationID and id~=expectedInstallationID then return false,"The installation changed during transfer." end
    local data=GIPT.ensureTankData(obj); local calc,msg=GIPT.calculateDeposit(item,data); if not calc then return false,msg end
    local transfer=math.min(calc.transfer,tonumber(maxTransfer) or calc.transfer)
    if transfer<=0 then return false,"No fluid can be transferred." end
    if calc.source.mode=="PROPANE" then
        local newFraction=GIPT.clamp(calc.source.fraction-transfer/calc.source.adapter.fullPoints,0,1)
        if not GIPT.setItemFraction(item,newFraction) then return false,"Unable to update that container." end
    else
        calc.source.container:removeFluid(transfer,false)
        if item.syncItemFields then pcall(function() item:syncItemFields() end) end
    end
    if data.amount<=0 or data.fluidType==GIPT.FLUID_EMPTY then
        data.fluidType=calc.fluidType; data.capacity=calc.capacity; data.amount=0
    end
    data.amount=GIPT.clamp(data.amount+transfer,0,data.capacity)
    if data.tankClass == "SMALL" then data = GIPT.ensureSmallTankStorageData(obj, data) end
    GIPT.syncGasolineCabinets(obj,data)
    if obj.transmitModData then pcall(function() obj:transmitModData() end) end
    return true,nil,data,transfer
end
