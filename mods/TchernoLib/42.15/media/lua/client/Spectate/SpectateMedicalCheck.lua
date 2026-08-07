require "TimedActions/ISBaseTimedAction"

ISSpectatorMedicalCheckAction = ISBaseTimedAction:derive("ISSpectatorMedicalCheckAction");


function ISSpectatorMedicalCheckAction:isValid()
    return true
end

function ISSpectatorMedicalCheckAction:waitToStart()
    return false
end

function ISSpectatorMedicalCheckAction:update()
end

function ISSpectatorMedicalCheckAction:start()
end

function ISSpectatorMedicalCheckAction:stop()
    ISBaseTimedAction.stop(self);
end

function ISSpectatorMedicalCheckAction:perform()

    local playerNum = self.character:getPlayerNum()
    local x = getPlayerScreenLeft(playerNum) + 70
    local y = getPlayerScreenTop(playerNum) + 50
    local healthPanel = ISSpectatorHealthPanel:new(self.otherPlayer, x, y, 400, 400)
    healthPanel:initialise()

    local title = nil
    if isClient() then
        title = getText("IGUI_health_playerHealth", self.otherPlayer:getUsername())
    else
        title = getText("IGUI_health_playerHealth", self.otherPlayer:getDescriptor():getForename().." "..self.otherPlayer:getDescriptor():getSurname())        
    end
    local wrap = healthPanel:wrapInCollapsableWindow(title);
    wrap:setResizable(false)
    wrap:addToUIManager();
    wrap.visibleTarget = self;
    
    healthPanel.doctorLevel = 10;
    healthPanel:setOtherPlayer(self.character)

    if JoypadState.players[playerNum+1] then
        JoypadState.players[playerNum+1].focus = healthPanel
        updateJoypadFocus(JoypadState.players[playerNum+1])
    end

    if self.otherPlayer then
        self.character:startReceivingBodyDamageUpdates(self.otherPlayer)
    end

    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self);
end

function ISSpectatorMedicalCheckAction:new(character, otherPlayer)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character;
    o.otherPlayer = otherPlayer;
    o.otherPlayerX = otherPlayer:getX();
    o.otherPlayerY = otherPlayer:getY();
    o.stopOnWalk = false;
    o.stopOnRun = false;
    o.maxTime = 1
    o.forceProgressBar = false;
    return o;
end


--health panel from any distance: does not work
local PAD_BOTTOM = 8
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

ISSpectatorHealthPanel = ISHealthPanel:derive("ISSpectatorHealthPanel");

function ISSpectatorHealthPanel:new(player, x, y, width, height)
    local o = ISHealthPanel:new(player, x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    return o
end

function ISSpectatorHealthPanel:update()
    ISPanelJoypad.update(self)
    if self.otherPlayer then
        -- ISCollapsableWindow:close() just hides the window
        if not self.parent:getIsVisible() then
            self.parent:removeFromUIManager()
            if self.joyfocus then self.joyfocus.focus = nil end
            self:getDoctor():stopReceivingBodyDamageUpdates(self:getPatient())
            return
        end
        if self.blockingMessage then self:getDoctor():startReceivingBodyDamageUpdates(self:getPatient()) end
        self.blockingMessage = nil;
        self.blockingAlpha = math.max(0.0, self.blockingAlpha - 0.05)
    end
    if self:getIsVisible() then
        self:updateBodyPartList()
        if self.textRight and self.listbox.textRight then
            local width = math.max(self.textRight, self.listbox.x + self.listbox.textRight)
            if width > 0 then
                width = math.max(width, self.healthPanel:getRight())
                self:setWidthAndParentWidth(width + 20);
            end
        end
        self:setHeightAndParentHeight(math.max(self.healthPanel:getBottom(), self.allTextHeight or 0) + FONT_HGT_SMALL + PAD_BOTTOM * 2);
    else
        self.textRight = 0
        self.listbox.textRight = 0
    end
end

--remove interactions
function ISSpectatorHealthPanel:doBodyPartContextMenu(bodyPart, x, y)
end