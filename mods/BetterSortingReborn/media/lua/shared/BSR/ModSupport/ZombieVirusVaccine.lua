--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: Zombie Virus Vaccine.
-- https://steamcommunity.com/sharedfiles/filedetails/?id=2512119000
--
-- One guard, three mod IDs in the original (the base mod plus Dr Reaper's
-- single- and multiplayer re-uploads); they ship the same LabBooks/LabItems
-- modules, so they stay one pack.
--
-- Mappings migrated from Better Sorting (ZombieVirusVaccine_Items.lua): 73
-- lines, no repeats -> 73 items, all in the mod's own modules. The original's
-- opinionated split is kept as-is: lab furniture, glassware and syringes ->
-- Tool, blood/chemical intermediates -> Craft, the finished vaccine and cure
-- syringes -> Med.
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.ModPacks = BSR.ModPacks or {}

table.insert(BSR.ModPacks, {
    name = "ZombieVirusVaccine",
    mods = { "DemoniusZombieVirusVaccine", "VaccinDrReapers", "VaccinDrReapersMP" },
    data = {
        Craft = {
            items = {
                "LabItems.ChAmmonia",
                "LabItems.ChHydrochloricAcidCan",
                "LabItems.ChSodiumHydroxideBag",
                "LabItems.ChSulfuricAcidCan",
                "LabItems.CmpFlaskWithAmmoniumSulfate",
                "LabItems.CmpFlaskWithBloodCells",
                "LabItems.CmpFlaskWithBloodPlasma",
                "LabItems.CmpFlaskWithHydrogenPeroxide",
                "LabItems.CmpFlaskWithLeukocytes",
                "LabItems.CmpFlaskWithSodiumHypochlorite",
                "LabItems.CmpSyringeReusableWithBlood",
                "LabItems.CmpSyringeReusableWithTaintedBlood",
                "LabItems.CmpSyringeWithBlood",
                "LabItems.CmpSyringeWithTaintedBlood",
                "LabItems.CmpTestTubeWithAntibodies",
                "LabItems.CmpTestTubeWithInfectedBlood",
                "LabItems.CmpTestTubeWithTaintedBlood",
                "LabItems.FrnGolgIngot",
                "LabItems.FrnGolgNugget",
                "LabItems.FrnIngotMold",
                "LabItems.FrnSilverIngot",
                "LabItems.FrnSilverNugget",
                "LabItems.MatInfectedBlood",
                "LabItems.MatShatteredGlass",
                "LabItems.MatTaintedBlood",
            },
        },
        LitR = {
            items = {
                "LabBooks.BkChemistryCourse",
                "LabBooks.BkLaboratoryEquipment1",
                "LabBooks.BkVirologyCourses1",
            },
        },
        Med = {
            items = {
                "LabItems.CmpAlbuminPills",
                "LabItems.CmpSyringeReusableWithAdvancedVaccine",
                "LabItems.CmpSyringeReusableWithCure",
                "LabItems.CmpSyringeReusableWithPlainVaccine",
                "LabItems.CmpSyringeReusableWithQualityVaccine",
                "LabItems.CmpSyringeWithAdvancedVaccine",
                "LabItems.CmpSyringeWithCure",
                "LabItems.CmpSyringeWithPlainVaccine",
                "LabItems.CmpSyringeWithQualityVaccine",
            },
        },
        Tool = {
            items = {
                "LabItems.CmpChlorineTablets",
                "LabItems.LabCentrifuge",
                "LabItems.LabChemistrySet",
                "LabItems.LabChromatograph",
                "LabItems.LabDecorCaduceus",
                "LabItems.LabDecorSkeleton",
                "LabItems.LabDecorVirusModel",
                "LabItems.LabDecorWhiteboard",
                "LabItems.LabEasel",
                "LabItems.LabFlask",
                "LabItems.LabFlaskDirty",
                "LabItems.LabFlaskWater",
                "LabItems.LabGarbageBagWithRemains",
                "LabItems.LabMicroscope",
                "LabItems.LabMuffleFurnace",
                "LabItems.LabNeonSignPharmacy",
                "LabItems.LabNeonSignPizza",
                "LabItems.LabPlasticBagWithRemains",
                "LabItems.LabPosterBiohazard",
                "LabItems.LabPosterHumanBrain",
                "LabItems.LabPosterPeriodicTable",
                "LabItems.LabPosterSexyNurse",
                "LabItems.LabPosterWashHands",
                "LabItems.LabSpectrometer",
                "LabItems.LabSyringe",
                "LabItems.LabSyringePack",
                "LabItems.LabSyringeReusable",
                "LabItems.LabSyringeReusableUsed",
                "LabItems.LabSyringeUsed",
                "LabItems.LabTestResultNegative",
                "LabItems.LabTestResultPositive",
                "LabItems.LabTestTube",
                "LabItems.LabTestTubeDirty",
                "LabItems.LabWorkbench",
                "LabItems.Mov_Morge1",
                "LabItems.Mov_Morge2",
            },
        },
    },
})
