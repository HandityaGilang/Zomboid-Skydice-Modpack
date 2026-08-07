-- Entry point: golden stone button in the sidebar plus hotkey, and the
-- blue player panel button right below it
require "ISUI/ISEquippedItem"
require "Aegis/AegisTheme"
require "Aegis/AegisPlayerCore"
require "Aegis/AegisWindow"
require "Aegis/AegisPageDashboard"
require "Aegis/AegisPagePowers"
require "Aegis/AegisPagePlayers"
require "Aegis/AegisPageItems"
require "Aegis/AegisPageVehicles"
require "Aegis/AegisVehicleDetail"
require "Aegis/AegisPageWorld"
require "Aegis/AegisPageZones"
require "Aegis/AegisPageHorde"
require "Aegis/AegisPageServer"
require "Aegis/AegisPageSandbox"
require "Aegis/AegisPageLogs"
require "Aegis/AegisPageRoles"
require "Aegis/AegisModerationClient"

AegisHud = AegisHud or {}

function AegisHud.onButtonClick(equipped, button)
    AegisWindow.toggle()
end

function AegisHud.onPlayerButtonClick(equipped, button)
    if AegisPlayerWindow then AegisPlayerWindow.toggle() end
end

-- golden fullscreen banner for server announcements (restart notices),
-- visible to EVERY player, independent of the Aegis window
AegisBanner = ISPanel:derive("AegisBanner")

function AegisBanner.show(text)
    if not text or text == "" then return end
    if AegisBanner.instance then
        AegisBanner.instance:removeFromUIManager()
        AegisBanner.instance = nil
    end
    local sw = getCore():getScreenWidth()
    local w = math.max(360, Aegis.strW(UIFont.Large, text) + 80)
    local o = ISPanel:new(math.floor((sw - w) / 2), 96, w, 64)
    setmetatable(o, AegisBanner)
    AegisBanner.__index = AegisBanner
    o.background = false
    o.text = text
    o.untilMs = getTimestampMs() + 8000
    o:initialise()
    o:addToUIManager()
    o:setAlwaysOnTop(true)
    pcall(function() o.javaObject:setConsumeMouseEvents(false) end)
    AegisBanner.instance = o
    -- also to chat, for anyone looking elsewhere right now; ChatManager
    -- itself can be unavailable for a moment on some clients (live
    -- finding: indexing it then throws even inside pcall's protection,
    -- PZ still surfaces the caught trace as an error popup)
    if ChatManager then
        pcall(function() ChatManager.getInstance():showInfoMessage(text) end)
    end
    return o
end

function AegisBanner:prerender()
    local c = Aegis.col
    Aegis.shadow(self, 0, 0, self.width, self.height, 24, 0.6)
    Aegis.roundFrame(self, 0, 0, self.width, self.height, 12, 0.97, c.gold, c.dark)
    Aegis.icon(self, "clock", 20, 20, 22, 1, c.gold)
    Aegis.textCentre(self, self.text, math.floor(self.width / 2) + 10,
        math.floor((self.height - Aegis.fontH(UIFont.Large)) / 2), UIFont.Large, c.goldHi)
end

function AegisBanner:update()
    if getTimestampMs() > self.untilMs then
        self:removeFromUIManager()
        if AegisBanner.instance == self then AegisBanner.instance = nil end
    end
end

-- Attach the button below the vanilla bar. Class patch, because the bar
-- is rebuilt from scratch whenever the sidebar size changes.
-- non-admins get no button at all, not just a hidden one: other mods
-- that add their own icon below the bar without checking visibility
-- would otherwise still count ours as an occupied slot. Creation is
-- LAZY (first prerender with confirmed rights) because the bar is
-- built during UI bootstrap, before the engine knows the admin state
-- (live finding: the button never appeared for admins otherwise)
-- lowest visible sibling in the equipped-item bar, OURS excluded. The
-- test cannot be child.Type == "ISButton": other mods derive their icon
-- from ISButton and thereby rename the Type (FactionFramework ships
-- "FFHudIcon"), so a strict compare made Aegis blind to them and it sat
-- down on top of their button. Anything that draws and reports a bottom
-- counts as occupied space, Aegis is the one that yields
-- an icon slot in this bar is small and roughly square. Panels, popups
-- and tooltips get parented to the bar as well (vanilla does it with the
-- moveables tooltip), and yielding below one of those pushed our button
-- far down, in the worst case off the screen entirely: the button
-- existed, answered nothing and was nowhere to be seen. Only child
-- elements that could actually BE an icon count as occupied space
local ICON_MAX_W, ICON_MAX_H = 96, 72

