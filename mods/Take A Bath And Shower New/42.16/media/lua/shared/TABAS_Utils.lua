local TABAS_Utils = {}
local _climateManager = nil

local TABAS_GameTimes = require("TABAS_GameTimes")
local TABAS_BodyLocations = require("NPCs/TABAS_BodyLocations")

TABAS_Utils.DEBUG_ENABLE = isDebugEnabled()
TABAS_Utils.DEBUG_PRINT = true
TABAS_Utils.DEBUG_ALLOWED_ALL_ACTION = false

function TABAS_Utils.debugPrint(title, str)
    if not TABAS_Utils.DEBUG_PRINT then return end
    title = title or ""
    print("[TABAS] " .. title .. ": " .. str)
end

----------------- For Object -----------------
local function getPlayerKeyOnSquare(square)
    if not square then return nil end
    local playerObj = square:getPlayer()
    return playerObj and TABAS_Utils.getPlayerKey(playerObj) or nil
end

function TABAS_Utils.isCurrentlyUsing(playerObj, object, object2)
    if not object then return false end

    local md = object:getModData()
    local usingKey = md and md.using
    if not usingKey then return false end

    local objectSq = object:getSquare()
    local object2Sq = object2 and object2:getSquare() or nil

    local currentKey = getPlayerKeyOnSquare(objectSq)
    if currentKey == nil and object2Sq then
        currentKey = getPlayerKeyOnSquare(object2Sq)
    end

    if currentKey ~= usingKey then
        md.using = nil
        object:transmitModData()
        return false
    end

    local isUsingPlayer = TABAS_Utils.getPlayerKey(playerObj) == usingKey
    local playerSq = playerObj:getSquare()
    local isInside = playerSq == objectSq or playerSq == object2Sq

    if isUsingPlayer and isInside then
        return false
    end

    return true
end

----------------- For Characters -----------------

function TABAS_Utils.getPlayerKey(playerObj)
    if isServer() then
        local id = playerObj:getOnlineID()
        if id ~= nil and id ~= 0 then return id end
    end
    return isMultiplayer() and playerObj:getUsername() or playerObj:getPlayerNum()
end

function TABAS_Utils.getCurrentPlayerPosition(playerObj)
    local x = playerObj:getX()
    local y = playerObj:getY()
    local z = playerObj:getZ()
    return x, y, z
end

function TABAS_Utils.getBodyBloodAndDirt(playerObj)
    local visual = playerObj:getHumanVisual()
    local bodyBlood = 0
    local bodyDirt = 0
    local maxIndex = BloodBodyPartType.MAX:index()
    for i=1, maxIndex do
        local part = BloodBodyPartType.FromIndex(i-1)
        bodyBlood = bodyBlood + visual:getBlood(part)
        bodyDirt = bodyDirt + visual:getDirt(part)
    end
    bodyBlood = math.ceil(bodyBlood / BloodBodyPartType.MAX:index() * 100)
    bodyDirt = math.ceil(bodyDirt / BloodBodyPartType.MAX:index() * 100)
    return bodyBlood, bodyDirt
end

function TABAS_Utils.getClothingBloodAndDirt(playerObj)
    local blood, dirt = 0, 0
    local wornItems = playerObj:getWornItems()
    if wornItems:isEmpty() then return blood, dirt end

    local size = wornItems:size()
    for i=0, size-1 do
        local item = wornItems:get(i):getItem()
        if item:IsClothing() and not item:isHidden() then
            local coveredParts = BloodClothingType.getCoveredParts(item:getBloodClothingType())
            if coveredParts then
                local psize = coveredParts:size()
                for j=0, psize - 1 do
                    local part = coveredParts:get(j)
                    blood = blood + item:getBlood(part)
                    dirt = dirt + item:getDirt(part)
                end
            end
        end
    end
    return blood, dirt
end

