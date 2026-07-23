local CD = CompanionDogs

CD.SKILLS = { "scent", "combat", "obedience", "hunt" }
CD.SKILL_MAX_LEVEL = 10
CD.SKILL_XP_BASE = 20

CD.DEFAULT_BREED = "caramelo"
CD.BREEDS = {
    caramelo = {
        key = "caramelo",
        engineBreed = "brown",
        typePrefix = "dog",
        nameKey = "IGUI_PD_Breed_caramelo",
        -- Tamanho da ninhada (vira-lata comum = ninhada maior). Ver CD.rollLitterSize.
        litter = { 2, 4 },
        xpMult = { scent = 1, combat = 1, obedience = 1, hunt = 1 },
        combatPower = 0.2,
        -- Mesma forma de curva por nivel do GS, mas combatPower 0.2 o mantem fraco. canKill=false torna "nunca mata sozinho"
        -- uma regra RIGIDA (nao uma corrida fragil de panico-antes-de-arrancar-o-abate): seus golpes desgastam o zumbi e o
        -- derrubam, mas o prendem logo acima da morte (SUBLETHAL_HEALTH_FLOOR); o dono ou uma raca forte da o golpe final.
        lethalityCurve = { min = 0.40, max = 1.5 },
        canKill = false,
        canKnockdown = true,
        geneRange = {
            strength       = { 0.0, 0.15 },
            aggressiveness = { 0.0, 0.15 },
            resistance     = { 0.0, 0.15 },
            stress         = { 0.85, 1.0 },
        },
    },
    germanshepherd = {
        key = "germanshepherd",
        engineBreed = "germanshepherd",
        typePrefix = "gs",
        nameKey = "IGUI_PD_Breed_germanshepherd",
        litter = { 1, 2 },
        -- Cao de guerra: especialista em combate (2x), cacador modesto (1.2x).
        xpMult = { scent = 1, combat = 2.0, obedience = 1.5, hunt = 1.2 },
        combatPower = 0.6,
        -- A letalidade e conquistada pela skill de Combate: fraco em L0/L1 (~10 golpes para matar um zumbi normal),
        -- subindo ate o poder pleno da raca em nivel alto. levelMult = min + (max-min)*(level/SKILL_MAX_LEVEL).
        -- Nerf 07-06: combatPower 1.0->0.6 e teto da curva 1.5->1.3 (no L3 melava zumbi rapido demais).
        lethalityCurve = { min = 0.40, max = 1.3 },
        canKnockdown = true,
        combatStressMult = 0.20,
        -- Raca corajosa: aguenta passar do ponto de panico normal 0.80 (onde o caramelo ja quebra),
        -- mas ainda para de lutar quando esta de fato apavorado (stress >= 0.90). Nao e imunidade absoluta, entao o
        -- comportamento funcional bate com o badge de stress em vez de contradize-lo.
        panicThreshold = 0.90,
        geneRange = {
            strength       = { 0.30, 0.50 },
            aggressiveness = { 0.30, 0.50 },
            resistance     = { 0.30, 0.50 },
            stress         = { 0.20, 0.50 },
        },
    },
    retriever = {
        key = "retriever",
        engineBreed = "golden",
        typePrefix = "retriever",
        nameKey = "IGUI_PD_Breed_retriever",
        litter = { 1, 2 },
        -- Golden: especialista em caca (hunt 2x), lutador leve (combat 1.2x). Mata, mas devagar (combatPower 0.34:
        -- nerf 07-06 0.33->0.28, depois 0.28->0.34 a pedido; teto 1.5->1.3; o GS (0.6) segue o guerreiro de verdade).
        xpMult = { scent = 1.3, combat = 1.2, obedience = 1.3, hunt = 2.0 },
        combatPower = 0.34,
        lethalityCurve = { min = 0.40, max = 1.3 },
        canKill = true,
        canKnockdown = true,
        combatStressMult = 0.33,
        panicThreshold = 0.85,
        geneRange = {
            strength       = { 0.20, 0.40 },
            aggressiveness = { 0.10, 0.30 },
            resistance     = { 0.20, 0.40 },
            stress         = { 0.30, 0.60 },
        },
    },
    husky = {
        key = "husky",
        engineBreed = "husky",
        typePrefix = "husky",
        nameKey = "IGUI_PD_Breed_husky",
        litter = { 1, 2 },
        -- Cao de trenó: carga (Forca a mais alta do jogo) + sobrevivencia no frio, com um pe no combate.
        -- Teimoso de proposito (obedience 0.8 treina devagar). combatPower 0.44 fica entre o retriever (0.34) e
        -- o GS (0.6): mata, mas nao e especialista; a Forca alta da o soco extra via effectiveHitDamage.
        -- Nerf 07-06: 0.45->0.38 + teto da curva 1.5->1.3; depois 0.38->0.44 a pedido (bump leve).
        xpMult = { scent = 1.0, combat = 1.2, obedience = 0.8, hunt = 1.2 },
        combatPower = 0.44,
        lethalityCurve = { min = 0.40, max = 1.3 },
        canKill = true,
        canKnockdown = true,
        combatStressMult = 0.6,
        panicThreshold = 0.85,
        bagMult = 1.5,  -- cao de carga: +50% na capacidade do alforje (sobre a derivada da Forca), ver CD.bagCapacity
        geneRange = {
            strength       = { 0.55, 0.80 },  -- a mais forte: puxador de carga, alimenta o alforje (capacidade ~ Forca)
            aggressiveness = { 0.10, 0.30 },  -- amigavel: huskies sao maus caes de guarda
            resistance     = { 0.40, 0.60 },  -- robusto
            stress         = { 0.20, 0.45 },  -- calmo/estavel
        },
    },
}

