-- From "Open All Containers [B41]" mod -- Author = carlesturo

local OAC_SpriteData = require("OAC_SpriteData")
local OAC_Utils = require("OAC_Utils")
local IsoObjectUtilsFromStarlitLibrary = require("IsoObjectUtilsFromStarlitLibrary")

-- ------------------------------------------------------------------------------------------------

local OAC_isInVehicle = false

local tickCounter = 0

function OnTick()
	if not OAC.options.autoOpen or OAC_isInVehicle then return end

	local tickRate = SandboxVars.OpenAllContainers.TickRate or 60
    tickCounter = tickCounter + 1

    if tickCounter >= tickRate then
		for i = 0, getNumActivePlayers() - 1 do
			local player = getSpecificPlayer(i)
			if player and player:getSquare() then
				local playerSquare = player:getSquare()
				local x, y, z = playerSquare:getX(), playerSquare:getY(), playerSquare:getZ()

				for dx = -2, 2 do
					for dy = -2, 2 do
						local neighborSquare = getCell():getGridSquare(x + dx, y + dy, z)
						if neighborSquare then
							local objects = neighborSquare:getObjects()
							for j = 0, objects:size() - 1 do
								local obj = objects:get(j)
								if obj and obj:getSprite() then
									local spriteName = obj:getSprite():getName()
									local spriteData = OAC_SpriteData.getSpriteDataByOriginalSprite(spriteName)
									if spriteData then
										local modData = obj:getModData()

										if obj:isHighlighted() and spriteName == spriteData.originalSprite then
											if not modData.autoOpened then
												modData.autoOpened = true

												local chosenSprite = spriteData.openSprite
												if getActivatedMods():contains("P4PostFlag") and spriteData.openSprite4PostFlag then
													chosenSprite = spriteData.openSprite4PostFlag
												end

												OAC_Utils.saveAndRemoveOriginalTileOverlay(obj)
												OAC_Utils.replaceAllObjectsBySprite(neighborSquare, spriteData.originalSprite, chosenSprite)
												--OAC_Utils.applyNewTileOverlay(obj, spriteData, "overlayOpenSprite")
												ItemPicker.updateOverlaySprite(obj)

												if spriteData.originalSprite and OAC_SpriteData.SpritePairs[spriteData.originalSprite] then
													if spriteData.isPaired and spriteData.pairedOffset then
														local pairedSquare = getCell():getGridSquare(neighborSquare:getX() + spriteData.pairedOffset.x, neighborSquare:getY() + spriteData.pairedOffset.y, neighborSquare:getZ())
														if pairedSquare then
															local pairedObjects = pairedSquare:getObjects()
															for k = 0, pairedObjects:size() - 1 do
																local pairedObj = pairedObjects:get(k)
																if pairedObj and pairedObj:getSprite() then
																	local pairedSpriteName = pairedObj:getSprite():getName()
																	local pairedData = OAC_SpriteData.getSpriteDataByOriginalSprite(pairedSpriteName)
																	if pairedData and OAC_SpriteData.SpritePairs[spriteName] == pairedSpriteName then
																		OAC_Utils.replaceAllObjectsBySprite(pairedSquare, pairedData.originalSprite, pairedData.openSprite)
																		ItemPicker.updateOverlaySprite(pairedObj)
																	end
																end
															end
														end
													end
												end

												if spriteData.doorSprite then
													local coord = spriteData.doorSprite
													if coord.sprite and coord.dx and coord.dy then
														local newSquare = IsoObjectUtilsFromStarlitLibrary.getOrCreateSquare(neighborSquare:getX() + coord.dx, neighborSquare:getY() + coord.dy, neighborSquare:getZ())
														if newSquare then
															OAC_Utils.addObjectToSquare(newSquare, coord.sprite)
														end
													end
												end
											end

										elseif not obj:isHighlighted() and spriteData then
											local shouldRespectAutoClose = OAC.options.autoClose

											if not spriteData.isPaired and (shouldRespectAutoClose or spriteData.autoClosed) then
												local chosenSprite = spriteData.openSprite
												if getActivatedMods():contains("P4PostFlag") and spriteData.openSprite4PostFlag then
													chosenSprite = spriteData.openSprite4PostFlag
												end

												if spriteName == chosenSprite then
													OAC_Utils.replaceAllObjectsBySprite(neighborSquare, chosenSprite, spriteData.originalSprite)
													if getActivatedMods():contains("P4PostFlag") and spriteData.openSprite4PostFlag then
														ItemPicker.updateOverlaySprite(obj)
													else
														OAC_Utils.restoreOriginalTileOverlay(obj)
													end

												elseif spriteName == spriteData.openSprite2 then
													OAC_Utils.replaceAllObjectsBySprite(neighborSquare, spriteData.openSprite2, spriteData.originalSprite)
													OAC_Utils.restoreOriginalTileOverlay(obj)

												elseif spriteName == spriteData.openSprite3 then
													OAC_Utils.replaceAllObjectsBySprite(neighborSquare, spriteData.openSprite3, spriteData.originalSprite)
													OAC_Utils.restoreOriginalTileOverlay(obj)
												end

											elseif spriteData.isPaired and (shouldRespectAutoClose or spriteData.autoClosed) then
												if not modData.currentState then
													modData.currentState = 1
												end

												if spriteData.isPaired and spriteData.pairedOffset then
													local pairedSquare = getCell():getGridSquare(neighborSquare:getX() + spriteData.pairedOffset.x, neighborSquare:getY() + spriteData.pairedOffset.y, neighborSquare:getZ())
													if pairedSquare then
														local pairedObjects = pairedSquare:getObjects()
														for k = 0, pairedObjects:size() - 1 do
															local pairedObj = pairedObjects:get(k)
															if pairedObj and pairedObj:getSprite() then
																local pairedSpriteName = pairedObj:getSprite():getName()
																local pairedData = OAC_SpriteData.getSpriteDataByOriginalSprite(pairedSpriteName)
																local pairedModData = pairedObj:getModData()
																if pairedData and OAC_SpriteData.SpritePairs[spriteName] == pairedSpriteName then

																	if not obj:isHighlighted() and not pairedObj:isHighlighted() then
																		if modData.currentState == 1 then
																			OAC_Utils.replaceAllObjectsBySprite(obj:getSquare(), spriteData.openSprite, spriteData.originalSprite)
																			OAC_Utils.replaceAllObjectsBySprite(pairedSquare, pairedData.openSprite, pairedData.originalSprite)
																			OAC_Utils.restoreOriginalTileOverlay(obj)
																			OAC_Utils.restoreOriginalTileOverlay(pairedObj)
																			modData.currentState = 0
																			pairedModData.currentState = 0

																		elseif modData.currentState == 3 then
																			OAC_Utils.replaceAllObjectsBySprite(obj:getSquare(), spriteData.openSprite2, spriteData.originalSprite)
																			OAC_Utils.replaceAllObjectsBySprite(pairedSquare, pairedData.openSprite2, pairedData.originalSprite)
																			OAC_Utils.restoreOriginalTileOverlay(obj)
																			OAC_Utils.restoreOriginalTileOverlay(pairedObj)
																			modData.currentState = 0
																			pairedModData.currentState = 0

																		elseif modData.currentState == 5 then
																			OAC_Utils.replaceAllObjectsBySprite(obj:getSquare(), spriteData.openSprite3, spriteData.originalSprite)
																			OAC_Utils.replaceAllObjectsBySprite(pairedSquare, pairedData.openSprite3, pairedData.originalSprite)
																			OAC_Utils.restoreOriginalTileOverlay(obj)
																			OAC_Utils.restoreOriginalTileOverlay(pairedObj)
																			modData.currentState = 0
																			pairedModData.currentState = 0
																		end
																	end
																end
															end
														end
													end
												end
											end

											if spriteData.doorSprite and (shouldRespectAutoClose or spriteData.autoClosed) then
												local coord = spriteData.doorSprite
												if coord.sprite and coord.dx and coord.dy then
													local newSquare = IsoObjectUtilsFromStarlitLibrary.getOrCreateSquare(neighborSquare:getX() + coord.dx, neighborSquare:getY() + coord.dy, neighborSquare:getZ())
													if newSquare then
														OAC_Utils.removeAllObjectsBySprite(newSquare, coord.sprite)
													end
												end
											end

											if spriteName == spriteData.originalSprite then
												if modData.currentState then
													modData.currentState = nil
												end
												modData.autoOpened = nil
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end

        tickCounter = 0
    end
