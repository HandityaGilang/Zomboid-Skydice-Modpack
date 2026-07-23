require "PlayableMinigames/PMG_Core"
require "PlayableMinigames/PMG_Registry"
require "PlayableMinigames/PMG_Darts"
require "PlayableMinigames/PMG_Cards"
require "PlayableMinigames/PMG_BoardGames"
require "PlayableMinigames/PMG_AI"
require "PlayableMinigames/PMG_GameDarts"
require "PlayableMinigames/PMG_GameBlackjack"
require "PlayableMinigames/PMG_GameHoldem"
require "PlayableMinigames/PMG_GameSolitaire"
require "PlayableMinigames/PMG_GameChess"
require "PlayableMinigames/PMG_GameCheckers"

-- Compatibility registration for the existing pool implementation. Pool still
-- owns its mature physics/UI path while the new PMG layer becomes the host for
-- additional minigames and future pool migration.
PMG_Registry.register({
    id = "pool",
    name = "Pool",
    shortName = "Pool",
    icon = "mode_8ball.png",
    minPlayers = 1,
    maxPlayers = 2,
    anchorKind = "pool_table",
    legacyModule = "PlayablePool",
    canStart = function()
        return false, "Use Play Pool on the pool table."
    end,
})