local GENE_MIN, GENE_MAX = 0.2, 0.6

local function clamp(v, lo, hi)
    if v < lo then return lo elseif v > hi then return hi end
    return v
end

local SEX_SUFFIX = { male = true, female = true, pup = true }

-- Deriva a raca funcional a partir do TYPE nativo do animal (gs* -> germanshepherd, dog* -> caramelo). O type
-- escolhe a mesh do corpo e e um campo central da engine: sempre sincroniza em MP e sobrevive ao rebuild do copyFrom
-- que descarta nosso ModData. Por isso e a fonte confiavel da FAMILIA da raca quando d.breed esta ausente/desatualizado.
function CD.breedFromType(animal)
    if not animal or not animal.getAnimalType then return nil end
    local t = animal:getAnimalType()
    if not t then return nil end
    for key, def in pairs(CD.BREEDS) do
        local p = def.typePrefix
        if p and string.len(t) > string.len(p)
                and string.sub(t, 1, string.len(p)) == p
                and SEX_SUFFIX[string.sub(t, string.len(p) + 1)] then
            return key
        end
    end
    return nil
end

function CD.getBreed(animal)
    local stored = CD.data(animal).breed
    local byType = CD.breedFromType(animal)
    if byType then
        -- O type e a autoridade para a familia de mesh. Se o ModData estiver ausente, ou nomear uma raca de uma
        -- familia de mesh DIFERENTE (ex.: um cao gs* cujo ModData de raca nao chegou ao client / foi perdido num
        -- rebuild do copyFrom e caiu para caramelo), confie no type. Racas futuras de mesma mesh (um labrador tipo
        -- "dog" vs caramelo) compartilham um typePrefix, entao mantem o valor armazenado e nunca disparam esse mismatch.
        local sdef = stored and CD.BREEDS[stored]
        if not sdef or sdef.typePrefix ~= CD.BREEDS[byType].typePrefix then
            return byType
        end
    end
    return stored or CD.DEFAULT_BREED
end

function CD.setBreed(animal, key)
    if CD.BREEDS[key] then CD.data(animal).breed = key end
end

-- Substantivo de exibicao localizado para a raca do companheiro ("Caramelo" / "German Shepherd"), usado onde a UI
-- se refere ao cao em vez do antigo generico "dog". Apenas no client (os halos do server transmitem a KEY da raca
-- e deixam cada client localizar, entao em MP cada jogador ve no seu proprio idioma). Protegido por pcall com o
-- fallback de nome padrao (o proxy de status dentro do veiculo nao tem getAnimalType).
function CD.breedNoun(animal)
    local key = "IGUI_PD_DogDefaultName"
    pcall(function() key = CD.getBreedDef(animal).nameKey end)
    return getText(key)
end

-- Localiza uma KEY de raca ("caramelo"/"germanshepherd") enviada pela rede; mesmo fallback.
function CD.breedNounFromKey(breedKey)
    local def = breedKey and CD.BREEDS[breedKey]
    if def and def.nameKey then return getText(def.nameKey) end
    return getText("IGUI_PD_DogDefaultName")
