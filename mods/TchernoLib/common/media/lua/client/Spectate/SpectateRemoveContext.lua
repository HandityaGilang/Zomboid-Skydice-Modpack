
require 'Spectate/ShSpectate'

function Spectate.doSpectatingRightClick(player, worldobjects, x, y, test)
    local playerObj = getSpecificPlayer(player)
    
    local clickedPlayer = nil
    local square = nil
    for i,worldObj in ipairs(worldobjects) do
        if worldObj then
            if instanceof(worldObj, "IsoPlayer") and (worldObj ~= playerObj) and not Spectate.isSpectating(worldObj) then
                clickedPlayer = worldObj;
                break
            elseif square == nil and worldObj.getSquare then
                square = worldObj:getSquare()
            end
        end
    end
    
    --check players on contiguous squares
    if square and not clickedPlayer then
        -- help detecting a player by checking nearby squares
        for x=square:getX()-1,square:getX()+1 do
            for y=square:getY()-1,square:getY()+1 do
                local sq = getCell():getGridSquare(x,y,square:getZ());
                if sq and square ~= sq then
                    for i=0,sq:getMovingObjects():size()-1 do
                        local o = sq:getMovingObjects():get(i)
                        if instanceof(o, "IsoPlayer") and (o ~= playerObj) and not Spectate.isSpectating(o) then
                            clickedPlayer = o
                        end
                    end
                end
            end
        end
    end
    
    if clickedPlayer and playerObj then
        ISTimedActionQueue.add(ISSpectatorMedicalCheckAction:new(playerObj,clickedPlayer))
    end

    return nil
end

---click removals / replace---

--Remove:
--context:addOption(getText("ContextMenu_Medical_Check"), worldobjects, ISWorldObjectContextMenu.onMedicalCheck, playerObj, clickedPlayer)
--context:addOption("Check Stats", worldobjects, ISWorldObjectContextMenu.onCheckStats, playerObj, clickedPlayer)
--context:addOption(getText("ContextMenu_Trade", clickedPlayer:getDisplayName()), worldobjects, ISWorldObjectContextMenu.onTrade, playerObj, clickedPlayer)
local ul_ISContextMenu_addOption = ISContextMenu.addOption
function ISContextMenu:addOption(name, target, onSelect, param1, param2, param3, param4, param5, param6, param7, param8, param9, param10)
    if instanceof(param2, "IsoPlayer") and Spectate.isSpectating(param2) then return {} end
    return ul_ISContextMenu_addOption(self, name, target, onSelect, param1, param2, param3, param4, param5, param6, param7, param8, param9, param10)
end

---remove right click menu on Spectators => as a consequence, rightclick on potential non spectator is not retrieved, yet.
local ul_ISWorldObjectContextMenu_fetch = ISWorldObjectContextMenu.fetch
ISWorldObjectContextMenu.fetch = function(v, player, doSquare)
    local playerObj = getSpecificPlayer(player)
    if instanceof(v, "IsoPlayer") and v ~= playerObj and Spectate.isSpectating(v) then return end--remove right click on spectating player
    
    ul_ISWorldObjectContextMenu_fetch(v, player, doSquare)
    
    if Spectate.isSpectating(clickedPlayer) then
        --print ('Inhibit clickedPlayer.')
        if playerObj then
            --playerObj:Say('Inhibit clickedPlayer '..tostring(clickedPlayer or 'nil'))
            clickedPlayer = nil
        end
    end
end


---replace right click on world as spectator
local ul_ISWorldObjectContextMenu_createMenu = ISWorldObjectContextMenu.createMenu
ISWorldObjectContextMenu.createMenu = function(player, worldobjects, x, y, test)
    local playerObj = getSpecificPlayer(player)
    if Spectate.isSpectating(playerObj) then
        return Spectate.doSpectatingRightClick(player, worldobjects, x, y, test)
    else
        return ul_ISWorldObjectContextMenu_createMenu(player, worldobjects, x, y, test)
    end
end

---remove right click disassemble as spectator
local ul_ISMoveableSpriteProps_OnDynamicMovableRecipe = ISMoveableSpriteProps.OnDynamicMovableRecipe
function ISMoveableSpriteProps.OnDynamicMovableRecipe(_sprite, _recipe, _item, _player)
    if not Spectate.isSpectating(_player) then
        ul_ISMoveableSpriteProps_OnDynamicMovableRecipe(_sprite, _recipe, _item, _player)
    end
end

local ul_ISWorldMenuElements_ContextDebugHighlights = ISWorldMenuElements.ContextDebugHighlights
function ISWorldMenuElements.ContextDebugHighlights()
    if Spectate.isSpectating(getPlayer()) then
        return ISMenuElement.new();
    else
        return ul_ISWorldMenuElements_ContextDebugHighlights()
    end
end

local ul_ISWorldMenuElements_ContextDisassemble = ISWorldMenuElements.ContextDisassemble
function ISWorldMenuElements.ContextDisassemble()
    if Spectate.isSpectating(getPlayer()) then
        return ISMenuElement.new();
    else
        return ul_ISWorldMenuElements_ContextDisassemble()
    end
end

local ul_ISWorldMenuElements_ContextTelevision = ISWorldMenuElements.ContextTelevision
function ISWorldMenuElements.ContextTelevision()
    if Spectate.isSpectating(getPlayer()) then
        return ISMenuElement.new();
    else
        return ul_ISWorldMenuElements_ContextTelevision()
    end
end


---Moveable
local ul_function ISMoveablesAction_isValid = ISMoveablesAction.isValid
function ISMoveablesAction:isValid()
    if Spectate.isSpectating(self.character) then
        return false
    else
        return ISMoveablesAction_isValid(self)
    end
end

---remove right click on inventory as spectator
local ul_ISInventoryPaneContextMenu_createMenu = ISInventoryPaneContextMenu.createMenu
ISInventoryPaneContextMenu.createMenu = function(player, isInPlayerInventory, items, x, y, origin)
    local playerObj = getSpecificPlayer(player)
    if not Spectate.isSpectating(playerObj) then
        return ul_ISInventoryPaneContextMenu_createMenu(player, isInPlayerInventory, items, x, y, origin)
    end
    return nil
end

---remove all transfer on spectators
local ul_ISInventoryTransferAction_new = ISInventoryTransferAction.new
function ISInventoryTransferAction:new(character, item, srcContainer, destContainer, time)
    local o = ul_ISInventoryTransferAction_new(self, character, item, srcContainer, destContainer, time)
    
    if o and Spectate.isSpectating(character) then
        o.item = nil
        o.queueList = {}
        o.loopedAction = false
    end
    return o
end

