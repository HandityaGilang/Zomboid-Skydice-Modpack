
--  ♡ 𝒜𝓂𝑒𝓁𝒾𝒶𝒦𝑒𝓃𝓎𝒶 𝒫𝒵 𝓂𝑜𝒹𝓈 ♡
--    𝐿𝑒𝒶𝓋𝑒 𝒶 𝓂𝑒𝓈𝓈𝒶𝑔𝑒 𝐵𝟦𝟤 

if not isServer() and not isClient() then return end

local function OnClientCommand_LMN(module, command, player, args)
    if module ~= "LMN" then return end
    
    if command == "SetPickupLock" then
        -- Cari item di square 
        local sq = getSquare(args.x, args.y, args.z)
        if sq then
            local worldObjects = sq:getWorldObjects()
            for i=0, worldObjects:size()-1 do
                local item = worldObjects:get(i):getItem()
                if item and item:getID() == args.noteId then
                    -- Tulis data ke item secara permanen, bandel bgt di MP
                    local md = item:getModData()
                    md.LMN_Admin = md.LMN_Admin or {}
                    md.LMN_Admin.lockPickup = args.locked
                    
                    -- Paksa sinkron ke semua client (Termasuk yang baru join nanti)
                    item:transmitModData()
                    item:transmitCompleteItemToClients()

                    sendServerCommand(nil, "LMN", "SyncPickupLock", {  -- nil = semua player
                        noteId = item:getID(),
                        locked = args.locked,
                        x = args.x,
                        y = args.y,
                        z = args.z
                    })
                    
                    break
                end
            end
        end
    end
end
Events.OnClientCommand.Add(OnClientCommand_LMN)
