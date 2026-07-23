local AE_SummoningRouter = {}
local AE_EnvironmentDetector = require("AnimalsEssentials/Core/AE_EnvironmentDetector")

function AE_SummoningRouter.requestAnimalSummon(player, x, y, z, radius)
    if AE_EnvironmentDetector.isSinglePlayer() then
        local AE_SinglePlayerSummoning = require("AnimalsEssentials/Core/AE_SinglePlayerSummoning")
        return AE_SinglePlayerSummoning.summonAnimal(player, x, y, z, radius)
    else
        local AE_MultiplayerSummoning = require("AnimalsEssentials/Core/AE_MultiplayerSummoning")
        return AE_MultiplayerSummoning.sendSummonCommand(player, x, y, z, radius)
    end
end

return AE_SummoningRouter