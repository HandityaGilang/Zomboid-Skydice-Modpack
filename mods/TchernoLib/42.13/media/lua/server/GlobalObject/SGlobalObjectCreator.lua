
if isClient() then return end

require "Map/SGlobalObject"
require "Map/SGlobalObjectSystem"
require "GlobalObject/SharedGlobalObjectTools"

SGOSystems = SGOSystems or {}
SGOs = SGOs or {}
SGOParams = SGOParams or {}

----------------- interface ------------------------------

--effective server instance system construction is done from vanilla code OnSGlobalObjectSystemInit event
-- so all type creation definition including the RegisterSystemClass below must be done before that.
-- if you can, do it at lua load time.
function ShGO.initSGO(key,objectModDataKeys)
    if not SGOs[key] then
        ShGO.createServerGlobalObjectType(key)
    end
    if not SGOSystems[key] then
        ShGO.createServerGlobalObjectSystemType(key,objectModDataKeys)
    end
end

--TODO missing ShGO.removeSGO here
--TODO simplify OnClientCommand call when this is done server side
function ShGO.createSGO(key, square, character, params)
    local sq = ShGO.convertPosToTable(square)
    local args = {globalObjectKey=key, x=sq.x, y=sq.y, z=sq.z, transfer=params}
    if character == nil then character = getPlayer() end
    if ShGO.Verbose then print('ShGO.createSGO '..tostring(key or 'nil')..' '..ShGO.getTableString(args)) end
    SGOSystems[key].instance:OnClientCommand('add_'..key, character, args)
end

--A new Event can be used server side: 'OnSGlobalObjectReceiveCommand_'..key
--requires initSGO to have been called before
--use event registration as usual: Events['OnSGlobalObjectReceiveCommand_'..key].Add(myServerSideModdedFunction) and Events['OnSGlobalObjectReceiveCommand_'..key].Remove(myServerSideModdedFunction)
--myServerSideModdedFunction = function (command, playerObj, args, result, objectSystemInstance) <MyJob> end
--command: string (e.g. 'add_'..key)
--playerObj: server side player obj related to the client initiating the command
--args: client command arguments
--result: nil or result of the server system actions on the command if any
----add_-> nil if failed or created lua object if succeeded
----remove_-> false if failed or true is succeeded from server's pov. (note could still be true but async problem makes it fail)
----custom command -> nil
--objectSystemInstance: the instance of the object system for ease of use. (you probably should neglect that)


----------------- internals ------------------------------

