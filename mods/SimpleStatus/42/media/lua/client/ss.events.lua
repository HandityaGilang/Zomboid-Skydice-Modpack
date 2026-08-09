local function onInitGlobalModData(is_new_game)
    ModData.request("SimpleStatusConfig")
    print("[SimpleStatus] Requested mod data")
end

local function onReceiveGlobalModData(key, data)
    if key ~= "SimpleStatusConfig" then return end
    if not data then return end
    ModData.add(key, data)
    print("[SimpleStatus] Received mod data: ", key, data)
end


Events.OnReceiveGlobalModData.Add(onReceiveGlobalModData)
Events.OnInitGlobalModData.Add(onInitGlobalModData)
