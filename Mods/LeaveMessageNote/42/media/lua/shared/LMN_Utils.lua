
--  ♡ 𝒜𝓂𝑒𝓁𝒾𝒶𝒦𝑒𝓃𝓎𝒶 𝒫𝒵 𝓂𝑜𝒹𝓈 ♡
--    𝐿𝑒𝒶𝓋𝑒 𝒶 𝓂𝑒𝓈𝓈𝒶𝑔𝑒 𝐵𝟦𝟤 

require "TimedActions/ISBaseTimedAction"

LMN = LMN or {}

LMN.WritingItems = {
    "Base.Pencil",
    "Base.Pen",
    "Base.BluePen",
    "Base.RedPen",
    "Base.BlackPen"
}

function LMN.playerHasWritingTool(player)
    if not player then return false end
    local inv = player:getInventory()

    for _, fullType in ipairs(LMN.WritingItems) do
        if inv:containsTypeRecurse(fullType) then
            return true
        end
    end

    return false
end

function LMN.getNoteMessage(note)
    local md = note:getModData()
    return md.leaveMessage
end

function LMN.setNoteMessage(note, text)
    local md = note:getModData()
    if text == nil or text == "" then
        md.leaveMessage = nil
    else
        md.leaveMessage = text
    end
end

function LMN.isAdmin(player)
    if not player then return false end
        if not isClient() and not isServer() then
        return true
    end
    return player:isAccessLevel("Admin") or player:isAccessLevel("Moderator")
end

function LMN.getAdminSettings(item)
    if not item then return nil end

    local md = item:getModData()
    md.adminSettings = md.adminSettings or {
        hideDontShowAgain = false,
        destroyAfterOpen = false,
        lockPickup = false
    }

    return md.adminSettings
end

