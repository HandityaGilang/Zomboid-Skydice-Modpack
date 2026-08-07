--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: Fantasy Workshop VS.
-- https://steamcommunity.com/sharedfiles/filedetails/?id=2870725947
--
-- Large clothing/cosplay pack; every item lives in the Base module.
--
-- One of the original's lines is dropped: Base.Maggots is a vanilla 42.19
-- item that Data/FoodN.lua already sorts to the same category.
--
-- Mappings migrated from Better Sorting v2.0.4
-- (Fantasy_Workshop_Items.lua).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.ModPacks = BSR.ModPacks or {}

table.insert(BSR.ModPacks, {
    name = "Fantasy_Workshop",
    mods = { "Fantasy Workshop VS" },
    data = {
        ClothAcc = {
            items = {
                "Base.belt_cat1",
                "Base.belt_cat19",
                "Base.belt_cat24",
                "Base.belt_cat28",
                "Base.belt_cat6",
                "Base.belt_catgun",
                "Base.neck_cat17",
                "Base.neck_cat22",
                "Base.neck_cat25",
            },
        },
        ClothArm = {
            items = {
                "Base.glove_cat10",
                "Base.glove_cat11_w",
                "Base.glove_cat18",
                "Base.glove_cat19",
                "Base.glove_cat2",
                "Base.glove_cat20",
                "Base.glove_cat28",
            },
        },
        ClothBack = {
            items = {
                "Base.Bag_cat_1",
                "Base.Bag_cat_2",
                "Base.Bag_cat_3",
                "Base.Bag_cat_4",
                "Base.Bag_cat_5",
                "Base.Bag_cat_6",
            },
        },
        ClothBag = {
            items = {
                "Base.bbao1",
                "Base.bbbao1",
                "Base.bpbao1",
                "Base.pbao1",
            },
        },
        ClothBody = {
            items = {
                "Base.XXhong",
                "Base.beike_cat1",
                "Base.bra_cat12",
                "Base.bra_cat12G",
                "Base.bra_cat19",
                "Base.bra_cat19_1",
                "Base.clothes_cat1",
                "Base.clothes_cat10",
                "Base.clothes_cat10_G",
                "Base.clothes_cat11",
                "Base.clothes_cat12",
                "Base.clothes_cat12G",
                "Base.clothes_cat13",
                "Base.clothes_cat14",
                "Base.clothes_cat14_1",
                "Base.clothes_cat15",
                "Base.clothes_cat16",
                "Base.clothes_cat16_1",
                "Base.clothes_cat16_2",
                "Base.clothes_cat17",
                "Base.clothes_cat18",
                "Base.clothes_cat2",
                "Base.clothes_cat20",
                "Base.clothes_cat20_1",
                "Base.clothes_cat21",
                "Base.clothes_cat22",
                "Base.clothes_cat23",
                "Base.clothes_cat24",
                "Base.clothes_cat25",
                "Base.clothes_cat26",
                "Base.clothes_cat27",
                "Base.clothes_cat28",
                "Base.clothes_cat29",
                "Base.clothes_cat3",
                "Base.clothes_cat4",
                "Base.clothes_cat5",
                "Base.clothes_cat6",
                "Base.clothes_cat7",
                "Base.clothes_cat8",
                "Base.clothes_cat9",
                "Base.clothes_catM",
                "Base.clothes_catMb",
                "Base.clothes_picao_cat",
                "Base.picao_cat",
            },
        },
        ClothFeet = {
            items = {
                "Base.gaogen_cat1",
                "Base.shoe_cat1",
                "Base.shoe_cat10",
                "Base.shoe_cat11",
                "Base.shoe_cat12",
                "Base.shoe_cat14",
                "Base.shoe_cat15",
                "Base.shoe_cat16",
                "Base.shoe_cat17",
                "Base.shoe_cat18",
                "Base.shoe_cat19",
                "Base.shoe_cat2",
                "Base.shoe_cat20",
                "Base.shoe_cat24",
                "Base.shoe_cat28",
                "Base.shoe_cat29",
                "Base.shoe_cat4",
                "Base.shoe_cat5",
                "Base.shoe_cat6",
            },
        },
        ClothHead = {
            items = {
                "Base.Mask_cat13",
                "Base.hat_cat_1",
                "Base.hat_cat_17",
                "Base.hat_cat_2",
                "Base.hat_cat_28",
                "Base.hat_cat_3",
                "Base.head_cat11",
                "Base.head_cat5",
                "Base.head_cat6",
                "Base.head_junyong",
                "Base.headcat1",
            },
        },
        ClothLeg = {
            items = {
                "Base.beike_cat2",
                "Base.pant_cat1",
                "Base.pant_cat11",
                "Base.pant_cat11_w",
                "Base.pant_cat12",
                "Base.pant_cat12G",
                "Base.pant_cat15",
                "Base.pant_cat15_h",
                "Base.pant_cat16",
                "Base.pant_cat16_1",
                "Base.pant_cat18",
                "Base.pant_cat19",
                "Base.pant_cat2",
                "Base.pant_cat22",
                "Base.pant_cat24",
                "Base.pant_cat25",
                "Base.pant_cat26",
                "Base.pant_cat28",
                "Base.pant_cat29",
                "Base.pant_cat3",
                "Base.pant_cat4",
                "Base.pant_cat6",
                "Base.pant_cat7",
                "Base.pant_cat9",
            },
        },
        ClothMisc = {
            items = {
                "Base.JumpEggs",
                "Base.JumpEggs2",
                "Base.RuBag",
                "Base.RuBag1",
            },
        },
        ClothUnder = {
            items = {
                "Base.neiku_cat16",
                "Base.neiku_cat19",
                "Base.rutie20",
            },
        },
        FoodN = {
            items = {
                "Base.Maggots2",
            },
        },
        Junk = {
            items = {
                "Base.kuoyin",
            },
        },
        Misc = {
            items = {
                "Base.CompleteSoulGem",
                "Base.Gold_Coin",
                "Base.Golden_sand",
            },
        },
        WepMelee = {
            items = {
                "Base.Knife_cat",
            },
        },
    },
})