local function occupiedBottom(bar, skipA, skipB)
    local bottom = 0
    local w, h = 48, 36
    for _, child in pairs(bar:getChildren()) do
        if child ~= skipA and child ~= skipB and child.getBottom and child.isVisible
            and child:isVisible() and child.getWidth
            and child:getWidth() <= ICON_MAX_W and child:getHeight() <= ICON_MAX_H then
            bottom = math.max(bottom, child:getBottom())
            if child.Type == "ISButton" then
                w = math.max(w, child:getWidth())
                h = math.max(h, child:getHeight())
            end
        end
    end
    return bottom, w, h
end

local function attachButton(bar)
    local bottom, w, h = occupiedBottom(bar, bar.aegisPlayerBtn, nil)

    local btn = ISButton:new(0, bottom + 15, w, h, "", bar, AegisHud.onButtonClick)
    btn:initialise()
    btn:instantiate()
    btn:setImage(Aegis.tex("hud"))
    btn:setDisplayBackground(false)
    btn:ignoreWidthChange()
    btn:ignoreHeightChange()
    btn:setVisible(false)
    -- rename the Type so foreign sidebar mods do NOT see us. They anchor
    -- on child.Type == "ISButton" and reposition every frame; if we also
    -- anchored on them while they anchor on us, both buttons would chase
    -- each other down the screen. Aegis yields, so Aegis stays invisible
    -- to their scan and does the dodging itself. Vanilla shrinkWrap uses
    -- the same test, which is why the height sync below is ours to do
    btn.Type = "AegisHudButton"
    bar:addChild(btn)
    bar.aegisBtn = btn
end

-- same lazy pattern for the blue player panel button, without any admin
-- gate: it exists once the server confirmed the panel for this player
local function attachPlayerButton(bar)
    local bottom, w, h = occupiedBottom(bar, bar.aegisBtn, nil)

    local btn = ISButton:new(0, bottom + 15, w, h, "", bar, AegisHud.onPlayerButtonClick)
    btn:initialise()
    btn:instantiate()
    btn:setImage(Aegis.tex("hud_player"))
    btn:setDisplayBackground(false)
    btn:ignoreWidthChange()
    btn:ignoreHeightChange()
    btn:setVisible(false)
    btn.Type = "AegisHudButton"
    bar:addChild(btn)
    bar.aegisPlayerBtn = btn
end

