NMMediaWorldTextureResolver = NMMediaWorldTextureResolver or {}

local pathCache = {}
local textureCache = {}

local function norm(value)
    return tostring(value or "")
end

local function findScriptItem(fullType)
    local ft = norm(fullType)
    if ft == "" then
        return nil
    end
    return ScriptManager and ScriptManager.instance and ScriptManager.instance.FindItem
        and ScriptManager.instance:FindItem(ft) or nil
end

local function orderedCandidates(fullType)
    local out = {}
    local seen = {}

    local function add(value)
        local key = norm(value)
        if key == "" or seen[key] then
            return
        end
        seen[key] = true
        out[#out + 1] = key
    end

    add(fullType)

    if NMMediaContract and NMMediaContract.resolveContainerMediaBinding then
        add(NMMediaContract.resolveContainerMediaBinding(fullType))
    end

    if NMMediaContract and NMMediaContract.resolveMediaCanonical then
        add(NMMediaContract.resolveMediaCanonical(fullType))
    end

    return out
end

local function resolveWorldStaticModelToken(fullType)
    local item = findScriptItem(fullType)
    if not item then
        return ""
    end

    if item.getWorldStaticModel then
        local ok, token = pcall(item.getWorldStaticModel, item)
        if ok and tostring(token or "") ~= "" then
            return tostring(token)
        end
    end

    if item.getStaticModel then
        local ok, token = pcall(item.getStaticModel, item)
        if ok and tostring(token or "") ~= "" then
            return tostring(token)
        end
    end

    return ""
end

local function cassettePathFromWorldModelToken(token)
    local modelToken = norm(token)
    if modelToken == "" then
        return nil
    end

    local cassetteNumber = string.match(modelToken, "^NewMusic%.Cassette(%d+)$")
    if cassetteNumber then
        local idx = tonumber(cassetteNumber)
        if idx and idx >= 1 and idx <= 99 then
            return string.format("media/textures/WorldItems/Cassette/World_NM_Cassette%02d.png", idx)
        end
    end

    return nil
end

local function cassettePathFromIconToken(fullType)
    local item = findScriptItem(fullType)
    if not item or not item.getIcon then
        return nil
    end

    local ok, iconToken = pcall(item.getIcon, item)
    if not ok then
        return nil
    end

    local icon = norm(iconToken)
    if icon == "" then
        return nil
    end

    local cassetteNumber = string.match(icon, "^TCTape(%d+)$")
    if cassetteNumber then
        local idx = tonumber(cassetteNumber)
        if idx and idx >= 1 and idx <= 99 then
            return string.format("media/textures/WorldItems/Cassette/World_NM_Cassette%02d.png", idx)
        end
    end

    cassetteNumber = string.match(icon, "^NM_Cassette0*(%d+)$")
    if cassetteNumber then
        local idx = tonumber(cassetteNumber)
        if idx and idx >= 1 and idx <= 99 then
            return string.format("media/textures/WorldItems/Cassette/World_NM_Cassette%02d.png", idx)
        end
    end

    local suffix = string.match(icon, "^NM_Cassette_(.+)$")
    if suffix and suffix ~= "" then
        return "media/textures/WorldItems/Cassette/World_NM_Cassette_" .. suffix .. ".png"
    end

    return nil
end

function NMMediaWorldTextureResolver.resolvePath(fullType)
    local ft = norm(fullType)
    if ft == "" then
        return nil
    end

    local cached = pathCache[ft]
    if cached ~= nil then
        return cached or nil
    end

    local path = nil
    local candidates = orderedCandidates(ft)
    for i = 1, #candidates do
        local candidate = candidates[i]
        path = cassettePathFromWorldModelToken(resolveWorldStaticModelToken(candidate))
            or cassettePathFromIconToken(candidate)
        if path then
            break
        end
    end

    pathCache[ft] = path or false
    return path
end

function NMMediaWorldTextureResolver.resolveTexture(fullType)
    local path = NMMediaWorldTextureResolver.resolvePath(fullType)
    if not path or not getTexture then
        return nil, path
    end

    local cached = textureCache[path]
    if cached ~= nil then
        return cached or nil, path
    end

    local tex = getTexture(path)
    textureCache[path] = tex or false
    return tex, path
end
