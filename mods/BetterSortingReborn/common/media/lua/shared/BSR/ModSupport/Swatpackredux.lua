--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: SWAT Pack Redux.
-- https://steamcommunity.com/sharedfiles/filedetails/?id=2091564445
--
-- Mappings migrated from Better Sorting (Swatpackredux_Items.lua): 36 lines, no
-- repeats -> 36 items. Like several gear packs, the mod adds its items to the
-- Base module; none of them exists in vanilla 42.19 or in BSR's Data/ tables,
-- so the whole pack is `data`. The original's placement is kept: the gas mask,
-- goggles and balaclava go with the helmets (ClothHead), pouches -> ClothBag
-- and the two duffel-style bags -> ClothBack.
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.ModPacks = BSR.ModPacks or {}

table.insert(BSR.ModPacks, {
    name = "Swatpackredux",
    mods = { "Swatpack" },
    data = {
        Ammo = {
            items = {
                "Base.RubberShells",
                "Base.RubberShellsBox",
            },
        },
        ClothAcc = {
            items = {
                "Base.Hat_SWATNeck",
            },
        },
        ClothArm = {
            items = {
                "Base.Gloves_RiotGloves",
                "Base.Gloves_SwatGloves",
                "Base.SwatElbowPads",
                "Base.SwatShoulderPads",
            },
        },
        ClothBack = {
            items = {
                "Base.Bag_BigSwatBag",
                "Base.Bag_PoliceBag",
            },
        },
        ClothBag = {
            items = {
                "Base.SWATPouch",
            },
        },
        ClothBody = {
            items = {
                "Base.AntibombSuit",
                "Base.AntibombSuitP2",
                "Base.Jacket_Swat",
                "Base.RiotArmorSuit",
                "Base.Vest_BulletSwat",
            },
        },
        ClothFeet = {
            items = {
                "Base.Shoes_RiotBoots",
                "Base.Shoes_SwatBoots",
            },
        },
        ClothHead = {
            items = {
                "Base.Glasses_SwatGoggles",
                "Base.Hat_Antibombhelmet",
                "Base.Hat_Balaclava_Swat",
                "Base.Hat_PoliceRiotHelmet",
                "Base.Hat_SWATRiotHelmet",
                "Base.Hat_SWATRiotHelmet2",
                "Base.Hat_SwatGasMask",
                "Base.Hat_SwatHelmet",
            },
        },
        ClothLeg = {
            items = {
                "Base.SwatKneePads",
                "Base.Trousers_Swat",
            },
        },
        WepAmmoMag = {
            items = {
                "Base.9mmMp5Clip",
            },
        },
        WepBomb = {
            items = {
                "Base.SwatFragGrenade",
                "Base.SwatSmokeGrenade",
                "Base.SwatStunGrenade",
            },
        },
        WepFire = {
            items = {
                "Base.Co2ShortRiotShotgun",
                "Base.RiotShotgun",
                "Base.SwatMP5",
            },
        },
        WepShield = {
            items = {
                "Base.RiotShieldPolice",
                "Base.RiotShieldSwat",
            },
        },
    },
})
