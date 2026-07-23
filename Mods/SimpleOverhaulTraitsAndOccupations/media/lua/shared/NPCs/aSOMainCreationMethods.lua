SOBaseGameCharacterDetails = {}

	----------------------------------------------
	--- SIMPLE OVERHAUL TRAITS AND OCCUPATIONS ---
	----------------------------------------------

SOBaseGameCharacterDetails.DoTraits = function()

	-----------------------
	--- TRAITS OVERHAUL ---
	-----------------------

	local SleepEnabled = (isClient() or isServer()) and getServerOptions():getBoolean("SleepAllowed") and getServerOptions():getBoolean("SleepNeeded")
	
	-- STR TRAITS	
	local stout = TraitFactory.addTrait("Stout", getText("UI_trait_stout"), 6, getText("UI_trait_stoutdesc"), false);
	stout:addXPBoost(Perks.Strength, 2)	
	local strong = TraitFactory.addTrait("Strong", getText("UI_trait_strong"), 12, getText("UI_trait_strongdesc"), false);
	strong:addXPBoost(Perks.Strength, 4)
	local feeble = TraitFactory.addTrait("Feeble", getText("UI_trait_feeble"), -6, getText("UI_trait_feebledesc"), false);
	feeble:addXPBoost(Perks.Strength, -2)	
	local weak = TraitFactory.addTrait("Weak", getText("UI_trait_weak"), -12, getText("UI_trait_weakdesc"), false);
	weak:addXPBoost(Perks.Strength, -4)	

	-- FITNESS TRAITS
	local fit = TraitFactory.addTrait("Fit", getText("UI_trait_fit"), 6, getText("UI_trait_fitdesc"), false);
	fit:addXPBoost(Perks.Fitness, 2)	
	local ath = TraitFactory.addTrait("Athletic", getText("UI_trait_athletic"), 12, getText("UI_trait_athleticdesc"), false);
	ath:addXPBoost(Perks.Fitness, 4)	
	local outof = TraitFactory.addTrait("Out of Shape", getText("UI_trait_outofshape"), -6, getText("UI_trait_outofshapedesc"), false);
	outof:addXPBoost(Perks.Fitness, -2)	
	local unfit = TraitFactory.addTrait("Unfit", getText("UI_trait_unfit"), -12, getText("UI_trait_unfitdesc"), false);
	unfit:addXPBoost(Perks.Fitness, -4)

	-- CHARACTER WEIGHT TRAITS
	local underweight = TraitFactory.addTrait("Underweight", getText("UI_trait_underweight"), -5, getText("UI_trait_underweightdesc"), false);
	underweight:addXPBoost(Perks.Strength, -1)
	local veryUnderweight = TraitFactory.addTrait("Very Underweight", getText("UI_trait_veryunderweight"), -10, getText("UI_trait_veryunderweightdesc"), false);
	veryUnderweight:addXPBoost(Perks.Strength, -2)
    TraitFactory.addTrait("Emaciated", getText("UI_trait_emaciated"), -10, getText("UI_trait_emaciateddesc"), true);	
	local overweight = TraitFactory.addTrait("Overweight", getText("UI_trait_overweight"), -6, getText("UI_trait_overweightdesc"), false);
	overweight:addXPBoost(Perks.Fitness, -1)
	local obese = TraitFactory.addTrait("Obese", getText("UI_trait_obese"), -12, getText("UI_trait_obesedesc"), false);
	obese:addXPBoost(Perks.Fitness, -2)	

	-- STR AND FIT TRAITS
	local taut = TraitFactory.addTrait("Taut", getText("UI_trait_taut"), 6, getText("UI_trait_tautdesc"), false);
	taut:addXPBoost(Perks.Fitness, 1)
	taut:addXPBoost(Perks.Strength, 1)
	local slack = TraitFactory.addTrait("Slack", getText("UI_trait_slack"), -6, getText("UI_trait_slackdesc"), false);
	slack:addXPBoost(Perks.Fitness, -1)
	slack:addXPBoost(Perks.Strength, -1)	

	-- VANILLA TRAITS
	-- AGILITY TRAITS
	local jogger = TraitFactory.addTrait("Jogger", getText("UI_trait_Jogger"), 2, getText("UI_trait_JoggerDesc"), false);
	jogger:addXPBoost(Perks.Sprinting, 1)	
	local sneaky = TraitFactory.addTrait("Sneaky", getText("UI_trait_sneaky"), 2, getText("UI_trait_sneakydesc"), false);
	sneaky:addXPBoost(Perks.Sneak, 1)	
	local lightfooted = TraitFactory.addTrait("Lightfooted", getText("UI_trait_lightfooted"), 1, getText("UI_trait_lightfooteddesc"), false);
	lightfooted:addXPBoost(Perks.Lightfoot, 1)
	local nimble = TraitFactory.addTrait("Nimble", getText("UI_trait_nimble"), 3, getText("UI_trait_nimbledesc"), false);
	nimble:addXPBoost(Perks.Nimble, 1)	
	local gym = TraitFactory.addTrait("Gymnast", getText("UI_trait_Gymnast"), 4, getText("UI_trait_GymnastDesc"), false);
	gym:addXPBoost(Perks.Lightfoot, 1)
	gym:addXPBoost(Perks.Nimble, 1)
	TraitFactory.addTrait("Gymnast2", getText("UI_trait_Gymnast"), 0, getText("UI_trait_Gymnast2desc"), true);	

	-- SURVIVING TRAITS
	local fisher = TraitFactory.addTrait("Fishing", getText("UI_trait_Fishing"), 2, getText("UI_trait_FishingDesc"), false);
	fisher:addXPBoost(Perks.Fishing, 1)
	fisher:getFreeRecipes():add("Make Fishing Rod");
	fisher:getFreeRecipes():add("Fix Fishing Rod");
	local gardener = TraitFactory.addTrait("Gardener", getText("UI_trait_Gardener"), 1, getText("UI_trait_GardenerDesc"), false);
	gardener:addXPBoost(Perks.Farming, 1)
	gardener:getFreeRecipes():add("Make Mildew Cure");
	gardener:getFreeRecipes():add("Make Flies Cure");
	TraitFactory.addTrait("Gardener2", getText("UI_trait_Gardener"), 0, getText("UI_trait_Gardener2Desc"), true);
	local forager = TraitFactory.addTrait("Forager", getText("UI_trait_forager"), 2, getText("UI_trait_foragerdesc"), false);
	forager:addXPBoost(Perks.PlantScavenging, 1)
	local trapper = TraitFactory.addTrait("Trapper", getText("UI_trait_trapper"), 2, getText("UI_trait_trapperdesc"), false);
	trapper:addXPBoost(Perks.Trapping, 1)
	trapper:getFreeRecipes():add("Make Stick Trap");
	trapper:getFreeRecipes():add("Make Wooden Box Trap");	
	local backpacker = TraitFactory.addTrait("Hiker", getText("UI_trait_Hiker"), 6, getText("UI_trait_SOHikerDesc"), false);
	backpacker:addXPBoost(Perks.PlantScavenging, 1)
	backpacker:addXPBoost(Perks.Trapping, 1)
	backpacker:addXPBoost(Perks.Fishing, 1)	
    backpacker:getFreeRecipes():add("Make Stick Trap");
    backpacker:getFreeRecipes():add("Make Snare Trap");
    backpacker:getFreeRecipes():add("Make Wooden Box Trap");	
	local mushroompicker = TraitFactory.addTrait("MushroomPicker", getText("UI_trait_mushroompicker"), 1, getText("UI_trait_mushroompickerdesc"), false);
	local entomologist = TraitFactory.addTrait("Entomologist", getText("UI_trait_entomologist"), 1, getText("UI_trait_entomologistdesc"), false);

	-- CRAFTING TRAITS
	local firstAid = TraitFactory.addTrait("FirstAid", getText("UI_trait_FirstAid"), 1, getText("UI_trait_FirstAidDesc"), false);
	firstAid:addXPBoost(Perks.Doctor, 1)
	TraitFactory.addTrait("FirstAid2", getText("UI_trait_FirstAid"), 0, getText("UI_trait_FirstAid2Desc"), true);
	local tailoring = TraitFactory.addTrait("Tailor", getText("UI_trait_Tailor"), 2, getText("UI_trait_TailorDesc"), false);
	tailoring:addXPBoost(Perks.Tailoring, 1)
	local cook = TraitFactory.addTrait("Cook", getText("UI_trait_Cook"), 2, getText("UI_trait_CookDesc"), false);
	cook:addXPBoost(Perks.Cooking, 2)
	cook:getFreeRecipes():add("Make Cake Batter");
	cook:getFreeRecipes():add("Make Pie Dough");
	cook:getFreeRecipes():add("Make Bread Dough");
    cook:getFreeRecipes():add("Make Cake Batter");
    cook:getFreeRecipes():add("Make Pie Dough");
    cook:getFreeRecipes():add("Make Bread Dough");
    cook:getFreeRecipes():add("Make Biscuits");
    cook:getFreeRecipes():add("Make Chocolate Cookie Dough");
    cook:getFreeRecipes():add("Make Chocolate Chip Cookie Dough");
    cook:getFreeRecipes():add("Make Oatmeal Cookie Dough");
    cook:getFreeRecipes():add("Make Shortbread Cookie Dough");
    cook:getFreeRecipes():add("Make Sugar Cookie Dough");
    cook:getFreeRecipes():add("Make Pizza");	
	TraitFactory.addTrait("Cook2", getText("UI_trait_Cook"), 0, getText("UI_trait_Cook2Desc"), true);
	local handy = TraitFactory.addTrait("Handy", getText("UI_trait_handy"), 6, getText("UI_trait_handydesc"), false);
	handy:addXPBoost(Perks.Maintenance, 1)
	handy:addXPBoost(Perks.Woodwork, 1)
	TraitFactory.addTrait("Handy2", getText("UI_trait_handy"), 0, getText("UI_trait_handydesc"), true);
	local scullion = TraitFactory.addTrait("Scullion", getText("UI_trait_scullion"), 1, getText("UI_trait_sculliondesc"), false);
	scullion:addXPBoost(Perks.Cooking, 1)
	local carpenter = TraitFactory.addTrait("Carpenter", getText("UI_trait_carpenter"), 2, getText("UI_trait_carpenterdesc"), false);
	carpenter:addXPBoost(Perks.Woodwork, 1)
	local electrictech = TraitFactory.addTrait("ElectricTech", getText("UI_trait_electrictech"), 2, getText("UI_trait_electrictechdesc"), false);
	electrictech:addXPBoost(Perks.Electricity, 1)
	local automechanic = TraitFactory.addTrait("AutoMechanic", getText("UI_trait_automechanic"), 2, getText("UI_trait_automechanicdesc"), false);
	automechanic:addXPBoost(Perks.Mechanics, 1)
	local metalwelder = TraitFactory.addTrait("MetalWelder", getText("UI_trait_metalwelder"), 2, getText("UI_trait_metalwelderdesc"), false);
	metalwelder:addXPBoost(Perks.MetalWelding, 1)

	-- COMBAT TRAITS
	local baseball = TraitFactory.addTrait("BaseballPlayer", getText("UI_trait_PlaysBaseball"), 4, getText("UI_trait_PlaysBaseballDesc"), false);
	baseball:addXPBoost(Perks.Blunt, 1)	
	local stabber = TraitFactory.addTrait("Stabber", getText("UI_trait_stabber"), 2, getText("UI_trait_stabberdesc"), false);
	stabber:addXPBoost(Perks.SmallBlade, 1)
	local crusher = TraitFactory.addTrait("Crusher", getText("UI_trait_crusher"), 3, getText("UI_trait_crusherdesc"), false);
	crusher:addXPBoost(Perks.SmallBlunt, 1)
 	local cutter = TraitFactory.addTrait("Cutter", getText("UI_trait_cutter"), 4, getText("UI_trait_cutterdesc"), false);
	cutter:addXPBoost(Perks.Axe, 1)
	local spearman = TraitFactory.addTrait("Spearman", getText("UI_trait_spearman"), 4, getText("UI_trait_spearmandesc"), false);
	spearman:addXPBoost(Perks.Spear, 1)
	local swordsman = TraitFactory.addTrait("Swordsman", getText("UI_trait_swordsman"), 4, getText("UI_trait_swordsmandesc"), false);
	swordsman:addXPBoost(Perks.LongBlade, 1)
	local durab = TraitFactory.addTrait("Durab", getText("UI_trait_durab"), 3, getText("UI_trait_durabdesc"), false);
	durab:addXPBoost(Perks.Maintenance, 1)		

	-- FIREARM TRAITS	
	local shooter = TraitFactory.addTrait("Shooter", getText("UI_trait_shooter"), 4, getText("UI_trait_shooterdesc"), false);
	shooter:addXPBoost(Perks.Aiming, 1)
	shooter:addXPBoost(Perks.Reloading, 1)
	TraitFactory.addTrait("Shooter2", getText("UI_trait_shooter"), 0, getText("UI_trait_shooter2desc"), true);		
	local expshooter = TraitFactory.addTrait("ExpShooter", getText("UI_trait_expshooter"), 8, getText("UI_trait_expshooterdesc"), false);
	expshooter:addXPBoost(Perks.Aiming, 2)
	expshooter:addXPBoost(Perks.Reloading, 2)	
	local sniper = TraitFactory.addTrait("Sniper", getText("UI_trait_sniper"), 6, getText("UI_trait_sniperdesc"), true); -- trait disabled but keep for old characters
	sniper:addXPBoost(Perks.Aiming, 2)

	-- MIXED TRAITS
	local hunter = TraitFactory.addTrait("Hunter", getText("UI_trait_Hunter"), 9, getText("UI_trait_HunterDesc"), false);
	hunter:addXPBoost(Perks.Aiming, 1)
	hunter:addXPBoost(Perks.Trapping, 1)
	hunter:addXPBoost(Perks.Sneak, 1)
	hunter:addXPBoost(Perks.SmallBlade, 1)
    hunter:getFreeRecipes():add("Make Stick Trap");
    hunter:getFreeRecipes():add("Make Snare Trap");
    hunter:getFreeRecipes():add("Make Wooden Box Trap");
    hunter:getFreeRecipes():add("Make Trap Box");
    hunter:getFreeRecipes():add("Make Cage Trap");
	local formerscout = TraitFactory.addTrait("Formerscout", getText("UI_trait_Scout"), 3, getText("UI_trait_ScoutDesc"), false);
	formerscout:addXPBoost(Perks.Doctor, 1)	
	formerscout:addXPBoost(Perks.PlantScavenging, 1)
	TraitFactory.addTrait("Formerscout2", getText("UI_trait_Scout"), 0, getText("UI_trait_Scout2Desc"), true);
	local barfighter = TraitFactory.addTrait("Brawler", getText("UI_trait_BarFighter"), 5, getText("UI_trait_BarFighterDesc2"), false);
	barfighter:addXPBoost(Perks.Strength, 1)

	--RECIPES TRAITS
	local carenthusiast = TraitFactory.addTrait("Mechanics", getText("UI_trait_Mechanics"), 2, getText("UI_trait_MechanicsDesc"), false);
	carenthusiast:getFreeRecipes():add("Basic Mechanics");
	carenthusiast:getFreeRecipes():add("Intermediate Mechanics");
	TraitFactory.addTrait("Mechanics2", getText("UI_trait_Mechanics"), 0, getText("UI_trait_Mechanics2Desc"), true);
	local herbalist = TraitFactory.addTrait("Herbalist", getText("UI_trait_Herbalist"), 2, getText("UI_trait_HerbalistDesc"), false);
	herbalist:getFreeRecipes():add("Herbalist");
	TraitFactory.addTrait("Herbalist2", getText("UI_trait_Herbalist"), 0, getText("UI_trait_HerbalistDesc"), true);
	local genexp = TraitFactory.addTrait("GenExp", getText("UI_trait_genexp"), 1, getText("UI_trait_genexpdesc"), false);
	genexp:getFreeRecipes():add("Generator");
	TraitFactory.addTrait("GenExp2", getText("UI_trait_genexp"), 0, getText("UI_trait_genexpdesc"), true);	

	-- UNIQUE TRAITS
	-- Endurance traits
	local marathonrunner = TraitFactory.addTrait("MarathonRunner", getText("UI_trait_marathonrunner"), 2, getText("UI_trait_marathonrunnerdesc"), false);
	local relentless = TraitFactory.addTrait("Relentless", getText("UI_trait_relentless"), 3, getText("UI_trait_relentlessdesc"), false);
	TraitFactory.addTrait("Relentless2", getText("UI_trait_relentless"), 0, getText("UI_trait_relentlessdesc"), true);	
	local ninjaway = TraitFactory.addTrait("NinjaWay", getText("UI_trait_ninjaway"), 2, getText("UI_trait_ninjawaydesc"), false);
	local breathingtech = TraitFactory.addTrait("BreathingTech", getText("UI_trait_breathingtech"), 0, getText("UI_trait_breathingtechdesc"), true);	
	TraitFactory.addTrait("BreathingTech2", getText("UI_trait_breathingtech"), 2, getText("UI_trait_breathingtechdesc"), false);	
	
	-- Vehicle speed traits
	TraitFactory.addTrait("SpeedDemon", getText("UI_trait_SpeedDemon"), 1, getText("UI_trait_SpeedDemonDesc"), false);
	TraitFactory.addTrait("SpeedDemon2", getText("UI_trait_SpeedDemon"), 0, getText("UI_trait_SpeedDemonDesc"), true);	
	TraitFactory.addTrait("SundayDriver", getText("UI_trait_SundayDriver"), -2, getText("UI_trait_SundayDriverDesc"), false);

	-- VISION traits
	TraitFactory.addTrait("ShortSighted", getText("UI_trait_shortsigh"), -2, getText("UI_trait_shortsighdesc"), false);
	TraitFactory.addTrait("EagleEyed", getText("UI_trait_eagleeyed"), 2, getText("UI_trait_eagleeyeddesc"), false);
	TraitFactory.addTrait("EagleEyed2", getText("UI_trait_eagleeyed"), 0, getText("UI_trait_eagleeyeddesc"), true);			
 	TraitFactory.addTrait("NightVision", getText("UI_trait_NightVision"), 2, getText("UI_trait_NightVisionDesc"), false);
 	TraitFactory.addTrait("NightVision2", getText("UI_trait_NightVision"), 0, getText("UI_trait_NightVisionDesc"), true);	

	-- Hearing traits
	TraitFactory.addTrait("KeenHearing", getText("UI_trait_keenhearing"), 5, getText("UI_trait_keenhearingdesc"), false);
	TraitFactory.addTrait("KeenHearing2", getText("UI_trait_keenhearing"), 0, getText("UI_trait_keenhearingdesc"), true);			
	TraitFactory.addTrait("HardOfHearing", getText("UI_trait_hardhear"), -5, getText("UI_trait_hardheardesc"), false);
	TraitFactory.addTrait("Deaf", getText("UI_trait_deaf"), -12, getText("UI_trait_deafdesc"), false);

	-- Sneaking traits
	TraitFactory.addTrait("Inconspicuous", getText("UI_trait_Inconspicuous"), 2, getText("UI_trait_InconspicuousDesc"), false);
	TraitFactory.addTrait("Inconspicuous2", getText("UI_trait_Inconspicuous"), 0, getText("UI_trait_InconspicuousDesc"), true);
	TraitFactory.addTrait("Conspicuous", getText("UI_trait_Conspicuous"), -4, getText("UI_trait_ConspicuousDesc"), false);	

	-- Panic traits
	TraitFactory.addTrait("AdrenalineJunkie", getText("UI_trait_AdrenalineJunkie"), 4, getText("UI_trait_AdrenalineJunkieDesc"), false);
	TraitFactory.addTrait("AdrenalineJunkie2", getText("UI_trait_AdrenalineJunkie"), 0, getText("UI_trait_AdrenalineJunkieDesc"), true);
	TraitFactory.addTrait("Desensitized2", getText("UI_trait_Desensitized"), 8, getText("UI_trait_DesensitizedDesc"), false);
	TraitFactory.addTrait("Desensitized", getText("UI_trait_Desensitized"), 0, getText("UI_trait_DesensitizedDesc"), true);		
	TraitFactory.addTrait("Brave", getText("UI_trait_brave"), 3, getText("UI_trait_bravedesc"), false);
	TraitFactory.addTrait("Brave2", getText("UI_trait_brave"), 0, getText("UI_trait_bravedesc"), true);		
	TraitFactory.addTrait("Cowardly", getText("UI_trait_cowardly"), -2, getText("UI_trait_cowardlydesc"), false);

	-- Graceful and Clumsy
	TraitFactory.addTrait("Graceful", getText("UI_trait_graceful"), 2, getText("UI_trait_gracefuldesc"), false);
	TraitFactory.addTrait("Graceful2", getText("UI_trait_graceful"), 0, getText("UI_trait_gracefuldesc"), true);
	TraitFactory.addTrait("Clumsy", getText("UI_trait_clumsy"), -2, getText("UI_trait_clumsydesc"), false);

	-- Reading traits
	TraitFactory.addTrait("FastReader", getText("UI_trait_FastReader"), 1, getText("UI_trait_FastReaderDesc"), false);
	TraitFactory.addTrait("FastReader2", getText("UI_trait_FastReader"), 0, getText("UI_trait_FastReaderDesc"), true);	
	TraitFactory.addTrait("SlowReader", getText("UI_trait_SlowReader"), -1, getText("UI_trait_SlowReaderDesc"), false);
	TraitFactory.addTrait("Illiterate", getText("UI_trait_Illiterate"), -8, getText("UI_trait_IlliterateDesc"), false);
	TraitFactory.addTrait("LifelongLearner", getText("UI_trait_lifelonglearner"), 0, getText("UI_trait_lifelonglearnerdesc"), true);	

	-- Lucky traits
    TraitFactory.addTrait("Lucky", getText("UI_trait_lucky"), 3, getText("UI_trait_luckydesc"), false, true);	
    TraitFactory.addTrait("Unlucky", getText("UI_trait_unlucky"), -3, getText("UI_trait_unluckydesc"), false, true);

	-- Phobic traits
	TraitFactory.addTrait("Agoraphobic", getText("UI_trait_agoraphobic"), -6, getText("UI_trait_agoraphobicdesc"), false);
	TraitFactory.addTrait("Claustophobic", getText("UI_trait_claustro"), -4, getText("UI_trait_claustrodesc"), false);	
	TraitFactory.addTrait("Hemophobic", getText("UI_trait_Hemophobic"), -6, getText("UI_trait_Hemophobic2Desc"), false);
	local fearofthedark = TraitFactory.addTrait("FearoftheDark", getText("UI_trait_fearofthedark"), -1, getText("UI_trait_fearofthedarkdesc"), false);	

	-- Nutritionist trait
	TraitFactory.addTrait("Nutritionist", getText("UI_trait_nutritionist"), 1, getText("UI_trait_nutritionistdesc"), false);
	TraitFactory.addTrait("Nutritionist2", getText("UI_trait_nutritionist"), 0, getText("UI_trait_nutritionistdesc"), true);

	-- Outdoorsman trait
	TraitFactory.addTrait("Outdoorsman", getText("UI_trait_outdoorsman"), 2, getText("UI_trait_outdoorsmandesc"), false);
	TraitFactory.addTrait("Outdoorsman2", getText("UI_trait_outdoorsman"), 0, getText("UI_trait_outdoorsmandesc"), true);	

	-- XP traits
	local mesomorph = TraitFactory.addTrait("Mesomorph", getText("UI_trait_mesomorph"), 0, getText("UI_trait_mesomorphdesc"), true);		
	local ectomorph = TraitFactory.addTrait("Ectomorph", getText("UI_trait_ectomorph"), 3, getText("UI_trait_ectomorphdesc"), false);	
	ectomorph:addXPBoost(Perks.Fitness, 1)
	local endomorph = TraitFactory.addTrait("Endomorph", getText("UI_trait_endomorph"), 3, getText("UI_trait_endomorphdesc"), false);	
	endomorph:addXPBoost(Perks.Strength, 1)		
	local fragilehealth = TraitFactory.addTrait("FragileHealth", getText("UI_trait_fragilehealth"), -3, getText("UI_trait_fragilehealthdesc"), false);	
	local accmetabolism = TraitFactory.addTrait("AccMetabolism", getText("UI_trait_accmetabolism"), 4, getText("UI_trait_accmetabolismdesc"), false);	
	TraitFactory.addTrait("FastLearner", getText("UI_trait_FastLearner"), 7, getText("UI_trait_FastLearnerDesc"), false);
	TraitFactory.addTrait("SlowLearner", getText("UI_trait_SlowLearner"), -7, getText("UI_trait_SlowLearnerDesc"), false);	
	local cruelty = TraitFactory.addTrait("Cruelty", getText("UI_trait_cruelty"), 4, getText("UI_trait_crueltydesc"), false);
	TraitFactory.addTrait("Cruelty2", getText("UI_trait_cruelty"), -0, getText("UI_trait_crueltydesc"), true);	
	TraitFactory.addTrait("Pacifist", getText("UI_trait_Pacifist"), -5, getText("UI_trait_PacifistDesc"), false);
	TraitFactory.addTrait("Pacifist2", getText("UI_trait_Pacifist"), 0, getText("UI_trait_PacifistDesc"), true);

	--Stomach traits
	TraitFactory.addTrait("IronGut", getText("UI_trait_IronGut"), 1, getText("UI_trait_IronGutDesc"), false);
	TraitFactory.addTrait("WeakStomach", getText("UI_trait_WeakStomach"), -1, getText("UI_trait_WeakStomachDesc"), false);
	local sensitivedigestion = TraitFactory.addTrait("SensitiveDigestion", getText("UI_trait_sensitivedigestion"), -2, getText("UI_trait_sensitivedigestiondesc"), false);			

	--Addiction traits
	TraitFactory.addTrait("Smoker", getText("UI_trait_Smoker"), -4, getText("UI_trait_SOSmokerDesc"), false);
	local soalcoholic = TraitFactory.addTrait("SOAlcoholic", getText("UI_trait_soalcoholic"), -5, getText("UI_trait_soalcoholicdesc"), false);	

	--Sweating traits
	local lesssweaty = TraitFactory.addTrait("LessSweaty", getText("UI_trait_lesssweaty"), 1, getText("UI_trait_lesssweatydesc"), false);
	local highsweaty = TraitFactory.addTrait("HighSweaty", getText("UI_trait_highsweaty"), -2, getText("UI_trait_highsweatydesc"), false);	
	
	--Capacity traits
	TraitFactory.addTrait("Organized", getText("UI_trait_Packmule"), 5, getText("UI_trait_PackmuleDesc"), false);
	TraitFactory.addTrait("Organized2", getText("UI_trait_Packmule"), 0, getText("UI_trait_PackmuleDesc"), true);	
	TraitFactory.addTrait("Disorganized", getText("UI_trait_Disorganized"), -5, getText("UI_trait_DisorganizedDesc"), false);	

	--Weight traits
	local strongback = TraitFactory.addTrait("StrongBack", getText("UI_trait_strongback"), 2, getText("UI_trait_strongbackdesc"), false);
	TraitFactory.addTrait("StrongBack2", getText("UI_trait_strongback"), 0, getText("UI_trait_strongbackdesc"), true);
	local weakback = TraitFactory.addTrait("WeakBack", getText("UI_trait_weakback"), -4, getText("UI_trait_weakbackdesc"), false);	

	--Items transfering traits
	TraitFactory.addTrait("Dextrous", getText("UI_trait_Dexterous"), 2, getText("UI_trait_DexterousDesc2"), false);
	TraitFactory.addTrait("Dextrous2", getText("UI_trait_Dexterous"), 0, getText("UI_trait_DexterousDesc2"), true);
	TraitFactory.addTrait("AllThumbs", getText("UI_trait_AllThumbs"), -4, getText("UI_trait_AllThumbsDesc2"), false);

	--Bleeding traits		
	local liquidblood = TraitFactory.addTrait("LiquidBlood", getText("UI_trait_liquidblood"), -6, getText("UI_trait_liquidblooddesc"), false);
	local thickblood = TraitFactory.addTrait("ThickBlood", getText("UI_trait_thickblood"), 3, getText("UI_trait_thickblooddesc"), false);	

	--Thirst traits
	TraitFactory.addTrait("LowThirst", getText("UI_trait_LowThirst"), 2, getText("UI_trait_LowThirstDesc"), false);
	TraitFactory.addTrait("HighThirst", getText("UI_trait_HighThirst"), -4, getText("UI_trait_HighThirstDesc"), false);

	--Hunger traits
	TraitFactory.addTrait("LightEater", getText("UI_trait_lighteater"), 2, getText("UI_trait_lighteaterdesc"), false);
	TraitFactory.addTrait("HeartyAppitite", getText("UI_trait_heartyappetite"), -4, getText("UI_trait_heartyappetitedesc"), false);

	--Endurance traits
	TraitFactory.addTrait("Asthmatic", getText("UI_trait_Asthmatic"), -6, getText("UI_trait_AsthmaticDesc"), false);

	--Healing traits
	TraitFactory.addTrait("FastHealer", getText("UI_trait_FastHealer"), 4, getText("UI_trait_FastHealerDesc"), false);	
	TraitFactory.addTrait("SlowHealer", getText("UI_trait_SlowHealer"), -4, getText("UI_trait_SlowHealerDesc"), false);

	--Cold traits
	TraitFactory.addTrait("Resilient", getText("UI_trait_resilient"), 2, getText("UI_trait_resilientdesc"), false);
	TraitFactory.addTrait("ProneToIllness", getText("UI_trait_pronetoillness"), -4, getText("UI_trait_pronetoillness2desc"), false);	

	--Skin traits
	TraitFactory.addTrait("ThickSkinned", getText("UI_trait_thickskinned"), 6, getText("UI_trait_thickskinneddesc"), false);
	TraitFactory.addTrait("Thinskinned", getText("UI_trait_ThinSkinned"), -6, getText("UI_trait_ThinSkinnedDesc"), false);

	--Sleeping traits
	TraitFactory.addTrait("NeedsLessSleep", getText("UI_trait_LessSleep"), 4, getText("UI_trait_LessSleepDesc"), false, not SleepEnabled);
	TraitFactory.addTrait("NeedsMoreSleep", getText("UI_trait_MoreSleep"), -4, getText("UI_trait_MoreSleepDesc"), false, not SleepEnabled);
	TraitFactory.addTrait("Insomniac", getText("UI_trait_Insomniac"), -6, getText("UI_trait_InsomniacDesc"), false, not SleepEnabled);
	local owlperson = TraitFactory.addTrait("OwlPerson", getText("UI_trait_owlperson"), -1, getText("UI_trait_owlpersondesc"), false, not SleepEnabled);
	local larkperson = TraitFactory.addTrait("LarkPerson", getText("UI_trait_larkperson"), -1, getText("UI_trait_larkpersondesc"), false, not SleepEnabled);	

	--Mood traits
	local optimistmood = TraitFactory.addTrait("Optimist", getText("UI_trait_optimistmood"), 2, getText(	"UI_trait_optimistmooddesc"), false);	
	local depressivemood = TraitFactory.addTrait("Depressive", getText("UI_trait_depressivemood"), -3, getText("UI_trait_depressivemooddesc"), false);	

	--Negative traits	
	local weathersensitive = TraitFactory.addTrait("WeatherSensitive", getText("UI_trait_weathersensitive"), -1, getText("UI_trait_weathersensitivedesc"), false, true);
	local snorer = TraitFactory.addTrait("Snorer", getText("UI_trait_snorer"), -2, getText("UI_trait_snorerdesc"), false, not SleepEnabled);
	local allergic = TraitFactory.addTrait("Allergic", getText("UI_trait_allergic"), -3, getText("UI_trait_allergicdesc"), false);
	local panicattacks = TraitFactory.addTrait("PanicAttacks", getText("UI_trait_panicattacks"), -4, getText("UI_trait_panicattacksdesc"), false);	
	local sorelegs = TraitFactory.addTrait("SoreLegs", getText("UI_trait_sorelegs"), -7, getText("UI_trait_sorelegsdesc"), false);

	--Occupation traits
	TraitFactory.addTrait("Axeman", getText("UI_trait_axeman"), 0, getText("UI_trait_axemandesc"), true);
	TraitFactory.addTrait("Burglar", getText("UI_prof_Burglar"), 0, getText("UI_trait_BurglarDesc"), true);
    TraitFactory.addTrait("Marksman", getText("UI_trait_marksman"), 0, getText("UI_trait_marksmandesc"), true);	
	TraitFactory.addTrait("NightOwl", getText("UI_trait_nightowl"), 0, getText("UI_trait_nightowldesc"), true);
	local commdriver = TraitFactory.addTrait("CommDriver", getText("UI_trait_commdriver"), 0, getText("UI_trait_commdriverdesc"), true);
	commdriver:getFreeRecipes():add("Intermediate Mechanics");
	local enjoytheride = TraitFactory.addTrait("EnjoytheRide", getText("UI_trait_enjoytheride"), 0, getText("UI_trait_enjoytheridedesc"), true);		
	enjoytheride:getFreeRecipes():add("Advanced Mechanics");
	local usedtocorpses = TraitFactory.addTrait("UsedToCorpses", getText("UI_trait_usedtocorpses"), 0, getText("UI_trait_usedtocorpsesdesc"), true);
	local improvisedcleaning = TraitFactory.addTrait("ImprovisedCleaning", getText("UI_trait_improvisedcleaning"), 0, getText("UI_trait_improvisedcleaningdesc"), true);
	local priestspirit = TraitFactory.addTrait("priestspirit", getText("UI_trait_priestspirit"), 0, getText("UI_trait_priestspiritdesc"), true);	
	local woodaxemybeloved = TraitFactory.addTrait("WoodAxeMyBeloved", getText("UI_trait_woodaxemybeloved"), 0, getText("UI_trait_woodaxemybeloveddesc"), true);
	local demostronggrip = TraitFactory.addTrait("DemoStrongGrip", getText("UI_trait_demostronggrip"), 0, getText("UI_trait_demostronggripdesc"), true);
	local gasmanagement = TraitFactory.addTrait("GasManagement", getText("UI_trait_gasmanagement"), 0, getText("UI_trait_gasmanagementdesc"), true);	
	local bladetools = TraitFactory.addTrait("BladeTools", getText("UI_trait_bladetools"), 0, getText("UI_trait_bladetoolsdesc"), true);
	local minersendurance = TraitFactory.addTrait("MinersEndurance", getText("UI_trait_minersendurance"), 0, getText("UI_trait_minersendurancedesc"), true);