-- If the Grime value is small, it will not be displayed.
function TABAS_Utils.getBodyGrimeDisplay(playerObj)
    local grime = playerObj:getModData().tabas_BodyGrime or 0
    if isDebugEnabled() then
        return math.ceil(grime)
    elseif grime >= 15 then
        return math.ceil(grime)
    end
    return 0
end

function TABAS_Utils.getRequiredSoap(playerObj)
	return ISWashYourself.GetRequiredSoap(playerObj)
end

function TABAS_Utils.increaseCharacterWetness(character, value)
    if isClient() then
        sendClientCommand('tabas_player', 'increaseWetness', {value=value})
    elseif not character:getStats():isAtMaximum(CharacterStat.WETNESS) then
        character:getBodyDamage():increaseBodyWetness(value)
        sendDamage(character)
    end
end

function TABAS_Utils.decreaseCharacterWetness(character, value)
    if isClient() then
        sendClientCommand('tabas_player', 'decreaseWetness', {value=value})
    elseif not character:getStats():isAtMinimum(CharacterStat.WETNESS) then
        character:getBodyDamage():decreaseBodyWetness(value)
        sendDamage(character)
    end
end

----------------- For Items -----------------

TABAS_Utils.SoapTypes = {["Soap2"] = true, ["BodyShampoo"] = true}

function TABAS_Utils.predicateNotBroken(item)
    return not item:isBroken()
end

function TABAS_Utils.predicateNotBrokenSponge(item)
	return item:getType() == "Sponge" and not item:isBroken()
end

function TABAS_Utils.predicateCleanStainsTool(item)
    return item and item:hasTag(ItemTag.CLEAN_STAINS) and not item:isBroken()
end

function TABAS_Utils.predicateBleach(item)
	return item:getFluidContainer() and item:getFluidContainer():contains(Fluid.Bleach) and (item:getFluidContainer():getAmount() >= ZomboidGlobals.CleanBloodBleachAmount)
end

function TABAS_Utils.predicateCleaningLiquid(item)
	return item:getFluidContainer() and item:getFluidContainer():contains(Fluid.CleaningLiquid) and (item:getFluidContainer():getAmount() >= ZomboidGlobals.CleanBloodBleachAmount)
end

function TABAS_Utils.predicateBathSalt(item)
    return item:hasTag(TABAS_Tag.BathSalt) and item:getCurrentUsesFloat() > 0
end

function TABAS_Utils.predicateBathTowel(item)
	if TABAS_Compat.BTO then
		return item:hasTag(BTO_Tag.Wipeable) and not item:isBroken()
	else
		return item:IsDrainable() and item:getType() == "BathTowel"
	end
end

function TABAS_Utils.isAvailableBathTowel(item)
    if not TABAS_Utils.predicateBathTowel(item) then
        return false
    end
    if TABAS_Compat.BTO and item:hasTag(BTO_Tag.Wipeable) then
        return (item:getWetness() or 0) < 25
    end
    return true
end

local function getBathTowelPriority(item)
    local score = 0
    if item:getType() == "BathTowel" then
        score = score + 1000
    end
    if item:IsClothing() then
        score = score + 100
    end
    if TABAS_Compat.BTO and item:hasTag(BTO_Tag.Wipeable) then
        score = score + math.max(0, 100 - math.floor(item:getWetness() or 0))
    end
    return score
end

function TABAS_Utils.getPreferredBathTowel(items, requireAvailable)
    if not items then return nil end

    local bestItem = nil
    local bestScore = -1

    local function consider(item)
        if not item then return end
        if not TABAS_Utils.predicateBathTowel(item) then return end
        if requireAvailable and not TABAS_Utils.isAvailableBathTowel(item) then return end

        local score = getBathTowelPriority(item)
        if score > bestScore then
            bestItem = item
            bestScore = score
        end
    end

    if items.size and items.get then
        for i = 0, items:size() - 1 do
            consider(items:get(i))
        end
    else
        for i = 1, #items do
            consider(items[i])
        end
    end

    return bestItem
