--[[
    TMJukeboxWindow.lua  (client)

    Control window for a TM_Jukebox world object.

    Controls:
      - Prev / Play-Stop toggle / Skip
      - shared jukebox volume + client volume toggle (MP)
      - Playlist: every track in the box; double-click a row to play it,
        drag a row onto the queue list to enqueue it (dropped between the
        two queue rows the cursor hovers over)
      - Queue mode checkbox: when on, playback loops the queued songs and
        the queue list is shown; when off the list is hidden (queue kept)
      - Queue list: double-click to play that entry, right-click to remove,
        drag a row up/down to reorder the queue

    Media management happens through the loot window - the jukebox is a
    media-only container you drop cassettes / vinyl / CDs into.
]]

require "ISUI/ISCollapsableWindow"
-- ISVolumeBar is a vanilla global by mod load time; require path fails in B42 (WARN spam).
require "ISUI/ISScrollingListBox"
require "TMJukeboxDefs"

TMJukeboxWindow = ISCollapsableWindow:derive("TMJukeboxWindow")
TMJukeboxWindow.instances = {}

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local BTN_HGT   = FONT_HGT_SMALL + 8
local PAD       = 10
local LIST_HGT  = FONT_HGT_SMALL * 10
local QUEUE_HGT = FONT_HGT_SMALL * 7
local HDR_HGT   = FONT_HGT_SMALL + 2

local COLOR_PLAYING = { r = 0.4, g = 1.0, b = 0.4, a = 1 }

function TMJukeboxWindow.activate(player, jukeboxObj)
    local playerNum = player:getPlayerNum()
    local win = TMJukeboxWindow.instances[playerNum]
    if not win then
        local w = 300 + (getCore():getOptionFontSizeReal() * 30)
        win = TMJukeboxWindow:new(120, 120, w, 200, player)
        win:initialise()
        win:instantiate()
        TMJukeboxWindow.instances[playerNum] = win
    end
    win.player  = player
    win.jukebox = jukeboxObj
    win._playlist = nil
    win._playlistMs = nil
    win._trackSig = nil
    win._queueSig = nil
    win:addToUIManager()
    win:setVisible(true)
    if TMJukeboxAudio then TMJukeboxAudio.register(jukeboxObj) end
    return win
end

