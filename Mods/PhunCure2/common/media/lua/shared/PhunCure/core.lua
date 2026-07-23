PhunCure = {
    name = "PhunCure",
    commands = {
        playerSetup = "playerSetup",
        notify = "notify",
        cure = "cure"
    },
    events = {
        OnReady = "PhunCureOnReady"
    },
    settings = {},
    tools = require("PhunCure/tools")
}

local Core = PhunCure

Core.isLocal = not isClient() and not isServer() and not isCoopHost()
Core.settings = SandboxVars[Core.name] or {}
for _, event in pairs(Core.events) do
    if not Events[event] then
        LuaEventManager.AddEvent(event)
    end
end

function Core:ini()
    self.inied = true
    triggerEvent(self.events.OnReady, self)
end

function Core.getOption(name, default)
    local n = Core.name .. "." .. name
    local val = getSandboxOptions():getOptionByName(n) and getSandboxOptions():getOptionByName(n):getValue()
    if val == nil then
        return default
    end
    return val
end

function Core.debugLn(str)
    if Core.settings.Debug then
        print("[" .. Core.name .. "] " .. str)
    end
end

function Core.debug(...)
    if Core.settings.Debug then
        Core.tools.debug(Core.name, ...)
    end
end

-- I suppose getOnlineID is no longer a thing in B42.17
local testForOnlineId = getCore():getGameVersion():getMajor() == 42 and getCore():getGameVersion():getMinor() < 17 and
                            (isClient() or isServer() or isCoopHost())

function Core.getZId(zed)
    if zed then
        if instanceof(zed, "IsoZombie") then
            if zed:isZombie() then

                if testForOnlineId then
                    return tostring(zed:getOnlineID())
                else
                    return tostring(zed:getID())
                end

            end
        end
    end
end

function Core.getZData(zed)
    if zed then
        local id = Core.getZId(zed)
        local data = zed:getModData()
        if not data.PhunCure then
            data.PhunCure = {
                id = id
            }
        elseif id ~= data.PhunCure.id then
            -- Possibly recycled zed
            data.PhunCure = {
                id = id
            }
        end
        return data.PhunCure
    end
    return {}
end

Core.cure = function(food, player, percent)
    if not isServer() then
        getSoundManager():PlaySound("InjectCure", false, 0):setVolume(0.50);
        if not food:isRotten() then
            sendClientCommand(player, Core.name, Core.commands.cure, {})
        else
            player:Say(getText("IGUI_ItemRottenAmpule"));
            Core.tools.addLineInChat(getText("IGUI_ItemSuccessAmpule_NoSuccess"), "<RGB:255,255,0>");
        end
    else
        Core.debugLn("Cure command received for player " .. tostring(player:getUsername()))
    end

end

function Core.applyFreshAndRottenDays()
    local item = ScriptManager.instance:getItem("PhunCure.Cure")
    local daysRotten = Core.getOption("DaysRotten", 5)
    local daysFresh = Core.getOption("DaysFresh", 1)

    if daysRotten <= 0 then
        daysRotten = 1000000000
    end
    item:DoParam("DaysTotallyRotten = " .. daysRotten)
    item:DoParam("DaysFresh = " .. daysFresh)
    Core.debugLn("Updated Cure item rotten days to " .. tostring(daysRotten) .. " and fresh days to " ..
                     tostring(daysFresh))
end

Events.EveryTenMinutes.Add(function()
    -- refresh periodically so we aren't constantly reading from function
    Core.settings.Debug = Core.getOption("Debug", false)
end)

Events.OnGameStart.Add(function()
    Core.applyFreshAndRottenDays()
end)

Events.OnServerStarted.Add(function()
    Core.applyFreshAndRottenDays()
end)
