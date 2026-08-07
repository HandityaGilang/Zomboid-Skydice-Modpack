ISRefillFromLargePropaneTank = ISBaseTimedAction:derive("ISRefillFromLargePropaneTank")

function ISRefillFromLargePropaneTank:isValid()
	if isClient() and not self.character:getInventory():containsID(self.propaneTank:getID()) then
		return false
	elseif not self.character:getInventory():contains(self.propaneTank) then
		return false
	end

	if self.largePropaneTank ~= MoreCarFeatures.findWholeLargePropaneTank(self.name, self.square:getX(), self.square:getY(), self.square:getZ()) then
		return false
	end

	local square = luautils.getCorrectSquareForWall(self.character, self.square)
	local diffX = math.abs(square:getX() + 0.5 - self.character:getX())
	local diffY = math.abs(square:getY() + 0.5 - self.character:getY())
	if not (diffX <= 1.6 and diffY <= 1.6 and self.character:getSquare():canReachTo(square)) then
		return false
	end

	return self.largePropaneTank:getModData().MCFPropaneUnits > 0
end

function ISRefillFromLargePropaneTank:waitToStart()
	self.character:faceLocation(self.square:getX(), self.square:getY())
	return self.character:shouldBeTurning()
end

function ISRefillFromLargePropaneTank:start()
	self:setActionAnim("fill_container_tap")
	self:setOverrideHandModels(self.character:getPrimaryHandItem(), nil)
end

function ISRefillFromLargePropaneTank:update()
	self.character:faceLocation(self.square:getX(), self.square:getY())

	if isClient() then
		self.propaneTank:setJobDelta(self:getJobDelta())
	else
		local PropaneUnits1 = self.playerTankStart + (self.playerTankTarget - self.playerTankStart) * self:getJobDelta()
		if PropaneUnits1 ~= self.amountSent then
			self.propaneTank:setCurrentUses(PropaneUnits1*250)
			self.amountSent = PropaneUnits1
		end
		local PropaneUnits2 = self.worldTankStart + (self.worldTankTarget - self.worldTankStart) * self:getJobDelta()
		self.largePropaneTank:getModData().MCFPropaneUnits = PropaneUnits2*250
	end

	self.character:setMetabolicTarget(Metabolics.HeavyDomestic)
end

function ISRefillFromLargePropaneTank:serverStop()
	if not self.propaneTank or not self.largePropaneTank then
		return
	end

    local PropaneUnits1 = self.worldTankStart + (self.worldTankTarget - self.worldTankStart) * self.netAction:getProgress()
    self.largePropaneTank:getModData().MCFPropaneUnits = PropaneUnits1*250
    self.largePropaneTank:transmitModData()
    local PropaneUnits2 = self.playerTankStart + (self.playerTankTarget - self.playerTankStart) * self.netAction:getProgress()
    self.propaneTank:setCurrentUses(PropaneUnits2*250)
	self.propaneTank:UseAndSync()
end

function ISRefillFromLargePropaneTank:stop()
	if isClient() then
		self.propaneTank:setJobDelta(0.0)
	end

	ISBaseTimedAction.stop(self)
end

function ISRefillFromLargePropaneTank:perform()
	if isClient() then
		self.propaneTank:setJobDelta(0.0)
	end

	ISBaseTimedAction.perform(self)
end

function ISRefillFromLargePropaneTank:complete()
	if not self.propaneTank or not self.largePropaneTank then
		return false
	end

	self.propaneTank:setCurrentUses(self.playerTankTarget*250)
	self.propaneTank:UseAndSync()
    self.largePropaneTank:getModData().MCFPropaneUnits = self.worldTankTarget*250
    self.largePropaneTank:transmitModData()

	return true
end

function ISRefillFromLargePropaneTank:getDuration()
	if not self.propaneTank or not self.largePropaneTank then
		return 0
	end

	if not self.largePropaneTank:getModData().MCFPropaneUnits then
		self.largePropaneTank:getModData().MCFPropaneUnits = self.initialSetAmount
		if isServer() then
			self.largePropaneTank:transmitModData()
		end
	end

    self.playerTankStart = self.propaneTank:getCurrentUses()/250
	self.worldTankStart = self.largePropaneTank:getModData().MCFPropaneUnits/250
	local worldTankUnitsAvail = self.worldTankStart
	local playerTankUnitsFree = self.propaneTank:getMaxUses()/250 - self.playerTankStart
	local takeUnits = math.min(playerTankUnitsFree, worldTankUnitsAvail)
	self.playerTankTarget = self.playerTankStart + takeUnits
	self.worldTankTarget = self.worldTankStart - takeUnits
	self.amountSent = self.playerTankStart

	return takeUnits * 50
