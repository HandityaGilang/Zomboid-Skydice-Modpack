-- PK42SharedUtils.lua
-- Tabela de estados do gancho e helpers compartilhados entre cliente e servidor.

local PK42SharedUtils = {}

-- ==============================================================
-- DEBUG
-- ==============================================================
function PK42SharedUtils.Dbg(msg)
    local side
    if isServer() then
        side = "[server]"
    elseif isClient() then
        side = "[client]"
    else
        side = "[sp]"
    end
    print("[PK42] " .. side .. " " .. msg)
end

-- ==============================================================
-- HOOK SPRITES
-- ==============================================================
PK42SharedUtils.HookTable = {
    ["crafted_04_120"]  = { Status = "Empty"    },
    psychopath_tiles_3  = { Status = "Corpse"   },
    psychopath_tiles_2  = { Status = "Skinned"  },
    psychopath_tiles_1  = { Status = "Skeleton" },
    psychopath_tiles_6  = { Status = "CorpseBleeded"},
    psychopath_tiles_7  = { Status = "SkinnedBleeded"  },
}

PK42SharedUtils.HookSprite = {
    Empty    = "crafted_04_120",
    Corpse   = "psychopath_tiles_3",
    Skinned  = "psychopath_tiles_2",
    Skeleton = "psychopath_tiles_1",
    CorpseBleeded = "psychopath_tiles_6",
    SkinnedBleeded = "psychopath_tiles_7",
}

-- ==============================================================
-- HOOK HELPERS
-- ==============================================================
function PK42SharedUtils.hook_GetStatus(hook)
    if not hook or not hook:getSprite() then return "Empty" end
    local entry = PK42SharedUtils.HookTable[hook:getSprite():getName()]
    return entry and entry.Status or "Empty"
end

function PK42SharedUtils.hook_SwapSprite(hook, targetStatus)
    if not hook or not targetStatus then return end
    local newSprite = PK42SharedUtils.HookSprite[targetStatus]
    if not newSprite then return end
    if hook:getSprite():getName() ~= newSprite then
        hook:setSpriteFromName(newSprite)
    end
    hook:transmitUpdatedSpriteToClients()
    local sq = hook:getSquare()
    if sq then sq:RecalcAllWithNeighbours(true) end
end

-- ==============================================================
-- CORPSE TYPE HELPERS: Poderia usar uma única função para detectar e retornar o tipo correto. Mas fiquei com preguiça de mexer em tudo.
-- ==============================================================
-- Texturas de skin que identificam um corpo humano.
local isHumanTex = {
    ["MaleBody01"]              = true,
    ["MaleBody01a"]             = true,
    ["MaleBody02"]              = true,
    ["MaleBody02a"]             = true,
    ["MaleBody03"]              = true,
    ["MaleBody03a"]             = true,
    ["MaleBody04"]              = true,
    ["MaleBody04a"]             = true,
    ["MaleBody05"]              = true,
    ["MaleBody05a"]             = true,
    ["FemaleBody01"]            = true,
    ["FemaleBody02"]            = true,
    ["FemaleBody03"]            = true,
    ["FemaleBody04"]            = true,
    ["FemaleBody05"]            = true,
    ["M_HumanBody04_Skinned"]   = true,
    ["M_HumanBody04_Skinned_Bleeded"] = true,
}

-- Retorna true se a skin texture do corpse esta na lista de humanos.
-- Cobre players reais, NPCs do Bandits (vivos ou ja esfolados).
local function isHumanSkinTexture(obj)
    local ok, hv = pcall(function() return obj:getHumanVisual() end)
    if not ok or not hv then return false end
    local ok2, tex = pcall(function() return hv:getSkinTexture() end)
    if not ok2 or not tex then return false end
    return isHumanTex[tex] == true
end

--- Retorna true se o IsoZombie e um NPC humano do Bandits mod.
function PK42SharedUtils.IsBanditNPC(zombie)
    if not zombie then return false end
    return isHumanSkinTexture(zombie)
end