end

function CD.getBreedDef(animal)
    return CD.BREEDS[CD.getBreed(animal)] or CD.BREEDS[CD.DEFAULT_BREED]
end

-- Mapeia uma key de raca funcional -> o nome de raca da engine passado para addAnimal (controla a textura).
function CD.breedEngineName(key)
    local def = CD.BREEDS[key]
    return (def and def.engineBreed) or CD.BREED
end

-- Mapeia key de raca funcional + sexo ("male"/"female"/"pup") -> o animal type da engine (controla a MESH do corpo).
function CD.breedAnimalType(key, sex)
    local def = CD.BREEDS[key]
    return ((def and def.typePrefix) or "dog") .. (sex or "male")
end

function CD.breedCombatPower(animal)
    local p = CD.getBreedDef(animal).combatPower
    return p ~= nil and p or 1
end

function CD.breedCanKnockdown(animal)
    return CD.knockdownEnabled() and CD.getBreedDef(animal).canKnockdown == true
end

-- Se esta raca pode desferir um golpe mortal num zumbi. Padrao true; uma raca com canKill=false
-- (caramelo) desgasta e derruba zumbis mas nunca os finaliza (ver SUBLETHAL_HEALTH_FLOOR).
function CD.breedCanKill(animal)
    return CD.getBreedDef(animal).canKill ~= false
end

-- Nivel de stress no qual esta raca para de lutar (panico funcional). Racas corajosas o elevam acima do
-- padrao; panicImmune == true (nenhuma raca usa hoje) significa "nunca entra em panico" via um threshold inalcancavel.
function CD.breedPanicThreshold(animal)
    local def = CD.getBreedDef(animal)
    if def.panicImmune == true then return math.huge end
    return def.panicThreshold or CD.STRESS_PANIC_THRESHOLD
end

function CD.initSkills(animal)
    local d = CD.data(animal)
    d.breed = d.breed or CD.breedFromType(animal) or CD.DEFAULT_BREED
    d.skills = d.skills or {}
end

function CD.rollBreedGenes(animal)
    if isClient() then return end
    local d = CD.data(animal)
    if d.genes then return end
    local range = CD.getBreedDef(animal).geneRange
    if not range then return end
    d.genes = {}
    for gene, r in pairs(range) do
        local lo, hi = r[1], r[2]
        d.genes[gene] = clamp(lo + (hi - lo) * (ZombRand(0, 1001) / 1000), 0, 1)
    end

    -- Acoplamento tamanho-do-corpo-a-partir-da-forca desativado por ora: sobrescrevia o gene maxSize e forcava
    -- setSize(getMaxSize()) ao domesticar, estourando o cao para o tamanho maximo ao alimentar. A engine agora
    -- cuida do tamanho nativamente (gene maxSize vanilla + crescimento natural).
end

