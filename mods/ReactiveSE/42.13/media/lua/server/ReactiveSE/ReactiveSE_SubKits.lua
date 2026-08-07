--//////////////////////////////////////////////////--
--    Reactive Sound Events - SubKits
--    Defines SubKit pools for each category
--//////////////////////////////////////////////////--

local Utils = require "ReactiveSE/ReactiveSE_Utils"
local Config = require "ReactiveSE/ReactiveSE_Config"
local WorldTier = require "ReactiveSE/ReactiveSE_WorldTier"

local ReactiveSE_SubKits = {}

local SUB_KIT_POOLS = {
    Food = {
        EARLY = { "Base.Crisps", "Base.Crisps2", "Base.Crisps3", "Base.Crisps4", "Base.Cereal", "Base.Apple", "Base.Chocolate", "Base.JellyBeans", "Base.Lard", "Base.Margarine" },
        MID = { "Base.Crisps", "Base.Crisps2", "Base.Crisps3", "Base.Crisps4", "Base.Cereal", "Base.Apple", "Base.Chocolate", "Base.JellyBeans", "Base.Lard", "Base.Margarine", "Base.CannedSardines", "Base.CannedPineapple" },
        LATE = { "Base.BeefJerky", "Base.TunaTin", "Base.CannedTomato2", "Base.CannedPotato2", "Base.CannedPeaches", "Base.CannedFruitCocktail", "Base.CannedMushroomSoup", "Base.CannedCorn", "Base.CannedChili", "Base.CannedCarrots2", "Base.TinnedBeans" },
        END = { "Base.BeefJerky", "Base.TunaTin", "Base.CannedTomato2", "Base.CannedPotato2", "Base.CannedPeaches", "Base.CannedFruitCocktail", "Base.CannedMushroomSoup", "Base.CannedCorn", "Base.CannedChili", "Base.CannedCarrots2", "Base.TinnedBeans" }
    },
    Water = {
        EARLY = { "Base.Pop", "Base.Pop2", "Base.WaterBottle" },
        MID = { "Base.WaterBottle", "Base.Canteen" },
        LATE = { "Base.Canteen" },
        END = { "Base.Canteen", "Base.CanteenMilitary" }
    },
    MeleeWeapon = {
        EARLY = { "Base.KitchenKnife", "Base.RollingPin", "Base.KnifeParing", "Base.SteakKnife", "Base.KnifeFillet", "Base.ScrewDriver", "Base.KnifePocket" },
        MID = { "Base.KitchenKnifeForged", "Base.HandAxe", "Base.GlassShiv", "Base.KnifeShiv", "Base.HuntingKnife" },
        LATE = { "Base.HuntingKnife", "Base.HuntingKnifeForged", "Base.FightingKnife", "Base.HandAxeForged" },
        END = { "Base.HuntingKnife", "Base.HuntingKnifeForged", "Base.FightingKnife", "Base.HandAxeForged" }
    },
    Vice = {
        EARLY = { "Base.CigaretteSingle", "Base.CigarettePack" },
        MID = { "Base.CigaretteSingle", "Base.CigarettePack", "Base.BeerCan", "Base.BeerBottle", "Base.Wine" },
        LATE = { "Base.CigaretteSingle", "Base.CigarettePack", "Base.CigarBox", "Base.Whiskey", "Base.BeerBottle", "Base.Wine" },
        END = { "Base.CigaretteSingle", "Base.CigarettePack", "Base.CigarBox", "Base.Whiskey", "Base.BeerBottle", "Base.Wine" }
    },
    Tools = {
        EARLY = { "Base.Screwdriver", "Base.Hammer", "Base.BallPeenHammer", "Base.ClubHammer", "Base.Wrench", "Base.MasonsChisel" },
        MID = { "Base.Screwdriver", "Base.HammerForged", "Base.Crowbar", "Base.MasonsChisel" },
        LATE = { "Base.HammerForged", "Base.Saw", "Base.CrowbarForged", "Base.MetalworkingChisel" },
        END = { "Base.HammerForged", "Base.CrowbarForged", "Base.BlowTorch", "Base.MetalworkingChisel" }
    },
    Medicine = {
        EARLY = { "Base.Bandage", "Base.Bandaid", "Base.PillsBeta", "Base.Pills" },
        MID = { "Base.Bandage", "Base.PillsBeta", "Base.Pills", "Base.Antibiotics", "Base.Disinfectant" },
        LATE = { "Base.AlcoholBandage", "Base.Antibiotics", "Base.Disinfectant", "Base.PillsVitamins" },
        END = { "Base.AlcoholBandage", "Base.Antibiotics", "Base.AlcoholWipes", "Base.PillsVitamins", "Base.SutureNeedle" }
    }
}

