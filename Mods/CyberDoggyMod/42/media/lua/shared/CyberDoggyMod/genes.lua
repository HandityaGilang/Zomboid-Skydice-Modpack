--[[
NOTE: remove the above comment brackets if using this template for your own mod!


local GeneDefinitions = AnimalGenomeDefinitions.genes

GeneDefinitions.swiftness = {
    minValue = 0.8,
    maxValue = 1.2,
    category = "mobility",
    displayName = "Swiftness",
    tooltipDescription = "Determines how quickly the CyberDoggy can move",
    affectsVisuals = false,
    inheritanceWeight = 1.0
}


GeneDefinitions.endurance = {
    minValue = 0.7,
    maxValue = 1.4,
    category = "mobility",
    displayName = "Endurance",
    tooltipDescription = "Affects endurance regeneration",
    affectsVisuals = false,
    inheritanceWeight = 1.0
}

 GeneDefinitions.haulingCapacity = {
    minValue = 0.7,
    maxValue = 1.4,
    category = "utility",
    displayName = "Hauling Capacity",
    tooltipDescription = "Determines maximum carry weight",
    affectsVisuals = false,
    inheritanceWeight = 0.8
}

GeneDefinitions.vitality = {
    minValue = 1.0,
    maxValue = 50.0,
    category = "combat",
    displayName = "Vitality",
    tooltipDescription = "Determines the CyberDoggy's health pool and survivability.",
    affectsVisuals = false,
    inheritanceWeight = 1.0
}

--]]