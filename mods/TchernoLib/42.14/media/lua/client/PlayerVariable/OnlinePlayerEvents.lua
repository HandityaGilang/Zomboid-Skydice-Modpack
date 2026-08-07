
require 'PlayerVariable/PlayerVariableShared'
PlaVar.onlinePlayers = {}

function PlaVar.surveyPlayers()
    local onlinePlayers = getOnlinePlayers()
    local newOnlinePlayers = {}
    if onlinePlayers then
        for i=0, onlinePlayers:size()-1 do
            --Tch: onlinePlayers:get(i) should always work from what I understand. but it does not. so we protect.
            local ok, isoPlayer = pcall(onlinePlayers.get, onlinePlayers, i)
            if not ok then break end
            if isoPlayer and not isoPlayer:isLocalPlayer() then
                newOnlinePlayers[i] = isoPlayer
                local op = PlaVar.onlinePlayers[i]
                if isoPlayer ~= op then
                    if PlaVar.Verbose then print("PlaVar.surveyPlayers update "..p2str(isoPlayer)) end
                    triggerEvent("OnOtherPlayerDetected",isoPlayer)
                end
            else
                newOnlinePlayers[i] = nil
                --if PlaVar.Verbose then print("PlaVar.updateOnlinePlayers nop "..p2str(isoPlayer)) end
            end
        end
    end
    
    PlaVar.onlinePlayers = newOnlinePlayers
end

--- install callbacks
if isClient() then
--all connections except those before we arrived are associated to OnMiniScoreboardUpdate trigger: awesome !
Events.OnMiniScoreboardUpdate.Add(PlaVar.surveyPlayers)
end
