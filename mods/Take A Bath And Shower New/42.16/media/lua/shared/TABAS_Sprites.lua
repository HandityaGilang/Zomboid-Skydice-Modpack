local TABAS_Sprites = {}

TABAS_Sprites.Bathtub = {
    ["Large Deluxe"] = {
        modelType = "Large Deluxe",
        spriteKey = "fixtures_bathroom_01",
        isClean = false,
        isImproved = false,
        hasShower = true,
        sortOrder = 10,
        spriteS = {faucet="fixtures_bathroom_01_25", tub="fixtures_bathroom_01_24"},
        spriteE = {faucet="fixtures_bathroom_01_26", tub="fixtures_bathroom_01_27"},
        spriteN = {faucet="fixtures_bathroom_01_52", tub="fixtures_bathroom_01_53"},
        spriteW = {faucet="fixtures_bathroom_01_55", tub="fixtures_bathroom_01_54"},
    },
    ["Large Deluxe Clean"] = {
        modelType = "Large Deluxe Clean",
        spriteKey = "tabas_fixtures_bathroom_01",
        isClean = true,
        isImproved = false,
        hasShower = true,
        sortOrder = 20,
        spriteS = {faucet="tabas_fixtures_bathroom_01_25", tub="tabas_fixtures_bathroom_01_24"},
        spriteE = {faucet="tabas_fixtures_bathroom_01_26", tub="tabas_fixtures_bathroom_01_27"},
        spriteN = {faucet="tabas_fixtures_bathroom_01_52", tub="tabas_fixtures_bathroom_01_53"},
        spriteW = {faucet="tabas_fixtures_bathroom_01_55", tub="tabas_fixtures_bathroom_01_54"},
    },
    ["Improved Large Deluxe"] = {
        modelType = "Improved Large Deluxe",
        spriteKey = "tabas_fixtures_bathroom_02",
        isClean = false,
        isImproved = true,
        hasShower = false,
        sortOrder = 30,
        spriteS = {faucet="tabas_fixtures_bathroom_02_25", tub="tabas_fixtures_bathroom_02_24"},
        spriteE = {faucet="tabas_fixtures_bathroom_02_26", tub="tabas_fixtures_bathroom_02_27"},
        spriteN = {faucet="tabas_fixtures_bathroom_02_52", tub="tabas_fixtures_bathroom_02_53"},
        spriteW = {faucet="tabas_fixtures_bathroom_02_55", tub="tabas_fixtures_bathroom_02_54"},
    },
    ["Improved Large Deluxe Clean"] = {
        modelType = "Improved Large Deluxe Clean",
        spriteKey = "tabas_fixtures_bathroom_03",
        isClean = true,
        isImproved = true,
        hasShower = false,
        sortOrder = 40,
        spriteS = {faucet="tabas_fixtures_bathroom_03_25", tub="tabas_fixtures_bathroom_03_24"},
        spriteE = {faucet="tabas_fixtures_bathroom_03_26", tub="tabas_fixtures_bathroom_03_27"},
        spriteN = {faucet="tabas_fixtures_bathroom_03_52", tub="tabas_fixtures_bathroom_03_53"},
        spriteW = {faucet="tabas_fixtures_bathroom_03_55", tub="tabas_fixtures_bathroom_03_54"},
    },
}

TABAS_Sprites.Shower = {
    ["Deluxe"] = {
        modelType = "Deluxe",
        isImproved = false,
        sortOrder = 20,
        spriteS = "fixtures_bathroom_01_32", spriteE = "fixtures_bathroom_01_33"
    },
    ["Improved Deluxe"] = {
        modelType = "Improved Deluxe",
        isImproved = true,
        sortOrder = 30,
        spriteS = "tabas_fixtures_bathroom_01_32", spriteE = "tabas_fixtures_bathroom_01_33", spriteN = "tabas_fixtures_bathroom_01_34", spriteW = "tabas_fixtures_bathroom_01_35"
    },
    ["Wall"] = {
        modelType = "Wall",
        isImproved = false,
        sortOrder = 10,
        spriteS = "fixtures_bathroom_01_30", spriteE = "fixtures_bathroom_01_31", spriteN = "fixtures_bathroom_01_22", spriteW = "fixtures_bathroom_01_23"
    },
}

