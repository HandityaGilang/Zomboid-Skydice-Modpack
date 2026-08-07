local function HorticultureItemParam(item, newparam)
	local x = ScriptManager.instance:getItem(item)
	if x then
		x:DoParam(newparam)
		print("Horticulture item updated: "..item.." "..newparam)
	else
		print("Horticulture item not found: "..item)
	end	
end

local function HorticultureLearnedRecipe()
	if SandboxVars.B42Horticulture.LearnedRecipe then

		HorticultureItemParam("GlassmakingMag1","LearnedRecipes = MakeWineGlass;MakeLanternGlass;MakeGlassPipe")
    end
end

Events.OnInitGlobalModData.Add(HorticultureLearnedRecipe)