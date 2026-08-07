
require "Map/CGlobalObject"
require "Map/CGlobalObjectSystem"
require "GlobalObject/SharedGlobalObjectTools"

CGOSystems = CGOSystems or {}
CGOs = CGOs or {}

----------------- client interface ------------------------------
--everything (else than itself) requires ShGO.initCGO to have been called before

--effective client/solo instance system construction is done from vanilla code OnCGlobalObjectSystemInit event
-- so all type creation definition including the RegisterSystemClass below must be done before that.
-- if you can, do it at lua load time.
function ShGO.initCGO(key)
    if not CGOs[key] then
        ShGO.createClientGlobalObjectType(key)
    end
    if not CGOSystems[key] then
        ShGO.createClientGlobalObjectSystemType(key)
    end
    
    if not ShGO['triggerOnCGlobalObjectContextMenu_'..key] then
        ShGO.installClientGlobalObjectContextMenu(key)
    end
end

--square can be either an IsoGridSquare or a table {x=,y=,z=}

--create the global object
function ShGO.createCGO(key, square, character, params)
    local sq = ShGO.convertPosToTable(square)
    local args = {globalObjectKey=key, x=sq.x, y=sq.y, z=sq.z, transfer=params}
    if character == nil then character = getPlayer() end
    if ShGO.Verbose then print('ShGO.createCGO '..tostring(key or 'nil')..' '..ShGO.getTableString(args)) end
    CGOSystems[key].instance:sendCommand(character, 'add_'..key , args)
end

--remove the global object
function ShGO.removeCGO(key, square, character)
    local sq = ShGO.convertPosToTable(square)
    local args = {globalObjectKey=key, x=sq.x, y=sq.y, z=sq.z }
    if character == nil then character = getPlayer() end
    CGOSystems[key].instance:sendCommand(character, 'remove_'..key , args)
end

--update the global object
function ShGO.updateCGO(key, square, character, params)
    local sq = ShGO.convertPosToTable(square)
    local args = {globalObjectKey=key, x=sq.x, y=sq.y, z=sq.z, transfer=params}
    if character == nil then character = getPlayer() end
    CGOSystems[key].instance:sendCommand(character, 'update_'..key , args)
end

--new client event on specific Global Object creation: 'OnObjectAdded_'..key
--use event registration as usual: Events['OnObjectAdded_'..key].Add(myClientSideModdedFunction) and Events['OnObjectAdded_'..key].Remove(myClientSideModdedFunction)
--myClientSideModdedFunction = function (luaObj) <MyJob> end
--luaObj:luaObject associated to the IsoObject

--new client event on specific Global Object deletion: 'OnObjectRemoved_'..key
--use event registration as usual: Events['OnObjectRemoved_'..key].Add(myClientSideModdedFunction) and Events['OnObjectRemoved_'..key].Remove(myClientSideModdedFunction)
--myClientSideModdedFunction = function (luaObj) <MyJob> end
--luaObj: notice it is likely not valid anymore (because the IsoObject may already be removed or altered)

---contextual menu interface
--A new Event can be used client side: 'OnCGlobalObjectContextMenu_'..key
--use event registration as usual: Events['OnCGlobalObjectContextMenu_'..key].Add(myClientSideModdedFunction) and Events['OnCGlobalObjectContextMenu_'..key].Remove(myClientSideModdedFunction)
--myClientSideModdedFunction = function (context, isoObj, playerNum, x, y, test) <MyJob> end
--context: the usual context to add your option
--isoObj: client side Global Object of type 'key' you clicked on
--playerNum: local num of the clicking player
--x: position on screen
--y: position on screen
--test: boolean, vanilla, not sure, you probably should not do anything when test is true


----------------- internals ------------------------------

--create the object type
function ShGO.createClientGlobalObjectType(key)
    local oType = CGlobalObject:derive("CGlobalObject_"..key)

    function oType:new(luaSystem, globalObject)
        return CGlobalObject.new(self, luaSystem, globalObject)
    end

    function oType:fromModData(modData)
        for k,v in pairs(modData) do
            self[k] = luautils.copyTable(v)
        end
        if ShGO.Verbose then print('CGOs['..key..']:fromModData'..ShGO.getTableString(self)) end
    end
    
    function oType:updateFromIsoObject()
        local isoObject = self:getIsoObject()
        if isoObject then
            self:fromModData(isoObject:getModData())
            triggerEvent('OnObjectUpdated_'..key,self)
        end
    end

    CGOs[key] = oType
end

