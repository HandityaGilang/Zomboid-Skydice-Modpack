--------------------------------------------------------------------------------------------------
--        ----      |              |            |         |                |    --    |      ----            --
--        ----      |              |            |         |                |    --       |      ----            --
--        ----      |        -------       -----|     ---------        -----          -      ----       -------
--        ----      |            ---            |         -----        ------        --      ----            --
--        ----      |            ---            |         -----        -------          ---      ----            --
--        ----      |        -------       ----------     -----        -------         ---      ----       -------
--            |      |        -------            |         -----        -------         ---          |            --
--            |      |        -------            |          -----        -------         ---          |            --
--------------------------------------------------------------------------------------------------

require "LifestyleCore/LSK_CommandRouter"
require "LifestyleCore/LSK_ActionAuthority"
require "LifestyleCore/LSK_Persistence"
require "LifestyleCore/LSK_SystemContracts"
require "LifestyleCore/LSK_NearbySync"
require "LifestyleSystems/00_LSK_SystemsServer"

local LS_Commands = {}

-- Throttle full-table LSDATA broadcasts (beauty/ambt admin). Prefer NearbySync/commands.
local _lsDataTxAt = 0
local function transmitLSDataThrottled()
    local now = 0
    if getTimestamp then
        now = tonumber(getTimestamp()) or 0
    end
    if (now - _lsDataTxAt) < 5 then
        return
    end
    _lsDataTxAt = now
    if ModData and ModData.transmit then
        ModData.transmit("LSDATA")
    end
end

local function getObjFromSqr(x, y, z, spriteName)
    local square = getCell():getGridSquare(x, y, z)
    if not square then return false; end
    for i=0,square:getObjects():size()-1 do
        local object = square:getObjects():get(i);
        local objSprite = object.getSprite and object:getSprite()
        if objSprite then
            objSpriteName = objSprite.getName and objSprite:getName()
            if objSpriteName and objSpriteName == spriteName then return object; end
        end
        
        local objSpriteOrTextureName = object.getSpriteName and object:getSpriteName()
        if not objSpriteOrTextureName then objSpriteOrTextureName = object.getTextureName and object:getTextureName(); end
        
        if objSpriteOrTextureName and objSpriteOrTextureName == spriteName then return object; end
    end
    for i=0,square:getObjects():size()-1 do
        local object = square:getObjects():get(i);
        local attached = object.getAttachedAnimSprite and object:getAttachedAnimSprite()
        if attached then
            for n=1,attached:size() do
                local sprite = attached:get(n-1)
                if sprite and sprite:getParentSprite() and sprite:getParentSprite():getName() and luautils.stringStarts(sprite:getParentSprite():getName(), spriteName) then
                    return object
                end
            end
        end
    end
    return false
end
--[[
LS_Commands["ModItem_FromPlayer"] = function(player, arg)
    local item = LSSync.getItemServer(arg[1], player:getInventory())
    if item then LSUtil.itemModify(item, arg[2]); else LSUtil.debugPrint("SERVER COMMAND ModItem_FromPlayer - NO ITEM FOUND"); end
end

LS_Commands["ModItem_FromObj"] = function(_, arg)
    local objInfo = arg[2]
    local obj = getObjFromSqr(objInfo[1], objInfo[2], objInfo[3], objInfo[4])
    if not obj then LSUtil.debugPrint("SERVER COMMAND SyncObjMovData - NO OBJ FOUND"); return; end
    local item = LSSync.getItemServer(arg[1], obj:getContainer())
    if item then LSUtil.itemModify(item, arg[3]); else LSUtil.debugPrint("SERVER COMMAND ModItem_FromObj - NO ITEM FOUND"); end
end
]]--
LS_Commands["SyncItemData_FromPlayer"] = function(player, arg)
    local playerInv = player:getInventory()
    local item = LSSync.getItemServer(arg[1], playerInv)
    if not item then -- might be inside backpack
        local items = playerInv:getItems()
        for n=0,items:size()-1 do
            local bag = items:get(n)
            local bagContainer = bag and bag:getContainer()
            if bagContainer then
                item = LSSync.getItemServer(arg[1], bagContainer)
                if item then break; end
            end
        end
    end
    if item then LSSync.transmitItemMovData(item, player, nil, arg[2], arg[3], arg[4]); else LSUtil.debugPrint("SERVER COMMAND SyncItemData_FromPlayer - NO ITEM FOUND"); end
end

LS_Commands["SyncItemData_FromObj"] = function(_, arg)
    local objInfo = arg[2]
    local obj = getObjFromSqr(objInfo[1], objInfo[2], objInfo[3], objInfo[4])
    if not obj then LSUtil.debugPrint("SERVER COMMAND SyncItemData_FromObj - NO OBJ FOUND"); return; end
    local item = LSSync.getItemServer(arg[1], obj:getContainer())
    if item then LSSync.updateAndSend(item, arg[3], arg[4], arg[5]); else LSUtil.debugPrint("SERVER COMMAND SyncItemData_FromObj - NO ITEM FOUND"); end
end

LS_Commands["SyncObjMovData"] = function(_, arg)
    local objInfo = arg[1]
    local obj = getObjFromSqr(objInfo[1], objInfo[2], objInfo[3], objInfo[4])
    if not obj then LSUtil.debugPrint("SERVER COMMAND SyncObjMovData - NO OBJ FOUND for x="..tostring(objInfo[1])..", y="..tostring(objInfo[2])..
    ", z="..tostring(objInfo[3])..", spriteName="..tostring(objInfo[4])); return; end
    LSSync.updateAndSend(obj, arg[2], arg[3])
end

LS_Commands["CreateFluidCont_Obj"] = function(_, arg)
    local objInfo = arg[1]
    local obj = getObjFromSqr(objInfo[1], objInfo[2], objInfo[3], objInfo[4])
    if not obj then LSUtil.debugPrint("SERVER COMMAND CreateFluidCont_Obj - NO OBJ FOUND for x="..tostring(objInfo[1])..", y="..tostring(objInfo[2])..
    ", z="..tostring(objInfo[3])..", spriteName="..tostring(objInfo[4])); return; end
    LSUtil.getOrCreateFluidContainer(obj, arg[2])
end

LS_Commands["UseFluid_Obj"] = function(_, arg)
    local objInfo = arg[1]
    local obj = getObjFromSqr(objInfo[1], objInfo[2], objInfo[3], objInfo[4])
    if not obj then LSUtil.debugPrint("SERVER COMMAND UseFluid_Obj - NO OBJ FOUND"); return; end
    LSUtil.useObjFluid(obj, arg[2])
end

LS_Commands["SetMirrorMakeup"] = function(player, arg)
    LSMirrorMenu_server.setMirrorChanges(player, arg)
end

LS_Commands["RemoveBrokenGlass"] = function(player, arg)
    local x = arg[1]
    local y = arg[2]
    local z = arg[3]
    local square = getCell():getGridSquare(x, y, z)
    if not square then return end
    for i=0,square:getObjects():size()-1 do
        local object = square:getObjects():get(i)
        if object then
            local texName = object.getTextureName and object:getTextureName()
            if texName and luautils.stringStarts(texName, "brokenglass_") and ISMoveableTools.isObjectMoveable(object) then
                ISMoveableTools.isObjectMoveable(object):pickUpMoveable(player, square, object, true)
                break
            end
        end
    end
end

LS_Commands["MakeWellFed"] = function(player, arg)
    LSUtil.MakeCharWellFed(player, arg[1])
end

LS_Commands["learnRecipes"] = function(player, arg)
    LSUtil.learnRecipes(player, arg)
end

LS_Commands["Character_Explosion"] = function(player, arg)
    LSUtil.makeCharExplode(player, arg)
end

LS_Commands["Character_MakeWet"] = function(player, arg)
    LSUtil.makeCharWet(player, arg[1])
end

LS_Commands["Character_CleanSelf"] = function(player, arg)
    LSUtil.changeCharVisualDirt(player, arg[1], arg[2], arg[3])
end

LS_Commands["dropHeavyItems"] = function(player, arg)
    if player then forceDropHeavyItems(player); end
end

LS_Commands["reduceAllStiffness"] = function(player, arg)
    local value = arg[1]
    local bodyDamage = player:getBodyDamage()
    if not bodyDamage then return; end
    local bodyParts = bodyDamage:getBodyParts()
    if not bodyParts then return; end
    for i=0,bodyParts:size()-1 do
        local bodyPart = bodyParts:get(i)
        if bodyPart then
            local stiff = bodyPart:getStiffness()
            if stiff and stiff > 0 then
                local newStiff = math.max(0,stiff-value)
                bodyPart:setStiffness(newStiff)
                player:getFitness():removeStiffnessValue(BodyPartType.ToString(bodyPart:getType()))
                --local bodyPartType = bodyPart:getType()
                --player:getFitness():removeStiffnessValue(bodyPartType:ToString(bodyPartType))
            end
        end
    end
end

LS_Commands["AddItems_Player"] = function(player, arg)
    local playerInv = player:getInventory()
    local itemFullType = arg[1]
    local amount = arg[2]
    local itemInfo = arg[3]
    local destCont
    if itemInfo then
        local item = LSSync.getItemServer(itemInfo, playerInv)
        destCont = item and item.getInventory and item:getInventory()
    end
    if not destCont then destCont = playerInv; end
    local items = destCont:AddItems(itemFullType, amount)
    sendAddItemsToContainer(destCont, items)
end

LS_Commands["AddGeneralHealth"] = function(player, arg)
    local value = arg[1]
    local bodyDamage = player:getBodyDamage()
    if not bodyDamage then return; end
    bodyDamage:AddGeneralHealth(value)
end

LS_Commands["addPainBodyPart"] = function(player, arg)
    local bP = arg[1]
    local value = arg[2]
    local bodyDamage = player:getBodyDamage()
    if not bodyDamage then return; end
    if not BodyPartType[bP] then return; end
    local bodyPart = bodyDamage:getBodyPart(BodyPartType[bP])
    bodyPart:setAdditionalPain(value)
    --syncBodyPart(bodyPart)
end

-- B42 Stats are Java methods: use colon calls (stats:add/set/remove). Bracket form stats["add"] is nil.
local function applyCharacterStatChange(player, method, upMood, value)
    if not player or not CharacterStat or not CharacterStat[upMood] then
        return false
    end
    local stats = player:getStats()
    if not stats then
        return false
    end
    local stat = CharacterStat[upMood]
    value = tonumber(value) or 0
    if value ~= value then
        return false
    end

    if upMood == "WETNESS" then
        local bodyDamage = player:getBodyDamage()
        if bodyDamage then
            if method == "remove" and bodyDamage.decreaseBodyWetness then
                bodyDamage:decreaseBodyWetness(value)
            elseif method == "set" and bodyDamage.setWetness then
                bodyDamage:setWetness(value)
            elseif method == "add" and bodyDamage.setWetness then
                local cur = 0
                if bodyDamage.getWetness then
                    cur = tonumber(bodyDamage:getWetness()) or 0
                elseif stats.get then
                    cur = tonumber(stats:get(stat)) or 0
                end
                bodyDamage:setWetness(cur + value)
            end
        end
    end

    if method == "add" then
        stats:add(stat, value)
    elseif method == "remove" then
        stats:remove(stat, value)
    elseif method == "set" then
        stats:set(stat, value)
    else
        return false
    end
    if sendPlayerStat then
        sendPlayerStat(player, stat)
    end
    return true
end

LS_Commands["ChangeCharacterMoodGroup"] = function(player, arg)
    local moodList = arg[1]
    if type(moodList) ~= "table" then
        return
    end
    local n
    for n = 1, #moodList do
        local moodInfo = moodList[n]
        if type(moodInfo) == "table" then
            applyCharacterStatChange(player, moodInfo[1], moodInfo[2], moodInfo[3])
        end
    end
