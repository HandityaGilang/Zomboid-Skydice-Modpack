FA.preDistributionMerge = function()
    	ProceduralDistributions.list.BulletinBoards = {
        	rolls = 5,
        	items = {
            		"SheetPaper2", 40,
            		"SheetPaper2", 20,
            		"SheetPaper2", 10,
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
			"Magazine", 2,
			"Newspaper", 2,
			"HottieZ", 0.1,
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
            		"FunctionalAppliances.FAPaperNapkins", 40,
            		"FunctionalAppliances.FAPaperNapkins", 20,
            		"FunctionalAppliances.FAPaperNapkins", 10,
        	}
    	}

	if getActivatedMods():contains("sapphcooking") then
    		ProceduralDistributions.list.HotdogMachines = {
        		rolls = 3,
       		 	items = {
        	    		"Sausage", 40,
        	    		"SapphCooking.HotdogBun", 20,
        	    		"FunctionalAppliances.FAHotdog", 10,
       		 	}
    		}
	else
    		ProceduralDistributions.list.HotdogMachines = {
        		rolls = 3,
       		 	items = {
        	    		"Sausage", 40,
        	    		"Sausage", 20,
        	    		"FunctionalAppliances.FAHotdog", 10,
       		 	}
    		}
	end

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
            		"FunctionalAppliances.FAFountainCup", 40,
            		"FunctionalAppliances.FAFountainCup", 20,
            		"FunctionalAppliances.FAFountainCup", 10,
        	}
    	}

    	ProceduralDistributions.list.Pegboards = {
        	rolls = 4,
        	items = {
            		"BallPeenHammer", 6,
            		"Battery", 2,
            		"BlowTorch", 4,
			"ClubHammer", 4,
            		"Crowbar", 4,
            		"DuctTape", 8,
            		"ElectronicsScrap", 10,
            		"Extinguisher", 6,
            		"Hammer", 8,
            		"HandTorch", 8,
            		"LeadPipe", 4,
            		"LightBulb", 2,
            		"MetalPipe", 6,
            		"PipeWrench", 6,
            		"Radio.ElectricWire", 10,
            		"Rope", 8,
            		"ScrapMetal", 10,
            		"Screwdriver", 10,
            		"Screws", 10,
            		"Sledgehammer", 0.01,
            		"Sledgehammer2", 0.01,
            		"Tarp", 10,
            		"Toolbox", 2,
            		"Torch", 4,
            		"WeldingRods", 8,
            		"Wire", 10,
            		"Wrench", 8,
        		},
        	junk = {
            		rolls = 1,
            		items = {
                
            		}
        	}
    	}
end

Events.OnPreDistributionMerge.Add(FA.preDistributionMerge)