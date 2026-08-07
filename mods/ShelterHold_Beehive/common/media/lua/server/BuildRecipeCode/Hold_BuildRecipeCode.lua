Hold_BuildRecipeCode = Hold_BuildRecipeCode or {}
Hold_BuildRecipeCode.beehive = {}
Hold_BuildRecipeCode.honeyExtractor = {}
Hold_BuildRecipeCode.baitHive = {}

function Hold_BuildRecipeCode.beehive.OnIsValid(params)
	if isServer() and SBeehiveSystem.instance:getLuaObjectOnSquare(params.square) then
		return false
	end
	if not isServer() and CBeehiveSystem.instance:getLuaObjectOnSquare(params.square) then
		return false
	end
	return true
end

function Hold_BuildRecipeCode.beehive.OnCreate(params)
    local thumpable = params.thumpable
	local sprite = thumpable:getSprite()
	local spriteName = sprite:getName()
	local grid = thumpable:getSquare()
	if not grid then return end

	SBeehiveSystem.instance:addBeehive(grid, spriteName)
end

function Hold_BuildRecipeCode.honeyExtractor.OnCreate(params)
    local thumpable = params.thumpable
	local sprite = thumpable:getSprite()
	local square = thumpable:getSquare()
	local objects = square:getObjects()

	for i=objects:size()-1, 0, -1 do
		local object = objects:get(i)
		if object:getSprite() == sprite then 
			local fluidContainer = object:getFluidContainer()
			if fluidContainer then
				local whitelist = FluidFilter.new()
				whitelist:add("RawHoney")
				fluidContainer:setWhitelist(whitelist)
				break
			end
		end
	end
end