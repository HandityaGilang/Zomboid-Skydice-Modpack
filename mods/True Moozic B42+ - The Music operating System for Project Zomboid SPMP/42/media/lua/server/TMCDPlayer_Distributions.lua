require "Items/SuburbsDistributions"
require "Items/ProceduralDistributions"

local function TM_InitDistributions()

    local function safeInsert(listName, itemName, weight)
        local dist = ProceduralDistributions.list[listName]
        if dist and dist.items then
            table.insert(dist.items, itemName)
            table.insert(dist.items, weight)
        end
    end

    -- =============================================
    -- CDPlayer variants — schools, music stores, rare in gloveboxes
    -- =============================================

    -- SchoolLockers
    safeInsert("SchoolLockers", "Tsarcraft.TM_CDPlayer_Blue", 4)
    safeInsert("SchoolLockers", "Tsarcraft.TM_CDPlayer_Purple", 4)
    safeInsert("SchoolLockers", "Tsarcraft.TM_CDPlayer_Red", 4)
    safeInsert("SchoolLockers", "Tsarcraft.TM_CDPlayer_Black", 4)
    safeInsert("SchoolLockers", "Tsarcraft.TM_CDPlayer_Green", 4)
    safeInsert("SchoolLockers", "Tsarcraft.TM_CDPlayer_Orange", 4)
    safeInsert("SchoolLockers", "Tsarcraft.TM_CDPlayer_White", 4)
    safeInsert("SchoolLockers", "Tsarcraft.TM_CDPlayer_TrueMoozic", 2)

    -- SchoolDesk
    safeInsert("SchoolDesk", "Tsarcraft.TM_CDPlayer_Blue", 2)
    safeInsert("SchoolDesk", "Tsarcraft.TM_CDPlayer_Purple", 2)
    safeInsert("SchoolDesk", "Tsarcraft.TM_CDPlayer_Red", 2)
    safeInsert("SchoolDesk", "Tsarcraft.TM_CDPlayer_Black", 2)
    safeInsert("SchoolDesk", "Tsarcraft.TM_CDPlayer_Green", 2)
    safeInsert("SchoolDesk", "Tsarcraft.TM_CDPlayer_Orange", 2)
    safeInsert("SchoolDesk", "Tsarcraft.TM_CDPlayer_White", 2)
    safeInsert("SchoolDesk", "Tsarcraft.TM_CDPlayer_TrueMoozic", 1)

    -- MusicStoreShelves
    safeInsert("MusicStoreShelves", "Tsarcraft.TM_CDPlayer_Blue", 8)
    safeInsert("MusicStoreShelves", "Tsarcraft.TM_CDPlayer_Purple", 8)
    safeInsert("MusicStoreShelves", "Tsarcraft.TM_CDPlayer_Red", 8)
    safeInsert("MusicStoreShelves", "Tsarcraft.TM_CDPlayer_Black", 8)
    safeInsert("MusicStoreShelves", "Tsarcraft.TM_CDPlayer_Green", 8)
    safeInsert("MusicStoreShelves", "Tsarcraft.TM_CDPlayer_Orange", 8)
    safeInsert("MusicStoreShelves", "Tsarcraft.TM_CDPlayer_White", 8)
    safeInsert("MusicStoreShelves", "Tsarcraft.TM_CDPlayer_TrueMoozic", 4)

    -- MusicStoreCounter
    safeInsert("MusicStoreCounter", "Tsarcraft.TM_CDPlayer_Blue", 6)
    safeInsert("MusicStoreCounter", "Tsarcraft.TM_CDPlayer_Purple", 6)
    safeInsert("MusicStoreCounter", "Tsarcraft.TM_CDPlayer_Red", 6)
    safeInsert("MusicStoreCounter", "Tsarcraft.TM_CDPlayer_Black", 6)
    safeInsert("MusicStoreCounter", "Tsarcraft.TM_CDPlayer_Green", 6)
    safeInsert("MusicStoreCounter", "Tsarcraft.TM_CDPlayer_Orange", 6)
    safeInsert("MusicStoreCounter", "Tsarcraft.TM_CDPlayer_White", 6)
    safeInsert("MusicStoreCounter", "Tsarcraft.TM_CDPlayer_TrueMoozic", 3)

    -- GloveBox (rare)
    safeInsert("GloveBox", "Tsarcraft.TM_CDPlayer_Blue", 0.5)
    safeInsert("GloveBox", "Tsarcraft.TM_CDPlayer_Purple", 0.5)
    safeInsert("GloveBox", "Tsarcraft.TM_CDPlayer_Red", 0.5)
    safeInsert("GloveBox", "Tsarcraft.TM_CDPlayer_Black", 0.5)
    safeInsert("GloveBox", "Tsarcraft.TM_CDPlayer_Green", 0.5)
    safeInsert("GloveBox", "Tsarcraft.TM_CDPlayer_Orange", 0.5)
    safeInsert("GloveBox", "Tsarcraft.TM_CDPlayer_White", 0.5)
    safeInsert("GloveBox", "Tsarcraft.TM_CDPlayer_TrueMoozic", 0.25)

    -- =============================================
    -- CDCarryingCase — schools, music stores, gloveboxes
    -- =============================================

    safeInsert("SchoolLockers", "Tsarcraft.TM_CDCarryingCase", 4)
    safeInsert("SchoolDesk", "Tsarcraft.TM_CDCarryingCase", 2)
    safeInsert("MusicStoreShelves", "Tsarcraft.TM_CDCarryingCase", 8)
    safeInsert("MusicStoreCounter", "Tsarcraft.TM_CDCarryingCase", 6)
    safeInsert("GloveBox", "Tsarcraft.TM_CDCarryingCase", 1)

end

Events.OnPreDistributionMerge.Add(TM_InitDistributions)
