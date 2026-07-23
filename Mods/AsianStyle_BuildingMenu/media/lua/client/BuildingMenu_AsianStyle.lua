---@class BuildingMenu
local BuildingMenu = require("BuildingMenu01_Main")
require("BuildingMenu04_CategoriesDefinitions")


local function addAsianStyleWallsToMenu()
    local fullyWooden = {
        BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge" },
            {
                sprite = "fixtures_asianwalls_03_36",
                northSprite = "fixtures_asianwalls_03_37",
                pillar = "fixtures_asianwalls_03_39"
            }
        ),
		BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
			{ 
				completionSound = "BuildWoodenStructureLarge",
				isThumpable = true,
				canBarricade = true,
				hoppable = true,
				modData = { wallType = "windowsframe" }
			},
            {
                sprite = "fixtures_asianwalls_03_32",
                northSprite = "fixtures_asianwalls_03_33",
                pillar = "fixtures_asianwalls_03_39"
            }
        ),
		BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildDoorFrame,
            BuildingMenu.BigWoodWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge",			
			 modData = { wallType = "doorframe" }},
            {
                sprite = "fixtures_asianwalls_03_35",
                northSprite = "fixtures_asianwalls_03_34",
                pillar = "fixtures_asianwalls_03_39"
            }
        ),
		BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWindowWall,
            BuildingMenu.BigWoodWindowWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge"},
            {
                sprite = "fixtures_asianwalls_03_8",
                northSprite = "fixtures_asianwalls_03_10",
                pillar = "fixtures_asianwalls_03_39"
            }
        ),
		BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWindowWall,
            BuildingMenu.BigWoodWindowWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge"},
            {
                sprite = "fixtures_asianwalls_03_9",
                northSprite = "fixtures_asianwalls_03_11",
                pillar = "fixtures_asianwalls_03_39"
            }
        ),
		BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWindowWall,
            BuildingMenu.BigWoodWindowWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge"},
            {
                sprite = "fixtures_asianwalls_03_12",
                northSprite = "fixtures_asianwalls_03_14",
                pillar = "fixtures_asianwalls_03_39"
            }
        ),
		BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWindowWall,
            BuildingMenu.BigWoodWindowWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge"},
            {
                sprite = "fixtures_asianwalls_03_13",
                northSprite = "fixtures_asianwalls_03_15",
                pillar = "fixtures_asianwalls_03_39"
            }
        ),
			BuildingMenu.createObject(
             "Tooltip_BuildingMenuObj_Old_Wood_Panel_Pillar",
            "Tooltip_Old_Wood_Pillar",
            BuildingMenu.onBuildWall,
            BuildingMenu.SmallWoodWallRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureLarge",
                canPassThrough = true,
                canBarricade = false,
                isCorner = true,
                modData = { wallType = "pillar" }
            },
            {
                sprite = "fixtures_asianwalls_1_11"
            }
        ),
		BuildingMenu.createObject(
            "Tooltip_RoofWall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.SmallWoodWallRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureSmall",
                isThumpable = true,
                canBarricade = false,
                modData = { wallType = "wall" }
            },
            { sprite = "asianroofwalls_01_80", northSprite = "asianroofwalls_01_88" }
        ),
        BuildingMenu.createObject(
            "Tooltip_RoofWall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureLarge",
                isThumpable = true,
                canBarricade = false,
                modData = { wallType = "wall" }
            },
            { sprite = "asianroofwalls_01_81", northSprite = "asianroofwalls_01_89" }
        ),
        BuildingMenu.createObject(
            "Tooltip_RoofWall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureLarge",
                isThumpable = true,
                canBarricade = false,
                modData = { wallType = "wall" }
            },
            { sprite = "asianroofwalls_01_82", northSprite = "asianroofwalls_01_90" }
        ),
        BuildingMenu.createObject(
            "Tooltip_RoofWall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.SmallWoodWallRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureSmall",
                isThumpable = true,
                canBarricade = false,
                modData = { wallType = "wall" }
            },
            { sprite = "asianroofwalls_01_83", northSprite = "asianroofwalls_01_91" }
        ),
        BuildingMenu.createObject(
            "Tooltip_RoofWall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureLarge",
                isThumpable = true,
                canBarricade = false,
                modData = { wallType = "wall" }
            },
            { sprite = "asianroofwalls_01_84", northSprite = "asianroofwalls_01_92" }
        ),
        BuildingMenu.createObject(
            "Tooltip_RoofWall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureLarge",
                isThumpable = true,
                canBarricade = false,
                modData = { wallType = "wall" }
            },
            { sprite = "asianroofwalls_01_85", northSprite = "asianroofwalls_01_93" }
        ),
        BuildingMenu.createObject(
            "Tooltip_RoofWall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.SmallWoodWallRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureSmall",
                isThumpable = true,
                canBarricade = false,
                modData = { wallType = "wall" }
            },
            { sprite = "asianroofwalls_01_86", northSprite = "asianroofwalls_01_94" }
        ),
        BuildingMenu.createObject(
            "Tooltip_RoofWall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureLarge",
                isThumpable = true,
                canBarricade = false,
                modData = { wallType = "wall" }
            },
            { sprite = "asianroofwalls_01_87", northSprite = "asianroofwalls_01_95" }
        ),
        BuildingMenu.createObject(
            "Tooltip_RoofWall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureLarge",
                isThumpable = true,
                canBarricade = false,
                modData = { wallType = "wall" }
            },
            { sprite = "asianroofwalls_01_99", northSprite = "asianroofwalls_01_103" }
        ),
		BuildingMenu.createObject(
            "Tooltip_RoofWall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureLarge",
                isThumpable = true,
                canBarricade = false,
                modData = { wallType = "wall" }
            },
            { sprite = "asianroofwalls_01_98", northSprite = "asianroofwalls_01_102" }
        ),
		BuildingMenu.createObject(
            "Tooltip_RoofWall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureLarge",
                isThumpable = true,
                canBarricade = false,
                modData = { wallType = "wall" }
            },
            { sprite = "asianroofwalls_01_97", northSprite = "asianroofwalls_01_101" }
        ),
		BuildingMenu.createObject(
            "Tooltip_BuildingMenuObj_Old_Wood_Panel_Roof_End_Big",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureLarge",
                isThumpable = true,
                canBarricade = false,
                modData = { wallType = "wall" }
            },
            { sprite = "asianroofwalls_01_96", northSprite = "asianroofwalls_01_100" }
        )
		
	}

    BuildingMenu.addObjectsToCategories(
        "AsianStyle",
        "IGUI_BuildingMenuCat_Walls",
        "fixtures_asianwalls_01_0",
        "IGUI_BuildingMenuSubCat_Walls_Wooden_Panel",
        "fixtures_asianwalls_03_8",
        fullyWooden
    )
	local halfWooden= {
	
	BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge"},
            {
                sprite = "fixtures_asianwalls_01_48",
                northSprite = "fixtures_asianwalls_01_49",
                pillar = "fixtures_asianwalls_03_39"
            }
        ),
	BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge"},
            {
                sprite = "fixtures_asianwalls_01_50",
                northSprite = "fixtures_asianwalls_01_55",
                pillar = "fixtures_asianwalls_03_39"
            }
        ),
	BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge"},
            {
                sprite = "fixtures_asianwalls_01_54",
                northSprite = "fixtures_asianwalls_01_51",
                pillar = "fixtures_asianwalls_03_39"
            }
        ),
	BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge"},
            {
                sprite = "fixtures_asianwalls_01_52",
                northSprite = "fixtures_asianwalls_01_53",
                pillar = "fixtures_asianwalls_03_39"
            }
        ),
	BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWindowWall,
            BuildingMenu.BigWoodWindowWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge"},
            {
                sprite = "fixtures_asianwalls_01_56",
                northSprite = "fixtures_asianwalls_01_58",
                pillar = "fixtures_asianwalls_03_39"
            }
        ),
	BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWindowWall,
            BuildingMenu.BigWoodWindowWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge"},
            {
                sprite = "fixtures_asianwalls_01_57",
                northSprite = "fixtures_asianwalls_01_59",
                pillar = "fixtures_asianwalls_03_39"
            }
        ),
	BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWindowWall,
            BuildingMenu.BigWoodWindowWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge"},
            {
                sprite = "fixtures_asianwalls_01_60",
                northSprite = "fixtures_asianwalls_01_62",
                pillar = "fixtures_asianwalls_03_39"
            }
        ),
	BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWindowWall,
            BuildingMenu.BigWoodWindowWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge"},
            {
                sprite = "fixtures_asianwalls_01_61",
                northSprite = "fixtures_asianwalls_01_63",
                pillar = "fixtures_asianwalls_03_39"
            }
        ),
	BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
			{ 
				completionSound = "BuildWoodenStructureLarge",
				isThumpable = true,
				canBarricade = true,
				hoppable = true,
				modData = { wallType = "windowsframe" }
			},
            {
                sprite = "fixtures_asianwalls_01_82",
                northSprite = "fixtures_asianwalls_01_83",
                pillar = "fixtures_asianwalls_03_39"
            }
        ),
		BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
			{ 
				completionSound = "BuildWoodenStructureLarge",
				isThumpable = true,
				canBarricade = true,
				hoppable = true,
				modData = { wallType = "windowsframe" }
			},
            {
                sprite = "fixtures_asianwalls_01_84",
                northSprite = "fixtures_asianwalls_01_85",
                pillar = "fixtures_asianwalls_03_39"
            }
        ),
		BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
			{ 
				completionSound = "BuildWoodenStructureLarge",
				isThumpable = true,
				canBarricade = true,
				hoppable = true,
				modData = { wallType = "windowsframe" }
			},
            {
                sprite = "fixtures_asianwalls_01_88",
                northSprite = "fixtures_asianwalls_01_86",
                pillar = "fixtures_asianwalls_03_39"
            }
        ),
		BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
			{ 
				completionSound = "BuildWoodenStructureLarge",
				isThumpable = true,
				canBarricade = true,
				hoppable = true,
				modData = { wallType = "windowsframe" }
			},
            {
                sprite = "fixtures_asianwalls_01_87",
                northSprite = "fixtures_asianwalls_01_89",
                pillar = "fixtures_asianwalls_03_39"
            }
        ),
		BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildDoorFrame,
            BuildingMenu.BigWoodWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge",			
			 modData = { wallType = "doorframe" }},
            {
                sprite = "fixtures_asianwalls_01_80",
                northSprite = "fixtures_asianwalls_01_81",
                pillar = "fixtures_asianwalls_03_39"
            }
        ),
	}
	    BuildingMenu.addObjectsToCategories(
        "AsianStyle",
        "IGUI_BuildingMenuCat_Walls",
        "fixtures_asianwalls_01_0",
        "IGUI_BuildingMenuSubCat_Walls_Half_Wooden",
        "fixtures_asianwalls_01_48",
        halfWooden
    )
	local interior = {
	BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge"},
            {
                sprite = "fixtures_asianwalls_01_8",
                northSprite = "fixtures_asianwalls_01_9",
				corner = "fixtures_asianwalls_01_10",
                pillar = "fixtures_asianwalls_01_11"
            }
        ),
	BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge"},
            {
                sprite = "fixtures_asianwalls_01_12",
                northSprite = "fixtures_asianwalls_01_13",
				corner = "fixtures_asianwalls_01_14",
                pillar = "fixtures_asianwalls_01_11"
            }
        ),
	BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge"},
            {
                sprite = "fixtures_asianwalls_01_16",
                northSprite = "fixtures_asianwalls_01_17",
                pillar = "fixtures_asianwalls_01_11"
            }
        ),
	BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge"},
            {
                sprite = "fixtures_asianwalls_01_18",
                northSprite = "fixtures_asianwalls_01_19",
                pillar = "fixtures_asianwalls_01_11"
            }
        ),

	BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
			{ 
				completionSound = "BuildWoodenStructureLarge",
				isThumpable = true,
				canBarricade = true,
				hoppable = true,
				modData = { wallType = "windowsframe"}
			},
            {
                sprite = "fixtures_asianwalls_01_90",
                northSprite = "fixtures_asianwalls_01_91",
                pillar = "fixtures_asianwalls_01_11"
            }
        ),
	BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
			{ 
				completionSound = "BuildWoodenStructureLarge",
				isThumpable = true,
				canBarricade = true,
				hoppable = true,
				modData = { wallType = "windowsframe"}
			},
            {
                sprite = "fixtures_asianwalls_01_92",
                northSprite = "fixtures_asianwalls_01_93",
                pillar = "fixtures_asianwalls_01_11"
            }
        ),
	BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildDoorFrame,
            BuildingMenu.BigWoodWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge",			
			 modData = { wallType = "doorframe"}},
            {
                sprite = "fixtures_asianwalls_01_7",
                northSprite = "fixtures_asianwalls_01_23",
                pillar = "fixtures_asianwalls_01_11"
            }
        ),
	BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWindowWall,
            BuildingMenu.BigWoodWindowWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge",
			isThumpable = true,
            canBarricade = true,
			},
            {
                sprite = "fixtures_asianwalls_01_0",
                northSprite = "fixtures_asianwalls_01_1",
				corner = "fixtures_asianwalls_01_2",
                pillar = "fixtures_asianwalls_1_11"
            }
        ),
	BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge" },
            {
                sprite = "fixtures_asianwalls_01_96",
                northSprite = "fixtures_asianwalls_01_98",
                pillar = "fixtures_asianwalls_01_11"
            }
        ),
		BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge" },
            {
                sprite = "fixtures_asianwalls_01_97",
                northSprite = "fixtures_asianwalls_01_99",
                pillar = "fixtures_asianwalls_01_11"
            }
        ),
		BuildingMenu.createObject(
            "Tooltip_RoofWall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.SmallWoodWallRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureSmall",
                isThumpable = true,
                canBarricade = false,
                modData = { wallType = "wall" }
            },
            { sprite = "asianroofwalls_01_0", northSprite = "asianroofwalls_01_16" }
        ),
        BuildingMenu.createObject(
            "Tooltip_RoofWall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureLarge",
                isThumpable = true,
                canBarricade = false,
                modData = { wallType = "wall" }
            },
            { sprite = "asianroofwalls_01_1", northSprite = "asianroofwalls_01_17" }
        ),
        BuildingMenu.createObject(
            "Tooltip_RoofWall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureLarge",
                isThumpable = true,
                canBarricade = false,
                modData = { wallType = "wall" }
            },
            { sprite = "asianroofwalls_01_2", northSprite = "asianroofwalls_01_18" }
        ),
        BuildingMenu.createObject(
            "Tooltip_RoofWall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.SmallWoodWallRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureSmall",
                isThumpable = true,
                canBarricade = false,
                modData = { wallType = "wall" }
            },
            { sprite = "asianroofwalls_01_3", northSprite = "asianroofwalls_01_19" }
        ),
        BuildingMenu.createObject(
            "Tooltip_RoofWall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureLarge",
                isThumpable = true,
                canBarricade = false,
                modData = { wallType = "wall" }
            },
            { sprite = "asianroofwalls_01_10", northSprite = "asianroofwalls_01_26" }
        ),
        BuildingMenu.createObject(
            "Tooltip_RoofWall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureLarge",
                isThumpable = true,
                canBarricade = false,
                modData = { wallType = "wall" }
            },
            { sprite = "asianroofwalls_01_11", northSprite = "asianroofwalls_01_27" }
        ),
        BuildingMenu.createObject(
            "Tooltip_RoofWall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.SmallWoodWallRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureSmall",
                isThumpable = true,
                canBarricade = false,
                modData = { wallType = "wall" }
            },
            { sprite = "asianroofwalls_01_12", northSprite = "asianroofwalls_01_28" }
        ),
        BuildingMenu.createObject(
            "Tooltip_RoofWall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureLarge",
                isThumpable = true,
                canBarricade = false,
                modData = { wallType = "wall" }
            },
            { sprite = "asianroofwalls_01_13", northSprite = "asianroofwalls_01_29" }
        ),
        BuildingMenu.createObject(
            "Tooltip_RoofWall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureLarge",
                isThumpable = true,
                canBarricade = false,
                modData = { wallType = "wall" }
            },
            { sprite = "asianroofwalls_01_39", northSprite = "asianroofwalls_01_35" }
        ),
		BuildingMenu.createObject(
            "Tooltip_RoofWall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureLarge",
                isThumpable = true,
                canBarricade = false,
                modData = { wallType = "wall" }
            },
            { sprite = "asianroofwalls_01_38", northSprite = "asianroofwalls_01_34" }
        ),
		BuildingMenu.createObject(
            "Tooltip_RoofWall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureLarge",
                isThumpable = true,
                canBarricade = false,
                modData = { wallType = "wall" }
            },
            { sprite = "asianroofwalls_01_7", northSprite = "asianroofwalls_01_31" }
        ),
		BuildingMenu.createObject(
            "Tooltip_BuildingMenuObj_Old_Wood_Panel_Roof_End_Big",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureLarge",
                isThumpable = true,
                canBarricade = false,
                modData = { wallType = "wall" }
            },
            { sprite = "asianroofwalls_01_6", northSprite = "asianroofwalls_01_30" }
        )
	}
	BuildingMenu.addObjectsToCategories(
        "AsianStyle",
        "IGUI_BuildingMenuCat_Walls",
        "fixtures_asianwalls_01_0",
        "IGUI_BuildingMenuSubCat_Interior_Walls",
        "fixtures_asianwalls_01_8",
        interior
    )
	local exterior = {
	BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge" },
            {
                sprite = "fixtures_asianwalls_02_0",
                northSprite = "fixtures_asianwalls_02_1",
                pillar = "fixtures_asianwalls_03_39"
            }
        ),
	BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge" },
            {
                sprite = "fixtures_asianwalls_02_2",
                northSprite = "fixtures_asianwalls_02_3",
                pillar = "fixtures_asianwalls_03_39"
            }
        ),
	BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge" },
            {
                sprite = "fixtures_asianwalls_02_4",
                northSprite = "fixtures_asianwalls_02_5",
                pillar = "fixtures_asianwalls_03_39"
            }
        ),
	BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge" },
            {
                sprite = "fixtures_asianwalls_02_6",
                northSprite = "fixtures_asianwalls_02_7",
                pillar = "fixtures_asianwalls_03_39"
            }
        ),
	BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWindowWall,
            BuildingMenu.BigWoodWindowWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge"},
            {
                sprite = "fixtures_asianwalls_02_8",
                northSprite = "fixtures_asianwalls_02_10",
				pillar = "fixtures_asianwalls_03_39"
            }
        ),
	BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWindowWall,
            BuildingMenu.BigWoodWindowWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge"},
            {
                sprite = "fixtures_asianwalls_02_9",
                northSprite = "fixtures_asianwalls_02_11",
				pillar = "fixtures_asianwalls_03_39"
            }
        ),
	BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWindowWall,
            BuildingMenu.BigWoodWindowWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge"},
            {
                sprite = "fixtures_asianwalls_02_12",
                northSprite = "fixtures_asianwalls_02_14",
				pillar = "fixtures_asianwalls_03_39"
            }
        ),
	BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWindowWall,
            BuildingMenu.BigWoodWindowWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge"},
            {
                sprite = "fixtures_asianwalls_02_13",
                northSprite = "fixtures_asianwalls_02_15",
				pillar = "fixtures_asianwalls_03_39"
            }
        ),
	BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
			{ 
				completionSound = "BuildWoodenStructureLarge",
				isThumpable = true,
				canBarricade = true,
				hoppable = true,
				modData = { wallType = "windowsframe"}
			},
            {
                sprite = "fixtures_asianwalls_02_32",
                northSprite = "fixtures_asianwalls_02_33",
                pillar = "fixtures_asianwalls_03_39"
            }
        ),
	BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
			{ 
				completionSound = "BuildWoodenStructureLarge",
				isThumpable = true,
				canBarricade = true,
				hoppable = true,
				modData = { wallType = "windowsframe"}
			},
            {
                sprite = "fixtures_asianwalls_02_34",
                northSprite = "fixtures_asianwalls_02_35",
                pillar = "fixtures_asianwalls_03_39"
            }
        ),
	BuildingMenu.createObject(
             "Tooltip_BuildingMenuObj_Old_Wood_Panel_Pillar",
            "Tooltip_Old_Wood_Pillar",
            BuildingMenu.onBuildWall,
            BuildingMenu.SmallWoodWallRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureLarge",
                canPassThrough = true,
                canBarricade = false,
                isCorner = true,
                modData = { wallType = "pillar" }
            },
            {
                sprite = "fixtures_asianwalls_03_39"
            }
        ),
	--[[BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildDoorFrame,
            BuildingMenu.BigWoodWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge",			
			 modData = { wallType = "doorframe"}},
            {
                sprite = "fixtures_asianwalls_01_7",
                northSprite = "fixtures_asianwalls_01_23",
                pillar = "fixtures_asianwalls_03_39"
            }
        ),]]
	BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWindowWall,
            BuildingMenu.BigWoodWindowWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge"},
            {
                sprite = "fixtures_asianwalls_03_40",
                northSprite = "fixtures_asianwalls_03_42",
				pillar = "fixtures_asianwalls_03_39"
            }
        ),
	BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWindowWall,
            BuildingMenu.BigWoodWindowWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge"},
            {
                sprite = "fixtures_asianwalls_03_41",
                northSprite = "fixtures_asianwalls_03_43",
				pillar = "fixtures_asianwalls_03_39"
            }
        ),
	BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWindowWall,
            BuildingMenu.BigWoodWindowWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge"},
            {
                sprite = "fixtures_asianwalls_03_44",
                northSprite = "fixtures_asianwalls_03_46",
				pillar = "fixtures_asianwalls_03_39"
            }
        ),
	BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWindowWall,
            BuildingMenu.BigWoodWindowWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge"},
            {
                sprite = "fixtures_asianwalls_03_45",
                northSprite = "fixtures_asianwalls_03_47",
				pillar = "fixtures_asianwalls_03_39"
            }
        ),
		
	BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWindowWall,
            BuildingMenu.BigWoodWindowWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge"},
            {
                sprite = "fixtures_asianwalls_03_68",
                northSprite = "fixtures_asianwalls_03_70",
				pillar = "fixtures_asianwalls_03_39"
            }
        ),
	BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWindowWall,
            BuildingMenu.BigWoodWindowWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge"},
            {
                sprite = "fixtures_asianwalls_03_69",
                northSprite = "fixtures_asianwalls_03_71",
				pillar = "fixtures_asianwalls_03_39"
            }
        ),
		
	BuildingMenu.createObject(
            "Tooltip_Wall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            { completionSound = "BuildWoodenStructureLarge" },
            {
                sprite = "fixtures_asianwalls_03_64",
                northSprite = "fixtures_asianwalls_03_65",
                corner = "fixtures_asianwalls_03_66",
				pillar = "fixtures_asianwalls_03_67"
            }
        ),
		BuildingMenu.createObject(
            "Tooltip_RoofWall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.SmallWoodWallRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureSmall",
                isThumpable = true,
                canBarricade = false,
                modData = { wallType = "wall" }
            },
            { sprite = "asianroofwalls_01_40", northSprite = "asianroofwalls_01_56" }
        ),
        BuildingMenu.createObject(
            "Tooltip_RoofWall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureLarge",
                isThumpable = true,
                canBarricade = false,
                modData = { wallType = "wall" }
            },
            { sprite = "asianroofwalls_01_41", northSprite = "asianroofwalls_01_57" }
        ),
        BuildingMenu.createObject(
            "Tooltip_RoofWall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureLarge",
                isThumpable = true,
                canBarricade = false,
                modData = { wallType = "wall" }
            },
            { sprite = "asianroofwalls_01_42", northSprite = "asianroofwalls_01_58" }
        ),
        BuildingMenu.createObject(
            "Tooltip_RoofWall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.SmallWoodWallRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureSmall",
                isThumpable = true,
                canBarricade = false,
                modData = { wallType = "wall" }
            },
            { sprite = "asianroofwalls_01_43", northSprite = "asianroofwalls_01_59" }
        ),
        BuildingMenu.createObject(
            "Tooltip_RoofWall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureLarge",
                isThumpable = true,
                canBarricade = false,
                modData = { wallType = "wall" }
            },
            { sprite = "asianroofwalls_01_50", northSprite = "asianroofwalls_01_66" }
        ),
        BuildingMenu.createObject(
            "Tooltip_RoofWall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureLarge",
                isThumpable = true,
                canBarricade = false,
                modData = { wallType = "wall" }
            },
            { sprite = "asianroofwalls_01_51", northSprite = "asianroofwalls_01_67" }
        ),
        BuildingMenu.createObject(
            "Tooltip_RoofWall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.SmallWoodWallRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureSmall",
                isThumpable = true,
                canBarricade = false,
                modData = { wallType = "wall" }
            },
            { sprite = "asianroofwalls_01_52", northSprite = "asianroofwalls_01_68" }
        ),
        BuildingMenu.createObject(
            "Tooltip_RoofWall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureLarge",
                isThumpable = true,
                canBarricade = false,
                modData = { wallType = "wall" }
            },
            { sprite = "asianroofwalls_01_53", northSprite = "asianroofwalls_01_69" }
        ),
        BuildingMenu.createObject(
            "Tooltip_RoofWall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureLarge",
                isThumpable = true,
                canBarricade = false,
                modData = { wallType = "wall" }
            },
            { sprite = "asianroofwalls_01_79", northSprite = "asianroofwalls_01_75" }
        ),
		BuildingMenu.createObject(
            "Tooltip_RoofWall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureLarge",
                isThumpable = true,
                canBarricade = false,
                modData = { wallType = "wall" }
            },
            { sprite = "asianroofwalls_01_78", northSprite = "asianroofwalls_01_74" }
        ),
		BuildingMenu.createObject(
            "Tooltip_RoofWall",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureLarge",
                isThumpable = true,
                canBarricade = false,
                modData = { wallType = "wall" }
            },
            { sprite = "asianroofwalls_01_47", northSprite = "asianroofwalls_01_71" }
        ),
		BuildingMenu.createObject(
            "Tooltip_BuildingMenuObj_Old_Wood_Panel_Roof_End_Big",
            "Tooltip_Wooden_Wall",
            BuildingMenu.onBuildWall,
            BuildingMenu.BigWoodWallRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureLarge",
                isThumpable = true,
                canBarricade = false,
                modData = { wallType = "wall" }
            },
            { sprite = "asianroofwalls_01_46", northSprite = "asianroofwalls_01_70" }
        )
	}
	BuildingMenu.addObjectsToCategories(
        "AsianStyle",
        "IGUI_BuildingMenuCat_Walls",
        "fixtures_asianwalls_01_0",
        "IGUI_BuildingMenuSubCat_Exterior_Walls",
        "fixtures_asianwalls_02_6",
        exterior
    )
	local doors = {

    BuildingMenu.createObject(
		"Tooltip_BuildingMenuObj_Brown_Sliding_Glass_Door",
		"Tooltip_Brown_Sliding_Glass_Door",
		BuildingMenu.onBuildDoor,
		BuildingMenu.WoodenDoubleGlassDoorRecipe,
		true,
		{
			dontNeedFrame = true,
			canBarricade = false,
			completionSound = "BuildWoodenStructureLarge",
			modData = { wallType = "doorframe" }
		},
		{
			sprite = "fixtures_asiandoors_01_4",
			northSprite = "fixtures_asiandoors_01_5",
			openSprite = "fixtures_asiandoors_01_6",
			openNorthSprite = "fixtures_asiandoors_01_7"
		}
	),
    BuildingMenu.createObject(
		"Tooltip_BuildingMenuObj_Brown_Sliding_Glass_Door",
		"Tooltip_Brown_Sliding_Glass_Door",
		BuildingMenu.onBuildDoor,
		BuildingMenu.WoodenDoubleGlassDoorRecipe,
		true,
		{
			dontNeedFrame = true,
			canBarricade = false,
			completionSound = "BuildWoodenStructureLarge",
			modData = { wallType = "doorframe" }
		},
		{
			sprite = "fixtures_asiandoors_01_20",
			northSprite = "fixtures_asiandoors_01_21",
			openSprite = "fixtures_asiandoors_01_22",
			openNorthSprite = "fixtures_asiandoors_01_23"
		}
	),
    BuildingMenu.createObject(
		"Tooltip_BuildingMenuObj_Brown_Sliding_Glass_Door",
		"Tooltip_Brown_Sliding_Glass_Door",
		BuildingMenu.onBuildDoor,
		BuildingMenu.WoodenDoubleGlassDoorRecipe,
		true,
		{
			dontNeedFrame = true,
			canBarricade = false,
			completionSound = "BuildWoodenStructureLarge",
			modData = { wallType = "doorframe" }
		},
		{
			sprite = "fixtures_asiandoors_01_28",
			northSprite = "fixtures_asiandoors_01_29",
			openSprite = "fixtures_asiandoors_01_30",
			openNorthSprite = "fixtures_asiandoors_01_31"
		}
	),
   BuildingMenu.createObject(
		"Tooltip_BuildingMenuObj_Brown_Sliding_Glass_Door",
		"Tooltip_Brown_Sliding_Glass_Door",
		BuildingMenu.onBuildDoor,
		BuildingMenu.WoodenDoubleGlassDoorRecipe,
		true,
		{
			dontNeedFrame = true,
			canBarricade = false,
			completionSound = "BuildWoodenStructureLarge",
			modData = { wallType = "doorframe" }
		},
		{
			sprite = "fixtures_asiandoors_01_32",
			northSprite = "fixtures_asiandoors_01_33",
			openSprite = "fixtures_asiandoors_01_34",
			openNorthSprite = "fixtures_asiandoors_01_35"
		}
	),
   BuildingMenu.createObject(
		"Tooltip_BuildingMenuObj_Brown_Sliding_Glass_Door",
		"Tooltip_Brown_Sliding_Glass_Door",
		BuildingMenu.onBuildDoor,
		BuildingMenu.WoodenDoubleGlassDoorRecipe,
		true,
		{
			dontNeedFrame = true,
			canBarricade = false,
			completionSound = "BuildWoodenStructureLarge",
			modData = { wallType = "doorframe" }
		},
		{
			sprite = "fixtures_asiandoors_01_40",
			northSprite = "fixtures_asiandoors_01_41",
			openSprite = "fixtures_asiandoors_01_42",
			openNorthSprite = "fixtures_asiandoors_01_43"
		}
	),
	 BuildingMenu.createObject(
		"Tooltip_BuildingMenuObj_Brown_Door",
		"Tooltip_Brown_Door",
		BuildingMenu.onBuildDoor,
		BuildingMenu.WoodenDoorRecipe,
		true,
		{
			completionSound = "BuildWoodenStructureLarge",
			canBarricade = true,
			modData = { wallType = "doorframe" }
		},
		{
			sprite = "fixtures_asiandoors_01_8",
			northSprite = "fixtures_asiandoors_01_9",
			openSprite = "fixtures_asiandoors_01_10",
			openNorthSprite = "fixtures_asiandoors_01_11"
		}
	),
	}
	BuildingMenu.addObjectsToCategories(
        "AsianStyle",
        "IGUI_BuildingMenuCat_Doors",
        "fixtures_asiandoors_01_8",
        "IGUI_BuildingMenuSubCat_Doors_Wooden_Doors",
        "fixtures_asianwalls_02_6",
        doors
    )
	local floors ={
	BuildingMenu.createObject(
		"Tooltip_Tatami",
		"Tooltip_Floor_Generic",
		BuildingMenu.onBuildFloor,
		BuildingMenu.FloorRugRecipe,
		true,
		{
			completionSound = "BuildWoodenStructureSmall"
		},
		{
			sprite = "interior_asianfloor_01_0",
			northSprite = "interior_asianfloor_01_20",
			eastSprite = "interior_asianfloor_01_1",
            southSprite = "interior_asianfloor_01_21"
		}
	),
	BuildingMenu.createObject(
		"Tooltip_Tatami",
		"Tooltip_Floor_Generic",
		BuildingMenu.onBuildFloor,
		BuildingMenu.FloorRugRecipe,
		true,
		{
			completionSound = "BuildWoodenStructureSmall"
		},
		{
			sprite = "interior_asianfloor_01_3",
			northSprite = "interior_asianfloor_01_5",
			southSprite = "interior_asianfloor_01_6",
			eastSprite = "interior_asianfloor_01_4",
		}
	),
	BuildingMenu.createObject(
		"Tooltip_Tatami",
		"Tooltip_Floor_Generic",
		BuildingMenu.onBuildFloor,
		BuildingMenu.FloorRugRecipe,
		true,
		{
			completionSound = "BuildWoodenStructureSmall"
		},
		{
			sprite = "interior_asianfloor_01_8",
			northSprite = "interior_asianfloor_01_11",
			southSprite = "interior_asianfloor_01_10",
			eastSprite = "interior_asianfloor_01_13",
            
		}
	),
	BuildingMenu.createObject(
		"Tooltip_Tatami",
		"Tooltip_Floor_Generic",
		BuildingMenu.onBuildFloor,
		BuildingMenu.FloorRugRecipe,
		true,
		{
			completionSound = "BuildWoodenStructureSmall"
		},
		{
			sprite = "interior_asianfloor_01_16",
			northSprite = "interior_asianfloor_01_18",
            southSprite = "interior_asianfloor_01_17",
			eastSprite = "interior_asianfloor_01_19",

		}
	),
	BuildingMenu.createObject(
		"Tooltip_Tatami",
		"Tooltip_Floor_Generic",
		BuildingMenu.onBuildFloor,
		BuildingMenu.FloorRugRecipe,
		true,
		{
			completionSound = "BuildWoodenStructureSmall"
		},
		{
			sprite = "interior_asianfloor_01_9",
			northSprite = "interior_asianfloor_01_12",
		}
	),
	BuildingMenu.createObject(
		"Tooltip_BuildingMenuObj_Narrow_Plank",
		"Tooltip_Floor_Generic",
		BuildingMenu.onBuildFloor,
		BuildingMenu.TwoSpriteFloorRecipe,
		true,
		{
			completionSound = "BuildWoodenStructureSmall"
		},
		{
			sprite = "interior_asianfloor_01_24",
			northSprite = "interior_asianfloor_01_25",
		}
	),
	
	BuildingMenu.createObject(
		"Tooltip_BuildingMenuObj_Wide_Plank",
		"Tooltip_Floor_Generic",
		BuildingMenu.onBuildFloor,
		BuildingMenu.TwoSpriteFloorRecipe,
		true,
		{
			completionSound = "BuildWoodenStructureSmall"
		},
		{
			sprite = "interior_asianfloor_01_26",
			northSprite = "interior_asianfloor_01_27",
		}
	),
	
	BuildingMenu.createObject(
		"Tooltip_Tatami",
		"Tooltip_Floor_Generic",
		BuildingMenu.onBuildFloor,
		BuildingMenu.FloorRugRecipe,
		true,
		{
			completionSound = "BuildWoodenStructureSmall"
		},
		{
			sprite = "interior_asianfloor_01_28",
			northSprite = "interior_asianfloor_01_29",
		}
	),
	
	
	}
		BuildingMenu.addObjectsToCategories(
        "AsianStyle",
        "IGUI_BuildingMenuCat_Floors",
        "interior_asianfloor_01_11",
        "IGUI_BuildingMenuSubCat_Floors_Carpets",
        "interior_asianfloor_01_11",
        floors
    )
	local fences = {
        BuildingMenu.createObject(
            "Tooltip_BuildingMenuObj_Wooden_Railing",
            "Tooltip_Plain_Wooden_Fence",
            BuildingMenu.onBuildWall,
            BuildingMenu.WoodenFenceRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureSmall",
                isThumpable = true,
                hoppable = true,
                blockAllTheSquare = false
            },
            { sprite = "asianfence_0_0", northSprite = "asianfence_0_1", corner = "asianfence_0_2", pillar = "asianfence_0_3" }
        ),
       BuildingMenu.createObject(
            "Tooltip_BuildingMenuObj_Wooden_Railing_Corner",
            "Tooltip_Plain_Wooden_Fence",
            BuildingMenu.onBuildWall,
            BuildingMenu.WoodenFenceRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureSmall",
                canBeAlwaysPlaced = true,
                canPassThrough = true,
                canBarricade = false,
                isCorner = true
            },
            { sprite = "asianfence_0_3" }
        ),
        BuildingMenu.createObject(
            "Tooltip_BuildingMenuObj_Wooden_Railing",
            "Tooltip_Plain_Wooden_Fence",
            BuildingMenu.onBuildWall,
            BuildingMenu.WoodenFenceRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureSmall",
                isThumpable = true,
                hoppable = true,
                blockAllTheSquare = false
            },
            { sprite = "asianfence_0_4", northSprite = "asianfence_0_5", corner = "asianfence_0_6", pillar = "asianfence_0_3" }
        ),
	}
		BuildingMenu.addObjectsToCategories(
        "AsianStyle",
        "IGUI_BuildingMenuCat_Fencing",
        "asianfence_0_6",
        "IGUI_BuildingMenuSubCat_Fencing_Fencing_Low",
        "asianfence_0_6",
        fences
    )
	local furniture = {
	BuildingMenu.createObject(
		"Tooltip_LowAsianTable",
		"Tooltip_craft_largeTableDesc",
		BuildingMenu.onBuildDoubleTileFurniture,
		BuildingMenu.LargeFurnitureRecipe,
		true,
		{
			completionSound = "BuildWoodenStructureLarge"
		},
		{
			sprite = "fixtures_asianfurniture_01_2",
			sprite2 = "fixtures_asianfurniture_01_1",
			northSprite = "fixtures_asianfurniture_01_3",
			northSprite2 = "fixtures_asianfurniture_01_4"
		}
	),
	 BuildingMenu.createObject(
		"Tooltip_LowAsianTable",
		"Tooltip_craft_smallTableDesc",
		BuildingMenu.onBuildSimpleFurniture,
		BuildingMenu.SmallFurnitureRecipe,
		true,
		{
			completionSound = "BuildWoodenStructureSmall"
		},
		{ sprite = "fixtures_asianfurniture_01_0" }
	),
	BuildingMenu.createObject(
		"Tooltip_Futon",
		"Tooltip_craft_bedDesc",
		BuildingMenu.onBuildFourTileFurniture,
		BuildingMenu.BigFutonRecipe,
		true,
		{
			completionSound = "BuildFenceGravelbag"
		},
		{
			sprite = "fixtures_asianfurniture_01_19",
			sprite2 = "fixtures_asianfurniture_01_17",
			sprite3 = "fixtures_asianfurniture_01_16",
			sprite4 = "fixtures_asianfurniture_01_18",
			northSprite = "fixtures_asianfurniture_01_20",
			northSprite2 = "fixtures_asianfurniture_01_21",
			northSprite3 = "fixtures_asianfurniture_01_23",
			northSprite4 = "fixtures_asianfurniture_01_22"
		}
	),
	BuildingMenu.createObject(
		"Tooltip_Futon",
		"Tooltip_craft_bedDesc",
		BuildingMenu.onBuildDoubleTileFurniture,
		BuildingMenu.FutonRecipe,
		true,
		{
			completionSound = "BuildFenceGravelbag"
		},
		{
			sprite = "fixtures_asianfurniture_01_9",
			sprite2 = "fixtures_asianfurniture_01_8",
			northSprite = "fixtures_asianfurniture_01_10",
			northSprite2 = "fixtures_asianfurniture_01_11",
		}
	),
	        BuildingMenu.createObject(
            "Tooltip_Kotatsu",
            "Tooltip_Oven",
            BuildingMenu.onBuildBarbecue,
            BuildingMenu.StoveRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureLarge",
            },
            {
                sprite = "fixtures_asianfurniture_01_5"
            }
        ),
	}
	BuildingMenu.addObjectsToCategories(
        "AsianStyle",
        "IGUI_BuildingMenuCat_Furniture",
        "fixtures_asianfurniture_01_5",
        "IGUI_BuildingMenuSubCat_Misc",
        "fixtures_asianfurniture_01_5",
        furniture
    )
	local podiums = {
	BuildingMenu.createObject(
            "Tooltip_Podium",
            "",
            BuildingMenu.onBuildFloorOverlay,
            BuildingMenu.WoodenFenceRecipe,
            true,
            {
                needToBeAgainstWall = false,
                blockAllTheSquare = false,
                canPassThrough = true,
                canBarricade = false,
                isThumpable = true,
                isCorner = true
            },
            {
                sprite = "location_trailer_01_17",
                northSprite = "location_trailer_01_18",
                eastSprite = "location_trailer_01_19",
                southSprite = "location_trailer_01_20"
            }
        ),
	BuildingMenu.createObject(
            "Tooltip_Podium",
            "",
            BuildingMenu.onBuildFloorOverlay,
            BuildingMenu.WoodenFenceRecipe,
            true,
            {
                needToBeAgainstWall = false,
                blockAllTheSquare = false,
                canPassThrough = true,
                canBarricade = false,
                isThumpable = true,
                isCorner = true
            },
            {
                sprite = "location_trailer_01_21",
                northSprite = "location_trailer_01_22",

            }
        ),
		}
			BuildingMenu.addObjectsToCategories(
        "AsianStyle",
        "IGUI_BuildingMenuCat_Decorations",
        "location_trailer_01_19",
        "IGUI_BuildingMenuSubCat_Misc",
        "location_trailer_01_19",
        podiums
    )
end



local function addCategoriesToBuildingMenu()
    addAsianStyleWallsToMenu()

end
Events.OnInitializeBuildingMenuObjects.Add(addCategoriesToBuildingMenu)
