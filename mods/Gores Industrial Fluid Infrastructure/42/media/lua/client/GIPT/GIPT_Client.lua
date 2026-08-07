require "ISUI/ISContextMenu"
require "TimedActions/ISTimedActionQueue"
require "GIPT/GIPT_Constants"
require "GIPT/GIPT_Objects"
require "GIPT/GIPT_Storage"
require "GIPT/GIPT_NativeSmallTank"
require "GIPT/GIPT_NativeTransferTiming"
require "GIPT/GIPT_AdminLargeTankPlacement"
require "GIPT/GIPT_TimedAction"
local pending={}
local pendingBatches={}
local pendingDeposits={}
local nextBatchID=1
local function showSupply(player,data)
    if not data then return end
    local pct=data.capacity>0 and math.floor(data.amount*100/data.capacity+0.5) or 0
    local level=GIPT.formatLitres(data.amount,data.fluidType)
    local capacity=GIPT.formatLitres(data.capacity,data.fluidType==GIPT.FLUID_EMPTY and GIPT.FLUID_PROPANE or data.fluidType)
    HaloTextHelper.addText(player,string.format("Storage tank: %s, %s / %s, %d%%",GIPT.fluidDisplayName(data.fluidType),level,capacity,pct))
end
local function collectEligible(player,fluidType)
    local out={}; local inv=player and player:getInventory(); if not inv then return out end
    local items=inv:getAllEvalRecurse(function(item)
        if fluidType==GIPT.FLUID_PROPANE then local a=GIPT.getAdapter(item); local f=GIPT.getItemFraction(item); return a and f and f<0.999 end
        if fluidType==GIPT.FLUID_WATER then return GIPT.isCleanWaterContainer(item) end
        if fluidType==GIPT.FLUID_GASOLINE then local c=GIPT.getFluidContainer(item); return c and c:getFreeCapacity()>0.0001 and (c:isEmpty() or c:contains(Fluid.Petrol)) end
        return false
    end)
    if items then for i=0,items:size()-1 do table.insert(out,items:get(i)) end end
    table.sort(out,function(a,b) return tostring(a:getName())<tostring(b:getName()) end); return out
end
local function requestFill(player,obj,item,batchID,batchIndex)
    if isClient() then pending[item:getID()]={item=item,batchID=batchID,batchIndex=batchIndex}; sendClientCommand(player,GIPT.MODULE,"BeginFill",{x=obj:getX(),y=obj:getY(),z=obj:getZ(),itemID=item:getID(),batchID=batchID,batchIndex=batchIndex})
    else local tank,id=GIPT.resolveTankObject(obj:getX(),obj:getY(),obj:getZ()); local data=tank and GIPT.ensureTankData(tank); local calc,msg=data and GIPT.calculateTransfer(item,data); if not calc then HaloTextHelper.addText(player,msg or "Unable to fill."); return end; ISTimedActionQueue.add(GIPT_FillAction:new(player,obj:getX(),obj:getY(),obj:getZ(),item,nil,id,calc.transfer,calc.duration,data.fluidType)) end
end
local function pluralise(name)
    name=tostring(name or "Container")
    local lower=string.lower(name)
    if lower=="welding torch" then return "Welding Torches" end
    if string.sub(lower,-1)=="s" then return name end
    if string.sub(lower,-1)=="y" and #name>1 then return string.sub(name,1,-2).."ies" end
    return name.."s"
end

-- Group items by their functional refill family rather than their current display name.
-- In B42 an empty welding torch may be represented as Base.Propane_Refill while a
-- partly-filled torch is Base.BlowTorch. They are the same player-facing item family
-- and must therefore produce one "Fill all Welding Torches" batch option.
local function getBatchFamily(item,fluidType)
    if fluidType==GIPT.FLUID_PROPANE then
        local fullType=item and item.getFullType and item:getFullType() or nil
        if fullType=="Base.BlowTorch" or fullType=="Base.Propane_Refill" then
            return "PROPANE_TORCH", "Welding Torch"
        elseif fullType=="Base.PropaneTank" then
            return "PROPANE_TANK", "Propane Tank"
        end
        local adapter=GIPT.getAdapter(item)
        if adapter then return fullType or tostring(adapter.label), adapter.label or item:getName() end
    end
    local name=tostring(item:getName() or item:getFullType() or "Container")
    return name,name
