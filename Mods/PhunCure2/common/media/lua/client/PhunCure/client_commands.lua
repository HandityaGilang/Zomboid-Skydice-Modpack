if isServer() then
    return
end

local Core = PhunCure
local Commands = {}

Commands[Core.commands.cure] = function(arguments)
    Core.debugLn("Cure command received on client with wasInfected=" .. tostring(arguments.wasInfected) ..
                     ", wasInfectedWound=" .. tostring(arguments.wasInfectedWound) .. ", wasScratched=" ..
                     tostring(arguments.wasScratched) .. ", wasBitten=" .. tostring(arguments.wasBitten))
    local player = getPlayer()
    if arguments.wasInfected or arguments.wasInfectedWound or arguments.wasScratched or arguments.wasBitten then

        if player then
            player:Say(getText("IGUI_ItemSuccessAmpule_" .. ZombRand(1, 4)));
            Core.tools.addLineInChat(getText("IGUI_ItemSuccessAmpule_Success"), "<RGB:0,255,0>");
        end
    else
        if player then
            Core.tools.addLineInChat(getText("IGUI_ItemSuccessAmpule_NoSuccess"), "<RGB:255,255,0>");
        end
    end
end

return Commands
