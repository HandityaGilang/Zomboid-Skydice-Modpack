DCS_WeaponLookup = DCS_WeaponLookup or {}

DCS_WeaponLookup.pzWeaponToChallenge = {
    Crowbar = "Crowbar",
    CrowbarForged = "Crowbar",
    Hammer = "Hammer",
    HammerForged = "Hammer",
    HammerStone = "HammerStone",
    BallPeenHammer = "BallPeenHammer",
    BallPeenHammerForged = "BallPeenHammer",
    ClubHammer = "ClubHammer",
    ClubHammerForged = "ClubHammer",
    HuntingKnife = "HuntingKnife",
    HuntingKnifeForged = "HuntingKnife",
    KitchenKnife = "KitchenKnife",
    KitchenKnifeForged = "KitchenKnife",
    Screwdriver = "Screwdriver",
    SteakKnife = "SteakKnife",
    Katana = "Katana",
    Machete = "Machete",
    MacheteForged = "Machete",
    Axe = "Axe",
    Axe_Old = "Axe_Old",
    HandAxe = "HandAxe",
    HandAxe_Old = "HandAxe_Old",
    HandAxeForged = "HandAxe",
    WoodAxe = "WoodAxe",
    WoodAxeForged = "WoodAxe",
    MeatCleaver = "MeatCleaver",
    MeatCleaver_Scrap = "MeatCleaver_Scrap",
    MeatCleaverForged = "MeatCleaver",
    BaseballBat = "BaseballBat",
    BaseballBat_Crafted = "BaseballBat",
    BaseballBat_Can = "BaseballBat",
    BaseballBat_GardenForkHead = "BaseballBat",
    BaseballBat_Metal = "BaseballBat",
    BaseballBat_Metal_Bolts = "BaseballBat",
    BaseballBat_Nails = "BaseballBat",
    BaseballBat_RakeHead = "BaseballBat",
    BaseballBat_ScrapSheet = "BaseballBat",
    BaseballBat_Spiked = "BaseballBat",
    BaseballBat_Metal_Sawblade = "BaseballBat",
    BaseballBat_RailSpike = "BaseballBat",
    BaseballBat_Sawblade = "BaseballBat",
    BaseballBat_Broken = "BaseballBat",
    BaseballBat_Broken_Nails = "BaseballBat",
    SpearCrafted = "SpearCrafted",
    SpearCraftedFireHardened = "SpearCrafted",
    SpearCrude = "SpearCrafted",
    SpearCrudeLong = "SpearCrafted",
    SpearHandFork = "SpearCrafted",
    SpearGlass = "SpearCrafted",
    SpearHuntingKnife = "SpearCrafted",
    SpearKnife = "SpearCrafted",
    SpearKnifeSmall = "SpearCrafted",
    SpearLong = "SpearLong",
    SpearScissors = "SpearCrafted",
    SpearScrewdriver = "SpearCrafted",
    SpearShort = "SpearShort",
    SpearSteakKnife = "SpearCrafted",
    SpearStone = "SpearCrafted",
    SpearStoneLong = "SpearCrafted",
    Spear_Bone = "SpearCrafted",
    Spear_BoneLong = "SpearCrafted",
    Spear_Plunger = "SpearCrafted",
    SpearLargeKnife = "SpearCrafted",
    SpearScrapKnife = "SpearCrafted",
    SpearFightingKnife = "SpearCrafted",
    Gavel = "Gavel",
    Mace = "Mace",
    Mace_Stone = "Mace_Stone",
    Nightstick = "Nightstick",
    ShortBat = "ShortBat",
    ShortBat_Can = "ShortBat",
    ShortBat_Nails = "ShortBat",
    ShortBat_RakeHead = "ShortBat",
    SpikedShortBat = "SpikedShortBat",
    LongMace = "LongMace",
    LongMace_Stone = "LongMace_Stone",
    LongSpikedClub = "LongSpikedClub",
    CrudeShortSword = "CrudeShortSword",
    CrudeSword = "CrudeSword",
    ShortSword = "ShortSword",
    Sword = "Sword",
    FightingKnife = "FightingKnife",
    HandguardDagger = "HandguardDagger",
    KnifeButterfly = "KnifeButterfly",
    RailroadSpikeKnife = "RailroadSpikeKnife",
    SwitchKnife = "SwitchKnife",
}

local weaponVariantLookup = nil

local function buildWeaponVariantLookup()
    local map = {}
    for _, ch in pairs(DCS_Challenges.Lookup or {}) do
        if ch.weaponVariants then
            for _, variant in ipairs(ch.weaponVariants) do
                map[variant] = ch.weaponType
            end
        end
    end
    return map
end

function DCS_WeaponLookup.resolveWeaponType(pzType)
    if not pzType then return nil end

    if not weaponVariantLookup then
        weaponVariantLookup = buildWeaponVariantLookup()
    end
    if weaponVariantLookup[pzType] then
        return weaponVariantLookup[pzType]
    end

    if DCS_WeaponLookup.pzWeaponToChallenge[pzType] then
        return DCS_WeaponLookup.pzWeaponToChallenge[pzType]
    end

    return pzType
end

function DCS_WeaponLookup.resolveWeaponCategory(weapon)
    if not weapon then return nil end

    local itemType = weapon.getType and weapon:getType() or nil
    if itemType then
        local it = itemType:lower()
        if it:find("shotgun") then
            DCS_dprint("[DCS]   weapon type detect: shotgun (" .. itemType .. ")")
            return "shotgun"
        end
        if it:find("rifle") or it:find("varmint") or it:find("m14") or it:find("m16") then
            DCS_dprint("[DCS]   weapon type detect: rifle (" .. itemType .. ")")
            return "rifle"
        end
    end

    if weapon.getPerk then
        local perk = weapon:getPerk()
        if perk then
            local perkName = nil
            if perk.getName then
                perkName = perk:getName()
            end
            if not perkName and perk.getSkillName then
                perkName = perk:getSkillName()
            end
            if not perkName then
                perkName = tostring(perk)
            end
            DCS_dprint("[DCS]   getPerk() result: " .. tostring(perkName) .. " type=" .. tostring(type(perk)))
            if perkName then
                local pn = perkName:lower()
                if pn:find("short blunt") then return "smallblunt" end
                if pn:find("long blunt") then return "blunt" end
                if pn:find("short blade") then return "smallblade" end
                if pn:find("long blade") then return "longblade" end
                if pn:find("axe") then return "axe" end
                if pn:find("spear") then return "spear" end
                if pn:find("aiming") or pn:find("handgun") then return "handgun" end
            end
        end
    end

    if itemType then
        local script = ScriptManager and ScriptManager.getInstance and ScriptManager.getInstance()
        if script and script.getItem then
            local itemScript = script:getItem(itemType)
            if itemScript and itemScript.getCategories then
                local cats = itemScript:getCategories()
                if cats and #cats > 0 then
                    local cat = cats[1]
                    if cat then cat = cat:gsub("base:", "") end
                    DCS_dprint("[DCS]   ScriptManager categories: " .. tostring(cat))
                    return cat
                end
            end
        end
    end

    return nil
end