local NOT_POCKETABLE = {
    ["Base.Sledgehammer"] = true,
    ["Base.PickAxe"] = true,
    ["Base.Shovel"] = true,
    ["Base.GasCan"] = true,
    ["Base.BaseballBat"] = true,
    ["Base.Plank"] = true,
    ["Base.Poolcue"] = true,
    ["Base.HockeyStick"] = true,
    ["Base.GardenHoe"] = true,
    ["Base.Rake"] = true,
    ["Base.LeafRake"] = true,
    ["Base.Broom"] = true,
    ["Base.Mop"] = true,
    ["Base.FishingRod"] = true,
    ["Base.GuitarAcoustic"] = true,
    ["Base.GuitarElectric"] = true,
    ["Base.Pan"] = true,
    ["Base.GridlePan"] = true,
}

-- Lazy Cache for reverse lookup
local categoryCache = nil

---Checks if an item is considered "small" or "pocketable"
---@param itemType InventoryItem
---@return boolean
function ReactiveSE_SubKits.IsPocketable(itemType)
    local weight = 0.0
    local typeStr = nil

    if not itemType then return true end

    -- Handle String Input (Script Item lookup)
    if type(itemType) == "string" then
        typeStr = itemType
        local scriptItem = getScriptManager():getItem(itemType)
        if scriptItem then
            weight = scriptItem:getActualWeight()
        end
        -- Handle InventoryItem Input (Instance)
    elseif instanceof(itemType, "InventoryItem") then
        weight = itemType:getActualWeight()
        typeStr = itemType:getFullType()
    end

    -- Safety default
    if not weight then weight = 0 end

    if weight >= 1.5 then
        return false
    end

    -- Check Blacklist (Too big/bulky)
    if typeStr and NOT_POCKETABLE[typeStr] then
        return false
    end

    return true
end

---Gets an item type from the subkit pool, with optional quality bias
---@param subKitType string
---@param worldTier string
---@param lootQuality number|nil
function ReactiveSE_SubKits.GetItem(subKitType, worldTier, lootQuality)
    local pool = SUB_KIT_POOLS[subKitType]
    if not pool then return nil end

    Utils.LogInfo(string.format("[SubKits] GetItem Request: Type=%s Tier=%s Quality=%s", subKitType, worldTier,
        tostring(lootQuality)))

    -- Determine Item Count based on Sandbox / Loot Quality
    local count = 1

    -- Only apply multiple items logic for Food, Vice, and Medicine
    if subKitType == "Food" or subKitType == "Vice" or subKitType == "Medicine" then
        local config = Config.Get()
        local min = config.scenes.subKitCountMin or 1
        local max = config.scenes.subKitCountMax or 3

        if lootQuality == 1 then
            if worldTier == "EARLY" then
                count = min
            elseif worldTier == "MID" or worldTier == "LATE" then
                count = ZombRand(min, max + 1)
            else
                count = max
            end
        elseif lootQuality == 2 then
            count = min
        elseif lootQuality == 3 then
            count = ZombRand(min, max + 1)
        elseif lootQuality == 4 then
            count = max
        end
    end

    -- Ensure at least 1
    if count < 1 then count = 1 end

    local effectiveTier = worldTier

    if lootQuality then
        if lootQuality == 4 then
            -- 50% chance to upgrade tier for better loot
            if ZombRand(100) < 50 then
                effectiveTier = WorldTier.GetNextTier(worldTier)
            end
        elseif lootQuality == 2 then
            -- 50% chance to downgrade
            if ZombRand(100) < 50 then
                effectiveTier = WorldTier.GetPrevTier(worldTier)
            end
        end
    end

    local tierPool = pool[effectiveTier] or pool.EARLY

    -- Fallback to EARLY if tierPool is empty
    if #tierPool == 0 then tierPool = pool.EARLY end
    if #tierPool == 0 then return nil end

    local selectedItem = tierPool[ZombRand(#tierPool) + 1]
    Utils.LogInfo(string.format("[SubKits] Selected: %s (Count: %d)", selectedItem, count))
    return { item = selectedItem, count = count }
end

---Same as GetItem, selects an item type string from the pool
---@param subKitType string
---@param worldTier string
---@param lootQuality number
function ReactiveSE_SubKits.SelectSubKitItem(subKitType, worldTier, lootQuality)
    return ReactiveSE_SubKits.GetItem(subKitType, worldTier, lootQuality)
end

---Returns the category name for a given item type, or nil if not found
---@param itemType string
---@return string|nil category
function ReactiveSE_SubKits.GetCategory(itemType)
    -- Lazy initialization: Build cache on first call only
    if not categoryCache then
        categoryCache = {}
        for categoryName, tierData in pairs(SUB_KIT_POOLS) do
            for _, items in pairs(tierData) do
                for i = 1, #items do
                    categoryCache[items[i]] = categoryName
                end
            end
        end
    end
    return categoryCache[itemType]
end

return ReactiveSE_SubKits
