-- From "Snowman" mod -- Author = carlesturo

local Data_Snowman = require("Data_Snowman")

if not Container_Snowman then Container_Snowman = {} end

-------------------------------------------------
-- AUXILIARY FUNCTIONS
-------------------------------------------------

function Container_Snowman.AcceptItemFunction(container, item)
    if not container or not item then return false end
    local fullType = item:getFullType()
    if not fullType then return false end

    if fullType == "Base.Button" then
        local count = 0
        local items = container:getItems()
        for i=0, items:size()-1 do
            local it = items:get(i)
            if it and it:getFullType() == "Base.Button" then
                count = count + 1
            end
        end
        return count < (Data_Snowman.ItemLimits.Buttons or 5)
    end

	if fullType == "Base.TreeBranch2" then
		local count = 0
		local items = container:getItems()
		for i=0, items:size()-1 do
			local it = items:get(i)
			if it and it:getFullType() == "Base.TreeBranch2" then
				count = count + 1
			end
		end
		return count < (Data_Snowman.ItemLimits.Arms or 2)
	end

    for catName, map in pairs(Data_Snowman.Categories) do
        if catName ~= "Buttons" and catName ~= "Arms" and map[fullType] then
            local count = 0
            local items = container:getItems()
            for i=0, items:size()-1 do
                local it = items:get(i)
                if it and it:getFullType() and map[it:getFullType()] then
                    count = count + 1
                end
            end
            local limit = Data_Snowman.ItemLimits[catName] or 1
            return count < limit
        end
    end

    return false
end

function Container_Snowman.AddChildSprite(isoObject, spriteData, item)
    if not isoObject or not spriteData then return end

    local baseSprite = isoObject:getSprite():getName()
    local spriteName

	if type(spriteData) == "table" then
		local posMap = {["snowman_01_0"] = 1, ["snowman_01_1"] = 2, ["snowman_01_2"] = 3, ["snowman_01_3"] = 4}
        local idx = posMap[baseSprite] or 1
        spriteName = spriteData[idx]
    else
        spriteName = spriteData
    end

    if not spriteName or spriteName == "" then return end

    local spriteInst = getSpriteManager(spriteName):AddSprite(spriteName)
    if not spriteInst then return end

    spriteInst:setName(spriteName)

    if item and item.getColorInfo then
        local col = item:getColorInfo()
        if col then
            local cinfo = ColorInfo.new()
            cinfo:set(col)
            spriteInst:setTintMod(cinfo)
        end
    end

    isoObject:addAttachedAnimSprite(spriteInst)
end

-------------------------------------------------
-- SPRITE UPDATE
-------------------------------------------------

