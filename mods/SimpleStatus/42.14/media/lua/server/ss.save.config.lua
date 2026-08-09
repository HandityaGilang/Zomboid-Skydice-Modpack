local function join_keys(tab, sep)
    local keys = {}
    for k, _ in pairs(tab) do
        table.insert(keys, k)
    end
    table.sort(keys)
    return table.concat(keys, sep)
end

local function table_equal(t1, t2)
    if t1 == t2 then return true end
    if type(t1) ~= "table" or type(t2) ~= "table" then return false end

    local count1 = 0
    for _ in pairs(t1) do count1 = count1 + 1 end
    local count2 = 0
    for _ in pairs(t2) do count2 = count2 + 1 end
    if count1 ~= count2 then return false end

    for k, v in pairs(t1) do
        if type(v) == "table" and type(t2[k]) == "table" then
            if not table_equal(v, t2[k]) then return false end
        elseif v ~= t2[k] then
            return false
        end
    end
    return true
end

local function onReceiveGlobalModData(key, data)
    if key ~= "SimpleStatusConfig" then return end
    if not data then return end
    print("[SimpleStatus] Server received mod data: ", key, ", Users: ", join_keys(data, ", "))

    -- check if moddata is changed, if not, do not transmit
    local md = ModData.get("SimpleStatusConfig")
    if table_equal(md, data) then return end

    ModData.add(key, data)
    ModData.transmit(key)
end

local function onInitGlobalModData(is_new_game)
    if not isServer() then return end
    local md = ModData.getOrCreate("SimpleStatusConfig")
    ModData.add("SimpleStatusConfig", md)
    ModData.transmit("SimpleStatusConfig")
    print("[SimpleStatus] Server initialized mod data: ", md, ", Users: ", join_keys(md, ", "))
end


Events.OnInitGlobalModData.Add(onInitGlobalModData)
Events.OnReceiveGlobalModData.Add(onReceiveGlobalModData)