function TMJukeboxWindow:createChildren()
    ISCollapsableWindow.createChildren(self)

    local th = self:titleBarHeight()
    local y = th + PAD + FONT_HGT_SMALL * 2 + 8   -- room for status lines
    local w = self.width

    -- Transport buttons: Prev | Play/Stop | Skip
    local btnW = math.floor((w - PAD * 4) / 3)
    self.prevBtn = ISButton:new(PAD, y, btnW, BTN_HGT,
        getText("IGUI_TM_Jukebox_Prev"), self, TMJukeboxWindow.onPrev)
    self.prevBtn:initialise()
    self:addChild(self.prevBtn)

    self.playBtn = ISButton:new(PAD * 2 + btnW, y, btnW, BTN_HGT,
        getText("IGUI_TM_Jukebox_Play"), self, TMJukeboxWindow.onPlayStop)
    self.playBtn:initialise()
    self:addChild(self.playBtn)

    self.skipBtn = ISButton:new(PAD * 3 + btnW * 2, y, btnW, BTN_HGT,
        getText("IGUI_TM_Jukebox_Skip"), self, TMJukeboxWindow.onSkip)
    self.skipBtn:initialise()
    self:addChild(self.skipBtn)

    y = y + BTN_HGT + PAD

    -- Volume slider
    self.volumeBar = ISVolumeBar:new(PAD, y, w - PAD * 2, BTN_HGT,
        TMJukeboxWindow.onVolumeChange, self)
    self.volumeBar:initialise()
    self.volumeBar:setVolumeSteps(10)
    self:addChild(self.volumeBar)

    y = y + BTN_HGT + 4

    -- Client volume toggle (local listening volume) - MP only: in true SP
    -- you're the only listener, the device volume already IS your volume.
    if isClient() then
        self.clientVolBox = ISTickBox:new(PAD, y, 18, 18, "", self, TMJukeboxWindow.onClientVolumeToggle)
        self.clientVolBox:initialise()
        self.clientVolBox:addOption(getText("IGUI_TCClientVolume"))
        self.clientVolBox.tooltip = getText("IGUI_TCClientVolume_Tooltip")
        self.clientVolBox.selected[1] = false
        self:addChild(self.clientVolBox)
        y = y + 18 + 4
    end

    -- Queue mode toggle
    self.queueBox = ISTickBox:new(PAD, y, 18, 18, "", self, TMJukeboxWindow.onQueueToggle)
    self.queueBox:initialise()
    self.queueBox:addOption(getText("IGUI_TM_Jukebox_QueueMode"))
    self.queueBox.tooltip = getText("IGUI_TM_Jukebox_QueueMode_Tooltip")
    self:addChild(self.queueBox)
    y = y + 18 + 4

    -- Shuffle toggle
    self.shuffleBox = ISTickBox:new(PAD, y, 18, 18, "", self, TMJukeboxWindow.onShuffleToggle)
    self.shuffleBox:initialise()
    self.shuffleBox:addOption(getText("IGUI_TM_Jukebox_Shuffle"))
    self.shuffleBox.tooltip = getText("IGUI_TM_Jukebox_Shuffle_Tooltip")
    self:addChild(self.shuffleBox)
    y = y + 18 + PAD

    -- Playlist: double-click a row to play it; drag a row onto the queue.
    self.trackList = ISScrollingListBox:new(PAD, y, w - PAD * 2, LIST_HGT)
    self.trackList:initialise()
    self.trackList:instantiate()
    self.trackList.itemheight = FONT_HGT_SMALL + 4
    self.trackList.font = UIFont.Small
    self.trackList.drawBorder = true
    self.trackList:setOnMouseDoubleClick(self, TMJukeboxWindow.onTrackDoubleClick)
    self.trackList.parentWindow = self
    -- Drag support: remember which row the press started on, and check
    -- where the button was released (the pressed element gets onMouseUp
    -- even when the cursor has left it; outside-release -> onMouseUpOutside).
    self.trackList.onMouseDown = function(lst, x, y2)
        ISScrollingListBox.onMouseDown(lst, x, y2)
        lst.parentWindow._dragIndex = lst.selected
        lst.parentWindow._dragStartX = getMouseX()
        lst.parentWindow._dragStartY = getMouseY()
    end
    self.trackList.onMouseUp = function(lst, x, y2)
        ISScrollingListBox.onMouseUp(lst, x, y2)
        lst.parentWindow:finishTrackDrag()
    end
    self.trackList.onMouseUpOutside = function(lst, x, y2)
        ISScrollingListBox.onMouseUpOutside(lst, x, y2)
        lst.parentWindow:finishTrackDrag()
    end
    self:addChild(self.trackList)
    self._trackListY = y
    y = y + LIST_HGT + PAD

    -- Queue list (hidden unless queue mode is on)
    self.queueList = ISScrollingListBox:new(PAD, y + HDR_HGT, w - PAD * 2, QUEUE_HGT)
    self.queueList:initialise()
    self.queueList:instantiate()
    self.queueList.itemheight = FONT_HGT_SMALL + 4
    self.queueList.font = UIFont.Small
    self.queueList.drawBorder = true
    self.queueList:setOnMouseDoubleClick(self, TMJukeboxWindow.onQueueDoubleClick)
    self.queueList.parentWindow = self
    self.queueList.onRightMouseUp = function(lst, x, y2)
        local row = lst:rowAt(x, y2)
        if row and row >= 1 and row <= #lst.items then
            lst.parentWindow:removeFromQueue(row)
        end
    end
    -- Drag-to-reorder support (same press/release pattern as the playlist).
    self.queueList.onMouseDown = function(lst, x, y2)
        ISScrollingListBox.onMouseDown(lst, x, y2)
        local row = lst:rowAt(x, y2)
        if row and row >= 1 and row <= #lst.items then
            lst.parentWindow._queueDragIndex = row
            lst.parentWindow._queueDragStartX = getMouseX()
            lst.parentWindow._queueDragStartY = getMouseY()
        end
    end
    self.queueList.onMouseUp = function(lst, x, y2)
        ISScrollingListBox.onMouseUp(lst, x, y2)
        lst.parentWindow:finishQueueDrag()
    end
    self.queueList.onMouseUpOutside = function(lst, x, y2)
        ISScrollingListBox.onMouseUpOutside(lst, x, y2)
        lst.parentWindow:finishQueueDrag()
    end
    self:addChild(self.queueList)

    self:applyLayout(false)
end

