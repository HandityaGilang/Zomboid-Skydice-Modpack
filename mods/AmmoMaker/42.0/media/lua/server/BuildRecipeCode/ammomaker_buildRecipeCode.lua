--Ammo Maker by STIMP_TM

BuildRecipeCode = BuildRecipeCode or {};
BuildRecipeCode.birdFeeder = {};

function BuildRecipeCode.birdFeeder.OnCreate(params)

	local thumpable = params.thumpable;
	local gridSquare = thumpable:getSquare();

	if gridSquare:isOutside() then

		local birdFeederSaveID = "birdFeeder";
		local birdFeederTable = ModData.getOrCreate(birdFeederSaveID);

		local birdFeederLocationNew = gridSquare:getX() .. "," .. gridSquare:getY() .. "," .. gridSquare:getZ();

		local isPartOf = false;

		for _, birdFeederLocation in ipairs(birdFeederTable) do

			if birdFeederLocationNew == birdFeederLocation then

				isPartOf = true;

			end

		end

		if isPartOf == false then

			table.insert(birdFeederTable, birdFeederLocationNew);

		end

		ModData.add(birdFeederSaveID, birdFeederTable);

	end

end