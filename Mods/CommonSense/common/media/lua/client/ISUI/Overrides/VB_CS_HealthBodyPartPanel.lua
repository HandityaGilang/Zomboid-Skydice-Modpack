-- ************************************************************************
-- **                  ██  ██    ██ ██ ████████  █████                   **
-- **                ████  ██    ██ ██    ██   ██   ██                   **
-- **              ██  ██  ██    ██ ██    ██   ███████                   **
-- **                  ██   ██  ██  ██    ██   ██   ██                   **
-- **                  ██    ████   ██    ██   ██   ██                   **
-- **                https://steamcommunity.com/id/1vita                 **
-- ************************************************************************
-- **        The following content was crafted from the ground up,       **
-- **       writing my own lines, but also taking inspiration from       **
-- **       others' work to better understand the game's workflow.       **
-- **                So, as it should be with every mod,                 **
-- **                   >>> USE IT AS YOU PLEASE <<<                     **
-- ************************************************************************
-- **            Let's make Project Zomboid greater togheter!            **
-- ************************************************************************

local doBodyPartContextMenu = ISHealthPanel.doBodyPartContextMenu

---@param bodyPart BodyPart
---@return boolean
local function isStillInjured(bodyPart)
    return bodyPart:getBleedingTime() > 0
    or bodyPart:getCutTime() > 0
    or bodyPart:getScratchTime() > 0
    or bodyPart:getDeepWoundTime() > 0
    or bodyPart:getFractureTime() > 0
    or bodyPart:getStitchTime() > 0
    or bodyPart:getBurnTime() > 0
    or bodyPart:getBiteTime() > 0
    or bodyPart:haveBullet()
end

---@param target unknown
---@param doctor IsoPlayer
---@param otherPlayer IsoPlayer
---@param item InventoryItem
---@param bodyPart BodyPart
---@param transferNeeded boolean
local function replaceBandage(target, doctor, otherPlayer, item, bodyPart, transferNeeded)
    if transferNeeded then ISWorldObjectContextMenu.transferIfNeeded(doctor, item) end
    local removeBandage = ISApplyBandage:new(doctor, otherPlayer, item, bodyPart, false)
    ISTimedActionQueue.add(removeBandage)
    local applyBandage = ISApplyBandage:new(doctor, otherPlayer, item, bodyPart, true)
    ISTimedActionQueue.addAfter(removeBandage, applyBandage)
end

---@param bodyPart BodyPart
---@param x number
---@param y number
function ISHealthPanel:doBodyPartContextMenu(bodyPart, x, y)
    doBodyPartContextMenu(self, bodyPart, x, y)
	if not SandboxVars.CommonSense.ReplaceBandage then return end
    local doctor = self.otherPlayer or self.character --[[@cast doctor IsoPlayer]]
    local patient = self.character
    local context = getPlayerContextMenu(doctor:getPlayerNum())
    if not context then return end
    local bandageOpt = context:getOptionFromName(getText("ContextMenu_Remove_Bandage"))
    if not bandageOpt or not bodyPart:isBandageDirty() then return end
    if not isStillInjured(bodyPart) then return end

    local inventoryItems = doctor:getInventory():getItemsFromCategory("Item")
    local cleanBandage = nil
    local transferNeeded = false
    for i=0, inventoryItems:size()-1 do
        local item = inventoryItems:get(i)
        local isCleanBandage = item:getBandagePower() > 0.5
        local isSterilized = string.match(item:getFullType(), "Alcohol")
        if isCleanBandage then
            cleanBandage = item
            if isSterilized then break end
        end
    end
    if not cleanBandage then
        local squares = {} --[[@as (IsoGridSquare[])]]
        BB_CS_Utils.getSquaresInRadius(doctor:getX(), doctor:getY(), doctor:getZ(), 1, {}, squares)
        local itemsInRadius = BB_CS_Utils.getItemsInSquares(squares, {})
        for i=0, itemsInRadius:size()-1 do
            local item = itemsInRadius:get(i)
            local isCleanBandage = item:getBandagePower() > 0.5
            local isSterilized = string.match(item:getFullType(), "Alcohol")
            if isCleanBandage then
                transferNeeded = true
                cleanBandage = item
                if isSterilized then break end
            end
        end
        if not cleanBandage then return end
    end

    local replaceBandageOpt = context:addOptionOnTop(getText("ContextMenu_CS_Replace_Bandage"), self, replaceBandage, doctor, patient, cleanBandage, bodyPart, transferNeeded)
    replaceBandageOpt.itemForTexture = cleanBandage --[[@diagnostic disable-line: inject-field]]
end