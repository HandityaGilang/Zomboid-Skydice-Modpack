local PSR = require "PSR/Utilities"
local RandomWorldSpawns = require "PSR/World/RandomWorldSpawns"

-- 🔴 GARDE 3-CONTEXTES (audit 2026-08-04). Valait `if isClient() then`.
-- Sur un HOTE COOP, `isClient()` ET `isServer()` sont vrais tous les deux : l'hote prenait donc la
-- branche CLIENT et la moitie serveur ne tournait jamais — `PBSystem_Server:loadIsoObject` jamais
-- appele au chargement de chunk, et `OnNewWithSprite` jamais enregistre (un sprite PSR cuit dans la
-- carte restait un decor inerte).
-- C'est le seul fichier de `server/` qui n'avait pas recu la garde appliquee aux 4 autres
-- (PowerBankSystem_Server, PowerBankObject_Server, PowerBankSystem_Commands, RandomWorldSpawns).
-- ⚖️ Basculer l'hote vers la branche serveur ne lui fait rien perdre : le seul geste de la branche
-- client (`setAcceptItemFunction`) est aussi fait par la branche serveur, ligne plus bas.
if isClient() and not isServer() then

    ---update isoObjects when chunk loads
    local function LoadPowerbank(isoObject)
        isoObject:getCell():addToProcessIsoObjectRemove(isoObject)
        -- Guard against IsoObjects matching the sprite but without a container (mod conflict,
        -- save corruption, transient chunk state). Skipping avoids a load-time crash and lets
        -- the rest of the chunk process normally.
        local c = isoObject:getContainer()
        if c and AcceptItemFunction and AcceptItemFunction.PSR_Batteries then
            c:setAcceptItemFunction("AcceptItemFunction.PSR_Batteries")
        end
    end
    MapObjects.OnLoadWithSprite("solarmod_tileset_01_0", LoadPowerbank, 6)

else

    ---update isoObjects when chunk loads
    local function LoadPowerbank(isoObject)
        PSR.PBSystem_Server:loadIsoObject(isoObject)
        local c = isoObject:getContainer()
        if c then
            c:setAcceptItemFunction("AcceptItemFunction.PSR_Batteries")
        end
    end
    MapObjects.OnLoadWithSprite("solarmod_tileset_01_0", LoadPowerbank, 6)

    ---update isoObjects when chunk loads first time
    local function OnNewWithSprite(isoObject)
        local PSRType = PSR.WorldUtil.getType(isoObject)
        local square = isoObject:getSquare()
        if not square then error("PSR: OnNewWithSprite no square") return end

        if PSRType == "PowerBank" then
            local index = isoObject:getObjectIndex()
            local spriteName = isoObject:getTextureName()
            square:transmitRemoveItemFromSquare(isoObject)
            RandomWorldSpawns.addToWorld(square, spriteName, index)
        else
            square:getSpecialObjects():add(isoObject)
        end
    end

    for sprite, type in pairs(PSR.WorldUtil.PSRTypes) do
        MapObjects.OnNewWithSprite(sprite, OnNewWithSprite, 5)
    end

end
