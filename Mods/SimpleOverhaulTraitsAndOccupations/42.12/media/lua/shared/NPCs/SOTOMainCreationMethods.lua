SOTOBaseGameCharacterDetails = {}

	----------------------------------------------
	--- SIMPLE OVERHAUL TRAITS AND OCCUPATIONS ---
	----------------------------------------------

SOTOBaseGameCharacterDetails.DoTraits = function()

	local isMP = (isClient() or isServer());
	local sleepOK = (isClient() or isServer()) and getServerOptions():getBoolean("SleepAllowed") and getServerOptions():getBoolean("SleepNeeded")

	-- NOT USED
	--	TraitFactory.addTrait("Patient", getText("UI_trait_patient"), 4, getText("UI_trait_patientdesc"), false);
	--	TraitFactory.addTrait("ShortTemper", getText("UI_trait_shorttemper"), -4, getText("UI_trait_shorttemperdesc"), false);
	--	TraitFactory.addTrait("Brooding", getText("UI_trait_brooding"), -2, getText("UI_trait_broodingdesc"), false);
	--	TraitFactory.addTrait("LightDrinker", getText("UI_trait_lightdrink"), -2, getText("UI_trait_lightdrinkdesc"), false);
	--	TraitFactory.addTrait("HeavyDrinker", getText("UI_trait_harddrink"), 3, getText("UI_trait_harddrinkdesc"), false);
	--	TraitFactory.addTrait("Lucky", getText("UI_trait_lucky"), 4, getText("UI_trait_luckydesc"), false, true);
	--	TraitFactory.addTrait("Unlucky", getText("UI_trait_unlucky"), -4, getText("UI_trait_unluckydesc"), false, true);
	--	TraitFactory.addTrait("GiftOfTheGab", getText("UI_trait_giftgab"), 0, getText("UI_trait_giftgabdesc"), true);
	--	TraitFactory.addTrait("Injured", "Injured", -4, getText("UI_trait_outdoorsmandesc"), false);
	--	local selfdef = TraitFactory.addTrait("SelfDefenseClass", getText("UI_trait_SelfDefenseClass"), 6, getText("UI_trait_SelfDefenseClassDesc"), false);
	--	selfdef:addXPBoost(Perks.Guard, 1)

	--local test1 = TraitFactory.addTrait("test1", getText("UI_trait_test1"), 1, getText("UI_trait_test1desc"), false);
	--local testalcho = TraitFactory.addTrait("testalcho", getText("UI_trait_testalcho"), 1, getText("UI_trait_testalchodesc"), false);
	--local testcomfort = TraitFactory.addTrait("testcomfort", getText("UI_trait_testcomfort"), 1, getText("UI_trait_testcomfortdesc"), false);

	---------------------------------------------

	local weightgain = TraitFactory.addTrait("WeightGain", getText("UI_trait_weightgain"), 0, getText("UI_trait_weightgaindesc"), true);
	-- weightgain:addFreeTrait("Overweight");
	local weightloss = TraitFactory.addTrait("WeightLoss", getText("UI_trait_weightloss"), 0, getText("UI_trait_weightlossdesc"), true);
	-- weightloss:addFreeTrait("Underweight");

	---------------------------------------------

	-- STRENGTH TRAITS	
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
	
	-- STR AND FIT TRAITS
	local taut = TraitFactory.addTrait("Taut", getText("UI_trait_taut"), 6, getText("UI_trait_tautdesc"), false);
	taut:addXPBoost(Perks.Fitness, 1)
	taut:addXPBoost(Perks.Strength, 1)
	local slack = TraitFactory.addTrait("Slack", getText("UI_trait_slack"), -6, getText("UI_trait_slackdesc"), false);
	slack:addXPBoost(Perks.Fitness, -1)
	slack:addXPBoost(Perks.Strength, -1)	

	-- CHARACTER WEIGHT TRAITS
	-- LOW WEIGT
	local underweight = TraitFactory.addTrait("Underweight", getText("UI_trait_underweight"), -5, getText("UI_trait_underweightdesc"), false);
	underweight:addXPBoost(Perks.Strength, -1)
	underweight:addFreeTrait("FastMetabolism");
	local veryUnderweight = TraitFactory.addTrait("Very Underweight", getText("UI_trait_veryunderweight"), -10, getText("UI_trait_veryunderweightdesc"), false);
	veryUnderweight:addXPBoost(Perks.Strength, -2)
	veryUnderweight:addFreeTrait("FastMetabolism");
    TraitFactory.addTrait("Emaciated", getText("UI_trait_emaciated"), -10, getText("UI_trait_emaciateddesc"), true);	
	-- HIGH WEIGHT
	local overweight = TraitFactory.addTrait("Overweight", getText("UI_trait_overweight"), -6, getText("UI_trait_overweightdesc"), false);
	overweight:addXPBoost(Perks.Fitness, -1)
	overweight:addFreeTrait("SlowMetabolism");
	local obese = TraitFactory.addTrait("Obese", getText("UI_trait_obese"), -12, getText("UI_trait_obesedesc"), false);
	obese:addXPBoost(Perks.Fitness, -2)	
	obese:addFreeTrait("SlowMetabolism");

	-- VANILLA TRAITS
	-- AGILITY TRAITS
	local jogger = TraitFactory.addTrait("Jogger", getText("UI_trait_Jogger"), 2, getText("UI_trait_JoggerDesc"), false);
	jogger:addXPBoost(Perks.Sprinting, 1)	
	local sneaky = TraitFactory.addTrait("Sneaky", getText("UI_trait_sneaky"), 2, getText("UI_trait_sneakydesc"), false);
	sneaky:addXPBoost(Perks.Sneak, 1)	
	local lightfooted = TraitFactory.addTrait("Lightfooted", getText("UI_trait_lightfooted"), 1, getText("UI_trait_lightfooteddesc"), false);
	lightfooted:addXPBoost(Perks.Lightfoot, 1)
	local nimble = TraitFactory.addTrait("Nimble", getText("UI_trait_nimble"), 4, getText("UI_trait_nimbledesc"), false);
	nimble:addXPBoost(Perks.Nimble, 1)	
	local gym = TraitFactory.addTrait("Gymnast", getText("UI_trait_Gymnast"), 5, getText("UI_trait_GymnastDesc"), false);
	gym:addXPBoost(Perks.Lightfoot, 1)
	gym:addXPBoost(Perks.Nimble, 1)
	TraitFactory.addTrait("Gymnast2", getText("UI_trait_Gymnast"), 0, getText("UI_trait_Gymnast2desc"), true);	

	-- SURVIVING TRAITS
	local fisher = TraitFactory.addTrait("Fishing", getText("UI_trait_Fishing"), 2, getText("UI_trait_FishingDesc"), false);
	fisher:addXPBoost(Perks.Fishing, 1)
    fisher:getFreeRecipes():add("MakeFishingRod");
    fisher:getFreeRecipes():add("FixFishingRod");
    fisher:getFreeRecipes():add("MakeChum");
	local gardener = TraitFactory.addTrait("Gardener", getText("UI_trait_Gardener"), 1, getText("UI_trait_GardenerDesc2"), false);
	gardener:addXPBoost(Perks.Farming, 1)
    gardener:getFreeRecipes():add("MakeFliesCureFromCigarettes");
    gardener:getFreeRecipes():add("MakeFliesCureFromLooseTobacco");
    gardener:getFreeRecipes():add("MakeFliesCureFromChewingTobacco");
    gardener:getFreeRecipes():add("MakeMildewCure");
    gardener:getFreeRecipes():add("MakeAphidsCure");
--     gardener:getFreeRecipes():add("Make Slug Trap");
    gardener:getFreeRecipes():add("MakeScarecrow");

    gardener:getFreeRecipes():add("Carrot Growing Season");
    gardener:getFreeRecipes():add("Broccoli Growing Season");
    gardener:getFreeRecipes():add("Radish Growing Season");
    gardener:getFreeRecipes():add("Strawberry Growing Season");
    gardener:getFreeRecipes():add("Tomato Growing Season");
    gardener:getFreeRecipes():add("Potato Growing Season");
    gardener:getFreeRecipes():add("Cabbage Growing Season");

    gardener:getFreeRecipes():add("Corn Growing Season");
    gardener:getFreeRecipes():add("Kale Growing Season");
    gardener:getFreeRecipes():add("Sweet Potato Growing Season");
    gardener:getFreeRecipes():add("Green Pea Growing Season");
    gardener:getFreeRecipes():add("Onion Growing Season");
    gardener:getFreeRecipes():add("Garlic Growing Season");
    gardener:getFreeRecipes():add("Soybean Growing Season");

    gardener:getFreeRecipes():add("Basil Growing Season");
    gardener:getFreeRecipes():add("Chives Growing Season");
    gardener:getFreeRecipes():add("Cilantro Growing Season");
    gardener:getFreeRecipes():add("Oregano Growing Season");
    gardener:getFreeRecipes():add("Parsley Growing Season");
    gardener:getFreeRecipes():add("Sage Growing Season");
    gardener:getFreeRecipes():add("Rosemary Growing Season");
    gardener:getFreeRecipes():add("Thyme Growing Season");

    gardener:getFreeRecipes():add("Hops Growing Season");
    gardener:getFreeRecipes():add("Sugar Beet Growing Season");

    gardener:getFreeRecipes():add("Bell Pepper Growing Season");
    gardener:getFreeRecipes():add("Cauliflower Growing Season");
    gardener:getFreeRecipes():add("Cucumber Growing Season");
    gardener:getFreeRecipes():add("Habanero Growing Season");
    gardener:getFreeRecipes():add("Jalapeno Growing Season");
    gardener:getFreeRecipes():add("Leek Growing Season");
    gardener:getFreeRecipes():add("Lettuce Growing Season");
    gardener:getFreeRecipes():add("Pumpkin Growing Season");
    gardener:getFreeRecipes():add("Spinach Growing Season");
    gardener:getFreeRecipes():add("Sunflower Growing Season");
    gardener:getFreeRecipes():add("Turnip Growing Season");
    gardener:getFreeRecipes():add("Watermelon Growing Season");
    gardener:getFreeRecipes():add("Zucchini Growing Season");

    gardener:getFreeRecipes():add("Chamomile Growing Season");
    gardener:getFreeRecipes():add("Lemongrass Growing Season");
    gardener:getFreeRecipes():add("Marigold Growing Season");
    gardener:getFreeRecipes():add("Mint Growing Season");

    gardener:getFreeRecipes():add("Black Sage Growing Season");
    gardener:getFreeRecipes():add("Broadleaf Plantain Growing Season");
    gardener:getFreeRecipes():add("Comfrey Growing Season");
    gardener:getFreeRecipes():add("Common Mallow Growing Season");
    gardener:getFreeRecipes():add("Wild Garlic Growing Season");

    gardener:getFreeRecipes():add("Rose Growing Season");
    gardener:getFreeRecipes():add("Poppy Growing Season");
    gardener:getFreeRecipes():add("Lavender Growing Season");

    gardener:getFreeRecipes():add("MakeJarofTomatoes");
    gardener:getFreeRecipes():add("MakeJarofCarrots");
    gardener:getFreeRecipes():add("MakeJarofPotatoes");
    gardener:getFreeRecipes():add("MakeJarofEggplant");
    gardener:getFreeRecipes():add("MakeJarofLeeks");
    gardener:getFreeRecipes():add("MakeJarofRedRadishes");
    gardener:getFreeRecipes():add("MakeJarofBellPeppers");
    gardener:getFreeRecipes():add("MakeJarofCabbage");
    gardener:getFreeRecipes():add("MakeJarofBroccoli");
	TraitFactory.addTrait("Gardener2", getText("UI_trait_Gardener"), 0, getText("UI_trait_Gardener2Desc"), true);
	local backpacker = TraitFactory.addTrait("Hiker", getText("UI_trait_Hiker"), 6, getText("UI_trait_SOHikerDesc"), false);
	backpacker:addXPBoost(Perks.PlantScavenging, 1)
	backpacker:addXPBoost(Perks.Trapping, 1)
	backpacker:addXPBoost(Perks.Fishing, 1)	
	backpacker:getFreeRecipes():add("MakeStickTrap");
	backpacker:getFreeRecipes():add("MakeSnareTrap");
	backpacker:getFreeRecipes():add("MakeWoodenBoxTrap");
	local wilderness = TraitFactory.addTrait("WildernessKnowledge", getText("UI_trait_WildernessKnowledge"), 8, getText("UI_trait_WildernessKnowledgeDesc"), false);
	wilderness:addXPBoost(Perks.PlantScavenging, 1)
    wilderness:addXPBoost(Perks.FlintKnapping, 1)
	wilderness:addXPBoost(Perks.Maintenance, 1)
    wilderness:addXPBoost(Perks.Carving, 1)
    wilderness:getFreeRecipes():add("Herbalist");
    wilderness:getFreeRecipes():add("MakeStoneBlade");
    wilderness:getFreeRecipes():add("MakeLongStoneBlade");
    wilderness:getFreeRecipes():add("MakeStoneBladeScythe");
    wilderness:getFreeRecipes():add("FireHardenSpear");
    wilderness:getFreeRecipes():add("MakeCrudeWhetstone");
    wilderness:getFreeRecipes():add("MakePlantainPoultice");
    wilderness:getFreeRecipes():add("MakeComfreyPoultice");
    wilderness:getFreeRecipes():add("MakeWildGarlicPoultice");

