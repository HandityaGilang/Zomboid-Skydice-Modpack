-- TMBanListServer.lua (server)
-- Applies Ban Music List changes sent from an admin/debug client and
-- broadcasts the updated list to everyone. Non-authorized senders are
-- ignored (the client UI is admin-gated, but never trust the client).
require "TMBanListDefs"

local function onClientCommand(module, command, player, args)
    if module ~= "TMBanList" then return end
    if command ~= "set" then return end
    if not player then return end
    -- Validate the SENDER's own access level (never local-context globals);
    -- getDebug() is allowed so -debug test servers still work.
    local allowed = TMBanList.isPlayerAuthorized(player) or (getDebug and getDebug())
    if not allowed then
        print("[TMBanList] set REFUSED for non-admin " .. tostring(player:getUsername()))
        return
    end
    args = args or {}
    local d = TMBanList.getData()

    -- Replace the banned set wholesale (the UI always sends the full list).
    local newBanned = {}
    if type(args.banned) == "table" then
        for fullType, v in pairs(args.banned) do
            if v then newBanned[tostring(fullType)] = true end
        end
    end
    d.banned = newBanned
    d.bypass = args.bypass ~= false
    d.rev = (d.rev or 0) + 1

    local count = 0
    for _ in pairs(newBanned) do count = count + 1 end
    print("[TMBanList] set by " .. tostring(player:getUsername())
        .. " banned=" .. tostring(count) .. " bypass=" .. tostring(d.bypass))

    ModData.transmit(TMBanList.MODDATA_KEY)
end

Events.OnClientCommand.Add(onClientCommand)