--create the object type
function ShGO.createServerGlobalObjectType(key,funcGetSpriteName)
    local oType = SGlobalObject:derive('SGOs['..key..']')

    function oType:new(luaSystem, globalObject)
        local o = SGlobalObject.new(self, luaSystem, globalObject)
        if ShGO.Verbose then print('SGOs['..key..']:new '..tab2str(o)) end
        return o
    end

    function oType:getSpriteName()
        if ShGO.Verbose then print('SGOs['..key..']:getSpriteName') end
        return self.spriteName or ShGO.getSpriteName(key) or ""--not sure about the fallback sprite name to ""
    end

    function oType:initNew()
        if ShGO.Verbose then print('SGOs['..key..']:initNew') end
        self[key]=true
        self.spriteName = self:getSpriteName()
    end

    function oType:stateFromIsoObject(isoObject)
        if ShGO.Verbose then print('SGOs['..key..']:stateFromIsoObject') end
        self:initNew()
        self:fromModData(isoObject:getModData())
        self.objectName = isoObject:getName()
        self.spriteName = isoObject:getSpriteName()--tODO getSprite():getName() ?
        -- MapObjects-related code (if any, see MOFarming.lua) might have changed the
        -- isoObject when it was loaded, we must sync with clients.
        if isServer() then
            isoObject:sendObjectChange('name')
            isoObject:sendObjectChange('sprite')
            isoObject:transmitModData()
        end
    end

    function oType:stateToIsoObject(isoObject)
        if ShGO.Verbose then print('SGOs['..key..']:stateToIsoObject') end
        isoObject:setName(self.objectName)
        isoObject:setSprite(self.spriteName)
        self:toModData(isoObject)

        if isServer() then
            isoObject:sendObjectChange('name')
            isoObject:sendObjectChange('sprite')
            isoObject:transmitModData()
        end
    end

    function oType:getObject()
        if ShGO.Verbose then print('SGOs['..key..']:getObject') end
        return self:getIsoObject()
    end

    function oType:addObject()
        if ShGO.Verbose then print('SGOs['..key..']:addObject') end
        if self:getObject() then return end
        local square = self:getSquare()
        if not square then return end
        local isoObject = IsoObject.new(square, self:getSpriteName(), ShGO.getGOName(key))
        self:toModData(isoObject)
        square:AddTileObject(isoObject)
        self:noise('added '..key..' IsoObject at index='..isoObject:getObjectIndex())
    end

    function oType:removeObject()
        if ShGO.Verbose then print('SGOs['..key..']:removeObject') end
        local square = self:getSquare()
        local isoObject = self:getIsoObject()
        if not square or not isoObject then return end
        square:transmitRemoveItemFromSquare(isoObject)
    end

    function oType:setSpriteName(spriteName)
        if ShGO.Verbose then print('SGOs['..key..']:setSpriteName '..tostring(spriteName or 'nil')) end
        if spriteName == self.spriteName then return end
        self:noise('changed '..key..' sprite from='..self.spriteName..' to '..spriteName..' '..self.x..','..self.y..','..self.z)
        self.spriteName = spriteName
        local isoObject = self:getIsoObject()
        if not isoObject then return end
        isoObject:setSprite(spriteName)
    end

    function oType:fromModData(modData)
        if ShGO.Verbose then print('SGOs['..key..']:fromModData '..tab2str(modData[key] or 'nil')) end
        self[key] = modData[key]
    end

    function oType:toModData(isoObject)
        if ShGO.Verbose then print('SGOs['..key..']:toModData '..tab2str(self[key] or 'nil')..' '..tab2str(self)..' '..tab2str(SGOParams[key])) end
        local modData = isoObject:getModData()
        modData[key] = self[key]
        for i=1, #SGOParams[key] do
            local dataKey = SGOParams[key][i]
            modData[dataKey] = self[dataKey]
        end
    end

    function oType:fromObject(isoObject)
        if ShGO.Verbose then print('SGOs['..key..']:fromObject') end
        self:fromModData(isoObject:getModData())
    end

    function oType:syncIsoObject()
        if ShGO.Verbose then print('SGOs['..key..']:syncIsoObject') end
        self.transmitObject = false
        if not self:getIsoObject() then
            self:addObject()
            self.transmitObject = true
        end
    end

    function oType:syncSprite()--this is not correctly implemented yet has I have not decided how the nature of the sprite can change over time
        if ShGO.Verbose then print('SGOs['..key..']:syncSprite') end
        self.transmitSprite = false
        local spriteName
        if not self[key] then
            spriteName = self:getSpriteName()--TODO allow sprite evolution depending on ?parameters?
        else
            spriteName = self:getSpriteName()
        end
        if spriteName ~= self.spriteName then
            self:setSpriteName(spriteName)
            self.transmitSprite = true
        end
    end

    function oType:saveData()
        self:noise('update object modData for '..key..' '..self.x..','..self.y..','..self.z)
        local isoObject = self:getIsoObject()
        if isoObject then
            self:toModData(isoObject)
            isoObject:transmitModData()
        end
    end
    
    function oType:loadGridSquare()
        self:noise('loadGridSquare')
        local isoObject = self:getObject()
        if not isoObject then return end
        self:loadIsoObject(isoObject)
    end
    
    SGOs[key] = oType
end

