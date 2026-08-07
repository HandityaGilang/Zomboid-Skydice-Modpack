local AE_SinglePlayerTaming = {}
local AE_TamingSystem = require("AnimalsEssentials/Taming/AE_TamingSystem")

function AE_SinglePlayerTaming.feedAnimal(animal, player)
    return AE_TamingSystem.FeedAnimal(animal, player)
end

return AE_SinglePlayerTaming