AutoTailoring = AutoTailoring or {}
AutoTailoring.OPTIONS = AutoTailoring.OPTIONS or {}
AutoTailoring.OPTIONS.Verbose = AutoTailoring.OPTIONS.Verbose or false;--from nil to false :D
AutoTailoring.OPTIONS.MaxTailoringLevel = AutoTailoring.OPTIONS.MaxTailoringLevel or 10

--hook the ISGarmentUI:doContextMenu to install our button
local genuine_ISGarmentUI_doContextMenu = ISGarmentUI.doContextMenu;
function ISGarmentUI:doContextMenu(part, x, y)
    local context = genuine_ISGarmentUI_doContextMenu(self, part, x, y);

    local needle = AutoTailoring.getPlayerFastestItemAnyInventoryByTag(self.chr,"SewingNeedle");
    local thread = AutoTailoring.getPlayerFastestItemAnyInventory(self.chr,"Thread");
    local hole = false--self.clothing:getVisual():getHole(part) > 0;--holes blocking patching is not a thing anymore with B42
    local fabric = AutoTailoring.getPatchingItem(self.chr);--will not start the auto stuff even if it could remove patch once and leave.
    local cannotBePatched = not self.clothing:getFabricType();
    
    local trainTailoringOption = context:addOption(getText("ContextMenu_AutoTailoring"), self.chr, ISGarmentUI.autoSewing, self.clothing, part);

    if not thread or not needle or not fabric or hole or cannotBePatched then
        trainTailoringOption.notAvailable = true
        trainTailoringOption.toolTip = ISInventoryPaneContextMenu.addToolTip();
        trainTailoringOption.toolTip.description = "You need";
        if hole then trainTailoringOption.toolTip.description = trainTailoringOption.toolTip.description .." <LINE> <RGB:1,0,0> "..getText("ContextMenu_PatchHole"); end 
        if not thread or not needle or not fabric then
            trainTailoringOption.toolTip.description = trainTailoringOption.toolTip.description .." <LINE> <RGB:1,0,0> "..getText("ContextMenu_CantRepair");
        end 
        if cannotBePatched then trainTailoringOption.toolTip.description = trainTailoringOption.toolTip.description .." <LINE> <RGB:1,0,0> "..getText("IGUI_garment_CantRepair"); end 
    end
    
    return context;
end

--activate on right-click on patchable item and left-click on "Auto Sewing"
local AutoTailoring_actionStarted = false
ISGarmentUI.autoSewing = function(player, clothing, part)
--we could click long after the menu was created and objects inside inventory could be gone so let's not
    if AutoTailoring.OPTIONS.Verbose then print ("ISGarmentUI.autoSewing start "..tostring(player).." "..tostring(clothing).." "..tostring(part)); end
    local needle = AutoTailoring.getPlayerFastestItemAnyInventoryByTag(player,"SewingNeedle");--self player is assumed still there but not needle
    local thread = AutoTailoring.getPlayerFastestItemAnyInventory(player,"Thread");--that ressource will be depleted frequently
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
    if actionStarted and not AutoTailoring_actionStarted then--starting the session, boost time
        --setGameSpeed(4);getGameTime():setMultiplier(40);--activate max LEGAL game speed
        AutoTailoring_actionStarted = true;
        if AutoTailoring.OPTIONS.Verbose then print ("ISGarmentUI.autoSewing max speed= "..getGameSpeed().." "..getGameTime():getTrueMultiplier()); end
    elseif not actionStarted and AutoTailoring_actionStarted then--some ressource is depleted, freeze time
        if AutoTailoring.OPTIONS.Verbose then print ("ISGarmentUI.autoSewing stops for lack of ressources."); end
        AutoTailoring_stop(true);
    end
end

function AutoTailoring_stop(freeze)
    if AutoTailoring_actionStarted == false then
        print ("ERROR AutoTailoring_stop called while not started.");
    end
    if freeze == true then setGameSpeed(0);getGameTime():setMultiplier(1);--freeze game
    else setGameSpeed(1);getGameTime():setMultiplier(1); end--speed 1 game
    AutoTailoring_actionStarted = false;
    if AutoTailoring.OPTIONS.Verbose then print ("AutoTailoring_stop speed= "..getGameSpeed().." "..getGameTime():getTrueMultiplier()); end
end

