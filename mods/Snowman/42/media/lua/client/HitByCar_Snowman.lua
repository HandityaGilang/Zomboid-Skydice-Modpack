-- From "Post Flag" mod -- Author = PePePePePeil

local HitByCar_Snowman = {}

HitByCar_Snowman.isInVehicle = false
HitByCar_Snowman.damagedMap = {
    ["snowman_01_0"] = "snowman_01_4",
    ["snowman_01_1"] = "snowman_01_5",
    ["snowman_01_2"] = "snowman_01_6",
    ["snowman_01_3"] = "snowman_01_7"
}

-- *****************************************************************************
-- * Event trigger functions
-- *****************************************************************************

HitByCar_Snowman.OnCreatePlayer = function(index, player)
	HitByCar_Snowman.isInVehicle = player:getVehicle() and true or false
	if HitByCar_Snowman.isInVehicle then
		Events.OnWorldSound.Add(HitByCar_Snowman.OnWorldSound)
	end
end
Events.OnCreatePlayer.Add(HitByCar_Snowman.OnCreatePlayer)

local function OnEnterVehicle(character)
	HitByCar_Snowman.isInVehicle = true
	Events.OnWorldSound.Add(HitByCar_Snowman.OnWorldSound)
end
Events.OnEnterVehicle.Add(OnEnterVehicle)

local function OnExitVehicle(character)
	HitByCar_Snowman.isInVehicle = false
	Events.OnWorldSound.Remove(HitByCar_Snowman.OnWorldSound)
end
Events.OnExitVehicle.Add(OnExitVehicle)

HitByCar_Snowman.OnWorldSound = function(x, y, z, radius, volume, source)
	if HitByCar_Snowman.isInVehicle then
		if radius == 20 and volume == 20 and not source then
			local square = getSquare(x, y, z)
			if square then
				local objects = square:getObjects()
				for i = 0, objects:size() - 1 do
					local object = objects:get(i)
					if instanceof(object, "IsoObject") then
						local sprite = object:getSprite()
						local spriteName = sprite and sprite:getName() or nil
						if spriteName and HitByCar_Snowman.damagedMap[spriteName] then
							local container = object:getContainer()
							if container then
								local items = container:getItems()
								for j = items:size()-1, 0, -1 do
									local item = items:get(j)
									if item then
										square:AddWorldInventoryItem(item, 0.0, 0.0, 0.0)
									end
								end
							end
							square:transmitRemoveItemFromSquare(object)
							Melt_Snowman.snowmen[object] = nil

							local newSprite = HitByCar_Snowman.damagedMap[spriteName]
							local newObj = IsoObject.new(square, newSprite, nil, false)
							square:AddTileObject(newObj)
							newObj:transmitCompleteItemToServer()
							Melt_Snowman.registerSnowman(newObj)
						end
					end
				end
			end
		end
	end
end