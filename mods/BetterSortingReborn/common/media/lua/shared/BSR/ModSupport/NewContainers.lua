--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: New Containers.
-- https://steamcommunity.com/sharedfiles/filedetails/?id=2917951452
--
-- Boxes, totes, crates, jars and cans sort to Container; the forage basket is
-- worn on the back (ClothBack) and the two forage pouches are bags (ClothBag);
-- the filled water jug is a beverage (FoodB) while its empty twin is a container.
--
-- Mappings migrated from Better Sorting v2.0.4 (NewContainers_Items.lua), with
-- the original's "Cont" key remapped to "Container".
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.ModPacks = BSR.ModPacks or {}

table.insert(BSR.ModPacks, {
    name = "NewContainers",
    mods = { "newcontainers" },
    data = {
        ClothBack = {
            items = {
                "newcontainers.basket_forage",
            },
        },
        ClothBag = {
            items = {
                "newcontainers.foragepouch_back",
                "newcontainers.foragepouch_front",
            },
        },
        Container = {
            items = {
                "newcontainers.ammocan",
                "newcontainers.ammocan30",
                "newcontainers.ammocan50",
                "newcontainers.basket",
                "newcontainers.canvastote",
                "newcontainers.carcrateb",
                "newcontainers.carcrateg",
                "newcontainers.carcrateo",
                "newcontainers.carcrater",
                "newcontainers.carcratey",
                "newcontainers.cardboard_large",
                "newcontainers.cardboard_medium",
                "newcontainers.cardboard_small",
                "newcontainers.cardboardbox",
                "newcontainers.coffeecan",
                "newcontainers.coffeecan_open",
                "newcontainers.cookiejar",
                "newcontainers.cutleryroll",
                "newcontainers.donutbox",
                "newcontainers.fakerock",
                "newcontainers.jewelrybox",
                "newcontainers.jugempty",
                "newcontainers.kindlingbox",
                "newcontainers.lockbox",
                "newcontainers.piggybank",
                "newcontainers.pizzabox",
                "newcontainers.pizzaboxpw",
                "newcontainers.plastictote_large",
                "newcontainers.plastictote_medium",
                "newcontainers.plastictote_small",
                "newcontainers.roadsidekit",
                "newcontainers.shoebox",
                "newcontainers.shoppingbasket",
                "newcontainers.spicerack",
                "newcontainers.tacklebox",
                "newcontainers.tissuebox",
                "newcontainers.travelkit",
                "newcontainers.trunkorganizer",
            },
        },
        FoodB = {
            items = {
                "newcontainers.jugfull",
            },
        },
    },
})
