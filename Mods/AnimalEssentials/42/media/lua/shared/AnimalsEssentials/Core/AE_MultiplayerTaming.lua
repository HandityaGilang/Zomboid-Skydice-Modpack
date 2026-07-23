local AE_MultiplayerTaming = {}

function AE_MultiplayerTaming.sendFeedCommand(animal, player)
    sendServerCommand("AE_TamingService", "feedAnimal", {
        animalID = animal:getOnlineID() or animal:getID(),
        playerID = player:getOnlineID() or player:getID(),
        animalX = animal:getX(),
        animalY = animal:getY()
    })
end

return AE_MultiplayerTaming