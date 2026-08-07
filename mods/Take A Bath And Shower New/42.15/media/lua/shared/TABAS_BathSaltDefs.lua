local TABAS_BathSaltDefs = {}


--[[
-- **** BATH BENEFITS ****
-- STATS
    "ANGER",
    "FATIGUE", -- reduces fatigue to 45.
    "FATIGUE_BASE", -- slowly reduces fatigue to 60.
    "SANITY",
    "STRESS",

-- body_damage
    "COLD",
    "BOREDOM",
    "UNHAPPINESS", -- reduces unhappiness.
    "INTOXICATION", -- drunkenness
    "INTOXICATION_INC",
    "HEALTH", -- in most cases, it won't be very effective because other factors will reduce your health.

-- character -- these give various pill effects.
    "SLEEP_SUSTAIN",
    "ANTI_DEPRESS_SUSTAIN",
    "PANIC_SUSTAIN",
    "PAIN_SUSTAIN",

-- body_parts
    "BURN",
    "FRACTURE",
    "PART_HEALTH",
    "ADDITIONAL_PAIN_INC",  -- if has injury, add additional pain.
    "ADDITIONAL_PAIN",
    "BITE",
    "CUT",
    "DEEP_WOUND",
    "SCRATCH",
    "STITCH",
    "WOUND_INFECTION",
    "STIFFNESS",

    "INJURIES_SUSTAIN", -- gain plantain
    "FRACTURE_SUSTAIN", -- gain comfrey
    "WOUND_INFECTION_SUSTAIN", -- gain garlic
]]

TABAS_BathSaltDefs.BenefitCategories = {
    ["BurnedTreatment"]     = {"BURN", "WOUND_INFECTION", "ADDITIONAL_PAIN"},
    ["CalmMind"]            = {"SANITY", "PANIC_SUSTAIN", "ANGER"},
    ["DrunkennessRelief"]   = {"INTOXICATION"},
    ["FatigueRecovery"]     = {"FATIGUE"},
    ["FeelingHappiness"]    = {"ANTI_DEPRESS_SUSTAIN", "BOREDOM", "STRESS", "PANIC_SUSTAIN"},
    ["FractureRecovery"]    = {"FRACTURE", "ADDITIONAL_PAIN"},
    ["GoodSleep"]           = {"SLEEP_SUSTAIN", "BOREDOM", "FATIGUE_BASE"},
    ["WoundRecovery"]       = {"BITE", "CUT", "DEEP_WOUND", "SCRATCH", "STITCH", "WOUND_INFECTION"},
    ["MuscleStrainRelief"]  = {"STIFFNESS"},
    ["PainRelief"]          = {"PAIN_SUSTAIN", "ADDITIONAL_PAIN"},
    ["PreventsCold"]        = {"COLD"},
    ["StressRelief"]        = {"STRESS"},
    -- ["FractureRecovery2"] = {"FRACTURE_SUSTAIN", "PAIN", "PART_HEALTH"},
    -- ["WoundRecovery2"]    = {"INJURIES_SUSTAIN", "WOUND_INFECTION_SUSTAIN", "PART_HEALTH"},
}

TABAS_BathSaltDefs.BathSaltTypes = {
    Lavender = {
        type = "Lavender",
        itemType = "TABAS.BathSalt_Lavender",
        fluidType = "BathSaltWater_Lavender",
        name = "IGUI_TABAS_BathSalt_Lavender",
        color = "MediumPurple", -- There refers to the ColorReference in script/fluids.
        benefitCategories = {"GoodSleep", "CalmMind", "StressRelief", "PainRelief"},
    },
    Citrus = {
        type = "Citrus",
        itemType = "TABAS.BathSalt_Citrus",
        fluidType = "BathSaltWater_Citrus",
        name = "IGUI_TABAS_BathSalt_Citrus",
        color = "PaleGoldenrod",
        benefitCategories = {"DrunkennessRelief", "PreventsCold", "StressRelief", "MuscleStrainRelief"},
    },
    Floral = {
        type = "Floral",
        itemType = "TABAS.BathSalt_Floral",
        fluidType = "BathSaltWater_Floral",
        name = "IGUI_TABAS_BathSalt_Floral",
        color = "LightPink",
        benefitCategories = {"FeelingHappiness", "BurnedTreatment", "CalmMind"}
    },
    Forest = {
        type = "Forest",
        itemType = "TABAS.BathSalt_Forest",
        fluidType = "BathSaltWater_Forest",
        name = "IGUI_TABAS_BathSalt_Forest",
        color = "ForestGreen",
        benefitCategories = {"FractureRecovery", "PainRelief", "MuscleStrainRelief"}
    },
    Herb = {
        type = "Herb",
        itemType = "TABAS.BathSalt_Herb",
        fluidType = "BathSaltWater_Herb",
        name = "IGUI_TABAS_BathSalt_Herb",
        color = "YellowGreen",
        benefitCategories = {"WoundRecovery", "PreventsCold"}
    },
    Rose = {
        type = "Rose",
        itemType = "TABAS.BathSalt_Rose",
        fluidType = "BathSaltWater_Rose",
        name = "IGUI_TABAS_BathSalt_Rose",
        color = "Crimson",
        benefitCategories = {"CalmMind", "FatigueRecovery", "PreventsCold"}
    }
}

function TABAS_BathSaltDefs.getDef(typeName)
    local _prefix = "BathSalt_"
    if not string.find(typeName, _prefix) then
        print("Bath Salt Defs: Invalid type name requested!")
        return
    end
    local bathsaltType = string.gsub(typeName, _prefix, "")
    if TABAS_BathSaltDefs.BathSaltTypes[bathsaltType] then
        return TABAS_BathSaltDefs.BathSaltTypes[bathsaltType]
    end
end

function TABAS_BathSaltDefs.getBathSaltBenefits(def)
    local result = {}

    for i=1, #def.benefitCategories do
        local category = def.benefitCategories[i]
        if TABAS_BathSaltDefs.BenefitCategories[category] then
            local benefits = TABAS_BathSaltDefs.BenefitCategories[category]
            for j=1, #benefits do
                local benefit = benefits[j]
                if not result[benefit] then
                    table.insert(result, benefit)
                end
            end
        end
    end
    return result
end

function TABAS_BathSaltDefs.getDisplayColor(typeName)
    local def = TABAS_BathSaltDefs.BathSaltTypes[typeName]
    if not def or not def.color then
        return nil
    end

    if def._displayColor == nil then
        local c = Colors.GetColorByName(def.color)
        if not c then
            return nil
        end

        def._displayColor = {
            r = c:getRedFloat(),
            g = c:getGreenFloat(),
            b = c:getBlueFloat(),
            a = 0.50,
        }
    end

    return def._displayColor
end

function TABAS_BathSaltDefs.getFluidType(typeName)
    local def = TABAS_BathSaltDefs.BathSaltTypes[typeName]
    return def and def.fluidType or nil
end

function TABAS_BathSaltDefs.getFluid(typeName)
    local fluidType = TABAS_BathSaltDefs.getFluidType(typeName)
    if not fluidType then
        return nil
    end
    return Fluid.Get(fluidType)
end

return TABAS_BathSaltDefs
