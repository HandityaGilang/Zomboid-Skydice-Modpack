require "ZScienceSkill/Data"

ZScienceSkill.Data.add({ specimens = {
    ["EnergyRouting.Aerogenerador"]         = { Science = 20, Electricity = 20 },
    ["EnergyRouting.BatteryTank"]           = { Science = 20, Electricity = 20 },
    ["EnergyRouting.SolarPanel"]            = { Science = 20, Electricity = 20 },
    ["EnergyRouting.SolarPanel_Individual"] = { Science = 20, Electricity = 20, key = "EnergyRouting.SolarPanel" },
    ["EnergyRouting.SolarPanelHorizontal"]  = { Science = 20, Electricity = 20, key = "EnergyRouting.SolarPanel" },
    ["EnergyRouting.TurbinaHidraulica"]     = { Science = 20, Electricity = 20 },
    ["EnergyRouting.TurbineHelice"]         = { Science = 10, Electricity = 10, Mechanics = 10 },
    ["EnergyRouting.WindBattery"]           = { Science = 20, Electricity = 20 },
    ["EnergyRouting.WindTurbineMotor"]      = { Science = 20, Electricity = 20 },
    ["EnergyRouting.WireTransferEnergy"]    = { Science = 10, Electricity = 10 },
}})
