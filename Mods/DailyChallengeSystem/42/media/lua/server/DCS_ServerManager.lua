local dcsRandom = newrandom()

local DCS_Server = {}

local MOD_ID = "DailyChallengeSystem"

local function fmtTime(sec)
    if not sec or sec < 0 then return "0s" end
    sec = math.floor(sec + 0.5)
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = sec % 60
    local parts = {}
    if h > 0 then parts[#parts + 1] = h .. "hr" end
    if m > 0 then parts[#parts + 1] = m .. "m" end
    parts[#parts + 1] = s .. "s"
    return table.concat(parts, " ")
end

local function fmtClock(t)
    return os.date("!%H:%M:%S", t or os.time())
end
local SECONDS_A_DAY = 86400

local AUTHOR_STEAM_ID = "76561198704029390"
local function isModAuthor(player)
    local sid
    if DCS_Env.isSP() then
        sid = getCurrentUserSteamID()
    else
        if not player then return false end
        sid = player:getSteamID()
    end
    if sid == nil then return false end
    if tostring(sid) == AUTHOR_STEAM_ID then return true end
    local n = tonumber(sid)
    return n ~= nil and n == tonumber(AUTHOR_STEAM_ID)
end

local todaySeed = nil
local todayChallenges = {}
local lastCheckedDay = nil
local forcedDayOffset = 0
local lastRealDay = nil
local npcsSpawned = false
local tradersSpawned = false

local function getUTCDateString()
    return os.date("!%Y%m%d")
end

local function getResetIntervalSeconds()
    local h = DCS_Config and DCS_Config.RESET_INTERVAL_HOURS
    if type(h) ~= "number" or h <= 0 then h = 24 end
    return math.floor(h * 3600)
end

local function periodStringAt(periodOffset)
    local interval = getResetIntervalSeconds()
    local t = os.time() + (periodOffset * interval)
    if interval == 86400 then
        return os.date("!%Y%m%d", t)
    end
    return "P" .. tostring(math.floor(t / interval))
end

local function getEffectiveDateString()
    return periodStringAt(forcedDayOffset)
end

local function startSpeedrunTimer(pd)
    pd.challengeStartDay = getEffectiveDateString()
    pd.challengeStartTime = os.time()
    pd.speedrun1DoneToday = false
    pd.speedrun7DoneToday = false
end

local function lcgRand(seed, index)
    local a = 1664525
    local c = 1013904223
    local m = 2^32
    local state = seed
    for _ = 1, index do
        state = (a * state + c) % m
    end
    return state / m
end

local function dateSeed(dateStr)
    if not dateStr then return 20240101 end
    local n = tonumber(dateStr)
    if n then return n end
    local digits = tostring(dateStr):gsub("%D", "")
    return tonumber(digits) or 20240101
end

local function selectChallenges(seed)
    local picked = {}

    local visitNPC, questNPC = DCS_Challenges.pickDailyNPCs(seed)

    local traderTowns = DCS_Challenges.getActiveTraderTowns()

    local visitCh = DCS_Challenges.buildVisitChallenge(lcgRand(seed, 4 * 13), visitNPC and visitNPC.name, traderTowns)
    local questCh = DCS_Challenges.buildQuestChallenge(lcgRand(seed, 3 * 13), lcgRand(seed, 3 * 17), questNPC and questNPC.name, visitCh.town, traderTowns)

    DCS_Challenges.Lookup[visitCh.id] = visitCh
    DCS_Challenges.Lookup[questCh.id] = questCh

    local catCount = #DCS_Challenges.CategoryPools
    for catIndex = 1, catCount do
        local pool = DCS_Challenges.CategoryPools[catIndex]
        if catIndex == 2 then
            picked[#picked + 1] = questCh
        elseif catIndex == 3 then
            picked[#picked + 1] = visitCh
        elseif pool and #pool > 0 then
            local idx = 1 + math.floor(lcgRand(seed, catIndex * 13) * #pool)
            idx = math.max(1, math.min(idx, #pool))
            picked[#picked + 1] = pool[idx]
        else
            print("[DCS] WARNING: Category pool " .. catIndex .. " is empty — skipping")
        end
    end

    DCS_dprint("[DCS] selectChallenges: picked " .. #picked .. " of " .. catCount .. " categories")
    return picked
end

local function buildTodayChallenges()
    if not DCS_Challenges or not DCS_Challenges.Lookup or not DCS_Challenges.pickDailyNPCs then
        print("[DCS] ERROR: buildTodayChallenges called before DCS_ChallengeDefinitions loaded — aborting")
        return
    end
    local dateStr = getEffectiveDateString()
    todaySeed = dateStr
    lastCheckedDay = dateStr

    local seed = dateSeed(dateStr)

    if DCS_Challenges.buildTraderLocationPools then
        DCS_Challenges.buildTraderLocationPools(seed)
    end

    todayChallenges = selectChallenges(seed)

    DCS_dprint("[DCS] buildTodayChallenges: date=" .. dateStr .. " selected " .. tostring(#todayChallenges) .. " challenges")
    for i, ch in ipairs(todayChallenges) do
        DCS_dprint("[DCS]   " .. i .. ": " .. tostring(ch.id))
    end

    local gmd = ModData.getOrCreate("DCS_Global")
    gmd.todaySeed = todaySeed
    gmd.todayChallengeIDs = {}
    for i, ch in ipairs(todayChallenges) do
        gmd.todayChallengeIDs[i] = ch.id
    end
    gmd.activeTraderTowns = DCS_Challenges.getActiveTraderTowns()
    ModData.transmit("DCS_Global")
end

local function defaultPlayerData()
    return {
        currency = 0,
        streak = 0,
        streakLevel = 0,
        lifetimeCompleted = 0,
        lastCompletedDay = "",
        dailyCompleted = {},
        dailyKills = 0,
        killsResetDay = "",
        dailyKillsByWeapon = {},
        killsByWeaponResetDay = "",
        dailyKillsByCategory = {},
        killsByCategoryResetDay = "",
        bonusAwardedDay = "",
        dailyProgress = {},
        progressResetDay = "",
        challengeStartDay = "",
        challengeStartTime = 0,
        speedrun1DoneToday = false,
        speedrun7DoneToday = false,
        dataVersion = 0,
    }
end

local function getPlayerData(player)
    local md = player:getModData()

    if DCS_Env.isSP() then
        local wallet = ModData.getOrCreate("DCS_SP")
        if not wallet.tokens then wallet.tokens = 0 end
        if not wallet.history then wallet.history = {} end

        if not md.DCS or not md.DCS._id then
            md.DCS = md.DCS or {}
            md.DCS._id = tostring(os.time()) .. "_" .. tostring(dcsRandom:random(0, 99999))
        end
        local charId = md.DCS._id

        if wallet.carriedProgress then
            local cp = wallet.carriedProgress
            for k, v in pairs(cp) do
                md.DCS[k] = v
            end
            wallet.carriedProgress = nil
            DCS_dprint("[DCS] getPlayerData: Applied carried challenge progress from previous character")
        end

        local charEntry = nil
        for _, h in ipairs(wallet.history) do
            if h.id == charId then charEntry = h; break end
        end
        if not charEntry then
            charEntry = {
                id = charId,
                name = DCS_Identity.displayName(player),
                bestFastest1 = 0,
                bestFastest7 = 0,
                longestStreak = 0,
                totalChallengesCompleted = 0,
                speedrun1Attempts = {},
                speedrun7Attempts = {},
            }
            wallet.history[#wallet.history + 1] = charEntry
        end

        local pd = md.DCS
        pd.currency = wallet.tokens

        local uname = player:getUsername()

        pd.bestFastest1 = charEntry.bestFastest1 or 0
        pd.bestFastest7 = charEntry.bestFastest7 or 0
        pd.longestStreak = charEntry.longestStreak or 0

        if pd.streak == nil then pd.streak = 0 end
        if pd.streakLevel == nil then
            pd.streakLevel = pd.streak > 0 and ((pd.streak - 1) % 28) + 1 or 0
        end
        if pd.lifetimeCompleted == nil then pd.lifetimeCompleted = 0 end
        if pd.lastCompletedDay == nil then pd.lastCompletedDay = "" end
        if pd.dailyCompleted == nil then pd.dailyCompleted = {} end
        if pd.dailyKills == nil then pd.dailyKills = 0 end
        if pd.killsResetDay == nil then pd.killsResetDay = "" end
        if pd.dailyKillsByWeapon == nil then pd.dailyKillsByWeapon = {} end
        if pd.killsByWeaponResetDay == nil then pd.killsByWeaponResetDay = "" end
        if pd.dailyKillsByCategory == nil then pd.dailyKillsByCategory = {} end
        if pd.killsByCategoryResetDay == nil then pd.killsByCategoryResetDay = "" end
        if pd.bonusAwardedDay == nil then pd.bonusAwardedDay = "" end
        if pd.dailyProgress == nil then pd.dailyProgress = {} end
        if pd.progressResetDay == nil then pd.progressResetDay = "" end
        if pd.challengeStartDay == nil then pd.challengeStartDay = "" end
        if pd.challengeStartTime == nil then pd.challengeStartTime = 0 end
        if pd.speedrun1DoneToday == nil then pd.speedrun1DoneToday = false end
        if pd.speedrun7DoneToday == nil then pd.speedrun7DoneToday = false end
        if pd.dataVersion == nil then pd.dataVersion = 0 end

        local gmd = ModData.getOrCreate("DCS_Global")
        local resetVersion = gmd.debugResetVersion or 0
        local resetType = gmd.debugResetType or ""
        if resetVersion > (pd.dataVersion or 0) and resetType ~= "" then
            if resetType == "clearTokens" then
                pd.currency = 0
                wallet.tokens = 0
                print("[DCS] Pending reset applied (clearTokens) for SP character")
            elseif resetType == "clearProgress" then
                pd.dailyCompleted = {}
                pd.dailyKills = 0
                pd.killsResetDay = ""
                pd.dailyKillsByWeapon = {}
                pd.killsByWeaponResetDay = ""
                pd.dailyKillsByCategory = {}
                pd.killsByCategoryResetDay = ""
                pd.dailyProgress = {}
                pd.progressResetDay = ""
                pd.bonusAwardedDay = ""
                startSpeedrunTimer(pd)
                print("[DCS] Pending reset applied (clearProgress) for SP character")
            elseif resetType == "resetAll" then
                local savedCurrency = pd.currency
                for k, v in pairs(defaultPlayerData()) do
                    pd[k] = v
                end
                pd.currency = savedCurrency
                pd._id = charId
                startSpeedrunTimer(pd)
                print("[DCS] Pending reset applied (resetAll) for SP character")
            end
            pd.dataVersion = resetVersion
        end

        md.DCS = pd

        local store = ModData.getOrCreate("DCS_PlayerStore")
        if not store.players then store.players = {} end
        if not store.players[uname] then store.players[uname] = {} end
        for k, v in pairs(pd) do
            store.players[uname][k] = v
        end

        return pd
    end

    local gmd = ModData.getOrCreate("DCS_Global")
    local store = ModData.getOrCreate("DCS_PlayerStore")
    if not store.players then store.players = {} end
    local uname = player:getUsername() or "unknown"

    local pd = store.players[uname]
    if not pd then
        pd = md.DCS or defaultPlayerData()
        store.players[uname] = pd
    end

    if pd.streakLevel == nil then
        pd.streakLevel = (pd.streak or 0) > 0
            and ((pd.streak - 1) % 28) + 1 or 0
    end
    if pd.challengeStartDay == nil then pd.challengeStartDay = "" end
    if pd.challengeStartTime == nil then pd.challengeStartTime = 0 end
    if pd.dataVersion == nil then pd.dataVersion = 0 end

    local resetVersion = gmd.debugResetVersion or 0
    local resetType = gmd.debugResetType or ""
    if resetVersion > (pd.dataVersion or 0) and resetType ~= "" then
        if resetType == "clearTokens" then
            pd.currency = 0
            print("[DCS] Pending reset applied (clearTokens) for " .. tostring(uname))
        elseif resetType == "clearProgress" then
            pd.dailyCompleted = {}
            pd.dailyKills = 0
            pd.killsResetDay = ""
            pd.dailyKillsByWeapon = {}
            pd.killsByWeaponResetDay = ""
            pd.dailyKillsByCategory = {}
            pd.killsByCategoryResetDay = ""
            pd.dailyProgress = {}
            pd.progressResetDay = ""
            pd.bonusAwardedDay = ""
            startSpeedrunTimer(pd)
            print("[DCS] Pending reset applied (clearProgress) for " .. tostring(uname))
        elseif resetType == "resetAll" then
            pd = defaultPlayerData()
            store.players[uname] = pd
            startSpeedrunTimer(pd)
            print("[DCS] Pending reset applied (resetAll) for " .. tostring(uname))
        end
        pd.dataVersion = resetVersion
    end

    md.DCS = pd
    return pd
end

local function syncWallet(pd)
    if DCS_Env.isSP() and pd then
        local wallet = ModData.getOrCreate("DCS_SP")
        wallet.tokens = pd.currency or 0
    end
end

local function getPlayerDisplayName(player)
    return DCS_Identity.displayName(player)
end

local function sendToClient(player, command, args)
    if isServer() then
        sendServerCommand(player, MOD_ID, command, args)
    end
    if (DCS_Env.isHost() and player == getSpecificPlayer(0)) or DCS_Env.isSP() then
        triggerEvent("OnServerCommand", MOD_ID, command, args)
    end
end

local function sendToAllClients(command, args)
    if isServer() and DCS_Env.isServerNetworkReady() then
        sendServerCommand(MOD_ID, command, args)
    end
    if DCS_Env.isHost() or DCS_Env.isSP() then
        triggerEvent("OnServerCommand", MOD_ID, command, args)
    end
end

local shopStockData = {}

local shopTraderSplit = { east = {}, west = {} }

local dailySelectedItems = {}
local dailyRotationActive = false

local function getShopConfig()
    local gmd = ModData.getOrCreate("DCS_Global")
    if not gmd.shopConfig then
        gmd.shopConfig = { enabledItems = {}, customCosts = {}, customStock = {} }
        for _, item in ipairs(DCS_Challenges.Shop) do
            if DCS_Env.isSP() or item.mpDefault then
                gmd.shopConfig.enabledItems[#gmd.shopConfig.enabledItems + 1] = item.itemId
            end
        end
        ModData.transmit("DCS_Global")
    end
    return gmd.shopConfig
end

local function isShopItemEnabled(itemId)
    local cfg = getShopConfig()
    for _, id in ipairs(cfg.enabledItems) do
        if id == itemId then return true end
    end
    return false
end

local function getShopItemDef(itemId)
    for _, item in ipairs(DCS_Challenges.Shop) do
        if item.itemId == itemId then return item end
    end
    return nil
end

local function resolveShopItem(itemId)
    local def = getShopItemDef(itemId)
    if not def then return nil end
    local cfg = getShopConfig()
    local resolved = {}
    resolved.cost = cfg.customCosts[itemId] or def.cost
    local q = cfg.customStock[itemId]
    if q and q[1] and q[2] then
        resolved.quantities = q
    else
        resolved.quantities = def.quantities or { def.cost, def.cost }
    end
    return resolved
end

local TRADER_SPLIT_MIN_ITEMS = 4

local SHOP_DAILY_CAP = 36

local DISPLAY_CAT_MAP = {
    tool = "Tools", toolweapon = "Tools", gardening = "Tools",
    gardeningweapon = "Tools", cooking = "Tools", cookingweapon = "Tools",
    fishing = "Tools", fishingweapon = "Tools", lightsource = "Tools",
    firesource = "Tools", trapping = "Tools", security = "Tools",
    cartography = "Tools", vehiclemaintenance = "Tools",
    vehiclemaintenanceweapon = "Tools",
    weapon = "Weapons", weaponcrafted = "Weapons", weaponimprovised = "Weapons",
    weaponpart = "Weapons", explosives = "Weapons", ammo = "Weapons",
    brokenweapon = "Weapons", householdweapon = "Weapons", junkweapon = "Weapons",
    materialweapon = "Weapons", sportsweapon = "Weapons",
    instrumentweapon = "Weapons", animalpartweapon = "Weapons",
    firstaidweapon = "Weapons",
    clothing = "Clothing", accessories = "Clothing", accessory = "Clothing",
    appearance = "Other", ears = "Clothing", tail = "Clothing",
    bag = "Equipment", communications = "Equipment", container = "Equipment",
    protectivegear = "Equipment", water = "Equipment", watercontainer = "Equipment",
    camping = "Equipment",
    food = "Food",
    literature = "Literature", skillbook = "Literature",
    ["recipe resource"] = "Literature", reciperesource = "Literature", memento = "Other",
    material = "Materials",
    firstaid = "Medical", bandage = "Medical",
    entertainment = "Other", electronics = "Other", furniture = "Other",
    household = "Other", instrument = "Other", junk = "Other",
    generic = "Other", sports = "Other", paint = "Other", animal = "Other",
    animalpart = "Materials", dog = "Other",
}
local EXCLUDED_CATEGORIES = { Corpse = true, RemovedItem = true, Debug = true }

local function resolveItemCategory(itemId)
    local sm = ScriptManager and ScriptManager.getInstance and ScriptManager.getInstance()
    if not sm then sm = getScriptManager and getScriptManager() end
    if sm then
        local si = sm:FindItem(itemId)
        if si then
            local displayCat = si.getDisplayCategory and si:getDisplayCategory()
            if displayCat then
                local dc = string.lower(displayCat)
                if dc == "gardeningweapon" then
                    if string.find(string.lower(itemId), "machete") then return "Weapons" end
                    return "Tools"
                end
                local mapped = DISPLAY_CAT_MAP[dc]
                if mapped then return mapped end
                if EXCLUDED_CATEGORIES[displayCat] then return nil end
                if string.find(string.lower(itemId), "mag") or string.find(string.lower(itemId), "book") then
                    DCS_dprint("[DCS_SHOP] unmapped category '" .. displayCat .. "' for " .. itemId)
                end
            end
            local cat = si.getCategory and si:getCategory()
            if cat == "Clothing" then return "Clothing" end
            if cat == "Container" then return "Equipment" end
            if cat == "Communications" then return "Equipment" end
        end
    end
    local lt = string.lower(itemId)

    if string.find(lt, "nails") or string.find(lt, "screw") or string.find(lt, "duct")
        or string.find(lt, "glue") or string.find(lt, "rope") or string.find(lt, "wire")
        or string.find(lt, "leather") or string.find(lt, "yarn") or string.find(lt, "thread")
        or string.find(lt, "fabric") or string.find(lt, "scrap") or string.find(lt, "ingot")
        or string.find(lt, "bar") or string.find(lt, "sheet") or string.find(lt, "plank")
        or string.find(lt, "log") or string.find(lt, "stone") or string.find(lt, "clay")
        or string.find(lt, "sand") or string.find(lt, "gravel") or string.find(lt, "concrete")
        or string.find(lt, "gunpowder") or string.find(lt, "mold") or string.find(lt, "ammostrap")
        or string.find(lt, "fishingline") or string.find(lt, "fishinghook") or string.find(lt, "fishingnet")
        or string.find(lt, "premiumfishing") then return "Materials" end

    if string.find(lt, "book") or string.find(lt, "mag") or string.find(lt, "newspaper")
        or string.find(lt, "recipe") or string.find(lt, "skillbook") then return "Literature" end

    if string.find(lt, "hat") or string.find(lt, "jacket") or string.find(lt, "shirt")
        or string.find(lt, "pants") or string.find(lt, "shoes") or string.find(lt, "vest")
        or string.find(lt, "gloves") or string.find(lt, "scarf") or string.find(lt, "belt")
        or string.find(lt, "boots") or string.find(lt, "helmet") or string.find(lt, "mask")
        or string.find(lt, "bra") or string.find(lt, "underwear") or string.find(lt, "socks")
        or string.find(lt, "bunny") or string.find(lt, "holster") or string.find(lt, "poncho")
        or string.find(lt, "robe") or string.find(lt, "dress") or string.find(lt, "skirt")
        or string.find(lt, "sweater") or string.find(lt, "hoodie") or string.find(lt, "tshirt")
        or string.find(lt, "apron") or string.find(lt, "necklace") or string.find(lt, "ring")
        or string.find(lt, "earring") or string.find(lt, "glasses") or string.find(lt, "goggle")
        or string.find(lt, "codpiece") or string.find(lt, "gorget") or string.find(lt, "greave")
        or string.find(lt, "kneepad") or string.find(lt, "shoulderpad") or string.find(lt, "shinpad")
        or string.find(lt, "cuirass") or string.find(lt, "longjohn") or string.find(lt, "hazmat")
        or string.find(lt, "spiffo") or string.find(lt, "ghillie") or string.find(lt, "jockey")
        or string.find(lt, "football") or string.find(lt, "hockey") or string.find(lt, "swimsuit")
        or string.find(lt, "swimtrunk") or string.find(lt, "bandage") then return "Clothing" end

    if string.find(lt, "bag") or string.find(lt, "backpack") or string.find(lt, "container")
        or string.find(lt, "radio") or string.find(lt, "walkie") or string.find(lt, "generator")
        or string.find(lt, "flashlight") or string.find(lt, "torch") or string.find(lt, "battery")
        or string.find(lt, "lantern") or string.find(lt, "lighter") or string.find(lt, "match")
        or string.find(lt, "key") or string.find(lt, "padlock") or string.find(lt, "suitcase")
        or string.find(lt, "toolbox") or string.find(lt, "firstaid") or string.find(lt, "medkit")
        or string.find(lt, "fishingrod") or string.find(lt, "fishing") or string.find(lt, "bait")
        or string.find(lt, "hook") or string.find(lt, "lure") or string.find(lt, "bobber")
        or string.find(lt, "net") or string.find(lt, "trap") or string.find(lt, "spear")
        or string.find(lt, "tent") or string.find(lt, "sleepingbag") or string.find(lt, "compass")
        or string.find(lt, "watch") or string.find(lt, "canteen") or string.find(lt, "petrol")
        or string.find(lt, "jerry") or string.find(lt, "siphon") or string.find(lt, "jack")
        or string.find(lt, "tire") or string.find(lt, "wrench") or string.find(lt, "lug")
        or string.find(lt, "carbattery") or string.find(lt, "engine") or string.find(lt, "muffler")
        or string.find(lt, "suspension") or string.find(lt, "brake") or string.find(lt, "windshield")
        or string.find(lt, "window") or string.find(lt, "door") or string.find(lt, "hood")
        or string.find(lt, "trunk") or string.find(lt, "seat") or string.find(lt, "glovebox")
        or string.find(lt, "lightbulb") or string.find(lt, "welding") or string.find(lt, "blowtorch")
        or string.find(lt, "propane") or string.find(lt, "knapsack") or string.find(lt, "chest")
        or string.find(lt, "oldweldinggoggles") then return "Equipment" end

    if string.find(lt, "pill") or string.find(lt, "suture")
        or string.find(lt, "antibiotic") or string.find(lt, "disinfect") or string.find(lt, "splint")
        or string.find(lt, "stethoscope") or string.find(lt, "scalpel") or string.find(lt, "tweezers")
        or string.find(lt, "forceps") or string.find(lt, "mortar") or string.find(lt, "pestle")
        or string.find(lt, "tissue") or string.find(lt, "cottonball") or string.find(lt, "alcohol")
        or string.find(lt, "bandaid") or string.find(lt, "firstaidkit") then return "Medical" end

    if string.find(lt, "canned") or string.find(lt, "food") or string.find(lt, "snack")
        or string.find(lt, "chocolate") or string.find(lt, "candy") or string.find(lt, "pop")
        or string.find(lt, "soda") or string.find(lt, "juice") or string.find(lt, "beer")
        or string.find(lt, "wine") or string.find(lt, "whiskey") or string.find(lt, "vodka")
        or string.find(lt, "rum") or string.find(lt, "gin") or string.find(lt, "brandy")
        or string.find(lt, "tea") or string.find(lt, "coffee") or string.find(lt, "milk")
        or string.find(lt, "water") or string.find(lt, "soup") or string.find(lt, "stew")
        or string.find(lt, "bread") or string.find(lt, "cheese") or string.find(lt, "meat")
        or string.find(lt, "fish") or string.find(lt, "fruit") or string.find(lt, "vegetable")
        or string.find(lt, "pie") or string.find(lt, "cake") or string.find(lt, "cookie")
        or string.find(lt, "muffin") or string.find(lt, "cereal") or string.find(lt, "oats")
        or string.find(lt, "rice") or string.find(lt, "pasta") or string.find(lt, "noodle")
        or string.find(lt, "butter") or string.find(lt, "oil") or string.find(lt, "sauce")
        or string.find(lt, "spice") or string.find(lt, "herb") or string.find(lt, "seed")
        or string.find(lt, "flour") or string.find(lt, "sugar") or string.find(lt, "salt")
        or string.find(lt, "pepper") or string.find(lt, "honey") or string.find(lt, "jam")
        or string.find(lt, "yogurt") or string.find(lt, "icecream") or string.find(lt, "popsicle")
        or string.find(lt, "granola") or string.find(lt, "cracker")
        or string.find(lt, "pretzel") or string.find(lt, "chips") or string.find(lt, "popcorn")
        or string.find(lt, "dogfood") or string.find(lt, "catfood") or string.find(lt, "treat") then return "Food" end

    return "Other"
end

local function groupItemsByCategory(itemIds)
    local groups = {}
    for _, cat in ipairs(DCS_Challenges.ShopCategories or {}) do
        groups[cat] = {}
    end
    groups["Other"] = groups["Other"] or {}
    for _, itemId in ipairs(itemIds) do
        local cat = resolveItemCategory(itemId) or "Other"
        if not groups[cat] then groups[cat] = {} end
        groups[cat][#groups[cat] + 1] = itemId
    end
    for cat, items in pairs(groups) do
        if #items > 0 then
            DCS_dprint("[DCS_SHOP] Category '" .. cat .. "': " .. #items .. " items")
        end
    end
    return groups
end

local function pickRandomItems(items, count, seed, salt)
    if #items <= count then return { unpack(items) } end
    local copy = {}
    for _, v in ipairs(items) do copy[#copy + 1] = v end
    local s = seed + (salt or 0)
    for i = #copy, 2, -1 do
        local j = 1 + math.floor(lcgRand(s, i) * i)
        if j < 1 then j = 1 elseif j > i then j = i end
        copy[i], copy[j] = copy[j], copy[i]
        s = s + 1
    end
    local result = {}
    for i = 1, count do result[#result + 1] = copy[i] end
    return result
end

local SETTING_DEFAULT = {
    limitShopItems = true,
    tokensPersistDeath = true,
    challengeProgressPersistDeath = false,
}

local function dcsSetting(key)
    local gmd = ModData.getOrCreate("DCS_Global")
    local s = gmd.dcsSettings and gmd.dcsSettings[key]
    if type(s) == "boolean" then return s end
    if type(s) == "table" and type(s.effective) == "boolean" then return s.effective end
    local d = SETTING_DEFAULT[key]
    if d == nil then d = true end
    return d
end

local function shopItemsLimited()
    return dcsSetting("limitShopItems")
end

local function shuffleList(items, seed, salt)
    local copy = {}
    for _, v in ipairs(items) do copy[#copy + 1] = v end
    local s = (seed or 0) + (salt or 0)
    for i = #copy, 2, -1 do
        local j = 1 + math.floor(lcgRand(s, i) * i)
        if j < 1 then j = 1 elseif j > i then j = i end
        copy[i], copy[j] = copy[j], copy[i]
        s = s + 1
    end
    return copy
end

local function roundRobinSelect(groups, cap, seed)
    local queues, salt = {}, 0
    for _, cat in ipairs(DCS_Challenges.ShopCategories or {}) do
        local items = groups[cat]
        if items and #items > 0 then
            queues[#queues + 1] = shuffleList(items, seed, salt)
            salt = salt + 100
        end
    end
    local selected, depth, anyLeft = {}, 1, true
    while #selected < cap and anyLeft do
        anyLeft = false
        for _, q in ipairs(queues) do
            local id = q[depth]
            if id then
                selected[#selected + 1] = id
                anyLeft = true
                if #selected >= cap then break end
            end
        end
        depth = depth + 1
    end
    return selected
end

local function computeTraderSplit()
    local seed = dateSeed(getEffectiveDateString())
    local items = dailySelectedItems or {}

    if #items < TRADER_SPLIT_MIN_ITEMS then
        local east, west = {}, {}
        for _, id in ipairs(items) do
            east[#east + 1] = id
            west[#west + 1] = id
        end
        shopTraderSplit = { east = east, west = west }
        DCS_dprint("[DCS_SHOP] Trader split: " .. #items .. " items (< " .. TRADER_SPLIT_MIN_ITEMS
            .. ") - both traders show all")
        return
    end

    if dailyRotationActive then
        local east, west = {}, {}
        local groups = groupItemsByCategory(items)
        for _, cat in ipairs(DCS_Challenges.ShopCategories or {}) do
            local catItems = groups[cat] or {}
            for i, id in ipairs(catItems) do
                if i % 2 == 1 then east[#east + 1] = id else west[#west + 1] = id end
            end
        end
        shopTraderSplit = { east = east, west = west }
        DCS_dprint("[DCS_SHOP] Trader split (rotation): East=" .. #east .. " West=" .. #west .. " items")
        return
    end

    local shuffled = shuffleList(items, seed)
    local east, west = {}, {}
    local half = math.ceil(#shuffled / 2)
    for idx, id in ipairs(shuffled) do
        if idx <= half then east[#east + 1] = id else west[#west + 1] = id end
    end
    shopTraderSplit = { east = east, west = west }
    DCS_dprint("[DCS_SHOP] Trader split (all): East=" .. #east .. " West=" .. #west .. " items")
end

local function randomizeShopStock()
    shopStockData = {}
    local cfg = getShopConfig()
    local defIds = {}

    local allEnabled = {}
    for _, item in ipairs(DCS_Challenges.Shop or {}) do
        if item and item.itemId and isShopItemEnabled(item.itemId) then
            allEnabled[#allEnabled + 1] = item.itemId
            defIds[item.itemId] = true
        end
    end
    for _, itemId in ipairs(cfg.enabledItems or {}) do
        if not defIds[itemId] and isShopItemEnabled(itemId) then
            allEnabled[#allEnabled + 1] = itemId
        end
    end

    dailyRotationActive = shopItemsLimited() and #allEnabled > SHOP_DAILY_CAP
    local stockThese = allEnabled
    if dailyRotationActive then
        local seed = dateSeed(getEffectiveDateString())
        local groups = groupItemsByCategory(allEnabled)
        stockThese = roundRobinSelect(groups, SHOP_DAILY_CAP, seed)
        DCS_dprint("[DCS_SHOP] Daily stock (limited): " .. #stockThese .. " of " .. #allEnabled .. " enabled")
    else
        DCS_dprint("[DCS_SHOP] Daily stock (all): " .. #allEnabled .. " items")
    end
    dailySelectedItems = stockThese

    for _, itemId in ipairs(stockThese) do
        local resolved = resolveShopItem(itemId)
        local q = resolved and resolved.quantities
        local min = (q and tonumber(q[1])) or 1
        local max = (q and tonumber(q[2])) or min
        local stockVal = dcsRandom:random(min, max)
        shopStockData[itemId] = stockVal
    end

    local count = 0
    for _ in pairs(shopStockData) do count = count + 1 end
    DCS_dprint("[DCS_SHOP] Shop stock: " .. tostring(count) .. " items")

    computeTraderSplit()

    local gmd = ModData.getOrCreate("DCS_Global")
    gmd.shopStockData = shopStockData
    gmd.dailySelectedItems = dailySelectedItems
    gmd.dailyRotationActive = dailyRotationActive
end

local function getShopStock()
    local count = 0
    for _ in pairs(shopStockData) do count = count + 1 end
    if count == 0 then
        DCS_dprint("[DCS_SHOP] getShopStock: shopStockData empty at read time — lazy-rolling now (diagnostic: this firing before onServerStarted's restore assignment would explain a spurious reroll)")
        randomizeShopStock()
    end
    return shopStockData
end

local function broadcastShopStock()
    local stock = getShopStock()
    local arr = {}
    for k, v in pairs(stock) do
        if isShopItemEnabled(k) then
            arr[#arr + 1] = { id = k, qty = v }
        end
    end
    DCS_dprint("[DCS_SHOP] broadcastShopStock: " .. #arr .. " items with stock > 0")
    if #arr > 0 then
        for i = 1, math.min(10, #arr) do
            DCS_dprint("[DCS]   " .. arr[i].id .. " = " .. tostring(arr[i].qty))
        end
    end
    DCS_dprint("[DCS_SHOP]   East items: " .. #shopTraderSplit.east .. ", West items: " .. #shopTraderSplit.west)
    if #shopTraderSplit.east > 0 then
        for i = 1, math.min(5, #shopTraderSplit.east) do
            DCS_dprint("[DCS_SHOP]   East[" .. i .. "] = " .. tostring(shopTraderSplit.east[i]))
        end
    end
    sendToAllClients("shopStockUpdate", {
        stock = arr,
        east = shopTraderSplit.east,
        west = shopTraderSplit.west,
    })
end

local function syncShopStockToPlayer(player)
    local stock = getShopStock()
    local arr = {}
    for k, v in pairs(stock) do
        if isShopItemEnabled(k) then
            arr[#arr + 1] = { id = k, qty = v }
        end
    end
    DCS_dprint("[DCS_SHOP] syncShopStockToPlayer: " .. #arr .. " items with stock > 0")
    for i = 1, math.min(5, #arr) do
        DCS_dprint("[DCS_SHOP]   stock[" .. arr[i].id .. "] = " .. tostring(arr[i].qty))
    end
    DCS_dprint("[DCS_SHOP]   East=" .. #shopTraderSplit.east .. " West=" .. #shopTraderSplit.west)
    for i = 1, math.min(3, #shopTraderSplit.east) do
        DCS_dprint("[DCS_SHOP]   East[" .. i .. "] = " .. tostring(shopTraderSplit.east[i]))
    end
    sendToClient(player, "shopStockSync", {
        stock = arr,
        east = shopTraderSplit.east,
        west = shopTraderSplit.west,
    })
end

local function syncShopConfigToPlayer(player)
    local cfg = getShopConfig()
    sendToClient(player, "shopConfigSync", {
        enabledItems = cfg.enabledItems,
        customCosts = cfg.customCosts,
        customStock = cfg.customStock,
        limitShopItems = shopItemsLimited(),
        tokensPersistDeath = dcsSetting("tokensPersistDeath"),
        challengeProgressPersistDeath = dcsSetting("challengeProgressPersistDeath"),
    })
end

local function broadcastShopConfig()
    local cfg = getShopConfig()
    sendToAllClients("shopConfigUpdate", {
        enabledItems = cfg.enabledItems,
        customCosts = cfg.customCosts,
        customStock = cfg.customStock,
        limitShopItems = shopItemsLimited(),
        tokensPersistDeath = dcsSetting("tokensPersistDeath"),
        challengeProgressPersistDeath = dcsSetting("challengeProgressPersistDeath"),
    })
end

local function syncChallengesToPlayer(player)
    local ids = {}
    local chDefs = {}
    for i, ch in ipairs(todayChallenges) do
        ids[i] = ch.id
        chDefs[i] = ch
    end
    local topology = "sp"
    if DCS_Env.isDedicated() then
        topology = "dedicated"
    elseif DCS_Env.isHost() then
        topology = "hosted"
    end
    sendToClient(player, "syncChallenges", {
        challengeIDs = ids,
        challenges = chDefs,
        seed = todaySeed,
        topology = topology,
    })
end

local function syncProgressToPlayer(player, resetProgress, includeWindowPositions)
    local pd = getPlayerData(player)
    local payload = {
        currency = pd.currency,
        streak = pd.streak,
        streakLevel = pd.streakLevel,
        dailyCompleted = pd.dailyCompleted,
        dailyKills = pd.dailyKills,
        dailyKillsByWeapon = pd.dailyKillsByWeapon or {},
        dailyKillsByCategory = pd.dailyKillsByCategory or {},
        dailyProgress = pd.dailyProgress or {},
        displayName = getPlayerDisplayName(player),
        resetProgress = resetProgress or false,
    }
    DCS_dprint("[DCS] syncProgressToPlayer -> " .. tostring(player:getUsername())
        .. " streak=" .. tostring(pd.streak) .. " streakLevel=" .. tostring(pd.streakLevel)
        .. " resetProgress=" .. tostring(resetProgress or false))
    if resetProgress or includeWindowPositions then
        local wp = {}
        for _, id in ipairs(DCS_Challenges.WindowIds) do
            wp[id .. "X"] = pd[id .. "X"]
            wp[id .. "Y"] = pd[id .. "Y"]
        end
        payload.windowPositions = wp
    end
    sendToClient(player, "syncProgress", payload)
end

local lastSentScalars = {}
local function syncProgressDelta(player)
    local pd = getPlayerData(player)
    local uname = player:getUsername() or "unknown"
    local last = lastSentScalars[uname]
    local payload = {
        dailyCompleted = pd.dailyCompleted,
        dailyKillsByWeapon = pd.dailyKillsByWeapon or {},
        dailyKillsByCategory = pd.dailyKillsByCategory or {},
        dailyProgress = pd.dailyProgress or {},
        displayName = getPlayerDisplayName(player),
        resetProgress = false,
    }
    if not last or last.currency ~= pd.currency then payload.currency = pd.currency end
    if not last or last.streak ~= pd.streak then payload.streak = pd.streak end
    if not last or last.streakLevel ~= pd.streakLevel then payload.streakLevel = pd.streakLevel end
    if not last or last.dailyKills ~= pd.dailyKills then payload.dailyKills = pd.dailyKills end
    lastSentScalars[uname] = {
        currency = pd.currency, streak = pd.streak,
        streakLevel = pd.streakLevel, dailyKills = pd.dailyKills,
    }
    DCS_dprint("[DCS] syncProgressDelta -> " .. uname
        .. " scalarsSent=" .. tostring(payload.currency ~= nil) .. "/" .. tostring(payload.streak ~= nil)
        .. "/" .. tostring(payload.streakLevel ~= nil) .. "/" .. tostring(payload.dailyKills ~= nil))
    sendToClient(player, "syncProgress", payload)
end

local lastProgressSync = {}
local PROGRESS_SYNC_THROTTLE = 3

local function syncProgressThrottled(player)
    local uname = player:getUsername() or "unknown"
    local now = os.time()
    if not lastProgressSync[uname] or (now - lastProgressSync[uname]) >= PROGRESS_SYNC_THROTTLE then
        lastProgressSync[uname] = now
        syncProgressDelta(player)
    end
end

local function awardCurrency(player, amount, reason)
    local pd = getPlayerData(player)
    pd.currency = pd.currency + amount
    syncWallet(pd)
    sendToClient(player, "currencyAwarded", {
        amount = amount,
        newTotal = pd.currency,
        reason = reason,
    })
    if DCS_Leaderboard and DCS_Leaderboard.updateTokens then
        DCS_Leaderboard.updateTokens(player, getPlayerDisplayName(player), pd.currency)
    end
end

local function removeQuestItems(inv, player, itemIds, count)
    local equippedItems = {}
    local nonEquippedItems = {}

    for _, itemId in ipairs(itemIds) do
        local found = inv:getAllTypeRecurse(itemId)
        for i = 0, found:size() - 1 do
            local item = found:get(i)
            if item then
                if player and item:isEquipped() then
                    equippedItems[#equippedItems + 1] = item
                else
                    nonEquippedItems[#nonEquippedItems + 1] = item
                end
            end
        end
    end

    local toRemove = {}
    for _, item in ipairs(nonEquippedItems) do
        if #toRemove >= count then break end
        toRemove[#toRemove + 1] = item
    end
    for _, item in ipairs(equippedItems) do
        if #toRemove >= count then break end
        toRemove[#toRemove + 1] = item
    end

    for _, item in ipairs(toRemove) do
        local actualContainer = item:getContainer() or inv
        actualContainer:DoRemoveItem(item)
        if sendRemoveItemFromContainer then
            sendRemoveItemFromContainer(actualContainer, item)
        end
    end

    return toRemove, #toRemove
end

local function countQuestItemVariants(inv, ch)
    local count = 0
    for _, variantId in ipairs(ch.itemVariants or { ch.itemId }) do
        count = count + inv:getCountTypeRecurse(variantId)
    end
    return count
end

local function completeChallenge(player, challengeId)
    DCS_dprint("[DCS] completeChallenge CALLED: player=" .. tostring(player:getUsername()) .. " challengeId=" .. tostring(challengeId))
    local pd = getPlayerData(player)
    local today = getEffectiveDateString()

    if pd.progressResetDay ~= today then
        pd.dailyCompleted = {}
        pd.dailyProgress = {}
        pd.progressResetDay = today
    end

    if pd.dailyCompleted[challengeId] then
        DCS_dprint("[DCS] completeChallenge: SKIP — " .. challengeId .. " already completed")
        return
    end

    pd.dailyCompleted[challengeId] = true
    DCS_dprint("[DCS] completeChallenge: PROCEED — " .. challengeId .. " marked complete")

    if DCS_Leaderboard and DCS_Leaderboard.deferBroadcasts then
        DCS_Leaderboard.deferBroadcasts()
    end

    if pd.lastCompletedDay ~= today then
        pd.streak = pd.streak + 1
        pd.streakLevel = ((pd.streak - 1) % 28) + 1
        pd.lastCompletedDay = today
    end

    local tier = DCS_Challenges.getTier(pd.streakLevel)

    local chTitle = (DCS_Challenges.Lookup[challengeId] and DCS_Challenges.Lookup[challengeId].title) or challengeId
    awardCurrency(player, tier.tokenPerChallenge,
        "Challenge Completed: " .. chTitle)

    local completedCount = 0
    for _, ch in ipairs(todayChallenges) do
        if ch and pd.dailyCompleted[ch.id] then
            completedCount = completedCount + 1
        end
    end

    sendToClient(player, "haloText", {
        text = nil,
        count = completedCount,
        total = DCS_Challenges.ChallengesPerDay
    })

    if completedCount == DCS_Challenges.ChallengesPerDay and pd.bonusAwardedDay ~= today then
        pd.bonusAwardedDay = today
        awardCurrency(player, tier.bonusAllSeven,
            "All " .. DCS_Challenges.ChallengesPerDay .. " Challenges Bonus!")
    end

    if pd.streakLevel == 28 then
        awardCurrency(player, DCS_Challenges.StreakCycleBonus,
            "28 Day Streak Completed\n+25 Tokens")
        pd.streakLevel = 1
        sendToClient(player, "playSound", { sound = "DCS_reward" })
        DCS_dprint("[DCS] 28-day cycle complete for " .. tostring(player:getUsername())
            .. " — streakLevel reset to 1, streak=" .. pd.streak)
    end

    pd.lifetimeCompleted = (pd.lifetimeCompleted or 0) + 1

    if DCS_Env and DCS_Env.isSP() then
        local sp = getSpecificPlayer(0)
        if sp then
            local md = sp:getModData()
            if md.DCS and md.DCS._id then
                local wallet = ModData.getOrCreate("DCS_SP")
                if wallet.history then
                    for _, h in ipairs(wallet.history) do
                        if h.id == md.DCS._id then
                            h.totalChallengesCompleted = (h.totalChallengesCompleted or 0) + 1
                            break
                        end
                    end
                end
            end
        end
    end

    if DCS_Leaderboard and DCS_Leaderboard.updatePlayer then
        DCS_Leaderboard.updatePlayer(
            player,
            getPlayerDisplayName(player),
            pd.lifetimeCompleted,
            pd.streak
        )
    end

    DCS_dprint("[DCS] Speedrun check: username=" .. tostring(player:getUsername())
        .. " challengeStartDay=" .. tostring(pd.challengeStartDay)
        .. " today=" .. today
        .. " challengeStartTime=" .. tostring(pd.challengeStartTime))
    if pd.challengeStartDay ~= today then
        local prevStartDay = pd.challengeStartDay
        pd.challengeStartDay = today
        local yesterday = os.date("!%Y%m%d", os.time() - 86400)
        if prevStartDay == yesterday then
            pd.challengeStartTime = os.time() - (os.time() % 86400)
        else
            pd.challengeStartTime = os.time()
        end
        DCS_dprint("[DCS] Speedrun timer initialized for " .. tostring(player:getUsername())
            .. " prevDay=" .. tostring(prevStartDay)
            .. " today=" .. today
            .. " startTime=" .. tostring(pd.challengeStartTime))
    else
        DCS_dprint("[DCS] Speedrun timer already set for today, keeping startTime=" .. tostring(pd.challengeStartTime))
    end

    local startTime = pd.challengeStartTime or os.time()
    local elapsedTime = os.time() - startTime
    local displayName = getPlayerDisplayName(player)
    DCS_dprint("[DCS] Speedrun elapsed: " .. tostring(player:getUsername())
        .. " login=" .. fmtClock(startTime)
        .. " now=" .. fmtClock()
        .. " elapsed=" .. fmtTime(elapsedTime)
        .. " (" .. tostring(elapsedTime) .. "s)")

    local leaderboardDate = getUTCDateString()

    DCS_dprint("[DCS] Speedrun completedCount=" .. tostring(completedCount)
        .. " speedrun1DoneToday=" .. tostring(pd.speedrun1DoneToday)
        .. " speedrun7DoneToday=" .. tostring(pd.speedrun7DoneToday))
    if not pd.speedrun1DoneToday then
        if DCS_Leaderboard and DCS_Leaderboard.updateSpeedrun then
            DCS_dprint("[DCS] Speedrun 1-challenge: " .. displayName .. " took " .. fmtTime(elapsedTime) .. " to complete 1st challenge")
            DCS_Leaderboard.updateSpeedrun(player, displayName, "speedrun1", elapsedTime, leaderboardDate)
            pd.speedrun1DoneToday = true
        end
    end

    if completedCount >= DCS_Challenges.ChallengesPerDay and not pd.speedrun7DoneToday then
        if DCS_Leaderboard and DCS_Leaderboard.updateSpeedrun then
            DCS_dprint("[DCS] Speedrun 7-challenge: " .. displayName .. " took " .. fmtTime(elapsedTime) .. " to complete all 7 challenges")
            DCS_Leaderboard.updateSpeedrun(player, displayName, "speedrun7", elapsedTime, leaderboardDate)
            pd.speedrun7DoneToday = true
        end
    end

    syncProgressToPlayer(player)
    lastProgressSync[player:getUsername() or "unknown"] = os.time()

    if DCS_Leaderboard and DCS_Leaderboard.flush then
        DCS_Leaderboard.flush()
    end

    if DCS_Backup and DCS_Backup.autoBackup then
        DCS_Backup.autoBackup()
    end
end

local function isHost()
    return isServer() and isClient()
end

local function isTrueSinglePlayer()
    return isServer() and isClient() and not DCS_SERVER_STARTED
end

local DEBUG_TIER = {
    grantAdmin = true,
    forceNextDay = true,
    forceChallenge = true,
    completeAndNext = true,
    completeAllChallenges = true,
    addToken = true,
    forceRePlaceObjects = true,
    objectStateCheck = true,
}

local function playerHasAdminTool(player)
    if not player then return false end
    local role = player:getRole()
    return role and role.hasAdminTool and role:hasAdminTool() == true
end

local function hasAdminCmdAccess(player)
    if DCS_Env.isHost() and player == getSpecificPlayer(0) then return true end
    if DCS_Env.isSP() and ((getCore() and getCore():getDebug()) or isModAuthor(player)) then return true end
    if getCore and getCore():getDebug() then return true end
    if playerHasAdminTool(player) then return true end
    return isModAuthor(player)
end

local function hasDebugCmdAccess(player)
    return isModAuthor(player)
end

local lastHitCache = {}

local function onWeaponHitCharacter(attacker, target, weapon, damage)
    if isTrueSinglePlayer() then return end
    if not attacker or not target then return end
    if not (instanceof and instanceof(attacker, "IsoPlayer")) then return end
    if not (instanceof and instanceof(target, "IsoZombie")) then return end

    do
        local md = target:getModData()
        if md and md.IsDCSNPC then return end
    end

    if weapon and weapon.isBareHands and weapon:isBareHands() then
        lastHitCache[target] = nil
        return
    end

    local weaponType = nil
    local weaponCategory = nil
    local primaryItem = attacker:getPrimaryHandItem()
    if primaryItem and primaryItem.getType then
        weaponType = DCS_WeaponLookup.resolveWeaponType(primaryItem:getType())
        weaponCategory = DCS_WeaponLookup.resolveWeaponCategory(primaryItem)
        DCS_dprint("[DCS] onWeaponHit: primaryHandItem:getType()=" .. tostring(primaryItem:getType()) .. " resolved=" .. tostring(weaponType) .. " category=" .. tostring(weaponCategory))
    elseif weapon and weapon.getType then
        weaponType = DCS_WeaponLookup.resolveWeaponType(weapon:getType())
        weaponCategory = DCS_WeaponLookup.resolveWeaponCategory(weapon)
        DCS_dprint("[DCS] onWeaponHit: weapon:getType()=" .. tostring(weapon:getType()) .. " resolved=" .. tostring(weaponType) .. " category=" .. tostring(weaponCategory))
    end

    lastHitCache[target] = { attacker = attacker, weaponType = weaponType, weaponCategory = weaponCategory }
end

Events.OnWeaponHitCharacter.Add(onWeaponHitCharacter)

local function onZombieDead(zombie)
    if isTrueSinglePlayer() then return end
    if not zombie then return end

    do
        local md = zombie:getModData()
        if md and md.IsDCSNPC then
            DCS_dprint("[DCS] onZombieDead: skipping DCS NPC kill (not a real zombie kill)")
            return
        end
    end

    local attacker = zombie.getAttackedBy and zombie:getAttackedBy() or nil
    local weaponType = nil
    local cached = lastHitCache[zombie]
    if cached then
        if not attacker then attacker = cached.attacker end
        weaponType = cached.weaponType
    end
    lastHitCache[zombie] = nil

    if not attacker then return end
    if not (instanceof and instanceof(attacker, "IsoPlayer")) then return end
    if not cached then return end

    local player = attacker
    local pd = getPlayerData(player)
    local today = getEffectiveDateString()

    if pd.killsResetDay ~= today then
        pd.dailyKills = 0
        pd.killsResetDay = today
    end

    pd.dailyKills = pd.dailyKills + 1
    DCS_dprint("[DCS] MP Kill: player=" .. tostring(player:getUsername()) .. " dailyKills=" .. pd.dailyKills .. " weaponType=" .. tostring(weaponType))

    if weaponType then
        if pd.killsByWeaponResetDay ~= today then
            pd.dailyKillsByWeapon = {}
            pd.killsByWeaponResetDay = today
        end
        pd.dailyKillsByWeapon[weaponType] = (pd.dailyKillsByWeapon[weaponType] or 0) + 1
        DCS_dprint("[DCS] MP Weapon Kill: weapon=" .. weaponType .. " count=" .. pd.dailyKillsByWeapon[weaponType])
    end

    local weaponCategory = cached and cached.weaponCategory or nil
    if weaponCategory then
        if pd.killsByCategoryResetDay ~= today then
            pd.dailyKillsByCategory = {}
            pd.killsByCategoryResetDay = today
        end
        pd.dailyKillsByCategory[weaponCategory] = (pd.dailyKillsByCategory[weaponCategory] or 0) + 1
        DCS_dprint("[DCS] MP Category Kill: category=" .. weaponCategory .. " count=" .. pd.dailyKillsByCategory[weaponCategory])
    end

    local challengeCompleted = false
    for _, ch in ipairs(todayChallenges) do
        if ch.type == "killZombies"
        and not pd.dailyCompleted[ch.id]
        and pd.dailyKills >= ch.target then
            completeChallenge(player, ch.id)
            challengeCompleted = true
        end
    end

    if weaponType then
        for _, ch in ipairs(todayChallenges) do
            if ch.type == "killWithWeapon"
            and not pd.dailyCompleted[ch.id]
            and ch.weaponType == weaponType then
                local count = pd.dailyKillsByWeapon[weaponType] or 0
                if count >= ch.target then
                    completeChallenge(player, ch.id)
                    challengeCompleted = true
                end
            end
        end
    end

    if weaponCategory then
        for _, ch in ipairs(todayChallenges) do
            if ch.type == "killWithCategory"
            and not pd.dailyCompleted[ch.id]
            and ch.weaponType == weaponCategory then
                local count = pd.dailyKillsByCategory[weaponCategory] or 0
                if count >= ch.target then
                    completeChallenge(player, ch.id)
                    challengeCompleted = true
                end
            end
        end
    end

    if not challengeCompleted then
        syncProgressThrottled(player)
    end
end

local function getAllPlayers()
    local players = DCS_Env.players()
    if type(players) ~= "table" then return {} end
    return players
end

local function onEveryOneMinute()
    if not DCS_Env.runsServerLogic() then return end

    local realDay = getUTCDateString()
    if lastRealDay and realDay ~= lastRealDay and forcedDayOffset ~= 0 then
        DCS_dprint("[DCS] Real UTC midnight detected — resetting forcedDayOffset from " .. forcedDayOffset .. " to 0")
        forcedDayOffset = 0
    end
    lastRealDay = realDay

    local currentDay = getEffectiveDateString()
    if currentDay ~= lastCheckedDay then
        DCS_Server.onDailyReset()
        return
    end

    if DCS_NPC and DCS_NPC.checkProximityAndSpawn then
        DCS_NPC.checkProximityAndSpawn(getAllPlayers())
        if DCS_NPC.getSpawnedNPCData then
            local npcData = DCS_NPC.getSpawnedNPCData()
            if #npcData > 0 then
                local rawTL = DCS_NPC.getTraderLocations and DCS_NPC.getTraderLocations() or {}
                local traderLocations = {}
                if rawTL.east then traderLocations[#traderLocations + 1] = { side = "east", x = rawTL.east.x, y = rawTL.east.y, z = rawTL.east.z, name = rawTL.east.name } end
                if rawTL.west then traderLocations[#traderLocations + 1] = { side = "west", x = rawTL.west.x, y = rawTL.west.y, z = rawTL.west.z, name = rawTL.west.name } end
                sendToAllClients("syncObjects", { npcs = npcData, traderLocations = traderLocations })
            end
        end
    end
end

function DCS_Server.onDailyReset()
    local previousDay = periodStringAt(forcedDayOffset - 1)

    lastHitCache = {}

    buildTodayChallenges()

    for _, player in ipairs(getAllPlayers()) do
        local pd = getPlayerData(player)
        pd.dailyCompleted = {}
        pd.dailyKills = 0
        pd.killsResetDay = getEffectiveDateString()
        pd.dailyKillsByWeapon = {}
        pd.killsByWeaponResetDay = getEffectiveDateString()
        pd.dailyKillsByCategory = {}
        pd.killsByCategoryResetDay = getEffectiveDateString()
        pd.dailyProgress = {}
        pd.progressResetDay = getEffectiveDateString()

        DCS_dprint("[DCS] onDailyReset streak check: " .. tostring(player:getUsername())
            .. " lastCompletedDay=" .. tostring(pd.lastCompletedDay)
            .. " previousDay=" .. tostring(previousDay)
            .. " equal=" .. tostring(pd.lastCompletedDay == previousDay)
            .. " streak(before)=" .. tostring(pd.streak)
            .. " forcedDayOffset=" .. tostring(forcedDayOffset))
        if pd.lastCompletedDay ~= previousDay then
            if pd.streak > 0 then
                DCS_dprint("[DCS] Streak reset for " .. tostring(player:getUsername()) ..
                      ": lastCompletedDay=" .. tostring(pd.lastCompletedDay) ..
                      " previousDay=" .. previousDay)
                if DCS_Leaderboard and DCS_Leaderboard.clearCurrentStreak then
                    DCS_Leaderboard.clearCurrentStreak(getPlayerDisplayName(player))
                end
            end
            pd.streak = 0
            pd.streakLevel = 0
        end

        startSpeedrunTimer(pd)
    end

    if not DCS_Env.isSP() then
        local store = ModData.getOrCreate("DCS_PlayerStore")
        if store.players then
            local onlineNames = {}
            for _, player in ipairs(getAllPlayers()) do
                onlineNames[player:getUsername()] = true
            end
            for uname, pd in pairs(store.players) do
                if not onlineNames[uname] and pd.lastCompletedDay ~= previousDay then
                    if pd.streak and pd.streak > 0 then
                        DCS_dprint("[DCS] Streak reset for offline " .. tostring(uname) ..
                              ": lastCompletedDay=" .. tostring(pd.lastCompletedDay) ..
                              " previousDay=" .. previousDay)
                        if DCS_Leaderboard and DCS_Leaderboard.clearCurrentStreak then
                            DCS_Leaderboard.clearCurrentStreak(uname)
                        end
                    end
                    pd.streak = 0
                    pd.streakLevel = 0
                end
            end
        end
    end

    if DCS_NPC and DCS_NPC.cleanupOrphans then
        local orphaned = DCS_NPC.cleanupOrphans()
        if orphaned > 0 then
            DCS_dprint("[DCS] CULL - onDailyReset: removed " .. orphaned .. " orphan(s)")
        end
    end
    if DCS_NPC and DCS_NPC.clearPersistedNPCData then
        DCS_NPC.clearPersistedNPCData()
    end

    if DCS_Config and DCS_Config.USE_NPC then
        if DCS_NPC and DCS_NPC.spawnForDay then
            DCS_NPC.spawnForDay(todayChallenges)
            npcsSpawned = true
        end
        if DCS_NPC and DCS_NPC.spawnTraders then
            DCS_NPC.spawnTraders(dateSeed(getEffectiveDateString()))
            tradersSpawned = true
        end
    end
    if DCS_Config and DCS_Config.USE_OBJECTS then
        if DCS_Objects and DCS_Objects.rebuildForDay then
            DCS_Objects.rebuildForDay(todayChallenges, dateSeed(getEffectiveDateString()))
        end
    end

    local ids = {}
    local chDefs = {}
    for i, ch in ipairs(todayChallenges) do
        ids[i] = ch.id
        chDefs[i] = ch
    end
    DCS_dprint("[DCS] onDailyReset: sending dailyReset with " .. #ids .. " challenges to all clients")
    sendToAllClients("dailyReset", {
        challengeIDs = ids,
        challenges = chDefs,
        seed = todaySeed,
    })

    for _, player in ipairs(getAllPlayers()) do
        syncProgressToPlayer(player)
    end

    randomizeShopStock()
    broadcastShopStock()

    if DCS_Backup and DCS_Backup.autoBackup then
        DCS_Backup.autoBackup(true)
    end

    if DCS_NPC and DCS_NPC.getSpawnedNPCData then
        local npcData = DCS_NPC.getSpawnedNPCData()
        local rawTL = DCS_NPC.getTraderLocations and DCS_NPC.getTraderLocations() or {}
        local traderLocations = {}
        if rawTL.east then traderLocations[#traderLocations + 1] = { side = "east", x = rawTL.east.x, y = rawTL.east.y, z = rawTL.east.z, name = rawTL.east.name } end
        if rawTL.west then traderLocations[#traderLocations + 1] = { side = "west", x = rawTL.west.x, y = rawTL.west.y, z = rawTL.west.z, name = rawTL.west.name } end
        DCS_dprint("[DCS] onDailyReset: sending syncObjects with " .. #npcData .. " NPCs, " .. #traderLocations .. " trader locations")
        sendToAllClients("syncObjects", { npcs = npcData, traderLocations = traderLocations })
    end
end

DCS_Server.completeChallenge = completeChallenge

local function onServerStarted()
    if not DCS_Env.runsServerLogic() then return end

    DCS_SERVER_STARTED = true

    if not DCS_Challenges or not DCS_Challenges.Lookup then
        print("[DCS] WARNING: DCS_Challenges not ready in onServerStarted — will retry on OnInitGlobalModData")
        return
    end

    if DCS_Backup and DCS_Backup.init then
        DCS_Backup.init()
    end

    DCS_dprint("[DCS] onServerStarted running. DCS_Challenges.Pool size: " .. tostring(DCS_Challenges and #DCS_Challenges.Pool or "nil"))

    local gmd = ModData.getOrCreate("DCS_Global")
    local today = getEffectiveDateString()

    local shopStockCount = 0
    if gmd.shopStockData then for _ in pairs(gmd.shopStockData) do shopStockCount = shopStockCount + 1 end end
    DCS_dprint("[DCS] today=" .. today .. " gmd.todaySeed=" .. tostring(gmd.todaySeed)
        .. " gmd.shopStockData count=" .. tostring(shopStockCount))

    if gmd.todaySeed == today and gmd.todayChallengeIDs and #gmd.todayChallengeIDs == 7 then
        DCS_dprint("[DCS] Restoring challenges from ModData")
        if gmd.activeTraderTowns then
            DCS_Challenges.setActiveTraderTowns(gmd.activeTraderTowns)
            DCS_dprint("[DCS] Restored active trader towns from ModData")
        end
        local seed = dateSeed(today)
        local visitNPC, questNPC = DCS_Challenges.pickDailyNPCs(seed)
        local traderTowns = DCS_Challenges.getActiveTraderTowns()
        local visitCh = DCS_Challenges.buildVisitChallenge(lcgRand(seed, 4 * 13), visitNPC and visitNPC.name, traderTowns)
        local questCh = DCS_Challenges.buildQuestChallenge(lcgRand(seed, 3 * 13), lcgRand(seed, 3 * 17), questNPC and questNPC.name, visitCh.town, traderTowns)
        DCS_Challenges.Lookup[visitCh.id] = visitCh
        DCS_Challenges.Lookup[questCh.id] = questCh

        todaySeed = gmd.todaySeed
        lastCheckedDay = today
        todayChallenges = {}
        for i, id in ipairs(gmd.todayChallengeIDs) do
            local ch = DCS_Challenges.Lookup[id]
            if ch then
                todayChallenges[i] = ch
                DCS_dprint("[DCS]   Restored: " .. id)
            else
                print("[DCS]   ID not found in Lookup: " .. tostring(id) .. " — rebuilding fresh")
                buildTodayChallenges()
                return
            end
        end
        if gmd.shopStockData and shopStockCount > 0 then
            shopStockData = gmd.shopStockData
            dailySelectedItems = gmd.dailySelectedItems or {}
            dailyRotationActive = gmd.dailyRotationActive or false
            computeTraderSplit()
            DCS_dprint("[DCS_SHOP] Restored shop stock from ModData (restart-stable)")
        else
            randomizeShopStock()
        end
    else
        DCS_dprint("[DCS] Building fresh challenges for today")
        buildTodayChallenges()
        randomizeShopStock()
    end
    broadcastShopStock()

    if DCS_Config and DCS_Config.USE_NPC then
        if not npcsSpawned and DCS_NPC and DCS_NPC.spawnForDay then
            DCS_dprint("[DCS] onServerStarted: queuing NPC spawns (proximity-triggered)")
            DCS_NPC.spawnForDay(todayChallenges)
            npcsSpawned = true
        end
        if not tradersSpawned and DCS_NPC and DCS_NPC.spawnTraders then
            DCS_dprint("[DCS] onServerStarted: queuing trader spawns")
            DCS_NPC.spawnTraders(dateSeed(getEffectiveDateString()))
            tradersSpawned = true
        end
        if DCS_NPC and DCS_NPC.cleanupOrphans then
            local orphaned = DCS_NPC.cleanupOrphans()
            if orphaned > 0 then
                DCS_dprint("[DCS] CULL - onServerStarted: removed " .. orphaned .. " orphan(s)")
            end
        end
    end
    if DCS_Config and DCS_Config.USE_OBJECTS then
        if DCS_Objects and DCS_Objects.rebuildForDay then
            DCS_dprint("[DCS] onServerStarted: placing challenge objects")
            DCS_Objects.rebuildForDay(todayChallenges, dateSeed(getEffectiveDateString()))
        end
    end
    DCS_dprint("[DCS] onServerStarted complete. todayChallenges count: " .. tostring(#todayChallenges))
end

local function onInitGlobalModData(isNewGame)
    DCS_dprint("[DCS] onInitGlobalModData fired. todaySeed=" .. tostring(todaySeed) .. " DCS_Challenges ready=" .. tostring(DCS_Challenges ~= nil))
    if not DCS_Challenges or not DCS_Challenges.Lookup then
        print("[DCS] ERROR: DCS_ChallengeDefinitions not loaded — check load order")
        return
    end
    if not todaySeed then
        DCS_dprint("[DCS] todaySeed nil — running onServerStarted from OnInitGlobalModData")
        onServerStarted()
    else
        DCS_dprint("[DCS] todaySeed already set (" .. todaySeed .. ") — skipping re-init")
    end
end

local function findTargetPlayer(targetName)
    if not targetName then return nil end
    for _, p in ipairs(getAllPlayers()) do
        if p:getUsername() == targetName then
            return p
        end
    end
    return nil
end

local function resolveTargetData(targetName)
    if not targetName then return nil, nil end
    local online = findTargetPlayer(targetName)
    if online then return getPlayerData(online), online end
    local store = ModData.getOrCreate("DCS_PlayerStore")
    if not store.players then store.players = {} end
    return store.players[targetName], nil
end

local function cmdResetAllUser(player, args)
    if DCS_Env.isSP() then
        local wallet = ModData.getOrCreate("DCS_SP")
        wallet.tokens = 0
        wallet.history = {}
        local sp = getSpecificPlayer(0)
        if sp then sp:getModData().DCS = nil end
        local tpd = getPlayerData(sp)
        startSpeedrunTimer(tpd)
        syncChallengesToPlayer(sp)
        syncProgressToPlayer(sp, true)
        if DCS_Leaderboard and DCS_Leaderboard.removePlayer then
            DCS_Leaderboard.removePlayer(getPlayerDisplayName(sp))
        end
        DCS_dprint("[DCS] resetAllUser (SP): wiped wallet + history + character data")
        return
    end
    local targetName = args.targetUsername
    if not targetName then print("[DCS] resetAllUser: missing targetUsername"); return end
    local store = ModData.getOrCreate("DCS_PlayerStore")
    if not store.players then store.players = {} end
    local online = findTargetPlayer(targetName)
    if online then
        store.players[targetName] = nil
        online:getModData().DCS = nil
        local tpd = getPlayerData(online)
        startSpeedrunTimer(tpd)
        syncChallengesToPlayer(online)
        syncProgressToPlayer(online, true)
        if DCS_Leaderboard and DCS_Leaderboard.removePlayer then
            DCS_Leaderboard.removePlayer(getPlayerDisplayName(online))
        end
    else
        local tpd = defaultPlayerData()
        startSpeedrunTimer(tpd)
        local gmd = ModData.getOrCreate("DCS_Global")
        tpd.dataVersion = gmd.debugResetVersion or 0
        store.players[targetName] = tpd
        if DCS_Leaderboard and DCS_Leaderboard.removePlayer then
            DCS_Leaderboard.removePlayer(targetName)
        end
    end
    DCS_dprint("[DCS] resetAllUser: " .. targetName .. (online and " (online)" or " (offline)")
        .. " wiped and re-initialised by " .. tostring(player:getUsername()))
end

local function cmdClearTokensUser(player, args)
    if DCS_Env.isSP() then
        local sp = getSpecificPlayer(0)
        if sp then
            local pd = getPlayerData(sp)
            pd.currency = 0
            syncWallet(pd)
            if DCS_Leaderboard and DCS_Leaderboard.updateTokens then
                DCS_Leaderboard.updateTokens(sp, getPlayerDisplayName(sp), 0)
            end
            syncProgressToPlayer(sp)
            DCS_Leaderboard.broadcast()
            DCS_dprint("[DCS] clearTokensUser (SP): tokens cleared")
        end
        return
    end
    local targetName = args.targetUsername
    if not targetName then print("[DCS] clearTokensUser: missing targetUsername"); return end
    local tpd, online = resolveTargetData(targetName)
    if not tpd then print("[DCS] clearTokensUser: no data for " .. targetName); return end
    tpd.currency = 0
    syncWallet(tpd)
    if DCS_Leaderboard and DCS_Leaderboard.updateTokens then
        DCS_Leaderboard.updateTokens(online, online and getPlayerDisplayName(online) or targetName, 0)
    end
    if online then syncProgressToPlayer(online) end
    DCS_dprint("[DCS] clearTokensUser: " .. targetName .. (online and " (online)" or " (offline)")
        .. " tokens cleared by " .. tostring(player:getUsername()))
end

local function cmdClearProgressUser(player, args)
    local targetName = args.targetUsername
    if not targetName then print("[DCS] clearProgressUser: missing targetUsername"); return end
    local tpd, online = resolveTargetData(targetName)
    if not tpd then print("[DCS] clearProgressUser: no data for " .. targetName); return end
    tpd.dailyCompleted = {}
    tpd.dailyKills = 0
    tpd.killsResetDay = getEffectiveDateString()
    tpd.dailyKillsByWeapon = {}
    tpd.killsByWeaponResetDay = getEffectiveDateString()
    tpd.dailyKillsByCategory = {}
    tpd.killsByCategoryResetDay = getEffectiveDateString()
    tpd.dailyProgress = {}
    tpd.progressResetDay = getEffectiveDateString()
    tpd.bonusAwardedDay = ""
    startSpeedrunTimer(tpd)
    if online then syncProgressToPlayer(online, true) end
    DCS_dprint("[DCS] clearProgressUser: " .. targetName .. (online and " (online)" or " (offline)")
        .. " progress cleared by " .. tostring(player:getUsername()))
end

local function cmdSetTokensUser(player, args)
    local targetName = args.targetUsername
    local amount = tonumber(args.amount) or 0
    if not targetName then print("[DCS] setTokensUser: missing targetUsername"); return end
    local tpd, online = resolveTargetData(targetName)
    if not tpd then print("[DCS] setTokensUser: no data for " .. targetName); return end
    tpd.currency = amount
    syncWallet(tpd)
    if DCS_Leaderboard and DCS_Leaderboard.updateTokens then
        DCS_Leaderboard.updateTokens(online, online and getPlayerDisplayName(online) or targetName, tpd.currency)
    end
    if online then syncProgressToPlayer(online) end
    DCS_dprint("[DCS] setTokensUser: " .. targetName .. (online and " (online)" or " (offline)")
        .. " tokens set to " .. amount .. " by " .. tostring(player:getUsername()))
end

local function cmdAddTokenToAll()
    if DCS_Env.isSP() then
        local sp = getSpecificPlayer(0)
        if sp then
            local pd = getPlayerData(sp)
            pd.currency = (pd.currency or 0) + 1
            syncWallet(pd)
            if DCS_Leaderboard and DCS_Leaderboard.updateTokens then
                DCS_Leaderboard.updateTokens(sp, getPlayerDisplayName(sp), pd.currency)
            end
            syncProgressToPlayer(sp)
            DCS_dprint("[DCS] addTokenToAll (SP): +1 -> " .. pd.currency)
        end
        return
    end
    local store = ModData.getOrCreate("DCS_PlayerStore")
    if not store.players then store.players = {} end
    local onlineByName = {}
    for _, p in ipairs(getAllPlayers()) do onlineByName[p:getUsername()] = p end
    local count = 0
    for uname, ppd in pairs(store.players) do
        ppd.currency = (ppd.currency or 0) + 1
        local online = onlineByName[uname]
        if DCS_Leaderboard and DCS_Leaderboard.updateTokens then
            DCS_Leaderboard.updateTokens(online, online and getPlayerDisplayName(online) or uname, ppd.currency)
        end
        if online then syncProgressToPlayer(online) end
        count = count + 1
        DCS_dprint("[DCS] addTokenToAll: " .. tostring(uname) .. (online and " (online)" or " (offline)")
            .. " +1 -> " .. ppd.currency)
    end
    DCS_dprint("[DCS] addTokenToAll: added 1 token to " .. count .. " player(s) (online + offline)")
end

local function cmdClearTokens(player, args)
    if DCS_Env.isSP() then
        local sp = getSpecificPlayer(0)
        if sp then
            local ppd = getPlayerData(sp)
            ppd.currency = 0
            syncWallet(ppd)
            if DCS_Leaderboard and DCS_Leaderboard.updateTokens then
                DCS_Leaderboard.updateTokens(sp, getPlayerDisplayName(sp), 0)
            end
            syncProgressToPlayer(sp)
            DCS_Leaderboard.broadcast()
            DCS_dprint("[DCS] Debug clearTokens (SP): tokens cleared")
        end
    else
        local gmd = ModData.getOrCreate("DCS_Global")
        gmd.debugResetVersion = (gmd.debugResetVersion or 0) + 1
        gmd.debugResetType = "clearTokens"
        ModData.transmit("DCS_Global")
        local store = ModData.getOrCreate("DCS_PlayerStore")
        local onlineUsernames = {}
        local count = 0
        for _, p in ipairs(getAllPlayers()) do
            onlineUsernames[p:getUsername()] = true
            local ppd = getPlayerData(p)
            ppd.currency = 0
            syncWallet(ppd)
            if DCS_Leaderboard and DCS_Leaderboard.updateTokens then
                DCS_Leaderboard.updateTokens(p, getPlayerDisplayName(p), 0)
            end
            ppd.dataVersion = gmd.debugResetVersion
            syncProgressToPlayer(p)
            count = count + 1
            DCS_dprint("[DCS] Debug clearTokens: " .. tostring(p:getUsername()) .. " -> 0")
        end
        if store.players then
            for uname, ppd in pairs(store.players) do
                if not onlineUsernames[uname] then
                    ppd.currency = 0
                    ppd.dataVersion = gmd.debugResetVersion
                    if DCS_Leaderboard and DCS_Leaderboard.updateTokens then
                        DCS_Leaderboard.updateTokens(nil, uname, 0)
                    end
                    DCS_dprint("[DCS] Debug clearTokens: " .. uname .. " (offline) -> 0")
                end
            end
        end
        DCS_dprint("[DCS] Debug clearTokens: cleared for " .. count .. " connected player(s), and all offline players")
    end
end

local function cmdAddToken(player, args)
    local pd = getPlayerData(player)
    local amount = tonumber(args.amount) or 1
    pd.currency = pd.currency + amount
    syncWallet(pd)
    if DCS_Leaderboard and DCS_Leaderboard.updateTokens then
        DCS_Leaderboard.updateTokens(player, getPlayerDisplayName(player), pd.currency)
    end
    DCS_dprint("[DCS] Debug addToken: " .. tostring(player:getUsername()) .. " +" .. amount .. " -> " .. pd.currency)
    syncProgressToPlayer(player)
end

local function cmdClearProgress(player, args)
    local gmd = ModData.getOrCreate("DCS_Global")
    gmd.debugResetVersion = (gmd.debugResetVersion or 0) + 1
    gmd.debugResetType = "clearProgress"
    ModData.transmit("DCS_Global")
    local count = 0
    for _, p in ipairs(getAllPlayers()) do
        local ppd = getPlayerData(p)
        ppd.dailyCompleted = {}
        ppd.dailyKills = 0
        ppd.killsResetDay = getEffectiveDateString()
        ppd.dailyKillsByWeapon = {}
        ppd.killsByWeaponResetDay = getEffectiveDateString()
        ppd.dailyKillsByCategory = {}
        ppd.killsByCategoryResetDay = getEffectiveDateString()
        ppd.dailyProgress = {}
        ppd.progressResetDay = getEffectiveDateString()
        ppd.bonusAwardedDay = ""
        startSpeedrunTimer(ppd)
        ppd.dataVersion = gmd.debugResetVersion
        syncProgressToPlayer(p, true)
        count = count + 1
        DCS_dprint("[DCS] Debug clearProgress: " .. tostring(p:getUsername()))
    end
    DCS_dprint("[DCS] Debug clearProgress: cleared for " .. count .. " connected player(s), pending for offline players")
end

local function cmdForceNextDay(player, args)
    local pd = getPlayerData(player)
    local oldOffset = forcedDayOffset
    forcedDayOffset = forcedDayOffset + 1
    pd.dailyCompleted = {}
    pd.dailyKills = 0
    pd.killsResetDay = ""
    pd.dailyKillsByWeapon = {}
    pd.killsByWeaponResetDay = ""
    pd.dailyProgress = {}
    pd.progressResetDay = ""
    pd.bonusAwardedDay = ""
    DCS_dprint("[DCS] Debug forceNextDay: " .. tostring(player:getUsername()) .. " offset " .. oldOffset .. " -> " .. forcedDayOffset)
    DCS_Server.onDailyReset()
    DCS_dprint("[DCS] Debug forceNextDay: onDailyReset returned, sending syncChallenges")
    syncChallengesToPlayer(player)
    syncProgressToPlayer(player, true)
    DCS_dprint("[DCS] Debug forceNextDay: all done")
end

local function cmdTestSeal(player, args)
    local sq = nil
    if args and args.x and getCell and getCell() then
        sq = getCell():getGridSquare(args.x, args.y, args.z or 0)
    end
    if not sq then sq = player and player:getCurrentSquare() end
    if sq and DCS_ObjectPlace and DCS_ObjectPlace.regionSealed then
        DCS_ObjectPlace._sealGen = (DCS_ObjectPlace._sealGen or 0) + 1
        local sealed = DCS_ObjectPlace.regionSealed(sq)
        local outside = sq:isOutside()
        local d = DCS_ObjectPlace.sealDiag and DCS_ObjectPlace.sealDiag(sq) or {}
        local r = DCS_ObjectPlace.reachDiag and DCS_ObjectPlace.reachDiag(sq) or {}
        DCS_dprint("[DCS] RoomTest by " .. tostring(player:getUsername())
            .. " at " .. sq:getX() .. "," .. sq:getY() .. "," .. sq:getZ()
            .. " outside=" .. tostring(outside))
        DCS_dprint("[DCS]   SEAL: sealed=" .. tostring(sealed)
            .. " flooded=" .. tostring(d.count)
            .. " reason=" .. tostring(d.reason)
            .. (d.atX and (" at=" .. d.atX .. "," .. d.atY) or "")
            .. " | startEdges: " .. tostring(d.edges))
        DCS_dprint("[DCS]   REACH: size=" .. tostring(r.size)
            .. " doors=" .. tostring(r.doors)
            .. " maxDepth=" .. tostring(r.maxDepth)
            .. " touchedOutside=" .. tostring(r.touchedOutside)
            .. " capped=" .. tostring(r.capped)
            .. " bbox=[" .. tostring(r.minX) .. "," .. tostring(r.minY)
            .. ".." .. tostring(r.maxX) .. "," .. tostring(r.maxY) .. "]"
            .. ((r.minX and r.maxX) and (" " .. (r.maxX - r.minX + 1) .. "x" .. (r.maxY - r.minY + 1)) or ""))
        DCS_dprint("[DCS]   DEPTH: d0(green)=" .. tostring(r.d0)
            .. " d1(yellow)=" .. tostring(r.d1)
            .. " d2(red)=" .. tostring(r.d2)
            .. " d3+(magenta)=" .. tostring(r.d3))
        sendToClient(player, "haloText", { noSound = true, roomTest = true, text = "Sealed=" .. tostring(sealed)
            .. " | rooms d0/d1/d2=" .. tostring(r.d0) .. "/" .. tostring(r.d1)
            .. "/" .. tostring(r.d2) .. (r.touchedOutside and " +out" or "") })
        sendToClient(player, "roomTestTiles", { z = r.z, cols = r.cols })
    else
        DCS_dprint("[DCS] SealTest: no square or DCS_ObjectPlace.regionSealed unavailable")
    end
end

local function cmdObjectStateCheck(player, args)
    local gmd = ModData.getOrCreate("DCS_ObjectData")
    local reg = gmd.objects or {}
    local staleKeys = gmd.staleKeys or {}
    local today = getEffectiveDateString()
    local regDay = gmd.day or "nil"
    local dayMatch = (regDay == today)

    DCS_dprint("[DCS] ####################")
    DCS_dprint("[DCS] Object State Check — " .. tostring(player:getUsername()))
    DCS_dprint("[DCS]   Registry day=" .. regDay .. " effective day=" .. today
        .. " match=" .. tostring(dayMatch))
    DCS_dprint("[DCS]   Registry entries=" .. tostring(#(function() local r={} for k in pairs(reg) do r[#r+1]=k end; return r end)()))
    DCS_dprint("[DCS]   Stale keys=" .. tostring(#(function() local r={} for k in pairs(staleKeys) do r[#r+1]=k end; return r end)()))

    local R = (DCS_ObjectPlace and DCS_ObjectPlace.MAX_R) or 0
    local cell = getCell and getCell() or nil
    local mismatches = 0
    local missing = 0
    local unloaded = 0
    for key, entry in pairs(reg) do
        local x, y, z = key:match("^(-?%d+),(-?%d+),(-?%d+)$")
        local sx, sy, sz = tonumber(x), tonumber(y), tonumber(z)
        local liveObj = nil
        local liveModData = nil
        local anyLoaded = false
        if cell and sx and sy then
            sz = sz or 0
            for dx = -R, R do
                if liveObj then break end
                for dy = -R, R do
                    local sq = cell:getGridSquare(sx + dx, sy + dy, sz)
                    if sq then
                        anyLoaded = true
                        local objs = sq:getObjects()
                        if objs then
                            for i = 0, objs:size() - 1 do
                                local o = objs:get(i)
                                if o then
                                    local md = o:getModData()
                                    if md and md.IsDCSObject and md.DCSAnchorKey == key then
                                        liveObj = o
                                        liveModData = md
                                        break
                                    end
                                end
                            end
                        end
                    end
                    if liveObj then break end
                end
            end
        end
        local status
        if liveObj then
            status = "OK"
            if liveModData.DCSChallengeId ~= entry.challengeId then
                status = "[MISMATCH] challengeId live=" .. tostring(liveModData.DCSChallengeId)
                    .. " reg=" .. tostring(entry.challengeId)
                mismatches = mismatches + 1
            end
        elseif anyLoaded then
            status = "[MISSING]"
            missing = missing + 1
        else
            status = "[UNLOADED]"
            unloaded = unloaded + 1
        end
        DCS_dprint("[DCS]   " .. key .. " type=" .. tostring(entry.type)
            .. " chId=" .. tostring(entry.challengeId)
            .. " -> " .. status)
    end

    local staleOnLoaded = 0
    for key in pairs(staleKeys) do
        local x, y, z = key:match("^(-?%d+),(-?%d+),(-?%d+)$")
        local sx, sy, sz = tonumber(x), tonumber(y), tonumber(z)
        if cell and sx and sy then
            local sq = cell:getGridSquare(sx, sy, sz or 0)
            if sq then
                staleOnLoaded = staleOnLoaded + 1
                DCS_dprint("[DCS]   STALE ON LOADED SQUARE: " .. key)
            end
        end
    end

    local summary = "Objects=" .. tostring(#(function() local r={} for k in pairs(reg) do r[#r+1]=k end; return r end)())
        .. " Missing=" .. missing .. " Mismatches=" .. mismatches
        .. " Unloaded=" .. unloaded
        .. " StaleOnLoaded=" .. staleOnLoaded
        .. " DayMatch=" .. tostring(dayMatch)
    DCS_dprint("[DCS]   SUMMARY: " .. summary)
    DCS_dprint("[DCS] ####################")

    sendToClient(player, "objectStateCheckClient", {})

    sendToClient(player, "haloText", { noSound = true, diagnostic = true, text = "Object State Check Complete // Added to Logs" })
end

local function cmdForceRePlaceObjects(player, args)
    local n = DCS_Objects and DCS_Objects.forceRePlaceAll and DCS_Objects.forceRePlaceAll() or 0
    DCS_dprint("[DCS] forceRePlaceObjects: " .. tostring(player:getUsername())
        .. " re-placed " .. n .. " object(s)")
    sendToClient(player, "haloText", { noSound = true, diagnostic = true,
        text = "Re-placed " .. n .. " DCS object(s)" })
end

local function cmdResetLeaderboard(player, args)
    if DCS_Leaderboard and DCS_Leaderboard.reset then
        DCS_Leaderboard.reset()
        DCS_dprint("[DCS] Debug resetLeaderboard: " .. tostring(player:getUsername()) .. " - leaderboard wiped")
    else
        print("[DCS] Debug resetLeaderboard: " .. tostring(player:getUsername()) .. " - DCS_Leaderboard.reset not found!")
    end
end

local function cmdResetAll(player, args)
    if DCS_Env.isSP() then
        local wallet = ModData.getOrCreate("DCS_SP")
        wallet.tokens = 0
        wallet.history = {}
        local sp = getSpecificPlayer(0)
        if sp then sp:getModData().DCS = nil end
        local ppd = getPlayerData(sp)
        startSpeedrunTimer(ppd)
        syncChallengesToPlayer(sp)
        syncProgressToPlayer(sp, true)
        if DCS_Leaderboard and DCS_Leaderboard.reset then DCS_Leaderboard.reset() end
        DCS_Leaderboard.broadcast()
        DCS_dprint("[DCS] Debug resetAll (SP): full wipe + re-init")
    else
        local gmd = ModData.getOrCreate("DCS_Global")
        gmd.debugResetVersion = (gmd.debugResetVersion or 0) + 1
        gmd.debugResetType = "resetAll"
        ModData.transmit("DCS_Global")
        local store = ModData.getOrCreate("DCS_PlayerStore")
        local count = 0
        for _, p in ipairs(getAllPlayers()) do
            if store.players then store.players[p:getUsername()] = nil end
            p:getModData().DCS = nil
            local ppd = getPlayerData(p)
            startSpeedrunTimer(ppd)
            ppd.dataVersion = gmd.debugResetVersion
            syncChallengesToPlayer(p)
            syncProgressToPlayer(p, true)
            count = count + 1
            DCS_dprint("[DCS] Debug resetAll: " .. tostring(p:getUsername()) .. " - wiped and re-initialised")
        end
        local onlineUsernames = {}
        for _, p in ipairs(getAllPlayers()) do
            onlineUsernames[p:getUsername()] = true
        end
        if store.players then
            for uname, _ in pairs(store.players) do
                if not onlineUsernames[uname] then
                    local freshPd = defaultPlayerData()
                    freshPd.dataVersion = gmd.debugResetVersion
                    store.players[uname] = freshPd
                    DCS_dprint("[DCS] Debug resetAll: " .. uname .. " (offline) - store entry reset")
                end
            end
        end
        DCS_dprint("[DCS] Debug resetAll: wiped for " .. count .. " connected player(s), reset for offline players (pending full reset on next login)")
        if DCS_Leaderboard and DCS_Leaderboard.reset then
            DCS_Leaderboard.reset()
            DCS_dprint("[DCS] Debug resetAll: leaderboard wiped")
        end
        DCS_dprint("[DCS] Debug resetAll: full sync sent")
    end
end

local function cmdForceChallenge(player, args)
    local chId = args.challengeId
    local slot = args.slot
    if not chId or not slot or slot < 1 or slot > #todayChallenges then
        DCS_dprint("[DCS] Debug forceChallenge: invalid args (chId=" .. tostring(chId) .. " slot=" .. tostring(slot) .. ")")
        return
    end
    local ch = DCS_Challenges.Lookup[chId]
    if not ch then
        DCS_dprint("[DCS] Debug forceChallenge: unknown challenge ID: " .. tostring(chId))
        return
    end
    local oldId = todayChallenges[slot] and todayChallenges[slot].id or "nil"
    todayChallenges[slot] = ch
    local gmd = ModData.getOrCreate("DCS_Global")
    gmd.todayChallengeIDs[slot] = ch.id
    ModData.transmit("DCS_Global")
    syncChallengesToPlayer(player)
    DCS_dprint("[DCS] Debug forceChallenge: " .. tostring(player:getUsername()) ..
          " replaced slot " .. slot .. " (" .. oldId .. ") -> " .. ch.id)
end

local function cmdGrantAdmin(player, args)
    local targetName = player:getUsername()
    local adminRole = nil
    local roles = getRoles()
    for i = 0, roles:size() - 1 do
        local role = roles:get(i)
        if role and role.getName and role:getName() == "admin" then
            adminRole = role
            break
        end
    end
    if not adminRole then
        print("[DCS] Debug grantAdmin FAILED: could not find 'admin' role")
    else
        player:setRole(adminRole)
        DCS_dprint("[DCS] Debug grantAdmin: " .. targetName .. " granted admin (in-memory, session only)")
    end
end

local function cmdCompleteAndNext(player, args)
    local pd = getPlayerData(player)
    local uncompleted = {}
    for _, ch in ipairs(todayChallenges) do
        if ch and not pd.dailyCompleted[ch.id] then
            uncompleted[#uncompleted + 1] = ch
        end
    end
    if #uncompleted > 0 then
        local pick = uncompleted[dcsRandom:random(1, #uncompleted)]
        completeChallenge(player, pick.id)
        syncProgressToPlayer(player)
        DCS_dprint("[DCS] Debug completeAndNext: completed " .. pick.id .. " for " .. tostring(player:getUsername()))
    else
        DCS_dprint("[DCS] Debug completeAndNext: all challenges already completed, skipping completion")
    end
    local oldOffset = forcedDayOffset
    forcedDayOffset = forcedDayOffset + 1
    pd.dailyCompleted = {}
    pd.dailyKills = 0
    pd.killsResetDay = ""
    pd.dailyKillsByWeapon = {}
    pd.killsByWeaponResetDay = ""
    pd.dailyProgress = {}
    pd.progressResetDay = ""
    pd.bonusAwardedDay = ""
    DCS_dprint("[DCS] Debug completeAndNext: " .. tostring(player:getUsername()) .. " offset " .. oldOffset .. " -> " .. forcedDayOffset)
    DCS_Server.onDailyReset()
    local newToday = getEffectiveDateString()
    pd.challengeStartDay = newToday
    pd.challengeStartTime = os.time()
    DCS_dprint("[DCS] Debug completeAndNext: speedrun timer re-initialized startDay=" .. newToday .. " startTime=" .. fmtClock(pd.challengeStartTime))
    syncChallengesToPlayer(player)
    syncProgressToPlayer(player, true)
    DCS_dprint("[DCS] Debug completeAndNext: onDailyReset completed")
end

local function cmdCompleteAllChallenges(player, args)
    local pd = getPlayerData(player)
    local count = 0
    for _, ch in ipairs(todayChallenges) do
        if ch and not pd.dailyCompleted[ch.id] then
            completeChallenge(player, ch.id)
            count = count + 1
        end
    end
    syncProgressToPlayer(player)
    DCS_dprint("[DCS] Debug completeAllChallenges: completed " .. count .. " challenge(s) for " .. tostring(player:getUsername()))
end

local ACTION_HANDLERS = {
    clearTokens = cmdClearTokens,
    addToken = cmdAddToken,
    clearProgress = cmdClearProgress,
    forceNextDay = cmdForceNextDay,
    testSeal = cmdTestSeal,
    objectStateCheck = cmdObjectStateCheck,
    forceRePlaceObjects = cmdForceRePlaceObjects,
    resetLeaderboard = cmdResetLeaderboard,
    resetAll = cmdResetAll,
    forceChallenge = cmdForceChallenge,
    grantAdmin = cmdGrantAdmin,
    completeAndNext = cmdCompleteAndNext,
    completeAllChallenges = cmdCompleteAllChallenges,
    resetAllUser = cmdResetAllUser,
    clearTokensUser = cmdClearTokensUser,
    clearProgressUser = cmdClearProgressUser,
    setTokensUser = cmdSetTokensUser,
    addTokenToAll = cmdAddTokenToAll,
}

local function handleDebugCmd(player, args)
    if not args or not args.action then return end
    local action = args.action

    local isDebugTier = DEBUG_TIER[action] == true
    local accessOK
    if isDebugTier then
        accessOK = hasDebugCmdAccess(player)
    else
        accessOK = hasAdminCmdAccess(player)
    end
    DCS_dprint("[DCS] debugCmd access: action=" .. tostring(action) ..
          " tier=" .. (isDebugTier and "debug" or "admin") ..
          " user=" .. tostring(player:getUsername()) ..
          " ok=" .. tostring(accessOK))
    if not accessOK then
        print("[DCS] debugCmd rejected: insufficient access for " ..
              tostring(player:getUsername()) .. " action=" .. tostring(action))
        return
    end

    local handler = ACTION_HANDLERS[action]
    if handler then handler(player, args) end
end

local function handleSaveWindowPos(player, args)
    if not args or not args.window then return end
    local pd = getPlayerData(player)
    local key = args.window .. "X"
    local keyY = args.window .. "Y"
    pd[key] = tonumber(args.x) or 0
    pd[keyY] = tonumber(args.y) or 0
    DCS_dprint("[DCS] saveWindowPos: " .. args.window .. " = (" .. pd[key] .. ", " .. pd[keyY] .. ")")
end

local function handleReportKills(player, args)
    DCS_dprint("[DCS] reportKills handler reached: isHost=" .. tostring(isHost()) .. " kills=" .. tostring(args and args.kills) .. " day=" .. tostring(args and args.day))
    if not args or not args.kills then return end
    local pd = getPlayerData(player)
    local today = getEffectiveDateString()
    if pd.killsResetDay ~= today then
        pd.dailyKills = 0
        pd.killsResetDay = today
    end
    pd.dailyKills = pd.dailyKills + (tonumber(args.kills) or 0)
    DCS_dprint("[DCS] SP reportKills: player=" .. tostring(player:getUsername()) .. " dailyKills=" .. pd.dailyKills)

    if args.weaponKills then
        if pd.killsByWeaponResetDay ~= today then
            pd.dailyKillsByWeapon = {}
            pd.killsByWeaponResetDay = today
        end
        for wType, count in pairs(args.weaponKills) do
            pd.dailyKillsByWeapon[wType] = (pd.dailyKillsByWeapon[wType] or 0) + count
            DCS_dprint("[DCS] SP reportKills weapon: " .. wType .. " +" .. count .. " total=" .. pd.dailyKillsByWeapon[wType])
        end
    end

    if args.weaponCategories then
        if pd.killsByCategoryResetDay ~= today then
            pd.dailyKillsByCategory = {}
            pd.killsByCategoryResetDay = today
        end
        for wCat, count in pairs(args.weaponCategories) do
            pd.dailyKillsByCategory[wCat] = (pd.dailyKillsByCategory[wCat] or 0) + count
            DCS_dprint("[DCS] SP reportKills category: " .. wCat .. " +" .. count .. " total=" .. pd.dailyKillsByCategory[wCat])
        end
    end

    local challengeCompleted = false
    for _, ch in ipairs(todayChallenges) do
        if ch.type == "killZombies"
        and not pd.dailyCompleted[ch.id]
        and pd.dailyKills >= ch.target then
            completeChallenge(player, ch.id)
            challengeCompleted = true
        end
    end

    for _, ch in ipairs(todayChallenges) do
        if ch.type == "killWithWeapon"
        and not pd.dailyCompleted[ch.id] then
            local count = pd.dailyKillsByWeapon[ch.weaponType] or 0
            if count >= ch.target then
                completeChallenge(player, ch.id)
                challengeCompleted = true
            end
        end
    end

    for _, ch in ipairs(todayChallenges) do
        if ch.type == "killWithCategory"
        and not pd.dailyCompleted[ch.id] then
            local count = pd.dailyKillsByCategory[ch.weaponType] or 0
            if count >= ch.target then
                completeChallenge(player, ch.id)
                challengeCompleted = true
            end
        end
    end

    if not challengeCompleted then
        syncProgressToPlayer(player)
    end
end

local function handleReportWeaponKill(player, args)
    if not args then return end
    local weaponTypes = args.weaponTypes or {}
    local weaponCategories = args.weaponCategories or {}
    if #weaponTypes == 0 and #weaponCategories == 0 then return end
    local pd = getPlayerData(player)
    local today = getEffectiveDateString()

    if pd.killsByWeaponResetDay ~= today then
        pd.dailyKillsByWeapon = {}
        pd.killsByWeaponResetDay = today
    end
    for _ in pairs(weaponCategories) do
        if pd.killsByCategoryResetDay ~= today then
            pd.dailyKillsByCategory = {}
            pd.killsByCategoryResetDay = today
            break
        end
    end

    local challengeCompleted = false
    for _, wt in ipairs(weaponTypes) do
        for _, ch in ipairs(todayChallenges) do
            if ch.type == "killWithWeapon"
            and not pd.dailyCompleted[ch.id]
            and ch.weaponType == wt then
                local count = pd.dailyKillsByWeapon[wt] or 0
                if count >= ch.target then
                    completeChallenge(player, ch.id)
                    challengeCompleted = true
                end
            end
        end
    end

    for _, wc in ipairs(weaponCategories) do
        for _, ch in ipairs(todayChallenges) do
            if ch.type == "killWithCategory"
            and not pd.dailyCompleted[ch.id]
            and ch.weaponType == wc then
                local count = pd.dailyKillsByCategory[wc] or 0
                if count >= ch.target then
                    completeChallenge(player, ch.id)
                    challengeCompleted = true
                end
            end
        end
    end

    if not challengeCompleted then
        syncProgressToPlayer(player)
    end
end

local function handleReportLocation(player, args)
    DCS_dprint("[DCS] reportLocation handler reached: isHost=" .. tostring(isHost()) .. " challengeId=" .. tostring(args and args.challengeId))
    if not args or not args.challengeId then return end
    local ch = DCS_Challenges.Lookup[args.challengeId]
    if not ch then return end
    if ch.type ~= "visitLocation" and ch.type ~= "questDeliver" then return end

    if ch.type == "questDeliver" then
        local inv = player:getInventory()
        local count = countQuestItemVariants(inv, ch)
        DCS_dprint("[DCS] questDeliver: itemId=" .. ch.itemId .. " have=" .. count .. " need=" .. ch.count)
        if count < ch.count then
            DCS_dprint("[DCS] questDeliver: FAIL — not enough items (have=" .. count .. " need=" .. ch.count .. ")")
            return
        end
        local removed, removedCount = removeQuestItems(inv, player, ch.itemVariants or { ch.itemId }, ch.count)
        DCS_dprint("[DCS] questDeliver: removed " .. removedCount .. " items")
        for i, it in ipairs(removed) do
            DCS_dprint("[DCS]   removed[" .. i .. "]=" .. tostring(it) .. " fullType=" .. tostring(it and it.getFullType and it:getFullType() or "?"))
        end
        if removedCount < ch.count then
            DCS_dprint("[DCS] questDeliver: FAIL — removed " .. removedCount .. " < needed " .. ch.count)
            return
        end
        DCS_dprint("[DCS] questDeliver: SUCCESS — removed " .. removedCount .. " x " .. ch.itemId)
    end

    DCS_dprint("[DCS] reportLocation: player=" .. tostring(player:getUsername()) .. " id=" .. args.challengeId)
    completeChallenge(player, args.challengeId)
end

local function handleReportChallengeProgress(player, args)
    DCS_dprint("[DCS] reportChallengeProgress received: args=" .. tostring(args and args.challengeId) .. " amount=" .. tostring(args and args.amount))
    if not args or not args.challengeId then return end

    local ch, inToday = nil, false
    for _, tc in ipairs(todayChallenges) do
        if tc.id == args.challengeId then ch, inToday = tc, true; break end
    end
    if not inToday then
        print("[DCS] reportChallengeProgress: " .. tostring(args.challengeId) .. " not in today's list — rejected")
        return
    end

    local pd = getPlayerData(player)
    local today = getEffectiveDateString()

    if pd.progressResetDay ~= today then
        pd.dailyCompleted = {}
        pd.dailyProgress = {}
        pd.progressResetDay = today
    end

    local cap = ch.maxPerReport or 1
    local amount = math.min(math.max(tonumber(args.amount) or 1, 1), cap)
    pd.dailyProgress[args.challengeId] = (pd.dailyProgress[args.challengeId] or 0) + amount

    local current = pd.dailyProgress[args.challengeId]
    local target = ch.target or 1
    DCS_dprint("[DCS] reportChallengeProgress: player=" .. tostring(player:getUsername())
        .. " id=" .. args.challengeId .. " progress=" .. current .. "/" .. target)

    if current >= target then
        completeChallenge(player, ch.id)
    else
        syncProgressToPlayer(player)
    end
end

local function handleReportChallengeNPC(player, args)
    if not args or not args.challengeId then return end
    local ch = DCS_Challenges.Lookup[args.challengeId]
    if not ch then
        DCS_dprint("[DCS] reportChallengeNPC: unknown challengeId=" .. tostring(args.challengeId))
        return
    end

    local inToday = false
    for _, tc in ipairs(todayChallenges) do
        if tc.id == args.challengeId then inToday = true; break end
    end
    if not inToday then
        print("[DCS] reportChallengeNPC: " .. args.challengeId .. " not in today's list — rejected")
        return
    end

    local pd = getPlayerData(player)
    if pd.dailyCompleted[args.challengeId] then
        DCS_dprint("[DCS] reportChallengeNPC: " .. args.challengeId .. " already completed by " .. tostring(player:getUsername()))
        return
    end

    if ch.type == "questDeliver" then
        local inv = player:getInventory()
        local count = countQuestItemVariants(inv, ch)
        DCS_dprint("[DCS] reportChallengeNPC questDeliver: itemId=" .. ch.itemId
            .. " have=" .. count .. " need=" .. ch.count)
        if count < ch.count then
            DCS_dprint("[DCS] reportChallengeNPC: FAIL — not enough items for " .. tostring(player:getUsername()))
            return
        end
        local removed, removedCount = removeQuestItems(inv, player, ch.itemVariants or { ch.itemId }, ch.count)
        DCS_dprint("[DCS] reportChallengeNPC: removed " .. removedCount .. " items")
        if removedCount < ch.count then
            DCS_dprint("[DCS] reportChallengeNPC: FAIL — removed " .. removedCount .. " < needed " .. ch.count)
            return
        end
    end

    DCS_dprint("[DCS] reportChallengeNPC: completing " .. args.challengeId
        .. " for " .. tostring(player:getUsername()))
    completeChallenge(player, args.challengeId)
end

local function handlePurchaseItem(player, args)
    if not args or not args.itemId then return end
    if not isShopItemEnabled(args.itemId) then return end
    local pd = getPlayerData(player)
    local quantity = tonumber(args.quantity) or 1
    if quantity <= 0 then return end

    local resolved = resolveShopItem(args.itemId)
    if not resolved then return end
    local cost = resolved.cost or 0
    local stock = getShopStock()
    local available = stock[args.itemId] or 0
    local totalCost = cost * quantity

    if pd.currency >= totalCost and available >= quantity then
        pd.currency = pd.currency - totalCost
        syncWallet(pd)
        if DCS_Leaderboard and DCS_Leaderboard.updateTokens then
            DCS_Leaderboard.updateTokens(player, getPlayerDisplayName(player), pd.currency)
        end
        stock[args.itemId] = available - quantity
        local inventory = player:getInventory()
        inventory:setDrawDirty(true)
        for i = 1, quantity do
            local item = inventory:AddItem(args.itemId)
            if item and sendAddItemToContainer then
                sendAddItemToContainer(inventory, item)
            end
        end
        sendToClient(player, "purchaseResult", {
            success = true,
            newTotal = pd.currency,
            itemId = args.itemId,
            quantity = quantity,
        })
        broadcastShopStock()
    else
        sendToClient(player, "purchaseResult", {
            success = false,
            newTotal = pd.currency,
        })
    end
end

local function handleGetPlayersData(player, args)
    local accessOK = (DCS_Env.isHost() and player == getSpecificPlayer(0))
            or (DCS_Env.isSP() and ((getCore() and getCore():getDebug()) or isModAuthor(player)))
    if not accessOK then
        accessOK = getCore and getCore():getDebug()
    end
    if not accessOK then
        accessOK = playerHasAdminTool(player)
    end
    if not accessOK then
        print("[DCS] getPlayersData rejected: insufficient access for " .. tostring(player:getUsername()))
        return
    end
    local playersData = {}
    local store = ModData.getOrCreate("DCS_PlayerStore")
    for uname, pd in pairs(store.players or {}) do
        if pd then
            playersData[#playersData + 1] = {
                username = uname,
                data = {
                    currency = pd.currency or 0,
                    streak = pd.streak or 0,
                    streakLevel = pd.streakLevel or 0,
                    lifetimeCompleted = pd.lifetimeCompleted or 0,
                    dailyCompleted = pd.dailyCompleted or {},
                    dailyKills = pd.dailyKills or 0,
                },
            }
        end
    end
    sendToClient(player, "playersData", {
        players = playersData,
    })
    local names = {}
    for _, e in ipairs(playersData) do names[#names + 1] = e.username end
    DCS_dprint("[DCS] getPlayersData: DCS_PlayerStore has " .. #playersData
        .. " player(s) [" .. table.concat(names, ", ") .. "] -> sent to "
        .. tostring(player:getUsername()))
end

local function handleShopAdminApply(player, args)
    local accessOK = (DCS_Env.isHost() and player == getSpecificPlayer(0))
            or (DCS_Env.isSP() and ((getCore() and getCore():getDebug()) or isModAuthor(player)))
    if not accessOK then
        accessOK = getCore and getCore():getDebug()
    end
    if not accessOK then
        accessOK = playerHasAdminTool(player)
    end
    if not accessOK then
        accessOK = isModAuthor(player)
    end
    if not accessOK then
        print("[DCS] shopAdminApply rejected: insufficient access for " .. tostring(player:getUsername()))
        return
    end
    if not args then return end

    local gmd = ModData.getOrCreate("DCS_Global")
    if not gmd.shopConfig then
        gmd.shopConfig = { enabledItems = {}, customCosts = {}, customStock = {} }
    end

    if args.enabledItems and type(args.enabledItems) == "table" then
        gmd.shopConfig.enabledItems = args.enabledItems
    end

    if args.customCosts and type(args.customCosts) == "table" then
        for itemId, cost in pairs(args.customCosts) do
            if cost then
                gmd.shopConfig.customCosts[itemId] = cost
            else
                gmd.shopConfig.customCosts[itemId] = nil
            end
        end
    end

    if args.customStock and type(args.customStock) == "table" then
        for itemId, range in pairs(args.customStock) do
            if range then
                gmd.shopConfig.customStock[itemId] = range
            else
                gmd.shopConfig.customStock[itemId] = nil
            end
        end
    end

    ModData.transmit("DCS_Global")

    randomizeShopStock()
    broadcastShopStock()
    broadcastShopConfig()

    DCS_dprint("[DCS] shopAdminApply: " .. tostring(player:getUsername()) .. " applied shop config changes")
end

local function handleApplyDCSSettings(player, args)
    local accessOK = (DCS_Env.isHost() and player == getSpecificPlayer(0))
            or (DCS_Env.isSP() and ((getCore() and getCore():getDebug()) or isModAuthor(player)))
    if not accessOK then accessOK = getCore and getCore():getDebug() end
    if not accessOK then accessOK = playerHasAdminTool(player) end
    if not accessOK then accessOK = isModAuthor(player) end
    if not accessOK then
        print("[DCS] applyDCSSettings rejected: insufficient access for " .. tostring(player:getUsername()))
        return
    end
    if not args then return end

    local gmd = ModData.getOrCreate("DCS_Global")
    gmd.dcsSettings = gmd.dcsSettings or {}
    if args.tokensPersistDeath ~= nil then
        gmd.dcsSettings.tokensPersistDeath = args.tokensPersistDeath == true
    end
    if args.challengeProgressPersistDeath ~= nil then
        gmd.dcsSettings.challengeProgressPersistDeath = args.challengeProgressPersistDeath == true
    end
    local shopChanged = false
    if args.limitShopItems ~= nil then
        local oldEffective = dcsSetting("limitShopItems")
        gmd.dcsSettings.limitShopItems = args.limitShopItems == true
        if gmd.dcsSettings.limitShopItems ~= oldEffective then shopChanged = true end
    end
    ModData.transmit("DCS_Global")

    broadcastShopConfig()
    if shopChanged then
        randomizeShopStock()
        broadcastShopStock()
    end

    DCS_dprint("[DCS] applyDCSSettings: " .. tostring(player:getUsername())
        .. " tokensPersistDeath=" .. tostring(args.tokensPersistDeath)
        .. " limitShopItems=" .. tostring(args.limitShopItems)
        .. " challengeProgressPersistDeath=" .. tostring(args.challengeProgressPersistDeath)
        .. " shopChanged=" .. tostring(shopChanged))
end

local function handleToggleDefaultItems(player, args)
    local accessOK = (DCS_Env.isHost() and player == getSpecificPlayer(0))
            or (DCS_Env.isSP() and ((getCore() and getCore():getDebug()) or isModAuthor(player)))
    if not accessOK then accessOK = getCore and getCore():getDebug() end
    if not accessOK then accessOK = playerHasAdminTool(player) end
    if not accessOK then accessOK = isModAuthor(player) end
    if not accessOK then
        print("[DCS] toggleDefaultItems rejected: insufficient access for " .. tostring(player:getUsername()))
        return
    end
    if not args then return end

    local gmd = ModData.getOrCreate("DCS_Global")
    if not gmd.shopConfig then
        gmd.shopConfig = { enabledItems = {}, customCosts = {}, customStock = {} }
    end

    local enable = args.enable
    local defaultIds = {}
    for _, item in ipairs(DCS_Challenges.Shop or {}) do
        defaultIds[item.itemId] = true
    end

    if enable then
        local added = 0
        for _, item in ipairs(DCS_Challenges.Shop or {}) do
            local found = false
            for _, id in ipairs(gmd.shopConfig.enabledItems) do
                if id == item.itemId then found = true; break end
            end
            if not found then
                gmd.shopConfig.enabledItems[#gmd.shopConfig.enabledItems + 1] = item.itemId
                added = added + 1
            end
        end
        DCS_dprint("[DCS_SHOP] toggleDefaultItems: ENABLED - added " .. added .. " default items")
    else
        local kept = {}
        for _, id in ipairs(gmd.shopConfig.enabledItems) do
            if not defaultIds[id] then
                kept[#kept + 1] = id
            end
        end
        local removed = #gmd.shopConfig.enabledItems - #kept
        gmd.shopConfig.enabledItems = kept
        DCS_dprint("[DCS_SHOP] toggleDefaultItems: DISABLED - removed " .. removed .. " default items")
    end

    ModData.transmit("DCS_Global")
    randomizeShopStock()
    broadcastShopStock()
    broadcastShopConfig()
    sendToClient(player, "toggleDefaultItemsResult", { enabled = enable })
end

local function handleBackupDCS(player, args)
    local accessOK = playerHasAdminTool(player)
    if not accessOK and not isModAuthor(player) then
        print("[DCS] backupDCS rejected: insufficient access for " .. tostring(player:getUsername()))
        return
    end
    if DCS_Backup and DCS_Backup.export then
        local ok, filename = DCS_Backup.export()
        if ok then
            sendToClient(player, "dcsBackupResult", { success = true, message = "Backup Saved:\nC:\\Users\\[PCNAME]\\Zomboid\n\\Lua\\DailyChallengeSystem", filename = filename })
        else
            sendToClient(player, "dcsBackupResult", { success = false, message = "Backup failed — see server log" })
        end
    else
        print("[DCS] backupDCS: DCS_Backup module not loaded")
        sendToClient(player, "dcsBackupResult", { success = false, message = "DCS_Backup module not available" })
    end
end

local function handleListBackups(player, args)
    DCS_dprint("[DCS] listBackups: Received request from " .. tostring(player:getUsername()))
    local accessOK = playerHasAdminTool(player)
    if not accessOK and not isModAuthor(player) then
        DCS_dprint("[DCS] listBackups: Access denied for " .. tostring(player:getUsername()))
        return
    end
    if DCS_Backup and DCS_Backup.listFiles then
        local backups = DCS_Backup.listFiles()
        DCS_dprint("[DCS] listBackups: Sending " .. #backups .. " backups to client")
        sendToClient(player, "backupList", { backups = backups })
    else
        print("[DCS] listBackups: DCS_Backup module not available")
        sendToClient(player, "backupList", { backups = {} })
    end
end

local function handleRestoreDCS(player, args)
    local accessOK = playerHasAdminTool(player)
    if not accessOK and not isModAuthor(player) then
        if DCS_Env.isSP() and getCore and getCore():getDebug() then
            accessOK = true
        end
    end
    if not accessOK and not isModAuthor(player) then
        print("[DCS] restoreDCS rejected: insufficient access for " .. tostring(player:getUsername()))
        return
    end
    local filename = args and args.filename
    if not filename or filename == "" then
        sendToClient(player, "dcsRestoreResult", { success = false, message = "No backup file specified" })
        return
    end
    if DCS_Backup and DCS_Backup.import then
        DCS_dprint("[DCS] restoreDCS: calling import(" .. filename .. ")")
        local ok, msg = DCS_Backup.import(filename)
        DCS_dprint("[DCS] restoreDCS: import returned ok=" .. tostring(ok) .. " msg=" .. tostring(msg))
        if ok then
            local players = getAllPlayers()
            DCS_dprint("[DCS] restoreDCS: syncing " .. tostring(#players) .. " player(s)")
            for _, p in ipairs(players) do
                local uname = p:getUsername()
                local pd = getPlayerData(p)
                DCS_dprint("[DCS] restoreDCS: syncPlayer " .. uname
                    .. " currency=" .. tostring(pd.currency)
                    .. " streak=" .. tostring(pd.streak)
                    .. " dailyCompleted=" .. tostring(pd.dailyCompleted and "table" or "nil"))
                syncChallengesToPlayer(p)
                syncProgressToPlayer(p, true)
                syncShopStockToPlayer(p)
            end
            if DCS_Leaderboard and DCS_Leaderboard.broadcast then
                DCS_Leaderboard.broadcast()
            end
            sendToClient(player, "dcsRestoreResult", { success = true, message = "Restore complete: " .. tostring(msg) .. " player(s)" })
        else
            sendToClient(player, "dcsRestoreResult", { success = false, message = msg or "Restore failed" })
        end
    else
        print("[DCS] restoreDCS: DCS_Backup module not loaded")
        sendToClient(player, "dcsRestoreResult", { success = false, message = "DCS_Backup module not available" })
    end
end

local function handleRequestSync(player, args)
    if not todaySeed then
        DCS_dprint("[DCS] requestSync: todaySeed nil — calling onServerStarted()")
        onServerStarted()
    end
    DCS_dprint("[DCS] requestSync: todaySeed=" .. tostring(todaySeed) .. " challenges=" .. tostring(#todayChallenges) .. " player=" .. tostring(player:getUsername()))
    syncChallengesToPlayer(player)
    syncProgressToPlayer(player, false, true)
    syncShopStockToPlayer(player)
    syncShopConfigToPlayer(player)
    if DCS_Leaderboard and DCS_Leaderboard.syncToPlayer then
        DCS_Leaderboard.syncToPlayer(player)
    end
    if DCS_NPC and DCS_NPC.checkProximityAndSpawn then
        local newSpawns = DCS_NPC.checkProximityAndSpawn({ player })
        if newSpawns > 0 and DCS_NPC.getSpawnedNPCData then
            local npcData = DCS_NPC.getSpawnedNPCData()
            DCS_dprint("[DCS] requestSync: " .. newSpawns .. " NPC(s) spawned on player connect")
            sendToAllClients("syncObjects", { npcs = npcData })
        end
    end
    local pd = getPlayerData(player)
    local today = getEffectiveDateString()
    if pd.challengeStartDay ~= today then
        local prevStartDay = pd.challengeStartDay
        pd.challengeStartDay = today
        pd.speedrun1DoneToday = false
        pd.speedrun7DoneToday = false
        local yesterday = os.date("!%Y%m%d", os.time() - 86400)
        if prevStartDay == yesterday then
            pd.challengeStartTime = os.time() - (os.time() % 86400)
        else
            pd.challengeStartTime = os.time()
        end
        DCS_dprint("[DCS] Speedrun timer initialized (login) for " .. tostring(player:getUsername())
            .. " prevDay=" .. tostring(prevStartDay)
            .. " today=" .. today
            .. " startTime=" .. fmtClock(pd.challengeStartTime)
            .. " (" .. tostring(pd.challengeStartTime) .. ")")
    end
    if DCS_NPC and DCS_NPC.cleanupOrphans then
        local orphaned = DCS_NPC.cleanupOrphans()
        if orphaned > 0 then
            DCS_dprint("[DCS] requestSync: cleaned up " .. orphaned .. " orphaned NPC(s)")
        end
    end
    if DCS_NPC and DCS_NPC.checkProximityAndSpawn then
        local spawned = DCS_NPC.checkProximityAndSpawn({ player })
        if spawned > 0 then
            DCS_dprint("[DCS] requestSync: post-cleanup proximity spawn: " .. spawned .. " NPC(s)")
        end
    end
    if DCS_NPC and DCS_NPC.getSpawnedNPCData then
        local npcData = DCS_NPC.getSpawnedNPCData()
        local rawTL = DCS_NPC.getTraderLocations and DCS_NPC.getTraderLocations() or {}
        local traderLocations = {}
        if rawTL.east then traderLocations[#traderLocations + 1] = { side = "east", x = rawTL.east.x, y = rawTL.east.y, z = rawTL.east.z, name = rawTL.east.name } end
        if rawTL.west then traderLocations[#traderLocations + 1] = { side = "west", x = rawTL.west.x, y = rawTL.west.y, z = rawTL.west.z, name = rawTL.west.name } end
        DCS_dprint("[DCS] requestSync: sending syncObjects with " .. #npcData .. " NPC(s), " .. #traderLocations .. " trader locations to " .. tostring(player:getUsername()))
        for _, tl in ipairs(traderLocations) do
            DCS_dprint("[DCS]   traderLocation: side=" .. tl.side .. " name=" .. tl.name .. " x=" .. tl.x .. " y=" .. tl.y)
        end
        sendToClient(player, "syncObjects", { npcs = npcData, traderLocations = traderLocations })
    end
end

local COMMAND_HANDLERS = {
    requestSync = handleRequestSync,
    saveWindowPos = handleSaveWindowPos,
    reportKills = handleReportKills,
    reportWeaponKill = handleReportWeaponKill,
    reportLocation = handleReportLocation,
    reportChallengeProgress = handleReportChallengeProgress,
    reportChallengeNPC = handleReportChallengeNPC,
    purchaseItem = handlePurchaseItem,
    debugCmd = handleDebugCmd,
    getPlayersData = handleGetPlayersData,
    shopAdminApply = handleShopAdminApply,
    applyDCSSettings = handleApplyDCSSettings,
    toggleDefaultItems = handleToggleDefaultItems,
    backupDCS = handleBackupDCS,
    listBackups = handleListBackups,
    restoreDCS = handleRestoreDCS,
}

local function onClientCommand(module, command, player, args)
    if module ~= MOD_ID then return end
    local handler = COMMAND_HANDLERS[command]
    if handler then handler(player, args) end
end

local function onSPPlayerDeath(player)
    local md = player:getModData()
    if not md.DCS or not md.DCS._id then return end

    local wallet = ModData.getOrCreate("DCS_SP")
    if not wallet.history then wallet.history = {} end

    local charId = md.DCS._id
    for _, h in ipairs(wallet.history) do
        if h.id == charId then
            h.name = DCS_Identity.displayName(player)
            DCS_dprint("[DCS] onSPPlayerDeath: finalized history entry for " .. tostring(h.name)
                .. " (fastest1=" .. tostring(h.bestFastest1)
                .. " fastest7=" .. tostring(h.bestFastest7)
                .. " streak=" .. tostring(h.longestStreak) .. ")")
            break
        end
    end

    local persistTokens = dcsSetting("tokensPersistDeath")
    if not persistTokens then
        wallet.tokens = 0
        DCS_dprint("[DCS] onSPPlayerDeath: Tokens wiped (TokensPersistDeath=false)")
    end

    local persistProgress = dcsSetting("challengeProgressPersistDeath")
    if persistProgress then
        wallet.carriedProgress = {
            streak = md.DCS.streak,
            streakLevel = md.DCS.streakLevel,
            lastCompletedDay = md.DCS.lastCompletedDay,
            lifetimeCompleted = md.DCS.lifetimeCompleted,
            dailyCompleted = md.DCS.dailyCompleted,
            dailyKills = md.DCS.dailyKills,
            killsResetDay = md.DCS.killsResetDay,
            dailyKillsByWeapon = md.DCS.dailyKillsByWeapon,
            killsByWeaponResetDay = md.DCS.killsByWeaponResetDay,
            dailyKillsByCategory = md.DCS.dailyKillsByCategory,
            killsByCategoryResetDay = md.DCS.killsByCategoryResetDay,
            bonusAwardedDay = md.DCS.bonusAwardedDay,
            dailyProgress = md.DCS.dailyProgress,
            progressResetDay = md.DCS.progressResetDay,
            challengeStartDay = md.DCS.challengeStartDay,
            challengeStartTime = md.DCS.challengeStartTime,
            speedrun1DoneToday = md.DCS.speedrun1DoneToday,
            speedrun7DoneToday = md.DCS.speedrun7DoneToday,
        }
        DCS_dprint("[DCS] onSPPlayerDeath: Challenge progress snapshot saved to wallet")
    end

    md.DCS = nil
end

local function onMPPlayerDeath(player)
    local persistTokens = dcsSetting("tokensPersistDeath")
    if persistTokens then return end

    local gmd = ModData.getOrCreate("DCS_Global")
    local store = ModData.getOrCreate("DCS_PlayerStore")
    if not store.players then store.players = {} end
    local uname = player:getUsername() or "unknown"
    local pd = store.players[uname]
    if not pd then return end

    pd.currency = 0
    DCS_dprint("[DCS] onMPPlayerDeath: tokens wiped for " .. tostring(uname) .. " (TokensPersistDeath=false)")
    syncProgressToPlayer(player)
end

local function onCharacterDeath(character)
    if not DCS_Env.runsServerLogic() then return end
    if not (character and instanceof and instanceof(character, "IsoPlayer")) then return end
    if DCS_Env.isSP() then
        onSPPlayerDeath(character)
    else
        onMPPlayerDeath(character)
    end
end
Events.OnCharacterDeath.Add(onCharacterDeath)

Events.OnServerStarted.Add(function()
    DCS_dprint("[DCS] Events.OnServerStarted fired — calling onServerStarted()")
    onServerStarted()
end)
Events.OnInitGlobalModData.Add(onInitGlobalModData)
Events.OnClientCommand.Add(onClientCommand)
Events.OnZombieDead.Add(onZombieDead)
Events.EveryOneMinute.Add(onEveryOneMinute)
