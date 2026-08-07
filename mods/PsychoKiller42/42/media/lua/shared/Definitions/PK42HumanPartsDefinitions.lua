-- PK42HumanPartsDefinitions.lua (Shared)
-- Define as partes obtidas ao esquartejar um humano/zumbi.
-- Se o mod ZVirusVaccine42BETA estiver ativo, usa os itens dele.
-- Caso contrário usa os itens próprios do PK42.

AnimalPartsDefinitions          = AnimalPartsDefinitions          or {}
AnimalPartsDefinitions.animals  = AnimalPartsDefinitions.animals  or {}
AnimalPartsDefinitions.meat     = AnimalPartsDefinitions.meat     or {}

local SU = require "Utils/PK42SharedUtils"

-- Detecção de mod
local ZVV_ACTIVE = getActivatedMods():contains("ZVirusVaccine42BETA")

-- Listas de ossos
local BONES_PK42_HUMAN = {
    "PK42.HumanSkullWithBrain",     -- [1] crânio
    "PK42.HumanTeeth",              -- [2] dentes
    "PK42.HumanBoneLarge",          -- [3] grande
    "PK42.RegularHumanBone",        -- [4] médio
    "PK42.SmallRandomHumanBones",   -- [5] pequeno
}

local BONES_PK42_ZOMBIE = {
    "PK42.InfectedSkullWithBrain",  -- [1] crânio (infectado)
    "PK42.HumanTeeth",              -- [2] dentes
    "PK42.HumanBoneLarge",          -- [3] grande
    "PK42.RegularHumanBone",        -- [4] médio
    "PK42.SmallRandomHumanBones",   -- [5] pequeno
}

local BONES_ZVV_HUMAN = {
    "PK42.HumanSkullWithBrain",          -- [1] crânio
    "LabItems.LabHumanTeeth",            -- [2] dentes
    "LabItems.LabHumanBoneLargeWP",      -- [3] grande
    "LabItems.LabRegularHumanBoneWP",    -- [4] médio
    "LabItems.LabSmallRandomHumanBones", -- [5] pequeno
}

local BONES_ZVV_ZOMBIE = {
    "PK42.InfectedSkullWithBrain",       -- [1] crânio
    "LabItems.LabHumanTeeth",            -- [2] dentes
    "LabItems.LabHumanBoneLargeWP",      -- [3] grande
    "LabItems.LabRegularHumanBoneWP",    -- [4] médio
    "LabItems.LabSmallRandomHumanBones", -- [5] pequeno
}

local function getSandboxCFG()
    local opts       = SandboxVars.PK42
    local butcherXp  = opts and opts.ButcheringXP or 10
    local insanityXp = opts and opts.InsanityXP   or 10
    return {
        -- xpPerItem
        XP_PER_ITEM_ZOMBIE  = butcherXp,       -- zumbi
        XP_PER_ITEM_HUMAN   = butcherXp * 2,   -- humano = dobro

        -- XP de Insanity por pedaço de carne obtido no giveMeatModified
        INSANITY_XP_PER_MEAT = insanityXp,

        -- Cap diário de XP (contador independente dos de EatMeat e kills)
        ENABLE_XP_DAILY_CAP = opts and opts.EnableXPDailyCap ~= false,
        DAILY_XP_CAP        = opts and opts.XPDailyCap or 200,
    }
end

-- Exporta para uso no ServerLogic
PK42.HumanBones  = ZVV_ACTIVE and BONES_ZVV_HUMAN  or BONES_PK42_HUMAN
PK42.ZombieBones = ZVV_ACTIVE and BONES_ZVV_ZOMBIE or BONES_PK42_ZOMBIE

-- Definição: Zumbi 
local PKzombie = AnimalPartsDefinitions.animals["PKzombie"] or {}
PKzombie.parts = PKzombie.parts or {}
table.insert(PKzombie.parts, { item = "PK42.TaintedMeat", minNb = 2, maxNb = 6 })
PKzombie.bones      = {}   -- ossos tratados manualmente no ServerLogic via PK42.ZombieBones
local _cfg          = getSandboxCFG()
PKzombie.xpPerItem  = _cfg.XP_PER_ITEM_ZOMBIE
PKzombie.noSkeleton = false
AnimalPartsDefinitions.animals["PKzombie"] = PKzombie

-- Definição: Humano
local PKhuman = AnimalPartsDefinitions.animals["PKhuman"] or {}
PKhuman.parts = PKhuman.parts or {}
table.insert(PKhuman.parts, { item = "PK42.HumanMeat", minNb = 3, maxNb = 8 })
PKhuman.bones      = {}   -- ossos tratados manualmente no ServerLogic via PK42.HumanBones
PKhuman.xpPerItem   = _cfg.XP_PER_ITEM_HUMAN
PKhuman.noSkeleton = false
AnimalPartsDefinitions.animals["PKhuman"] = PKhuman