--	local rescuer = TraitFactory.addTrait("Rescuer", getText("UI_trait_rescuerendurance"), 0, getText("UI_trait_rescuerendurancedesc"), true);
	
--	local campingexp = TraitFactory.addTrait("CampingExp", getText("UI_trait_campingexp"), 0, getText("UI_trait_campingexpdesc"), true);		

	-- Compatability with Better Lockpicking Mod	
    if getActivatedMods():contains("betterLockpicking") then
	local nimblefingers = TraitFactory.addTrait("nimblefingers", getText("UI_trait_nimblefingers"), 0, getText("UI_trait_nimblefingersDesc"), true);	
    nimblefingers:getFreeRecipes():add("Lockpicking");
    nimblefingers:getFreeRecipes():add("Alarm check");
	nimblefingers:getFreeRecipes():add("Create BobbyPin");
	end
	-- Compatability with Pie's First Aid Overhaul
    if getActivatedMods():contains("piesfirstaidoverhaul") then
    TraitFactory.addTrait("DoctorPerk", getText("UI_prof_DoctorPerk"), 0, getText("UI_prof_DoctorPerk_Desc"), true);
    TraitFactory.addTrait("NursePerk", getText("UI_prof_NursePerk"), 0, getText("UI_prof_NursePerk_Desc"), true);
    TraitFactory.addTrait("FastMedical",  getText("UI_prof_FastMedical"), 0, getText("UI_prof_FastMedical_Desc"), true);
	end	
	-- Compatability with Braven's First Aid Overhaul	
    if getActivatedMods():contains("BB_FirstAidOverhaul") then
	TraitFactory.addTrait("MedicalPractitioner", getText("UI_trait_MedicalPractitioner"), 0, getText("UI_trait_MedicalPractitionerDesc"), true)
	end		
	
	
	------------------------
	--- MUTAL EXCLUSIVES ---
	------------------------	

	-- Vanilla traits
	TraitFactory.setMutualExclusive("ShortSighted", "EagleEyed");
	TraitFactory.setMutualExclusive("ShortSighted", "EagleEyed2");	
	TraitFactory.setMutualExclusive("EagleEyed", "EagleEyed2");	
	
	TraitFactory.setMutualExclusive("NightVision", "NightVision2");	
	TraitFactory.setMutualExclusive("FearoftheDark", "NightVision");
	TraitFactory.setMutualExclusive("FearoftheDark", "NightVision2");	
	TraitFactory.setMutualExclusive("FearoftheDark", "Desensitized");
	TraitFactory.setMutualExclusive("FearoftheDark", "Desensitized2");	
	TraitFactory.setMutualExclusive("FearoftheDark", "Brave");
	TraitFactory.setMutualExclusive("FearoftheDark", "Brave2");	

	TraitFactory.setMutualExclusive("SpeedDemon", "SpeedDemon2");
	TraitFactory.setMutualExclusive("SpeedDemon", "SundayDriver");
	TraitFactory.setMutualExclusive("SpeedDemon2", "SundayDriver");	
	TraitFactory.setMutualExclusive("CommDriver", "SundayDriver");	
	
	TraitFactory.setMutualExclusive("Dextrous", "AllThumbs");
	TraitFactory.setMutualExclusive("Dextrous2", "AllThumbs");
	TraitFactory.setMutualExclusive("Dextrous", "Dextrous2");	

