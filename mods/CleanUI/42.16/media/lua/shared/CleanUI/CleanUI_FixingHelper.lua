CleanUI_FixingHelper = CleanUI_FixingHelper or {}

function CleanUI_FixingHelper.getFixingName(fixing)
    if fixing == nil then
        return "unknown"
    end

    local fixingName = fixing:getName()
    if fixingName ~= nil and fixingName ~= "" then
        return tostring(fixingName)
    end

    return "unknown"
end

function CleanUI_FixingHelper.getSafeFixes(item)
    local result = ArrayList.new()
    if item == nil then
        return result
    end

    local fullType = item:getFullType()
    if fullType == nil then
        return result
    end

    local allFixing = ScriptManager.instance:getAllFixing(ArrayList.new())
    if allFixing == nil then
        return result
    end

    for i = 0, allFixing:size() - 1 do
        local fixing = allFixing:get(i)
        if fixing ~= nil then
            local requiredItems = fixing:getRequiredItem()
            local fixers = fixing:getFixers()

            if requiredItems ~= nil and fixers ~= nil and fixers:size() > 0 and requiredItems:contains(fullType) then
                result:add(fixing)
            elseif requiredItems == nil then
                print("[CleanUI] Skipping invalid fixing without Require for " .. fullType .. ": " .. CleanUI_FixingHelper.getFixingName(fixing))
            end
        end
    end

    return result
end

function CleanUI_FixingHelper.getSafeFixing(item, fixingNum)
    local fixingList = CleanUI_FixingHelper.getSafeFixes(item)
    if fixingList == nil or fixingNum == nil then
        return nil
    end

    if fixingNum < 0 or fixingNum >= fixingList:size() then
        return nil
    end

    return fixingList:get(fixingNum)
end
