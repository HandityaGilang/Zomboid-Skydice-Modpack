require ("BuildRecipeCode\NB_BuildRecipeCode")

local originalNB_BuildRecipeCode = NB_BuildRecipeCode

NB_BuildRecipeCode.SlidingDoor = {}

function NB_BuildRecipeCode.SlidingDoor.OnCreate(params)
    local thumpable = params.thumpable
	local doorframesprite = "fixtures_asianwalls_02_49"
	if not thumpable:getNorth() then 
		doorframesprite = "fixtures_asianwalls_02_48"
	end
	local doorframe = IsoThumpable.new(getCell(), thumpable:getSquare(), doorframesprite, thumpable:getNorth());  --cell, self.sq, sprite, north, self
	thumpable:getSquare():AddSpecialObject(doorframe)
    doorframe:setCanPassThrough(true)
    doorframe:setIsThumpable(false)
end