--create the system type
function ShGO.createClientGlobalObjectSystemType(key)
    local oSysType = CGlobalObjectSystem:derive("CGOSystems_"..key)

    function oSysType:new()
        if ShGO.Verbose then print('CGOSystems['..key..']:new') end
        return CGlobalObjectSystem.new(self, key)
    end

    function oSysType:initSystem()
        CGlobalObjectSystem.initSystem(self)
        
        --add a refresh one obj per tick
        --self.resyncIndex = 1
        --Events.OnTick.Add(function()self:resync()end);
    end
    
    function oSysType:resync()--one per tick, arbitrarily chosen. feel free to improve.
        if self.resyncIndex > self.system:getObjectCount() then self.resyncIndex = 1 end
        if self.resyncIndex <= self.system:getObjectCount() then
            local globalObject = self.system:getObjectByIndex(self.resyncIndex-1)
            self.resyncIndex = self.resyncIndex + 1
            if globalObject then
                local luaObject = globalObject:getModData()
                if luaObject then
                    luaObject:updateFromIsoObject()
                end
            end
        end
    end

    function oSysType:isValidIsoObject(isoObject)
        if not isoObject or not isoObject:hasModData() or isoObject:getModData()[key] == nil then
            if ShGO.Verbose then print('CGOSystems['..key..']:isValidIsoObject No '..tostring(isoObject or 'nil')..' '..tostring(isoObject:getName() or 'nil')) end
            return false
        end
        if ShGO.Verbose then print('CGOSystems['..key..']:isValidIsoObject Yes '..tostring(isoObject or 'nil')..' '..tostring(isoObject:getName() or 'nil')..' '..ShGO.getGOName(key)..' '..ShGO.getTableString(isoObject:getModData())) end
        return true
    end

    function oSysType:newLuaObject(globalObject)
        local obj = CGOs[key]:new(self, globalObject)
        local md = nil
        if obj then
            local isoObj = obj:getIsoObject()
            if isoObj then
                md = isoObj:getModData()[key]
            end
        end
        if ShGO.Verbose then print('CGOSystems['..key..']:newLuaObject '..ShGO.getTableString(obj)..' '..ShGO.getTableString(md)) end
        triggerEvent('OnObjectAdded_'..key,obj)
        return obj
    end

    function oSysType:getLuaObjectAt(x, y, z)
        local globalObject = self.system:getObjectAt(x, y, z)
        -- This used to be done in CGlobalItem:new()
        if globalObject then
            local luaObject = globalObject:getModData()
            luaObject:updateFromIsoObject()
        end
        return globalObject and globalObject:getModData() or nil
    end
    
    function oSysType:OnServerCommand(command, args)
        CGlobalObjectSystem.OnServerCommand(self, command, args)
        --TODO maybe 1/2:
        --triggerEvent('OnCGlobalObjectReceiveCommand_'..key, command, args);
    end
    
    --TODO maybe 2/2:
    --LuaEventManager.AddEvent('OnCGlobalObjectReceiveCommand_'..key)

    function oSysType:removeLuaObject(luaObject)
        if ShGO.Verbose then print('CGOSystems['..key..']:removeLuaObject '..tostring(luaObject or 'nil')) end
        if luaObject and (luaObject.luaSystem == self) then
            if ShGO.Verbose then print('CGOSystems['..key..']:removeLuaObject 2 '..tostring(luaObject or 'nil')) end
            triggerEvent('OnObjectRemoved_'..key,luaObject)
        end
        CGlobalObjectSystem.removeLuaObject(self,luaObject)
    end
    
    function oSysType:OnTick()
    
    end
    
    LuaEventManager.AddEvent('OnObjectAdded_'..key)
    LuaEventManager.AddEvent('OnObjectRemoved_'..key)
    LuaEventManager.AddEvent('OnObjectUpdated_'..key)

    CGOSystems[key] = oSysType
    CGlobalObjectSystem.RegisterSystemClass(CGOSystems[key])
    
    
    
    ---debug
    function dbgMultiCreation(obj)
        print ('CGOSystems['..key..']: dbgMultiCreation on '..sq2str(obj))
        function debugThatObj()
            local square = getCell():getGridSquare(obj.x, obj.y, obj.z)
            if not square then return nil end
            local nbIsoObj = 0
            for i=1,square:getObjects():size() do
                local isoObject = square:getObjects():get(i-1)
                if obj.luaSystem:isValidIsoObject(isoObject) then
                    nbIsoObj = nbIsoObj + 1
                end
            end
            if nbIsoObj > 0 then
                print ('CGOSystems['..key..']: debugThatObj '..nbIsoObj..' obj on '..sq2str(obj))
                Events.OnTick.Remove(debugThatObj)
            end
        end
        Events.OnTick.Add(debugThatObj)
    end
    --Events['OnObjectAdded_'..key].Add(dbgMultiCreation)
end

function ShGO.installClientGlobalObjectContextMenu(key)

    --so you can either overload this function or use the event as you prefer
    ShGO['triggerOnCGlobalObjectContextMenu_'..key] = function(context, isoObj, playerNum, x, y, test)
        LuaEventManager.triggerEvent('OnCGlobalObjectContextMenu_'..key, context, isoObj, playerNum, x, y, test);
    end

    local upperLayerCreateMenu = ISWorldObjectContextMenu.createMenu
    ISWorldObjectContextMenu.createMenu = function(playerNum, worldobjects, x, y, test)
        local context = upperLayerCreateMenu(playerNum, worldobjects, x, y, test)
        
        if not context and ShGO.getContextMenuInPause(key) and ISContextMenu and ISContextMenu.get then
            context = ISContextMenu.get(playerNum, x, y);
            if context then
                context.blinkOption = ISWorldObjectContextMenu.blinkOption;
                --if test then context:setVisible(false) end--maybe apply test ?
                --ISWorldObjectContextMenu.Test = false--maybe apply test ?
            end
        end
        
        if context then--do nothing in pause
            --contextual menu option for action on that specific global object
            local playerObj = getSpecificPlayer(playerNum)
            if playerObj and playerObj:isLocalPlayer() then
                for iter,isoObj in ipairs(worldobjects) do
                    if ShGO.isValidIsoObj(isoObj,key) then
                        ShGO['triggerOnCGlobalObjectContextMenu_'..key](context, isoObj, playerNum, x, y, test)
                    end
                end
            end
        end
        return context
    end

    LuaEventManager.AddEvent('OnCGlobalObjectContextMenu_'..key)
end