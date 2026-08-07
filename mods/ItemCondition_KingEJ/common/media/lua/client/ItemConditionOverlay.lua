-- ItemConditionOverlay.lua
-- Item Condition Visual Indicator Mod for Project Zomboid Build 42
-- Author: KingEJ
-- Version: 1.2.0

-- Localized references for performance
local math_max = math.max
local math_min = math.min
local math_floor = math.floor
local math_abs = math.abs
local instanceof = instanceof

-- Cached text manager (initialized on first use)
local cachedTextManager = nil

-- Vanilla hotbar geometry, from ISHotbar:new(). These are hardcoded constants in
-- vanilla and never scale with resolution, which is why the hotbar looks tiny at
-- 1440p/4K while fonts (which DO scale with the font size option) overflow it.
local BASE_SLOT_WIDTH = 60
local BASE_SLOT_HEIGHT = 60

-- Backing colour for every bar. Deliberately not pure black: against a dark
-- inventory row a 0% bar drawn on black is indistinguishable from no bar at all, so
-- "empty" and "nothing here" looked identical. That matters now that fill-type items
-- keep their bar at any level, since being able to spot an empty canteen at a glance
-- is half the point.
local BAR_BG_R, BAR_BG_G, BAR_BG_B = 0.22, 0.22, 0.22

-- Global namespace
ItemConditionOverlay = ItemConditionOverlay or {}
ItemConditionOverlay.VERSION = "1.2.0"

-- Settings (configurable via Mod Options menu)
ItemConditionOverlay.Settings = {
    ammoCounterMode = "advanced",   -- "off" | "simple" | "advanced"
    ammoFontMode = "auto",          -- "auto" | "small" | "medium" | "large"
    showInInventory = true,         -- draw condition bars on inventory item icons
    showHotbarTooltips = true,      -- allow vanilla's hotbar item tooltip
    showFluidLevel = true,          -- draw fill level on canteens, bottles, buckets
    fluidUseOwnColor = true,        -- tint that bar with the fluid's colour
    alwaysShowFillBars = true,      -- keep fill bars visible in inventory when full
    hotbarScale = 1.0               -- 1.0 = vanilla 60px slots
}

-- Direct handle on the settings table. ItemConditionSettings.lua mutates these
-- fields in place and never replaces the table, so holding a local reference saves
-- a global lookup plus a table index on every item, every frame.
local Settings = ItemConditionOverlay.Settings

-- Battery powered electric lights. These get a white "battery" bar instead of a
-- condition-coloured bar. Fuel burning lights (hurricane lanterns, propane
-- lanterns, lighters, candles) are deliberately NOT listed here: they are ordinary
-- drainables and render through the drainable branch with a coloured fuel bar.
local FLASHLIGHT_TYPES = {
    Torch = true,
    HandTorch = true,
    FlashLight_AngleHead = true,
    FlashLight_AngleHead_Army = true,
    PenLight = true,
    Lantern_CraftedElectric = true,
    Flashlight_Crafted = true,
    GunLight = true
}

-- Reusable render data tables (reduces GC pressure)
local weaponCondCache = {
    handle = 0,
    head = 0,
    sharpness = 0,
    hasSharpness = false,
    hasHead = false,
    barCount = 1,
    useMultipleBars = false
}

local renderDataCache = {
    weaponCond = nil,
    percent = 100,
    isDamaged = false,
    isBattery = false,
    -- Set only for fluid containers, so the bar can be tinted with the fluid's own
    -- colour instead of the usual condition gradient
    tintR = nil,
    tintG = nil,
    tintB = nil
}

local ammoDataCache = {
    current = 0,
    max = 0,
    magAmmo = 0,
    chambered = 0,
    maxMag = 0,
    hasChamber = false
}

-- Cached texture dimensions
local equippedIconWidth = nil

--------------------------------------------------------------------------------
-- CONDITION DETECTION FUNCTIONS
--------------------------------------------------------------------------------

-- Get color based on condition percentage (local for hot path optimization)
local function getConditionColor(percent)
    if percent >= 75 then
        return 0.0, 1.0, 0.0  -- Green
    elseif percent >= 50 then
        return 1.0, 1.0, 0.0  -- Yellow
    elseif percent >= 25 then
        return 1.0, 0.5, 0.0  -- Orange
    else
        return 1.0, 0.0, 0.0  -- Red
    end
end

-- Export for external use
ItemConditionOverlay.getConditionColor = getConditionColor

-- Check if an item is a Build 42 weapon with Handle/Head/Sharpness
local function isBuild42Weapon(item)
    return instanceof(item, "HandWeapon") and item.getSharpness and item.getHeadCondition
end

ItemConditionOverlay.isBuild42Weapon = function(item)
    if not item then return false end
    return isBuild42Weapon(item)
end

