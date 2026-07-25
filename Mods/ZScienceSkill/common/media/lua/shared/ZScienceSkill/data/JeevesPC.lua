require "ZScienceSkill/Data"

ZScienceSkill.Data.add({ specimens = {
    ["JeevesPC.LowEndRAM"]        = { Science = 20, Hacking = 10 },
    ["JeevesPC.LowEndVideoCard"]  = { Science = 20, Hacking = 10 },
    ["JeevesPC.SolderingIron"]    = { Science = 10, Electricity = 20 },

    ["JeevesPC.BrokenPC"]         = { Science = 20, Hacking = 20, Electricity = 20 },
    ["JeevesPC.PersonalComputer"] = { Science = 30, Hacking = 30, Electricity = 30 },
}})

ZScienceSkill.Data.add({ literatureReadOnce = {
    ["JeevesPC.PCWorldPDA"]       = { Science = 20, Hacking = 20, Electricity = 20 },
}})
