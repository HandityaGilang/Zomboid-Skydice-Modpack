require "ZScienceSkill/Data"

ZScienceSkill.Data.add({ specimens = {
    ["TankWater.CleaningTablets"]       = { Science = 15, Maintenance = 15 },
    ["TankWater.FilterCartridge"]       = { Science = 10, Maintenance = 15 },
    ["TankWater.MotorPump"]             = { Science = 10, Electricity = 10 },
    ["TankWater.PumpTransferHose"]      = { Science =  5, Maintenance = 10 },
    ["TankWater.PumpTransferHoseLarge"] = { Science =  5, Maintenance = 10, key = "TankWater.PumpTransferHose" },
}})