-- Get Build 42 weapon condition values (reuses cached table).
-- isWeapon is supplied by the caller so the hot path can use the cached per-type
-- classification instead of paying for an instanceof on every item, every frame.
local function getBuild42WeaponCondition(item, isWeapon)
    if not (isWeapon and item.getSharpness and item.getHeadCondition) then
        return nil
    end

    local maxCond = item:getConditionMax()
    if not maxCond or maxCond <= 0 then
        return nil
    end

    local rawCondition = item:getCondition()
    local rawHeadCondition = item:getHeadCondition()
    local rawSharpness = item:getSharpness()

    if rawCondition == nil or rawHeadCondition == nil or rawSharpness == nil then
        return nil
    end

    local handle = math_max(0, (rawCondition / maxCond) * 100)
    local head = math_max(0, (rawHeadCondition / maxCond) * 100)
    local sharpness = math_max(0, rawSharpness * 100)

    local hasSharpness = sharpness > 0.01
    local hasHead = head > 0.01

    local barCount = 1
    if hasSharpness then barCount = barCount + 1 end
    if hasHead then barCount = barCount + 1 end

    -- Reuse cached table
    weaponCondCache.handle = handle
    weaponCondCache.head = head
    weaponCondCache.sharpness = sharpness
    weaponCondCache.hasSharpness = hasSharpness
    weaponCondCache.hasHead = hasHead
    weaponCondCache.barCount = barCount
    weaponCondCache.useMultipleBars = barCount > 1

    return weaponCondCache
end

-- Public accessor returns a COPY. The internal caches are shared mutable tables
-- reused on every item, so handing the live table to another mod would let it be
-- clobbered by the next item we render.
ItemConditionOverlay.getBuild42WeaponCondition = function(item)
    if not item then return nil end
    local c = getBuild42WeaponCondition(item, instanceof(item, "HandWeapon"))
    if not c then return nil end
    return {
        handle = c.handle,
        head = c.head,
        sharpness = c.sharpness,
        hasSharpness = c.hasSharpness,
        hasHead = c.hasHead,
        barCount = c.barCount,
        useMultipleBars = c.useMultipleBars
    }
end

--------------------------------------------------------------------------------
-- PER-TYPE CLASSIFICATION CACHE
--------------------------------------------------------------------------------

-- instanceof and getCategory are Java calls, and every answer they give is fixed by
-- the item's script type: a Base.Pistol is always a HandWeapon, a Base.Bread is
-- always Food. Previously this cost four instanceof calls plus a getCategory on
-- every item, every frame, which at 40 visible inventory items was ~180 Java class
-- checks per frame and was by far the mod's largest cost.
--
-- Classify once per item TYPE and cache it. Keyed on getFullType() ("Base.Pistol"),
-- which is module qualified and therefore cannot collide between mods that happen to
-- reuse a short type name.
local typeInfoCache = {}

local function getTypeInfo(item)
    local key = item.getFullType and item:getFullType() or nil
    if not key then
        key = item.getType and item:getType() or nil
        if not key then return nil end
    end

    local info = typeInfoCache[key]
    if info then
        return info
    end

    local shortType = item.getType and item:getType() or nil
    info = {
        -- Types that never have a meaningful condition bar
        skip = (instanceof(item, "InventoryContainer")
             or instanceof(item, "Food")
             or instanceof(item, "Literature")
             or item:getCategory() == "Key") and true or false,
        isWeapon = instanceof(item, "HandWeapon") and true or false,
        isDrainable = instanceof(item, "DrainableComboItem") and true or false,
        -- Only drainables and clothing can carry a charge (clothing because of gas
        -- masks and respirators with a filter fitted), so everything else can skip
        -- the getUsedDelta call entirely
        isClothing = instanceof(item, "Clothing") and true or false,
        isFlashlight = (shortType ~= nil and FLASHLIGHT_TYPES[shortType]) and true or false,
        -- Canteens, bottles and buckets are NOT drainables in B42. They carry a
        -- FluidContainer component and report their level in litres, which is why
        -- they never showed a bar before. Whether a type has one is fixed, so cache
        -- it rather than calling getFluidContainer() on every item every frame.
        hasFluid = (item.getFluidContainer and item:getFluidContainer() ~= nil) and true or false
    }
    typeInfoCache[key] = info
    return info
end

ItemConditionOverlay.isFlashlight = function(item)
    if not item then return false end
    local info = getTypeInfo(item)
    return info ~= nil and info.isFlashlight
end

