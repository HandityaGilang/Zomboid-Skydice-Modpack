require "Items/SuburbsDistributions"
require "Items/ProceduralDistributions"

local function TM_CDCase_InitDistributions()

    local function safeInsert(listName, itemName, weight)
        local dist = ProceduralDistributions.list[listName]
        if dist and dist.items then
            table.insert(dist.items, itemName)
            table.insert(dist.items, weight)
        end
    end

    local CD = "Tsarcraft.TM_CDCase"

    -- =============================================
    -- CD Case (single CD)
    -- Living rooms / bedrooms (residential, common)
    -- Music / electronics stores (commercial, very common)
    -- Cars (glove box / seats, uncommon)
    -- =============================================

    -- Residential: living rooms / bedrooms
    safeInsert("LivingRoomShelf",     CD, 6)
    safeInsert("LivingRoomSideTable", CD, 3)
    safeInsert("LivingRoomCabinet",   CD, 4)
    safeInsert("BedroomDresser",      CD, 3)
    safeInsert("BedroomSideTable",    CD, 2)
    safeInsert("Bookshelf",           CD, 2)

    -- Commercial: music / electronics stores
    safeInsert("MusicStoreCDs",       CD, 20)
    safeInsert("MusicStoreShelves",   CD, 12)
    safeInsert("MusicStoreCounter",   CD, 8)
    safeInsert("MusicStoreOthers",    CD, 6)
    safeInsert("ElectronicsStoreShelf",  CD, 6)
    safeInsert("ElectronicsStoreCounter", CD, 3)

    -- Vehicles: glove box / seats
    safeInsert("GloveBox",  CD, 2)
    safeInsert("CarSeat",   CD, 1)
    safeInsert("CarTrunk",  CD, 0.5)

    -- Schools (kids' CDs in lockers/desks, light)
    safeInsert("SchoolLockers", CD, 2)
    safeInsert("SchoolDesk",    CD, 1)

end

Events.OnPreDistributionMerge.Add(TM_CDCase_InitDistributions)
