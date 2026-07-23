local AE_SinglePlayerSummoning = {}
local AE_SummoningSystem = require("AnimalsEssentials/AE_SummoningSystem")

function AE_SinglePlayerSummoning.summonAnimal(player, x, y, z, radius)
    return AE_SummoningSystem.summonRandomCat(player, x, y, z, radius)
end

return AE_SinglePlayerSummoning