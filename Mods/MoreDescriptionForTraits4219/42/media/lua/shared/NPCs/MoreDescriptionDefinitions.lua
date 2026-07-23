
MDFT = MDFT or {}

local MDFT_BaseMoreDescription = {
    inventive = {
        {value = 1, text = "UI_trait_moredesc_levellower"},
    },
    axeman = {
        {value = "25%", text = "UI_trait_moredesc_fasteraxeswing"},
        {value = "+50%", text = "UI_trait_moredesc_axetreedamage"},
    },
    handy = {
        {value = "+100", text = "UI_trait_moredesc_HPtoallconstructionsexceptwalls"},
        {value = false, text = "UI_trait_moredesc_Fasterbuildingspeed"},
        {value = false, text = "UI_trait_moredesc_Fasterbarricadingspeed"},
    },
    speeddemon = {
        {value = "+100", text = "UI_trait_moredesc_gearswitchingspeed"},
        {value = "+15", text = "UI_trait_moredesc_topspeed"},
        {value = "+200", text = "UI_trait_moredesc_engineloudnessreversing"},
        {value = false, text = "UI_trait_moredesc_increasedreversingspeed"},
        {value = "+15", text = "UI_trait_moredesc_grappleeffectiveness"},
    },
    sundaydriver = {
        {value = -40, text = "UI_trait_moredesc_acceleration"},
        {value = -30, text = "UI_trait_moredesc_reverseacceleration"},
        {value = "30", text = "UI_trait_moredesc_maxspeed"},
        {value = false, text = "UI_trait_moredesc_nochangetoengineloudness"},
    },
    poorpassenger = {
        {value = "+30", text = "UI_trait_moredesc_motionsickness"},
    },
    motionsensitive = {
        {value = false, text = "UI_trait_moredesc_motionsickness_forwardbackward"},
        {value = false, text = "UI_trait_moredesc_motionsickness_skidsturns"},
        {value = "+25", text = "UI_trait_moredesc_motionsickness_offroad"},
        {value = false, text = "UI_trait_moredesc_motionsickness_alloccupants"},
    },
    brave = {
        {value = -70, text = "UI_trait_moredesc_panicexceptnightterrors"},
        {value = -50, text = "UI_trait_moredesc_stressfromlootingcorpses"},
        {value = "+10", text = "UI_trait_moredesc_grappleeffectiveness"},
    },
    cowardly = {
        {value = "+100", text = "UI_trait_moredesc_panicexceptnightterrors"},
        {value = "+100", text = "UI_trait_moredesc_stressfromlootingcorpses"},
        {value = -10, text = "UI_trait_moredesc_grappleeffectiveness"},
    },
    clumsy = {
        {value = "+20", text = "UI_trait_moredesc_footstepsoundradius"},
        {value = "+10", text = "UI_trait_moredesc_chancetotripvaultingfence"},
        {value = false, text = "UI_trait_moredesc_increasedchanceoffallwhenbumping"},
        {value = false, text = "UI_trait_moredesc_increasedchanceofinjurywhenopeningcan"},
    },
    graceful = {
        {value = "-40", text = "UI_trait_moredesc_footstepsoundradius"},
        {value = "-10", text = "UI_trait_moredesc_chancetotripvaultingfence"},
        {value = false, text = "UI_trait_moredesc_decreasedchancetotripfromlunge"},
        {value = false, text = "UI_trait_moredesc_decreasedchanceoffallwhenbumping"},
    },
    shortsighted = {
        {value = false, text = "UI_trait_moredesc_alsogivesblurryvision"},
        {value = false, text = "UI_trait_moredesc_weaponsightsrangebonusatminimum"},
        {value = false, text = "UI_trait_moredesc_maluscanberemovedbywearingglasses"},
    },
    hardofhearing = {
        {value = false, text = "UI_trait_moredesc_soundeffectsmuffled"},
    },
    deaf = {
        {value = false, text = "UI_trait_moredesc_canthearsound"},
        {value = false, text = "UI_trait_moredesc_stillabletowatchtv"},
    },
    keenhearing = {
        {value = "+50", text = "UI_trait_moredesc_perceptionradius"},
        {value = false, text = "UI_trait_moredesc_zombiesbehindvisibleearlier"},
    },
    eagleeyed = {
        {value = false, text = "UI_trait_moredesc_widerfieldofview"},
        {value = "+20", text = "UI_trait_moredesc_maxrangemodifieronweaponsights"},
    },
    heartyappetite = {
        {value = "+50", text = "UI_trait_moredesc_hunger"},
    },
    lighteater = {
        {value = -25, text = "UI_trait_moredesc_hunger"},
    },
    thickskinned = {
        {value = "+30", text = "UI_trait_moredesc_chanceofnotbeinginjuredbyzombies"},
        {value = -54, text = "UI_trait_moredesc_chanceofgettingscratchedcutbytrees"},
    },
    unfit = {
        {value = 3, text = "UI_trait_moredesc_unfitlosecondition"},
        {value = 3, text = "UI_trait_moredesc_unfitgaincondition"},
    },
    ["out of shape"] = {
        {value = 5, text = "UI_trait_moredesc_outofshapelosecondition"},
        {value = 3, text = "UI_trait_moredesc_outofshapelosecondition2"},
        {value = 5, text = "UI_trait_moredesc_outofshapegaincondition"},
        {value = -1, text = "UI_trait_moredesc_speed"},
    },
    fit = {
        {value = 5, text = "UI_trait_moredesc_fitlosecondition"},
        {value = 3, text = "UI_trait_moredesc_fitlosecondition2"},
        {value = 5, text = "UI_trait_moredesc_unfitgaincondition"},
    },
    athletic = {
        {value = "+20", text = "UI_trait_moredesc_runningsprintingspeed"},
        {value = -20, text = "UI_trait_moredesc_runningsprintingenduranceloss"},
        {value = "+25", text = "UI_trait_moredesc_grappleeffectiveness"},
        {value = 9, text = "UI_trait_moredesc_athleticlosecondition"},
        {value = 9, text = "UI_trait_moredesc_athleticgaincondition"},
    },
    nutritionist = {
        {value = false, text = "UI_trait_moredesc_includingnonpackagedandcookedfood"},
    },
    nutritionist2 = {
        {value = false, text = "UI_trait_moredesc_includingnonpackagedandcookedfood"},
    },
    overweight = {
        {value = "+10", text = "UI_trait_moredesc_chancetotripwhilerunvaulting"},
        {value = "+10", text = "UI_trait_moredesc_chancetotripfromlunge"},
        {value = false, text = "UI_trait_moredesc_increasedchanceoffallwhenbumping"},
        {value = false, text = "UI_trait_moredesc_increasedchancetofailatallfenceclimb"},
        {value = -30, text = "UI_trait_moredesc_enduranceregeneration"},
        {value = false, text = "UI_trait_moredesc_doubledendurancelosswhenrunning"},
        {value = "+20", text = "UI_trait_moredesc_falldamage"},
        {value = false, text = "UI_trait_moredesc_slowerropeclimbingspeed"},
        {value = "+10", text = "UI_trait_moredesc_grappleeffectiveness"},
        {value = 10, text = "UI_trait_moredesc_cannotgainfitnessxptowardslevel"},
        {value = false, text = ""},
        {value = 95, text = "UI_trait_moredesc_startingweight"},
        {value = 100, text = "UI_trait_moredesc_replacedbyobeseifweightgoesabove"},
        {value = 85, text = "UI_trait_moredesc_lostifweightgoesbelow"},
    },
    underweight = {
        {value = -20, text = "UI_trait_moredesc_meleedamage"},
        {value = "+10", text = "UI_trait_moredesc_chancetotripfromlunge"},
        {value = false, text = "UI_trait_moredesc_increasedchanceoffallwhenbumping"},
        {value = false, text = "UI_trait_moredesc_increasedchancetofailatallfenceclimb"},
        {value = 10, text = "UI_trait_moredesc_cannotgainfitnessxptowardslevel"},
        {value = -10, text = "UI_trait_moredesc_grappleeffectiveness"},
        {value = false, text = ""},
        {value = 70, text = "UI_trait_moredesc_startingweight"},
        {value = 65, text = "UI_trait_moredesc_replacedbyveryunderweightifweightgoesbelow"},
        {value = 75, text = "UI_trait_moredesc_lostifweightgoesabove"},
    },
    emaciated = {
        {value = -60, text = "UI_trait_moredesc_meleedamage"},
        {value = false, text = "UI_trait_moredesc_greatlyincreasedchancetofailatallfenceclimb"},
        {value = -70, text = "UI_trait_moredesc_enduranceregeneration"},
        {value = "+40", text = "UI_trait_moredesc_falldamage"},
        {value = false, text = "UI_trait_moredesc_cannotgainxptowardsfitnesslevel7orhigher"},
        {value = -60, text = "UI_trait_moredesc_grappleeffectiveness"},
        {value = false, text = ""},
        {value = 50, text = "UI_trait_moredesc_replacedbyveryunderweightifweightgoesabove"},
        {value = 35, text = "UI_trait_moredesc_characterwillstartlosinglife"},
    },
    ["very underweight"] = {
        {value = -40, text = "UI_trait_moredesc_meleedamage"},
        {value = "+20", text = "UI_trait_moredesc_chancetotripfromlunge"},
        {value = false, text = "UI_trait_moredesc_increasedchanceoffallwhenbumping"},
        {value = false, text = "UI_trait_moredesc_greatlyincreasedchancetofailatallfenceclimb"},
        {value = -30, text = "UI_trait_moredesc_enduranceregeneration"},
        {value = "+20", text = "UI_trait_moredesc_falldamage"},
        {value = false, text = "UI_trait_moredesc_cannotgainxptowardsfitnesslevel7orhigher"},
        {value = -40, text = "UI_trait_moredesc_grappleeffectiveness"},
        {value = false, text = ""},
        {value = 50, text = "UI_trait_moredesc_replacedbyemaciatedifweightgoesbelow"},
        {value = 65, text = "UI_trait_moredesc_replacedbyunderweightifweightgoesabove"},
    },
    obese = {
        {value = "+20", text = "UI_trait_moredesc_chancetotripwhilerunvaulting"},
        {value = -10, text = "UI_trait_moredesc_chancetotripfromlunge"},
        {value = false, text = "UI_trait_moredesc_increasedchanceoffallwhenbumping"},
        {value = false, text = "UI_trait_moredesc_greatlyincreasedchancetofailatallfenceclimb"},
        {value = -60, text = "UI_trait_moredesc_enduranceregeneration"},
        {value = "+40", text = "UI_trait_moredesc_falldamage"},
        {value = -15, text = "UI_trait_moredesc_runningsprintingspeed"},
        {value = false, text = "UI_trait_moredesc_cannotgainxptowardsfitnesslevel7orhigher"},
        {value = "+5", text = "UI_trait_moredesc_grappleeffectiveness"},
        {value = false, text = ""},
        {value = 100, text = "UI_trait_moredesc_replacedbyoverweightifweightgoesbelow"},
    },
    strong = {
        {value = "+40", text = "UI_trait_moredesc_knockbackpower"},
        {value = "+25", text = "UI_trait_moredesc_grappleeffectiveness"},
        {value = 9, text = "UI_trait_moredesc_canbegainedbytrainingstrengthtolevel"},
    },
    stout = {
        {value = 6, text = "UI_trait_moredesc_canbegainedbytrainingstrengthtolevel"},
        {value = 9, text = "UI_trait_moredesc_replacedbystrongatlevel9strength"},
    },
    weak = {
        {value = -40, text = "UI_trait_moredesc_knockbackpower"},
        {value = 2, text = "UI_trait_moredesc_replacedbyfeebleatlevel2strength"},
    },
    feeble = {
        {value = 5, text = "UI_trait_moredesc_canbelostbytrainingstrengthtolevel5"},
    },
    resilient = {
        {value = -25, text = "UI_trait_moredesc_corpsesickness"},
        {value = -55, text = "UI_trait_moredesc_chanceofcatchingacold"},
        {value = -20, text = "UI_trait_moredesc_coldstrength"},
        {value = -50, text = "UI_trait_moredesc_coldprogressionspeed"},
        {value = -25, text = "UI_trait_moredesc_zombificationspeed"},
    },
    pronetoillness = {
        {value = "+25", text = "UI_trait_moredesc_corpsesickness"},
        {value = "+70", text = "UI_trait_moredesc_chanceofcatchingacold"},
        {value = "+20", text = "UI_trait_moredesc_coldstrength"},
        {value = "+50", text = "UI_trait_moredesc_coldprogressionspeed"},
        {value = "+25", text = "UI_trait_moredesc_zombificationspeed"},
    },
    agoraphobic = {},
    claustrophobic = {
        {value = 70, text = "UI_trait_moredesc_claustrophobic"},
    },
    marksman = {
        {value = -40, text = "UI_trait_moredesc_windpenaltywhenaimingwithguns"},
        {value = "+20", text = "UI_trait_moredesc_accuracywithguns"},
        {value = "+10", text = "UI_trait_moredesc_critchancewithguns"},
        {value = false, text = "UI_trait_moredesc_betteraimingdelay"},
    },
    nightowl = {
        {value = "+40", text = "UI_trait_moredesc_tirednessrecoveryratewhensleeping"},
        {value = false, text = "UI_trait_moredesc_doesnotwakeupwhenreaching0tiredness"},
        {value = false, text = "UI_trait_moredesc_needtosetanalarmtotakefulladvantage"},
    },
    outdoorsman = {
        {value = false, text = "UI_trait_moredesc_greatlydecreasedchanceofscratchbytrees"},
        {value = -75, text = "UI_trait_moredesc_chanceofcatchingacold"},
        {value = -33, text = "UI_trait_moredesc_chanceofbreakingfirekindling"},
        {value = "100", text = "UI_trait_moredesc_lightsfiresfaster"},
        {value = -33, text = "UI_trait_moredesc_gunaimweatherpenalty"},
    },
    fasthealer = {
        {value = -20, text = "UI_trait_moredesc_severityofvehicleinjuries"},
        {value = -40, text = "UI_trait_moredesc_fractureseverity"},
        {value = false, text = "UI_trait_moredesc_allwoundshealmuchfaster"},
        {value = false, text = "UI_trait_moredesc_noeffectonexercisefatigue"},
    },
    fastlearner = {
        {value = "+30", text = "UI_trait_moredesc_xpforallskillsexcept"},
    },
    fastreader = {
        {value = "+30", text = "UI_trait_moredesc_readingspeed"},
    },
    adrenalinejunkie = {
        {value = "+0.2", text = "UI_trait_moredesc_basespeedatstrongpanic"},
        {value = "+0.25", text = "UI_trait_moredesc_basespeedatextremepanic"},
        {value = false, text = "UI_trait_moredesc_stillcantgoabovemovespeedcap"},
    },
    inconspicuous = {
        {value = false, text = "UI_trait_moredesc_ifusingthenewstealthsystem"},
        {value = -20, text = "UI_trait_moredesc_chanceofbeingspottedbyazombie"},
        {value = false, text = ""},
        {value = false, text = "UI_trait_moredesc_ifusingtheoldstealthsystem"},
        {value = -50, text = "UI_trait_moredesc_chanceofbeingspottedbyazombie"},
    },
    needslesssleep = {
        {value = -30, text = "UI_trait_moredesc_tirednesslossratewhileawake"},
        {value = "+25", text = "UI_trait_moredesc_tirednessrecoveryratewhensleeping"},
        {value = -25, text = "UI_trait_moredesc_sleepduration"},
    },
    nightvision = {
        {value = "+10", text = "UI_trait_moredesc_percent"},
        {value = false, text = "UI_trait_moredesc_increasedminimumanbiantlight"},
        {value = false, text = "UI_trait_moredesc_reducedvisoinconemalusindarkness"},
    },
    organized = {
        {value = "+30", text = "UI_trait_moredesc_percent"},
    },
    lowthirst = {
        {value = -50, text = "UI_trait_moredesc_thirst"},
    },
    burglar = {
        {value = false, text = "UI_trait_moredesc_decreasedchanceoffailingatallfenceclimb"},
        {value = false, text = "UI_trait_moredesc_slightlyincreasedropclimbingspeed"},
    },
    slowhealer = {
        {value = "+20", text = "UI_trait_moredesc_severityofvehicleinjuries"},
        {value = "+80", text = "UI_trait_moredesc_fractureseverity"},
        {value = false, text = "UI_trait_moredesc_allwoundshealmuchslower"},
        {value = false, text = "UI_trait_moredesc_noeffectonexercisefatigue"},
    },
    slowlearner = {
        {value = -30, text = "UI_trait_moredesc_xpforallskillsexcept"},
    },
    slowreader = {
        {value = -30, text = "UI_trait_moredesc_readingspeed"},
    },
    needsmoresleep = {
        {value = "+30", text = "UI_trait_moredesc_tirednesslossratewhileawake"},
        {value = "+18", text = "UI_trait_moredesc_tirednessrecoveryratewhensleeping"},
        {value = -18, text = "UI_trait_moredesc_sleepduration"},
    },
    conspicuous = {
        {value = false, text = "UI_trait_moredesc_ifusingthenewstealthsystem"},
        {value = "+20", text = "UI_trait_moredesc_chanceofbeingspottedbyazombie"},
        {value = false, text = ""},
        {value = false, text = "UI_trait_moredesc_ifusingtheoldstealthsystem"},
        {value = "+100", text = "UI_trait_moredesc_chanceofbeingspottedbyazombie"},
    },
    disorganized = {
        {value = -30, text = "UI_trait_moredesc_percent"},
        {value = false, text = "UI_trait_moredesc_aftercraftingdoesntreturnitems"}
    },
    highthirst = {
        {value = "+100", text = "UI_trait_moredesc_thirst"},
    },
    illiterate = {
        {value = false, text = "UI_trait_moredesc_includingtextonmapsandcaloryvaluesonfood"},
    },
    insomniac = {
        {value = false, text = "UI_trait_moredesc_hardertostartsleeping"},
        {value = -50, text = "UI_trait_moredesc_tirednessrecoveryratewhensleeping"},
    },
    pacifist = {
        {value = -25, text = "UI_trait_moredesc_xpforweaponskillsandaimingskill"},
    },
    thinskinned = {
        {value = -23, text = "UI_trait_moredesc_chanceofnotbeinginjuredbyzombies"},
        {value = "+100", text = "UI_trait_moredesc_chanceofgettingscratchedcutbytrees"},
    },
    dextrous = {
        {value = -50, text = "UI_trait_moredesc_inventorytransferringtime"},
        {value = -20, text = "UI_trait_moredesc_aimingdelaywithguns"},
        {value = false, text = "UI_trait_moredesc_decreasedchanceofjammingguns"},
        {value = false, text = "UI_trait_moredesc_decreasedchancewoundwhenopeningacan"},
    },
    allthumbs = {
        {value = "+100", text = "UI_trait_moredesc_inventorytransferringtime"},
        {value = "+20", text = "UI_trait_moredesc_aimingdelaywithguns"},
        {value = false, text = "UI_trait_moredesc_increasedchanceofjammingguns"},
        {value = false, text = "UI_trait_moredesc_increasedchancewoundwhenopeningacan"},
    },
    desensitized = {
        {value = -85, text = "UI_trait_moredesc_panicexceptnightterrors"},
        {value = false, text = "UI_trait_moredesc_doesntpanicfromzombiereanimating"},
        {value = false, text = "UI_trait_moredesc_nostressfromlootingzombies"},
    },
    weakstomach = {
        {value = "+100", text = "UI_trait_moredesc_foodillnesschance"},
        {value = "+45", text = "UI_trait_moredesc_foodillnessduration"},
        {value = "+50", text = "UI_trait_moredesc_taintedwatermorepoisonous"},
        {value = "+30", text = "UI_trait_moredesc_motionsicknessprogression"},
    },
    irongut = {
        {value = -50, text = "UI_trait_moredesc_foodillnesschance"},
        {value = -55, text = "UI_trait_moredesc_foodillnessduration"},
        {value = -50, text = "UI_trait_moredesc_taintedwatermorepoisonous"},
        {value = -50, text = "UI_trait_moredesc_raweggsnevercausefoodillness"},
        {value = -30, text = "UI_trait_moredesc_motionsicknessprogression"},
    },
    hemophobic = {
        {value = false, text = "UI_trait_moredesc_inventorytransferbloodyitemsfasterandstressfull"},
    },
    asthmatic = {
        {value = "+42", text = "UI_trait_moredesc_endurancelosswhenrunningsprintingcarryingdragging"},
        {value = "+20", text = "UI_trait_moredesc_endurancelosswhenswinging"},
    },
    gymnast = {
        {value = false, text = "UI_trait_moredesc_decreasedchanceoffailingatallfenceclimb"},
        {value = false, text = "UI_trait_moredesc_slightlyincreasedropclimbingspeed"},
    },
    lucky = {
        {value = "+10", text = "UI_trait_moredesc_loot"},
        {value = -5, text = "UI_trait_moredesc_chanceoffailingitemrepairs"},
        {value = false, text = "UI_trait_moredesc_decreasedchanceofinjurywhenopeningcan"},
        {value = "+10", text = "UI_trait_moredesc_grappleeffectiveness"},
    },
    unlucky = {
        {value = -10, text = "UI_trait_moredesc_loot"},
        {value = "+5", text = "UI_trait_moredesc_chanceoffailingitemrepairs"},
        {value = false, text = "UI_trait_moredesc_increasedchanceofinjurywhenopeningcan"},
    },

    -- PROFESSIONS (already lowercase)
    fireofficer = {
        {value = "10-20", text = "UI_prof_moredesc_startingregularityexercise"},
    },
    parkranger = {
        {value = "+30", text = "UI_prof_moredesc_movespeedintrees"},
    },
    securityguard = {
        {value = "7-12", text = "UI_prof_moredesc_startingregularityexercise"},
    },
    lumberjack = {
        {value = "+15", text = "UI_prof_moredesc_movespeedintrees"},
    },
    fitnessinstructor = {
        {value = "40-60", text = "UI_prof_moredesc_startingregularityexercise"},
    },
}

MDFT.MoreDescription = MDFT.MoreDescription or {}
for k, v in pairs(MDFT_BaseMoreDescription) do
    MDFT.MoreDescription[k] = v
end

require("NPCs/SOTO_MoreDescriptionDefinitions")
