-- XP Popups - per-player PZAPI.ModOptions registration.
-- Settings are accessible from: Main Menu / In-Game Options > Mod Options > XP Popups
-- Saved per-player to: Zomboid/Lua/ModOptions.ini

-- Same overrides as XPPopupsClient.lua — enum ID → IGUI_perks_ key suffix.
local perkKeyOverrides = {
    Lightfoot       = "Lightfooted",
    Sneak           = "Sneaking",
    PlantScavenging = "Foraging",
}

local function perkLabel(perkId)
    local key = perkKeyOverrides[perkId] or perkId
    return getText("IGUI_perks_" .. key)
end

local function registerOptions()
    local options = PZAPI.ModOptions:create("XPPopups", "XP Popups")

    -- Disabled by default: already shown by vanilla UI or trained very rarely.
    options:addTickBox("Fitness",         perkLabel("Fitness"),         false)
    options:addTickBox("Strength",        perkLabel("Strength"),        false)
    options:addTickBox("Electricity",     perkLabel("Electricity"),     false)
    options:addTickBox("PlantScavenging", perkLabel("PlantScavenging"), false)

    -- Athletic / stealth
    options:addTickBox("Sprinting",       perkLabel("Sprinting"),       true)
    options:addTickBox("Lightfoot",       perkLabel("Lightfoot"),       true)
    options:addTickBox("Nimble",          perkLabel("Nimble"),          true)
    options:addTickBox("Sneak",           perkLabel("Sneak"),           true)

    -- Combat
    options:addTickBox("Axe",             perkLabel("Axe"),             true)
    options:addTickBox("SmallBlade",      perkLabel("SmallBlade"),      true)
    options:addTickBox("LongBlade",       perkLabel("LongBlade"),       true)
    options:addTickBox("SmallBlunt",      perkLabel("SmallBlunt"),      true)
    options:addTickBox("Blunt",           perkLabel("Blunt"),           true)
    options:addTickBox("Spear",           perkLabel("Spear"),           true)
    options:addTickBox("Maintenance",     perkLabel("Maintenance"),     true)

    -- Ranged
    options:addTickBox("Aiming",          perkLabel("Aiming"),          true)
    options:addTickBox("Reloading",       perkLabel("Reloading"),       true)

    -- Crafting
    options:addTickBox("Woodwork",        perkLabel("Woodwork"),        true)
    options:addTickBox("MetalWelding",    perkLabel("MetalWelding"),    true)
    options:addTickBox("Mechanics",       perkLabel("Mechanics"),       true)
    options:addTickBox("Tailoring",       perkLabel("Tailoring"),       true)
    options:addTickBox("Blacksmith",      perkLabel("Blacksmith"),      true)
    options:addTickBox("Carving",         perkLabel("Carving"),         true)
    options:addTickBox("FlintKnapping",   perkLabel("FlintKnapping"),   true)
    options:addTickBox("Glassmaking",     perkLabel("Glassmaking"),     true)
    options:addTickBox("Pottery",         perkLabel("Pottery"),         true)
    options:addTickBox("Masonry",         perkLabel("Masonry"),         true)

    -- Survival
    options:addTickBox("Cooking",         perkLabel("Cooking"),         true)
    options:addTickBox("Farming",         perkLabel("Farming"),         true)
    options:addTickBox("Doctor",          perkLabel("Doctor"),          true)
    options:addTickBox("Fishing",         perkLabel("Fishing"),         true)
    options:addTickBox("Trapping",        perkLabel("Trapping"),        true)
    options:addTickBox("Tracking",        perkLabel("Tracking"),        true)
    options:addTickBox("Butchering",      perkLabel("Butchering"),      true)
    options:addTickBox("Husbandry",       perkLabel("Husbandry"),       true)
end

registerOptions()