function PK42SharedUtils.isHumanCorpse(corpse)
    if not corpse then return false end
    local ok1, isAnimal   = pcall(function() return corpse:isAnimal()   end)
    local ok2, isZombie   = pcall(function() return corpse:isZombie()   end)
    local ok3, isSkeleton = pcall(function() return corpse:isSkeleton() end)
    if ok1 and isAnimal   then return false end
    if ok3 and isSkeleton then return false end
    return true
end

--- Retorna true se o corpo é um skeleton humano (não animal).
function PK42SharedUtils.isHumanSkeleton(corpse)
    if not corpse then return false end
    local ok1, isAnimal   = pcall(function() return corpse:isAnimal()   end)
    local ok2, isSkeleton = pcall(function() return corpse:isSkeleton() end)
    if ok1 and isAnimal then return false end
    return ok2 and isSkeleton or false
end

--- Retorna true se o corpo é de player ou NPC humano (Bandits, etc.).
function PK42SharedUtils.isPlayerCorpse(corpse)
    if not corpse then return false end
    if isHumanSkinTexture(corpse) then return true end
    local okZ, isZombie = pcall(function() return corpse:isZombie() end)
    local okA, isAnimal = pcall(function() return corpse:isAnimal() end)
    return not (okZ and isZombie) and not (okA and isAnimal)
end

--- Resolve o ID de um IsoDeadBody para envio via sendClientCommand.
function PK42SharedUtils.corpse_GetID(corpse)
    if not corpse then return nil end
    if corpse.getOnlineID then
        local ok, id = pcall(function() return corpse:getOnlineID() end)
        if ok and id then return id end
    end
    if corpse.getID then return corpse:getID() end
    return nil
end

-- ==============================================================
-- ITEM HELPERS
-- ==============================================================

--- Predicate auxiliar
local function isPredicateNotBroken(item)
    return not item:isBroken()
end

--- Retorna a primeira ferramenta de abate não-quebrada no inventário, ou nil.
function PK42SharedUtils.findButcherTool(inv)
    if not inv then return nil end
    return inv:getFirstTagEvalRecurse(ItemTag.BUTCHER_ANIMAL, isPredicateNotBroken)
end

--- Retorna true se a arma é mão nua (nil, BareHands ou Base.BareHands).
function PK42SharedUtils.IsBareHands(weapon)
    if not weapon then return true end
    local t = weapon:getType()
    return t == "BareHands" or t == "Base.BareHands"
end

-- Retorna true apenas se o item for uma HandWeapon.
function PK42SharedUtils.IsHandWeapon(item)
    if not item then return false end
    return instanceof(item, "HandWeapon")
end

-- ==============================================================
-- TRAIT HELPERS
-- ==============================================================
function PK42SharedUtils.hasPsychopathTrait(player)
    return PK42.CharacterTrait.PSYCHOPATH ~= nil
        and player:hasTrait(PK42.CharacterTrait.PSYCHOPATH)
end

--- Retorna true se o player tem o trait Cannibalist.
function PK42SharedUtils.hasCannibalistTrait(player)
    return PK42.CharacterTrait.CANNIBALIST ~= nil
        and player:hasTrait(PK42.CharacterTrait.CANNIBALIST)
end

