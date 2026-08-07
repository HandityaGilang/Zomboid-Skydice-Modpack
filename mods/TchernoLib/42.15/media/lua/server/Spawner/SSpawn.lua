require 'Shared_luautils'

Spawn = Spawn or {}
Spawn.SpawnKey = 'spawn'
Spawn.Verbose = false
Spawn.spawnDefinitions = Spawn.spawnDefinitions or {}
Spawn.eventsRegistered = false

--user interface must be called BEFORE OnInitGlobalModData event is triggered.
function Spawn.addToSpawn(spawnDef)
    local toAdd = true
    if spawnDef.rKey then
        local md = ModData.get(Spawn.SpawnKey)
        if md and md[spawnDef.rKey]then
            print ('Spawn.addToSpawn WARNING inhibited by mod data '..tab2str(spawnDef))
            toAdd = false
        end
    end

    if toAdd then
        table.insert(Spawn.spawnDefinitions, spawnDef)
        
        if not Spawn.eventsRegistered then
            Spawn.registerEvents()
            Spawn.eventsRegistered = true
            if Spawn.Verbose then print ('Spawn.addToSpawn Events.LoadGridsquare.Add(Spawn.spawnOnLoadGridsquare)') end
        end
    end
end

--spawnDef:
--x,y,z: coordinate of the spawn
--cItem: item spawn in the first container on the square, if any (exclusive spawn type)
--hItem: [Optional] subItem added to cItem
--sItem: item spawn on interaction (right click) with the square (exclusive spawn type)
--respawn: (with cItem spawn type only) the item will respawn with normal respawn (But only if the tile is reloaded: this means you must go further than usual to get the respawn).
--rKey: (incompatible-unused- with respawn)
--sprite: (with sItem spawn only, required for sItem spawn) sprite of the isoObject used. [TODO remove this requirement)
--e.g. 1 {x=5539 ,y=12490,z=0,cItem='Base.Book',respawn=true}
--e.g. 2 {x=13696,y=1538 ,z=0,cItem='Base.Book',rKey='LouisVilleHotelLibrary1'}
--e.g. 3 {x=4279 ,y=7290 ,z=0,sItem=Portal.PortGun,sprite='location_community_cemetary_01_30',rKey='SouthPond'}


---------------------- internals ---------------------------
function Spawn.removeFromSpawn(rKey,inhibitFromModData)
    for iter=#Spawn.spawnDefinitions, 1, -1 do
        local val = Spawn.spawnDefinitions[iter]
        if val and val.rKey and val.rKey == rKey then
            table.remove(Spawn.spawnDefinitions,iter)
        end
    end
    if inhibitFromModData then
        --ensure at next reload it will also be removed
        ModData.getOrCreate(Spawn.SpawnKey)[rKey] = true
    end
    
    if #Spawn.spawnDefinitions == 0 and Spawn.eventsRegistered then
        --do not even fire the event if we have nothing to to (anymore)
        Events.LoadGridsquare.Remove(Spawn.spawnOnLoadGridsquare)
        Spawn.eventsRegistered = false
        if Spawn.Verbose then print ('Events.LoadGridsquare.Remove(Spawn.spawnOnLoadGridsquare)') end
    end
end



function Spawn.sameSquarePos(square,pos)
    return square and pos and square:getX() == pos.x and square:getY() == pos.y and square:getZ() == pos.z
end

--put that in a tool lib
function Spawn.getFirstContainerFromSquare(square)
    if not square then return nil end
    local obs = square:getObjects()
    if not obs then return nil end
    for i = 0, obs:size()-1 do
        local obj = obs:get(i);
        local nbContainers = obj:getContainerCount();--a same object can have multiple containers (e.g. classic fridge object has firdge container + freezer)
        for containerIter=0, nbContainers do
            local itemContainer = obj:getContainerByIndex(containerIter);
            if itemContainer ~= nil then
                return itemContainer
            end
        end
    end
    return nil
end

function Spawn.getFirstObjFromSquare(square,objSpriteName)
    if not square then return nil end
    local obs = square:getObjects()
    if not obs then return nil end
    for i = 0, obs:size()-1 do
        local obj = obs:get(i);
        local spriteName = obj:getSpriteName()
        if spriteName == objSpriteName then return obj end
    end
    return nil
