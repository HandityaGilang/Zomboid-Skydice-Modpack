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

local UnlinkComputer = ISBaseTimedAction:derive("PSR_UnlinkComputer")
PSR_UnlinkComputer = UnlinkComputer

---@param character  IsoPlayer
---@param computerIso IsoObject  le Desktop Computer lié (PSR_linkedBank doit être dans son modData)
function UnlinkComputer:new(character, computerIso)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character   = character
    o.computerIso = computerIso
    o.cx = computerIso:getX()
    o.cy = computerIso:getY()
    o.cz = computerIso:getZ()
    o.cSprite = computerIso:getTextureName()
    -- Coords de la bank lues depuis le modData client (synché par transmitModData lors du LinkComputer)
    local linkedBank = computerIso:getModData().PSR_linkedBank
    o.bx = linkedBank and linkedBank.x
    o.by = linkedBank and linkedBank.y
    o.bz = linkedBank and linkedBank.z
    o.stopOnWalk = true
    o.stopOnRun  = true
    o.stopOnAim  = false
    o.maxTime    = 30
    return o
end

---Variante DEPUIS LA BANK — c'est la porte de sortie qui manquait.
---Jusqu'ici l'unique moyen de delier etait le menu de l'ORDINATEUR, garde par le drapeau que
---l'ordinateur porte : quand il disparait (demontage), le lien cote bank survit et plus rien ne
---peut l'effacer. *Une issue de secours ne doit pas vivre sur l'objet qui peut disparaitre.*
---Demande explicite du joueur Zephyrum (2026-08-04) — et il avait raison de la demander.
---@param character IsoPlayer
---@param bankIso   IsoObject  la Battery Bank (c'est elle qu'on cible et qu'on regarde)
---@param comp      table      { x, y, z } lu dans le modData de la bank
function UnlinkComputer:newFromBank(character, bankIso, comp)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character   = character
    o.computerIso = bankIso          -- cible de l'animation / du regard : la bank
    o.fromBank    = true
    o.bx, o.by, o.bz = bankIso:getX(), bankIso:getY(), bankIso:getZ()
    o.cx, o.cy, o.cz = comp and comp.x, comp and comp.y, comp and comp.z
    o.cSprite     = nil              -- inconnu, et sans importance : on matche la reference en retour
    o.stopOnWalk  = true
    o.stopOnRun   = true
    o.stopOnAim   = false
    o.maxTime     = 30
    return o
end

function UnlinkComputer:isValid()
    if isServer() then return true end
    return self.computerIso:getObjectIndex() ~= -1
end

function UnlinkComputer:start()
    if isServer() then return end
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Low")
    self.character:reportEvent("EventLootItem")
end

function UnlinkComputer:waitToStart()
    if isServer() then return false end
    self.character:faceThisObject(self.computerIso)
    return self.character:shouldBeTurning()
end

function UnlinkComputer:update()
    if isServer() then return end
    self.character:faceThisObject(self.computerIso)
end

function UnlinkComputer:perform()
    if isServer() then return true end
    ISBaseTimedAction.perform(self)
    return true
end

function UnlinkComputer:complete()
    -- B42.19 : complete() must return a boolean on dedicated (protectedCallBoolean).
    if not PSR.PBSystem_Server then return true end
    -- Nettoyer côté bank
    if self.bx then
        local pb = PSR.PBSystem_Server:getLuaObjectAt(self.bx, self.by, self.bz)
        if pb then
            pb.PSR_computer = nil
            pb:saveData(true)
        end
    end
    -- Nettoyer côté computer. Deux façons de retrouver l'objet, et elles ne se valent pas :
    --  · depuis l'ORDINATEUR (chemin historique) : on connaît son sprite, on matche dessus.
    --  · depuis la BANK : on ne connaît pas le sprite, et surtout l'ordinateur peut avoir DISPARU
    --    ou avoir été remplacé par un autre desktop. On matche donc la RÉFÉRENCE EN RETOUR, ce qui
    --    ne touche que l'objet réellement lié à CETTE bank — et ne fait rien s'il n'y en a plus.
    if not self.cx then return true end
    local sq = getSquare(self.cx, self.cy, self.cz)
    if not sq then return true end
    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do
        local obj = objs:get(i)
        local matches
        if self.fromBank then
            local lb = obj and obj:getModData().PSR_linkedBank
            matches = lb and lb.x == self.bx and lb.y == self.by and lb.z == self.bz
        else
            matches = obj and obj:getTextureName() == self.cSprite
        end
        if matches then
            obj:getModData().PSR_linkedBank = nil
            obj:transmitModData()
            break
        end
    end
    return true
end

PSR.UnlinkComputer = UnlinkComputer
