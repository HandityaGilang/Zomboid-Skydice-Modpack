--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: Smoker.
-- Cigarettes, packs, cartons and smoking devices -> Drugs; lighters and matches
-- -> Tool; loose tobacco, filters and foil -> Crafting; ashtray, empty packs and
-- burnt filters -> Junk.
--
-- Covers:
--   Smoker (Smoker) — https://steamcommunity.com/sharedfiles/filedetails/?id=2026976958
--
-- Mappings migrated from Better Sorting (Smoker_Items.lua).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.ModPacks = BSR.ModPacks or {}

table.insert(BSR.ModPacks, {
    name = "Smoker",
    mods = { "Smoker" },
    data = {
        Craft = {
            items = {
                "SM.SMBigPileTobacco",
                "SM.SMCrumpledBottle",
                "SM.SMCrumpledBottle2",
                "SM.SMCrumpledWithFoilCap",
                "SM.SMCrumpledWithFoilCap2",
                "SM.SMFilter",
                "SM.SMFoil",
                "SM.SMHandfulTobacco",
                "SM.SMPileTobacco",
                "SM.SMPinchTobacco",
                "SM.SMSmallHandfulTobacco",
                "SM.SMSmokingBlend",
                "SM.SMTobaccoPouches",
                "SM.SMUsedFoilLighter",
            },
        },
        Drugs = {
            items = {
                "SM.SMButt",
                "SM.SMButt2",
                "SM.SMCartonCigarettes",
                "SM.SMCartonCigarettesGold",
                "SM.SMCartonCigarettesLight",
                "SM.SMCartonCigarettesMenthol",
                "SM.SMCigarette",
                "SM.SMCigaretteLight",
                "SM.SMFullPack",
                "SM.SMFullPackGold",
                "SM.SMFullPackLight",
                "SM.SMFullPackMenthol",
                "SM.SMGum",
                "SM.SMHomemadeCigarette",
                "SM.SMHomemadeCigarette2",
                "SM.SMNicorette",
                "SM.SMNicoretteBox",
                "SM.SMPCigaretteGold",
                "SM.SMPCigaretteMenthol",
                "SM.SMPack",
                "SM.SMPackGold",
                "SM.SMPackLight",
                "SM.SMPackMenthol",
                "SM.SMSmokingBlendBong",
                "SM.SMSmokingBlendPipe",
                "SM.SMSmokingDeviceWithPinchTobacco",
                "SM.SMSmokingDeviceWithSmokingBlend",
            },
        },
        Junk = {
            items = {
                "SM.Ashtray",
                "SM.CarbonizedFilter",
                "SM.ChocolateFoil",
                "SM.EmptyMatchbox",
                "SM.SMEmptyPack",
                "SM.SMEmptyPackGold",
                "SM.SMEmptyPackLight",
                "SM.SMEmptyPackMenthol",
            },
        },
        Tool = {
            items = {
                "SM.Lighter",
                "SM.Matches",
                "SM.SMEmptyLighter",
            },
        },
    },
})