-- Creation, placement and height sync, deliberately split out of the
-- prerender wrap. Both buttons used to be born ONLY inside our wrap of
-- ISEquippedItem.prerender. A mod that assigns that function instead of
-- chaining to the previous one cuts us out completely: no button is ever
-- created, and the height correction below (which keeps FOREIGN icons
-- clickable) disappears with it. Two independent player reports showed
-- exactly that, with different mod sets, so existence must not depend on
-- our wrap surviving. The keeper at the end of this file calls the same
-- function whenever the wrap has been quiet for a moment
function AegisHud.syncBar(self)
    if not self or not self.getChildren then return end
    local adminVisible = Aegis.allowed(self.chr)
    local playerVisible = AegisPlayerClient ~= nil and AegisPlayerClient.enabled() or false
    if self.chr and self.chr:getPlayerNum() == 0 then
        if not self.aegisBtn and adminVisible then pcall(attachButton, self) end
        if not self.aegisPlayerBtn and playerVisible then pcall(attachPlayerButton, self) end
    end
    local btn = self.aegisBtn
    local pbtn = self.aegisPlayerBtn
    if not btn and not pbtn then return end
    if btn then btn:setVisible(adminVisible) end
    if pbtn then pbtn:setVisible(playerVisible) end

    -- lowest visible sibling as anchor, vanilla buttons and foreign mod
    -- icons alike. BOTH Aegis buttons are excluded here: each would
    -- otherwise anchor on the other and the pair would drift further down
    -- every frame
    local bottom = occupiedBottom(self, btn, pbtn)

    -- the bar height must reach the LOWEST visible child, not just our
    -- own buttons: other mods (FactionFramework and friends) hang their
    -- icons below ours, clipping them off makes them click-dead
    local function syncHeight(floor)
        local target = floor
        for _, child in pairs(self:getChildren()) do
            if child ~= btn and child ~= pbtn and child.getBottom and child:isVisible() then
                target = math.max(target, child:getBottom())
            end
        end
        if target > 0 and self:getHeight() ~= target then
            self:setHeight(target)
        end
    end

    -- last line of defence: whatever the siblings claim, the pair has to
    -- stay on screen. Without this a single misreported child could park
    -- our buttons below the bottom edge and they would simply be gone
    local screenH = getCore():getScreenHeight()
    local needed = 15 + ((btn and adminVisible) and btn:getHeight() + 10 or 0)
        + ((pbtn and playerVisible) and pbtn:getHeight() or 0)
    local maxBottom = screenH - self:getAbsoluteY() - needed - 8
    if bottom > maxBottom then bottom = math.max(0, maxBottom) end

    local floor = 0
    if btn then
        if adminVisible then
            btn:setY(bottom + 15)
            btn:setImage(AegisWindow.instance and Aegis.tex("hud_on") or Aegis.tex("hud"))
            floor = btn:getBottom()
        elseif AegisWindow.instance then
            AegisWindow.instance:close()
        end
    end
    if pbtn and playerVisible then
        -- stacked below the golden button, or in its slot without admin rights
        pbtn:setY((btn and adminVisible) and (btn:getBottom() + 10) or (bottom + 15))
        local open = AegisPlayerWindow and AegisPlayerWindow.instance
        pbtn:setImage(open and Aegis.tex("hud_player_on") or Aegis.tex("hud_player"))
        floor = math.max(floor, pbtn:getBottom())
    end
    -- floor 0 with both buttons hidden releases the panel height again,
    -- otherwise the empty area blocks clicks
    syncHeight(floor)
end

-- fast path: once per frame, in the right spot of the draw order
local prevPrerender = ISEquippedItem.prerender
function ISEquippedItem:prerender()
    prevPrerender(self)
    self.aegisSyncMs = getTimestampMs()
    AegisHud.syncBar(self)
end

-- keeper: if the wrap above has been silent for half a second, someone
-- replaced ISEquippedItem.prerender without chaining. Then the bar is
-- served from here instead, so neither our buttons nor the height fix
-- for foreign icons depend on a chain we do not control
Events.OnTick.Add(function()
    local bar = ISEquippedItem.instance
    if not bar then return end
    local now = getTimestampMs()
    if now - (bar.aegisSyncMs or 0) < 500 then return end
    bar.aegisSyncMs = now
    pcall(AegisHud.syncBar, bar)
end)

-- hotkeys via the B42 mod options: F7 opens the admin panel, F6 the
-- player area. F1 to F5, F10 and F11 are taken by vanilla
if PZAPI and PZAPI.ModOptions then
    local opts = PZAPI.ModOptions:create("AegisAdmin", "Aegis Admin Suite")
    AegisHud.keybind = opts:addKeyBind("openPanel", getText("UI_Aegis_Hotkey"), Keyboard.KEY_F7, "")
    AegisHud.playerKeybind = opts:addKeyBind("openPlayerPanel", getText("UI_Aegis_HotkeyPlayer"), Keyboard.KEY_F6, "")
end

-- the player area has no rights gate: whoever is on the server has it,
-- the toggle itself refuses while the server has not granted the panel
Events.OnKeyPressed.Add(function(key)
    if not AegisHud.playerKeybind or key == 0 then return end
    if key ~= AegisHud.playerKeybind:getValue() then return end
    if AegisPlayerWindow then AegisPlayerWindow.toggle() end
end)