--	TraitFactory.setMutualExclusive("GasManagement", "Dextrous");
	TraitFactory.setMutualExclusive("GasManagement", "AllThumbs");
	
	TraitFactory.setMutualExclusive("Organized", "Disorganized");
	TraitFactory.setMutualExclusive("Organized2", "Disorganized");
	TraitFactory.setMutualExclusive("Organized", "Organized2");

	TraitFactory.setMutualExclusive("Lucky", "Unlucky");	

	TraitFactory.setMutualExclusive("Handy2", "Handy");	
	TraitFactory.setMutualExclusive("Cook2", "Cook");
	TraitFactory.setMutualExclusive("Cook", "Scullion");	
	TraitFactory.setMutualExclusive("Cook2", "Scullion");
	
	TraitFactory.setMutualExclusive("Nutritionist2", "Nutritionist");

	TraitFactory.setMutualExclusive("Mechanics2", "Mechanics");
	
	TraitFactory.setMutualExclusive("Brave2", "Brave");	
	TraitFactory.setMutualExclusive("Brave2", "Desensitized");	
	TraitFactory.setMutualExclusive("Brave2", "Agoraphobic");
	TraitFactory.setMutualExclusive("Brave2", "Claustophobic");
	TraitFactory.setMutualExclusive("Brave2", "Hemophobic");	
	TraitFactory.setMutualExclusive("Brave2", "Cowardly");		
	
	TraitFactory.setMutualExclusive("GenExp2", "GenExp");
	TraitFactory.setMutualExclusive("StrongBack2", "StrongBack");
	TraitFactory.setMutualExclusive("StrongBack2", "WeakBack");
	TraitFactory.setMutualExclusive("StrongBack2", "Weak");
	
	TraitFactory.setMutualExclusive("Gardener", "Gardener2");
	TraitFactory.setMutualExclusive("FirstAid", "FirstAid2");		

	-- Compatability
	if getActivatedMods():contains("AliceSPack") then	
	TraitFactory.setMutualExclusive("WeakBack", "Strongback");
	TraitFactory.setMutualExclusive("WeakBack", "Strongback2");
	TraitFactory.setMutualExclusive("WeakBack", "Metalstrongback");	
	TraitFactory.setMutualExclusive("WeakBack", "Metalstrongback2");
	end

	TraitFactory.setMutualExclusive("Herbalist2", "Herbalist");	
	
	TraitFactory.setMutualExclusive("Formerscout", "Formerscout2");	

	TraitFactory.setMutualExclusive("FastHealer", "SlowHealer");
	TraitFactory.setMutualExclusive("ThickSkinned", "Thinskinned");	
	TraitFactory.setMutualExclusive("Resilient", "ProneToIllness");
	TraitFactory.setMutualExclusive("IronGut", "WeakStomach");
	
	TraitFactory.setMutualExclusive("LowThirst", "HighThirst");
	TraitFactory.setMutualExclusive("HeartyAppitite", "LightEater");
	
	TraitFactory.setMutualExclusive("HeartyAppitite", "Very Underweight");
	TraitFactory.setMutualExclusive("LightEater", "Obese");	
	
	TraitFactory.setMutualExclusive("FastLearner", "SlowLearner");
	TraitFactory.setMutualExclusive("FastReader", "SlowReader");
	TraitFactory.setMutualExclusive("FastReader2", "FastReader");
	TraitFactory.setMutualExclusive("FastReader2", "SlowReader");
	TraitFactory.setMutualExclusive("FastReader2", "Illiterate");	
	TraitFactory.setMutualExclusive("priestspirit", "Illiterate");
	
	TraitFactory.setMutualExclusive("Illiterate", "SlowReader");
	TraitFactory.setMutualExclusive("Illiterate", "FastReader");
	
	TraitFactory.setMutualExclusive("NeedsLessSleep", "NeedsMoreSleep");
	
	TraitFactory.setMutualExclusive("Conspicuous", "Inconspicuous");
	TraitFactory.setMutualExclusive("Conspicuous", "Inconspicuous2");	
	TraitFactory.setMutualExclusive("Inconspicuous", "Inconspicuous2");
	
	TraitFactory.setMutualExclusive("Clumsy", "Graceful");
	TraitFactory.setMutualExclusive("Clumsy", "Graceful2");
	
	TraitFactory.setMutualExclusive("Graceful", "Graceful2");
	TraitFactory.setMutualExclusive("Graceful2", "Obese");	
	
	TraitFactory.setMutualExclusive("Gymnast", "Gymnast2");
	TraitFactory.setMutualExclusive("Gymnast", "Clumsy");
	