--     wilderness:getFreeRecipes():add("Black Sage Growing Season");
--     wilderness:getFreeRecipes():add("Broadleaf Plantain Growing Season");
--     wilderness:getFreeRecipes():add("Comfrey Growing Season");
--     wilderness:getFreeRecipes():add("Common Mallow Growing Season");
--     wilderness:getFreeRecipes():add("Wild Garlic Growing Season");

    wilderness:getFreeRecipes():add("BindSpear");
    wilderness:getFreeRecipes():add("WireSpear");
    wilderness:getFreeRecipes():add("SharpenLongBone");
    wilderness:getFreeRecipes():add("MakeBoneFishingHook");
    wilderness:getFreeRecipes():add("MakeBoneSewingNeedle");
    wilderness:getFreeRecipes():add("MakeBoneAwl");
    wilderness:getFreeRecipes():add("MakeStoneAwl");
    wilderness:getFreeRecipes():add("MakeStoneChisel");
    wilderness:getFreeRecipes():add("MakeStoneDrill");
    wilderness:getFreeRecipes():add("MakeLargeStoneAxeHead");
    wilderness:getFreeRecipes():add("MakeStoneMaulHead");

    wilderness:getFreeRecipes():add("MakeBoneClub");
    wilderness:getFreeRecipes():add("MakeBoneHatchetHead");
    wilderness:getFreeRecipes():add("MakeJawboneAxe");
    wilderness:getFreeRecipes():add("MakeFishingRod");
    wilderness:getFreeRecipes():add("MakeSnareTrap");
    wilderness:getFreeRecipes():add("MakeStoneBladeSaw");
    wilderness:getFreeRecipes():add("CarveBucket");
    wilderness:getFreeRecipes():add("CarveFleshingTool");
	
	local forager = TraitFactory.addTrait("Forager", getText("UI_trait_forager"), 2, getText("UI_trait_foragerdesc"), false);
	forager:addXPBoost(Perks.PlantScavenging, 1)
	local trapper = TraitFactory.addTrait("Trapper", getText("UI_trait_trapper"), 2, getText("UI_trait_trapperdesc"), false);
	trapper:addXPBoost(Perks.Trapping, 1)
	trapper:getFreeRecipes():add("MakeStickTrap");
	trapper:getFreeRecipes():add("MakeWoodenBoxTrap");	
	local tracker = TraitFactory.addTrait("Tracker", getText("UI_trait_tracker"), 1, getText("UI_trait_trackerdesc"), false);
	tracker:addXPBoost(Perks.Tracking, 1)
	
	local mushroompicker = TraitFactory.addTrait("MushroomPicker", getText("UI_trait_mushroompicker"), 1, getText("UI_trait_mushroompickerdesc"), false);
	local entomologist = TraitFactory.addTrait("Entomologist", getText("UI_trait_entomologist"), 1, getText("UI_trait_entomologistdesc"), false);

	local improvedforaging = TraitFactory.addTrait("ImprovedForaging", getText("UI_trait_improvedforaging"), 0, getText("UI_trait_improvedforagingdesc"), true);
	local advancedforaging = TraitFactory.addTrait("AdvancedForaging", getText("UI_trait_advancedforaging"), 0, getText("UI_trait_advancedforagingdesc"), true);
	
	local inventive = TraitFactory.addTrait("Inventive", getText("UI_trait_Inventive"), 1, getText("UI_trait_InventiveDesc"), false);
	TraitFactory.addTrait("Inventive2", getText("UI_trait_Inventive"), 0, getText("UI_trait_InventiveDesc"), true);

	-- CRAFTING TRAITS
	local firstAid = TraitFactory.addTrait("FirstAid", getText("UI_trait_FirstAid"), 1, getText("UI_trait_FirstAidDesc"), false);
	firstAid:addXPBoost(Perks.Doctor, 1)
	TraitFactory.addTrait("FirstAid2", getText("UI_trait_FirstAid"), 0, getText("UI_trait_FirstAid2Desc"), true);
	local tailoring = TraitFactory.addTrait("Tailor", getText("UI_trait_Tailor"), 2, getText("UI_trait_TailorDesc2"), false);
	tailoring:addXPBoost(Perks.Tailoring, 1)
    doTailorRecipes(tailoring);
	
	local cook = TraitFactory.addTrait("Cook", getText("UI_trait_Cook"), 2, getText("UI_trait_CookDesc"), false);
	cook:addXPBoost(Perks.Cooking, 2)
    cook:getFreeRecipes():add("MakeCakeBatter");
    cook:getFreeRecipes():add("MakePieDough");
    cook:getFreeRecipes():add("MakeBreadDough");
    cook:getFreeRecipes():add("MakeBaguetteDough");
    cook:getFreeRecipes():add("MakeBiscuits");
    cook:getFreeRecipes():add("MakeCookieDough");
    cook:getFreeRecipes():add("MakeChocolateChipCookieDough");
    cook:getFreeRecipes():add("MakeOatmealCookieDough");
    cook:getFreeRecipes():add("MakeShortbreadCookieDough");
    cook:getFreeRecipes():add("MakeSugarCookieDough");
    cook:getFreeRecipes():add("MakePizza");
    cook:getFreeRecipes():add("MakeFriedOnionRings");
    cook:getFreeRecipes():add("MakeFriedShrimp");
    cook:getFreeRecipes():add("MakeCabbageRolls");
    cook:getFreeRecipes():add("MakeJar");
    cook:getFreeRecipes():add("MakeGuacamole");
	
	TraitFactory.addTrait("Cook2", getText("UI_trait_Cook"), 0, getText("UI_trait_Cook2Desc"), true);
	
	local handy = TraitFactory.addTrait("Handy", getText("UI_trait_handy"), 7, getText("UI_trait_handydesc"), false);
	handy:addXPBoost(Perks.Maintenance, 1)
	handy:addXPBoost(Perks.Woodwork, 1)
    handy:addXPBoost(Perks.Carving, 1)
    handy:getFreeRecipes():add("BarbedWireWeapon")
    handy:getFreeRecipes():add("BoltBat")
    handy:getFreeRecipes():add("MakeBrakeWeapon")
    handy:getFreeRecipes():add("MakeBucketMaul")
    handy:getFreeRecipes():add("CanReinforceLongWeapon")
    handy:getFreeRecipes():add("CanReinforceShortWeapon")
    handy:getFreeRecipes():add("CanReinforceWeapon")
    handy:getFreeRecipes():add("MakeGardenForkHeadWeapon")
    handy:getFreeRecipes():add("MakeKettleMaul")
    handy:getFreeRecipes():add("RailspikeBaseballBat")
    handy:getFreeRecipes():add("MakeRailspikeCudgel")
    handy:getFreeRecipes():add("MakeRailspikeIronPipe")
    handy:getFreeRecipes():add("MakeRailspikeLongHandle")
    handy:getFreeRecipes():add("MakeRailspikeWeapon")
    handy:getFreeRecipes():add("MakeRakeHeadWeapon")
    handy:getFreeRecipes():add("MakeSawPlank")
    handy:getFreeRecipes():add("MakeSawbladeCudgel")
    handy:getFreeRecipes():add("MakeSawbladeLongHandle")
    handy:getFreeRecipes():add("MakeSawbladePlank")
    handy:getFreeRecipes():add("MakeSawbladeTableLeg")
    handy:getFreeRecipes():add("MakeSawbladeWeapon")
    handy:getFreeRecipes():add("SheetMetalWeapon")
    handy:getFreeRecipes():add("MakeSpadeHeadCudgel")
    handy:getFreeRecipes():add("MakeScrewdriver")
	TraitFactory.addTrait("Handy2", getText("UI_trait_handy"), 0, getText("UI_trait_handydesc"), true);
	local blacksmith = TraitFactory.addTrait("Blacksmith", getText("UI_trait_Blacksmith"), 2, getText("UI_trait_BlacksmithDesc2"), false);
	blacksmith:addXPBoost(Perks.Blacksmith, 1)
	doMetalWorkerRecipes(blacksmith);
	TraitFactory.addTrait("Blacksmith2", getText("UI_trait_Blacksmith2"), 0, getText("UI_trait_BlacksmithDesc2"), true);
	local whittler = TraitFactory.addTrait("Whittler", getText("UI_trait_Whittler"), 1, getText("UI_trait_WhittlerDesc2"), false);
	whittler:addXPBoost(Perks.Carving, 1)
    whittler:getFreeRecipes():add("SharpenBone");
    whittler:getFreeRecipes():add("SharpenLongBone");
    whittler:getFreeRecipes():add("SharpenJawbone");
    whittler:getFreeRecipes():add("MakeBoneFishingHook");
    whittler:getFreeRecipes():add("MakeBoneSewingNeedle");
    whittler:getFreeRecipes():add("CarveKnittingNeedles");
    whittler:getFreeRecipes():add("CarveBat");
    whittler:getFreeRecipes():add("MakeBoneHatchetHead");
    whittler:getFreeRecipes():add("MakeBoneAwl");
    whittler:getFreeRecipes():add("MakeLargeBoneBead");
    whittler:getFreeRecipes():add("MakeLargeBoneBeads");
    whittler:getFreeRecipes():add("CarveWoodenFork");
    whittler:getFreeRecipes():add("MakeBoneFork");
    whittler:getFreeRecipes():add("CarveWoodenSpade");
    whittler:getFreeRecipes():add("CarveGoblets");
    whittler:getFreeRecipes():add("CarveBucket");
    whittler:getFreeRecipes():add("CarveFleshingTool");
    whittler:getFreeRecipes():add("CarveShortBat");
	local culinary = TraitFactory.addTrait("Culinary", getText("UI_trait_culinary"), 1, getText("UI_trait_culinarydesc"), false);
	culinary:addXPBoost(Perks.Cooking, 1)
    culinary:getFreeRecipes():add("MakeCakeBatter");
    culinary:getFreeRecipes():add("MakePieDough");	
	local woodworker = TraitFactory.addTrait("Woodworker", getText("UI_trait_woodworker"), 2, getText("UI_trait_woodworkerdesc"), false);
	woodworker:addXPBoost(Perks.Woodwork, 1)
	local electrictech = TraitFactory.addTrait("ElectricTech", getText("UI_trait_electrictech"), 2, getText("UI_trait_electrictechdesc"), false);
	electrictech:addXPBoost(Perks.Electricity, 1)
    electrictech:getFreeRecipes():add("MakeRemoteControllerV1");
    electrictech:getFreeRecipes():add("MakeRemoteControllerV2");
    electrictech:getFreeRecipes():add("MakeRemoteControllerV3");
	local automechanic = TraitFactory.addTrait("AutoMechanic", getText("UI_trait_automechanic"), 2, getText("UI_trait_automechanicdesc"), false);
	automechanic:addXPBoost(Perks.Mechanics, 1)
	local metalwelder = TraitFactory.addTrait("MetalWelder", getText("UI_trait_metalwelder"), 2, getText("UI_trait_metalwelderdesc"), false);
	metalwelder:addXPBoost(Perks.MetalWelding, 1)
    metalwelder:getFreeRecipes():add("Make Metal Walls");
    metalwelder:getFreeRecipes():add("Make Metal Fences");
    metalwelder:getFreeRecipes():add("Make Metal Containers");
    metalwelder:getFreeRecipes():add("Make Metal Sheet");
    metalwelder:getFreeRecipes():add("Make Small Metal Sheet");
    metalwelder:getFreeRecipes():add("Make Metal Roof");
	local mason = TraitFactory.addTrait("Mason", getText("UI_trait_Mason"), 0, getText("UI_trait_MasonDesc"), true); -- vanilla Mason disabled
	local artisan = TraitFactory.addTrait("Artisan", getText("UI_trait_Artisan"), 0, getText("UI_trait_ArtisanDesc"), true); -- vanilla Artisan disabled
	local masonry = TraitFactory.addTrait("Masonry", getText("UI_trait_masonry"), 1, getText("UI_trait_masonrydesc"), false);
	masonry:addXPBoost(Perks.Masonry, 1)
    masonry:getFreeRecipes():add("Construct_Advanced_Forge");
    masonry:getFreeRecipes():add("Construct_Blast_Furnace");
    masonry:getFreeRecipes():add("Construct_Dome_Kiln");
    masonry:getFreeRecipes():add("Construct_Forge");
    masonry:getFreeRecipes():add("Construct_Smelting_Furnace");
    masonry:getFreeRecipes():add("Construct_Primitive_Forge");
	local potter = TraitFactory.addTrait("Potter", getText("UI_trait_potter"), 1, getText("UI_trait_potterdesc"), false);
	potter:addXPBoost(Perks.Pottery, 1)
	local glassblower = TraitFactory.addTrait("GlassBlower", getText("UI_trait_glassblower"), 1, getText("UI_trait_glassblowerdesc"), false);
	glassblower:addXPBoost(Perks.Glassmaking, 1)
    glassblower:getFreeRecipes():add("MakeWineGlass");
    glassblower:getFreeRecipes():add("MakeDrinkingGlass");
    glassblower:getFreeRecipes():add("MakeGlassBottle");
    glassblower:getFreeRecipes():add("MakeGlassJar");
	local knappingbasics = TraitFactory.addTrait("KnappingBasics", getText("UI_trait_knappingbasics"), 1, getText("UI_trait_knappingbasicsdesc"), false);
	knappingbasics:addXPBoost(Perks.FlintKnapping, 1)
    knappingbasics:getFreeRecipes():add("MakeStoneBlade");
	knappingbasics:getFreeRecipes():add("MakeCrudeWhetstone");
	local animalfriend = TraitFactory.addTrait("AnimalFriend", getText("UI_trait_animalfriend"), 1, getText("UI_trait_animalfrienddesc"), false);
	animalfriend:addXPBoost(Perks.Husbandry, 1)
	TraitFactory.addTrait("AnimalFriend2", getText("UI_trait_animalfriend"), 0, getText("UI_trait_animalfriend2desc"), true);
	local slaughterer = TraitFactory.addTrait("Slaughterer", getText("UI_trait_slaughterer"), 1, getText("UI_trait_slaughtererdesc"), false);
	slaughterer:addXPBoost(Perks.Butchering, 1)
	TraitFactory.addTrait("Slaughterer2", getText("UI_trait_slaughterer"), 0, getText("UI_trait_slaughterer2desc"), true);	