Events.OnKeyPressed.Add(function(key)
    if not AegisHud.keybind then return end
    if key ~= AegisHud.keybind:getValue() or key == 0 then return end
    if not Aegis.allowed(getPlayer()) then return end
    -- the same key first exits photo mode without also toggling the
    -- panel (which is only hidden then, not closed)
    if AegisPhotoMode and AegisPhotoMode.isOn() then
        AegisPhotoMode.setOn(false)
        return
    end
    AegisWindow.toggle()
end)

-- pinned carry weight: the engine recomputes maxWeight from traits on
-- several sync events, the gaps made the inventory claim "full" with a
-- heavy pack (user finding). Pinning every tick closes the gaps; the
-- toast only fires when the value actually changes
local carryPin = nil

Events.OnTick.Add(function()
    if not carryPin then return end
    pcall(function()
        local p = getPlayer()
        if p and p:getMaxWeight() ~= carryPin then
            p:setMaxWeightBase(carryPin)
            p:setMaxWeight(carryPin)
        end
    end)
end)

-- return path for server commands: apply healing locally, report spawn results,
-- adopt Aegis rights and surface denials
Events.OnServerCommand.Add(function(module, command, args)
    if module ~= "AegisAdmin" then return end
    if command == "heal" then
        AegisShared.fullHeal(getPlayer())
    elseif command == "carryWeight" then
        local value = math.floor(tonumber(args and args.value) or 0)
        if value >= 5 and value <= 1000 then
            local changed = carryPin ~= value
            carryPin = (value > 8) and value or nil
            pcall(function()
                local p = getPlayer()
                p:setMaxWeightBase(value)
                p:setMaxWeight(value)
                -- the engine keeps TWO limits apart: maxWeight is the
                -- encumbrance threshold, and the body container has its own
                -- hard cap of 50 (constructor default, never changed by the
                -- character classes) past which picking up is refused. The
                -- stamp overrides that hard cap through the Aegis capacity
                -- hook, and it exists ONLY to lift it above 50 for big carry
                -- values. Stamping small values LOWERED the cap to the
                -- threshold itself and pickups died at the limit (community
                -- report), so below the vanilla cap the stamp goes away and
                -- vanilla overloading behaviour stays
                p:getModData().aegisCapacity = (value > 50) and value or nil
            end)
            if changed then
                Aegis.showToast(getText("UI_Aegis_CarryWeight") .. ": " .. tostring(value))
            end
        end
    elseif command == "spawnvehicle" then
        local ok = args and args.ok == true
        local name = args and args.name or ""
        Aegis.showToast((ok and getText("UI_Aegis_VehicleSpawned") or getText("UI_Aegis_VehicleFailed")) .. ": " .. tostring(name))
        if ok and args.id then
            AegisVehicleDetail.open(args.id)
        end
    elseif command == "spawnanimal" then
        local ok = args and args.ok == true
        local name = args and args.name or ""
        Aegis.showToast((ok and getText("UI_Aegis_AnimalSpawned") or getText("UI_Aegis_VehicleFailed")) .. ": " .. tostring(name))
    elseif command == "rightsSync" then
        if args and args.full then
            Aegis.rights = nil
        elseif args and args.none then
            Aegis.rights = false
        else
            local r = {}
            if args and type(args.rights) == "table" then
                for _, b in pairs(args.rights) do r[b] = true end
            end
            Aegis.rights = r
        end
        -- from now on "nil" really means confirmed full access instead of
        -- "no answer yet" (see AegisTheme.lua, Aegis.canSee)
        Aegis.rightsLoaded = true
        Aegis.role = args and args.role or nil
    elseif command == "banner" then
        -- translate only here: the dedicated server loads no UI texts,
        -- getText there returns just the raw key
        local text = args and args.text
        if args and args.key then
            text = args.par ~= nil and getText(args.key, args.par) or getText(args.key)
        end
        AegisBanner.show(text)
    elseif command == "hordeResult" then
        if args then
            Aegis.showToast("Horde: " .. tostring(args.spawned) .. "/" .. tostring(args.requested))
        end
    elseif command == "quitRelay" then
        -- the triggering admin restarts the server: /restart first
        -- (user request, comes from the panel wrapper, vanilla lacks it),
        -- if the server is still alive afterwards, /quit follows as safety net,
        -- the hoster panel brings the stopped server back up.
        -- if the scheduler is offline, any authorized admin steps in
        local me = getPlayer() and getPlayer():getUsername()
        -- the engine accepts /quit only from a connection whose role
        -- carries QuitWorld (measured on QuitCommand), so exactly that
        -- decides who answers the anyone call. Wider than the old server
        -- area gate: every client the engine would listen to responds,
        -- and nobody the engine would refuse wastes the attempt
        local canQuit = false
        pcall(function()
            local level = tostring(getPlayer():getAccessLevel() or ""):lower()
            local role = AegisShared.roleForLevel(level)
            if role then
                canQuit = role:hasCapability(Capability.QuitWorld) == true
            else
                local r = getPlayer():getRole()
                canQuit = (r and r:hasCapability(Capability.QuitWorld)) == true
            end
        end)
        local responsible = args and (args.by == me or (args.anyone and canQuit))
        if responsible and isClient() then
            -- the memo ages out: a restart planned later starts over with
            -- the polite /restart, only knocks of the SAME round skip it
            local fresh = AegisHud.relayRan and (getTimestampMs() - AegisHud.relayRan) < 300000
            if fresh then
                -- the server is knocking again, so it is still alive and
                -- /restart demonstrably did nothing. Straight to the command
                -- the engine really has, and never rearm the fallback: a
                -- repeat that pushes it forward keeps it from ever firing
                SendCommandToServer("/quit")
            else
                AegisHud.relayRan = getTimestampMs()
                SendCommandToServer("/restart")
                AegisHud.quitFallback = getTimestampMs() + 8000
            end
            -- trace to the actions log: which client actually picked the
            -- relay up. The server resends every minute while it lives,
            -- so repeated lines here mean the quit keeps failing
            pcall(function()
                sendClientCommand(getPlayer(), AegisShared.MODULE, "relayRan", {})
            end)
        end
    elseif command == "teleportVehicle" then
        local p = getPlayer()
        local x, y, z = args and args.x, args and args.y, (args and args.z) or 0
        if args and args.ok == true and args.phase == "exit" then
            -- first stage: teleport the player right away. In MP the
            -- vanilla teleport dismounts the admin cleanly and frees the
            -- vehicle, and arriving at the target streams the area in so
            -- the server watcher can pull the vehicle after him
            if x and y then
                if isClient() then
                    SendCommandToServer("/teleportto " .. tostring(x) .. "," .. tostring(y) .. "," .. tostring(z))
                elseif p then
                    -- solo: the in-process server part already dismounted
                    pcall(function() p:teleportTo(x, y, z + 0.0) end)
                end
            end
        elseif args and args.ok == true then
            -- the vehicle was recreated at the target: the old key is
            -- dead, a fresh one waits in the new glove box
            Aegis.showToast(getText("UI_Aegis_VehicleTeleportedKey"))
            -- a detail window still looking at the old id follows along
            pcall(function()
                local inst = AegisVehicleDetail.instance
                if inst and args.oldId and inst.vehicleId == args.oldId and args.newId then
                    inst:close()
                    AegisVehicleDetail.open(args.newId)
                end
            end)
        else
            Aegis.showToast(getText("UI_Aegis_VehicleFailed"))
        end
    elseif command == "denied" then
        local key = (args and args.reason == "capability") and "UI_Aegis_DeniedCap" or "UI_Aegis_Denied"
        Aegis.showToast(getText(key))
    end
end)