end

function TABAS_Utils.predicateAvailableTowel(item)
    return not item:isBroken() and item:IsClothing() and item:getWetness() < 25
end

function TABAS_Utils.predicateDrainableComboTowel(item)
    return not item:isBroken() and item:IsDrainable()
end

function TABAS_Utils.predicateDrainableComboItem(item)
	return instanceof(item, "DrainableComboItem") and item:getCurrentUsesFloat() > 0
end


local function addItemUnique(items, seen, item)
    if not item then return end
    local id = item:getID()
    if seen[id] then return end
    seen[id] = true
    items:add(item)
end

local function addContainsItemUnique(items, seen, container, name, itemTag, closure)
    if not container then return end

    local contains
    if name then
        contains = container:getAllTypeEvalRecurse(name, closure, ArrayList.new())
    elseif itemTag then
        contains = container:getAllTagEvalRecurse(itemTag, closure, ArrayList.new())
    else
        return
    end

    if contains and contains:size() > 0 then
        for i = 0, contains:size() - 1 do
            addItemUnique(items, seen, contains:get(i))
        end
    end
end

function TABAS_Utils.getNearbyItems(playerObj, specifiedSquare, range, name, itemTag, closure)
    local baseSq = specifiedSquare or playerObj:getCurrentSquare()
    if not baseSq then return end

    local items = ArrayList.new()
    local seen = {}
    local playerInv = playerObj:getInventory()
    if playerInv then
        local invItems
        if name then
            invItems = playerInv:getAllTypeEvalRecurse(name, closure, ArrayList.new())
        elseif itemTag then
            invItems = playerInv:getAllTagEvalRecurse(itemTag, closure, ArrayList.new())
        end
        if invItems and invItems:size() > 0 then
            for i = 0, invItems:size() - 1 do
                addItemUnique(items, seen, invItems:get(i))
            end
        end
    end

    local r = range or 1
    for dx = -r, r do
        for dy = -r, r do
            local sq = getCell():getGridSquare(baseSq:getX()+dx, baseSq:getY()+dy, baseSq:getZ())
            if sq then
                if not baseSq:isWallTo(sq) or (baseSq:isWallTo(sq) and baseSq:isHoppableTo(sq)) then
                    local worldObjects = sq:getWorldObjects()
                    for k = 0, worldObjects:size() - 1 do
                        local witem = worldObjects:get(k):getItem()
                        if witem then
                            if instanceof(witem, "InventoryContainer") then
                                local inv = witem:getInventory()
                                if inv and not inv:isEmpty() then
                                    addContainsItemUnique(items, seen, inv, name, itemTag, closure)
                                end
                            elseif closure and closure(witem) then
                                local cont = witem:getContainer()
                                if cont then
                                    addContainsItemUnique(items, seen, cont, name, itemTag, closure)
                                end
                            end
                        end
                    end
                    local objects = sq:getObjects()
                    for l = 0, objects:size() - 1 do
                        local obj = objects:get(l)
                        if obj and obj:getSprite() then
                            local props = obj:getSprite():getProperties()
                            if props and props:has("container") then
                                local cont = obj:getContainer()
                                if cont then
                                    addContainsItemUnique(items, seen, cont, name, itemTag, closure)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return items
end

function TABAS_Utils.getAvailableTowel(playerObj)
    local playerInv = playerObj:getInventory()
    if not playerInv then return nil end

    local towels = ArrayList.new()
    if TABAS_Compat.BTO then
        towels = playerInv:getAllTagEvalRecurse(BTO_Tag.Wipeable, TABAS_Utils.isAvailableBathTowel, towels)
    else
        towels = playerInv:getAllTypeEvalRecurse("BathTowel", TABAS_Utils.isAvailableBathTowel, towels)
    end
    if not towels or towels:isEmpty() then
        return nil
    end

    return TABAS_Utils.getPreferredBathTowel(towels, true)
