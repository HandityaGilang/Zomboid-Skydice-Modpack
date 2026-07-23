MDFT = MDFT or {}
MDFT.MoreDescription = MDFT.MoreDescription or {}

local function sotoAppend(key, lines)
    if not MDFT.MoreDescription[key] then MDFT.MoreDescription[key] = {} end
    for _, line in ipairs(lines) do table.insert(MDFT.MoreDescription[key], line) end
end

-- SOTO traits
sotoAppend("adrenalinejunkie2", {
        {text = "UI_trait_moredesc_soto_prof"},
        {text = "UI_trait_moredesc_soto_rework"},
        {text = "UI_trait_moredesc_soto_swap_adrenalinejunkie"}
})

sotoAppend("advancedforaging", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_advancedforaging"}
})

sotoAppend("agile", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_earnable_nimble"}
})

sotoAppend("alcoholic", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_alcoholic"}
})

sotoAppend("allergic", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_allergic"}
})

sotoAppend("animalfriend", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_animalfriend_forage"}
})

sotoAppend("animalfriend2", {
        {text = "UI_trait_moredesc_soto_prof"},
        {text = "UI_trait_moredesc_soto_rework"},
        {text = "UI_trait_moredesc_soto_swap_animalfriend"}
})

sotoAppend("automechanic", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_earnable_mechanics"}
})

sotoAppend("bludgeoner", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_earnable_smallblunt"}
})

sotoAppend("breakintechnique", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_breakintechnique"}
})

sotoAppend("breathingtechnique", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_breathing_vehicle"}
})

sotoAppend("breathingtechnique2", {
        {text = "UI_trait_moredesc_soto_prof"},
        {text = "UI_trait_moredesc_soto_rework"},
        {text = "UI_trait_moredesc_soto_swap_breathingtechnique"}
})

sotoAppend("calmminded", {
        {text = "UI_trait_moredesc_soto_new"}
})

sotoAppend("chronicmigraine", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_chronicmigraine"}
})

sotoAppend("commercialdriver", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_commercialdriver"}
})

sotoAppend("cruelty", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_cruelty"}
})

sotoAppend("cruelty2", {
        {text = "UI_trait_moredesc_soto_prof"},
        {text = "UI_trait_moredesc_soto_rework"},
        {text = "UI_trait_moredesc_soto_swap_cruelty"}
})

sotoAppend("culinary", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_culinary_note"}
})

sotoAppend("cutter", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_earnable_axe"},
        {text = "UI_trait_moredesc_soto_cutter_chop"}
})

sotoAppend("cuttingtools", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_cuttingtools"}
})

sotoAppend("depressive", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_depressive"}
})

sotoAppend("desensitized2", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_desensitized2"}
})

sotoAppend("dextrous2", {
        {text = "UI_trait_moredesc_soto_prof"},
        {text = "UI_trait_moredesc_soto_rework"},
        {text = "UI_trait_moredesc_soto_swap_dextrous"}
})

sotoAppend("durability", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_earnable_maintenance"}
})

sotoAppend("eagleeyed2", {
        {text = "UI_trait_moredesc_soto_prof"},
        {text = "UI_trait_moredesc_soto_rework"},
        {text = "UI_trait_moredesc_soto_swap_eagleeyed"}
})

sotoAppend("electricalmechanic", {
        {text = "UI_trait_moredesc_soto_new"}
})

sotoAppend("entomologist", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_entomologist_forage"}
})

sotoAppend("expshooter", {
        {text = "UI_trait_moredesc_soto_new"}
})

sotoAppend("fastmetabolism", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_fastmeta_1"},
        {text = "UI_trait_moredesc_soto_fastmeta_2"}
})

sotoAppend("fastreader2", {
        {text = "UI_trait_moredesc_soto_prof"},
        {text = "UI_trait_moredesc_soto_rework"},
        {text = "UI_trait_moredesc_soto_swap_fastreader"}
})

sotoAppend("fearofthedark", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_fearofthedark"}
})

sotoAppend("firstaid2", {
        {text = "UI_trait_moredesc_soto_prof"},
        {text = "UI_trait_moredesc_soto_rework"},
        {text = "UI_trait_moredesc_soto_swap_firstaid"}
})

