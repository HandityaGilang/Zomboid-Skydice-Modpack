-- Registro da raca Doberman no Companion Dogs (contrato de addon, ver companion-dogs-addon-contract.md
-- no repo do base). Identidade: cao de TIRO. Treina combate na mesma velocidade do GS/Rott (2.0) e tem a
-- curva de letalidade mais INGREME do mod (fraco sem treino, o mais letal no L10),
-- pagando com resistencia baixa: aguenta menos pancada que o Rottweiler. O diferencial de jogo vem do
-- moodle Mira Firme (client/CompanionDogsDob_Moodle.lua).
local CD = CompanionDogs
-- Sem o base (CompanionDogs 0.6.3+) o addon fica inerte.
if not (CD and CD.registerBreed and (CD.API_VERSION or 0) >= 1) then return end

-- Tuning do addon (constantes proprias, prefixo DOB_ pra nao colidir com o base)
CD.DOB_POLICE_CHANCE = 18       -- % por delegacia, escala com DogSpawnMultiplier
CD.DOB_MILITARY_CHANCE = 22     -- % por predio militar (mais raro de achar, entao chance maior por predio)
-- Moodle Mira Firme:
-- STRESS e escala 0-1 (o PANIC do GS e 0-100), entao a constante do GS NAO transfere: ~100x menor.
CD.DOB_STRESS_RELIEF_PER_MIN = 0.010  -- alivio de CharacterStat.STRESS por minuto (0-1)
CD.DOB_RECOIL_FRAC = 0.45             -- fracao do recoilDelay removida enquanto mira (0 = sem efeito)
CD.DOB_RELOAD_MULT = 1.15             -- multiplicador do ReloadSpeed (1.15 = 15% mais rapido)

-- Predio militar: paiol/quartel/checkpoint. Mesma tecnica do police-like do base e do industrial do
-- Rottweiler (fareja nomes de comodo; nao ha API nativa). ADITIVA (sem exclusive): classe de addon nao
-- pode roubar predio das classes base. skipUrbanGate: base militar/checkpoint fica fora de TownZone.
local MILITARY_ROOM_KEYS = { "armory", "armoury", "barracks", "military", "checkpoint", "guardpost", "bunker" }
CD.registerBuildingClass("military", function(def)
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
            for _, k in ipairs(MILITARY_ROOM_KEYS) do
                if string.find(nm, k, 1, true) then return true end
            end
        end
    end
    return false
end, { skipUrbanGate = true })

CD.registerBreed({
    key = "doberman",
    engineBreed = "doberman",
    typePrefix = "dob",
    nameKey = "IGUI_PD_Breed_doberman",
    litter = { 1, 2 },
    -- Cao de ATAQUE treinavel: combate 2.0, obediencia 1.5, caca 1.2 (escada padrao do mod, 07-23).
    -- Divide o combat 2.0 com GS e Rottweiler, mas se separa dos dois na LETALIDADE, nao na velocidade de
    -- treino: combatPower 0.52 (abaixo dos 0.6 deles) com a curva mais ingreme do ecossistema.
    xpMult = { scent = 1, combat = 2.0, obedience = 1.5, hunt = 1.2, herding = 1.0 },
    combatPower = 0.52,
    -- Curva mais ingreme do ecossistema (todas as outras sao 0.40..1.3): fraco cru, o mais letal treinado.
    lethalityCurve = { min = 0.30, max = 1.5 },
    canKnockdown = true,
    combatStressMult = 0.25,
    panicThreshold = 0.90,
    geneRange = {
        strength       = { 0.25, 0.45 },  -- mais leve que o Rott (0.30-0.50)
        aggressiveness = { 0.35, 0.55 },  -- o mais alto do ecossistema
        resistance     = { 0.20, 0.40 },  -- o preco do combate alto: encaixa menos pancada
        stress         = { 0.20, 0.45 },
    },
    -- Sufixos |db / |dm sao chave do store persistido de spawn: NUNCA renomear num save vivo.
    spawns = {
        { id = "dobpolice", class = "police", suffix = "|db", breed = "doberman",
          chance = function() return CD.DOB_POLICE_CHANCE * CD.dogSpawnMultiplier() end },
        { id = "dobmil", class = "military", suffix = "|dm", breed = "doberman",
          chance = function() return CD.DOB_MILITARY_CHANCE * CD.dogSpawnMultiplier() end },
    },
})
