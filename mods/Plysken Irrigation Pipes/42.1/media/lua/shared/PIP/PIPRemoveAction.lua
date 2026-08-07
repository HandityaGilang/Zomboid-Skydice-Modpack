-- PIPRemoveAction.lua (SHARED) — TimedAction de retrait d'une pipe.
--
-- POURQUOI shared/ (deplace depuis client/ en v1.1) — appris en MP dedie :
--  En MP, l'action mise en file est transmise au serveur (NetTimedAction) qui la RECONSTRUIT via
--  LuaManager.getFunctionObject("PIPRemovePipeAction.new"). En client/ la classe n'existe pas cote
--  serveur -> « no such function PIPRemovePipeAction.new » -> retrait casse. Meme pattern que les 7
--  TimedActions MP de PSR (toutes en shared/PSR/TimedActions/) + que PIPPipe.
--
-- ISBaseTimedAction est une classe CLIENT : absente sur serveur dedie. On fournit un stub serveur
-- (calque sur PSR) dont le :derive enregistre la classe dans _G -> getFunctionObject la trouve.
-- ⚠️ complete() retourne un booleen (piege B42.19, vecu sur PSR — sinon NPE en MP dedie).

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

PIPRemovePipeAction = ISBaseTimedAction:derive("PIPRemovePipeAction")

function PIPRemovePipeAction:isValid()
    if isServer() then return true end
    return self.pipeObject ~= nil and self.square ~= nil
end

function PIPRemovePipeAction:update()
    if isServer() then return end
    self.character:faceThisObject(self.pipeObject)
end

function PIPRemovePipeAction:perform()
    -- No-op quand le SERVEUR reconstruit l'action d'un joueur DISTANT (dedie OU listen-host) : le handler
    -- OnClientCommand 'removePipe' est l'autorite UNIQUE. ⚠️ Sur un listen-host isServer() ET isClient()
    -- valent true -> `not isClient()` ne suffit PAS (l'hote doublait le retrait + l'item du joueur distant).
    -- On discrimine sur isLocalPlayer, comme PIPEnrichAction. [audit MP 2026-06-27]
    if isServer() and not (self.character and self.character.isLocalPlayer and self.character:isLocalPlayer()) then return true end
    if isClient() and not isServer() then
        -- Client dédié : le serveur retire (autoritaire) PUIS rend l'item lui-même (givePipeTo) SEULEMENT
        -- s'il a vraiment retiré -> pas de dup si 2 joueurs visent la même pipe (avant : AddItem optimiste).
        sendClientCommand('PIP', 'removePipe',
            { x = self.square:getX(), y = self.square:getY(), z = self.square:getZ() })
    else
        -- SP / host : autoritaire localement -> retrait + item direct.
        PIP.removePipeObject(self.pipeObject)
        if self.character and self.character:getInventory() then
            self.character:getInventory():AddItem("PIP.WaterPipe")
        end
    end
    ISBaseTimedAction.perform(self)
    return true
end

function PIPRemovePipeAction:complete()
    return true   -- OBLIGATOIRE (B42.19)
end

function PIPRemovePipeAction:new(character, pipeObject, square, time)
    local o = ISBaseTimedAction.new(self, character)
    o.pipeObject = pipeObject
    o.square = square
    o.maxTime = time or 30
    if not isServer() and character and character.isTimedActionInstant and character:isTimedActionInstant() then
        o.maxTime = 1
    end
    o.stopOnWalk = true
    o.stopOnRun = true
    return o
end