end

function ISRefillFromLargePropaneTank:new(character, largePropaneTank, propaneTank, initialSetAmount)
	local o = ISBaseTimedAction.new(self, character)
	o.largePropaneTank = largePropaneTank
	o.square = largePropaneTank:getSquare()
	o.name = largePropaneTank:getTextureName()
	o.propaneTank = propaneTank
	o.stopOnWalk = true
	o.stopOnRun = true
	o.initialSetAmount = initialSetAmount
	o.maxTime = o:getDuration()
	return o
end


MoreCarFeatures = MoreCarFeatures or {}
--Start counting from the South West corner to other end, the long way, then back to the original end and then back to the other end, again
--The ladder is the main point to reflect off of
--	fossoil,	80 through 87,		ladder west
--	fossoil,	88 through 95,		ladder east
--	fossoil,	96 through 103,		ladder north
--	fossoil,	104 through 111,	ladder south
--	gas2go,		64 through 71,		ladder west
--	gas2go,		72 through 79,		ladder east
--	gas2go,		80 through 87,		ladder north
--	gas2go,		88 through 95,		ladder south
--	industry,	64 through 71,		ladder west
--	industry,	280 through 287,	ladder east
--	industry,	288 through 295,	ladder north
--	industry,	296 through 303,	ladder south

local function checkWholeLargePropaneTank(rangetx, rangety, x, y, z, possibleStringEnds, stringStart)
	local cell = getCell()
	local object
	local txCountDir, tyCountDir = 1, 1
	if rangetx > 0 then
		txCountDir = -1
	end
	if rangety > 0 then
		tyCountDir = -1
	end

	for tx=rangetx, 0, txCountDir do
		for ty=rangety, 0, tyCountDir do
			local tsquare = cell:getOrCreateGridSquare(x + tx, y + ty, z)
			if not tsquare then return nil end
			local hasPropaneTankPart = false
			for _, stringEnd in ipairs(possibleStringEnds) do
				local tobject = tsquare:getObjectWithSprite(stringStart .. stringEnd)
				if tobject then
					if tx == 0 and ty == 0 then
						object = tobject
					end
					hasPropaneTankPart = true
					break
				end
			end
			if not hasPropaneTankPart then return nil end
		end
	end

	return object
end

