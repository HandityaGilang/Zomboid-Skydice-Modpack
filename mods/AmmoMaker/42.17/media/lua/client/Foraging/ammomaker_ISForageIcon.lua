--Ammo Maker by STIMP_TM - Temporary fix for foraging items from modules other than Base:

function ISForageIcon:doForage(_x, _y, _contextOption, _targetContainer)
	if _contextOption then _contextOption:hideAndChildren(); end;
	local targetSquare = getCell():getGridSquare(self.xCoord, self.yCoord, self.zCoord);
	if not targetSquare then return; end;

	--double clicking sends item to currently selected inventory in panel
	if self:getIsSeen() and self:getAlpha() > 0 then
		local targetContainer = _targetContainer or getPlayerInventory(self.player).inventory or self.character:getInventory();
		if targetContainer:isItemAllowed(self.itemObj) then
			if targetContainer and targetSquare and luautils.walkAdj(self.character, targetSquare) then
			    local itemDataList = {}
			    for i = 0, self.itemList:size() - 1 do
                    local item = self.itemList:get(i)
                    local data = { type = item:getFullType() }; --Ammo Maker fix: Using getFullType() instead of getType() to allow picking up foraging items from modules other than base
                    if instanceof(item, "Food") then
                        data.poisonPower = item:getPoisonPower();
                        data.poisonDetectionLevel = item:getPoisonDetectionLevel();
                    end
			        table.insert(itemDataList, data);
                end;
				ISTimedActionQueue.add(ISForageAction:new(self.character, self.iconID, itemDataList, targetContainer, self.itemType));
			end;
		end;
	else
		return false;
	end;
end