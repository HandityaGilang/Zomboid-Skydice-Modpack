-- Ensure the global SWTCCDAlbums table exists and create aliases for CD_... item types
if not SWTCCDAlbums then SWTCCDAlbums = {} end

local function createAliases()
    if not SWTCCDAlbums then return end
    for k, v in pairs(SWTCCDAlbums) do
        if v and v.folderName then
            local alias = "CD_" .. v.folderName .. "CD"
            if not SWTCCDAlbums[alias] then
                -- point alias to same table so playback data is shared
                SWTCCDAlbums[alias] = v
            end
        end
    end
end

-- Run on game boot to ensure other mods' album loaders have executed
if Events and Events.OnGameBoot then
    Events.OnGameBoot.Add(createAliases)
else
    createAliases()
end
