require('AutoTailoring_Shared')

--hook the ISGarmentUI:doContextMenu to install our button
local genuine_ISGarmentUI_doContextMenu = ISGarmentUI.doContextMenu;
function ISGarmentUI:doContextMenu(part, x, y)
    local context = genuine_ISGarmentUI_doContextMenu(self, part, x, y);
    
    local inventory = self.chr:getInventory()
    local thread = inventory:getItemFromType("Thread", true, true) or inventory:getItemFromTag(ItemTag.THREAD, true, true);
    local needle = inventory:getItemFromType("Needle", true, true) or inventory:getFirstTagRecurse(ItemTag.SEWING_NEEDLE);
    local hole = false--self.clothing:getVisual():getHole(part) > 0;--holes blocking patching is not a thing anymore with B42
    local fabric = AutoTailoring.getPatchingItem(self.chr);--will not start the auto stuff even if it could remove patch once and leave.
    local cannotBePatched = not self.clothing:getFabricType();
    local player = self.chr
    local tailoringLevel = player and player:getPerkLevel(Perks.Tailoring) or 0;
    local tooHighLevel = tailoringLevel >= AutoTailoring.OPTIONS.MaxTailoringLevel;
    
    local trainTailoringOption = context:addOption(getText("ContextMenu_AutoTailoring"), self.chr, ISGarmentUI.autoSewing, self.clothing, part);

    if not thread or not needle or not fabric or hole or cannotBePatched or tooHighLevel then
        trainTailoringOption.notAvailable = true
        trainTailoringOption.toolTip = ISInventoryPaneContextMenu.addToolTip();
        if cannotBePatched then
            trainTailoringOption.toolTip.description = trainTailoringOption.toolTip.description .." <LINE> <RGB:1,0,0> "..getText("IGUI_garment_CantRepair");
        else 
            trainTailoringOption.toolTip.description = getText("Farming_MissingItem",":") ;--"You need %1"
            trainTailoringOption.toolTip.description = trainTailoringOption.toolTip.description .." <LINE> "..(thread and "<RGB:1,1,1> " or "<RGB:1,0,0> ")..getItemNameFromFullType("Base.Thread");
            trainTailoringOption.toolTip.description = trainTailoringOption.toolTip.description .." <LINE> "..(needle and "<RGB:1,1,1> " or "<RGB:1,0,0> ")..getItemNameFromFullType("Base.Needle");
            trainTailoringOption.toolTip.description = trainTailoringOption.toolTip.description .." <LINE> "..(fabric and "<RGB:1,1,1> " or "<RGB:1,0,0> ")..getItemNameFromFullType("Base.RippedSheets").." / "..getItemNameFromFullType("Base.DenimStrips").." / "..getItemNameFromFullType("Base.LeatherStrips");--todo use Tags = base:binding??
            if tooHighLevel then trainTailoringOption.toolTip.description = trainTailoringOption.toolTip.description .." <LINE> <RGB:1,0,0> "..getText("IGUI_perks_Tailoring").." "..tostring(tailoringLevel).." < 10"; end
            if hole then trainTailoringOption.toolTip.description = trainTailoringOption.toolTip.description .." <LINE> <RGB:1,0,0> "..getText("ContextMenu_PatchHole"); end 
        end
    end
    
    return context;
end


