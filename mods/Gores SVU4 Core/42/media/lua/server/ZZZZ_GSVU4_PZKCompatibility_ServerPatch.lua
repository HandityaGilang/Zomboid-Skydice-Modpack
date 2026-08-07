--========================================================
-- Gore's SVU4 Core - PZK / ATA2 Compatibility Server Patch
--========================================================

if isClient() then return end

require "GoresSVU4Core/GSVU4_PZKCompatibility"

-- This file is intentionally light.  The main server module calls the helper
-- directly after the matching require has been added.  Keeping this file means
-- the helper is also loaded server-side even if file ordering changes later.
