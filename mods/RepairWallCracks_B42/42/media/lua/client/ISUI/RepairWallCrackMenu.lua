require('luautils');

local function predicateNotBroken(item)
	return not item:isBroken()
end

local InfoPanelFlags = {
    hasSkill = false,
    toolString = {}
}

local function onRepairWallCrackMenu(worldObject, sprite, player)
    local square = worldObject:getSquare()

    if not worldObject or not player then
        return
    end
    if square then
        RepairWallCrackCursor.doRepairWallCrackMenu(RepairWallCrackCursor, player, square)
    end
end

ISMoveableSpriteProps.ghc = getCore():getGoodHighlitedColor();
ISMoveableSpriteProps.bhc = getCore():getBadHighlitedColor();

local function getColorValues( _bool )
    if _bool then
        return ISMoveableSpriteProps.ghc:getR()*255, ISMoveableSpriteProps.ghc:getG()*255, ISMoveableSpriteProps.ghc:getB()*255;
    end
    return ISMoveableSpriteProps.bhc:getR()*255, ISMoveableSpriteProps.bhc:getG()*255, ISMoveableSpriteProps.bhc:getB()*255;
end

local function addToolsString(infoTable, tag, hasTool)
    local r, g, b = getColorValues(hasTool)
    local itemScript = getScriptManager():getItem("Base."..tag)

    if not itemScript then
        itemScript = getScriptManager():getItem(tag)
    end

    local displayName = itemScript and itemScript:getDisplayName() or tag

    if itemScript then
        if ISMoveableSpriteProps and ISMoveableSpriteProps.addLineToInfoTable then
            infoTable = ISMoveableSpriteProps.addLineToInfoTable(infoTable, getText("IGUI_Tool")..":", 255, 255, 255, displayName, r, g, b)
        end
    end

    return infoTable
end

local function InfoPanelDescription(_square, _object, _player, _spriteName)
    local infoTable = {}

    if not _player then return infoTable end
    local inventory = _player:getInventory()
    if not inventory then return infoTable end

    infoTable = ISMoveableSpriteProps.addLineToInfoTable( infoTable, getText("IGUI_Name")..":", 255, 255, 255, getText("ContextMenu_Repair_Wall_Object"), 255, 255, 255 );

    if getCore():getDebug()  then
        local scriptName = _spriteName or "none"
        infoTable = ISMoveableSpriteProps.addLineToInfoTable( infoTable, "SCRIPT NAME:", 255, 0, 255, scriptName, 255, 0, 255 );
    end
    InfoPanelFlags.hasSkill = _player:getPerkLevel(Perks.Masonry) >= 1
    local skillText = PerkFactory.getPerkName(Perks.Masonry)
    infoTable = ISMoveableSpriteProps.addLineToInfoTable(infoTable, getText("IGUI_Skill")..":", 255, 255, 255, skillText, getColorValues(InfoPanelFlags.hasSkill))

    local hasTool = inventory:containsTypeRecurse("BucketPlasterFull") or inventory:containsTypeRecurse("BucketCarvedPlasterFull")
    infoTable = addToolsString(infoTable, "BucketPlasterFull", hasTool) or addToolsString(infoTable, "BucketCarvedPlasterFull", hasTool)

    local toolsTag = {
        "HandShovel",
        "MasonsTrowel",
        "PlasterTrowel",
        "MasonsTrowel_Wood"
    }

    local isFirstInGroup = true
    for _, tag in ipairs(toolsTag) do
        local fullItemName = "Base."..tag
        local hasThisTool = false
        if getScriptManager():getItem(fullItemName) then
            hasThisTool = inventory:containsTypeEvalRecurse(fullItemName, predicateNotBroken)
        end
        local r, g, b = getColorValues(hasThisTool)

        local items = getScriptManager():getItem("Base."..tag)
        local displayName = items and items:getDisplayName() or tag

        if isFirstInGroup then
            infoTable = ISMoveableSpriteProps.addLineToInfoTable(infoTable, getText("IGUI_Tool")..":", 255, 255, 255, displayName, r, g, b)
            isFirstInGroup = false
        else
            infoTable = ISMoveableSpriteProps.addLineToInfoTable(infoTable, "", 255, 255, 255, displayName, r, g, b)
        end
    end
    return infoTable
