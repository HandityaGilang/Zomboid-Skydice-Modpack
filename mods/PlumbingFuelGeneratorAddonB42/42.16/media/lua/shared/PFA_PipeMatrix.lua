-- Waterpipes' own shape/vector matrix lives as a local in its WPServer.lua,
-- so it isn't reachable from an addon. This is a self-contained copy of the
-- same shape -> direction -> vector mapping, used only to walk the shared
-- pipe graph (WPModData.Pipes) for fuel.
PFAPipeMatrix = {
    ["ne"] = {
        ["n"] = {{x=1, y=0, z=0}},
        ["e"] = {{x=0, y=-1, z=0}},
    },
    ["se"] = {
        ["s"] = {{x=1, y=0, z=0}},
        ["e"] = {{x=0, y=1, z=0}},
    },
    ["sw"] = {
        ["s"] = {{x=-1, y=0, z=0}},
        ["w"] = {{x=0, y=1, z=0}},
    },
    ["nw"] = {
        ["n"] = {{x=-1, y=0, z=0}},
        ["w"] = {{x=0, y=-1, z=0}},
    },
    ["ns"] = {
        ["n"] = {{x=0, y=1, z=0}},
        ["s"] = {{x=0, y=-1, z=0}},
    },
    ["we"] = {
        ["w"] = {{x=1, y=0, z=0}},
        ["e"] = {{x=-1, y=0, z=0}},
    },
    ["nd"] = {
        ["n"] = {{x=0, y=0, z=-1}},
        ["d"] = {{x=0, y=-1, z=0}},
    },
    ["sd"] = {
        ["s"] = {{x=0, y=0, z=-1}},
        ["d"] = {{x=0, y=1, z=0}},
    },
    ["wd"] = {
        ["w"] = {{x=0, y=0, z=-1}},
        ["d"] = {{x=-1, y=0, z=0}},
    },
    ["ed"] = {
        ["e"] = {{x=0, y=0, z=-1}},
        ["d"] = {{x=1, y=0, z=0}},
    },
    ["nu"] = {
        ["n"] = {{x=0, y=0, z=1}},
        ["u"] = {{x=0, y=-1, z=0}},
    },
    ["su"] = {
        ["s"] = {{x=0, y=0, z=1}},
        ["u"] = {{x=0, y=1, z=0}},
    },
    ["wu"] = {
        ["w"] = {{x=0, y=0, z=1}},
        ["u"] = {{x=-1, y=0, z=0}},
    },
    ["eu"] = {
        ["e"] = {{x=0, y=0, z=1}},
        ["u"] = {{x=1, y=0, z=0}},
    },
    ["nsw"] = {
        ["n"] = {{x=-1, y=0, z=0}, {x=0, y=1, z=0}},
        ["s"] = {{x=-1, y=0, z=0}, {x=0, y=-1, z=0}},
        ["w"] = {{x=0, y=-1, z=0}, {x=0, y=1, z=0}},
    },
    ["swe"] = {
        ["s"] = {{x=-1, y=0, z=0}, {x=1, y=0, z=0}},
        ["w"] = {{x=1, y=0, z=0}, {x=0, y=1, z=0}},
        ["e"] = {{x=-1, y=0, z=0}, {x=0, y=1, z=0}},
    },
    ["nse"] = {
        ["n"] = {{x=1, y=0, z=0}, {x=0, y=1, z=0}},
        ["s"] = {{x=1, y=0, z=0}, {x=0, y=-1, z=0}},
        ["e"] = {{x=0, y=-1, z=0}, {x=0, y=1, z=0}},
    },
    ["nwe"] = {
        ["n"] = {{x=-1, y=0, z=0}, {x=1, y=0, z=0}},
        ["w"] = {{x=1, y=0, z=0}, {x=0, y=-1, z=0}},
        ["e"] = {{x=-1, y=0, z=0}, {x=0, y=-1, z=0}},
    },
    ["nswe"] = {
        ["n"] = {{x=-1, y=0, z=0}, {x=1, y=0, z=0}, {x=0, y=1, z=0}},
        ["s"] = {{x=-1, y=0, z=0}, {x=1, y=0, z=0}, {x=0, y=-1, z=0}},
        ["w"] = {{x=0, y=-1, z=0}, {x=0, y=1, z=0}, {x=1, y=0, z=0}},
        ["e"] = {{x=0, y=-1, z=0}, {x=0, y=1, z=0}, {x=-1, y=0, z=0}},
    },
}

PFAGetVectors = function(shape, dir)
    local vectors = {}
    if PFAPipeMatrix[shape] and PFAPipeMatrix[shape][dir] then
        -- shallow-copy so callers can freely mutate the result
        for i, v in ipairs(PFAPipeMatrix[shape][dir]) do
            vectors[i] = {x=v.x, y=v.y, z=v.z}
        end
    end

    for _, vector in ipairs(vectors) do
        local d
        if vector.x == 1 then d = "w" end
        if vector.x == -1 then d = "e" end
        if vector.y == 1 then d = "n" end
        if vector.y == -1 then d = "s" end
        if vector.z == 1 then d = "d" end
        if vector.z == -1 then d = "u" end
        vector.d = d
    end
    return vectors
end
