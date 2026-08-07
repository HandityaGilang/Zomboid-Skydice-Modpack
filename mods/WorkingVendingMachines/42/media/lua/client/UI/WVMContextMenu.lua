WVM = {};
WVM.vendingContextMenu = function(_player, context, worldobjects)
	local maxStock = 25; -- maximum vending machine stock
	local stuckStockProbInv = 25; -- reciprocal of the probability to find stuck stock in new game
	local stuckStockGetProbInv = 4;  -- reciprocal of the probability to get stuck stock

    local player  = getSpecificPlayer(_player);
	local object  = nil;
	local objType = nil;
	
	local objFound = false;
	for _,wObj in ipairs(worldobjects) do -- find object to interact with; code support for controllers
		local square = wObj:getSquare()
		if square then
			for i=1,square:getObjects():size() do
				object = square:getObjects():get(i-1)

				if object:getContainer() then
					objType = object:getContainer():getType():gsub("vending", "");
				end
				
				if (objType == "pop" or objType == "snack") then
					objFound = true;
					break
				end
			end
		end
		if objFound == true then
			break
		end
	end
	
	if objFound == false then
		return
	end

	local objectData = object:getModData();
	-- initialise vending machine object properties --
	function fix(object)
        objectData.WVM_stock = nil;
		objectData.WVM_stuckStock = nil;
		objectData.WVM_cash = nil;
    end
	
	if (objectData.WVM_stock == nil or objectData.WVM_stuckStock == nil or objectData.WVM_cash == nil) then
        objectData.WVM_stock = ZombRand(maxStock+1);
		if (ZombRand(stuckStockProbInv) == 0 and objType == "snack") then
			objectData.WVM_stuckStock = 1;
		else
			objectData.WVM_stuckStock = 0;
		end
		objectData.WVM_cash = math.max(maxStock-objectData.WVM_stock+ZombRand(9)-4,0);
        object:transmitModData();
    end

	-- check for power --
    if not ((SandboxVars.ElecShutModifier > -1 and GameTime:getInstance():getNightsSurvived() < SandboxVars.ElecShutModifier) or object:getSquare():haveElectricity()) then
        player:Say(getText("ContextMenu_WVMNoPower"));
        return;
    end    
	
	-- check for stuck snack --
	if objectData.WVM_stuckStock > 0 then
		--player:Say(getText("ContextMenu_WVMSnackInChute"));
		--context:addOption(getText("ContextMenu_WVMStrikeMachine"), player, WVM.strikeMachine, object, objType, stuckStockGetProbInv);
	end
	
	-- if machine empty or player has no money, show nothing --
    if objectData.WVM_stock == 0 then
        player:Say(getText("ContextMenu_WVMSoldOut"));
	elseif not player:getInventory():contains("Money") then
		if objType == "pop" then
			player:Say(getText("ContextMenu_WVMNoMoneyDrink"));
		elseif objType == "snack" then
			player:Say(getText("ContextMenu_WVMNoMoneySnack"));
		end		
	else
		if objType == "pop" then
			context:addOption(getText("ContextMenu_WVMBuyDrink"), player, WVM.buyProduct, object, objType);
		elseif objType == "snack" then
			context:addOption(getText("ContextMenu_WVMBuySnack"), player, WVM.buyProduct, object, objType);
		end
    end
end

WVM.buyProduct = function(player, object, objType)
	luautils.walkAdj(player, object:getSquare(), false);
	ISTimedActionQueue.add(WVMBuyItem:new(player, object, objType, 400))
end

WVM.strikeMachine = function(player, object, objType, stuckStockGetProbInv)
	-- walk over to and face machine --
    luautils.walkAdj(player, object:getSquare(), false);
    player:faceThisObject(object);
	
	-- strike machine --
	player:playSound("VendingSoundStrike");
	
	-- choose product randomly for now --
	if ZombRand(stuckStockGetProbInv) == 0 then
		if objType == "pop" then
			items = {"Base.Pop", "Base.Pop2", "Base.Pop3", "Base.PopBottle", "Base.WaterBottle"};
			player:playSound("VendingSoundDrink");
		elseif objType == "snack" then
			items = {"Base.Crisps", "Base.Crisps2", "Base.Crisps3", "Base.Crisps4", "Base.CookieChocolateChip", "Base.CandyPackage", "Base.Jujubes", "Base.QuaggaCakes", "Base.LicoriceRed", "Base.SnoGlobes"};
			player:playSound("VendingSoundSnack");
		end
		object:getContainer():AddItem(items[ZombRand(#items)+1]);
		
		-- decrease stuck stock --
		local objectData = object:getModData();
		objectData.WVM_stuckStock = objectData.WVM_stuckStock-1;
		object:transmitModData();
	end
end

Events.OnPreFillWorldObjectContextMenu.Add(WVM.vendingContextMenu);