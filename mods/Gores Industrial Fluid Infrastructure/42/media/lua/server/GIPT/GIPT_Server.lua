if isClient() then return end
require "GIPT/GIPT_Constants"
require "GIPT/GIPT_Objects"
require "GIPT/GIPT_Storage"
require "GIPT/GIPT_NativeSmallTank"
require "GIPT/GIPT_AdminLargeTank"
local locks,transactions,rate={},{},{}
local function now() return os.time() end
local function playerKey(p) if p and p.getOnlineID then return tostring(p:getOnlineID()) end return tostring(p) end
local function sendMessage(p,t) sendServerCommand(p,GIPT.MODULE,"Message",{text=t}) end
local function sendSupply(p,d) sendServerCommand(p,GIPT.MODULE,"Supply",{amount=d.amount,capacity=d.capacity,fluidType=d.fluidType}) end
local function allowed(p,a,i) local k=playerKey(p)..":"..a; local t=now(); if t-(rate[k] or 0)<(i or 1) then return false end; rate[k]=t; return true end
local function batchHasTransactions(batchID)
    if not batchID then return false end
    for _,tx in pairs(transactions) do if tx.batchID==batchID then return true end end
    return false
end
local function release(tx,forceBatch)
    if not tx then return end
    transactions[tx.id]=nil
    if forceBatch and tx.batchID then
        for id,other in pairs(transactions) do if other.batchID==tx.batchID then transactions[id]=nil end end
    end
    local lock=locks[tx.installationID]
    if lock and (not tx.batchID or forceBatch or not batchHasTransactions(tx.batchID)) then locks[tx.installationID]=nil end
end
local function cleanup()
    local t=now()
    local expired={}
    for _,tx in pairs(transactions) do if tx.expiresAt<=t then table.insert(expired,tx) end end
    for _,tx in ipairs(expired) do release(tx,true) end
    for k,v in pairs(rate) do if t-v>120 then rate[k]=nil end end
end
local function getDataAt(args)
    local obj,id=GIPT.resolveTankObject(args.x,args.y,args.z); if not obj then return nil end
    local d=GIPT.ensureTankData(obj); GIPT.reconcileGasoline(obj,d); return obj,id,d
end
local function inspect(p,args)
    if not allowed(p,"inspect",1) then return end
    if not GIPT.distanceOkay(p,args.x,args.y,args.z) then sendMessage(p,"Move closer to the fluid station."); return end
    local obj,id,d=getDataAt(args); if not obj then sendMessage(p,"Industrial tank not found."); return end
    GIPT.syncGasolineCabinets(obj,d); obj:transmitModData(); sendSupply(p,d)
end
local function validateDispenser(p,args)
    if not GIPT.distanceOkay(p,args.x,args.y,args.z) then return nil,"Move closer to the fluid station." end
    local clicked=GIPT.findPropaneObject(getCell():getGridSquare(args.x,args.y,args.z))
    if not clicked then return nil,"Fluid storage object not found." end
    local role=GIPT.getObjectRole(clicked)
    if role~="dispenser" and role~="smallTank" then return nil,"Hand-held containers can only be filled at the cabinet or compact tank." end
    local obj,id,d=getDataAt(args); if not obj then return nil,"Storage tank not found." end
    if role=="dispenser" and d.fluidType==GIPT.FLUID_EMPTY then return nil,"The storage tank is empty." end
    if d.fluidType==GIPT.FLUID_EMPTY then return nil,"The storage tank is empty." end
    return {obj=obj,id=id,data=d}
