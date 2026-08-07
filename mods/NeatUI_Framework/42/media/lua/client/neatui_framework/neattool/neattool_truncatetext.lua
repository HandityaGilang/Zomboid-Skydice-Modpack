NeatTool = NeatTool or {}

-- Cache repeated UI text truncation, which is expensive because it measures text several times.
local NT_TRUNCATE_CACHE_MAX = 512
local NT_TRUNCATE_CACHE = {}
local NT_TRUNCATE_CACHE_ORDER = {}

local function NT_truncateCacheSet(key, value)
    -- Keep a small FIFO cache so scrolling inventories do not grow memory forever.
    if NT_TRUNCATE_CACHE[key] == nil then
        table.insert(NT_TRUNCATE_CACHE_ORDER, key)
        if #NT_TRUNCATE_CACHE_ORDER > NT_TRUNCATE_CACHE_MAX then
            local oldKey = table.remove(NT_TRUNCATE_CACHE_ORDER, 1)
            NT_TRUNCATE_CACHE[oldKey] = nil
        end
    end
    NT_TRUNCATE_CACHE[key] = value
    return value
end

function NeatTool.truncateText(text, maxWidth, font, suffix)
    if not text or text == "" then
        return ""
    end

    font = font or UIFont.Small
    suffix = suffix or "..."
    maxWidth = math.floor(tonumber(maxWidth) or 0)

    if maxWidth <= 0 then
        return ""
    end

    local cacheKey = tostring(font) .. "|" .. tostring(maxWidth) .. "|" .. tostring(suffix) .. "|" .. tostring(text)
    local cached = NT_TRUNCATE_CACHE[cacheKey]
    if cached ~= nil then
        return cached
    end

    local originalWidth = getTextManager():MeasureStringX(font, text)

    if originalWidth <= maxWidth then
        return NT_truncateCacheSet(cacheKey, text)
    end

    local suffixWidth = getTextManager():MeasureStringX(font, suffix)

    if suffixWidth >= maxWidth then
        return NT_truncateCacheSet(cacheKey, "")
    end

    local textMaxWidth = maxWidth - suffixWidth

    local left = 1
    local right = string.len(text)
    local bestLength = 0

    while left <= right do
        local mid = math.floor((left + right) / 2)
        local truncatedText = string.sub(text, 1, mid)
        local truncatedWidth = getTextManager():MeasureStringX(font, truncatedText)

        if truncatedWidth <= textMaxWidth then
            bestLength = mid
            left = mid + 1
        else
            right = mid - 1
        end
    end

    if bestLength == 0 then
        return NT_truncateCacheSet(cacheKey, suffix)
    end

    local finalText = string.sub(text, 1, bestLength)
    return NT_truncateCacheSet(cacheKey, finalText .. suffix)
end
