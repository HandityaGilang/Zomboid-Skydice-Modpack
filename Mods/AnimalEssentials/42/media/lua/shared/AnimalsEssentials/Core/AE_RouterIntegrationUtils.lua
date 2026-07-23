local AE_RouterIntegrationUtils = {}
local AE_SummoningRouter = require("AnimalsEssentials/Core/AE_SummoningRouter")

function AE_RouterIntegrationUtils.routedSpawnCat(player, x, y, z, radius)
    if not player then
        local playerObj = getPlayer()
        if not playerObj then
            return false
        end
        player = playerObj
    end
    
    radius = radius or 3
    
    return AE_SummoningRouter.requestAnimalSummon(player, x, y, z, radius)
end

function AE_RouterIntegrationUtils.routedSpawnAtPlayer(player, radius)
    if not player then
        local playerObj = getPlayer()
        if not playerObj then
            return false
        end
        player = playerObj
    end
    
    local x = player:getX()
    local y = player:getY() 
    local z = player:getZ()
    
    return AE_RouterIntegrationUtils.routedSpawnCat(player, x, y, z, radius)
end

return AE_RouterIntegrationUtils