-- Variantes de qualidade: Carne contaminada (zumbi)
AnimalPartsDefinitions.meat["PK42.TaintedMeat"] = AnimalPartsDefinitions.meat["PK42.TaintedMeat"] or {}
AnimalPartsDefinitions.meat["PK42.TaintedMeat"].variants = AnimalPartsDefinitions.meat["PK42.TaintedMeat"].variants or {}
table.insert(AnimalPartsDefinitions.meat["PK42.TaintedMeat"].variants, { item = "PK42.TaintedMeat", baseChance = 15, hungerBoost = 3, baseName = Translator.getItemNameFromFullType("PK42.TaintedMeat"), extraName = "IGUI_AnimalMeat_PrimeCut" })
table.insert(AnimalPartsDefinitions.meat["PK42.TaintedMeat"].variants, { item = "PK42.TaintedMeat", baseChance = 45, hungerBoost = 2, baseName = Translator.getItemNameFromFullType("PK42.TaintedMeat"), extraName = "IGUI_AnimalMeat_MediumCut" })
table.insert(AnimalPartsDefinitions.meat["PK42.TaintedMeat"].variants, { item = "PK42.TaintedMeat", hungerBoost = 1, baseName = Translator.getItemNameFromFullType("PK42.TaintedMeat"), extraName = "IGUI_AnimalMeat_PoorCut" })

-- Variantes de qualidade: Carne humana (player)
AnimalPartsDefinitions.meat["PK42.HumanMeat"] = AnimalPartsDefinitions.meat["PK42.HumanMeat"] or {}
AnimalPartsDefinitions.meat["PK42.HumanMeat"].variants = AnimalPartsDefinitions.meat["PK42.HumanMeat"].variants or {}
table.insert(AnimalPartsDefinitions.meat["PK42.HumanMeat"].variants, { item = "PK42.HumanMeat", baseChance = 15, hungerBoost = 3, baseName = Translator.getItemNameFromFullType("PK42.HumanMeat"), extraName = "IGUI_AnimalMeat_PrimeCut" })
table.insert(AnimalPartsDefinitions.meat["PK42.HumanMeat"].variants, { item = "PK42.HumanMeat", baseChance = 45, hungerBoost = 2, baseName = Translator.getItemNameFromFullType("PK42.HumanMeat"), extraName = "IGUI_AnimalMeat_MediumCut" })
table.insert(AnimalPartsDefinitions.meat["PK42.HumanMeat"].variants, { item = "PK42.HumanMeat", hungerBoost = 1, baseName = Translator.getItemNameFromFullType("PK42.HumanMeat"), extraName = "IGUI_AnimalMeat_PoorCut" })

-- Hook
zdk.hook({
    ButcheringUtil = {
        getCarcassName = function(orig, carcass)
            if type(carcass) == "table" and carcass.getCarcassName then
                return carcass:getCarcassName()
            end
            if instanceof(carcass, "IsoDeadBody") then
                local md = carcass:getModData()
                if md and md["PK42DefKey"] then
                    return md["PK42DefKey"]
                end
            end
            return orig(carcass)
        end,

        giveMeatModified = function(orig, meatDef, nb, player, meatRatio, carcass, fromGround, rotten, deathAge)
            local firstVariant = meatDef.variants and meatDef.variants[1]
            if not firstVariant or not firstVariant.item
            or (firstVariant.item ~= "PK42.TaintedMeat" and firstVariant.item ~= "PK42.HumanMeat") then
                return orig(meatDef, nb, player, meatRatio, carcass, fromGround, rotten, deathAge)
            end

            local inv        = player:getInventory()
            local items      = inv:getItems()
            local sizeBefore = items:size()

            local result = orig(meatDef, nb, player, meatRatio, carcass, fromGround, rotten, deathAge)

            local itemsAdded = items:size() - sizeBefore
            if itemsAdded > 0 then
                local cfg        = getSandboxCFG()
                local insanityXp = itemsAdded * cfg.INSANITY_XP_PER_MEAT
                --print("[PK42][giveMeatModified] gainInsanityXP Insanity=" .. insanityXp)
                SU.gainInsanityXP(
                    player, insanityXp,
                    SU.MD.XP_BUTCHER_TODAY, SU.MD.LAST_BUTCHER_RESET,
                    cfg.DAILY_XP_CAP, cfg.ENABLE_XP_DAILY_CAP
                )
            end

            for i = sizeBefore, items:size() - 1 do
                local item = items:get(i)
                if item and item:isCustomName() then
                    item:syncItemFields()
                end
            end

            return result
        end,
    }
})