--	Only Fitness
	TraitFactory.setMutualExclusive("Athletic", "Fit");
	TraitFactory.setMutualExclusive("Athletic", "Out of Shape");
	TraitFactory.setMutualExclusive("Athletic", "Unfit");
	
	TraitFactory.setMutualExclusive("Fit", "Out of Shape");
	TraitFactory.setMutualExclusive("Fit", "Unfit");
	
	TraitFactory.setMutualExclusive("Out of Shape", "Unfit");	

--	Only Strength
	TraitFactory.setMutualExclusive("Strong", "Stout");
	TraitFactory.setMutualExclusive("Strong", "Feeble");	
	TraitFactory.setMutualExclusive("Strong", "Weak");		
 
 	TraitFactory.setMutualExclusive("Stout", "Feeble");
	TraitFactory.setMutualExclusive("Stout", "Weak");
 
 	TraitFactory.setMutualExclusive("Feeble", "Weak");	

-- 	Only Weight
	TraitFactory.setMutualExclusive("Very Underweight", "Underweight");
	TraitFactory.setMutualExclusive("Very Underweight", "Obese");		
	TraitFactory.setMutualExclusive("Very Underweight", "Overweight");	

	TraitFactory.setMutualExclusive("Underweight", "Obese");
	TraitFactory.setMutualExclusive("Underweight", "Overweight");

	TraitFactory.setMutualExclusive("Obese", "Overweight");

--	Strength and fitness with weight
--	TraitFactory.setMutualExclusive("Strong", "Underweight");
	TraitFactory.setMutualExclusive("Strong", "Very Underweight");
	TraitFactory.setMutualExclusive("Stout", "Very Underweight");	

--	TraitFactory.setMutualExclusive("Athletic", "Underweight");
--	TraitFactory.setMutualExclusive("Athletic", "Very Underweight");
--	TraitFactory.setMutualExclusive("Athletic", "Overweight");
	TraitFactory.setMutualExclusive("Athletic", "Obese");

--	TraitFactory.setMutualExclusive("Fit", "Very Underweight");
--	TraitFactory.setMutualExclusive("Fit", "Overweight");
	TraitFactory.setMutualExclusive("Fit", "Obese");

--	TraitFactory.setMutualExclusive("Overweight", "Emaciated");
--	TraitFactory.setMutualExclusive("Obese", "Emaciated");	
	
	-- Hearing
	TraitFactory.setMutualExclusive("HardOfHearing", "KeenHearing");	
	TraitFactory.setMutualExclusive("Deaf", "HardOfHearing");
	TraitFactory.setMutualExclusive("Deaf", "KeenHearing");

	TraitFactory.setMutualExclusive("KeenHearing2", "KeenHearing");
	TraitFactory.setMutualExclusive("KeenHearing2", "HardOfHearing");	
	TraitFactory.setMutualExclusive("KeenHearing2", "Deaf");

	-- FirstAider2
	TraitFactory.setMutualExclusive("FirstAid2", "Hemophobic");	
	TraitFactory.setMutualExclusive("BladeTools", "Hemophobic");		

	-- BreathingTech
	TraitFactory.setMutualExclusive("BreathingTech", "BreathingTech2");			
	
	-- Panic traits
	TraitFactory.setMutualExclusive("Claustophobic", "Agoraphobic");
	-- AdrenalineJunkie
	TraitFactory.setMutualExclusive("AdrenalineJunkie", "AdrenalineJunkie2");
	-- Desensitized
	TraitFactory.setMutualExclusive("Desensitized", "AdrenalineJunkie");
	TraitFactory.setMutualExclusive("Desensitized2", "AdrenalineJunkie2");	
	TraitFactory.setMutualExclusive("Desensitized", "Hemophobic");
	TraitFactory.setMutualExclusive("Desensitized", "Cowardly");
	TraitFactory.setMutualExclusive("Desensitized", "Brave");
--	TraitFactory.setMutualExclusive("Desensitized", "Pacifist");	
	TraitFactory.setMutualExclusive("Desensitized", "Agoraphobic");
	TraitFactory.setMutualExclusive("Desensitized", "Claustophobic");

	TraitFactory.setMutualExclusive("Desensitized2", "AdrenalineJunkie");
	TraitFactory.setMutualExclusive("Desensitized2", "Hemophobic");
	TraitFactory.setMutualExclusive("Desensitized2", "Cowardly");
	TraitFactory.setMutualExclusive("Desensitized2", "Brave");
