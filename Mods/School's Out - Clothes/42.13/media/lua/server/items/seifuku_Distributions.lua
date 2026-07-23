require "Items/SuburbsDistributions"
require "seifuku_defines"

Events.OnInitGlobalModData.Add(function()

    if SandboxVars.SchoolsOut.SpawnChanceToggle then

        local addToDistroTable = seifuku.addToDistroTable
        -- local distributeCuteClothes = seifuku.distributeCuteClothes
        -- local distributeSchoolUniform = seifuku.distributeSchoolUniform
        -- local distributeTies = seifuku.distributeTies
        local distributeGymUniform = seifuku.distributeGymUniform
        local distributeSwimsuits = seifuku.distributeSwimsuits
        local distributeShoes = seifuku.distributeShoes

        addToDistroTable(SuburbsDistributions["Bag_BigHikingBag"].items, "Base.Cute_Hoodie", 0.05)

        addToDistroTable(SuburbsDistributions["Bag_NormalHikingBag"].items, "Base.Cute_Hoodie", 0.05)

        distributeGymUniform(SuburbsDistributions["Bag_DuffelBag"].items, 2, 1)
        addToDistroTable(SuburbsDistributions["Bag_DuffelBag"].items, "Base.Cute_Hoodie", 0.05)

        distributeGymUniform(SuburbsDistributions["Bag_DuffelBagTINT"].items, 2, 1)
        addToDistroTable(SuburbsDistributions["Bag_DuffelBagTINT"].items, "Base.Cute_Hoodie", 0.05)

        distributeGymUniform(SuburbsDistributions["Bag_Schoolbag"].items, 1, 1)
        distributeSwimsuits(SuburbsDistributions["Bag_Schoolbag"].items, 1, 0.2, 0, 0)
        distributeShoes(SuburbsDistributions["Bag_Schoolbag"].items, 0.5, 4)

        ItemPickerJava.Parse()

    end
end)