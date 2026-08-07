local SandboxSettings = require "config/IH_SandboxSettings"

IH = IH or {}

local ToolsSync = {}

local function setCache(tools)
    if type(tools) ~= "table" then
        return
    end
    IH.ToolsCache = tools
end

local function handleToolsResponse(args)
    if type(args) ~= "table" then
        return
    end
    setCache(args)
    IH._toolsRequestInFlight = false
end

function ToolsSync.request()
    if IH._toolsRequestInFlight then
        return
    end
    IH._toolsRequestInFlight = true
    sendClientCommand("IH", "RequestTools", {})
end

function ToolsSync.refreshOnOpen()
    ToolsSync.request()
end

function ToolsSync.get(kind)
    local cache = IH.ToolsCache
    local list = cache and cache[kind]
    if type(list) == "table" and #list > 0 then
        return list
    end
    return SandboxSettings.get(kind)
end

local function hookAdminSandboxApply()
    if ISServerSandboxOptionsUI == nil then
        return
    end
    if ISServerSandboxOptionsUI._IH_onButtonApplyWrapped then
        return
    end
    local original = ISServerSandboxOptionsUI.onButtonApply
    if not original then
        return
    end
    ISServerSandboxOptionsUI._IH_onButtonApplyWrapped = true
    ISServerSandboxOptionsUI.onButtonApply = function(self, ...)
        local result = original(self, ...)
        if isClient() then
            ToolsSync.request()
        else
            local options = getSandboxOptions()
            options:copyValuesFrom(self.options)
            options:toLua()
            setCache(SandboxSettings.buildToolsFromSandbox())
        end
        return result
    end
end

function ToolsSync.init()
    if IH._toolsSyncInited then
        return
    end
    IH._toolsSyncInited = true
    IH.ToolsCache = IH.ToolsCache or {}
    IH._toolsRequestInFlight = IH._toolsRequestInFlight == true
    IH.RequestToolsFromServer = ToolsSync.request

    if not IH._toolsNetHooked then
        IH._toolsNetHooked = true
        Events.OnServerCommand.Add(function(module, command, args)
            if module ~= "IH" then
                return
            end
            if command ~= "ToolsResponse" then
                return
            end
            handleToolsResponse(args)
        end)
    end

    if not IH._toolsAdminHooked then
        IH._toolsAdminHooked = true
        Events.OnGameBoot.Add(hookAdminSandboxApply)
    end
end

return ToolsSync
