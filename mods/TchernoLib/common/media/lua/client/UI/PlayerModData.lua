--***********************************************************
--**                    THE INDIE STONE                    **
--**				  Author: turbotutone				   **
--***********************************************************

require "ISUI/ISPanel"

PlayerModDataDebug = ISPanel:derive("PlayerModDataDebug");
PlayerModDataDebug.instance = nil;

local function roundstring(_val)
    return tostring(ISDebugUtils.roundNum(_val,2));
end

function PlayerModDataDebug.OnOpenPanel()
    if PlayerModDataDebug.instance==nil then
        PlayerModDataDebug.instance = PlayerModDataDebug:new (100, 100, 840, 600, "Player ModData Debugger");
        PlayerModDataDebug.instance:initialise();
        PlayerModDataDebug.instance:instantiate();
    end

    PlayerModDataDebug.instance:addToUIManager();
    PlayerModDataDebug.instance:setVisible(true);

    return PlayerModDataDebug.instance;
end

function PlayerModDataDebug:initialise()
    ISPanel.initialise(self);

    self.firstTableName = false;
end

function PlayerModDataDebug:createChildren()
    ISPanel.createChildren(self);

    ISDebugUtils.addLabel(self, {}, 10, 20, "Player ModData Debugger", UIFont.Medium, true)

    self.tableNamesList = ISScrollingListBox:new(10, 50, 200, self.height - 100);
    self.tableNamesList:initialise();
    self.tableNamesList:instantiate();
    self.tableNamesList.itemheight = 22;
    self.tableNamesList.selected = 0;
    self.tableNamesList.joypadParent = self;
    self.tableNamesList.font = UIFont.NewSmall;
    self.tableNamesList.doDrawItem = self.drawTableNameList;
    self.tableNamesList.drawBorder = true;
    self.tableNamesList.onmousedown = PlayerModDataDebug.OnTableNamesListMouseDown;
    self.tableNamesList.target = self;
    self:addChild(self.tableNamesList);

    self.infoList = ISScrollingListBox:new(220, 50, 600, self.height - 100);
    self.infoList:initialise();
    self.infoList:instantiate();
    self.infoList.itemheight = 22;
    self.infoList.selected = 0;
    self.infoList.joypadParent = self;
    self.infoList.font = UIFont.NewSmall;
    self.infoList.doDrawItem = self.drawInfoList;
    self.infoList.drawBorder = true;
    self:addChild(self.infoList);

    local y, obj = ISDebugUtils.addButton(self,"close",self.width-200,self.height-40,180,20,getText("IGUI_CraftUI_Close"),PlayerModDataDebug.onClickClose);
    y, obj = ISDebugUtils.addButton(self,"refresh",self.width-400,self.height-40,180,20,"Refresh",PlayerModDataDebug.onClickRefresh);
    
    y, obj = ISDebugUtils.addButton(self,"auto refresh",self.width-600,self.height-40,180,20,"Auto-Refresh (Off)",PlayerModDataDebug.onClickAuto);
    self.autoRefreshButton = obj;

    self:populateList();
end

function PlayerModDataDebug:onClickClose()
    self:close();
end

function PlayerModDataDebug:onClickRefresh()
    self:populateList();
end

function PlayerModDataDebug:onClickAuto()
    self.autoRefresh = not self.autoRefresh;
    self.autoRefreshButton:setTitle("Auto-Refresh ("..(self.autoRefresh and "On)" or "Off)"))
end

function PlayerModDataDebug:OnTableNamesListMouseDown(item)
    self:populateInfoList(item);
end

function PlayerModDataDebug:populateList()
    self.tableNamesList:clear();
    
    local mainPlayer = getPlayer()
    if not mainPlayer then
        self:populateInfoList(nil);
        return
    end
    
    local tableNames = ArrayList.new()
    tableNames:add(mainPlayer:getUsername())
    local nbPlayers = getNumActivePlayers()
    if nbPlayers > 0 then
        for itP=0, nbPlayers-1 do
            local player = getSpecificPlayer(itP)
            if player and player ~= mainPlayer then
                tableNames:add(player:getUsername())
            end
        end
    end
    local onlinePlayers = getOnlinePlayers()
    if onlinePlayers then
        for i=0, onlinePlayers:size()-1 do
            local player = onlinePlayers:get(i)
            if player and not player:isLocalPlayer() then
                tableNames:add(player:getUsername())
            end
        end
    end

    --if self.firstTableName and self.firstTableName==tableNames:get(0) then --todo remove this?
    --    return;
    --end


    if tableNames:size()==0 then
        return;
    end

    for i=0, tableNames:size()-1 do
        local name = tableNames:get(i);
        self.tableNamesList:addItem(name, name);
    end

    self.firstTableName=tableNames:get(0);

    self:populateInfoList(self.firstTableName);
