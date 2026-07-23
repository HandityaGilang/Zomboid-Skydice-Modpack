local AE_SystemRouter = {}
local AE_EnvironmentDetector = require("AnimalsEssentials/Core/AE_EnvironmentDetector")

function AE_SystemRouter.processTamingAttempt(animal, player)
    if AE_EnvironmentDetector.isSinglePlayer() then
        local AE_SinglePlayerTaming = require("AnimalsEssentials/Core/AE_SinglePlayerTaming")
        return AE_SinglePlayerTaming.feedAnimal(animal, player)
    else
        local AE_MultiplayerTaming = require("AnimalsEssentials/Core/AE_MultiplayerTaming")
        return AE_MultiplayerTaming.sendFeedCommand(animal, player)
    end
end

return AE_SystemRouter