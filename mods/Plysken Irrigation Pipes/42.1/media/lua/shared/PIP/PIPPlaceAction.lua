-- PIPPlaceAction.lua (SHARED) — TimedAction de POSE d'une pipe (barre de progression).
--
-- POURQUOI (fix MP session 39) : avant, PIPPipe:tryBuild consommait l'item et envoyait 'placePipe'
-- IMMEDIATEMENT -> pose INSTANTANEE (pas de temps de construction, pas realiste). On passe par une
-- vraie TimedAction : le joueur marche a la case, la barre tourne, et a la FIN on consomme l'item +
-- delegue la creation au serveur (autoritaire) via sendClientCommand 'placePipe' (handler PIPCommands).
--
-- shared/ + stub serveur : meme raison que PIPRemoveAction / les 7 actions MP de PSR — en dedie la
-- NetTimedAction est reconstruite cote serveur (getFunctionObject "PIPPlaceAction.new"). ISBaseTimedAction
-- est une classe CLIENT (absente serveur) -> stub dont :derive enregistre la classe dans _G.
-- complete()/perform() -> return true (B42.19, NPE sinon).

if isServer() then
    if not ISBaseTimedAction then
        ISBaseTimedAction = {}
        ISBaseTimedAction.__index = ISBaseTimedAction
        function ISBaseTimedAction:derive(name)
            local cls = {}
            cls.__index = cls
            setmetatable(cls, self)
            self.__index = self
            _G[name] = cls
            return cls
        end
        function ISBaseTimedAction.new(self, character) local o = {} setmetatable(o, self) self.__index = self o.character = character return o end
        function ISBaseTimedAction:perform() self:complete() return true end
        function ISBaseTimedAction:isValid() return true end
        function ISBaseTimedAction:waitToStart() return false end
        function ISBaseTimedAction:start() end
        function ISBaseTimedAction:update() end
        function ISBaseTimedAction:stop() end
        function ISBaseTimedAction:complete() end
    end
else
    require "TimedActions/ISBaseTimedAction"
end
require "PIP/PIPShared"

PIPPlaceAction = ISBaseTimedAction:derive("PIPPlaceAction")

function PIPPlaceAction:isValid()
    if isServer() then return true end
    -- l'item doit toujours etre la (le joueur a pu le lacher en marchant)
    return self.character and (self.character:isEquipped(self.pipeItem)
        or self.character:getInventory():contains("WaterPipe"))
end

function PIPPlaceAction:update()
    if isServer() then return end
    local sq = self.character and self.character:getCurrentSquare()
    if sq then self.character:faceLocation(self.x, self.y) end
end

function PIPPlaceAction:perform()
    -- No-op quand le SERVEUR reconstruit l'action d'un joueur DISTANT (dedie OU listen-host) : le handler
    -- OnClientCommand 'placePipe' est l'autorite UNIQUE. ⚠️ Sur un listen-host isServer() ET isClient()
    -- valent true -> `not isClient()` ne suffit PAS (l'hote doublait la conso d'item + la commande du
    -- joueur distant = dup/perte de pipe). On discrimine sur isLocalPlayer, comme PIPEnrichAction. [audit MP 2026-06-27]
    if isServer() and not (self.character and self.character.isLocalPlayer and self.character:isLocalPlayer()) then return true end
    -- Cote joueur (client dedie / host / SP) : consommer l'item ICI (joueur valide) puis deleguer
    -- la creation au serveur. Le handler placePipe est gate pour ne creer que cote autoritaire.
    local pl = self.character
    if pl:isEquipped(self.pipeItem) then pl:removeFromHands(self.pipeItem) end
    pl:getInventory():Remove("WaterPipe")
    sendClientCommand('PIP', 'placePipe', { x = self.x, y = self.y, z = self.z, pipeType = self.pipeType })
    PIP.dbg("PIPPlaceAction:perform -> placePipe cmd", self.pipeType, self.x, self.y, self.z)
    ISBaseTimedAction.perform(self)
    return true
end

function PIPPlaceAction:complete()
    return true   -- OBLIGATOIRE (B42.19)
end

function PIPPlaceAction:new(character, pipeItem, x, y, z, pipeType)
    local o = ISBaseTimedAction.new(self, character)
    o.pipeItem = pipeItem
    o.x = x
    o.y = y
    o.z = z
    o.pipeType = pipeType
    o.maxTime = 60
    if not isServer() and character and character.isTimedActionInstant and character:isTimedActionInstant() then
        o.maxTime = 1
    end
    o.stopOnWalk = true
    o.stopOnRun = true
    return o
end
