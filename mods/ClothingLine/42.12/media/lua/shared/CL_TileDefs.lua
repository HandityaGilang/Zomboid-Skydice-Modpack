
do
    local vals1 = IsoWorld.PropertyValueMap:get("ContainerCapacity") or ArrayList.new()
    local vals2 = IsoWorld.PropertyValueMap:get("container") or ArrayList.new()
  --[[  local vals3 = IsoWorld.PropertyValueMap:get("IsMoveAble") or ArrayList.new()
    local vals4 = IsoWorld.PropertyValueMap:get("GroupName") or ArrayList.new()
    local vals5 = IsoWorld.PropertyValueMap:get("PickUpWeight") or ArrayList.new()
    local vals6 = IsoWorld.PropertyValueMap:get("CustomItem") or ArrayList.new()
    local vals7 = IsoWorld.PropertyValueMap:get("Facing") or ArrayList.new()
    local vals8 = IsoWorld.PropertyValueMap:get("TileOverlay") or ArrayList.new()
   -- local vals8 = IsoWorld.PropertyValueMap:get("TileOverlay") or ArrayList.new() --]]

for i = 1,20 do
    local val = tostring(i)
    if not vals1:contains(val) then vals1:add(val) end
end
    if not vals2:contains("clothesLineEnd") then vals2:add("clothesLineEnd") end
    if not vals2:contains("clothesLineMiddle") then vals2:add("clothesLineMiddle") end
    
--[[
    if not vals2:contains("clothesHorse") then vals2:add("clothesHorse") end
    if not vals2:contains("clothesHorse") then vals2:add("clothesHorse") end
    if not vals3:contains("True") then vals3:add("True") end
    if not vals4:contains("clothesHorse") then vals4:add("clothesHorse") end
    if not vals5:contains("20") then vals5:add("20") end
    if not vals6:contains("CL_clothingHorse.openClotheshorse") then vals6:add("CL_clothingHorse.openClotheshorse") end
    if not vals7:contains("S") then vals7:add("S") end
    if not vals7:contains("E") then vals7:add("E") end
    if not vals8:contains("True") then vals8:add("True") end --]]
   -- if not vals8:contains("True") then vals3:add("True") end
    IsoWorld.PropertyValueMap:put("ContainerCapacity",vals1)
    IsoWorld.PropertyValueMap:put("container",vals2)
--[[    IsoWorld.PropertyValueMap:put("IsMoveAble",vals3)
    IsoWorld.PropertyValueMap:put("GroupName",vals4)
    IsoWorld.PropertyValueMap:put("PickUpWeight",vals5)
    IsoWorld.PropertyValueMap:put("CustomItem",vals6)
    IsoWorld.PropertyValueMap:put("Facing",vals7)
    IsoWorld.PropertyValueMap:put("TileOverlay",vals8) --]]
   -- IsoWorld.PropertyValueMap:put("TileOverlay",vals8)

end

Events.OnLoadedTileDefinitions.Add(function(manager)
    local sprites = {
        "appliances_laundry_01_26",
        "appliances_laundry_01_27",
        "appliances_laundry_01_28",
        "appliances_laundry_01_29",
    }

    for _, sprite in ipairs(sprites) do
        local props = manager:getSprite(sprite):getProperties();
	    props:Set(IsoFlagType.container);
        props:Set("ContainerCapacity", "1", false);
        props:Set("container", "clothesLineEnd", false);
	    props:CreateKeySet();
    end

    sprites = {
        "appliances_laundry_01_30",
        "appliances_laundry_01_31",
    }

    for _, sprite in ipairs(sprites) do
        local props = manager:getSprite(sprite):getProperties();
	    props:Set(IsoFlagType.container);
        props:Set("ContainerCapacity", "2", false);
        props:Set("container", "clothesLineMiddle", false);
	    props:CreateKeySet();
    end
    --[[
    sprites = {
        "clothesHorse_0",
        "clothesHorse_2",
    }

    for _, sprite in ipairs(sprites) do
        local props = manager:getSprite(sprite):getProperties();
	    props:Set(IsoFlagType.container);
        props:Set("ContainerCapacity", "6", false);
        props:Set("container", "clothesHorse", false);
        props:Set("GroupName","clothesHorse", false);
        props:Set("IsMoveAble","True", false);
        props:Set("PickUpWeight","20", false);
        props:Set("CustomItem","CL_clothingHorse.openClotheshorse",false);
        if sprite == "clothesHorse_0" then
            props:Set("Facing","S",false)
        else props:Set("Facing","E",false)
        end
	    props:CreateKeySet();
    end
    sprites = {}
    
        for _, name in pairs(CL.fullSpriteNames)do
            for i=0,7 do
                table.insert(sprites,name..i)
            end
        end
    for _,sprite in pairs(sprites) do
        local props = manager:getSprite(sprite):getProperties();
        if string.sub(sprite,-1) == 0 or 1 or 4 or 6 then
            props:Set(IsoFlagType.attachedN);
        else props:Set(IsoFlagType.attachedW);end
	    props:Set("TileOverlay","True",false);
        props:Set(IsoFlagType.blocksight);
	    props:CreateKeySet();
    end
	--]]

end)


