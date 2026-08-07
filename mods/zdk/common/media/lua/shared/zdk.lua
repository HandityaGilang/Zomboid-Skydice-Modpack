zdk = {
    author  = "Zed",
    version = tonumber(getModInfoByID("zdk"):getModVersion()),
}

local function format_version(v)
    if type(v) == "number" then
        return tostring(v) .. (v == math.floor(v) and ".0" or "")
    else
        return tostring(v)
    end
end

print("zdk v" .. format_version(zdk.version) .. " init")

-- example usage:
--   zdk.dig(MainOptions, "instance", "gameOptions", "options") -- like ruby Hash#dig:
--   zdk.dig("MainOptions.instance.gameOptions.options")        -- compact syntax
--
-- but:
--   zdk.dig(MainOptions, "instance.gameOptions.options")       -- returns MainOptions["instance.gameOptions.options"]
function zdk.dig(obj, ...)
    local keys = {...}

    if type(obj) == "string" and table.isempty(keys) then
        local path = obj
        keys = {}
        for part in path:gmatch("[^%.]+") do
            if part ~= "" then
                table.insert(keys, part)
            end
        end

        obj = _G[keys[1]]
        table.remove(keys, 1)
    end

    for _, key in ipairs(keys) do
        if type(obj) ~= "table" then return nil end

        obj = obj[key]
    end

    return obj
end

function zdk.try(obj, funcName, ...)
    if obj and obj[funcName] and zdk.is_callable(obj[funcName]) then
        return obj[funcName](obj, ...)
    end
end

-- both of min and max are optional
function zdk.clamp(_value, _min, _max)
    if not _min then _min = _value end
    if not _max then _max = _value end
    return math.min(math.max(_value, _min), _max)
end

-- get mod from a full pathname of a file
function zdk.fname2mod(absPath)
    local longestMatch = nil
    local mod_ids = getActivatedMods()
    for i=0, mod_ids:size()-1 do
        local mod = getModInfoByID(mod_ids:get(i))
        local modDir = mod:getDir()
        if modDir and absPath:sub(1, #modDir) == modDir then
            if not longestMatch or #modDir > #longestMatch:getDir() then
                longestMatch = mod
            end
        end
    end
    return longestMatch
end

function zdk.get_metatable(obj)
    if luautils.stringStarts(tostring(obj), "class ") then -- is there a better way?
        return __classmetatables and __classmetatables[obj] or nil
    else
        return getmetatable(obj)
    end
end
