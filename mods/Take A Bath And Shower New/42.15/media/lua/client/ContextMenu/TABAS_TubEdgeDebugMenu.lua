local TABAS_TubEdgeDebugMenu = {}

local TABAS_Utils = require("TABAS_Utils")
local TABAS_Iso = require("TABAS_Iso")

local EDGE_SPRITES = {
    tabas_fixtures_bathroom_01_0 = true,
    tabas_fixtures_bathroom_01_1 = true,
    tabas_fixtures_bathroom_01_2 = true,
    tabas_fixtures_bathroom_01_3 = true,
}

local ADJ_DIRS = {
    IsoDirections.N,
    IsoDirections.S,
    IsoDirections.E,
    IsoDirections.W,
}

local function isTubEdgeObject(obj)
    if not obj then return false end
    local sprite = obj:getSprite()
    local spriteName = sprite and sprite:getName()
    if spriteName and EDGE_SPRITES[spriteName] then
        return true
    end
    return false
end

local function hasBathObjectAtSquare(sq)
    if not sq then return false end
    local objs = sq:getObjects()
    if not objs then return false end

    for i=0, objs:size() - 1 do
        local object = objs:get(i)
        if TABAS_Iso.isBathObject(object) then
            return object
        end
    end
    return false
end

local function hasBathAroundSquare(sq)
    if not sq then return false end

    if hasBathObjectAtSquare(sq) then
        return true
    end

    for _, dir in ipairs(ADJ_DIRS) do
        local adj = sq:getAdjacentSquare(dir)
        if hasBathObjectAtSquare(adj) then
            return true
        end
    end

    return false
end

local function collectOrphanTubEdgesFromSquare(sq, list, dups)
    if not sq then return end

    local objects = sq:getSpecialObjects()
    if not objects then return end

    for i=0, objects:size() - 1 do
        local obj = objects:get(i)
        if obj and not dups[obj] and isTubEdgeObject(obj) then
            dups[obj] = true
            if not hasBathAroundSquare(sq) then
                table.insert(list, obj)
            end
        end
    end
end

function TABAS_TubEdgeDebugMenu.onRemoveTubEdges(playerObj, objects)
    if not objects or #objects == 0 then return end

    local sent = {}
    for i=1, #objects do
        local obj = objects[i]
        local sq = obj and obj:getSquare()
        if sq then
            local key = string.format("%d,%d,%d", sq:getX(), sq:getY(), sq:getZ())
            if not sent[key] then
                sent[key] = true
                local args = {x = sq:getX(), y = sq:getY(), z = sq:getZ()}
                sendClientCommand(playerObj, "tabas_debug", "removeTubEdgeAtSquare", args)
            end
        end
    end
end

function TABAS_TubEdgeDebugMenu.doDebugMenu(player, context, worldobjects, test)
    if not TABAS_Utils.DEBUG_ENABLE then return end
    if test and ISWorldObjectContextMenu.Test then return true end

    local squares = {}
    local dupObjs = {}
    local tubEdges = {}
    for j=#worldobjects,1,-1 do
        local v = worldobjects[j]
        if v:getSquare() then
            local dup = false
            for i=1,#squares do
                if squares[i] == v:getSquare() then dup = true; break end
            end
            if not dup then table.insert(squares, v:getSquare()) end
        end
    end

    for i=1,#squares do
        collectOrphanTubEdgesFromSquare(squares[i], tubEdges, dupObjs)
    end
    if #tubEdges == 0 then return end

    local playerObj = getSpecificPlayer(player)
    local option = context:addOptionOnTop("Remove Orphan Tub Edges", playerObj, TABAS_TubEdgeDebugMenu.onRemoveTubEdges, tubEdges)
    option.iconTexture = getTexture("media/textures/Item_Plumpabug_Left.png")
    option.color = nil
end

Events.OnFillWorldObjectContextMenu.Add(TABAS_TubEdgeDebugMenu.doDebugMenu)

return TABAS_TubEdgeDebugMenu