--[[require "recipecode"
function AliceTextureOnCreateFunction(items, result, player)
    --=========== HANDLE TEXTURE CHOICE PART
    -- Initialize a nil texture choice
    local textureChoice = nil

    -- Loop over all ingredients and find the item you want to base it on
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item:IsClothing() or instanceof(item, "InventoryContainer") then
            local visual = item:getVisual()
            if visual then
                textureChoice = visual:getTextureChoice() -- At this point, target item, visual choice exists, so we set previously initiailized textureChoice to that target item's textureChoice, and break from the loop
                break
            else
                print("WARNING: Fabric visual not found for one item. Skipping.") -- Error handling in case target item doesn't have a visual
            end
        end
    end

    if textureChoice then -- Set the result item to the texture choice
        result:getVisual():setTextureChoice(textureChoice)
    else               -- Error handling in case texture choice is still nil
        print("ERROR: textureChoice not found. Stopping the function.")
    end
end]]