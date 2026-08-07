BuildingRecipeGroups = {}

BuildingRecipeGroups.RECIPE_GROUPS = {
-- Carpentry
    WoodenWall = {
        "WoodenWallLvl1",
        "WoodenWallLvl2", 
        "WoodenWallLvl3"
    },

    WoodenDarkWall = {
        "WoodenDarkWallLvl1",
        "WoodenDarkWallLvl2", 
        "WoodenDarkWallLvl3"
    },
    
    WoodenWindowFrame = {
        "WoodenWindowFrameLvl1",
        "WoodenWindowFrameLvl2",
        "WoodenWindowFrameLvl3"
    },

    WoodenDarkWindowFrame = {
        "WoodenDarkWindowFrameLvl1",
        "WoodenDarkWindowFrameLvl2",
        "WoodenDarkWindowFrameLvl3"
    },
    
    WoodenDoor = {
        "WoodenDoorLvl1",
        "WoodenDoorLvl2",
        "WoodenDoorLvl3"
    },

    WoodenBarnDoor = {
        "Doors_WoodenBarnLight",
        "Doors_WoodenBarnDark"
    },
    
    WoodFloor = {
        "WoodFloorLvl1",
        "WoodFloorLvl2",
        "WoodFloorLvl3"
    },
    
    WoodFence = {
        "WoodFenceLvl1",
        "WoodFenceLvl2",
        "WoodFenceLvl3"
    },
    
    WoodDoorFrame = {
        "WoodDoorFrameLvl1",
        "WoodDoorFrameLvl2",
        "WoodDoorFrameLvl3"
    },

    WoodenDarkDoorFrame = {
        "WoodenDarkDoorFrameLvl1",
        "WoodenDarkDoorFrameLvl2",
        "WoodenDarkDoorFrameLvl3"
    },
    
    Wood_TableSmall = {
        "Wood_TableSmall_Lvl1",
        "Wood_TableSmall_Lvl2",
        "Wood_TableSmall_Lvl3"
    },
    
    Wood_TableDrawer = {
        "Wood_TableDrawerLvl1",
        "Wood_TableDrawerLvl2",
        "Wood_TableDrawerLvl3"
    },
    
    Wood_Table = {
        "Wood_TableLvl1",
        "Wood_TableLvl2",
        "Wood_TableLvl3"
    },

    Wood_Shelves = {
        "Wood_Shelves_Lvl1",
        "Wood_Shelves_Lvl2"
    },

    Wood_Crate = {
        "Wood_Crate_Lvl1",
        "Wood_Crate_Lvl2"
    },

    Wood_Chair = {
        "Wood_Chair_Lvl1",
        "Wood_Chair_Lvl2",
        "Wood_Chair_Lvl3"
    },

    Wood_BookcaseSmall = {
        "Wood_BookcaseSmall_Lvl1",
        "Wood_BookcaseSmall_Lvl2"
    },

    Wood_Bookcase = {
        "Wood_Bookcase_Lvl1",
        "Wood_Bookcase_Lvl2",
        "Wood_WhiteBookcase"
    },
    
    Wood_BarElementCorner = {
        "Wood_BarElementCorner_Lvl1",
        "Wood_BarElementCorner_Lvl2",
        "Wood_BarElementCorner_Lvl3"
    },

    Wood_BarElement = {
        "Wood_BarElement_Lvl1",
        "Wood_BarElement_Lvl2",
        "Wood_BarElement_Lvl3"
    },

    -- Welding
    MetalWindow = {
        "MetalWindowFrameLvl1",
        "MetalWindowFrameLvl2"
    },
    
    MetalWall = {
        "MetalWallLvl1",
        "MetalWallLvl2"
    },
    
    MetalFence = {
        "MetalFenceLvl1",
        "MetalFenceLvl2"
    },
    
    MetalDoorFrame = {
        "MetalDoorFrameLvl1",
        "MetalDoorFrameLvl2"
    },
    
    Metal_Shelves = {
        "Metal_Shelves_Lvl1",
        "Metal_Shelves_Lvl2"
    },

    Metal_LockerSmall = {
        "Metal_LockerSmall_Lvl1",
        "Metal_LockerSmall_Lvl2"
    },

    Metal_LockerBig = {
        "Metal_LockerBig_Lvl1",
        "Metal_LockerBig_Lvl2",
        "Metal_Welding_MilitaryLockerBig"
    },

    WeldingSchoolLocker = {
        "Welding_SchoolYellowLocker",
        "Welding_SchoolBlueLocker"
    },

    Metal_Crate = {
        "Metal_Crate_Lvl1",
        "Metal_Crate_Lvl2"
    },

    Metal_CounterCorner = {
        "Metal_CounterCorner_Lvl1",
        "Metal_CounterCorner_Lvl2"
    },

    Metal_Counter = {
        "Metal_Counter_Lvl1",
        "Metal_Counter_Lvl2"
    },
    
    -- Brick
    BrickWindowFrame = {
        "BrickWindowFrameLvl1",
        "BrickWindowFrameLvl2"
    },

    BrickWall = {
        "BrickWallLvl1",
        "BrickWallLvl2"
    },

    BrickDoorFrame = {
        "BrickDoorFrameLvl1",
        "BrickDoorFrameLvl2"
    },
    
    -- Other
    Composter = {
        "Composter",
        "ComposterShoddy"
    },

    ConstructionDirtBlock = {
        "Fences_ConstructionGravel",
        "Fences_ConstructionSand",
        "Fences_ConstructionDirt",
    },

    WoodenCoffin = {
        "Coffin",
        "Wood_StandCoffin"
    },

    -- Disabled/preserved group: the referenced scripts are not loaded by the game yet.
    -- They are kept as entity_outdoor_smalllogpile*.txt(needfix), so Project Zomboid ignores them.
    -- SmallLogPile1 = {
    --     "Outdoor_SmallLogPile1",
    --     "Outdoor_SmallLogPile2"
    -- },

    --Floor
    SpringGrassFloor = {
        "Floor_SpringGrass",
        "Floor_SpringGrassCorner",
        "Floor_SpringGrassEdge"
    },

    SummerGrassFloor = {
        "Floor_SummerGrass",
        "Floor_SummerGrassCorner",
        "Floor_SummerGrassEdge"
    },

    FallGrassFloor = {
        "Floor_FallGrass",
        "Floor_FallGrassCorner",
        "Floor_FallGrassEdge"
    },

    SandFloor = {
        "SandFloor",
        "Floor_SandCorner",
        "Floor_SandEdge"
    },

    GravelFloor = {
        "GravelFloor",
        "Floor_GravelCorner",
        "Floor_GravelEdge"
    },

    DirtFloor = {
        "DirtFloor",
        "Floor_DirtCorner",
        "Floor_DirtEdge"
    },

    HayFloor = {
        "Floor_Hay",
        "Floor_HayEdge"
    },

    ConcreteFloor = {
        "Floor_Concrete",
        "Floor_ConcreteCorner"
    },

    RailRoadFloor = {
        "Floor_RailroadLight",
        "Floor_RailroadDark"
    },

    PerforatedFloor = {
        "Welding_IndustryPerforatedFloor",
        "Welding_IndustryMeshFloor"
    },

    -- Stairs
    ModernWoodStairs = {
        "Wood_ModernDarkStairs",
        "Wood_ModernLightStaris",
        "Wood_ModernOrangeStairs",
        "Wood_ModernRedStairs",
        "Wood_ModernHostipalStair",
        "Wood_ModernHotelStaris"
    },

    ConciseStairs = {
        "Welding_ConciseStairs",
        "Wood_ConciseStairs"
    },

    --Wall
    WoodenPanelwall = {
        "Wood_YellowPanelWall",
        "Wood_BrownPanelWall",
        "Wood_BluePanelWall",
        "Wood_GreenPanelWall",
        "Wood_RedPanelWall",
        "Wood_WhitePanelWall"
    },

    RailroadWall = {
        "Industry_RailroadBrownWall",
        "Industry_RailroadRedWall"
    },

    PotteryTileWall = {
        "Pottery_WhiteTileWall",
        "Pottery_GreyTileWall",
        "Pottery_BrownTileWall",
        "Pottery_DarkTileWall",
        "Pottery_YellowTileWall"
    },

    GarageWall = {
        "Wood_LightGarageWall",
        "Wood_DarkGarageWall",
        "Wood_LineGarageWall"
    },

    FullCommercialGlassWall = {
        "Commercial_FullGlassBlackWall",
        "Commercial_FullGlassRedWall"
    },

    HalfCommercialGlassWall = {
        "Commercial_HalfGlassBlackWall",
        "Commercial_HalfGlassRedWall"
    },

    GridCommercialGlassWall = {
        "Commercial_GridGlassBlackWall",
        "Commercial_GridGlassRedWall"
    },

    -- windows
    RailroadWindowFrame = {
        "Industry_RailroadBrownWindowFrame",
        "Industry_RailroadRedWindowFrame"
    },

    PotteryTileWindowFrame = {
        "Pottery_WhiteTileWindowFrame",
        "Pottery_GreyTileWindowFrame",
        "Pottery_BrownTileWindowFrame",
        "Pottery_DarkTileWindowFrame",
        "Pottery_YellowTileWindowFrame"
    },

    WoodenPanelWindowFrame = {
        "Wood_YellowPanelWindowFrame",
        "Wood_BrownPanelWindowFrame",
        "Wood_BluePanelWindowFrame",
        "Wood_GreenPanelWindowFrame",
        "Wood_RedPanelWindowFrame",
        "Wood_WhitePanelWindowFrame"
    },

    GarageWindowFrame = {
        "Wood_LightGarageWindowFrame",
        "Wood_DarkGarageWindowFrame",
        "Wood_LineGarageWindowFrame"
    },

    -- Doors
    RailroadDoorFrame = {
        "Industry_RailroadBrownDoorFrame",
        "Industry_RailroadRedDoorFrame"
    },

    WoodenPanelDoorFrame = {
        "Wood_YellowPanelDoorFrame",
        "Wood_BrownPanelDoorFrame",
        "Wood_BluePanelDoorFrame",
        "Wood_GreenPanelDoorFrame",
        "Wood_RedPanelDoorFrame",
        "Wood_WhitePanelDoorFrame"
    },

    PotteryTileDoorFrame = {
        "Pottery_WhiteTileDoorFrame",
        "Pottery_GreyTileDoorFrame",
        "Pottery_BrownTileDoorFrame",
        "Pottery_DarkTileDoorFrame",
        "Pottery_YellowTileDoorFrame"
    },

    GarageDoorFrame = {
        "Wood_LightGarageDoorFrame",
        "Wood_DarkGarageDoorFrame",
        "Wood_LineGarageDoorFrame"
    },

    CommercialDoorFrame = {
        "Commercial_BlackDoorFrame",
        "Commercial_RedDoorFrame"
    },

    CommercialGlassDoorFrame = {
        "Commercial_GlassBlackDoorFrame",
        "Commercial_GlassRedDoorFrame"
    },

    WoodenInteriorDoor = {
        "Wood_BrownInteriorDoor",
        "Wood_RedInteriorDoor",
        "Wood_BlueInteriorDoor",
        "Wood_WhiteInteriorDoor"
    },

    MetalSimpleDoor = {
        "MetalDoorLvl1",
        "MetalDoorLvl2",
        "Welding_WhiteDoor",
        "Welding_YellowDoor"
    },

    WoodenDoubleDoor = {
        "DoubleDoor",
        "Wood_DoubleDoorDark"
    },

    OfficeMetalDoor = {
        "Welding_OfficeYellowDoor",
        "Welding_OfficeBlackDoor"
    },

    WoodenExteriorDoor = {
        "Wood_BrownExteriorDoor",
        "Wood_WhiteExteriorDoor"
    },

    -- Furnitures
    SingleBed = {
        "Wood_Bed",
        "Wood_SimpleSingleBed",
        "Wood_BlueSheetSingleBed",
        "Wood_ModernSingleBed",
        "Welding_GreenFrameSingleBed",
    },

    FancyWoodenBookCase = {
        "Wood_FancyBookCase",
        "Wood_FancyCornerBookCase"
    },

    ShopClothingRack = {
        "Welding_ShopClothingSingleRack",
        "Welding_ShopClothingDoubleRack",
        "Welding_ShopClothingStandRack"
    },

    -- Fences
    LogFences = {
        "Fences_Log",
        "Fences_LogCorner"
    },

    MetalRailingFence = {
        "Welding_BlackRailingFence",
        "Welding_WhiteRailingFence",
        "Welding_MixRailingFence",
        "Welding_RailroadRailingFence"
    },

    WoodenRailingFence = {
        "Wood_RawRailingFence",
        "Wood_WhiteRailingFence"
    },

    ConcreteRailingFences = {
        "Fences_RawConcreteRailing",
        "Fences_WhiteConcreteRailing",
        "Fences_BlackConcreteRailing",
        "Fences_GlassConcreteRailing"
    },

    FancyRailingWoodenFence = {
        "Wood_FancyWhiteRailingFence",
        "Wood_FancyBrownRailingFence"
    },

}

BuildingRecipeGroups.RECIPE_TO_GROUP = {}

for groupName, recipes in pairs(BuildingRecipeGroups.RECIPE_GROUPS) do
    for _, recipeName in ipairs(recipes) do
        BuildingRecipeGroups.RECIPE_TO_GROUP[recipeName] = groupName
    end
end

function BuildingRecipeGroups.getRecipeGroup(recipeName)
    return BuildingRecipeGroups.RECIPE_TO_GROUP[recipeName]
end

function BuildingRecipeGroups.getGroupRecipes(groupName)
    return BuildingRecipeGroups.RECIPE_GROUPS[groupName] or {}
end

function BuildingRecipeGroups.hasMultipleLevels(recipeName)
    local groupName = BuildingRecipeGroups.getRecipeGroup(recipeName)
    if not groupName then return false end
    
    local groupRecipes = BuildingRecipeGroups.getGroupRecipes(groupName)
    return #groupRecipes > 1
end

return BuildingRecipeGroups