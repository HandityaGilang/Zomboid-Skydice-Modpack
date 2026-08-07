local function EarlyExitVehiclesSyncAndDamage()
if not SandboxVars.GamestaVehicleZones.earlyExitVehicle then
	return
end


if not isClient() then
	local myBodyPartsTable = {
		["Foot_L"]		=	"Foot_L",
		["Foot_R"]		=	"Foot_R",
		["ForeArm_L"]	=	"ForeArm_L",
		["ForeArm_R"]	=	"ForeArm_R",
		["Hand_L"]		=	"Hand_L",
		["Hand_R"]		=	"Hand_R",
		["Head"]		=	"Head",
		["LowerLeg_L"]	=	"LowerLeg_L",
		["LowerLeg_R"]	=	"LowerLeg_R",
		["Neck"]		=	"Neck",
		["Torso_Lower"]	=	"Torso_Lower",
		["Torso_Upper"]	=	"Torso_Upper",
		["UpperArm_L"]	=	"UpperArm_L",
		["UpperArm_R"]	=	"UpperArm_R",
		["UpperLeg_L"]	=	"UpperLeg_L",
		["UpperLeg_R"]	=	"UpperLeg_R",
	}

	local function getBloodBodyPartType(bodyPart)
		return BloodBodyPartType.FromString(myBodyPartsTable[bodyPart])
	end
	local function getBodyPartType(bodyPart)
		return BodyPartType.FromString(myBodyPartsTable[bodyPart])
	end

	local function onClientCommand(module, command, playerObj, args)
		if module == 'MoreCarFeatures' then
			if command == "EarlyExitVehicleFallDamage" then
				if not args or not args.vspeed or args.vspeed <= 30 then return end
				local damageRand = round((args.vspeed/20), 0)
				if playerObj:hasTrait(CharacterTrait.CLUMSY) then
					damageRand = damageRand + 1
				elseif playerObj:hasTrait(CharacterTrait.GRACEFUL) then
					damageRand = damageRand - 1
				end
				damageRand = damageRand + playerObj:getMoodles():getMoodleLevel(MoodleType.HEAVY_LOAD)/2.5
				damageRand = damageRand * SandboxVars.GamestaVehicleZones.earlyExitVehicleDamage
				if damageRand < 1 then return end	--no damage chance

				local rand = newrandom()
				if args.vspeed <= 50 then
					local extremityBodyParts = {
						{"Foot_L", {}, 0, 0, 0},
						{"Foot_R", {}, 0, 0, 0},
						{"ForeArm_L", {}, 0, 0, 0},
						{"ForeArm_R", {}, 0, 0, 0},
						{"Hand_L", {}, 0, 0, 0},
						{"Hand_R", {}, 0, 0, 0},
						{"LowerLeg_L", {}, 0, 0, 0},
						{"LowerLeg_R", {}, 0, 0, 0},
						{"ForeArm_L", {}, 0, 0, 0},
						{"ForeArm_R", {}, 0, 0, 0},
						{"Hand_L", {}, 0, 0, 0},
						{"Hand_R", {}, 0, 0, 0},
					}

					local it = playerObj:getInventory():getItems()
					for i = 0, it:size() - 1 do
						local item = it:get(i)
						if playerObj:isEquipped(item)
							and item:getCategory() == "Clothing"
							and item:getClothingItem()
							and item:getCoveredParts():size() > 0
							and not item:isBroken()
						then
							local scrDef, insulDef = item:getScratchDefense(), item:getInsulation()
							if scrDef > 0 or insulDef > 0 then
								local coverdParts = item:getCoveredParts()
								for i = 0, coverdParts:size() - 1 do
									local partName = coverdParts:get(i):toString()
									for i = #extremityBodyParts, 1, -1 do
										if extremityBodyParts[i][1] == partName then
											table.insert(extremityBodyParts[i][2], item)
											extremityBodyParts[i][3] = extremityBodyParts[i][3] + scrDef
											extremityBodyParts[i][4] = extremityBodyParts[i][4] + insulDef
											extremityBodyParts[i][5] = extremityBodyParts[i][5] + item:getCondition()-damageRand/(coverdParts:size()/12+1)
										end
									end
								end
							end
						end
					end

					for _, bodyPart in ipairs(extremityBodyParts) do
						local playerBodyPart = playerObj:getBodyDamage():getBodyPart(getBodyPartType(bodyPart[1]))
						local bloodBodyPart = getBloodBodyPartType(bodyPart[1])
						local insulDef = bodyPart[4]/10	--extra padding can help, still gets torn
						for _, clothingPart in ipairs(bodyPart[2]) do
							if not clothingPart:isBroken() then
								if bodyPart[5] <= 0 then
									bodyPart[5] = 0
									clothingPart:setBroken(true)
								end
								clothingPart:setCondition(bodyPart[5])
								clothingPart:syncItemFields()
							end
						end
						if rand:random(1, 20) <= damageRand then	--chance to get hurt badly
							playerObj:addHole(bloodBodyPart)
							if rand:random(1, 100) > bodyPart[3] then	--scratch protection fails
								if rand:random(1, 20) == 1 then
									playerBodyPart:generateFractureNew(damageRand*5+10-insulDef)
								else
									playerBodyPart:setScratched(true, true)
									playerObj:addBlood(bloodBodyPart, true, false, true)
									if rand:random(1, 10) == 1 then
										playerBodyPart:generateBleeding()
									end
								end
							else	--scratch protection applied, no bleeding or scratches, less chance to fracture and slightly less severity
								if rand:random(1, 30) == 1 then
									playerBodyPart:generateFractureNew(damageRand*5+10-insulDef)
								else
									playerBodyPart:ReduceHealth((damageRand*10)/(10+insulDef))
								end
							end
						else
							playerBodyPart:ReduceHealth((damageRand*10)/(10+insulDef))
						end
					end

				else
					local mostBodyParts = {
						{"Foot_L", {}, 0, 0, 0},
						{"Foot_R", {}, 0, 0, 0},
						{"ForeArm_L", {}, 0, 0, 0},
						{"ForeArm_R", {}, 0, 0, 0},
						{"Hand_L", {}, 0, 0, 0},
						{"Hand_R", {}, 0, 0, 0},
						{"Head", {}, 0, 0, 0},
						{"LowerLeg_L", {}, 0, 0, 0},
						{"LowerLeg_R", {}, 0, 0, 0},
						{"Neck", {}, 0, 0, 0},
						{"Torso_Lower", {}, 0, 0, 0},
						{"Torso_Upper", {}, 0, 0, 0},
						{"UpperArm_L", {}, 0, 0, 0},
						{"UpperArm_R", {}, 0, 0, 0},
						{"UpperLeg_L", {}, 0, 0, 0},
						{"UpperLeg_R", {}, 0, 0, 0},
						{"Foot_L", {}, 0, 0, 0},
						{"Foot_R", {}, 0, 0, 0},
						{"ForeArm_L", {}, 0, 0, 0},
						{"ForeArm_R", {}, 0, 0, 0},
						{"Hand_L", {}, 0, 0, 0},
						{"Hand_R", {}, 0, 0, 0},
						{"Head", {}, 0, 0, 0},
						{"LowerLeg_L", {}, 0, 0, 0},
						{"LowerLeg_R", {}, 0, 0, 0},
					}

					local it = playerObj:getInventory():getItems()
					for i = 0, it:size() - 1 do
						local item = it:get(i)
						if playerObj:isEquipped(item)
							and item:getCategory() == "Clothing"
							and item:getClothingItem()
							and item:getCoveredParts():size() > 0
							and not item:isBroken()
						then
							local scrDef, insulDef = item:getScratchDefense(), item:getInsulation()
							if scrDef > 0 or insulDef > 0 then
								local coverdParts = item:getCoveredParts()
								for i = 0, coverdParts:size() - 1 do
									local partName = coverdParts:get(i):toString()
									for i = #mostBodyParts, 1, -1 do
										if mostBodyParts[i][1] == partName then
											table.insert(mostBodyParts[i][2], item)
											mostBodyParts[i][3] = mostBodyParts[i][3] + scrDef
											mostBodyParts[i][4] = mostBodyParts[i][4] + insulDef
											mostBodyParts[i][5] = mostBodyParts[i][5] + item:getCondition()-damageRand/(coverdParts:size()/16+1)
										end
									end
								end
							end
						end
					end

					for _, bodyPart in ipairs(mostBodyParts) do
						local playerBodyPart = playerObj:getBodyDamage():getBodyPart(getBodyPartType(bodyPart[1]))
						local bloodBodyPart = getBloodBodyPartType(bodyPart[1])
						local insulDef = bodyPart[4]/10
						for _, clothingPart in ipairs(bodyPart[2]) do
							if not clothingPart:isBroken() then
								if bodyPart[5] <= 0 then
									bodyPart[5] = 0
									clothingPart:setBroken(true)
								end
								clothingPart:setCondition(bodyPart[5])
								clothingPart:syncItemFields()
							end
						end
						if rand:random(1, 20) <= damageRand then
							playerObj:addHole(bloodBodyPart)
							if rand:random(1, 100) > bodyPart[3] then
								if rand:random(1, 10) == 1 then
									playerBodyPart:generateFractureNew(damageRand*10+10-insulDef)
								else
									playerBodyPart:setScratched(true, true)
									playerObj:addBlood(bloodBodyPart, true, false, true)
									if rand:random(1, 5) == 1 then
										playerBodyPart:generateBleeding()
									end
								end
							else
								if rand:random(1, 20) == 1 then
									playerBodyPart:generateFractureNew(damageRand*10+10-insulDef)
								else
									playerBodyPart:ReduceHealth((damageRand*10)/(10+insulDef))
								end
							end
						else
							playerBodyPart:ReduceHealth((damageRand*10)/(10+insulDef))
						end
					end
				end

				if isServer() then
					sendDamage(playerObj)
					syncVisuals(playerObj)
				end

			elseif command == "SyncFallExitVehicleCHRXY" then
				if not args or not args.chrx or not args.chry then return end
				local args2 = { args.chrx, args.chry, playerObj:getOnlineID() }
				sendServerCommand("MoreCarFeatures", command, args2)

			elseif command == "SyncFallExitVehicleAnim" then
				if not args or not args.animTypeString then return end
				local args2 = { args.animTypeString, args.faceDir, playerObj:getOnlineID(), args.chrx, args.chry }
				sendServerCommand("MoreCarFeatures", command, args2)

			elseif command == "SyncFallExitVehicleEND" then
				local args2 = { playerObj:getOnlineID() }
				sendServerCommand("MoreCarFeatures", command, args2)

			end
		end
	end
	Events.OnClientCommand.Add(onClientCommand)

