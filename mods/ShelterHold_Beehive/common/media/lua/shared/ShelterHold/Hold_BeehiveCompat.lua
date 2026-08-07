-- Hold_BeehiveCompat.lua
-- Small compatibility helpers for ShelterHold: Beehive.
-- Build 42.15+ moved many item-tag checks toward ItemTag objects, while older
-- B42 builds and older mod code often used string tags.  For this mod's own
-- items we use full item types, which is stable across B42.12 -> B42.19.

HoldBeehiveCompat = HoldBeehiveCompat or {}

local QUEEN_BEE_TYPES = {
    ["Hold.Honeybee"] = true,
    ["Hold.Bumblebee"] = true,
    ["Hold.Zombee"] = true,
}

local HIVE_FRAME_TYPES = {
    ["Hold.HiveFrame_Basic"] = "empty",
    ["Hold.HiveFrame_Wax"] = "wax",
    ["Hold.HiveFrame_Full"] = "full",
}

local function getFullTypeSafe(item)
    if not item or type(item.getFullType) ~= "function" then return nil end
    local ok, value = pcall(function() return item:getFullType() end)
    if ok then return value end
    return nil
end

function HoldBeehiveCompat.isQueenBee(item)
    return QUEEN_BEE_TYPES[getFullTypeSafe(item)] == true
end

function HoldBeehiveCompat.isHiveFrame(item)
    return HIVE_FRAME_TYPES[getFullTypeSafe(item)] ~= nil
end

function HoldBeehiveCompat.isEmptyHiveFrame(item)
    return HIVE_FRAME_TYPES[getFullTypeSafe(item)] == "empty"
end

function HoldBeehiveCompat.isWaxHiveFrame(item)
    return HIVE_FRAME_TYPES[getFullTypeSafe(item)] == "wax"
end

function HoldBeehiveCompat.isFullHiveFrame(item)
    return HIVE_FRAME_TYPES[getFullTypeSafe(item)] == "full"
end

function HoldBeehiveCompat.isHazmatSuit(item)
    if not item or type(item.hasTag) ~= "function" then return false end

    -- Newer B42 builds prefer ItemTag constants.
    if ItemTag and ItemTag.HAZMAT_SUIT then
        local ok, value = pcall(function() return item:hasTag(ItemTag.HAZMAT_SUIT) end)
        if ok and value then return true end
    end

    -- Older B42 fallback.
    local ok, value = pcall(function() return item:hasTag("HazmatSuit") end)
    return ok and value == true
end