end
local function startBatchFill(player,target,items)
    if not items or #items<2 then return end
    local id=tostring(nextBatchID); nextBatchID=nextBatchID+1
    if isClient() then
        local ids={}
        for _,item in ipairs(items) do table.insert(ids,item:getID()) end
        pendingBatches[id]={player=player,target=target,itemIDs=ids}
        sendClientCommand(player,GIPT.MODULE,"BeginBatchFill",{x=target:getX(),y=target:getY(),z=target:getZ(),batchID=id,itemIDs=ids})
    else
        local obj,installationID=GIPT.resolveTankObject(target:getX(),target:getY(),target:getZ())
        local data=obj and GIPT.ensureTankData(obj)
        if not data then return end
        for _,item in ipairs(items) do
            local calc=GIPT.calculateTransfer(item,data)
            if calc then ISTimedActionQueue.add(GIPT_FillAction:new(player,target:getX(),target:getY(),target:getZ(),item,nil,installationID,calc.transfer,calc.duration,data.fluidType)) end
        end
    end
end
local function groupEligible(items,fluidType)
    local groups={}
    for _,item in ipairs(items) do
        local key,label=getBatchFamily(item,fluidType)
        groups[key]=groups[key] or {label=label,items={}}
        table.insert(groups[key].items,item)
    end
    return groups
end
local function collectDepositSources(player,data)
    local out={}; local inv=player and player:getInventory(); if not inv then return out end
    local items=inv:getAllEvalRecurse(function(item)
        local fluidType,amount=GIPT.getSourceFluid(item)
        if not fluidType or not amount or amount<=0.0001 then return false end
        return data.amount<=0 or data.fluidType==GIPT.FLUID_EMPTY or data.fluidType==fluidType
    end)
    if items then for i=0,items:size()-1 do table.insert(out,items:get(i)) end end
    table.sort(out,function(a,b) return tostring(a:getName())<tostring(b:getName()) end)
    return out
end
local function requestDeposit(player,obj,item)
    if isClient() then
        pendingDeposits[item:getID()]={item=item}
        sendClientCommand(player,GIPT.MODULE,"BeginDeposit",{x=obj:getX(),y=obj:getY(),z=obj:getZ(),itemID=item:getID()})
    else
        local tank,id=GIPT.resolveTankObject(obj:getX(),obj:getY(),obj:getZ()); local data=tank and GIPT.ensureTankData(tank)
        local calc,msg=data and GIPT.calculateDeposit(item,data)
        if not calc then HaloTextHelper.addText(player,msg or "Unable to transfer fluid."); return end
        ISTimedActionQueue.add(GIPT_DepositAction:new(player,obj:getX(),obj:getY(),obj:getZ(),item,nil,id,calc.transfer,calc.duration,calc.fluidType))
    end
end
local function inspectTank(player,target)
    if isClient() then sendClientCommand(player,GIPT.MODULE,"Inspect",{x=target:getX(),y=target:getY(),z=target:getZ()})
    else local obj=GIPT.resolveTankObject(target:getX(),target:getY(),target:getZ()); if not obj then return end; local d=GIPT.ensureTankData(obj); GIPT.reconcileGasoline(obj,d); showSupply(player,d) end
end
local function adminSet(player,target,fluidType,pct)
    if isClient() then sendClientCommand(player,GIPT.MODULE,"AdminSetFluid",{x=target:getX(),y=target:getY(),z=target:getZ(),fluidType=fluidType,percent=pct})
    else local obj=GIPT.resolveTankObject(target:getX(),target:getY(),target:getZ()); if not obj then return end; local d=GIPT.ensureTankData(obj); d=GIPT.setTankFluid(d,fluidType,pct,obj) or d; GIPT.syncGasolineCabinets(obj,d); obj:transmitModData(); showSupply(player,d) end
end
local function findBulkSourceNear(target,fluidType)
    local range=GIPT.getBulkDeliveryRange(); for _,a in pairs(GIPT.BULK_SOURCE_ADAPTERS or {}) do if (not fluidType or a.fluidType==fluidType) and a.findNearby then local ok,s=pcall(a.findNearby,target,range); if ok and s then return a,s end end end
