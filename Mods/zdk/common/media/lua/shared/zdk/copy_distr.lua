zdk = zdk or {}

-- copies all entries for srcKey to dstKey in all distributions found in rootTbl
function zdk.copy_distr(rootTbl, srcKey, dstKey, logger)
    logger = (logger or zdk.Logger.default):withPrefix("copyDistr(rootTbl, '%s', '%s'): ", srcKey, dstKey)

    if type(rootTbl) ~= "table" then
        logger:error("rootTbl: expected a table but got %s", type(rootTbl))
        return 0
    end
    if not getItem(srcKey) then
        logger:warn("src item '%s' not found", srcKey)
        return 0
    end
    if not getItem(dstKey) then
        logger:warn("dst item '%s' not found", dstKey)
        return 0
    end

    local nAdded = 0
    for tableName, dist in pairs(rootTbl) do
        if type(dist) == "table" and dist.items then
            for i = 1, #dist.items, 2 do
                if dist.items[i] == srcKey then
                    -- assuming table structure is consistent and contains pairs of key and weight, so the weight is always at index i + 1
                    local weight = dist.items[i + 1]

                    -- logger:debug("adding %s to distribution %s with weight %d", dstKey, tableName, weight)
                    table.insert(dist.items, dstKey)
                    table.insert(dist.items, weight)
                    nAdded = nAdded + 1
                    break -- intended break of inner loop only
                end
            end
        end
    end
    logger:info("added %d entries", nAdded)

    -- return value is unused for now, but may be useful for testing or logging in the future
    return nAdded
end
