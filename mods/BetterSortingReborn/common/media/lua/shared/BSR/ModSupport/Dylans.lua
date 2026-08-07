--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: Dylan's mods (The Workshop, Pitstop).
-- Novelty weapons, clothing and collectables sorted by kind.
--
-- Covers (one guard per mod in the original):
--   NewEkron (TheWorkshop(new version)) — https://steamcommunity.com/sharedfiles/filedetails/?id=2712480036
--   Pitstop (Pitstop, PitstopLegacy) — https://steamcommunity.com/sharedfiles/filedetails/?id=2597946327
--
-- Mappings migrated from Better Sorting (Dylans_Items.lua).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.ModPacks = BSR.ModPacks or {}

table.insert(BSR.ModPacks, {
    name = "Dylans",
    mods = { "TheWorkshop(new version)", "Pitstop", "PitstopLegacy" },
    data = {
        Appear = {
            items = {
                "Base.DisrespectMullet",
            },
        },
        ClothAcc = {
            items = {
                "Base.StormTrooperBelt",
            },
        },
        ClothArm = {
            items = {
                "Base.StormTrooperArmletL",
                "Base.StormTrooperArmletR",
                "Base.StormTrooperShoulders",
            },
        },
        ClothBack = {
            items = {
                "Base.AlienBackPack",
                "Base.FluxBackPack",
                "Base.KleanBackPack",
            },
        },
        ClothBag = {
            items = {
                "Base.SheriffEliBelt",
            },
        },
        ClothBody = {
            items = {
                "Base.AstroSuit",
                "Base.AstronautSuit",
                "Base.Bandshirt",
                "Base.CleanUpKrewJumpsuit",
                "Base.DisrespectVest",
                "Base.Dress_StarTrekDress1",
                "Base.FutureJacket",
                "Base.PowerArmor",
                "Base.SheriffEliVest",
                "Base.Shirt_StarTrekShirt1",
                "Base.StormTrooperArmor",
            },
        },
        ClothFeet = {
            items = {
                "Base.AirMags",
                "Base.Shoes_CleanUpKrewSneakers",
                "Base.Shoes_StormTrooperBoots",
            },
        },
        ClothHead = {
            items = {
                "Base.AlienCap",
                "Base.AstroHelmet",
                "Base.DarthVaderHelmet",
                "Base.MedievalHelmet",
                "Base.RoboCopHelmet",
                "Base.ScifiHelmet01",
                "Base.SheriffEliHat",
                "Base.SpaceHelmet",
                "Base.StormTrooperHelmet",
            },
        },
        ClothLeg = {
            items = {
                "Base.StormTrooperLegs",
            },
        },
        Collect = {
            items = {
                "Base.AstroSpiff_WorldItem",
                "Base.Bender_WorldItem",
                "Base.HBoard_WorldItem",
                "Base.Lightsaber_WorldItem",
                "Base.R2D2_WorldItem",
            },
        },
        Misc = {
            items = {
                "Base.AirMags_WorldItem",
            },
        },
        WepFire = {
            items = {
                "Base.Boltgun",
                "Base.BuckRogersGun",
                "Base.CyberPistol",
                "Base.E11Blaster",
                "Base.FutureAssaultRifle",
                "Base.FutureRevolver",
                "Base.FutureShotgun",
                "Base.M41APulse",
                "Base.MP5HK",
                "Base.Rusty",
                "Base.TheZapper",
            },
        },
        WepMelee = {
            items = {
                "Base.DjackzVinyl",
                "Base.EnergySword",
                "Base.GhostTrap",
                "Base.HoverboardMelee",
                "Base.JadeCandyCane",
                "Base.JeanBeanWand",
                "Base.Lightsaber01",
                "Base.Lightsaber02",
                "Base.Lightsaber03",
                "Base.MndoBrush",
                "Base.SausageWeapon",
                "Base.TheBong",
            },
        },
    },
})
