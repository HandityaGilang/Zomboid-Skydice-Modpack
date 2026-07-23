
--  ♡ 𝒜𝓂𝑒𝓁𝒾𝒶𝒦𝑒𝓃𝓎𝒶 𝒫𝒵 𝓂𝑜𝒹𝓈 ♡
--    𝐿𝑒𝒶𝓋𝑒 𝒶 𝓂𝑒𝓈𝓈𝒶𝑔𝑒 𝐵𝟦𝟤 
 
if not isServer() then return end

local function OnClientCommand_LMN_Admin(module, command, player, args)
    if module ~= "LMN" then return end
    
    -- status Admin
    if command == "SetDestroyMode" then
        local sq = getSquare(args.x, args.y, args.z)
        if sq then
            local worldObjects = sq:getWorldObjects()
            for i=0, worldObjects:size()-1 do
                local item = worldObjects:get(i):getItem()
                if item and item:getID() == args.noteId then
                    local md = item:getModData()
                    md.LMN_Admin = md.LMN_Admin or {}
                    md.LMN_Admin.destroyAfterOpen = args.active
                    item:transmitModData()
                    item:transmitCompleteItemToClients()
                    break
                end
            end
        end
    end

    -- Berat & Tandai
    if command == "LockNoteWeight" then
        local sq = getSquare(args.x, args.y, args.z)
        if sq then
            local worldObjects = sq:getWorldObjects()
            for i=0, worldObjects:size()-1 do
                local item = worldObjects:get(i):getItem()
                if item and item:getID() == args.noteId then
                    local md = item:getModData()
                    md.LMN_Admin = md.LMN_Admin or {}
                    md.LMN_Admin.isExploding = true 
                    
                    item:setActualWeight(args.weight)
                    item:setCustomWeight(true)
                    item:transmitModData()
                    item:transmitCompleteItemToClients()
                    break
                end
            end
        end
    end

    -- Hapus note
    if command == "AdminDestroyNote" then
        local sq = getSquare(args.worldX, args.worldY, args.worldZ)
        if sq then
            local worldObjects = sq:getWorldObjects()
            for i=0, worldObjects:size()-1 do
                local worldObj = worldObjects:get(i)
                local item = worldObj:getItem()
                if item and item:getID() == args.noteId then
                    sq:transmitRemoveItemFromSquare(worldObj)
                    break
                end
            end
        end
    end
end

Events.OnClientCommand.Add(OnClientCommand_LMN_Admin)