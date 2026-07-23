if isServer() then
    return
end
-- Zombie scanning and cure assignment is now handled entirely server-side.
-- See server_events.lua for the OnZombieUpdate and OnZombieDead handlers.
