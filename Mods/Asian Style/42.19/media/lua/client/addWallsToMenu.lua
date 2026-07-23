require ("Neat_Building\BuildingRecipeGroups")
--if not getActivatedMods():contains("Neat_Building") then return end

--WALLS
BuildingRecipeGroups.RECIPE_GROUPS["AsianStyle_PlainWall"] = {
	"Asian_PlainWall",
	"Asian_PlainWall_Left",
	"Asian_PlainWall_Right",
	"Asian_PlainWall_Both",
	"Asian_PlainWall_Doorframe"
}
BuildingRecipeGroups.RECIPE_GROUPS["AsianStyle_PlainOutdoorWall"] = {
	"Asian_PlainOutdoorWall_Both",
	"Asian_PlainOutdoorWall_Left",
	"Asian_PlainOutdoorWall_Right",
	"Asian_PlainOutdoorWall",
	"Asian_PlainOutdoorWall_Windowframe",
	"Asian_PlainOutdoorWall_Windowframe_Both",
}
BuildingRecipeGroups.RECIPE_GROUPS["AsianStyle_PlainOutdoorWall_Horisontal"] = {
	"Asian_PlainOutdoorWall_Both_Horisontal",
	"Asian_PlainOutdoorWall_Left_Horisontal",
	"Asian_PlainOutdoorWall_Right_Horisontal",
	"Asian_PlainOutdoorWall_Horisontal"
}
BuildingRecipeGroups.RECIPE_GROUPS["AsianStyle_HalfWoodenWall"] = {
	"Asian_HalfWoodenWall",
	"Asian_HalfWoodenWall_Both",
	"Asian_HalfWoodenWall_Left",
	"Asian_HalfWoodenWall_Right",
	"Asian_HalfWoodenWall_Doorframe"
}

--Double Windows
BuildingRecipeGroups.RECIPE_GROUPS["AsianStyle_PlainWall_Dbl_Window"] = {
	"Asian_PlainWall_Windowframe",
	"Asian_PlainWall_Windowframe_Both",
	"Asian_PlainWall_Dbl_WindowLeft",
	"Asian_PlainWall_Dbl_WindowRight",
	"Asian_PlainWall_Dbl_WindowLeft_Bordered",
	"Asian_PlainWall_Dbl_WindowRight_Bordered"
}
BuildingRecipeGroups.RECIPE_GROUPS["AsianStyle_PlainOutdoorWall_Dbl_Window"] = {

	"Asian_PlainOutdoorWall_Dbl_WindowLeft",
	"Asian_PlainOutdoorWall_Dbl_WindowRight",
	"Asian_PlainOutdoorWall_Dbl_WindowLeft_Deco",
	"Asian_PlainOutdoorWall_Dbl_WindowRight_Deco",
	"Asian_PlainOutdoorWall_Dbl_WindowLeft_Bordered",
	"Asian_PlainOutdoorWall_Dbl_WindowRight_Bordered",
	"Asian_PlainOutdoorWall_Dbl_WindowLeft_Bordered_Deco",
	"Asian_PlainOutdoorWall_Dbl_WindowRight_Bordered_Deco"
}
BuildingRecipeGroups.RECIPE_GROUPS["AsianStyle_HalfWoodenWall_Dbl_Window"] = {
	"Asian_HalfWoodenWall_Dbl_WindowLeft",
	"Asian_HalfWoodenWall_Dbl_WindowRight",
	"Asian_HalfWoodenWall_Dbl_WindowLeft_Bordered",
	"Asian_HalfWoodenWall_Dbl_WindowRight_Bordered",
	"Asian_HalfWoodenWall_Windowframe",
	"Asian_HalfWoodenWall_Windowframe_Both",
	"Asian_HalfWoodenWall_Windowframe_Left",
	"Asian_HalfWoodenWall_Windowframe_Right"
}
BuildingRecipeGroups.RECIPE_GROUPS["AsianStyle_HalfShinglesWall"] = {
	"Asian_HalfShinglesWall",
	"Asian_HalfShinglesWall_Dbl_WindowLeft",
	"Asian_HalfShinglesWall_Dbl_WindowRight",
}
BuildingRecipeGroups.RECIPE_GROUPS["AsianStyle_WoodenWall"] = {
	"Asian_WoodenWall",
	"Asian_WoodenWall_Windowframe",
	"Asian_WoodenWall_Dbl_WindowLeft",
	"Asian_WoodenWall_Dbl_WindowRight",
	"Asian_WoodenWall_Dbl_WindowLeft_Deco",
	"Asian_WoodenWall_Dbl_WindowRight_Deco",
	"Asian_WoodenWall_Doorframe"
}

--Windowframes


