--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: Paint Your Ride.
-- https://steamcommunity.com/sharedfiles/filedetails/?id=2281256511
--
-- Automotive paints, tints, spray cans and the tools that apply them all sort to
-- Paint; the two vehicle-painting magazines to LitR.
--
-- Mappings migrated from Better Sorting v2.0.4 (PaintYourRide_Items.lua).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.ModPacks = BSR.ModPacks or {}

table.insert(BSR.ModPacks, {
    name = "PaintYourRide",
    mods = { "PaintYourRide" },
    data = {
        LitR = {
            items = {
                "PaintYourRide.VehiclePaintingMag1",
                "PaintYourRide.VehiclePaintingMag2",
            },
        },
        Paint = {
            items = {
                "PaintYourRide.AutomotivePaintBottleEmpty",
                "PaintYourRide.AutomotivePaintBucketEmpty",
                "PaintYourRide.AutomotivePaintWhite",
                "PaintYourRide.AutomotiveSprayCanEmpty",
                "PaintYourRide.AutomotiveSprayPaintBlack",
                "PaintYourRide.AutomotiveSprayPaintBlue",
                "PaintYourRide.AutomotiveSprayPaintBlueNavy",
                "PaintYourRide.AutomotiveSprayPaintBlueNeon",
                "PaintYourRide.AutomotiveSprayPaintBlueOlympic",
                "PaintYourRide.AutomotiveSprayPaintBrownDarkChocolate",
                "PaintYourRide.AutomotiveSprayPaintBrownRusty",
                "PaintYourRide.AutomotiveSprayPaintGreen",
                "PaintYourRide.AutomotiveSprayPaintGreenArmy",
                "PaintYourRide.AutomotiveSprayPaintGreenForest",
                "PaintYourRide.AutomotiveSprayPaintGreenNeon",
                "PaintYourRide.AutomotiveSprayPaintGrey",
                "PaintYourRide.AutomotiveSprayPaintGreySteel",
                "PaintYourRide.AutomotiveSprayPaintOrangeTangerine",
                "PaintYourRide.AutomotiveSprayPaintPinkBubbleGum",
                "PaintYourRide.AutomotiveSprayPaintPinkGlamorous",
                "PaintYourRide.AutomotiveSprayPaintRed",
                "PaintYourRide.AutomotiveSprayPaintRedBurgundy",
                "PaintYourRide.AutomotiveSprayPaintRedCandyApple",
                "PaintYourRide.AutomotiveSprayPaintVioletGrape",
                "PaintYourRide.AutomotiveSprayPaintVioletIndigo",
                "PaintYourRide.AutomotiveSprayPaintWhite",
                "PaintYourRide.AutomotiveSprayPaintYellow",
                "PaintYourRide.AutomotiveSprayPaintYellowNeon",
                "PaintYourRide.AutomotiveSprayPaintYellowTuscany",
                "PaintYourRide.AutomotiveSprayPrimer",
                "PaintYourRide.AutomotiveTintPaintBlack",
                "PaintYourRide.AutomotiveTintPaintBlue",
                "PaintYourRide.AutomotiveTintPaintCyan",
                "PaintYourRide.AutomotiveTintPaintGreen",
                "PaintYourRide.AutomotiveTintPaintMagenta",
                "PaintYourRide.AutomotiveTintPaintRed",
                "PaintYourRide.AutomotiveTintPaintYellow",
                "PaintYourRide.BoxAutomotivePaintSprays1",
                "PaintYourRide.BoxAutomotivePaintSprays2",
                "PaintYourRide.BoxAutomotivePaintSprays3",
                "PaintYourRide.BoxAutomotivePaintSprays4",
                "PaintYourRide.BoxAutomotivePaintTints",
                "PaintYourRide.CataloguePaintSpray",
                "PaintYourRide.CataloguePaintTints",
                "PaintYourRide.SprayGun",
                "PaintYourRide.WireBrush",
            },
        },
    },
})