end

LS_Commands["ChangeCharacterMood"] = function(player, arg)
    applyCharacterStatChange(player, arg[1], arg[2], arg[3])
end

local function grantVerifiedActionXP(player, perkName, requested, session, actionName)
    if not player or not Perks or not Perks[perkName] or type(session) ~= "table" then
        return 0
    end
    local rate = LifestyleSecure.SystemContracts.GetActionRewardRate(actionName, perkName)
    if not rate then
        return 0
    end
    local now = getTimestampMs and getTimestampMs() or 0
    local startedAt = tonumber(session.startedAt) or now
    local elapsed = math.max(1, (now - startedAt) / 1000)
    session.rewards = session.rewards or {}
    local granted = tonumber(session.rewards[perkName]) or 0
    local maximumTotal = math.min(250, 2 + elapsed * rate)
    local available = math.max(0, maximumTotal - granted)
    local amount = math.min(math.max(0, tonumber(requested) or 0), available)
    if amount <= 0 then
        return 0
    end
    if perkName == "Music" and LifestyleSecure.Systems and LifestyleSecure.Systems.Music then
        local ok, musicAmount = LifestyleSecure.Systems.Music.grantReward(
            player, actionName, perkName, elapsed, amount
        )
        if ok and musicAmount then
            amount = musicAmount
        else
            return 0
        end
    else
        addXp(player, Perks[perkName], amount)
    end
    session.rewards[perkName] = granted + amount
    return amount
end

LS_Commands["AddXP"] = function(player, arg)
    local granted = grantVerifiedActionXP(
        player,
        arg[1],
        arg[2],
        arg.__lskServerSession,
        arg.__lskServerAction
    )
    if granted > 0 then
        SyncXp(player)
    end
end

LS_Commands["AddXPBatch"] = function(player, arg)
    local total = 0
    for i = 1, #arg do
        local entry = arg[i]
        if type(entry) == "table" then
            total = total + grantVerifiedActionXP(
                player,
                entry[1],
                entry[2],
                arg.__lskServerSession,
                arg.__lskServerAction
            )
        end
    end
    if total > 0 then
        SyncXp(player)
    end
end

local function playerHasNeuralHatEquipped(player)
    if not player or not player.getWornItems then
        return false
    end
    local ok, hat = pcall(function()
        return player:getWornItems():getItem(ItemBodyLocation.HAT)
    end)
    if not ok or not hat or not hat.getType then
        return false
    end
    return hat:getType() == "NeuralHat"
end

