require "ISUI/ISCollapsableWindow"
local PSR = require "PSR/Utilities"

---@class PSRComputerPanel : ISCollapsableWindow
local PSRComputerPanel = ISCollapsableWindow:derive("PSRComputerPanel")

-- Layout — base values calibrated for UIFont.Small at default Font Size (~14 px).
-- Real positions are scaled at runtime via computeLayout() to respect the player's
-- in-game Font Size setting (Options > Display > Font Size). Without scaling, text
-- bleeds across columns at Font Size 24+ (bug reported by Workshop player).
local ROWS_PER_PAGE   = 12
local FUEL_TO_AH      = 800   -- matches PowerBank.fuelToSolarRate (L/h → Ah/h)
local BASE_FONT_H     = 14
local BASE_ROW_H      = 22
local BASE_WIN_W      = 460
local BASE_COL_EXPAND = 6     -- expand/collapse button (width 18 scaled)
local BASE_COL_TYPE   = 30    -- device type name or indented coords
local BASE_COL_COUNT  = 185   -- active count "(on/total)" or "(n)"
local BASE_COL_DRAIN  = 222   -- drain in Ah
local BASE_COL_STATUS = 292   -- ON / OFF / PARTIAL text
local BASE_COL_BTN    = 358   -- group toggle button
local BASE_COL_GO     = 356   -- "Go" button on device rows
local BASE_COL_DEVBTN = 388   -- Disable/Enable on device rows

-- Device types that can be physically toggled on/off
local PSR_CONTROLLABLE = { light=true, switch=true, tv=true, radio=true, washer=true, dryer=true, coldunit=true, fridge=true, freezer=true, fridgeFreezer=true }

--- Compute current layout dict based on the player's Font Size setting.
--- Multiplies all positions/dimensions by max(1.0, fontH / BASE_FONT_H) so the panel
--- stays readable at any Font Size. Called once at panel construction.
local function computeLayout()
    local fontH = getTextManager():getFontHeight(UIFont.Small)
    local scale = math.max(1.0, fontH / BASE_FONT_H)
    return {
        scale     = scale,
        rowH      = math.floor(BASE_ROW_H      * scale),
        winW      = math.floor(BASE_WIN_W      * scale),
        colExpand = math.floor(BASE_COL_EXPAND * scale),
        colType   = math.floor(BASE_COL_TYPE   * scale),
        colCount  = math.floor(BASE_COL_COUNT  * scale),
        colDrain  = math.floor(BASE_COL_DRAIN  * scale),
        colStatus = math.floor(BASE_COL_STATUS * scale),
        colBtn    = math.floor(BASE_COL_BTN    * scale),
        colGo     = math.floor(BASE_COL_GO     * scale),
        colDevBtn = math.floor(BASE_COL_DEVBTN * scale),
    }
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ──────────────────────────────────────────────────────────────────────────────

--- Format a fuel L/h rate as Ah. Shows one decimal only when needed.
--- e.g. 0.002 → "1.6Ah", 0.08 → "64Ah"
local function fmtAh(rate)
    local ah = rate * FUEL_TO_AH
    local rounded = math.floor(ah * 10 + 0.5) / 10
    return string.format("%gAh", rounded)
end

--- Per-panel nominal solar output at full sun (Ah). Mirrors PbSystem:getMaxSolarOutput(1)
--- in PowerBankSystem_Shared.lua (83 * efficiency*1.25/100). Depends only on the
--- client-synced solarPanelEfficiency sandbox, so it's safe to compute client-side here.
--- This answers the recurring player question "how much does each solar panel generate?".
local function perPanelOutput()
    local eff = (SandboxVars.PSR and SandboxVars.PSR.solarPanelEfficiency) or 25
    return 83 * ((eff * 1.25) / 100)
end

