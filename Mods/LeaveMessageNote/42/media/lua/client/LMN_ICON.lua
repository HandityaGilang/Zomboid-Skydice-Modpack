
--  ♡ 𝒜𝓂𝑒𝓁𝒾𝒶𝒦𝑒𝓃𝓎𝒶 𝒫𝒵 𝓂𝑜𝒹𝓈 ♡
--    𝐿𝑒𝒶𝓋𝑒 𝒶 𝓂𝑒𝓈𝓈𝒶𝑔𝑒 𝐵𝟦𝟤 
            
local NOTE_TYPE = "Base.Note"
local RADIUS = 4
local ICON_TEXTURE = getTexture("media/ui/LMN_NOTE_PIN.png")
local ICON_SIZE = 80
local ICON_OFFSET_Y = 90
local isLMBPressed = false

require "LMN_Render"

-- simpan animasi per note
local noteAnimData = {} 

-- util
local function dist2dSq(ax, ay, bx, by)
    local dx = ax - bx
    local dy = ay - by
    return dx * dx + dy * dy
end

local TheNoteEmpty = {
    "The note is empty.",
    "There's nothing written here.",
    "This note has no message.",
    "It's just a blank note.",
    "No message on this note.",
    "This note is devoid of any writing.",
    "Nothing to read here.",
    "This note contains no information.",
    "It's an empty piece of paper.",
    "No text found on this note."
}

-- Interaksi sentuh ikon
local LMN_TouchIcon = ISBaseTimedAction:derive("LMN_TouchIcon")
function LMN_TouchIcon:isValid() return true end

