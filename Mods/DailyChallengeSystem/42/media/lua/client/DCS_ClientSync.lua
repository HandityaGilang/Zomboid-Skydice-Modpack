if isServer() and not isClient() then return end

require "DCS_UI_Scale"
require "DCS_Translate"

DCS_Sync = DCS_Sync or {}

DCS_Sync.State = {
    challengeIDs = {},
    challenges = {},
    seed = "",
    topology = "",

    currency = 0,
    streak = 0,
    streakLevel = 0,
    dailyCompleted = {},
    dailyKills = 0,
    dailyKillsByWeapon = {},
    dailyKillsByCategory = {},
    dailyProgress = {},
    displayName = "",

    leaderboard = {
        mostCompleted = {},
        highestStreak = {},
        currentStreak = {},
        speedrun1 = {},
        speedrun7 = {},
        mostTokens = {},
    },

    npcRegistry = {},

    npcSpawnPos = {},

    initialized = false,
    lastToast = "",

    windowPositions = {},

    shopStock = {},

    shopConfig = { enabledItems = {}, customCosts = {}, customStock = {} },

    shopTraderItems = { east = {}, west = {} },

    traderLocations = { east = nil, west = nil },
}

local localPlayer = nil

local npcVisualPending = {}
local npcVisualTickCounter = 0
local npcVisualCache = {}
local npcDressedPid = {}
local npcFlagsApplied = {}

local DCS_NPC_OUTFIT_INDEX = 30000

local function countZombiesNear(zombieList, tx, ty, radius)
    if not tx or not ty then return 0 end
    local r2 = radius * radius
    local n = 0
    for i = 0, zombieList:size() - 1 do
        local z = zombieList:get(i)
        if z and not z:isDead() then
            local dx, dy = z:getX() - tx, z:getY() - ty
            if dx * dx + dy * dy <= r2 then n = n + 1 end
        end
    end
    return n
end

local function cacheEntryForZombie(z, radius)
    radius = radius or 2.5
    local zx, zy = z:getX(), z:getY()
    local best, bestDist = nil, radius * radius
    for _, entry in pairs(npcVisualCache) do
        if entry.x and entry.y then
            local dx, dy = zx - entry.x, zy - entry.y
            local d = dx * dx + dy * dy
            if d <= bestDist then best, bestDist = entry, d end
        end
    end
    return best
end

function DCS_Sync.resolveNPCChallengeId(z, radius)
    if not z then return nil end
    radius = radius or 2.0
    local st = DCS_Sync.State
    if not st or not st.npcSpawnPos or not st.npcRegistry then return nil end
    local zx, zy = z:getX(), z:getY()
    local bestBid, bestDist = nil, radius * radius
    for bidStr, sp in pairs(st.npcSpawnPos) do
        if sp.x and sp.y then
            local dx, dy = zx - sp.x, zy - sp.y
            local d = dx * dx + dy * dy
            if d <= bestDist then bestBid, bestDist = bidStr, d end
        end
    end
    if bestBid then return st.npcRegistry[bestBid] end
    return nil
end

local DEFAULT_APPEARANCE = {
    skinTexture = "MaleBody01",
    hairModel = "Short",
    hairColor = { r = 0.25, g = 0.15, b = 0.08 },
    beardModel = nil,
    beardColor = { r = 0.25, g = 0.15, b = 0.08 },
}

local function computeNPCIdlePose(npcDef)
    if not npcDef or not npcDef.id then return "0" end
    local dateNum = tonumber(os.date("!%Y%m%d")) or 0
    local nameHash = 0
    for i = 1, #npcDef.id do
        nameHash = nameHash + string.byte(npcDef.id, i)
    end
    local pose = (dateNum + nameHash) % 4
    return tostring(pose)
end

local function lookupNPCDef(z)
    if not DCS_Challenges or not DCS_Challenges.NPCNames then return nil end
    local md = z:getModData()
    if md and md.DCSNPC_Name then
        for _, npc in ipairs(DCS_Challenges.NPCNames) do
            if npc.name == md.DCSNPC_Name then return npc end
        end
    end
    local bid = tostring(z:getPersistentOutfitID())
    if bid and DCS_Sync and DCS_Sync.State and DCS_Sync.State.npcRegistry then
        local chId = DCS_Sync.State.npcRegistry[bid]
        if chId then
            local ch = DCS_Challenges.Lookup and DCS_Challenges.Lookup[chId]
            if ch and ch.npcName then
                for _, npc in ipairs(DCS_Challenges.NPCNames) do
                    if npc.name == ch.npcName then return npc end
                end
            end
        end
    end
    return nil
end

local function lookupNPCDefByName(npcName)
    if not npcName or npcName == "" or npcName == "NPC" then return nil end
    if not DCS_Challenges or not DCS_Challenges.NPCNames then return nil end
    for _, npc in ipairs(DCS_Challenges.NPCNames) do
        if npc.name == npcName then return npc end
    end
    local lowerSearch = npcName:lower()
    for _, npc in ipairs(DCS_Challenges.NPCNames) do
        if npc.name and npc.name:lower():find(lowerSearch, 1, true) then
            return npc
        end
    end
    return nil
end

local function findNPCZombieNear(zombieList, tx, ty, radius)
    if not tx or not ty then return nil end
    radius = radius or 2.0
    local best, bestDist = nil, radius * radius
    for i = 0, zombieList:size() - 1 do
        local z = zombieList:get(i)
        if z and not z:isDead() then
            local dx = z:getX() - tx
            local dy = z:getY() - ty
            local d = dx * dx + dy * dy
            if d <= bestDist then best, bestDist = z, d end
        end
    end
    return best
end

