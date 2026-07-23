
--  ♡ 𝒜𝓂𝑒𝓁𝒾𝒶𝒦𝑒𝓃𝓎𝒶 𝒫𝒵 𝓂𝑜𝒹𝓈 ♡
--    𝐿𝑒𝒶𝓋𝑒 𝒶 𝓂𝑒𝓈𝓈𝒶𝑔𝑒 𝐵𝟦𝟤 

LMN_AdminClient = {}

function LMN_AdminClient.startSelfDestruct(playerObj, noteItem, worldObj)
    if not noteItem or not worldObj then return end
    
    local md = noteItem:getModData()
    if md.LMN_Admin and md.LMN_Admin.isExploding then return end

    local count = 5
    local ticks = 0
    
    if isClient() then
        sendClientCommand(playerObj, "LMN", "LockNoteWeight", {
            noteId = noteItem:getID(), 
            weight = 1000.0,
            x = worldObj:getX(),
            y = worldObj:getY(),
            z = worldObj:getZ()
        })
    end

    local function countdownTick()
        ticks = ticks + 1
        
        if not worldObj or not worldObj:getSquare() then
            Events.OnTick.Remove(countdownTick)
            return
        end

        if ticks >= 60 then
            ticks = 0
            if count > 0 then
                playerObj:Say(tostring(count) .. "...")
                count = count - 1
            else
                playerObj:Say("The note is destroyed")
                Events.OnTick.Remove(countdownTick)
                
                if isClient() then
                    local sq = worldObj:getSquare()
                    sendClientCommand(playerObj, "LMN", "AdminDestroyNote", {
                        noteId = noteItem:getID(), 
                        worldX = sq:getX(),
                        worldY = sq:getY(),
                        worldZ = sq:getZ(),
                        worldItemIndex = worldObj:getObjectIndex()
                    })
                else
                    worldObj:getSquare():transmitRemoveItemFromSquare(worldObj)
                end
            end
        end
    end
    
    playerObj:Say(tostring(count) .. "...")
    count = count - 1
    Events.OnTick.Add(countdownTick)
end