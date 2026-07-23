---@class BuildingMenu
local BuildingMenu = require("BuildingMenu01_Main");

local function initBuildingMenuRecipes()
    local bigWallWoodCount = SandboxVars.BuildingMenuRecipes.bigWallWoodCount or 6;
    local bigWallNailsCount = SandboxVars.BuildingMenuRecipes.bigWallNailsCount or 6;
	local bigObjectsCarpentrySkill = SandboxVars.BuildingMenuRecipes.bigObjectsCarpentrySkill or 5;
    local smallObjectsCarpentrySkill = SandboxVars.BuildingMenuRecipes.smallObjectsCarpentrySkill or 4;
	local carpentryXpPerLevel = SandboxVars.BuildingMenuRecipes.carpentryXpPerLevel or 2.5;
	local glassPaneCount = SandboxVars.BuildingMenuRecipes.glassPaneCount or 2;
	BuildingMenu.BigWoodWindowWallRecipe = {
        neededTools = {
            "Hammer",
        },
        neededMaterials = {
            {
                Material = "Base.Plank",
                Amount = bigWallWoodCount
            },
            {
                BuildingMenu.generateGroupAlternatives(BuildingMenu.GroupsAlternatives.Nails, bigWallNailsCount,
                    "Material")
            },
            {
                Material = BuildingMenu.ItemsAlternatives.GlassPaneSmall,
                Amount = glassPaneCount
            }
        },
        skills = {
            {
                Skill = "Woodwork",
                Level = bigObjectsCarpentrySkill,
                Xp = BuildingMenu.round(bigObjectsCarpentrySkill * carpentryXpPerLevel)
            }
        }
    }
	BuildingMenu.FutonRecipe = {
        neededTools = {
            "Needle",
        },
        neededMaterials = {
            {
                Material = "Base.RippedSheets",
                Amount = 12
            },
            {
                Material = "Base.Thread",
                Amount = 5
            },
			{
                Material = "Base.Pillow",
                Amount = 3
            }

        },
        skills = {
            {
                Skill = "Tailoring",
                Level = 2,
                Xp = 10
            }
        }
    }
	BuildingMenu.BigFutonRecipe = {
        neededTools = {
            "Needle",
        },
        neededMaterials = {
            {
                Material = "Base.RippedSheets",
                Amount = 20
            },
            {
                Material = "Base.Thread",
                Amount = 10
            },
			{
                Material = "Base.Pillow",
                Amount = 6
            }

        },
        skills = {
            {
                Skill = "Tailoring",
                Level = 2,
                Xp = 10
            }
        }
    }
	end
Events.OnInitializeBuildingMenuRecipes.Add(function()
    initBuildingMenuRecipes()
end)