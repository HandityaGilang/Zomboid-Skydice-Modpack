local function SurvivalItemParam(item, newparam)
	local x = ScriptManager.instance:getItem(item)
	if x then
		x:DoParam(newparam)
		print("Survival item updated: "..item.." "..newparam)
	else
		print("Survival item not found: "..item)
	end	
end

local function SurvivalLearnedRecipe()
	if SandboxVars.B42Survival.LearnedRecipe then

		SurvivalItemParam("PrimitiveToolMag3","LearnedRecipes = CarveKnittingNeedles;CarveWoodenFork;MakeBoneFork;CarveWoodenSpade;CarveGoblets;CarveBucket;CarveButton")
    end
end

local function SurvivalTorchSmoking()
	if SandboxVars.B42Survival.TorchSmoking then

		SurvivalItemParam("Cigar","RequireInHandOrInventory = Base.CandleLit/Base.CandleTinCanLit/Base.CandleWaterRationCanLit/Base.Matches/Base.Matchbox/Base.LighterDisposable/Base.Lighter/Base.LighterBBQ/Base.Lighter_Battery/Base.TorchLit")
		SurvivalItemParam("Cigarillo","RequireInHandOrInventory = Base.CandleLit/Base.CandleTinCanLit/Base.CandleWaterRationCanLit/Base.Matches/Base.Matchbox/Base.LighterDisposable/Base.Lighter/Base.LighterBBQ/Base.Lighter_Battery/Base.TorchLit")
		SurvivalItemParam("CigaretteRolled","RequireInHandOrInventory = Base.CandleLit/Base.CandleTinCanLit/Base.CandleWaterRationCanLit/Base.Matches/Base.Matchbox/Base.LighterDisposable/Base.Lighter/Base.LighterBBQ/Base.Lighter_Battery/Base.TorchLit")
		SurvivalItemParam("CigaretteSingle","RequireInHandOrInventory = Base.CandleLit/Base.CandleTinCanLit/Base.CandleWaterRationCanLit/Base.Matches/Base.Matchbox/Base.LighterDisposable/Base.Lighter/Base.LighterBBQ/Base.Lighter_Battery/Base.TorchLit")
		-- [B42] Horticulture
		SurvivalItemParam("CigarHemp","RequireInHandOrInventory = Base.CandleLit/Base.CandleTinCanLit/Base.CandleWaterRationCanLit/Base.Matches/Base.Matchbox/Base.LighterDisposable/Base.Lighter/Base.LighterBBQ/Base.Lighter_Battery/Base.TorchLit")
		SurvivalItemParam("CigarRolled","RequireInHandOrInventory = Base.CandleLit/Base.CandleTinCanLit/Base.CandleWaterRationCanLit/Base.Matches/Base.Matchbox/Base.LighterDisposable/Base.Lighter/Base.LighterBBQ/Base.Lighter_Battery/Base.TorchLit")
		SurvivalItemParam("CigaretteHemp","RequireInHandOrInventory = Base.CandleLit/Base.CandleTinCanLit/Base.CandleWaterRationCanLit/Base.Matches/Base.Matchbox/Base.LighterDisposable/Base.Lighter/Base.LighterBBQ/Base.Lighter_Battery/Base.TorchLit")
    end
end

Events.OnInitGlobalModData.Add(SurvivalLearnedRecipe)
Events.OnInitGlobalModData.Add(SurvivalTorchSmoking)