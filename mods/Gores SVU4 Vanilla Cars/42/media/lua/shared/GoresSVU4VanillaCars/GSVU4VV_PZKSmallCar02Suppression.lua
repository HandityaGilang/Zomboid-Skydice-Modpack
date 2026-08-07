local function hasActivatedMod(modId)
    if not modId or not getActivatedMods then return false end
    local ok, mods = pcall(getActivatedMods)
    if not ok or not mods or not mods.contains then return false end
    local okContains, result = pcall(function() return mods:contains(modId) end)
    return okContains and result == true
end

if hasActivatedMod("PzkVanillaPlusCarPack") then
end
