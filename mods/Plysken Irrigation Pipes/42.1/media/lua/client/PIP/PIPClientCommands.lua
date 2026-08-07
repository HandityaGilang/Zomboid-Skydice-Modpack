-- PIPClientCommands.lua (CLIENT) — réception des commandes serveur.
-- 'givePipe' : LEGACY (v1.2.6 et avant). Le serveur ne l'émet plus depuis la v1.2.7 — il rend l'item
-- lui-même via givePipeTo (PIPCommands.lua), car un AddItem CLIENT n'est pas connu du serveur et
-- disparaissait à la reconnexion sur dédié. Handler gardé pour la transition serveur 1.2.6 / client 1.2.7.

require "PIP/PIPShared"

local function onServerCommand(module, command, args)
    if module ~= "PIP" then return end
    if command == "givePipe" then
        -- ⚠️ LEGACY depuis v1.2.7 : le serveur ne l'émet PLUS (il rend l'item lui-même, de façon
        -- autoritaire, via givePipeTo dans PIPCommands.lua). Un AddItem CLIENT n'est pas connu du
        -- serveur : l'item disparaissait à la reconnexion sur dédié (et pour un joueur distant d'un
        -- listen-host). Handler CONSERVÉ volontairement pour la fenêtre de transition où un serveur
        -- encore en 1.2.6 parle à un client déjà à jour — sans lui, l'item serait purement perdu.
        -- À supprimer quand la 1.2.7 sera largement déployée.
        local pl = getPlayer()
        if pl and pl:getInventory() then pl:getInventory():AddItem("PIP.WaterPipe") end
    elseif command == "notConnected" then
        -- Fertigation MP (v1.2.3) : barrel non relie a un reseau. Depuis v1.2.3 le client ne consomme
        -- plus de dose de facon optimiste (tout est autoritaire serveur) -> rien a rendre, juste le halo.
        local pl = getPlayer()
        if pl and HaloTextHelper and HaloTextHelper.addBadText then
            HaloTextHelper.addBadText(pl, getText("IGUI_PIP_NotConnected"))
        end
    elseif command == "enriched" and args then
        -- Feedback (c) MP : texte flottant "+N doses" a la confirmation serveur du versement.
        local pl = getPlayer()
        if pl and HaloTextHelper and HaloTextHelper.addGoodText then
            HaloTextHelper.addGoodText(pl, getText("IGUI_PIP_PouredDoses", tostring(args.n or 0)))
        end
    end
end

Events.OnServerCommand.Add(onServerCommand)
