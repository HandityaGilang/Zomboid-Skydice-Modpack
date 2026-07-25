require "ZScienceSkill/Data"

ZScienceSkill.Data.add({ specimens = {
    -- Electronics
    ["SupportCorps.ABHCDDrive"]             = { Science =  5, Hacking =  5, Electricity =  5 },
    ["SupportCorps.ABHMotherboard"]         = { Science = 15, Hacking = 15, Electricity = 10 },
    ["SupportCorps.ABHPonderPadLaptop"]     = { Science = 20, Hacking = 20, Electricity = 10 },
    ["SupportCorps.ABHPrinter"]             = { Science = 10, Hacking =  5, Electricity =  5 },
    ["SupportCorps.BatteryCharger"]         = { Science = 10, Electricity = 15 },
    ["SupportCorps.FloppyDiskBinder"]       = { Science =  1, Hacking =  5 },
    ["SupportCorps.InkCartridge"]           = { Science =  5, Hacking =  5 },
    ["SupportCorps.PortableGenerator"]      = { Science = 10, Electricity = 30 },

    -- Doctor
    ["SupportCorps.ActivatedCharcoalPills"] = { Science = 10, Doctor = 20 },
    ["SupportCorps.ColdaFluPills"]          = { Science = 10, Doctor = 20 },
    ["SupportCorps.OrthopedicCast"]         = { Science =  5, Doctor = 25 },
    ["SupportCorps.PillCapsule"]            = { Science =  5, Doctor =  5 },
    ["SupportCorps.PillCapsuleBag"]         = { Science =  5, Doctor =  5 },
    ["SupportCorps.Vicodin"]                = { Science = 10, Doctor = 20 },

    -- Cooking
    ["SupportCorps.Airlock"]                = { Science = 10, Cooking = 10 },
    ["SupportCorps.BottleCapper"]           = { Science = 10, Cooking = 10 },
    ["SupportCorps.GlassFermenter"]         = { Science = 10, Cooking = 15 },
    ["SupportCorps.PasturMachine"]          = { Science = 10, Cooking = 15 },
    ["SupportCorps.PortableCanningMachine"] = { Science = 10, Cooking = 15 },
    ["SupportCorps.YoghurtMaker"]           = { Science = 20, Cooking = 15 },

    -- misc
    ["SupportCorps.Handwarmer"]             = { Science = 10 },
    ["SupportCorps.WeedGrinder"]            = { Science =  5, Farming = 5 },
}})
