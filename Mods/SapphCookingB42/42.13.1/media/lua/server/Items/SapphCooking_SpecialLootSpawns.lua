--[[
SpecialLootSpawns.OnCreateFortuneMessage=function(item)
    if not item then return; end;
	local text
	local bookList = PrintMediaDefinitions.FortuneMessage
	local book = bookList[ZombRand(#bookList)+1]
	local text = getText(item:getDisplayName())
	item:setName(text)
    item:getModData().printMedia = book
end
]]--


SpecialLootSpawns.OnCreateSapphJuicePopBottle = function(item)
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
	
	if fluid:getFluidTypeString() == "Cola" then
		r, g, b = 1.0, 0.0, 0.0;
	elseif fluid:getFluidTypeString() == "GingerAle" then
		r, g, b = 0.0, 0.0, 1.0;
	elseif fluid:getFluidTypeString() == "SodaLime" then
		r, g, b = 0.0, 1.0, 0.0;			
	elseif fluid:getFluidTypeString() == "SodaPop" then
		r, g, b = 1.0, 0.8, 0.0;	
	end

	item:setColorRed(r);
	item:setColorGreen(g);
	item:setColorBlue(b);
	item:setColor(Color.new(r, g, b));
	item:setCustomColor(true);
end

