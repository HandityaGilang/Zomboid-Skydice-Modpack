local Logger = {}

zdk = zdk or {}
zdk.Logger = Logger

Logger.DEBUG = 1
Logger.INFO  = 2
Logger.WARN  = 3
Logger.ERROR = 4

Logger.DEFAULT_LEVEL = isDebugEnabled and isDebugEnabled() and Logger.DEBUG or Logger.INFO

local prefix_tbl = {
    [Logger.DEBUG] = "[d] ",
    [Logger.INFO]  = "",
    [Logger.WARN]  = "[?] ",
    [Logger.ERROR] = "[!] ",
}

function zdk.formatObj(arg)
    if _G and arg == _G then
        return "_G" -- avoid dumping the entire global table when someone accidentally does zdk.format("%s", _G) or similar
    end

    local arg_type = type(arg)
    if arg_type == "number" or arg_type == "string" then
        -- do nothing
    elseif arg_type == "function" and ZombieBuddy and ZombieBuddy.getCallableInfo then
        local cinfo = ZombieBuddy.getCallableInfo(arg)
        if cinfo and cinfo.name then
            arg = "function " .. tostring(cinfo.name) .. "()"
        else
            arg = zdk.serialize(arg)
        end
    elseif instanceof(arg, "IsoGridSquare") then
        local sq = arg
        arg = string.format("IsoGridSquare(%d, %d, %d)", sq:getX(), sq:getY(), sq:getZ())
    else
        arg = zdk.serialize(arg)
    end
    return arg
end

-- extensions of string.format:
--   - parametrized with specifiers: %*d, %-*s
--   - %S specifier: if argument is a string, it is escaped and put in quotes
--   - %s and %S print table contents / function names / boolean values / etc
function zdk.sprintf(fmt, ...)
    local args = { ... }
    local out_fmt = {}
    local out_args = {}

    local ai = 1
    local i = 1

    while i <= #fmt do
        local c = fmt:sub(i,i)

        if c ~= "%" then
            out_fmt[#out_fmt+1] = c
            i = i + 1

        else
            -- 1) escaped %%
            if fmt:sub(i, i+1) == "%%" then
                out_fmt[#out_fmt+1] = "%%"
                i = i + 2

            else
                -- 2) full specifier
                local s, e, spec = fmt:find("%%([%-%.%*%d]*%a)", i)
                if not s then
                    error("bad format at: " .. fmt:sub(i))
                end

                i = e + 1

                -- handle %* width
                if spec:find("%*") then
                    local width = args[ai]
                    ai = ai + 1
                    spec = spec:gsub("%*", tostring(width))
                end

                local arg = args[ai]
                if spec:sub(-1) == "S" then
                    spec = spec:sub(1, -2) .. "s"
                    if type(arg) == "string" then
                        -- escape quotes and put string in quotes
                        arg = "\"" .. arg:gsub("\"", "\\\"") .. "\""
                    else
                        arg = zdk.formatObj(arg)
                    end
                elseif spec:sub(-1) == "s" and type(arg) ~= "string" then
                    arg = zdk.formatObj(arg)
                end

                out_fmt[#out_fmt+1] = "%" .. spec
                out_args[#out_args+1] = arg
                ai = ai + 1
            end
        end
    end

    local success, result = pcall(function()
        return string.format(table.concat(out_fmt), unpack(out_args))
    end)
    if not success then
        result = string.format("zdk.sprintf error: fmt: '%s', args: '%s'", tostring(fmt), serialize(args))
    end
    return result
end

-- legacy alias
function zdk.format(fmt, ...) return zdk.sprintf(fmt, ...) end

local _once_cache = {}

function Logger:log(level, fmt, ...)
    local once = false
    if level < 0 then
        once = true
        level = -level
    end
    if self.level > level then return end

    local prefix = prefix_tbl[level] or prefix_tbl[Logger.WARN]
    if self.id then
        prefix = prefix .. "[" .. self.id .. "] "
    end
    if self.prefix then
        prefix = prefix .. self.prefix
    end

    local line = prefix .. zdk.format(fmt, ...)
    if once then
        -- dedup by message body
        if _once_cache[line] then return end
        _once_cache[line] = true
    end

    if DebugLog and DebugLog.log then
        DebugLog.log(line)
    else
        print(line) -- behaves differently during load-time and play-time
    end
end

function Logger:log_once(level, fmt, ...)
    if self.level > level then return end

    -- dedup by call site
    local origin = zdk.get_call_origin()
    local key = origin and origin.short_str
    if key and _once_cache[key] then return end
    _once_cache[key] = true

    return self:log(-level, fmt, ...)
end

function Logger:debug(...)      self:log(Logger.DEBUG, ...) end
function Logger:info(...)       self:log(Logger.INFO,  ...) end
function Logger:warn(...)       self:log(Logger.WARN,  ...) end
function Logger:error(...)      self:log(Logger.ERROR, ...) end

function Logger:debug_once(...) self:log_once(Logger.DEBUG, ...) end
function Logger:info_once(...)  self:log_once(Logger.INFO,  ...) end
function Logger:warn_once(...)  self:log_once(Logger.WARN,  ...) end
function Logger:error_once(...) self:log_once(Logger.ERROR, ...) end

function Logger:withPrefix(prefix_fmt, ...)
    return Logger.new(self.id, self.level, self.prefix .. zdk.format(prefix_fmt, ...))
end

function Logger:setLevel(level)
    self.level = level
end

local _loggers = {}

function Logger.new(id, level, prefix)
    local cache_key = (id or "") .. "|" .. (prefix or "")
    local logger = _loggers[cache_key]
    if logger then
        if level and level < logger.level then
            logger.level = level -- only update level if it's more verbose than the existing one
        end
        return logger
    end

    logger = {
        id     = id,
        level  = level or Logger.DEFAULT_LEVEL,
        prefix = prefix or "",
    }
    setmetatable(logger, { __index = Logger })

    _loggers[cache_key] = logger
    return logger
end

Logger.default = Logger.new("zdk")
zdk.logger = Logger.default

local mod = getModInfoByID("zdk")
if mod and luautils.stringStarts(mod:getDir(), "/Users/zed/") then
    zdk.logger:setLevel(Logger.DEBUG)
end