--	local smelter = TraitFactory.addTrait("Smelter", getText("UI_trait_smelter"), 1, getText("UI_trait_smelterdesc"), false);
--	smelter:addXPBoost(Perks.Melting, 1)
	
	-- MELEE COMBAT TRAITS
	local baseball = TraitFactory.addTrait("BaseballPlayer", getText("UI_trait_PlaysBaseball"), 4, getText("UI_trait_PlaysBaseballDesc"), false);
	baseball:addXPBoost(Perks.Blunt, 1)	
	baseball:getFreeRecipes():add("CarveBat")
	local stabber = TraitFactory.addTrait("Stabber", getText("UI_trait_stabber"), 2, getText("UI_trait_stabberdesc"), false);
	stabber:addXPBoost(Perks.SmallBlade, 1)
	local smasher = TraitFactory.addTrait("Smasher", getText("UI_trait_smasher"), 3, getText("UI_trait_smasherdesc"), false);
	smasher:addXPBoost(Perks.SmallBlunt, 1)
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
	local hunter = TraitFactory.addTrait("Hunter", getText("UI_trait_Hunter"), 10, getText("UI_trait_HunterDesc"), false);
	hunter:addXPBoost(Perks.Aiming, 1)
	hunter:addXPBoost(Perks.Trapping, 1)
	hunter:addXPBoost(Perks.Sneak, 1)
	hunter:addXPBoost(Perks.SmallBlade, 1)
	hunter:addXPBoost(Perks.Tracking, 1)
	hunter:getFreeRecipes():add("Make Stick Trap");
	hunter:getFreeRecipes():add("MakeStickTrap");
	hunter:getFreeRecipes():add("MakeSnareTrap");
	hunter:getFreeRecipes():add("MakeWoodenBoxTrap");
	hunter:getFreeRecipes():add("MakeTrapBox");
	hunter:getFreeRecipes():add("MakeCageTrap");
	TraitFactory.addTrait("Hunter2", getText("UI_trait_Hunter"), 0, getText("UI_trait_Hunter2Desc"), true);		
	
	local formerscout = TraitFactory.addTrait("Formerscout", getText("UI_trait_Scout"), 3, getText("UI_trait_ScoutDesc"), false);
	formerscout:addXPBoost(Perks.Doctor, 1)	
	formerscout:addXPBoost(Perks.PlantScavenging, 1)
	TraitFactory.addTrait("Formerscout2", getText("UI_trait_Scout"), 0, getText("UI_trait_Scout2Desc"), true);
	local barfighter = TraitFactory.addTrait("Brawler", getText("UI_trait_BarFighter"), 5, getText("UI_trait_BarFighterDesc2"), false);
	barfighter:addXPBoost(Perks.Strength, 1)
	barfighter:getFreeRecipes():add("BarbedWireWeapon");
	barfighter:getFreeRecipes():add("BoltBat");
	barfighter:getFreeRecipes():add("CanReinforceLongWeapon");
	barfighter:getFreeRecipes():add("CanReinforceShortWeapon");
	barfighter:getFreeRecipes():add("CanReinforceWeapon");
	barfighter:getFreeRecipes():add("SheetMetalWeapon");
	
	--RECIPES TRAITS
	local carenthusiast = TraitFactory.addTrait("Mechanics", getText("UI_trait_Mechanics"), 2, getText("UI_trait_MechanicsDesc"), false);
	carenthusiast:getFreeRecipes():add("Basic Mechanics");
	carenthusiast:getFreeRecipes():add("Intermediate Mechanics");
	TraitFactory.addTrait("Mechanics2", getText("UI_trait_Mechanics"), 0, getText("UI_trait_Mechanics2Desc"), true);
    local herbalist = TraitFactory.addTrait("Herbalist", getText("UI_trait_Herbalist"), 2, getText("UI_trait_HerbalistDesc"), false);
    herbalist:getFreeRecipes():add("Herbalist");
    herbalist:getFreeRecipes():add("MakePlantainPoultice");
    herbalist:getFreeRecipes():add("MakeComfreyPoultice");
    herbalist:getFreeRecipes():add("MakeWildGarlicPoultice");

    herbalist:getFreeRecipes():add("Black Sage Growing Season");
    herbalist:getFreeRecipes():add("Broadleaf Plantain Growing Season");
    herbalist:getFreeRecipes():add("Comfrey Growing Season");
    herbalist:getFreeRecipes():add("Common Mallow Growing Season");
    herbalist:getFreeRecipes():add("Wild Garlic Growing Season");
	TraitFactory.addTrait("Herbalist2", getText("UI_trait_Herbalist"), 0, getText("UI_trait_HerbalistDesc"), true);

	local genexp = TraitFactory.addTrait("GenExp", getText("UI_trait_genexp"), 1, getText("UI_trait_genexpdesc"), false);
	genexp:getFreeRecipes():add("Generator");
	TraitFactory.addTrait("GenExp2", getText("UI_trait_genexp"), 0, getText("UI_trait_genexpdesc"), true);	

	-- UNIQUE TRAITS
	-- Stress traits	
	local calmminded = TraitFactory.addTrait("CalmMinded", getText("UI_trait_calmminded"), 3, getText("UI_trait_calmmindeddesc"), false);
	
	-- Endurance traits
	local marathonrunner = TraitFactory.addTrait("MarathonRunner", getText("UI_trait_marathonrunner"), 2, getText("UI_trait_marathonrunnerdesc"), false);
	local tireless = TraitFactory.addTrait("Tireless", getText("UI_trait_tireless"), 3, getText("UI_trait_tirelessdesc"), false);
--	TraitFactory.addTrait("Tireless2", getText("UI_trait_tireless"), 0, getText("UI_trait_tirelessdesc"), true);	
	local ninjaway = TraitFactory.addTrait("NinjaWay", getText("UI_trait_ninjaway"), 0, getText("UI_trait_ninjawaydesc"), true);
	local breathingtech = TraitFactory.addTrait("BreathingTech", getText("UI_trait_breathingtech"), 0, getText("UI_trait_breathingtechdesc"), true);	
	TraitFactory.addTrait("BreathingTech2", getText("UI_trait_breathingtech"), 2, getText("UI_trait_breathingtechdesc"), false);

	TraitFactory.addTrait("Asthmatic", getText("UI_trait_Asthmatic"), -6, getText("UI_trait_AsthmaticDesc"), false);	
	
	-- VEHICLE SPEED TRAITS
	TraitFactory.addTrait("SpeedDemon", getText("UI_trait_SpeedDemon"), 1, getText("UI_trait_SpeedDemonDesc"), false);
	TraitFactory.addTrait("SpeedDemon2", getText("UI_trait_SpeedDemon"), 0, getText("UI_trait_SpeedDemonDesc"), true);	
	TraitFactory.addTrait("SundayDriver", getText("UI_trait_SundayDriver"), -2, getText("UI_trait_SundayDriverDesc"), false);

	-- VISION TRAITS
	TraitFactory.addTrait("ShortSighted", getText("UI_trait_shortsigh"), -2, getText("UI_trait_shortsighdesc"), false);
	TraitFactory.addTrait("EagleEyed", getText("UI_trait_eagleeyed"), 2, getText("UI_trait_eagleeyeddesc"), false);
	TraitFactory.addTrait("EagleEyed2", getText("UI_trait_eagleeyed"), 0, getText("UI_trait_eagleeyeddesc"), true);			
 	TraitFactory.addTrait("NightVision", getText("UI_trait_NightVision"), 2, getText("UI_trait_NightVisionDesc"), false);
 	TraitFactory.addTrait("NightVision2", getText("UI_trait_NightVision"), 0, getText("UI_trait_NightVisionDesc"), true);	

	-- HEARING TRAITS
	TraitFactory.addTrait("KeenHearing", getText("UI_trait_keenhearing"), 5, getText("UI_trait_keenhearingdesc"), false);
	TraitFactory.addTrait("KeenHearing2", getText("UI_trait_keenhearing"), 0, getText("UI_trait_keenhearingdesc"), true);			
	TraitFactory.addTrait("HardOfHearing", getText("UI_trait_hardhear"), -5, getText("UI_trait_hardheardesc"), false);
	TraitFactory.addTrait("Deaf", getText("UI_trait_deaf"), -12, getText("UI_trait_deafdesc"), false);

	-- SNEAKING TRAITS
	TraitFactory.addTrait("Inconspicuous", getText("UI_trait_Inconspicuous"), 2, getText("UI_trait_InconspicuousDesc"), false);
	TraitFactory.addTrait("Inconspicuous2", getText("UI_trait_Inconspicuous"), 0, getText("UI_trait_InconspicuousDesc"), true);
	TraitFactory.addTrait("Conspicuous", getText("UI_trait_Conspicuous"), -4, getText("UI_trait_ConspicuousDesc"), false);	

	-- PANIC TRAITS
	TraitFactory.addTrait("AdrenalineJunkie", getText("UI_trait_AdrenalineJunkie"), 4, getText("UI_trait_AdrenalineJunkieDesc"), false);
	TraitFactory.addTrait("AdrenalineJunkie2", getText("UI_trait_AdrenalineJunkie"), 0, getText("UI_trait_AdrenalineJunkieDesc"), true);
	TraitFactory.addTrait("Desensitized2", getText("UI_trait_Desensitized"), 8, getText("UI_trait_DesensitizedDesc"), false);
	TraitFactory.addTrait("Desensitized", getText("UI_trait_Desensitized"), 0, getText("UI_trait_DesensitizedDesc"), true);		
	TraitFactory.addTrait("Brave", getText("UI_trait_brave"), 3, getText("UI_trait_bravedesc"), false);
	TraitFactory.addTrait("Brave2", getText("UI_trait_brave"), 0, getText("UI_trait_bravedesc"), true);		
	TraitFactory.addTrait("Cowardly", getText("UI_trait_cowardly"), -2, getText("UI_trait_cowardlydesc"), false);

	-- GRACEFUL AND CLUMSY
	TraitFactory.addTrait("Graceful", getText("UI_trait_graceful"), 2, getText("UI_trait_gracefuldesc"), false);
	TraitFactory.addTrait("Graceful2", getText("UI_trait_graceful"), 0, getText("UI_trait_gracefuldesc"), true);
	TraitFactory.addTrait("Clumsy", getText("UI_trait_clumsy"), -2, getText("UI_trait_clumsydesc"), false);

	-- READING TRAITS
	TraitFactory.addTrait("FastReader", getText("UI_trait_FastReader"), 1, getText("UI_trait_FastReaderDesc"), false);
	TraitFactory.addTrait("FastReader2", getText("UI_trait_FastReader"), 0, getText("UI_trait_FastReaderDesc"), true);	
	TraitFactory.addTrait("SlowReader", getText("UI_trait_SlowReader"), -1, getText("UI_trait_SlowReaderDesc"), false);
	TraitFactory.addTrait("Illiterate", getText("UI_trait_Illiterate"), -8, getText("UI_trait_IlliterateDesc"), false);
	TraitFactory.addTrait("LifelongLearner", getText("UI_trait_lifelonglearner"), 0, getText("UI_trait_lifelonglearnerdesc"), true);	

	-- LUCKY TRAITS
    TraitFactory.addTrait("Lucky", getText("UI_trait_lucky"), 3, getText("UI_trait_luckydesc"), false, true); -- disabled in b42
    TraitFactory.addTrait("Unlucky", getText("UI_trait_unlucky"), -3, getText("UI_trait_unluckydesc"), false, true); -- disabled in b42

	-- PHOBIC TRAITS
	TraitFactory.addTrait("Agoraphobic", getText("UI_trait_agoraphobic"), -4, getText("UI_trait_agoraphobicdesc"), false);
	TraitFactory.addTrait("Claustrophobic", getText("UI_trait_claustro"), -4, getText("UI_trait_claustrodesc"), false);	
	TraitFactory.addTrait("Hemophobic", getText("UI_trait_Hemophobic"), -6, getText("UI_trait_Hemophobic2Desc"), false);
	local fearofthedark = TraitFactory.addTrait("FearoftheDark", getText("UI_trait_fearofthedark"), -1, getText("UI_trait_fearofthedarkdesc"), false);	

	-- NUTRITIONIST TRAIT
	TraitFactory.addTrait("Nutritionist", getText("UI_trait_nutritionist"), 1, getText("UI_trait_nutritionistdesc"), false);
	TraitFactory.addTrait("Nutritionist2", getText("UI_trait_nutritionist"), 0, getText("UI_trait_nutritionistdesc"), true);

	-- OUTDOORSMAN TRAIT
	TraitFactory.addTrait("Outdoorsman", getText("UI_trait_outdoorsman"), 2, getText("UI_trait_outdoorsmandesc"), false);
	TraitFactory.addTrait("Outdoorsman2", getText("UI_trait_outdoorsman"), 0, getText("UI_trait_outdoorsmandesc"), true);	

	-- XP TRAITS
	local fastmetabolism = TraitFactory.addTrait("FastMetabolism", getText("UI_trait_fastmetabolism"), 0, getText("UI_trait_fastmetabolismdesc"), true);	
	local slowmetabolism = TraitFactory.addTrait("SlowMetabolism", getText("UI_trait_slowmetabolism"), 0, getText("UI_trait_slowmetabolismdesc"), true);	
