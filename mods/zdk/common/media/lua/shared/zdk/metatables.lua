zdk = zdk or {}

function zdk.augment_metatable(obj, functbl)
    if not obj then return end

    local mt = zdk.get_metatable(obj)
    if not mt then return end

    local index = mt.__index
    if not index then return end

    for methodName, func in pairs(functbl) do
        if not rawget(index, methodName) then -- patch only if method is not already defined
            if type(func) == "string" then
                func = rawget(index, func) -- alias to existing method
            end
            -- calling with func = nil will remove the method, and we don't want that
            if func then
                index[methodName] = func
            end
        end
    end
end

-- deprecated name, use zdk.augment_metatable() or zdk.hook() instead
--function zdk.patch_metatable(obj, functbl)
--    return zdk.augment_metatable(obj, functbl)
--end

local function process_all_metatables(condKey, func)
    for klass, mt in pairs(__classmetatables) do
        local index = mt.__index
        -- XXX have to use rawget() here to avoid calling any metamethods that regular tbl['hasTrait'] or tbl.hasTrait might potentially trigger
        -- random mods break in random places if "tbl['hasTrait']" or "tbl.hasTrait" is used here
        if type(index) == "table" and rawget(index, condKey) then
            func(klass, index)
        end
    end
end

function zdk.find_all_metatables(condKey)
    local result = {}
    process_all_metatables(condKey, function(klass, index)
        result[klass] = index
    end)
    return result
end

-- add new methods if they not already exist
function zdk.augment_all_metatables(condKey, tbl)
    process_all_metatables(condKey, function(klass)
        zdk.augment_metatable(klass, tbl)
    end)
end

-- patch existing methods
function zdk.patch_all_metatables(condKey, tbl)
    process_all_metatables(condKey, function(klass)
        zdk.hook({
            [klass] = tbl
        })
    end)
end
