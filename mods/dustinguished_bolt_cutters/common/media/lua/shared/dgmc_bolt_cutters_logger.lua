local constants = require("dgmc_bolt_cutters_constants")

local infoString = "dgmc bolt cutters: (%s) INFO - %s"
local debugString = "dgmc bolt cutters: (%s) DEBUG - %s"
local errorString = "dgmc bolt cutters: (%s) ERROR - %s"

---@class DGMCLogger
local logger = {}

---@param func string
---@param text string
---@param ... any
function logger.info(func, text, ...)
	print(string.format(infoString, func, string.format(text, ...)))
end

---@param func string
---@param text string
---@param ... any
local function debug(func, text, ...)
	print(string.format(debugString, func, string.format(text, ...)))
end

local function doNothing()
end

---@param func string
---@param text string
---@param ... any
function logger.error(func, text, ...)
	print(string.format(errorString, func, string.format(text, ...)))
end

--- swapping to a function that does nothing makes each debug print call 2x faster
--- than an if check on the sandbox var and 3x faster than a getter call :)
---@param new boolean
---@param _old boolean
local function onDebugLoggingChange(new, _old)
	if new == true then
		logger.info("onDebugLoggingChange", "enabling debug logging")
		logger.debug = debug
	else
		logger.info("onDebugLoggingChange", "disabling debug logging")
		logger.debug = doNothing
	end
end

---@param _newGame boolean
local function onInitGlobalModData(_newGame)
	local options = require("dgmc_bolt_cutters_options")
	options.registerSandboxVars()
	options.addListener(constants.sandbox.debugLogging, onDebugLoggingChange)
end
Events.OnInitGlobalModData.Add(onInitGlobalModData)

--- default to debug logging being on until we get the sandbox vars
logger.debug = debug

return logger