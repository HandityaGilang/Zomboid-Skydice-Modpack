require 'luautils'
luautils.Verbose = false

--defualt string formatting of a table
function tab2str(object)
    if type(object) == "table" then
        local str = nil
        for key,subObj in pairs(object) do
            if str == nil then str = '[' else str = str..',' end
            str = str..tab2str(key)..'='..tab2str(subObj)
        end
        if str == nil then return "" else return str..']' end
    else
        return tostring(object or 'nil')--beware mixing nil with string 'nil'
    end
end

function sq2str(square)
    if not square then return 'nil' end
    return '['..(square.x or square:getX())..','..(square.y or square:getY())..','..(square.z or square:getZ())..']'
end

function sq2tab(square)
    if instanceof(square, "IsoGridSquare") then
        return {x=square:getX(),y=square:getY(),z=square:getZ()}
    end
    return square
end

function p2str(isoPlayer)
    if isoPlayer then
        if isoPlayer.getUsername then
            return isoPlayer:getUsername()
        else
            return 'err'
        end
    else
        return 'nil'
    end
end

function o2str(isoObject)
    if isoObject then
        if isoObject.getObjectName then
            return isoObject:getObjectName()
        else
            return 'err'
        end
    else
        return 'nil'
    end
end

function b2str(boolean)
    return tostring(boolean and 'true' or 'false')
end

--https://gist.github.com/tylerneylon/81333721109155b2d244
function luautils.copyTable(obj, seen)
    -- Handle non-tables and previously-seen tables.w
    if type(obj) ~= 'table' then return obj end
    if seen and seen[obj] then return seen[obj] end

    -- New table; mark it as seen and copy recursively.
    local s = seen or {}
    local res = {}
    s[obj] = res
    for k, v in pairs(obj) do
        local source = luautils.copyTable(k, s)
        res[source] = luautils.copyTable(v, s)
    end
    return setmetatable(res, getmetatable(obj))
end

