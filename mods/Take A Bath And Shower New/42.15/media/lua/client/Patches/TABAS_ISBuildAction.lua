local TABAS_ISBuildAction = {}
local TABAS_Iso = require("TABAS_Iso")

local ADJ_DIRS = { IsoDirections.N, IsoDirections.S, IsoDirections.E, IsoDirections.W }
local _sprPropsCache = {}

local function checkTubEdgeNeedChanges(square, spriteCache)
    for spriteName,_ in pairs(spriteCache) do
        if _sprPropsCache[spriteName] == nil then
            -- create cache
            local sprite = getSprite(spriteName)
            if not sprite then
                _sprPropsCache[spriteName] = false
            else
                local props = sprite:getProperties()
                if props then
                    _sprPropsCache[spriteName] = (props:has(IsoFlagType.solid) or props:has(IsoFlagType.solidtrans))
                end
            end
        end

        if not _sprPropsCache[spriteName] then return false end
    end

    if not square then return end
    for _, dir in ipairs(ADJ_DIRS) do
        local sq = square:getAdjacentSquare(dir)
        if sq then
            local objs = sq:getObjects()
            for i=0, objs:size()-1 do
                local obj = objs:get(i)
                if obj and TABAS_Iso.isBathObject(obj) then
                    return true
                end
            end
        end
    end
    return false
end

function TABAS_ISBuildAction.apply()
    if TABAS_ISBuildAction._applied or ISBuildAction.tabas_TubEdgeWrapped then return end

    TABAS_ISBuildAction._applied = true
    ISBuildAction.tabas_TubEdgeWrapped = true

    local _oldPerform = ISBuildAction.perform
    function ISBuildAction:perform()
        _oldPerform(self)

        local spriteCache = self.item.spriteCache
        if not spriteCache then return end
        if checkTubEdgeNeedChanges(self.square, spriteCache) then
            sendClientCommand("tabas_object", "tubEdgeReevalAt", { x=self.x, y=self.y, z=self.z })
            return
        end
    end
end

return TABAS_ISBuildAction
