
-- panic with fear of blood when butchering animals
local oldRecipe_OnCreate_CutAnimal = Recipe.OnCreate.CutAnimal
function Recipe.OnCreate.CutAnimal(items, result, player)
	if player:HasTrait("Hemophobic") then
		SOAddPanic(player, 100, 50);
	end
    oldRecipe_OnCreate_CutAnimal(items, result, player)	
end

-- panic with fear of blood when butchering fish
local oldRecipe_OnCreate_CutFillet = Recipe.OnCreate.CutFillet
function Recipe.OnCreate.CutFillet(items, result, player)
	if player:HasTrait("Hemophobic") then
		SOAddPanic(player, 100, 35);
	end
    oldRecipe_OnCreate_CutFillet(items, result, player)	
end