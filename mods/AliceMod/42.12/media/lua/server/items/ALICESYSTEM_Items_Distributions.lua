
require "Items/ProceduralDistributions"
require "Items/ItemPicker"





local ALICE_ClothingDistribution = {
    Trapper = {
        {"ALICE.AliceVest2PTight", 0.02},
        {"ALICE.AliceCanteen", 0.02},
        {"ALICE.M9BayonetSheath", 0.02},
        {"ALICE.M9Bayonet", 0.02},
        {"ALICE.AliceBackpack", 0.02},
        {"ALICE.AliceFieldpack", 0.02},
        {"ALICE.M9Bayonet", 0.02},
    },
    ArmyBunkerLockers = {
        {"ALICE.AliceVest2PTight", 0.02},
        {"ALICE.AliceCanteen", 0.02},
        {"ALICE.M9BayonetSheath", 0.02},
        {"ALICE.M9Bayonet", 0.02},
        {"ALICE.AliceBackpack", 0.02},
        {"ALICE.AliceFieldpack", 0.02},
        {"ALICE.M9Bayonet", 0.02},
    },
    SurvivalGear = {
        {"ALICE.AliceVest2PTight", 0.02},
        {"ALICE.AliceCanteen", 2},
        {"ALICE.M9BayonetSheath", 0.05},
        {"ALICE.M9Bayonet", 0.05},
        {"ALICE.AliceBackpack", 0.03},
        {"ALICE.AliceFieldpack", 0.03},
        {"ALICE.M9Bayonet", 0.05},
    },
    ArmySurplusOutfit = {
        {"ALICE.AliceVest2PTight", 2},
        {"ALICE.AliceCanteen", 2},
        {"ALICE.M9BayonetSheath", 2},
        {"ALICE.AliceBackpack", 2},
        {"ALICE.AliceFieldpack", 2},
        {"ALICE.M9Bayonet", 2},
    },
     ArmyStorageOutfit = {
        {"ALICE.AliceVest2PTight", 2},
        {"ALICE.AliceCanteen", 2},
        {"ALICE.M9BayonetSheath", 2},
        {"ALICE.AliceBackpack", 2},
        {"ALICE.AliceFieldpack", 2},
        {"ALICE.M9Bayonet", 2},
    },
    CampingStoreClothes = {
        {"ALICE.AliceVest2PTight", 2},
        {"ALICE.AliceCanteen", 2},
        {"ALICE.M9BayonetSheath", 2},
        {"ALICE.M9Bayonet", 2},
        {"ALICE.AliceBackpack", 2},
        {"ALICE.AliceFieldpack", 2},
    },
    CrateRandomJunk = {
        {"ALICE.AliceVest2PTight", 0.002},
        {"ALICE.AliceCanteen", 0.004},
        {"ALICE.M9BayonetSheath", 0.002},
        {"ALICE.AliceBackpack", 0.002},
        {"ALICE.AliceFieldpack", 0.002},
        {"ALICE.M9Bayonet", 0.002},
    },
    Hunter = {
        {"ALICE.AliceVest2PTight", 1},
        {"ALICE.AliceCanteen", 0.5},
        {"ALICE.M9BayonetSheath", 1},
        {"ALICE.AliceBackpack", 1},
        {"ALICE.AliceFieldpack", 1},
        {"ALICE.M9Bayonet", 1},
    },
    LockerArmyBedroom = {
        {"ALICE.AliceVest2PTight", 2},
        {"ALICE.AliceCanteen", 2},
        {"ALICE.M9BayonetSheath", 2},
        {"ALICE.M9Bayonet", 2},
        {"ALICE.AliceBackpack", 0.2},
        {"ALICE.AliceFieldpack", 0.2},
    },
    LockerArmyBedroomHome = {
        {"ALICE.AliceVest2PTight", 2},
        {"ALICE.AliceCanteen", 2},
        {"ALICE.M9BayonetSheath", 2},
        {"ALICE.M9Bayonet", 2},
        {"ALICE.AliceBackpack", 0.2},
        {"ALICE.AliceFieldpack", 0.2},
    },
    SafehouseArmor_Mid = {
        {"ALICE.AliceVest2PTight", 2},
        {"ALICE.AliceCanteen", 2},
        {"ALICE.M9BayonetSheath", 2},
        {"ALICE.M9Bayonet", 2},
        {"ALICE.AliceBackpack", 0.2},
        {"ALICE.AliceFieldpack", 0.2},
    },
    SafehouseArmor_Late = {
        {"ALICE.AliceVest2PTight", 2},
        {"ALICE.AliceCanteen", 2},
        {"ALICE.M9BayonetSheath", 2},
        {"ALICE.M9Bayonet", 2},
        {"ALICE.AliceBackpack", 0.2},
        {"ALICE.AliceFieldpack", 0.2},
    },
    WardrobeRedneck = {
        {"ALICE.AliceVest2PTight", 0.002},
        {"ALICE.AliceCanteen", 0.004},
        {"ALICE.M9BayonetSheath", 0.002},
        {"ALICE.M9Bayonet", 0.002},
        {"ALICE.AliceBackpack", 0.002},
        {"ALICE.AliceFieldpack", 0.002},
    },
}

local function add2Distribution(distributionTable)
    for location,locationItems in pairs(distributionTable) do
        for _,item in ipairs(locationItems) do
            table.insert(ProceduralDistributions.list[location].items, item[1])
            table.insert(ProceduralDistributions.list[location].items, item[2])
        end
    end
end

add2Distribution(ALICE_ClothingDistribution)
