-- Dragonslayer - Build 42.19 procedural loot integration.

require "Items/ProceduralDistributions"

local ITEM_ID = "Dragonslayer.Dragonslayer"
local MAGAZINE_ID = "Dragonslayer.BerserkerMagazine"

-- Match every reachable primary Katana distribution and value in the exact
-- Build 42.19 ProceduralDistributions source.  The unreferenced
-- MedievalWeaponsJapan table and Katana-only broken-item junk entries are not
-- copied.
local ITEM_DISTRIBUTIONS = {
    MeleeWeapons_Mid = 0.01,
    MeleeWeapons_Late = 0.1,
    PawnShopGunsSpecial = 0.1,
    PawnShopKnives = 0.1,
}

-- The unlock magazine follows every exact Build 42.19 SmithingMag7 route at
-- full vanilla parity. This makes it as available as a normal sword-smithing
-- magazine while preserving the same specialist-to-generic location tiers.
local MAGAZINE_DISTRIBUTIONS = {
    BlacksmithLiterature = 4.0,
    BookstoreBlueCollar = 0.1,
    BookstoreMisc = 0.1,
    CrateBlacksmithing = 4.0,
    CrateMagazines = 0.1,
    GunStoreLiterature = 2.0,
    GunStoreMagazineRack = 2.0,
    Hobbies = 1.0,
    Homesteading = 1.0,
    LibraryMagazines = 1.0,
    LivingRoomShelf = 0.01,
    LivingRoomShelfClassy = 0.01,
    LivingRoomShelfRedneck = 0.01,
    LivingRoomSideTable = 0.01,
    LivingRoomSideTableClassy = 0.01,
    LivingRoomSideTableRedneck = 0.01,
    LivingRoomWardrobe = 0.01,
    MagazineRackMixed = 0.1,
    MedievalBooks = 6.0,
    PostOfficeMagazines = 0.1,
    RecRoomShelf = 0.01,
    SafehouseBookShelf = 1.0,
    ShelfGeneric = 0.01,
    SurvivalGear = 1.0,
    ToolStoreBooks = 1.0,
    UniversityLibraryMagazines = 1.0,
}

-- Distribution item arrays are alternating item/chance pairs. Remove every
-- existing copy before appending the approved pair so repeated calls are safe.
local function setChancePair(items, item, chance)
    if type(items) ~= "table" then
        return
    end

    local index = 1
    while index <= #items do
        if items[index] == item then
            if index < #items then
                table.remove(items, index + 1)
            end
            table.remove(items, index)
        else
            index = index + 2
        end
    end

    table.insert(items, item)
    table.insert(items, chance)
end

local function injectDragonslayerLoot()
    local distributions = ProceduralDistributions and ProceduralDistributions.list
    if type(distributions) ~= "table" then
        return
    end

    for distributionName, chance in pairs(ITEM_DISTRIBUTIONS) do
        local distribution = distributions[distributionName]
        if distribution and type(distribution.items) == "table" then
            setChancePair(distribution.items, ITEM_ID, chance)
        end
    end

    for distributionName, chance in pairs(MAGAZINE_DISTRIBUTIONS) do
        local distribution = distributions[distributionName]
        if distribution and type(distribution.items) == "table" then
            setChancePair(distribution.items, MAGAZINE_ID, chance)
        end
    end
end

Events.OnPreDistributionMerge.Add(injectDragonslayerLoot)
