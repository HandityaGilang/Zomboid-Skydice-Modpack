local TABAS_DestoryCursor = {}

local EDGE_SPRITES = {
    tabas_fixtures_bathroom_01_0 = true,
    tabas_fixtures_bathroom_01_1 = true,
    tabas_fixtures_bathroom_01_2 = true,
    tabas_fixtures_bathroom_01_3 = true,
}

local function isTubEdgeObject(obj)
    if not obj then return false end

    local sprite = obj:getSprite()
    local props = sprite and sprite:getProperties()
    if props and props:has("CustomName") and props:get("CustomName") == "TubEdge" then
        return true
    end

    local spriteName = sprite and sprite:getName()
    return spriteName and EDGE_SPRITES[spriteName] == true or false
end

function TABAS_DestoryCursor.apply()
    if TABAS_DestoryCursor._applied then return end
    TABAS_DestoryCursor._applied = true

    if not ISDestroyCursor or ISDestroyCursor.tabas_TubEdgeWrapped then
        return
    end

    ISDestroyCursor.tabas_TubEdgeWrapped = true

    local old_canDestroy = ISDestroyCursor.canDestroy

    function ISDestroyCursor:canDestroy(object)
        if isTubEdgeObject(object) then
            return false
        end
        return old_canDestroy(self, object)
    end
end

return TABAS_DestoryCursor
