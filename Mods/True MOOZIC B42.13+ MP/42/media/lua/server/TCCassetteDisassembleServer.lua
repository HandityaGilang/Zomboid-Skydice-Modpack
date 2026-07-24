-- TM - Unstable Addons: Cassette Disassemble Server Logic
-- Server-side handling for cassette disassembling (MP-safe)

TCCassetteDisassembleServer = TCCassetteDisassembleServer or {}

local DEBUG = false
local function dlog(msg)
    if DEBUG then
        print(msg)
    end
end

local startWithLoaded = pcall(require, "TCStartWithDevice")
dlog("[TCCassetteDisassembleServer] TCStartWithDevice loaded? " .. tostring(startWithLoaded))

-- Ensure shared definitions are loaded
pcall(function() require "TCCassetteDisassembleDefinitions" end)
pcall(function() require "TCCassetteDisassembleLoot" end)
dlog("[TCCassetteDisassembleServer] Loaded definitions? " .. tostring(TCCassetteDisassembleDefinitions ~= nil))

-- Main disassemble function (called from client action or server command)
function TCCassetteDisassembleServer.performDisassemble(player, item)
    if not player or not item then 
        dlog("TCCassetteDisassemble: Invalid player or item")
        return 
    end

    -- Disassembly is optional and gated by sandbox option
    local sandbox = SandboxVars and SandboxVars.PZTrueMusicSandbox
    if sandbox and sandbox.EnableDisassembly == false then
        dlog("TCCassetteDisassemble: Disassembly disabled in sandbox")
        return
    end
    -- Debug info
    local playerName = (player and player.getUsername and player:getUsername()) or tostring(player)
    local itemTypeDebug = nil
    if item then
        if item.getFullType then itemTypeDebug = item:getFullType()
        elseif item.getType then itemTypeDebug = item:getType()
        else itemTypeDebug = tostring(item)
        end
    end
    dlog("[TCCassetteDisassemble] performDisassemble called for " .. tostring(playerName) .. ", item: " .. tostring(itemTypeDebug))
    
    local inventory = player:getInventory()
    
    -- Verify item still exists in inventory
    local contains = false
    if inventory and inventory.contains then
        contains = inventory:contains(item)
    end
    dlog("[TCCassetteDisassemble] inventory:contains(item) -> " .. tostring(contains))
    if not contains then
        dlog("TCCassetteDisassemble: Item not in inventory -- attempting to locate by type")
        -- try to find equivalent item instance by matching type/fullType
        if inventory and inventory.getItems then
            local items = inventory:getItems()
            for i = 0, items:size() - 1 do
                local it = items:get(i)
                if it and item.getFullType and it.getFullType and it:getFullType() == item:getFullType() then
                    item = it
                    contains = true
                    dlog("[TCCassetteDisassemble] Found matching inventory item by fullType: " .. tostring(it:getFullType()))
                    break
                elseif it and item.getType and it.getType and it:getType() == item:getType() then
                    item = it
                    contains = true
                    dlog("[TCCassetteDisassemble] Found matching inventory item by type: " .. tostring(it:getType()))
                    break
                end
            end
        end
        if not contains then
            dlog("TCCassetteDisassemble: Item truly not in inventory, aborting")
            return
        end
    end
    
    -- Auto-eject media before disassembling a device (authoritative in MP)
    local itemTypeCheck = item.getType and item:getType() or nil
    local isDevice = itemTypeCheck and (itemTypeCheck:find("TCWalkman", 1, true) or itemTypeCheck:find("TCBoombox", 1, true) or itemTypeCheck:find("TCVinylplayer", 1, true)) or false
    if isDevice and TCCassetteDisassembleLoot and TCCassetteDisassembleLoot.DeviceHasMedia then
        if TCCassetteDisassembleLoot.DeviceHasMedia(item) and TCCassetteDisassembleLoot.ReturnMediaToInventory then
            TCCassetteDisassembleLoot.ReturnMediaToInventory(player, item)
        end
    end

    -- Get player's electrical skill level (for XP/loot scaling only)
    local electricalSkill = player:getPerkLevel(Perks.Electrical)

    -- Determine item type and whether it's an electronic (matches client logic)
    local itemType = nil
    if item and item.getType then
        itemType = item:getType()
    end
    local isElectronics = (itemType and (itemType:find("TCWalkman", 1, true) or itemType:find("TCBoombox", 1, true) or itemType:find("TCVinylplayer", 1, true))) or false

    -- Success-only (vanilla-style): award XP based on item category
    local xpAmount = isElectronics and (TCCassetteDisassembleDefinitions.ExpGain.Electrical or 10) or (TCCassetteDisassembleDefinitions.ExpGain.Cassette or 5)
    if player and player.getXp and type(player.getXp) == "function" then
        local xpObj = player:getXp()
        if xpObj and type(xpObj.AddXP) == "function" then
            local perkId = Perks and Perks.Electrical or nil
            if not perkId and type(Perks) == "table" then
                for k, v in pairs(Perks) do
                    if type(k) == "string" and string.find(string.lower(k), "electr") then
                        perkId = v
                        break
                    end
                end
            end
            if perkId then
                xpObj:AddXP(perkId, xpAmount)
                dlog("TCCassetteDisassemble: Awarded XP (" .. tostring(xpAmount) .. ") to " .. tostring(player:getUsername()))
            else
                dlog("TCCassetteDisassemble: Could not locate Electrical perk to award XP")
            end
        else
            dlog("TCCassetteDisassemble: player:getXp():AddXP unavailable")
        end
    end

    -- Add components based on shared loot rules
    if TCCassetteDisassembleLoot and TCCassetteDisassembleLoot.ApplyDisassemblyLoot then
        TCCassetteDisassembleLoot.ApplyDisassemblyLoot(player, item)
    else
        -- Fallback to legacy definitions if shared loot isn't available
        for _, component in ipairs(TCCassetteDisassembleDefinitions.ComponentsReceived) do
            local skillBonus = electricalSkill * 0.05
            local actualChance = math.min(component.chance + skillBonus, 1.0)
            if ZombRand(100) < (actualChance * 100) then
                local compType = component.item
                local count = component.count or 1
                for i = 1, count do
                    inventory:AddItem(compType)
                end
            end
        end
    end

    -- Remove the item (authoritative removal on server)
    inventory:Remove(item)

    dlog("TCCassetteDisassemble: Successfully disassembled cassette for player " .. player:getUsername())