sotoAppend("forager", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_forager_forage"}
})

sotoAppend("formeralcoholic", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_formeralcoholic"}
})

sotoAppend("formerscout2", {
        {text = "UI_trait_moredesc_soto_prof"},
        {text = "UI_trait_moredesc_soto_rework"},
        {text = "UI_trait_moredesc_soto_swap_formerscout"}
})

sotoAppend("formersmoker", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_formersmoker"}
})

sotoAppend("gardener2", {
        {text = "UI_trait_moredesc_soto_prof"},
        {text = "UI_trait_moredesc_soto_rework"},
        {text = "UI_trait_moredesc_soto_swap_gardener"}
})

sotoAppend("generatorexpert", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_generatorexpert_xp"}
})

sotoAppend("generatorexpert2", {
        {text = "UI_trait_moredesc_soto_prof"},
        {text = "UI_trait_moredesc_soto_rework"},
        {text = "UI_trait_moredesc_soto_swap_generatorexpert"}
})

sotoAppend("glassblower", {
        {text = "UI_trait_moredesc_soto_new"}
})

sotoAppend("graceful2", {
        {text = "UI_trait_moredesc_soto_prof"},
        {text = "UI_trait_moredesc_soto_rework"},
        {text = "UI_trait_moredesc_soto_swap_graceful"}
})

sotoAppend("gymnast2", {
        {text = "UI_trait_moredesc_soto_prof"},
        {text = "UI_trait_moredesc_soto_rework"},
        {text = "UI_trait_moredesc_soto_swap_gymnast"}
})

sotoAppend("handy2", {
        {text = "UI_trait_moredesc_soto_prof"},
        {text = "UI_trait_moredesc_soto_rework"},
        {text = "UI_trait_moredesc_soto_swap_handy"}
})

sotoAppend("herbalist2", {
        {text = "UI_trait_moredesc_soto_prof"},
        {text = "UI_trait_moredesc_soto_rework"},
        {text = "UI_trait_moredesc_soto_swap_herbalist"}
})

sotoAppend("highsweaty", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_highsweaty"}
})

sotoAppend("hunter2", {
        {text = "UI_trait_moredesc_soto_prof"},
        {text = "UI_trait_moredesc_soto_rework"},
        {text = "UI_trait_moredesc_soto_swap_hunter"}
})

sotoAppend("improvedforaging", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_improvedforaging"}
})

sotoAppend("inconspicuous2", {
        {text = "UI_trait_moredesc_soto_prof"},
        {text = "UI_trait_moredesc_soto_rework"},
        {text = "UI_trait_moredesc_soto_swap_inconspicuous"}
})

sotoAppend("inventive2", {
        {text = "UI_trait_moredesc_soto_prof"},
        {text = "UI_trait_moredesc_soto_rework"},
        {text = "UI_trait_moredesc_soto_swap_inventive"}
})

sotoAppend("keenhearing2", {
        {text = "UI_trait_moredesc_soto_prof"},
        {text = "UI_trait_moredesc_soto_rework"},
        {text = "UI_trait_moredesc_soto_swap_keenhearing"}
})

sotoAppend("knappingbasics", {
        {text = "UI_trait_moredesc_soto_new"}
})

sotoAppend("knifer", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_earnable_smallblade"}
})

sotoAppend("larkperson", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_larkperson"}
})

sotoAppend("lesssweaty", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_lesssweaty"}
})

sotoAppend("lifelonglearner", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_lifelonglearner"}
})

sotoAppend("lightfooted", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_earnable_lightfoot"}
})

sotoAppend("liquidblood", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_liquidblood"}
})

sotoAppend("marathonrunner", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_marathonrunner_scale"}
})

sotoAppend("masonry", {
        {text = "UI_trait_moredesc_soto_new"}
})

sotoAppend("metalwelder", {
        {text = "UI_trait_moredesc_soto_new"}
})

sotoAppend("mushroompicker", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_mushroom_forage"}
})

sotoAppend("nightvision2", {
        {text = "UI_trait_moredesc_soto_prof"},
        {text = "UI_trait_moredesc_soto_rework"},
        {text = "UI_trait_moredesc_soto_swap_nightvision"}
})

