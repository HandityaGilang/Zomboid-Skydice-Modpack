
--  ♡ 𝒜𝓂𝑒𝓁𝒾𝒶𝒦𝑒𝓃𝓎𝒶 𝒫𝒵 𝓂𝑜𝒹𝓈 ♡
--    𝐿𝑒𝒶𝓋𝑒 𝒶 𝓂𝑒𝓈𝓈𝒶𝑔𝑒 𝐵𝟦𝟤 

LMN_AdminClient1 = {}

function LMN_AdminClient1.sendHideMode(playerObj, noteItem, isSelected)
    if not noteItem then return end
    
    local worldItem = noteItem:getWorldItem()
    if not worldItem then return end

    if isClient() then
        sendClientCommand(playerObj, "LMN", "SetHideMode", {
            noteId = noteItem:getID(),
            active = isSelected,
            x = worldItem:getX(),
            y = worldItem:getY(),
            z = worldItem:getZ()
        })
    end
end