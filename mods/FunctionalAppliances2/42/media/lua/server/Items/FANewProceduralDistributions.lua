FA.preDistributionMerge = function()
    	ProceduralDistributions.list.BulletinBoards = {
        	rolls = 5,
        	items = {
            		"SheetPaper2", 10,
            		"SheetPaper2", 5,
            		"LouisvilleMap1", 1,
            		"LouisvilleMap2", 1,
            		"LouisvilleMap3", 1,
            		"LouisvilleMap4", 1,
            		"LouisvilleMap5", 1,
            		"LouisvilleMap6", 1,
           		"LouisvilleMap7", 1,
            		"LouisvilleMap8", 1,
            		"LouisvilleMap9", 1,
            		"MuldraughMap", 1,
            		"WestpointMap", 1,
            		"MarchRidgeMap", 1,
            		"RosewoodMap", 1,
            		"RiversideMap", 1,
			"Magazine", 1,
			"Newspaper", 1,
			"Newspaper_Recent", 2,
			"Newspaper_Herald_New", 2,
			"HottieZ", 0.5,
			"Flier", 5,
			"Flier", 2,
			"Note", 5,
			"Note", 2,
			"Photo", 5,
			"Photo", 2,
			"Photo_Secret", 0.5,
			"Postcard", 5,
			"Doodle", 1,
			"DoodleKids", 5,
        	}
    	}

    	ProceduralDistributions.list.PoolCues = {
        	rolls = 3,
        	items = {
            		"Poolcue", 40,
            		"Poolcue", 20,
            		"Poolcue", 10,
            		"Poolcue", 5,
            		"Poolcue", 3,
        	}
    	}

    	ProceduralDistributions.list.Napkins = {
        	rolls = 3,
        	items = {
            		"FunctionalAppliances.FAPaperNapkins", 50,
            		"FunctionalAppliances.FAPaperNapkins", 25,
            		"FunctionalAppliances.FAPaperNapkins", 12.5,
            		"FunctionalAppliances.FAPaperNapkins", 6.25,
        	}
    	}

	ProceduralDistributions.list.HotdogMachines = {
        	rolls = 3,
       	 	items = {
            		"Sausage", 40,
            		"Sausage", 20,
			"Hotdog_single", 40,
			"Hotdog_single", 20,
            		"BunsHotdog_single", 40,
            		"BunsHotdog_single", 20,
            		"Hotdog", 10,
       	 	}
    	}

    	ProceduralDistributions.list.PopcornMachines = {
        	rolls = 3,
        	items = {
            		"FunctionalAppliances.FATheaterPopcorn", 40,
            		"FunctionalAppliances.FAButteredPopcorn", 20,
            		"FunctionalAppliances.FAButteredPopcorn", 10,
        	}
    	}

    	ProceduralDistributions.list.SlurpNBurps = {
        	rolls = 3,
        	items = {
            		"Base.FountainCup", 40,
            		"Base.FountainCup", 20,
            		"Base.FountainCup", 10,
        	}
    	}

    	ProceduralDistributions.list.Pegboards = {
		rolls = 4,
		items = {
			-- Tools
			"BallPeenHammer", 8,
			"BlowTorch", 10,
			"BoltCutters", 4,
			"Calipers", 8,
			"CarpentryChisel", 6,
			"CeramicCrucible", 2,
			"ClubHammer", 2,
			"File", 8,
			"Hammer", 6,
			"HandDrill", 4,
			"MetalworkingChisel", 4,
			"MetalworkingPliers", 0.1,
			"MetalworkingPunch", 4,
			"Pliers", 8,
			"Ratchet", 4,
			"Saw", 8,
			"Screwdriver", 8,
			"SheetMetalSnips", 4,
			"Sledgehammer", 0.1,
			"Sledgehammer2", 0.1,
			"SmallFileSet", 4,
			"SmallPunchSet", 4,
			"SmallSaw", 4,
			"ViseGrips", 4,
			"WoodenMallet", 1,
			"Wrench", 4,
			-- Materials
			"BatteryBox", 1,
			"BarbedWire", 8,
			"CircularSawblade", 4,
			"ElectricWire", 4,
			"Epoxy", 4,
			"FiberglassTape", 4,
			"HeavyChain", 10,
			"HeavyChain_Hook", 2,
			"LargeHook", 4,
			"LightBulbBox", 1,
			"NutsBolts", 10,
			"Oxygen_Tank", 2,
			"Propane_Refill", 2,
			"ScrewsBox", 4,
			"ScrewsCarton", 0.1,
			"WeldingRods", 8,
			"Wire", 4,
			-- Misc.
			"HandTorch", 8,
			"FlashLight_AngleHead_Army", 4,
			"WalkieTalkie5", 2,
			"Whetstone", 10,
			-- Bags/Containers
			"Bag_ProtectiveCaseMilitary_Tools", 1,
			"Toolbox_Mechanic", 2,
			"ToolRoll_Leather", 4,
		},
		junk = {
			rolls = 1,
			items = {
				"Extinguisher", 6,
				"Glasses_SafetyGoggles", 8,
				"Hat_EarMuff_Protectors", 4,
				"MarkerBlack", 10,
				"MeasuringTape", 10,
			}
		}
    	}
end

Events.OnPreDistributionMerge.Add(FA.preDistributionMerge)