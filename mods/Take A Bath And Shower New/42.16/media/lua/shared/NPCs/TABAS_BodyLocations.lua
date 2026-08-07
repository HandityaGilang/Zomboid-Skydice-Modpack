local group = BodyLocations.getGroup("Human")

group:getOrCreateLocation(TABAS_BodyLocation.BodyGrime)
group:getOrCreateLocation(TABAS_BodyLocation.BodyShampoo)

-----------------------------------------------------------------------
-----------------------------------------------------------------------

local TABAS_BodyLocations = {}
TABAS_BodyLocations.Exclude = {}

TABAS_BodyLocations.Exclude.AccessoryLocations = {
    ItemBodyLocation.BELLY_BUTTON,
    ItemBodyLocation.EAR_TOP,
    ItemBodyLocation.EARS,
    ItemBodyLocation.NOSE,
    ItemBodyLocation.NECKLESS,
    ItemBodyLocation.NECKLESS_LONG,
    ItemBodyLocation.LEFT_WRIST,
    ItemBodyLocation.RIGHT_WRIST,
    ItemBodyLocation.LEFT_MIDDLE_FINGER,
    ItemBodyLocation.RIGHT_MIDDLE_FINGER,
    ItemBodyLocation.LEFT_RING_FINGER,
    ItemBodyLocation.RIGHT_RING_FINGER,
}

TABAS_BodyLocations.Exclude.GlassesLocations = {
    ItemBodyLocation.EYES,
    ItemBodyLocation.LEFT_EYE,
    ItemBodyLocation.RIGHT_EYE,
}

TABAS_BodyLocations.Exclude.BodyLocations = {
    ItemBodyLocation.MAKE_UP_FULL_FACE,
    ItemBodyLocation.MAKE_UP_EYES,
    ItemBodyLocation.MAKE_UP_EYES_SHADOW,
    ItemBodyLocation.MAKE_UP_LIPS,
    ItemBodyLocation.BANDAGE,
    ItemBodyLocation.WOUND,
    ItemBodyLocation.ZED_DMG,
}

TABAS_BodyLocations.Exclude.FullType = {
    ["Base.TowelHat"] = true, -- From Bathtowel Overhaul - Wearable Addon
    ["Base.TowelBottom"] = true,
    ["Base.TowelTop"] = true,
    ["Base.Hat_ShowerCap"] = true -- Base item
}

function TABAS_BodyLocations.Exclude.AddExcludeAccessoryLocations(bodyLocation)
    table.insert(TABAS_BodyLocations.Exclude.AccessoryLocations, bodyLocation)
end

function TABAS_BodyLocations.Exclude.AddExcludeBodyLocations(bodyLocation)
    table.insert(TABAS_BodyLocations.Exclude.BodyLocations, bodyLocation)
end

-- TABAS_BodyLocations.Exclude.AddExcludeBodyLocations(TABAS_BodyLocation.BodyGrime)
-- TABAS_BodyLocations.Exclude.AddExcludeBodyLocations(TABAS_BodyLocation.BodyShampoo)

return TABAS_BodyLocations