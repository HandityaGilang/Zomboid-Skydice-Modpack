-- boombox_distribution.lua
-- Adds colored boombox variants to procedural loot tables

require "Items/ProceduralDistributions"
require "Items/SuburbsDistributions"

local boomboxes = {
    "Tsarcraft.TCBoomboxBlue",
    "Tsarcraft.TCBoomboxCamo",
    "Tsarcraft.TCBoomboxBlack",
    "Tsarcraft.TCBoomboxGreen",
    "Tsarcraft.TCBoomboxPink",
    "Tsarcraft.TCBoomboxRed",
}

-- Add colored boomboxes to MusicStoreOthers (good place for radios/boomboxes)
if ProceduralDistributions and ProceduralDistributions.list and ProceduralDistributions.list.MusicStoreOthers then
    for _, item in ipairs(boomboxes) do
        table.insert(ProceduralDistributions.list.MusicStoreOthers.items, item)
        table.insert(ProceduralDistributions.list.MusicStoreOthers.items, 1) -- spawn weight
    end
end

-- Also add to LivingRoomShelf so small/portable radios can appear in houses
if ProceduralDistributions and ProceduralDistributions.list and ProceduralDistributions.list.LivingRoomShelf then
    for _, item in ipairs(boomboxes) do
        table.insert(ProceduralDistributions.list.LivingRoomShelf.items, item)
        table.insert(ProceduralDistributions.list.LivingRoomShelf.items, 0.5) -- lower spawn chance
    end
end

-- Optionally add to MusicStoreCDs for variety
if ProceduralDistributions and ProceduralDistributions.list and ProceduralDistributions.list.MusicStoreCDs then
    for _, item in ipairs(boomboxes) do
        table.insert(ProceduralDistributions.list.MusicStoreCDs.items, item)
        table.insert(ProceduralDistributions.list.MusicStoreCDs.items, 0.25)
    end
end

