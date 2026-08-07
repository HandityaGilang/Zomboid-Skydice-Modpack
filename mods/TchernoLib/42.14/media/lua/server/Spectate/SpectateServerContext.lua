---left click maybe should be client side
require 'ISObjectClickHandler'
local ul_ISObjectClickHandler_doClick = ISObjectClickHandler.doClick
ISObjectClickHandler.doClick = function(object, x, y)
    if not Spectate.isSpectating(getPlayer()) then
        ul_ISObjectClickHandler_doClick(object, x, y)
    end
end

local ul_ISObjectClickHandler_onObjectLeftMouseButtonUp = ISObjectClickHandler.onObjectLeftMouseButtonUp
ISObjectClickHandler.onObjectLeftMouseButtonUp = function(object, x, y)
    if not Spectate.isSpectating(getPlayer()) then
        ul_ISObjectClickHandler_onObjectLeftMouseButtonUp(object, x, y)
    end
end

local ul_ISObjectClickHandler_onObjectLeftMouseButtonDown = ISObjectClickHandler.onObjectLeftMouseButtonDown
ISObjectClickHandler.onObjectLeftMouseButtonDown = function(object, x, y)
    if not Spectate.isSpectating(getPlayer()) then
        ul_ISObjectClickHandler_onObjectLeftMouseButtonDown(object, x, y)
    end
end

Events.OnObjectLeftMouseButtonUp.Remove(ul_ISObjectClickHandler_onObjectLeftMouseButtonUp);
Events.OnObjectLeftMouseButtonDown.Remove(ul_ISObjectClickHandler_onObjectLeftMouseButtonDown);


Events.OnObjectLeftMouseButtonUp.Add(ISObjectClickHandler.onObjectLeftMouseButtonUp);
Events.OnObjectLeftMouseButtonDown.Add(ISObjectClickHandler.onObjectLeftMouseButtonDown);
