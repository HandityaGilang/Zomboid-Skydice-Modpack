
--  ♡ 𝒜𝓂𝑒𝓁𝒾𝒶𝒦𝑒𝓃𝓎𝒶 𝒫𝒵 𝓂𝑜𝒹𝓈 ♡
--    𝐿𝑒𝒶𝓋𝑒 𝒶 𝓂𝑒𝓈𝓈𝒶𝑔𝑒 𝐵𝟦𝟤 

if not isServer() then return end

local function OnClientCommand_LMN_Admin1(module, command, player, args)
    if module ~= "LMN" then return end
    
    -- Admin atur biar gak munculin lagi
    if command == "SetHideMode" then
        local sq = getSquare(args.x, args.y, args.z)
        if sq then
            local worldObjects = sq:getWorldObjects()
            for i=0, worldObjects:size()-1 do
                local item = worldObjects:get(i):getItem()
                if item and item:getID() == args.noteId then
                    local md = item:getModData()
                    md.LMN_Admin = md.LMN_Admin or {}
                    md.LMN_Admin.hideDontShow = args.active
                    
                    item:transmitModData()
                    item:transmitCompleteItemToClients()
                    break
                end
            end
        end
    end
end

Events.OnClientCommand.Add(OnClientCommand_LMN_Admin1)