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
local PSR = require "PSR/Utilities"

local LinkComputer = ISBaseTimedAction:derive("PSR_LinkComputer")
PSR_LinkComputer = LinkComputer

---@param character IsoPlayer
---@param computerIso IsoObject   the Desktop Computer IsoMoveable
---@param bankIso    IsoObject   the adjacent PowerBank
function LinkComputer:new(character, computerIso, bankIso)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character   = character
    o.computerIso = computerIso
    o.bankIso     = bankIso
    o.cx = computerIso:getX()
    o.cy = computerIso:getY()
    o.cz = computerIso:getZ()
    o.bx = bankIso:getX()
    o.by = bankIso:getY()
    o.bz = bankIso:getZ()
    o.cSprite    = computerIso:getTextureName()
    o.stopOnWalk = true
    o.stopOnRun  = true
    o.stopOnAim  = false
    o.maxTime    = 50
    return o
end

function LinkComputer:isValid()
    if isServer() then return true end
    return self.computerIso:getObjectIndex() ~= -1
end

function LinkComputer:start()
    if isServer() then return end
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Low")
    self.character:reportEvent("EventLootItem")
end

function LinkComputer:waitToStart()
    if isServer() then return false end
    self.character:faceThisObject(self.computerIso)
    return self.character:shouldBeTurning()
end

function LinkComputer:update()
    if isServer() then return end
    self.character:faceThisObject(self.computerIso)
end

function LinkComputer:perform()
    if isServer() then return true end
    ISBaseTimedAction.perform(self)
    return true
end

function LinkComputer:complete()
    -- B42.19 : complete() must return a boolean on dedicated (protectedCallBoolean).
    if not PSR.PBSystem_Server then return true end
    local pb = PSR.PBSystem_Server:getLuaObjectAt(self.bx, self.by, self.bz)
    if not pb then return true end
    -- 🩹 AUTO-REPARATION AVANT LE REFUS (signal joueur Zephyrum, 2026-08-04).
    -- `pb.PSR_computer` est une COORDONNEE, pas un objet : elle peut survivre a la disparition de
    -- l'ordinateur. Le nettoyage de `PowerBankSystem_Server:OnObjectAboutToBeRemoved` ne couvre pas
    -- tous les chemins de destruction — le joueur a isole le discriminant lui-meme :
    -- « dismantle it for part (not pick up!) ».
    -- Sans cette reparation, le refus ci-dessous devient DEFINITIF et SILENCIEUX : la bank refuse
    -- tout nouvel ordinateur, partout, et l'unique option « Disconnect » est portee par l'objet qui
    -- vient de disparaitre. => on ne croit un « oui » du registre qu'apres l'avoir verifie dans le
    -- monde (cf. registre-reconstructible : le monde est la source de verite, le registre un index).
    PSR.WorldUtil.healComputerLink(pb)
    -- Vérification : cette bank n'a pas déjà un ordinateur lié
    if pb.PSR_computer then return true end
    -- Trouver l'IsoObject du computer sur le serveur via ses coordonnées + sprite
    local sq = getSquare(self.cx, self.cy, self.cz)
    if not sq then return true end
    local objs = sq:getObjects()
    local computerIso = nil
    for i = 0, objs:size() - 1 do
        local obj = objs:get(i)
        if obj and obj:getTextureName() == self.cSprite then
            computerIso = obj
            break
        end
    end
    if not computerIso then return true end
    -- Écrire la liaison côté bank (SGlobalObject → sauvegardé via savedObjectModData)
    pb.PSR_computer = { x = self.cx, y = self.cy, z = self.cz }
    pb:saveData(true)
    -- Écrire la liaison côté computer (IsoObject modData → transmitModData synche clients)
    local compMD = computerIso:getModData()
    compMD.PSR_linkedBank = { x = self.bx, y = self.by, z = self.bz }
    computerIso:transmitModData()
    return true
end

PSR.LinkComputer = LinkComputer
