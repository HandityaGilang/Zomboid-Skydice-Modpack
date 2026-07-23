require("Skateboard/SkateboardCore")

local Core = Skateboard.Core

---@type table<string, number>
local distributions = {
    CampingLockers = 0.7,
    ClosetSportsEquipment = 7,
    CrateSports = 7,
    CrateToys = 7,
    GarageTools = 1,
    GasStoreSpecial = 1,
    GiftStoreToys = 7,
    GigamartSchool = 7,
    GigamartToys = 7,
    GymLockers = 2,
    PawnShopCases = 1,
    PoliceEvidence = 0.7,
    PoolLockers = 2,
    PostOfficeParcels = 0.7,
    SchoolGymSportsGear = 7,
    SchoolLockers = 7,
    SportStoreAccessories = 3,
    SportStorageWeights = 1,
    SchoolLockersBad = 1
}

---@return nil
local function applyDistributions()
    for listName, weight in pairs(distributions) do
        local list = ProceduralDistributions["list"][listName]
        if list and list.items then
            table.insert(list.items, Core.ItemFullType)
            table.insert(list.items, weight)
        end
    end
end

applyDistributions()
