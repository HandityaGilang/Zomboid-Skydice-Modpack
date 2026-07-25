require "ZScienceSkill/Data"

ZScienceSkill.Data.add({
    literatureReadOnce = {
        ["LabBooks.BkLaboratoryEquipment1"] = { Science = 30, Woodwork = 15 },         -- lab equipment assembly
        ["LabBooks.BkLaboratoryEquipment2"] = { Science = 30, Woodwork = 15 },         -- decorations assembly
        ["LabBooks.BkLaboratoryEquipment3"] = { Science = 30, Glassmaking = 30 },      -- glassware crafting
        ["LabBooks.BkVirologyCourses1"]     = { Science = 40, Doctor = 15 },           -- virology basics
        ["LabBooks.BkVirologyCourses2"]     = { Science = 50, Doctor = 30 },           -- advanced virology
        ["LabBooks.BkChemistryCourse"]      = { Science = 40, AppliedChemistry = 20 }, -- chemistry
    },

    specimens = {
        -- Human brains (autopsy)
        ["LabItems.HumanBrainLow"]            = { Science = 40, Doctor = 30 },
        ["LabItems.HumanBrainMid"]            = { Science = 50, Doctor = 40 },
        ["LabItems.HumanBrainHigh"]           = { Science = 60, Doctor = 50 },
        ["LabItems.RottenHumanBrain"]         = { Science = 20, Doctor = 10 },
        -- Human skulls & bones
        ["LabItems.LabHumanSkullWithBrain"]   = { Science = 50, Doctor = 40 },
        ["LabItems.LabHumanSkull"]            = { Science = 30, Doctor = 20 },
        ["LabItems.LabHumanSkullFixed"]       = { Science = 35, Doctor = 25 },
        ["LabItems.LabHumanSkullPart"]        = { Science = 15, Doctor = 10 },
        ["LabItems.LabHumanBoneLarge"]        = { Science = 20, Doctor = 15 },
        ["LabItems.LabRegularHumanBone"]      = { Science = 15, Doctor = 10 },
        ["LabItems.LabSmallRandomHumanBones"] = { Science = 10, Doctor = 5 },
        ["LabItems.LabHumanTeeth"]            = { Science = 10, Doctor = 10 },
        -- Blood samples
        ["LabItems.MatInfectedBlood"]         = { Science = 30, Doctor = 25 },
        ["LabItems.MatTaintedBlood"]          = { Science = 35, Doctor = 30 },
        -- Pills
        ["LabItems.CmpAlbuminPills"]          = { Science = 30, Doctor = 20 },
        -- Chemicals
        ["LabItems.CmpChlorineTablets"]       = { Science = 30, AppliedChemistry = 15 },
        ["LabItems.ChHydrochloricAcidCan"]    = { Science = 50, AppliedChemistry = 15 },
        ["LabItems.ChSulfuricAcidCan"]        = { Science = 50, AppliedChemistry = 15 },
        ["LabItems.ChSodiumHydroxideBag"]     = { Science = 40, AppliedChemistry = 15 },
        ["LabItems.ChAmmonia"]                = { Science = 40, AppliedChemistry = 15 },
        -- Other
        ["LabItems.LabFlask"]                 = { Science = 5, Glassmaking = 7.5 },
        ["LabItems.LabSyringeReusable"]       = { Science = 5, Doctor = 10 },
        ["LabItems.LabTestTube"]              = { Science = 5, Glassmaking = 7.5 },
        ["LabItems.MatShatteredGlass"]        = { Science = 5, Glassmaking = 5 },
    },

    fluids = {
        ["InfectedBlood"] = { Science =  50, Doctor = 50 },
    }
})
