CleanUIConfig = {}
CleanUIConfig.configCache = nil

-- ----------------------------------------- --
-- serializeTable
-- ----------------------------------------- --
function CleanUIConfig.serializeTable(val, name, skipnewlines, depth)
    skipnewlines = skipnewlines or false
    depth = depth or 0

    local tmp = string.rep("    ", depth)

    if name then 
        tmp = tmp .. name .. " = "
    end

    if type(val) == "table" then
        tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")

        for k, v in pairs(val) do
            tmp = tmp .. CleanUIConfig.serializeTable(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and "\n" or "")
        end

        tmp = tmp .. string.rep("    ", depth) .. "}"
    elseif type(val) == "number" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = tmp .. string.format("%q", val)
    elseif type(val) == "boolean" then
        tmp = tmp .. (val and "true" or "false")
    else
        tmp = tmp .. "\"[" .. type(val) .. "]\""
    end

    return tmp
end

-- ----------------------------------------- --
-- load / save
-- ----------------------------------------- --
function CleanUIConfig.saveConfig(config)
    local file = getFileWriter("CleanUIConfig.lua", true, false)
    if file == nil then return nil end

    local contents = "return " .. CleanUIConfig.serializeTable(config)
    file:write(contents)
    file:close()

    CleanUIConfig.configCache = config
end

function CleanUIConfig.loadConfig()
    if CleanUIConfig.configCache then
        return CleanUIConfig.configCache
    end
    
    local file = getFileReader("CleanUIConfig.lua", true)
    if file == nil then return nil end

    local content = ""
    local line = file:readLine()
    while line do
        content = content .. line .. "\n"
        line = file:readLine()
    end
    file:close()
    
    if content == "" then return nil end
    
    local fn, errorMsg = loadstring(content)
    if fn then
        local config = fn()
        CleanUIConfig.configCache = config
        return config
    else
        print("CleanUI: Error loading config - " .. tostring(errorMsg))
        return nil
    end
end

-- ----------------------------------------- --
-- Config Manager
-- ----------------------------------------- --
function CleanUIConfig.getDefaultConfig()
    return {
        lockInventoryWindow = false,
        lockLootWindow = false,
        hideEquipped = false,
    }
end

function CleanUIConfig.getConfig()
    local config = CleanUIConfig.loadConfig()
    
    if not config then
        config = CleanUIConfig.getDefaultConfig()
        CleanUIConfig.saveConfig(config)
        return config
    end

    local defaults = CleanUIConfig.getDefaultConfig()
    local needsSave = false

    for key, defaultValue in pairs(defaults) do
        if config[key] == nil then
            config[key] = defaultValue
            needsSave = true
        else
            local configType = type(config[key])
            local defaultType = type(defaultValue)
            
            if configType ~= defaultType then
                config[key] = defaultValue
                needsSave = true
            end
        end
    end
    
    if needsSave then
        CleanUIConfig.saveConfig(config)
    end
    
    return config
end

function CleanUIConfig.updateConfig(key, value)
    CleanUIConfig.configCache = nil
    
    local config = CleanUIConfig.loadConfig()
    
    if not config then
        config = CleanUIConfig.getDefaultConfig()
    end
    
    config[key] = value
    CleanUIConfig.saveConfig(config)
end

Events.OnGameBoot.Add(CleanUIConfig.getConfig)

return CleanUIConfig