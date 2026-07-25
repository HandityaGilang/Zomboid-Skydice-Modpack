require "ZScienceSkill/Data"

ZScienceSkill.Data.add({
    literatureReadOnce = {
        ["ProfessionItems.DiaryPage1"] = 5,
        ["ProfessionItems.DiaryPage2"] = 5,
        ["ProfessionItems.DiaryPage3"] = 5,
        ["ProfessionItems.DiaryPage4"] = 5,
        ["ProfessionItems.DiaryPage5"] = 5,
        ["ProfessionItems.DiaryPage6"] = 15, -- contains actual lab procedures
    }
})

-- Base medical stuff intern starts with already researched, already has Science level 2
ZScienceSkill.Data.profPreResearchedSpecimens["rlp:labintern"] = {
    "Base.Antibiotics", "Base.Pills", "Base.PillsAntiDep", "Base.PillsBeta",
    "Base.PillsSleepingTablets", "Base.PillsVitamins",
    "Base.Stethoscope", "Base.SutureNeedle", "Base.TongueDepressor",

    "Fluid:Blood",

    "ProfessionItems.DiaryPage1", "ProfessionItems.DiaryPage2", "ProfessionItems.DiaryPage3",
    "ProfessionItems.DiaryPage4", "ProfessionItems.DiaryPage5", "ProfessionItems.DiaryPage6",

    "LabItems.LabFlask", "LabItems.LabSyringeReusable", "LabItems.LabTestTube", "LabItems.MatTaintedBlood",
}