-- Aegis teleport on world map right click (key M). Vanilla only shows its
-- own menu in debug mode or as MP vanilla admin, with the teleport buried
-- between dev options; Aegis adds a clean entry everywhere else where
-- the user has Aegis access
local function patchWorldMap()
    if not ISWorldMap or ISWorldMap.aegisTeleport then return end
    ISWorldMap.aegisTeleport = true
    local prev = ISWorldMap.onRightMouseUp
    ISWorldMap.onRightMouseUp = function(self, x, y)
        local result = prev(self, x, y)
        -- where the vanilla menu appears, it already has the teleport itself
        if getDebug() or (isClient() and getAccessLevel() == "admin") then return result end
        if result == true then return result end
        local p = getPlayer()
        if not p or not Aegis.allowed(p) or not Aegis.canSee("world") then return result end
        local ok = pcall(function()
            local worldX = self.mapAPI:uiToWorldX(x, y)
            local worldY = self.mapAPI:uiToWorldY(x, y)
            if not getWorld():getMetaGrid():isValidChunk(worldX / 10, worldY / 10) then return end
            local context = ISContextMenu.get(0, x + self:getAbsoluteX(), y + self:getAbsoluteY())
            context:addOption(getText("UI_Aegis_MapTeleport"), self, function(map)
                Aegis.teleportSmart(worldX, worldY, 0)
                Aegis.logAction("world", string.format("Map teleport to %d,%d", math.floor(worldX), math.floor(worldY)))
                -- close the map, otherwise you stand invisible behind the open map
                pcall(function() map:close() end)
            end)
        end)
        return result
    end