--	TraitFactory.setMutualExclusive("Desensitized2", "Pacifist");
--	TraitFactory.setMutualExclusive("Desensitized2", "Pacifist2");	
	TraitFactory.setMutualExclusive("Desensitized2", "Agoraphobic");
	TraitFactory.setMutualExclusive("Desensitized2", "Claustophobic");	
	
	TraitFactory.setMutualExclusive("Desensitized", "Desensitized2");	
	-- Pacifist 1 2
	TraitFactory.setMutualExclusive("Pacifist", "Pacifist2");
	TraitFactory.setMutualExclusive("Pacifist", "Shooter");
	TraitFactory.setMutualExclusive("Pacifist", "Shooter2");
	TraitFactory.setMutualExclusive("Pacifist", "ExpShooter");	
	TraitFactory.setMutualExclusive("Pacifist", "Sniper");	
	TraitFactory.setMutualExclusive("Pacifist", "Brawler");	
	TraitFactory.setMutualExclusive("Pacifist2", "Shooter");
	TraitFactory.setMutualExclusive("Pacifist2", "Shooter2");
	TraitFactory.setMutualExclusive("Pacifist2", "ExpShooter");		
	TraitFactory.setMutualExclusive("Pacifist2", "Sniper");
	TraitFactory.setMutualExclusive("Pacifist2", "Brawler");

	TraitFactory.setMutualExclusive("Cruelty", "Cruelty2");
	
	TraitFactory.setMutualExclusive("Pacifist", "Cruelty");	
	TraitFactory.setMutualExclusive("Pacifist2", "Cruelty");
	TraitFactory.setMutualExclusive("Pacifist", "Cruelty2");		
	
	TraitFactory.setMutualExclusive("Pacifist", "Hunter");	
	TraitFactory.setMutualExclusive("Pacifist2", "Hunter");	

	-- Shooters
	TraitFactory.setMutualExclusive("Shooter", "ExpShooter");
	
	-- Brave
	TraitFactory.setMutualExclusive("Brave", "Agoraphobic");
	TraitFactory.setMutualExclusive("Brave", "Claustophobic");
--	TraitFactory.setMutualExclusive("Brave", "Hemophobic");	
	TraitFactory.setMutualExclusive("Brave", "Cowardly");	

	-- Slack
	TraitFactory.setMutualExclusive("Slack", "Athletic");
	TraitFactory.setMutualExclusive("Slack", "Strong");
--	TraitFactory.setMutualExclusive("Slack", "Unfit");
--	TraitFactory.setMutualExclusive("Slack", "Weak");	
	TraitFactory.setMutualExclusive("Slack", "Taut");
	
	-- Taut
	TraitFactory.setMutualExclusive("Taut", "Unfit");
	TraitFactory.setMutualExclusive("Taut", "Weak");		
	
	-- TRIPPLE
--	TraitFactory.setMutualExclusive("MarathonRunner", "Relentless");		
--	TraitFactory.setMutualExclusive("MarathonRunner", "NinjaWay");	
--	TraitFactory.setMutualExclusive("Relentless", "NinjaWay");	

	-- AccMetabolism
	TraitFactory.setMutualExclusive("AccMetabolism", "LightEater");	
	TraitFactory.setMutualExclusive("AccMetabolism", "FragileHealth");		
	TraitFactory.setMutualExclusive("AccMetabolism", "Ectomorph");	
	TraitFactory.setMutualExclusive("AccMetabolism", "Endomorph");		
	-- FragileHealth
	TraitFactory.setMutualExclusive("FragileHealth", "Strong");
	TraitFactory.setMutualExclusive("FragileHealth", "Athletic");
	TraitFactory.setMutualExclusive("FragileHealth", "StrongBack");	
	TraitFactory.setMutualExclusive("FragileHealth", "StrongBack2");
	-- Endomorph-Ectomorph
	TraitFactory.setMutualExclusive("Ectomorph", "Endomorph");	
	-- Endomorph 
	TraitFactory.setMutualExclusive("Endomorph", "Underweight");		
	TraitFactory.setMutualExclusive("Endomorph", "Very Underweight");	
	TraitFactory.setMutualExclusive("Endomorph", "Athletic");		
	-- Ectomorph
	TraitFactory.setMutualExclusive("Ectomorph", "Overweight");		
	TraitFactory.setMutualExclusive("Ectomorph", "Obese");
	TraitFactory.setMutualExclusive("Ectomorph", "Strong");	
	
	-- MarathonRunner
	TraitFactory.setMutualExclusive("MarathonRunner", "Unfit");	
	TraitFactory.setMutualExclusive("MarathonRunner", "Obese");
	TraitFactory.setMutualExclusive("MarathonRunner", "Asthmatic");			
	-- Relentless
	TraitFactory.setMutualExclusive("Relentless", "Weak");
	TraitFactory.setMutualExclusive("Relentless", "Obese");	
	TraitFactory.setMutualExclusive("Relentless", "Unfit");			
	TraitFactory.setMutualExclusive("Relentless", "Very Underweight");
	TraitFactory.setMutualExclusive("Relentless", "Asthmatic");	
	TraitFactory.setMutualExclusive("Relentless2", "Relentless");	
--	TraitFactory.setMutualExclusive("Relentless2", "Weak");
--	TraitFactory.setMutualExclusive("Relentless2", "Obese");	
--	TraitFactory.setMutualExclusive("Relentless2", "Unfit");			
--	TraitFactory.setMutualExclusive("Relentless2", "Very Underweight");
	TraitFactory.setMutualExclusive("Relentless2", "Asthmatic");		
	-- NinjaWay	
	TraitFactory.setMutualExclusive("NinjaWay", "Conspicuous");	
	TraitFactory.setMutualExclusive("NinjaWay", "Clumsy");
	TraitFactory.setMutualExclusive("NinjaWay", "Obese");	
	TraitFactory.setMutualExclusive("NinjaWay", "Unfit");	
	TraitFactory.setMutualExclusive("NinjaWay", "Asthmatic");		
	-- Sneaky	
	TraitFactory.setMutualExclusive("Sneaky", "Conspicuous");
	-- Lightfooted
	TraitFactory.setMutualExclusive("Lightfooted", "Clumsy");
	-- Time traits	
	TraitFactory.setMutualExclusive("OwlPerson", "LarkPerson");
	-- SoreLegs
	TraitFactory.setMutualExclusive("SoreLegs", "MarathonRunner");	
	TraitFactory.setMutualExclusive("SoreLegs", "Hiker");
	TraitFactory.setMutualExclusive("SoreLegs", "Jogger");
	TraitFactory.setMutualExclusive("SoreLegs", "Gymnast");	
	TraitFactory.setMutualExclusive("SoreLegs", "Gymnast2");		
	-- WeakBack
	TraitFactory.setMutualExclusive("WeakBack", "StrongBack");
	TraitFactory.setMutualExclusive("WeakBack", "Strong");
	-- StrongBack
	TraitFactory.setMutualExclusive("StrongBack", "Weak");
	-- Bleeding
	TraitFactory.setMutualExclusive("LiquidBlood", "ThickBlood");	
	-- Allergic
	TraitFactory.setMutualExclusive("Allergic", "Resilient");	
	-- SOAlcoholic
--	TraitFactory.setMutualExclusive("SOAlcoholic", "Optimist");
--	TraitFactory.setMutualExclusive("SOAlcoholic", "EnjoytheRide");		
	-- DEPRESSIVE AND POSITIVE MOOD
	TraitFactory.setMutualExclusive("Depressive", "Optimist");
	-- SNIPER
	TraitFactory.setMutualExclusive("Sniper", "ShortSighted");	
	-- SHOOTERS
	TraitFactory.setMutualExclusive("Shooter", "Shooter2");	
	-- LessSweaty and HighSweaty
	TraitFactory.setMutualExclusive("LessSweaty", "HighSweaty");
	-- Outdoorsman
	TraitFactory.setMutualExclusive("Outdoorsman", "Outdoorsman2");
	-- Hiker
	TraitFactory.setMutualExclusive("Hiker", "Agoraphobic");	
	
	
	-- Alcholic if GreenFire mod active
	if getActivatedMods():contains("jiggasGreenfireMod") == true then		
	TraitFactory.setMutualExclusive("SOAlcoholic", "Alcoholic");
	end	
	
	TraitFactory.sortList();
		
		local traitList = TraitFactory.getTraits()
	for i = 1, traitList:size() do
		local trait = traitList:get(i - 1)
		BaseGameCharacterDetails.SetTraitDescription(trait)
	end

end

SOBaseGameCharacterDetails.DoProfessions = function()

	local SleepEnabled = (isClient() or isServer()) and getServerOptions():getBoolean("SleepAllowed") and getServerOptions():getBoolean("SleepNeeded")

	-----------------------------
	--- OCCUPATIONS OVERHAUL ---
	-----------------------------

	-- UNEMPLOYED
	local unemployed = ProfessionFactory.addProfession("unemployed", getText("UI_prof_unemployed"), "profession_unemployed", 10);

	-- FIRE OFFICER
	local fireofficer = ProfessionFactory.addProfession("fireofficer", getText("UI_prof_fireoff"), "profession_fireofficer2", -4, getText("UI_profdesc_fireoff"));	
	fireofficer:addXPBoost(Perks.Fitness, 1)
	fireofficer:addXPBoost(Perks.Strength, 1)
	fireofficer:addXPBoost(Perks.Axe, 1)
	fireofficer:addXPBoost(Perks.Sprinting, 1)	
	fireofficer:addFreeTrait("Axeman");
--	fireofficer:addFreeTrait("Rescuer");
	
	-- POLICE OFFICER
	local policeofficer = ProfessionFactory.addProfession("policeofficer", getText("UI_prof_policeoff"), "profession_policeofficer2", -4, getText("UI_profdesc_policeoff"));
	policeofficer:addXPBoost(Perks.Aiming, 2)
	policeofficer:addXPBoost(Perks.Reloading, 2)
	policeofficer:addXPBoost(Perks.Nimble, 1)
	policeofficer:addXPBoost(Perks.SmallBlunt, 1)

	-- PARK RANGER
	local parkranger = ProfessionFactory.addProfession("parkranger", getText("UI_prof_parkranger"), "profession_parkranger2", 2, getText("UI_profdesc_parkranger"));
	parkranger:addXPBoost(Perks.PlantScavenging, 2)	
	parkranger:addXPBoost(Perks.Trapping, 1)
	parkranger:getFreeRecipes():add("Make Stick Trap");
	parkranger:getFreeRecipes():add("Make Snare Trap");
	parkranger:getFreeRecipes():add("Make Wooden Box Trap");
	parkranger:getFreeRecipes():add("Make Trap Box");
	parkranger:getFreeRecipes():add("Make Cage Trap");
	if getActivatedMods():contains("Woodcutting Skill") then	
		parkranger:addXPBoost(Perks.Woodcutting, 2);
	end	

	-- CONSTRUCTION WORKER
	local constructionworker = ProfessionFactory.addProfession("constructionworker", getText("UI_prof_constructionworker"), "profession_constructionworker2", 0, getText("UI_profdesc_constructionworker"));
	constructionworker:addXPBoost(Perks.Woodwork, 1)
	constructionworker:addXPBoost(Perks.SmallBlunt, 2)
	constructionworker:addFreeTrait("StrongBack2");		

	-- SECURITY GUARD
	local securityguard = ProfessionFactory.addProfession("securityguard", getText("UI_prof_securityguard"), "profession_securityguard2", 1, getText("UI_profdesc_securityguard"));
	securityguard:addXPBoost(Perks.Lightfoot, 1)	
	securityguard:addXPBoost(Perks.Sprinting, 1)
	securityguard:addFreeTrait("NightOwl");
	securityguard:addFreeTrait("KeenHearing2");		

	-- CARPENTER
	local carpenter = ProfessionFactory.addProfession("carpenter", getText("UI_prof_Carpenter"), "profession_hammer2", -1, getText("UI_profdesc_Carpenter"));
	carpenter:addXPBoost(Perks.Maintenance, 1)	
	carpenter:addXPBoost(Perks.SmallBlunt, 1)	
	carpenter:addXPBoost(Perks.Woodwork, 2)	
	carpenter:addFreeTrait("Handy2");

	-- BURGLAR
	local burglar = ProfessionFactory.addProfession("burglar", getText("UI_prof_Burglar"), "profession_burglar2", 0, getText("UI_profdesc_Burglar"));
	burglar:addXPBoost(Perks.Nimble, 1)
	burglar:addXPBoost(Perks.Lightfoot, 1)
	burglar:addXPBoost(Perks.Sneak, 1)	
	burglar:addFreeTrait("Burglar");	
	if getActivatedMods():contains("betterLockpicking") then	
