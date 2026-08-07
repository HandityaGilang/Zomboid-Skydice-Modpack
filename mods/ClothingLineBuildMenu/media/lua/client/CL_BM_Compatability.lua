if not getActivatedMods():contains("BuildingMenu") then return; end

local BuildingMenu = require("BuildingMenu01_Main")
require("BuildingMenu04_CategoriesDefinitions")
local CL = require("CL_Server") or {};
CL.ClothesLinesInSquare = CL.ClothesLinesInSquare or {}
CL.textureNames = {
    ["appliances_laundry_01_26"] = true,
    ["appliances_laundry_01_27"] = true,
    ["appliances_laundry_01_28"] = true,
    ["appliances_laundry_01_29"] = true,
    ["appliances_laundry_01_30"] = true,
    ["appliances_laundry_01_31"] = true,
    ["clothesHorse_0"] = true,
    ["clothesHorse_2"] = true
}

local function addClothesHorseToMenu()
    local clothesHorseRecipe = {
        neededTools = {
            "Screwdriver",
            "Saw",
        },
        neededMaterials = {
            {
                Material = "Base.Plank",
                Amount = 4
            },
            {
                Material = "Base.Screws",
                Amount = 6
            }
        },
        skills = {
            {
                Skill = "Woodwork",
                Level = 3,
                Xp = 10
            }
        }
    };
    local clothesHorseObject = {
        BuildingMenu.createObject(
            "Tooltip_BuildingMenuObj_ClothesHorse",
            "Tooltip_ClothesHorse",
            BuildingMenu.onBuildWoodenContainer,
            clothesHorseRecipe,
            true,
            {
                completionSound = "BuildWoodenStructureMedium",
                blockAllTheSquare = false,
                canPassThrough = false,
                dismantable = true,
                isCorner = true,
                isHigh = false,
            },
            {
                sprite = "clothesHorse_0",
                northSprite = "clothesHorse_0",
                eastSprite = "clothesHorse_2",
            }
        ),
    }
    BuildingMenu.addObjectsToCategories(
        "IGUI_BuildingMenuTab_General",
        "IGUI_BuildingMenuCat_Appliances",
        "",
        "IGUI_BuildingMenuSubCat_Appliances_Laundry",
        "",
        clothesHorseObject
    );
end
local function addClothesLinesToMenu()
    local clothesLineEndRecipe = {
        neededTools = {
            "BlowTorch",
            "WeldingMask",
            "Screwdriver",
            "Saw",
        },
        neededMaterials = {
            {
                Material = "Base.MetalBar",
                Amount = 4
            },
            {
                Material = "Base.Screws",
                Amount = 10
            }
        },
        useConsumable = {
            {
                Consumable = "Base.Wire",
                Amount = 5
            },
            {
                Consumable = "Base.BlowTorch",
                Amount = 5
            },
            {
                Consumable = "Base.WeldingRods",
                Amount = BuildingMenu.weldingRodUses(5)
            }
        },
        skills = {
            {
                Skill = "MetalWelding",
                Level = 3,
                Xp = 10
            }
        }
    };

    local clothesLineMiddleRecipe = {
        neededTools = {
            "BlowTorch",
            "WeldingMask",
        },
        useConsumable = {
            {
                Consumable = "Base.Wire",
                Amount = 5
            },
            {
                Consumable = "Base.BlowTorch",
                Amount = 5
            },
            {
                Consumable = "Base.WeldingRods",
                Amount = BuildingMenu.weldingRodUses(5)
            }
        },
        skills = {
            {
                Skill = "MetalWelding",
                Level = 3,
                Xp = 10
            }
        }
    };

    local clothesLinesObjects = {
        BuildingMenu.createObject(
            "Tooltip_BuildingMenuObj_ClothesLines",
            "Tooltip_ClothesLines",
            BuildingMenu.onBuildWoodenContainer,
            clothesLineEndRecipe,
            true,
            {
                completionSound = "BuildMetalStructureMedium",
                blockAllTheSquare = false,
                canPassThrough = true,
                dismantable = true,
                isCorner = true,
                isHigh = true,
            },
            {
                sprite = "appliances_laundry_01_26",
                northSprite = "appliances_laundry_01_29",
                eastSprite = "appliances_laundry_01_27",
                southSprite = "appliances_laundry_01_28"
            }
        ),
        BuildingMenu.createObject(
            "Tooltip_BuildingMenuObj_ClothesLines",
            "Tooltip_ClothesLines",
            BuildingMenu.onBuildWoodenContainer,
            clothesLineMiddleRecipe,
            true,
            {
                completionSound = "BuildMetalStructureMedium",
                blockAllTheSquare = false,
                canPassThrough = true,
                dismantable = true,
                isCorner = true,
                isHigh = true,
            },
            {
                sprite = "appliances_laundry_01_31",
                northSprite = "appliances_laundry_01_30",
            }
        ),
    };
    BuildingMenu.addObjectsToCategories(
        "IGUI_BuildingMenuTab_General",
        "IGUI_BuildingMenuCat_Appliances",
        "",
        "IGUI_BuildingMenuSubCat_Appliances_Laundry",
        "",
        clothesLinesObjects
    );
end
Events.OnGameStart.Add(addClothesLinesToMenu);
Events.OnGameStart.Add(addClothesHorseToMenu);


--- @param buildingObj ISBuildingObject
local function onBuildActionPerformed(buildingObj)
    if (buildingObj.sprite and CL.textureNames[buildingObj.sprite]) or (buildingObj.northSprite and CL.textureNames[buildingObj.northSprite]) or (buildingObj.eastSprite and CL.textureNames[buildingObj.eastSprite]) or (buildingObj.southSprite and CL.textureNames[buildingObj.southSprite]) then
        local obj = buildingObj.javaObject;
       if obj then CL.ClothesLinesInSquare[obj] = true; end
    end
end
Events.OnBuildActionPerformed.Add(onBuildActionPerformed)