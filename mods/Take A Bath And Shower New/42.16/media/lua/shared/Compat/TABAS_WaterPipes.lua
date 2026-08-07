local TABAS_Patches = {}
local DIR_KEYS = { "spriteS", "spriteE", "spriteN", "spriteW" }

TABAS_Patches.applied = false

function TABAS_Patches.apply()
    if TABAS_Patches.applied then return true end
    if not WPIso or type(WPIso.barrelSprites) ~= "table" then
        return false
    end

    local barrelSprites = WPIso.barrelSprites
    local TABAS_Sprites = require("TABAS_Sprites")

    local exists = {}
    for _, sprite in ipairs(barrelSprites) do
        exists[sprite] = true
    end

    local function addSprite(sprite)
        if sprite and not exists[sprite] then
            exists[sprite] = true
            table.insert(barrelSprites, sprite)
        end
    end

    for _, v in pairs(TABAS_Sprites.Bathtub) do
        for _, dirKey in ipairs(DIR_KEYS) do
            local dir = v[dirKey]
            addSprite(dir.faucet)
        end
    end

    for _, v in pairs(TABAS_Sprites.Shower) do
        for _, dirKey in ipairs(DIR_KEYS) do
            local dir = v[dirKey]
            addSprite(dir)
        end
    end

    TABAS_Patches.applied = true
    return true
end

return TABAS_Patches
