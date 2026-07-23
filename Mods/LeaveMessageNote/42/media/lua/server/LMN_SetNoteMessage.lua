
--  ♡ 𝒜𝓂𝑒𝓁𝒾𝒶𝒦𝑒𝓃𝓎𝒶 𝒫𝒵 𝓂𝑜𝒹𝓈 ♡
--    𝐿𝑒𝒶𝓋𝑒 𝒶 𝓂𝑒𝓈𝓈𝒶𝑔𝑒 𝐵𝟦𝟤 

if not isServer() then return end

require "shared/LMN_Utils"

local function onClientCommand(module, command, player, args)
    if module ~= "LMN" then return end

    if command == "SetNoteMessage" then
        if not args then return end

        local text = args.text or ""
        local item = nil

        -- 1) kalau containerType == playerInv -> ambil langsung dari source player inventory index
        if args.containerType == "playerInv" and player and player.getInventory and args.containerIndex then
            local inv = player:getInventory()
            if inv and inv.getItems then
                local items = inv:getItems()
                if items and args.containerIndex >= 0 and args.containerIndex < items:size() then
                    item = items:get(args.containerIndex)
                end
            end
        end

        -- 2) kalau world -> cari di square berdasarkan worldX/worldY/worldZ + worldItemIndex
        if not item and args.containerType == "world" and args.worldX and args.worldY and args.worldZ then
            local sq = getCell():getGridSquare(args.worldX, args.worldY, args.worldZ)
            if sq then
                for i=0, sq:getObjects():size()-1 do
                    local obj = sq:getObjects():get(i)
                    if obj and obj.getItemContainer then
                        local c = obj:getItemContainer()
                        if c and c.getItems then
                            local itms = c:getItems()
                            for j=0, itms:size()-1 do
                                local it = itms:get(j)
                                if it and it.getWorldItem and it:getWorldItem() and it:getWorldItem().getObjectIndex and args.worldItemIndex and it:getWorldItem():getObjectIndex() == args.worldItemIndex then
                                    item = it
                                    break
                                end
                            end
                        end
                    end
                    if item then break end
                end
            end
        end

        -- 3) scan di inventory semua pemain (fallback)
        if not item then
            local players = getOnlinePlayers()
            if players then
                for i = 0, players:size()-1 do
                    local p = players:get(i)
                    if p and p.getInventory then
                        local its = p:getInventory():getItems()
                        for j = 0, its:size()-1 do
                            local it = its:get(j)
                            if it and it.getID and args.noteId and it:getID() == args.noteId then
                                item = it
                                break
                            end
                        end
                    end
                    if item then break end
                end
            end
        end

        if not item then
            return
        end

        -- set modData di server
        local md = item:getModData()
        if text == "" then md.leaveMessage = nil else md.leaveMessage = text end

        -- Kalu item pass, gass!!
        if item.transmitModData then
            item:transmitModData()
        end

        -- relay ke clients (kecuali source player) biar client lain bisa update UI / cache mereka
        local players = getOnlinePlayers()
        if players then
            for i = 0, players:size()-1 do
                local p = players:get(i)
                if p and p ~= player then
                    sendServerCommand(p, "LMN", "SyncNoteMessage", {
                        containerType = args.containerType,
                        containerIndex = args.containerIndex,
                        worldX = args.worldX,
                        worldY = args.worldY,
                        worldZ = args.worldZ,
                        worldItemIndex = args.worldItemIndex,
                        noteId = args.noteId,
                        text = text
                    })
                end
            end
        end
    end
end

Events.OnClientCommand.Add(onClientCommand)