SpecialLootSpawns = SpecialLootSpawns or {}

SpecialLootSpawns.OnCreatePopBottleFA = function(item)
	if not item then return; end;
	if not item:getFluidContainer() then return end;
	local fluid = item:getFluidContainer():getPrimaryFluid();
	if fluid:getFluidTypeString() == "SodaPop" then
		item:setModelIndex(1);	
	else
		item:setModelIndex(0);
	end

	local fluidColor = item:getFluidContainer():getColor();
	local r, g, b = fluidColor:getR(), fluidColor:getG(), fluidColor:getB();
	
	if fluid:getFluidTypeString() == "FAKYCola" then
		r, g, b = 0.8, 0.0, 0.0;
	elseif fluid:getFluidTypeString() == "FARootBeer" then
		r, g, b = 1.0, 0.8, 0.0;
	elseif fluid:getFluidTypeString() == "FALemonLime" then
		r, g, b = 0.2, 0.5, 0.0;			
	elseif fluid:getFluidTypeString() == "FAMixedBerries" then
		r, g, b = 0.5, 0.2, 0.5;	
	elseif fluid:getFluidTypeString() == "FADrPeppa" then
		r, g, b = 0.8, 0.6, 0.6;
	end

	item:setColorRed(r);
	item:setColorGreen(g);
	item:setColorBlue(b);
	item:setColor(Color.new(r, g, b));
	item:setCustomColor(true);
end