TABAS_Sprites.Index = TABAS_Sprites.Index or {}
TABAS_Sprites.indexesBuilt = TABAS_Sprites.indexesBuilt or false

local DIR_KEYS = { "spriteS", "spriteE", "spriteN", "spriteW" }
function TABAS_Sprites.ensureIndexes()
    if TABAS_Sprites.indexesBuilt then return true end
    TABAS_Sprites.buildIndexes()
    return true
end

function TABAS_Sprites.buildIndexes()
    if TABAS_Sprites.indexesBuilt then return true end
    TABAS_Sprites.indexesBuilt = true

    TABAS_Sprites.Index.ModelTypeBySprite = TABAS_Sprites.Index.ModelTypeBySprite or {}
    TABAS_Sprites.Index.BathtubDefBySprite = {}
    TABAS_Sprites.Index.BathtubDefBySpriteKey = {}
    TABAS_Sprites.Index.ShowerDefBySprite = {}
    TABAS_Sprites.Index.BathWithShowerSprite = {}
    TABAS_Sprites.Index.BathPartBySprite = {} -- sprite -> "faucet"/"tub"
    do
        local map = {}
        local bath = TABAS_Sprites.Bathtub
        for modelType, def in pairs(bath) do
            if def.spriteKey then
                TABAS_Sprites.Index.BathtubDefBySpriteKey[def.spriteKey] = def
            end
            for _, dirKey in ipairs(DIR_KEYS) do
                local dir = def[dirKey]
                if type(dir) == "table" then
                    if dir.faucet then
                        map[dir.faucet] = modelType
                        TABAS_Sprites.Index.BathtubDefBySprite[dir.faucet] = def
                        TABAS_Sprites.Index.BathPartBySprite[dir.faucet] = "faucet"

                        if def.hasShower then
                            TABAS_Sprites.Index.BathWithShowerSprite[dir.faucet] = true
                        end
                    end
                    if dir.tub then
                        map[dir.tub] = modelType
                        TABAS_Sprites.Index.BathtubDefBySprite[dir.tub] = def
                        TABAS_Sprites.Index.BathPartBySprite[dir.tub] = "tub"
                    end
                end
            end
        end
        TABAS_Sprites.Index.ModelTypeBySprite.Bathtub = map
    end

    do
        local map = {}
        local sh = TABAS_Sprites.Shower
        for modelType, def in pairs(sh) do
            for _, dirKey in ipairs(DIR_KEYS) do
                local sprite = def[dirKey]
                if type(sprite) == "string" then
                    map[sprite] = modelType
                    TABAS_Sprites.Index.ShowerDefBySprite[sprite] = def
                end
            end
        end
        TABAS_Sprites.Index.ModelTypeBySprite.Shower = map
    end
end

Events.OnGameStart.Add(TABAS_Sprites.buildIndexes)
Events.OnServerStarted.Add(TABAS_Sprites.buildIndexes)


