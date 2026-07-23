require 'Items/SuburbsDistributions'
require 'Items/ProceduralDistributions'

-- Helper: safe insert that skips missing distribution tables (B42 may rename some)
local function safeInsert(tbl, key, item, chance)
    if tbl and tbl[key] and tbl[key].items then
        table.insert(tbl[key].items, item)
        table.insert(tbl[key].items, chance)
    end
end

local proc = ProceduralDistributions["list"]
local sub  = SuburbsDistributions

-- BookstoreBooks (general bookstore)
safeInsert(proc, "BookstoreBooks",          "RGM.BookTinkering1", 27)
safeInsert(proc, "BookstoreBooks",          "RGM.BookTinkering2", 21)
safeInsert(proc, "BookstoreBooks",          "RGM.BookTinkering3", 16)
safeInsert(proc, "BookstoreBooks",          "RGM.BookTinkering4", 11)
safeInsert(proc, "BookstoreBooks",          "RGM.BookTinkering5", 5)

-- BookstoreBlueCollar (technical/trade bookstore — best thematic fit)
safeInsert(proc, "BookstoreBlueCollar",     "RGM.BookTinkering1", 10)
safeInsert(proc, "BookstoreBlueCollar",     "RGM.BookTinkering2", 8)
safeInsert(proc, "BookstoreBlueCollar",     "RGM.BookTinkering3", 6)
safeInsert(proc, "BookstoreBlueCollar",     "RGM.BookTinkering4", 4)
safeInsert(proc, "BookstoreBlueCollar",     "RGM.BookTinkering5", 2)

-- LibraryBooks
safeInsert(proc, "LibraryBooks",            "RGM.BookTinkering1", 21)
safeInsert(proc, "LibraryBooks",            "RGM.BookTinkering2", 16)
safeInsert(proc, "LibraryBooks",            "RGM.BookTinkering3", 11)
safeInsert(proc, "LibraryBooks",            "RGM.BookTinkering4", 5)
safeInsert(proc, "LibraryBooks",            "RGM.BookTinkering5", 3)

-- ToolStoreBooks (tool store bookshelf)
safeInsert(proc, "ToolStoreBooks",          "RGM.BookTinkering1", 16)
safeInsert(proc, "ToolStoreBooks",          "RGM.BookTinkering2", 11)
safeInsert(proc, "ToolStoreBooks",          "RGM.BookTinkering3", 5)
safeInsert(proc, "ToolStoreBooks",          "RGM.BookTinkering4", 3)
safeInsert(proc, "ToolStoreBooks",          "RGM.BookTinkering5", 1.33)

-- PostOfficeBooks
safeInsert(proc, "PostOfficeBooks",         "RGM.BookTinkering1", 16)
safeInsert(proc, "PostOfficeBooks",         "RGM.BookTinkering2", 11)
safeInsert(proc, "PostOfficeBooks",         "RGM.BookTinkering3", 5)
safeInsert(proc, "PostOfficeBooks",         "RGM.BookTinkering4", 3)
safeInsert(proc, "PostOfficeBooks",         "RGM.BookTinkering5", 1.33)

-- CrateBooks (warehouse crates)
safeInsert(proc, "CrateBooks",              "RGM.BookTinkering1", 16)
safeInsert(proc, "CrateBooks",              "RGM.BookTinkering2", 11)
safeInsert(proc, "CrateBooks",              "RGM.BookTinkering3", 5)
safeInsert(proc, "CrateBooks",              "RGM.BookTinkering4", 3)
safeInsert(proc, "CrateBooks",              "RGM.BookTinkering5", 1.33)

-- EngineerTools (engineering workshop)
safeInsert(proc, "EngineerTools",           "RGM.BookTinkering1", 10)
safeInsert(proc, "EngineerTools",           "RGM.BookTinkering2", 8)
safeInsert(proc, "EngineerTools",           "RGM.BookTinkering3", 6)
safeInsert(proc, "EngineerTools",           "RGM.BookTinkering4", 4)
safeInsert(proc, "EngineerTools",           "RGM.BookTinkering5", 2)

-- GarageMechanics
safeInsert(proc, "GarageMechanics",        "RGM.BookTinkering1", 6)
safeInsert(proc, "GarageMechanics",        "RGM.BookTinkering2", 4)
safeInsert(proc, "GarageMechanics",        "RGM.BookTinkering3", 2)
safeInsert(proc, "GarageMechanics",        "RGM.BookTinkering4", 1)
safeInsert(proc, "GarageMechanics",        "RGM.BookTinkering5", 0.5)