--- Build groups from a PowerBank server object (SP / coop-host direct path).
--- Returns array of { dtype, total, activeCount, rate, devices=[{x,y,z,rate,active}] }
--- ⚡ PERF 2026-08-04 : `dl` OPTIONNEL. Après un toggle, `pb:updateDrain()` vient de produire cette
--- liste exacte et de la ranger dans `pb.deviceList` ⇒ la recalculer était un 3ᵉ balayage complet
--- de la structure pour un seul clic (le coût est LINÉAIRE en surface du bâtiment).
--- ✅ Bonus de justesse : la conso facturée et la liste affichée viennent désormais du MÊME relevé.
---@param dl table|nil deviceList déjà résolue
local function buildGroupsFromPB(pb, dl)
    local sq = pb:getSquare()
    if not sq then return {} end
    if not dl then
        local building = sq:getBuilding()
        -- Mirror updateDrain / the server device list: building scan inside a vanilla building,
        -- vanilla-radius scan otherwise (player-built base) — so the Computer lists & manages the
        -- same devices the bank actually powers and drains.
        local drainUnused
        if building then
            drainUnused, dl = pb:getDrainBuilding(sq, building)
        else
            drainUnused, dl = pb:getDrainVanilla(sq)
        end
    end
    if not dl then return {} end

    local groups = {}
    local order  = {}

    for _, dev in ipairs(dl) do
        if not groups[dev.dtype] then
            groups[dev.dtype] = { dtype=dev.dtype, total=0, activeCount=0, rate=0, devices={}, seen={} }
            order[#order + 1] = dev.dtype
        end
        local g   = groups[dev.dtype]
        local sqk = dev.x .. "_" .. dev.y .. "_" .. dev.z
        if not g.seen[sqk] then
            g.seen[sqk]             = true
            g.total                 = g.total + 1
            if dev.active then g.activeCount = g.activeCount + 1 end
            g.devices[#g.devices+1] = { x=dev.x, y=dev.y, z=dev.z, rate=dev.rate, active=dev.active }
        else
            for _, e in ipairs(g.devices) do
                if e.x==dev.x and e.y==dev.y and e.z==dev.z then
                    e.rate = e.rate + dev.rate; break
                end
            end
        end
        if dev.active then g.rate = g.rate + dev.rate end
    end

    local result = {}
    for _, dtype in ipairs(order) do
        local g = groups[dtype]; g.seen = nil
        result[#result + 1] = g
    end
    return result
end

--- Flatten groups + expanded state into ordered row list.
local function buildAllRows(groups, expanded)
    local rows = {}
    for _, grp in ipairs(groups) do
        rows[#rows + 1] = { kind="group", grp=grp }
        if expanded[grp.dtype] then
            for _, dev in ipairs(grp.devices) do
                rows[#rows + 1] = { kind="device", dev=dev, grp=grp }
            end
        end
    end
    return rows
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Constructor
-- ──────────────────────────────────────────────────────────────────────────────

function PSRComputerPanel:new(x, y, width, height)
    local o = ISCollapsableWindow.new(self, x, y, width, height)
    o.title   = getText("IGUI_PSRComputerPanel_Title")
    o:setResizable(false)
    o.L = computeLayout()   -- scaled layout for current Font Size
    o.bx, o.by, o.bz = 0, 0, 0
    o.cx, o.cy, o.cz = nil, nil, nil   -- computer square (proximity check)
    o.player   = 0
    o.devices  = {}   -- array of groups
    o.expanded = {}   -- dtype = true when group row is expanded
    o.page     = 1
    o.allRows  = {}
    o.btnRows  = {}
    o.loaded   = false
    -- Horloges REELLES en millisecondes (voir update()). Les anciens compteurs de FRAMES
    -- (`autoRefreshTimer`, `proximityTimer`, `linkCheckTimer`) sont retires : leur periode variait
    -- du simple au quintuple selon le framerate du joueur.
    local nowNew = getTimestampMs()
    o.autoRefreshAt = nowNew + 10000
    o.proximityAt   = nowNew + 2000
    o.linkCheckAt   = nowNew + 500
    PSRComputerPanel.instance = o
    return o
end

-- ──────────────────────────────────────────────────────────────────────────────
-- createChildren
-- ──────────────────────────────────────────────────────────────────────────────

function PSRComputerPanel:createChildren()
    ISCollapsableWindow.createChildren(self)
    local th = self:titleBarHeight()
    local L  = self.L
    local btnH    = math.floor(22 * L.scale)
    local btnW    = math.floor(80 * L.scale)
    local pageBtn = math.floor(28 * L.scale)

    -- Loading label
    self.lblLoading = ISLabel:new(
        L.colType, th + math.floor(28 * L.scale) + 2, 20,
        getText("IGUI_PSRComputerPanel_Loading"),
        1, 0.9, 0.5, 1, UIFont.Small, true
    )
    self.lblLoading:initialise()
    self:addChild(self.lblLoading)

    -- Pagination row: [<]  1 / 3  [>]
    local paginY = self.height - math.floor(56 * L.scale)
    self.btnPrev = ISButton:new(L.colType, paginY, pageBtn, btnH, "<", self, PSRComputerPanel.onPrevPage)
    self.btnPrev:initialise()
    self.btnPrev:setVisible(false)
    self:addChild(self.btnPrev)

    self.lblPage = ISLabel:new(L.colType + math.floor(34 * L.scale), paginY + 3, 20, "", 1, 1, 1, 1, UIFont.Small, false)
    self.lblPage:initialise()
    self.lblPage:setVisible(false)
    self:addChild(self.lblPage)

    self.btnNext = ISButton:new(L.colType + math.floor(90 * L.scale), paginY, pageBtn, btnH, ">", self, PSRComputerPanel.onNextPage)
    self.btnNext:initialise()
    self.btnNext:setVisible(false)
    self:addChild(self.btnNext)

    -- Action buttons
    self.btnRefresh = ISButton:new(
        self.width - math.floor(172 * L.scale), self.height - math.floor(28 * L.scale), btnW, btnH,
        getText("IGUI_PSRComputerPanel_Refresh"), self, PSRComputerPanel.onRefresh
    )
    self.btnRefresh:initialise()
    self:addChild(self.btnRefresh)

    self.btnClose = ISButton:new(
        self.width - math.floor(86 * L.scale), self.height - math.floor(28 * L.scale), btnW, btnH,
        getText("IGUI_PSRComputerPanel_Close"), self, PSRComputerPanel.close
    )
    self.btnClose:initialise()
    self:addChild(self.btnClose)
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Data fetch (dual path: SP/host direct, dedicated MP via network)
-- ──────────────────────────────────────────────────────────────────────────────

function PSRComputerPanel:fetchDeviceList()
    local srv = PSR.PBSystem_Server
    if srv then
        local pb = srv:getLuaObjectAt(self.bx, self.by, self.bz)
        if not pb then self:populateDevices({}); return end
        self:populateDevices(buildGroupsFromPB(pb))
    else
        local char = getSpecificPlayer(self.player)
        if char then
            sendClientCommand(char, "psr_powerbank", "requestDeviceList",
                { x=self.bx, y=self.by, z=self.bz })
        end
    end
end

-- ──────────────────────────────────────────────────────────────────────────────
-- populateDevices — store data then rebuild from page 1
-- ──────────────────────────────────────────────────────────────────────────────

function PSRComputerPanel:clearRows()
    for _, btn in ipairs(self.btnRows) do self:removeChild(btn) end
    self.btnRows = {}
end

-- Initial load: reset to page 1 (called by fetchDeviceList / OnOpen).
function PSRComputerPanel:populateDevices(devices)
    self.devices = devices
    self.loaded  = true
    self.page    = 1
    self.lblLoading:setVisible(false)
    self:rebuildView()
end

-- Control refresh: preserve current page (called after Disable / Enable action).
function PSRComputerPanel:refreshDevices(devices)
    self.devices = devices
    self.loaded  = true
    self.lblLoading:setVisible(false)
    self:rebuildView()  -- page unchanged
end

-- ──────────────────────────────────────────────────────────────────────────────
-- rebuildView — recreate buttons for the current page
-- ──────────────────────────────────────────────────────────────────────────────

function PSRComputerPanel:rebuildView()
    self:clearRows()
    local th      = self:titleBarHeight()
    local L       = self.L
    local expW    = math.floor(18 * L.scale)
    local goW     = math.floor(28 * L.scale)
    local headerY = math.floor(28 * L.scale)
    local allRows = buildAllRows(self.devices, self.expanded)
    self.allRows  = allRows
    local total   = #allRows
    local pages   = math.max(1, math.ceil(total / ROWS_PER_PAGE))
    self.page     = math.min(self.page, pages)
    local p0      = (self.page - 1) * ROWS_PER_PAGE + 1
    local p1      = math.min(total, p0 + ROWS_PER_PAGE - 1)

    for i = p0, p1 do
        local row  = allRows[i]
        local rowY = th + headerY + (i - p0) * L.rowH

        if row.kind == "group" then
            local grp         = row.grp
            local isExp       = self.expanded[grp.dtype]
            local allOff      = grp.activeCount == 0
            local controllable = PSR_CONTROLLABLE[grp.dtype]

            -- Expand / collapse button
            local expBtn = ISButton:new(L.colExpand, rowY + 2, expW, L.rowH - 4,
                isExp and "-" or "+", self, PSRComputerPanel.onExpandToggle)
            expBtn.PSR_dtype = grp.dtype
            expBtn:initialise(); self:addChild(expBtn)
            self.btnRows[#self.btnRows + 1] = expBtn

            -- Group Disable / Enable (only for controllable types)
            if controllable then
                local grpBtn = ISButton:new(L.colBtn, rowY + 2, self.width - L.colBtn - 8, L.rowH - 4,
                    allOff and getText("IGUI_PSRComputerPanel_Enable")
                           or getText("IGUI_PSRComputerPanel_Disable"),
                    self, PSRComputerPanel.onToggleGroup)
                grpBtn.PSR_dtype = grp.dtype
                grpBtn.PSR_on    = allOff  -- clicking Enable → on=true, Disable → on=false
                grpBtn:initialise(); self:addChild(grpBtn)
                self.btnRows[#self.btnRows + 1] = grpBtn
            end

        else  -- kind == "device"
            local dev = row.dev
            local grp = row.grp

            -- "Go" button: teleport player to device square
            local goBtn = ISButton:new(L.colGo, rowY + 2, goW, L.rowH - 4,
                getText("IGUI_PSRComputerPanel_Go"), self, PSRComputerPanel.onGoToDevice)
            goBtn.PSR_gx = dev.x
            goBtn.PSR_gy = dev.y
            goBtn.PSR_gz = dev.z
            goBtn:initialise(); self:addChild(goBtn)
            self.btnRows[#self.btnRows + 1] = goBtn

            if PSR_CONTROLLABLE[grp.dtype] then
                local devBtn = ISButton:new(L.colDevBtn, rowY + 2, self.width - L.colDevBtn - 8, L.rowH - 4,
                    dev.active and getText("IGUI_PSRComputerPanel_Disable")
                               or getText("IGUI_PSRComputerPanel_Enable"),
                    self, PSRComputerPanel.onToggleDevice)
                devBtn.PSR_x     = dev.x
                devBtn.PSR_y     = dev.y
                devBtn.PSR_z     = dev.z
                devBtn.PSR_dtype = grp.dtype
                devBtn.PSR_on    = not dev.active  -- toggle
                devBtn:initialise(); self:addChild(devBtn)
                self.btnRows[#self.btnRows + 1] = devBtn
            end
        end
    end

    -- Pagination controls
    if pages > 1 then
        self.btnPrev:setVisible(self.page > 1)
        self.btnNext:setVisible(self.page < pages)
        self.lblPage.name = string.format("%d / %d", self.page, pages)
        self.lblPage:setVisible(true)
    else
        self.btnPrev:setVisible(false)
        self.btnNext:setVisible(false)
        self.lblPage:setVisible(false)
    end
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Callbacks
-- ──────────────────────────────────────────────────────────────────────────────

function PSRComputerPanel:onExpandToggle(btn)
    local dtype = btn.PSR_dtype
    self.expanded[dtype] = not self.expanded[dtype] and true or nil
    self.page = 1
    self:rebuildView()
end

function PSRComputerPanel:onToggleGroup(btn)
    self:applyControl(btn.PSR_dtype, nil, nil, nil, btn.PSR_on)
end

function PSRComputerPanel:onToggleDevice(btn)
    self:applyControl(btn.PSR_dtype, btn.PSR_x, btn.PSR_y, btn.PSR_z, btn.PSR_on)
end

function PSRComputerPanel:onGoToDevice(btn)
    local chr = getSpecificPlayer(self.player)
    if not chr then return end
    local sq = getSquare(btn.PSR_gx, btn.PSR_gy, btn.PSR_gz)
    if not sq then return end
    -- Use AdjacentFreeTileFinder (vanilla ISBBQMenu pattern) to find the nearest
    -- accessible square next to the device — the device square itself may be blocked
    -- (lamp in wall, appliance, furniture). Falls back to exact square if none found.
    local dest = AdjacentFreeTileFinder.Find(sq, chr)
    if dest then
        ISTimedActionQueue.add(ISWalkToTimedAction:new(chr, dest))
    else
        ISTimedActionQueue.add(ISPathFindAction:pathToLocationF(chr, sq:getX(), sq:getY(), sq:getZ()))
    end
end

--- Toggle wall switches using ISToggleLightAction (exact vanilla path).
--- Using the TimedAction framework captures any Java-level cascade that
--- direct toggle() from plain Lua context misses (start→faceThisObject, perform→complete).
--- Guard: only queue if current state ≠ desired state.
local function clientToggleSwitches(chr, devices, x, y, z, on)
    local function tryToggle(sx, sy, sz)
        local sq = getSquare(sx, sy, sz)
        if not sq then return end
        local objs = sq:getObjects()
        for i = 0, objs:size() - 1 do
            local obj = objs:get(i)
            if instanceof(obj, "IsoLightSwitch") and obj:isActivated() ~= on then
                ISTimedActionQueue.add(ISToggleLightAction:new(chr, obj))
            end
        end
    end
    if x then
        tryToggle(x, y, z)
    else
        -- Group: iterate cached device list for dtype="switch"
        for _, grp in ipairs(devices) do
            if grp.dtype == "switch" then
                for _, dev in ipairs(grp.devices) do
                    tryToggle(dev.x, dev.y, dev.z)
                end
            end
        end
    end
end

--- Send control command to the server (group or individual device).
--- x/y/z nil = group command; x/y/z set = individual device command.
function PSRComputerPanel:applyControl(dtype, x, y, z, on)
    local srv = PSR.PBSystem_Server
    -- Fridges/freezers toggle via container:setType, which does NOT auto-replicate over the network.
    local coolingType = (dtype == "fridge" or dtype == "freezer" or dtype == "fridgeFreezer")
    if srv then
        -- SP / coop-host: direct server access (instant UI refresh — no command round-trip).
        -- Wall switches: ISToggleLightAction works here (same process, adjacency is fine).
        if dtype == "switch" then
            local chr = getSpecificPlayer(self.player)
            if chr then clientToggleSwitches(chr, self.devices, x, y, z, on) end
        end
        local pb = srv:getLuaObjectAt(self.bx, self.by, self.bz)
        if pb then
            if x then
                pb:controlDevice(x, y, z, dtype, on)
            else
                pb:controlDeviceGroup(dtype, on)
            end
            pb:updateDrain()
            pb:saveData(true)
            -- Refresh UI immediately, preserving current page.
            -- ⚡ PERF : on réutilise la liste que `updateDrain()` vient de produire (3ᵉ scan supprimé).
            self:refreshDevices(buildGroupsFromPB(pb, pb.deviceList))
            -- Fridges/freezers swap container type via setType, which does NOT auto-replicate.
            -- On a coop HOST, broadcast the swap so remote clients apply it too (the host already
            -- applied it directly above; setType is idempotent → the host receiving it is a no-op).
            if coolingType and isServer() then
                local devices
                if x then
                    devices = { { x = x, y = y, z = z } }
                else
                    devices = {}
                    for _, d in ipairs(pb.deviceList or {}) do
                        if d.dtype == dtype then devices[#devices + 1] = { x = d.x, y = d.y, z = d.z } end
                    end
                end
                if #devices > 0 then
                    sendServerCommand("PSR", "applyDeviceToggle", { dtype = dtype, on = on, devices = devices })
                end
            end
        end
    else
        -- Dedicated MP: send to server; visual toggle arrives via applyDeviceToggle.
        -- Wall switches in dedicated: ISToggleLightAction fails (adjacency check);
        -- server sends applyDeviceToggle → client calls obj:toggle() directly.
        local char = getSpecificPlayer(self.player)
        if char then
            if x then
                sendClientCommand(char, "psr_powerbank", "controlDevice", {
                    bank = { x=self.bx, y=self.by, z=self.bz },
                    dtype=dtype, x=x, y=y, z=z, on=on,
                })
            else
                sendClientCommand(char, "psr_powerbank", "controlDeviceGroup", {
                    bank = { x=self.bx, y=self.by, z=self.bz },
                    dtype=dtype, on=on,
                })
            end
            -- Server will send back updated deviceList via OnServerCommand
        end
    end
end

function PSRComputerPanel:onPrevPage()
    if self.page > 1 then self.page = self.page - 1; self:rebuildView() end
end

function PSRComputerPanel:onNextPage()
    local pages = math.max(1, math.ceil(#self.allRows / ROWS_PER_PAGE))
    if self.page < pages then self.page = self.page + 1; self:rebuildView() end
end

function PSRComputerPanel:onRefresh()
    self.loaded   = false
    self.expanded = {}
    self.page     = 1
    self.lblLoading:setVisible(true)
    self:clearRows()
    self.btnPrev:setVisible(false)
    self.btnNext:setVisible(false)
    self.lblPage:setVisible(false)
    self:fetchDeviceList()
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Auto-refresh (~10 s — preserves page and expanded groups)
-- ──────────────────────────────────────────────────────────────────────────────

function PSRComputerPanel:update()
    ISCollapsableWindow.update(self)

    -- Proximity check: close panel if player moves more than 5 tiles from the computer.
    -- Checked every ~2 s (60 frames) to keep per-frame cost negligible.
    -- Même conversion que l'auto-refresh ci-dessous : ces compteurs étaient en FRAMES, donc leur
    -- période réelle variait du simple au quintuple selon le framerate. Le travail par tick est ici
    -- négligeable, mais on balaye la famille plutôt que le seul cas coûteux — c'est exactement le
    -- défaut « corrigé à un endroit, pas à son jumeau » que cet audit a mis en évidence.
    if self.cx then
        local nowP = getTimestampMs()
        self.proximityAt = self.proximityAt or (nowP + 2000)
        if nowP >= self.proximityAt then
            self.proximityAt = nowP + 2000   -- 2 s réelles
            local pchr = getSpecificPlayer(self.player)
            if pchr then
                local psq = pchr:getSquare()
                if psq then
                    local dx = psq:getX() - self.cx
                    local dy = psq:getY() - self.cy
                    if dx * dx + dy * dy > 4 then   -- ~2-tile radius (RP: must stay at the computer)
                        self:close()
                        return
                    end
                end
            end

        end
    end

    -- La fenêtre doit se fermer quand le lien qu'elle pilote n'existe plus (signal Commandeur,
    -- 2026-08-04 : délier l'ordinateur laissait le panneau ouvert sur une liaison morte, et
    -- manipulable). Couvre TOUS les chemins de déliaison — depuis l'ordinateur, depuis la bank,
    -- ou par un autre joueur en MP : une fenêtre ne doit pas dépendre de qui l'a invalidée pour
    -- savoir qu'elle l'est.
    --
    -- ⏱️ Timer PROPRE, à ~0,5 s, et volontairement plus court que celui de la proximité (~2 s) :
    -- à 2 s la fermeture se voyait « en retard » et le Commandeur a signalé, à raison, que ça
    -- ferait une question de joueur. Une FAQ sert à expliquer un comportement IRRÉDUCTIBLE —
    -- celui-ci était réductible, donc on le supprime au lieu de le documenter. Le coût est nul :
    -- une case porte une poignée d'objets, deux passages par seconde ne se mesurent pas.
    -- On ne ferme toujours PAS au clic : la déliaison est une TimedAction interruptible, fermer
    -- au clic fermerait sur une intention et non sur un fait.
    if self.bx and self.cx then
        local nowL = getTimestampMs()
        self.linkCheckAt = self.linkCheckAt or (nowL + 500)
        if nowL >= self.linkCheckAt then
            self.linkCheckAt = nowL + 500   -- 0,5 s réelles (était 15 frames : 0,1 s à 144 fps)
            local csq = getSquare(self.cx, self.cy, self.cz)
            -- ⚠️ Case non chargée = on NE SAIT PAS : on ne ferme rien sur une absence d'info.
            if csq then
                local stillLinked = false
                local objs = csq:getObjects()
                for i = 0, objs:size() - 1 do
                    local obj = objs:get(i)
                    local lb = obj and obj:getModData().PSR_linkedBank
                    if lb and lb.x == self.bx and lb.y == self.by and lb.z == self.bz then
                        stillLinked = true
                        break
                    end
                end
                if not stillLinked then
                    self:close()
                    return
                end
            end
        end
    end

    if not self.loaded then return end
    -- 🔴 COMPTEUR DE FRAMES → HORLOGE REELLE (audit 2026-08-04).
    -- Valait `self.autoRefreshTimer + 1` avec un seuil a 300 et le commentaire « ~10 s at 30 fps ».
    -- `update()` est appele UNE FOIS PAR FRAME : a 144 fps la periode reelle tombait a **~2 s**,
    -- soit **5x plus** de scans complets du batiment — et, en dedie, 5x plus d'aller-retours reseau,
    -- avec une charge serveur proportionnelle. *Plus le joueur avait de FPS, plus il coutait cher.*
    -- C'est le motif exact de l'incident PFR v1.21 : un travail lourd cadence par l'affichage.
    local now = getTimestampMs()
    self.autoRefreshAt = self.autoRefreshAt or (now + 10000)
    if now >= self.autoRefreshAt then
        self.autoRefreshAt = now + 10000   -- 10 s REELLES, quel que soit le framerate
        self:silentFetch()
    end
end

-- Refresh without resetting page or expanded groups (used by auto-refresh and OnServerCommand).
function PSRComputerPanel:silentFetch()
    local srv = PSR.PBSystem_Server
    if srv then
        local pb = srv:getLuaObjectAt(self.bx, self.by, self.bz)
        if pb then self:refreshDevices(buildGroupsFromPB(pb)) end
    else
        -- Dedicated MP: send request; response arrives via OnServerCommand → refreshDevices
        local char = getSpecificPlayer(self.player)
        if char then
            sendClientCommand(char, "psr_powerbank", "requestDeviceList",
                { x=self.bx, y=self.by, z=self.bz })
        end
    end
end

-- ──────────────────────────────────────────────────────────────────────────────
-- render
-- ──────────────────────────────────────────────────────────────────────────────

function PSRComputerPanel:render()
    ISCollapsableWindow.render(self)
    if not self.loaded then return end

    local th      = self:titleBarHeight()
    local L       = self.L
    local headerY = math.floor(28 * L.scale)
    local allRows = self.allRows
    local p0      = (self.page - 1) * ROWS_PER_PAGE + 1
    local p1      = math.min(#allRows, p0 + ROWS_PER_PAGE - 1)

    -- Column headers
    self:drawText(getText("IGUI_PSRComputerPanel_ColDevice"), L.colType,   th + 6, 1, 0.9, 0.4, 1, UIFont.Small)
    self:drawText(getText("IGUI_PSRComputerPanel_ColCount"),  L.colCount,  th + 6, 1, 0.9, 0.4, 1, UIFont.Small)
    self:drawText(getText("IGUI_PSRComputerPanel_ColDrain"),  L.colDrain,  th + 6, 1, 0.9, 0.4, 1, UIFont.Small)
    self:drawText(getText("IGUI_PSRComputerPanel_ColStatus"), L.colStatus, th + 6, 1, 0.9, 0.4, 1, UIFont.Small)
    self:drawRect(0, th + math.floor(24 * L.scale), self.width, 1, 1, 0.5, 0.5, 0.5)

    -- Rows
    for i = p0, p1 do
        local row  = allRows[i]
        local rowY = th + headerY + (i - p0) * L.rowH

        if i % 2 == 0 then
            self:drawRect(0, rowY, self.width, L.rowH, 0.4, 0.12, 0.12, 0.12)
        end

        if row.kind == "group" then
            local grp    = row.grp
            local allOff = grp.activeCount == 0
            local allOn  = grp.activeCount == grp.total

            -- Type name (gray if all off)
            local nr, ng, nb = 1, 1, 1
            if allOff then nr, ng, nb = 0.5, 0.5, 0.5 end
            self:drawText(getText("IGUI_PSRDeviceType_" .. grp.dtype), L.colType, rowY + 4, nr, ng, nb, 1, UIFont.Small)

            -- Count: "(active/total)" when partial, "(n)" when all same
            local countText
            if allOn or allOff then
                countText = "(" .. grp.total .. ")"
            else
                countText = "(" .. grp.activeCount .. "/" .. grp.total .. ")"
            end
            self:drawText(countText, L.colCount, rowY + 4, 0.75, 0.75, 0.75, 1, UIFont.Small)

            -- Drain (active devices only)
            if grp.rate > 0 then
                self:drawText(fmtAh(grp.rate), L.colDrain, rowY + 4, 0.9, 0.7, 0.3, 1, UIFont.Small)
            end

            -- Status
            if allOff then
                self:drawText(getText("IGUI_PSRComputerPanel_StatusOff"), L.colStatus, rowY + 4, 1, 0.35, 0.35, 1, UIFont.Small)
            elseif allOn then
                self:drawText(getText("IGUI_PSRComputerPanel_StatusOn"),  L.colStatus, rowY + 4, 0.35, 1, 0.35, 1, UIFont.Small)
            else
                self:drawText(getText("IGUI_PSRComputerPanel_StatusPartial"), L.colStatus, rowY + 4, 1, 0.75, 0.2, 1, UIFont.Small)
            end

        else  -- device row
            local dev = row.dev
            local grp = row.grp

            -- Coords (gray if off)
            local dr, dg, db = dev.active and 0.8 or 0.45, dev.active and 0.8 or 0.45, dev.active and 0.8 or 0.45
            self:drawText("  -> " .. dev.x .. "," .. dev.y, L.colType,  rowY + 4, dr, dg, db, 1, UIFont.Small)
            self:drawText(fmtAh(dev.rate),                  L.colDrain, rowY + 4, 0.65, 0.55, 0.35, 1, UIFont.Small)

            if dev.active then
                self:drawText(getText("IGUI_PSRComputerPanel_StatusOn"),  L.colStatus, rowY + 4, 0.35, 1, 0.35, 1, UIFont.Small)
            else
                self:drawText(getText("IGUI_PSRComputerPanel_StatusOff"), L.colStatus, rowY + 4, 1, 0.35, 0.35, 1, UIFont.Small)
            end
        end
    end

    if #allRows == 0 then
        self:drawText(getText("IGUI_PSRComputerPanel_NoDevices"), L.colType, th + headerY + 5, 0.8, 0.8, 0.8, 1, UIFont.Small)
    end

    -- Solar panel output (per-panel nominal at full sun). Right-aligned on the pagination
    -- row, whose buttons sit on the left, so it never collides with them or the device table.
    local outTxt = getText("IGUI_PSRComputerPanel_PanelOutput") .. " " .. string.format("%.1f", perPanelOutput()) .. " Ah"
    self:drawTextRight(outTxt, self.width - math.floor(10 * L.scale), self.height - math.floor(54 * L.scale), 0.5, 1, 0.5, 1, UIFont.Small)
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Open / close
-- ──────────────────────────────────────────────────────────────────────────────

function PSRComputerPanel:close()
    self:removeFromUIManager()
    if JoypadState and JoypadState.players and
       JoypadState.players[(self.player or 0) + 1] then
        setPrevFocusForPlayer(self.player)
    end
end

function PSRComputerPanel.OnOpen(player, computer)
    local linkedBank = computer:getModData().PSR_linkedBank
    if not linkedBank then return end

    local instance = PSRComputerPanel.instance
    if not instance then
        -- Pre-compute layout to know the right window size for current Font Size.
        -- :new() will recompute and store o.L (same result).
        local layout = computeLayout()
        local winH = math.floor(20 * layout.scale) + math.floor(28 * layout.scale)
                   + ROWS_PER_PAGE * layout.rowH
                   + math.floor(28 * layout.scale) + math.floor(34 * layout.scale) + 6
        instance = PSRComputerPanel:new(80, 80, layout.winW, winH)
        if ISLayoutManager and ISLayoutManager.RegisterWindow then
            ISLayoutManager.RegisterWindow("PSRComputerPanel", PSRComputerPanel, instance)
        end
    end

    instance.player   = player
    instance.bx       = linkedBank.x
    instance.by       = linkedBank.y
    instance.bz       = linkedBank.z
    -- Store computer square for proximity check
    local compSq = computer:getSquare()
    if compSq then
        instance.cx = compSq:getX()
        instance.cy = compSq:getY()
        instance.cz = compSq:getZ()
    end
    instance.loaded   = false
    instance.devices  = {}
    instance.expanded = {}
    instance.page     = 1
    instance.allRows  = {}
    -- Horloges REELLES (ms), pas des compteurs de frames — voir update(). On les repousse a
    -- l'ouverture pour ne pas declencher un `silentFetch` immediat juste apres le `fetchDeviceList`
    -- explicite ci-dessous (l'instance est un singleton reutilise d'une ouverture a l'autre).
    local nowOpen = getTimestampMs()
    instance.autoRefreshAt = nowOpen + 10000
    instance.proximityAt   = nowOpen + 2000
    instance.linkCheckAt   = nowOpen + 500
    if instance.lblLoading then instance.lblLoading:setVisible(true)  end
    if instance.btnPrev    then instance.btnPrev:setVisible(false)    end
    if instance.btnNext    then instance.btnNext:setVisible(false)    end
    if instance.lblPage    then instance.lblPage:setVisible(false)    end
    instance:clearRows()
    instance:addToUIManager()
    instance:fetchDeviceList()
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Server → client (dedicated MP: receive updated device list)
-- ──────────────────────────────────────────────────────────────────────────────

Events.OnServerCommand.Add(function(module, command, args)
    if module ~= "PSR" then return end

    if command == "deviceList" then
        local instance = PSRComputerPanel.instance
        if not instance then return end
        if args.bx ~= instance.bx or args.by ~= instance.by or args.bz ~= instance.bz then return end
        instance:refreshDevices(args.devices or {})

    elseif command == "applyDeviceToggle" then
        -- Server instructs this client to apply the visual toggle using native client-side APIs.
        -- Client-side calls let PZ handle its own sync (transmitModData client→server→all clients).
        if not args.devices then return end
        for _, dev in ipairs(args.devices) do
            local sq = getSquare(dev.x, dev.y, dev.z)
            if sq then
                local objs = sq:getObjects()
                for i = 0, objs:size() - 1 do
                    local obj = objs:get(i)
                    if obj then
                        if args.dtype == "light" then
                            if instanceof(obj, "IsoLightSwitch") then
                                -- Avoid toggling wall switches (dtype "switch" is handled separately)
                                local sq2 = obj:getSquare()
                                local isWallSwitch = sq2 and sq2.getProperties
                                    and sq2:getProperties():get("CustomName") == "Switch"
                                if not isWallSwitch then
                                    -- toggle() fires Java-level network sync
                                    if obj:isActivated() ~= args.on then obj:toggle() end
                                end
                            end
                        elseif args.dtype == "tv" then
                            if instanceof(obj, "IsoTelevision") then
                                -- Same fix as the server-side psrSetDeviceState: refresh the cached
                                -- power flag first, or vanilla's own tick reverts IsTurnedOn shortly after.
                                if obj.checkHaveElectricity then obj:checkHaveElectricity() end
                                local dd = obj:getDeviceData()
                                if dd then dd:setIsTurnedOn(args.on); obj:transmitModData() end
                            end
                        elseif args.dtype == "radio" then
                            if instanceof(obj, "IsoRadio") then
                                if obj.checkHaveElectricity then obj:checkHaveElectricity() end
                                local dd = obj:getDeviceData()
                                if dd then dd:setIsTurnedOn(args.on); obj:transmitModData() end
                            end
                        elseif args.dtype == "washer" then
                            if instanceof(obj, "IsoClothingWasher") or instanceof(obj, "IsoStackedWasherDryer") then
                                obj:setActivated(args.on); obj:transmitModData()
                            end
                        elseif args.dtype == "dryer" then
                            if instanceof(obj, "IsoClothingDryer") or instanceof(obj, "IsoCombinationWasherDryer") then
                                obj:setActivated(args.on); obj:transmitModData()
                            end
                        elseif args.dtype == "switch" then
                            -- Direct toggle from Lua (no adjacency needed in dedicated MP).
                            -- Known B42 piège: ceiling light GroupName cascade may not
                            -- always fire — standalone switches reliably toggle.
                            if instanceof(obj, "IsoLightSwitch") then
                                if obj:isActivated() ~= args.on then obj:toggle() end
                            end
                        elseif args.dtype == "coldunit" then
                            -- PFR Cold Unit cross-mod support. Soft check on modData tag —
                            -- no runtime dependency on PFR being loaded.
                            if obj.hasModData and obj:hasModData() and obj:getModData().PFR_isColdUnit == true then
                                obj:getModData().PFR_on = args.on
                                obj:transmitModData()
                            end
                        elseif args.dtype == "fridge" or args.dtype == "freezer" or args.dtype == "fridgeFreezer" then
                            -- Apply the container type swap client-side so every client sees the
                            -- fridge/freezer turn off/on (cooling + container title). Same "_off" types
                            -- as the Fridges Off! mod; PZ persists the container type in the save.
                            if obj.getContainerByType then
                                -- Only act on objects matching the requested dtype: a fridge and a
                                -- freezer can be two distinct objects on the same tile → don't swap the
                                -- wrong one (mirrors the server-side psrGetDeviceType classification).
                                local hasF = (obj:getContainerByType("fridge")  ~= nil) or (obj:getContainerByType("fridge_off")  ~= nil)
                                local hasZ = (obj:getContainerByType("freezer") ~= nil) or (obj:getContainerByType("freezer_off") ~= nil)
                                local objType = (hasF and hasZ) and "fridgeFreezer" or (hasF and "fridge") or (hasZ and "freezer") or nil
                                if objType == args.dtype then
                                    local fc = obj:getContainerByType(args.on and "fridge_off" or "fridge")
                                    if fc then fc:setType(args.on and "fridge" or "fridge_off") end
                                    local zc = obj:getContainerByType(args.on and "freezer_off" or "freezer")
                                    if zc then zc:setType(args.on and "freezer" or "freezer_off") end
                                    if obj.checkHaveElectricity then obj:checkHaveElectricity() end
                                    -- Refresh open loot windows so an open fridge UI isn't left stale.
                                    local pd = getPlayer() and getPlayerData(getPlayer():getPlayerNum())
                                    if pd then
                                        if pd.playerInventory then pd.playerInventory:refreshBackpacks() end
                                        if pd.lootInventory   then pd.lootInventory:refreshBackpacks()   end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

PSR.ComputerPanel = PSRComputerPanel
