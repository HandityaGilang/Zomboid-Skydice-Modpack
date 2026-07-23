require "PlayableMinigames/PMG_Core"

PMG_Random = PMG_Random or {}

local MOD = 2147483647
local MUL = 48271

local function normalizeSeed(seed)
    seed = math.floor(tonumber(seed) or 1) % MOD
    if seed <= 0 then
        seed = seed + MOD - 1
    end
    return seed
end

function PMG_Random.hash(text)
    text = tostring(text or "")
    local hash = 5381
    for i = 1, #text do
        hash = (hash * 33 + string.byte(text, i)) % MOD
    end
    return normalizeSeed(hash)
end

function PMG_Random.new(seed)
    return { seed = normalizeSeed(seed) }
end

function PMG_Random.next(rng)
    rng.seed = (rng.seed * MUL) % MOD
    return rng.seed / MOD
end

function PMG_Random.int(rng, low, high)
    low = math.floor(tonumber(low) or 1)
    high = math.floor(tonumber(high) or low)
    if high < low then
        low, high = high, low
    end
    return low + math.floor(PMG_Random.next(rng) * (high - low + 1))
end

function PMG_Random.shuffle(list, seed)
    local rng = PMG_Random.new(seed)
    local copy = PMG.copyTable(list or {})
    for i = #copy, 2, -1 do
        local j = PMG_Random.int(rng, 1, i)
        copy[i], copy[j] = copy[j], copy[i]
    end
    return copy
end
