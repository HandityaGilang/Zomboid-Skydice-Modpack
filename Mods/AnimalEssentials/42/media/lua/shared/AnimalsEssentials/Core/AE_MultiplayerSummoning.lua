local AE_MultiplayerSummoning = {}

function AE_MultiplayerSummoning.sendSummonCommand(player, x, y, z, radius)
    if not player then
        return false
    end

    sendServerCommand("AE_ZoneSpawning", "spawnAnimal", {
        x = x,
        y = y,
        z = z,
        radius = radius or 3
    })
    return true
end

return AE_MultiplayerSummoning