end

-- Handle client commands (for multiplayer)
local function OnClientCommand(module, command, player, args)
    if module ~= "TCCassetteDisassemble" then return end
    
    if command == "PerformDisassemble" then
        dlog("[TCCassetteDisassemble] OnClientCommand PerformDisassemble received. args: " .. tostring(args and args.itemID) .. " " .. tostring(args and args.fullType) .. " " .. tostring(args and args.itemType))
        -- Find the item by ID in player's inventory
        local itemID = args.itemID
        local fullType = args and args.fullType or nil
        local itemType = args and args.itemType or nil
        -- itemID may be nil or not match server-side instances; fall back to type/fullType matching.
        
        local inventory = player:getInventory()
        local item = nil
        -- Try direct lookup first (engine-provided helper)
        if inventory.getItemById then
            item = inventory:getItemById(itemID)
        end

        -- Fallback: scan inventory for matching ID or matching fullType/itemType
        if not item and inventory.getItems then
            local items = inventory:getItems()
            for i = 0, items:size() - 1 do
                local it = items:get(i)
                if it then
                    -- try matching getID if available
                    if it.getID and itemID and it:getID() == itemID then
                        item = it
                        break
                    end
                    -- fall back to matching type information if provided
                    if fullType and it.getFullType and it:getFullType() == fullType then
                        item = it
                        break
                    end
                    if itemType and it.getType and it:getType() == itemType then
                        item = it
                        break
                    end
                end
            end
        end

        if item then
            TCCassetteDisassembleServer.performDisassemble(player, item)
        else
            dlog("TCCassetteDisassemble: Item not found in inventory, ID: " .. tostring(itemID) .. ", fullType: " .. tostring(fullType))
        end
    end
end

-- Register server command handler (works for both SP and MP)
Events.OnClientCommand.Add(OnClientCommand)

dlog("TCCassetteDisassembleServer loaded")
