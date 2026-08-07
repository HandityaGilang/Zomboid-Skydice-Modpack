--//////////////////////////////////////////////////--
--    Reactive Sound Events - Outfit Data
--    Data definitions for the Outfit System
--//////////////////////////////////////////////////--

local ReactiveSE_OutfitData = {}

--//////////////////////////////////////////////////--
--    Outfit Pool
--//////////////////////////////////////////////////--

ReactiveSE_OutfitData.OUTFITS = {
    CIVILIAN = {
        STANDARD = {
            "Biker",
            "Camper",
            "Rocker",
            "Generic01", "Generic02", "Generic03", "Generic04", "Generic05",
            "Tourist",
            "Punk"
        }
    },

    SURVIVOR = {
        LOW = {
            "Survivalist",
            "Survivalist02",
            "Survivalist03",
            "Survivalist04",
            "Survivalist05"
        },
        MID = {
            "Survivalist_Mid",
            "Survivalist02_Mid",
            "Survivalist03_Mid",
            "Survivalist04_Mid",
            "Survivalist05_Mid"
        },
        HIGH = {
            "Survivalist_Late",
            "Survivalist02_Late",
            "Survivalist03_Late",
            "Survivalist04_Late",
            "Survivalist05_Late"
        }
    },

    BANDIT = {
        SCAVENGER = {
            "Bandit_Early"
        },
        GANG = {
            "Bandit_Mid"
        },
        WARLORD = {
            "Bandit_Late"
        }
    },

    AUTHORITY = {
        BASIC = {
            "Police",
            "Fireman",
            "Ranger"
        },
        SPECIAL = {
            "Sheriff_Deputy",
            "PoliceState",
            "FiremanFullSuit"
        },
        ELITE = {
            "Police_SWAT",
            "PoliceRiot",
            "PrivateMilitia"
        }
    },

    MILITARY = {
        LIGHT = {
            "ArmyServiceUniform"
        },
        HEAVY = {
            "ArmyCamoGreen",
            "ArmyCamoDesert"
        },
        ELITE = {
            "ArmyInstructor",
        }
    }
}

-- Outfits identified as MALE ONLY
ReactiveSE_OutfitData.MALE_ONLY_OUTFITS = {
    "PoliceRiot",
    "ArmyInstructor"
}

--//////////////////////////////////////////////////--
--    PROBABILITY CONFIGURATION
--//////////////////////////////////////////////////--

ReactiveSE_OutfitData.TIER_CONFIG = {
    EARLY = {
        CategoryWeights = {
            CIVILIAN  = 60,
            SURVIVOR  = 25,
            BANDIT    = 10,
            AUTHORITY = 4,
            MILITARY  = 1
        }
    },
    MID = {
        CategoryWeights = {
            CIVILIAN  = 20,
            SURVIVOR  = 35,
            BANDIT    = 30,
            AUTHORITY = 10,
            MILITARY  = 5
        }
    },
    LATE = {
        CategoryWeights = {
            CIVILIAN  = 5,
            SURVIVOR  = 30,
            BANDIT    = 35,
            AUTHORITY = 15,
            MILITARY  = 15
        }
    },
    END = {
        CategoryWeights = {
            CIVILIAN  = 0,
            SURVIVOR  = 30,
            BANDIT    = 40,
            AUTHORITY = 10,
            MILITARY  = 20
        }
    }
}

-- Relative weights for subtier selection within a category
ReactiveSE_OutfitData.SUBTIER_WEIGHTS = {
    SURVIVOR = {
        EARLY = { LOW = 90, MID = 10, HIGH = 0 },
        MID   = { LOW = 30, MID = 60, HIGH = 10 },
        LATE  = { LOW = 10, MID = 40, HIGH = 50 },
        END   = { LOW = 0, MID = 20, HIGH = 80 }
    },
    BANDIT = {
        EARLY = { SCAVENGER = 100, GANG = 0, WARLORD = 0 },
        MID   = { SCAVENGER = 40, GANG = 60, WARLORD = 0 },
        LATE  = { SCAVENGER = 10, GANG = 50, WARLORD = 40 },
        END   = { SCAVENGER = 0, GANG = 20, WARLORD = 80 }
    },
    AUTHORITY = {
        EARLY = { BASIC = 90, SPECIAL = 10, ELITE = 0 },
        MID   = { BASIC = 50, SPECIAL = 40, ELITE = 10 },
        LATE  = { BASIC = 20, SPECIAL = 30, ELITE = 50 },
        END   = { BASIC = 0, SPECIAL = 20, ELITE = 80 }
    },
    MILITARY = {
        EARLY = { LIGHT = 100, HEAVY = 0, ELITE = 0 },
        MID   = { LIGHT = 60, HEAVY = 40, ELITE = 0 },
        LATE  = { LIGHT = 20, HEAVY = 60, ELITE = 20 },
        END   = { LIGHT = 0, HEAVY = 40, ELITE = 60 }
    },
    CIVILIAN = {
        EARLY = { STANDARD = 100 },
        MID   = { STANDARD = 100 },
        LATE  = { STANDARD = 100 },
        END   = { STANDARD = 100 }
    }
}

--//////////////////////////////////////////////////--
--          Public Functions                      --
--//////////////////////////////////////////////////--

---Gets a random outfit from a category/subcategory
---@param category string "CIVILIAN", "SURVIVOR", "BANDIT", "AUTHORITY", "MILITARY"
---@param subcategory string Subcategory key within the category
---@return string outfit name
function ReactiveSE_OutfitData.GetRandomOutfit(category, subcategory)
    local pool = ReactiveSE_OutfitData.OUTFITS[category]
    if pool and pool[subcategory] then
        local outfits = pool[subcategory]
        return outfits[ZombRand(1, #outfits + 1)]
    end
    return "Generic01"
end

return ReactiveSE_OutfitData