function LMN_TouchIcon:start()
    if self.item and self.obj then
        local md = self.item:getModData()

        if md.LMN_Admin and md.LMN_Admin.isExploding then
            if isClient() then
                sendClientCommand(self.character, "LMN", "AdminDestroyNote", {
                    noteId = self.item:getID(), 
                    worldX = self.obj:getX(),
                    worldY = self.obj:getY(),
                    worldZ = self.obj:getZ(),
                    worldItemIndex = self.obj:getObjectIndex()
                })
            else
                self.obj:getSquare():transmitRemoveItemFromSquare(self.obj)
            end
            self:forceStop()
            return 
        end

        local noteId = "note_" .. tostring(self.item:getID())

        if LMN_PopupUI.dontShowAgainNotes and LMN_PopupUI.dontShowAgainNotes[noteId] then
            self.character:Say("I don't want to see the contents anymore, I already know.")
            self:forceStop()
            return 
        end

        local text = md.leaveMessage
        
        if text and text ~= "" then
            LMN_PopupUI.createPopup(text, self.item, self.obj)
        else
            local randomIndex = ZombRand(#TheNoteEmpty) + 1
            self.character:Say(TheNoteEmpty[randomIndex])
        end

        if md.LMN_Admin and md.LMN_Admin.destroyAfterOpen then
            if LMN_AdminClient and LMN_AdminClient.startSelfDestruct then
                LMN_AdminClient.startSelfDestruct(self.character, self.item, self.obj)
            end
        end
    end
    self:forceStop()
end

function LMN_TouchIcon:new(character, item, obj)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.item = item 
    o.obj = obj   
    o.stopOnWalk = false
    o.stopOnRun = false
    o.maxTime = 0
    return o
end

-- Cek klik pada tile
local function isTileClicked(x, y, z, clickRadius)
    local mouseDown = isMouseButtonDown(0)
    
    if not mouseDown then
        isLMBPressed = false
        return false
    end

    if isLMBPressed then return false end

    -- Ambil koordinat dunia dari posisi mouse
    local worldX = screenToIsoX(0, getMouseX(), getMouseY(), z)
    local worldY = screenToIsoY(0, getMouseX(), getMouseY(), z)
    
    -- Hitung jarak dari titik presisi (wx, wy)
    local dx = worldX - x
    local dy = worldY - y
    local distSq = dx * dx + dy * dy

    -- Cek apakah di dalam radius
    if distSq <= (clickRadius * clickRadius) then
        isLMBPressed = true 
        return true
    end

    return false
end

local goingThereTexts = {
    "Going there...",
    "Alright.",
    "Someone left a note...",
    "Lemme see.",
    "What's that?.",
    "Looks like someone left a message.",
    "interesting.",
    "Someone wrote something here.",
    "Who left a message here.",
    "Okay."
}

-- Jalan ke tujuan
local function walkToAndInteract(player, square, item, obj)
    local px, py = player:getX(), player:getY()
    local tx, ty = square:getX(), square:getY()
    
    ISTimedActionQueue.clear(player)
    
    if dist2dSq(px, py, tx, ty) <= (1 * 1) then
        ISTimedActionQueue.add(LMN_TouchIcon:new(player, item, obj))
    else
        ISTimedActionQueue.add(ISWalkToTimedAction:new(player, square))
        ISTimedActionQueue.add(LMN_TouchIcon:new(player, item, obj))
        
        local randomIndex = ZombRand(#goingThereTexts) + 1
        player:Say(goingThereTexts[randomIndex])
    end
end

local function squareInRadius(px, py, ox, oy, radius)
    return dist2dSq(px, py, ox, oy) <= (radius * radius)
end

local function shouldRender()
    return getPlayer() ~= nil
end

-- Render
local function renderNoteIcons()
    if not shouldRender() then return end
    if not ICON_TEXTURE then return end

    local player = getPlayer()
    local psq = player and player:getSquare()
    if not psq then return end

    local cell = getCell()
    if not cell then return end

    local px, py, pz = psq:getX(), psq:getY(), psq:getZ()
    local now = getGameTime():getWorldAgeHours() * 3600

    for x = px - RADIUS, px + RADIUS do
        for y = py - RADIUS, py + RADIUS do
            local gsq = cell:getGridSquare(x, y, pz)
            if gsq then
                local objs = gsq:getWorldObjects()
                for i = 0, objs:size() - 1 do
                    local obj = objs:get(i)
                    if instanceof(obj, "IsoWorldInventoryObject") then
                        local item = obj:getItem()
                        if item and item:getFullType() == NOTE_TYPE then

                            -- Cek klik
                            if isTileClicked(gsq:getX(), gsq:getY(), gsq:getZ(), 0.3) then
                                walkToAndInteract(player, gsq, item, obj)
                            end

                            local inRange = squareInRadius(
                                px, py,
                                obj:getX(), obj:getY(),
                                RADIUS
                            )

                            local anim = noteAnimData[obj]

                            -- Atur jarak
                            if not inRange then
                                if anim and not anim.removing then
                                    anim.removing = true
                                    anim.removeTime = now
                                end
                            else
                                if not anim then
                                    anim = {
                                        spawnTime = now,
                                        removing = false,
                                        removeTime = 0
                                    }
                                    noteAnimData[obj] = anim
                                end
                            end

                            if anim then
                                local wx = obj:getWorldPosX()
                                local wy = obj:getWorldPosY()
                                local wz = obj:getZ()

                                if isTileClicked(wx, wy, wz, 0.3) then
                                    walkToAndInteract(player, gsq, item, obj)
                                end

                                local sx = IsoUtils.XToScreen(wx, wy, wz, 0)
                                local sy = IsoUtils.YToScreen(wx, wy, wz, 0)

                                sx = sx - IsoCamera.getOffX()
                                sy = sy - IsoCamera.getOffY()

                                -- Animasi
                                local elapsed = now - anim.spawnTime

                                -- Pop In
                                local popDuration = 25
                                local t = math.min(elapsed / popDuration, 1)
                                local popScale = t * (2 - t)

                                -- Float
                                local float = math.sin(now * 0.05) * 7
                                            + math.sin(now * 0.10) * 7.5
                                -- Pop Out
                                if anim.removing then
                                    local outDuration = 20
                                    local outElapsed = now - anim.removeTime
                                    local ot = math.min(outElapsed / outDuration, 1)

                                    popScale = popScale * (1 - ot)

                                    if ot >= 1 then
                                        noteAnimData[obj] = nil
                                        anim = nil
                                    end
                                end

                                if anim and popScale > 0 then
                                    local size = ICON_SIZE * popScale
                                    local drawX = sx - (size * 0.5)
                                    local drawY = sy - ICON_OFFSET_Y + float

                                    UIManager.DrawTexture(
                                        ICON_TEXTURE,
                                        drawX,
                                        drawY,
                                        size,
                                        size,
                                        popScale
                                    )
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

Events.OnPostRender.Add(renderNoteIcons)