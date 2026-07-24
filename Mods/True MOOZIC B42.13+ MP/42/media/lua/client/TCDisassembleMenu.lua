-- TCDisassembleMenu module pattern for all helpers and handlers
local TCDisassembleMenu = {}

local DEBUG = false
local function dlog(...)
    if DEBUG then
        print(...)
    end
end



TCDisassembleMenu.TC_ELECTRONIC_TOOLS = {
    "Base.Screwdriver",
    "Base.Screwdriver_Improvised",
    "Base.SpearScrewdriver",
    "Base.Screwdriver_Old"
}


-- Use base game global classes for timed actions
-- Core requires moved to top to ensure globals exist during file load
require "ISUI/ISInventoryPaneContextMenu"
require "TimedActions/ISEquipWeaponAction"
require "TimedActions/ISWaitAction"
require "TCGenericDisassembleAction"
pcall(function() require "TCCassetteDisassembleLoot" end)

function TCDisassembleMenu.onDisassemble(playerObj, item)
    dlog("[TCDisassemble] onDisassemble called. Player: " .. tostring(playerObj) .. ", Item: " .. tostring(item))
    if playerObj and playerObj.getInventory then
        local inv = playerObj:getInventory()
        if inv and inv.getItems then
            local items = inv:getItems()
            dlog("[TCDisassemble] Player inventory contains " .. tostring(items:size()) .. " items.")
            for i=0,items:size()-1 do
                local it = items:get(i)
                if it and it.getFullType then
                    dlog("[TCDisassemble] Inventory item " .. tostring(i) .. ": " .. tostring(it:getFullType()))
                end
            end
        end
    end
    -- Handle ComboItem: extract real InventoryItem if needed
    if item and item.getItem and not instanceof(item, "InventoryItem") and instanceof(item, "ComboItem") then
        dlog("[TCDisassemble] Unwrapping ComboItem to InventoryItem.")
        item = item:getItem()
    end
    -- Strict type checking for multiplayer safety
    if not item or type(item) ~= "userdata" or not instanceof(item, "InventoryItem") then
        if playerObj and playerObj.Say then
            playerObj:Say("Error: Invalid item for disassembly.")
        end
        return
    end
    local fullType = item.getFullType and item:getFullType() or nil
    local itemType = item.getType and item:getType() or nil
    dlog("[TCDisassemble] Item fullType: " .. tostring(fullType) .. ", itemType: " .. tostring(itemType))
    if not fullType or not itemType then
        if playerObj and playerObj.Say then
            playerObj:Say("Error: Item missing type info.")
        end
        return
    end
    dlog("[TCDisassemble] onDisassemble called for " .. tostring(fullType))

    -- Close any active radio/boombox UI tied to this device before removing it.
    if ISRadioWindow and ISRadioWindow.closeIfActive then
        ISRadioWindow.closeIfActive(playerObj, item)
    end
    if ISTCBoomboxWindow and ISTCBoomboxWindow.closeIfActive then
        ISTCBoomboxWindow.closeIfActive(playerObj, item)
    end

    -- Auto-eject media before disassembling a device (SP only; MP is handled server-side to avoid dupes)
    local isDevice = itemType and (string.find(itemType, "TCWalkman") or string.find(itemType, "TCBoombox") or string.find(itemType, "TCVinylplayer"))
    if not isClient() and isDevice and TCCassetteDisassembleLoot and TCCassetteDisassembleLoot.DeviceHasMedia then
        if TCCassetteDisassembleLoot.DeviceHasMedia(item) and TCCassetteDisassembleLoot.ReturnMediaToInventory then
            TCCassetteDisassembleLoot.ReturnMediaToInventory(playerObj, item)
        end
    end
    -- Transfer item to inventory if needed
    ISInventoryPaneContextMenu.transferIfNeeded(playerObj, item)
    -- Get and transfer tool to inventory if needed
    dlog("[TCDisassemble] Calling getRequiredTool with playerObj and item.")
    local tool = TCDisassembleMenu.getRequiredTool(playerObj, item)
    dlog("[TCDisassemble] getRequiredTool returned: " .. tostring(tool and tool.getFullType and tool:getFullType() or tool))
    if tool then
        ISInventoryPaneContextMenu.transferIfNeeded(playerObj, tool)
    end
    -- Equip tool to off hand, then cassette to main hand, then start disassembly

    -- Helper: safely add timed actions ensuring `character` is set
    local function safeAdd(action)
        if type(action) ~= "table" then
            dlog("[TCDisassemble] Tried to queue non-table timed action.")
            return
        end
        if not action.character then
            action.character = playerObj
        end
        ISTimedActionQueue.add(action)
    end

    local function afterToolEquipped()
        -- Do not equip the target item (avoids radio UI popups); just start disassembly.
        -- TimedAction units: ~60 = 1 real second. Use ~5s base (300) to match vanilla feel.
        local disassembleTime = 300
        if ISWaitAction and ISWaitAction.new then
            local waitForTool = ISWaitAction:new(playerObj, 1)
            if type(waitForTool) == "table" then
                waitForTool.OnComplete = function()
                    if TCGenericDisassembleAction and TCGenericDisassembleAction.new then
                        local disAction = TCGenericDisassembleAction:new(playerObj, item, disassembleTime)
                        if type(disAction) == "table" then
                            safeAdd(disAction)
                        else
                            if playerObj and playerObj.Say then playerObj:Say("Error: Disassembly action unavailable.") end
                        end
                    else
                        if playerObj and playerObj.Say then playerObj:Say("Error: Disassembly action unavailable.") end
                    end
                end
                safeAdd(waitForTool)
            else
                dlog("[TCDisassemble] ISWaitAction:new returned nil; starting immediately.")
                if TCGenericDisassembleAction and TCGenericDisassembleAction.new then
                    local disAction = TCGenericDisassembleAction:new(playerObj, item, disassembleTime)
                    if type(disAction) == "table" then
                        safeAdd(disAction)
                    else
                        if playerObj and playerObj.Say then playerObj:Say("Error: Disassembly action unavailable.") end
                    end
                end
            end
        else
            dlog("[TCDisassemble] ISWaitAction class missing; starting immediately.")
            if TCGenericDisassembleAction and TCGenericDisassembleAction.new then
                local disAction = TCGenericDisassembleAction:new(playerObj, item, disassembleTime)
                if type(disAction) == "table" then
                    safeAdd(disAction)
                else
                    if playerObj and playerObj.Say then playerObj:Say("Error: Disassembly action unavailable.") end
                end
            end
        end
    end
    if tool and tool ~= item and instanceof(tool, "InventoryItem") then
        -- Guard creation/use of engine timed-action classes which may be nil
        if ISEquipWeaponAction then
            local equipToolAction = ISEquipWeaponAction:new(playerObj, tool, 50, false, false)
            safeAdd(equipToolAction)
        else
            dlog("[TCDisassemble] ISEquipWeaponAction is nil; skipping equip animation.")
        end

        if ISWaitAction then
            local waitAction = ISWaitAction:new(playerObj, 1)
            waitAction.OnComplete = afterToolEquipped
            safeAdd(waitAction)
        else
            -- If wait action isn't available, immediately continue to next step
            dlog("[TCDisassemble] ISWaitAction is nil; calling afterToolEquipped immediately.")
            afterToolEquipped()
        end
    elseif tool and not instanceof(tool, "InventoryItem") then
        return
    else
        if playerObj and playerObj.Say then
            playerObj:Say("Error: No valid tool for disassembly.")
        end
        return
    end
