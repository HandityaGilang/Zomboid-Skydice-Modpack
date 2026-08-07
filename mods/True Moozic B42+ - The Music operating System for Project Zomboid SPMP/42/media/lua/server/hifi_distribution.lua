require "Items/SuburbsDistributions"
require "Items/ProceduralDistributions"

local function TM_HiFi_InitDistributions()

    local function safeInsert(listName, itemName, weight)
        local dist = ProceduralDistributions.list[listName]
        if dist and dist.items then
            table.insert(dist.items, itemName)
            table.insert(dist.items, weight)
        end
    end

    local HIFI = "Tsarcraft.TM_HiFiStereo"

    -- =============================================
    -- HiFi Stereo
    -- Living rooms / bedrooms (residential, common)
    -- Electronics / music stores (commercial, more common)
    -- Garages / sheds (uncommon)
    -- =============================================

    -- Residential: living rooms / bedrooms
    safeInsert("LivingRoomShelf",     HIFI, 2)
    safeInsert("LivingRoomSideTable", HIFI, 1)
    safeInsert("BedroomDresser",      HIFI, 1)
    safeInsert("BedroomSideTable",    HIFI, 0.5)

    -- Commercial: electronics / music stores
    safeInsert("ElectronicsStoreShelf", HIFI, 4)
    safeInsert("ElectronicsStoreCounter", HIFI, 2)
    safeInsert("MusicStoreShelves",   HIFI, 4)
    safeInsert("MusicStoreCounter",   HIFI, 2)
    safeInsert("MusicStoreOthers",    HIFI, 2)

    -- Garages / sheds
    safeInsert("GarageShelf",  HIFI, 1)
    safeInsert("GarageMisc",   HIFI, 1)
    safeInsert("GarageTools",  HIFI, 0.25)
    safeInsert("ShedShelf",    HIFI, 1)
    safeInsert("StorageUnitShelves", HIFI, 0.5)

end

Events.OnPreDistributionMerge.Add(TM_HiFi_InitDistributions)