end

function PlayerModDataDebug:drawTableNameList(y, item, alt)
    local a = 0.9;

    self:drawRectBorder(0, (y), self:getWidth(), self.itemheight - 1, a, self.borderColor.r, self.borderColor.g, self.borderColor.b);

    if self.selected == item.index then
        self:drawRect(0, (y), self:getWidth(), self.itemheight - 1, 0.3, 0.7, 0.35, 0.15);
    end

    self:drawText( item.text, 10, y + 2, 1, 1, 1, a, self.font);

    return y + self.itemheight;
end

function PlayerModDataDebug:formatVal(_value, _func, _func2)
    return _func2 and (_func2(_func(_value))) or (_func(_value));
end

function PlayerModDataDebug:parseTable(_t, _ident)
    if not _ident then
        _ident = "";
    end
    local s;
    for k,v in pairs(_t) do
        if type(v)=="table" then
            s = tostring(_ident).."["..tostring(k).."] -> ";
            self.infoList:addItem(s, nil);
            self:parseTable(v, _ident.."    ");
        else
            s = tostring(_ident).."["..tostring(k).."] -> "..tostring(v);
            self.infoList:addItem(s, nil);
        end
    end
end

function PlayerModDataDebug:populateInfoList(_name)
    self.infoList:clear();

    if not _name then
        self.infoList:addItem("No data.", nil);
        return;
    end
    --print("Attempting to draw table = "..tostring(_name));
    local isoPlayer = getPlayerFromUsername(_name);
    if not isoPlayer then
        isoPlayer = getPlayer()
        if _name ~= isoPlayer:getUsername() then
            self.infoList:addItem("No Player ".._name, nil);
            return;
        end
    end
    
    local modData = isoPlayer:getModData();

    if modData then
        self:parseTable(modData, "");
        --[[
        local s;
        for k,v in pairs(modData) do
            s = "["..tostring(k).."] -> "..tostring(v);
            self.infoList:addItem(s, nil);
        end
        --]]
    else
        self.infoList:addItem("Table not found.", nil);
    end
end


function PlayerModDataDebug:drawInfoList(y, item, alt)
    local a = 0.9;

    self:drawRectBorder(0, (y), self:getWidth(), self.itemheight - 1, a, self.borderColor.r, self.borderColor.g, self.borderColor.b);

    if self.selected == item.index then
        self:drawRect(0, (y), self:getWidth(), self.itemheight - 1, 0.3, 0.7, 0.35, 0.15);
    end

    self:drawText( item.text, 10, y + 2, 1, 1, 1, a, self.font);

    return y + self.itemheight;
end

function PlayerModDataDebug:prerender()
    if self.autoRefresh then
        self:populateList()
    end
    ISPanel.prerender(self);
    --self:populateList();
end

function PlayerModDataDebug:update()
    ISPanel.update(self);
end

function PlayerModDataDebug:close()
    self:setVisible(false);
    self:removeFromUIManager();
    PlayerModDataDebug.instance = nil
end

function PlayerModDataDebug:new(x, y, width, height, title)
    local o = {};
    o = ISPanel:new(x, y, width, height);
    setmetatable(o, self);
    self.__index = self;
    o.variableColor={r=0.9, g=0.55, b=0.1, a=1};
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1};
    o.backgroundColor = {r=0, g=0, b=0, a=0.8};
    o.buttonBorderColor = {r=0.7, g=0.7, b=0.7, a=0.5};
    o.zOffsetSmallFont = 25;
    o.moveWithMouse = true;
    o.panelTitle = title;
    ISDebugMenu.RegisterClass(self);
    return o;
end

--install
local ul_ISDebugMenu_addButtonInfo = ISDebugMenu.addButtonInfo
function ISDebugMenu:addButtonInfo(_title, _func, _tab, _marginTop)
    if _title == "Close" and not _func and _tab == "DEV" then
        ul_ISDebugMenu_addButtonInfo(self, "PlayerModData", function() PlayerModDataDebug.OnOpenPanel() end, "DEV")
    end
    ul_ISDebugMenu_addButtonInfo(self, _title, _func, _tab, _marginTop)
end
