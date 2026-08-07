-- PIPEnrichAction.lua (SHARED) — TimedAction « verser un sac (engrais/compost) dans l'eau
-- d'irrigation d'un barrel connecté ». Le joueur marche jusqu'au barrel (ou reste s'il est déjà
-- adjacent), une barre de progression tourne, puis A LA FIN : consomme UNE DOSE du sac (Drainable :
-- 4 doses pour le compost, 8 pour l'engrais ; un CompostBag vidé rend un EmptySandbag via
-- ReplaceOnDeplete) + ajoute les charges. SP/host : tout en local dans perform (réseau vérifié AVANT
-- de consommer). MP client : aucune consommation optimiste -> la commande 'enrich' fait tout côté
-- serveur (autoritaire, anti-dup ; cf. fix pipes v1.2.2) ; halo via 'enriched' / 'notConnected'.
--
-- shared/ + stub serveur : même raison que PIPPlaceAction / PIPRemoveAction — en MP dédié la
-- NetTimedAction est reconstruite côté serveur (getFunctionObject "PIPEnrichAction.new") -> la classe
-- doit exister des deux côtés. ISBaseTimedAction est une classe CLIENT (absente serveur) -> stub dont
-- :derive enregistre la classe dans _G. complete()/perform() -> return true (B42.19, NPE sinon).

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

-- Consommation = UNE dose (UseDelta) du sac Drainable via PIP.useOneDrainable (PIPShared, récursif).
-- item:Use() applique le ReplaceOnDeplete -> un CompostBag vidé rend un EmptySandbag au joueur ;
-- l'engrais disparaît une fois vide. Un sac = 4 versements (compost) / 8 (engrais). (v1.2.3)

PIPEnrichAction = ISBaseTimedAction:derive("PIPEnrichAction")

function PIPEnrichAction:isValid()
    if isServer() then return true end
    -- le sac doit toujours etre la (le joueur a pu le lacher en marchant)
    return self.character and self.character:getInventory():contains(self.shortType)
end

function PIPEnrichAction:update()
    if isServer() then return end
    if self.character then self.character:faceLocation(self.x, self.y) end
end

function PIPEnrichAction:perform()
    -- Serveur dedie : reconstruction NetTimedAction. L'ajout des charges est fait par le handler
    -- OnClientCommand 'enrich' (autorite unique) -> no-op ici pour ne pas le doubler.
    -- No-op quand le SERVEUR reconstruit l'action d'un joueur DISTANT (dedie OU listen-host) : le handler
    -- 'enrich' (commande) est l'autorite UNIQUE. ⚠️ Sur un listen-host isServer() ET isClient() valent true,
    -- donc `not isClient()` ne suffit pas -> on discrimine sur isLocalPlayer (sinon DOUBLE charge :
    -- reconstruction host-side + commande du client distant). [audit MP 2026-06-10]
    if isServer() and not (self.character and self.character.isLocalPlayer and self.character:isLocalPlayer()) then return true end
    local pl = self.character
    if isClient() and not isServer() then
        -- MP client : AUCUNE consommation optimiste -> tout est autoritaire serveur (dose + charges +
        -- EmptySandbag). Le retrait client-only ne persiste pas sur dedie (cf. fix dup pipes v1.2.2 /
        -- cookbook §24). Le sac se met a jour au sync serveur ; le halo arrive via la commande 'enriched'.
        sendClientCommand('PIP', 'enrich', { x = self.x, y = self.y, z = self.z, kind = self.kind, shortType = self.shortType })
    else
        -- SP / host : autoritaire localement. Verifier le reseau AVANT de consommer (sinon une dose
        -- serait perdue sur un barrel non relie). useOneDrainable consomme 1 dose + rend l'EmptySandbag
        -- (compost) via ReplaceOnDeplete.
        local barrel = (PIP.Barrels and PIP.Barrels.fetchAt) and PIP.Barrels.fetchAt(self.x, self.y, self.z) or nil
        local gid = (barrel and PIP.Barrels.groupId) and PIP.Barrels.groupId(barrel) or nil
        if barrel and gid and gid > 0 then
            if PIP.useOneDrainable(pl:getInventory(), self.shortType) then
                PIP.Barrels.addCharges(barrel, self.kind, PIP.getConfig().chargesPerBag)
                if HaloTextHelper and HaloTextHelper.addGoodText then
                    HaloTextHelper.addGoodText(pl, getText("IGUI_PIP_PouredDoses", tostring(PIP.getConfig().chargesPerBag)))
                end
            end
        else
            -- Barrel non relie : rien consomme (on a verifie avant) -> juste le halo.
            if HaloTextHelper and HaloTextHelper.addBadText then
                HaloTextHelper.addBadText(pl, getText("IGUI_PIP_NotConnected"))
            end
        end
    end
    PIP.dbg("PIPEnrichAction:perform", tostring(self.kind), self.x, self.y, self.z)
    ISBaseTimedAction.perform(self)
    return true
end

function PIPEnrichAction:complete()
    return true   -- OBLIGATOIRE (B42.19)
end

function PIPEnrichAction:new(character, x, y, z, kind, shortType, fullType)
    local o = ISBaseTimedAction.new(self, character)
    o.x = x
    o.y = y
    o.z = z
    o.kind = kind
    o.shortType = shortType
    o.fullType = fullType
    o.maxTime = 80   -- verser un sac = un peu plus long que retirer une pipe (60)
    if not isServer() and character and character.isTimedActionInstant and character:isTimedActionInstant() then
        o.maxTime = 1
    end
    o.stopOnWalk = true
    o.stopOnRun = true
    return o
end