end

 ----------------- For Clothes -----------------

function TABAS_Utils.canAutoUnequipClothing(item, ignoreOptions, excludeList)
    if not item or item:isHidden() then return false end

    local bodyLocation = item:getBodyLocation() or item:canBeEquipped()
    local attachmentReplacement = item:getAttachmentReplacement()

    if not bodyLocation and not attachmentReplacement then
        return false
    end

    local fullType = item:getFullType()
    local excludeFullType = TABAS_BodyLocations.Exclude.FullType
    if excludeFullType[fullType] or (excludeList and excludeList[fullType]) then
        return false
    end

    if attachmentReplacement then
        return true
    end

    local excludeBodyLocations = TABAS_BodyLocations.Exclude.BodyLocations
    for i=1, #excludeBodyLocations do
        if bodyLocation == excludeBodyLocations[i] then
            return false
        end
    end

    if instanceof(item, "AlarmClockClothing") then
        if ignoreOptions or TABAS_Utils.ModOptionsValue("NotTakeoff_Watches") then
            return false
        end
    end

    if (item:getAttachmentsProvided() and item:getActualWeight() <= 0.5) then
        if ignoreOptions or TABAS_Utils.ModOptionsValue("NotTakeOff_Belts") then
            return false
        end
    end

    if ignoreOptions or TABAS_Utils.ModOptionsValue("NotTakeOff_Accessories") then
        local excludeAccessoryLocations = TABAS_BodyLocations.Exclude.AccessoryLocations
        for i=1, #excludeAccessoryLocations do
            if bodyLocation == excludeAccessoryLocations[i] then
                return false
            end
        end
    end

    if ignoreOptions or TABAS_Utils.ModOptionsValue("NotTakeOff_Glasses") then
        local excludeGlassesLocations = TABAS_BodyLocations.Exclude.GlassesLocations
        for i=1, #excludeGlassesLocations do
            if bodyLocation == excludeGlassesLocations[i] then
                return false
            end
        end
    end

    return true
end

function TABAS_Utils.countWornClothesAfterExclusions(items, excludeList)
    local count = 0
    for i=0, items:size()-1 do
        local item = items:get(i):getItem()
        if item and item:IsClothing() then
            if TABAS_Utils.canAutoUnequipClothing(item, true, excludeList) then
                count = count + 1
            end
        end
    end
    return count
end

local function removeFakeWornItem_Internal(character, bodyLocation)
    local oldItem = character:getWornItem(bodyLocation)
    if not oldItem then return end

    local srcContainer = oldItem:getContainer()
    local inv = character:getInventory()

    inv:Remove(oldItem)
    character:removeWornItem(oldItem, false)

    if isServer() then
        sendRemoveItemFromContainer(srcContainer, oldItem)
        sendClothing(character, oldItem:getBodyLocation(), nil)
    end
    if not isServer() or isClient() then
        triggerEvent("OnClothingUpdated", character)
    end
end

function TABAS_Utils.addFakeWornItem(character, itemType, locName)
    local bodyLocation = TABAS_BodyLocation[locName]
    if not bodyLocation or not itemType then return end

    local curWorn = character:getWornItem(bodyLocation)
    if curWorn and curWorn:getFullType() == itemType then
        return
    end
    if (isClient() and not isServer()) then
        sendClientCommand('tabas_player', 'addFakeWorn', { itemType = itemType, locName = locName })
        return
    end

    removeFakeWornItem_Internal(character, bodyLocation)

    local item = instanceItem(itemType)
    if not item then return end

    local inv = character:getInventory()
    inv:AddItem(item)
    if isServer() then sendAddItemToContainer(inv, item) end

    character:setWornItem(bodyLocation, item)
    if isServer() then
        sendClothing(character, bodyLocation, item)
    else
        triggerEvent("OnClothingUpdated", character)
    end
end

