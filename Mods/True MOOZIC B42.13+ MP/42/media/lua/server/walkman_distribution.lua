-- walkman_distribution.lua
-- Adds colored walkman variants to procedural loot tables

require "Items/ProceduralDistributions"
require "Items/SuburbsDistributions"

local walkmans = {
    "Tsarcraft.TCWalkmanPurple",
    "Tsarcraft.TCWalkmanRed",
    "Tsarcraft.TCWalkmanBlack",
    "Tsarcraft.TCWalkmanPink",
    "Tsarcraft.TCWalkmanGreen",
    "Tsarcraft.TCWalkmanCamoGreen",
}

-- Add walkman variants to MusicStoreOthers (small radios/portable players)
if ProceduralDistributions and ProceduralDistributions.list and ProceduralDistributions.list.MusicStoreOthers then
    for _, item in ipairs(walkmans) do
        table.insert(ProceduralDistributions.list.MusicStoreOthers.items, item)
        table.insert(ProceduralDistributions.list.MusicStoreOthers.items, 1)
    end
end

-- Also add to LivingRoomShelf so portable players can appear in houses
if ProceduralDistributions and ProceduralDistributions.list and ProceduralDistributions.list.LivingRoomShelf then
    for _, item in ipairs(walkmans) do
        table.insert(ProceduralDistributions.list.LivingRoomShelf.items, item)
        table.insert(ProceduralDistributions.list.LivingRoomShelf.items, 0.5)
    end
end

-- Add to BedroomDresser for small personal items
if ProceduralDistributions and ProceduralDistributions.list and ProceduralDistributions.list.BedroomDresser then
    for _, item in ipairs(walkmans) do
        table.insert(ProceduralDistributions.list.BedroomDresser.items, item)
        table.insert(ProceduralDistributions.list.BedroomDresser.items, 0.5)
    end
end

-- Optionally add to MusicStoreCDs for variety
if ProceduralDistributions and ProceduralDistributions.list and ProceduralDistributions.list.MusicStoreCDs then
    for _, item in ipairs(walkmans) do
        table.insert(ProceduralDistributions.list.MusicStoreCDs.items, item)
        table.insert(ProceduralDistributions.list.MusicStoreCDs.items, 0.25)
    end
end

