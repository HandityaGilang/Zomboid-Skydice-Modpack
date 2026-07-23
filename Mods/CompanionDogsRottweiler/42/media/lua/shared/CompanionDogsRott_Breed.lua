-- Registro da raça Rottweiler no Companion Dogs (contrato de addon, ver companion-dogs-addon-contract.md
-- no repo do base). Balanço = espelho do German Shepherd; a identidade da raça vem do moodle Linha de
-- Frente (client/CompanionDogsRott_Moodle.lua) e do spawn de cão de guarda industrial.
local CD = CompanionDogs
-- Sem o base (CompanionDogs 0.6.3+) o addon fica inerte.
if not (CD and CD.registerBreed and (CD.API_VERSION or 0) >= 1) then return end

-- Tuning do addon (constantes proprias, prefixo ROTT_ pra nao colidir com o base)
CD.ROTT_INDUSTRIAL_CHANCE = 10     -- % por predio industrial, escala com DogSpawnMultiplier
CD.ROTT_HOUSE_RARITY = 4           -- rolagem por casa = chance do caramelo / isto (aditivo, como o golden)
CD.ROTT_FRONTLINE_REFUND_FRAC = 0.35 -- fracao do custo de endurance de cada golpe melee devolvida com o moodle ativo

-- Predio industrial: deposito/galpao/fabrica/ferro-velho, o quintal classico do cao de guarda. Mesma tecnica
-- do police-like do base (fareja nomes de comodo; sem API nativa). Exclui residenciais (um closet "storage"
-- de casa nao vira patio industrial). skipUrbanGate: zona industrial fica fora de TownZone com frequencia.
local INDUSTRIAL_ROOM_KEYS = { "warehouse", "storage", "factory", "industrial", "workshop", "junkyard", "scrapyard", "loadingbay", "shipping" }
CD.registerBuildingClass("industrial", function(def)
    if not def or not def.getRooms then return false end
    if def:isResidential() then return false end
    local rooms
    local ok = pcall(function() rooms = def:getRooms() end)
    if not ok or not rooms then return false end
    for i = 0, rooms:size() - 1 do
        local rd = rooms:get(i)
        local nm = rd and rd:getName()
        if nm then
            nm = string.lower(nm)
            for _, k in ipairs(INDUSTRIAL_ROOM_KEYS) do
                if string.find(nm, k, 1, true) then return true end
            end
        end
    end
    return false
end, { skipUrbanGate = true })

CD.registerBreed({
    key = "rottweiler",
    engineBreed = "rottweiler",
    typePrefix = "rott",
    nameKey = "IGUI_PD_Breed_rottweiler",
    litter = { 1, 2 },
    -- Espelho do GS: guerreiro pleno (combate 2x, obediencia 1.5x, caca 1.2x).
    xpMult = { scent = 1, combat = 2.0, obedience = 1.5, hunt = 1.2 },
    combatPower = 0.6,
    lethalityCurve = { min = 0.40, max = 1.3 },
    canKnockdown = true,
    combatStressMult = 0.20,
    panicThreshold = 0.90,
    geneRange = {
        strength       = { 0.30, 0.50 },
        aggressiveness = { 0.30, 0.50 },
        resistance     = { 0.30, 0.50 },
        stress         = { 0.20, 0.50 },
    },
    -- Sufixos |rw / |r sao chave do store persistido de spawn: NUNCA renomear num save vivo.
    spawns = {
        { id = "rottind", class = "industrial", suffix = "|rw", breed = "rottweiler",
          chance = function() return CD.ROTT_INDUSTRIAL_CHANCE * CD.dogSpawnMultiplier() end },
        { id = "rotthouse", class = "house", suffix = "|r", breed = "rottweiler",
          chance = function() return CD.strayChancePerHouse() / CD.ROTT_HOUSE_RARITY end },
    },
})
