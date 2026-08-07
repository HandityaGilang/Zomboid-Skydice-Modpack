-- From "Snowman" mod -- Author = carlesturo

BuildRecipeCode_Snowman = BuildRecipeCode_Snowman or {}
BuildRecipeCode_Snowman.snowman = {}

function BuildRecipeCode_Snowman.snowman.OnIsValid(params)
    if not params or not params.square then return false end

    local square = params.square
    local cell = square:getCell()
    if not cell then return false end

    local x, y, z = square:getX(), square:getY(), square:getZ()

    return cell:gridSquareIsSnow(x, y, z)
end


function BuildRecipeCode_Snowman.snowman.OnCreate(params)
    local snowman = params.thumpable or params.object
    if not snowman then return end

    local container = snowman:getContainer()
    if container then
        container:setAcceptItemFunction('Container_Snowman.AcceptItemFunction')
    end

    Melt_Snowman.registerSnowman(snowman)

	local playerObj = params.character
	if not playerObj then return end

	local wearingGloves = playerObj:getWornItem(ItemBodyLocation.HANDS)
	local bodyDamage = playerObj:getBodyDamage()
	local stiffnessAmount = 100
	if not wearingGloves then
		bodyDamage:addStiffness(BodyPartType.Hand_L, stiffnessAmount)
		bodyDamage:addStiffness(BodyPartType.Hand_R, stiffnessAmount)
	end

	for i=0, getNumActivePlayers()-1 do
		local player = getSpecificPlayer(i)
		if player and getPlayerInventory and getPlayerLoot then
			local invPage = getPlayerInventory(player:getPlayerNum())
			local lootPage = getPlayerLoot(player:getPlayerNum())
			if invPage then invPage:refreshBackpacks() end
			if lootPage then lootPage:refreshBackpacks() end
		end
	end
end