--		burglar:addXPBoost(Perks.Lockpicking, 2)	
		burglar:addFreeTrait("nimblefingers")
		burglar:getFreeRecipes():add("Lockpicking");
		burglar:getFreeRecipes():add("Alarm check");
		burglar:getFreeRecipes():add("Create BobbyPin");		
	end	

	-- CHEF
	local chef = ProfessionFactory.addProfession("chef", getText("UI_prof_Chef"), "profession_chef2", 6, getText("UI_profdesc_Chef"));
	chef:addXPBoost(Perks.Cooking, 4)	
    chef:getFreeRecipes():add("Make Cake Batter");
    chef:getFreeRecipes():add("Make Pie Dough");
    chef:getFreeRecipes():add("Make Bread Dough");
    chef:getFreeRecipes():add("Make Biscuits");
    chef:getFreeRecipes():add("Make Chocolate Cookie Dough");
    chef:getFreeRecipes():add("Make Chocolate Chip Cookie Dough");
    chef:getFreeRecipes():add("Make Oatmeal Cookie Dough");
    chef:getFreeRecipes():add("Make Shortbread Cookie Dough");
    chef:getFreeRecipes():add("Make Sugar Cookie Dough");
    chef:getFreeRecipes():add("Make Pizza");
	chef:addFreeTrait("Cook2");
	chef:addFreeTrait("Nutritionist2");	

	-- REPAIRMAN
	local repairman = ProfessionFactory.addProfession("repairman", getText("UI_prof_Repairman"), "profession_repairman2", 1, getText("UI_profdesc_Repairman"));	
	repairman:addXPBoost(Perks.Woodwork, 1)
	repairman:addXPBoost(Perks.Maintenance, 2)
	repairman:addFreeTrait("Handy2");

	-- FARMER
	local farmer = ProfessionFactory.addProfession("farmer", getText("UI_prof_Farmer"), "profession_farmer2", 0, getText("UI_profdesc_Farmer"));
	farmer:addXPBoost(Perks.PlantScavenging, 1)
	farmer:addXPBoost(Perks.Farming, 4)	
	farmer:addXPBoost(Perks.Spear, 1)	
	farmer:addFreeTrait("Gardener2");	
	farmer:getFreeRecipes():add("Make Mildew Cure");
	farmer:getFreeRecipes():add("Make Flies Cure");	
	if getActivatedMods():contains("Woodcutting Skill") then	
		farmer:addXPBoost(Perks.Woodcutting, 1);
	end	

	-- FISHERMAN
	local fisherman = ProfessionFactory.addProfession("fisherman", getText("UI_prof_Fisherman"), "profession_fisher2", 3, getText("UI_profdesc_Fisherman"));
	fisherman:addXPBoost(Perks.Fishing, 2)
	fisherman:getFreeRecipes():add("Make Fishing Rod");
	fisherman:getFreeRecipes():add("Fix Fishing Rod");
	fisherman:getFreeRecipes():add("Get Wire Back");
	fisherman:getFreeRecipes():add("Make Fishing Net");	
	fisherman:addFreeTrait("Outdoorsman2");		

	-- DOCTOR
	local doctor = ProfessionFactory.addProfession("doctor", getText("UI_prof_Doctor"), "profession_doctor2", 7, getText("UI_profdesc_Doctor"));
	doctor:addXPBoost(Perks.Doctor, 4)
	doctor:addFreeTrait("FirstAid2");
    if getActivatedMods():contains("piesfirstaidoverhaul") then
		doctor:addFreeTrait("DoctorPerk")
	end
    if getActivatedMods():contains("BB_FirstAidOverhaul") then
		doctor:addFreeTrait("MedicalPractitioner")
	end	

	-- VETERAN
	local veteran = ProfessionFactory.addProfession("veteran", getText("UI_prof_Veteran"), "profession_veteran2", -8, getText("UI_profdesc_Veteran"));
	veteran:addXPBoost(Perks.Reloading, 2)
	veteran:addXPBoost(Perks.Aiming, 2)
	veteran:addXPBoost(Perks.SmallBlade, 1)	
	veteran:addFreeTrait("Desensitized");
	if getActivatedMods():contains("AliceSPack") then	
		veteran:addFreeTrait("Metalstrongback2");
	end
	
	-- NURSE
	local nurse = ProfessionFactory.addProfession("nurse", getText("UI_prof_Nurse"), "profession_nurse", 6, getText("UI_profdesc_Nurse"));
	nurse:addXPBoost(Perks.Lightfoot, 1)
	nurse:addXPBoost(Perks.Doctor, 2)
    nurse:addFreeTrait("NightOwl")	
    if getActivatedMods():contains("piesfirstaidoverhaul") then
		nurse:addFreeTrait("NursePerk")
		nurse:getFreeRecipes():add("Make Cotton Ball (Nurse)")
		nurse:getFreeRecipes():add("Make Suture Needles (Nurse)")
		nurse:getFreeRecipes():add("Make Disinfectant (Nurse)")
	end	
    if getActivatedMods():contains("BB_FirstAidOverhaul") then
		nurse:addFreeTrait("MedicalPractitioner")
	end		

	-- LUMBERJACK
	local lumberjack = ProfessionFactory.addProfession("lumberjack", getText("UI_prof_Lumberjack"), "profession_lumberjack", -5, getText("UI_profdesc_Lumberjack"));
	lumberjack:addXPBoost(Perks.Strength, 1)
	lumberjack:addXPBoost(Perks.Axe, 2)
	lumberjack:addFreeTrait("Axeman");
	lumberjack:addFreeTrait("WoodAxeMyBeloved");
	if getActivatedMods():contains("AliceSPack") then	
		lumberjack:addFreeTrait("Metalstrongback2");
	end
	if getActivatedMods():contains("Woodcutting Skill") then	
		lumberjack:addXPBoost(Perks.Woodcutting, 3);
	end	

	-- FITNESS INSTRUCTOR
	local fitnessInstructor = ProfessionFactory.addProfession("fitnessInstructor", getText("UI_prof_FitnessInstructor"), "profession_fitnessinstructor", -3, getText("UI_profdesc_FitnessInstructor"));
	fitnessInstructor:addXPBoost(Perks.Sprinting, 2)
	fitnessInstructor:addXPBoost(Perks.Fitness, 3)
	fitnessInstructor:addFreeTrait("Nutritionist2");	
	if getActivatedMods():contains("AliceSPack") then	
		fitnessInstructor:addFreeTrait("Strongback2");
	end	
	
	-- BURGER FLIPPER
	local burger = ProfessionFactory.addProfession("burgerflipper", getText("UI_prof_BurgerFlipper"), "profession_burgerflipper", 3, getText("UI_profdesc_BurgerFlipper"));
	burger:addXPBoost(Perks.Cooking, 1)
	burger:addXPBoost(Perks.Maintenance, 1)	
	burger:addXPBoost(Perks.Nimble, 1)

	-- ELECTRICIAN
	local electrician = ProfessionFactory.addProfession("electrician", getText("UI_prof_Electrician"), "profession_electrician", 5, getText("UI_profdesc_Electrician"));
	electrician:addXPBoost(Perks.Electricity, 2)
	electrician:getFreeRecipes():add("Make Remote Controller V1");
	electrician:getFreeRecipes():add("Make Remote Controller V2");
	electrician:getFreeRecipes():add("Make Remote Controller V3");
	electrician:getFreeRecipes():add("Make Remote Trigger");
	electrician:getFreeRecipes():add("Make Timer");
	electrician:getFreeRecipes():add("Craft Makeshift Radio");
	electrician:getFreeRecipes():add("Craft Makeshift HAM Radio");
	electrician:getFreeRecipes():add("Craft Makeshift Walkie Talkie");
	electrician:getFreeRecipes():add("Generator");	
	electrician:addFreeTrait("GenExp2");

	-- ENGINEER
	local engineer = ProfessionFactory.addProfession("engineer", getText("UI_prof_Engineer"), "profession_engineer", 0, getText("UI_profdesc_Engineer"));
	engineer:addXPBoost(Perks.Woodwork, 1)
	engineer:addXPBoost(Perks.Electricity, 1)
	engineer:getFreeRecipes():add("Make Aerosol bomb");
	engineer:getFreeRecipes():add("Make Flame bomb");
	engineer:getFreeRecipes():add("Make Pipe bomb");
	engineer:getFreeRecipes():add("Make Noise generator");
	engineer:getFreeRecipes():add("Make Smoke Bomb");	
	engineer:addFreeTrait("Burglar");

	-- METALWORKER
	local metalworker = ProfessionFactory.addProfession("metalworker", getText("UI_prof_MetalWorker"), "profession_metalworker", 2, getText("UI_profdesc_MetalWorker"));
	metalworker:addXPBoost(Perks.MetalWelding, 2)
	metalworker:addXPBoost(Perks.Maintenance, 1)	
	metalworker:getFreeRecipes():add("Make Metal Walls");
	metalworker:getFreeRecipes():add("Make Metal Fences");
	metalworker:getFreeRecipes():add("Make Metal Containers");
	metalworker:getFreeRecipes():add("Make Metal Sheet");
	metalworker:getFreeRecipes():add("Make Small Metal Sheet");
	metalworker:getFreeRecipes():add("Make Metal Roof");

	-- MECHANICS
	local mechanics = ProfessionFactory.addProfession("mechanics", getText("UI_prof_Mechanics"), "profession_mechanic", 4, getText("UI_profdesc_mechanics"))
	mechanics:addXPBoost(Perks.Mechanics, 2)
	mechanics:getFreeRecipes():add("Basic Mechanics");
	mechanics:getFreeRecipes():add("Intermediate Mechanics");
	mechanics:getFreeRecipes():add("Advanced Mechanics");
	mechanics:addFreeTrait("Mechanics2");	

	-- SOTO OCCUPATIONS --
	
	-- TAILOR
	local tailor = ProfessionFactory.addProfession("tailor", getText("UI_prof_tailor"), "icon_tailor", 4, getText("UI_profdesc_tailor"))
	tailor:addXPBoost(Perks.Tailoring, 2)
	tailor:addFreeTrait("Dextrous2");
	
	-- DELIVERYMAN
	local deliveryman = ProfessionFactory.addProfession("deliveryman", getText("UI_prof_deliveryman"), "icon_deliveryman", -2, getText("UI_profdesc_deliveryman"))
	deliveryman:addXPBoost(Perks.Nimble, 1)
	deliveryman:addXPBoost(Perks.Sprinting, 2)
	deliveryman:addFreeTrait("Organized2");	

	-- LOADER
	local loader = ProfessionFactory.addProfession("loader", getText("UI_prof_loader"), "icon_loader", -1, getText("UI_profdesc_loader"))
	loader:addXPBoost(Perks.Strength, 2)
	loader:addXPBoost(Perks.Nimble, 1)
	loader:addFreeTrait("StrongBack2");
	if getActivatedMods():contains("AliceSPack") then	
		loader:addFreeTrait("Metalstrongback2");
	end	
	
	-- TRUCK DRIVER
	local trucker = ProfessionFactory.addProfession("trucker", getText("UI_prof_trucker"), "icon_trucker", 4, getText("UI_profdesc_trucker"))
	trucker:addXPBoost(Perks.Mechanics, 1)
	trucker:addXPBoost(Perks.Maintenance, 1)
	trucker:addFreeTrait("CommDriver");
    if getActivatedMods():contains("DrivingSkill") then
		trucker:addXPBoost(Perks.Driving, 2)	
	end			
	
	-- SOLDIER
	local soldier = ProfessionFactory.addProfession("soldier", getText("UI_prof_soldier"), "icon_soldier", -8, getText("UI_profdesc_soldier"))
	soldier:addXPBoost(Perks.Strength, 1)
	soldier:addXPBoost(Perks.Fitness, 1)
	soldier:addXPBoost(Perks.Reloading, 2)	
	soldier:addXPBoost(Perks.Aiming, 2)
	soldier:addXPBoost(Perks.SmallBlade, 1)	
	soldier:addFreeTrait("NightOwl");	
	if getActivatedMods():contains("AliceSPack") then	
		soldier:addFreeTrait("Metalstrongback2");
	end		

	-- BOTANIST
	local botanist = ProfessionFactory.addProfession("botanist", getText("UI_prof_botanist"), "icon_botanist", 1, getText("UI_profdesc_botanist"))
	botanist:addXPBoost(Perks.Farming, 1)	
	botanist:addXPBoost(Perks.PlantScavenging, 2)
	botanist:addFreeTrait("Herbalist2");
	botanist:getFreeRecipes():add("Herbalist");	
	
	-- GRAVE DIGGER
	local graveman = ProfessionFactory.addProfession("graveman", getText("UI_prof_graveman"), "icon_graveman", -2, getText("UI_profdesc_graveman"))	
	graveman:addXPBoost(Perks.Strength, 1)		
	graveman:addXPBoost(Perks.Blunt, 1)
	graveman:addXPBoost(Perks.Maintenance, 1)	
	graveman:addFreeTrait("UsedToCorpses");
	
	-- DANCER
	local dancerocc = ProfessionFactory.addProfession("dancerocc", getText("UI_prof_dancerocc"), "icon_dancerocc", -2, getText("UI_profdesc_dancerocc"))	
	dancerocc:addXPBoost(Perks.Fitness, 1)
	dancerocc:addXPBoost(Perks.Lightfoot, 1)
	dancerocc:addXPBoost(Perks.Nimble, 2)	
	dancerocc:addFreeTrait("Graceful2");
	dancerocc:addFreeTrait("Gymnast2");	
    if getActivatedMods():contains("Lifestyle") then	
		dancerocc:addXPBoost(Perks.Dancing, 2)
	end