end

-- solo needs the admin role, otherwise the power setters do nothing;
-- plus the map patch
Events.OnGameStart.Add(function()
    -- every fresh session (including reconnect without client restart) starts
    -- unsynced, otherwise stale rights from the previous server connection
    -- could briefly carry over (see AegisTheme.lua)
    Aegis.rights = nil
    Aegis.rightsLoaded = false
    Aegis.role = nil
    Aegis.ensureSoloRole()
    patchWorldMap()
    -- heal characters that still carry the old small capacity stamp: it
    -- lowered the body hard cap below the vanilla 50 and blocked pickups
    -- at the carry limit. A player stamp at or under 50 is never right,
    -- the stamp only exists to raise the cap
    pcall(function()
        local p = getPlayer()
        local md = p and p:getModData()
        local s = md and tonumber(md.aegisCapacity)
        if s and s <= 50 then md.aegisCapacity = nil end
    end)
    -- fetch the rights right away instead of waiting for the first window
    -- open: entry points outside the window (vehicle context menu) are
    -- gated by canSee and stayed invisible until the panel was opened once
    if isClient() and Aegis.allowed(getPlayer()) then
        sendClientCommand(getPlayer(), AegisShared.MODULE, "rightsReq", {})
    end
end)

-- /setaccesslevel changes the level mid session and no aegis command
-- runs with it, so the rights cache kept the OLD verdict until the gold
-- panel was opened once. Until then every context menu entry gated by
-- canSee was missing, and a demoted admin kept entries he no longer had
-- (live finding, twice in one test day). This watches the level and
-- refetches on any change
local levelWatchNext = 0
local levelWatchLast = nil
Events.OnTick.Add(function()
    local now = getTimestampMs()
    if now < levelWatchNext then return end
    levelWatchNext = now + 2000
    if not isClient() then return end
    local level = nil
    pcall(function() level = tostring(getPlayer():getAccessLevel() or ""):lower() end)
    if level == nil or level == levelWatchLast then return end
    local first = levelWatchLast == nil
    levelWatchLast = level
    -- session start is handled by OnGameStart, only a real change counts
    if first then return end
    Aegis.rights = nil
    Aegis.rightsLoaded = false
    Aegis.role = nil
    print("[Aegis] access level changed to '" .. level .. "', refetching rights")
    if Aegis.allowed(getPlayer()) then
        sendClientCommand(getPlayer(), AegisShared.MODULE, "rightsReq", {})
    end
end)

-- safety net for the restart relay: only kicks in if /restart did not
-- stop the server (this client is still running then)
Events.OnTick.Add(function()
    if AegisHud.quitFallback and getTimestampMs() >= AegisHud.quitFallback then
        AegisHud.quitFallback = nil
        if isClient() then
            SendCommandToServer("/quit")
        end
    end
end)