--- Show/hide the queue list and size the window accordingly.
function TMJukeboxWindow:applyLayout(queueVisible)
    if self._queueVisible == queueVisible then return end
    self._queueVisible = queueVisible
    self.queueList:setVisible(queueVisible)
    local bottom = self._trackListY + LIST_HGT + PAD
    if queueVisible then
        bottom = bottom + HDR_HGT + QUEUE_HGT + PAD
    end
    self:setHeight(bottom)
end

------------------------------------------------------------------------
--  Playlist / queue list refresh
------------------------------------------------------------------------

-- Light cache so render/update don't rebuild the playlist every frame.
function TMJukeboxWindow:getPlaylist()
    local now = getTimestampMs()
    if not self._playlist or not self._playlistMs or (now - self._playlistMs) > 500 then
        self._playlist = TMJukebox.buildPlaylist(self.jukebox)
        self._playlistMs = now
        self:refreshTrackList()
        self:refreshQueueList()
    end
    return self._playlist
end

function TMJukeboxWindow:refreshTrackList()
    if not self.trackList then return end
    local playlist = self._playlist or {}
    local sig = tostring(#playlist)
    for i = 1, #playlist do
        sig = sig .. "|" .. tostring(playlist[i].uid)
            .. (playlist[i].scratch and "~s" or "")
    end
    if sig == self._trackSig then return end
    self._trackSig = sig
    self.trackList:clear()
    for i = 1, #playlist do
        self.trackList:addItem(i .. ". " .. TMJukebox.entryLabel(playlist[i]), i)
    end
end

function TMJukeboxWindow:refreshQueueList()
    if not self.queueList or not self.jukebox then return end
    local d = TMJukebox.getData(self.jukebox)
    local q = d.queue or {}
    local playlist = self._playlist or {}
    local sig = tostring(#q) .. "@" .. tostring(#playlist)
    for i = 1, #q do
        sig = sig .. "|" .. tostring(q[i].uid or q[i].soundName)
    end
    if sig == self._queueSig then return end
    self._queueSig = sig
    self.queueList:clear()
    for i = 1, #q do
        -- Live label from the playlist entry (media tag + scratch state);
        -- fall back to the title stored at enqueue time.
        local idx = TMJukebox.findQueueEntryIndex(playlist, q[i])
        local label = idx and TMJukebox.entryLabel(playlist[idx])
            or tostring(q[i].title or q[i].soundName)
        self.queueList:addItem(i .. ". " .. label, i)
    end
end

--- Colour the playing row green in both lists (no selection forcing, so
--- user clicks/double-clicks are never overridden).
function TMJukeboxWindow:highlightPlaying(d)
    local playIdx = d.playIndex or 1
    if self.trackList then
        for i = 1, #self.trackList.items do
            local it = self.trackList.items[i]
            it.textColor = (d.isPlaying and it.item == playIdx) and COLOR_PLAYING or nil
        end
    end
    if self.queueList then
        local qp = d.queuePos or 0
        for i = 1, #self.queueList.items do
            local it = self.queueList.items[i]
            it.textColor = (d.isPlaying and d.queueMode and i == qp) and COLOR_PLAYING or nil
        end
    end
end

------------------------------------------------------------------------
--  Queue actions
------------------------------------------------------------------------

function TMJukeboxWindow:addToQueue(playlistIndex, insertPos)
    local obj = self.jukebox
    if not obj then return end
    local playlist = self:getPlaylist()
    local entry = playlist[playlistIndex]
    if not entry then return end
    local d = TMJukebox.getData(obj)
    d.queue = d.queue or {}
    local pos = insertPos or (#d.queue + 1)
    if pos < 1 then pos = 1 end
    if pos > #d.queue + 1 then pos = #d.queue + 1 end
    table.insert(d.queue, pos, { uid = entry.uid, soundName = entry.soundName, title = entry.title })
    -- Inserting at or before the playing queue entry shifts it down one.
    local qp = d.queuePos or 0
    if qp > 0 and pos <= qp then d.queuePos = qp + 1 end
    TMJukebox.transmit(obj)
    self._queueSig = nil
    self:refreshQueueList()
end

--- Move a queue entry: remove row `from` and re-insert it at slot `to`
--- (a slot is a gap between rows, 1 .. #queue+1, in pre-move numbering).
function TMJukeboxWindow:moveQueueEntry(from, to)
    local obj = self.jukebox
    if not obj then return end
    local d = TMJukebox.getData(obj)
    local q = d.queue
    if not q or not q[from] then return end
    if to == from or to == from + 1 then return end   -- dropped back in place
    local entry = table.remove(q, from)
    local dest = to
    if to > from then dest = to - 1 end
    table.insert(q, dest, entry)
    -- Keep queuePos pointing at the same song.
    local qp = d.queuePos or 0
    if qp > 0 then
        if qp == from then
            qp = dest
        else
            if qp > from then qp = qp - 1 end
            if qp >= dest then qp = qp + 1 end
        end
        d.queuePos = qp
    end
    TMJukebox.transmit(obj)
    self._queueSig = nil
    self:refreshQueueList()
end

function TMJukeboxWindow:removeFromQueue(row)
    local obj = self.jukebox
    if not obj then return end
    local d = TMJukebox.getData(obj)
    if not d.queue or not d.queue[row] then return end
    table.remove(d.queue, row)
    if (d.queuePos or 0) >= row then
        d.queuePos = (d.queuePos or 0) - 1
        if d.queuePos < 0 then d.queuePos = 0 end
    end
    TMJukebox.transmit(obj)
    self._queueSig = nil
    self:refreshQueueList()
end

function TMJukeboxWindow:onQueueToggle(index, selected)
    local obj = self.jukebox
    if not obj then return end
    local d = TMJukebox.getData(obj)
    d.queueMode = selected and true or false
    TMJukebox.transmit(obj)
    self:applyLayout(d.queueMode)
end

function TMJukeboxWindow:onShuffleToggle(index, selected)
    local obj = self.jukebox
    if not obj then return end
    local d = TMJukebox.getData(obj)
    d.shuffle = selected and true or false
    TMJukebox.transmit(obj)
end

function TMJukeboxWindow:onQueueDoubleClick(item)
    if type(item) ~= "number" then return end
    local obj = self.jukebox
    if not obj then return end
    local d = TMJukebox.getData(obj)
    local qEntry = d.queue and d.queue[item] or nil
    if not qEntry then return end
    local idx = TMJukebox.findQueueEntryIndex(self:getPlaylist(), qEntry)
    if not idx then return end
    d.queuePos = item
    self:startAt(idx)
end

--- Insertion slot (1 .. #queue+1) for the current mouse position over the
--- queue list, snapping to the nearer row edge. nil when not over the list.
function TMJukeboxWindow:queueDropPos()
    local lst = self.queueList
    if not lst or not self._queueVisible then return nil end
    local mx, my = getMouseX(), getMouseY()
    local ax, ay = lst:getAbsoluteX(), lst:getAbsoluteY()
    if mx < ax or mx > ax + lst:getWidth()
        or my < ay or my > ay + lst:getHeight() then
        return nil
    end
    local n = #lst.items
    if n == 0 then return 1 end
    local contentY = my - ay - lst:getYScroll()
    local slot = math.floor(contentY / lst.itemheight + 0.5) + 1
    if slot < 1 then slot = 1 end
    if slot > n + 1 then slot = n + 1 end
    return slot
end

--- Called when a press that started on the track list is released.
function TMJukeboxWindow:finishTrackDrag()
    local idx = self._dragIndex
    self._dragIndex = nil
    if not idx or idx < 1 then return end
    if not self._queueVisible or not self.queueList then return end
    -- Require an actual drag, not just a click.
    local dx = math.abs(getMouseX() - (self._dragStartX or 0))
    local dy = math.abs(getMouseY() - (self._dragStartY or 0))
    if dx < 6 and dy < 6 then return end
    -- Released over the queue list? Insert at the hovered gap.
    local pos = self:queueDropPos()
    if pos then
        self:addToQueue(idx, pos)
    end
end

--- Called when a press that started on the queue list is released.
function TMJukeboxWindow:finishQueueDrag()
    local from = self._queueDragIndex
    self._queueDragIndex = nil
    if not from or from < 1 then return end
    local dx = math.abs(getMouseX() - (self._queueDragStartX or 0))
    local dy = math.abs(getMouseY() - (self._queueDragStartY or 0))
    if dx < 6 and dy < 6 then return end
    local pos = self:queueDropPos()
    if not pos then return end
    self:moveQueueEntry(from, pos)
end

------------------------------------------------------------------------
--  Transport actions
------------------------------------------------------------------------

function TMJukeboxWindow:startAt(index)
    local obj = self.jukebox
    if not obj then return end
    if not TMJukebox.hasPower(obj:getSquare()) then return end
    local playlist = self:getPlaylist()
    if #playlist == 0 then return end
    local d = TMJukebox.getData(obj)
    if index < 1 then index = #playlist end
    if index > #playlist then index = 1 end
    d.playIndex = index
    d.isPlaying = true
    -- Bump the play serial so playback restarts even when the chosen track
    -- is the same song (or the same index) as the one already playing.
    d.playSeq = (d.playSeq or 0) + 1
    TMJukebox.transmit(obj)
    if TMJukeboxAudio then TMJukeboxAudio.register(obj) end
end

function TMJukeboxWindow:onPlayStop()
    local obj = self.jukebox
    if not obj then return end
    local d = TMJukebox.getData(obj)
    if d.isPlaying then
        d.isPlaying = false
        TMJukebox.transmit(obj)
        if TMJukeboxAudio then TMJukeboxAudio.stopLocal(obj) end
        if TMSpeech then TMSpeech.announceDevice(obj, "Stopped") end
    else
        self:startAt(d.playIndex or 1)
    end
end

function TMJukeboxWindow:step(dir)
    local obj = self.jukebox
    if not obj then return end
    local d = TMJukebox.getData(obj)
    if not d.isPlaying then return end
    local playlist = self:getPlaylist()
    if #playlist == 0 then return end
    TMJukebox.stepTrack(d, playlist, dir)
    TMJukebox.transmit(obj)
    if TMSpeech then
        TMSpeech.announceDevice(obj, dir > 0 and "Next" or "Prev")
    end
end

function TMJukeboxWindow:onSkip() self:step(1) end
function TMJukeboxWindow:onPrev() self:step(-1) end

function TMJukeboxWindow:onTrackDoubleClick(item)
    -- item is the playlist index stored via addItem.
    if type(item) ~= "number" then return end
    self:startAt(item)
end

function TMJukeboxWindow:clientVolKey()
    return TCMusic.getClientVolumeKeyFor and self.jukebox and TCMusic.getClientVolumeKeyFor(self.jukebox, "IsoObject") or nil
end

function TMJukeboxWindow:onVolumeChange(newVol)
    local vol = newVol / self.volumeBar:getVolumeSteps()
    local cvKey = self:clientVolKey()
    if cvKey and TCMusic.isClientVolumeActive and TCMusic.isClientVolumeActive(cvKey) then
        -- Local mode for THIS jukebox only.
        TCMusic.setClientVolume(cvKey, vol)
        return
    end
    local obj = self.jukebox
    if not obj then return end
    local d = TMJukebox.getData(obj)
    d.volume = vol
    TMJukebox.transmit(obj)
end

function TMJukeboxWindow:onClientVolumeToggle(index, selected)
    local key = self:clientVolKey()
    if not key then return end
    if selected then
        local d = self.jukebox and TMJukebox.getData(self.jukebox) or nil
        TCMusic.setClientVolume(key, (d and d.volume) or 1.0)
    else
        TCMusic.setClientVolume(key, nil)
    end
end

------------------------------------------------------------------------
--  Update / render
------------------------------------------------------------------------

local CLOSE_DIST = 10

function TMJukeboxWindow:update()
    ISCollapsableWindow.update(self)
    if not self:getIsVisible() then return end

    local obj = self.jukebox
    if not obj or not obj:getSquare() or not self.player then
        self:close()
        return
    end
    if math.abs(self.player:getX() - obj:getX()) > CLOSE_DIST
        or math.abs(self.player:getY() - obj:getY()) > CLOSE_DIST then
        self:close()
        return
    end

    local d = TMJukebox.getData(obj)

    -- Play/Stop toggle label
    if self.playBtn then
        self.playBtn:setTitle(d.isPlaying and getText("IGUI_TM_Jukebox_Stop")
            or getText("IGUI_TM_Jukebox_Play"))
    end

    -- Keep lists fresh + highlight the playing row (no selection forcing).
    self:getPlaylist()
    self:refreshQueueList()
    self:highlightPlaying(d)

    -- Queue mode checkbox / layout mirror shared state.
    if self.queueBox then
        self.queueBox.selected[1] = d.queueMode and true or false
    end
    if self.shuffleBox then
        self.shuffleBox.selected[1] = d.shuffle and true or false
    end
    self:applyLayout(d.queueMode and true or false)

    -- Volume slider mirrors this jukebox's local volume when active,
    -- shared device volume otherwise.
    local cvKey = self:clientVolKey()
    local cvActive = cvKey and TCMusic.isClientVolumeActive and TCMusic.isClientVolumeActive(cvKey) or false
    if self.clientVolBox then
        self.clientVolBox.selected[1] = cvActive
    end
    if cvActive then
        self.volumeBar:setVolume(math.floor(((TCMusic.getClientVolume(cvKey) or 1.0) + 0.05) * self.volumeBar:getVolumeSteps()))
    else
        self.volumeBar:setVolume(math.floor(((d.volume or 0) + 0.05) * self.volumeBar:getVolumeSteps()))
    end
end

function TMJukeboxWindow:render()
    ISCollapsableWindow.render(self)

    local obj = self.jukebox
    if not obj then return end

    local th = self:titleBarHeight()
    local y = th + PAD

    local d = TMJukebox.getData(obj)
    local playlist = self:getPlaylist()

    -- Line 1: status / now playing
    local line
    if not TMJukebox.hasPower(obj:getSquare()) then
        line = getText("IGUI_TM_Jukebox_NoPower")
    elseif #playlist == 0 then
        line = getText("IGUI_TM_Jukebox_Empty")
    elseif d.isPlaying then
        local title = TMJukeboxAudio and TMJukeboxAudio.getNowPlaying(obj) or nil
        if not title then
            local entry = playlist[d.playIndex or 1]
            title = entry and entry.title or "..."
        end
        line = getText("IGUI_TM_Jukebox_NowPlaying") .. " " .. title
    else
        line = getText("IGUI_TM_Jukebox_Ready")
    end
    self:drawText(line, PAD, y, 0.9, 0.9, 0.9, 1, UIFont.Small)

    -- Line 2: track position
    if #playlist > 0 then
        local pos = math.min(d.playIndex or 1, #playlist)
        self:drawText(getText("IGUI_TM_Jukebox_Tracks", pos, #playlist),
            PAD, y + FONT_HGT_SMALL + 2, 0.7, 0.7, 0.7, 1, UIFont.Small)
    end

    -- Queue header above the queue list
    if self._queueVisible and self.queueList then
        self:drawText(getText("IGUI_TM_Jukebox_Queue"),
            PAD, self.queueList:getY() - HDR_HGT, 0.8, 0.8, 0.8, 1, UIFont.Small)
    end

    -- Drag ghost: dragged song title follows the cursor; while hovering the
    -- queue list a line marks the gap the song will be dropped into.
    local ghost = nil
    if self._dragIndex and self._dragIndex >= 1 then
        local dx = math.abs(getMouseX() - (self._dragStartX or 0))
        local dy = math.abs(getMouseY() - (self._dragStartY or 0))
        if dx >= 6 or dy >= 6 then
            local entry = playlist[self._dragIndex]
            ghost = entry and TMJukebox.entryLabel(entry) or nil
        end
    elseif self._queueDragIndex and self._queueDragIndex >= 1 then
        local dx = math.abs(getMouseX() - (self._queueDragStartX or 0))
        local dy = math.abs(getMouseY() - (self._queueDragStartY or 0))
        if dx >= 6 or dy >= 6 then
            local qEntry = d.queue and d.queue[self._queueDragIndex] or nil
            ghost = qEntry and (qEntry.title or qEntry.soundName) or nil
        end
    end
    if ghost then
        local lx = getMouseX() - self:getAbsoluteX() + 12
        local ly = getMouseY() - self:getAbsoluteY() - 6
        self:drawText(ghost, lx, ly, 1, 1, 0.6, 0.85, UIFont.Small)

        local pos = self:queueDropPos()
        if pos and self.queueList then
            local lst = self.queueList
            local lineY = lst:getY() + lst:getYScroll() + (pos - 1) * lst.itemheight
            if lineY < lst:getY() then lineY = lst:getY() end
            local maxY = lst:getY() + lst:getHeight() - 2
            if lineY > maxY then lineY = maxY end
            self:drawRect(lst:getX() + 1, lineY, lst:getWidth() - 2, 2, 0.9, 0.4, 1, 0.4)
        end
    end
end

function TMJukeboxWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
end

function TMJukeboxWindow:new(x, y, width, height, player)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.player = player
    o.title = getText("IGUI_TM_Jukebox")
    o.resizable = false
    o.pin = true
    return o
end
