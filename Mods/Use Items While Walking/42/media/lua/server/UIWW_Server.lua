-- Use Items While Walking (B42) By Jeilko

if isClient() then return end
if not isServer() then return end

local UIWW_Server = {}

local function isAmmoBox(item)
	if not item or type(item) ~= "userdata" then return false end
	local okCat, cat = pcall(function() return item.getDisplayCategory and item:getDisplayCategory() end)
	if not okCat or cat ~= "Ammo" then return false end

	local okType, tp = pcall(function() return item.getType and item:getType() end)
	if okType and tp and tp:find("Box", 1, true) then return true end

	local okFull, ft = pcall(function() return item.getFullType and item:getFullType() end)
	if okFull and ft and ft:find("Box", 1, true) then return true end

	return false
end

local function patchTimedActionNew(globalName, requirePath)
	pcall(require, requirePath)
	local klass = _G and _G[globalName]
	if type(klass) ~= "table" or type(klass.new) ~= "function" then return end
	if klass.__UIWWPatchedServer then return end

	if globalName == "ISWearClothing" then
		klass.isStopOnWalk = function(item) return false end
	end

	local old_new = klass.new
	klass.new = function(self, character, ...)
		local o = old_new(self, character, ...)
		if type(o) == "table" then
			o.stopOnWalk = false
			o.stopOnRun = true
		end
		return o
	end

	klass.__UIWWPatchedServer = true
end

local function patchUseItemAmmoBox()
	pcall(require, "TimedActions/ISUseItemAction")
	local klass = _G and _G.ISUseItemAction
	if type(klass) ~= "table" or type(klass.new) ~= "function" then return end
	if klass.__UIWWAmmoPatchedServer then return end

	local old_new = klass.new
	klass.new = function(self, character, item, ...)
		local o = old_new(self, character, item, ...)
		if type(o) == "table" and isAmmoBox(item) then
			o.stopOnWalk = false
			o.stopOnRun  = true
			o.__UIWWAmmoBox = true
		end
		return o
	end

	klass.__UIWWAmmoPatchedServer = true
end

function UIWW_Server.TryPatch()
	patchTimedActionNew("ISWearClothing", "TimedActions/ISWearClothing")
	patchTimedActionNew("ISUnequipAction", "TimedActions/ISUnequipAction")
	patchTimedActionNew("ISReadABook", "TimedActions/ISReadABook")
	patchTimedActionNew("ISHandcraftAction", "Entity/TimedActions/ISHandcraftAction")
	patchTimedActionNew("ISCraftAction", "TimedActions/ISCraftAction")
	patchUseItemAmmoBox()
end

UIWW_Server.TryPatch()

Events.OnGameStart.Add(function()
	UIWW_Server.TryPatch()
end)

return UIWW_Server
