-- Insere os livros customizados nas tabelas de loot
require "Items/ProceduralDistributions"

local function ApplyPK42BookDistributions()
    -- tabela e chance
    local bookTables = {
        BookstoreBooks                = 1,
        BookstoreMisc                 = 0.5,
        BookstoreOutdoors             = 0.5,
        CampingStoreBooks             = 0.5,
        ClassroomDesk                 = 0.1,
        ClassroomMisc                 = 0.1,
        ClassroomShelves              = 0.1,
        ClassroomSecondaryDesk        = 0.1,
        ClassroomSecondaryMisc        = 0.1,
        ClassroomSecondaryShelves     = 0.1,
        CrateBooks                    = 1,
        GigamartLiterature            = 1,
        LibraryBooks                  = 1,
        LibraryCounter                = 0.5,
        LivingRoomShelf               = 0.05,
        LivingRoomShelfClassy         = 0.05,
        LivingRoomShelfRedneck        = 0.05,
        LivingRoomSideTable           = 0.05,
        LivingRoomSideTableClassy     = 0.5,
        LivingRoomSideTableRedneck    = 0.05,
        PostOfficeBooks               = 0.5,
        RecRoomShelf                  = 0.5,
        SafehouseBookShelf            = 0.5,
        ShelfGeneric                  = 0.5,
        UniversityLibraryBooks        = 5,
        ToolStoreBooks                = 0.1,
        UniversitySideTable           = 1,
    }

    -- itens a serem inseridos
    local books = {
        "PK42.BookPsychopath1",
        "PK42.BookPsychopath2",
        "PK42.BookPsychopath3",
        "PK42.BookPsychopath4",
        "PK42.BookPsychopath5",
    }

    local flierTables = {
        BookstoreBooks                = 2,
        BookstoreMisc                 = 2,
        BookstoreOutdoors             = 1,
        CampingStoreBooks             = 8,
        ClassroomShelves              = 0.5,
        ClassroomSecondaryDesk        = 0.2,
        ClassroomSecondaryMisc        = 0.2,
        ClassroomSecondaryShelves     = 0.2,
        CrateBooks                    = 4,
        CrateMagazines                = 2,
        CrateNewspapers               = 0.5,
        CrateNewspapersNew            = 0.5,
        GigamartLiterature            = 3,
        LibraryBooks                  = 4,
        LibraryBiography              = 1,
        LibraryBusiness               = 2,
        LibraryCounter                = 3,
        LibraryMagazines              = 2,
        LibraryOutdoors               = 2,
        LivingRoomShelf               = 0.5,
        LivingRoomShelfClassy         = 0.5,
        LivingRoomShelfRedneck        = 0.5,
        LivingRoomSideTable           = 0.5,
        LivingRoomSideTableClassy     = 0.5,
        LivingRoomSideTableRedneck    = 0.5,
        LivingRoomWardrobe            = 0.1,
        MagazineRackMixed             = 0.1,
        PostOfficeBooks               = 3,
        PostOfficeMagazines           = 1,
        RecRoomShelf                  = 0.5,
        SafehouseArmor                = 1,
        SafehouseBookShelf            = 1,
        SafehouseFireplace            = 0.1,
        SafehouseFireplace_Late       = 0.1,
        ShelfGeneric                  = 2,
        ToolStoreBooks                = 4,
        UniversityLibraryBooks        = 5,
        UniversityLibraryMedical      = 3,
        UniversitySideTable           = 1,
        AmbulanceDriverOutfit         = 1,
        AmbulanceDriverTools          = 0.5,
        BookstoreCrafts               = 3,
        ArmySurplusLiterature         = 3,
        CabinetFactoryTools           = 1,
        CarpenterTools                = 1,
        ComicStoreMagazines           = 1,
        ConstructionWorkerTools       = 0.1,
        GarageCarpentry               = 0.2,
        GarageTools                   = 0.5,
        GeneratorRoom                 = 2,
        GunStoreLiterature            = 1,
        MetalWorkerOutfit             = 1,
        MetalWorkerTools              = 1,
        SurvivalGear                  = 1,
    }

    local fliers = {
        "PK42.PsychoFlierPage1",
    }

    for tableName, chance in pairs(bookTables) do
        local dist = ProceduralDistributions.list[tableName]
        if dist and dist.items then
            for _, book in ipairs(books) do
                table.insert(dist.items, book)
                table.insert(dist.items, chance)
            end
        else
            print("[PK42] WARNING: table not found:", tableName)
        end
    end

    for tableName, chance in pairs(flierTables) do
        local dist = ProceduralDistributions.list[tableName]
        if dist and dist.items then
            for _, flier in ipairs(fliers) do
                table.insert(dist.items, flier)
                table.insert(dist.items, chance)
            end
        else
            print("[PK42] WARNING: table not found:", tableName)
        end
    end

    ItemPickerJava.Parse() -- recarrega as tabelas de loot
    print("[PK42] Book distributions applied.")
end

-- Primeiro evento após o carregamento do sandbox
-- É possível inserir as distribuições antes sem necessidade do evento
-- Mas assim é possível fazer o loot usar opções de sandbox futuramente
Events.OnInitGlobalModData.Add(ApplyPK42BookDistributions)