-- Get render data for an item - returns nil if item shouldn't show a bar
-- isHotbar: true for hotbar (always show), false for inventory (only if damaged)
local function getItemRenderData(item, isHotbar)
    if not item then
        return nil
    end

    -- Broken state is per item, not per type, so it stays an every-frame check
    if item.isBroken and item:isBroken() then
        return nil
    end

    -- One cached lookup replaces four instanceof calls plus a getCategory
    local info = getTypeInfo(item)
    if not info or info.skip then
        return nil
    end

    -- Reset cached table
    renderDataCache.weaponCond = nil
    renderDataCache.percent = 100
    renderDataCache.isDamaged = false
    renderDataCache.isBattery = false
    renderDataCache.tintR = nil
    renderDataCache.tintG = nil
    renderDataCache.tintB = nil

    -- For a tool, no bar sensibly reads as "it's fine". For a canteen, a torch or a
    -- filter, no bar is ambiguous with "I can't tell", and full versus empty is
    -- exactly what you want to know. So fill-type items keep their bar in the
    -- inventory even at full, unless the user turns that off.
    local showWhenFull = Settings.alwaysShowFillBars

    -- Flashlights: show battery life (white bar) instead of condition
    if info.isFlashlight and item.getCurrentUsesFloat then
        local remaining = item:getCurrentUsesFloat()
        if remaining and remaining >= 0 then
            renderDataCache.percent = remaining * 100
            renderDataCache.isBattery = true
            if remaining < 1.0 then
                renderDataCache.isDamaged = true
            end
            if isHotbar or renderDataCache.isDamaged or showWhenFull then
                return renderDataCache
            end
        end
        return nil
    end

    -- Build 42 weapons with multi-bar display
    local weaponCond = getBuild42WeaponCondition(item, info.isWeapon)
    if weaponCond then
        renderDataCache.weaponCond = weaponCond
        renderDataCache.percent = weaponCond.handle
        if weaponCond.handle < 100 or
           (weaponCond.hasHead and weaponCond.head < 100) or
           (weaponCond.hasSharpness and weaponCond.sharpness < 100) then
            renderDataCache.isDamaged = true
        end
        if isHotbar or renderDataCache.isDamaged then
            return renderDataCache
        end
        return nil
    end

    -- Fill-type branches below are deliberately checked BEFORE plain condition. A
    -- handful of items have both a condition and a fill level (gas masks with a
    -- filter fitted, car batteries, electric shears, canteens). Checking condition
    -- first made those flip between showing wear and showing fill depending on
    -- whether they happened to be damaged, which is what made the gas mask filter
    -- look inconsistent as well as inverted.

    -- Fluid level (canteens, water bottles, buckets). These are NOT drainables in
    -- Build 42: they carry a FluidContainer component reporting an amount in litres
    -- against a capacity, which is why none of them ever showed a bar. Vanilla reads
    -- them the same way, e.g. ISButcherHookUI.lua:666.
    if Settings.showFluidLevel and info.hasFluid then
        local fc = item:getFluidContainer()
        if fc then
            local capacity = fc:getCapacity()
            if capacity and capacity > 0 then
                local amount = fc:getAmount() or 0
                renderDataCache.percent = (amount / capacity) * 100
                if amount < capacity then
                    renderDataCache.isDamaged = true
                end

                -- Decide visibility BEFORE fetching the colour, so a hidden bar
                -- (e.g. full canteen with the keep-when-full option off) costs no
                -- extra Java calls
                if not (isHotbar or renderDataCache.isDamaged or showWhenFull) then
                    return nil
                end

                -- Tint the bar with the fluid's own colour so you can tell water from
                -- petrol from bleach at a glance. A fill level tells you how much;
                -- the colour tells you what. Vanilla exposes the same colour it uses
                -- in its tooltips (ISFluidContainerPanel.lua:265).
                if Settings.fluidUseOwnColor and amount > 0 and fc.getColor then
                    local col = fc:getColor()
                    if col and col.getRedFloat then
                        local r, g, b = col:getRedFloat(), col:getGreenFloat(), col:getBlueFloat()
                        if r and g and b then
                            -- Some fluids are almost black, which would vanish against
                            -- the bar's dark backing. Lift those to stay readable
                            -- while keeping the hue.
                            local brightest = math_max(r, math_max(g, b))
                            if brightest < 0.35 then
                                local lift = 0.35 / math_max(brightest, 0.01)
                                r, g, b = math_min(1, r * lift), math_min(1, g * lift), math_min(1, b * lift)
                            end
                            renderDataCache.tintR, renderDataCache.tintG, renderDataCache.tintB = r, g, b
                        end
                    end
                end
                return renderDataCache
            end
        end
    end

    -- Charge level (respirator and gas mask filters, car batteries, electric
    -- shears, fuel lanterns). Read with getCurrentUsesFloat(), NOT getUsedDelta().
    --
    -- Verified in game on B42 stable: for a component-based item such as a respirator
    -- filter, getUsedDelta() does not return the charge and instanceof(item,
    -- "DrainableComboItem") answers false, so anything built on those drew no bar at
    -- all. getCurrentUsesFloat() works, which is both what the flashlight branch above
    -- already uses successfully and what vanilla itself uses to render its own
    -- "Remaining:" row (ISInventoryPane.lua:2648). getUsedDelta stays as a fallback
    -- for anything that only implements the older accessor.
    local remaining = nil
    if item.getCurrentUsesFloat then
        remaining = item:getCurrentUsesFloat()
    elseif item.getUsedDelta then
        remaining = item:getUsedDelta()
    end

    if remaining then
        -- A value strictly between empty and full is unambiguous evidence of a real
        -- charge. Exactly 0 or exactly 1 is ambiguous, because an ordinary item with
        -- no charge at all reports the same, so those defer to the cached class check
        -- rather than painting a bogus empty or full bar on every item in the game.
        if (remaining > 0 and remaining < 1) or info.isDrainable then
            renderDataCache.percent = remaining * 100
            if remaining < 1.0 then
                renderDataCache.isDamaged = true
            end
            if isHotbar or renderDataCache.isDamaged or showWhenFull then
                return renderDataCache
            end
            return nil
        end
    end

    -- Standard condition items (tools, weapons, clothing)
    if item.getCondition and item.getConditionMax then
        local max = item:getConditionMax()
        if max and max > 0 then
            local current = item:getCondition()
            if current then
                renderDataCache.percent = (current / max) * 100
                if current < max then
                    renderDataCache.isDamaged = true
                end
                if isHotbar or renderDataCache.isDamaged then
                    return renderDataCache
                end
            end
        end
    end

    return nil
end

-- Public accessor returns a COPY, for the same aliasing reason as above.
ItemConditionOverlay.getItemRenderData = function(item, isHotbar)
    local d = getItemRenderData(item, isHotbar)
    if not d then return nil end
    local copy = {
        percent = d.percent,
        isDamaged = d.isDamaged,
        isBattery = d.isBattery,
        tintR = d.tintR,
        tintG = d.tintG,
        tintB = d.tintB,
        weaponCond = nil
    }
    local c = d.weaponCond
    if c then
        copy.weaponCond = {
            handle = c.handle,
            head = c.head,
            sharpness = c.sharpness,
            hasSharpness = c.hasSharpness,
            hasHead = c.hasHead,
            barCount = c.barCount,
            useMultipleBars = c.useMultipleBars
        }
    end
    return copy
