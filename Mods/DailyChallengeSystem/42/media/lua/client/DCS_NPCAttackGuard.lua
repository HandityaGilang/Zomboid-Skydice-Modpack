local function isDCSNPC(obj)
    if not obj then return false end
    if not (instanceof and instanceof(obj, "IsoZombie")) then return false end

    local md = obj:getModData()
    if md then
        if md.IsDCSNPC and md.DCSNPC_UUID then return true end
    end

    local bid = tostring(obj:getPersistentOutfitID())
    if bid and DCS_Sync and DCS_Sync.State and DCS_Sync.State.npcRegistry
       and DCS_Sync.State.npcRegistry[bid] then
        return true
    end

    return false
end