end
local function makeToken(id,prefix) return id..":"..prefix..":"..tostring(now())..":"..tostring(ZombRand(1000000)) end
local function beginFill(p,args)
    cleanup(); if not allowed(p,"begin",1) then sendServerCommand(p,GIPT.MODULE,"FillDenied",{itemID=args.itemID,text="Please wait before trying again."}); return end
    local v,msg=validateDispenser(p,args); if not v then sendServerCommand(p,GIPT.MODULE,"FillDenied",{itemID=args.itemID,text=msg}); return end
    local existing=locks[v.id]; if existing and existing.expiresAt>now() then sendServerCommand(p,GIPT.MODULE,"FillDenied",{itemID=args.itemID,text="This fluid station is currently in use."}); return end
    local item=GIPT.findInventoryItemByID(p:getInventory(),args.itemID); if not item then sendServerCommand(p,GIPT.MODULE,"FillDenied",{itemID=args.itemID,text="The selected item is no longer in your inventory."}); return end
    local calc,why=GIPT.calculateTransfer(item,v.data); if not calc then sendServerCommand(p,GIPT.MODULE,"FillDenied",{itemID=args.itemID,text=why or "Unable to fill that item."}); return end
    local token=makeToken(v.id,playerKey(p)); local tx={id=token,installationID=v.id,playerKey=playerKey(p),itemID=args.itemID,x=args.x,y=args.y,z=args.z,maxTransfer=calc.transfer,fluidType=v.data.fluidType,expiresAt=now()+GIPT.TRANSACTION_TIMEOUT_SECONDS}
    transactions[token]=tx; locks[v.id]={transactionID=token,expiresAt=tx.expiresAt}
    sendServerCommand(p,GIPT.MODULE,"FillGranted",{transactionID=token,installationID=v.id,itemID=args.itemID,x=args.x,y=args.y,z=args.z,maxTransfer=calc.transfer,duration=calc.duration or 120,fluidType=v.data.fluidType})
end
local function beginBatchFill(p,args)
    cleanup(); if not allowed(p,"batchbegin",1) then sendServerCommand(p,GIPT.MODULE,"FillDenied",{batchID=args.batchID,text="Please wait before trying again."}); return end
    local v,msg=validateDispenser(p,args); if not v then sendServerCommand(p,GIPT.MODULE,"FillDenied",{batchID=args.batchID,text=msg}); return end
    local existing=locks[v.id]; if existing and existing.expiresAt>now() then sendServerCommand(p,GIPT.MODULE,"FillDenied",{batchID=args.batchID,text="This fluid station is currently in use."}); return end
    if type(args.itemIDs)~="table" or #args.itemIDs<2 then sendServerCommand(p,GIPT.MODULE,"FillDenied",{batchID=args.batchID,text="No valid batch was supplied."}); return end
    local batchID=playerKey(p)..":"..tostring(args.batchID)..":"..tostring(now())
    local virtual={fluidType=v.data.fluidType,amount=v.data.amount,capacity=v.data.capacity}
    local grants={}
    for _,itemID in ipairs(args.itemIDs) do
        local item=GIPT.findInventoryItemByID(p:getInventory(),itemID)
        local calc=item and GIPT.calculateTransfer(item,virtual)
        if calc and calc.transfer>0 then
            local token=makeToken(v.id,batchID)
            local tx={id=token,installationID=v.id,playerKey=playerKey(p),itemID=itemID,x=args.x,y=args.y,z=args.z,maxTransfer=calc.transfer,fluidType=v.data.fluidType,batchID=batchID,expiresAt=now()+math.max(GIPT.TRANSACTION_TIMEOUT_SECONDS,300)}
            transactions[token]=tx
            virtual.amount=math.max(0,virtual.amount-calc.transfer)
            table.insert(grants,{transactionID=token,itemID=itemID,maxTransfer=calc.transfer,duration=calc.duration or 120})
            if virtual.amount<=0 then break end
        end
    end
    if #grants==0 then sendServerCommand(p,GIPT.MODULE,"FillDenied",{batchID=args.batchID,text="No containers can be filled."}); return end
    locks[v.id]={batchID=batchID,expiresAt=now()+300}
    sendServerCommand(p,GIPT.MODULE,"BatchFillGranted",{batchID=args.batchID,installationID=v.id,x=args.x,y=args.y,z=args.z,fluidType=v.data.fluidType,grants=grants})
end
local function commitFill(p,args)
    cleanup(); local tx=transactions[args.transactionID]; if not tx or tx.playerKey~=playerKey(p) then sendMessage(p,"The refill reservation expired."); return end
    local item=GIPT.findInventoryItemByID(p:getInventory(),tx.itemID); if not item then release(tx,true); sendMessage(p,"The selected item is no longer in your inventory."); return end
    local progress=GIPT.clamp(tonumber(args.progress) or 1,0,1); local permitted=tx.maxTransfer*progress
    if tx.fluidType==GIPT.FLUID_PROPANE then permitted=math.floor(permitted+0.5) else permitted=math.floor(permitted*1000+0.5)/1000 end
    if progress<0.01 or permitted<=0 then release(tx,args.interrupted==true); return end
    local ok,msg,d=GIPT.commitTransfer(p,tx.x,tx.y,tx.z,item,tx.installationID,permitted)
    release(tx,args.interrupted==true)
    if not ok then sendMessage(p,msg or "Unable to complete the refill."); return end
    if sendItemStats then pcall(function() sendItemStats(item) end) end
    sendSupply(p,d)