end
local function isVanillaFuelOptionName(name)
    if not name then return false end
    local text=string.lower(tostring(name))
    -- These are vanilla pump entries generated from the cabinet's FuelPump tile property.
    -- Keep matching deliberately narrow so nearby non-pump context options are untouched.
    return string.find(text,"fuel pump",1,true) ~= nil
        or string.find(text,"gas pump",1,true) ~= nil
        or text == string.lower(tostring(getText("ContextMenu_TakeGasFromPump")))
        or text == "take gas"
        or text == "no container for fuel"
end
local function removeVanillaFuelOptions(context)
    if not context or not context.options then return end
    -- Do not mutate context.options directly. ISContextMenu keeps a separate
    -- numOptions counter and cached dimensions; raw table.remove() corrupts
    -- the menu and can make options added afterwards disappear.
    local names = {}
    for _, option in ipairs(context.options) do
        if option and isVanillaFuelOptionName(option.name) then
            table.insert(names, option.name)
        end
    end
    for _, name in ipairs(names) do
        context:removeOptionByName(name)
    end
    if context.setWidth and context.calcWidth then context:setWidth(context:calcWidth()) end
end
local function isVanillaCompactTankOptionName(name)
    if not name then return false end
    -- This is the native FluidContainer root generated for the GIPT compact
    -- tank. Match the observed label exactly so nearby barrels, sinks, and
    -- unrelated fluid containers keep their own context-menu entries.
    return string.lower(tostring(name)) == "compact fluid tank"
end
local function removeVanillaCompactTankOptions(context)
    if not context or not context.options then return end
    -- As with the fuel-pump cleanup above, use ISContextMenu's public removal
    -- method rather than table.remove() so numOptions and cached dimensions
    -- remain valid in Build 42.19.
    local names = {}
    for _, option in ipairs(context.options) do
        if option and isVanillaCompactTankOptionName(option.name) then
            table.insert(names, option.name)
        end
    end
    for _, name in ipairs(names) do
        context:removeOptionByName(name)
    end
    if context.setWidth and context.calcWidth then context:setWidth(context:calcWidth()) end
end
local function addStatusLines(menu,data)
    local pct=data.capacity>0 and math.floor(data.amount*100/data.capacity+0.5) or 0
    local displayType=data.fluidType==GIPT.FLUID_EMPTY and GIPT.FLUID_PROPANE or data.fluidType
    local contents=menu:addOption("Contents: "..GIPT.fluidDisplayName(data.fluidType))
    contents.notAvailable=true
    local level=menu:addOption("Level: "..GIPT.formatLitres(data.amount,data.fluidType).." / "..GIPT.formatLitres(data.capacity,displayType).." ("..pct.."%)")
    level.notAvailable=true
end
local function collectPropaneSources(player, state)
    local out = {}
    local inv = player and player:getInventory()
    if not inv then return out end
    local items = inv:getAllEvalRecurse(function(item)
        local adapter = GIPT.getAdapter(item)
        local fraction = GIPT.getItemFraction(item)
        if not adapter or not fraction or fraction <= 0.0001 then return false end
        return state.mode == "EMPTY" or state.mode == "PROPANE"
    end)
    if items then for i=0,items:size()-1 do table.insert(out,items:get(i)) end end
    table.sort(out,function(a,b) return tostring(a:getName()) < tostring(b:getName()) end)
    return out
end

local function openNativeTransfer(playerNum, controller)
    local container = controller and controller.getFluidContainer and controller:getFluidContainer() or nil
    if container and ISWorldObjectContextMenu and ISWorldObjectContextMenu.onFluidTransfer then
        ISWorldObjectContextMenu.onFluidTransfer(playerNum, container)
        return
    end
    local player = getSpecificPlayer(playerNum)
    if player then HaloTextHelper.addText(player, "Native liquid storage is still initialising. Reopen the menu.") end
    if isClient() and player and controller then
        sendClientCommand(player, GIPT.MODULE, "EnsureNativeSmallTank", {x=controller:getX(), y=controller:getY(), z=controller:getZ()})
    end
end

local function openNativeInfo(playerNum, controller)
    local container = controller and controller.getFluidContainer and controller:getFluidContainer() or nil
    if container and ISWorldObjectContextMenu and ISWorldObjectContextMenu.onFluidInfo then
        ISWorldObjectContextMenu.onFluidInfo(playerNum, container)
        return
    end
    openNativeTransfer(playerNum, controller)
end