BuildingRecipeGroups.RECIPE_GROUPS["AsianStyle_Asiandoors"] = {
	"Asian_Outdoor_Sliding",
	"Asian_JClassic_Sliding",
	"Asian_Transparent_Sliding",
	"Asian_Indoor_Sliding",
	'Asian_Indoor_Sliding_Deco'
}
BuildingRecipeGroups.RECIPE_GROUPS["AsianStyle_TatamiFloors"] = {
	"Asian_TatamiFloor_WideSide",
	"Asian_TatamiFloor_Narrow",
	"Asian_TatamiFloor_NarrowEdge",
	"Asian_TatamiFloor_WideCorner1",
	'Asian_TatamiFloor_WideCorner2'
}
BuildingRecipeGroups.RECIPE_GROUPS["AsianStyle_WoodenFloors"] = {
	"Asian_WoodenFloor",
	"Asian_WoodenFloorNarrow"

}
BuildingRecipeGroups.RECIPE_GROUPS["AsianStyle_Fence"] = {
	"Asian_FencePosts",
	"Asian_Fence"

}
BuildingRecipeGroups.RECIPE_GROUPS["AsianStyle_Tables"] = {
	"Asian_Kotatsu",
	"Asian_TableLow",
	"Asian_TableLow_Small"

}

for _, recipeName in ipairs(BuildingRecipeGroups.RECIPE_GROUPS["AsianStyle_PlainWall"]) do
    BuildingRecipeGroups.RECIPE_TO_GROUP[recipeName] = "AsianStyle_PlainWall"
end

for _, recipeName in ipairs(BuildingRecipeGroups.RECIPE_GROUPS["AsianStyle_PlainOutdoorWall"]) do
    BuildingRecipeGroups.RECIPE_TO_GROUP[recipeName] = "AsianStyle_PlainOutdoorWall"
end

for _, recipeName in ipairs(BuildingRecipeGroups.RECIPE_GROUPS["AsianStyle_PlainOutdoorWall_Horisontal"]) do
    BuildingRecipeGroups.RECIPE_TO_GROUP[recipeName] = "AsianStyle_PlainOutdoorWall_Horisontal"
end

for _, recipeName in ipairs(BuildingRecipeGroups.RECIPE_GROUPS["AsianStyle_HalfWoodenWall"]) do
    BuildingRecipeGroups.RECIPE_TO_GROUP[recipeName] = "AsianStyle_HalfWoodenWall"
end

for _, recipeName in ipairs(BuildingRecipeGroups.RECIPE_GROUPS["AsianStyle_PlainWall_Dbl_Window"]) do
    BuildingRecipeGroups.RECIPE_TO_GROUP[recipeName] = "AsianStyle_PlainWall_Dbl_Window"
end

for _, recipeName in ipairs(BuildingRecipeGroups.RECIPE_GROUPS["AsianStyle_PlainOutdoorWall_Dbl_Window"]) do
    BuildingRecipeGroups.RECIPE_TO_GROUP[recipeName] = "AsianStyle_PlainOutdoorWall_Dbl_Window"
end

for _, recipeName in ipairs(BuildingRecipeGroups.RECIPE_GROUPS["AsianStyle_HalfWoodenWall_Dbl_Window"]) do
    BuildingRecipeGroups.RECIPE_TO_GROUP[recipeName] = "AsianStyle_HalfWoodenWall_Dbl_Window"
end
for _, recipeName in ipairs(BuildingRecipeGroups.RECIPE_GROUPS["AsianStyle_HalfShinglesWall"]) do
    BuildingRecipeGroups.RECIPE_TO_GROUP[recipeName] = "AsianStyle_HalfShinglesWall"
end

for _, recipeName in ipairs(BuildingRecipeGroups.RECIPE_GROUPS["AsianStyle_WoodenWall"]) do
    BuildingRecipeGroups.RECIPE_TO_GROUP[recipeName] = "AsianStyle_WoodenWall"
end



for _, recipeName in ipairs(BuildingRecipeGroups.RECIPE_GROUPS["AsianStyle_Asiandoors"]) do
    BuildingRecipeGroups.RECIPE_TO_GROUP[recipeName] = "AsianStyle_Asiandoors"
end
for _, recipeName in ipairs(BuildingRecipeGroups.RECIPE_GROUPS["AsianStyle_Fence"]) do
    BuildingRecipeGroups.RECIPE_TO_GROUP[recipeName] = "AsianStyle_Fence"
end
for _, recipeName in ipairs(BuildingRecipeGroups.RECIPE_GROUPS["AsianStyle_TatamiFloors"]) do
    BuildingRecipeGroups.RECIPE_TO_GROUP[recipeName] = "AsianStyle_TatamiFloors"
end
for _, recipeName in ipairs(BuildingRecipeGroups.RECIPE_GROUPS["AsianStyle_WoodenFloors"]) do
    BuildingRecipeGroups.RECIPE_TO_GROUP[recipeName] = "AsianStyle_WoodenFloors"
end
for _, recipeName in ipairs(BuildingRecipeGroups.RECIPE_GROUPS["AsianStyle_Tables"]) do
    BuildingRecipeGroups.RECIPE_TO_GROUP[recipeName] = "AsianStyle_Tables"
end