--	local fragilehealth = TraitFactory.addTrait("FragileHealth", getText("UI_trait_fragilehealth"), 0, getText("UI_trait_fragilehealthdesc"), true);	
	TraitFactory.addTrait("FastLearner", getText("UI_trait_FastLearner"), 8, getText("UI_trait_FastLearnerDesc"), false);
	TraitFactory.addTrait("SlowLearner", getText("UI_trait_SlowLearner"), -8, getText("UI_trait_SlowLearnerDesc"), false);	
	local cruelty = TraitFactory.addTrait("Cruelty", getText("UI_trait_cruelty"), 4, getText("UI_trait_crueltydesc"), false);
	TraitFactory.addTrait("Cruelty2", getText("UI_trait_cruelty"), -0, getText("UI_trait_crueltydesc"), true);	
	TraitFactory.addTrait("Pacifist", getText("UI_trait_Pacifist"), -5, getText("UI_trait_PacifistDesc"), false);
	TraitFactory.addTrait("Pacifist2", getText("UI_trait_Pacifist"), 0, getText("UI_trait_PacifistDesc"), true);
	local crafty = TraitFactory.addTrait("Crafty", getText("UI_trait_Crafty"), 3, getText("UI_trait_CraftyDesc"), false);

	-- STOMACH TRAITS
	TraitFactory.addTrait("IronGut", getText("UI_trait_IronGut"), 1, getText("UI_trait_IronGutDesc"), false);
	TraitFactory.addTrait("WeakStomach", getText("UI_trait_WeakStomach"), -1, getText("UI_trait_WeakStomachDesc"), false);
	local sensitivedigestion = TraitFactory.addTrait("SensitiveDigestion", getText("UI_trait_sensitivedigestion"), -2, getText("UI_trait_sensitivedigestiondesc"), false);	

	-- ADDICTION TRAITS
	TraitFactory.addTrait("Smoker", getText("UI_trait_Smoker"), -3, getText("UI_trait_SOSmokerDesc"), false);
	local soalcoholic = TraitFactory.addTrait("SOAlcoholic", getText("UI_trait_soalcoholic"), -5, getText("UI_trait_soalcoholicdesc"), false);	

	-- SWEATING TRAITS
	local lesssweaty = TraitFactory.addTrait("LessSweaty", getText("UI_trait_lesssweaty"), 2, getText("UI_trait_lesssweatydesc"), false);
	local highsweaty = TraitFactory.addTrait("HighSweaty", getText("UI_trait_highsweaty"), -2, getText("UI_trait_highsweatydesc"), false);	
	
	-- CAPACITY TRAITS
	TraitFactory.addTrait("Organized", getText("UI_trait_Packmule"), 4, getText("UI_trait_PackmuleDesc"), false);
	TraitFactory.addTrait("Organized2", getText("UI_trait_Packmule"), 0, getText("UI_trait_PackmuleDesc"), true);	
	TraitFactory.addTrait("Disorganized", getText("UI_trait_Disorganized"), -4, getText("UI_trait_DisorganizedDesc"), false);	

	-- CARRY WEIGHT TRAITS
	local strongback = TraitFactory.addTrait("StrongBack", getText("UI_trait_strongback"), 2, getText("UI_trait_strongbackdesc"), false);
	TraitFactory.addTrait("StrongBack2", getText("UI_trait_strongback"), 0, getText("UI_trait_strongbackdesc"), true);
	local weakback = TraitFactory.addTrait("WeakBack", getText("UI_trait_weakback"), -4, getText("UI_trait_weakbackdesc"), false);	

	-- ITEMS TRANSFERING TRAITS
	TraitFactory.addTrait("Dextrous", getText("UI_trait_Dexterous"), 2, getText("UI_trait_DexterousDesc2"), false);
	TraitFactory.addTrait("Dextrous2", getText("UI_trait_Dexterous"), 0, getText("UI_trait_DexterousDesc2"), true);
	TraitFactory.addTrait("AllThumbs", getText("UI_trait_AllThumbs"), -2, getText("UI_trait_AllThumbsDesc2"), false);

	-- BLEEDING TRAITS		
	local liquidblood = TraitFactory.addTrait("LiquidBlood", getText("UI_trait_liquidblood"), -4, getText("UI_trait_liquidblooddesc"), false);
	local thickblood = TraitFactory.addTrait("ThickBlood", getText("UI_trait_thickblood"), 2, getText("UI_trait_thickblooddesc"), false);	

	-- THIRST TRAITS
	TraitFactory.addTrait("LowThirst", getText("UI_trait_LowThirst"), 1, getText("UI_trait_LowThirstDesc"), false);
	TraitFactory.addTrait("HighThirst", getText("UI_trait_HighThirst"), -2, getText("UI_trait_HighThirstDesc"), false);

	-- HUNGER TRAITS
	TraitFactory.addTrait("LightEater", getText("UI_trait_lighteater"), 2, getText("UI_trait_lighteaterdesc"), false);
	TraitFactory.addTrait("HeartyAppetite", getText("UI_trait_heartyappetite"), -4, getText("UI_trait_heartyappetitedesc"), false);

	-- HEALING TRAITS
	TraitFactory.addTrait("FastHealer", getText("UI_trait_FastHealer"), 4, getText("UI_trait_FastHealerDesc"), false);	
	TraitFactory.addTrait("SlowHealer", getText("UI_trait_SlowHealer"), -4, getText("UI_trait_SlowHealerDesc"), false);

	-- COLD TRAITS
	TraitFactory.addTrait("Resilient", getText("UI_trait_resilient"), 2, getText("UI_trait_resilientdesc"), false);
	TraitFactory.addTrait("ProneToIllness", getText("UI_trait_pronetoillness"), -4, getText("UI_trait_pronetoillness2desc"), false);	

	-- SKIN TRAITS
	TraitFactory.addTrait("ThickSkinned", getText("UI_trait_thickskinned"), 6, getText("UI_trait_thickskinneddesc"), false);
	TraitFactory.addTrait("ThinSkinned", getText("UI_trait_ThinSkinned"), -6, getText("UI_trait_ThinSkinnedDesc"), false);

	-- SLEEPING TRAITS
	TraitFactory.addTrait("NeedsLessSleep", getText("UI_trait_LessSleep"), 4, getText("UI_trait_LessSleepDesc"), false, sleepOK);
	TraitFactory.addTrait("NeedsMoreSleep", getText("UI_trait_MoreSleep"), -4, getText("UI_trait_MoreSleepDesc"), false, sleepOK);
	TraitFactory.addTrait("Insomniac", getText("UI_trait_Insomniac"), -6, getText("UI_trait_InsomniacDesc"), false, sleepOK);
	local owlperson = TraitFactory.addTrait("OwlPerson", getText("UI_trait_owlperson"), -1, getText("UI_trait_owlpersondesc"), false, sleepOK);
	local larkperson = TraitFactory.addTrait("LarkPerson", getText("UI_trait_larkperson"), -1, getText("UI_trait_larkpersondesc"), false, sleepOK);	
	-- MOOD TRAITS
	local optimistmood = TraitFactory.addTrait("Optimist", getText("UI_trait_optimistmood"), 2, getText("UI_trait_optimistmooddesc"), false);	
	local depressivemood = TraitFactory.addTrait("Depressive", getText("UI_trait_depressivemood"), -3, getText("UI_trait_depressivemooddesc"), false);	

	-- UNIQUE NEGATIVE TRAITS	
	local chronicmigraine = TraitFactory.addTrait("ChronicMigraine", getText("UI_trait_chronicmigraine"), -2, getText("UI_trait_chronicmigrainedesc"), false);
	local snorer = TraitFactory.addTrait("Snorer", getText("UI_trait_snorer"), -1, getText("UI_trait_snorerdesc"), false, sleepOK);
	local allergic = TraitFactory.addTrait("Allergic", getText("UI_trait_allergic"), -2, getText("UI_trait_allergicdesc"), false);
	local panicattacks = TraitFactory.addTrait("PanicAttacks", getText("UI_trait_panicattacks"), -4, getText("UI_trait_panicattacksdesc"), false);	
	local sorelegs = TraitFactory.addTrait("SoreLegs", getText("UI_trait_sorelegs"), -6, getText("UI_trait_sorelegsdesc"), false);

	--Occupation traits
	TraitFactory.addTrait("Axeman", getText("UI_trait_axeman"), 0, getText("UI_trait_axemandesc"), true);
	TraitFactory.addTrait("Burglar", getText("UI_prof_Burglar"), 0, getText("UI_trait_BurglarDesc"), true);
    TraitFactory.addTrait("Marksman", getText("UI_trait_marksman"), 0, getText("UI_trait_marksmandesc"), true);	
	TraitFactory.addTrait("NightOwl", getText("UI_trait_nightowl"), 0, getText("UI_trait_nightowldesc"), true);
	local breakintechnique = TraitFactory.addTrait("BreakinTechnique", getText("UI_trait_breakintechnique"), 0, getText("UI_trait_breakintechniquedesc"), true);	
	local commdriver = TraitFactory.addTrait("CommDriver", getText("UI_trait_commdriver"), 0, getText("UI_trait_commdriverdesc"), true);
	commdriver:getFreeRecipes():add("Intermediate Mechanics");
	local enjoytheride = TraitFactory.addTrait("EnjoytheRide", getText("UI_trait_enjoytheride"), 0, getText("UI_trait_enjoytheridedesc"), true);		
	enjoytheride:getFreeRecipes():add("Advanced Mechanics");
	local usedtocorpses = TraitFactory.addTrait("UsedToCorpses", getText("UI_trait_usedtocorpses"), 0, getText("UI_trait_usedtocorpsesdesc"), true);
	local heavyaxemybeloved = TraitFactory.addTrait("HeavyAxeMyBeloved", getText("UI_trait_heavyaxemybeloved"), 0, getText("UI_trait_heavyaxemybeloveddesc"), true);
	local demostronggrip = TraitFactory.addTrait("DemoStrongGrip", getText("UI_trait_demostronggrip"), 0, getText("UI_trait_demostronggripdesc"), true);
	local gasmanagement = TraitFactory.addTrait("GasManagement", getText("UI_trait_gasmanagement"), 0, getText("UI_trait_gasmanagementdesc"), true);	
	local bladetools = TraitFactory.addTrait("BladeTools", getText("UI_trait_bladetools"), 0, getText("UI_trait_bladetoolsdesc"), true);
	local minersendurance = TraitFactory.addTrait("MinersEndurance", getText("UI_trait_minersendurance"), 0, getText("UI_trait_minersendurancedesc"), true);

	local improvisedcleaning = TraitFactory.addTrait("ImprovisedCleaning", getText("UI_trait_improvisedcleaning"), 0, getText("UI_trait_improvisedcleaningdesc"), true);
	local priestspirit = TraitFactory.addTrait("PriestSpirit", getText("UI_trait_priestspirit"), 0, getText("UI_trait_priestspiritdesc"), true);	

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
	TraitFactory.setMutualExclusive("Cook", "Culinary");	
	TraitFactory.setMutualExclusive("Cook2", "Culinary");
	
	TraitFactory.setMutualExclusive("Nutritionist2", "Nutritionist");

	TraitFactory.setMutualExclusive("Mechanics2", "Mechanics");
	
	TraitFactory.setMutualExclusive("Brave2", "Brave");	
	TraitFactory.setMutualExclusive("Brave2", "Desensitized");	
	TraitFactory.setMutualExclusive("Brave2", "Agoraphobic");
	TraitFactory.setMutualExclusive("Brave2", "Claustrophobic");
	TraitFactory.setMutualExclusive("Brave2", "Hemophobic");	
	TraitFactory.setMutualExclusive("Brave2", "Cowardly");		
	
	
	TraitFactory.setMutualExclusive("Inventive2", "Inventive");
	
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
	TraitFactory.setMutualExclusive("ThickSkinned", "ThinSkinned");	
	TraitFactory.setMutualExclusive("Resilient", "ProneToIllness");
	TraitFactory.setMutualExclusive("IronGut", "WeakStomach");
	
	TraitFactory.setMutualExclusive("LowThirst", "HighThirst");
	TraitFactory.setMutualExclusive("HeartyAppetite", "LightEater");
	
	TraitFactory.setMutualExclusive("HeartyAppetite", "Very Underweight");
	TraitFactory.setMutualExclusive("LightEater", "Obese");	
	
	TraitFactory.setMutualExclusive("FastLearner", "SlowLearner");
    TraitFactory.setMutualExclusive("Crafty", "FastLearner");
    TraitFactory.setMutualExclusive("Crafty", "SlowLearner");
	
	TraitFactory.setMutualExclusive("FastReader", "SlowReader");
	TraitFactory.setMutualExclusive("FastReader2", "FastReader");
	TraitFactory.setMutualExclusive("FastReader2", "SlowReader");
	TraitFactory.setMutualExclusive("FastReader2", "Illiterate");	
--	TraitFactory.setMutualExclusive("priestspirit", "Illiterate");
	
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
	-- Claustrophobic
	TraitFactory.setMutualExclusive("Claustrophobic", "Agoraphobic");
	TraitFactory.setMutualExclusive("Claustrophobic", "MinersEndurance");	
	
	-- AdrenalineJunkie
	TraitFactory.setMutualExclusive("AdrenalineJunkie", "AdrenalineJunkie2");
	TraitFactory.setMutualExclusive("AdrenalineJunkie", "Claustrophobic");
	TraitFactory.setMutualExclusive("AdrenalineJunkie", "Agoraphobic");
	TraitFactory.setMutualExclusive("AdrenalineJunkie2", "Claustrophobic");
	TraitFactory.setMutualExclusive("AdrenalineJunkie2", "Agoraphobic");
	-- Desensitized
	TraitFactory.setMutualExclusive("Desensitized", "AdrenalineJunkie");
	TraitFactory.setMutualExclusive("Desensitized2", "AdrenalineJunkie2");	
	TraitFactory.setMutualExclusive("Desensitized", "Hemophobic");
	TraitFactory.setMutualExclusive("Desensitized", "Cowardly");
	TraitFactory.setMutualExclusive("Desensitized", "Brave");
--	TraitFactory.setMutualExclusive("Desensitized", "Pacifist");	
	TraitFactory.setMutualExclusive("Desensitized", "Agoraphobic");
	TraitFactory.setMutualExclusive("Desensitized", "Claustrophobic");

	TraitFactory.setMutualExclusive("Desensitized2", "AdrenalineJunkie");
	TraitFactory.setMutualExclusive("Desensitized2", "Hemophobic");
	TraitFactory.setMutualExclusive("Desensitized2", "Cowardly");
	TraitFactory.setMutualExclusive("Desensitized2", "Brave");
