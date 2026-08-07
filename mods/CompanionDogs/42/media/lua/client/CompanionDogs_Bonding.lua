local CD = CompanionDogs

local wasAsleep = {}
local sleptNear = {}

local function onPlayerUpdate(player)
    if not player then return end
    if not CD.bondingEnabled() then return end
    local idx = player:getPlayerNum()
    local asleep = player:isAsleep()
    local prev = wasAsleep[idx]

    if asleep and not prev then
        sleptNear[idx] = CD.findNearbyCompanion(player, CD.sleepNearRadius())
    elseif prev and not asleep then
        if sleptNear[idx] then
            CD.relieveMood(player, CD.sleepMoodRelief())
            -- Alem do alivio pontual, abre a janela temporizada "Bem Descansado" (calma + descanso por algumas horas).
            if CD.restedBuffEnabled and CD.startRestedBuff and CD.restedBuffEnabled() then CD.startRestedBuff(player) end
            HaloTextHelper.addGoodText(player, getText("IGUI_PD_SleptWithDog", CD.breedNoun(sleptNear[idx])))
        end
        sleptNear[idx] = nil
    end

    wasAsleep[idx] = asleep
end

if isClient() or not isServer() then
    Events.OnPlayerUpdate.Add(onPlayerUpdate)
end
