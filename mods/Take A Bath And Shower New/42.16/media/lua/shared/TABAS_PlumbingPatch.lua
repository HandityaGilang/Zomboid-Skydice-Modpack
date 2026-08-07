local TABAS_PlumbingPatch = {}

local function hasWaterPipedSprite(item)
    if not item then
        return false
    end

    local sprite = item:getSprite()
    if not sprite then
        return false
    end

    local props = sprite:getProperties()
    if not props then
        return false
    end

    return props:has("waterPiped") or props:has(IsoFlagType.waterPiped)
end

function TABAS_PlumbingPatch.apply()
    if TABAS_PlumbingPatch._applied then
        return
    end
    TABAS_PlumbingPatch._applied = true

    if not ISPlumbItem or ISPlumbItem._TABASPatched then
        return
    end

    ISPlumbItem._TABASPatched = true
    local TABAS_Iso = require("TABAS_Iso")
    local WaterReader = require("TABAS_WaterReader")
    local originalComplete = ISPlumbItem.complete

    function ISPlumbItem:complete()
        local result = originalComplete(self)

        if self.itemToPipe and hasWaterPipedSprite(self.itemToPipe) then
            if TABAS_Iso.isBathObject(self.itemToPipe) or TABAS_Iso.isShowerObject(self.itemToPipe) then
                local externalContainer = WaterReader.getExternalContainerCount(self.itemToPipe)
                if externalContainer == 0 then
                    self.itemToPipe:setUsesExternalWaterSource(false)
                    self.itemToPipe:sendObjectChange(IsoObjectChange.USES_EXTERNAL_WATER_SOURCE, { value = false })
                    local modData = self.itemToPipe:hasModData() and self.itemToPipe:getModData() or nil
                    if modData then
                        modData.canBeWaterPiped = nil
                        self.itemToPipe:transmitModData()
                    end
                    return true
                end
            end
        end

        return result
    end
end

return TABAS_PlumbingPatch