end
-- TM - Unstable Addons: Disassemble Context Menu
-- Adds "Disassemble" option directly to right-click menu

function TCDisassembleMenu.canDisassemble(item)
    if not item then return false end
    
    local fullType = item:getFullType()
    local itemType = item.getType and item:getType() or nil
    
    -- Check for cassettes (ANY module with "Cassette" in type name)
    if itemType and string.find(itemType, "Cassette") then
        return true
    end
    
    -- Check for electronics
    if itemType and (string.find(itemType, "TCWalkman") or string.find(itemType, "TCBoombox") or string.find(itemType, "TCVinylplayer")) then
        return true
    end
    
    return false
end

function TCDisassembleMenu.hasRequiredTool(player, item)
    local inv = player:getInventory()
    local fullType = item:getFullType()
    -- Electronics need any screwdriver variant
        for _, tool in ipairs(TCDisassembleMenu.TC_ELECTRONIC_TOOLS) do
        if inv:containsTypeRecurse(tool) then
            return true
        end
    end
    return false
end

function TCDisassembleMenu.getRecipeName(item)
    if not item then return nil end
    
    local fullType = item:getFullType()
    if not fullType then return nil end
    
    local itemType = item.getType and item:getType() or nil
    if not itemType then return nil end
    
    -- Check for electronics (exact matching)
    if itemType and string.find(itemType, "TCWalkman") then
        return "Disassemble (Walkman)"
    elseif itemType and string.find(itemType, "TCBoombox") then
        return "Disassemble (Boombox)"
    elseif string.find(itemType, "TCVinylplayer") then
        return "Disassemble (Vinyl Player)"
    end
    
    -- For cassettes, dynamically extract module name
    if itemType and string.find(itemType, "Cassette") then
        local dotPos = string.find(fullType, "%.")
        if dotPos then
            local moduleName = string.sub(fullType, 1, dotPos - 1)
            -- Return recipe name based on module (matches recipe definitions in TCCassette_Recipes.txt)
            return "Disassemble (" .. moduleName .. ")"
        end
    end
    
    return nil
