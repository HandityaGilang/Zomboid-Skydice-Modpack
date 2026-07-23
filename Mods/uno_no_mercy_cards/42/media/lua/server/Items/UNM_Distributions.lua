require "Items/ProceduralDistributions"

UNM_Distributions = UNM_Distributions or {}

local ITEM = "Base.NoMercyDeck"

local PROCEDURAL_LOOT = {
    ClassroomDesk = 2,
    ClassroomMisc = 2,
    ClassroomShelves = 2,
    SchoolLockers = 1,
    DaycareShelves = 2,
    CrateToys = 3,
    GigamartToys = 3,
    StoreShelfGames = 3,
    StoreShelfBoardGames = 3,
    BookstoreMisc = 1,
    LivingRoomShelf = 1,
    LivingRoomSideTable = 1,
    BedroomDresser = 1,
    BedroomSideTable = 1,
    ClosetShelfGeneric = 1,
}

local function addProceduralItem(listName, chance)
    local distributions = ProceduralDistributions and ProceduralDistributions.list
    local list = distributions and distributions[listName] or nil
    if not list or not list.items then
        return
    end
    table.insert(list.items, ITEM)
    table.insert(list.items, chance)
end

function UNM_Distributions.apply()
    if UNM_Distributions.applied then
        return
    end
    UNM_Distributions.applied = true
    for listName, chance in pairs(PROCEDURAL_LOOT) do
        addProceduralItem(listName, chance)
    end
end

UNM_Distributions.apply()