end

--------------------------------------------------------------------------------
-- AMMO COUNTER FUNCTIONS
--------------------------------------------------------------------------------

-- Get ammo data for a firearm (reuses cached table)
-- Returns nil if not a firearm or has no ammo capacity
local function getAmmoData(item)
    if not item then
        return nil
    end

    -- Check if firearm with ammo capacity (cached class check, single getMaxAmmo call)
    local info = getTypeInfo(item)
    if not info or not info.isWeapon or not item.getMaxAmmo then
        return nil
    end

    local maxMag = item:getMaxAmmo()
    if not maxMag or maxMag <= 0 then
        return nil
    end

    local magAmmo = item:getCurrentAmmoCount() or 0
    local chambered = (item.isRoundChambered and item:isRoundChambered()) and 1 or 0
    local hasChamber = item.haveChamber and item:haveChamber()

    -- Reuse cached table
    ammoDataCache.current = magAmmo + chambered
    ammoDataCache.max = maxMag + (hasChamber and 1 or 0)
    ammoDataCache.magAmmo = magAmmo
    ammoDataCache.chambered = chambered
    ammoDataCache.maxMag = maxMag
    ammoDataCache.hasChamber = hasChamber

    return ammoDataCache
end

-- Public accessor returns a COPY, for the same aliasing reason as above.
ItemConditionOverlay.getAmmoData = function(item)
    local a = getAmmoData(item)
    if not a then return nil end
    return {
        current = a.current,
        max = a.max,
        magAmmo = a.magAmmo,
        chambered = a.chambered,
        maxMag = a.maxMag,
        hasChamber = a.hasChamber
    }
end

-- Check if item is a firearm with ammo tracking (for external use)
ItemConditionOverlay.isFirearm = function(item)
    if not item then return false end
    return instanceof(item, "HandWeapon") and item.getMaxAmmo and item:getMaxAmmo() > 0
end

-- Format ammo text based on mode parameter
local function formatAmmoText(ammoData, mode)
    if mode == "advanced" and ammoData.hasChamber then
        return ammoData.magAmmo .. "+" .. ammoData.chambered .. "/" .. ammoData.maxMag
    else
        return ammoData.current .. "/" .. ammoData.max
    end
end

ItemConditionOverlay.formatAmmoText = function(ammoData)
    return formatAmmoText(ammoData, ItemConditionOverlay.Settings.ammoCounterMode)
end

--------------------------------------------------------------------------------
-- AMMO FONT SIZING
--------------------------------------------------------------------------------

-- Vanilla hotbar slots are a fixed 60px, but UIFont sizes scale with the user's
-- Font Size option. At the largest tier UIFont.Small renders at 38px, so the ammo
-- text outgrows the slot and bleeds into its neighbours.
--
-- Everything here is computed once and then memoised per slot. Font metrics are
-- fixed for the session, because changing Font Size calls resetLua()
-- (MainOptions.lua:1329) which reloads this file. The fitted text only changes when
-- the ammo count, display mode or slot width changes, so a steady-state frame costs
-- a few integer comparisons and allocates nothing.

local ammoFontLadder = nil   -- ascending by rendered height, de-duplicated
local outlineWidth = 1
local useHeavyOutline = false
local fontMetricsReady = false
local baseFontHeight = 19    -- UIFont.Small at the user's current Font Size tier

