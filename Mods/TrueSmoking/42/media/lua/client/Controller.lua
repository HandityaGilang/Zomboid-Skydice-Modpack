--[[
    Controller Support begins here, everything is bound to B/O but we listen for LB presses and button releases
    to flag when buttons are held, LB is used as a modifer key. Store the original functions and call them first to ensure vanilla
    functionality takes priority

    This could be configured through a combo box and options later.
]]
local originalOnJoypadButtonReleased = ISButtonPrompt.onJoypadButtonReleased
local originalOnLBPress = ISButtonPrompt.onLBPress
local originalOnBPress = ISButtonPrompt.onBPress
local originalGetBestBButtonAction = ISButtonPrompt.getBestBButtonAction

function ISButtonPrompt:onJoypadButtonReleased(button)
    originalOnJoypadButtonReleased(self, button)

    local o = TrueSmoking:getPlayerReference(self.player)

    if button == 4 then
        o.LB_HELD = false
    elseif button == 1 then
        o.B_HELD = false
    end
    -- print(string.format('Button released - %s',button))
end

function ISButtonPrompt:onLBPress()
    originalOnLBPress(self)

    local o = TrueSmoking:getPlayerReference(self.player)

    o.LB_HELD = true
end

function ISButtonPrompt:onBPress()
    originalOnBPress(self)

    local o = TrueSmoking:getPlayerReference(self.player)

    o.B_HELD = true
end

function ISButtonPrompt:getBestBButtonAction(dir)
    originalGetBestBButtonAction(self, dir)

    local grab = getText('UI_GrabAndDrop_GrabAction')
    local drop = getText('UI_GrabAndDrop_DropAction')

    local player = self.player and getSpecificPlayer(self.player)

    local square = player and player:getSquare()

    if not square then return end -- Possibly teleporting.

    if self.bPrompt and not (self.bPrompt:find(grab) or self.bPrompt:find(drop)) then return end

    local o = TrueSmoking:getPlayerReference(player)

    if o.isSmoking and o.Smokable.smokeLit and not o.LB_HELD then
        self:setBPrompt(getText('UI_TRUESMOKING_PUFF'), function() o.Smokable:puff() end)
    elseif o.isSmoking and not o.Smokable.smokeLit and not o.LB_HELD then
        self:setBPrompt(getText('UI_TRUESMOKING_RELIGHT'), function() o.Smokable:light() end)
    elseif TrueSmoking.Config.FindSmoke and not o.isSmoking and o.LB_HELD then
        self:setBPrompt(getText('UI_TRUESMOKING_GET_SMOKE'), function() TrueSmoking:findSmokable(player) end)
    elseif o.isSmoking and o.LB_HELD then
        self:setBPrompt(getText('UI_TRUESMOKING_PUT_OUT'), function() o.Smokable:putOut() end)
    elseif not o.isSmoking and o.LB_HELD and o.mask and TrueSmoking.Options.ManageHeadGear then
        self:setBPrompt(getText('UI_TRUESMOKING_PUT_OUT'), function() TrueSmoking:equipItem(player, o.mask, false) end)
    end
end