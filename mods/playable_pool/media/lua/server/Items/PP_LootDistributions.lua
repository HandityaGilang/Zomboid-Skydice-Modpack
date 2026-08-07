require "Items/ProceduralDistributions"

local function addItems(distributionName, weightedItems)
    if not ProceduralDistributions or not ProceduralDistributions.list then
        return
    end
    local distribution = ProceduralDistributions.list[distributionName]
    if not distribution or not distribution.items then
        return
    end
    for i = 1, #weightedItems, 2 do
        table.insert(distribution.items, weightedItems[i])
        table.insert(distribution.items, weightedItems[i + 1])
    end
end

local commonBooks = {
    "BookBilliards1", 8,
    "BookBilliards2", 6,
    "BookBilliards3", 4,
    "BookBilliards4", 2,
    "BookBilliards5", 1,
}

local focusedBooks = {
    "BookBilliards1", 10,
    "BookBilliards2", 8,
    "BookBilliards3", 6,
    "BookBilliards4", 4,
    "BookBilliards5", 2,
}

addItems("BookstoreBooks", focusedBooks)
addItems("LibraryBooks", commonBooks)
addItems("SafehouseBookShelf", {
    "BookBilliards1", 1,
    "BookBilliards2", 1,
    "BookBilliards3", 1,
    "BookBilliards4", 1,
    "BookBilliards5", 0.5,
})
addItems("BookstoreSports", {
    "BookBilliards1", 4,
    "BookBilliards2", 3,
    "BookBilliards3", 2,
    "BookBilliards4", 1,
    "BookBilliards5", 0.5,
})
addItems("LibrarySports", {
    "BookBilliards1", 3,
    "BookBilliards2", 2,
    "BookBilliards3", 1,
    "BookBilliards4", 0.5,
    "BookBilliards5", 0.25,
})
addItems("UniversityLibrarySports", {
    "BookBilliards3", 4,
    "BookBilliards4", 2,
    "BookBilliards5", 1,
})
