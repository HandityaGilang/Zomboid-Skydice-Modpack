local constants = require("dgmc_bolt_cutters_constants")
local logger = require("dgmc_bolt_cutters_logger")

local options = {}

---@class DGMCOption
---@field getter fun(): any
---@field cachedValue any
---@field listeners fun(any, any)[]
---@field isSandboxVar boolean

---@alias DGMCOptionRegistry { [string]: DGMCOption }

---@type DGMCOptionRegistry
local registry = {}

---@param valueName string
---@param getter any
---@param isSandboxVar boolean
local function registerOption(valueName, getter, isSandboxVar)
	registry[valueName] = { getter = getter, cachedValue = getter(), listeners = {}, isSandboxVar = isSandboxVar}
end

--- go through the registry and find any values that differ from our cached version
--- and notify any listeners of the new value
---@param isSandboxVar boolean
local function checkForUpdates(isSandboxVar)
	for _, option in pairs(registry) do
		if option.isSandboxVar == isSandboxVar then
			-- grab the value and see if it differs from ours
			local currentValue = option.getter()

			if option.cachedValue ~= currentValue then
				
				-- notify each listener of the new and old value
				for i = 1, #option.listeners do
					option.listeners[i](currentValue, option.cachedValue)
				end

				-- and lastly, update our cached version
				option.cachedValue = currentValue
			end
		end
	end
end

function options.registerSandboxVars()
	local SBV = SandboxVars[constants.module]

	if SBV == nil then
		logger.error("registerSandboxVars", "failed to get sandbox vars for %s", constants.module)
		return
	end

	local legacyStrength = -1
	for name, _ in pairs(SBV) do
		if name == "Minimum_Strength" then
			legacyStrength = SBV[name]
			logger.info("registerSandboxVars", "detected legacy strength value of %i", legacyStrength)
			SBV[name] = nil
		else
			registerOption(name, function() return SBV[name] end, true)
		end
	end

	if legacyStrength ~= -1 then
		SBV[constants.sandbox.easyStrengthReq] = math.max(legacyStrength - 2, 0)
		SBV[constants.sandbox.hardStrengthReq] = math.min(legacyStrength + 2, 10)
	end

	Events.EveryOneMinute.Add(function() checkForUpdates(true) end)
end

---@param modOptions PZAPI.ModOptions.Options
function options.registerModOptions(modOptions)
	for _, option in pairs(modOptions.dict) do
		---@diagnostic disable-next-line
		registerOption(option.id, function() return option:getValue() end, false)
	end

	modOptions.apply = function() checkForUpdates(false) end
end

--- it is a little extra overhead for sandbox vars, BUT it keeps everything uniform between sandbox and modoptions, which I like :)
---@param valueName string
---@return (fun(): any)
function options.obtainGetter(valueName)
	return registry[valueName].getter
end

---@param valueName string
---@return any
function options.getValue(valueName)
	return registry[valueName].cachedValue
end

---@param valueName string
---@param callback fun(any, any)
function options.addListener(valueName, callback)
	local option = registry[valueName]
	if option == nil then
		logger.error("addListener", "failed to get option %s", valueName)
		return
	end

	for i = 1, #option.listeners do
		if option.listeners[i] == callback then
			logger.error("addListener", "duplicate callback registered for %s", valueName)
		end
	end

	table.insert(option.listeners, callback)

	-- as a courtesy, execute the callback immediately with the current value
	local value = option.getter()
	callback(value, value)
end

---@param valueName string
---@param callback fun(any, any)
function options.removeListener(valueName, callback)
	local option = registry[valueName]
	if option == nil then
		logger.error("removeListener", "failed to get option %s", valueName)
		return
	end

	for i = 1, #option.listeners do
		if option.listeners[i] == callback then
			table.remove(option.listeners, i)
		end
	end

	logger.error("removeListener", "failed to find listener for %s", valueName)
end

return options