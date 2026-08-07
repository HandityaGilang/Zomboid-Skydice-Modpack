-- PIPPlacement.lua (SERVER) — enregistrement server-side des pipes posées.
-- Phase 1 : minimal (log + accroche). Phase 2 : enregistrement réseau (BFS, group ID, registry barrels).

require "PIP/PIPShared"

PIP = PIP or {}
PIP.Placement = PIP.Placement or {}

-- Appelé quand une pipe vient d'être posée (depuis le curseur en SP/host, ou via commande en MP).
function PIP.Placement.registerPipe(obj)
    if isClient() and not isServer() then return end
    if not (obj and obj.getSquare and obj:getSquare()) then return end
    local sq = obj:getSquare()
    PIP.dbg("registerPipe (server)", obj:getModData().PIP_pipeType, sq:getX(), sq:getY(), sq:getZ())
    if PIP.Network and PIP.Network.loadPipe then PIP.Network.loadPipe(obj) end
end

Events.OnGameStart.Add(function()
    PIP.refreshDebug()
    PIP.dbg("loaded v1.3.0. debug=" .. tostring(PIP.DEBUG))   -- gaté (silencieux en prod)
end)