end

function TCDisassembleMenu.getRequiredTool(playerObj, item)
    dlog("[TCDisassemble] getRequiredTool called. Player: " .. tostring(playerObj) .. ", Item: " .. tostring(item))
    local inv = playerObj:getInventory()
    if inv and inv.getItems then
        local items = inv:getItems()
        dlog("[TCDisassemble] getRequiredTool inventory has " .. tostring(items:size()) .. " items.")
        for i=0,items:size()-1 do
            local it = items:get(i)
            if it and it.getFullType and it.getType then
                dlog("[TCDisassemble] getRequiredTool inventory item " .. tostring(i) .. ": fullType=" .. tostring(it:getFullType()) .. ", type=" .. tostring(it:getType()))
            end
        end
    end
    local fullType = item:getFullType()
    -- Electronics need any screwdriver variant
    for _, toolType in ipairs(TCDisassembleMenu.TC_ELECTRONIC_TOOLS) do
        dlog("[TCDisassemble] Checking for tool: " .. toolType)
        local tool = inv:getFirstTypeRecurse(toolType)
        dlog("[TCDisassemble] getFirstTypeRecurse returned: " .. tostring(tool and tool:getFullType() or tool))
        if tool then
            return tool
        end
    end
    dlog("[TCDisassemble] No valid tool found in inventory for disassembly.")
    return nil
end

function TCDisassembleMenu.createDisassembleMenu(player, context, items)
    -- Check if disassembly system is enabled in sandbox options
    local sandbox = SandboxVars and SandboxVars.PZTrueMusicSandbox
    if sandbox and sandbox.EnableDisassembly == false then
        return -- Disassembly disabled, don't add menu option
    end
    
    local playerObj = getSpecificPlayer(player)
    if not playerObj then return end
    
    -- Get the item
    local item = nil
    if items then
        if type(items) == "table" and #items > 0 then
            item = items[1]
            if not instanceof(item, "InventoryItem") then
                if item.items and #item.items > 0 then
                    item = item.items[1]
                end
            end
        end
    end
    
    if not item or not TCDisassembleMenu.canDisassemble(item) then return end
    local hasTool = TCDisassembleMenu.hasRequiredTool(playerObj, item)
    if not hasTool then
        return
    end
    local option = context:addOption("Disassemble", item, function()
        TCDisassembleMenu.onDisassemble(playerObj, item)
    end)
end

Events.OnFillInventoryObjectContextMenu.Add(TCDisassembleMenu.createDisassembleMenu)