function Container_Snowman.UpdateOverlay(isoObject)
    if not isoObject or not isoObject:getContainer() then return end

    local sprite = isoObject:getSprite()
    if not sprite or not sprite:getName() or not string.find(sprite:getName(), "snowman_01_") then
        return
    end

    local container = isoObject:getContainer()
    local items = container:getItems()
    local modData = isoObject:getModData()

    modData.overlayOrder = modData.overlayOrder or {}
    local overlayOrder = modData.overlayOrder

    isoObject:setAttachedAnimSprite(nil)

    if items:isEmpty() then
        local dummy = IsoSpriteManager.instance:getSprite("constructedobjects_01_0")
        if dummy then
            isoObject:addAttachedAnimSprite(dummy)
            isoObject:setAttachedAnimSprite(nil)
        end
        modData.overlayOrder = {}
        if isServer() then
			isoObject:transmitUpdatedSprite()
		end
        return
    end

    -- Get current items from container
    local currentItems = {}
    for i=0, items:size()-1 do
        currentItems[i+1] = items:get(i)
    end

    -- Remove items from overlayOrder no longer in container
    for i = #overlayOrder, 1, -1 do
        local found = false
        for _, it in ipairs(currentItems) do
            if it == overlayOrder[i] then
                found = true
                break
            end
        end
        if not found then table.remove(overlayOrder, i) end
    end

    -- Add new items to overlayOrder preserving insert order
    for _, it in ipairs(currentItems) do
        local exists = false
        for _, oi in ipairs(overlayOrder) do
            if oi == it then
                exists = true
                break
            end
        end
        if not exists then table.insert(overlayOrder, it) end
    end

    -- Draw overlays according to overlayOrder
    for _, itemObj in ipairs(overlayOrder) do
        if itemObj and itemObj:getFullType() then
            local ft = itemObj:getFullType()
            local spriteData

			--[[if itemObj.getIcon then
				local iconTex = itemObj:getIcon()
				if iconTex then
					print("Item:", ft, "Icon name:", iconTex:getName())
				else
					print("Item:", ft, "Icon: nil")
				end
			end--]]

            if ft == "Base.Button" then
                local btnIndex, count = 0, 0
                for i=0, items:size()-1 do
                    local it = items:get(i)
                    if it:getFullType() == "Base.Button" then
                        count = count + 1
                        if it == itemObj then
                            btnIndex = count
                            break
                        end
                    end
                end
                spriteData = Data_Snowman.Buttons[btnIndex]

			elseif ft == "Base.TreeBranch2" then
				local armIndex, count = 0, 0
				for i=0, items:size()-1 do
					local it = items:get(i)
					if it:getFullType() == "Base.TreeBranch2" then
						count = count + 1
						if it == itemObj then
							armIndex = count
							break
						end
					end
				end
				spriteData = Data_Snowman.Arms[armIndex]

            else
				for catName, map in pairs(Data_Snowman.Categories) do
					if map[ft] then
						local spriteVariants = map[ft]

						if type(spriteVariants) == "table" then
							local isArray = #spriteVariants > 0

							if isArray then
								local baseSprite = isoObject:getSprite():getName()
								local posMap = {["snowman_01_0"] = 1, ["snowman_01_1"] = 2, ["snowman_01_2"] = 3, ["snowman_01_3"] = 4}
								local idx = posMap[baseSprite] or 1
								spriteData = spriteVariants[idx]

							else
								local iconName = itemObj:getIcon():getName()
								iconName = string.match(iconName, "([^/\\]+)$") or iconName
								iconName = string.gsub(iconName, "^Item_", "")
								iconName = string.gsub(iconName, "%.png$", "")
								spriteData = spriteVariants[iconName]
							end
						end

						break
					end
				end
            end

            if spriteData then
                Container_Snowman.AddChildSprite(isoObject, spriteData, itemObj)
            end
        end
    end

    if isServer() then
		isoObject:transmitUpdatedSprite()
	end
end

-------------------------------------------------
-- CALLBACKS
-------------------------------------------------

function Container_Snowman.OnContainerContentsChanged(container)
    if not container then return end
    local parent = container:getParent()
    if not parent then return end
    local sprite = parent:getSprite()
    if not sprite or not sprite:getName() then return end
    if string.find(sprite:getName(), "snowman_01_") then
        Container_Snowman.UpdateOverlay(parent)
    end
end

function Container_Snowman.SetupPlacedTile(isoObject)
    if not isoObject or not isoObject:getContainer() then return end
    local container = isoObject:getContainer()

    container:setAcceptItemFunction('Container_Snowman.AcceptItemFunction')

    if container.setOnContentsChangedCallback then
        pcall(function()
            container:setOnContentsChangedCallback("Container_Snowman.OnContainerContentsChanged")
        end)
    end

    Container_Snowman.UpdateOverlay(isoObject)
end

Events.OnObjectAdded.Add(function(isoObject)
    if not isoObject then return end
    local sprite = isoObject:getSprite()
    if not sprite then return end
    local spriteName = sprite:getName()
    if spriteName and string.find(spriteName, "snowman_01_") then
        Container_Snowman.SetupPlacedTile(isoObject)
    end
end)

local tile_tags = { "snowman_01" }
for _, value in ipairs(tile_tags) do
    for i = 0, 3 do
        MapObjects.OnLoadWithSprite(value .. "_" .. i, Container_Snowman.SetupPlacedTile, 5)
    end
end

Events.OnCreatePlayer.Add(function(playerIndex, player)
    if ISInventoryTransferAction and ISInventoryTransferAction.perform then
        local ISInventoryTransferAction_perform_original = ISInventoryTransferAction.perform
        function ISInventoryTransferAction:perform()
            ISInventoryTransferAction_perform_original(self)
            if self.srcContainer and self.srcContainer:getParent() then
                Container_Snowman.UpdateOverlay(self.srcContainer:getParent())
            end
            if self.destContainer and self.destContainer:getParent() then
                Container_Snowman.UpdateOverlay(self.destContainer:getParent())
            end
        end
    end
end)