-- ==============================================================
-- MODDATA KEYS
-- ==============================================================
PK42SharedUtils.MD = {
    -- Consumo de carne
    TOTAL_MEAT           = "totalMeatConsumed",

    -- Cap diário: EatMeat (Insanity por comer)
    XP_EAT_TODAY         = "xpEatToday",
    LAST_EAT_RESET       = "lastEatReset",

    -- Cap diário: Butchering (Insanity por esquartejar/esfolar)
    -- Compartilhado entre ServerLogic e HumanPartsDefinitions
    XP_BUTCHER_TODAY     = "xpButcherToday",
    LAST_BUTCHER_RESET   = "lastButcherReset",

    -- Cap diário: Kills normais (Insanity por matar zumbi/player fora do frenzy)
    XP_KILL_TODAY        = "xpKillToday",
    LAST_KILL_RESET      = "lastKillReset",

    -- Cap diário: Kills em frenzy (contador separado do kill normal)
    XP_FRENZY_TODAY      = "xpFrenzyToday",
    LAST_FRENZY_RESET    = "lastFrenzyReset",

    -- Streaks e kills
    LAST_KILL            = "lastKillTime",
    STREAK               = "killStreak",

    -- Frenzy
    FRENZY_ACTIVE        = "frenzyActive",
    FRENZY_REAL_FATIGUE  = "frenzyRealFatigue",
    FRENZY_REAL_ENDUR    = "frenzyRealEndurance",
    FRENZY_REAL_PAIN     = "frenzyRealPain",
    FRENZY_FIXED_FATIGUE = "frenzyFixedFatigue",
    FRENZY_FIXED_ENDUR   = "frenzyFixedEndur",
    FRENZY_START_HOUR    = "frenzyStartHour",
    FRENZY_END_HOUR      = "frenzyEndHour",
    FRENZY_RESTORE_DONE  = "frenzyRestoreDone",
    COOLDOWN_START       = "cooldownStart",

    -- Álcool
    LAST_DRANK_HOUR      = "PK42LastDrankHour",

    -- Infecção / food poisoning pendentes (EatMeat)
    PENDING_INFECTION    = "pendingInfection",
    PENDING_POISON       = "pendingPoison",
    INF_WINDOW           = "infWindow",
    POISON_WINDOW        = "poisonWindow",

    -- Neutralizador de infecção ativo
    NEUTRALIZER_FLAG     = "PK42_NeutralizerActive",
}

-- ==============================================================
-- MODDATA HELPERS
-- ==============================================================
function PK42SharedUtils.GetLastKill(player)
    local md = player and player:getModData()
    return md and md[PK42SharedUtils.MD.LAST_KILL] or nil
end

function PK42SharedUtils.SetLastKill(player, h)
    local md = player and player:getModData()
    if md then md[PK42SharedUtils.MD.LAST_KILL] = h end
end

function PK42SharedUtils.GetStreak(player)
    local md = player and player:getModData()
    return (md and md[PK42SharedUtils.MD.STREAK]) or 0
end

function PK42SharedUtils.SetStreak(player, v)
    local md = player and player:getModData()
    if md then md[PK42SharedUtils.MD.STREAK] = v end
end

function PK42SharedUtils.IsFrenzyActive(player)
    local md = player and player:getModData()
    return md ~= nil and md[PK42SharedUtils.MD.FRENZY_ACTIVE] == true
end

-- ==============================================================
-- XP CAP HELPERS
-- ==============================================================

function PK42SharedUtils.worldHour()
    return getGameTime():getWorldAgeHours()
end

--- Reseta o contador diário de XP se o dia de jogo mudou.
-- @param player       IsoPlayer
-- @param keyToday     chave MD do acumulador (ex: SU.MD.XP_EAT_TODAY)
-- @param keyLastReset chave MD do timestamp do último reset
local function ensureDailyReset(player, keyToday, keyLastReset)
    local md      = player:getModData()
    local last    = md[keyLastReset] or 0
    local nowDay  = math.floor(PK42SharedUtils.worldHour() / 24)
    local lastDay = math.floor(last / 24)
    if nowDay > lastDay then
        md[keyToday]     = 0
        md[keyLastReset] = PK42SharedUtils.worldHour()
        player:transmitModData()
    end
end

