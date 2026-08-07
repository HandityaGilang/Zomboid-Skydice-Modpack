require 'Shared_luautils'

--Shared Global Object: ShGO
ShGO = ShGO or {}
ShGO.Verbose = false
ShGO.Options = ShGO.Options or {}
ShGO.Options.ContextMenuInPause = ShGO.Options.ContextMenuInPause or {}
ShGO.Sprites = ShGO.Sprites or {}

function ShGO.getSpriteName(key)
    return ShGO.Sprites[key] --or 'appliances_01_58'--default is vanilla fully transparent sprite
end--we need a sprite for the live texture load based on MapObjects.OnNewWithSprite & MapObjects.OnLoadWithSprite to work 

function ShGO.getGOName(key)
    return 'GO'..key
end

function ShGO.isValidIsoObj(isoObject,key)
    return isoObject and isoObject:hasModData() and isoObject:getModData()[key]
end

function ShGO.getIsoObjParams(isoObject,key)
    if isoObject and isoObject:hasModData() then
        return isoObject:getModData()
    end
    return nil
end

function ShGO.getFirstObject(grid,key)
    if not grid then return nil end
    if grid.getObjects then
        local objects = grid:getObjects()
        if objects then
            local size = objects:size()
            if size > 0 then
                for i = 0, objects:size()-1 do
                    local obj = objects:get(i);
                    if ShGO.isValidIsoObj(obj,key) then
                        return obj
                    end
                end
            end
        end
    end
    return nil
end

function ShGO.getGridSquareFromArgs(args)
    return getCell():getGridSquare(args.x, args.y, args.z)
end

function ShGO.setContextMenuInPause(key,contextMenuInPause)
    ShGO.Options.ContextMenuInPause[key] = contextMenuInPause
end

function ShGO.getContextMenuInPause(key)
    return ShGO.Options.ContextMenuInPause[key]
end

--beware there could be recursion errors. we could handle it but I prefer not. I should detect it and push errors but I'm lazy.
function ShGO.overrideGOArgsWithParams(args,params)
    if args and params and type(args) == "table" and type(params) == "table" then
        for key,subObj in pairs(params) do
            if type(subObj) == "table" then
                if not args[key] then args[key] = {} end --create table if not already created
                args[key] = ShGO.overrideGOArgsWithParams(args[key],subObj)
            else
                args[key] = subObj--create or override
            end
        end
    end
    return args
end

function ShGO.getClientGlobalObjectSystem(key)
    local keySys = CGOSystems and CGOSystems[key]
    if keySys and keySys.instance then
        return keySys.instance.system
    end
    return nil
end

function ShGO.samePos(posA, posB)
    if not posA or (not posA.x and not posA.y and not posA.z) then return false end
    if not posB or (not posB.x and not posB.y and not posB.z) then return false end
    return posA.x == posB.x and posA.y == posB.y and posA.z == posB.z
end

--get the first global object at requested position (if any)
function ShGO.getGO(key, x, y, z)
    local globalObject = nil
    if isClient() then
        globalObject = CGOSystems[key].instance.system:getObjectAt(x, y, z)--TODO recheck validity to avoid crash and report errors ?
    else
        globalObject = SGOSystems[key].instance.system:getObjectAt(x, y, z)--TODO recheck validity to avoid crash and report errors ?
    end
    return globalObject and globalObject:getModData() or nil
end

----obsolete
function ShGO.getTableString(object)
    return tab2str(object)
end

function ShGO.convertPosToTable(square)
    return sq2tab(square)
end
