-- ************************************************************************
-- **        ██████  ██████   █████  ██    ██ ███████ ███    ██          **
-- **        ██   ██ ██   ██ ██   ██ ██    ██ ██      ████   ██          **
-- **        ██████  ██████  ███████ ██    ██ █████   ██ ██  ██          **
-- **        ██   ██ ██   ██ ██   ██  ██  ██  ██      ██  ██ ██          **
-- **        ██████  ██   ██ ██   ██   ████   ███████ ██   ████          **
-- ************************************************************************
-- ** All rights reserved. This content is protected by © Copyright law. **
-- ************************************************************************

---@param playerObj IsoPlayer
---@param clickedSquare IsoGridSquare
---@param spriteName string
---@param itemsList string "Item1_Name:Value", "Item2_Name:Value"...
local function collectItem(playerObj, clickedSquare, spriteName, itemsList)
	if luautils.walkAdj(playerObj, clickedSquare) then
        ISTimedActionQueue.add(BB_CS_CollectTimedAction:CollectItem(playerObj, clickedSquare, spriteName, itemsList))
	end
end

---@param player integer
---@param context ISContextMenu
---@param worldobjects IsoObject[]
---@param test boolean
local function addCollectOption(player, context, worldobjects, test)

    if not SandboxVars.CommonSense.ObviousCollecting then return end

    local playerObj = getSpecificPlayer(player)
    if playerObj:getVehicle() then return end

    local fetch = ISWorldObjectContextMenu.fetchVars
    if not fetch or not fetch.clickedSquare then return end

    local objs = fetch.clickedSquare:getObjects() --[[@as PZArrayList<IsoObject>]]

    for i = 0, objs:size() - 1 do
        local obj = objs:get(i)
        local spriteName = obj:getSprite() and obj:getSprite():getName() or ""
        local itemsList = BB_CS_CollectDatabase.Database[spriteName] or spriteName:contains("trash&junk") and ""

        if itemsList then
            local gardeningOpt = context:getOptionFromName(getText("ContextMenu_Gardening"))
            local option = nil --[[@as umbrella.ISContextMenu.Option?]]
            local optionName = ""
            local iconTex = nil --[[@as Texture?]]

            if gardeningOpt and not spriteName:contains("trash") then
                context = context:getSubMenu(gardeningOpt.subOption or -1) or context

                if itemsList:contains("Base.Log") then
                    optionName = getText("ContextMenu_CS_Pickup_Logs")
                    local logItem = ScriptManager.instance:FindItem("Base.Log")
                    iconTex = logItem and logItem:getNormalTexture()
                else
                    optionName = getText("IGUI_Pickup") .. ": " .. getText("IGUI_Name_Object")
                end
            else
                optionName = getText("ContextMenu_CS_Pickup_Trash")
            end
            option = context:addOptionOnTop( optionName, playerObj, collectItem, fetch.clickedSquare, spriteName, itemsList)
            option.iconTexture = iconTex or getTexture("media/textures/Foraging/eyeconOn_Shade.png")
            if itemsList == "" then
                option.notAvailable = true
                BB_CS_Utils.addTooltip(getText("ContextMenu_CannotBeForaged"), option)
            end
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(addCollectOption)