elseif isClient() then	--NONE OF THE BELOW IS GOOD PRACTICE OR EVEN LOOKS GOOD IN-GAME, BUT TBH, IDRC BECAUSE IT LOOKS GREAT IN SP AND ON THE CLIENT'S SIDE, I DID THE BARE MINIMUM
	local function onServerCommand(module, command, args)
		if module == 'MoreCarFeatures' and command == "SyncFallExitVehicleAnim" then
			local players = getPlayerByOnlineID(args[3])
			if not players or players == (getSpecificPlayer(0) or getSpecificPlayer(1) or getSpecificPlayer(2) or getSpecificPlayer(3)) then return end

			local endAll = false
			local x, y = args[4], args[5]
			players:setVariable(args[1], true)

			local function onInternalServerCommand(module, command, args2)
				if module == 'MoreCarFeatures' then
					if command == "SyncFallExitVehicleCHRXY" then
						local players2 = getPlayerByOnlineID(args2[3])
						if players2 == players then
							x, y = args2[1], args2[2]
						end
					elseif command == "SyncFallExitVehicleEND" then
						local players2 = getPlayerByOnlineID(args2[1])
						if players2 == players then
							players:setVariable("EarlyExitVehicleFallDamage", false)
							players:setVariable("EarlySprintAway", false)
							players:setVariable("StumbleVehicleExitRoll", false)
							players:setVariable("TripVehicleExitRoll", false)
							players:setVariable("TumbleVehicleExitRoll", false)
							players:setVariable("doScrambleFromExitVehicleFall", false)
							endAll = true
						end
					end
				end
			end
			Events.OnServerCommand.Add(onInternalServerCommand)

			local function playersAnimChecks()
				if not endAll and getPlayerByOnlineID(args[3]) then
					players:setX(x)
					players:setY(y)
					players:setTargetAndCurrentDirection(math.cos(args[2]), math.sin(args[2]))
					players:PlayAnim("Idle")
					return
				end
				Events.OnServerCommand.Remove(onInternalServerCommand)
				Events.OnTick.Remove(playersAnimChecks)
			end
			Events.OnTick.Add(playersAnimChecks)
		end
	end
	Events.OnServerCommand.Add(onServerCommand)
end


end
Events.OnInitGlobalModData.Add(EarlyExitVehiclesSyncAndDamage)
