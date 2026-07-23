require 'Items/ProceduralDistributions'
require "seifuku_defines"

Events.OnInitGlobalModData.Add(function()

    if SandboxVars.SchoolsOut.SpawnChanceToggle then

        local addToDistroTable = seifuku.addToDistroTable
        local distributeCuteClothes = seifuku.distributeCuteClothes
        local distributeSchoolUniform = seifuku.distributeSchoolUniform
        local distributeSweaters = seifuku.distributeSweaters
        local distributeTies = seifuku.distributeTies
        local distributeSocks = seifuku.distributeSocks
        local distributeGymUniform = seifuku.distributeGymUniform
        local distributeSwimsuits = seifuku.distributeSwimsuits
        local distributeShoes = seifuku.distributeShoes

        -- Teen/Child Bedrooms

        distributeCuteClothes(ProceduralDistributions.list['WardrobeChild'].items, 0.1, 0, 0.1, 0.01, 0.001)
        distributeSchoolUniform(ProceduralDistributions.list['WardrobeChild'].items, 1, 1, 1, 1, 1)
        distributeSweaters(ProceduralDistributions.list['WardrobeChild'].items, 1)
        distributeTies(ProceduralDistributions.list['WardrobeChild'].items, 1)
        distributeGymUniform(ProceduralDistributions.list['WardrobeChild'].items, 1, 1)
        distributeSwimsuits(ProceduralDistributions.list['WardrobeChild'].items, 0.5, 0.1, 0, 0)
        distributeSocks(ProceduralDistributions.list['WardrobeChild'].items, 0.5)
        distributeShoes(ProceduralDistributions.list['WardrobeChild'].items, 0.5, 0.2)

        distributeCuteClothes(ProceduralDistributions.list['BedroomDresserChild'].items, 0.1, 0, 0.1, 0.005, 0.0005)
        distributeSchoolUniform(ProceduralDistributions.list['BedroomDresserChild'].items, 1, 1, 1, 1, 1)
        distributeSweaters(ProceduralDistributions.list['BedroomDresserChild'].items, 1)
        distributeTies(ProceduralDistributions.list['BedroomDresserChild'].items, 1)
        distributeGymUniform(ProceduralDistributions.list['BedroomDresserChild'].items, 1, 1)
        distributeSwimsuits(ProceduralDistributions.list['BedroomDresserChild'].items, 0.5, 0.1, 0, 0)
        distributeSocks(ProceduralDistributions.list['BedroomDresserChild'].items, 0.5)
        distributeShoes(ProceduralDistributions.list['BedroomDresserChild'].items, 0.5, 0.2)

        distributeCuteClothes(ProceduralDistributions.list['BedroomSidetableChild'].items, 0.05, 0, 0, 0, 0)
        distributeTies(ProceduralDistributions.list['BedroomSidetableChild'].items, 0.5)

        -- University Bedrooms

        distributeCuteClothes(ProceduralDistributions.list['UniversityWardrobe'].items, 0.05, 0, 0.05, 0.01, 0.0001)
        distributeSchoolUniform(ProceduralDistributions.list['UniversityWardrobe'].items, 0.2, 0.2, 0.2, 0.2, 0.2)
        distributeSweaters(ProceduralDistributions.list['UniversityWardrobe'].items, 0.5)
        distributeTies(ProceduralDistributions.list['UniversityWardrobe'].items, 0.2)
        distributeGymUniform(ProceduralDistributions.list['UniversityWardrobe'].items, 1, 1)
        distributeSwimsuits(ProceduralDistributions.list['UniversityWardrobe'].items, 0.5, 0.1, 2, 1)
        distributeSocks(ProceduralDistributions.list['UniversityWardrobe'].items, 0.5)
        distributeShoes(ProceduralDistributions.list['UniversityWardrobe'].items, 1, 0.2)

        distributeCuteClothes(ProceduralDistributions.list['UniversitySideTable'].items, 0.05, 0, 0.05, 0.005, 0)
        distributeSchoolUniform(ProceduralDistributions.list['UniversitySideTable'].items, 0, 0.2, 0.2, 0, 0.2)
        distributeSweaters(ProceduralDistributions.list['UniversitySideTable'].items, 0.5)
        distributeTies(ProceduralDistributions.list['UniversitySideTable'].items, 0.2)
        distributeGymUniform(ProceduralDistributions.list['UniversitySideTable'].items, 1, 1)
        distributeSwimsuits(ProceduralDistributions.list['UniversitySideTable'].items, 0.5, 0.1, 2, 1)
        distributeSocks(ProceduralDistributions.list['UniversitySideTable'].items, 0.5)
        distributeShoes(ProceduralDistributions.list['UniversitySideTable'].items, 1, 0.2)

        -- School

        distributeCuteClothes(ProceduralDistributions.list['ClassroomDesk'].items, 0.1, 0, 0, 0, 0)
        distributeTies(ProceduralDistributions.list['ClassroomDesk'].items, 0.5)
        distributeShoes(ProceduralDistributions.list['ClassroomDesk'].items, 0.5, 1)

        distributeCuteClothes(ProceduralDistributions.list['ClassroomSecondaryDesk'].items, 0.1, 0, 0, 0, 0)
        distributeTies(ProceduralDistributions.list['ClassroomSecondaryDesk'].items, 0.5)
        distributeShoes(ProceduralDistributions.list['ClassroomSecondaryDesk'].items, 0.5, 1)

        distributeCuteClothes(ProceduralDistributions.list['SchoolLockers'].items, 0.1, 0, 0, 0.05, 0)
        distributeSchoolUniform(ProceduralDistributions.list['SchoolLockers'].items, 2, 2, 2, 2, 2)
        distributeSweaters(ProceduralDistributions.list['SchoolLockers'].items, 2)
        distributeTies(ProceduralDistributions.list['SchoolLockers'].items, 1)
        distributeGymUniform(ProceduralDistributions.list['SchoolLockers'].items, 8, 8)
        distributeSwimsuits(ProceduralDistributions.list['SchoolLockers'].items, 4, 1, 0, 0)
        distributeShoes(ProceduralDistributions.list['SchoolLockers'].items, 2, 6)

        distributeSchoolUniform(ProceduralDistributions.list['SchoolLockersBad'].items, 1, 0, 0, 1, 1)
        distributeSweaters(ProceduralDistributions.list['SchoolLockersBad'].items, 1)
        distributeGymUniform(ProceduralDistributions.list['SchoolLockersBad'].items, 4, 4)
        distributeShoes(ProceduralDistributions.list['SchoolLockersBad'].items, 2, 6)

        -- Other Lockers

        distributeGymUniform(ProceduralDistributions.list['GymLockers'].items, 1, 2)

        distributeSwimsuits(ProceduralDistributions.list['PoolLockers'].items, 10, 2, 0, 0)

        distributeCuteClothes(ProceduralDistributions.list['StripClubDressers'].items, 0, 0.2, 2, 0, 0)
        distributeSwimsuits(ProceduralDistributions.list['StripClubDressers'].items, 0.2, 0.2, 1, 2)
        addToDistroTable(ProceduralDistributions.list["StripClubDressers"].items, "seifuku.FemaleUniform_SailorShortWhiteBlack", 0.2)
        addToDistroTable(ProceduralDistributions.list["StripClubDressers"].items, "seifuku.FemaleUniform_SkirtBlackShort", 0.2)
        addToDistroTable(ProceduralDistributions.list["StripClubDressers"].items, "seifuku.Socks_KneeHighBlack", 4)
        addToDistroTable(ProceduralDistributions.list["StripClubDressers"].items, "seifuku.Socks_KneeHighWhite", 4)
        addToDistroTable(ProceduralDistributions.list["StripClubDressers"].items, "seifuku.Socks_OverKneeBlack", 4)
        addToDistroTable(ProceduralDistributions.list["StripClubDressers"].items, "seifuku.Socks_OverKneeWhite", 4)

        -- Clothing Stores

        distributeCuteClothes(ProceduralDistributions.list['ClothingRack'].items, 0, 0, 0, 0.01, 0)
        distributeSchoolUniform(ProceduralDistributions.list['ClothingRack'].items, 0, 0.05, 0, 0, 1)
        distributeSweaters(ProceduralDistributions.list['ClothingRack'].items, 0.5)
        distributeTies(ProceduralDistributions.list['ClothingRack'].items, 0.5)
        distributeGymUniform(ProceduralDistributions.list['ClothingRack'].items, 0.05, 0.05)
        distributeSwimsuits(ProceduralDistributions.list['ClothingRack'].items, 0.1, 0.025, 0, 0)

        addToDistroTable(ProceduralDistributions.list["ClothingStorageAllJackets"].items, "seifuku.Cute_Hoodie", 2)

        distributeSchoolUniform(ProceduralDistributions.list['ClothingStorageAllShirts'].items, 0, 2, 0, 0, 0)
        distributeSweaters(ProceduralDistributions.list['ClothingStorageAllShirts'].items, 2)
        addToDistroTable(ProceduralDistributions.list["ClothingStorageAllShirts"].items, "seifuku.GymUniform_Shirt", 6)

        distributeShoes(ProceduralDistributions.list['ClothingStorageFootwear'].items, 6, 2)

        distributeSchoolUniform(ProceduralDistributions.list['ClothingStorageLegwear'].items, 0, 0, 0, 0, 2)

        distributeSchoolUniform(ProceduralDistributions.list['ClothingStoresDress'].items, 0, 0, 4, 0, 0)

        addToDistroTable(ProceduralDistributions.list["ClothingStoresJackets"].items, "seifuku.GymUniform_TracksuitTopRed", 4)
        addToDistroTable(ProceduralDistributions.list["ClothingStoresJackets"].items, "seifuku.GymUniform_TracksuitTopBlue", 4)

        distributeSchoolUniform(ProceduralDistributions.list['ClothingStoresJacketsFormal'].items, 6, 0, 0, 6, 0)

        addToDistroTable(ProceduralDistributions.list["ClothingStoresJumpers"].items, "seifuku.Cute_Hoodie", 2)
        distributeSweaters(ProceduralDistributions.list['ClothingStoresJumpers'].items, 4)

        addToDistroTable(ProceduralDistributions.list["ClothingStoresPants"].items, "seifuku.GymUniform_TracksuitPantsRed", 4)
        addToDistroTable(ProceduralDistributions.list["ClothingStoresPants"].items, "seifuku.GymUniform_TracksuitPantsBlue", 4)

        addToDistroTable(ProceduralDistributions.list["ClothingStoresPantsFormal"].items, "seifuku.MaleUniform_Trousers", 6)

        addToDistroTable(ProceduralDistributions.list["ClothingStoresShirts"].items, "seifuku.GymUniform_Shirt", 6)

        distributeSchoolUniform(ProceduralDistributions.list['ClothingStoresShirtsFormal'].items, 0, 6, 0, 0, 0)

        distributeSocks(ProceduralDistributions.list['ClothingStoresSocks'].items, 4)

        distributeShoes(ProceduralDistributions.list['ClothingStoresShoes'].items, 6, 4)

        distributeShoes(ProceduralDistributions.list['ClothingStoresShoesLeather'].items, 10, 0)

        distributeGymUniform(ProceduralDistributions.list['ClothingStoresSport'].items, 4, 4)

        distributeSwimsuits(ProceduralDistributions.list['ClothingStoresSummer'].items, 6, 4, 2, 0)

        distributeCuteClothes(ProceduralDistributions.list['ClothingStoresUnderwearWoman'].items, 0, 0, 2, 0, 0)
        addToDistroTable(ProceduralDistributions.list["ClothingStoresUnderwearWoman"].items, "seifuku.Socks_KneeHighBlack", 4)
        addToDistroTable(ProceduralDistributions.list["ClothingStoresUnderwearWoman"].items, "seifuku.Socks_KneeHighWhite", 4)
        addToDistroTable(ProceduralDistributions.list["ClothingStoresUnderwearWoman"].items, "seifuku.Socks_OverKneeBlack", 4)
        addToDistroTable(ProceduralDistributions.list["ClothingStoresUnderwearWoman"].items, "seifuku.Socks_OverKneeWhite", 4)

        addToDistroTable(ProceduralDistributions.list["LingerieStoreOutfits"].items, "seifuku.FemaleUniform_SkirtBlackShort", 4)

        distributeCuteClothes(ProceduralDistributions.list['LingerieStoreUnderwear'].items, 0, 0, 8, 0, 0)
        addToDistroTable(ProceduralDistributions.list["LingerieStoreUnderwear"].items, "seifuku.Socks_KneeHighBlack", 10)
        addToDistroTable(ProceduralDistributions.list["LingerieStoreUnderwear"].items, "seifuku.Socks_KneeHighWhite", 10)
        addToDistroTable(ProceduralDistributions.list["LingerieStoreUnderwear"].items, "seifuku.Socks_OverKneeBlack", 10)
        addToDistroTable(ProceduralDistributions.list["LingerieStoreUnderwear"].items, "seifuku.Socks_OverKneeWhite", 10)

        addToDistroTable(ProceduralDistributions.list["SportStoreGolf"].items, "seifuku.GymUniform_PoloShirt", 10)
        addToDistroTable(ProceduralDistributions.list["SportStoreGolf"].items, "seifuku.GymUniform_PoloShirtShort", 10)

        addToDistroTable(ProceduralDistributions.list["SportStoreTennis"].items, "seifuku.GymUniform_PoloShirt", 10)
        addToDistroTable(ProceduralDistributions.list["SportStoreTennis"].items, "seifuku.GymUniform_PoloShirtShort", 10)

        addToDistroTable(ProceduralDistributions.list["SportStoreBadminton"].items, "seifuku.GymUniform_PoloShirt", 10)
        addToDistroTable(ProceduralDistributions.list["SportStoreBadminton"].items, "seifuku.GymUniform_PoloShirtShort", 10)

        distributeCuteClothes(ProceduralDistributions.list['PetShopShelf'].items, 0, 20, 0, 0, 0)

        -- Crates

        distributeCuteClothes(ProceduralDistributions.list['CrateRandomJunk'].items, 1, 2, 0.05, 0.005, 0.001)
        distributeSchoolUniform(ProceduralDistributions.list['CrateRandomJunk'].items, 0.3, 0.3, 0.2, 0.3, 0.2)
        distributeSweaters(ProceduralDistributions.list['CrateRandomJunk'].items, 0.3)
        distributeGymUniform(ProceduralDistributions.list['CrateRandomJunk'].items, 0.4, 0.4)
        distributeSwimsuits(ProceduralDistributions.list['CrateRandomJunk'].items, 0.3, 0.3, 1, 1)
        distributeShoes(ProceduralDistributions.list['CrateRandomJunk'].items, 0, 2)

        distributeSchoolUniform(ProceduralDistributions.list['CrateClothesRandom'].items, 3, 3, 0, 3, 0)
        distributeSweaters(ProceduralDistributions.list['CrateClothesRandom'].items, 3)
        distributeGymUniform(ProceduralDistributions.list['CrateClothesRandom'].items, 4, 4)
        addToDistroTable(ProceduralDistributions.list["CrateClothesRandom"].items, "seifuku.Cute_Hoodie", 0.5)

        distributeShoes(ProceduralDistributions.list['CrateFootwearRandom'].items, 6, 4)

        distributeCuteClothes(ProceduralDistributions.list['CrateCostume'].items, 4, 2, 1, 0, 0.1)

        distributeSchoolUniform(ProceduralDistributions.list['CrateTailoring'].items, 0, 6, 0, 0, 6)

        -- Misc

        distributeGymUniform(ProceduralDistributions.list['ClosetSportsEquipment'].items, 0.05, 0.05)

        distributeSwimsuits(ProceduralDistributions.list['VacationStuff'].items, 6, 2, 3, 0)

        distributeCuteClothes(ProceduralDistributions.list['Gifts'].items, 0.8, 0.2, 0.4, 0.005, 0.001)
        addToDistroTable(ProceduralDistributions.list["Gifts"].items, "seifuku.FemaleUniform_SailorShortWhiteBlack", 4)

        -- Laundry

        distributeGymUniform(ProceduralDistributions.list['GymLaundry'].items, 2, 2)

        addToDistroTable(ProceduralDistributions.list["LaundryLoad3"].items, "seifuku.MaleUniform_Trousers", 4)

        addToDistroTable(ProceduralDistributions.list["LaundryLoad4"].items, "seifuku.GymUniform_Shirt", 10)

        distributeSweaters(ProceduralDistributions.list['LaundryLoad5'].items, 2)

        distributeCuteClothes(ProceduralDistributions.list['LaundryLoad6'].items, 0, 0, 0, 0.05, 0.001)
        distributeSchoolUniform(ProceduralDistributions.list['LaundryLoad6'].items, 0, 0.4, 0.4, 0, 0.2)
        distributeSweaters(ProceduralDistributions.list['LaundryLoad6'].items, 0.4)
        distributeGymUniform(ProceduralDistributions.list['LaundryLoad6'].items, 0.5, 0.4)
        distributeSwimsuits(ProceduralDistributions.list['LaundryLoad6'].items, 0.3, 0.1, 5, 0)

        addToDistroTable(ProceduralDistributions.list["LaundryLoad7"].items, "seifuku.GymUniform_Shirt", 10)
        distributeSocks(ProceduralDistributions.list['LaundryLoad7'].items, 5)

        addToDistroTable(ProceduralDistributions.list["LaundryLoad8"].items, "seifuku.GymUniform_Bloomers", 0.8)
        distributeSocks(ProceduralDistributions.list['LaundryLoad8'].items, 5)

        ItemPickerJava.Parse()

    end
end)