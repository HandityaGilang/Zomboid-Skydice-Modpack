AE_Core = {}

-- Minimal stub for AE_Core to satisfy KittyMod require() checks
-- This is a compatibility stub for single-mod AEAPI architecture

-- Core functionality indicators
AE_Core.isInitialized = true
AE_Core.version = "1.0.0-AEAPI"

-- Basic functionality stub
function AE_Core.isAvailable()
    return true
end

-- Export for global access
_G.AE_Core = AE_Core

return AE_Core