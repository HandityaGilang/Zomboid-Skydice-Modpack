
--  ♡ 𝒜𝓂𝑒𝓁𝒾𝒶𝒦𝑒𝓃𝓎𝒶 𝒫𝒵 𝓂𝑜𝒹𝓈 ♡
--    𝐿𝑒𝒶𝓋𝑒 𝒶 𝓂𝑒𝓈𝓈𝒶𝑔𝑒 𝐵𝟦𝟤 

require "TimedActions/ISInventoryTransferAction"

-- Fungsi deteksi lock
local function isLocked(item)
    if not item then return false end
    
    -- Cek cache global dulu
    if LMN.ClientLockedNotes and LMN.ClientLockedNotes[item:getID()] ~= nil then
        return LMN.ClientLockedNotes[item:getID()]
    end
    
    local md = item:getModData()
    return md and md.LMN_Admin and md.LMN_Admin.lockPickup == true
end

-- Muehehe iseng
local lockMessages = {
    "The note is locked",
    "You don't have permission to take this",
    "Admin has secured this item",
    "Access denied!",
    "Stop trying, it's locked!",
    "bruh i told u",
    "stop",
    "doing",
    "that",
    "...",
    "yea yea.. it's up to you",
    "what?",
    "just stop bro",
    "Fahh",
    "Bodo amat"
}
local currentMsgIndex = 1
local lastSayTime = 0 -- Biar gak spam :)

-- Hook Inven
local original_isValid = ISInventoryTransferAction.isValid
function ISInventoryTransferAction:isValid()
    if self.item and isLocked(self.item) then
        if self.destContainer == self.character:getInventory() then
            
            local currentTime = getTimeInMillis()
            
            if self.character:isLocalPlayer() and (currentTime - lastSayTime > 500) then
                local msg = lockMessages[currentMsgIndex]
                self.character:Say(msg)
                
                currentMsgIndex = currentMsgIndex + 1
                if currentMsgIndex > #lockMessages then
                    currentMsgIndex = 1
                end
                
                lastSayTime = currentTime
            end
            
            return false
        end
    end
    return original_isValid(self)
end

-- Hook Berat + Forage
local function updateNoteWeight(character, isSearchMode)
    if not character:isLocalPlayer() then return end

    local pX, pY, pZ = character:getX(), character:getY(), character:getZ()
    local range = 20
    local cell = getCell()

    for x = pX - range, pX + range do
        for y = pY - range, pY + range do
            local square = cell:getGridSquare(x, y, pZ)
            if square then
                local worldObjects = square:getWorldObjects()
                for i = 0, worldObjects:size() - 1 do
                    local worldObj = worldObjects:get(i)
                    local item = worldObj and worldObj:getItem()
                    
                    if item and item:getFullType() == "Base.Note" and isLocked(item) then
                        if isSearchMode then
                            item:setActualWeight(1000.0)
                            item:setCustomWeight(true)
                        else
                            item:setActualWeight(0.1)
                            item:setCustomWeight(false)
                        end
                    end
                end
            end
        end
    end
end


local function LMN_OnEnableSearchMode(character, isSearchMode)
    updateNoteWeight(character, true)
end

local function LMN_OnDisableSearchMode(character, isSearchMode)
    updateNoteWeight(character, false)
end

Events.onEnableSearchMode.Add(LMN_OnEnableSearchMode)
Events.onDisableSearchMode.Add(LMN_OnDisableSearchMode)

local function LMN_ResetWeightsOnJoin(playerNum, playerObj)
    if not playerObj then return end
    updateNoteWeight(playerObj, false)
end

Events.OnCreatePlayer.Add(LMN_ResetWeightsOnJoin)

-- Hook Grab
local function LMN_RemoveGrabOptionAlways(player, context, worldObjects)
    local playerObj = getSpecificPlayer(player)
    if not playerObj then return end

    local clickedSquare = nil
    for _, v in ipairs(worldObjects) do
        if instanceof(v, "IsoObject") then
            clickedSquare = v:getSquare()
            break
        end
    end

    if not clickedSquare then return end
    for x = -1, 1 do
        for y = -1, 1 do
            local sq = getCell():getGridSquare(clickedSquare:getX() + x, clickedSquare:getY() + y, clickedSquare:getZ())
            if sq then
                local objects = sq:getWorldObjects()
                for i = 0, objects:size() - 1 do
                    local worldObj = objects:get(i)
                    local item = worldObj:getItem()
                    if item and item:getFullType() == "Base.Note" and isLocked(item) then
                        context:removeOptionByName(getText("ContextMenu_Grab"))
                        context:removeOptionByName(getText("ContextMenu_Grab_all"))
                    end
                end
            end
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(LMN_RemoveGrabOptionAlways)