local function initFontMetrics()
    if fontMetricsReady then return end

    local tm = getTextManager()
    local smallHeight = tm:getFontHeight(UIFont.Small)
    if not smallHeight or smallHeight <= 0 then smallHeight = 19 end
    baseFontHeight = smallHeight

    -- Vanilla's own scale idiom, e.g. ISItemSlot.lua:10 divides by 19 to
    -- "normalize to 1080p". 1 at the 19px tier, 2 at the 38px tier.
    outlineWidth = math_max(1, math_floor(smallHeight / 19))
    -- A 1px drop shadow reads fine at 19px but disappears under a 38px glyph. Only
    -- pay for the four-way outline when it actually buys legibility.
    useHeavyOutline = outlineWidth > 1

    -- fonts.txt maps NewSmall/NewMedium/NewLarge to the very same .fnt files as
    -- Small/Medium/Large, so de-duplicate by height or we measure each font twice.
    local ladder = {}
    local seenHeight = {}
    local names = { "Small", "Medium", "Large", "NewSmall", "NewMedium", "NewLarge" }
    for i = 1, #names do
        local font = UIFont[names[i]]
        if font then
            local h = tm:getFontHeight(font)
            if h and h > 0 and not seenHeight[h] then
                seenHeight[h] = true
                ladder[#ladder + 1] = { font = font, height = h }
            end
        end
    end
    if #ladder == 0 then
        ladder[1] = { font = UIFont.Small, height = smallHeight }
    end
    table.sort(ladder, function(a, b) return a.height < b.height end)

    ammoFontLadder = ladder
    fontMetricsReady = true
end

local FONT_MODE_TO_NAME = {
    small = "Small",
    medium = "Medium",
    large = "Large"
}

-- Reused so building the candidate list allocates nothing
local ammoCandidates = {}

-- Progressively shorter ways to say the same thing, richest first. UIFont.Small is
-- the smallest font the game ships, so shrinking the font is not enough on its own:
-- "15+1/15" cannot fit a 60px slot at the 38px tier, and past that point we shorten
-- the string rather than bleed into the neighbouring slot.
local function buildAmmoCandidates(ammoData, mode)
    local n = 0
    if mode == "advanced" and ammoData.hasChamber then
        n = n + 1
        ammoCandidates[n] = ammoData.magAmmo .. "+" .. ammoData.chambered .. "/" .. ammoData.maxMag
    end
    n = n + 1
    ammoCandidates[n] = ammoData.current .. "/" .. ammoData.max
    n = n + 1
    ammoCandidates[n] = ammoData.current .. ""
    return n
end

-- Zooming a bitmap font interpolates the glyphs and looks noticeably soft next to
-- vanilla's crisp slot numbers, which are always drawn at a native size. So prefer a
-- genuinely larger FONT and only zoom for whatever is left over. Anything under this
-- much residual scaling snaps back to 1, trading a little size for a sharp glyph.
local ZOOM_SNAP_THRESHOLD = 1.5

-- Uncached fit. Only reached on a cache miss, i.e. when the ammo count changes.
-- Returns text, font, width at zoom 1, and the zoom to draw it at.
local function computeAmmoFit(ammoData, mode, maxWidth, targetHeight)
    initFontMetrics()

    local tm = getTextManager()
    local count = buildAmmoCandidates(ammoData, mode)
    local ladder = ammoFontLadder

    local forcedName = FONT_MODE_TO_NAME[Settings.ammoFontMode]
    local forcedFont = forcedName and UIFont[forcedName] or nil

    if forcedFont then
        -- User picked a size: honour it natively, shortening the text if forced to
        for i = 1, count do
            local text = ammoCandidates[i]
            local width = tm:MeasureStringX(forcedFont, text)
            if width <= maxWidth then
                return text, forcedFont, width, 1
            end
        end
        local text = ammoCandidates[count]
        return text, forcedFont, tm:MeasureStringX(forcedFont, text), 1
    end

    -- Auto. At vanilla hotbar size targetHeight equals UIFont.Small, so this picks
    -- Small at zoom 1 and looks exactly as it always has. On a scaled hotbar it
    -- climbs the ladder to a real larger font rather than stretching a small one.
    for i = 1, count do
        local text = ammoCandidates[i]
        for j = #ladder, 1, -1 do
            local entry = ladder[j]
            -- Never overshoot the target height by more than a hair
            if entry.height <= targetHeight * 1.08 then
                local width = tm:MeasureStringX(entry.font, text)
                if width <= maxWidth then
                    local zoom = targetHeight / entry.height
                    if zoom < ZOOM_SNAP_THRESHOLD then
                        zoom = 1          -- close enough: keep it sharp
                    elseif zoom > 3 then
                        zoom = 3
                    end
                    if width * zoom > maxWidth then
                        zoom = 1          -- zooming would overflow the slot
                    end
                    return text, entry.font, width, zoom
                end
            end
        end
    end

    -- Nothing fit at any size: smallest font, shortest string, no zoom
    local text = ammoCandidates[count]
    local font = ladder[1].font
    return text, font, tm:MeasureStringX(font, text), 1
end

-- Per-slot memo. Entries are allocated once per slot then mutated in place.
local ammoCache = {}

local function fitAmmoText(slotIndex, ammoData, mode, maxWidth, targetHeight)
    local c = ammoCache[slotIndex]
    if not c then
        c = { magAmmo = -1, chambered = -1, maxMag = -1, current = -1, max = -1,
              mode = false, maxWidth = -1, targetHeight = -1, fontMode = false,
              text = "", font = nil, width = 0, height = 0, zoom = 1 }
        ammoCache[slotIndex] = c
    end

    if c.current == ammoData.current
        and c.max == ammoData.max
        and c.magAmmo == ammoData.magAmmo
        and c.chambered == ammoData.chambered
        and c.maxMag == ammoData.maxMag
        and c.mode == mode
        and c.maxWidth == maxWidth
        and c.targetHeight == targetHeight
        and c.fontMode == Settings.ammoFontMode then
        return c.text, c.font, c.width, c.height, c.zoom
    end

    local text, font, width, zoom = computeAmmoFit(ammoData, mode, maxWidth, targetHeight)

    c.current = ammoData.current
    c.max = ammoData.max
    c.magAmmo = ammoData.magAmmo
    c.chambered = ammoData.chambered
    c.maxMag = ammoData.maxMag
    c.mode = mode
    c.maxWidth = maxWidth
    c.targetHeight = targetHeight
    c.fontMode = Settings.ammoFontMode
    c.text = text
    c.font = font
    c.width = width
    c.height = getTextManager():getFontHeight(font) or 0
    c.zoom = zoom

    return c.text, c.font, c.width, c.height, c.zoom
end

-- UIFont.Large is the biggest font the game ships, so on a scaled-up hotbar even
-- the largest font that "fits" still looks lost in the slot. drawTextZoomed can
-- scale text arbitrarily, but it has zero callers anywhere in vanilla, so the Java
-- overload behind it is unproven. Try it once and fall back permanently if it
-- throws, rather than assuming it works.
local textZoomSupported = nil   -- nil = untried, true/false once known

local function drawScaledText(ui, text, x, y, r, g, b, a, font, zoom)
    if zoom > 1.01 and textZoomSupported ~= false and ui.drawTextZoomed then
        if textZoomSupported == nil then
            local ok = pcall(ui.drawTextZoomed, ui, text, x, y, zoom, r, g, b, a, font)
            textZoomSupported = ok
            if ok then return end
        else
            ui:drawTextZoomed(text, x, y, zoom, r, g, b, a, font)
            return
        end
    end
    ui:drawText(text, x, y, r, g, b, a, font)
end

--------------------------------------------------------------------------------
-- RENDERING FUNCTIONS
--------------------------------------------------------------------------------

-- Draw a single condition bar
local function drawSingleBar(pane, x, y, w, percent, barHeight, isBattery, tintR, tintG, tintB)
    local r, g, b
    if tintR then
        -- Fluid containers paint in the fluid's own colour
        r, g, b = tintR, tintG, tintB
    elseif isBattery then
        r, g, b = 1.0, 1.0, 1.0
    else
        r, g, b = getConditionColor(percent)
    end

    pane:drawRect(x, y, w, barHeight, 1.0, BAR_BG_R, BAR_BG_G, BAR_BG_B)
    -- Clamp both ways: debug-edited condition (15/10), modded overfilled fluid or
    -- sharpness above 1.0 would otherwise draw the fill past the slot edge into the
    -- neighbouring slot
    local filledWidth = math_min(w, math_max(0, w * (percent / 100)))
    pane:drawRect(x, y, filledWidth, barHeight, 1.0, r, g, b)
end

-- Draw multiple condition bars for Build 42 weapons.
-- Fill widths are clamped to the bar width for the same reason as drawSingleBar:
-- modded values above 100% must not paint into the neighbouring slot.
local function drawMultiBar(pane, x, baseY, w, weaponCond, barHeight, barSpacing)
    local currentY = baseY

    if weaponCond.hasSharpness then
        local r, g, b = getConditionColor(weaponCond.sharpness)
        pane:drawRect(x, currentY, w, barHeight, 1.0, BAR_BG_R, BAR_BG_G, BAR_BG_B)
        local sharpWidth = math_min(w, math_max(0, w * (weaponCond.sharpness / 100)))
        pane:drawRect(x, currentY, sharpWidth, barHeight, 1.0, r, g, b)
        currentY = currentY + barHeight + barSpacing
    end

    local hr, hg, hb = getConditionColor(weaponCond.handle)
    pane:drawRect(x, currentY, w, barHeight, 1.0, BAR_BG_R, BAR_BG_G, BAR_BG_B)
    local handleWidth = math_min(w, math_max(0, w * (weaponCond.handle / 100)))
    pane:drawRect(x, currentY, handleWidth, barHeight, 1.0, hr, hg, hb)
    currentY = currentY + barHeight + barSpacing

    if weaponCond.hasHead then
        local headR, headG, headB = getConditionColor(weaponCond.head)
        pane:drawRect(x, currentY, w, barHeight, 1.0, BAR_BG_R, BAR_BG_G, BAR_BG_B)
        local headWidth = math_min(w, math_max(0, w * (weaponCond.head / 100)))
        pane:drawRect(x, currentY, headWidth, barHeight, 1.0, headR, headG, headB)
    end
end

--------------------------------------------------------------------------------
-- INVENTORY RENDERING
--------------------------------------------------------------------------------

if not ItemConditionOverlay.original_renderItemIcon then
    ItemConditionOverlay.original_renderItemIcon = ISInventoryItem.renderItemIcon

    function ISInventoryItem.renderItemIcon(pane, item, x, y, alpha, w, h)
        ItemConditionOverlay.original_renderItemIcon(pane, item, x, y, alpha, w, h)

        if not Settings.showInInventory then
            return
        end

        -- w/h are optional in vanilla. ISInventoryPane:rendericons() calls this with
        -- only four arguments, and vanilla falls back to the texture's own size.
        -- Without this guard every bar draw in inventory "icons" mode throws
        -- "attempt to perform arithmetic on a nil value".
        if not w or not h then
            if not item or not item.getTex then return end
            local tex = item:getTex()
            if not tex then return end
            w = tex:getWidthOrig()
            h = tex:getHeightOrig()
            if not w or not h or w <= 0 or h <= 0 then return end
        end

        local renderData = getItemRenderData(item, false)
        if renderData then
            local weaponCond = renderData.weaponCond

            if weaponCond and weaponCond.useMultipleBars then
                local barHeight = 1
                local barSpacing = 1
                local barCount = weaponCond.barCount
                local baseY = y + h - (barHeight * barCount) - (barSpacing * (barCount - 1)) - 1
                drawMultiBar(pane, x, baseY, w, weaponCond, barHeight, barSpacing)
            else
                local barHeight = 2
                local barY = y + h - barHeight
                drawSingleBar(pane, x, barY, w, renderData.percent, barHeight, renderData.isBattery,
                    renderData.tintR, renderData.tintG, renderData.tintB)
            end
        end
    end
end

--------------------------------------------------------------------------------
-- HOTBAR RENDERING
--------------------------------------------------------------------------------

-- Vanilla draws the slot's item icon at `slotX + tex:getWidth()/2`. With the vanilla
-- 60px slot and a 32px icon that lands roughly centred by coincidence, but once the
-- slot is scaled up the icon stays pinned near the left edge. While the vanilla
-- render runs we intercept drawTexture and re-centre only those draws whose x matches
-- that exact formula, so the equipped indicator (which uses a different formula) and
-- anything another mod draws are left untouched.
--
-- Built once per scale change and cached on the hotbar, never per frame.
local function buildIconCenteringShim(hotbar)
    local slotWidth = hotbar.slotWidth
    local margins = hotbar.margins
    local stride = slotWidth + hotbar.slotPad
    local panelHeight = hotbar.height
    local scale = slotWidth / BASE_SLOT_WIDTH
    -- Instance field is clear at this point, so this resolves to the class method
    local realDrawTexture = hotbar.drawTexture

    return function(selfRef, tex, x, y, a, r, g, b)
        if tex and type(x) == "number" and stride > 0 then
            local texW = tex:getWidth()
            if texW and texW > 0 then
                local slotIdx = math_floor((x - margins - 1) / stride)
                if slotIdx >= 0 then
                    local slotStart = margins + 1 + (slotIdx * stride)
                    -- Only touch draws that used vanilla's item-icon formula
                    if math_abs(x - (slotStart + (texW / 2))) < 1.5 then
                        -- Grow the icon with the slot. Vanilla draws it at native
                        -- size, so on a scaled hotbar a 32px icon sits marooned in a
                        -- 150px slot. Scaling by the same factor keeps the icon at
                        -- the proportion of the slot it occupies at vanilla size.
                        local target = texW * scale
                        local maxDim = slotWidth - (8 * scale)
                        if target > maxDim then target = maxDim end
                        local nx = slotStart + ((slotWidth - target) / 2)
                        local ny = (panelHeight - target) / 2
                        if selfRef.drawTextureScaledAspect then
                            selfRef:drawTextureScaledAspect(tex, nx, ny, target, target, a, r, g, b)
                            return
                        end
                        x = slotStart + ((slotWidth - texW) / 2)
                    end
                end
            end
        end
        return realDrawTexture(selfRef, tex, x, y, a, r, g, b)
    end
end

-- Apply the user's hotbar scale to a hotbar instance. Vanilla recomputes the panel
-- width from slotWidth in setSizeAndPosition() and derives click hit-testing from
-- slotWidth in getSlotIndexAt(), so resizing stays self consistent.
-- Early-outs on every frame except the one where the scale actually changed.
local function applyHotbarScale(hotbar)
    local scale = Settings.hotbarScale or 1.0
    if hotbar.ICO_appliedScale == scale then
        return
    end

    hotbar.slotWidth = math_floor(BASE_SLOT_WIDTH * scale)
    hotbar.slotHeight = math_floor(BASE_SLOT_HEIGHT * scale)
    hotbar.height = hotbar.slotHeight + (hotbar.margins * 2) + 2
    if hotbar.setHeight then
        hotbar:setHeight(hotbar.height)
    end
    hotbar.ICO_appliedScale = scale

    -- Keep the slot number legible on a large hotbar
    hotbar.font = (scale >= 1.5) and UIFont.Medium or UIFont.Small

    -- At vanilla scale the shim is nil and the draw path is untouched
    hotbar.ICO_drawTextureShim = (scale ~= 1.0) and buildIconCenteringShim(hotbar) or nil

    if hotbar.setSizeAndPosition then
        hotbar:setSizeAndPosition()
    end
end

ItemConditionOverlay.applyHotbarScale = applyHotbarScale

if not ItemConditionOverlay.original_ISHotbar_render then
    ItemConditionOverlay.original_ISHotbar_render = ISHotbar.render

    function ISHotbar:render()
        -- Resize before vanilla draws, so slot borders and icons use the new geometry
        applyHotbarScale(self)

        -- Save original equipped icon and replace with transparent version
        local originalIcon = self.equippedItemIcon
        if not ItemConditionOverlay.transparentIcon then
            ItemConditionOverlay.transparentIcon = getTexture("media/ui/transparent.png")
        end
        self.equippedItemIcon = ItemConditionOverlay.transparentIcon or originalIcon

        -- Only re-centre when the hotbar is actually scaled, so default setups run
        -- exactly the vanilla draw path with no wrapper in it at all
        local shim = self.ICO_drawTextureShim
        if shim then
            self.drawTexture = shim
        end

        ItemConditionOverlay.original_ISHotbar_render(self)

        if shim then
            -- Clearing the instance field falls back to the class method
            self.drawTexture = nil
        end

        -- Restore original icon
        self.equippedItemIcon = originalIcon

        -- Cache texture dimensions on first use
        if not equippedIconWidth and originalIcon then
            equippedIconWidth = originalIcon:getWidth()
        end

        -- Cache text manager and session-fixed font metrics on first use. Both
        -- self-guard, so this costs one boolean test per frame afterwards.
        if not cachedTextManager then
            cachedTextManager = getTextManager()
        end
        initFontMetrics()

        -- Cache self properties for this render pass (reduces table lookups in loop)
        local slotWidth = self.slotWidth
        local slotHeight = self.slotHeight
        local slotPad = self.slotPad
        local margins = self.margins

        -- Anchor to the slot rectangle vanilla actually draws (ISHotbar.lua:32 draws
        -- it at y = margins+1 with height slotHeight) rather than to self.height.
        -- Deriving from self.height only works while the constructor invariant
        -- height == slotHeight + margins*2 + 2 holds, which another hotbar mod can
        -- break by changing one without the other.
        local slotBottom = margins + 1 + slotHeight
        local attachedItems = self.attachedItems
        local availableSlot = self.availableSlot
        local ammoMode = Settings.ammoCounterMode
        local scale = Settings.hotbarScale or 1.0
        local slotX = margins + 1

        -- Bar thickness tracks the hotbar scale so bars don't look like hairlines
        -- on a large hotbar
        local scaledBarHeight = math_max(2, math_floor(2 * scale))
        local scaledBarSpacing = math_max(1, math_floor(2 * scale))
        local ammoPadX = math_max(2, math_floor(4 * scale))
        local ammoMaxWidth = slotWidth - (ammoPadX * 2)

        for i in pairs(availableSlot) do
            local item = attachedItems[i]

            local ammoData = nil
            local showAmmoCounter = false

            if ammoMode ~= "off" then
                ammoData = getAmmoData(item)
                showAmmoCounter = ammoData ~= nil
            end

            local ammoText, ammoFont, ammoTextWidth, ammoTextHeight = nil, nil, 0, 0
            local ammoZoom = 1

            if showAmmoCounter then
                -- Grow the text with the hotbar, but let the fitter reach that size by
                -- choosing a real larger font first and only zooming for the residue.
                -- Zooming a bitmap font blurs it, and vanilla's slot numbers sitting
                -- right next to ours are always crisp.
                local ammoTarget = baseFontHeight
                if scale > 1.01 then
                    ammoTarget = baseFontHeight * math_min(3, scale)
                end
                -- Memoised per slot: recomputes only when the count, mode, fit width,
                -- target size or font setting changes
                ammoText, ammoFont, ammoTextWidth, ammoTextHeight, ammoZoom =
                    fitAmmoText(i, ammoData, ammoMode, ammoMaxWidth, ammoTarget)
                if textZoomSupported == false then
                    ammoZoom = 1
                end
                ammoTextWidth = ammoTextWidth * ammoZoom
                ammoTextHeight = ammoTextHeight * ammoZoom
            end

            -- Draw equipped indicator at top right, below the ammo text if present.
            -- Scales with the hotbar like the item icon does, otherwise it shrinks to
            -- a speck on a large slot.
            if item and item:isEquipped() and equippedIconWidth then
                local eqSize = equippedIconWidth * scale
                local newX = slotX + slotWidth - eqSize - (8 * scale)
                local newY = margins + (4 * scale)
                if showAmmoCounter then
                    -- Clear the actual measured text, not a constant tuned for 19px
                    newY = margins + 2 + ammoTextHeight
                end
                if scale > 1.01 and self.drawTextureScaledAspect then
                    self:drawTextureScaledAspect(originalIcon, newX, newY, eqSize, eqSize, 1, 1, 1, 1)
                else
                    self:drawTexture(originalIcon, newX, newY, 1, 1, 1, 1)
                end
            end

            -- Ammo counter for firearms
            if showAmmoCounter then
                local textX = slotX + slotWidth - ammoTextWidth - ammoPadX
                local textY = margins + 3

                -- Outline thickness follows both the font tier and the hotbar scale
                local o = math_max(1, math_floor(outlineWidth * ammoZoom))
                if useHeavyOutline or ammoZoom > 1.01 then
                    drawScaledText(self, ammoText, textX - o, textY - o, 0, 0, 0, 1, ammoFont, ammoZoom)
                    drawScaledText(self, ammoText, textX + o, textY - o, 0, 0, 0, 1, ammoFont, ammoZoom)
                    drawScaledText(self, ammoText, textX - o, textY + o, 0, 0, 0, 1, ammoFont, ammoZoom)
                    drawScaledText(self, ammoText, textX + o, textY + o, 0, 0, 0, 1, ammoFont, ammoZoom)
                else
                    -- Vanilla-tier, unscaled: same two draws v1.1.0 did
                    self:drawText(ammoText, textX + 1, textY + 1, 0, 0, 0, 1, ammoFont)
                end
                drawScaledText(self, ammoText, textX, textY, 1, 1, 1, 1, ammoFont, ammoZoom)
            end

            -- Condition bar
            local renderData = getItemRenderData(item, true)
            if renderData then
                local weaponCond = renderData.weaponCond
                local barPadding = 1
                local barX = slotX + barPadding
                local barWidth = slotWidth - (barPadding * 2)

                if weaponCond and weaponCond.useMultipleBars then
                    local barCount = weaponCond.barCount
                    local baseY = slotBottom
                        - (scaledBarHeight * barCount)
                        - (scaledBarSpacing * (barCount - 1)) - 2
                    drawMultiBar(self, barX, baseY, barWidth, weaponCond, scaledBarHeight, scaledBarSpacing)
                else
                    local barY = slotBottom - scaledBarHeight - 4
                    drawSingleBar(self, barX, barY, barWidth, renderData.percent, scaledBarHeight, renderData.isBattery,
                        renderData.tintR, renderData.tintG, renderData.tintB)
                end
            end

            slotX = slotX + slotWidth + slotPad
        end
    end
end

--------------------------------------------------------------------------------
-- HOTBAR TOOLTIP SUPPRESSION
--------------------------------------------------------------------------------

-- Vanilla ISHotbar:update() builds self.toolRender on mouseover and shows it.
-- Rather than reimplement update(), let vanilla run and then hide the tooltip.
if not ItemConditionOverlay.original_ISHotbar_update then
    ItemConditionOverlay.original_ISHotbar_update = ISHotbar.update

    function ISHotbar:update()
        ItemConditionOverlay.original_ISHotbar_update(self)

        if not Settings.showHotbarTooltips and self.toolRender then
            self.toolRender:setVisible(false)
        end
    end
end
