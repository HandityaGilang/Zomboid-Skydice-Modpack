if isClient() then
    return
end
require "PhunCure/core"
local Core = PhunCure
local Commands = {}

Commands[Core.commands.cure] = function(player, arguments)

    local bodyDamage = player:getBodyDamage();
    local stats = player:getStats();

    local bodyParts = bodyDamage:getBodyParts();
    local wasInfected = false
    local wasScratched = false
    local wasInfectedWound = false
    local wasBitten = false

    for i = bodyParts:size() - 1, 0, -1 do

        local bodyPart = bodyParts:get(i);

        if bodyPart:IsInfected() and Core.getOption("CureInfection") then
            Core.debugLn("Curing infected body part: " .. BodyPartType.ToString(bodyPart:getType()))
            wasInfected = true
            bodyPart:SetInfected(false);
            -- bodyPart:RestoreToFullHealth();

        end

        if bodyPart:bitten() and Core.getOption("CureBite") then
            Core.debugLn("Curing bitten body part: " .. BodyPartType.ToString(bodyPart:getType()))
            wasBitten = true
            bodyPart:SetBitten(false);
            -- bodyPart:RestoreToFullHealth();
        end
        if bodyPart:isInfectedWound() and Core.getOption("CureWound") then

            Core.debugLn("Curing infected wound on body part: " .. BodyPartType.ToString(bodyPart:getType()))
            wasInfectedWound = true
            bodyPart:setWoundInfectionLevel(-1)
        end

        if Core.getOption("CureScratch") and bodyPart:getScratchTime() > 0 then
            Core.debugLn("Curing scratched body part: " .. BodyPartType.ToString(bodyPart:getType()))
            wasScratched = true
            bodyPart:setScratched(false, true)
            bodyPart:setScratchTime(0)
        end
    end

    if wasInfected then
        Core.debugLn("Removing virus")
        bodyDamage:setInfected(false);
        bodyDamage:setInfectionMortalityDuration(-1);
        bodyDamage:setInfectionTime(-1)
        stats:set(CharacterStat.ZOMBIE_INFECTION, 0)
        stats:set(CharacterStat.ZOMBIE_FEVER, 0)
    end

    Core.debugLn(
        "Cure command processed on server with wasInfected=" .. tostring(wasInfected) .. ", wasInfectedWound=" ..
            tostring(wasInfectedWound) .. ", wasScratched=" .. tostring(wasScratched) .. ", wasBitten=" ..
            tostring(wasBitten))

    if Core.isLocal then
        Core.debugLn("Cure command processed locally.")
        if wasInfected or wasInfectedWound or wasScratched or wasBitten then
            player:Say(getText("IGUI_ItemSuccessAmpule_" .. ZombRand(1, 4)));
        end
    else
        Core.debugLn("Sending cure result back to client.", wasInfected, wasInfectedWound, wasScratched, wasBitten)
        sendServerCommand(player, Core.name, Core.commands.cure, {
            wasInfected = wasInfected,
            wasInfectedWound = wasInfectedWound,
            wasScratched = wasScratched,
            wasBitten = wasBitten
        })
    end

end

return Commands
