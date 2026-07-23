-- From "Post Flag" mod -- Author = PePePePePeil

local OAC_CompatibilityWith_4PostFlag = {}

OAC_CompatibilityWith_4PostFlag.isInVehicle = false
OAC_CompatibilityWith_4PostFlag.spriteNames = {"ct_oac_street_decoration_01_24","ct_oac_street_decoration_01_25","ct_oac_street_decoration_01_26","ct_oac_street_decoration_01_27",
											   "ct_oac_trashcontainers_01_0","ct_oac_trashcontainers_01_1","ct_oac_trashcontainers_01_2","ct_oac_trashcontainers_01_3","ct_oac_trashcontainers_01_16",
											   "ct_oac_trashcontainers_01_24","ct_oac_trashcontainers_01_25","ct_oac_trashcontainers_01_26","ct_oac_trashcontainers_01_27"}

-- *****************************************************************************
-- * Event trigger functions
-- *****************************************************************************

OAC_CompatibilityWith_4PostFlag.OnCreatePlayer = function(index, player)
	OAC_CompatibilityWith_4PostFlag.isInVehicle = player:getVehicle() and true or false
	if OAC_CompatibilityWith_4PostFlag.isInVehicle then
		Events.OnWorldSound.Add(OAC_CompatibilityWith_4PostFlag.OnWorldSound)
	end
end
Events.OnCreatePlayer.Add(OAC_CompatibilityWith_4PostFlag.OnCreatePlayer)

local function OnEnterVehicle(character)
	OAC_CompatibilityWith_4PostFlag.isInVehicle = true
	Events.OnWorldSound.Add(OAC_CompatibilityWith_4PostFlag.OnWorldSound)
end
Events.OnEnterVehicle.Add(OnEnterVehicle)

local function OnExitVehicle(character)
	OAC_CompatibilityWith_4PostFlag.isInVehicle = false
	Events.OnWorldSound.Remove(OAC_CompatibilityWith_4PostFlag.OnWorldSound)
end
Events.OnExitVehicle.Add(OnExitVehicle)

OAC_CompatibilityWith_4PostFlag.OnWorldSound = function(x, y, z, radius, volume, source)
	if OAC_CompatibilityWith_4PostFlag.isInVehicle then
		if radius == 20 and volume == 20 and not source then
			local square = getSquare(x, y, z)
			if square then
				local objects = square:getObjects()
				for i = 0, objects:size() - 1 do
					local object = objects:get(i)
					if instanceof(object, "IsoObject") then
						local sprite = object:getSprite()
						local spriteName = sprite and sprite:getName() or nil
						if spriteName then
							for i,v in ipairs(OAC_CompatibilityWith_4PostFlag.spriteNames) do
								if v == spriteName then
									object:setOverlaySprite("")
									break
								end
							end
						end
					end
				end
			end
		end
	end
end