end

function OnKeyPressed(key)
	if OAC_isInVehicle then return end

    if key == OAC.keyBind.key then
		for i = 0, getNumActivePlayers() - 1 do
			local player = getSpecificPlayer(i)
			if player and player:getSquare() then
				local playerSquare = player:getSquare()
				local x, y, z = playerSquare:getX(), playerSquare:getY(), playerSquare:getZ()

				for dx = -2, 2 do
					for dy = -2, 2 do
						local neighborSquare = getCell():getGridSquare(x + dx, y + dy, z)
						if neighborSquare then
							local objects = neighborSquare:getObjects()
							for j = 0, objects:size() - 1 do
								local obj = objects:get(j)
								if obj and obj:getSprite() then
									local spriteName = obj:getSprite():getName()
									local spriteData = OAC_SpriteData.getSpriteDataByOriginalSprite(spriteName)
									local modData = obj:getModData()

									if obj:isHighlighted() and spriteData then
										if not modData.currentState then
											if OAC.options.autoOpen then
												modData.currentState = 1
											else
												modData.currentState = 0
											end
										end

										local shouldIgnoreAutoClosed = not OAC.options.autoOpen

										if not spriteData.isPaired and (shouldIgnoreAutoClosed or not spriteData.autoClosed) then
											local chosenSprite = spriteData.openSprite
											if getActivatedMods():contains("P4PostFlag") and spriteData.openSprite4PostFlag then
												chosenSprite = spriteData.openSprite4PostFlag
											end

											if modData.currentState == 0 then
												OAC_Utils.saveAndRemoveOriginalTileOverlay(obj)
												OAC_Utils.replaceAllObjectsBySprite(neighborSquare, spriteData.originalSprite, chosenSprite)
												--OAC_Utils.applyNewTileOverlay(obj, spriteData, "overlayOpenSprite")
												ItemPicker.updateOverlaySprite(obj)
												modData.currentState = 1

											elseif modData.currentState == 1 then
												OAC_Utils.replaceAllObjectsBySprite(neighborSquare, chosenSprite, spriteData.originalSprite)
												if not spriteData.openSprite2 then
													if getActivatedMods():contains("P4PostFlag") and spriteData.openSprite4PostFlag then
														ItemPicker.updateOverlaySprite(obj)
													else
														OAC_Utils.restoreOriginalTileOverlay(obj)
													end
													modData.currentState = 0
												else
													OAC_Utils.restoreOriginalTileOverlay(obj)
													modData.currentState = 2
												end

											elseif modData.currentState == 2 then
												OAC_Utils.saveAndRemoveOriginalTileOverlay(obj)
												OAC_Utils.replaceAllObjectsBySprite(neighborSquare, spriteData.originalSprite, spriteData.openSprite2)
												--OAC_Utils.applyNewTileOverlay(obj, spriteData, "overlayOpenSprite2")
												ItemPicker.updateOverlaySprite(obj)
												modData.currentState = 3

											elseif modData.currentState == 3 then
												OAC_Utils.replaceAllObjectsBySprite(neighborSquare, spriteData.openSprite2, spriteData.originalSprite)
												if not spriteData.openSprite3 then
													OAC_Utils.restoreOriginalTileOverlay(obj)
													modData.currentState = 0
												else
													OAC_Utils.restoreOriginalTileOverlay(obj)
													modData.currentState = 4
												end

											elseif modData.currentState == 4 then
												OAC_Utils.saveAndRemoveOriginalTileOverlay(obj)
												OAC_Utils.replaceAllObjectsBySprite(neighborSquare, spriteData.originalSprite, spriteData.openSprite3)
												--OAC_Utils.applyNewTileOverlay(obj, spriteData, "overlayOpenSprite3")
												ItemPicker.updateOverlaySprite(obj)
												modData.currentState = 5

											elseif modData.currentState == 5 then
												OAC_Utils.replaceAllObjectsBySprite(neighborSquare, spriteData.openSprite3, spriteData.originalSprite)
												if not spriteData.openSprite4 then
													OAC_Utils.restoreOriginalTileOverlay(obj)
													modData.currentState = 0
												else
													OAC_Utils.restoreOriginalTileOverlay(obj)
													modData.currentState = 6
												end
											end

										elseif spriteData.isPaired and (shouldIgnoreAutoClosed or not spriteData.autoClosed) then
											if spriteData.isPaired and spriteData.pairedOffset then
												local pairedSquare = getCell():getGridSquare(neighborSquare:getX() + spriteData.pairedOffset.x, neighborSquare:getY() + spriteData.pairedOffset.y, neighborSquare:getZ())
												if pairedSquare then
													local pairedObjects = pairedSquare:getObjects()
													for k = 0, pairedObjects:size() - 1 do
														local pairedObj = pairedObjects:get(k)
														if pairedObj and pairedObj:getSprite() then
															local pairedSpriteName = pairedObj:getSprite():getName()
															local pairedData = OAC_SpriteData.getSpriteDataByOriginalSprite(pairedSpriteName)
															local pairedModData = pairedObj:getModData()

															if pairedData and OAC_SpriteData.SpritePairs[spriteName] == pairedSpriteName then
																if modData.currentState == 0 then
																	OAC_Utils.replaceAllObjectsBySprite(neighborSquare, spriteData.originalSprite, spriteData.openSprite)
																	ItemPicker.updateOverlaySprite(obj)
																	OAC_Utils.replaceAllObjectsBySprite(pairedSquare, pairedData.originalSprite, pairedData.openSprite)
																	ItemPicker.updateOverlaySprite(pairedObj)
																	modData.currentState = 1
																	pairedModData.currentState = 1

																elseif modData.currentState == 1 then
																	OAC_Utils.replaceAllObjectsBySprite(neighborSquare, spriteData.openSprite, spriteData.originalSprite)
																	OAC_Utils.replaceAllObjectsBySprite(pairedSquare, pairedData.openSprite, pairedData.originalSprite)
																	if not spriteData.openSprite2 then
																		OAC_Utils.restoreOriginalTileOverlay(obj)
																		OAC_Utils.restoreOriginalTileOverlay(pairedObj)
																		modData.currentState = 0
																		pairedModData.currentState = 0
																	else
																		OAC_Utils.restoreOriginalTileOverlay(obj)
																		OAC_Utils.restoreOriginalTileOverlay(pairedObj)
																		modData.currentState = 2
																		pairedModData.currentState = 2
																	end

																elseif modData.currentState == 2 then
																	OAC_Utils.replaceAllObjectsBySprite(neighborSquare, spriteData.originalSprite, spriteData.openSprite2)
																	ItemPicker.updateOverlaySprite(obj)
																	OAC_Utils.replaceAllObjectsBySprite(pairedSquare, pairedData.originalSprite, pairedData.openSprite2)
																	ItemPicker.updateOverlaySprite(pairedObj)
																	modData.currentState = 3
																	pairedModData.currentState = 3

																elseif modData.currentState == 3 then
																	OAC_Utils.replaceAllObjectsBySprite(neighborSquare, spriteData.openSprite2, spriteData.originalSprite)
																	OAC_Utils.replaceAllObjectsBySprite(pairedSquare, pairedData.openSprite2, pairedData.originalSprite)
																	if not spriteData.openSprite3 then
																		OAC_Utils.restoreOriginalTileOverlay(obj)
																		OAC_Utils.restoreOriginalTileOverlay(pairedObj)
																		modData.currentState = 0
																		pairedModData.currentState = 0
																	else
																		OAC_Utils.restoreOriginalTileOverlay(obj)
																		OAC_Utils.restoreOriginalTileOverlay(pairedObj)
																		modData.currentState = 4
																		pairedModData.currentState = 4
																	end

																elseif modData.currentState == 4 then
																	OAC_Utils.replaceAllObjectsBySprite(neighborSquare, spriteData.originalSprite, spriteData.openSprite3)
																	ItemPicker.updateOverlaySprite(obj)
																	OAC_Utils.replaceAllObjectsBySprite(pairedSquare, pairedData.originalSprite, pairedData.openSprite3)
																	ItemPicker.updateOverlaySprite(pairedObj)
																	modData.currentState = 5
																	pairedModData.currentState = 5

																elseif modData.currentState == 5 then
																	OAC_Utils.replaceAllObjectsBySprite(neighborSquare, spriteData.openSprite3, spriteData.originalSprite)
																	OAC_Utils.replaceAllObjectsBySprite(pairedSquare, pairedData.openSprite3, pairedData.originalSprite)
																	if not spriteData.openSprite4 then
																		OAC_Utils.restoreOriginalTileOverlay(obj)
																		OAC_Utils.restoreOriginalTileOverlay(pairedObj)
																		modData.currentState = 0
																		pairedModData.currentState = 0
																	else
																		OAC_Utils.restoreOriginalTileOverlay(obj)
																		OAC_Utils.restoreOriginalTileOverlay(pairedObj)
																		modData.currentState = 6
																		pairedModData.currentState = 6
																	end
																end
															end
														end
													end
												end
											end
										end

										if OAC.options.autoOpen then
											modData.autoOpened = true
										end
									end
								end
							end
						end
					end
				end
			end
		end
    end
end

Events.OnTick.Add(OnTick)
Events.OnKeyPressed.Add(OnKeyPressed)

local function OnCreatePlayer(index, player)
    OAC_isInVehicle = player:getVehicle() and true or false
end
Events.OnCreatePlayer.Add(OnCreatePlayer)

local function OnEnterVehicle(character)
    OAC_isInVehicle = true
end
Events.OnEnterVehicle.Add(OnEnterVehicle)

local function OnExitVehicle(character)
    OAC_isInVehicle = false
end
Events.OnExitVehicle.Add(OnExitVehicle)

-- ------------------------------------------------------------------------------------------------