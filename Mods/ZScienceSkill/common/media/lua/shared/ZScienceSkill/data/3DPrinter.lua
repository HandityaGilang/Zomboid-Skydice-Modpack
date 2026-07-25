-- 3DPrinter mod integration
require "ZScienceSkill/Data"

local filamentXP = 10
ZScienceSkill.Data.add({
    specimens = {
        -- Filaments (polymer science / materials science)
        ["Printer3D.Filament3D_Blue"]   = filamentXP,
        ["Printer3D.Filament_Green"]    = filamentXP,
        ["Printer3D.Filament_Yellow"]   = filamentXP,
        ["Printer3D.Filament_Orange"]   = filamentXP,
        ["Printer3D.Filament_Violet"]   = filamentXP,
        ["Printer3D.Filament_Brown"]    = filamentXP,

        -- printers
        ["Printer3D.Printer3DPortable"] = { Science = 20, Electricity = 20 },
        ["Printer3D.Printer3D"]         = { Science = 20, Electricity = 20 },
        ["Printer3D.MachineRecicler"]   = { Science = 25, Electricity = 10, Maintenance = 10 },
    },

    literatureReadOnce = {
        -- Design blueprints (technical documentation)
        ["Printer3D.Design_Basics"]     = 10, -- 14 pages
        ["Printer3D.Design_Industrial"] = 20, -- 28 pages
        ["Printer3D.Design_Heavy"]      = 30, -- 42 pages
        ["Printer3D.Design_Advanced"]   = 30, -- 64 pages
        ["Printer3D.Design_Reclicler"]  = 30, -- 64 pages, recycler blueprints
    },
})
