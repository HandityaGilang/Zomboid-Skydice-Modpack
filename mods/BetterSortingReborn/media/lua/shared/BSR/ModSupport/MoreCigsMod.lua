--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: More Cigs (+ Greenfire).
-- Everything smokeable, and the paraphernalia that goes with it, -> Drugs; the
-- four cannabis/tobacco seed items -> Survival - Farming.
--
-- Covers (one guard, three mod IDs, in the original):
--   MoreCigsMod / MCMGreenfire / MCMLitter — https://steamcommunity.com/sharedfiles/filedetails/?id=2396329386
--
-- Mappings migrated from Better Sorting (MoreCigsMod_Items.lua): 81 lines, of
-- which 7 are exact repeats (the Greenfire carton/tobacco/seed block is listed
-- twice with identical categories) -> 74 items. The one commented-out upstream
-- line (Greenfire.Marshmallows -> FoodN) is not migrated; the generic food rule
-- covers it.
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.ModPacks = BSR.ModPacks or {}

table.insert(BSR.ModPacks, {
    name = "MoreCigsMod",
    mods = { "MoreCigsMod", "MCMGreenfire", "MCMLitter" },
    data = {
        Drugs = {
            items = {
                "Cigs.CardboardBox",
                "Cigs.CigsButtGold",
                "Cigs.CigsButtLite",
                "Cigs.CigsButtMent",
                "Cigs.CigsButtReg",
                "Cigs.CigsCartonGold",
                "Cigs.CigsCartonGoldEmpty",
                "Cigs.CigsCartonLite",
                "Cigs.CigsCartonLiteEmpty",
                "Cigs.CigsCartonMent",
                "Cigs.CigsCartonMentEmpty",
                "Cigs.CigsCartonReg",
                "Cigs.CigsCartonRegEmpty",
                "Cigs.CigsCaseGold",
                "Cigs.CigsCaseLite",
                "Cigs.CigsCaseMent",
                "Cigs.CigsCaseReg",
                "Cigs.CigsCigaretteGold",
                "Cigs.CigsCigaretteLite",
                "Cigs.CigsCigaretteMent",
                "Cigs.CigsCigaretteReg",
                "Cigs.CigsClosedPackGold",
                "Cigs.CigsClosedPackLite",
                "Cigs.CigsClosedPackMent",
                "Cigs.CigsClosedPackReg",
                "Cigs.CigsEmptyPackGold",
                "Cigs.CigsEmptyPackLite",
                "Cigs.CigsEmptyPackMent",
                "Cigs.CigsEmptyPackReg",
                "Cigs.CigsFilterGold",
                "Cigs.CigsFilterLite",
                "Cigs.CigsFilterMent",
                "Cigs.CigsFilterReg",
                "Cigs.CigsOpenPackGold",
                "Cigs.CigsOpenPackLite",
                "Cigs.CigsOpenPackMent",
                "Cigs.CigsOpenPackReg",
                "Cigs.CigsSpawnPackGold",
                "Cigs.CigsSpawnPackLite",
                "Cigs.CigsSpawnPackMent",
                "Greenfire.BluntCigar",
                "Greenfire.BluntWrap",
                "Greenfire.Bong",
                "Greenfire.Cannabis",
                "Greenfire.CigarLeaf",
                "Greenfire.DryBTobacco",
                "Greenfire.FreshBTobacco",
                "Greenfire.GFCigar",
                "Greenfire.GFCigarette",
                "Greenfire.GFCigaretteCarton",
                "Greenfire.GFCigaretteCase",
                "Greenfire.GFCigarettes",
                "Greenfire.GFEmptyCigaretteCarton",
                "Greenfire.GFUsedCigaretteCarton",
                "Greenfire.HalfBluntCigar",
                "Greenfire.HalfCigar",
                "Greenfire.NiceCrispiez",
                "Greenfire.NiceCrispiezPan",
                "Greenfire.PipeTobaccoBag",
                "Greenfire.RollingPapers",
                "Greenfire.SBrownie",
                "Greenfire.SBrownieBatter",
                "Greenfire.SBrowniePan",
                "Greenfire.SCrispyMix",
                "Greenfire.SCrispySauce",
                "Greenfire.SmokingPipe",
                "Greenfire.Tobacco",
                "Greenfire.TobaccoBong",
                "Greenfire.TobaccoPipe",
                "Greenfire.UncuredCigar",
            },
        },
        SurFarm = {
            items = {
                "Greenfire.CannabisBagSeed",
                "Greenfire.CannabisSeed",
                "Greenfire.TobaccoBagSeed",
                "Greenfire.TobaccoSeed",
            },
        },
    },
})
