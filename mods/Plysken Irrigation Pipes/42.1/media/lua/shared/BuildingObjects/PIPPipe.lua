-- PIPPipe.lua (SHARED) — objet de pose de la pipe (curseur ISBuildingObject).
-- Adapté du placement B42 de Cluster Barrels (AddTileObject + isValid via square:isFree(false)).
--
-- POURQUOI shared/ (et pas client/ ni server/) — appris en MP dédié :
--  * CLIENT : a besoin de PIPPipe pour le curseur de pose (menu contextuel).
--  * SERVEUR : en MP, poser un ISBuildingObject envoie un paquet BuildAction ; le serveur
--    reconstruit l'objet via LuaManager.getFunctionObject("PIPPipe.new") (BuildAction.parse:154).
--    PIPPipe absent côté serveur -> « no such function PIPPipe.new » + IndexOutOfBounds -> la pose
--    ne se termine JAMAIS. La classe DOIT donc exister des DEUX côtés -> shared/.
--  * On ne dérive PAS au parse (ISBuildingObject peut ne pas être encore chargé -> « derive of
--    non-table »). Définition paresseuse (ensurePipeClass) déclenchée à OnGameBoot (client ET
--    serveur, ISBuildingObject alors chargé) + au 1er usage du menu (filet client).

require "PIP/PIPShared"

function PIP.ensurePipeClass()
    if PIPPipe then return PIPPipe end
    if not ISBuildingObject then return nil end   -- pas encore chargée -> réessai au prochain appel

    PIPPipe = ISBuildingObject:derive("PIPPipe")

    -- POSE EN MP : on N'utilise PAS la build-action moteur (ISBuildAction). En dédié, le serveur
    -- reconstruit l'objet (BuildAction.parse -> PIPPipe.new) et exécute create() SANS joueur valide
    -- (getSpecificPlayer(num)=nil côté serveur) -> pose avortée silencieusement. On override donc
    -- tryBuild (qui tourne CÔTÉ CLIENT, joueur valide) : on marche à la case puis on lance une
    -- TimedAction de pose (PIPPlaceAction, shared/) — barre de progression, plus de pose INSTANTANÉE.
    -- C'est l'action qui, À LA FIN de la barre, consomme l'item + délègue la création au SERVEUR via
    -- la commande 'placePipe' (handler reçoit le player). Même pattern que le retrait + que PSR
    -- ([[feedback-psr-mp-architecture]]). Unifié SP / host / dédié.
    function PIPPipe:tryBuild(x, y, z)
        local cell = getWorld() and getWorld():getCell()
        local playerObj = getSpecificPlayer(self.player)
        local square = (playerObj and cell) and cell:getGridSquare(x, y, z) or nil
        if not (playerObj and square) then return nil end
        if not playerObj:isEquipped(self.pipeItem) and not playerObj:getInventory():contains("WaterPipe") then
            if cell then cell:setDrag(nil, self.player) end   -- plus de pipe en main/inv -> stop curseur
            return nil
        end
        if not self:isValid(square, self.north) then return nil end   -- case invalide -> curseur rouge, pas de pose
        if not PIPPlaceAction then return nil end                     -- classe pas encore chargée
        -- marche à la case puis barre de construction ; la pose réelle se fait dans l'action.
        if luautils.walkAdj(playerObj, square) then
            ISTimedActionQueue.add(PIPPlaceAction:new(playerObj, self.pipeItem, x, y, z, self.pipeType))
            PIP.dbg("tryBuild -> queued PIPPlaceAction", self.pipeType, x, y, z)
        end
        return nil
    end

    function PIPPipe:isValid(square, north)
        if not square then return false end
        if not square:isFree(false) then return false end      -- fix B42 : sols construits OK, pas la logique murs
        if PIP.findPipeObject(square) then return false end     -- pas deux pipes sur la même case
        return true
    end

    function PIPPipe:render(x, y, z, square, north)
        ISBuildingObject.render(self, x, y, z, square, north)
    end

    function PIPPipe:getHealth() return 100 end

    function PIPPipe:new(player, pipeItem, sprite, pipeType)
        local o = {}
        setmetatable(o, self); self.__index = self
        o:init()
        o:setSprite(sprite)
        o.name = "Irrigation Pipe"
        o.dismantable   = false
        o.canBarricade  = false
        o.blockAllTheSquare = false
        o.canPassThrough = true
        o.maxTime = 10
        o.isContainer = false
        o.isThumpable = false
        o.noNeedHammer = true
        o.pipeItem = pipeItem
        o.player = player
        o.pipeType = pipeType
        return o
    end

    PIP.dbg("PIPPipe class defined")
    return PIPPipe
end

-- Définition au boot (client ET serveur) + tentative immédiate si ISBuildingObject déjà chargé.
-- Le menu de pose rappelle aussi PIP.ensurePipeClass() juste avant de poser (filet runtime client).
PIP.ensurePipeClass()
Events.OnGameBoot.Add(function() PIP.ensurePipeClass() end)
