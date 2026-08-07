local TABAS_Patches = {}

TABAS_Patches.applied = false

local ModBathSprites = require("Compat/TABAS_ModBathSprites")
local melosSprites = ModBathSprites.MelosTiles
local TABAS_Sprites = require("TABAS_Sprites")

local function addBathtubSprite(name, sheet, base)
    TABAS_Sprites.Bathtub[name] = {
        modelType = name,
        spriteKey = sheet,
        isClean = false,
        isImproved = false,
        isLargeDeluxe = true,
        hasShower = true,
        sortOrder = 1000 + base,
        spriteS = { faucet = sheet .. "_" .. (base + 1), tub = sheet .. "_" .. base },
        spriteE = { faucet = sheet .. "_" .. (base + 2), tub = sheet .. "_" .. (base + 3) },
        spriteN = { faucet = sheet .. "_" .. (base + 4), tub = sheet .. "_" .. (base + 5) },
        spriteW = { faucet = sheet .. "_" .. (base + 7), tub = sheet .. "_" .. (base + 6) },
    }
end

local function addShowerSprite(name, sheet, base)
    TABAS_Sprites.Shower[name] = {
        modelType = name,
        spriteKey = sheet,
        isImproved = false,
        isDeluxe = true,
        sortOrder = 1000 + base,
        spriteS = sheet .. "_" ..base,
        spriteE = sheet .. "_" .. (base + 1),
        spriteW = sheet .. "_" .. (base + 2),
        spriteN = sheet .. "_" .. (base + 3),
    }
end

function TABAS_Patches.apply()
    if TABAS_Patches.applied then return true end
    if not melosSprites.enabled then return false end

    for _, def in ipairs(melosSprites.Bathtub) do
        addBathtubSprite(def.name, def.sheet, def.base)
    end
    for _, def in ipairs(melosSprites.Shower) do
        addShowerSprite(def.name, def.sheet, def.base)
    end

    TABAS_Sprites.indexesBuilt = false
    TABAS_Sprites.buildIndexes()

    local TABAS_TileProperties = require("TABAS_TileProperties")
    if TABAS_TileProperties and TABAS_TileProperties.apply then
        TABAS_TileProperties.apply(true)
    end

    TABAS_Patches.applied = true
    return true
end

return TABAS_Patches
