zdk = zdk or {}
zdk.ModData = {}

zdk.get_mod_data = function(obj, mod_id, ...)
    if not obj or not mod_id then return nil end
    local modData = obj:getModData()
    if not modData[mod_id] then
        modData[mod_id] = {}
    end
    return modData[mod_id]
end

function zdk.ModData.get(obj, mod_id, key)
    if not obj or not obj.getModData or not mod_id then return nil end

    local md = obj:getModData()
    if not md then return nil end

    if not md[mod_id] then return nil end

    if key then
        return md[mod_id][key]
    else
        return md[mod_id]
    end
end

function zdk.ModData.set(obj, mod_id, key, value)
    if not obj or not obj.getModData or not mod_id then return end

    local md = obj:getModData()
    if not md then return end

    if not md[mod_id] then
        md[mod_id] = {}
    end

    md[mod_id][key] = value
end
