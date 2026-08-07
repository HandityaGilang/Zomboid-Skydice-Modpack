
Spawn = Spawn or {}
Spawn.SpawnKey = Spawn.SpawnKey or 'spawn'
----exemple of TimeAction add
--function Spawn.addInspectOption(playerNum, context, worldobjects, test)
--    if not context then return end
--    local player = getSpecificPlayer(playerNum)
--    if not player then return end
--    local xUI = context:getX()
--    local yUI = context:getY()
--    local xIso  = screenToIsoX(playerNum, xUI, yUI, player:getZ());
--    local yIso  = screenToIsoY(playerNum, xUI, yUI, player:getZ());
--    local square = getCell():getGridSquare(xIso, yIso, player:getZ())
--    if not square then return end
--    --todo maybe add conditions isSolid, isSolidTransient, isWater, ..
--    local optionText = getText("IGUI_CreatePortal")
--    local option = context:addOption(optionText, player, addCreatePortalAction, square)
--end
function Spawn.isSpawner(isoObject)
    if not isoObject then return false end
    local md = isoObject:getModData()
    return md and md[Spawn.SpawnKey] ~= nil 
end

function Spawn.getObjectToInvestigateFromTab(worldobjects)
    for iter,isoObj in ipairs(worldobjects) do
        if Spawn.isSpawner(isoObj) then
            return isoObj
        end
    end
    return nil
end

function Spawn.getObjectToInvestigateFromSquare(square)
    if not square then return end
    if square.getObjects then
        local objects = square:getObjects()
        for i = 0, objects:size()-1 do
            local obj = objects:get(i);
            if Spawn.isSpawner(obj) then
                return obj
            end
        end
    end
    return nil
end

function Spawn.investigate(character, square)
    if not character then return end
    if not square then return end
    local isoObj = Spawn.getObjectToInvestigateFromSquare(square)
    if not isoObj then return end--could happen in MP
    local spawnInfo = isoObj:getModData()[Spawn.SpawnKey]
    
    local item = nil
    if spawnInfo.items then
        local nbItem = 0
        --TODO send server request and to get the items(s)
        for k,val in pairs(spawnInfo.items) do
            if val then
                if item == nil then
                    item = val
                    spawnInfo.items[k] = nil
                else
                    nbItem = nbItem + 1
                end
            end
        end
        if nbItem == 0 then
            isoObj:getModData()[Spawn.SpawnKey] = nil
        end
    end
    
    if item then
        local inventoryItem = character:getInventory():AddItem(item)
        character:Say(getText('IGUI_Spawn_Investigate',inventoryItem:getName()))
        isoObj:transmitModData()
    end
end

function Spawn.startInvestigate(character, pos)
    if not character then return end
    if not pos or not pos.x or not pos.y or not pos.z then return end
    local square = getCell():getGridSquare(pos.x,pos.y,pos.z)
    if not square then return end
    if luautils.walkAdj(character, square, true) then
        ISTimedActionQueue.add(ISInvestigateTimedAction:new(character, square, 200));
    end
end

local ul_ISSearchWindow_OnFillWorldObjectContextMenu = ISSearchWindow.OnFillWorldObjectContextMenu
function ISSearchWindow.OnFillWorldObjectContextMenu(player, context, worldobjects, test)
    local override = false
    local isoObject = Spawn.getObjectToInvestigateFromTab(worldobjects)
    if Spawn.Verbose then print ('Spawn spawnOnInvestigate build menu for '..tostring(isoObject or 'nil')) end
    if isoObject then
        local character = getSpecificPlayer(player)
        local inspectOption = context:addOption(getText("UI_investigate_area_window_show"), character, Spawn.startInvestigate, sq2tab(isoObject:getSquare()));
        local tooltip = ISToolTip:new();
        tooltip:initialise();
        tooltip:setVisible(true);
        local nb = ZombRand(1,4)
        --print ('ZombRand_1_3 '..nb)
        tooltip.description = getText("IGUI_Spawn_Tooltip"..nb)
        inspectOption.toolTip = tooltip
        
        override = true
    end
    if not override then
        ul_ISSearchWindow_OnFillWorldObjectContextMenu(player, context)
    end
end
Events.OnFillWorldObjectContextMenu.Remove(ul_ISSearchWindow_OnFillWorldObjectContextMenu);
Events.OnFillWorldObjectContextMenu.Add(ISSearchWindow.OnFillWorldObjectContextMenu);

