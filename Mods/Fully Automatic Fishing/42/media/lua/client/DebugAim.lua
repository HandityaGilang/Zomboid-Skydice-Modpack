
local function inspectAimCoords()
    if not Fishing or not Fishing.Utils or not Fishing.Utils.getAimCoords then
        print("[Debug] Fishing.Utils.getAimCoords not found")
        return
    end

    local player = getPlayer()
    if not player then return end

    local result = Fishing.Utils.getAimCoords(player)
    print("[Debug] getAimCoords return type: " .. type(result))
    
    if type(result) == "table" then
        print("[Debug] Table content: x=" .. tostring(result.x) .. " y=" .. tostring(result.y))
    elseif type(result) == "number" then
        print("[Debug] First value is number: " .. tostring(result))
        -- Try multiple returns
        local a, b, c = Fishing.Utils.getAimCoords(player)
        print("[Debug] Multiple returns: " .. tostring(a) .. ", " .. tostring(b) .. ", " .. tostring(c))
    else
        print("[Debug] Unknown return type: " .. tostring(result))
    end
end

Events.OnTick.Add(function() 
    if not _G.debugChecked then
        inspectAimCoords()
        _G.debugChecked = true
    end
end)
