
WorldChat = ISUIElement:derive("WorldChat")
WorldChat.DisplayTimeS = 8--8s
WorldChat.DisplayTime = nil--hour simtime, todo 8s realtime pauseable
WorldChat.objects = {}

-------------- User interface -------------------
--isoObject can be anything that implements getX and getY methods, returning the reference iso coordinates
--[Option] some instance related (random data) will only be stored if a getModData method is available
function WorldChat.say(isoObject, text)
    if not isoObject or not isoObject.getX or not isoObject.getY then return end
    local chat = WorldChat.get(isoObject)
    chat:addLine(text)
    chat:setVisible(true)
end

----------- Optional (not recommended) interface ---------
function WorldChat.get(isoObject, args)
    local chat = WorldChat.objects[isoObject]
    if not chat then
        WorldChat.objects[isoObject] = WorldChat:new(isoObject, args)
        chat = WorldChat.objects[isoObject]
        chat:initialise();
        chat:addToUIManager();
    end
    return chat
end

function WorldChat:setParams(args)
    for key,value in pairs(args) do
        self.params[key] = value
    end
end

function WorldChat:addLine(text)
    table.insert(self.lines,{line=text,startTime=0})
end

----------------------------------------------

--todo split between prerender and render
function WorldChat:render()
    local rendered = false
    local currentTime = nil
    local tm = nil
    local pos = nil
    local npc = nil
    local isoPlayer = nil
    local toRemoveLines = {}
    local duration = WorldChat.DisplayTime
    if not duration then
        WorldChat.DisplayTime = luatime.getRealtimeSeconds2WorldHours(WorldChat.DisplayTimeS)
        duration = WorldChat.DisplayTime
    end
    for it=1, #self.lines do
        local struct = self.lines[it]
        if currentTime == nil then currentTime = getGameTime():getWorldAgeHours() end
        if struct.startTime == 0 then
            struct.startTime = currentTime
        end
        
        if (currentTime - struct.startTime) < duration then
            if tm == nil then tm = getTextManager() end
            local x = self.params.offsetIsoX + self.source:getX()
            local y = self.params.offsetIsoY + self.source:getY()
            local z = self.params.offsetIsoZ + (self.source.getZ and self.source:getZ() or 0)
            local xui  = isoToScreenX(0, x, y, z) + (self.params.offsetUIX);
            local yui  = isoToScreenY(0, x, y, z) + (self.params.offsetUIY) - self.params.offsetUIYPerLine * (#self.lines-it);
            local font = self.params.font or UIFont.Dialogue
            local r = self.params.r
            local g = self.params.g
            local b = self.params.b
            local a = self.params.a
            
            tm:DrawStringCentre(font, xui*1.0D, yui*1.0D, struct.line, r, g, b, a);
            rendered = true
        else
            table.insert(toRemoveLines,it)
        end
    end
    
    for iter=#toRemoveLines, 1, -1 do
        table.remove(self.lines,toRemoveLines[iter])
    end
    
    self:setVisible(rendered)
end


function WorldChat:new(source, args)
    local o = ISUIElement.new(self, 0, 0, 1, 1)
    o.background = true
    o.backgroundColor = {r=0.25, g=0.25, b=0.25, a=0.0}
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=0.0}
    o.lines = {}
    o.source = source
    o.params = args or WorldChat.getDefaultParams(source)
    o:setVisible(false)
    return o
end

