-- From "Starlit Library" mod -- Author = albion

local IsoObjectUtilsFromStarlitLibrary = {}

---@type IsoCell
local CELL
Events.OnPostMapLoad.Add(function (_cell, x, y)
    CELL = _cell
end)

local MIN_HEIGHT = -32

---Adds and connects a square at the given coordinates.
---@param x integer X world coordinate
---@param y integer Y world coordinate
---@param z integer Z world coordinate
---@return IsoGridSquare square The square that was added
IsoObjectUtilsFromStarlitLibrary.addSquare = function(x, y, z)
    if z < 0 and z % 2 == 1 then -- negative odd number
        -- prevent min level from becoming odd
        -- if it does, when the next lowest level is created its lighting will be severely bugged
        local chunk = CELL:getChunkForGridSquare(x, y, z)
        local minLevel = chunk:getMinLevel()
        if minLevel < z - 1 then
            chunk:setMinMaxLevel(z - 1, chunk:getMaxLevel())
        end
    end
    return CELL:createNewGridSquare(x, y, z, true)
end

---Gets or creates a square at the given coordinates.
---@param x integer X world coordinate
---@param y integer Y world coordinate
---@param z integer Z world coordinate
---@return IsoGridSquare square The square at the location
IsoObjectUtilsFromStarlitLibrary.getOrCreateSquare = function(x, y, z)
    return getSquare(x, y, z) or IsoObjectUtilsFromStarlitLibrary.addSquare(x, y, z)
end

return IsoObjectUtilsFromStarlitLibrary