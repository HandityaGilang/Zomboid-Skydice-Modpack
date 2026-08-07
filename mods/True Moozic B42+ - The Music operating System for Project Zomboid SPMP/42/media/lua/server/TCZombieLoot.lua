-- Adds a rare zombie loot bundle: walkman + headphones + cassette
if isClient() then return end

require "TCMusicModDetector"
require "TCMusicSandbox"

TCZombieLoot = TCZombieLoot or {}
if TCZombieLoot._registered then return end

local ZOMBIE_WALKMAN_CHANCE = 0.01 -- 1.0% (~1 in 100), tuned via sandbox rate

local WALKMAN_VARIANTS = {
    "Tsarcraft.TCWalkmanPurple",
    "Tsarcraft.TCWalkmanRed",
    "Tsarcraft.TCWalkmanBlack",
    "Tsarcraft.TCWalkmanPink",
    "Tsarcraft.TCWalkmanGreen",
    "Tsarcraft.TCWalkmanCamoGreen",
}

local function pickRandomWalkman()
    return WALKMAN_VARIANTS[ZombRand(#WALKMAN_VARIANTS) + 1]
end

local function pickRandomCassetteFullType()
    local all = {}
    if TCMusicModDetector and TCMusicModDetector.GetAllCassettes then
        local cassettes = TCMusicModDetector.GetAllCassettes()
        if cassettes then
            for _, cassette in ipairs(cassettes) do
                if type(cassette) == "table" and cassette.fullType then
                    table.insert(all, cassette.fullType)
                elseif type(cassette) == "string" then
                    table.insert(all, cassette)
                end
            end
        end
    end
    if #all > 0 then
        return all[ZombRand(#all) + 1]
    end
    return "Tsarcraft.CassetteMainTheme"
end

local function addWalkmanBundle(zombie)
    if not zombie or zombie:isSkeleton() then return end
    local inv = zombie:getInventory()
    if not inv then return end

    inv:AddItem(pickRandomWalkman())
    inv:AddItem("Base.Headphones")
    inv:AddItem(pickRandomCassetteFullType())
end

local function onZombieDead(zombie)
    if not zombie then return end
    local rate = 1.0
    if TCMusicSandbox and TCMusicSandbox.GetZombieWalkmanSpawnRate then
        rate = TCMusicSandbox.GetZombieWalkmanSpawnRate()
    end
    if rate <= 0 then return end
    if ZombRandFloat(0, 1) >= (ZOMBIE_WALKMAN_CHANCE * rate) then return end
    addWalkmanBundle(zombie)
end

Events.OnZombieDead.Add(onZombieDead)
TCZombieLoot._registered = true

