local M = {}

function M.rollChance(prob01)
    local roll = ZombRand(100) + 1
    local need = math.floor(prob01 * 100 + 0.5)
    return roll <= need
end

function M.countRoles(roles)
    local count = 0
    for _, has in pairs(roles) do
        if has then
            count = count + 1
        end
    end
    return count
end

function M.clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

function M.getWirePivot(x, y, h, scale, offsetX, offsetY)
    local s = scale or 1
    local ox = offsetX or 0
    local oy = offsetY or 0
    return x + (ox * s), y + h + (oy * s)
end

function M.nextRand(seed)
    return (seed * 1103515245 + 12345) % 2147483647
end

function M.shuffle(list, seed)
    for i = #list, 2, -1 do
        seed = M.nextRand(seed + i)
        local j = (seed % i) + 1
        list[i], list[j] = list[j], list[i]
    end
end

function M.joinWithAnd(parts, middleSep, lastSep)
    if #parts == 0 then
        return ""
    end
    if #parts == 1 then
        return parts[1]
    end
    local mid = middleSep or ", "
    local last = lastSep or " and "
    if #parts == 2 then
        return parts[1] .. last .. parts[2]
    end
    local head = table.concat(parts, mid, 1, #parts - 1)
    return head .. last .. parts[#parts]
end

return M