end
local function beginDeposit(p,args)
    cleanup(); if not allowed(p,"deposit",1) then sendServerCommand(p,GIPT.MODULE,"FillDenied",{itemID=args.itemID,text="Please wait before trying again."}); return end
    if not GIPT.distanceOkay(p,args.x,args.y,args.z) then sendServerCommand(p,GIPT.MODULE,"FillDenied",{itemID=args.itemID,text="Move closer to the storage tank."}); return end
    local clicked=GIPT.findPropaneObject(getCell():getGridSquare(args.x,args.y,args.z)); if not clicked or GIPT.getObjectRole(clicked)=="dispenser" then sendServerCommand(p,GIPT.MODULE,"FillDenied",{itemID=args.itemID,text="Fill the storage tank from the tank body."}); return end
    local obj,id,d=getDataAt(args); if not obj then sendServerCommand(p,GIPT.MODULE,"FillDenied",{itemID=args.itemID,text="Industrial tank not found."}); return end
    local existing=locks[id]; if existing and existing.expiresAt>now() then sendServerCommand(p,GIPT.MODULE,"FillDenied",{itemID=args.itemID,text="This storage tank is currently in use."}); return end
    local item=GIPT.findInventoryItemByID(p:getInventory(),args.itemID); local calc,msg=item and GIPT.calculateDeposit(item,d)
    if not calc then sendServerCommand(p,GIPT.MODULE,"FillDenied",{itemID=args.itemID,text=msg or "Unable to transfer that fluid."}); return end
    local token=makeToken(id,"deposit"..playerKey(p)); local tx={id=token,kind="deposit",installationID=id,playerKey=playerKey(p),itemID=args.itemID,x=args.x,y=args.y,z=args.z,maxTransfer=calc.transfer,fluidType=calc.fluidType,expiresAt=now()+GIPT.TRANSACTION_TIMEOUT_SECONDS}
    transactions[token]=tx; locks[id]={transactionID=token,expiresAt=tx.expiresAt}
    sendServerCommand(p,GIPT.MODULE,"DepositGranted",{transactionID=token,installationID=id,itemID=args.itemID,x=args.x,y=args.y,z=args.z,maxTransfer=calc.transfer,duration=calc.duration,fluidType=calc.fluidType})
end
local function commitDeposit(p,args)
    cleanup(); local tx=transactions[args.transactionID]; if not tx or tx.kind~="deposit" or tx.playerKey~=playerKey(p) then sendMessage(p,"The transfer reservation expired."); return end
    local item=GIPT.findInventoryItemByID(p:getInventory(),tx.itemID); if not item then release(tx); sendMessage(p,"The selected container is no longer in your inventory."); return end
    local progress=GIPT.clamp(tonumber(args.progress) or 1,0,1); local permitted=tx.maxTransfer*progress
    if tx.fluidType==GIPT.FLUID_PROPANE then permitted=math.floor(permitted+0.5) else permitted=math.floor(permitted*1000+0.5)/1000 end
    if progress<0.01 or permitted<=0 then release(tx); return end
    local ok,msg,d=GIPT.commitDeposit(p,tx.x,tx.y,tx.z,item,tx.installationID,permitted); release(tx)
    if not ok then sendMessage(p,msg or "Unable to complete the transfer."); return end
    if sendItemStats then pcall(function() sendItemStats(item) end) end
    sendSupply(p,d)
end
local function adminSet(p,args)
    if not GIPT.isAdmin(p) or not allowed(p,"adminset",1) or not GIPT.distanceOkay(p,args.x,args.y,args.z) then return end
    local obj,id,d=getDataAt(args); if not obj then return end
    local allowedType={[GIPT.FLUID_EMPTY]=true,[GIPT.FLUID_PROPANE]=true,[GIPT.FLUID_GASOLINE]=true,[GIPT.FLUID_WATER]=true}; if not allowedType[args.fluidType] then return end
    d=GIPT.setTankFluid(d,args.fluidType,args.percent,obj) or d; GIPT.syncGasolineCabinets(obj,d); obj:transmitModData(); sendSupply(p,d)
