
--  ♡ 𝒜𝓂𝑒𝓁𝒾𝒶𝒦𝑒𝓃𝓎𝒶 𝒫𝒵 𝓂𝑜𝒹𝓈 ♡
--    𝐿𝑒𝒶𝓋𝑒 𝒶 𝓂𝑒𝓈𝓈𝒶𝑔𝑒 𝐵𝟦𝟤 --

require "LMN_Utils"

local function resolvePlayer(p)
    if not p then return nil end
    if type(p) == "number" then
        return getSpecificPlayer(p)
    end
    return p
end

local function isItemInPlayerInventory(player, item)
    if not player or not item or not item.getID then return false end
    local inv = player:getInventory()
    if not inv or not inv.getItems then return false end
    local items = inv:getItems()
    for i = 0, items:size()-1 do
        local it = items:get(i)
        if it and it.getID and it:getID() == item:getID() then
            return true
        end
    end
    return false
end

local function onLeaveMessage(note, player)
    player = resolvePlayer(player) or getPlayer()
    if not player or not note then return end

    if not instanceof(note, "InventoryItem") then
        return
    end

    local inInv = isItemInPlayerInventory(player, note)
    local hasTool = LMN.playerHasWritingTool(player)

    if not hasTool and not inInv then
        player:Say("I need a pen and this note in my inventory first.")
        return
    elseif not hasTool then
        player:Say("I need a pen or pencil.")
        return
    elseif not inInv then
        player:Say("I need to move this note to my inventory first.")
        return
    end

    -- kedua syarat terpenuhi
    if LMN_OpenUI then
        LMN_OpenUI(note, player)
    end
end

local function onFillContextMenu(playerIndex, context, items)
    local player = resolvePlayer(playerIndex)
    if not player then return end

    -- Sandbox Options
    local isAdminOnly = false
    if SandboxVars.LMN and SandboxVars.LMN.AdminOnlyLeaveMessage ~= nil then
        isAdminOnly = SandboxVars.LMN.AdminOnlyLeaveMessage
    end

    local canLeaveMessage = true
    if isAdminOnly then
        if not LMN.isAdmin(player) then
            canLeaveMessage = false
        end
    end

    for _, v in ipairs(items) do
        local item = v
        if type(v) == "table" and v.items and v.items[1] then
            item = v.items[1]
        end

        -- Cek apakah item adalah Note
        if item and instanceof(item, "InventoryItem") and item.getFullType and item:getFullType() == "Base.Note" then
            
            -- Jika lolos pengecekan izin, tampilkan menunya
            if canLeaveMessage then
                local hasTool = LMN.playerHasWritingTool(player)

                local option = context:addOption(
                    getText("Leave a message") or "Leave a message",
                    item,
                    onLeaveMessage,
                    player
                )

                -- Pengecekan alat tulis tetap aktif
                if not hasTool then
                    option.notAvailable = true
                    option.toolTip = ISToolTip:new()
                    option.toolTip.description = "You need a pen or pencil."
                end
            end

            -- Berhenti setelah menemukan Note agar menu tidak duplikat
            return
        end
    end
end
Events.OnFillInventoryObjectContextMenu.Add(onFillContextMenu)