local genuine_ISRemovePatch_stop = ISRemovePatch.stop;
function ISRemovePatch:stop()
if AutoTailoring.OPTIONS.Verbose then print ("Debug ISRemovePatch:stop stuff "..tostring(self.clothing)..' '..tostring(self.part)); end
if AutoTailoring.OPTIONS.Verbose and self.clothing and self.part then print ("Debug ISRemovePatch:stop type "..tostring(self.clothing:getPatchType(self.part))); end
    genuine_ISRemovePatch_stop(self);
    if AutoTailoring_actionStarted then
        if AutoTailoring.OPTIONS.Verbose then print ("ISRemovePatch:stop calls AutoTailoring_sto"); end
        AutoTailoring_stop();
    end
end

local genuine_ISRepairClothing_stop = ISRepairClothing.stop;
function ISRepairClothing:stop()
    genuine_ISRepairClothing_stop(self);
    if AutoTailoring_actionStarted then
        if AutoTailoring.OPTIONS.Verbose then print ("ISRemovePatch:stop calls AutoTailoring_sto"); end
        AutoTailoring_stop();
    end
end


local genuine_ISRepairClothing_complete = ISRepairClothing.complete;
function ISRepairClothing:complete()
    local returnVal = genuine_ISRepairClothing_complete(self);
    if AutoTailoring_actionStarted then--let's do it after to ensure the patch is applied
        ISGarmentUI.autoSewing(self.character, self.clothing, self.part)
        if AutoTailoring.OPTIONS.Verbose then print ("ISRepairClothing:complete calls ISGarmentUI.autoSewing"); end
    end
    return returnVal
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
    return player:getInventory():getFirstTypeRecurse(itemType);
end
function AutoTailoring.getPlayerFastestItemAnyInventoryByTag(player,tag)
    return player:getInventory():getFirstTagRecurse(tag);
end





--temporary bug patch remove the removal from complete. it is also in perform
local genuine_ISRemovePatch_perform = ISRemovePatch.perform;
function ISRemovePatch:perform()
    self.lastPatch = self.clothing:getPatchType(self.part);
    genuine_ISRemovePatch_perform(self);
end



local genuine_ISRemovePatch_complete = ISRemovePatch.complete;
function ISRemovePatch:complete()
if AutoTailoring.OPTIONS.Verbose then print ("Debug ISRemovePatch:complete stuff "..tostring(self.clothing)..' '..tostring(self.part)); end
if AutoTailoring.OPTIONS.Verbose and self.clothing and self.part then print ("Debug ISRemovePatch:complete type "..tostring(self.clothing:getPatchType(self.part))); end

    -- chance to get the patch back
    if ZombRand(100) < ISRemovePatch.chanceToGetPatchBack(self.character) then
        local patch = self.clothing:getPatchType(self.part) or self.lastPatch;
        self.lastPatch = nil
        local fabricType = ClothingPatchFabricType.fromIndex(patch:getFabricType());
        local item = instanceItem(ClothingRecipesDefinitions["FabricType"][fabricType:getType()].material);
        self.character:getInventory():addItem(item);
        sendAddItemToContainer(self.character:getInventory(), item);
        -- doubled because the xp gains from ripping clothing was nerfed
        addXp(self.character, Perks.Tailoring, 6);
    end

    -- doubled because the xp gains from ripping clothing was nerfed
    -- removed random exp because people don't understand how it averages out over time and think it's a bug or bad
    addXp(self.character, Perks.Tailoring, ZombRand(2));
    -- 	addXp(self.character, Perks.Tailoring, ZombRand(1, 3));
    syncVisuals(self.character);
    
    
    ---my own auto stuff:
    if AutoTailoring_actionStarted then--let's do it after to ensure the patch is removed and maybe reuse the patch
        ISGarmentUI.autoSewing(self.character, self.clothing, self.part)
        if AutoTailoring.OPTIONS.Verbose then print ("ISRemovePatch:perform calls ISGarmentUI.autoSewing"); end
    end

    return true;
end

--local genuine_ISRemovePatch_update = ISRemovePatch.update;
--function ISRemovePatch:update()
--if AutoTailoring.OPTIONS.Verbose then print ("Debug ISRemovePatch.update stuff "..tostring(self.clothing)..' '..tostring(self.part)); end
--if AutoTailoring.OPTIONS.Verbose and self.clothing and self.part then print ("Debug ISRemovePatch.update type "..tostring(self.clothing:getPatchType(self.part))); end
--    genuine_ISRemovePatch_update(self);
--end