function TABAS_Utils.removeFakeWornItem(character, locName)
    local bodyLocation = TABAS_BodyLocation[locName]
    if not bodyLocation then return end
    if not character:getWornItem(bodyLocation) then return end

    if (isClient() and not isServer()) then
        sendClientCommand('tabas_player', 'removeFakeWorn', { locName = locName })
        return
    end

    removeFakeWornItem_Internal(character, bodyLocation)
end

----------------- Timed Action -----------------

function TABAS_Utils.isAleadyInTub(playerObj, tfc_Base)
    if not playerObj or not tfc_Base then return false end

    local isInTub = false
    local curSq = playerObj:getCurrentSquare()
    if not curSq then return false end

    local x = curSq:getX()
    local y = curSq:getY()
    if curSq:getZ() ~= tfc_Base.z then return false end

    if x == tfc_Base.x and y == tfc_Base.y then
        isInTub = true
    end
    if tfc_Base:hasLinked() then
        if x == tfc_Base.linkedX and y == tfc_Base.linkedY then
            isInTub = true
        end
    end
    return isInTub
end

function TABAS_Utils.waitFrames(self, frames, trigger)
    if trigger then
        self._waitFrames = frames
    end
    if not self._waitFrames then
        return false
    end
    self._waitFrames = self._waitFrames - 1
    if self._waitFrames > 0 then
        return true
    end
    self._waitFrames = nil
    return false
end

----------------- Game Times -----------------

function TABAS_Utils.formatedCelsiusOrFahrenheit(_temperature, _decimal)
    local decimal = _decimal or 0
	local temperature = round(_temperature, decimal)
    if getCore():isCelsius() then
        return tostring(temperature) .. " C"
    else
        local f = math.floor(temperature * 9 / 5 + 32 + 0.5)
		 return tostring(f) .. " F"
	end
end

function TABAS_Utils.getDifferentialTime(prevTime)
    if not prevTime then return 0,0,0 end
    local currentTime = TABAS_GameTimes.Calendar:getTimeInMillis()
    if not currentTime or currentTime == prevTime then return 0,0,0 end
    local dt = math.abs(currentTime - prevTime)
    -- print("Calculated Time Difference: ",dt)
    local minMod, hourMod, dayMod = 1000*60, 1000*60*60, 1000*60*60*24
    local days = math.floor(dt/dayMod)
    local output = "Diff Time: "
    if days ~= 0 then
        output = output .. tostring(days) .. "d, "
        dt = dt % dayMod
    end
    local hours = math.floor(dt/hourMod)
    if hours ~= 0 then
        output = output .. tostring(hours) .. "h, "
        dt = dt % hourMod
    end
    local minutes = math.floor(dt/minMod)
    if minutes ~= 0 then
        output = output .. tostring(minutes) .. "m"
        dt = dt - minutes*minMod
    end
    -- print(output)
    return minutes, hours, days
end

function TABAS_Utils.gameMinutesToTicks(gameMinutes)
    local minutesPerDay = TABAS_GameTimes.getMinutesPerDay()
    return math.max(1, math.floor(gameMinutes * minutesPerDay * 2.5 + 0.5))
end

function TABAS_Utils.getWorldTemperature()
    if not _climateManager then
        _climateManager = getWorld():getClimateManager()
    end
    return _climateManager:getTemperature()
end

----------------- Misc -----------------

function TABAS_Utils.ModOptionsValue(option)
    return PZAPI.ModOptions:getOptions("TakeABathAndShower"):getOption(option):getValue()
end

function TABAS_Utils.getModDataTable(character, key, create)
    if not character then return nil end
    local md = character:getModData()
    if not md then return nil end

    local t = md[key]
    if not t and create then
        t = {}
        md[key] = t
    end
    return t
end

function TABAS_Utils.clearModDataTable(character, key)
    if not character then return end
    local md = character:getModData()
    if not md then return end
    md[key] = nil
end

return TABAS_Utils
