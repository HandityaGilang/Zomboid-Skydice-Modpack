require "TimedActions/ISBaseTimedAction"

WVMBuyItem = ISBaseTimedAction:derive("WVMBuyItem");

function WVMBuyItem:isValid()
	return true
end

function WVMBuyItem:waitToStart()
	self.character:faceThisObject(self.object)
	return self.character:shouldBeTurning()
end

function WVMBuyItem:update()
	self.character:faceThisObject(self.object)
	if self.numCoins < 4 and not self.character:getEmitter():isPlaying(self.insertCoinSound) then
        self.character:getEmitter():playSound(self.insertCoinSound);
		self.numCoins = self.numCoins + 1;
	elseif self.numCoins == 4 and not self.character:getEmitter():isPlaying(self.insertCoinSound) then
		self.character:getEmitter():playSound(self.vendingSound);
		self.numCoins = self.numCoins + 1;
    end
end

function WVMBuyItem:start()
	-- insert cash --
	self.character:getInventory():RemoveOneOf("Base.Money");
	-- animate --
	self:setActionAnim("ExamineVehicle")
end

function WVMBuyItem:stop()
	-- if interrupted, return cash --
	local newVendItem = self.object:getContainer():AddItem("Base.Money");
	if isClient() then
		self.object:getContainer():addItemOnServer(newVendItem);
	end
	self.character:getEmitter():playSound(self.returnCoinSound);
    ISBaseTimedAction.stop(self);
end

function WVMBuyItem:perform()
	-- play vending sound if not yet triggered --
	if self.numCoins < 4 then
		self.character:getEmitter():playSound(self.vendingSound);
	end

	-- choose product randomly for now --
	local items = {};
	if self.objType == "pop" then
		items = {"Base.SodaCan", "Base.PopBottle", "Base.WaterBottle"};
	elseif self.objType == "snack" then
		items = {"Base.Crisps", "Base.Crisps2", "Base.Crisps3", "Base.Crisps4", "Base.CookieChocolateChip", "Base.CandyPackage", "Base.Jujubes", "Base.QuaggaCakes", "Base.LicoriceRed", "Base.SnoGlobes","Base.TortillaChips","Base.CandyGummyfish","Base.Chocolate_SnikSnak"};
	end
	local newVendItem = self.object:getContainer():AddItem(items[ZombRand(#items)+1]);
	if isClient() then
		self.object:getContainer():addItemOnServer(newVendItem);
	end
    	
	-- decrease stock and increase cash --
    local objectData = self.object:getModData();
    objectData.WVM_stock = objectData.WVM_stock-1;
	objectData.WVM_cash  = objectData.WVM_cash+1;
    self.object:transmitModData();

    -- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end

function WVMBuyItem:new(character, object, objType, time)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character;
	o.object = object;
	o.objType = objType;
	o.stopOnWalk = true;
	o.stopOnRun = true;
	o.maxTime = time;
	
	o.numCoins = 0;
	o.insertCoinSound = "VendingSoundInsertCoin";
	o.returnCoinSound = "VendingSoundReturnCoin";
	if o.objType == "pop" then
		o.vendingSound = "VendingSoundDrink";
	elseif o.objType == "snack" then
		o.vendingSound = "VendingSoundSnack";
	end
	
	return o;
end
