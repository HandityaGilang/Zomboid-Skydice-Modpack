local TABAS_Patches = {}

TABAS_Patches.applied = false

function TABAS_Patches.apply()
    if TABAS_Patches.applied then return true end

    if not (RasBodyModRegistries and RasBodyModRegistries.Skin) then
        DebugLog.log("[TABAS Patch Error] Not found rasBodyMod's Body Location!")
        return false
    end

    local function cleaningBodyRasSkin(character, pct, factor)
        local mul = pct * factor
        local decTotal = 0

        local rasSkin = RasBodyModRegistries.Skin
        local skin = character:getWornItem(rasSkin)
        if skin then
            local changed = false
            local coveredParts = BloodClothingType.getCoveredParts(skin:getBloodClothingType())
            if coveredParts then
                local psize = coveredParts:size()
                for j = 0, psize - 1 do
                    local part = coveredParts:get(j)

                    local value = skin:getBlood(part)
                    if value > 0 then
                        local decrease = value * mul
                        skin:setBlood(part, math.max(0, value - decrease))
                        decTotal = decTotal + decrease
                        changed = true
                    end

                    value = skin:getDirt(part)
                    if value > 0 then
                        local decrease = value * mul
                        skin:setDirt(part, math.max(0, value - decrease))
                        decTotal = decTotal + decrease
                        changed = true
                    end
                end
            end

            if changed then
                syncItemFields(character, skin)
                character:resetModelNextFrame()
                syncVisuals(character)
                if isServer() then
                    sendClothing(character, skin:getBodyLocation(), skin)
                end
            end
        end

        return decTotal
    end

    local TABAS_BathingUtils = require("Bathing/TABAS_BathingUtils")
    TABAS_BathingUtils.cleaningBody = cleaningBodyRasSkin

    TABAS_Patches.applied = true
    return true
end

return TABAS_Patches