local function initialiseNativeSmallTank(playerNum, controller)
    local player = getSpecificPlayer(playerNum)
    if not player or not controller then return end
    if isClient() then
        sendClientCommand(player, GIPT.MODULE, "EnsureNativeSmallTank", {x=controller:getX(), y=controller:getY(), z=controller:getZ()})
    else
        GIPT.ensureNativeSmallTank(controller, true)
        GIPT.ensureTankData(controller)
        HaloTextHelper.addText(player, "Native compact-tank storage initialised. Reopen the menu.")
    end
end

local function addSmallStatusLines(menu, state)
    local name = state.mode == "PROPANE" and "Propane" or (state.mode == "EMPTY" and "Empty" or state.name)
    local contents = menu:addOption("Contents: " .. tostring(name or "Stored liquid"))
    contents.notAvailable = true
    local amountText
    local capacityText
    if state.mode == "PROPANE" then
        amountText = GIPT.formatLitres(state.amount, GIPT.FLUID_PROPANE)
        capacityText = GIPT.formatLitres(state.capacity, GIPT.FLUID_PROPANE)
    else
        amountText = GIPT.formatLitres(state.amount, GIPT.FLUID_NATIVE)
        capacityText = GIPT.formatLitres(state.capacity, GIPT.FLUID_NATIVE)
    end
    local pct = state.capacity > 0 and math.floor(state.amount * 100 / state.capacity + 0.5) or 0
    local level = menu:addOption("Level: " .. amountText .. " / " .. capacityText .. " (" .. pct .. "%)")
    level.notAvailable = true
end

local function addPropaneWithdrawalOptions(sub, player, target, data)
    local items = collectEligible(player, GIPT.FLUID_PROPANE)
    if #items == 0 then
        local option = sub:addOption("No refillable propane items")
        option.notAvailable = true
        return
    end
    local groups = groupEligible(items, GIPT.FLUID_PROPANE)
    local orderedKeys = {}
    for key,_ in pairs(groups) do table.insert(orderedKeys,key) end
    table.sort(orderedKeys)
    for _,key in ipairs(orderedKeys) do
        local group = groups[key]
        if #group.items > 1 then sub:addOption("Fill all " .. pluralise(group.label), player, startBatchFill, target, group.items) end
    end
    for _,item in ipairs(items) do
        local pct = math.floor((GIPT.getItemFraction(item) or 0) * 100 + 0.5)
        sub:addOption("Fill " .. item:getName() .. " (" .. pct .. "%)", player, requestFill, target, item)
    end
end

local function addPropaneDepositOptions(sub, player, target, state)
    local sources = collectPropaneSources(player, state)
    if #sources == 0 then return end
    local label = state.mode == "PROPANE" and "Top up propane from container" or "Fill compact tank with propane"
    local root = sub:addOption(label)
    local menu = ISContextMenu:getNew(sub)
    sub:addSubMenu(root, menu)
    for _,item in ipairs(sources) do
        local _,amount = GIPT.getSourceFluid(item)
        menu:addOption("Add " .. item:getName() .. " (" .. GIPT.formatLitres(amount or 0, GIPT.FLUID_PROPANE) .. ")", player, requestDeposit, target, item)
    end
end

local function addSmallAdminOptions(sub, player, target)
    if not GIPT.isAdmin(player) then return end
    local admin = sub:addOption("Admin controls")
    local menu = ISContextMenu:getNew(sub)
    sub:addSubMenu(admin, menu)
    menu:addOption("Empty tank", player, adminSet, target, GIPT.FLUID_EMPTY, 0)
    for _,ft in ipairs({GIPT.FLUID_PROPANE,GIPT.FLUID_GASOLINE,GIPT.FLUID_WATER}) do
        local fluid = menu:addOption("Set " .. GIPT.fluidDisplayName(ft))
        local levels = ISContextMenu:getNew(menu)
        menu:addSubMenu(fluid, levels)
        for _,pct in ipairs({25,50,75,100}) do levels:addOption(pct .. "%", player, adminSet, target, ft, pct) end
    end
end