-- Concede XP de Insanity respeitando o cap diário de um bucket específico.
-- O valor gravado no contador é amount/4 para compensar a divisão interna do engine
-- Assim o cap de 200 equivale a exatamente 200 XP reais.
-- O ideal é setar Insanity como bonus na criação do personagem, aí a xp é dada 1:1. Essa correção está prevista para o futuro (B42.20)
-- @param player       IsoPlayer
-- @param amount       XP bruto a conceder (mesmo valor passado a addXp)
-- @param keyToday     chave MD do acumulador diário
-- @param keyLastReset chave MD do timestamp do último reset
-- @param dailyCap     cap diário em XP real
-- @param capEnabled   bool: se false, concede sem verificar o cap
function PK42SharedUtils.gainInsanityXP(player, amount, keyToday, keyLastReset, dailyCap, capEnabled)
    if not amount or amount <= 0 then return end
    if not capEnabled then
        addXp(player, Perks.Insanity, amount)
        return
    end
    ensureDailyReset(player, keyToday, keyLastReset)
    local md     = player:getModData()
    local stored = md[keyToday] or 0
    local space  = dailyCap - stored          -- espaço disponível em XP real
    if space <= 0 then return end
    local realAmt  = amount / 4               -- XP real que addXp vai entregar
    local realGive = math.min(realAmt, space) -- limita ao espaço disponível
    local rawGive  = realGive * 4             -- converte de volta para valor bruto de addXp
    md[keyToday]   = stored + realGive
    player:transmitModData()
    addXp(player, Perks.Insanity, rawGive)
end

-- ==============================================================

return PK42SharedUtils


--[[
function PK42SharedUtils.gainInsanityXP(player, amount, keyToday, keyLastReset, dailyCap, capEnabled)
    if not amount or amount <= 0 then return end
    if not capEnabled then
        addXp(player, Perks.Insanity, amount)
        return
    end
    ensureDailyReset(player, keyToday, keyLastReset)
    local md     = player:getModData()
    local stored = md[keyToday] or 0
    local space  = dailyCap - stored     -- espaço disponível em XP real
    if space <= 0 then return end
    local give   = math.min(amount, space)
    md[keyToday] = stored + give
    player:transmitModData()
    addXp(player, Perks.Insanity, give)
end

-- ==============================================================

return PK42SharedUtils

-- ==============================================================
SANDBOX OPTIONS
-- ==============================================================
option PK42.XPOnKillZombie
{
    type = double,
    min = 0,
    max = 100,
    default = 0.25,
    page = PK42,
    translation = PK42_XPOnKillZombie,
    tooltip = PK42_XPOnKillZombie_tooltip,
}

option PK42.XPOnKillZombieOnFrenzy
{
    type = double,
    min = 0,
    max = 200,
    default = 0.5,
    page = PK42,
    translation = PK42_XPOnKillZombieOnFrenzy,
    tooltip = PK42_XPOnKillZombieOnFrenzy_tooltip,
}

option PK42.XPOnKillPlayer
{
    type = double,
    min = 0,
    max = 1000,
    default = 60,
    page = PK42,
    translation = PK42_XPOnKillPlayer,
    tooltip = PK42_XPOnKillPlayer_tooltip,
}

option PK42.BanditsXP
{
    type = double,
    min = 0,
    max = 1000,
    default = 12.5,
    page = PK42,
    translation = PK42_BanditsXP,
    tooltip = PK42_BanditsXP_tooltip,
}

option PK42.XPOnEatRawZombieMeat
{
    type = double,
    min = 0,
    max = 100,
    default = 30,
    page = PK42,
    translation = PK42_XPOnEatRawZombieMeat,
    tooltip = PK42_XPOnEatRawZombieMeat_tooltip,
}

option PK42.XPOnEatCookedZombieMeat
{
    type = double,
    min = 0,
    max = 100,
    default = 10,
    page = PK42,
    translation = PK42_XPOnEatCookedZombieMeat,
    tooltip = PK42_XPOnEatCookedZombieMeat_tooltip,
}

option PK42.XPOnEatRecipeZombieMeat
{
    type = double,
    min = 0,
    max = 100,
    default = 5,
    page = PK42,
    translation = PK42_XPOnEatRecipeZombieMeat,
    tooltip = PK42_XPOnEatRecipeZombieMeat_tooltip,
}

option PK42.ButcheringXP
{
    type = double,
    min = 0,
    max = 100,
    default = 2.5,
    page = PK42,
    translation = PK42_ButcheringXP,
    tooltip = PK42_ButcheringXP_tooltip,
}

option PK42.InsanityXP
{
    type = double,
    min = 0,
    max = 100,
    default = 2.5,
    page = PK42,
    translation = PK42_InsanityXP,
    tooltip = PK42_InsanityXP_tooltip,
}
]]