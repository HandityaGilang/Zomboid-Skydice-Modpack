--[[
    "psr_powerbank" shared functions between client and server systems
--]]

local PSR = require "PSR/Utilities"

-- ⚠️ 2026-08-04 — `local sandbox = SandboxVars.PSR` RETIRÉ (capture au CHARGEMENT du module).
-- Deux façons de tomber, aucune rattrapée : si `SandboxVars.PSR` n'est pas encore peuplé quand ce
-- fichier est requis, `sandbox` vaut `nil` ⇒ indexation d'un nil ; et si l'option manque (une option
-- ajoutée APRÈS la création d'une save, cf. `map_sand.bin` binaire), la valeur vaut `nil` ⇒
-- **arithmétique sur nil**. Dans les deux cas une erreur Lua, pas une valeur dégradée.
-- 📌 Et c'est surtout un DOUBLE POINT DE VÉRITÉ : `PSRComputerPanel.lua:perPanelOutput()` lit la
--    MÊME option, mais **en direct et avec un repli `or 25`**. Le point protégé était l'affichage,
--    le point nu était celui qui calcule la CHARGE RÉELLE. Les deux lisent désormais pareil.
--    ⚖️ Défaut `25` = celui de `sandbox-options.txt` (vérifié, pas supposé) — s'il change là-bas,
--    il doit changer ICI et dans `perPanelOutput()`.
local PSR_SOLAR_EFF_DEFAULT = 25

---@class PowerbankSystem
---@field getLuaObjectAt fun(self, x: number, y: number, z: number): PowerBankObject_Server
---@field getLuaObjectOnSquare fun(self, square: IsoGridSquare): PowerBankObject_Server
local PbSystem = {}

--also adds this function
function PbSystem:new(obj)
    for key,value in pairs(self) do
        obj[key] = value
    end
    return obj
end

---@param isoObject IsoObject
---@return boolean
function PbSystem:isValidIsoObject(isoObject)
    return instanceof(isoObject, "IsoGenerator") and PSR.WorldUtil.getType(isoObject) == "PowerBank"
end

function PbSystem:getIsoObjectOnSquare(square)
    if not square then return end
    local objects = square:getSpecialObjects()
    for i=0,objects:size()-1 do
        local isoObject = objects:get(i)
        if self:isValidIsoObject(isoObject) then
            return isoObject
        end
    end
end

function PbSystem:getMaxSolarOutput(SolarInput)
    -- Lecture EN DIRECT + repli (cf. la note en tête de fichier) : ce calcul alimente la charge
    -- réelle des banks, il ne doit jamais dépendre de l'instant où le module a été chargé.
    local eff = (SandboxVars and SandboxVars.PSR and SandboxVars.PSR.solarPanelEfficiency)
                or PSR_SOLAR_EFF_DEFAULT
    return SolarInput * (83 * ((eff * 1.25) / 100)) --changed to more realistic 1993 levels
end

local climateManager
function PbSystem:getModifiedSolarOutput(SolarInput)
    climateManager = climateManager or getClimateManager()
    local cloudiness = climateManager:getCloudIntensity()
    local light = climateManager:getDayLightStrength()
    local fogginess = climateManager:getFogIntensity()
    local CloudinessFogginessMean = 1 - (((cloudiness + fogginess) / 2) * 0.25) --make it so that clouds and fog can only reduce output by 25%
    local temperature = climateManager:getTemperature()
    local temperaturefactor = temperature * -0.0035 + 1.1 --based on linear single crystal sp efficiency
    local output = self:getMaxSolarOutput(SolarInput)
    output = output * CloudinessFogginessMean
    output = output * temperaturefactor
    output = output * light
    return output
end

---BFS from startPb — returns all PowerBankObjects in the linked network.
---@param startPb table
---@return table[]
function PbSystem:getNetwork(startPb)
    local visited = {}
    local queue   = { startPb }
    local result  = {}
    local function key(p) return p.x .. "," .. p.y .. "," .. p.z end
    visited[key(startPb)] = true
    while #queue > 0 do
        local pb = table.remove(queue, 1)
        table.insert(result, pb)
        for _, link in ipairs(pb.PSR_linkedBanks or {}) do
            local k = link.x .. "," .. link.y .. "," .. link.z
            if not visited[k] then
                visited[k] = true
                local linked = self:getLuaObjectAt(link.x, link.y, link.z)
                if linked then table.insert(queue, linked) end
            end
        end
    end
    return result
end

---Sums charge and capacity across a network.
---@param network table[]
---@return number totalCharge
---@return number totalCapacity
function PbSystem:getNetworkStats(network)
    local totalCharge, totalCapacity = 0, 0
    for _, pb in ipairs(network) do
        totalCharge    = totalCharge    + (pb.charge       or 0)
        totalCapacity  = totalCapacity  + (pb.maxcapacity  or 0)
    end
    return totalCharge, totalCapacity
end

---Distributes newCharge proportionally by each bank's maxcapacity.
---@param network table[]
---@param newCharge number
---@param totalCapacity number
function PbSystem:distributeCharge(network, newCharge, totalCapacity)
    for _, pb in ipairs(network) do
        pb.charge = totalCapacity > 0 and newCharge * ((pb.maxcapacity or 0) / totalCapacity) or 0
    end
end

function PbSystem:getValidBackupOnSquare(square)
    local generator = square:getGenerator()
    if generator and generator:isConnected() and not PSR.WorldUtil.findTypeOnSquare(square, "PowerBank") then
        return generator
    end
end

return PbSystem
