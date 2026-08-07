MiniHealthPlusSandbox = MiniHealthPlusSandbox or {}

local MHP_SB_PAGE = "MHP"

local function MHP_SB_GetRoot()
    local sandboxVars = rawget(_G, "SandboxVars")
    if type(sandboxVars) ~= "table" then
        return nil
    end

    local root = sandboxVars[MHP_SB_PAGE]
    if type(root) ~= "table" then
        root = {}
        sandboxVars[MHP_SB_PAGE] = root
    end

    if root.EnableReplaceBandage == nil then
        root.EnableReplaceBandage = false
    end

    if root.ShowSafeRemoveIndicator == nil then
        root.ShowSafeRemoveIndicator = true
    end

    if root.ShowStitchInspectIndicator == nil then
        root.ShowStitchInspectIndicator = true
    end

    return root
end

function MHP_SB_GetBool(name, default)
    local root = MHP_SB_GetRoot()
    local value = root and root[name]

    if type(value) == "boolean" then
        return value
    end

    return default
end

function MHP_SB_IsReplaceBandageEnabled()
    return MHP_SB_GetBool("EnableReplaceBandage", false)
end

function MHP_SB_IsSafeRemoveIndicatorEnabled()
    return MHP_SB_GetBool("ShowSafeRemoveIndicator", true)
end

function MHP_SB_IsStitchInspectIndicatorEnabled()
    return MHP_SB_GetBool("ShowStitchInspectIndicator", true)
end

return MiniHealthPlusSandbox
