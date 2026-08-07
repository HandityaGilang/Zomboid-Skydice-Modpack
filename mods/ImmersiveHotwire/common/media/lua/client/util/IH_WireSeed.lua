local Config = require "config/IH_Config"
local Utils = require "util/IH_Utils"

local M = {}

function M.getStableHotwireId(vehicle)
    if not vehicle then
        return 0
    end
    local md = vehicle:getModData()
    local stableId = md and md.IH_StableId
    if type(stableId) == "number" and stableId > 0 then
        return stableId
    end
    return 0
end

function M.getRoleIndexMapFromId(vehicleId)
    local roles = { Config.ROLES.BASE[1], Config.ROLES.BASE[2], Config.ROLES.BASE[3] }
    local extraRoles = { Config.ROLES.EXTRA[1] }
    local seed = vehicleId
    local count = (vehicleId % 2) + 3
    if count == 4 then
        seed = Utils.nextRand(seed + 7)
        local idx = (seed % #extraRoles) + 1
        roles[#roles + 1] = extraRoles[idx]
    end
    Utils.shuffle(roles, seed)
    local map = {}
    for i = 1, #roles do
        map[roles[i]] = i
    end
    return map, count
end

function M.getRoleIndexMap(vehicle)
    local vehicleId = M.getStableHotwireId(vehicle)
    local map = M.getRoleIndexMapFromId(vehicleId)
    return map
end

return M
