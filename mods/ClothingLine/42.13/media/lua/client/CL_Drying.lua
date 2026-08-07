CL = CL or {}
CL.itemList = {}

CL.timer = 0
CL.itemData = {}



function CL.compareTime(item)
    -- Ensure `theTime` exists and initialize it if it's not set
    local iTime = item:getModData().theTime or 0 -- Default to 0 if nil
    local gTime = CL.timer

    --print("Comparing times: CL.timer = " .. gTime .. ", item:getModData().theTime = " .. iTime)

    if (gTime > iTime) then
        local tDif = gTime - iTime
        --print("Time difference detected: tDif = " .. tDif)

        -- Update only if there is a difference
        if tDif > 0 then
            item:getModData().theTime = gTime
            return tDif
        end
    elseif (gTime < iTime) then item:getModData().theTime = gTime
    else
        --print("Times were equal or invalid: " .. gTime .. " = " .. iTime)
    end

    return 1 -- Default return if no significant difference is found
end


function CL.UpdateWetness(items)                              --sorts through the items in the clothesline containers and changes wetness based on weather and location
    for item,obj in pairs(items) do

        item:getModData().theTime = item:getModData().theTime or CL.timer
        if item and obj ~= nil and obj:getSquare() ~= nil and obj:getItemContainer() ~= nil then
            if item:IsClothing() then                                         --store items in a table
                CL.itemData = CL.itemData or {}
                CL.itemData[item:getContainer()] = item
            end
            local container = obj:getItemContainer()
            local cell = obj:getCell()
            if item:IsClothing() and not item:getModData().isIndoors then

                if not RainManager.isRaining() and item:getWetness() > 0 then --if the object is outside no rain
                    CL.updateItems(item,container,cell,item:getWetness() - (5 * CL.compareTime(item)))
                elseif RainManager.isRaining() then                            --if the object is outside raining
                    CL.updateItems(item,container,cell,item:getWetness() + (15 * CL.compareTime(item)))
                end
            elseif item:IsClothing() and item:getWetness() > 0 then             -- if the object is inside
                CL.updateItems(item,container,cell,item:getWetness() - (2 * CL.compareTime(item)))
            end
        end
    end
end

function CL.everyTenMinutes()
    if CL.ClothesLinesInSquare then
        local container = nil
        for obj in pairs(CL.ClothesLinesInSquare) do --iterate through clothesline objects that have been found
            if obj:getItemContainer() then 
             container = obj:getItemContainer():getItems()
                if container and not container:isEmpty() then
                    for x=0, container:size()-1 do
                        if obj:getModData().isIndoors then container:get(x):getModData().isIndoors = true end
                        if container:get(x) then
                            CL.itemList[container:get(x)] = obj
                        end
                    end
                end
            else --print("no container found")
            end
        end
        CL.itemList = CL.itemList or {}
            CL.UpdateWetness(CL.itemList)

    
    --check if i need to clear moddata on items
        if CL.itemData ~= nil then
            for c,item in pairs(CL.itemData)do
               if item:getWetness() == 0 then
               -- print("moddata reset")
                item:getModData().theTime = nil
               end
                if c ~=nil and item:getModData().theTime ~= nil then
                    if item:getContainer() ~= nil then
                        if item:getContainer():getParent() ~= nil then
                            if c:getParent() ~= nil then
                                if item:getContainer():getParent() ~= c:getParent() then
                                    --print("moddata reset")
                                    item:getModData().isIndoors = nil
                                    item:getModData().theTime = nil
                                end
                            end
                        end
                    end
                end
                
            end
        end
    end

    CL.timer = CL.timer + 1
    --print(" new Time " .. CL.timer)
    --print("10 minutes: " .. CL.timer)
end



Events.EveryTenMinutes.Add(CL.everyTenMinutes)

return CL