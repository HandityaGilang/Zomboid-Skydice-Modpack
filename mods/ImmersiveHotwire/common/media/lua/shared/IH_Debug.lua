local M = {}

local function isEnabled(category)
    if not isDebugEnabled() then
        return false
    end
    return true
end

local function fmtValue(v)
    local t = type(v)
    if t == "string" or t == "number" or t == "boolean" then
        return tostring(v)
    end
    if t == "nil" then
        return "nil"
    end
    return tostring(v)
end

local function fmtKV(kvTable)
    if type(kvTable) ~= "table" then
        return ""
    end
    local keys = {}
    for k, _ in pairs(kvTable) do
        keys[#keys + 1] = k
    end
    table.sort(keys, function(a, b)
        return tostring(a) < tostring(b)
    end)
    local out = {}
    for _, k in ipairs(keys) do
        out[#out + 1] = tostring(k) .. "=" .. fmtValue(kvTable[k])
    end
    if #out == 0 then
        return ""
    end
    return " " .. table.concat(out, " ")
end

function M.log(category, message, kvTable)
    if not isEnabled(category) then
        return
    end
    print("[IH][" .. tostring(category) .. "] " .. tostring(message) .. fmtKV(kvTable))
end

function M.warn(category, message, kvTable)
    if not isEnabled(category) then
        return
    end
    print("[IH][" .. tostring(category) .. "][WARN] " .. tostring(message) .. fmtKV(kvTable))
end

function M.err(category, message, kvTable)
    if not isEnabled(category) then
        return
    end
    print("[IH][" .. tostring(category) .. "][ERR] " .. tostring(message) .. fmtKV(kvTable))
end

return M