-- GarageMetalwork
safeInsert(proc, "GarageMetalwork",        "RGM.BookTinkering1", 6)
safeInsert(proc, "GarageMetalwork",        "RGM.BookTinkering2", 4)
safeInsert(proc, "GarageMetalwork",        "RGM.BookTinkering3", 2)
safeInsert(proc, "GarageMetalwork",        "RGM.BookTinkering4", 1)
safeInsert(proc, "GarageMetalwork",        "RGM.BookTinkering5", 0.5)

-- GarageTools (general garage, low chance)
safeInsert(proc, "GarageTools",            "RGM.BookTinkering1", 2)
safeInsert(proc, "GarageTools",            "RGM.BookTinkering2", 1)
safeInsert(proc, "GarageTools",            "RGM.BookTinkering3", 0.5)

-- LivingRoomShelf / ShelfGeneric (homes)
safeInsert(proc, "LivingRoomShelf",        "RGM.BookTinkering1", 5)
safeInsert(proc, "LivingRoomShelf",        "RGM.BookTinkering2", 3)
safeInsert(proc, "LivingRoomShelf",        "RGM.BookTinkering3", 1.33)
safeInsert(proc, "LivingRoomShelf",        "RGM.BookTinkering4", 0.27)
safeInsert(proc, "LivingRoomShelf",        "RGM.BookTinkering5", 0.03)

safeInsert(proc, "LivingRoomShelfNoTapes", "RGM.BookTinkering1", 5)
safeInsert(proc, "LivingRoomShelfNoTapes", "RGM.BookTinkering2", 3)
safeInsert(proc, "LivingRoomShelfNoTapes", "RGM.BookTinkering3", 1.33)
safeInsert(proc, "LivingRoomShelfNoTapes", "RGM.BookTinkering4", 0.27)
safeInsert(proc, "LivingRoomShelfNoTapes", "RGM.BookTinkering5", 0.03)

safeInsert(proc, "ShelfGeneric",           "RGM.BookTinkering1", 5)
safeInsert(proc, "ShelfGeneric",           "RGM.BookTinkering2", 3)
safeInsert(proc, "ShelfGeneric",           "RGM.BookTinkering3", 1.33)
safeInsert(proc, "ShelfGeneric",           "RGM.BookTinkering4", 0.27)
safeInsert(proc, "ShelfGeneric",           "RGM.BookTinkering5", 0.03)

safeInsert(proc, "KitchenBook",            "RGM.BookTinkering1", 1.6)
safeInsert(proc, "KitchenBook",            "RGM.BookTinkering2", 0.8)
safeInsert(proc, "KitchenBook",            "RGM.BookTinkering3", 0.27)
safeInsert(proc, "KitchenBook",            "RGM.BookTinkering4", 0.13)
safeInsert(proc, "KitchenBook",            "RGM.BookTinkering5", 0.03)

-- Magazine distributions
safeInsert(proc, "BookstoreBlueCollar",         "RGM.TinkeringMag", 3)
safeInsert(proc, "BookstoreMisc",               "RGM.TinkeringMag", 5)
safeInsert(proc, "CrateMagazines",              "RGM.TinkeringMag", 3)
safeInsert(proc, "EngineerTools",               "RGM.TinkeringMag", 5)
safeInsert(proc, "GarageMechanics",             "RGM.TinkeringMag", 3)
safeInsert(proc, "GarageMetalwork",             "RGM.TinkeringMag", 3)
safeInsert(proc, "GarageTools",                 "RGM.TinkeringMag", 2)
safeInsert(proc, "LibraryBooks",                "RGM.TinkeringMag", 3)
safeInsert(proc, "LivingRoomShelf",             "RGM.TinkeringMag", 0.27)
safeInsert(proc, "LivingRoomShelfNoTapes",      "RGM.TinkeringMag", 0.27)
safeInsert(proc, "LivingRoomSideTable",         "RGM.TinkeringMag", 0.27)
safeInsert(proc, "LivingRoomSideTableNoRemote", "RGM.TinkeringMag", 0.27)
safeInsert(proc, "MagazineRackMixed",           "RGM.TinkeringMag", 3)
safeInsert(proc, "PostOfficeMagazines",         "RGM.TinkeringMag", 3)
safeInsert(proc, "ShelfGeneric",                "RGM.TinkeringMag", 0.27)
safeInsert(proc, "StoreShelfMechanics",         "RGM.TinkeringMag", 0.53)
safeInsert(proc, "ToolStoreBooks",              "RGM.TinkeringMag", 5)

-- SuburbsDistributions: postbox
if sub and sub["all"] and sub["all"]["postbox"] and sub["all"]["postbox"].items then
    table.insert(sub["all"]["postbox"].items, "RGM.TinkeringMag")
    table.insert(sub["all"]["postbox"].items, 1.33)
end
