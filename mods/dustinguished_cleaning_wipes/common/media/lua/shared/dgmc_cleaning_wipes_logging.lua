local infoString = "dgmc cleaning wipes: (%s) INFO - %s"
local debugString = "dgmc cleaning wipes: (%s) DEBUG - %s"
local errorString = "dgmc cleaning wipes: (%s) ERROR - %s"

---@class DGMCLogger
local logger = {}
local SBV = SandboxVars.DGMC_Cleaning_Wipes

---@param func string
---@param text string
---@param ... any
function logger.info(func, text, ...)
	print(string.format(infoString, func, string.format(text, ...)))
end

---@param func string
---@param text string
---@param ... any
function logger.debug(func, text, ...)
	if SBV.Debug_Logging == true then
		print(string.format(debugString, func, string.format(text, ...)))
	end
end

---@param func string
---@param text string
---@param ... any
function logger.error(func, text, ...)
	print(string.format(errorString, func, string.format(text, ...)))
end

return logger