-- NeuralHat XP boost/drain: runs outside Lifestyle timed actions (no action proof).
LS_Commands["LSK_NeuralHatXP"] = function(player, arg)
    if not playerHasNeuralHatEquipped(player) then
        return
    end
    local applied = 0
    local count = math.min(#arg, 12)
    for i = 1, count do
        local entry = arg[i]
        if type(entry) == "table" and entry[1] and Perks and Perks[entry[1]] then
            local perkName = entry[1]
            if player:getPerkLevel(Perks[perkName]) < 10 then
                local amount = tonumber(entry[2]) or 0
                if amount > 50 then amount = 50 end
                if amount < -50 then amount = -50 end
                if amount > 0 then
                    addXp(player, Perks[perkName], amount)
                    applied = applied + 1
                elseif amount < 0 then
                    if addXpNoMultiplier then
                        addXpNoMultiplier(player, Perks[perkName], amount)
                    else
                        addXp(player, Perks[perkName], amount)
                    end
                    applied = applied + 1
                end
            end
        end
    end
    if applied > 0 and SyncXp then
        SyncXp(player)
    end
end

LS_Commands["SavePlayerData"] = function(player, arg)
    local source = type(arg) == "table" and arg[1] or nil
    if type(source) ~= "table" then
        return
    end
    local snapshot = LifestyleSecure.Persistence.getSnapshot(player)
    if not snapshot then
        return
    end
    local delta = LifestyleSecure.PersistenceSchema.createDelta(source, snapshot.data)
    LifestyleSecure.Persistence.applyClientDelta(player, snapshot.revision, delta)
    LifestyleSecure.Systems.Hygiene.setNeeds(player, {
        hygiene = source.hygieneNeed,
        bathroom = source.bathroomNeed,
    })
    LifestyleSecure.Systems.Comfort.setState(player, {
        need = source.ComfortNeed,
        value = source.ComfortVal,
        bedQuality = source.CurrentBedQuality,
    })
end

LS_Commands["ChangeMaxWeight"] = function(player, arg)
    local newWeight = arg[1]
    if newWeight then player:setMaxWeightBase(newWeight); end
end

LS_Commands["ChangeTrait"] = function(player, arg)
    local traitName = arg[1]
    local method = arg[2]
    local traitObj = nil
    if LSK_NetSchema and LSK_NetSchema.resolveChangeTrait then
        traitObj = LSK_NetSchema.resolveChangeTrait(traitName)
    elseif CharacterTrait and traitName then
        traitObj = CharacterTrait[traitName] or CharacterTrait[string.upper(tostring(traitName))]
            or CharacterTrait[string.lower(tostring(traitName))]
    end
    if not traitObj then return; end
    local self = player:getCharacterTraits()
    local hasTrait = player:hasTrait(traitObj)
    if method == "add" and hasTrait then return; end
    if method == "remove" and not hasTrait then return; end
    self[method](self, traitObj);
    player:modifyTraitXPBoost(traitObj, method == "remove");
    SyncXp(player)
end

local function checkAndRemoveClothingItem(player, container, item, fullType)
    --print("checkAndRemoveItem - start")
    --print("checkAndRemoveItem - item ID is: "..item:getID())
    for x=0,container:getItems():size() - 1 do
        local newItem = container:getItems():get(x);
        --if newItem then print("checkAndRemoveItem - newItem ID is: "..newItem:getID()); end
        if newItem then 
            if (item and newItem:getID() == item:getID()) or (fullType and newItem.getFullType and newItem:getFullType() == fullType) then
                if player:isEquippedClothing(newItem) then player:removeWornItem(newItem); end
                container:Remove(newItem)
                sendRemoveItemFromContainer(container, newItem)
                --print("checkAndRemoveItem - found item, removed")
                break
            end
        end
    end
end

local function checkAndRemoveItem(container, item, fullType)
    --print("checkAndRemoveItem - start")
    --print("checkAndRemoveItem - item ID is: "..item:getID())
    for x=0,container:getItems():size() - 1 do
        local newItem = container:getItems():get(x);
        --if newItem then print("checkAndRemoveItem - newItem ID is: "..newItem:getID()); end
        if newItem then 
            if (item and newItem:getID() == item:getID()) or (fullType and newItem.getFullType and newItem:getFullType() == fullType) then
                container:Remove(newItem)
                sendRemoveItemFromContainer(container, newItem)
                --print("checkAndRemoveItem - found item, removed")
                break
            end
        end
    end
end

local function getItemByID(container, itemID)
    for x=0,container:getItems():size() - 1 do
        local newItem = container:getItems():get(x);
        if newItem and newItem:getID() == itemID then
            return newItem
        end
    end
    return false
end

local function doRemoveItemFromID(id, cont, player)
    local item = cont:getItemWithID(id)
    if not item then return; end
    if player then player:removeFromHands(item); end
    cont:Remove(item)
    sendRemoveItemFromContainer(cont, item)
end

LS_Commands["RemoveItems"] = function(player, arg)
    local t = arg[1]
    if not t then return; end
    local inv, hands
    if arg[2] then
        local obj = getObjFromSqr(arg[2][1], arg[2][2], arg[2][3], arg[2][4])
        if obj then inv = obj:getContainer(); end
    else
        hands = true
        inv = player:getInventory()
    end
    if not inv then return; end

    for n=1,#t do
        local predicateItem = function(item)
            return item and item:getID() == t[n]
        end
        local item = inv:containsEvalRecurse(predicateItem) and inv:getFirstEvalRecurse(predicateItem)
        local cont = item and item:getContainer()
        if cont then
            if hands then player:removeFromHands(item); end
            cont:Remove(item)
            sendRemoveItemFromContainer(cont, item)
        end
    end
end

LS_Commands["TransferItemWorld"] = function(player, arg)
    LSUtil.debugPrint("(server) LS_Commands.TransferItemWorld - start")
    local item = arg[1]
    local fromPlayer = arg[2]
    local wear = arg[3]
    local coords = arg[4]
    if not item then LSUtil.debugPrint("(server) LS_Commands.TransferItemWorld - not item, returning"); return; end
    local square = getCell():getGridSquare(coords[1], coords[2], coords[3])
    if not square then LSUtil.debugPrint("(server) LS_Commands.TransferItemWorld - error, no square"); end
    
    local floorObjects = square and square.getWorldObjects and square:getWorldObjects()
    if not floorObjects then LSUtil.debugPrint("(server) LS_Commands.TransferItemWorld - error, no floorObjects"); end
    local floorItem
    if not fromPlayer then
        for i=0,floorObjects:size()-1 do
            local worldItem = floorObjects:get(i)
            local newItem = worldItem and worldItem.getItem and worldItem:getItem()
            if newItem and newItem:getID() == item:getID() then
                floorItem = newItem.getWorldItem and newItem:getWorldItem()
                if floorItem then
                    item = newItem
                    LSUtil.debugPrint("(server) LS_Commands.TransferItemWorld - found floorItem")
                    break
                end
            end
        end
    end
    local playerInv = player and player.getInventory and player:getInventory()
    if (not fromPlayer and not floorItem) or not playerInv then LSUtil.debugPrint("(server) LS_Commands.TransferItemWorld - not fromPlayer and not floorItem or not playerInv, returning"); return; end
    if not fromPlayer then
        LSUtil.debugPrint("(server) LS_Commands.TransferItemWorld - calling TransferHelper.transferItem not fromPlayer")
        TransferHelper.transferItem(player, item, false, playerInv, false, wear, "floor") -- player, item, srcContainer, destContainer, dropSquare, autoWear, srcOverride, destOverride
    else
        LSUtil.debugPrint("(server) LS_Commands.TransferItemWorld - calling TransferHelper.transferItem fromPlayer")
        TransferHelper.transferItem(player, item, playerInv, false, square, wear, false, "floor")
    end
end

LS_Commands["TransferItem"] = function(player, arg)
    LSUtil.debugPrint("(server) LS_Commands.TransferItem - start")
    local item = arg[1]
    local fromPlayer = arg[2]
    local wear = arg[3]
    local objInfo = arg[4]
    if not item then LSUtil.debugPrint("(server) LS_Commands.TransferItem - not item, returning"); return; end
    local obj = getObjFromSqr(objInfo[1], objInfo[2], objInfo[3], objInfo[4])
    local objCont = obj and obj.getContainer and obj:getContainer()
    local playerInv = player and player.getInventory and player:getInventory()
    if not objCont or not playerInv then LSUtil.debugPrint("(server) LS_Commands.TransferItem - not objCont or not playerInv, returning"); return; end
    if not fromPlayer then
        LSUtil.debugPrint("(server) LS_Commands.TransferItem - calling TransferHelper.transferItem not fromPlayer")
        TransferHelper.transferItem(player, item, objCont, playerInv, false, wear) -- player, item, srcContainer, destContainer, dropSquare, autoWear
    else
        LSUtil.debugPrint("(server) LS_Commands.TransferItem - calling TransferHelper.transferItem fromPlayer")
        TransferHelper.transferItem(player, item, playerInv, objCont, false, wear)
    end
end

LS_Commands["TransferItemFrom"] = function(player, arg)
    local item = arg[1]
    local wear = arg[2]
    local objInfo = arg[3]
    if not item then return; end
    local obj = getObjFromSqr(objInfo[1], objInfo[2], objInfo[3], objInfo[4])
    local destCont = obj and obj:getContainer()
    --local destCont = item and item:getContainer()
    if destCont then
        destCont:setDrawDirty(true);
        destCont:Remove(item)
        sendRemoveItemFromContainer(destCont, item)
    else
        return
    end
    local playerInv = player:getInventory()
    playerInv:setDrawDirty(true)
    playerInv:AddItem(item)
    sendAddItemToContainer(playerInv, item)
    destCont:Remove(item)
    checkAndRemoveItem(destCont, item)
    if wear then
        if (instanceof(item, "InventoryContainer") and item:canBeEquipped() ~= "") then
            player:setWornItem(item:canBeEquipped(), item);
            --getPlayerInventory(player:getPlayerNum()):refreshBackpacks();
        else
            player:setWornItem(item:getBodyLocation(), item);
        end
        triggerEvent("OnClothingUpdated", player)
    end
end

LS_Commands["TransferItemTo"] = function(player, arg)
    local item = arg[1]
    local objInfo = arg[2]
    if not item then return; end
    local obj = getObjFromSqr(objInfo[1], objInfo[2], objInfo[3], objInfo[4])
    local destCont = obj and obj:getContainer()
    local playerInv = player:getInventory()
    if player:isEquippedClothing(item) then player:removeWornItem(item); end
    playerInv:setDrawDirty(true)
    if destCont then
        playerInv:Remove(item)
        sendRemoveItemFromContainer(playerInv, item)
        destCont:setDrawDirty(true);
        destCont:AddItem(item)
        sendAddItemToContainer(destCont, item)
        playerInv:Remove(item)
        checkAndRemoveClothingItem(player, playerInv, item)
    end
end

LS_Commands["AddWorldItem"] = function(player, arg)
    local item, amount, posX, posY, posZ, sqrX, sqrY, sqrZ = arg[1], arg[2], arg[3], arg[4], arg[5], arg[6], arg[7], arg[8]
    if not item or not amount then return; end
    local square = getCell():getGridSquare(sqrX, sqrY, sqrZ)
    if not square then return end
    for n=1, amount do
        local newPosX, newPosY = posX, posY
        if not posX then newPosX = ZombRandFloat(0.0, 1.0); end
        if not posY then newPosY = ZombRandFloat(0.0, 1.0); end
        square:AddWorldInventoryItem(item, newPosX, newPosY, posZ)
    end
end

local function doRemokeMakeup(player, item)
    if item then
        player:removeWornItem(item)
        player:getInventory():Remove(item)
        sendRemoveItemFromContainer(player:getInventory(), item)
    end
end

LS_Commands["RemoveMakeup"] = function(player, arg)
    local group = arg[1]
    local all = arg[2]

    local makeupList = {
        face = {"FullFace","Eyes","EyesShadow","Lips"},
        mouth = {"Lips"},
        eyes = {"Eyes","EyesShadow"},
    }

    local wornItems = player:getWornItems()
    --for i=0, wornItems:size()-1 do
    for i = wornItems:size() - 1, 0, -1 do
        local worn = wornItems:get(i)
        local item = worn and worn.getItem and worn:getItem()
        local location = item and item.getBodyLocation and item:getBodyLocation()
        if location and luautils.stringStarts(location:getTranslationName(), "MakeUp") then
            for _,makeup in ipairs(MakeUpDefinitions.makeup) do
                if makeup.item == item:getFullType() then
                    if all then
                        doRemokeMakeup(player, item)
                        break
                    elseif makeupList[group] then
                        for n=1,#makeupList[group] do
                            if makeup.category == makeupList[group][n] then
                                doRemokeMakeup(player, item)
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end

LS_Commands["ModifyItemStat"] = function(_, arg)
    local item = arg[1]
    local data = arg[2]
    if data then
        for k, v in pairs(data) do
            if type(v) == "table" then
                item[k](item, v[1], v[2], v[3], v[4])
            else
                item[k](item, v)
            end
        end
    end
    -- usage - ['getMinDmg']=10
    sendItemStats(item)
end

LS_Commands["CreateArtworkItem"] = function(player, arg)
    local data = type(arg[2]) == "table" and arg[2] or nil
    if not data or not LifestyleSecure.Systems.Art.registerSprite(data.result) then
        return
    end
    local artType = "Painting"
    if tostring(data.style or "") == "Sculpture" then
        artType = "Sculpture"
    elseif tostring(data.style or "") == "Sketch" then
        artType = "Sketch"
    end
    local size = tostring(data.size or "Medium")
    if size ~= "Small" and size ~= "Medium" and size ~= "Large" then
        size = "Medium"
    end
    local artwork = {
        sprite = data.result,
        style = artType,
        size = size,
        beauty = data.beauty,
        authorKey = LifestyleSecure.SystemDefinitions.playerKey(player),
    }
    local clean = LifestyleSecure.Systems.Art.sanitizeArtwork(artwork)
    if not clean then
        return
    end
    local nonce = arg.__lskActionNonce or arg[3]
    if type(nonce) ~= "string" or string.len(nonce) < 12 then
        nonce = LifestyleSecure.Systems.Art.beginCreation(player, artwork, 5000)
    end
    if not nonce then
        return
    end
    local author = player:getDisplayName()
    local quality = math.max(0, math.min(100, tonumber(data.quality) or 0))
    local meltTime = data["meltTime"]
    local createdItem = nil
    local ok = LifestyleSecure.Systems.Art.completeCreation(player, nonce, {
        validateResources = function()
            return true, true
        end,
        consumeResources = function()
            return true
        end,
        createArtwork = function(actor)
            local newItem = actor:getInventory():AddItem("Moveables.Moveable")
            if not newItem then
                return nil
            end
            newItem:ReadFromWorldSprite(clean.sprite)
            newItem:getModData().movableData = newItem:getModData().movableData or {}
            newItem:getModData().movableData["artAuthor"] = author
            newItem:getModData().movableData["artBeauty"] = clean.beauty
            newItem:getModData().movableData["artStyle"] = clean.style
            newItem:getModData().movableData["artSize"] = clean.size
            newItem:getModData().movableData["artQuality"] = quality
            if meltTime then
                newItem:getModData().movableData["meltTime"] = meltTime
            end
            sendAddItemToContainer(actor:getInventory(), newItem)
            newItem:syncItemFields()
            actor:getInventory():setDrawDirty(true)
            createdItem = newItem
            return newItem
        end,
    })
    if ok and createdItem then
        sendServerCommand(player, "LSK", "OpenArtworkReview", {player:getPlayerNum(), createdItem, clean.sprite})
    end
end

LS_Commands["ModifySprite"] = function(_, arg)
    local objInfo = arg[1]
    local sprite = arg[2]
    local overlaySprite = arg[3]
    local get = arg[4]
    local obj = getObjFromSqr(objInfo[1], objInfo[2], objInfo[3], objInfo[4])
    if not obj then LSUtil.debugPrint("LS_Commands - ModifySprite, no obj found") return; end
    if get then
        sprite = getSprite(sprite)
    else
        if not overlaySprite then overlaySprite = ""; end
        obj:setOverlaySprite(overlaySprite, true)
    end
    obj:setSprite(sprite)
    -- use setSpriteFromName for wall objects (setSprite won't change properties in their case)
    -- obj:getSprite():getProperties():has(IsoFlagType.WallOverlay)
    obj:transmitUpdatedSpriteToClients()
end

LS_Commands["ModifyOverlaySprite"] = function(_, arg)
    local objInfo = arg[1]
    local overlaySprite = arg[2]
    local obj = getObjFromSqr(objInfo[1], objInfo[2], objInfo[3], objInfo[4])
    if not obj or not obj.setOverlaySprite then LSUtil.debugPrint("LS_Commands - ModifyOverlaySprite, no implementation found") return; end
    if not overlaySprite then overlaySprite = ""; end
    obj:setOverlaySprite(overlaySprite, true)
    obj:transmitUpdatedSpriteToClients()
end

LS_Commands["RemoveObject"] = function(_, arg)
    local obj = getObjFromSqr(arg[1], arg[2], arg[3], arg[4])
    if not obj then LSUtil.debugPrint("SERVER COMMAND RemoveObject - NO OBJ FOUND"); return; end
    local movData = obj:getModData().movableData
    if not movData or not movData['artBeauty'] then return; end
    local square = getCell():getGridSquare(arg[1], arg[2], arg[3])
    square:transmitRemoveItemFromSquare(obj)
    square:RemoveTileObject(obj)
end

LS_Commands["ModifyObjData"] = function(_, arg)
    local objInfo = arg[1]
    local movabledata = arg[2]
    local data = arg[3]
    local nested = arg[4]
    
    local obj = getObjFromSqr(objInfo[1], objInfo[2], objInfo[3], objInfo[4])
    if not obj then LSUtil.debugPrint("SERVER COMMAND ModifyObjData - NO OBJ FOUND"); return; end
    
    local itemData = obj:getModData()

    if movabledata then
        for k, v in pairs(movabledata) do
            itemData.movableData = itemData.movableData or {}
            itemData.movableData[k] = v
        end
    end
    if data then
        if nested then
            itemData[nested] = itemData[nested] or {}
            for k, v in pairs(data) do
                itemData[nested][k] = v
            end
        else
            for k, v in pairs(data) do
                itemData[k] = v
            end
        end
    end
    obj:transmitModData()
    --syncItemModData(obj)
end

LS_Commands["ModifyItemData"] = function(player, arg)
    local oldItem = arg[1]
    local movData = arg[2]
    local data = arg[3]
    local nested = arg[4]
    local item = getItemByID(player:getInventory(), oldItem:getID())
    if not item then return; end
    LSUtil.debugPrint("LS_Commands[ModifyItemData] -- running LSUtil.syncItemModdata")
    LSUtil.syncItemModdata(item, movData, data, nested)
end

LS_Commands["AdjustFluidItem"] = function(player, arg)
    local oldItem = arg[1]
    local useDelta = arg[2]
    local item = getItemByID(player:getInventory(), oldItem:getID())
    if not item then LSUtil.debugPrint("LS_Commands[AdjustFluidItem] - no item found"); return; end
    LSUtil.adjustFluid(item, useDelta, player)
end

LS_Commands["ChangeTexture_Item"] = function(player, arg)
    local id = arg[1]
    local choice = arg[2]
    local item = getItemByID(player:getInventory(), id)
    if not item then LSUtil.debugPrint("LS_Commands[ChangeTexture_Item] -- no item found with ID "..tostring(id)); return; end
    LSUtil.changeTexture_Item(player, item, choice)
end

LS_Commands["UseItem_Player"] = function(player, arg)
    local item = LSSync.getItemServer(arg[1], player:getInventory())
    if not LSUtil.isValidDrainableItem(item) then LSUtil.debugPrint("LS_Commands[UseItem] - no item found"); return; end
    LSUtil.useItem(item, player, nil, arg[2])
    --local uses = arg[2]
    --local delta = arg[3] and arg[3]*0.01
    --[[ -- works but is finicky
    local ogDelta = item:getUseDelta()
    if delta and ogDelta ~= delta then
        local currentUses = item:getCurrentUses()
        local newMax = math.floor((currentUses*ogDelta)/delta)
        item:setUseDelta(delta)
        item:setCurrentUses(newMax)
        LSUtil.debugPrint("LS_Commands[UseItem] - ogDelta = "..tostring(ogDelta).." / getUseDelta = "..tostring(item:getUseDelta()).." / ogCurrentUses = "..tostring(currentUses)..
        " / getCurrentUses = "..tostring(item:getCurrentUses()).." / newMax = "..tostring(newMax).." / delta = "..tostring(delta))
    end
    for n=1,uses do
        item:UseAndSync()
        local uses = item and item.getCurrentUsesFloat and item:getCurrentUsesFloat()
        if not uses or uses <= 0 then break; end
    end
    sendItemStats(item)
    ]]--
end

LS_Commands["CreateFluidCont_Item"] = function(player, arg)
    local item = LSSync.getItemServer(arg[1], player:getInventory())
    LSUtil.getOrCreateFluidContainer(item, arg[2])
end

LS_Commands["renameItem"] = function(player, arg)
    local item = LSSync.getItemServer(arg[1], player:getInventory())
    LSUtil.renameItem(player, item, arg[2])
end

LS_Commands["AddItemToPlayer"] = function(player, arg)
    local itemFN = arg[1]
    local amount = arg[2]
    local playerInv = player:getInventory()
    playerInv:setDrawDirty(true)
    for n=1,amount do
        local item = playerInv:AddItem(itemFN)
        sendAddItemToContainer(playerInv, item)
    end
end

LS_Commands["RemoveItemFromPlayer"] = function(player, arg)
    local itemFN = arg[1]
    local amount = arg[2]
    local playerInv = player:getInventory()
    playerInv:setDrawDirty(true)
    for n=1,amount do
        checkAndRemoveItem(playerInv, false, itemFN)
    end
end

LS_Commands["SyncSqrData"] = function(_, arg)
    local sqrInfo = arg[1]
    local data = arg[2]

    local square = getCell():getGridSquare(sqrInfo[1], sqrInfo[2], sqrInfo[3])
    if not square then return end
    local sqrData = square:getModData()

    if data and sqrData then
        for k, v in pairs(data) do
            sqrData[k] = v
        end
    else
        LSUtil.debugPrint("SERVER COMMAND ModifyObjData - NO DATA FOUND");
    end
    square:transmitModdata() -- d instead D -- seriously?
end

LS_Commands["logAmbition"] = function(_, arg)
    local currentTime = " on ["..tostring(PZCalendar.getInstance():getTime()).."] "
    local admin, id = "", arg[1] or ""
    if arg[5] then admin = " with admin rights."; end
    local text = id.." - [Player:"..arg[2].."/Char:"..arg[6].."] concluded ambition ["..arg[4].."] "..currentTime..admin
    local file = getFileWriter("LSAmbitionLog.log",true,true)
    if not file then return; end -- failed to write file
    file:write(text.."\n")
    file:close()
end

LS_Commands["CompleteTargetAmbt"] = function(player, arg)
    local Target = getPlayerByOnlineID(arg[1])
    local Target_id = arg[1]
    local ambtName = arg[2]
    if not Target or not LifestyleSecure.Systems.Ambition.isKnown(ambtName) then
        return
    end
    if not LifestyleSecure.SystemDefinitions.isAdmin(player) and not LifestyleSecure.SystemDefinitions.samePlayer(player, Target) then
        return
    end
    local ok = LifestyleSecure.Systems.Ambition.grantCompletionReward(Target, ambtName, function()
        return true
    end)
    if not ok then
        local recordOk = LifestyleSecure.Systems.Ambition.setProgress(Target, ambtName, 1, 0)
        if not recordOk then
            return
        end
    end
    sendServerCommand(Target, "LSK", "CompleteAmbtSelf", {Target_id, ambtName})
end

LS_Commands["ResetTargetAmbt"] = function(_, arg)
    local Target = getPlayerByOnlineID(arg[1])
    local Target_id = arg[1]
    local ambtName = arg[2]
    sendServerCommand(Target, "LSK", "ResetAmbtSelf", {Target_id, ambtName})
end

LS_Commands["LSSCTest"] = function(_, arg)

    local Argument = arg[1]


    if not Argument then
        --print("server received LSSCTest from client and Argument is nil")
    else
        --print("server received LSSCTest from client")
    end

end

LS_Commands["Social_sendInfo"] = function(player, arg)
    local targetID = arg[1]
    local srcInfo = arg[2]
    local target = getPlayerByOnlineID(targetID)
    if not target then
        return
    end
    if not LifestyleSecure.SystemDefinitions.inRange(player, target, LifestyleSecure.SystemDefinitions.Social.requestRadius) then
        return
    end
    sendServerCommand(target, "LSK", "Social_InfoSent", {srcInfo})
end

LS_Commands["Social_requestInfo"] = function(player, arg)
    local srcID = player:getOnlineID()
    local targetID = arg[1]
    local target = getPlayerByOnlineID(targetID)
    if not target then
        return
    end
    if not LifestyleSecure.SystemDefinitions.inRange(player, target, LifestyleSecure.SystemDefinitions.Social.requestRadius) then
        return
    end
    sendServerCommand(target, "LSK", "Social_InfoRequested", {srcID})
end

LS_Commands["InteractionStart"] = function(player, arg)
    local Target = getPlayerByOnlineID(arg[1])
    local Target_id = arg[1]
    local Source = arg[2]
    local Interaction = arg[3]
    local IsClose = arg[4]
    local actionArg = arg[5]
    if not Target then
        return
    end
    local actionName = "Hug"
    if type(Interaction) == "string" then
        if string.find(Interaction, "Praise", 1, true) then
            actionName = "Praise"
        elseif string.find(Interaction, "Boo", 1, true) then
            actionName = "Boo"
        elseif string.find(Interaction, "Shoo", 1, true) then
            actionName = "Shoo"
        elseif string.find(Interaction, "HighFive", 1, true) then
            actionName = "HighFive"
        elseif string.find(Interaction, "Plushie", 1, true) then
            actionName = "PlushieTalk"
        end
    end
    local accepted = LifestyleSecure.Systems.Social.request(player, Target, actionName)
    if not accepted then
        return
    end
    sendServerCommand(Target, "LSK", "WasAskedToInteract", {Target_id, Source, Interaction, IsClose, actionArg})
end

LS_Commands["StopOrStartInteraction"] = function(_, arg)

    local Target = getPlayerByOnlineID(arg[1])
    local Target_id = arg[1]
    local InteractionState = arg[2]
    --print("server received StopOrStartInteraction from client and is sending the command")
    sendServerCommand(Target, "LSK", "ChangeInteractionState", {Target_id, InteractionState})

end

LS_Commands["makeNauseous"] = function(_, arg)
    local Target = getPlayerByOnlineID(arg[1])
    local Target_id = arg[1]
    sendServerCommand(Target, "LSK", "makeNauseous", {Target_id})
end

LS_Commands["SendGetEmbarrassed"] = function(_, arg)

    local Target = getPlayerByOnlineID(arg[1])
    local Target_id = arg[1]
    --print("server received SendGetEmbarrassed from client and is sending the command")
    sendServerCommand(Target, "LSK", "GetEmbarrassed", {Target_id})

end

LS_Commands["AddDirtPuddle"] = function(_, arg)
    local coords = arg[1]
    local isOverlay = arg[2]
    local entity
    if isOverlay then
        entity = getObjFromSqr(coords[1], coords[2], coords[3], coords[4])
    else
        entity = getCell():getGridSquare(coords[1], coords[2], coords[3])
    end
    if not entity then LSUtil.debugPrint("SERVER COMMAND AddDirtPuddle - no entity found"); return; end
    LSServerCommandHandler("CreateDirtPuddle", {entity, isOverlay, arg[3]})
end

LS_Commands["DebugAddLitter"] = function(_, arg)

    local Sx = arg[1]
    local Sy = arg[2]
    local Sz = arg[3]
    local SolidOrOverlay = arg[4]
    local LitterSprite = arg[5]
    local AvailableFloorList = {}
    local targetFloor
    local sSquare = getCell():getGridSquare(Sx, Sy, Sz)

      for x = Sx-1,Sx+1 do---get x range
        for y = Sy-1,Sy+1 do----get y range

            local thisSquare = getCell():getGridSquare(x, y, Sz)---get grid square (our radius)
        
            if thisSquare and sSquare and thisSquare:getRoom() == sSquare:getRoom() and thisSquare:isOutside() == sSquare:isOutside() and thisSquare:isInARoom() and thisSquare:getFloor() and not 
            thisSquare:isSolid() and not thisSquare:isSolidTrans() then
            
            for i=0,thisSquare:getObjects():size()-1 do-----------search objects for each square on the radius (floor counts as an object)
                local ThisObject = thisSquare:getObjects():get(i);
                if instanceof(ThisObject, "IsoObject") then
                local object = ThisObject
                local hasSolidL = false
                if object then--solid litter is the result of direct actions and as such can happen anywhere the action takes place
                    local hasOverlayL = false
                    local attachedsprite = object:getAttachedAnimSprite()
                    if object:getTextureName() and
                    (luautils.stringStarts(object:getTextureName(), "overlay_messages") or 
                    luautils.stringStarts(object:getTextureName(), "overlay_graffiti") or 
                    --luautils.stringStarts(object:getTextureName(), "floors_burnt") or 
                    luautils.stringStarts(object:getTextureName(), "overlay_blood") or 
                    luautils.stringStarts(object:getTextureName(), "blood_floor") or
                    luautils.stringStarts(object:getTextureName(), "overlay_grime") or 
                    --luautils.stringStarts(object:getTextureName(), "trash_") or 
                    luautils.stringStarts(object:getTextureName(), "trash&junk") or 
                    luautils.stringStarts(object:getTextureName(), "d_floorleaves") or 
                    luautils.stringStarts(object:getTextureName(), "d_trash")) then-----------if object already has solid litter then do not add more
                        hasSolidL = true
                    end
                    if object:getOverlaySprite() and object:getOverlaySprite():getName() and
                    (luautils.stringStarts(object:getOverlaySprite():getName(), "overlay_messages") or 
                    luautils.stringStarts(object:getOverlaySprite():getName(), "overlay_graffiti") or 
                    --luautils.stringStarts(object:getOverlaySprite():getName(), "floors_burnt") or 
                    luautils.stringStarts(object:getOverlaySprite():getName(), "overlay_blood") or 
                    luautils.stringStarts(object:getOverlaySprite():getName(), "blood_floor") or
                    luautils.stringStarts(object:getOverlaySprite():getName(), "overlay_grime") or 
                    luautils.stringStarts(object:getOverlaySprite():getName(), "trash_") or 
                    luautils.stringStarts(object:getOverlaySprite():getName(), "trash&junk") or 
                    luautils.stringStarts(object:getOverlaySprite():getName(), "d_floorleaves") or 
                    luautils.stringStarts(object:getOverlaySprite():getName(), "d_trash") or
                    luautils.stringStarts(object:getOverlaySprite():getName(), "LS_HScraps") or
                    luautils.stringStarts(object:getOverlaySprite():getName(), "LS_Scraps")) then-----------if object already has overlay litter then do not add more
                        hasOverlayL = true
                    end
                    if object and attachedsprite and object:isFloor() then--overlays such as dirt and grime almost always occur based on random factors and movement so it only happens indoors
                        for n=1,attachedsprite:size() do
                            local sprite = attachedsprite:get(n-1)
                            if sprite and sprite:getParentSprite() and sprite:getParentSprite():getName() and
                            (luautils.stringStarts(sprite:getParentSprite():getName(), "overlay_messages") or 
                            luautils.stringStarts(sprite:getParentSprite():getName(), "overlay_graffiti") or 
                            --luautils.stringStarts(sprite:getParentSprite():getName(), "floors_burnt") or 
                            luautils.stringStarts(sprite:getParentSprite():getName(), "overlay_blood") or 
                            luautils.stringStarts(sprite:getParentSprite():getName(), "blood_floor") or
                            luautils.stringStarts(sprite:getParentSprite():getName(), "overlay_grime") or 
                            luautils.stringStarts(sprite:getParentSprite():getName(), "trash_") or 
                            luautils.stringStarts(sprite:getParentSprite():getName(), "trash&junk") or 
                            luautils.stringStarts(sprite:getParentSprite():getName(), "d_floorleaves") or 
                            luautils.stringStarts(sprite:getParentSprite():getName(), "LS_HScraps") or 
                            luautils.stringStarts(sprite:getParentSprite():getName(), "d_trash")) then-----------if object already has overlay litter then do not add more
                                hasOverlayL = true
                            end
                        end
                                
                    end
                    if SolidOrOverlay == 2 and not hasOverlayL then
                        table.insert(AvailableFloorList, object)
                    end
                end
                    if SolidOrOverlay == 1 and not hasSolidL then
                        table.insert(AvailableFloorList, thisSquare)
                    end
                    
                end
                end
                
            end
            
        end
        
    end

    if #AvailableFloorList > 0 then
        local randomTile = ZombRand(#AvailableFloorList) + 1
        targetFloor = AvailableFloorList[randomTile]
        if targetFloor then
            if SolidOrOverlay == 1 then
                local NewLitterObj = IsoObject.new(targetFloor, LitterSprite)
                targetFloor:AddTileObject(NewLitterObj)
                NewLitterObj:transmitCompleteItemToClients()
                targetFloor:transmitAddObjectToSquare(NewLitterObj, -1)
                --targetFloor:transmitAddObjectToSquare(NewLitterObj.javaObject, -1)
            
            
            elseif SolidOrOverlay == 2 then
                --targetFloor:setOverlaySprite(LitterSprite, 1, 1, 1, 1, true)--string/transmit
                --targetFloor:setOverlaySprite(LitterSprite, true)--string/transmit
                --targetFloor:transmitUpdatedSpriteToClients()

                local square = targetFloor:getSquare()
                local objOnFloor
                if square then
                    for i=1,square:getObjects():size() do
                        local thisObject = square:getObjects():get(i-1)
                        if thisObject then
                            local objSprite = thisObject:getSprite()
                            if objSprite then
                                local objProperties = objSprite:getProperties()
                                if objProperties:has("BlocksPlacement") then
                                    objOnFloor = true
                                end
                            end
                        end
                    end
                    if not objOnFloor then
                        targetFloor:setOverlaySprite(LitterSprite, 1, 1, 1, 1)--string/transmit
                        targetFloor:transmitUpdatedSpriteToClients()
                    end
                end
                
                --targetFloor:setOverlaySprite(LitterSprite, 1, 1, 1, 1, false)--string/transmit
                --if not objOnFloor then
                --    targetFloor:setOverlaySprite(LitterSprite, true)--string/transmit
                --    targetFloor:transmitUpdatedSpriteToClients()
                --end
                
            end
        end
    end
end

LS_Commands["RemoveDirtTileDebug"] = function(_, arg)

    local x = arg[1]
    local y = arg[2]
    local z = arg[3]
    local range = arg[4]

    local square = getCell():getGridSquare(x,y,z)
    if not square then return; end
    local sqrX, sqrY = square:getX(), square:getY()

    local listFull = {"overlay_grime","trash&junk","trash_","d_floorleaves","d_trash","LS_Scraps","brokenglass_",
    "overlay_messages","overlay_graffiti","overlay_blood","LS_HScraps","blood_floor"}

      for x = sqrX-range,sqrX+range do
        for y = sqrY-range,sqrY+range do
            local thisSqr = getCell():getGridSquare(x,y,z)
            if thisSqr then
                local mustRemove = {}
                for j=0,thisSqr:getObjects():size()-1 do
                    if j < 0 or j > thisSqr:getObjects():size() then break; end
                    local object = thisSqr:getObjects():get(j)
                    if object then
                        local texName = object:getTextureName()
                        local spriteName = object:getOverlaySprite() and object:getOverlaySprite():getName()
                        local hasChange

                        for n=1, #listFull do
                            if texName and luautils.stringStarts(texName, listFull[n]) then table.insert(mustRemove, object); break; end
                            if spriteName and luautils.stringStarts(spriteName, listFull[n]) then object:setOverlaySprite("", true); hasChange = true; spriteName = false; end
                            local attachedsprite = object:getAttachedAnimSprite()
                            if attachedsprite then
                                for i=0,attachedsprite:size()-1 do
                                    if i < 0 or i > attachedsprite:size() then break; end
                                    local sprite = attachedsprite:get(i)
                                    local spriteParentName = sprite and sprite:getParentSprite() and sprite:getParentSprite():getName()
                                    if spriteParentName and luautils.stringStarts(spriteParentName, listFull[n]) then hasChange = true; object:RemoveAttachedAnim(i); break; end
                                end
                            end
                        end
                        if hasChange then object:transmitUpdatedSpriteToClients(); end
                        --if mustRemove then thisSqr:transmitRemoveItemFromSquare(object); thisSqr:RemoveTileObject(object); end
                    end
                end
                if #mustRemove > 0 then
                    for n=1, #mustRemove do
                        thisSqr:transmitRemoveItemFromSquare(mustRemove[n]); thisSqr:RemoveTileObject(mustRemove[n]);
                    end
                end
            end
        end
    end

end

LS_Commands["RemoveDirtTile"] = function(player, arg)

    local x = arg[1]
    local y = arg[2]
    local z = arg[3]
    local isHeavy = arg[4] == true or arg[4] == 1 or arg[4] == "true"

    local thisSqr = getCell():getGridSquare(x, y, z)
        
    if not thisSqr then return; end

    local listDirt = {"overlay_grime","trash&junk","trash_","d_floorleaves","d_trash","LS_Scraps","brokenglass_"}
    local listBlood = {"overlay_messages","overlay_graffiti","overlay_blood","LS_HScraps","blood_floor"}
    local mustRemove = {}
    for j=0,thisSqr:getObjects():size()-1 do
        if j < 0 or j > thisSqr:getObjects():size() then break; end
        local object = thisSqr:getObjects():get(j)
        if object then
            local attachedsprite = object:getAttachedAnimSprite()
            local texName = object:getTextureName()
            local spriteName = object:getOverlaySprite() and object:getOverlaySprite():getName()

            if not isHeavy then
                for n=1, #listDirt do
                    if texName and luautils.stringStarts(texName, listDirt[n]) then table.insert(mustRemove, object); break; end
                    if spriteName and luautils.stringStarts(spriteName, listDirt[n]) then object:setOverlaySprite("", true); object:transmitUpdatedSpriteToClients(); break; end
                    if attachedsprite then
                        local removed
                        for i=0,attachedsprite:size()-1 do
                            if i < 0 or i > attachedsprite:size() then break; end
                            local sprite = attachedsprite:get(i)
                            local spriteParentName = sprite and sprite:getParentSprite() and sprite:getParentSprite():getName()
                            if spriteParentName and luautils.stringStarts(spriteParentName, listDirt[n]) then removed = true; object:RemoveAttachedAnim(i); object:transmitUpdatedSpriteToClients(); break; end
                        end
                        if removed then break; end
                    end
                end
            else
                for n=1, #listBlood do
                    if texName and luautils.stringStarts(texName, listBlood[n]) then table.insert(mustRemove, object); break; end
                    if spriteName and luautils.stringStarts(spriteName, listBlood[n]) then object:setOverlaySprite("", true); object:transmitUpdatedSpriteToClients(); break; end
                    if attachedsprite then
                        local removed
                        for i=0,attachedsprite:size()-1 do
                            if i < 0 or i > attachedsprite:size() then break; end
                            local sprite = attachedsprite:get(i)
                            local spriteParentName = sprite and sprite:getParentSprite() and sprite:getParentSprite():getName()
                            if spriteParentName and luautils.stringStarts(spriteParentName, listBlood[n]) then removed = true; object:RemoveAttachedAnim(i); object:transmitUpdatedSpriteToClients(); break; end
                        end
                        if removed then break; end
                    end
                end
            end
        end
    end
    if #mustRemove > 0 then
        for n=1, #mustRemove do
            thisSqr:transmitRemoveItemFromSquare(mustRemove[n]); thisSqr:RemoveTileObject(mustRemove[n]);
        end
    end

    -- Vanilla blood puddles (haveBlood) were never cleared on dedicated before.
    if isHeavy and thisSqr.haveBlood and thisSqr:haveBlood() and thisSqr.removeBlood then
        thisSqr:removeBlood(false, false)
    end

end

LS_Commands["TeleportSittingLocation"] = function(_, arg)

    local TargetName = getPlayerByOnlineID(arg[1])
    local TargetName_id = arg[1]
    local SourcePlayerName = arg[2]
    local teleportX = arg[3][1]
    local teleportY = arg[3][2]
    local NSvar = arg[3][3]
    --print("server received from client and is sending the command")
    sendServerCommand(TargetName, "LSK", "TeleportSittingLocation", {SourcePlayerName, teleportX, teleportY, NSvar})

    local otherPlayers = getOnlinePlayers()
    
    if otherPlayers then
    
    for index = 1, otherPlayers:size() do
        local sourcePlayer = otherPlayers:get(index-1)

        if sourcePlayer and sourcePlayer:getDisplayName() == SourcePlayerName then
            --thisPlayer:Say("teleporting " .. tostring(sourcePlayer:getDisplayName()))
            if teleportX and teleportY then
                sourcePlayer:setY(teleportY)
                sourcePlayer:setX(teleportX)
                --sourcePlayer:setLy(teleportY)
                --sourcePlayer:setLx(teleportX)
                
                if not string.match(tostring(sourcePlayer:getCurrentState()), "PlayerSitOnGroundState") then
                    sourcePlayer:setVariable("SittingToggleStart", NSvar)
                    sourcePlayer:reportEvent("EventSitOnGround");
                    sourcePlayer:setVariable("SittingToggleLoop", NSvar)
                end
                
            end

            break

        end

    end

    end

end

LS_Commands["ChangeAnimVarMulti"] = function(player, arg)

    local SourcePlayerName = arg[1]
    local AnimType = arg[2]
    local AnimVar = arg[3]
    local AnimType2 = arg[4]
    local AnimVar2 = arg[5]
    --print("server received from client and is sending the command")
    LifestyleSecure.NearbySync.SendAroundPlayer(
        player,
        35,
        "LSK",
        "ChangeAnimVarMulti",
        {SourcePlayerName, AnimType, AnimVar, AnimType2, AnimVar2}
    )

    local otherPlayers = getOnlinePlayers()
 
    --for index = 0, getOnlinePlayers():size() - 1 do

        --local sourcePlayer = getOnlinePlayers():get(index)
    if otherPlayers then
    
    for index = 1, otherPlayers:size() do
        local sourcePlayer = otherPlayers:get(index-1)

       -- if sourcePlayer:getDisplayName() == SourcePlayerName and sourcePlayer:getDisplayName() ~= thisPlayer:getDisplayName() then
        if sourcePlayer and sourcePlayer:getDisplayName() == SourcePlayerName then
            --thisPlayer:Say("source is " .. tostring(sourcePlayer:getDisplayName()))
            
            if AnimVar then
                sourcePlayer:setVariable(AnimType, AnimVar)
                if AnimType == "SittingToggleStart" and ((AnimVar == "N") or (AnimVar == "S")) then
                    --thisPlayer:Say("reporting eventsitOnGround")
                    sourcePlayer:reportEvent("EventSitOnGround")
                end
            else
                sourcePlayer:clearVariable(AnimType)
            end

            if AnimVar2 then
                sourcePlayer:setVariable(AnimType2, AnimVar2)
                if AnimType2 == "SittingToggleStart" and ((AnimVar2 == "N") or (AnimVar2 == "S")) then
                    --thisPlayer:Say("reporting eventsitOnGround")
                    sourcePlayer:reportEvent("EventSitOnGround")
                end
            else
                sourcePlayer:clearVariable(AnimType2)
            end

            break

        end

    end

    end

end

LS_Commands["ChangeAnimVar"] = function(_, arg)

    local TargetName = getPlayerByOnlineID(arg[1])
    local TargetName_id = arg[1]
    local SourcePlayerName = arg[2]
    local args = arg[3]
    sendServerCommand(TargetName, "LSK", "ChangeAnimVar", {SourcePlayerName, args})

    local otherPlayers = getOnlinePlayers()
    if not otherPlayers then return; end
    
    for index = 1, otherPlayers:size() do
        local sourcePlayer = otherPlayers:get(index-1)
        if sourcePlayer and sourcePlayer:getDisplayName() == SourcePlayerName then
            for n=1, #args, 2 do
                if n == #args then break; end
                if args[n] and type(args[n]) == "string" then
                    if args[n+1] then
                        sourcePlayer:setVariable(args[n], args[n+1])
                        if args[n] == "SittingToggleStart" then sourcePlayer:reportEvent("EventSitOnGround"); end
                    else
                        sourcePlayer:clearVariable(args[n])
                    end
                end
            end
            break
        end
    end
end

LS_Commands["IsPlayingMusic"] = function(player, arg)

    local listener = getPlayerByOnlineID(arg[1])
    local listener_id = arg[1]
    local SourceMusiclvl = arg[2]
    LifestyleSecure.Systems.Music.setListenerState(
        listener,
        true,
        LifestyleSecure.SystemDefinitions.playerKey(player),
        45
    )
    --print("server received from client and is sending the command")
    sendServerCommand(listener, "LSK", "IsListeningToMusic", {listener_id, SourceMusiclvl})

end

LS_Commands["IsStartingDuet"] = function(_, arg)

    local currentPerformer = getPlayerByOnlineID(arg[1])
    local currentPerformer_id = arg[1]
    local SourceWaitingDuet = arg[2]
    --print("server received from client and is sending the command")
    sendServerCommand(currentPerformer, "LSK", "IsStartingDuet", {currentPerformer_id, SourceWaitingDuet})

end

LS_Commands["IsPlayingDJ"] = function(player, arg)

    local DJlistener = getPlayerByOnlineID(arg[1])
    local DJlistener_id = arg[1]
    local SourceMusiclvl = arg[2]
    local SourceDJ = arg[3]
    local SourceIsDJ = arg[4]
    LifestyleSecure.Systems.Music.setListenerState(
        DJlistener,
        true,
        LifestyleSecure.SystemDefinitions.playerKey(player),
        45
    )
    --print("server received from client and is sending the command")
    sendServerCommand(DJlistener, "LSK", "IsListeningToDJ", {DJlistener_id, SourceMusiclvl, SourceDJ, SourceIsDJ})

end

LS_Commands["AskIfIsDancing"] = function(_, arg)

    local DanceTarget = getPlayerByOnlineID(arg[1])
    local DanceTarget_id = arg[1]
    local DanceProposer = arg[2]
    --print("server received AskToDance from client and is sending the command")
    sendServerCommand(DanceTarget, "LSK", "WasAskedIfIsDancing", {DanceTarget_id, DanceProposer})

end

LS_Commands["OtherPlayerIsDancing"] = function(_, arg)

    local DanceProposer = getPlayerByOnlineID(arg[1])
    local DanceProposer_id = arg[1]
    local IsDancing = arg[2]
    --print("server received AcceptedDance from client and is sending the command")
    sendServerCommand(DanceProposer, "LSK", "OtherPlayerIsDancingResponse", {DanceProposer_id, IsDancing})

end

LS_Commands["AskToDance"] = function(player, arg)

    local DanceTarget = getPlayerByOnlineID(arg[1])
    local DanceTarget_id = arg[1]
    local DanceProposer = arg[2]
    local accepted = LifestyleSecure.Systems.Dance.requestPartner(player, DanceTarget)
    if not accepted then
        return
    end
    --print("server received AskToDance from client and is sending the command")
    sendServerCommand(DanceTarget, "LSK", "WasAskedToDance", {DanceTarget_id, DanceProposer})

end

LS_Commands["AcceptedDance"] = function(player, arg)

    local DanceProposer = getPlayerByOnlineID(arg[1])
    local DanceProposer_id = arg[1]
    local DancePartner = arg[2]
    local PartnerX = arg[3]
    local PartnerY = arg[4]
    local accepted = LifestyleSecure.Systems.Dance.respond(player, DanceProposer, true)
    if not accepted then
        return
    end
    --print("server received AcceptedDance from client and is sending the command")
    sendServerCommand(DanceProposer, "LSK", "DanceWasAccepted", {DanceProposer_id, DancePartner, PartnerX, PartnerY})

end

LS_Commands["StopDance"] = function(player, arg)

    local DanceTarget = getPlayerByOnlineID(arg[1])
    local DanceTarget_id = arg[1]
    LifestyleSecure.Systems.Dance.stop(player)
    --print("server received StopDance from client and is sending the command")
    sendServerCommand(DanceTarget, "LSK", "PartnerStoppedDancing", {DanceTarget_id})

end

LS_Commands["FaceDanceProposer"] = function(_, arg)

    local DancePartner = getPlayerByOnlineID(arg[1])
    local DancePartner_id = arg[1]
    local ProposerX = arg[2]
    local ProposerY = arg[3]
    print("server received FaceDanceProposer from client and is sending the command")
    sendServerCommand(DancePartner, "LSK", "FaceDancingProposer", {DancePartner_id, ProposerX, ProposerY})

end

LS_Commands["ChangeDiscoStyle"] = function(_, arg)

    local style = arg[1]
    local x = arg[2]
    local y = arg[3]
    local z = arg[4]
    local s = arg[5]
    --print("server received from client and is sending the command")
    
    LifestyleSecure.NearbySync.SendAround(x, y, z, 50, "LSK", "ChangeDiscoStyle", {style, x, y, z, s})
    
    local sqr = getCell():getGridSquare(x,y,z);
    local DiscoBall
    
            for i=1,sqr:getObjects():size() do
                local thisObject = sqr:getObjects():get(i-1)

                local thisSprite = thisObject:getSprite()
                
                if thisSprite ~= nil then
                
                    local properties = thisObject:getSprite():getProperties()

                    if properties ~= nil then
                        local groupName = nil
                        local customName = nil
                        local thisSpriteName = nil
                    
                        local thisSprite = thisObject:getSprite()
                        if thisSprite:getName() then
                            thisSpriteName = thisSprite:getName()
                        end
                    
                        if properties:has("GroupName") then
                            groupName = properties:get("GroupName")
                        end
                    
                        if properties:has("CustomName") then
                            customName = properties:get("CustomName")
                        end
                    
                        if customName == "Disco Ball" then
                            DiscoBall = thisObject;
                        end
                    end
                end
            end
    



    if DiscoBall:hasModData() and
    DiscoBall:getModData().OnOff ~= nil and
    DiscoBall:getModData().OnOff == "on" then
    
        DiscoBall:getModData().Mode = style
        DiscoBall:getModData().Shuffle = s
    end

end

LS_Commands["TurnDiscoBallOff"] = function(_, arg)

    local playerDiscoCommand = arg[1]
    local x = arg[2]
    local y = arg[3]
    local z = arg[4]
    --print("server received from client and is sending the command")
    LifestyleSecure.NearbySync.SendAround(
        x, y, z, 50, "LSK", "TurnDiscoBallOff",
        {playerDiscoCommand, x, y, z}
    )

    local sqr = getCell():getGridSquare(x,y,z);
    local DiscoBall
    
            for i=1,sqr:getObjects():size() do
                local thisObject = sqr:getObjects():get(i-1)

                local thisSprite = thisObject:getSprite()
                
                if thisSprite ~= nil then
                
                    local properties = thisObject:getSprite():getProperties()

                    if properties ~= nil then
                        local groupName = nil
                        local customName = nil
                        local thisSpriteName = nil
                    
                        local thisSprite = thisObject:getSprite()
                        if thisSprite:getName() then
                            thisSpriteName = thisSprite:getName()
                        end
                    
                        if properties:has("GroupName") then
                            groupName = properties:get("GroupName")
                        end
                    
                        if properties:has("CustomName") then
                            customName = properties:get("CustomName")
                        end

                        if customName == "Disco Ball" then
                            DiscoBall = thisObject;
                        end
                    end
                end
            end


    if not DiscoBall then
    print("failed")
    return end

    if DiscoBall:hasModData() and
    DiscoBall:getModData().OnOff ~= nil and
    DiscoBall:getModData().OnOff == "on" then
    
        DiscoBall:getModData().OnOff = playerDiscoCommand
        --Jukebox:transmitModData()
    else
        return
    end


end

LS_Commands["JukeboxStart"] = function(_, arg)

    local x = arg[1]
    local y = arg[2]
    local z = arg[3]
    --print("server received from client and is sending the command")
    LifestyleSecure.NearbySync.SendAround(x, y, z, 50, "LSK", "JukeboxStart", {x, y, z})

end

LS_Commands["TurnJukeboxOff"] = function(_, arg)

    local x = arg[1]
    local y = arg[2]
    local z = arg[3]
    --print("server received from client and is sending the command")
    LifestyleSecure.NearbySync.SendAround(x, y, z, 50, "LSK", "TurnJukeboxOff", {x, y, z})

    local sqr = getCell():getGridSquare(x,y,z);
    local Jukebox
    
            for i=1,sqr:getObjects():size() do
                local thisObject = sqr:getObjects():get(i-1)

                local thisSprite = thisObject:getSprite()
                
                if thisSprite ~= nil then
                
                    local properties = thisObject:getSprite():getProperties()

                    if properties ~= nil then
                        local groupName = nil
                        local customName = nil
                        local thisSpriteName = nil
                    
                        local thisSprite = thisObject:getSprite()
                        if thisSprite:getName() then
                            thisSpriteName = thisSprite:getName()
                        end
                    
                        if properties:has("GroupName") then
                            groupName = properties:get("GroupName")
                        end
                    
                        if properties:has("CustomName") then
                            customName = properties:get("CustomName")
                        end
                    
                        if customName == "Jukebox" then
                            Jukebox = thisObject;
                        end
                    end
                end
            end


    if not Jukebox then
    print("failed")
    return end

    if Jukebox:hasModData() and
    Jukebox:getModData().OnOff ~= nil and
    Jukebox:getModData().OnOff == "on" then
    
        Jukebox:getModData().OnOff = "off"
        Jukebox:getModData().OnPlay = "nothing"
        --Jukebox:transmitModData()
    else
        return
    end


end

LS_Commands["JukeboxStyleChangePlayerPlaylist"] = function(_, arg)

    local x = arg[1]
    local y = arg[2]
    local z = arg[3]
    local style = arg[4]
    local length = arg[5]
    local genre = arg[6]
    local customPlaylist = arg[7]
    
    --print("server received from client and is sending the command")
    LifestyleSecure.NearbySync.SendAround(
        x,
        y,
        z,
        50,
        "LSK",
        "JukeboxStyleChangeCustom",
        {x, y, z, style, length, genre, customPlaylist}
    )

    local sqr = getCell():getGridSquare(x,y,z);
    local Jukebox
    
            for i=1,sqr:getObjects():size() do
                local thisObject = sqr:getObjects():get(i-1)

                local thisSprite = thisObject:getSprite()
                
                if thisSprite ~= nil then
                
                    local properties = thisObject:getSprite():getProperties()

                    if properties ~= nil then
                        local groupName = nil
                        local customName = nil
                        local thisSpriteName = nil
                    
                        local thisSprite = thisObject:getSprite()
                        if thisSprite:getName() then
                            thisSpriteName = thisSprite:getName()
                        end
                    
                        if properties:has("GroupName") then
                            groupName = properties:get("GroupName")
                        end
                    
                        if properties:has("CustomName") then
                            customName = properties:get("CustomName")
                        end

                        if customName == "Jukebox" then
                            Jukebox = thisObject;
                        end
                    end
                end
            end


    if not Jukebox then
    print("failed")
    return end

    if Jukebox:hasModData() and
    Jukebox:getModData().OnOff ~= nil and
    Jukebox:getModData().OnOff == "on" then
    
        Jukebox:getModData().OnPlay = "playing"
        Jukebox:getModData().Style = style
        Jukebox:getModData().customPlaylist = customPlaylist
        --Jukebox:transmitModData()
    else
        return
    end


end

LS_Commands["JukeboxStyleChange"] = function(_, arg)

    local x = arg[1]
    local y = arg[2]
    local z = arg[3]
    local style = arg[4]
    local length = arg[5]
    local genre = arg[6]
    
    --print("server received from client and is sending the command")
    LifestyleSecure.NearbySync.SendAround(
        x,
        y,
        z,
        50,
        "LSK",
        "JukeboxStyleChange",
        {x, y, z, style, length, genre}
    )

    local sqr = getCell():getGridSquare(x,y,z);
    local Jukebox
    
            for i=1,sqr:getObjects():size() do
                local thisObject = sqr:getObjects():get(i-1)

                local thisSprite = thisObject:getSprite()
                
                if thisSprite ~= nil then
                
                    local properties = thisObject:getSprite():getProperties()

                    if properties ~= nil then
                        local groupName = nil
                        local customName = nil
                        local thisSpriteName = nil
                    
                        local thisSprite = thisObject:getSprite()
                        if thisSprite:getName() then
                            thisSpriteName = thisSprite:getName()
                        end
                    
                        if properties:has("GroupName") then
                            groupName = properties:get("GroupName")
                        end
                    
                        if properties:has("CustomName") then
                            customName = properties:get("CustomName")
                        end

                        if customName == "Jukebox" then
                            Jukebox = thisObject;
                        end
                    end
                end
            end


    if not Jukebox then
    print("failed")
    return end

    if Jukebox:hasModData() and
    Jukebox:getModData().OnOff ~= nil and
    Jukebox:getModData().OnOff == "on" then
    
        Jukebox:getModData().OnPlay = "playing"
        Jukebox:getModData().Style = style
        --Jukebox:transmitModData()
    else
        return
    end


end

LS_Commands["StopJukeSong"] = function(_, arg)

    local x = arg[1]
    local y = arg[2]
    local z = arg[3]
    --print("server received from client and is sending the command")
    LifestyleSecure.NearbySync.SendAround(x, y, z, 50, "LSK", "StopJukeSong", {x, y, z})

end

LS_Commands["isPlayingJuke"] = function(_, arg)

    --local isPlayingJukeSong = nil;
    local genre = arg[2]
    local JukeReusableID = arg[1]
    local playercommand = arg[6]
    
--    print("server received from client and is sending the command")
--    if sqr then
--    print("is sqr")

--            for i=1,sqr:getObjects():size() do
--                local thisObject = sqr:getObjects():get(i-1)
--
--                local thisSprite = thisObject:getSprite()
--                
--                if thisSprite ~= nil then
--                
--                    local properties = thisObject:getSprite():getProperties()
--
--                    if properties ~= nil then
--                        local groupName = nil
--                        local customName = nil
--                        local thisSpriteName = nil
--                    
--                        --local thisSprite = thisObject:getSprite()
--                        if thisSprite:getName() then
--                            thisSpriteName = thisSprite:getName()
--                        end
--                    
--                        if properties:has("GroupName") then
--                            groupName = properties:get("GroupName")
--                        end
--                    
--                        if properties:has("CustomName") then
--                            customName = properties:get("CustomName")
--                        end
--
--                        if customName == "Jukebox" then
--                            Jukebox = thisObject;
--                            spriteName = thisSpriteName;
--                        end
--                    end
--                end
--            end


--    if not Jukebox then
--    print("failed")
--    return end

    local x = arg[3]
    local y = arg[4]
    local z = arg[5]
    
--    local emitter = getWorld():getFreeEmitter();
--    emitter:setPos(x, y, 0);

            if playercommand == "beforeplay" then
            --print("trying to send beforeplay")
            LifestyleSecure.NearbySync.SendAround(
                x, y, z, 50, "LSK", "isPlayingJuke",
                {genre, x, y, z, JukeReusableID, playercommand}
            )

            end

            if playercommand == "stop" then
            --print("trying to send stop")
            LifestyleSecure.NearbySync.SendAround(
                x, y, z, 50, "LSK", "isPlayingJuke",
                {genre, x, y, z, JukeReusableID, playercommand}
            )

            end

    --sendServerCommand("LSK", "isPlayingJuke", {genre, x, y, z, JukeReusableID, playercommand})
    --isPlayingJukeSong = getSoundManager():playSound(genre, sqr, 5, 75, 0.7, true);
    --addSound(Jukebox, x, y, z, 30, 10)


    --end
end

LS_Commands["JukeTurnedOn"] = function(_, arg)

    --local isPlayingJukeSong = nil;
    local genre = arg[1]
    local x = arg[2]
    local y = arg[3]
    local z = arg[4]
    local JukeReusableID = arg[5]
    local playercommand = arg[6]
    local sqr = getCell():getGridSquare(x, y, z);
--    print("server received from client and is sending the command")
    if sqr then
    --print("is sqr")

            for i=1,sqr:getObjects():size() do
                local thisObject = sqr:getObjects():get(i-1)

                local thisSprite = thisObject:getSprite()
                
                if thisSprite ~= nil then
                
                    local properties = thisObject:getSprite():getProperties()

                    if properties ~= nil then
                        local groupName = nil
                        local customName = nil
                        local thisSpriteName = nil
                    
                        --local thisSprite = thisObject:getSprite()
                        if thisSprite:getName() then
                            thisSpriteName = thisSprite:getName()
                        end
                    
                        if properties:has("GroupName") then
                            groupName = properties:get("GroupName")
                        end
                    
                        if properties:has("CustomName") then
                            customName = properties:get("CustomName")
                        end

                        if customName == "Jukebox" then
                            Jukebox = thisObject;
                            spriteName = thisSpriteName;
                        end
                    end
                end
            end


    if not Jukebox then
    --print("failed")
    return end

local JukeboxLightSprite = "LS_JukeboxLight_A_1"
local JukeboxCell = Jukebox:getCell()

                if JukeboxLightOn ~= nil then
                    if JukeboxLightOn == false then
                            local JukeboxLight = IsoObject.new(sqr, JukeboxLightSprite)
                            JukeboxLight:setName("JukeLight")
                            JukeboxLight:transmitModData();
                            sqr:AddTileObject(JukeboxLight)
                            JukeboxLightOn = true
                            Jukebox:getModData().MainLight = IsoLightSource.new(Jukebox:getX(), Jukebox:getY(), Jukebox:getZ(), 75, 75, 0, 2)
                            local JukeMainLight = Jukebox:getModData().MainLight
                            JukeboxCell:addLamppost(JukeMainLight)
                            Jukebox:transmitModData();
                            --print("LIGHTS ON")
                    else
                            --print("LIGHTS ALREADY ON")
                    return
                    end
                else
                            local JukeboxLight = IsoObject.new(sqr, JukeboxLightSprite)
                            JukeboxLight:setName("JukeLight")
                            JukeboxLight:transmitModData();
                            sqr:AddTileObject(JukeboxLight)
                            JukeboxLightOn = true
                            Jukebox:getModData().MainLight = IsoLightSource.new(Jukebox:getX(), Jukebox:getY(), Jukebox:getZ(), 75, 75, 0, 2)
                            local JukeMainLight = Jukebox:getModData().MainLight
                            JukeboxCell:addLamppost(JukeMainLight)
                            Jukebox:transmitModData();
                            --print("LIGHTS ON")
                end
    
--    local emitter = getWorld():getFreeEmitter();
--    emitter:setPos(x, y, 0);

            --if playercommand == "beforeplay" then
            --print("trying to send beforeplay")
            --sendServerCommand("LSK", "isPlayingJuke", {genre, x, y, z, JukeReusableID, playercommand})

            --end

            --if playercommand == "stop" then
            --print("trying to send stop")
            --sendServerCommand("LSK", "isPlayingJuke", {genre, x, y, z, JukeReusableID, playercommand})

            --end

    --sendServerCommand("LSK", "isPlayingJuke", {genre, x, y, z, JukeReusableID, playercommand})
    --isPlayingJukeSong = getSoundManager():playSound(genre, sqr, 5, 75, 0.7, true);
    --addSound(Jukebox, x, y, z, 30, 10)


    end
end

---------- GLOBAL MODDATA

function LS_OnInitGlobalModData()
    local lsModData = ModData.getOrCreate("LSDATA")
    if not lsModData["SO"] then lsModData["SO"] = {}; end
    LSgetSandboxOptions(lsModData["SO"])
    if not lsModData["AMBT"] then lsModData["AMBT"] = {}; end
    if not lsModData["BTY"] then lsModData["BTY"] = {}; end
    --if not ModData.exists("LSDATAPlaylists") then
    --    local LSModDataPlaylists = ModData.create("LSDATAPlaylists")
    --    LSModDataPlaylists["CustomPlaylists"] = {};
    --end
end

--function LS_OnReceiveGlobalModData(ModData, NewData)
--    if ModData ~= "LSDATAPlaylists" then return; end;
--    if not NewData then return; end
--    ModData.add(ModData, NewData);
--end

Events.OnInitGlobalModData.Add(LS_OnInitGlobalModData)
--Events.OnReceiveGlobalModData.Add(LS_OnReceiveGlobalModData)

local function grantPerkXp(player, perk, amount)
    amount = tonumber(amount) or 0
    if not player or not perk or amount <= 0 then
        return false
    end
    if addXp then
        addXp(player, perk, amount)
    elseif player.getXp then
        player:getXp():AddXP(perk, amount)
    else
        return false
    end
    if SyncXp then
        SyncXp(player)
    end
    return true
end

LS_Commands["LSK_WellnessBegin"] = function(player, args)
    local actionName = args[1]
    local durationMs = tonumber(args[2]) or 60000
    local nonce = LifestyleSecure.Systems.Wellness.begin(player, actionName, durationMs, {})
    if nonce then
        -- Keyed payload: safer than array form across B42 MP arg packing.
        sendServerCommand(player, "LSK", "LSK_ActionState", {
            phase = "begin",
            action = actionName,
            nonce = nonce,
            durationMs = durationMs,
        })
    else
        print("[LSK Wellness] begin failed action=" .. tostring(actionName)
            .. " player=" .. tostring(player and player:getDisplayName() or "?"))
    end
end

LS_Commands["LSK_WellnessComplete"] = function(player, args)
    local nonce = args[1]
    local requested = type(args[2]) == "table" and args[2] or {}
    local ok, reward = LifestyleSecure.Systems.Wellness.complete(player, nonce, requested)
    if not ok then
        print("[LSK Wellness] complete failed reason=" .. tostring(reward)
            .. " player=" .. tostring(player and player:getDisplayName() or "?"))
        return
    end
    if type(reward) == "table" then
        if (tonumber(reward.healing) or 0) > 0 and player.getBodyDamage then
            local bd = player:getBodyDamage()
            if bd and bd.AddGeneralHealth then
                bd:AddGeneralHealth(reward.healing)
            end
        end
        -- Meditation XP (meditation session) + Fitness/Nimble (yoga). Do not use LSK AddXP
        -- here: open-ended Yoga maxTime=-1 expired action proofs (action_proof_invalid).
        if (tonumber(reward.xp) or 0) > 0 and Perks and Perks.Meditation then
            grantPerkXp(player, Perks.Meditation, reward.xp)
        end
        if (tonumber(reward.fitnessXp) or 0) > 0 and Perks and Perks.Fitness then
            grantPerkXp(player, Perks.Fitness, reward.fitnessXp)
        end
        if (tonumber(reward.nimbleXp) or 0) > 0 and Perks and Perks.Nimble then
            grantPerkXp(player, Perks.Nimble, reward.nimbleXp)
        end
        sendServerCommand(player, "LSK", "LSK_ActionState", {
            phase = "complete",
            action = "Wellness",
            nonce = nonce,
            reward = reward,
        })
    end
end

LS_Commands["LSK_LearnTrack"] = function(player, args)
    local instrument = args[1]
    local trackId = args[2]
    LifestyleSecure.Systems.Music.registerTrack(instrument, trackId)
    local ok = LifestyleSecure.Systems.Music.learnTrack(player, instrument, trackId)
    if ok then
        sendServerCommand(player, "LSK", "LSK_LearnTrackResult", {instrument, trackId, true})
    end
end

LS_Commands["LSK_AmbitionProgress"] = function(player, args)
    local ambitionId = args[1]
    local goalIndex = args[2]
    local delta = args[3]
    local ok, record = LifestyleSecure.Systems.Ambition.addProgress(player, ambitionId, goalIndex, delta)
    if ok then
        sendServerCommand(player, "LSK", "LSK_AmbitionState", {ambitionId, record})
    end
end

LS_Commands["LSGoodEatingLoot"] = function(player, args)
    if not player or type(args) ~= "table" then
        return
    end
    local amount = math.floor(tonumber(args[1]) or 0)
    local x = tonumber(args[2])
    local y = tonumber(args[3])
    local z = tonumber(args[4])
    if amount < 1 or not x or not y or not z then
        return
    end
    amount = math.min(3, amount)
    local dx = player:getX() - x
    local dy = player:getY() - y
    if (dx * dx + dy * dy) > 144 then
        return
    end
    local square = getCell():getGridSquare(math.floor(x), math.floor(y), math.floor(z))
    if not square then
        return
    end
    for n = 1, amount do
        square:AddWorldInventoryItem("Lifestyle.BloodSausage", ZombRandFloat(0.0, 1.0), ZombRandFloat(0.0, 1.0), 0)
    end
end

LS_Commands["LSK_ComfortSavePreset"] = function(player, args)
    local presetName = args[1]
    local itemIds = type(args[2]) == "table" and args[2] or {}
    local ok = LifestyleSecure.Systems.Comfort.savePreset(player, presetName, itemIds)
    if ok then
        sendServerCommand(player, "LSK", "LSK_ComfortPresetSaved", {presetName, true})
    end
end

LS_Commands["LSK_InventionBegin"] = function(player, args)
    local mode = args[1]
    local inventionId = args[2]
    local durationMs = tonumber(args[3]) or 60000
    local contract = type(args[4]) == "table" and args[4] or {}
    local nonce = LifestyleSecure.Systems.Invention.beginSession(player, mode, inventionId, durationMs, contract)
    if nonce then
        sendServerCommand(player, "LSK", "LSK_ActionState", {"begin", "LSIW" .. tostring(mode), nonce, durationMs})
    end
end

LS_Commands["LSK_InventionComplete"] = function(player, args)
    local nonce = args[1]
    local ok = LifestyleSecure.Systems.Invention.completeSession(player, nonce, {
        hasIngredients = function()
            return true, true
        end,
        consumeIngredients = function()
            return true
        end,
        createOutputs = function(actor, outputs)
            local created = {}
            for i = 1, #(outputs or {}) do
                local entry = outputs[i]
                for _ = 1, entry.quantity do
                    local item = actor:getInventory():AddItem(entry.type)
                    if item then
                        sendAddItemToContainer(actor:getInventory(), item)
                        created[#created + 1] = entry.type
                    end
                end
            end
            return created
        end,
    })
    if ok then
        sendServerCommand(player, "LSK", "LSK_ActionState", {"complete", "Invention", nonce, true})
    end
end

LS_Commands["LSK_HygieneClaimFixture"] = function(player, args)
    local x, y, z, spriteName = args[1], args[2], args[3], args[4]
    local fixtureType = args[5] or "Toilet"
    local obj = getObjFromSqr(x, y, z, spriteName)
    if not obj then
        return
    end
    LifestyleSecure.Systems.Hygiene.claimFixture(player, obj, fixtureType)
end

LS_Commands["LSK_BeginAction"] = function(player, args)
    local actionName = args[1]
    local nonce = args[2]
    local duration = args[3]
    local accepted, reason = LSK_ActionAuthority.registerClient(
        player,
        actionName,
        nonce,
        duration,
        { startedAt = getTimestampMs and getTimestampMs() or 0 }
    )
    sendServerCommand(player, "LSK", "LSK_ActionState", {
        accepted = accepted == true,
        action = actionName,
        nonce = nonce,
        reason = reason,
    })
end

LS_Commands["LSK_EndAction"] = function(player, args)
    local actionName = args[1]
    local nonce = args[2]
    local valid = LSK_ActionAuthority.validate(player, actionName, nonce)
    if valid then
        LSK_ActionAuthority.cancel(player, actionName)
    end
end

LS_Commands.OnClientCommand = function(module, command, playerObj, args)
    if module == "LSK" then
        if args == nil then
            args = {}
        elseif type(args) ~= "table" then
            args = {args}
        end
        LSK_CommandRouter.dispatch(command, playerObj, args, LS_Commands)
    end
end

if isServer() or (not isServer() and not isClient()) then Events.OnClientCommand.Add(LS_Commands.OnClientCommand); end
--Events.OnClientCommand.Add(LS_Commands.OnClientCommand)

print("[LifestyleHobbies_KardinalTest] " .. LSK_NetSchema.VERSION
    .. " security=router+schema+rate-limit+authority enabled")

LS_Commands["UpdateAmbt"] = function(player, args)
    local lsModData = ModData.getOrCreate("LSDATA")
    local ogAmbt = args[1]
    local name = args[2]
    local key = args[3]
    local value = args[4]
    local forceReset = args[5]
    if (not lsModData["AMBT"][name]) or (not lsModData["AMBT"][name].custom) then lsModData["AMBT"][name] = ogAmbt; end
    --print("LS_Commands - UpdateAmbt... key is: "..key); print("LS_Commands - UpdateAmbt... value is: "..tostring(value))
    if (key ~= "resetAdm") and (lsModData["AMBT"][name][key] == value) then return; end
    lsModData["AMBT"][name][key] = value
    if (key == "resetAdm") and value then lsModData["AMBT"][name].custom = false;
    else lsModData["AMBT"][name].custom = true; lsModData["AMBT"][name].resetAdm = false; end
    lsModData["AMBT"][name].resetF = forceReset
    transmitLSDataThrottled()
    if player and player.getX then
        LifestyleSecure.NearbySync.SendAroundPlayer(player, 80, "LSK", "ResetAmbt", {name, lsModData["AMBT"][name].resetAdm})
    else
        local players = getOnlinePlayers and getOnlinePlayers() or nil
        if players then
            for i = 0, players:size() - 1 do
                local online = players:get(i)
                if online then
                    sendServerCommand(online, "LSK", "ResetAmbt", {name, lsModData["AMBT"][name].resetAdm})
                end
            end
        end
    end
end


LS_Commands.ChangePlayerState = function(playerObj, args)
    -- Per-player row on server ModData; full LSDATA broadcast is too heavy for MP.
    ModData.get("LSDATA")[playerObj:getUsername()] = args
end

local function logCustomBeauty(data, args)
    if isClient() then return; end
    if not data then return; end
    local file = getFileReader("LSCustomBeautyValues.ini",true)
    if not file then return; end -- failed to write file
    local oldValue
    while true do
        local line = file:readLine()
        if not line then file:close(); break; end
        local splitedLine = string.split(line, "=")
        local name = splitedLine[1]
        if name == args[1] then
            oldValue = true
            file:close()
            break
        end
    end
    if not oldValue then -- add
        file = getFileWriter("LSCustomBeautyValues.ini",true,true) -- append is true (add to)
        file:write(args[1].."="..tostring(args[2]).."\n")
    else -- edit
        file = getFileWriter("LSCustomBeautyValues.ini",true,false) -- append is false (overwrite)
        for k,v in pairs(data) do
            file:write(tostring(k).."="..tostring(v).."\n")
        end
    end
    file:close()
end

LS_Commands["UpdateServerBeauty"] = function(player, args)
    if not LifestyleSecure.SystemDefinitions.isAdmin(player) then
        return
    end
    local lsModData = ModData.getOrCreate("LSDATA")
    local spriteName = args[1]
    local val = LifestyleSecure.SystemDefinitions.clamp(args[2], -100, 1000)
    if not spriteName or val == nil then
        return
    end
    if not LifestyleSecure.Systems.Art.registerSprite(tostring(spriteName)) then
        -- allow non-artwork beauty overrides for admins, still clamp value
    end
    lsModData["BTY"][spriteName] = val
    transmitLSDataThrottled()
    local players = getOnlinePlayers and getOnlinePlayers() or nil
    if players then
        for i = 0, players:size() - 1 do
            local online = players:get(i)
            if online then
                sendServerCommand(online, "LSK", "UpdateClientBeauty", {spriteName, val})
            end
        end
    end
    logCustomBeauty(lsModData["BTY"], {spriteName, val})
end

local function getBeautyLines()
    local file = getFileReader("LSCustomBeautyValues.ini",false)
    if not file then return false; end
    local t, n = {}, 0
    while true do
        local line = file:readLine()
        if not line then file:close(); break; end
        local splitedLine = string.split(line, "=")
        local name = splitedLine[1]
        local val = splitedLine[2]
        t[name] = tonumber(val)
        n = n+1
    end
    return t, n
end

LS_Commands["ImportServerBeauty"] = function(player, args)
    if isClient() then return; end
    if not LifestyleSecure.SystemDefinitions.isAdmin(player) then
        return
    end
    local lsModData = ModData.getOrCreate("LSDATA")
    local allLines, num = getBeautyLines()
    if not allLines or num == 0 then print("-------- WARN: ImportServerBeauty FAILED: LSCustomBeautyValues.ini empty or null"); return; end
    lsModData["BTY"] = allLines
    transmitLSDataThrottled()
    local players = getOnlinePlayers and getOnlinePlayers() or nil
    if players then
        for i = 0, players:size() - 1 do
            local online = players:get(i)
            if online then
                sendServerCommand(online, "LSK", "ReloadClientBeauty", {})
            end
        end
    end
    print("-------- WARN: ImportServerBeauty COMPLETED: values from LSCustomBeautyValues.ini imported successfully")
end

LS_Commands["UpdateOuthouseRangeMap"] = function(player, args)
    if not LifestyleSecure.SystemDefinitions.isAdmin(player) then
        return
    end
    local lsModData = ModData.getOrCreate("LSDATA")
    local x, y = args[1], args[2]
    if not x or not y or not lsModData["SO"] or not lsModData["SO"]["OUTHOUSEAREAS"] then print("-------- WARN: UpdateOuthouseRangeMap FAILED - invalid args or data"); return; end
    if LSHygiene.TF.isInOuthouseArea(x, y, lsModData["SO"]["OUTHOUSEAREAS"]) then print("-------- WARN: UpdateOuthouseRangeMap FAILED - inside range"); return; end
    table.insert(lsModData["SO"]["OUTHOUSEAREAS"], {x, y})
    transmitLSDataThrottled()
    LifestyleSecure.NearbySync.SendAround(x, y, 0, 80, "LSK", "UpdateClientOuthouseAreas", {x, y}, true)
end