--[[
    TMJukeboxServer.lua  (server)

    Dedicated-server registration of the jukebox container accept function.

    Vanilla server/Items/AcceptItemFunction.lua does `AcceptItemFunction = {}`
    (no `or {}`), wiping anything shared lua registered. Mod server lua loads
    AFTER vanilla server lua, so re-registering here guarantees the function
    exists on dedicated servers ("no such function AcceptItemFunction.TM_Jukebox"
    spam + all media being rejected from the jukebox container otherwise).
]]

require "TMJukeboxDefs"

if TMJukebox and TMJukebox.registerAcceptItem then
    TMJukebox.registerAcceptItem()
end
