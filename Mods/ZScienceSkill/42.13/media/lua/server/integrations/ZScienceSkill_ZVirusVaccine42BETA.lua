local LabAutopsyLogic = require 'HealthSystem/LabAutopsyLogic_Server'
if not LabAutopsyLogic then return end

zdk.hook({
    [LabAutopsyLogic] = { -- XXX hook the required object, not declared as global
        ProcessAutopsy = function(orig, player, ...)
            local medXpBefore = nil
            if player and player.getXp then
                medXpBefore = player:getXp():getXP(Perks.Doctor)
            end

            local result = orig(player, ...)

            if medXpBefore then
                local medXpAfter = player:getXp():getXP(Perks.Doctor)
                local medXpGained = medXpAfter - medXpBefore
                if medXpGained > 1 then
                    addXp(player, Perks.Science, medXpGained/2)
                end
            end

            return result
        end -- ProcessAutopsy
    } -- LabAutopsyLogic
}) -- zdk.hook