sotoAppend("optimistic", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_optimistic"}
})

sotoAppend("organized2", {
        {text = "UI_trait_moredesc_soto_prof"},
        {text = "UI_trait_moredesc_soto_rework"},
        {text = "UI_trait_moredesc_soto_swap_organized"}
})

sotoAppend("outdoorsman2", {
        {text = "UI_trait_moredesc_soto_prof"},
        {text = "UI_trait_moredesc_soto_rework"},
        {text = "UI_trait_moredesc_soto_swap_outdoorsman"}
})

sotoAppend("owlperson", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_owlperson"}
})

sotoAppend("pacifist2", {
        {text = "UI_trait_moredesc_soto_prof"},
        {text = "UI_trait_moredesc_soto_rework"},
        {text = "UI_trait_moredesc_soto_swap_pacifist"}
})

sotoAppend("panicattacks", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_panicattacks"}
})

sotoAppend("potter", {
        {text = "UI_trait_moredesc_soto_new"}
})

sotoAppend("refueller", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_refueller"}
})

sotoAppend("sensitivedigestion", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_sensitivedigestion"}
})

sotoAppend("shooter", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_earnable_aiming"}
})

sotoAppend("slack", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_slack_2"}
})

sotoAppend("slaughterer", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_slaughterer_note"}
})

sotoAppend("slaughterer2", {
        {text = "UI_trait_moredesc_soto_prof"},
        {text = "UI_trait_moredesc_soto_rework"},
        {text = "UI_trait_moredesc_soto_swap_slaughterer"}
})

sotoAppend("slowmetabolism", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_slowmeta_1"},
        {text = "UI_trait_moredesc_soto_slowmeta_2"}
})

sotoAppend("sneaky", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_earnable_sneak"}
})

sotoAppend("spearman", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_earnable_spear"}
})

sotoAppend("speeddemon2", {
        {text = "UI_trait_moredesc_soto_prof"},
        {text = "UI_trait_moredesc_soto_rework"},
        {text = "UI_trait_moredesc_soto_swap_speeddemon"}
})

sotoAppend("strongback", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_strongback_detail"}
})

sotoAppend("strongback2", {
        {text = "UI_trait_moredesc_soto_prof"},
        {text = "UI_trait_moredesc_soto_rework"},
        {text = "UI_trait_moredesc_soto_swap_strongback"}
})

sotoAppend("stronggrip", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_stronggrip"}
})

sotoAppend("stronggrip2", {
        {text = "UI_trait_moredesc_soto_prof"},
        {text = "UI_trait_moredesc_soto_stronggrip2_note"}
})

sotoAppend("swordsman", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_earnable_longblade"}
})

sotoAppend("taut", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_taut_2"}
})

sotoAppend("thickblood", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_thickblood"}
})

sotoAppend("tireless", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_tireless"}
})

sotoAppend("tireless2", {
        {text = "UI_trait_moredesc_soto_prof"},
        {text = "UI_trait_moredesc_soto_rework"},
        {text = "UI_trait_moredesc_soto_swap_tireless"}
})

sotoAppend("tracker", {
        {text = "UI_trait_moredesc_soto_new"}
})

sotoAppend("trapper", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_trapper_forage"}
})

sotoAppend("usedtocorpses", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_usedtocorpses"}
})

sotoAppend("weakback", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_weakback_detail"}
})

sotoAppend("woodworker", {
        {text = "UI_trait_moredesc_soto_new"},
        {text = "UI_trait_moredesc_soto_earnable_woodwork"}
})

-- SOTO reworked vanilla traits
sotoAppend("obese", {
        {text = "UI_trait_moredesc_soto_obese_wetness"}
})

sotoAppend("pacifist", {
        {text = "UI_trait_moredesc_soto_pacifist_sandbox"}
})

-- SOTO professions
sotoAppend("animalcontrolofficer", {
        {text = "UI_trait_moredesc_soto_prof_soto"}
})

sotoAppend("botanist", {
        {text = "UI_trait_moredesc_soto_prof_soto"}
})

