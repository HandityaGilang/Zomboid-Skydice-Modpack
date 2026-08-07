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
			    local itemTypeList = {}
			    for i = 0, self.itemList:size() - 1 do
			        table.insert(itemTypeList, self.itemList:get(i):getFullType());
                end;
				ISTimedActionQueue.add(ISForageAction:new(self.character, self.iconID, itemTypeList, targetContainer, self.itemType));
			end;
		end;
	else
		return false;
	end;
end