end
local function ensureSmallNative(obj)
    if not obj or not obj:getSquare() or GIPT.getTankClass(obj) ~= "SMALL" then return end
    local controller = GIPT.resolveTankObject(obj:getX(), obj:getY(), obj:getZ())
    if not controller then return end
    GIPT.ensureNativeSmallTank(controller, true)
    GIPT.ensureTankData(controller)
end

local function ensureSmallNativeOnSquare(square)
    if not square then return end
    local objects = square:getObjects()
    for i=0,objects:size()-1 do
        local obj = objects:get(i)
        if GIPT.getTankClass(obj) == "SMALL" then ensureSmallNative(obj) end
    end
end

local function ensureSmallNativeCommand(p,args)
    if not GIPT.distanceOkay(p,args.x,args.y,args.z) then sendMessage(p,"Move closer to the compact tank."); return end
    local clicked=GIPT.findPropaneObject(getCell():getGridSquare(args.x,args.y,args.z))
    if not clicked or GIPT.getTankClass(clicked)~="SMALL" then sendMessage(p,"Compact tank not found."); return end
    local controller=GIPT.resolveTankObject(args.x,args.y,args.z)
    if not controller then sendMessage(p,"Compact tank controller not found."); return end
    local container=GIPT.ensureNativeSmallTank(controller,true)
    GIPT.ensureTankData(controller)
    if controller.transmitModData then pcall(function() controller:transmitModData() end) end
    if container then sendMessage(p,"Native compact-tank storage is ready. Reopen the menu.")
    else sendMessage(p,"Unable to initialise native compact-tank storage.") end
end


local function adminPlaceLargeInstallation(p,args)
    if not GIPT.canUseAdminInstallationPlacement(p) then return end
    if not allowed(p,"adminplace",1) then sendMessage(p,"Please wait before placing another installation."); return end

    local x, y, z = tonumber(args.x), tonumber(args.y), tonumber(args.z)
    if not x or not y or not z then return end
    x, y, z = math.floor(x), math.floor(y), math.floor(z)
    if p:getZ() ~= z then sendMessage(p,"The installation must be placed on your current level."); return end
    local dx, dy = p:getX() - x, p:getY() - y
    if dx * dx + dy * dy > 2500 then sendMessage(p,"The installation footprint is too far away."); return end

    local family = math.floor(tonumber(args.family) or -1)
    local orientation = args.orientation == "S" and "S" or "E"
    local ok, message = GIPT.placeAdminLargeInstallation(x, y, z, family, orientation)
    sendMessage(p, message or (ok and "Installation placed." or "Installation placement failed."))
end

local function protect(obj)
    if not (SandboxVars and SandboxVars.GIPT and SandboxVars.GIPT.IndestructibleInstallations) then return end
    local sp=obj and obj:getSprite(); if not sp or not GIPT.isPropaneSpriteName(sp:getName()) then return end
    if GIPT.getTankClass(obj)~="LARGE" then return end
    if obj.setMaxHealth and obj.setHealth then obj:setMaxHealth(1000000); obj:setHealth(1000000) end
    local md=obj:getModData(); md.GIPT_Indestructible=true; if obj:getSquare() then GIPT.ensureInstallation(obj:getX(),obj:getY(),obj:getZ()) end
end
Events.OnObjectAdded.Add(ensureSmallNative)
Events.OnObjectAdded.Add(protect)
if Events.LoadGridsquare then Events.LoadGridsquare.Add(ensureSmallNativeOnSquare) end
Events.OnDestroyIsoThumpable.Add(function(obj,player) protect(obj) end)
Events.EveryTenMinutes.Add(cleanup)
Events.OnClientCommand.Add(function(module,command,p,args)
    if module~=GIPT.MODULE or type(args)~="table" then return end
    if command=="Inspect" then inspect(p,args)
    elseif command=="BeginFill" then beginFill(p,args)
    elseif command=="BeginBatchFill" then beginBatchFill(p,args)
    elseif command=="CommitFill" then commitFill(p,args)
    elseif command=="CancelFill" then local tx=transactions[args.transactionID]; if tx and tx.playerKey==playerKey(p) then release(tx,true) end
    elseif command=="BeginDeposit" then beginDeposit(p,args)
    elseif command=="CommitDeposit" then commitDeposit(p,args)
    elseif command=="AdminSetFluid" then adminSet(p,args)
    elseif command=="EnsureNativeSmallTank" then ensureSmallNativeCommand(p,args)
    elseif command=="AdminPlaceLargeInstallation" then adminPlaceLargeInstallation(p,args) end
end)
