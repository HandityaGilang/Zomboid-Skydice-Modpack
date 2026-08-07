require 'Items/SuburbsDistributions'

local function MeatGrinderLootDrop()
    local ammoTypes = {
        "LG.Legendary_Axe_LEGION", 
    }

    for _, ammoType in ipairs(ammoTypes) do
        table.insert(SuburbsDistributions["all"]["inventorymale"].items, ammoType)
        table.insert(SuburbsDistributions["all"]["inventorymale"].items, SandboxVars.MeatGrinderLootDrop)
        table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, ammoType)
        table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, SandboxVars.MeatGrinderLootDrop)
    end

    ItemPickerJava.Parse()
end

Events.OnInitGlobalModData.Add(MeatGrinderLootDrop)