local function addSmallTankMenu(playerNum, context, target, controller)
    local player = getSpecificPlayer(playerNum)
    local state = GIPT.getSmallTankStorageState(controller)
    if not state then return false end

    local root = context:addOption("Compact Fluid Storage Tank")
    local sub = ISContextMenu:getNew(context)
    context:addSubMenu(root, sub)
    addSmallStatusLines(sub, state)

    if state.mode == "PROPANE" then
        sub:addOption("Check propane level", player, inspectTank, target)
        addPropaneWithdrawalOptions(sub, player, target, state.data)
        addPropaneDepositOptions(sub, player, target, state)
    else
        local nativeContainer = state.fluidContainer
        if nativeContainer then
            sub:addOption("Transfer liquids...", playerNum, openNativeTransfer, state.controller)
            sub:addOption("Inspect liquid contents...", playerNum, openNativeInfo, state.controller)
            local note = sub:addOption("Vanilla fluid rules control mixtures and compatibility")
            note.notAvailable = true
        else
            local init = sub:addOption("Initialise native liquid storage", playerNum, initialiseNativeSmallTank, state.controller)
            init.toolTip = ISToolTip:new()
            init.toolTip:initialise()
            init.toolTip.description = "The server has not yet attached the compact tank's native fluid component. Initialise it, then reopen this menu."
        end
        if state.mode == "EMPTY" then addPropaneDepositOptions(sub, player, target, state) end
    end

    addSmallAdminOptions(sub, player, target)
    return true
end

local function onWorldContext(playerNum,context,worldObjects)
    local player=getSpecificPlayer(playerNum); local target
    for _,wo in ipairs(worldObjects) do target=GIPT.findPropaneObject(wo and wo:getSquare()); if target then break end end
    if not target then return end
    local controller=GIPT.resolveTankObject(target:getX(),target:getY(),target:getZ()); if not controller then return end
    local tankClass=GIPT.getTankClass(target)

    if tankClass == "SMALL" then
        -- Add the unified GIPT menu first, then remove the pre-existing native
        -- root. Removing first can stale ISContextMenu bookkeeping and hide
        -- options added afterwards in Build 42.19. If the unified menu cannot
        -- be created, leave the native route available as a safety fallback.
        if addSmallTankMenu(playerNum, context, target, controller) then
            removeVanillaCompactTankOptions(context)
        end
        return
    end

    local data=GIPT.ensureTankData(controller); if not data then return end
    local role=GIPT.getObjectRole(target); local title=role=="dispenser" and "Industrial Fluid Dispenser" or "Industrial Storage Tank"
    -- B42.20 may build the vanilla pump option from a stale/zero cabinet value
    -- after load. Refresh the bridge whenever the cabinet is inspected so the
    -- retained vanilla vehicle-refuel route sees the controller's live amount.
    if role=="dispenser" and data.fluidType==GIPT.FLUID_GASOLINE then
        GIPT.syncGasolineCabinets(controller,data)
    end
    -- Build our submenu before removing the cabinet's vanilla FuelPump entry. In B42.19,
    -- removing a pre-existing option before adding new options can leave the context menu's
    -- internal option bookkeeping stale, causing later options to vanish. Removing the
    -- vanilla entry last avoids that menu-ordering bug.
    local suppressVanillaFuel = role=="dispenser" and data.fluidType~=GIPT.FLUID_GASOLINE
    local root=context:addOption(title); local sub=ISContextMenu:getNew(context); context:addSubMenu(root,sub)
    addStatusLines(sub,data)
    sub:addOption("Check contents",player,inspectTank,target)
    if role=="dispenser" then
        if data.fluidType==GIPT.FLUID_PROPANE or data.fluidType==GIPT.FLUID_WATER or data.fluidType==GIPT.FLUID_GASOLINE then
            local items=collectEligible(player,data.fluidType)
            if #items==0 then
                local emptyText
                if data.fluidType==GIPT.FLUID_WATER then emptyText="No valid water containers"
                elseif data.fluidType==GIPT.FLUID_GASOLINE then emptyText="No empty or partly filled gasoline containers"
                else emptyText="No refillable propane items" end
                local o=sub:addOption(emptyText); o.notAvailable=true
            else
                local groups=groupEligible(items,data.fluidType)
                local orderedKeys={}
                for key,_ in pairs(groups) do table.insert(orderedKeys,key) end
                table.sort(orderedKeys)
                for _,key in ipairs(orderedKeys) do
                    local group=groups[key]
                    if #group.items>1 then sub:addOption("Fill all "..pluralise(group.label),player,startBatchFill,target,group.items) end
                end
                for _,item in ipairs(items) do
                    local suffix=""
                    if data.fluidType==GIPT.FLUID_PROPANE then suffix=" ("..math.floor((GIPT.getItemFraction(item) or 0)*100+0.5).."%)"
                    elseif GIPT.getFluidContainer(item) then suffix=string.format(" (%.1f L free)",GIPT.getFluidContainer(item):getFreeCapacity()) end
                    sub:addOption("Fill "..item:getName()..suffix,player,requestFill,target,item)
                end
            end
        else local o=sub:addOption("Tank is empty"); o.notAvailable=true end
    else
        local sources=collectDepositSources(player,data)
        if #sources>0 then
            local addRoot=sub:addOption(data.amount<=0 and "Fill storage tank from container" or "Top up storage tank")
            local addMenu=ISContextMenu:getNew(sub); sub:addSubMenu(addRoot,addMenu)
            for _,item in ipairs(sources) do
                local fluidType,amount=GIPT.getSourceFluid(item)
                addMenu:addOption("Add "..item:getName().." ("..GIPT.formatLitres(amount,fluidType)..")",player,requestDeposit,target,item)
            end
        else
            local o=sub:addOption(data.amount<=0 and "No supported fluid containers" or "No matching fluid containers"); o.notAvailable=true
        end
        local a,s=findBulkSourceNear(target,data.fluidType==GIPT.FLUID_EMPTY and nil or data.fluidType)
        if a and s then local o=sub:addOption("Bulk source detected: "..(a.label or a.id)); o.notAvailable=true end
    end
    if GIPT.isAdmin(player) then
        local admin=sub:addOption("Admin controls"); local a=ISContextMenu:getNew(sub); sub:addSubMenu(admin,a)
        a:addOption("Empty tank",player,adminSet,target,GIPT.FLUID_EMPTY,0)
        for _,ft in ipairs({GIPT.FLUID_PROPANE,GIPT.FLUID_GASOLINE,GIPT.FLUID_WATER}) do local fluid=a:addOption("Set "..GIPT.fluidDisplayName(ft)); local fs=ISContextMenu:getNew(a); a:addSubMenu(fluid,fs); for _,pct in ipairs({25,50,75,100}) do fs:addOption(pct.."%",player,adminSet,target,ft,pct) end end
    end
    if suppressVanillaFuel then removeVanillaFuelOptions(context) end
