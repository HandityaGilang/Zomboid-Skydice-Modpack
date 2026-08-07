-- =========================================================
-- GSVU4 Crafting Propane Drain Helper (B42)
-- =========================================================
-- The B42 craftRecipe input line:
--      item 1 [Base.BlowTorch] mode:keep
-- only checks that a blowtorch exists. It does not spend any
-- propane/blowtorch uses by itself.
--
-- This OnCreate helper drains one BlowTorch use on successful
-- completion, using item:Use(), matching the Core armor install
-- fuel-consumption method.
-- =========================================================

GSVU4Crafting = GSVU4Crafting or {}
GSVU4Crafting.OnCreate = GSVU4Crafting.OnCreate or {}

local function GSVU4Crafting_GetFullType(item)
    if not item or not item.getFullType then return nil end
    local ok, result = pcall(function() return item:getFullType() end)
    if ok then return result end
    return nil
end

local function GSVU4Crafting_IsBlowTorch(item)
    if not item then return false end

    local t = nil
    if item.getType then
        local ok, result = pcall(function() return item:getType() end)
        if ok then t = result end
    end

    local ft = GSVU4Crafting_GetFullType(item)
    return t == "BlowTorch" or ft == "Base.BlowTorch"
end

local function GSVU4Crafting_GetTorchUses(item)
    if not item or not item.getCurrentUses then return 0 end
    local ok, uses = pcall(function() return item:getCurrentUses() end)
    if ok and uses then return tonumber(uses) or 0 end
    return 0
end

local function GSVU4Crafting_DrainTorch(item, amount)
    if not GSVU4Crafting_IsBlowTorch(item) then return 0 end
    if not item.Use then return 0 end

    local remaining = math.max(0, math.floor((tonumber(amount) or 0) + 0.5))
    local drained = 0

    while remaining > 0 do
        if GSVU4Crafting_GetTorchUses(item) <= 0 then break end
        item:Use()
        drained = drained + 1
        remaining = remaining - 1
    end

    return drained
end

local function GSVU4Crafting_ForEachPossibleItem(value, callback, seen)
    if value == nil then return end
    seen = seen or {}

    local valueType = type(value)

    if valueType == "userdata" then
        local key = tostring(value)
        if seen[key] then return end
        seen[key] = true

        if value.getType then
            callback(value)
            return
        end

        if value.size and value.get then
            local okSize, size = pcall(function() return value:size() end)
            if okSize and size then
                for i = 0, size - 1 do
                    local okGet, item = pcall(function() return value:get(i) end)
                    if okGet then
                        GSVU4Crafting_ForEachPossibleItem(item, callback, seen)
                    end
                end
            end
        end

        return
    end

    if valueType == "table" then
        local key = tostring(value)
        if seen[key] then return end
        seen[key] = true

        for _, v in pairs(value) do
            GSVU4Crafting_ForEachPossibleItem(v, callback, seen)
        end
    end
end

local function GSVU4Crafting_FindCharacter(...)
    for i = 1, select("#", ...) do
        local arg = select(i, ...)

        if arg and type(arg) == "userdata" and arg.getInventory and arg.getSquare then
            return arg
        end

        if type(arg) == "table" then
            local candidates = {
                arg.player,
                arg.character,
                arg.chr,
            }

            for _, candidate in ipairs(candidates) do
                if candidate and candidate.getInventory and candidate.getSquare then
                    return candidate
                end
            end
        end
    end

    return nil
end

local function GSVU4Crafting_FindTorchInInventory(inv)
    if not inv or not inv.getItems then return nil end

    local okItems, items = pcall(function() return inv:getItems() end)
    if not okItems or not items then return nil end

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if GSVU4Crafting_IsBlowTorch(item) and GSVU4Crafting_GetTorchUses(item) > 0 then
            return item
        end

        if item and item.getInventory then
            local okChild, child = pcall(function() return item:getInventory() end)
            if okChild and child then
                local nested = GSVU4Crafting_FindTorchInInventory(child)
                if nested then return nested end
            end
        end
    end

    return nil
end

local function GSVU4Crafting_DrainFromArgs(amount, ...)
    local drained = 0

    for i = 1, select("#", ...) do
        local arg = select(i, ...)
        GSVU4Crafting_ForEachPossibleItem(arg, function(item)
            if drained <= 0 and GSVU4Crafting_IsBlowTorch(item) then
                drained = GSVU4Crafting_DrainTorch(item, amount)
            end
        end)
        if drained > 0 then return drained end
    end

    local character = GSVU4Crafting_FindCharacter(...)
    if character and character.getInventory then
        local inv = character:getInventory()
        local torch = GSVU4Crafting_FindTorchInInventory(inv)
        if torch then
            drained = GSVU4Crafting_DrainTorch(torch, amount)
        end
    end

    return drained
end

function GSVU4Crafting.OnCreate.DrainBlowTorch1(...)
    return GSVU4Crafting_DrainFromArgs(1, ...)
end