--	TraitFactory.setMutualExclusive("Desensitized2", "Pacifist");
--	TraitFactory.setMutualExclusive("Desensitized2", "Pacifist2");	
	TraitFactory.setMutualExclusive("Desensitized2", "Agoraphobic");
	TraitFactory.setMutualExclusive("Desensitized2", "Claustrophobic");	
	
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
	
	-- Hunter
	TraitFactory.setMutualExclusive("Hunter", "Hunter2");
	
	-- Brave
	TraitFactory.setMutualExclusive("Brave", "Agoraphobic");
	TraitFactory.setMutualExclusive("Brave", "Claustrophobic");
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
--	TraitFactory.setMutualExclusive("AccMetabolism", "LightEater");	
--	TraitFactory.setMutualExclusive("AccMetabolism", "FragileHealth");		
--	TraitFactory.setMutualExclusive("AccMetabolism", "Ectomorph");	
--	TraitFactory.setMutualExclusive("AccMetabolism", "Endomorph");		
	-- FragileHealth
--	TraitFactory.setMutualExclusive("FragileHealth", "Strong");
--	TraitFactory.setMutualExclusive("FragileHealth", "Athletic");
--	TraitFactory.setMutualExclusive("FragileHealth", "StrongBack");	
--	TraitFactory.setMutualExclusive("FragileHealth", "StrongBack2");
	-- FastMetabolism and 
--	TraitFactory.setMutualExclusive("FastMetabolism", "Endomorph");	
	-- Endomorph 
--	TraitFactory.setMutualExclusive("Endomorph", "Underweight");		
--	TraitFactory.setMutualExclusive("Endomorph", "Very Underweight");	
--	TraitFactory.setMutualExclusive("Endomorph", "Athletic");		
	-- FastMetabolism
--	TraitFactory.setMutualExclusive("FastMetabolism", "Overweight");		
--	TraitFactory.setMutualExclusive("FastMetabolism", "Obese");
--	TraitFactory.setMutualExclusive("FastMetabolism", "Strong");	
	
	-- CalmMinded
	TraitFactory.setMutualExclusive("CalmMinded", "Smoker");		
	TraitFactory.setMutualExclusive("CalmMinded", "SOAlcoholic");
	TraitFactory.setMutualExclusive("CalmMinded", "PanicAttacks");	
	TraitFactory.setMutualExclusive("CalmMinded", "Hemophobic");	
	TraitFactory.setMutualExclusive("CalmMinded", "AdrenalineJunkie");	
	TraitFactory.setMutualExclusive("CalmMinded", "AdrenalineJunkie2");	
	
	-- MarathonRunner
	TraitFactory.setMutualExclusive("MarathonRunner", "Unfit");	
	TraitFactory.setMutualExclusive("MarathonRunner", "Obese");
	TraitFactory.setMutualExclusive("MarathonRunner", "Asthmatic");			
	-- Tireless
	TraitFactory.setMutualExclusive("Tireless", "Weak");
	TraitFactory.setMutualExclusive("Tireless", "Obese");	
	TraitFactory.setMutualExclusive("Tireless", "Unfit");			
	TraitFactory.setMutualExclusive("Tireless", "Very Underweight");
	TraitFactory.setMutualExclusive("Tireless", "Asthmatic");
	TraitFactory.setMutualExclusive("Tireless", "MinersEndurance");		
--	TraitFactory.setMutualExclusive("Tireless2", "Relentless");	
--	TraitFactory.setMutualExclusive("Relentless2", "Weak");
--	TraitFactory.setMutualExclusive("Relentless2", "Obese");	
--	TraitFactory.setMutualExclusive("Relentless2", "Unfit");			
--	TraitFactory.setMutualExclusive("Relentless2", "Very Underweight");
--	TraitFactory.setMutualExclusive("Tireless2", "Asthmatic");		
	-- NinjaWay	
--	TraitFactory.setMutualExclusive("NinjaWay", "Conspicuous");	
--	TraitFactory.setMutualExclusive("NinjaWay", "Clumsy");
--	TraitFactory.setMutualExclusive("NinjaWay", "Obese");	
--	TraitFactory.setMutualExclusive("NinjaWay", "Unfit");	
--	TraitFactory.setMutualExclusive("NinjaWay", "Asthmatic");		
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
--	TraitFactory.setMutualExclusive("Sniper", "ShortSighted");	
	-- SHOOTERS
	TraitFactory.setMutualExclusive("Shooter", "Shooter2");	
	-- LessSweaty and HighSweaty
	TraitFactory.setMutualExclusive("LessSweaty", "HighSweaty");
	-- Outdoorsman
	TraitFactory.setMutualExclusive("Outdoorsman", "Outdoorsman2");
	-- Hiker
	TraitFactory.setMutualExclusive("Hiker", "Agoraphobic");
	-- WildernessKnowledge
	--TraitFactory.setMutualExclusive("Herbalist", "WildernessKnowledge");
	-- Slaughterer
	TraitFactory.setMutualExclusive("Slaughterer", "Hemophobic");
	TraitFactory.setMutualExclusive("Slaughterer", "Slaughterer2");
	-- Blacksmith
	TraitFactory.setMutualExclusive("Blacksmith", "Blacksmith2");
	-- AnimalFriend
	TraitFactory.setMutualExclusive("AnimalFriend", "AnimalFriend2");	
	
	TraitFactory.sortList();

	local traitList = TraitFactory.getTraits()
	for i=1,traitList:size() do
		local trait = traitList:get(i-1)
		BaseGameCharacterDetails.SetTraitDescription(trait)
	end

end

SOTOBaseGameCharacterDetails.DoProfessions = function()

	--local sleepOK = (isClient() or isServer()) and getServerOptions():getBoolean("SleepAllowed") and getServerOptions():getBoolean("SleepNeeded")

	-- UNEMPLOYED
	local unemployed = ProfessionFactory.addProfession("unemployed", getText("UI_prof_unemployed"), "profession_unemployed", 10);

	-- FIRE OFFICER
	local fireofficer = ProfessionFactory.addProfession("fireofficer", getText("UI_prof_fireoff"), "profession_fireofficer2", -4);	
	fireofficer:addXPBoost(Perks.Strength, 1)
	fireofficer:addXPBoost(Perks.Fitness, 1)
	fireofficer:addXPBoost(Perks.Axe, 1)
	fireofficer:addXPBoost(Perks.Sprinting, 1)	
	fireofficer:addFreeTrait("Axeman");
	fireofficer:addFreeTrait("BreakinTechnique");
	
	-- POLICE OFFICER
	local policeofficer = ProfessionFactory.addProfession("policeofficer", getText("UI_prof_policeoff"), "profession_policeofficer2", -5);
	policeofficer:addXPBoost(Perks.Aiming, 2)
	policeofficer:addXPBoost(Perks.Reloading, 2)
	policeofficer:addXPBoost(Perks.SmallBlunt, 1)
	policeofficer:addXPBoost(Perks.Nimble, 1)

	-- PARK RANGER
	local parkranger = ProfessionFactory.addProfession("parkranger", getText("UI_prof_parkranger"), "profession_parkranger2", 2);
	parkranger:addXPBoost(Perks.PlantScavenging, 2)	
	parkranger:addXPBoost(Perks.Trapping, 1)
	parkranger:addFreeTrait("AdvancedForaging");	
    parkranger:getFreeRecipes():add("MakeStickTrap");
    parkranger:getFreeRecipes():add("MakeSnareTrap");
    parkranger:getFreeRecipes():add("MakeWoodenBoxTrap");
    parkranger:getFreeRecipes():add("MakeTrapBox");
    parkranger:getFreeRecipes():add("MakeCageTrap");

	-- CONSTRUCTION WORKER
	local constructionworker = ProfessionFactory.addProfession("constructionworker", getText("UI_prof_constructionworker"), "profession_constructionworker2", 0);
	constructionworker:addXPBoost(Perks.Masonry, 2)
	constructionworker:addXPBoost(Perks.SmallBlunt, 2)
--	constructionworker:addXPBoost(Perks.Maintenance, 1)		
	constructionworker:addFreeTrait("StrongBack2");	

	-- SECURITY GUARD
	local securityguard = ProfessionFactory.addProfession("securityguard", getText("UI_prof_securityguard"), "profession_securityguard2", 2);
	securityguard:addXPBoost(Perks.Lightfoot, 1)	
	securityguard:addXPBoost(Perks.Sprinting, 1)
	securityguard:addFreeTrait("NightOwl");
	securityguard:addFreeTrait("KeenHearing2");		

	-- CARPENTER
	local carpenter = ProfessionFactory.addProfession("carpenter", getText("UI_prof_Carpenter"), "profession_hammer2", -2);
	carpenter:addXPBoost(Perks.Woodwork, 2)	
	carpenter:addXPBoost(Perks.Maintenance, 1)	
	carpenter:addXPBoost(Perks.SmallBlunt, 1)
	carpenter:addXPBoost(Perks.Carving, 1)
	carpenter:addFreeTrait("Handy2");
    carpenter:getFreeRecipes():add("MakeBrakeWeapon")
    carpenter:getFreeRecipes():add("CanReinforceLongWeapon")
    carpenter:getFreeRecipes():add("CanReinforceShortWeapon")
    carpenter:getFreeRecipes():add("CanReinforceWeapon")
    carpenter:getFreeRecipes():add("MakeGardenForkHeadWeapon")
    carpenter:getFreeRecipes():add("RailspikeBaseballBat")
    carpenter:getFreeRecipes():add("MakeRailspikeCudgel")
    carpenter:getFreeRecipes():add("MakeRailspikeLongHandle")
    carpenter:getFreeRecipes():add("MakeRakeHeadWeapon")
    carpenter:getFreeRecipes():add("MakeSawPlank")
    carpenter:getFreeRecipes():add("MakeSawbladeCudgel")
    carpenter:getFreeRecipes():add("MakeSawbladeLongHandle")
    carpenter:getFreeRecipes():add("MakeSawbladePlank")
    carpenter:getFreeRecipes():add("MakeSawbladeTableLeg")
    carpenter:getFreeRecipes():add("MakeSawbladeWeapon")
    carpenter:getFreeRecipes():add("SheetMetalWeapon")
    carpenter:getFreeRecipes():add("MakeSpadeHeadCudgel")
    carpenter:getFreeRecipes():add("MakeAdvancedFramepackFrame")
    carpenter:getFreeRecipes():add("MakeAdvancedLargeFramepackFrame")

	-- BURGLAR
	local burglar = ProfessionFactory.addProfession("burglar", getText("UI_prof_Burglar"), "profession_burglar2", -1);
	burglar:addXPBoost(Perks.Nimble, 1)
	burglar:addXPBoost(Perks.Lightfoot, 1)
	burglar:addXPBoost(Perks.Sneak, 1)	
	burglar:addFreeTrait("Burglar");	
    burglar:getFreeRecipes():add("MakeForearmMagazineArmor");
    burglar:getFreeRecipes():add("MakeThighMagazineArmor");
    burglar:getFreeRecipes():add("MakeShinMagazineArmor");
    burglar:getFreeRecipes():add("MakeBodyMagazineArmor");
    burglar:getFreeRecipes():add("MakeGlassShiv");
    burglar:getFreeRecipes():add("MakeShiv");
    burglar:getFreeRecipes():add("MakeToothbrushShiv");
    burglar:getFreeRecipes():add("CopyBuildingKey");
    burglar:getFreeRecipes():add("MakeHollowBook");
    burglar:getFreeRecipes():add("MakeForearmBulletproofVestArmor");
    burglar:getFreeRecipes():add("MakeShinBulletproofVestArmor");
    burglar:getFreeRecipes():add("MakeThighBulletproofVestArmor");
    burglar:getFreeRecipes():add("Hemp Growing Season");
    burglar:getFreeRecipes():add("MakeScrewdriver");
    burglar:getFreeRecipes():add("MakeBlankID");
    burglar:getFreeRecipes():add("MakeImprovisedLighter");

	if getActivatedMods():contains("betterLockpicking") then	
