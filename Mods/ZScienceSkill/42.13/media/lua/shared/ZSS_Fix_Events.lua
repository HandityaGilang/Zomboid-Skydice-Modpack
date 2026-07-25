-- Events.AddXP logic changed after 42.13.1:
--
--  zombie/characters/IsoGameCharacter.java:
--
--    42.12:
--      12730-            if (!GameServer.bServer) {
--      12731:                LuaEventManager.triggerEventGarbage("AddXP", this.chr, perk, Float.valueOf(f));
--
--    42.13.1:
--      12927-            if (!GameServer.server) {
--      12928:                LuaEventManager.triggerEventGarbage("AddXP", this.chr, type, Float.valueOf(amount));
--
--    42.13.2:
--      12931-            if (!GameClient.client) {
--      12932:                LuaEventManager.triggerEventGarbage("AddXP", this.chr, type, Float.valueOf(amount));
--
--    unstable:
--      13283-            if (!GameClient.client) {
--      13284:                LuaEventManager.triggerEventGarbage("AddXP", this.chr, type, Float.valueOf(amount));
--
--  so before 42.13.2 AddXP never fires on server,
--  and after 42.13.2 it never fires on client.

ZSS_Fix_Events = {
    is_fix_needed = true,
    message_shown = false,
    handlers      = {},
    AddXP         = {},
}

local MOD_ID = 'ZScienceSkill'
local CMD_ID = 'AddXP'

function ZSS_Fix_Events.AddXP.Add(handler)
    Events.AddXP.Add(handler)
    if isServer() then
        ZSS_Fix_Events.handlers[handler] = true
    end
end

function ZSS_Fix_Events.AddXP.Remove(handler)
    Events.AddXP.Remove(handler)
    if isServer() then
        ZSS_Fix_Events.handlers[handler] = nil
    end
end

-- fires either on client or server
local function onAddXP(character, perk, amount)
    if isServer() then
        -- we're on 42.13.2+, no fix needed
        if not ZSS_Fix_Events.message_shown then
            ZSS_Fix_Events.message_shown = true
            print("ZSS_Fix_Events - got onAddXP() on server - no fix needed")
        end
        ZSS_Fix_Events.is_fix_needed = false
        Events.AddXP.Remove(onAddXP)
        return
    end
    if isClient() then
        -- we're on 42.13.1 or earlier, apply the fix
        if not ZSS_Fix_Events.message_shown then
            ZSS_Fix_Events.message_shown = true
            print("ZSS_Fix_Events - got onAddXP() on client - relaying via sendClientCommand")
        end
        sendClientCommand(character, MOD_ID, CMD_ID, { perk = perk:getId(), amount = amount })
    end
end

if isServer() then
    local function onClientCommand(module, command, player, args)
        if module ~= MOD_ID or command ~= CMD_ID then return end

        if ZSS_Fix_Events.is_fix_needed then
            for handler, _ in pairs(ZSS_Fix_Events.handlers) do
                pcall(handler, player, Perks.FromString(args.perk), args.amount)
            end
        else
            Events.OnClientCommand.Remove(onClientCommand)
        end
    end

    if Events and Events.OnClientCommand then
        Events.OnClientCommand.Add(onClientCommand)
    end
end

if Events and Events.AddXP then
    Events.AddXP.Add(onAddXP)
end
