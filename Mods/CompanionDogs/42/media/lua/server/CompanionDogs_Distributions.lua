-- Faz a Tigela do Companion Dogs aparecer como loot. Adicionamos ela nas listas de distribuicao procedural vanilla (as
-- roll tables por container) no OnPreDistributionMerge (o mesmo hook que o SuburbsDistributions usa) pra nossas entradas entrarem antes
-- das loot tables serem mescladas. Os pesos sao modestos (nao em todo lugar); ajuste a vontade. Os nomes das listas sao keys vanilla verificadas.
require "Items/ProceduralDistributions"

local BOWL = "CompanionDogsBowl"
local SADDLEBAG = "CompanionDogsSaddlebag"

-- listName -> peso (relativo aos outros itens ja presentes naquela lista)
local BOWL_TARGETS = {
    -- pet shops / suprimentos pet
    PetShopShelf = 18,
    CratePetSupplies = 14,
    -- supermercados / mercearia
    GigamartHousewares = 8,
    GroceryStorageCrate1 = 4,
    GroceryStorageCrate2 = 4,
    GroceryStorageCrate3 = 4,
    -- lojas de jardim / fazenda + crates de fazenda/jardim (galpoes, barracoes)
    GardenStoreMisc = 8,
    CrateFarming = 6,
    CrateGardening = 6,
    -- casas
    KitchenRandom = 2,
}

-- A saddlebag e mais rara que a tigela e passa como equipamento de couro outdoor/survival, entao se apoia
-- em listas de pet, camping, caca e survival em vez de cozinhas.
local SADDLEBAG_TARGETS = {
    PetShopShelf = 8,
    CratePetSupplies = 8,
    CampingStoreBackpacks = 8,
    CampingStoreGear = 6,
    CrateCamping = 6,
    HuntingLockers = 6,
    SurvivalGear = 6,
    GarageTools = 3,
    CrateFarming = 3,
}

local injected = false

local function injectInto(list, item, targets)
    for name, weight in pairs(targets) do
        local t = list[name]
        if t and t.items then
            table.insert(t.items, item)
            table.insert(t.items, weight)
        end
    end
end

local function injectLoot()
    if injected then return end
    injected = true
    local list = ProceduralDistributions and ProceduralDistributions.list
    if not list then return end
    injectInto(list, BOWL, BOWL_TARGETS)
    injectInto(list, SADDLEBAG, SADDLEBAG_TARGETS)
end

Events.OnPreDistributionMerge.Add(injectLoot)