--		burglar:addXPBoost(Perks.Lockpicking, 2)	
		burglar:addFreeTrait("nimblefingers")
		burglar:getFreeRecipes():add("Lockpicking");
		burglar:getFreeRecipes():add("Alarm check");
		burglar:getFreeRecipes():add("Create BobbyPin");		
	end	

	-- CHEF
	local chef = ProfessionFactory.addProfession("chef", getText("UI_prof_Chef"), "profession_chef2", 6);
	chef:addXPBoost(Perks.Cooking, 4)	
	chef:addFreeTrait("ImprovedForaging");	
	chef:addFreeTrait("Cook2");
	chef:addFreeTrait("Nutritionist2");	
	
    chef:getFreeRecipes():add("MakeCakeBatter");
    chef:getFreeRecipes():add("MakePieDough");
    chef:getFreeRecipes():add("MakeBreadDough");
    chef:getFreeRecipes():add("MakeBaguetteDough");
    chef:getFreeRecipes():add("MakeBiscuits");
    chef:getFreeRecipes():add("MakeChocolateCookieDough");
    chef:getFreeRecipes():add("MakeChocolateChipCookieDough");
    chef:getFreeRecipes():add("MakeOatmealCookieDough");
    chef:getFreeRecipes():add("MakeShortbreadCookieDough");
    chef:getFreeRecipes():add("MakeSugarCookieDough");
    chef:getFreeRecipes():add("MakePizza");
    chef:getFreeRecipes():add("MakeFriedOnionRings");
    chef:getFreeRecipes():add("MakeFriedShrimp");
    chef:getFreeRecipes():add("MakeSushi");
    chef:getFreeRecipes():add("MakeOnigiri");
    chef:getFreeRecipes():add("MakeMaki");
    chef:getFreeRecipes():add("MakeCabbageRolls");
	chef:getFreeRecipes():add("PrepareMuffins");
	chef:getFreeRecipes():add("MakeGuacamole");
    chef:getFreeRecipes():add("MakeJar");

	-- REPAIRMAN
	local repairman = ProfessionFactory.addProfession("repairman", getText("UI_prof_Repairman"), "profession_repairman2", 0);	
	repairman:addXPBoost(Perks.Woodwork, 1)
	repairman:addXPBoost(Perks.Maintenance, 2)
	repairman:addXPBoost(Perks.Carving, 1)	
	repairman:addFreeTrait("Handy2");
	
    repairman:getFreeRecipes():add("BarbedWireWeapon")
    repairman:getFreeRecipes():add("BoltBat")
    repairman:getFreeRecipes():add("MakeBrakeWeapon")
    repairman:getFreeRecipes():add("MakeBucketMaul")
    repairman:getFreeRecipes():add("CanReinforceLongWeapon")
    repairman:getFreeRecipes():add("CanReinforceShortWeapon")
    repairman:getFreeRecipes():add("CanReinforceWeapon")
    repairman:getFreeRecipes():add("MakeGardenForkHeadWeapon")
    repairman:getFreeRecipes():add("MakeKettleMaul")
    repairman:getFreeRecipes():add("RailspikeBaseballBat")
    repairman:getFreeRecipes():add("MakeRailspikeCudgel")
    repairman:getFreeRecipes():add("MakeRailspikeIronPipe")
    repairman:getFreeRecipes():add("MakeRailspikeLongHandle")
    repairman:getFreeRecipes():add("MakeRailspikeWeapon")
    repairman:getFreeRecipes():add("MakeRakeHeadWeapon")
    repairman:getFreeRecipes():add("MakeSawPlank")
    repairman:getFreeRecipes():add("MakeSawbladeCudgel")
    repairman:getFreeRecipes():add("MakeSawbladeLongHandle")
    repairman:getFreeRecipes():add("MakeSawbladePlank")
    repairman:getFreeRecipes():add("MakeSawbladeTableLeg")
    repairman:getFreeRecipes():add("MakeSawbladeWeapon")
    repairman:getFreeRecipes():add("SheetMetalWeapon")
    repairman:getFreeRecipes():add("MakeSpadeHeadCudgel")
    repairman:getFreeRecipes():add("MakeScrewdriver");

	-- LIVESTOCK FARMER / RANCHER
    local rancher = ProfessionFactory.addProfession("rancher", getText("UI_prof_rancher"), "profession_rancher", 6);
    rancher:addXPBoost(Perks.Farming, 1)
    rancher:addXPBoost(Perks.Husbandry, 2)
    rancher:addXPBoost(Perks.Butchering, 1)
	rancher:addFreeTrait("ImprovedForaging");	
    rancher:getFreeRecipes():add("MakeBarbedWire");

	if getActivatedMods():contains("Woodcutting Skill") then	
		rancher:addXPBoost(Perks.Woodcutting, 1);
	end	
	
	-- FARMER
	local farmer = ProfessionFactory.addProfession("farmer", getText("UI_prof_Farmer"), "profession_farmer2", 2);
--	farmer:addXPBoost(Perks.PlantScavenging, 1)
	farmer:addXPBoost(Perks.Farming, 4)	
	farmer:addXPBoost(Perks.Spear, 1)	
	farmer:addFreeTrait("Gardener2");
	farmer:addFreeTrait("ImprovedForaging");	
	
    farmer:getFreeRecipes():add("MakeMildewCure");
    farmer:getFreeRecipes():add("MakeFliesCureFromCigarettes");
    farmer:getFreeRecipes():add("MakeFliesCureFromLooseTobacco");
    farmer:getFreeRecipes():add("MakeFliesCureFromChewingTobacco");
    farmer:getFreeRecipes():add("MakeAphidsCure");
    farmer:getFreeRecipes():add("MakeScarecrow");
    farmer:getFreeRecipes():add("MakeBarbedWire");

    farmer:getFreeRecipes():add("Carrot Growing Season");
    farmer:getFreeRecipes():add("Broccoli Growing Season");
    farmer:getFreeRecipes():add("Radish Growing Season");
    farmer:getFreeRecipes():add("Strawberry Growing Season");
    farmer:getFreeRecipes():add("Tomato Growing Season");
    farmer:getFreeRecipes():add("Potato Growing Season");
    farmer:getFreeRecipes():add("Cabbage Growing Season");

    farmer:getFreeRecipes():add("Corn Growing Season");
    farmer:getFreeRecipes():add("Kale Growing Season");
    farmer:getFreeRecipes():add("Sweet Potato Growing Season");
    farmer:getFreeRecipes():add("Green Pea Growing Season");
    farmer:getFreeRecipes():add("Onion Growing Season");
    farmer:getFreeRecipes():add("Garlic Growing Season");
    farmer:getFreeRecipes():add("Soybean Growing Season");
    farmer:getFreeRecipes():add("Wheat Growing Season");

    farmer:getFreeRecipes():add("Basil Growing Season");
    farmer:getFreeRecipes():add("Chives Growing Season");
    farmer:getFreeRecipes():add("Cilantro Growing Season");
    farmer:getFreeRecipes():add("Oregano Growing Season");
    farmer:getFreeRecipes():add("Parsley Growing Season");
    farmer:getFreeRecipes():add("Sage Growing Season");
    farmer:getFreeRecipes():add("Rosemary Growing Season");
    farmer:getFreeRecipes():add("Thyme Growing Season");

    farmer:getFreeRecipes():add("Barley Growing Season");
    farmer:getFreeRecipes():add("Flax Growing Season");
