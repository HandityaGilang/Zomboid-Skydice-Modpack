local TABAS_Utils = require("TABAS_Utils")
if not TABAS_Utils.DEBUG_ENABLE then return end

require "DebugUIs/TABAS_DebugUI"

local old_ISGeneralDebug_initialise = ISGeneralDebug.initialise
function ISGeneralDebug.initialise(self)
    old_ISGeneralDebug_initialise(self)
    self:registerPanel("TABAS", TABAS_DebugUI)
end