-- Main object uses the "faucet" key, "dirty" key is completely optional.
-- Low, half, and full are required and require some kind of string. 
-- If you leave them as an empty string likes "", the Invisible tag will be automatically added.
TABAS_Sprites.BathWater = {
    spriteS = {
        faucet = {
            low="tabas_bath_water_01_4", halfLow="tabas_bath_water_01_5", half="tabas_bath_water_01_6", full="tabas_bath_water_01_7",
            dirty = {low="tabas_bath_water_01_44", halfLow="tabas_bath_water_01_45", half="tabas_bath_water_01_46", full="tabas_bath_water_01_47"},
            empty = "tabas_bath_water_01_33",
            steam = "tabas_textures_01_16"
        },
        tub = {
            low="tabas_bath_water_01_0", halfLow="tabas_bath_water_01_1", half="tabas_bath_water_01_2", full="tabas_bath_water_01_3",
            dirty = {low="tabas_bath_water_01_40", halfLow="tabas_bath_water_01_41", half="tabas_bath_water_01_42", full="tabas_bath_water_01_43"},
            empty = "tabas_bath_water_01_32",
            steam = "tabas_textures_01_20"
        }
    },
    spriteE = {
        faucet = {
            low="tabas_bath_water_01_8", halfLow="tabas_bath_water_01_9", half="tabas_bath_water_01_10", full="tabas_bath_water_01_11",
            dirty = {low="tabas_bath_water_01_48", halfLow="tabas_bath_water_01_49", half="tabas_bath_water_01_50", full="tabas_bath_water_01_51"},
            empty = "tabas_bath_water_01_34",
            steam = "tabas_textures_01_17"
        },
        tub = {
            low="tabas_bath_water_01_12", halfLow="tabas_bath_water_01_13", half="tabas_bath_water_01_14", full="tabas_bath_water_01_15",
            dirty = {low="tabas_bath_water_01_52", halfLow="tabas_bath_water_01_53", half="tabas_bath_water_01_54", full="tabas_bath_water_01_55"},
            empty = "tabas_bath_water_01_35",
            steam = "tabas_textures_01_21"
        }
    },
    spriteN = {
        faucet = {
            low="tabas_bath_water_01_16", halfLow="tabas_bath_water_01_17", half="tabas_bath_water_01_18", full="tabas_bath_water_01_19",
            dirty = {low="tabas_bath_water_01_56", halfLow="tabas_bath_water_01_57", half="tabas_bath_water_01_58", full="tabas_bath_water_01_59"},
            empty = "tabas_bath_water_01_36",
            steam = "tabas_textures_01_18"
        },
        tub = {
            low="tabas_bath_water_01_20", halfLow="tabas_bath_water_01_21", half="tabas_bath_water_01_22", full="tabas_bath_water_01_23",
            dirty = {low="tabas_bath_water_01_60", halfLow="tabas_bath_water_01_61", half="tabas_bath_water_01_62", full="tabas_bath_water_01_63"},
            empty = "tabas_bath_water_01_37",
            steam = "tabas_textures_01_22"
        }
    },
    spriteW = {
        faucet = {
            low="tabas_bath_water_01_28", halfLow="tabas_bath_water_01_29", half="tabas_bath_water_01_30", full="tabas_bath_water_01_31",
            dirty = {low="tabas_bath_water_01_68", halfLow="tabas_bath_water_01_69", half="tabas_bath_water_01_70", full="tabas_bath_water_01_71"},
            empty = "tabas_bath_water_01_39",
            steam = "tabas_textures_01_19"
        },
        tub = {
            low="tabas_bath_water_01_24", halfLow="tabas_bath_water_01_25", half="tabas_bath_water_01_26", full="tabas_bath_water_01_27",
            dirty = {low="tabas_bath_water_01_64", halfLow="tabas_bath_water_01_65", half="tabas_bath_water_01_66", full="tabas_bath_water_01_67"},
            empty = "tabas_bath_water_01_38",
            steam = "tabas_textures_01_23"
        }
    }
}

TABAS_Sprites.ShowerWater = {
    spriteS = {"tabas_textures_01_24", "tabas_textures_01_25", "tabas_textures_01_26", "tabas_textures_01_27", "tabas_textures_01_28"},
    spriteE = {"tabas_textures_01_32", "tabas_textures_01_33", "tabas_textures_01_34", "tabas_textures_01_35", "tabas_textures_01_36"},
    spriteN = {"tabas_textures_01_40", "tabas_textures_01_41", "tabas_textures_01_42", "tabas_textures_01_43", "tabas_textures_01_44"},
    spriteW = {"tabas_textures_01_48", "tabas_textures_01_49", "tabas_textures_01_50", "tabas_textures_01_51", "tabas_textures_01_52"}
}

TABAS_Sprites.ShowerBlank = {
    spriteS = "tabas_textures_01_4",
    spriteE = "tabas_textures_01_5",
    spriteN = "tabas_textures_01_6",
    spriteW = "tabas_textures_01_7"
}

TABAS_Sprites.ShowerSteam = {
    blank = {"tabas_textures_01_2", "tabas_textures_01_3"},
    body = {"tabas_textures_01_0", "tabas_textures_01_1"},
    puffL = {"tabas_textures_01_8", "tabas_textures_01_9", "tabas_textures_01_10", "tabas_textures_01_11"},
    puffR = {"tabas_textures_01_12", "tabas_textures_01_13", "tabas_textures_01_14", "tabas_textures_01_15"}
}

return TABAS_Sprites