local function dressNPCZombie(z, data)
    if not z or z:isDead() then return end
    local npcDef = lookupNPCDefByName(data.npcName) or lookupNPCDef(z)
    local appearance = {
        skinTexture = data.skinTexture or (npcDef and npcDef.appearance and npcDef.appearance.skinTexture) or "MaleBody01",
        hairModel = data.hairModel or (npcDef and npcDef.appearance and npcDef.appearance.hairModel) or "Short",
        hairColor = data.hairColor or (npcDef and npcDef.appearance and npcDef.appearance.hairColor) or { r = 0.25, g = 0.15, b = 0.08 },
        beardModel = data.beardModel or (npcDef and npcDef.appearance and npcDef.appearance.beardModel),
        beardColor = data.beardColor or (npcDef and npcDef.appearance and npcDef.appearance.beardColor),
    }
    if data.isFemale ~= nil and z.setFemale then z:setFemale(data.isFemale and true or false) end
    local vis = z:getHumanVisual()
    if vis then
        vis:setSkinTextureName(appearance.skinTexture)
        vis:setHairModel(appearance.hairModel)
        if ImmutableColor then
            local hc = appearance.hairColor
            vis:setHairColor(ImmutableColor.new(hc.r, hc.g, hc.b, 1))
            if appearance.beardModel then vis:setBeardModel(appearance.beardModel) end
            local bc = appearance.beardColor or hc
            vis:setBeardColor(ImmutableColor.new(bc.r, bc.g, bc.b, 1))
        end
        vis:removeBlood()
        vis:removeDirt()
        for pi = 0, BloodBodyPartType.MAX:index() - 1 do
            local part = BloodBodyPartType.FromIndex(pi)
            vis:setBlood(part, 0)
            vis:setDirt(part, 0)
        end
        if vis.getBodyVisuals then
            local bvs = vis:getBodyVisuals()
            if bvs then
                local toRemove = {}
                for vi = 0, bvs:size() - 1 do
                    local bodyVisual = bvs:get(vi)
                    if bodyVisual and bodyVisual.getType then
                        toRemove[#toRemove + 1] = bodyVisual:getType()
                    end
                end
                for vi = 1, #toRemove do
                    vis:removeBodyVisualFromItemType(toRemove[vi])
                end
            end
        end
    end
    local iVis = z:getItemVisuals()
    if iVis then iVis:clear() end
    local wornItems = z:getWornItems()
    if wornItems then wornItems:clear() end
    if iVis then
        local isTrader = (data.outfit == "trader")
        local traderOutfit = data.traderOutfit
        if isTrader and traderOutfit and #traderOutfit > 0 then
            for _, itemType in ipairs(traderOutfit) do
                local iv = ItemVisual.new()
                iv:setItemType(itemType)
                iv:setClothingItemName(itemType)
                iVis:add(iv)
            end
        else
            local outfitItem = (npcDef and npcDef.outfit) or data.outfit or "Base.Boilersuit"
            local iv = ItemVisual.new()
            iv:setItemType(outfitItem)
            iv:setClothingItemName(outfitItem)
            iVis:add(iv)
            if ImmutableColor then
                local tint = data.tint or (npcDef and npcDef.tint) or { r = 1.0, g = 1.0, b = 1.0 }
                iv:setTint(ImmutableColor.new(tint.r, tint.g, tint.b, 1.0))
            end
            local shoes = ItemVisual.new()
            shoes:setItemType("Base.Shoes_ArmyBoots")
            shoes:setClothingItemName("Base.Shoes_ArmyBoots")
            iVis:add(shoes)
        end
    end
    local iVis2 = z:getItemVisuals()
    if iVis2 then
        for ci = 0, iVis2:size() - 1 do
            local item = iVis2:get(ci)
            if item then
                for cj = 0, BloodBodyPartType.MAX:index() - 1 do
                    local part = BloodBodyPartType.FromIndex(cj)
                    item:removeHole(cj)
                    item:setBlood(part, 0)
                    item:setDirt(part, 0)
                end
                item:setInventoryItem(nil)
            end
        end
    end
    z:setAnimatingBackwards(false)
    z:setSpeedMod(1)
    z:setVariable("ZombieHitReaction", "Chainsaw")
    z:setTarget(nil)
    z:clearAggroList()
    local desc = z:getDescriptor()
    if desc then desc:setVoicePrefix("None") end
    local emitter = z:getEmitter()
    if emitter then emitter:stopAll() end
    z:setVariable("DCSNPC", true)
    z:setVariable("bMoving", false)
    z:setVariable("isMoving", false)
    local poseVar = "0"
    if npcDef then poseVar = computeNPCIdlePose(npcDef) end
    z:setVariable("DCSNPCIdleState", poseVar)
    z:setVariable("bBecomeCrawler", false)
    z:setVariable("bCrawling", false)
    z:setVariable("FallOnFront", false)
    z:setIgnoreStaggerBack(true)
    z:setOnlyJawStab(true)
    z:resetModelNextFrame()
end

local function applyNPCVisualsToClient(bidStr, data)
    local cell = getCell and getCell() or nil
    if not cell then return false end
    local zombieList = cell:getZombieList()
    if not zombieList then return false end

    if countZombiesNear(zombieList, data.x, data.y, 2.0) ~= 1 then return false end

    local z = findNPCZombieNear(zombieList, data.x, data.y)
    if not z then return false end

    if not npcVisualCache[bidStr] then
        DCS_dprint("[DCS] NPC dressed by position: serverBid=" .. tostring(bidStr)
            .. " clientPid=" .. tostring(z:getPersistentOutfitID())
            .. " at " .. tostring(data.x) .. "," .. tostring(data.y))
    end

    dressNPCZombie(z, data)
    npcVisualCache[bidStr] = data
    npcDressedPid[bidStr] = tostring(z:getPersistentOutfitID())
    return true
end

DCS_Sync.Events = {
    onChallengesUpdated = { listeners = {} },
    onProgressUpdated = { listeners = {} },
    onCurrencyAwarded = { listeners = {} },
    onLeaderboardUpdated= { listeners = {} },
    onDailyReset = { listeners = {} },
    onPurchaseResult = { listeners = {} },
    onShopStockUpdated = { listeners = {} },
    onShopConfigUpdated = { listeners = {} },
}

local function fireEvent(event, ...)
    for _, fn in ipairs(event.listeners) do
        local ok, err = pcall(fn, ...)
        if not ok and DCS_Config.DEBUG then
            DCS_dprint("[DCS] Event listener error: " .. tostring(err))
        end
    end
end

function DCS_Sync.Events.subscribe(event, fn)
    table.insert(event.listeners, fn)
end

function DCS_Sync.Events.unsubscribe(event, fn)
    for i, v in ipairs(event.listeners) do
        if v == fn then
            table.remove(event.listeners, i)
            return
        end
    end
end

function DCS_Sync.getChallengeDef(id)
    return DCS_Challenges and DCS_Challenges.Lookup and DCS_Challenges.Lookup[id] or nil
end

function DCS_Sync.getTodayChallenges()
    if #DCS_Sync.State.challenges > 0 then
        return DCS_Sync.State.challenges
    end
    local result = {}
    for _, id in ipairs(DCS_Sync.State.challengeIDs) do
        local def = DCS_Sync.getChallengeDef(id)
        if def then
            result[#result + 1] = def
        end
    end
    return result
end

function DCS_Sync.isCompleted(challengeId)
    return DCS_Sync.State.dailyCompleted[challengeId] == true
end

function DCS_Sync.addLocalProgress(challengeId, amount)
    if not challengeId or not amount or amount <= 0 then return end
    local state = DCS_Sync.State
    if not state.dailyProgress then state.dailyProgress = {} end
    local newVal = (state.dailyProgress[challengeId] or 0) + amount
    local def = DCS_Sync.getChallengeDef(challengeId)
    if def and def.target and newVal > def.target then newVal = def.target end
    state.dailyProgress[challengeId] = newVal
end

function DCS_Sync.getCompletedCount()
    local count = 0
    for _, id in ipairs(DCS_Sync.State.challengeIDs) do
        if DCS_Sync.State.dailyCompleted[id] then
            count = count + 1
        end
    end
    return count
end

function DCS_Sync.saveWindowPos(id, x, y)
    DCS_Sync.State.windowPositions = DCS_Sync.State.windowPositions or {}
    DCS_Sync.State.windowPositions[id .. "X"] = x
    DCS_Sync.State.windowPositions[id .. "Y"] = y
    local player = getSpecificPlayer(0)
    if player then
        sendClientCommand(player, "DailyChallengeSystem", "saveWindowPos",
            { window = id, x = x, y = y })
    end
end

function DCS_Sync.getWindowPos(id, defX, defY)
    local wp = DCS_Sync.State.windowPositions or {}
    return wp[id .. "X"] or defX, wp[id .. "Y"] or defY
end

local lastZombieKillCount = 0
local sessionCountedKills = 0

local weaponHitCache = {}
local dailyKillsByWeapon = {}
local dailyKillsByCategory = {}
local lastWeaponDay = ""
local pendingWeaponKillTypes = {}
local pendingWeaponCategoryKills = {}
local lastWeaponKillFlush = 0
local hasPendingWeaponKill = false

local function handleSyncChallenges(args)
    DCS_Sync.State.challengeIDs = args.challengeIDs or {}
    DCS_Sync.State.challenges = args.challenges or {}
    DCS_Sync.State.seed = args.seed or ""
    DCS_Sync.State.topology = args.topology or ""
    DCS_dprint("[DCS] Client received syncChallenges: " .. tostring(#DCS_Sync.State.challengeIDs) .. " IDs, " .. tostring(#DCS_Sync.State.challenges) .. " objects, seed=" .. tostring(DCS_Sync.State.seed) .. " topology=" .. tostring(DCS_Sync.State.topology))
    for i, id in ipairs(DCS_Sync.State.challengeIDs) do
        DCS_dprint("[DCS]   " .. i .. ": " .. tostring(id))
    end
    fireEvent(DCS_Sync.Events.onChallengesUpdated, DCS_Sync.State)
end

local function handleSyncProgress(args)
    if args.currency ~= nil then DCS_Sync.State.currency = tonumber(args.currency) or 0 end
    if args.streak ~= nil then DCS_Sync.State.streak = tonumber(args.streak) or 0 end
    if args.streakLevel ~= nil then DCS_Sync.State.streakLevel = tonumber(args.streakLevel) or 0 end
    if args.dailyCompleted ~= nil then DCS_Sync.State.dailyCompleted = args.dailyCompleted end
    if args.dailyKills ~= nil then DCS_Sync.State.dailyKills = tonumber(args.dailyKills) or 0 end
    if args.dailyKillsByWeapon ~= nil then DCS_Sync.State.dailyKillsByWeapon = args.dailyKillsByWeapon end
    if args.dailyKillsByCategory ~= nil then DCS_Sync.State.dailyKillsByCategory = args.dailyKillsByCategory end
    if args.displayName ~= nil then DCS_Sync.State.displayName = args.displayName end
    DCS_Sync.State.initialized = true
    if args.resetProgress then
        DCS_Sync.State.dailyProgress = args.dailyProgress or {}
    else
        local serverProgress = args.dailyProgress or {}
        local clientProgress = DCS_Sync.State.dailyProgress or {}
        for k, v in pairs(serverProgress) do
            if not clientProgress[k] or v > clientProgress[k] then
                clientProgress[k] = v
            end
        end
        DCS_Sync.State.dailyProgress = clientProgress
    end
    if args.windowPositions then
        DCS_Sync.State.windowPositions = args.windowPositions
        DCS_dprint("[DCS] syncProgress: windowPositions received")
        if args.windowPositions.panelX then
            DCS_dprint("[DCS]   panelX=" .. tostring(args.windowPositions.panelX) .. " panelY=" .. tostring(args.windowPositions.panelY))
        end
    end
    lastZombieKillCount = sessionCountedKills
    DCS_dprint("[DCS] syncProgress received: streak=" .. tostring(DCS_Sync.State.streak) .. " streakLevel=" .. tostring(DCS_Sync.State.streakLevel) .. " dailyKills=" .. tostring(DCS_Sync.State.dailyKills) .. " currency=" .. tostring(DCS_Sync.State.currency))
    fireEvent(DCS_Sync.Events.onProgressUpdated, DCS_Sync.State)
end

local function handleCurrencyAwarded(args)
    local amount = tonumber(args.amount) or 0
    local newTotal = tonumber(args.newTotal) or 0
    local reason = args.reason or ""
    DCS_Sync.State.currency = newTotal
    if string.find(reason, "28 Day Streak") then
        DCS_Sync.showToast(reason, "reward")
    else
        local englishTitle = string.match(reason, "Challenge Completed: (.+)") or reason or ""
        local translatedTitle = englishTitle
        local challenges = DCS_Sync.State.challenges or {}
        for _, ch in ipairs(challenges) do
            if ch.title and ch.title == englishTitle then
                translatedTitle = DCS_Translate.challengeTitle(ch)
                break
            end
        end
        local msg = getText("IGUI_DCS_ClientSync_Toast_ChallengeCompleted")
        if translatedTitle ~= "" then msg = msg .. "\n" .. translatedTitle end
        DCS_Sync.showToast(msg, "complete")
    end
    fireEvent(DCS_Sync.Events.onCurrencyAwarded, amount, newTotal, reason)
end

local function handleToggleDefaultItemsResult(args)
    DCS_dprint("[DCS] toggleDefaultItemsResult: enabled=" .. tostring(args.enabled))
    if DCS_ShopAddItemsWindow and DCS_ShopAddItemsWindow.instance then
        DCS_ShopAddItemsWindow.instance:onToggleDefaultsResult(args)
    end
end

local function handleDailyReset(args)
    DCS_dprint("[DCS] dailyReset received: " .. tostring(#(args.challengeIDs or {})) .. " IDs")
    DCS_Sync.State.challengeIDs = args.challengeIDs or {}
    DCS_Sync.State.challenges = args.challenges or {}
    DCS_Sync.State.seed = args.seed or ""
    DCS_Sync.State.dailyCompleted = {}
    DCS_Sync.State.dailyKills = 0
    DCS_Sync.State.dailyProgress = {}
    DCS_Sync.State.npcRegistry = {}
    DCS_Sync.State.npcSpawnPos = {}
    npcVisualPending = {}
    npcVisualCache = {}
    npcDressedPid = {}
    npcFlagsApplied = {}
    DCS_Sync.State.traderLocations = { east = nil, west = nil }
    DCS_Sync.State.shopTraderItems = { east = {}, west = {} }
    weaponHitCache = {}
    dailyKillsByWeapon = {}
    dailyKillsByCategory = {}
    lastWeaponDay = ""
    lastZombieKillCount = sessionCountedKills
    DCS_Sync.showToast(getText("IGUI_DCS_ClientSync_Toast_NewChallenges"), "new")
    local snd = DCS_Challenges and DCS_Challenges.Sounds and DCS_Challenges.Sounds.dailyReset
    if snd then
        DCS_dprint("[DCS] dailyReset: playing sound " .. snd)
        DCS_Sync.playSound(snd, 1.25)
    else
        DCS_dprint("[DCS] dailyReset: no sound defined (snd=" .. tostring(snd) .. ")")
    end
    fireEvent(DCS_Sync.Events.onDailyReset, DCS_Sync.State)
    fireEvent(DCS_Sync.Events.onChallengesUpdated, DCS_Sync.State)
end

local function handleLeaderboardUpdate(args)
    DCS_Sync.State.leaderboard.mostCompleted = args.mostCompleted or {}
    DCS_Sync.State.leaderboard.highestStreak = args.highestStreak or {}
    DCS_Sync.State.leaderboard.currentStreak = args.currentStreak or {}
    DCS_Sync.State.leaderboard.speedrun1 = args.speedrun1 or {}
    DCS_Sync.State.leaderboard.speedrun7 = args.speedrun7 or {}
    DCS_Sync.State.leaderboard.mostTokens = args.mostTokens or {}
    DCS_Sync.State.leaderboard.isSP = args.isSP
    fireEvent(DCS_Sync.Events.onLeaderboardUpdated, DCS_Sync.State.leaderboard)
end

local function handleAdminResponse(args)
    if args and args.message and DCS_Sync and DCS_Sync.showToast then
        DCS_Sync.showToast(args.message, "debug")
    end
end

local function handlePurchaseResult(args)
    local success = args.success == true
    local newTotal = tonumber(args.newTotal) or DCS_Sync.State.currency
    local itemId = args.itemId or ""
    DCS_Sync.State.currency = newTotal
    if not success then
        DCS_Sync.showToast(getText("IGUI_DCS_ClientSync_Toast_NotEnoughTokens"), "debug")
    end
    fireEvent(DCS_Sync.Events.onPurchaseResult, success, newTotal, itemId)
    fireEvent(DCS_Sync.Events.onProgressUpdated, DCS_Sync.State)
end

local function handleShopStockSync(args)
    DCS_Sync.State.shopStock = {}
    local raw = args.stock or {}
    for _, entry in ipairs(raw) do
        if entry.id and entry.qty then
            DCS_Sync.State.shopStock[entry.id] = entry.qty
        end
    end
    DCS_Sync.State.shopTraderItems = { east = args.east or {}, west = args.west or {} }
    local stockCount = 0
    for _ in pairs(DCS_Sync.State.shopStock) do stockCount = stockCount + 1 end
    DCS_dprint("[DCS_SHOP] Client shopStockSync: " .. stockCount .. " items, East=" .. #args.east .. " West=" .. #args.west)
    local debugCount = 0
    for k, v in pairs(DCS_Sync.State.shopStock) do
        if debugCount < 3 then
            DCS_dprint("[DCS_SHOP]   stock[" .. k .. "] = " .. tostring(v))
            debugCount = debugCount + 1
        end
    end
    for i = 1, math.min(3, #args.east) do
        DCS_dprint("[DCS_SHOP]   east[" .. i .. "] = " .. tostring(args.east[i]))
    end
    fireEvent(DCS_Sync.Events.onShopStockUpdated, DCS_Sync.State.shopStock)
end

local function handleShopStockUpdate(args)
    DCS_Sync.State.shopStock = {}
    local raw = args.stock or {}
    for _, entry in ipairs(raw) do
        if entry.id and entry.qty then
            DCS_Sync.State.shopStock[entry.id] = entry.qty
        end
    end
    DCS_Sync.State.shopTraderItems = { east = args.east or {}, west = args.west or {} }
    local stockCount = 0
    for _ in pairs(DCS_Sync.State.shopStock) do stockCount = stockCount + 1 end
    DCS_dprint("[DCS_SHOP] Client received shopStockUpdate: " .. stockCount .. " items, East=" .. #args.east .. " West=" .. #args.west)
    fireEvent(DCS_Sync.Events.onShopStockUpdated, DCS_Sync.State.shopStock)
end

local function handleShopConfigSync(args)
    DCS_Sync.State.shopConfig = {
        enabledItems = args.enabledItems or {},
        customCosts = args.customCosts or {},
        customStock = args.customStock or {},
    }
    DCS_Sync.State.dcsSettings = {
        limitShopItems = args.limitShopItems,
        tokensPersistDeath = args.tokensPersistDeath,
        challengeProgressPersistDeath = args.challengeProgressPersistDeath,
    }
    fireEvent(DCS_Sync.Events.onShopConfigUpdated, DCS_Sync.State.shopConfig)
end

local function handleShopConfigUpdate(args)
    DCS_Sync.State.shopConfig = {
        enabledItems = args.enabledItems or {},
        customCosts = args.customCosts or {},
        customStock = args.customStock or {},
    }
    DCS_Sync.State.dcsSettings = {
        limitShopItems = args.limitShopItems,
        tokensPersistDeath = args.tokensPersistDeath,
        challengeProgressPersistDeath = args.challengeProgressPersistDeath,
    }
    fireEvent(DCS_Sync.Events.onShopConfigUpdated, DCS_Sync.State.shopConfig)
end

local function handleSyncObjects(args)
    DCS_Sync.State.npcRegistry = {}
    npcFlagsApplied = {}
    local npcs = args.npcs or {}
    local liveBids = {}
    for _, npc in ipairs(npcs) do
        if npc.bodyInstanceID and npc.challengeId then
            local bidStr = tostring(npc.bodyInstanceID)
            liveBids[bidStr] = true
            DCS_Sync.State.npcRegistry[bidStr] = npc.challengeId
            local data = {
                isFemale = npc.isFemale or false,
                npcName = npc.npcName or "NPC",
                outfit = npc.outfit or "Base.Boilersuit",
                traderOutfit = npc.traderOutfit,
                tint = npc.tint or { r = 1.0, g = 1.0, b = 1.0 },
                skinTexture = npc.skinTexture or "MaleBody01",
                hairModel = npc.hairModel or "Short",
                hairColor = npc.hairColor or { r = 0.25, g = 0.15, b = 0.08 },
                beardModel = npc.beardModel,
                beardColor = npc.beardColor,
                x = npc.x, y = npc.y, z = npc.z or 0,
            }
            if npcVisualCache[bidStr] then
                npcVisualCache[bidStr] = data
            else
                npcVisualPending[bidStr] = data
            end
            if npc.x and npc.y then
                DCS_Sync.State.npcSpawnPos[bidStr] = { x = npc.x, y = npc.y, z = npc.z or 0 }
            end
        end
    end
    for bidStr in pairs(npcVisualCache) do
        if not liveBids[bidStr] then npcVisualCache[bidStr] = nil; npcDressedPid[bidStr] = nil end
    end
    for bidStr in pairs(npcVisualPending) do
        if not liveBids[bidStr] then npcVisualPending[bidStr] = nil end
    end
    DCS_dprint("[DCS] syncObjects: registered " .. #npcs .. " NPC(s)")
    for _, npc in ipairs(npcs) do
        DCS_dprint("[DCS]   bodyInstanceID=" .. tostring(npc.bodyInstanceID)
            .. " challengeId=" .. tostring(npc.challengeId)
            .. " pos=" .. tostring(npc.x) .. "," .. tostring(npc.y))
    end
    if args.traderLocations then
        DCS_dprint("[DCS] syncObjects: received traderLocations array, count=" .. #args.traderLocations)
        if #args.traderLocations > 0 then
            local tl = DCS_Sync.State.traderLocations
            for _, entry in ipairs(args.traderLocations) do
                DCS_dprint("[DCS] syncObjects: traderLocation entry side=" .. tostring(entry.side) .. " name=" .. tostring(entry.name))
                if entry.side then tl[entry.side] = entry end
            end
            DCS_dprint("[DCS] syncObjects: traderLocations east="
                .. tostring(tl.east and tl.east.name or "nil")
                .. " west=" .. tostring(tl.west and tl.west.name or "nil"))
        else
            print("[DCS] syncObjects: traderLocations array is empty")
        end
    else
        DCS_dprint("[DCS] syncObjects: no traderLocations in payload")
    end
end

local function handleSyncNPCVisuals(args)
    if args and args.bodyInstanceID then
        local bidStr = tostring(args.bodyInstanceID)
        DCS_Sync.State.npcRegistry[bidStr] = args.challengeId or ""
        npcVisualPending[bidStr] = {
            isFemale = args.isFemale or false,
            npcName = args.npcName or "NPC",
            outfit = args.outfit or "Base.Boilersuit",
            traderOutfit = args.traderOutfit,
            tint = args.tint or { r = 1.0, g = 1.0, b = 1.0 },
            heading = args.heading or "S",
            locName = args.locName or "",
            skinTexture = args.skinTexture or "MaleBody01",
            hairModel = args.hairModel or "Short",
            hairColor = args.hairColor or { r = 0.25, g = 0.15, b = 0.08 },
            beardModel = args.beardModel,
            beardColor = args.beardColor,
            x = args.x, y = args.y, z = args.z or 0,
        }
        if args.x and args.y then
            DCS_Sync.State.npcSpawnPos[bidStr] = {
                x = args.x,
                y = args.y,
                z = args.z or 0,
            }
        end
        DCS_dprint("[DCS] syncNPCVisuals: queued for bodyID=" .. bidStr
            .. " challengeId=" .. tostring(args.challengeId)
            .. " npcName=" .. tostring(args.npcName))
    end
end

local function handleHaloText(args)
    local msg = args and args.text or ""
    local isProgress = args and args.count and args.total
    local isRoomTest = args and args.roomTest
    local isDiagnostic = args and args.diagnostic
    if isProgress then
        msg = getText("IGUI_DCS_Panel_HeaderProgress", args.count, args.total)
    end
    local player = getPlayer and getPlayer() or nil
    if player and msg ~= "" then
        if (isProgress or isRoomTest or isDiagnostic) and player.setHaloNote then
            player:setHaloNote(msg, 242, 191, 51, 384)
        elseif HaloTextHelper and HaloTextHelper.addText then
            HaloTextHelper.addText(player, msg)
        else
            player:Say(msg)
        end
        if not (args and args.noSound) then
            local snd = DCS_Challenges and DCS_Challenges.Sounds and DCS_Challenges.Sounds.challengeComplete
            if snd then
                DCS_Sync.playSound(snd)
            end
        end
    end
end

local function handlePlaySound(args)
    local snd = args and args.sound
    if snd then
        DCS_Sync.playSound(snd)
    end
end

local function handleDcsBackupResult(args)
    local msg = args and args.message or getText("IGUI_DCS_ClientSync_Toast_BackupComplete")
    local toastType = (args and args.success) and "new" or "debug"
    DCS_Sync.showToast(msg, toastType)
end

local function handleDcsRestoreResult(args)
    local msg = args and args.message or getText("IGUI_DCS_ClientSync_Toast_RestoreComplete")
    local toastType = (args and args.success) and "complete" or "debug"
    DCS_Sync.showToast(msg, toastType)
    if args and args.success and DCS_UserReset then
        DCS_UserReset.cachedPlayers = nil
        if DCS_UserReset.instance and DCS_UserReset.instance.requestAndBuild then
            DCS_UserReset.instance:requestAndBuild()
        end
    end
end

local function handleBackupList(args)
    local backups = args and args.backups or {}
    DCS_dprint("[DCS] backupList: Received " .. #backups .. " backups from server")
    if DCS_BackupPicker and DCS_BackupPicker.onBackupList then
        DCS_BackupPicker.onBackupList(backups)
    else
        print("[DCS] backupList: DCS_BackupPicker or onBackupList not available")
    end
end

local function handlePlayersData(args)
    if DCS_UserReset and args and args.players then
        DCS_UserReset.cachedPlayers = args.players
        if DCS_UserReset.instance then
            DCS_UserReset.instance:buildPlayerList()
        end
    end
end

local function handleRoomTestTiles(args)
    if DCS_RoomTestViz then DCS_RoomTestViz.show(args) end
end

local COMMAND_HANDLERS = {
    syncChallenges = handleSyncChallenges,
    syncProgress = handleSyncProgress,
    currencyAwarded = handleCurrencyAwarded,
    toggleDefaultItemsResult = handleToggleDefaultItemsResult,
    dailyReset = handleDailyReset,
    leaderboardUpdate = handleLeaderboardUpdate,
    adminResponse = handleAdminResponse,
    purchaseResult = handlePurchaseResult,
    shopStockSync = handleShopStockSync,
    shopStockUpdate = handleShopStockUpdate,
    shopConfigSync = handleShopConfigSync,
    shopConfigUpdate = handleShopConfigUpdate,
    syncObjects = handleSyncObjects,
    syncNPCVisuals = handleSyncNPCVisuals,
    haloText = handleHaloText,
    playSound = handlePlaySound,
    dcsBackupResult = handleDcsBackupResult,
    dcsRestoreResult = handleDcsRestoreResult,
    backupList = handleBackupList,
    playersData = handlePlayersData,
    roomTestTiles = handleRoomTestTiles,
}

local function onServerCommand(module, command, args)
    if module ~= "DailyChallengeSystem" then return end
    args = args or {}
    local handler = COMMAND_HANDLERS[command]
    if handler then handler(args) end
end

Events.OnServerCommand.Add(onServerCommand)

DCS_RoomTestViz = DCS_RoomTestViz or {}
local RTV = DCS_RoomTestViz
RTV.active = {}
RTV.expiry = 0
RTV.DURATION_MS = 20000
RTV._ticking = false

local function rtvHi(x, y, z, r, g, b, a)
    local cell = getCell and getCell()
    local sq = cell and cell:getGridSquare(x, y, z) or nil
    if not sq then return end
    local floor = sq:getFloor()
    if not floor then return end
    floor:setHighlighted(true, false)
    floor:setHighlightColor(r, g, b, a)
    RTV.active[#RTV.active + 1] = floor
end

function RTV.clear()
    for _, floor in ipairs(RTV.active) do
        floor:setHighlighted(false)
    end
    RTV.active = {}
    if RTV._ticking then
        Events.OnTick.Remove(RTV._onTick)
        RTV._ticking = false
    end
end

RTV._onTick = function()
    if getTimestampMs() >= RTV.expiry then RTV.clear() end
end

local function rtvPaint(bucket, z, r, g, b)
    if not bucket or not bucket.x then return 0 end
    local n = #bucket.x
    for i = 1, n do rtvHi(bucket.x[i], bucket.y[i], z, r, g, b, 0.6) end
    return n
end

function RTV.show(args)
    if not args or not args.cols then return end
    RTV.clear()
    local z = args.z or 0
    local c = args.cols
    local g0 = rtvPaint(c.green, z, 0.0, 1.0, 0.0)
    local y1 = rtvPaint(c.yellow, z, 1.0, 1.0, 0.0)
    local r2 = rtvPaint(c.red, z, 1.0, 0.0, 0.0)
    local m3 = rtvPaint(c.magenta, z, 1.0, 0.0, 1.0)
    local ob = rtvPaint(c.out, z, 0.1, 0.4, 1.0)
    RTV.expiry = getTimestampMs() + RTV.DURATION_MS
    if not RTV._ticking then
        Events.OnTick.Add(RTV._onTick)
        RTV._ticking = true
    end
    DCS_dprint("[DCS] RoomTestViz: d0=" .. g0 .. " d1=" .. y1 .. " d2=" .. r2
        .. " d3+=" .. m3 .. " out=" .. ob
        .. " (clears in " .. (RTV.DURATION_MS / 1000) .. "s)")
end

local S = DCS_UI_Scale.s
local TOAST_W = S(550)
local TOAST_H = S(150)
local TOAST_LIFETIME = 80
local TOAST_FADE_IN = 20
local TOAST_FADE_OUT = 20
local TOAST_TEXT_MAX = TOAST_W - S(30) - S(100) - S(12) - S(30)
local ICON_SIZE = S(100)
local ICON_X = S(30)
local ICON_PAD = S(12)

local toast_bg = getTexture("media/textures/dcs_toast_bg.png")
local toast_icons = {
    debug = getTexture("media/textures/dcs_toast_debug.png"),
    complete = getTexture("media/textures/dcs_toast_complete.png"),
    new = getTexture("media/textures/dcs_toast_new.png"),
    reward = getTexture("media/textures/dcs_toast_reward.png"),
}

local function wrapText(text, font, maxWidth)
    local result = {}
    local tmgr = getTextManager()

    for segment in string.gmatch(text, "[^\n]+") do
        local current = nil
        for word in string.gmatch(segment, "%S+") do
            local candidate = current and (current .. " " .. word) or word
            if tmgr:MeasureStringX(font, candidate) <= maxWidth then
                current = candidate
            else
                if current then
                    result[#result + 1] = current
                    current = nil
                end
                if tmgr:MeasureStringX(font, word) <= maxWidth then
                    current = word
                else
                    local chunk = ""
                    for i = 1, #word do
                        local ch = word:sub(i, i)
                        if tmgr:MeasureStringX(font, chunk .. ch) <= maxWidth then
                            chunk = chunk .. ch
                        else
                            if chunk ~= "" then result[#result + 1] = chunk end
                            chunk = ch
                        end
                    end
                    if chunk ~= "" then current = chunk end
                end
            end
        end
        if current then result[#result + 1] = current end
    end

    return #result > 0 and result or { text }
end

local TOAST_COLORS = {
    debug = { r = 1.0, g = 1.0, b = 1.0 },
    complete = { r = 1.0, g = 1.0, b = 1.0 },
    new = { r = 1.0, g = 1.0, b = 1.0 },
    reward = { r = 1.0, g = 1.0, b = 1.0 },
}

local toastQueue = {}
local toastShowing = false

DCS_Toast = ISPanel:derive("DCS_Toast")

function DCS_Toast:new(message, toastType, font)
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local x = screenW - TOAST_W - S(20)
    local y = screenH - TOAST_H - S(400)
    local o = ISPanel.new(self, x, y, TOAST_W, TOAST_H)
    o.message = message or ""
    o.toastType = toastType or "debug"
    o.font = font or UIFont.Medium
    o.ticks = 0
    o.alpha = 0
    return o
end

function DCS_Toast:initialise()
    ISPanel.initialise(self)
    self:setCapture(false)
end

local function spawnToast(message, toastType, font)
    toastShowing = true
    local toast = DCS_Toast:new(message, toastType, font)
    toast:initialise()
    toast:instantiate()
    toast:addToUIManager()
end

function DCS_Toast:update()
    ISPanel.update(self)
    self.ticks = self.ticks + 1

    if self.ticks <= TOAST_FADE_IN then
        local t = self.ticks / TOAST_FADE_IN
        self.alpha = t * t * t * (t * (t * 6 - 15) + 10)
    elseif self.ticks <= (TOAST_LIFETIME - TOAST_FADE_OUT) then
        self.alpha = 1.0
    elseif self.ticks <= TOAST_LIFETIME then
        local t = (TOAST_LIFETIME - self.ticks) / TOAST_FADE_OUT
        self.alpha = t * t * t * (t * (t * 6 - 15) + 10)
    else
        self:removeFromUIManager()
        toastShowing = false
        if #toastQueue > 0 then
            local nextToast = table.remove(toastQueue, 1)
            spawnToast(nextToast.message, nextToast.toastType, nextToast.font)
        end
    end
end

function DCS_Toast:prerender()
    local col = TOAST_COLORS[self.toastType] or TOAST_COLORS.debug
    local a = self.alpha

    if toast_bg then
        self:drawTextureScaled(toast_bg, 0, 0, self.width, self.height, a)
    end

    local icon = toast_icons[self.toastType]
    if icon then
        local iconY = (self.height - ICON_SIZE) / 2 - S(3)
        self:drawTextureScaled(icon, ICON_X, iconY, ICON_SIZE, ICON_SIZE, a)
    end

    local textX = ICON_X + ICON_SIZE + ICON_PAD
    local lines = wrapText(self.message, self.font, TOAST_TEXT_MAX)
    if #lines > 4 then
        local truncated = {}
        for i = 1, 4 do
            truncated[i] = lines[i]
        end
        truncated[4] = truncated[4] .. "..."
        lines = truncated
    end
    local fontH = getTextManager():getFontHeight(self.font)
    local totalTextH = #lines * fontH
    local textY = (self.height - totalTextH) / 2

    for i, line in ipairs(lines) do
        self:drawText(line, textX, textY + (i - 1) * fontH, col.r, col.g, col.b, a, self.font)
    end
end

function DCS_Sync.showToast(message, toastType, font)
    if not localPlayer then return end
    if toastShowing then
        toastQueue[#toastQueue + 1] = { message = message, toastType = toastType, font = font }
        return
    end
    spawnToast(message, toastType, font)
end

function DCS_Sync.requestPurchase(itemId, cost, quantity)
    if not localPlayer then return end
    quantity = quantity or 1
    sendClientCommand(localPlayer, "DailyChallengeSystem", "purchaseItem", {
        itemId = itemId,
        cost = cost,
        quantity = quantity,
    })
end

local dcsOptions = nil

local function initModOptions()
    dcsOptions = PZAPI.ModOptions:create("DailyChallengeSystem", "Daily Challenge System")
    dcsOptions:addKeyBind("panelKey", "Toggle Challenge Panel", 0,
        "Opens or closes the Daily Challenge panel. No default keybind set.")
    dcsOptions:addTickBox("soundEnabled", "Enable sounds", true,
        "Play Daily Challenge sounds (daily reset, challenge complete, streak reward). Untick to mute all DCS sounds.")
end

function DCS_Sync.getPanelKey()
    if not dcsOptions then return nil end
    local opt = dcsOptions:getOption("panelKey")
    return opt and opt:getValue() or nil
end

function DCS_Sync.soundsEnabled()
    if not dcsOptions then return true end
    local opt = dcsOptions:getOption("soundEnabled")
    if not opt then return true end
    return opt:getValue() ~= false
end

function DCS_Sync.playSound(snd, vol)
    if not snd then return end
    if not DCS_Sync.soundsEnabled() then return end
    getSoundManager():PlaySound(snd, false, vol or 0.5)
end

local function onCreatePlayer(playerIndex, player)
    DCS_dprint("[DCS] onCreatePlayer fired: playerIndex=" .. tostring(playerIndex) .. " player=" .. tostring(player))
    if playerIndex ~= 0 then return end
    localPlayer = player
    loginTime = os.time()

    local ticksWaited = 0
    local function deferredSync()
        ticksWaited = ticksWaited + 1
        if ticksWaited >= 10 then
            Events.OnTick.Remove(deferredSync)
            if localPlayer then
                DCS_dprint("[DCS] onCreatePlayer: sending requestSync for player=" .. tostring(localPlayer:getUsername()))
                sendClientCommand(localPlayer, "DailyChallengeSystem", "requestSync", {})
                DCS_dprint("[DCS] onCreatePlayer: requestSync sent")
            end
        end
    end
    Events.OnTick.Add(deferredSync)
end

local function onKeyPressed(key)
    local bindKey = DCS_Sync.getPanelKey()
    if not bindKey then return end
    if key ~= bindKey then return end

    if DCS_UI_Panel then
        DCS_UI_Panel.toggle()
    end
end

local lastKillUpdateTick = 0
local loginTime = os.time()

local function onClientWeaponHitCharacter(attacker, target, weapon, damage)
    if not attacker or not target then return end
    if not (instanceof and instanceof(attacker, "IsoPlayer")) then return end
    if not (instanceof and instanceof(target, "IsoZombie")) then return end

    do
        local md = target:getModData()
        if md and md.IsDCSNPC then return end
    end

    if weapon and weapon.isBareHands and weapon:isBareHands() then
        weaponHitCache[target] = nil
        return
    end

    local weaponType = nil
    local weaponCategory = nil
    local primaryItem = attacker:getPrimaryHandItem()
    if primaryItem and primaryItem.getType then
        weaponType = DCS_WeaponLookup.resolveWeaponType(primaryItem:getType())
        weaponCategory = DCS_WeaponLookup.resolveWeaponCategory(primaryItem)
    elseif weapon and weapon.getType then
        weaponType = DCS_WeaponLookup.resolveWeaponType(weapon:getType())
        weaponCategory = DCS_WeaponLookup.resolveWeaponCategory(weapon)
    end
    weaponHitCache[target] = { attacker = attacker, weaponType = weaponType, weaponCategory = weaponCategory }
end

Events.OnWeaponHitCharacter.Add(onClientWeaponHitCharacter)

local function onClientNPCHit(attacker, target, weapon, damage)
    if not target then return end
    if not (instanceof and instanceof(target, "IsoZombie")) then return end

    local isNPC = false
    local md = target:getModData()
    if md and md.IsDCSNPC then
        isNPC = true
    end

    if not isNPC then
        local bid = tostring(target:getPersistentOutfitID())
        if bid and DCS_Sync and DCS_Sync.State and DCS_Sync.State.npcRegistry
           and DCS_Sync.State.npcRegistry[bid] then
            isNPC = true
        end
    end

    if not isNPC then return end
    if target:isDead() then return end

    target:changeState(ZombieIdleState.instance())
    target:setHealth(1000)
    target:setOnlyJawStab(true)
    target:setIgnoreStaggerBack(true)
    local poseVar = "0"
    local hitNPCName = nil
    local md3 = target:getModData()
    if md3 and md3.DCSNPC_Name then
        hitNPCName = md3.DCSNPC_Name
    else
        local bid3 = tostring(target:getPersistentOutfitID())
        if bid3 and DCS_Sync and DCS_Sync.State and DCS_Sync.State.npcRegistry then
            local chId3 = DCS_Sync.State.npcRegistry[bid3]
            if chId3 then
                local ch3 = DCS_Challenges.Lookup and DCS_Challenges.Lookup[chId3]
                if ch3 then hitNPCName = ch3.npcName end
            end
        end
    end
    local hitNPCDef = hitNPCName and lookupNPCDefByName(hitNPCName) or lookupNPCDef(target)
    if hitNPCDef then poseVar = computeNPCIdlePose(hitNPCDef) end
    target:setVariable("DCSNPC", true)
    target:setVariable("bMoving", false)
    target:setVariable("isMoving", false)
    target:setVariable("DCSNPCIdleState", poseVar)
    target:setCloseKilled(false)
    target:setKnifeDeath(false)
    target:setJawStabAttach(false)
    target:setHitTime(0)
    target:setSolid(true)
    target:setStaggerBack(false)
    target:setHitReaction("")
    target:setOnFloor(false)
    target:setCrawler(false)
    do
        local px, py = nil, nil
        local players = getOnlinePlayers and getOnlinePlayers() or nil
        if players then
            local bestDist = 9999
            for pi = 0, players:size() - 1 do
                local p = players:get(pi)
                if p and not p:isDead() then
                    local dx = target:getX() - p:getX()
                    local dy = target:getY() - p:getY()
                    local dist = dx * dx + dy * dy
                    if dist < bestDist then
                        bestDist = dist
                        px, py = p:getX(), p:getY()
                    end
                end
            end
        end
        if px and py then
            target:faceLocation(px, py)
        end
    end
    do
        local vis = target:getHumanVisual()
        if vis then
            vis:removeBlood()
            vis:removeDirt()
        end
    end
    target:clearAttachedItems()
    target:setVariable("bBecomeCrawler", false)
    target:setVariable("bCrawling", false)
    target:setVariable("FallOnFront", false)
    target:setUseless(false)
    target:setWalkType("Walk")
    target:setAnimatingBackwards(false)
    target:setUseless(true)
    do
        local vis = target:getHumanVisual()
        if vis then
            vis:removeBlood()
            vis:removeDirt()
            if vis.getBodyVisuals then
                local bvs = vis:getBodyVisuals()
                if bvs and bvs:size() > 0 then
                    local toRemove = {}
                    for i = 0, bvs:size() - 1 do
                        local bodyVisual = bvs:get(i)
                        if bodyVisual and bodyVisual.getType then
                            toRemove[#toRemove + 1] = bodyVisual:getType()
                        end
                    end
                    for i = 1, #toRemove do
                        vis:removeBodyVisualFromItemType(toRemove[i])
                    end
                end
            end
        end
    end
    do
        local iVis = target:getItemVisuals()
        if iVis then
            local hasBoiler = false
            for j = 0, iVis:size() - 1 do
                local item = iVis:get(j)
                if item and item.getType and item:getType() then
                    local itemType = item:getType()
                    if itemType and itemType:find("Boilersuit") then hasBoiler = true; break end
                end
            end
            if not hasBoiler then
                local hitNPCName2 = nil
                local md4 = target:getModData()
                if md4 and md4.DCSNPC_Name then
                    hitNPCName2 = md4.DCSNPC_Name
                else
                    local bid4 = tostring(target:getPersistentOutfitID())
                    if bid4 and DCS_Sync and DCS_Sync.State and DCS_Sync.State.npcRegistry then
                        local chId4 = DCS_Sync.State.npcRegistry[bid4]
                        if chId4 then
                            local isTrader = (type(chId4) == "string" and string.sub(chId4, 1, 7) == "trader_")
                            if not isTrader then
                                local ch4 = DCS_Challenges.Lookup and DCS_Challenges.Lookup[chId4]
                                if ch4 then hitNPCName2 = ch4.npcName end
                            end
                        end
                    end
                end
                if hitNPCName2 then
                    local hitDef2 = lookupNPCDefByName(hitNPCName2) or lookupNPCDef(target)
                    local traderOutfit = hitDef2 and hitDef2.traderOutfit
                    if traderOutfit and #traderOutfit > 0 then
                        for _, itemType in ipairs(traderOutfit) do
                            local iv = ItemVisual.new()
                            iv:setItemType(itemType)
                            iv:setClothingItemName(itemType)
                            iVis:add(iv)
                        end
                    else
                        local outfitItem = (hitDef2 and hitDef2.outfit) or "Base.Boilersuit"
                        local iv = ItemVisual.new()
                        iv:setItemType(outfitItem)
                        iv:setClothingItemName(outfitItem)
                        iVis:add(iv)
                        if ImmutableColor then
                            local tint = (hitDef2 and hitDef2.tint) or { r = 1.0, g = 1.0, b = 1.0 }
                            iv:setTint(ImmutableColor.new(tint.r, tint.g, tint.b, 1.0))
                        end
                        local shoes = ItemVisual.new()
                        shoes:setItemType("Base.Shoes_ArmyBoots")
                        shoes:setClothingItemName("Base.Shoes_ArmyBoots")
                        iVis:add(shoes)
                    end
                end
            end
        end
    end
end

Events.OnWeaponHitCharacter.Add(onClientNPCHit)

local function onClientZombieDead(zombie)
    if not zombie then return end

    local md = zombie:getModData()
    if md and md.IsDCSNPC then
        weaponHitCache[zombie] = nil
        return
    end

    local cached = weaponHitCache[zombie]
    weaponHitCache[zombie] = nil

    if cached then
        sessionCountedKills = sessionCountedKills + 1
    end

    if not cached or not cached.weaponType then return end

    local today = os.date("!%Y%m%d")
    if lastWeaponDay ~= today then
        dailyKillsByWeapon = {}
        dailyKillsByCategory = {}
        lastWeaponDay = today
    end

    local wType = cached.weaponType
    dailyKillsByWeapon[wType] = (dailyKillsByWeapon[wType] or 0) + 1
    DCS_dprint("[DCS] Client weapon kill: " .. wType .. " count=" .. dailyKillsByWeapon[wType])

    local wCat = cached.weaponCategory
    if wCat then
        dailyKillsByCategory[wCat] = (dailyKillsByCategory[wCat] or 0) + 1
        DCS_dprint("[DCS] Client category kill: " .. wCat .. " count=" .. dailyKillsByCategory[wCat])
    end

    if not isServer() then
        pendingWeaponKillTypes[wType] = true
        hasPendingWeaponKill = true
        if wCat then pendingWeaponCategoryKills[wCat] = true end
    end
end

Events.OnZombieDead.Add(onClientZombieDead)

local function onTick()
    if not localPlayer then return end
    lastKillUpdateTick = lastKillUpdateTick + 1
    if lastKillUpdateTick < 60 then return end
    lastKillUpdateTick = 0

    local totalKills = sessionCountedKills
    local sessionDelta = totalKills - lastZombieKillCount
    if sessionDelta > 0 then
        DCS_Sync.State.dailyKills = (DCS_Sync.State.dailyKills or 0) + sessionDelta
        lastZombieKillCount = totalKills
    end

    local now = os.time()
    if hasPendingWeaponKill and (now - lastWeaponKillFlush) >= 3 then
        lastWeaponKillFlush = now
        hasPendingWeaponKill = false
        local types, cats = {}, {}
        for t in pairs(pendingWeaponKillTypes) do types[#types + 1] = t end
        for c in pairs(pendingWeaponCategoryKills) do cats[#cats + 1] = c end
        pendingWeaponKillTypes = {}
        pendingWeaponCategoryKills = {}
        if not isServer() then
            sendClientCommand(localPlayer, "DailyChallengeSystem", "reportWeaponKill", {
                weaponTypes = types,
                weaponCategories = cats,
                day = os.date("!%Y%m%d"),
            })
        end
    end
end

Events.OnTick.Add(onTick)

local function onEveryOneMinute()
    if not localPlayer then return end

    if not DCS_UI_Panel.everOpenedThisSession and not DCS_UI_Panel.isWiggling then
        if (os.time() - loginTime) >= 120 then
            DCS_UI_Panel.triggerWiggle()
        end
    end

    local today = os.date("!%Y%m%d")

    local totalKills = sessionCountedKills
    local newKills = totalKills - lastZombieKillCount
    lastZombieKillCount = totalKills

    if newKills > 0 then
        if isServer() and not DCS_SERVER_STARTED then
            DCS_dprint("[DCS] Client sending reportKills: kills=" .. newKills .. " total=" .. totalKills .. " day=" .. today)
            sendClientCommand(localPlayer, "DailyChallengeSystem", "reportKills", {
                kills = newKills,
                day = today,
                weaponKills = dailyKillsByWeapon,
                weaponCategories = dailyKillsByCategory,
            })
        end
        dailyKillsByWeapon = {}
        dailyKillsByCategory = {}
    end

end

local npcZombiesReusable = {}
local npcBidReusable = {}
local faceLocationCounter = 0
local NPC_VISUAL_THROTTLE = 5
local function onTickNPCVisualFix()
    if not (DCS_Config and DCS_Config.USE_NPC) then return end
    npcVisualTickCounter = npcVisualTickCounter + 1
    faceLocationCounter = faceLocationCounter + 1

    if not DCS_Sync or not DCS_Sync.State or not DCS_Sync.State.npcRegistry then return end

    if npcVisualTickCounter < NPC_VISUAL_THROTTLE then return end
    npcVisualTickCounter = 0

    local cell = getCell and getCell() or nil
    if not cell then return end
    local zombieList = cell:getZombieList()
    if not zombieList then return end

    local toRemove = {}
    for bidStr, data in pairs(npcVisualPending) do
        local applied = applyNPCVisualsToClient(bidStr, data)
        if applied then toRemove[#toRemove + 1] = bidStr end
    end
    for _, bidStr in ipairs(toRemove) do
        npcVisualPending[bidStr] = nil
    end

    local npcCount = 0
    local seen = {}
    for bidStr, entry in pairs(npcVisualCache) do
        if entry.x and entry.y then
            local z = findNPCZombieNear(zombieList, entry.x, entry.y)
            if z then
                local zk = tostring(z:getPersistentOutfitID())
                if zk and not seen[zk] then
                    seen[zk] = true
                    npcCount = npcCount + 1
                    npcZombiesReusable[npcCount] = z
                    npcBidReusable[npcCount] = bidStr
                end
            end
        end
    end

    for idx = 1, npcCount do
        local z = npcZombiesReusable[idx]
        local bidStr = npcBidReusable[idx]
        npcZombiesReusable[idx] = nil
        npcBidReusable[idx] = nil

        local zombieKey = tostring(z:getPersistentOutfitID())

        if bidStr and zombieKey and npcDressedPid[bidStr] ~= zombieKey then
            local data = npcVisualCache[bidStr]
            if data then
                dressNPCZombie(z, data)
                npcDressedPid[bidStr] = zombieKey
            end
        end

        if zombieKey and not npcFlagsApplied[zombieKey] then
            z:setOnlyJawStab(true)
            z:setIgnoreStaggerBack(true)
            z:setCloseKilled(false)
            z:setKnifeDeath(false)
            z:setJawStabAttach(false)
            z:setHitTime(0)
            z:setSolid(true)
            z:setKnockedDown(false)
            z:setStaggerBack(false)
            z:setHitReaction("")
            z:setOnFloor(false)
            z:setCrawler(false)
            z:setVariable("bBecomeCrawler", false)
            z:setVariable("bCrawling", false)
            z:setVariable("FallOnFront", false)
            if not z:isUseless() then
                z:setUseless(false)
                z:setWalkType("Walk")
                z:setAnimatingBackwards(false)
                z:setUseless(true)
            end
            z:setVariable("DCSNPC", true)
            z:setVariable("bMoving", false)
            z:setVariable("isMoving", false)
            npcFlagsApplied[zombieKey] = true
        else
            z:setOnlyJawStab(true)
            z:setIgnoreStaggerBack(true)
            z:setCrawler(false)
            z:setOnFloor(false)
            z:setKnockedDown(false)
            z:setStaggerBack(false)
            z:setHitReaction("")
            z:setVariable("bBecomeCrawler", false)
            z:setVariable("bCrawling", false)
            z:setVariable("FallOnFront", false)
            z:setVariable("DCSNPC", true)
            z:setVariable("bMoving", false)
            z:setVariable("isMoving", false)
        end

        do
            local vis = z:getHumanVisual()
            if vis then
                vis:removeBlood()
                vis:removeDirt()
                if vis.getBodyVisuals then
                    local bvs = vis:getBodyVisuals()
                    if bvs and bvs:size() > 0 then
                        local typesToRemove = {}
                        for vi = 0, bvs:size() - 1 do
                            local bv = bvs:get(vi)
                            if bv and bv.getType then
                                typesToRemove[#typesToRemove + 1] = bv:getType()
                            end
                        end
                        for _, t in ipairs(typesToRemove) do
                            vis:removeBodyVisualFromItemType(t)
                        end
                    end
                end
            end
        end

        do
            local cached = cacheEntryForZombie(z)
            if cached then
                local vis = z:getHumanVisual()
                if vis then
                    vis:setSkinTextureName(cached.skinTexture)
                    vis:setHairModel(cached.hairModel)
                    if ImmutableColor then
                        local hc = cached.hairColor or { r = 0.25, g = 0.15, b = 0.08 }
                        vis:setHairColor(ImmutableColor.new(hc.r, hc.g, hc.b, 1))
                        if cached.beardModel then
                            vis:setBeardModel(cached.beardModel)
                            local bc = cached.beardColor or hc
                            vis:setBeardColor(ImmutableColor.new(bc.r, bc.g, bc.b, 1))
                        end
                    end
                end
            end
        end

        do
            local poseVar = "0"
            local md2 = z:getModData()
            if md2 and md2.DCSNPCIdlePose then
                poseVar = md2.DCSNPCIdlePose
            else
                local npcName = nil
                if md2 and md2.DCSNPC_Name then
                    npcName = md2.DCSNPC_Name
                else
                    local cached = cacheEntryForZombie(z)
                    if cached then npcName = cached.npcName end
                end
                local npcDef = npcName and lookupNPCDefByName(npcName) or lookupNPCDef(z)
                if npcDef then poseVar = computeNPCIdlePose(npcDef) end
                if md2 then md2.DCSNPCIdlePose = poseVar end
            end
            z:setVariable("DCSNPCIdleState", poseVar)
        end

        if faceLocationCounter >= 30 then
            local px, py = nil, nil
            local players = getOnlinePlayers and getOnlinePlayers() or nil
            if players then
                local bestDist = 9999
                for pi = 0, players:size() - 1 do
                    local p = players:get(pi)
                    if p and not p:isDead() then
                        local dx, dy = z:getX() - p:getX(), z:getY() - p:getY()
                        local dist = dx * dx + dy * dy
                        if dist < bestDist then bestDist = dist; px, py = p:getX(), p:getY() end
                    end
                end
            end
            if px and py then z:faceLocation(px, py) end
        end

        do
            local sp = cacheEntryForZombie(z)
            if sp and sp.x and sp.y then
                local dx, dy = z:getX() - sp.x, z:getY() - sp.y
                if dx * dx + dy * dy > 1.0 then z:setX(sp.x); z:setY(sp.y); z:setZ(sp.z or 0) end
            end
        end
    end

    if faceLocationCounter >= 30 then faceLocationCounter = 0 end
end

if DCS_Config and DCS_Config.USE_NPC then
    Events.OnTick.Add(onTickNPCVisualFix)
end
Events.OnCreatePlayer.Add(onCreatePlayer)
Events.OnKeyPressed.Add(onKeyPressed)
Events.EveryOneMinute.Add(onEveryOneMinute)

Events.OnCreateUI.Add(initModOptions)

if forageSystem and forageSystem.actionComplete then
    local origActionComplete = forageSystem.actionComplete
    function forageSystem.actionComplete(_character, _iconID)
        local itemType = nil
        local count = 1
        local itemCategories = nil
        local manager = ISSearchManager and ISSearchManager.getManager and ISSearchManager.getManager(_character)
        if manager and manager.forageIcons then
            local icon = manager.forageIcons[_iconID]
            if icon then
                itemType = icon.itemType
                if icon.itemList then
                    count = icon.itemList:size()
                end
                if icon.itemDef and icon.itemDef.categories then
                    itemCategories = icon.itemDef.categories
                end
            end
        end

        origActionComplete(_character, _iconID)

        if not itemType then return end
        if not _character or not _character:isLocalPlayer() then return end

        local today = os.date("!%Y%m%d")
        for _, ch in ipairs(DCS_Sync.getTodayChallenges()) do
            if ch.type == "forage"
            and not DCS_Sync.isCompleted(ch.id) then
                local matched = false
                if ch.targetCategory and itemCategories then
                    for _, cat in ipairs(itemCategories) do
                        if cat == ch.targetCategory then
                            matched = true
                            break
                        end
                    end
                elseif ch.targetItem then
                    matched = (ch.targetItem == itemType)
                else
                    matched = true
                end
                if matched then
                    DCS_dprint("[DCS] Forage match: " .. ch.id .. " itemType=" .. itemType .. " count=" .. count)
                    sendClientCommand(_character, "DailyChallengeSystem", "reportChallengeProgress", {
                        challengeId = ch.id,
                        day = today,
                        amount = count,
                    })
                end
            end
        end
    end
    DCS_dprint("[DCS] forageSystem.actionComplete override registered")
else
    print("[DCS] WARNING: forageSystem.actionComplete not found")
end

if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.onUpgradeWeapon then
    local origOnUpgradeWeapon = ISInventoryPaneContextMenu.onUpgradeWeapon
    ISInventoryPaneContextMenu.onUpgradeWeapon = function(weapon, part, player)
        origOnUpgradeWeapon(weapon, part, player)

        if not player then return end
        if not player:isLocalPlayer() then return end
        if not part then return end

        local partType = part.getFullType and part:getFullType() or nil
        if not partType then return end

        local today = os.date("!%Y%m%d")
        DCS_dprint("[DCS] Weapon attach: part=" .. partType)

        for _, ch in ipairs(DCS_Sync.getTodayChallenges()) do
            if ch.type == "weaponAttach" and not DCS_Sync.isCompleted(ch.id) then
                if not ch.targetPart or ch.targetPart == partType then
                    DCS_dprint("[DCS] Weapon attach match: " .. ch.id .. " part=" .. partType)
                    sendClientCommand(player, "DailyChallengeSystem", "reportChallengeProgress", {
                        challengeId = ch.id, day = today, amount = 1,
                    })
                end
            end
        end
    end
    DCS_dprint("[DCS] Weapon attach tracking registered via context menu hook")
else
    print("[DCS] WARNING: ISInventoryPaneContextMenu.onUpgradeWeapon not found")
end

local reloadLastAmmo = {}

if ISReloadWeaponAction and ISReloadWeaponAction.update then
    local origReloadUpdate = ISReloadWeaponAction.update
    function ISReloadWeaponAction:update()
        origReloadUpdate(self)

        if not self.character or not self.character:isLocalPlayer() then return end
        if not self.gun then return end

        local gunId = self.gun.getID and self.gun:getID() or nil
        if not gunId then return end

        local currentAmmo = self.gun:getCurrentAmmoCount()
        local lastAmmo = reloadLastAmmo[gunId]

        if lastAmmo and currentAmmo > lastAmmo then
            local bulletsLoaded = currentAmmo - lastAmmo
            local today = os.date("!%Y%m%d")
            for _, ch in ipairs(DCS_Sync.getTodayChallenges()) do
                if ch.type == "weaponReload" and not DCS_Sync.isCompleted(ch.id) then
                    sendClientCommand(self.character, "DailyChallengeSystem", "reportChallengeProgress", {
                        challengeId = ch.id, day = today, amount = bulletsLoaded,
                    })
                end
            end
        end

        reloadLastAmmo[gunId] = currentAmmo
    end

    if ISReloadWeaponAction.start then
        local origReloadStart = ISReloadWeaponAction.start
        function ISReloadWeaponAction:start()
            origReloadStart(self)
            if self.gun then
                local gunId = self.gun.getID and self.gun:getID() or nil
                if gunId then
                    reloadLastAmmo[gunId] = self.gun:getCurrentAmmoCount()
                end
            end
        end
    end

    DCS_dprint("[DCS] Weapon reload tracking registered (update per-bullet)")
else
    print("[DCS] WARNING: ISReloadWeaponAction.update not found")
end

if ISLoadBulletsInMagazine and ISLoadBulletsInMagazine.perform then
    local origLoadMagPerform = ISLoadBulletsInMagazine.perform
    function ISLoadBulletsInMagazine:perform()
        local ammoBefore = 0
        if self.magazine and self.magazine.getCurrentAmmoCount then
            ammoBefore = self.magazine:getCurrentAmmoCount()
        end
        origLoadMagPerform(self)
        if not self.character or not self.character:isLocalPlayer() then return end
        local ammoAfter = 0
        if self.magazine and self.magazine.getCurrentAmmoCount then
            ammoAfter = self.magazine:getCurrentAmmoCount()
        end
        local bulletsLoaded = ammoAfter - ammoBefore
        if bulletsLoaded <= 0 then return end
        local today = os.date("!%Y%m%d")
        for _, ch in ipairs(DCS_Sync.getTodayChallenges()) do
            if ch.type == "weaponReload" and not DCS_Sync.isCompleted(ch.id) then
                sendClientCommand(self.character, "DailyChallengeSystem", "reportChallengeProgress", {
                    challengeId = ch.id, day = today, amount = bulletsLoaded,
                })
            end
        end
    end
    DCS_dprint("[DCS] Weapon reload tracking registered (magazine)")
else
    print("[DCS] WARNING: ISLoadBulletsInMagazine not found")
end

Events.OnDeadBodySpawn.Add(function(body)
    if not body then return end

    local isNPC = false
    local md = body:getModData()
    if md and md.IsDCSNPC then
        isNPC = true
    end

    if not isNPC and body.getPersistentOutfitID then
        local bid = tostring(body:getPersistentOutfitID())
        if bid and DCS_Sync and DCS_Sync.State and DCS_Sync.State.npcRegistry
           and DCS_Sync.State.npcRegistry[bid] then
            isNPC = true
        end
    end

    if isNPC then
        local sq = body:getSquare()
        if sq then
            sq:removeCorpse(body, false)
        end
    end
end)