function MoreCarFeatures.findWholeLargePropaneTank(name, x, y, z)
	if luautils.stringStarts(name, "location_shop_fossoil_01") then
		local ladder

		if luautils.stringEnds(name, "_80") then
			ladder = {0, -1}
		elseif luautils.stringEnds(name, "_81") then
			ladder = {-1, -1}
		elseif luautils.stringEnds(name, "_82") then
			ladder = {-2, -1}
		elseif luautils.stringEnds(name, "_83") then
			ladder = {-3, -1}
		elseif luautils.stringEnds(name, "_84") then
			ladder = {0, 0}
		elseif luautils.stringEnds(name, "_85") then
			ladder = {-1, 0}
		elseif luautils.stringEnds(name, "_86") then
			ladder = {-2, 0}
		elseif luautils.stringEnds(name, "_87") then
			ladder = {-3, 0}
		end
		if ladder then
			return checkWholeLargePropaneTank(3, 1, x + ladder[1], y + ladder[2], z, {"_80", "_81", "_82", "_83", "_84", "_85", "_86", "_87"}, "location_shop_fossoil_01")
		end

		if luautils.stringEnds(name, "_88") then
			ladder = {3, -1}
		elseif luautils.stringEnds(name, "_89") then
			ladder = {2, -1}
		elseif luautils.stringEnds(name, "_90") then
			ladder = {1, -1}
		elseif luautils.stringEnds(name, "_91") then
			ladder = {0, -1}
		elseif luautils.stringEnds(name, "_92") then
			ladder = {3, 0}
		elseif luautils.stringEnds(name, "_93") then
			ladder = {2, 0}
		elseif luautils.stringEnds(name, "_94") then
			ladder = {1, 0}
		elseif luautils.stringEnds(name, "_95") then
			ladder = {0, 0}
		end
		if ladder then
			return checkWholeLargePropaneTank(-3, 1, x + ladder[1], y + ladder[2], z, {"_88", "_89", "_90", "_91", "_92", "_93", "_94", "_95"}, "location_shop_fossoil_01")
		end

		if luautils.stringEnds(name, "_96") then
			ladder = {3, -1}
		elseif luautils.stringEnds(name, "_97") then
			ladder = {2, -1}
		elseif luautils.stringEnds(name, "_98") then
			ladder = {1, -1}
		elseif luautils.stringEnds(name, "_99") then
			ladder = {0, -1}
		elseif luautils.stringEnds(name, "_100") then
			ladder = {3, 0}
		elseif luautils.stringEnds(name, "_101") then
			ladder = {2, 0}
		elseif luautils.stringEnds(name, "_102") then
			ladder = {1, 0}
		elseif luautils.stringEnds(name, "_103") then
			ladder = {0, 0}
		end
		if ladder then
			return checkWholeLargePropaneTank(1, 3, x + ladder[1], y + ladder[2], z, {"_96", "_97", "_98", "_99", "_100", "_101", "_102", "_103"}, "location_shop_fossoil_01")
		end

		if luautils.stringEnds(name, "_104") then
			ladder = {3, -1}
		elseif luautils.stringEnds(name, "_105") then
			ladder = {2, -1}
		elseif luautils.stringEnds(name, "_106") then
			ladder = {1, -1}
		elseif luautils.stringEnds(name, "_107") then
			ladder = {0, -1}
		elseif luautils.stringEnds(name, "_108") then
			ladder = {3, 0}
		elseif luautils.stringEnds(name, "_109") then
			ladder = {2, 0}
		elseif luautils.stringEnds(name, "_110") then
			ladder = {1, 0}
		elseif luautils.stringEnds(name, "_111") then
			ladder = {0, 0}
		end
		if ladder then
			return checkWholeLargePropaneTank(1, -3, x + ladder[1], y + ladder[2], z, {"_104", "_105", "_106", "_107", "_108", "_109", "_110", "_111"}, "location_shop_fossoil_01")
		end

	elseif luautils.stringStarts(name, "location_shop_gas2go_01") then
		local ladder

		if luautils.stringEnds(name, "_64") then
			ladder = {0, -1}
		elseif luautils.stringEnds(name, "_65") then
			ladder = {-1, -1}
		elseif luautils.stringEnds(name, "_66") then
			ladder = {-2, -1}
		elseif luautils.stringEnds(name, "_67") then
			ladder = {-3, -1}
		elseif luautils.stringEnds(name, "_68") then
			ladder = {0, 0}
		elseif luautils.stringEnds(name, "_69") then
			ladder = {-1, 0}
		elseif luautils.stringEnds(name, "_70") then
			ladder = {-2, 0}
		elseif luautils.stringEnds(name, "_71") then
			ladder = {-3, 0}
		end
		if ladder then
			return checkWholeLargePropaneTank(3, 1, x + ladder[1], y + ladder[2], z, {"_64", "_65", "_66", "_67", "_68", "_69", "_70", "_71"}, "location_shop_gas2go_01")
		end

		if luautils.stringEnds(name, "_72") then
			ladder = {3, -1}
		elseif luautils.stringEnds(name, "_73") then
			ladder = {2, -1}
		elseif luautils.stringEnds(name, "_74") then
			ladder = {1, -1}
		elseif luautils.stringEnds(name, "_75") then
			ladder = {0, -1}
		elseif luautils.stringEnds(name, "_76") then
			ladder = {3, 0}
		elseif luautils.stringEnds(name, "_77") then
			ladder = {2, 0}
		elseif luautils.stringEnds(name, "_78") then
			ladder = {1, 0}
		elseif luautils.stringEnds(name, "_79") then
			ladder = {0, 0}
		end
		if ladder then
			return checkWholeLargePropaneTank(-3, 1, x + ladder[1], y + ladder[2], z, {"_72", "_73", "_74", "_75", "_76", "_77", "_78", "_79"}, "location_shop_gas2go_01")
		end

		if luautils.stringEnds(name, "_80") then
			ladder = {3, -1}
		elseif luautils.stringEnds(name, "_81") then
			ladder = {2, -1}
		elseif luautils.stringEnds(name, "_82") then
			ladder = {1, -1}
		elseif luautils.stringEnds(name, "_83") then
			ladder = {0, -1}
		elseif luautils.stringEnds(name, "_84") then
			ladder = {3, 0}
		elseif luautils.stringEnds(name, "_85") then
			ladder = {2, 0}
		elseif luautils.stringEnds(name, "_86") then
			ladder = {1, 0}
		elseif luautils.stringEnds(name, "_87") then
			ladder = {0, 0}
		end
		if ladder then
			return checkWholeLargePropaneTank(1, 3, x + ladder[1], y + ladder[2], z, {"_80", "_81", "_82", "_83", "_84", "_85", "_86", "_87"}, "location_shop_gas2go_01")
		end

		if luautils.stringEnds(name, "_88") then
			ladder = {3, -1}
		elseif luautils.stringEnds(name, "_89") then
			ladder = {2, -1}
		elseif luautils.stringEnds(name, "_90") then
			ladder = {1, -1}
		elseif luautils.stringEnds(name, "_91") then
			ladder = {0, -1}
		elseif luautils.stringEnds(name, "_92") then
			ladder = {3, 0}
		elseif luautils.stringEnds(name, "_93") then
			ladder = {2, 0}
		elseif luautils.stringEnds(name, "_94") then
			ladder = {1, 0}
		elseif luautils.stringEnds(name, "_95") then
			ladder = {0, 0}
		end
		if ladder then
			return checkWholeLargePropaneTank(1, -3, x + ladder[1], y + ladder[2], z, {"_88", "_89", "_90", "_91", "_92", "_93", "_94", "_95"}, "location_shop_gas2go_01")
		end

	elseif luautils.stringStarts(name, "industry_02") then
		local ladder

		if luautils.stringEnds(name, "_64") then
			ladder = {0, -1}
		elseif luautils.stringEnds(name, "_65") then
			ladder = {-1, -1}
		elseif luautils.stringEnds(name, "_66") then
			ladder = {-2, -1}
		elseif luautils.stringEnds(name, "_67") then
			ladder = {-3, -1}
		elseif luautils.stringEnds(name, "_68") then
			ladder = {0, 0}
		elseif luautils.stringEnds(name, "_69") then
			ladder = {-1, 0}
		elseif luautils.stringEnds(name, "_70") then
			ladder = {-2, 0}
		elseif luautils.stringEnds(name, "_71") then
			ladder = {-3, 0}
		end
		if ladder then
			return checkWholeLargePropaneTank(3, 1, x + ladder[1], y + ladder[2], z, {"_64", "_65", "_66", "_67", "_68", "_69", "_70", "_71"}, "industry_02")
		end

		if luautils.stringEnds(name, "_280") then
			ladder = {3, -1}
		elseif luautils.stringEnds(name, "_281") then
			ladder = {2, -1}
		elseif luautils.stringEnds(name, "_282") then
			ladder = {1, -1}
		elseif luautils.stringEnds(name, "_283") then
			ladder = {0, -1}
		elseif luautils.stringEnds(name, "_284") then
			ladder = {3, 0}
		elseif luautils.stringEnds(name, "_285") then
			ladder = {2, 0}
		elseif luautils.stringEnds(name, "_286") then
			ladder = {1, 0}
		elseif luautils.stringEnds(name, "_287") then
			ladder = {0, 0}
		end
		if ladder then
			return checkWholeLargePropaneTank(-3, 1, x + ladder[1], y + ladder[2], z, {"_280", "_281", "_282", "_283", "_284", "_285", "_286", "_287"}, "industry_02")
		end

		if luautils.stringEnds(name, "_288") then
			ladder = {3, -1}
		elseif luautils.stringEnds(name, "_289") then
			ladder = {2, -1}
		elseif luautils.stringEnds(name, "_290") then
			ladder = {1, -1}
		elseif luautils.stringEnds(name, "_291") then
			ladder = {0, -1}
		elseif luautils.stringEnds(name, "_292") then
			ladder = {3, 0}
		elseif luautils.stringEnds(name, "_293") then
			ladder = {2, 0}
		elseif luautils.stringEnds(name, "_294") then
			ladder = {1, 0}
		elseif luautils.stringEnds(name, "_295") then
			ladder = {0, 0}
		end
		if ladder then
			return checkWholeLargePropaneTank(1, 3, x + ladder[1], y + ladder[2], z, {"_288", "_289", "_290", "_291", "_292", "_293", "_294", "_295"}, "industry_02")
		end

		if luautils.stringEnds(name, "_296") then
			ladder = {3, -1}
		elseif luautils.stringEnds(name, "_297") then
			ladder = {2, -1}
		elseif luautils.stringEnds(name, "_298") then
			ladder = {1, -1}
		elseif luautils.stringEnds(name, "_299") then
			ladder = {0, -1}
		elseif luautils.stringEnds(name, "_200") then
			ladder = {3, 0}
		elseif luautils.stringEnds(name, "_201") then
			ladder = {2, 0}
		elseif luautils.stringEnds(name, "_202") then
			ladder = {1, 0}
		elseif luautils.stringEnds(name, "_203") then
			ladder = {0, 0}
		end
		if ladder then
			return checkWholeLargePropaneTank(1, -3, x + ladder[1], y + ladder[2], z, {"_296", "_297", "_298", "_299", "_200", "_201", "_202", "_203"}, "industry_02")
		end

	end

	return nil
end