--     farmer:getFreeRecipes():add("Hemp Growing Season"); -- it's illegal in Kentucky in 1993 so Nope! Leaving the commented out code to flag this.
    farmer:getFreeRecipes():add("Hops Growing Season");
    farmer:getFreeRecipes():add("Rye Growing Season");
    farmer:getFreeRecipes():add("Sugar Beet Growing Season");
    farmer:getFreeRecipes():add("Tobacco Growing Season");

    farmer:getFreeRecipes():add("Bell Pepper Growing Season");
    farmer:getFreeRecipes():add("Cauliflower Growing Season");
    farmer:getFreeRecipes():add("Cucumber Growing Season");
    farmer:getFreeRecipes():add("Habanero Growing Season");
    farmer:getFreeRecipes():add("Jalapeno Growing Season");
    farmer:getFreeRecipes():add("Leek Growing Season");
    farmer:getFreeRecipes():add("Lettuce Growing Season");
    farmer:getFreeRecipes():add("Pumpkin Growing Season");
    farmer:getFreeRecipes():add("Spinach Growing Season");
    farmer:getFreeRecipes():add("Sunflower Growing Season");
    farmer:getFreeRecipes():add("Turnip Growing Season");
    farmer:getFreeRecipes():add("Watermelon Growing Season");
    farmer:getFreeRecipes():add("Zucchini Growing Season");

    farmer:getFreeRecipes():add("Chamomile Growing Season");
    farmer:getFreeRecipes():add("Lemongrass Growing Season");
    farmer:getFreeRecipes():add("Marigold Growing Season");
    farmer:getFreeRecipes():add("Mint Growing Season");

    farmer:getFreeRecipes():add("MakeJarofTomatoes");
    farmer:getFreeRecipes():add("MakeJarofCarrots");
    farmer:getFreeRecipes():add("MakeJarofPotatoes");
    farmer:getFreeRecipes():add("MakeJarofEggplant");
    farmer:getFreeRecipes():add("MakeJarofLeeks");
    farmer:getFreeRecipes():add("MakeJarofRedRadishes");
    farmer:getFreeRecipes():add("MakeJarofBellPeppers");
    farmer:getFreeRecipes():add("MakeJarofCabbage");
    farmer:getFreeRecipes():add("MakeJarofBroccoli");
	
	farmer:getFreeRecipes():add("MakeJar");

	if getActivatedMods():contains("Woodcutting Skill") then	
		farmer:addXPBoost(Perks.Woodcutting, 1);
	end	

	-- FISHERMAN
	local fisherman = ProfessionFactory.addProfession("fisherman", getText("UI_prof_Fisherman"), "profession_fisher2", 4);
	fisherman:addXPBoost(Perks.Fishing, 2)
	fisherman:addFreeTrait("Outdoorsman2");		
	fisherman:addFreeTrait("ImprovedForaging");
	
    fisherman:getFreeRecipes():add("MakeFishingRod");
    fisherman:getFreeRecipes():add("FixFishingRod");
    fisherman:getFreeRecipes():add("GetWireBack");
    fisherman:getFreeRecipes():add("MakeFishingNet");
    fisherman:getFreeRecipes():add("MakeChum");

	-- DOCTOR
	local doctor = ProfessionFactory.addProfession("doctor", getText("UI_prof_Doctor"), "profession_doctor2", 7);
	doctor:addXPBoost(Perks.Doctor, 4)
	doctor:addFreeTrait("FirstAid2");
    if getActivatedMods():contains("piesfirstaidoverhaul") then
		doctor:addFreeTrait("DoctorPerk")
	end
    if getActivatedMods():contains("BB_FirstAidOverhaul") then
		doctor:addFreeTrait("MedicalPractitioner")
	end	

	-- VETERAN
	local veteran = ProfessionFactory.addProfession("veteran", getText("UI_prof_Veteran"), "profession_veteran2", -8);
	veteran:addXPBoost(Perks.Reloading, 2)
	veteran:addXPBoost(Perks.Aiming, 2)
	veteran:addXPBoost(Perks.SmallBlade, 1)	
	veteran:addFreeTrait("Desensitized");
	veteran:addFreeTrait("ImprovedForaging");

    veteran:getFreeRecipes():add("MakeTarpChestRig");	
	
	if getActivatedMods():contains("AliceSPack") then	
		veteran:addFreeTrait("Metalstrongback2");
	end
	
	-- NURSE
	local nurse = ProfessionFactory.addProfession("nurse", getText("UI_prof_Nurse"), "profession_nurse", 8);
	nurse:addXPBoost(Perks.Lightfoot, 1)
	nurse:addXPBoost(Perks.Doctor, 1)
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
	local lumberjack = ProfessionFactory.addProfession("lumberjack", getText("UI_prof_Lumberjack"), "profession_lumberjack", -5);
	lumberjack:addXPBoost(Perks.Strength, 1)
	lumberjack:addXPBoost(Perks.Axe, 2)
	lumberjack:addFreeTrait("Axeman");
	lumberjack:addFreeTrait("HeavyAxeMyBeloved");
	lumberjack:addFreeTrait("ImprovedForaging");
	
	if getActivatedMods():contains("AliceSPack") then	
		lumberjack:addFreeTrait("Metalstrongback2");
	end
	if getActivatedMods():contains("Woodcutting Skill") then	
		lumberjack:addXPBoost(Perks.Woodcutting, 3);
	end	

	-- FITNESS INSTRUCTOR
	local fitnessInstructor = ProfessionFactory.addProfession("fitnessInstructor", getText("UI_prof_FitnessInstructor"), "profession_fitnessinstructor", -3);
	fitnessInstructor:addXPBoost(Perks.Sprinting, 2)
	fitnessInstructor:addXPBoost(Perks.Fitness, 3)
	fitnessInstructor:addFreeTrait("Nutritionist2");	
	
	if getActivatedMods():contains("AliceSPack") then	
		fitnessInstructor:addFreeTrait("Strongback2");
	end	
	
	-- BURGER FLIPPER
	local burger = ProfessionFactory.addProfession("burgerflipper", getText("UI_prof_BurgerFlipper"), "profession_burgerflipper", 2);
	burger:addXPBoost(Perks.Cooking, 1)
	burger:addXPBoost(Perks.Maintenance, 1)	
	burger:addXPBoost(Perks.Nimble, 1)
	
    burger:getFreeRecipes():add("MakePizza");
	
	-- ELECTRICIAN
	local electrician = ProfessionFactory.addProfession("electrician", getText("UI_prof_Electrician"), "profession_electrician", 6);
	electrician:addXPBoost(Perks.Electricity, 2)
	electrician:addFreeTrait("GenExp2");
    electrician:getFreeRecipes():add("Generator");
    electrician:getFreeRecipes():add("MakeRemoteControllerV1");
    electrician:getFreeRecipes():add("MakeRemoteControllerV2");
    electrician:getFreeRecipes():add("MakeRemoteControllerV3");
    electrician:getFreeRecipes():add("MakeRemoteTrigger");
    electrician:getFreeRecipes():add("MakeTimer");
    electrician:getFreeRecipes():add("CraftMakeshiftRadio");
    electrician:getFreeRecipes():add("CraftMakeshiftHAMRadio");
    electrician:getFreeRecipes():add("CraftMakeshiftWalkieTalkie");
    electrician:getFreeRecipes():add("MakeImprovisedFlashlight");
    electrician:getFreeRecipes():add("MakeImprovisedLantern");
    electrician:getFreeRecipes():add("MakeImprovisedLighter");

	-- ENGINEER
	local engineer = ProfessionFactory.addProfession("engineer", getText("UI_prof_Engineer"), "profession_engineer", 3);
	engineer:addXPBoost(Perks.Maintenance, 1)
	engineer:addXPBoost(Perks.Electricity, 1)
	engineer:addFreeTrait("GenExp2");
	engineer:addFreeTrait("Inventive2");
	
    engineer:getFreeRecipes():add("Generator");
    engineer:getFreeRecipes():add("MakeAerosolBomb");
    engineer:getFreeRecipes():add("MakeFlameBomb");
    engineer:getFreeRecipes():add("MakePipeBomb");
    engineer:getFreeRecipes():add("MakeNoisegenerator");
    engineer:getFreeRecipes():add("MakeSmokeBomb");
    engineer:getFreeRecipes():add("MakeFirecracker");
    engineer:getFreeRecipes():add("MakeCraftedGasMaskFilter");
    engineer:getFreeRecipes():add("MakeImprovisedGasMask");
    engineer:getFreeRecipes():add("RechargeGasMaskFilter");
    engineer:getFreeRecipes():add("RechargeRespiratorFilters");
    engineer:getFreeRecipes():add("RechargeFilters");
    engineer:getFreeRecipes():add("MakeImprovisedFlashlight");
    engineer:getFreeRecipes():add("MakeImprovisedLantern");
    engineer:getFreeRecipes():add("MakeImprovisedLighter");
	
	-- METALWORKER
	local metalworker = ProfessionFactory.addProfession("metalworker", getText("UI_prof_MetalWorker"), "profession_metalworker", 3);
	metalworker:addXPBoost(Perks.MetalWelding, 2)
	metalworker:addXPBoost(Perks.Maintenance, 1)	

    metalworker:getFreeRecipes():add("Make Metal Walls");
    metalworker:getFreeRecipes():add("Make Metal Fences");
    metalworker:getFreeRecipes():add("Make Metal Containers");
    metalworker:getFreeRecipes():add("Make Metal Sheet");
    metalworker:getFreeRecipes():add("Make Small Metal Sheet");
    metalworker:getFreeRecipes():add("Make Metal Roof");
	
    metalworker:getFreeRecipes():add("MakeScrapMetalHelmet");
    metalworker:getFreeRecipes():add("MakeScrapMetalShoulderArmor");
    metalworker:getFreeRecipes():add("MakeScrapMetalThighArmor");
    metalworker:getFreeRecipes():add("MakeScrapMetalBodyArmor");
    metalworker:getFreeRecipes():add("SpikeArmorWelding");
    metalworker:getFreeRecipes():add("Drill_Draw_Plate");
    metalworker:getFreeRecipes():add("Drill_Heading_Tool");
	
    metalworker:getFreeRecipes():add("MetalWallLvl1");
    metalworker:getFreeRecipes():add("MetalWallLvl2");
    metalworker:getFreeRecipes():add("MetalFloorLvl1");
    metalworker:getFreeRecipes():add("MetalWindowFrameLvl1");
    metalworker:getFreeRecipes():add("MetalWindowFrameLvl2");
    metalworker:getFreeRecipes():add("MetalWallFrame");
    metalworker:getFreeRecipes():add("MetalDoorFrameLvl1");
    metalworker:getFreeRecipes():add("MetalDoorFrameLvl2");
    metalworker:getFreeRecipes():add("Metal_Stairs");
	
    metalworker:getFreeRecipes():add("Metal_Counter_Lvl1");
    metalworker:getFreeRecipes():add("Metal_Counter_Lvl2");
    metalworker:getFreeRecipes():add("Metal_CounterCorner_Lvl1");
    metalworker:getFreeRecipes():add("Metal_CounterCorner_Lvl2");
    metalworker:getFreeRecipes():add("Metal_Crate_Lvl1");
    metalworker:getFreeRecipes():add("Metal_Crate_Lvl2");
    metalworker:getFreeRecipes():add("Metal_LockerBig_Lvl1");
    metalworker:getFreeRecipes():add("Metal_LockerBig_Lvl2");
    metalworker:getFreeRecipes():add("Metal_LockerSmall_Lvl1");
    metalworker:getFreeRecipes():add("Metal_LockerSmall_Lvl2");
    metalworker:getFreeRecipes():add("Metal_Shelves_Lvl1");
    metalworker:getFreeRecipes():add("Metal_Shelves_Lvl2");

    metalworker:getFreeRecipes():add("MetalPoleFenceGate");
    metalworker:getFreeRecipes():add("MetalWireFenceGate");
    metalworker:getFreeRecipes():add("MetalWireFenceGateSmall");
    metalworker:getFreeRecipes():add("DoubleFenceGate");
    metalworker:getFreeRecipes():add("DoubleWireGate");
    metalworker:getFreeRecipes():add("MetalBigWireFence");
    metalworker:getFreeRecipes():add("MetalBigMetalFence");
    metalworker:getFreeRecipes():add("MetalPoleFenceGateSmall");
    metalworker:getFreeRecipes():add("MetalSmallPoleFence");
    metalworker:getFreeRecipes():add("MetalFenceLvl1");
    metalworker:getFreeRecipes():add("MetalSmallWireFence");

	-- BLACKSMITH
	local smither = ProfessionFactory.addProfession("smither", getText("UI_prof_Smither"), "profession_smither", 0);
	smither:addXPBoost(Perks.Blacksmith, 2);
	smither:addXPBoost(Perks.Maintenance, 1)
	smither:addXPBoost(Perks.SmallBlunt, 1)
	smither:addFreeTrait("Blacksmith2");
	
	doMetalWorkerRecipes(smither);

	-- MECHANICS
	local mechanics = ProfessionFactory.addProfession("mechanics", getText("UI_prof_Mechanics"), "profession_mechanic", 4)
	mechanics:addXPBoost(Perks.Mechanics, 2)
	mechanics:addFreeTrait("Mechanics2");
	mechanics:getFreeRecipes():add("Basic Mechanics");
	mechanics:getFreeRecipes():add("Intermediate Mechanics");
	mechanics:getFreeRecipes():add("Advanced Mechanics");

	-- TAILOR
	local tailor = ProfessionFactory.addProfession("tailorProfession", getText("UI_prof_Tailor"), "profession_tailor", 5);
	tailor:addXPBoost(Perks.Tailoring, 2);
	tailor:addFreeTrait("Dextrous2");
 
	doTailorRecipes(tailor);	
	
	----------------------
	-- SOTO OCCUPATIONS --
	----------------------
	
	--[[ TAILOR
	local tailorocc = ProfessionFactory.addProfession("tailorocc", getText("UI_prof_tailorocc"), "icon_tailorocc", 4)
	tailorocc:addXPBoost(Perks.Tailoring, 2)
	tailorocc:addFreeTrait("Dextrous2");
    tailorocc:getFreeRecipes():add("KnitBalaclavaFace");
    tailorocc:getFreeRecipes():add("KnitBalaclavaFull");
    tailorocc:getFreeRecipes():add("KnitBeany");
    tailorocc:getFreeRecipes():add("KnitDoily");
    tailorocc:getFreeRecipes():add("KnitLegwarmers");
    tailorocc:getFreeRecipes():add("KnitScarf");
    tailorocc:getFreeRecipes():add("KnitSocks");
    tailorocc:getFreeRecipes():add("KnitSweaterVest");
    tailorocc:getFreeRecipes():add("KnitWoolyHat");
	]]
	
	-- DELIVERYMAN
	local deliverymanocc = ProfessionFactory.addProfession("deliverymanocc", getText("UI_prof_deliverymanocc"), "icon_deliverymanocc", -2)
	deliverymanocc:addXPBoost(Perks.Nimble, 1)
	deliverymanocc:addXPBoost(Perks.Sprinting, 2)
	deliverymanocc:addFreeTrait("Organized2");	

	-- LOADER
	local loaderocc = ProfessionFactory.addProfession("loaderocc", getText("UI_prof_loaderocc"), "icon_loaderocc", -2)
	loaderocc:addXPBoost(Perks.Strength, 2)
	loaderocc:addXPBoost(Perks.Nimble, 1)
	loaderocc:addFreeTrait("StrongBack2");

	if getActivatedMods():contains("AliceSPack") then	
		loaderocc:addFreeTrait("Metalstrongback2");
	end	
	
	-- TRUCK DRIVER
	local truckerocc = ProfessionFactory.addProfession("truckerocc", getText("UI_prof_truckerocc"), "icon_truckerocc", 4)
	truckerocc:addXPBoost(Perks.Mechanics, 1)
	truckerocc:addXPBoost(Perks.Maintenance, 1)
	truckerocc:addFreeTrait("CommDriver");
 
	if getActivatedMods():contains("DrivingSkill") then
		truckerocc:addXPBoost(Perks.Driving, 2)	
	end			
	
	-- SOLDIER
	local soldierocc = ProfessionFactory.addProfession("soldierocc", getText("UI_prof_soldierocc"), "icon_soldierocc", -7)
	soldierocc:addXPBoost(Perks.Strength, 1)
	soldierocc:addXPBoost(Perks.Fitness, 1)
	soldierocc:addXPBoost(Perks.Reloading, 2)	
	soldierocc:addXPBoost(Perks.Aiming, 2)
	soldierocc:addXPBoost(Perks.SmallBlade, 1)	
	soldierocc:addFreeTrait("NightOwl");
	soldierocc:addFreeTrait("ImprovedForaging");	

	if getActivatedMods():contains("AliceSPack") then	
		soldierocc:addFreeTrait("Metalstrongback2");
	end		

	-- BOTANIST
	local botanistocc = ProfessionFactory.addProfession("botanistocc", getText("UI_prof_botanistocc"), "icon_botanistocc", 1)
	botanistocc:addXPBoost(Perks.Farming, 1)	
	botanistocc:addXPBoost(Perks.PlantScavenging, 2)
	botanistocc:addFreeTrait("Herbalist2");
	botanistocc:addFreeTrait("AdvancedForaging");

    botanistocc:getFreeRecipes():add("Herbalist");
    botanistocc:getFreeRecipes():add("MakePlantainPoultice");
    botanistocc:getFreeRecipes():add("MakeComfreyPoultice");
    botanistocc:getFreeRecipes():add("MakeWildGarlicPoultice");

    botanistocc:getFreeRecipes():add("Black Sage Growing Season");
    botanistocc:getFreeRecipes():add("Broadleaf Plantain Growing Season");
    botanistocc:getFreeRecipes():add("Comfrey Growing Season");
    botanistocc:getFreeRecipes():add("Common Mallow Growing Season");
    botanistocc:getFreeRecipes():add("Wild Garlic Growing Season");

	-- GRAVE DIGGER
	local gravemanocc = ProfessionFactory.addProfession("gravemanocc", getText("UI_prof_gravemanocc"), "icon_gravemanocc", -2)	
	gravemanocc:addXPBoost(Perks.Strength, 1)		
	gravemanocc:addXPBoost(Perks.Blunt, 1)
	gravemanocc:addXPBoost(Perks.Maintenance, 1)	
	gravemanocc:addFreeTrait("UsedToCorpses");
	gravemanocc:addFreeTrait("ImprovedForaging");
	
	-- DANCER
	local dancerocc = ProfessionFactory.addProfession("dancerocc", getText("UI_prof_dancerocc"), "icon_dancerocc", -3)	
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
	local priestocc = ProfessionFactory.addProfession("priestocc", getText("UI_prof_priestocc"), "icon_priestocc", 14)	
	priestocc:addXPBoost(Perks.Lightfoot, 2)
	priestocc:getFreeRecipes():add("WriteAPrayer");	
	priestocc:addFreeTrait("Pacifist2");
--	priestocc:addFreeTrait("priestspirit");	
	
	-- WEIGHTLIFTING INSTRUCTOR
	local heavyathinstructorocc = ProfessionFactory.addProfession("heavyathinstructorocc", getText("UI_prof_heavyathinstructorocc"), "icon_heavyathinstructorocc", -4);
	heavyathinstructorocc:addXPBoost(Perks.Strength, 3)
	heavyathinstructorocc:addXPBoost(Perks.Fitness, 1)	
	heavyathinstructorocc:addFreeTrait("StrongBack2");	
	heavyathinstructorocc:addFreeTrait("Nutritionist2");
	
	if getActivatedMods():contains("AliceSPack") then	
		heavyathinstructorocc:addFreeTrait("Metalstrongback2");
	end		
	
	-- DETECTIVE
	local detectiveocc = ProfessionFactory.addProfession("detectiveocc", getText("UI_prof_detectiveocc"), "icon_detectiveocc", 0)	
	detectiveocc:addXPBoost(Perks.Sneak, 1)
	detectiveocc:addXPBoost(Perks.Aiming, 1)	
	detectiveocc:addXPBoost(Perks.Reloading, 1)		
	detectiveocc:addXPBoost(Perks.PlantScavenging, 1)	
	detectiveocc:addXPBoost(Perks.Tracking, 1)
	detectiveocc:addFreeTrait("AdvancedForaging");

    detectiveocc:getFreeRecipes():add("MakeHollowBook");
	
	if getActivatedMods():contains("ScavengingSkill") or getActivatedMods():contains("ScavengingSkillFixed") then
		detectiveocc:addXPBoost(Perks.Scavenging, 1)	
	end
	
	-- SCHOOL TEACHER
	local teacherocc = ProfessionFactory.addProfession("teacherocc", getText("UI_prof_teacherocc"), "icon_teacherocc", 8)
	teacherocc:addXPBoost(Perks.Lightfoot, 1)
	teacherocc:addFreeTrait("FastReader2");	
	teacherocc:addFreeTrait("LifelongLearner");		

	-- JANITOR
	local cleanermanocc = ProfessionFactory.addProfession("cleanermanocc", getText("UI_prof_cleanermanocc"), "icon_cleanermanocc", 2)
	cleanermanocc:addXPBoost(Perks.Spear, 1)
	cleanermanocc:addXPBoost(Perks.Maintenance, 1)
	cleanermanocc:addFreeTrait("ImprovedForaging");