--	Dancing recipes from True Actions Act 3 - Dancing 
    if getActivatedMods():contains("TrueActionsDancing") then
		dancerocc:getFreeRecipes():add("BobTA African Noodle");	
		dancerocc:getFreeRecipes():add("BobTA African Rainbow");	
		dancerocc:getFreeRecipes():add("BobTA Arms Hip Hop");
		dancerocc:getFreeRecipes():add("BobTA Arm Push");	
		dancerocc:getFreeRecipes():add("BobTA Arm Wave One");	
		dancerocc:getFreeRecipes():add("BobTA Arm Wave Two");	
		dancerocc:getFreeRecipes():add("BobTA Around The World");	
		dancerocc:getFreeRecipes():add("BobTA Bboy Hip Hop One");	
		dancerocc:getFreeRecipes():add("BobTA Bboy Hip Hop Three");
		dancerocc:getFreeRecipes():add("BobTA Bboy Hip Hop Two");	
		dancerocc:getFreeRecipes():add("BobTA Body Wave");	
		dancerocc:getFreeRecipes():add("BobTA Booty Step");		
		dancerocc:getFreeRecipes():add("BobTA Breakdance Brooklyn Uprock");	
		dancerocc:getFreeRecipes():add("BobTA Cabbage Patch");	
		dancerocc:getFreeRecipes():add("BobTA Can Can");
		dancerocc:getFreeRecipes():add("BobTA Chicken");	
		dancerocc:getFreeRecipes():add("BobTA Crazy Legs");	
		dancerocc:getFreeRecipes():add("BobTA Defile De Samba Parade");		
		dancerocc:getFreeRecipes():add("BobTA Hokey Pokey");	
		dancerocc:getFreeRecipes():add("BobTA Kick Step");	
		dancerocc:getFreeRecipes():add("BobTA Macarena");
		dancerocc:getFreeRecipes():add("BobTA Maraschino");	
		dancerocc:getFreeRecipes():add("BobTA MoonWalk One");	
		dancerocc:getFreeRecipes():add("BobTA Northern Soul Spin");		
		dancerocc:getFreeRecipes():add("BobTA Northern Soul Spin On Floor");	
		dancerocc:getFreeRecipes():add("BobTA Raise The Roof");	
		dancerocc:getFreeRecipes():add("BobTA Really Twirl");	
		dancerocc:getFreeRecipes():add("BobTA Rib Pops");	
		dancerocc:getFreeRecipes():add("BobTA Rockette Kick");	
		dancerocc:getFreeRecipes():add("BobTA Rumba Dancing");	
		dancerocc:getFreeRecipes():add("BobTA Running Man One");	
		dancerocc:getFreeRecipes():add("BobTA Running Man Three");	
		dancerocc:getFreeRecipes():add("BobTA Running Man Two");	
		dancerocc:getFreeRecipes():add("BobTA Salsa");		
		dancerocc:getFreeRecipes():add("BobTA Salsa Double Twirl");	
		dancerocc:getFreeRecipes():add("BobTA Salsa Double Twirl and Clap");	
		dancerocc:getFreeRecipes():add("BobTA Salsa Side to Side");	
		dancerocc:getFreeRecipes():add("BobTA Shimmy");	
		dancerocc:getFreeRecipes():add("BobTA Shim Sham");	
		dancerocc:getFreeRecipes():add("BobTA Shuffling");	
		dancerocc:getFreeRecipes():add("BobTA Side to Side");	
		dancerocc:getFreeRecipes():add("BobTA Twist One");	
		dancerocc:getFreeRecipes():add("BobTA Twist Two");	
		dancerocc:getFreeRecipes():add("BobTA Uprock Indian Step");	
		dancerocc:getFreeRecipes():add("BobTA YMCA");	
    end	
	
	-- PRIEST
	local priestocc = ProfessionFactory.addProfession("priestocc", getText("UI_prof_priestocc"), "icon_priestocc", 12, getText("UI_profdesc_priestocc"))	
	priestocc:addXPBoost(Perks.Lightfoot, 2)
	priestocc:getFreeRecipes():add("Write A Prayer");	
	priestocc:addFreeTrait("Pacifist2");
	priestocc:addFreeTrait("priestspirit");	
	
	-- WEIGHTLIFTING INSTRUCTOR
	local heavyathinstructor = ProfessionFactory.addProfession("heavyathinstructor", getText("UI_prof_heavyathinstructor"), "icon_heavyathinstructor", -4, getText("UI_profdesc_heavyathinstructor"));
	heavyathinstructor:addXPBoost(Perks.Strength, 3)
	heavyathinstructor:addXPBoost(Perks.Fitness, 1)	
	heavyathinstructor:addFreeTrait("StrongBack2");	
	heavyathinstructor:addFreeTrait("Nutritionist2");
	if getActivatedMods():contains("AliceSPack") then	
		heavyathinstructor:addFreeTrait("Metalstrongback2");
	end		
	
	-- DETECTIVE
	local detective = ProfessionFactory.addProfession("detective", getText("UI_prof_detective"), "icon_detective", 0, getText("UI_profdesc_detective"))	
	detective:addXPBoost(Perks.Sneak, 1)
	detective:addXPBoost(Perks.Aiming, 1)	
	detective:addXPBoost(Perks.Reloading, 1)		
	detective:addXPBoost(Perks.PlantScavenging, 1)	
    if getActivatedMods():contains("ScavengingSkill") or getActivatedMods():contains("ScavengingSkillFixed") then
		detective:addXPBoost(Perks.Scavenging, 1)	
	end
	
	-- SCHOOL TEACHER
	local teacherocc = ProfessionFactory.addProfession("teacherocc", getText("UI_prof_teacherocc"), "icon_teacherocc", 8, getText("UI_profdesc_teacherocc"))
	teacherocc:addXPBoost(Perks.Lightfoot, 1)
	teacherocc:addFreeTrait("FastReader2");	
	teacherocc:addFreeTrait("LifelongLearner");		

	-- JANITOR
	local cleanerman = ProfessionFactory.addProfession("cleanerman", getText("UI_prof_cleanerman"), "icon_cleanerman", 2, getText("UI_profdesc_cleanerman"))
	cleanerman:addXPBoost(Perks.Spear, 1)
	cleanerman:addXPBoost(Perks.Maintenance, 1)
	cleanerman:addFreeTrait("ImprovisedCleaning");	
	cleanerman:getFreeRecipes():add("Make Cleaning Liquid");
	cleanerman:getFreeRecipes():add("Make Bleach");
    if getActivatedMods():contains("ScavengingSkill") or getActivatedMods():contains("ScavengingSkillFixed") then
		cleanerman:addXPBoost(Perks.Scavenging, 1)	
	end		

	-- STUNTMAN
	local stuntman = ProfessionFactory.addProfession("stuntman", getText("UI_prof_stuntman"), "icon_stuntman", -1, getText("UI_profdesc_stuntman"))
	stuntman:addXPBoost(Perks.Sprinting, 1)
	stuntman:addXPBoost(Perks.Fitness, 1)
	stuntman:addXPBoost(Perks.Nimble, 1)	
	stuntman:addFreeTrait("AdrenalineJunkie2");
	
	-- GAS STATION OPERATOR
	local gasstationoperator = ProfessionFactory.addProfession("gasstationoperator", getText("UI_prof_gasstationoperator"), "icon_gasstationoperator", 0, getText("UI_profdesc_gasstationoperator"))
	gasstationoperator:addXPBoost(Perks.Nimble, 1)
	gasstationoperator:addXPBoost(Perks.Maintenance, 1)
	gasstationoperator:addXPBoost(Perks.Mechanics, 1)	
	gasstationoperator:addFreeTrait("GasManagement");		

	-- CAMP COUNSELOR
	local campcouns = ProfessionFactory.addProfession("campcouns", getText("UI_prof_campcouns"), "icon_campcouns", 1, getText("UI_profdesc_campcouns"))
	campcouns:addXPBoost(Perks.Tailoring, 1)	
	campcouns:addXPBoost(Perks.Doctor, 1)
	campcouns:addXPBoost(Perks.Fishing, 1)	
	campcouns:addXPBoost(Perks.PlantScavenging, 1)
	campcouns:addFreeTrait("Formerscout2");	
	campcouns:getFreeRecipes():add("Make Fishing Rod");
	campcouns:getFreeRecipes():add("Fix Fishing Rod");
	campcouns:getFreeRecipes():add("Get Wire Back");	
