--//////////////////////////////////////////////////--
--    Reactive Sound Events - Corpse Sanitizer
--    Cleans up default loot/weapons from the corpse before we add our own.
--//////////////////////////////////////////////////--

local Utils = require "ReactiveSE/ReactiveSE_Utils"

local ReactiveSE_CorpseSanitizer = {}

---Sanitizes the corpse by removing non-clothing items from inventory and visuals.
---@param deadBody IsoDeadBody
function ReactiveSE_CorpseSanitizer.Sanitize(deadBody)
    if not deadBody then return end

    local container = deadBody:getContainer()
    if not container then return end

    Utils.LogInfo("  [CorpseSanitizer] Starting sanitization...")

    local itemsToRemove = {}
    local items = container:getItems()

    -- 1. Identify Items to Remove (Everything not clothing, PLUS any containers/bags)
    for i = 0, items:size() - 1 do
        local item = items:get(i) --[[@as InventoryItem]]

        local isClothing = item:IsClothing() or instanceof(item, "Clothing")
        local isContainer = instanceof(item, "InventoryContainer")

        -- Remove if it's NOT clothing -OR- if it IS a Container (Bag)
        -- We want to strip default bags so our Kit bag is the only one.
        if (not isClothing) or isContainer then
            table.insert(itemsToRemove, item)
        end
    end

    -- 2. Visual Sanitization (Worn/Attached)
    local wornItems = deadBody:getWornItems()
    local attachedItems = deadBody:getAttachedItems()

    for i = 1, #itemsToRemove do
        local item = itemsToRemove[i]
        local itemType = item:getFullType() --[[@as string]]
        Utils.LogInfo("  [CorpseSanitizer] Removing default item: " .. itemType)

        -- Remove from Container
        container:Remove(item)

        -- Remove from WornItems (if present and matches)
        if wornItems and wornItems:contains(item) then
            wornItems:remove(item)
            Utils.LogInfo("    > Removed from WornItems visuals.")
        end

        -- Remove from AttachedItems
        if attachedItems and attachedItems:contains(item) then
            attachedItems:remove(item)
            Utils.LogInfo("    > Removed from AttachedItems visually.")
        end
    end
end

---Removes all items from a container
---@param container ItemContainer
function ReactiveSE_CorpseSanitizer.ClearContainer(container)
    if not container then return end

    local items = container:getItems()
    if items:size() > 0 then
        Utils.LogInfo("  [CorpseSanitizer] Clearing " .. items:size() .. " items from container.")
        container:removeAllItems()
    end
end

return ReactiveSE_CorpseSanitizer
