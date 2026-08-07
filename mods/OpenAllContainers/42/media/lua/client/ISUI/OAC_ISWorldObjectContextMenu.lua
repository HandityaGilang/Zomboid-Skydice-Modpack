-- From "Open All Containers [B42]" mod -- Author = carlesturo

local OAC_SpriteData = require("OAC_SpriteData")
local OAC_Utils = require("OAC_Utils")

-- **************** DISABLE/ENABLE AUTO-CLOSE WORLD CONTEXT MENU ****************

local function resolvePlayerObj(player)
    if type(player) == "number" then
        return getSpecificPlayer(player) or getPlayer()
    end
    if player and instanceof(player, "IsoPlayer") then
        return player
    end
    return getPlayer()
end

local function OnFillWorldObjectContextMenu(player, context, worldObjects)
    local playerObj = resolvePlayerObj(player)
    if not playerObj then return end

    for _, obj in ipairs(worldObjects) do
        if instanceof(obj, "IsoObject") and obj:getSprite() then
            local spriteName = obj:getSprite():getName()
            local spriteData = OAC_SpriteData.getSpriteDataByOriginalSprite(spriteName)
            if spriteData then

                local modData = obj:getModData()
				local label
				if modData.forceAutoClose then
					label = getText("ContextMenu_DisableAutoClose")
				else
					label = getText("ContextMenu_EnableAutoClose")
				end

                local option = context:addOption(label, obj, function(o)
                    OAC_Utils.toggleAutoCloseForContainer(o, spriteData)
                end)

				local spriteName = obj:getSprite():getName()
				local texture = getTexture(spriteName)
				if texture then
					option.iconTexture = texture:splitIcon()
				end

                return
            end
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(OnFillWorldObjectContextMenu)