--	campcouns:addFreeTrait("SOCamper");		
	if getActivatedMods():contains("Woodcutting Skill") then	
		campcouns:addXPBoost(Perks.Woodcutting, 2);
	end	

	-- DRAG RACER
	local dragracerocc = ProfessionFactory.addProfession("dragracerocc", getText("UI_prof_dragracerocc"), "icon_dragracerocc", 3, getText("UI_profdesc_dragracerocc"))
	dragracerocc:addXPBoost(Perks.Nimble, 1)
	dragracerocc:addXPBoost(Perks.Mechanics, 1)
	dragracerocc:addFreeTrait("SpeedDemon2");
	dragracerocc:addFreeTrait("EnjoytheRide");
	dragracerocc:getFreeRecipes():add("Advanced Mechanics");
    if getActivatedMods():contains("DrivingSkill") then
		dragracerocc:addXPBoost(Perks.Driving, 2)	
	end			
	
	-- JUNKYARD WORKER
	local junkyardworker = ProfessionFactory.addProfession("junkyardworker", getText("UI_prof_junkyardworker"), "icon_junkyardworker", 4, getText("UI_profdesc_junkyardworker"))
	junkyardworker:addXPBoost(Perks.Mechanics, 1)	
	junkyardworker:addXPBoost(Perks.MetalWelding, 1)
	junkyardworker:getFreeRecipes():add("Make Metal Fences");
	junkyardworker:getFreeRecipes():add("Make Metal Sheet");
	junkyardworker:getFreeRecipes():add("Make Small Metal Sheet");
    if getActivatedMods():contains("ScavengingSkill") or getActivatedMods():contains("ScavengingSkillFixed") then
		junkyardworker:addXPBoost(Perks.Scavenging, 1)	
	end	
	
	-- LIFEGUARD
	local lifeguard = ProfessionFactory.addProfession("lifeguard", getText("UI_prof_lifeguard"), "icon_lifeguard", 0, getText("UI_profdesc_lifeguard"))
	lifeguard:addXPBoost(Perks.Fitness, 1)	
	lifeguard:addXPBoost(Perks.Doctor, 1)
	lifeguard:addXPBoost(Perks.Sprinting, 1)	
	lifeguard:addFreeTrait("BreathingTech");		
	lifeguard:addFreeTrait("EagleEyed2");
    if getActivatedMods():contains("BB_FirstAidOverhaul") then
		lifeguard:addFreeTrait("MedicalPractitioner")
	end			
--	lifeguard:getFreeRecipes():add("Make Breathing Bag");	

	-- DEMOLITION WORKER
	local demoworker = ProfessionFactory.addProfession("demoworker", getText("UI_prof_demoworker"), "icon_demoworker", -2, getText("UI_profdesc_demoworker"))
	demoworker:addXPBoost(Perks.Strength, 1)		
	demoworker:addXPBoost(Perks.Blunt, 2)
	demoworker:addFreeTrait("DemoStrongGrip");	
	
	-- BUTCHER
	local butcherocc = ProfessionFactory.addProfession("butcherocc", getText("UI_prof_butcherocc"), "icon_butcherocc", 3, getText("UI_profdesc_butcherocc"))
	butcherocc:addXPBoost(Perks.SmallBlade, 1)
	butcherocc:addXPBoost(Perks.LongBlade, 1)
	butcherocc:addFreeTrait("BladeTools");

	-- PAPARAZZI
	local paparazziocc = ProfessionFactory.addProfession("paparazziocc", getText("UI_prof_paparazziocc"), "icon_paparazziocc", 3, getText("UI_profdesc_paparazziocc"))
	paparazziocc:addXPBoost(Perks.Lightfoot, 1)
	paparazziocc:addXPBoost(Perks.Sneak, 2)
	paparazziocc:addFreeTrait("Inconspicuous2");

	-- MINER
	local minerocc = ProfessionFactory.addProfession("minerocc", getText("UI_prof_minerocc"), "icon_minerocc", -3, getText("UI_profdesc_minerocc"))
	minerocc:addXPBoost(Perks.Axe, 1)
	minerocc:addXPBoost(Perks.Maintenance, 1)
	minerocc:addXPBoost(Perks.Fitness, 1)	
	minerocc:addFreeTrait("NightVision2");	
--	minerocc:addFreeTrait("Relentless2");
	minerocc:addFreeTrait("MinersEndurance");
	
	-- STORE EMPLOYEE
	local cashierocc = ProfessionFactory.addProfession("cashierocc", getText("UI_prof_cashierocc"), "icon_cashierocc", 4, getText("UI_profdesc_cashierocc"))
	cashierocc:addXPBoost(Perks.Maintenance, 1)
	cashierocc:addXPBoost(Perks.Lightfoot, 1)	
	cashierocc:addFreeTrait("Dextrous2");	
	
	-- CRIMINAL
	local criminalocc = ProfessionFactory.addProfession("criminalocc", getText("UI_prof_criminalocc"), "icon_criminalocc", -1, getText("UI_profdesc_criminalocc"))
	criminalocc:addXPBoost(Perks.SmallBlade, 1)
	criminalocc:addXPBoost(Perks.Nimble, 1)
	criminalocc:addXPBoost(Perks.Sprinting, 1)
	criminalocc:addFreeTrait("Cruelty2");		
	
	-- ANIMAL CONTROL OFFICER
	local animalcontrolofficer = ProfessionFactory.addProfession("animalcontrolofficer", getText("UI_prof_animalcontrolofficer"), "icon_animalcontrolofficer", 0, getText("UI_profdesc_animalcontrolofficer"))
	animalcontrolofficer:addXPBoost(Perks.Trapping, 2)	
	animalcontrolofficer:addXPBoost(Perks.Sprinting, 1)
	animalcontrolofficer:addXPBoost(Perks.Fitness, 1)	
	animalcontrolofficer:getFreeRecipes():add("Make Stick Trap");
	animalcontrolofficer:getFreeRecipes():add("Make Snare Trap");
	animalcontrolofficer:getFreeRecipes():add("Make Wooden Box Trap");
	animalcontrolofficer:getFreeRecipes():add("Make Trap Box");
	animalcontrolofficer:getFreeRecipes():add("Make Cage Trap");
    if getActivatedMods():contains("ScavengingSkill") or getActivatedMods():contains("ScavengingSkillFixed") then
		animalcontrolofficer:addXPBoost(Perks.Scavenging, 1)	
	end		
	
	-- OCCUPATIONS DESC
	local profList = ProfessionFactory.getProfessions()
		for i = 1, profList:size() do
		local prof = profList:get(i - 1)
		BaseGameCharacterDetails.SetProfessionDescription(prof)
	end
	
end

SOBaseGameCharacterDetails.DoNewCharacterInitializations = function(playernum, character)
	local player = getSpecificPlayer(playernum);

	-- BRAVE BONUS
	if player:HasTrait("Brave") or player:HasTrait("Brave2") then
		if player:getModData().SOBraveBonus == nil then
		player:getModData().SOBraveBonus = 1;
		end	
	end

	-- COWARDLY PENALTY
	if player:HasTrait("Cowardly") then
		if player:getModData().SOCowardlyPenalty == nil then
		player:getModData().SOCowardlyPenalty = 1;
		end	
	end	

	-- ALCOHOLIC MOD DATA
	if player:HasTrait("SOAlcoholic") then	
		if player:getModData().SOtenminutesSinceLastDrink == nil then
			player:getModData().SOtenminutesSinceLastDrink = 0;
		end	
		if player:getModData().SOAlcoholBottlesDrinked == nil then
			player:getModData().SOAlcoholBottlesDrinked = 0; 
		end			
	end
	if not player:HasTrait("SOAlcoholic") then	
		if player:getModData().SOtenminutesToObtainAlcoholic == nil then
			player:getModData().SOtenminutesToObtainAlcoholic = 0;
		end	
	end	

	--[[ ADDING MESOMORPH
	if not player:HasTrait("Endomorph") and not player:HasTrait("Ectomorph") then
		if not player:HasTrait("Mesomorph") then
			player:getTraits():add("Mesomorph");
		end
	end]]	
	
	if player:HasTrait("Slack") then
		player:getTraits():remove("Slack"); -- revoming trait since its only affect strength and fitness
	end		
	if player:HasTrait("Taut") then
		player:getTraits():remove("Taut"); -- revoming trait since its only affect strength and fitness
	end	
	
	-- TRAITS SWAP	
	if player:HasTrait("Brave2") then
		player:getTraits():remove("Brave2");
		player:getTraits():add("Brave");
	end
	if player:HasTrait("Relentless2") then
		player:getTraits():remove("Relentless2");
		player:getTraits():add("Relentless");
	end	
	if player:HasTrait("Dextrous2") then
		player:getTraits():remove("Dextrous2");
		player:getTraits():add("Dextrous");
	end
	if player:HasTrait("GenExp2") then
		player:getTraits():remove("GenExp2");
		player:getTraits():add("GenExp");
	end	
	if player:HasTrait("Handy2") then
		player:getTraits():remove("Handy2");
		player:getTraits():add("Handy");
	end	
	if player:HasTrait("StrongBack2") then
		player:getTraits():remove("StrongBack2");
		player:getTraits():add("StrongBack");
	end	
	if player:HasTrait("Herbalist2") then
		player:getTraits():remove("Herbalist2");
		player:getTraits():add("Herbalist");
	end		
	if player:HasTrait("Cook2") then
		player:getTraits():remove("Cook2");
		player:getTraits():add("Cook");
	end		
	if player:HasTrait("Nutritionist2") then
		player:getTraits():remove("Nutritionist2");
		player:getTraits():add("Nutritionist");
	end	
	if player:HasTrait("Mechanics2") then
		player:getTraits():remove("Mechanics2");
		player:getTraits():add("Mechanics");
	end
	if player:HasTrait("Organized2") then
		player:getTraits():remove("Organized2");
		player:getTraits():add("Organized");
	end
	if player:HasTrait("Graceful2") then
		player:getTraits():remove("Graceful2");
		player:getTraits():add("Graceful");
	end	
	if player:HasTrait("Inconspicuous2") then
		player:getTraits():remove("Inconspicuous2");
		player:getTraits():add("Inconspicuous");
	end	
	if player:HasTrait("Pacifist2") then
		player:getTraits():remove("Pacifist2");
		player:getTraits():add("Pacifist");
	end	
	if player:HasTrait("Shooter2") then
		player:getTraits():remove("Shooter2");
		player:getTraits():add("Shooter");
	end			
	if player:HasTrait("FastReader2") then
		player:getTraits():remove("FastReader2");
		player:getTraits():add("FastReader");
	end		
	if player:HasTrait("AdrenalineJunkie2") then
		player:getTraits():remove("AdrenalineJunkie2");
		player:getTraits():add("AdrenalineJunkie");
	end
	if player:HasTrait("Formerscout2") then
		player:getTraits():remove("Formerscout2");
		player:getTraits():add("Formerscout");
	end	
	if player:HasTrait("SpeedDemon2") then
		player:getTraits():remove("SpeedDemon2");
		player:getTraits():add("SpeedDemon");
	end		
	if player:HasTrait("EagleEyed2") then
		player:getTraits():remove("EagleEyed2");
		player:getTraits():add("EagleEyed");
	end	
	if player:HasTrait("FirstAid2") then
		player:getTraits():remove("FirstAid2");
		player:getTraits():add("FirstAid");
	end
	if player:HasTrait("Gardener2") then
		player:getTraits():remove("Gardener2");
		player:getTraits():add("Gardener");
	end	
	if player:HasTrait("Desensitized2") then
		player:getTraits():remove("Desensitized2");
		player:getTraits():add("Desensitized");
	end
	if player:HasTrait("NightVision2") then
		player:getTraits():remove("NightVision2");
		player:getTraits():add("NightVision");
	end
	if player:HasTrait("Gymnast2") then
		player:getTraits():remove("Gymnast2");
		player:getTraits():add("Gymnast");
	end	
	if player:HasTrait("Outdoorsman2") then
		player:getTraits():remove("Outdoorsman2");
		player:getTraits():add("Outdoorsman");
	end	
	if player:HasTrait("KeenHearing2") then
		player:getTraits():remove("KeenHearing2");
		player:getTraits():add("KeenHearing");
	end		
	if player:HasTrait("Cruelty2") then
		player:getTraits():remove("Cruelty2");
		player:getTraits():add("Cruelty");
	end		
	if player:HasTrait("BreathingTech2") then
		player:getTraits():remove("BreathingTech2");
		player:getTraits():add("BreathingTech");
	end	
	
end

Events.OnGameBoot.Add(SOBaseGameCharacterDetails.DoTraits);
Events.OnGameBoot.Add(SOBaseGameCharacterDetails.DoProfessions);
Events.OnCreatePlayer.Add(SOBaseGameCharacterDetails.DoNewCharacterInitializations);
Events.OnCreateLivingCharacter.Add(SOBaseGameCharacterDetails.DoProfessions);