--create the system type (real deal, this is where we have to add flexibility and functionnalities) 
function ShGO.createServerGlobalObjectSystemType(key,objectModDataKeys)
    local oSysType = SGlobalObjectSystem:derive("SGOSystems_"..key)

    function oSysType:new()
        if ShGO.Verbose then print('SGOSystems['..key..']:new') end
        return SGlobalObjectSystem.new(self, key)
    end

    function oSysType:initSystem()
        if ShGO.Verbose then print('SGOSystems['..key..']:initSystem') end
        SGlobalObjectSystem.initSystem(self)

        -- Specify GlobalObjectSystem fields that should be saved.
        self.system:setModDataKeys(nil)

        -- Specify GlobalObject fields that should be saved.
        if not objectModDataKeys then objectModDataKeys = {'spriteName'} end
        SGOParams[key] = objectModDataKeys
        self.system:setObjectModDataKeys(objectModDataKeys)
    end
    
    function oSysType:OnChunkLoaded(wx, wy)
        local globalObjects = self.system:getObjectsInChunk(wx, wy)
        local squaresToCheck = {}
        for i=1,globalObjects:size() do
            local globalObject = globalObjects:get(i-1)
            local square = getCell():getGridSquare(globalObject:getX(), globalObject:getY(), globalObject:getZ())
            if square then--hum why would we be watching the chunk object if the square is not ready ?
                local isoObject = self:getIsoObjectOnSquare(square)
                if isoObject then
                    --we need to refresh clients
                    if ShGO.Verbose then print('OnChunkLoaded '..i..' '..tab2str(globalObject:getModData())..' '..tab2str(isoObject:getModData())) end
                    --table.insert(squaresToCheck,{x=globalObject:getX(), y=globalObject:getY(), z=globalObject:getZ()})
                end
            end
        end
        SGlobalObjectSystem.OnChunkLoaded(self, wx, wy)
        
        if #squaresToCheck > 0 then
            sendServerCommand(key, 'OnChunkRefresh' , squaresToCheck)--this will help the player on that chunk now, but not the one coming later
        end
    end
    
    function oSysType:loadIsoObject(isoObject)
        if ShGO.Verbose then print('SGOSystems['..key..']:loadIsoObject 1 '..tab2str(isoObject:getModData())) end
        SGlobalObjectSystem.loadIsoObject(self,isoObject)
        if ShGO.Verbose then print('SGOSystems['..key..']:loadIsoObject 2 '..tab2str(isoObject:getModData())) end
    end
    
    function oSysType:getInitialStateForClient()
        if ShGO.Verbose then print('SGOSystems['..key..']:getInitialStateForClient') end
        return {}
    end

    function oSysType:newLuaObject(globalObject)
        if ShGO.Verbose then print('SGOSystems['..key..']:newLuaObject '..tab2str(globalObject)) end
        local luaObj = SGOs[key]:new(self, globalObject)
        if luaObj then
            if ShGO.Verbose then print('SGOSystems['..key..']:newLuaObject 2 '..tab2str(luaObj)) end
        else
            if ShGO.Verbose then print('SGOSystems['..key..']:newLuaObject Failed') end
        end
        return luaObj
    end

    function oSysType:isValidIsoObject(isoObject)
        local valid = ShGO.isValidIsoObj(isoObject,key)
        if ShGO.Verbose then print('SGOSystems['..key..']:isValidIsoObject '..tostring(valid and 'true  ' or 'false ')..tostring(isoObject or 'nil')..' '..tab2str(isoObject and isoObject:getModData()[key] or 'nil')) end
        --if valid then error.pop = now end
        return valid
    end

    --feel free to override this
    oSysType['isValidTileFor_'..key] = function(self,grid)
        if ShGO.Verbose then print('SGOSystems['..key..']:isValidTileFor'..key) end
        return not grid:has(IsoFlagType.water) and not grid:isSolid() and not grid:isSolidTrans()
    end
    
    -- add the instance
    oSysType['add_'..key] = function(self,playerObj,args)
        if ShGO.Verbose then print('SGOSystems['..key..']:add_'..key..' '..tab2str(args)) end
        local grid = ShGO.getGridSquareFromArgs(args)--TODO handle the case of requesting a GO creation on non loaded grid square
        if not grid then return nil end
        if self:getIsoObjectOnSquare(grid) then
            if ShGO.Verbose then print('SGOSystems['..key..']:add_'..key..' failed IsoObjectOnSquare.') end
            return nil
        end
        if not self['isValidTileFor_'..key](self,grid) then
            if ShGO.Verbose then print('SGOSystems['..key..']:add_'..key..' failed InvalidTileFor.') end
            return nil
        end

        local luaObject = self:newLuaObjectOnSquare(grid)
        luaObject:initNew()
        luaObject = ShGO.overrideGOArgsWithParams(luaObject,args.transfer)
        if ShGO.Verbose then print('SGOSystems['..key..']:add_'..key..' 2 '..tab2str(args)..' '..tab2str(luaObject)) end
        luaObject:addObject()
        self:noise('#'..key..'='..self:getLuaObjectCount())
        local isoObject = luaObject:getIsoObject()
        if isoObject then
            luaObject:toModData(isoObject)
            isoObject:transmitCompleteItemToClients()
        end
        return luaObject;
    end

    -- remove an instance if any
    oSysType['remove_'..key] = function(self,playerObj,args)
        if ShGO.Verbose then print('SGOSystems['..key..']:remove_'..key..' '..tab2str(args)) end
        local luaObject = self:getLuaObjectAt(args.x, args.y, args.z)
        if not luaObject then print('SGOSystems['..key..']:remove_'..key..' failed no luaobject.'); return false end
        
        --when an iso object remove is requested while the iso is not loaded, that iso must be removed when the database will be loaded.
        -- >keep track of the square to cleanup
        local square = getCell():getGridSquare(args.x, args.y, args.z)
        if not square then
            local shgo = ModData.getOrCreate('ShGO')
            if not shgo.toRemove then shgo.toRemove = {} end
            shgo.toRemove[sq2str(args)] = true--memorize the square to checkup
        end
        -- >TODO ensure we won't prevent any add request coming in between
        
        -- This call also removes the luaObject because of the OnObjectAboutToBeRemoved event
        LuaEventManager.triggerEvent('OnSGlobalObjectReceiveCommand_'..key, 'remove_'..key..'_beforeRemove', playerObj, args, luaObject, self);
        luaObject:removeIsoObject()
        return true
    end

    oSysType['update_'..key] = function(self,playerObj,args)
        if ShGO.Verbose then print('SGOSystems['..key..']:update_'..key..' '..tab2str(args)) end
        local luaObject = self:getLuaObjectAt(args.x, args.y, args.z)
        if not luaObject then print('SGOSystems['..key..']:update_'..key..' failed no luaobject.'); return false end
        luaObject = ShGO.overrideGOArgsWithParams(luaObject,args.transfer)
        self:noise('updated')
        luaObject:saveData()
        return luaObject
    end

    function oSysType:OnClientCommand(command, playerObj, args)
        if ShGO.Verbose then print('SGOSystems['..key..']:OnClientCommand '..tostring(command or 'nil')..' '..tab2str(args)) end
        local isForMe = args and args.globalObjectKey and args.globalObjectKey == key
        if isForMe then
            local result = nil
            if SGOSystems[key][command] then
                result = SGOSystems[key][command](self, playerObj, args)
            else
                --this may not be an error if all the modder wants is a server-side callback
                if ShGO.Verbose then print('SGOSystems['..key..']:OnClientCommand '..command..' is unknown.') end
            end
            LuaEventManager.triggerEvent('OnSGlobalObjectReceiveCommand_'..key, command, playerObj, args, result, self);
        end
    end
    
    function oSysType:OnLoadGridSquare(square)
        local shgo = ModData.get('ShGO')
        if shgo and shgo.toRemove and shgo.toRemove[sq2str(square)] then
            local iso = ShGO.getFirstObject(square,key)
            if iso then
                square:transmitRemoveItemFromSquare(iso);
            end
        end
    end
    
    oSysType['MaybeNew_'..key]=function(isoObject)
        local valid = ShGO.isValidIsoObj(isoObject,key)
        if valid then
            --SGOSystems[key].instance:loadIsoObject(isoObject)
            --TODO new
        end
        if ShGO.Verbose then print('SGOSystems['..key..']:MaybeNew => from pre-existing isoObject '..tostring(valid and 'true ' or 'false ')..tostring(isoObject or 'nil')..' '..tab2str(isoObject and isoObject:getModData() or 'nil')) end
        if isoObject and isoObject:getSquare() then
            local sq = isoObject:getSquare()
            local luaObject = self:getLuaObjectOnSquare(sq)
            if ShGO.Verbose then print('SGOSystems['..key..']:MaybeNew 2> from pre-existing square ['..sq:getX()..','..sq:getY()..','..sq:getZ()..']'..tab2str(luaObject)) end
        end
    end
    
    oSysType['MaybeLoad_'..key]=function(isoObject)
        if ShGO.isValidIsoObj(isoObject,key) then
            SGOSystems[key].instance:loadIsoObject(isoObject)
            if ShGO.Verbose then print('SGOSystems['..key..']:MaybeLoad => loadIsoObject from pre-existing isoObject '..tostring(isoObject)..' '..tab2str(isoObject:getModData())) end
        end
    end

    SGOSystems[key] = oSysType

    LuaEventManager.AddEvent('OnSGlobalObjectReceiveCommand_'..key)
    SGlobalObjectSystem.RegisterSystemClass(SGOSystems[key])
    
    --handle MapObjects load (whatever this is)
    local PRIORITY = 5
    local spriteName = ShGO.getSpriteName(key)
    if spriteName and spriteName ~= '' then
        MapObjects.OnNewWithSprite(spriteName, SGOSystems[key]['MaybeNew_'..key], PRIORITY)
        MapObjects.OnLoadWithSprite(spriteName, SGOSystems[key]['MaybeLoad_'..key], PRIORITY)
    end
    
    
    
    Events.LoadGridsquare.Add(function(square)if SGOSystems[key].instance then
        SGOSystems[key].instance:OnLoadGridSquare(square)
        end
    end)
end