end



local function addRepairWallCrackMenu(player, context, worldobjects)
   local player = getSpecificPlayer(player);
    local inventory = player:getInventory();
    local square;
    local animsprite = {};

    if player:getVehicle() then return end

    for i, v in ipairs(worldobjects) do
        square = v:getSquare();
    end
    if not square then
        return
    end

    for i = 0, square:getObjects():size() - 1 do
        local object = square:getObjects():get(i);
        local attached = object:getAttachedAnimSprite()
        if attached then
            for n = 1, attached:size() do
                local sprite = attached:get(n - 1)
                if sprite and sprite:getParentSprite() and sprite:getParentSprite():getName() and
                    (luautils.stringStarts(sprite:getParentSprite():getName(), "d_wallcrack")) then

                        local object = square:getObjects():get(i);
                        local sprite = object:getSprite()
                        local spriteName = sprite and sprite:getName() or "fixtures_windows_01_0";
                        table.insert(animsprite, { object = object, sprite = sprite, wallSpriteName = spriteName, square = square});
                    break;
                end
            end
        end
    end

    if #animsprite == 0 then
        return
    end

    local RepairMenu = context:addOption(getText("ContextMenu_Repair_Wall"), nil, nil); --ContextMenuCracks_RepairWallCrack
    local subRepMenu = ISContextMenu:getNew(context);
    context:addSubMenu(RepairMenu, subRepMenu);

    local Tooltip = ISToolTip.GetFont()
    local HColor= getCore():getBadHighlitedColor();

    for k,v in ipairs(animsprite) do
        local infoTable = {};

        local option = subRepMenu:addOption(getText("ContextMenu_Repair"), v.object, onRepairWallCrackMenu, v.sprite, player);
        local hasPlaster = inventory:containsTypeRecurse("BucketPlasterFull") or inventory:containsTypeRecurse("BucketCarvedPlasterFull")
        local hasTool = inventory:containsTypeEvalRecurse("Base.HandShovel", predicateNotBroken) or
                        inventory:containsTypeEvalRecurse("Base.MasonsTrowel", predicateNotBroken) or
                        inventory:containsTypeEvalRecurse("Base.PlasterTrowel", predicateNotBroken) or
                        inventory:containsTypeEvalRecurse("Base.MasonsTrowel_Wood", predicateNotBroken)

        if not (hasPlaster and hasTool and InfoPanelFlags.hasSkill) then
            option.notAvailable = true
        end

        local toolTip = ISToolTip:new();
        toolTip:initialise();
        toolTip.description = "";
        toolTip:setVisible(false);
        toolTip:setTexture(v.wallSpriteName)

        infoTable = InfoPanelDescription(v.square, v.object, player, v.wallSpriteName);
        if not infoTable then
            infoTable = {}
        end

        local column2 = 0;
        for _, t1 in ipairs(infoTable) do
            if #t1 == 2 then
                local textWid = getTextManager():MeasureStringX(Tooltip, t1[1].txt);
                column2 = math.max(column2, textWid + 20);
            end
        end

        for _, t1 in ipairs(infoTable) do
            toolTip.description = string.format("%s <RGB:%.2f,%.2f,%.2f> %s", toolTip.description, t1[1].r / 255, t1[1].g / 255, t1[1].b / 255, t1[1].txt);

            if #t1 == 2 then
                toolTip.description = string.format("%s <SETX:%d> <INDENT:%d> <RGB:%.2f,%.2f,%.2f> %s", toolTip.description, column2, column2, t1[2].r / 255, t1[2].g / 255, t1[2].b / 255, t1[2].txt);
            end
            toolTip.description = toolTip.description .. " <LINE> <INDENT:0> ";
        end

        option.toolTip = toolTip;
        option.onHighlightParams = { v.object, HColor };
        option.onHighlight = function(_option, _menu, _isHighlighted, _object, _color)
            if not _object then
                return
            end
            _object:setHighlighted(_menu.player, _isHighlighted, false);
            _object:setOutlineHighlight(_menu.player, _isHighlighted);
            _object:setOutlineHighlightCol(_menu.player, _color:getR(), _color:getG(), _color:getB(), 1);
        end
    end

end

Events.OnFillWorldObjectContextMenu.Add(addRepairWallCrackMenu);