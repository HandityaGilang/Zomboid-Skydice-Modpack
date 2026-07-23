
-- tinkering items available for all weapons, regardless if they can be fixed or not
PossibleTinkeringItems = {
    "Scotchtape", "Glue", "DuctTape", "Woodglue",
}

-- items accepted for tinkering clothing and bags (clean first, dirty as fallback)
LeatherworkTinkeringItem  = "LeatherStrips"
LeatherworkTinkeringItems = { "LeatherStrips", "LeatherStripsDirty" }

-- Returns remaining integer uses for a drainable item (base:drainable),
-- or 1 for normal items. Uses vanilla B42 API: getCurrentUses() works fine,
-- only getCurrentUsesInt() throws RuntimeException.
local function rgm_getItemUses(item)
    if instanceof(item, "DrainableComboItem") then
        return item:getCurrentUses()
    end
    return 1
end

-- Counts total available uses of an item type across all held instances.
-- For drainable items (DuctTape, Glue, Woodglue) sums actual charges.
-- For normal items (Scotchtape, LeatherStrips) counts items.
function RGM_countItemUses(inventory, itemType)
    local items = inventory:getItemsFromType(itemType)
    if not items then return 0 end
    local total = 0
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it then total = total + rgm_getItemUses(it) end
    end
    return total
end

-- Counts total leather strips (clean + dirty) across inventory.
function RGM_countLeatherUses(inventory)
    local total = 0
    for _, itemType in ipairs(LeatherworkTinkeringItems) do
        total = total + RGM_countItemUses(inventory, itemType)
    end
    return total
end

-- Consumes `cost` uses of itemType, draining drainable items before removing them.
function RGM_consumeItemUses(inventory, itemType, cost)
    local remaining = cost
    while remaining > 0 do
        local item = inventory:getItemFromType(itemType)
        if not item then break end
        if instanceof(item, "DrainableComboItem") then
            local uses  = item:getCurrentUses()
            local delta = item:getUseDelta()
            if uses > remaining then
                -- Partially drain: reduce by `remaining` uses
                item:setUsedDelta(item:getCurrentUsesFloat() - delta * remaining)
                remaining = 0
            else
                -- Fully consume this item
                remaining = remaining - uses
                inventory:Remove(item)
            end
        else
            -- Normal item: remove one at a time
            inventory:Remove(item)
            remaining = remaining - 1
        end
    end
end

-- Consumes `cost` leather units, clean strips first then dirty.
function RGM_consumeLeatherUses(inventory, cost)
    local remaining = cost
    for _, itemType in ipairs(LeatherworkTinkeringItems) do
        if remaining <= 0 then break end
        local avail = RGM_countItemUses(inventory, itemType)
        local toConsume = math.min(remaining, avail)
        if toConsume > 0 then
            RGM_consumeItemUses(inventory, itemType, toConsume)
            remaining = remaining - toConsume
        end
    end
end

-- Returns true if itemType is any accepted leather tinkering material.
function RGM_isLeatherworkItem(itemType)
    for _, t in ipairs(LeatherworkTinkeringItems) do
        if t == itemType then return true end
    end
    return false
end

-- How many uses of each tinkering item are consumed per reforge (multiplied by TinkerCost sandbox var).
-- DuctTape has UseDelta=0.25 (4 uses/roll), so cost=2 means half a roll.
TinkerItemQuantityNecessary = {
    ["Scotchtape"]         = 1,
    ["Glue"]               = 1,
    ["DuctTape"]           = 1,
    ["Woodglue"]           = 1,
    ["LeatherStrips"]      = 1,
    ["LeatherStripsDirty"] = 1,
}
