--  ♡ 𝒜𝓂𝑒𝓁𝒾𝒶𝒦𝑒𝓃𝓎𝒶 𝒫𝒵 𝓂𝑜𝒹𝓈 ♡
--    𝐿𝑒𝒶𝓋𝑒 𝒶 𝓂𝑒𝓈𝓈𝒶𝑔𝑒 𝐵𝟦𝟤 

local function OnServerCommand_LMN(module, command, args)
    if module ~= "LMN" then return end
    
    if command == "SyncPickupLock" then
        -- Cari item di world
        local sq = getSquare(args.x, args.y, args.z)
        if sq then
            local worldObjects = sq:getWorldObjects()
            for i=0, worldObjects:size()-1 do
                local item = worldObjects:get(i):getItem()
                if item and item:getID() == args.noteId then

                    -- Update modData lokal
                    local md = item:getModData()
                    md.LMN_Admin = md.LMN_Admin or {}
                    md.LMN_Admin.lockPickup = args.locked
                    
                    -- Update cache global biar gampang diakses
                    if not LMN.ClientLockedNotes then LMN.ClientLockedNotes = {} end
                    LMN.ClientLockedNotes[args.noteId] = args.locked
                    
                    -- Update UI panel KALO LAGI OPEN
                    if LMN_AdminPanelUI and LMN_AdminPanelUI.panel then
                        local panel = LMN_AdminPanelUI.panel
                        if panel.noteItem and panel.noteItem:getID() == args.noteId then
                            -- Update checkbox ke-3
                            for i, cb in ipairs(panel.checkboxes) do
                                if cb.id == 3 then
                                    cb.selected = args.locked
                                    break
                                end
                            end
                        end
                    end
                    
                    break
                end
            end
        end
    end
end

Events.OnServerCommand.Add(OnServerCommand_LMN)

-- fungsi biar cek cache dulu
local original_isLocked = isLocked
isLocked = function(item)
    if not item then return false end
    
    -- Cek cache dulu (lebih cepat)
    local noteId = item:getID()
    if LMN.ClientLockedNotes and LMN.ClientLockedNotes[noteId] ~= nil then
        return LMN.ClientLockedNotes[noteId]
    end
    
    -- Fallback ke modData
    local md = item:getModData()
    return md and md.LMN_Admin and md.LMN_Admin.lockPickup == true
end