sotoAppend("butcher", {
        {text = "UI_trait_moredesc_soto_prof_soto"}
})

sotoAppend("campcounselor", {
        {text = "UI_trait_moredesc_soto_prof_soto"}
})

sotoAppend("criminal", {
        {text = "UI_trait_moredesc_soto_prof_soto"}
})

sotoAppend("dancer", {
        {text = "UI_trait_moredesc_soto_prof_soto"}
})

sotoAppend("deliveryman", {
        {text = "UI_trait_moredesc_soto_prof_soto"}
})

sotoAppend("demolitionworker", {
        {text = "UI_trait_moredesc_soto_prof_soto"}
})

sotoAppend("detective", {
        {text = "UI_trait_moredesc_soto_prof_soto"}
})

sotoAppend("dragracer", {
        {text = "UI_trait_moredesc_soto_prof_soto"}
})

sotoAppend("gasstationoperator", {
        {text = "UI_trait_moredesc_soto_prof_soto"}
})

sotoAppend("gravedigger", {
        {text = "UI_trait_moredesc_soto_prof_soto"}
})

sotoAppend("huntsman", {
        {text = "UI_trait_moredesc_soto_prof_soto"}
})

sotoAppend("janitor", {
        {text = "UI_trait_moredesc_soto_prof_soto"}
})

sotoAppend("junkyardworker", {
        {text = "UI_trait_moredesc_soto_prof_soto"}
})

sotoAppend("lifeguard", {
        {text = "UI_trait_moredesc_soto_prof_soto"}
})

sotoAppend("loader", {
        {text = "UI_trait_moredesc_soto_prof_soto"}
})

sotoAppend("miner", {
        {text = "UI_trait_moredesc_soto_prof_soto"}
})

sotoAppend("paparazzi", {
        {text = "UI_trait_moredesc_soto_prof_soto"}
})

sotoAppend("priest", {
        {text = "UI_trait_moredesc_soto_prof_soto"}
})

sotoAppend("schoolteacher", {
        {text = "UI_trait_moredesc_soto_prof_soto"}
})

sotoAppend("soldier", {
        {text = "UI_trait_moredesc_soto_prof_soto"}
})

sotoAppend("storeemployee", {
        {text = "UI_trait_moredesc_soto_prof_soto"}
})

sotoAppend("stuntman", {
        {text = "UI_trait_moredesc_soto_prof_soto"}
})

sotoAppend("truckdriver", {
        {text = "UI_trait_moredesc_soto_prof_soto"}
})

sotoAppend("veterinarian", {
        {text = "UI_trait_moredesc_soto_prof_soto"}
})

sotoAppend("weightliftinginstructor", {
        {text = "UI_trait_moredesc_soto_prof_soto"}
})

-- Drop MDFT lines duplicated by SOTO/vanilla tooltips when SOTO mod is active
if getActivatedMods():contains("SimpleOverhaulTraitsAndOccupations") then
    MDFT.MoreDescription["strong"] = nil
    MDFT.MoreDescription["athletic"] = nil
    MDFT.MoreDescription["dextrous"] = nil
    MDFT.MoreDescription["allthumbs"] = nil
    MDFT.MoreDescription["pronetoillness"] = nil
    local function mdfDropStartingWeight(key)
        local t = MDFT.MoreDescription[key]
        if not t then return end
        local kept = {}
        for _, line in ipairs(t) do
            if line.text ~= "UI_trait_moredesc_startingweight" then
                table.insert(kept, line)
            end
        end
        MDFT.MoreDescription[key] = kept
    end
    mdfDropStartingWeight("overweight")
    mdfDropStartingWeight("underweight")
    mdfDropStartingWeight("very underweight")
    mdfDropStartingWeight("veryunderweight")
    local pac = MDFT.MoreDescription.pacifist
    if pac then
        local kept = {}
        for _, line in ipairs(pac) do
            if line.text ~= "UI_trait_moredesc_xpforweaponskillsandaimingskill" then
                table.insert(kept, line)
            end
        end
        if #kept == 0 then MDFT.MoreDescription.pacifist = nil else MDFT.MoreDescription.pacifist = kept end
    end
end