--	cleanermanocc:addFreeTrait("ImprovisedCleaning");	
--	cleanermanocc:getFreeRecipes():add("MakeCleaningLiquid");
--	cleanermanocc:getFreeRecipes():add("MakeBleach");

    if getActivatedMods():contains("ScavengingSkill") or getActivatedMods():contains("ScavengingSkillFixed") then
		cleanermanocc:addXPBoost(Perks.Scavenging, 1)	
	end		

	-- STUNTMAN
	local stuntmanocc = ProfessionFactory.addProfession("stuntmanocc", getText("UI_prof_stuntmanocc"), "icon_stuntmanocc", -2)
	stuntmanocc:addXPBoost(Perks.Sprinting, 1)
	stuntmanocc:addXPBoost(Perks.Fitness, 1)
	stuntmanocc:addXPBoost(Perks.Nimble, 1)	
	stuntmanocc:addFreeTrait("AdrenalineJunkie2");
	
	-- GAS STATION OPERATOR
	local gasstationoperatorocc = ProfessionFactory.addProfession("gasstationoperatorocc", getText("UI_prof_gasstationoperatorocc"), "icon_gasstationoperatorocc", 0)
	gasstationoperatorocc:addXPBoost(Perks.Nimble, 1)
	gasstationoperatorocc:addXPBoost(Perks.Maintenance, 1)
	gasstationoperatorocc:addXPBoost(Perks.Mechanics, 1)	
	gasstationoperatorocc:addFreeTrait("GasManagement");		

	-- CAMP COUNSELOR
	local campcounsocc = ProfessionFactory.addProfession("campcounsocc", getText("UI_prof_campcounsocc"), "icon_campcounsocc", 1)
	campcounsocc:addXPBoost(Perks.Tailoring, 1)	
	campcounsocc:addXPBoost(Perks.Carving, 1)	
	campcounsocc:addXPBoost(Perks.Doctor, 1)
	campcounsocc:addXPBoost(Perks.Fishing, 1)	
	campcounsocc:addXPBoost(Perks.PlantScavenging, 1)
	campcounsocc:addFreeTrait("Formerscout2");
	campcounsocc:addFreeTrait("AdvancedForaging");
	campcounsocc:getFreeRecipes():add("MakeFishingRod");
	campcounsocc:getFreeRecipes():add("FixFishingRod");
	campcounsocc:getFreeRecipes():add("GetWireBack");
    campcounsocc:getFreeRecipes():add("MakeChum");	
    campcounsocc:getFreeRecipes():add("MakeFishingNet");
    campcounsocc:getFreeRecipes():add("SharpenBone");
    campcounsocc:getFreeRecipes():add("MakeBoneFishingHook");
    campcounsocc:getFreeRecipes():add("MakeBoneSewingNeedle");

	if getActivatedMods():contains("Woodcutting Skill") then	
		campcounsocc:addXPBoost(Perks.Woodcutting, 2);
	end	

	-- DRAG RACER
	local dragracerocc = ProfessionFactory.addProfession("dragracerocc", getText("UI_prof_dragracerocc"), "icon_dragracerocc", 3)
	dragracerocc:addXPBoost(Perks.Nimble, 1)
	dragracerocc:addXPBoost(Perks.Mechanics, 1)
	dragracerocc:addFreeTrait("SpeedDemon2");
	dragracerocc:addFreeTrait("EnjoytheRide");
	
	dragracerocc:getFreeRecipes():add("AdvancedMechanics");
	
    if getActivatedMods():contains("DrivingSkill") then
		dragracerocc:addXPBoost(Perks.Driving, 2)	
	end			
	
	-- JUNKYARD WORKER
	local junkyardworkerocc = ProfessionFactory.addProfession("junkyardworkerocc", getText("UI_prof_junkyardworkerocc"), "icon_junkyardworkerocc", 2)
	junkyardworkerocc:addXPBoost(Perks.Mechanics, 1)	
	junkyardworkerocc:addXPBoost(Perks.MetalWelding, 1)
	junkyardworkerocc:addXPBoost(Perks.Blacksmith, 1)
	junkyardworkerocc:addFreeTrait("AdvancedForaging");	

	junkyardworkerocc:getFreeRecipes():add("MakeTireArmor");
	junkyardworkerocc:getFreeRecipes():add("MakeTireBodyArmor");
	junkyardworkerocc:getFreeRecipes():add("MakeTireForearmArmor");
	junkyardworkerocc:getFreeRecipes():add("MakeTireShinArmor");
	junkyardworkerocc:getFreeRecipes():add("MakeTireShoulderArmorLeft");
	junkyardworkerocc:getFreeRecipes():add("MakeTireShoulderArmorRight");
	junkyardworkerocc:getFreeRecipes():add("MakeTireThighArmor");
	
	junkyardworkerocc:getFreeRecipes():add("BuildMetalStructureScrap");
	junkyardworkerocc:getFreeRecipes():add("MakeMetalSheet");
    junkyardworkerocc:getFreeRecipes():add("Make Metal Sheet");
	junkyardworkerocc:getFreeRecipes():add("MakeSmallMetalSheet");
    junkyardworkerocc:getFreeRecipes():add("Make Small Metal Sheet");
    junkyardworkerocc:getFreeRecipes():add("MakeScrapMetalHelmet");
    junkyardworkerocc:getFreeRecipes():add("MakeScrapMetalShoulderArmor");
    junkyardworkerocc:getFreeRecipes():add("MakeScrapMetalThighArmor");
    junkyardworkerocc:getFreeRecipes():add("MakeScrapMetalBodyArmor");
    junkyardworkerocc:getFreeRecipes():add("SpikeArmorWelding");

    if getActivatedMods():contains("ScavengingSkill") or getActivatedMods():contains("ScavengingSkillFixed") then
		junkyardworkerocc:addXPBoost(Perks.Scavenging, 1)	
	end	
	
	-- LIFEGUARD
	local lifeguardocc = ProfessionFactory.addProfession("lifeguardocc", getText("UI_prof_lifeguardocc"), "icon_lifeguardocc", 1)
	lifeguardocc:addXPBoost(Perks.Fitness, 1)	
	lifeguardocc:addXPBoost(Perks.Doctor, 1)
	lifeguardocc:addXPBoost(Perks.Sprinting, 1)	
	lifeguardocc:addFreeTrait("BreathingTech");		
	lifeguardocc:addFreeTrait("EagleEyed2");
	
    if getActivatedMods():contains("BB_FirstAidOverhaul") then
		lifeguardocc:addFreeTrait("MedicalPractitioner")
	end			

	-- DEMOLITION WORKER
	local demoworkerocc = ProfessionFactory.addProfession("demoworkerocc", getText("UI_prof_demoworkerocc"), "icon_demoworkerocc", -2)
	demoworkerocc:addXPBoost(Perks.Strength, 1)		
	demoworkerocc:addXPBoost(Perks.Blunt, 2)
	demoworkerocc:addFreeTrait("DemoStrongGrip");	
	
	-- BUTCHER
	local butcherocc = ProfessionFactory.addProfession("butcherocc", getText("UI_prof_butcherocc"), "icon_butcherocc", 7)
	--butcherocc:addXPBoost(Perks.SmallBlade, 1)
	--butcherocc:addXPBoost(Perks.LongBlade, 1)
    butcherocc:addXPBoost(Perks.Butchering, 4)
	butcherocc:addFreeTrait("BladeTools");
	butcherocc:addFreeTrait("Slaughterer2");
	
	-- PAPARAZZI
	local paparazziocc = ProfessionFactory.addProfession("paparazziocc", getText("UI_prof_paparazziocc"), "icon_paparazziocc", 4)
	paparazziocc:addXPBoost(Perks.Lightfoot, 1)
	paparazziocc:addXPBoost(Perks.Sneak, 2)
	paparazziocc:addFreeTrait("Inconspicuous2");

	-- MINER
	local minerocc = ProfessionFactory.addProfession("minerocc", getText("UI_prof_minerocc"), "icon_minerocc", -4)
	minerocc:addXPBoost(Perks.Axe, 1)
	minerocc:addXPBoost(Perks.Maintenance, 1)
	minerocc:addXPBoost(Perks.Fitness, 1)	
	minerocc:addFreeTrait("NightVision2");	
	minerocc:addFreeTrait("MinersEndurance");
	
	-- STORE EMPLOYEE
	local cashierocc = ProfessionFactory.addProfession("cashierocc", getText("UI_prof_cashierocc"), "icon_cashierocc", 5)
	cashierocc:addXPBoost(Perks.Maintenance, 1)
	cashierocc:addXPBoost(Perks.Lightfoot, 1)	
	cashierocc:addFreeTrait("Dextrous2");	
	
	-- CRIMINAL
	local criminalocc = ProfessionFactory.addProfession("criminalocc", getText("UI_prof_criminalocc"), "icon_criminalocc", -1)
	criminalocc:addXPBoost(Perks.SmallBlade, 1)
	criminalocc:addXPBoost(Perks.Nimble, 1)
	criminalocc:addXPBoost(Perks.Sprinting, 1)
	criminalocc:addFreeTrait("Cruelty2");		

    criminalocc:getFreeRecipes():add("MakeForearmMagazineArmor");
    criminalocc:getFreeRecipes():add("MakeThighMagazineArmor");
    criminalocc:getFreeRecipes():add("MakeShinMagazineArmor");
    criminalocc:getFreeRecipes():add("MakeBodyMagazineArmor");
    criminalocc:getFreeRecipes():add("MakeGlassShiv");
    criminalocc:getFreeRecipes():add("MakeShiv");
    criminalocc:getFreeRecipes():add("MakeToothbrushShiv");
    --criminalocc:getFreeRecipes():add("CopyBuildingKey");
    criminalocc:getFreeRecipes():add("MakeHollowBook");
    criminalocc:getFreeRecipes():add("MakeForearmBulletproofVestArmor");
    criminalocc:getFreeRecipes():add("MakeShinBulletproofVestArmor");
    criminalocc:getFreeRecipes():add("MakeThighBulletproofVestArmor");
    criminalocc:getFreeRecipes():add("Hemp Growing Season");
    criminalocc:getFreeRecipes():add("MakeScrewdriver");
    criminalocc:getFreeRecipes():add("MakeBlankID");
    criminalocc:getFreeRecipes():add("MakeImprovisedLighter");

	-- ANIMAL CONTROL OFFICER
	local animalcontrolofficerocc = ProfessionFactory.addProfession("animalcontrolofficerocc", getText("UI_prof_animalcontrolofficerocc"), "icon_animalcontrolofficerocc", 0)
	animalcontrolofficerocc:addXPBoost(Perks.Fitness, 1)	
	animalcontrolofficerocc:addXPBoost(Perks.Trapping, 2)
	animalcontrolofficerocc:addXPBoost(Perks.Tracking, 1)
    animalcontrolofficerocc:addXPBoost(Perks.Husbandry, 1)	
	animalcontrolofficerocc:addXPBoost(Perks.Sprinting, 1)
	animalcontrolofficerocc:getFreeRecipes():add("MakeStickTrap");
	animalcontrolofficerocc:getFreeRecipes():add("MakeSnareTrap");
	animalcontrolofficerocc:getFreeRecipes():add("MakeWoodenBoxTrap");
	animalcontrolofficerocc:getFreeRecipes():add("MakeTrapBox");
	animalcontrolofficerocc:getFreeRecipes():add("MakeCageTrap");

	-- HUNTER
	local hunterocc = ProfessionFactory.addProfession("hunterocc", getText("UI_prof_hunterocc"), "icon_hunterocc", -3)
	hunterocc:addXPBoost(Perks.Aiming, 1)
	hunterocc:addXPBoost(Perks.Reloading, 1)	
	hunterocc:addXPBoost(Perks.Trapping, 1)
	hunterocc:addXPBoost(Perks.Sneak, 1)
	hunterocc:addXPBoost(Perks.SmallBlade, 1)
	hunterocc:addXPBoost(Perks.Tracking, 2)
--	hunterocc:addXPBoost(Perks.Butchering, 1)
    hunterocc:getFreeRecipes():add("MakeStickTrap");
    hunterocc:getFreeRecipes():add("MakeSnareTrap");
    hunterocc:getFreeRecipes():add("MakeWoodenBoxTrap");
    hunterocc:getFreeRecipes():add("MakeTrapBox");
    hunterocc:getFreeRecipes():add("MakeCageTrap");
	hunterocc:addFreeTrait("Hunter2");
	hunterocc:addFreeTrait("ImprovedForaging");

	-- VETERINAR
	local veterinarianocc = ProfessionFactory.addProfession("veterinarianocc", getText("UI_prof_veterinarianocc"), "icon_veterinarianocc", 5)
	veterinarianocc:addXPBoost(Perks.Husbandry, 4)
	veterinarianocc:addXPBoost(Perks.Doctor, 1)
	veterinarianocc:addXPBoost(Perks.Lightfoot, 1)
	veterinarianocc:addFreeTrait("AnimalFriend2");
	
	-- OCCUPATIONS DESC
	local profList = ProfessionFactory.getProfessions()
		for i = 1, profList:size() do
		local prof = profList:get(i - 1)
		BaseGameCharacterDetails.SetProfessionDescription(prof)
	end

end

SOTOBaseGameCharacterDetails.DoNewCharacterInitializations = function(playernum, character)
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
		if player:getModData().AlcoholicTimeSinceLastDrink == nil then
			player:getModData().AlcoholicTimeSinceLastDrink = 0;
		end	
	end

	if player:HasTrait("ChronicMigraine") then
		if player:getModData().migraineCooldown == nil then
			player:getModData().migraineCooldown = 0
		end
		if player:getModData().migraineDuration == nil then
			player:getModData().migraineDuration = 0
		end
		local initialDelay = ZombRand(72, 288) -- 12-48 hours
		player:getModData().migraineCooldown = initialDelay
		-- local initialDelayHours = math.floor(initialDelay)
		-- print("The first migraine:" .. initialDelayHours)
	end

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
	if player:HasTrait("Tireless2") then
		player:getTraits():remove("Tireless2");
		player:getTraits():add("Tireless");
	end	
	if player:HasTrait("Dextrous2") then
		player:getTraits():remove("Dextrous2");
		player:getTraits():add("Dextrous");
	end
	
	if player:HasTrait("Inventive2") then
		player:getTraits():remove("Inventive2");
		player:getTraits():add("Inventive");
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
	if player:HasTrait("AnimalFriend2") then
		player:getTraits():remove("AnimalFriend2");
		player:getTraits():add("AnimalFriend");
	end
	if player:HasTrait("Slaughterer2") then
		player:getTraits():remove("Slaughterer2");
		player:getTraits():add("Slaughterer");
	end
	if player:HasTrait("Hunter2") then
		player:getTraits():remove("Hunter2");
		player:getTraits():add("Hunter");
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

Events.OnGameBoot.Add(SOTOBaseGameCharacterDetails.DoTraits);
Events.OnGameBoot.Add(SOTOBaseGameCharacterDetails.DoProfessions);
Events.OnCreatePlayer.Add(SOTOBaseGameCharacterDetails.DoNewCharacterInitializations);
Events.OnCreateLivingCharacter.Add(SOTOBaseGameCharacterDetails.DoProfessions);