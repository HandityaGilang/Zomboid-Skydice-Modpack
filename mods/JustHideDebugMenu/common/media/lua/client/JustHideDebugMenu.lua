local hideDebug = true

local function applyDebugOptions()
    local debugOptions = getDebugOptions()
    if debugOptions then
        debugOptions:setBoolean("UI.HideDebugContextMenuOptions", hideDebug)
    end
end

local function onKeyPressed(key)
    if key == 68 then
        hideDebug = not hideDebug
        applyDebugOptions()
        local player = getSpecificPlayer(0)
        if player then
            if hideDebug then
                player:Say("DEBUG Disabled")
            else
                player:Say("DEBUG Enabled")
            end
        end
    end
end

local function onGameStart()
    applyDebugOptions()
end

Events.OnGameStart.Add(onGameStart)
Events.OnKeyPressed.Add(onKeyPressed)