ISGarmentUI.autoSewing = function(player, clothing, part)
--we could click long after the menu was created and objects inside inventory could be gone so let's not
    if AutoTailoring.OPTIONS.Verbose then print ("ISGarmentUI.autoSewing start "..tostring(player).." "..tostring(clothing).." "..tostring(part)); end
    local inventory = player:getInventory()
    local thread = inventory:getItemFromType("Thread", true, true) or inventory:getItemFromTag(ItemTag.THREAD, true, true);
    local needle = inventory:getItemFromType("Needle", true, true) or inventory:getFirstTagRecurse(ItemTag.SEWING_NEEDLE);
    local hole = false--clothing:getVisual():getHole(part) > 0;--holes blocking patching is not a thing anymore with B42
    local actionStarted = false
    if thread and needle and not hole and player:getPerkLevel(Perks.Tailoring) < AutoTailoring.OPTIONS.MaxTailoringLevel then
        if AutoTailoring.OPTIONS.Verbose then print ("ISGarmentUI.autoSewing ressources check OK "..tostring(thread).." "..tostring(needle)); end
        local patch = clothing:getPatchType(part)
        if not patch then
            if AutoTailoring.OPTIONS.Verbose then print ("ISGarmentUI.autoSewing not patch"); end
            local fabric = AutoTailoring.getPatchingItem(player);--that ressource will be depleted frequently
            if fabric then
                if AutoTailoring.OPTIONS.Verbose then print ("ISGarmentUI.autoSewing fabric valid => repairClothing "..tostring(fabric)); end
                ISInventoryPaneContextMenu.repairClothing(player, clothing, part, fabric, thread, needle);
                actionStarted = true;
            end
        else
            if AutoTailoring.OPTIONS.Verbose then print ("ISGarmentUI.autoSewing patched => remove it"); end
            ISInventoryPaneContextMenu.removePatch(player, clothing, part, needle)
            actionStarted = true
        end
    else
        if AutoTailoring.OPTIONS.Verbose then print ("ISGarmentUI.autoSewing ressources check NOK "..tostring(thread or "no thread").." "..tostring(needle or "no needle").." "..tostring(hole and "hole" or "no hole").." Tailoring="..tostring(player:getPerkLevel(Perks.Tailoring))); end
    end
    if actionStarted and not AutoTailoring.actionStarted then--starting the session, boost time
        --setGameSpeed(4);getGameTime():setMultiplier(40);--activate max LEGAL game speed
        AutoTailoring.actionStarted = true;
        if AutoTailoring.OPTIONS.Verbose then print ("ISGarmentUI.autoSewing max speed= "..getGameSpeed().." "..getGameTime():getTrueMultiplier()); end
    elseif not actionStarted and AutoTailoring.actionStarted then--some ressource is depleted, freeze time
        if AutoTailoring.OPTIONS.Verbose then print ("ISGarmentUI.autoSewing stops for lack of ressources."); end
        AutoTailoring_stop(true);
    end
end

function AutoTailoring_stop(freeze)
    if AutoTailoring.actionStarted == false then
        print ("ERROR AutoTailoring_stop called while not started.");
    end
    if freeze == true then setGameSpeed(0);getGameTime():setMultiplier(1);--freeze game
    else setGameSpeed(1);getGameTime():setMultiplier(1); end--speed 1 game
    AutoTailoring.actionStarted = false;
    if AutoTailoring.OPTIONS.Verbose then print ("AutoTailoring_stop speed= "..getGameSpeed().." "..getGameTime():getTrueMultiplier()); end
end


--tool functions
function AutoTailoring.convertItemFabricTypeToEnum(fabricTypeString)
    if "Cotton"==fabricTypeString then return 1 end
    if "Denim"==fabricTypeString then return 2 end
    if "Leather"==fabricTypeString then return 3 end
    return 0
end
function AutoTailoring.getPatchingItem(player, fabricType)
    local fabric = nil
    if (not fabric and (not fabricType or fabricType == 1)) then fabric = AutoTailoring.getPlayerFastestItemAnyInventory(player,"RippedSheets"); end
    if (not fabric and (not fabricType or fabricType == 2)) then fabric = AutoTailoring.getPlayerFastestItemAnyInventory(player,"DenimStrips"); end
    if (not fabric and (not fabricType or fabricType == 3)) then fabric = AutoTailoring.getPlayerFastestItemAnyInventory(player,"LeatherStrips"); end
    if AutoTailoring.OPTIONS.Verbose then print ("AutoTailoring.getPatchingItem returns "..(fabric~=nil and tostring(fabric) or "nil").." for type ".. tostring(fabricType or "any")); end
    return fabric;
end

function AutoTailoring.getPlayerFastestItemAnyInventory(player,itemType)
    return player:getInventory():getItemFromType(itemType, true, true);
end

