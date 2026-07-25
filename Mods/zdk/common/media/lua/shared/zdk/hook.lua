zdk = zdk or {}

local registry = {}

function zdk.named_function(objName, methodName, orig, wrapper)
    if not loadstring or not setfenv then
        -- fallback to unnamed functions if loadstring or setfenv is not available
        return function(...) return wrapper(orig, ...) end
    end

    local curHook = registry[orig]
    if curHook and curHook.orig then
        zdk.logger:info("updating existing %s hook: %s:%s", methodName, curHook.filename, curHook.line)
        registry[orig] = nil
        orig = curHook.orig
    end

    local str = "local function " .. methodName .. "(...) return wrapper(orig, ...) end; return " .. methodName
    local cinfo = nil
    if ZombieBuddy and ZombieBuddy.getClosureInfo then
        cinfo = ZombieBuddy.getClosureInfo(wrapper)
        if cinfo and cinfo.line and cinfo.line > 1 then
            -- fix linenumber so tostring(wrapper) shows original wrapper's source file and line number instead of zdk.hook's
            str = string.rep("\n", cinfo.line - 1) .. str
        end
    end
    local chunk = loadstring(str, "zdk.hook")
    setfenv(chunk, { wrapper = wrapper, orig = orig })
    local newFun = chunk()

    if cinfo then
        cinfo.orig = orig
        registry[newFun] = cinfo
    end

    return newFun
end

local function isCallable(obj)
    if type(obj) == "function" then return true end
    local mt = getmetatable(obj)
    return type(mt) == "table" and type(mt.__call) == "function"
end
zdk.is_callable = isCallable

-- returns: [nHooked, table] of the form { methodName1 = orig1, methodName2 = orig2, ... } containing the original methods that were hooked
local function hookTable(tbl, hooks, objName, objDisplayName, mode)
    local logger = zdk.logger:withPrefix("hookTable(): ")
    --logger:debug("objDisplayName=%-20s, mode=%s", objDisplayName, mode)

    if mode ~= "hook" and mode ~= "unhook" then
        logger:error("invalid mode '%s', expected 'hook' or 'unhook'", mode)
        return 0
    end

    local nHooked = 0
    local origMethods = {}
    for methodName, wrapper in pairs(hooks) do
        local orig = tbl[methodName]
        if orig ~= wrapper then -- skip duplicate hooks
            if isCallable(orig) then
                if isCallable(wrapper) then
                    if mode == "hook" then
                        tbl[methodName] = zdk.named_function( objName, methodName, orig, wrapper )
                    elseif mode == "unhook" then
                        tbl[methodName] = wrapper
                    end
                    nHooked = nHooked + 1
                    origMethods[methodName] = orig
                else
                    logger:error("%s.%s wrapper is not callable, type=%s", objDisplayName, methodName, type(wrapper))
                end
            else
                logger:warn("%s.%s is not callable, type=%s", objDisplayName, methodName, type(orig))
            end
        end
    end
    return nHooked, origMethods
end

local function hookMetaTable(obj, hooks, objName, objDisplayName, mode)
    local mt = zdk.get_metatable(obj)
    if not mt then
        zdk.logger:error("hookMetaTable(): no metatable found for %s, cannot hook", objDisplayName)
        return 0
    end

    local index = mt.__index
    if not index then
        zdk.logger:error("hookMetaTable(): no __index found on metatable of %s, cannot hook", objDisplayName)
        return 0
    end

    return hookTable(index, hooks, objName, objDisplayName, mode)
end

local function hookObj(objName, hooks, mode)
    local logger = zdk.logger:withPrefix("hookObj(): ")
    -- logger:debug("objName=%-20s, mode=%s", objName, mode)

    local obj = nil
    if type(objName) == "string" then
        obj = _G[objName]
    else
        obj = objName
        objName = nil
    end

    local objDisplayName = objName or tostring(obj)

    if type(hooks) ~= "table" then
        logger:error("expected hooks for %s to be a table, got %s", objDisplayName, type(hooks))
        return 0
    end

    if type(obj) == "table"    then return hookTable(obj, hooks, objName, objDisplayName, mode) end
    if type(obj) == "userdata" then return hookMetaTable(obj, hooks, objName, objDisplayName, mode) end

    logger:error("expected %s to be a table or userdata, got %s", objDisplayName, type(obj))
    return 0
end

--- Hooks methods on an object by wrapping them with custom functions.
-- @param tbl table of the form { obj1 = { methodName1 = wrapper1, methodName2 = wrapper2, ... }, obj2 = { ... }, ... }
-- @return nHooked, origMethodsByObj - number of methods hooked, and a table of original methods
function zdk.hook(tbl, mode)
    if type(tbl) ~= "table" then
        zdk.logger:error("hook(): expected a table, got %s", type(tbl))
        return
    end

    if not mode then mode = "hook" end
    if mode ~= "hook" and mode ~= "unhook" then
        zdk.logger:error("hook(): invalid mode '%s', expected 'hook' or 'unhook'", mode)
    end

    local nHooked = 0
    local origMethodsByObj = {}
    for objName, methods in pairs(tbl) do
        local n, origMethods = hookObj(objName, methods, mode)
        nHooked = nHooked + n
        if origMethods then
            origMethodsByObj[objName] = origMethods
        end
    end
    return nHooked, origMethodsByObj
end

-- Restores original methods that were hooked by zdk.hook.
-- @param origMethodsByObj table of the form { obj1 = { methodName1 = orig1, methodName2 = orig2, ... }, obj2 = ... }}
function zdk.unhook(origMethodsByObj)
    return zdk.hook(origMethodsByObj, 'unhook')
end

-- same as zdk.hook, but hooks methods first, runs the func() and then restores the original methods before returning.
function zdk.scoped_hook(tbl, func, ...)
    if not isCallable(func) then
        zdk.logger:error("scoped_hook(): expected func to be callable, got %s", type(func))
        return
    end

    local nHooked, origMethodsByObj = zdk.hook(tbl)
    if nHooked == 0 then
        zdk.logger:warn("scoped_hook(): no methods hooked, skipping hook and running func() directly")
        return func(...)
    end

    local ok, result = pcall(func, ...)

    zdk.unhook(origMethodsByObj)
    return result
end
