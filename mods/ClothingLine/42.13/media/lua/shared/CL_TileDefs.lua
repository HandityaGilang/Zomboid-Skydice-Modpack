
do
    local vals1 = IsoWorld.PropertyValueMap:get("ContainerCapacity") or ArrayList.new()
    local vals2 = IsoWorld.PropertyValueMap:get("container") or ArrayList.new()

for i = 1,20 do
    local val = tostring(i)
    if not vals1:contains(val) then vals1:add(val) end
end
    if not vals2:contains("clothesLineEnd") then vals2:add("clothesLineEnd") end
    if not vals2:contains("clothesLineMiddle") then vals2:add("clothesLineMiddle") end
    IsoWorld.PropertyValueMap:put("ContainerCapacity",vals1)
    IsoWorld.PropertyValueMap:put("container",vals2)
end
Events.OnLoadedTileDefinitions.Add(function(manager)
    local sprites = {
        "appliances_laundry_01_26",
        "appliances_laundry_01_27",
        "appliances_laundry_01_28",
        "appliances_laundry_01_29",
    }

    for _, sprite in ipairs(sprites) do
        local props = manager:getSprite(sprite):getProperties()
            if props then
                props:set(IsoFlagType.container)
                props:set("ContainerCapacity", "1", false)
                props:set("container", "clothesLineEnd", false)
                props:CreateKeySet()
            end
    end
    sprites = {
        "appliances_laundry_01_30",
        "appliances_laundry_01_31",
    }
    for _, sprite in ipairs(sprites) do
        local props = manager:getSprite(sprite):getProperties()
	    props:set(IsoFlagType.container)
        props:set("ContainerCapacity", "2", false)
        props:set("container", "clothesLineMiddle", false)
	    props:CreateKeySet()
    end
end)


