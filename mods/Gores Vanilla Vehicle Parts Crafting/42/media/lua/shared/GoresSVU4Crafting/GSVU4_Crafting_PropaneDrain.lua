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



local function GSVU4Crafting_VanillaRandomInclusive(minValue, maxValue)
    local minN = math.floor(tonumber(minValue) or 0)
    local maxN = math.floor(tonumber(maxValue) or minN)
    if maxN < minN then minN, maxN = maxN, minN end
    if ZombRand then
        local ok, value = pcall(function() return ZombRand(minN, maxN + 1) end)
        if ok and value ~= nil then return tonumber(value) or minN end
    end
    return math.random(minN, maxN)
end

local function GSVU4Crafting_GetVanillaSandboxOption(name, defaultValue)
    if not SandboxVars or not SandboxVars.GSVU4VanillaParts then return defaultValue end
    local value = SandboxVars.GSVU4VanillaParts[name]
    if value == nil then return defaultValue end
    return value
end

local function GSVU4Crafting_RemoveVanillaResult(value, consumedArg)
    local removed = false
    GSVU4Crafting_ForEachPossibleItem(value, function(item)
        if not removed and item ~= consumedArg and item.getContainer then
            local okContainer, container = pcall(function() return item:getContainer() end)
            if okContainer and container then
                if container.Remove and pcall(function() container:Remove(item) end) then removed = true return end
                if container.removeItemOnServer and pcall(function() container:removeItemOnServer(item) end) then removed = true end
            end
        end
    end)
    return removed
end

local function GSVU4Crafting_ApplyVanillaMinorInjury(character)
    if not character or not GSVU4Crafting_GetVanillaSandboxOption("EnableCraftingInjuries", true) then return false end
    local chance = tonumber(GSVU4Crafting_GetVanillaSandboxOption("CraftingInjuryChance", 5)) or 5
    chance = math.max(0, math.min(100, chance))
    if chance <= 0 or GSVU4Crafting_VanillaRandomInclusive(1, 100) > chance then return false end
    if not character.getBodyDamage or not BodyPartType then return false end
    local okBD, bodyDamage = pcall(function() return character:getBodyDamage() end)
    if not okBD or not bodyDamage or not bodyDamage.getBodyPart then return false end
    local bodyPartType = (GSVU4Crafting_VanillaRandomInclusive(0, 1) == 0) and BodyPartType.Hand_L or BodyPartType.Hand_R
    local okPart, part = pcall(function() return bodyDamage:getBodyPart(bodyPartType) end)
    if not okPart or not part then return false end
    local applied = false
    if part.AddDamage then applied = pcall(function() part:AddDamage(GSVU4Crafting_VanillaRandomInclusive(1, 3)) end) end
    if part.setAdditionalPain then
        pcall(function()
            local current = part.getAdditionalPain and (tonumber(part:getAdditionalPain()) or 0) or 0
            part:setAdditionalPain(current + GSVU4Crafting_VanillaRandomInclusive(2, 5))
        end)
    end
    return applied
end

function GSVU4Crafting.OnCreate.RiskyVanillaVehiclePart(...)
    GSVU4Crafting_DrainFromArgs(1, ...)
    local consumedItems = select(1, ...)
    local resultCandidate = select(2, ...)
    local character = GSVU4Crafting_FindCharacter(...)
    local chance = tonumber(GSVU4Crafting_GetVanillaSandboxOption("CraftingFailureChance", 15)) or 10
    chance = math.max(0, math.min(100, chance))
    local failed = chance > 0 and GSVU4Crafting_VanillaRandomInclusive(1, 100) <= chance
    if failed then
        GSVU4Crafting_RemoveVanillaResult(resultCandidate, consumedItems)
        if character then
            if HaloTextHelper and HaloTextHelper.addText then
                pcall(function() HaloTextHelper.addText(character, "The fabrication failed; the salvaged parts are ruined.") end)
            elseif character.setHaloNote then
                pcall(function() character:setHaloNote("The fabrication failed; the salvaged parts are ruined.") end)
            end
        end
    end
    GSVU4Crafting_ApplyVanillaMinorInjury(character)
    return not failed
end
