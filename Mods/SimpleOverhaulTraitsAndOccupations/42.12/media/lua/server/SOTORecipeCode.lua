-- panic with fear of blood when butchering animals
local oldRecipe_OnCreate_CutAnimal = Recipe.OnCreate.CutAnimal
function Recipe.OnCreate.CutAnimal(craftRecipeData, character)
	if character:HasTrait("Hemophobic") then
		SOAddPanic(character, 100, 50);
	end
    oldRecipe_OnCreate_CutAnimal(craftRecipeData, character)	
end

-- panic with fear of blood when butchering fish
local oldRecipe_OnCreate_CutFillet = Recipe.OnCreate.CutFillet
function Recipe.OnCreate.CutFillet(craftRecipeData, character)
	if character:HasTrait("Hemophobic") then
		SOAddPanic(character, 100, 25);
	end
    oldRecipe_OnCreate_CutFillet(craftRecipeData, character)	
end

local oldRecipe_OnCreate_CutFish = Recipe.OnCreate.CutFish
function Recipe.OnCreate.CutFish(craftRecipeData, character)
	if character:HasTrait("Hemophobic") then
		SOAddPanic(character, 100, 35);
	end
    oldRecipe_OnCreate_CutFish(craftRecipeData, character)	
end