end
Events.OnFillWorldObjectContextMenu.Add(onWorldContext)
local function onServerCommand(module,command,args)
    if module~=GIPT.MODULE then return end; local player=getPlayer()
    if command=="Supply" then showSupply(player,args)
    elseif command=="Message" then HaloTextHelper.addText(player,tostring(args.text or ""))
    elseif command=="FillGranted" then local p=pending[args.itemID]; pending[args.itemID]=nil; if not p then return end; local item=GIPT.findInventoryItemByID(player:getInventory(),args.itemID); if not item then return end; ISTimedActionQueue.add(GIPT_FillAction:new(player,args.x,args.y,args.z,item,args.transactionID,args.installationID,args.maxTransfer,args.duration,args.fluidType))
    elseif command=="BatchFillGranted" then
        local batch=pendingBatches[args.batchID]; pendingBatches[args.batchID]=nil; if not batch then return end
        for _,grant in ipairs(args.grants or {}) do
            local item=GIPT.findInventoryItemByID(player:getInventory(),grant.itemID)
            if item then ISTimedActionQueue.add(GIPT_FillAction:new(player,args.x,args.y,args.z,item,grant.transactionID,args.installationID,grant.maxTransfer,grant.duration,args.fluidType)) end
        end
    elseif command=="DepositGranted" then
        local p=pendingDeposits[args.itemID]; pendingDeposits[args.itemID]=nil; if not p then return end
        local item=GIPT.findInventoryItemByID(player:getInventory(),args.itemID); if item then ISTimedActionQueue.add(GIPT_DepositAction:new(player,args.x,args.y,args.z,item,args.transactionID,args.installationID,args.maxTransfer,args.duration,args.fluidType)) end
    elseif command=="FillDenied" then if args.itemID then pending[args.itemID]=nil; pendingDeposits[args.itemID]=nil end; if args.batchID then pendingBatches[args.batchID]=nil end; HaloTextHelper.addText(player,tostring(args.text or "Station unavailable.")) end
end
Events.OnServerCommand.Add(onServerCommand)
require "GIPT/GIPT_SmallTankMoveables"
require "GIPT/GIPT_Protection"