-- ===== Ascendencia (lineage) & breeding ============================================================
-- Ordem estavel das racas pra desempate deterministico (argmax/roleta sao iguais em todo client).
-- Ordem estavel (alfabetica) de TODAS as racas de CD.BREEDS, pra o desempate/roleta de lineage ser deterministico
-- (igual em todo client) e incluir automaticamente racas novas (ex.: husky) sem editar uma lista fixa.
CD.BREED_ORDER = {}
for _bk in pairs(CD.BREEDS) do CD.BREED_ORDER[#CD.BREED_ORDER + 1] = _bk end
table.sort(CD.BREED_ORDER)

-- Vetor de ascendencia do cao (proporcao por raca, soma 1). Puro = { [raca] = 1.0 }. Lazy-init a partir
-- da raca atual pra caes legados (domados antes do breeding) ganharem um lineage coerente na 1a leitura.
function CD.getLineage(animal)
    local d = CD.data(animal)
    if not d.lineage then d.lineage = { [CD.getBreed(animal)] = 1.0 } end
    return d.lineage
end

-- Mestico = mais de uma raca com proporcao > 0 no lineage. Pais da MESMA raca mantem { [raca] = 1.0 } = puro.
function CD.isMestico(animal)
    local n = 0
    for _, v in pairs(CD.getLineage(animal)) do if v and v > 0 then n = n + 1 end end
    return n > 1
end

-- Breakdown localizado da ascendencia: "50% Husky, 50% German Shepherd". So client (getText via breedNounFromKey).
function CD.lineageLabel(animal)
    local lin = CD.getLineage(animal)
    local parts = {}
    for _, k in ipairs(CD.BREED_ORDER) do
        local v = lin[k]
        if v and v > 0 then
            parts[#parts + 1] = tostring(math.floor(v * 100 + 0.5)) .. "% " .. CD.breedNounFromKey(k)
        end
    end
    return table.concat(parts, ", ")
end

-- Raca dominante (maior proporcao) do vetor; usada pra moodle/etiqueta. Desempate por BREED_ORDER.
function CD.lineageDominant(lineage)
    local bestK, bestV = nil, -1
    for _, k in ipairs(CD.BREED_ORDER) do
        local v = lineage[k]
        if v and v > bestV then bestK, bestV = k, v end
    end
    return bestK or CD.DEFAULT_BREED
end

-- Sorteio PONDERADO pela ascendencia (server, ZombRand): escolhe a familia de mesh de UM filhote no parto.
-- Na 1a geracao (50/50) e um sorteio 50/50; conforme a linhagem pende, o mesh tende a acompanhar.
function CD.lineageRoll(lineage)
    local total = 0
    for _, v in pairs(lineage) do if v and v > 0 then total = total + v end end
    if total <= 0 then return CD.DEFAULT_BREED end
    local r = (ZombRand(0, 1000000) / 1000000) * total
    local acc = 0
    for _, k in ipairs(CD.BREED_ORDER) do
        local v = lineage[k]
        if v and v > 0 then
            acc = acc + v
            if r <= acc then return k end
        end
    end
    return CD.lineageDominant(lineage)
end

-- Media componente-a-componente dos vetores dos pais, renormalizada pra somar 1 (admixture real).
-- caramelo(1/0) x pastor(0/1) -> 50/50; esse 50/50 x pastor puro -> 25/75; escala por geracoes.
function CD.blendLineage(a, b)
    a = a or {}
    b = b or {}
    local out, sum = {}, 0
    local keys = {}
    for k in pairs(a) do keys[k] = true end
    for k in pairs(b) do keys[k] = true end
    for k in pairs(keys) do
        local v = ((a[k] or 0) + (b[k] or 0)) * 0.5
        if v > 0 then out[k] = v; sum = sum + v end
    end
    if sum > 0 then for k, v in pairs(out) do out[k] = v / sum end end
    return out
end

-- Faixa permitida de um gene = UNIAO (menor lo, maior hi) das geneRange de todas as racas presentes no lineage,
-- pra um mestico poder cair ENTRE fraco e forte. Sem componente valida -> [0,1].
function CD.lineageGeneRange(lineage, gene)
    local lo, hi
    for k, v in pairs(lineage) do
        if v and v > 0 then
            local def = CD.BREEDS[k]
            local r = def and def.geneRange and def.geneRange[gene]
            if r then
                if lo == nil or r[1] < lo then lo = r[1] end
                if hi == nil or r[2] > hi then hi = r[2] end
            end
        end
    end
    if lo == nil then return 0, 1 end
    return lo, hi
end

-- Blend dos 4 genes do mod a partir dos genes dos dois pais: ponto medio + jitter de mutacao, clampado a uniao
-- das faixas do lineage. Server-only; espelha a forma de escrita de rollBreedGenes. damGenes/sireGenes = tabelas d.genes.
function CD.blendGenes(damGenes, sireGenes, lineage)
    if isClient() then return nil end
    local out, keys = {}, {}
    if damGenes then for g in pairs(damGenes) do keys[g] = true end end
    if sireGenes then for g in pairs(sireGenes) do keys[g] = true end end
    local mut = CD.GENE_MUTATION or 0.06
    for g in pairs(keys) do
        local a = damGenes and damGenes[g]
        local b = sireGenes and sireGenes[g]
        if a == nil then a = b end
        if b == nil then b = a end
        local mid = (a + b) * 0.5
        local jitter = (ZombRand(0, 1001) / 1000 - 0.5) * 2 * mut
        local lo, hi = CD.lineageGeneRange(lineage, g)
        out[g] = clamp(mid + jitter, lo, hi)
    end
    return out
end

local function cumulativeXpForLevel(level)
    return CD.SKILL_XP_BASE * level * (level + 1) / 2
end

function CD.getSkillXP(animal, skill)
    local s = CD.data(animal).skills
    return (s and s[skill]) or 0
end

function CD.getSkillLevel(animal, skill)
    local xp = CD.getSkillXP(animal, skill)
    local level = 0
    while level < CD.SKILL_MAX_LEVEL and xp >= cumulativeXpForLevel(level + 1) do
        level = level + 1
    end
    return level
end

function CD.skillProgress(animal, skill)
    local level = CD.getSkillLevel(animal, skill)
    if level >= CD.SKILL_MAX_LEVEL then
        local span = CD.SKILL_XP_BASE * CD.SKILL_MAX_LEVEL
        return level, span, span
    end
    local base = cumulativeXpForLevel(level)
    local need = cumulativeXpForLevel(level + 1) - base
    local into = CD.getSkillXP(animal, skill) - base
    if into < 0 then into = 0 end
    return level, into, need
end

function CD.addSkillXP(animal, skill, amount)
    if not CD.skillsEnabled() then return end
    if not amount or amount <= 0 then return end
    if isClient() then return end
    if CD.getSkillLevel(animal, skill) >= CD.SKILL_MAX_LEVEL then return end

    local before = CD.getSkillLevel(animal, skill)
    local d = CD.data(animal)
    d.skills = d.skills or {}
    local mult = (CD.getBreedDef(animal).xpMult[skill]) or 1
    d.skills[skill] = (d.skills[skill] or 0) + amount * mult * CD.skillXPRate()
    if CD.getSkillLevel(animal, skill) ~= before then
        CD.transmit(animal)
        -- Marca cada subida de nivel no canil durável na hora (ver CD.kennelSnapshot).
        local owner = CD.getOwnerPlayer and CD.getOwnerPlayer(animal)
        if owner and CD.kennelSnapshot then CD.kennelSnapshot(owner, animal) end
    end
end

-- Merge de skills por MAXIMO: dst[s] = max(dst[s], src[s]). Base do "skills nunca regridem" do canil.
function CD.mergeSkillsMax(dst, src)
    if type(dst) ~= "table" or type(src) ~= "table" then return end
    for s, b in pairs(src) do
        if type(b) == "number" and b > (dst[s] or 0) then dst[s] = b end
    end
end

-- Debug: define uma skill direto num nivel (XP = o acumulado desse nivel). No server, sincroniza com os clients.
function CD.setSkillLevel(animal, skill, level)
    if isClient() then return end
    if not skill then return end
    level = math.max(0, math.min(tonumber(level) or 0, CD.SKILL_MAX_LEVEL))
    local d = CD.data(animal)
    d.skills = d.skills or {}
    d.skills[skill] = cumulativeXpForLevel(level)
    CD.transmit(animal)
end

function CD.geneRatio(animal, gene)
    local d = CD.data(animal)
    if d.genes and d.genes[gene] ~= nil then return clamp(d.genes[gene], 0, 1) end
    local v
    -- animal pode ser a forma de item (AnimalInventoryItem: carregado/montado) durante transicoes (sair de veiculo):
    -- tem getModData mas nao getUsedGene. Checar o metodo antes de chamar evita o "tried to call nil" que, mesmo
    -- pego pelo pcall, a engine ainda despeja no console em debug.
    pcall(function()
        if animal.getUsedGene then
            local allele = animal:getUsedGene(gene)
            if allele then v = allele:getCurrentValue() end
        end
    end)
    if v == nil then return 0.5 end
    return clamp((v - GENE_MIN) / (GENE_MAX - GENE_MIN), 0, 1)
end

local function lvl(animal, skill)
    if not CD.skillsEnabled() then return 0 end
    return CD.getSkillLevel(animal, skill)
end

local function geneDelta(animal, gene)
    if not CD.genomeEffects() then return 0 end
    return CD.geneRatio(animal, gene) - 0.5
end

function CD.effectiveHitDamage(animal)
    local curve = CD.getBreedDef(animal).lethalityCurve
    local levelMult
    if curve and CD.skillsEnabled() then
        levelMult = curve.min + (curve.max - curve.min) * (lvl(animal, "combat") / CD.SKILL_MAX_LEVEL)
    else
        levelMult = 1 + 0.05 * lvl(animal, "combat")
    end
    local base = CD.hitDamage() * CD.breedCombatPower(animal) * levelMult
    return base * (1 + 0.30 * geneDelta(animal, "strength"))
end

-- Knockdown e um efeito da SKILL de Combate (guiado por nivel, nao por raca): chance por golpe que cresce com o nivel,
-- limitada para evitar stunlock permanente (um piso rigido de cooldown em strikeExchange reforca isso).
function CD.knockdownChance(animal)
    local chance = (CD.KNOCKDOWN_CHANCE_BASE or 0.10) + (CD.KNOCKDOWN_CHANCE_PER_LEVEL or 0.04) * lvl(animal, "combat")
    return clamp(chance, 0, CD.KNOCKDOWN_CHANCE_CAP or 0.50)
end

function CD.effectiveCombatStress(animal)
    local reduction = clamp(0.03 * lvl(animal, "combat") + 0.20 * geneDelta(animal, "resistance"), 0, 0.5)
    local breedMult = CD.getBreedDef(animal).combatStressMult or 1
    return CD.combatStressPerStrike() * (1 - reduction) * CD.stressGeneMult(animal) * breedMult
end

function CD.effectiveSentinelRadius(animal)
    local mult = 1 + 0.05 * lvl(animal, "scent")
    if mult > 1.5 then mult = 1.5 end
    return math.floor(CD.sentinelRadius() * mult + 0.5)
end

-- Raio de deteccao/engajamento de caca cresce com o nivel de Hunt (limite +60%).
function CD.effectiveHuntRadius(animal)
    local mult = 1 + 0.06 * lvl(animal, "hunt")
    if mult > 1.6 then mult = 1.6 end
    return math.floor(CD.huntRadius() * mult + 0.5)
end

-- Tiles somados a visao de coleta do dono enquanto um companheiro proximo, alimentado e leal esta por perto (Fase F);
-- disponivel a partir de L0 (mesmo um faro destreinado ajuda), subindo de ~metade do bonus em L0 ate o total em L10.
function CD.effectiveForageBonus(animal)
    local l = lvl(animal, "hunt")
    return CD.huntForageRadiusBonus() * (0.5 + 0.5 * l / CD.SKILL_MAX_LEVEL)
end

function CD.effectiveLoyaltyFloor(animal)
    local floor = CD.loyaltyFloor() - 1.5 * lvl(animal, "obedience")
    if floor < 10 then floor = 10 end
    return floor
end

function CD.combatXPRate(animal)
    return 1 + 0.30 * geneDelta(animal, "aggressiveness")
end

function CD.stressGeneMult(animal)
    return 1 + 0.20 * geneDelta(animal, "stress")
end

-- ===== API de addon (racas externas) ===============================================================
-- Contrato para mods de raca (ver companion-dogs-addon-contract.md no repo). Um addon com
-- require=CompanionDogs chama CD.registerBreed no load do shared; o base nunca chama, entao
-- sem addon nada muda. Bump CD.API_VERSION a cada mudanca incompativel do contrato.
CD.API_VERSION = 1

-- Reconstroi a ordem estavel (alfabetica) apos registrar raca nova; substitui a tabela inteira
-- (todos os leitores acessam via CD.BREED_ORDER, sem capture local).
function CD.rebuildBreedOrder()
    local order = {}
    for bk in pairs(CD.BREEDS) do order[#order + 1] = bk end
    table.sort(order)
    CD.BREED_ORDER = order
end

-- Registra uma raca de addon: valida o schema, insere em CD.BREEDS, registra os 3 animal types
-- em CD.TYPES (gate do CD.isDog), rebuilda BREED_ORDER (senao a raca fica fora do breeding) e
-- registra spawns selvagens opcionais. Def invalida = nil (nao derruba o load do addon).
function CD.registerBreed(def)
    if type(def) ~= "table" or not def.key then return nil end
    if CD.BREEDS[def.key] then return CD.BREEDS[def.key] end
    for _, field in ipairs({ "typePrefix", "nameKey", "xpMult", "combatPower", "lethalityCurve", "geneRange" }) do
        if def[field] == nil then return nil end
    end
    CD.BREEDS[def.key] = def
    CD.TYPES[def.typePrefix .. "pup"] = true
    CD.TYPES[def.typePrefix .. "female"] = true
    CD.TYPES[def.typePrefix .. "male"] = true
    CD.rebuildBreedOrder()
    if def.spawns and CD.registerStraySpawns then CD.registerStraySpawns(def.spawns) end
    return def
end
