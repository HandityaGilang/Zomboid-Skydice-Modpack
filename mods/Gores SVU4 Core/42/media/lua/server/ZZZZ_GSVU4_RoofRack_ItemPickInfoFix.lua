--========================================================
-- Gore's SVU4 Core - Roof Rack ItemPickInfo Server Safety Pass
--
-- Shared Lua performs the early empty distribution registration. This server
-- file deliberately only re-runs the idempotent helper so dedicated servers get
-- the same valid GSVU4RoofRack container ID without adding loot.
--========================================================

GSVU4 = GSVU4 or {}
GSVU4.RoofRack = GSVU4.RoofRack or {}

if GSVU4.RoofRack.RegisterEmptyItemPickInfo then
    GSVU4.RoofRack.RegisterEmptyItemPickInfo()
end
