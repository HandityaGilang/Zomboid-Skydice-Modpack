require('TimedActions/ISBaseTimedAction');
require('luautils');

RepairWallCrackAction = ISBaseTimedAction:derive("RepairWallCrackAction");

local function predicateNotBroken(item)
    return not item:isBroken()
end

function RepairWallCrackAction:isValid()
	local playerInv = self.character:getInventory()
	local statusTool = false
	local tools = {"HandShovel", "MasonsTrowel", "PlasterTrowel", "MasonsTrowel_Wood"}
	for _, t in ipairs(tools) do
        if playerInv:containsTypeEvalRecurse("Base."..t, predicateNotBroken) then
            statusTool = true
            break
        end
    end
return ISBuildMenu.cheat or (playerInv:containsTypeRecurse("BucketPlasterFull") and statusTool) or (playerInv:containsTypeRecurse("BucketCarvedPlasterFull") and statusTool)
end

function RepairWallCrackAction:waitToStart()
	self.character:faceLocation(self.square:getX(), self.square:getY())
	return self.character:shouldBeTurning()
end

function RepairWallCrackAction:update()
	self.character:faceLocation(self.square:getX(), self.square:getY())
    self.character:setMetabolicTarget(Metabolics.MediumWork);
end

function RepairWallCrackAction:start()
	self.sound = self.character:playSound("Plastering")
	local primaryItem = self.character:getPrimaryHandItem()
	local tool = primaryItem and primaryItem:getType() or "none"
	local hasTools = {
		["HandShovel"]=true,
		["MasonsTrowel"]=true,
		["PlasterTrowel"]=true,
		["MasonsTrowel_Wood"]=true }

	if hasTools[tool] then
		self:setActionAnim("Loot")
		self.character:SetVariable("LootPosition", "Mid")
		self:setOverrideHandModels("HandShovel", nil);
	else
		self:setActionAnim("Loot");
		self.character:SetVariable("LootPosition", "Low");
		self:setOverrideHandModels(nil, "HandShovel");
	end
	self.character:reportEvent("EventRepairWallCrack");
end

function RepairWallCrackAction:stop()
	if self.sound then self.character:stopOrTriggerSound(self.sound) end
    ISBaseTimedAction.stop(self);
end

function RepairWallCrackAction:perform()
    if self.sound then self.character:stopOrTriggerSound(self.sound) end
    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self)
end

function RepairWallCrackAction:complete()
    local sq = self.square
    if not sq then return false end

    -- Remove wall crack attached sprites from all objects on the square
    for i = 0, sq:getObjects():size() - 1 do
        local object = sq:getObjects():get(i)
        if object then
            local attached = object:getAttachedAnimSprite()
            if attached and attached:size() > 0 then
                local removedAny = false

                for n = attached:size() - 1, 0, -1 do
                    local sprite = attached:get(n)
                    if sprite and sprite:getParentSprite() then
                        local name = sprite:getParentSprite():getName()
                        if name and luautils.stringStarts(name, "d_wallcrack") then
                            object:RemoveAttachedAnim(n)
                            removedAny = true
                        end
                    end
                end

                if removedAny then
                    object:transmitUpdatedSpriteToClients()
                end
            end
        end
    end

    -- Consume one use of the plaster bucket
    local bucket = self.character:getInventory():getFirstTypeRecurse("BucketPlasterFull") or
                   self.character:getInventory():getFirstTypeRecurse("BucketCarvedPlasterFull")
    if bucket and instanceof(bucket, "DrainableComboItem") then
        bucket:Use()
        if bucket.syncItemFields then
            bucket:syncItemFields()
        end
    end

    return true
end


function RepairWallCrackAction:new(character, square, plasterBucket)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character;
	o.plasterBucket = plasterBucket;
	o.square = square;
	o.stopOnWalk = true;
	o.stopOnRun = true;
	o.maxTime =  100;
    o.caloriesModifier = 8;
	return o;
end
