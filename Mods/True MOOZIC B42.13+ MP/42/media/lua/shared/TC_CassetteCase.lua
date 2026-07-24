-- TC_CassetteCase.lua
-- Adds Cassette Case as a container (like a backpack)
require "Items/Distributions"

local function initCassetteCase()
    -- Add to loot tables if needed
    -- Example: table.insert(SuburbsDistributions.all.shelves.items, "CassetteCase")
    -- table.insert(SuburbsDistributions.all.shelves.items, 1)
end

Events.OnGameStart.Add(initCassetteCase)

-- Container functionality is handled by item.txt, but you can add custom logic here if needed
-- For example, restrict what can be placed inside:

local function CassetteCase_AllowPutItemInContainer(container, item)
    if container and type(container.getType) == "function" then
        local containingItem = container.getContainingItem and container:getContainingItem() or nil
        local isCase = containingItem
            and containingItem.getFullType
            and containingItem:getFullType() == "Tsarcraft.CassetteCase"
        if isCase then
            -- Only allow cassettes (example: items with "Cassette" in type)
            return string.find(item:getType(), "Cassette") ~= nil
        end
    end
    return true
end

-- Note: no auto-fill here; loot filling is handled by Distributions and server OnCreate.
Events.OnContainerUpdate.Add(CassetteCase_AllowPutItemInContainer)

