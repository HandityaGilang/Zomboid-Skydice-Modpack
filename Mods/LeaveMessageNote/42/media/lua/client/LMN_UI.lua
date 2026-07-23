
--  ♡ 𝒜𝓂𝑒𝓁𝒾𝒶𝒦𝑒𝓃𝓎𝒶 𝒫𝒵 𝓂𝑜𝒹𝓈 ♡
--    𝐿𝑒𝒶𝓋𝑒 𝒶 𝓂𝑒𝓈𝓈𝒶𝑔𝑒 𝐵𝟦𝟤 

require "ISUI/ISTextBox"
require "LMN_Utils"

LMN_CurrentNoteUI = LMN_CurrentNoteUI or nil

function LMN_OpenUI(note, playerObj)
    if not note or not playerObj then return end

    if LMN_CurrentNoteUI and LMN_CurrentNoteUI:getIsVisible() then
        if LMN_CurrentNoteUI.note == note then
            LMN_CurrentNoteUI:bringToTop()
            return
        else
            LMN_CurrentNoteUI:setVisible(false)
            LMN_CurrentNoteUI:removeFromUIManager()
            LMN_CurrentNoteUI = nil
        end
    end

    local playerIndex = playerObj:getPlayerNum()

    local startText = LMN.getNoteMessage(note)
    if type(startText) ~= "string" then
        startText = ""
    end

    local ui = ISTextBox:new(
        0, 0,
        420, 150,
        "Leave a message",
        startText,
        nil,
        LMN_UI_OnConfirm,
        playerIndex,
        note
    )

    LMN_CurrentNoteUI = ui
    ui.note = note
    ui.multipleLine = true
    ui.numLines = 5
    ui.maxLines = 10
    local CaptionText = {
        "Type your message below:",
        "When you're done, click OK to save.",
        "Your message will be saved to the note.",
        "Others can read it when they interact with the note.",
        "What message do you want to leave?",
        "Feel free to write anything you like!",
        "Leave a message for others to find.",
        "Happy writing!",
        "Let's leave a memorable note!",
        "Other survivors might read this. So what will you say?"
    }

    -- Ambil random caption
    local function getRandomCaption()
        return CaptionText[ZombRand(1, #CaptionText + 1)]
    end

    ui.labelText = getRandomCaption()
    ui.labelCurrent = ""
    ui.labelCharIndex = 0
    ui.labelTypeSpeed = 0.5
    ui.labelFont = UIFont.Small
    ui.labelTimer = 0
    ui.labelSwitchDelay = 180 

    local old_render = ui.render
    function ui:render()
        local font = self.labelFont or UIFont.Small
        local label = self.labelCurrent
        if self.labelCharIndex < #self.labelText then
            self.labelCharIndex = math.min(self.labelCharIndex + self.labelTypeSpeed, #self.labelText)
            label = string.sub(self.labelText, 1, math.floor(self.labelCharIndex))
        else
            label = self.labelText
            self.labelTimer = (self.labelTimer or 0) + 1
            if self.labelTimer >= self.labelSwitchDelay then
                local newText
                repeat
                    newText = getRandomCaption()
                until newText ~= self.labelText
                self.labelText = newText
                self.labelCharIndex = 0
                self.labelTimer = 0
            end
        end

        -- Tengahin teks
        local labelWidth = getTextManager():MeasureStringX(font, label)
        local centerX = (self:getWidth() - labelWidth) / 2
        self:drawText(label, centerX, 40, 1, 1, 1, 1, font)

        old_render(self)
    end

    ui:initialise()
    ui:addToUIManager()

    if ui.entry then
        ui.entry:setY(70)
    end

    if ui.yes then
        ui.yes:setY(ui.yes:getY() - 2.5)
    end

    if ui.no then
        ui.no:setY(ui.no:getY() - 2.5)
    end

    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    ui:setX((screenW - ui:getWidth()) / 2)
    ui:setY((screenH - ui:getHeight()) / 2 + 150)
end

-- Button Handler 
function LMN_UI_OnConfirm(target, button, note)
    LMN_CurrentNoteUI = nil
    
    if not button or button.internal ~= "OK" then return end
    if not note then return end

    local entry = button.parent and button.parent.entry
    if not entry then return end

    local text = entry:getText()
    if type(text) ~= "string" then
        text = ""
    end

    -- SOLO atau SP!!!!!!!!
    if not isClient() then
        LMN.setNoteMessage(note, text)
        return
    end

    -- SMS MASUK!! kirim ke server
    local player = nil
    if target and target.player then
        pcall(function() player = getSpecificPlayer(target.player) end)
    end

    if not player and getPlayer then
        pcall(function() player = getPlayer() end)
    end

    if not player then
        pcall(function() player = getSpecificPlayer(0) end)
    end

    if not player then
        return
    end

    if not text and entry and entry.getText then
        text = tostring(entry:getText() or "")
    end
    if not text then text = "" end

    local md = note:getModData()
    md.leaveMessage = text

    if note.transmitModData then
        note:transmitModData()
    end

    local args = {
        noteId = note and note.getID and note:getID() or -1,
        text = text
    }

    local cont = nil
    if note.getContainer then cont = note:getContainer() end

    if cont then
        -- kalau ada container, coba dapat index di container itu deh
        -- default "container" -> perhalus jadi playerInv/otherContainer
        if player and player:getInventory() == cont then
            args.containerType = "playerInv"
            local items = cont:getItems()
            for i = 0, items:size()-1 do
                if items:get(i) == note then
                    args.containerIndex = i
                    break
                end
            end
        else
            -- generic container (Semoga Semua Container)
            args.containerType = "otherContainer"
            if cont.getType then args.containerTypeName = cont:getType() end
        end
    else
        -- (Taruh di lantai) -> kirim pos + worldItem index biar mapan
        if note.getWorldItem and note:getWorldItem() then
            local worldItem = note:getWorldItem()
            if worldItem then
                args.containerType = "world"
                local sq = worldItem:getSquare()
                if sq then
                    args.worldX = sq:getX()
                    args.worldY = sq:getY()
                    args.worldZ = sq:getZ()
                end
                if worldItem.getObjectIndex then
                    args.worldItemIndex = worldItem:getObjectIndex()
                end
            end
        end
    end
    sendClientCommand(player, "LMN", "SetNoteMessage", args)
end

Events.OnServerCommand.Add(function(module, command, args)
    if module ~= "LMN" or command ~= "SyncNoteMessage" then return end

    -- cari item lokal berdasarkan args dan update modData
    local item = nil
    if args.containerType == "playerInv" then
        local players = getPlayer() and { getPlayer() } or nil 
        -- scanning semua players:
        for i = 0, getNumActivePlayers()-1 do
            local p = getSpecificPlayer(i)
            if p and p:getInventory() then
                local items = p:getInventory():getItems()
                if args.containerIndex and args.containerIndex >=0 and args.containerIndex < items:size() then
                    item = items:get(args.containerIndex)
                    if item then break end
                end
            end
        end
    elseif args.containerType == "world" and args.worldX then
        local sq = getCell():getGridSquare(args.worldX, args.worldY, args.worldZ)
        if sq then
            for i=0, sq:getObjects():size()-1 do
                local obj = sq:getObjects():get(i)
                if obj and obj.getItemContainer then
                    local c = obj:getItemContainer()
                    local itms = c:getItems()
                    for j=0, itms:size()-1 do
                        local it = itms:get(j)
                        if it and it.getWorldItem and it:getWorldItem() and it:getWorldItem().getObjectIndex and args.worldItemIndex and it:getWorldItem():getObjectIndex() == args.worldItemIndex then
                            item = it
                            break
                        end
                    end
                end
                if item then break end
            end
        end
    end

    if item then
        local md = item:getModData()
        if args.text == "" then md.leaveMessage = nil else md.leaveMessage = args.text end
    end
end)