end

function Spawn.spawnInContainer(square,struct)
    local container = Spawn.getFirstContainerFromSquare(square)
    if container and (not struct.respawn or not container:isHasBeenLooted()) then
        --check spawned by someone else since we connected
        local inhibitSpawn = false
        if struct.rKey then
            local gmd = ModData.get(Spawn.SpawnKey)
            if gmd and gmd[struct.rKey] then
                inhibitSpawn = true
            end
        end

        if not inhibitSpawn then
            local addedItem = container:getFirstTypeRecurse(struct.cItem)
            if not addedItem then
                addedItem = container:AddItem(struct.cItem)
                if struct.hItem then
                    addedItem:getModData()[Spawn.SpawnKey]=struct.hItem
                end
                if Spawn.Verbose then print ('spawnInContainer '..sq2str(square)..' adds '..struct.cItem..' for '..tab2str(struct)) end
            else
                --we would add it more than once with respawn without that => as a consequence we cannot add an item that would have spawn naturally
                if Spawn.Verbose then print ('spawnInContainer '..sq2str(square)..' has already '..struct.cItem) end
            end
        end
        if (not struct.respawn and struct.rKey) then
            --remove from check list
            Spawn.removeFromSpawn(struct.rKey,true)
        end
    end
end

function Spawn.spawnOnInvestigate(square,struct)
    local obj = Spawn.getFirstObjFromSquare(square,struct.sprite)
    if not obj then
        --check spawned by someone else since we connected
        local inhibitSpawn = false
        if struct.rKey then
            local gmd = ModData.get(Spawn.SpawnKey)
            if gmd and gmd[struct.rKey] then
                inhibitSpawn = true
            end
        end

        if not inhibitSpawn then
            --add obj to ground, add modelData to obj for right click
            local isoObject = IsoObject.new(square,struct.sprite,'Suspicious')
            square:AddTileObject(isoObject)
            local md = isoObject:getModData()
            md[Spawn.SpawnKey] = {items={struct.sItem}}
            isoObject:transmitCompleteItemToClients()
            if Spawn.Verbose then print ('Spawn spawnOnInvestigate '..tostring(struct.rKey or 'nil')..' '..sq2str(square)..' '..struct.sItem) end
        end
        
        if struct.rKey then
            --remove from check list
            Spawn.removeFromSpawn(struct.rKey)
            
            --ensure at next reload it will also be removed
            ModData.getOrCreate(Spawn.SpawnKey)[struct.rKey] = true
        end
    end
end


function Spawn.spawnOnLoadGridsquare(square)
    for iter=1, #Spawn.spawnDefinitions do
        local struct = Spawn.spawnDefinitions[iter]
        if struct and Spawn.sameSquarePos(square,struct) then
            if struct.cItem then
                Spawn.spawnInContainer(square,struct);
            elseif struct.sItem then
                Spawn.spawnOnInvestigate(square,struct)
            end
        end
    end
end


--1/ remove items that have already spawned last session on this server
--helps minimising the cost on grid load
--2/ being the first event after Sandbox options load, do all sandbox relative preparation, if any
function Spawn.spawnOnInitGMD()
    local md = ModData.get(Spawn.SpawnKey)
    if md then
        local toRemove = {}
        for it=1, #Spawn.spawnDefinitions do
            local val = Spawn.spawnDefinitions[it]
            if val and val.rKey and md[val.rKey] == true then
                if Spawn.Verbose then print ('Spawn spawnOnInitGMD remove'..tab2str(val)) end
                table.insert(toRemove,val.rKey)
            else
                if Spawn.Verbose then print ('Spawn spawnOnInitGMD keep'..tab2str(val)) end
            end
        end
        for iter,value in pairs(toRemove) do
            Spawn.removeFromSpawn(value,false)
        end
    end
    if Spawn.Verbose then print ('Spawn.spawnOnInitGMD End '..tab2str(Spawn.spawnDefinitions)) end
end

function Spawn.registerEvents()
    Events.LoadGridsquare.Add(Spawn.spawnOnLoadGridsquare)
    Events.OnInitGlobalModData.Add(Spawn.spawnOnInitGMD)
end
