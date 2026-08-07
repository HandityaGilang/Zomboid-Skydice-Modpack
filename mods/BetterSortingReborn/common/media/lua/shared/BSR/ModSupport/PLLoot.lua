--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: PL Loot.
--
-- Covers:
--   PLLoot / PLLootF / PLLootG (PL Loot, and its Fantasy / Guns variants)
--   — https://steamcommunity.com/sharedfiles/filedetails/?id=2279084780
--   PLLoot_Patch (PL Loot Patch)
--   — https://steamcommunity.com/sharedfiles/filedetails/?id=2703858802
--
-- The patch only adds recoloured variants (_Black / _Military) of items from
-- the base mod, so all four IDs share one pack. Every name is in the Base
-- module but is added by the mods themselves: none collides with a vanilla item
-- or with a BSR Data/ table.
--
-- The original sends the mod's wig-style hats (Hat_Hair*) to Appearance rather
-- than Clothing - Head; that choice is kept.
--
-- Mappings migrated from Better Sorting v2.0.4 (PLLoot_Items.lua).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.ModPacks = BSR.ModPacks or {}

table.insert(BSR.ModPacks, {
    name = "PLLoot",
    mods = { "PLLoot", "PLLootF", "PLLootG", "PLLoot_Patch" },
    data = {
        Ammo = {
            items = {
                "Base.132Box",
                "Base.132Bullets",
                "Base.40Clip",
                "Base.40ClipCan",
                "Base.40Rounds",
                "Base.500Box",
                "Base.500Bullets",
                "Base.556HMGBelt",
                "Base.LewisDrum",
                "Base.MASClip",
                "Base.PPSHClip",
                "Base.VulcanClip",
                "Base.WitchySMGClip",
            },
        },
        Appear = {
            items = {
                "Base.Hat_HairBun2",
                "Base.Hat_HairCroft",
                "Base.Hat_HairFab",
                "Base.Hat_HairFio",
                "Base.Hat_HairFio2",
                "Base.Hat_HairLeo",
                "Base.Hat_HairMarcel",
                "Base.Hat_HairP",
                "Base.Hat_HairPiggy",
                "Base.Hat_HairRachel2",
                "Base.Hat_HairWendy",
                "Base.Hat_HairWide",
            },
        },
        ClothAcc = {
            items = {
                "Base.ClericNeck",
                "Base.HolsterPLL",
                "Base.HolsterPLL2",
                "Base.HolsterPLL2M",
                "Base.HolsterPLLLEFT",
                "Base.HolsterPLLLEFT2",
                "Base.HolsterPLLLEFT2M",
                "Base.HolsterPLLLEFTM",
                "Base.HolsterPLLM",
                "Base.KnightWaist",
                "Base.RogueWaist",
                "Base.strapchest2_Black",
                "Base.strapchest2_Military",
                "Base.strapchest_Black",
                "Base.strapchest_Military",
            },
        },
        ClothArm = {
            items = {
                "Base.ElbowbandL",
                "Base.ElbowbandR",
                "Base.Gloves_Rogue",
                "Base.Gloves_TKnight",
                "Base.KnightArms",
                "Base.RogueArms",
                "Base.TKSPad",
                "Base.bandagesgloves",
                "Base.bandagesglovesdenim",
                "Base.bandagesglovesleather",
            },
        },
        ClothBack = {
            items = {
                "Base.Bag_ParaMedic",
                "Base.smallback",
            },
        },
        ClothBag = {
            items = {
                "Base.BeltRig",
                "Base.MVest",
                "Base.MVest2",
                "Base.MVest2_Black",
                "Base.MVest2_Military",
                "Base.MVest_Black",
                "Base.MVest_Military",
                "Base.RogueWaistBag",
                "Base.RogueWaistBag_Black",
                "Base.RogueWaistBag_Military",
                "Base.TacticalWaistBagBack",
                "Base.TacticalWaistBagBackMed",
                "Base.TacticalWaistBagBack_Black",
                "Base.TacticalWaistBagBack_Military",
                "Base.TacticalWaistBagFront",
                "Base.TacticalWaistBagFrontMed",
                "Base.TacticalWaistBagFront_Black",
                "Base.TacticalWaistBagFront_Military",
                "Base.medbag",
                "Base.medbag2",
            },
        },
        ClothBody = {
            items = {
                "Base.ChainMail",
                "Base.CropTop",
                "Base.PFCropped",
                "Base.PFVest",
                "Base.PFVest2",
                "Base.RogueHoodie",
                "Base.SpookySuit",
                "Base.SportTankTop",
                "Base.Vest_HECU",
                "Base.Vest_RogueVest",
                "Base.Vest_RogueVest_Black",
                "Base.Vest_RogueVest_Military",
                "Base.Vest_Tknight",
                "Base.Vest_WitchyCarrier",
                "Base.Vest_WitchyCarrier_Black",
                "Base.Vest_WitchyCarrier_Military",
                "Base.WetSuit",
                "Base.WitchyDress",
                "Base.aresbody",
                "Base.strapchest",
                "Base.strapchest2",
            },
        },
        ClothFeet = {
            items = {
                "Base.Shoes_Canvasshoes",
                "Base.Shoes_CanvasshoesLong",
                "Base.Shoes_Rogue",
                "Base.Shoes_TKnight",
                "Base.WitchySocks",
            },
        },
        ClothHead = {
            items = {
                "Base.Animask1",
                "Base.Animask12",
                "Base.Animask13",
                "Base.Animask2",
                "Base.Animask22",
                "Base.Animask23",
                "Base.BalaTight",
                "Base.BalaTight2",
                "Base.ClericMask",
                "Base.FlatCap",
                "Base.GlassesPLL",
                "Base.GlassesPLLR",
                "Base.HATELA",
                "Base.HATELAHEADS",
                "Base.Hat_Altyn",
                "Base.Hat_Altynopen",
                "Base.Hat_SpiffoEars",
                "Base.Hat_Tknight",
                "Base.Hat_Tknightopen",
                "Base.Hat_TubaHat",
                "Base.Hat_WitchyHat",
                "Base.Mask_HECU",
                "Base.RogueMask",
            },
        },
        ClothLeg = {
            items = {
                "Base.ClericPants",
                "Base.KnightGreaves",
                "Base.Leggings_Bottoms",
                "Base.PFKnee",
                "Base.PFPants",
                "Base.PFShorts",
                "Base.RogueGreaves",
                "Base.ShorterDenim",
                "Base.Shorts_Kimo",
                "Base.bandageslegs",
                "Base.bandageslegsdenim",
                "Base.bandageslegsleather",
            },
        },
        LitE = {
            items = {
                "Base.Grimoire",
                "Base.grimoireclosed",
            },
        },
        WepFire = {
            items = {
                "Base.AutoCannon",
                "Base.AutoCannonA",
                "Base.ClericRevolver",
                "Base.JERICHOP",
                "Base.Lewis",
                "Base.MAS38",
                "Base.MP5GL",
                "Base.MP5GL2",
                "Base.PPSH",
                "Base.RogueSniperRifle",
                "Base.TKShotgun",
                "Base.Vulcan",
                "Base.WitchySMG",
                "Base.WitchySMGE",
                "Base.WitchySMGEN",
                "Base.WitchySMGN",
                "Base.m32r",
                "Base.m79",
                "Base.m79A",
                "Base.p88p",
            },
        },
        WepMelee = {
            items = {
                "Base.ClericMace",
                "Base.RogueSword",
                "Base.RogueSword2",
                "Base.TKSword",
                "Base.TKSword2",
                "Base.TKSwordHalf",
                "Base.Tanto",
                "Base.Tanto2",
                "Base.Tanto3",
                "Base.WitchyStaff",
            },
        },
        WepShield = {
            items = {
                "Base.MShield",
            },
        },
    },
})
