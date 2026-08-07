VFX = VFX or {}

-- Debug Prints --

VFX.ReplaceOnUseDebug = false
VFX.TransferNutritionDebug = false

-- Transfer Nutrition --
    -- Transfer Nutrition Helpers --
        local function VFXFormatNutritionNumber(value)
            value = tonumber(value) or 0
            return string.format("%.2f", math.floor(value * 100) / 100)
        end

        local function VFXTransferNutritionDebug(message)
            if VFX.TransferNutritionDebug then
                print("[VFX.TransferNutrition] " .. tostring(message))
            end
        end

        local function VFXAddNutrition(total, calories, carbohydrates, lipids, proteins)
            total.calories = total.calories + calories
            total.carbohydrates = total.carbohydrates + carbohydrates
            total.lipids = total.lipids + lipids
            total.proteins = total.proteins + proteins
        end

        local VFXRecipeChecks = {}

        function VFXRecipeChecks.getItemUnits(item)
            return math.abs(item:getHungerChange()) * 100
        end

        function VFXRecipeChecks.inputScriptMatchesItem(inputScript, item)
            if not inputScript or not item then
                return false
            end

            if inputScript:getResourceType() ~= ResourceType.Item then
                return false
            end

            local fullType = item:getFullType()
            local possibleItems = inputScript:getPossibleInputItems()

            if possibleItems then
                for i = 0, possibleItems:size() - 1 do
                    local possibleItem = possibleItems:get(i)

                    if possibleItem and possibleItem:getFullName() == fullType then
                        return true
                    end
                end
            end

            return false
        end

        function VFXRecipeChecks.getInputAmount(inputScript, item)
            local fullType = item:getFullType()
            local amount = inputScript:getAmount(fullType)

            if not amount or amount <= 0 then
                amount = inputScript:getIntAmount()
            end

            return amount or 0
        end

        local function VFXGetFoodOutputs(results)
            local outputFoods = {}

            for i = 0, results:size() - 1 do
                local item = results:get(i)

                if instanceof(item, "Food") then
                    table.insert(outputFoods, item)
                end
            end

            return outputFoods
        end

        local function VFXCheckForFluids(craftRecipeData, outputTotal, includeHunger)
            local recipe = craftRecipeData:getRecipe()
            if not recipe then
                return
            end

            local scriptLines = recipe:getScriptLines()
            if not scriptLines then
                return
            end

            for lineIndex = 0, scriptLines:size() - 1 do
                local line = tostring(scriptLines:get(lineIndex))
                local amountText, allowedFluids = line:match("^%s*%-fluid%s+([%d%.]+)%s+%[([^%]]+)%]")

                if amountText and allowedFluids then
                    local usedAmount = tonumber(amountText) or 0
                    local fluids = {}
                    local fluidCodes = {}

                    for allowedFluid in string.gmatch(allowedFluids, "([^;]+)") do
                        allowedFluid = tostring(allowedFluid or ""):gsub("^%s+", ""):gsub("%s+$", "")

                        if allowedFluid ~= "" and Fluid and Fluid.getAllFluids then
                            local targetCode = allowedFluid:gsub("^%w+%.", "")
                            local allFluids = Fluid.getAllFluids()
                            local matchedFluid = nil

                            if allFluids then
                                for i = 0, allFluids:size() - 1 do
                                    local fluid = allFluids:get(i)

                                    if fluid then
                                        local fluidCode = tostring(fluid:getFluidTypeString() or ""):gsub("^%w+%.", "")

                                        if fluidCode == targetCode then
                                            matchedFluid = fluid
                                            break
                                        end
                                    end
                                end
                            end

                            if matchedFluid then
                                table.insert(fluids, matchedFluid)
                                table.insert(fluidCodes, targetCode)
                            else
                                VFXTransferNutritionDebug("Fluid not found: " .. tostring(allowedFluid))
                            end
                        end
                    end

                    if #fluids > 0 and usedAmount > 0 then
                        local averageHungerChange = 0
                        local averageCalories = 0
                        local averageCarbohydrates = 0
                        local averageLipids = 0
                        local averageProteins = 0

                        VFXTransferNutritionDebug("Input: " .. table.concat(fluidCodes, ";")
                            .. " | Units Needed: " .. VFXFormatNutritionNumber(usedAmount))

                        for i = 1, #fluids do
                            local fluid = fluids[i]
                            local properties = fluid:getProperties()

                            local hungerChange = properties:getHungerChange()
                            local calories = properties:getCalories()
                            local carbohydrates = properties:getCarbohydrates()
                            local lipids = properties:getLipids()
                            local proteins = properties:getProteins()

                            averageHungerChange = averageHungerChange + hungerChange
                            averageCalories = averageCalories + calories
                            averageCarbohydrates = averageCarbohydrates + carbohydrates
                            averageLipids = averageLipids + lipids
                            averageProteins = averageProteins + proteins

                            VFXTransferNutritionDebug(tostring(fluid:getDisplayName()) .. " [" .. tostring(i) .. "]:"
                                .. " cal=" .. VFXFormatNutritionNumber(calories)
                                .. " | carbs=" .. VFXFormatNutritionNumber(carbohydrates)
                                .. " | fat=" .. VFXFormatNutritionNumber(lipids)
                                .. " | protein=" .. VFXFormatNutritionNumber(proteins))
                        end

                        averageHungerChange = averageHungerChange / #fluids
                        averageCalories = averageCalories / #fluids
                        averageCarbohydrates = averageCarbohydrates / #fluids
                        averageLipids = averageLipids / #fluids
                        averageProteins = averageProteins / #fluids

                        if #fluids > 1 then
                            VFXTransferNutritionDebug("Average:"
                                .. " cal=" .. VFXFormatNutritionNumber(averageCalories)
                                .. " | carbs=" .. VFXFormatNutritionNumber(averageCarbohydrates)
                                .. " | fat=" .. VFXFormatNutritionNumber(averageLipids)
                                .. " | protein=" .. VFXFormatNutritionNumber(averageProteins))
                        end

                        local usedUnits = math.abs(averageHungerChange) * usedAmount * 100
                        local usedCalories = averageCalories * usedAmount
                        local usedCarbohydrates = averageCarbohydrates * usedAmount
                        local usedLipids = averageLipids * usedAmount
                        local usedProteins = averageProteins * usedAmount

                        if includeHunger then
                            outputTotal.units = outputTotal.units + usedUnits
                        end

                        VFXAddNutrition(outputTotal, usedCalories, usedCarbohydrates, usedLipids, usedProteins)

                        VFXTransferNutritionDebug("Used:"
                            .. " units=" .. VFXFormatNutritionNumber(usedAmount)
                            .. " | cal=" .. VFXFormatNutritionNumber(usedCalories)
                            .. " | carbs=" .. VFXFormatNutritionNumber(usedCarbohydrates)
                            .. " | fat=" .. VFXFormatNutritionNumber(usedLipids)
                            .. " | protein=" .. VFXFormatNutritionNumber(usedProteins))
                    end
                end
            end
        end

        local function VFXCollectNutrition(craftRecipeData, includeHunger)
            local consumedItems = craftRecipeData:getAllConsumedItems()
            local recipe = craftRecipeData:getRecipe()

            local outputTotal = {
                units = 0,
                calories = 0,
                carbohydrates = 0,
                lipids = 0,
                proteins = 0,
            }

            if not recipe then
                return outputTotal
            end

            local usedConsumedIndexes = {}
            local inputScripts = recipe:getInputs()

            for inputIndex = 0, inputScripts:size() - 1 do
                local inputScript = inputScripts:get(inputIndex)

                if inputScript:getResourceType() == ResourceType.Item then
                    local matchingItems = {}

                    for itemIndex = 0, consumedItems:size() - 1 do
                        local item = consumedItems:get(itemIndex)

                        if not usedConsumedIndexes[itemIndex]
                            and instanceof(item, "Food")
                            and VFXRecipeChecks.inputScriptMatchesItem(inputScript, item) then

                            table.insert(matchingItems, {
                                index = itemIndex,
                                item = item,
                            })
                        end
                    end

                    if #matchingItems > 0 then
                        local firstItem = matchingItems[1].item
                        local inputCode = firstItem:getFullType()
                        local inputAmount = VFXRecipeChecks.getInputAmount(inputScript, firstItem)

                        local inputTotal = {
                            units = 0,
                            calories = 0,
                            carbohydrates = 0,
                            lipids = 0,
                            proteins = 0,
                        }

                        if inputScript:isItemCount() then
                            local remainingCount = inputAmount
                            local usedItemCount = 0

                            VFXTransferNutritionDebug("Input: " .. tostring(inputCode)
                                .. " | Whole Units Needed: " .. VFXFormatNutritionNumber(inputAmount))

                            for i = 1, #matchingItems do
                                if remainingCount <= 0 then
                                    break
                                end

                                local itemData = matchingItems[i]
                                local item = itemData.item
                                local itemUnits = 0

                                if includeHunger then
                                    itemUnits = VFXRecipeChecks.getItemUnits(item)
                                    inputTotal.units = inputTotal.units + itemUnits
                                    outputTotal.units = outputTotal.units + itemUnits
                                end

                                usedConsumedIndexes[itemData.index] = true
                                remainingCount = remainingCount - 1
                                usedItemCount = usedItemCount + 1

                                VFXAddNutrition(inputTotal, item:getCalories(), item:getCarbohydrates(), item:getLipids(), item:getProteins())
                                VFXAddNutrition(outputTotal, item:getCalories(), item:getCarbohydrates(), item:getLipids(), item:getProteins())

                                local debugMessage = "Input: " .. tostring(item:getName()) .. " [" .. tostring(i) .. "]:"

                                if includeHunger then
                                    debugMessage = debugMessage
                                        .. " units=" .. VFXFormatNutritionNumber(itemUnits)
                                        .. " |"
                                end

                                VFXTransferNutritionDebug(debugMessage
                                    .. " cal=" .. VFXFormatNutritionNumber(item:getCalories())
                                    .. " | carbs=" .. VFXFormatNutritionNumber(item:getCarbohydrates())
                                    .. " | fat=" .. VFXFormatNutritionNumber(item:getLipids())
                                    .. " | protein=" .. VFXFormatNutritionNumber(item:getProteins()))
                            end

                            if usedItemCount > 1 then
                                local debugMessage = tostring(inputCode) .. " Total:"

                                if includeHunger then
                                    debugMessage = debugMessage
                                        .. " units=" .. VFXFormatNutritionNumber(inputTotal.units)
                                        .. " |"
                                end

                                VFXTransferNutritionDebug(debugMessage
                                    .. " cal=" .. VFXFormatNutritionNumber(inputTotal.calories)
                                    .. " | carbs=" .. VFXFormatNutritionNumber(inputTotal.carbohydrates)
                                    .. " | fat=" .. VFXFormatNutritionNumber(inputTotal.lipids)
                                    .. " | protein=" .. VFXFormatNutritionNumber(inputTotal.proteins))
                            end
                        else
                            local remainingUnits = inputAmount
                            local usedItemCount = 0

                            VFXTransferNutritionDebug("Input: " .. tostring(inputCode)
                                .. " | Units Needed: " .. VFXFormatNutritionNumber(inputAmount))

                            for i = 1, #matchingItems do
                                if remainingUnits <= 0 then
                                    break
                                end

                                local itemData = matchingItems[i]
                                local item = itemData.item
                                local itemUnits = VFXRecipeChecks.getItemUnits(item)
                                local usedUnits = math.min(itemUnits, remainingUnits)
                                local fraction = 0

                                if itemUnits > 0 then
                                    fraction = usedUnits / itemUnits
                                end

                                local usedCalories = item:getCalories() * fraction
                                local usedCarbohydrates = item:getCarbohydrates() * fraction
                                local usedLipids = item:getLipids() * fraction
                                local usedProteins = item:getProteins() * fraction

                                inputTotal.units = inputTotal.units + usedUnits

                                if includeHunger then
                                    outputTotal.units = outputTotal.units + usedUnits
                                end

                                VFXAddNutrition(inputTotal, usedCalories, usedCarbohydrates, usedLipids, usedProteins)
                                VFXAddNutrition(outputTotal, usedCalories, usedCarbohydrates, usedLipids, usedProteins)

                                usedConsumedIndexes[itemData.index] = true
                                remainingUnits = remainingUnits - usedUnits
                                usedItemCount = usedItemCount + 1

                                VFXTransferNutritionDebug(tostring(item:getName()) .. " [" .. tostring(i) .. "]:"
                                    .. " units=" .. VFXFormatNutritionNumber(itemUnits)
                                    .. " | cal=" .. VFXFormatNutritionNumber(item:getCalories())
                                    .. " | carbs=" .. VFXFormatNutritionNumber(item:getCarbohydrates())
                                    .. " | fat=" .. VFXFormatNutritionNumber(item:getLipids())
                                    .. " | protein=" .. VFXFormatNutritionNumber(item:getProteins()))

                                VFXTransferNutritionDebug("Used:"
                                    .. " units=" .. VFXFormatNutritionNumber(usedUnits)
                                    .. " | cal=" .. VFXFormatNutritionNumber(usedCalories)
                                    .. " | carbs=" .. VFXFormatNutritionNumber(usedCarbohydrates)
                                    .. " | fat=" .. VFXFormatNutritionNumber(usedLipids)
                                    .. " | protein=" .. VFXFormatNutritionNumber(usedProteins))
                            end

                            if usedItemCount > 1 then
                                VFXTransferNutritionDebug(tostring(inputCode) .. " Total:"
                                    .. " units=" .. VFXFormatNutritionNumber(inputTotal.units)
                                    .. " | cal=" .. VFXFormatNutritionNumber(inputTotal.calories)
                                    .. " | carbs=" .. VFXFormatNutritionNumber(inputTotal.carbohydrates)
                                    .. " | fat=" .. VFXFormatNutritionNumber(inputTotal.lipids)
                                    .. " | protein=" .. VFXFormatNutritionNumber(inputTotal.proteins))
                            end
                        end
                    end
                end
            end

            VFXCheckForFluids(craftRecipeData, outputTotal, includeHunger)

            return outputTotal
        end

    -- Transfer Nutrition --
        function VFX.TransferNutrition(craftRecipeData, character)
            local results = craftRecipeData:getAllCreatedItems()
            local recipe = craftRecipeData:getRecipe()

            if not recipe then
                VFXTransferNutritionDebug("No recipe found.")
                return
            end

            VFXTransferNutritionDebug("Preparing " .. tostring(recipe:getName()))

            local outputFoods = VFXGetFoodOutputs(results)

            if #outputFoods == 0 then
                VFXTransferNutritionDebug("No food output found.")
                return
            end

            local outputTotal = VFXCollectNutrition(craftRecipeData, false)
            local outputCount = #outputFoods

            local outputCalories = outputTotal.calories / outputCount
            local outputCarbohydrates = outputTotal.carbohydrates / outputCount
            local outputLipids = outputTotal.lipids / outputCount
            local outputProteins = outputTotal.proteins / outputCount

            for i = 1, outputCount do
                local result = outputFoods[i]

                result:setCalories(outputCalories)
                result:setCarbohydrates(outputCarbohydrates)
                result:setLipids(outputLipids)
                result:setProteins(outputProteins)

                VFXTransferNutritionDebug("Output: " .. tostring(result:getName())
                    .. " [" .. tostring(i) .. "/" .. tostring(outputCount) .. "]"
                    .. " | cal=" .. VFXFormatNutritionNumber(outputCalories)
                    .. " | carbs=" .. VFXFormatNutritionNumber(outputCarbohydrates)
                    .. " | fat=" .. VFXFormatNutritionNumber(outputLipids)
                    .. " | protein=" .. VFXFormatNutritionNumber(outputProteins))
            end
        end

    -- Transfer Nutrition Hunger --
        function VFX.TransferHungerNutrition(craftRecipeData, character)
            local results = craftRecipeData:getAllCreatedItems()
            local recipe = craftRecipeData:getRecipe()

            if not recipe then
                VFXTransferNutritionDebug("No recipe found.")
                return
            end

            VFXTransferNutritionDebug("Preparing " .. tostring(recipe:getName()))

            local outputFoods = VFXGetFoodOutputs(results)

            if #outputFoods == 0 then
                VFXTransferNutritionDebug("No food output found.")
                return
            end

            local outputTotal = VFXCollectNutrition(craftRecipeData, true)
            local outputCount = #outputFoods

            local outputUnits = outputTotal.units / outputCount
            local outputHunger = -(outputUnits / 100)

            local outputCalories = outputTotal.calories / outputCount
            local outputCarbohydrates = outputTotal.carbohydrates / outputCount
            local outputLipids = outputTotal.lipids / outputCount
            local outputProteins = outputTotal.proteins / outputCount

            for i = 1, outputCount do
                local result = outputFoods[i]

                result:setBaseHunger(outputHunger)
                result:setHungChange(outputHunger)
                result:setCalories(outputCalories)
                result:setCarbohydrates(outputCarbohydrates)
                result:setLipids(outputLipids)
                result:setProteins(outputProteins)

                VFXTransferNutritionDebug("Output: " .. tostring(result:getName())
                    .. " [" .. tostring(i) .. "/" .. tostring(outputCount) .. "]"
                    .. " | units=" .. VFXFormatNutritionNumber(outputUnits)
                    .. " | cal=" .. VFXFormatNutritionNumber(outputCalories)
                    .. " | carbs=" .. VFXFormatNutritionNumber(outputCarbohydrates)
                    .. " | fat=" .. VFXFormatNutritionNumber(outputLipids)
                    .. " | protein=" .. VFXFormatNutritionNumber(outputProteins))
            end
        end

    -- Transfer Nutrition Tags --
        local VFXOutputTags = {
            ["vfx:nutritiontarget"] = true,
        }

        local function VFXGetOutputTags(craftRecipeData)
            
            local recipe = craftRecipeData:getRecipe()
            local results = craftRecipeData:getAllCreatedItems()
            local taggedOutputTypes = {}
            local outputFoods = {}

            if not recipe then
                VFXTransferNutritionDebug("No recipe found while reading outputs.")
                return outputFoods
            end

            local outputs = recipe:getOutputs()

            if not outputs then
                VFXTransferNutritionDebug("Recipe has no outputs object: " .. tostring(recipe:getName()))
                return outputFoods
            end

            for outputIndex = 0, outputs:size() - 1 do
                local outputScript = outputs:get(outputIndex)

                if outputScript and outputScript:getResourceType() == ResourceType.Item then
                    local possibleResults = outputScript:getPossibleResultItems()

                    if possibleResults then
                        for itemIndex = 0, possibleResults:size() - 1 do
                            local possibleItem = possibleResults:get(itemIndex)
                            local fullName = nil
                            local matchedTag = nil

                            if possibleItem then
                                fullName = possibleItem:getFullName()

                                local tags = possibleItem:getTags()

                                if tags then
                                    local iterator = tags:iterator()

                                    while iterator:hasNext() do
                                        local tag = iterator:next()
                                        local tagText = tostring(tag)

                                        if VFXOutputTags[tagText] then
                                            matchedTag = tagText
                                            break
                                        end
                                    end
                                end
                            end

                            if fullName and matchedTag then
                                taggedOutputTypes[fullName] = true

                                VFXTransferNutritionDebug("Tagged recipe output selected: "
                                    .. tostring(fullName)
                                    .. " | tag="
                                    .. tostring(matchedTag))
                            elseif fullName then
                                VFXTransferNutritionDebug("Recipe output skipped, no matching output tag: "
                                    .. tostring(fullName))
                            end
                        end
                    else
                        VFXTransferNutritionDebug("Output script [" .. tostring(outputIndex)
                            .. "] getPossibleResultItems returned nil.")
                    end
                else
                    VFXTransferNutritionDebug("Output script [" .. tostring(outputIndex)
                        .. "] skipped, not an item resource.")
                end
            end

            for i = 0, results:size() - 1 do
                local item = results:get(i)
                local fullType = item:getFullType()

                if instanceof(item, "Food") and taggedOutputTypes[fullType] then
                    table.insert(outputFoods, item)

                    VFXTransferNutritionDebug("Created tagged food output selected: "
                        .. tostring(fullType))
                elseif instanceof(item, "Food") then
                    VFXTransferNutritionDebug("Created food output skipped, type not tagged: "
                        .. tostring(fullType))
                end
            end

            return outputFoods
        end

        function VFX.TransferNutritionTag(craftRecipeData, character)
            local recipe = craftRecipeData:getRecipe()

            if not recipe then
                VFXTransferNutritionDebug("No recipe found.")
                return
            end

            VFXTransferNutritionDebug("Preparing " .. tostring(recipe:getName()) .. " [tagged output]")

            local outputFoods = VFXGetOutputTags(craftRecipeData)

            if #outputFoods == 0 then
                VFXTransferNutritionDebug("No tagged food output found.")
                return
            end

            local outputTotal = VFXCollectNutrition(craftRecipeData, false)
            local outputCount = #outputFoods

            local outputCalories = outputTotal.calories / outputCount
            local outputCarbohydrates = outputTotal.carbohydrates / outputCount
            local outputLipids = outputTotal.lipids / outputCount
            local outputProteins = outputTotal.proteins / outputCount

            VFXTransferNutritionDebug("Tagged output count: " .. tostring(outputCount)
                .. " | cal each=" .. VFXFormatNutritionNumber(outputCalories)
                .. " | carbs each=" .. VFXFormatNutritionNumber(outputCarbohydrates)
                .. " | fat each=" .. VFXFormatNutritionNumber(outputLipids)
                .. " | protein each=" .. VFXFormatNutritionNumber(outputProteins))

            for i = 1, outputCount do
                local result = outputFoods[i]

                result:setCalories(outputCalories)
                result:setCarbohydrates(outputCarbohydrates)
                result:setLipids(outputLipids)
                result:setProteins(outputProteins)

                VFXTransferNutritionDebug("Output: " .. tostring(result:getName())
                    .. " [" .. tostring(i) .. "/" .. tostring(outputCount) .. "]"
                    .. " [tagged output]"
                    .. " | cal=" .. VFXFormatNutritionNumber(outputCalories)
                    .. " | carbs=" .. VFXFormatNutritionNumber(outputCarbohydrates)
                    .. " | fat=" .. VFXFormatNutritionNumber(outputLipids)
                    .. " | protein=" .. VFXFormatNutritionNumber(outputProteins))
            end
        end

        -- Replace On Use --
    -- Replace On Use Helpers --

        local function VFXFormatReplaceOnUseNumber(value)
            value = tonumber(value) or 0
            return tostring(value)
        end

        local function VFXReplaceOnUseDebug(message)
            if VFX.ReplaceOnUseDebug then
                print("[VFX.ReplaceOnUse] " .. tostring(message))
            end
        end

        local VFXReplaceOnUseChecks = {}

        function VFXReplaceOnUseChecks.getItemUnits(item)
            if not item or not instanceof(item, "Food") then
                return 0
            end

            return math.abs(item:getHungerChange()) * 100
        end

        function VFXReplaceOnUseChecks.inputScriptMatchesItem(inputScript, item)
            if not inputScript or not item then
                return false
            end

            if inputScript:getResourceType() ~= ResourceType.Item then
                return false
            end

            local fullType = item:getFullType()
            local possibleItems = inputScript:getPossibleInputItems()

            if possibleItems then
                for i = 0, possibleItems:size() - 1 do
                    local possibleItem = possibleItems:get(i)

                    if possibleItem and possibleItem:getFullName() == fullType then
                        return true
                    end
                end
            end

            return false
        end

        function VFXReplaceOnUseChecks.getInputAmount(inputScript, item)
            local fullType = item:getFullType()
            local amount = inputScript:getAmount(fullType)

            if not amount or amount <= 0 then
                amount = inputScript:getIntAmount()
            end

            return amount or 0
        end

        local function VFXGetReplaceOnUseType(item)
            if not item then
                return nil
            end

            local replaceType = item:getReplaceOnUseFullType()

            if replaceType and tostring(replaceType) ~= "" then
                return tostring(replaceType)
            end

            replaceType = item:getReplaceOnUse()

            if replaceType and tostring(replaceType) ~= "" then
                return tostring(replaceType)
            end

            return nil
        end

        local function VFXSpawnReplaceOnUseItem(character, replaceType, sourceItem)
            if not character then
                VFXReplaceOnUseDebug("Cannot spawn replacement; character is nil.")
                return
            end

            local inventory = character:getInventory()

            if not inventory then
                VFXReplaceOnUseDebug("Cannot spawn replacement; character inventory is nil.")
                return
            end

            local replacement = inventory:AddItem(replaceType)

            if replacement then
                VFXReplaceOnUseDebug("Spawned replacement: "
                    .. tostring(replaceType)
                    .. " | source="
                    .. tostring(sourceItem:getFullType()))
            else
                VFXReplaceOnUseDebug("Failed to spawn replacement: "
                    .. tostring(replaceType)
                    .. " | source="
                    .. tostring(sourceItem:getFullType()))
            end
        end

        local function VFXHandleFullyConsumedItem(item, character)
            local replaceType = VFXGetReplaceOnUseType(item)

            if not replaceType then
                VFXReplaceOnUseDebug("Fully consumed item has no ReplaceOnUse: "
                    .. tostring(item:getFullType()))
                return
            end

            VFXReplaceOnUseDebug("Fully consumed item has ReplaceOnUse: "
                .. tostring(item:getFullType())
                .. " -> "
                .. tostring(replaceType))

            VFXSpawnReplaceOnUseItem(character, replaceType, item)
        end

        local function VFXShouldSkipReplaceOnUseItem(item, options)
            if not item or not options or not options.skipItems then
                return false
            end

            local fullType = item:getFullType()

            if options.skipItems[fullType] then
                VFXReplaceOnUseDebug("Skipping ReplaceOnUse; item is excluded: "
                    .. tostring(fullType))
                return true
            end

            return false
        end

        local function VFXItemHasReplaceOnUse(item)
            if not item then
                return false
            end

            local replaceType = VFXGetReplaceOnUseType(item)

            if replaceType then
                VFXReplaceOnUseDebug("Item has ReplaceOnUse: "
                    .. tostring(item:getFullType())
                    .. " -> "
                    .. tostring(replaceType))
                return true
            end

            VFXReplaceOnUseDebug("Skipping ReplaceOnUse; item has no ReplaceOnUse: "
                .. tostring(item:getFullType()))
            return false
        end

function VFX.ReturnReplaceOnUse(craftRecipeData, character, options)
    if not craftRecipeData then
        VFXReplaceOnUseDebug("No craftRecipeData found.")
        return
    end

    options = options or {}

    local recipe = craftRecipeData:getRecipe()

    if not recipe then
        VFXReplaceOnUseDebug("No recipe found.")
        return
    end

    local consumedItems = craftRecipeData:getAllConsumedItems()

    if not consumedItems then
        VFXReplaceOnUseDebug("No consumed items found for recipe: " .. tostring(recipe:getName()))
        return
    end

    VFXReplaceOnUseDebug("Preparing " .. tostring(recipe:getName()))

    local inputScripts = recipe:getInputs()
    local usedConsumedIndexes = {}

    if not inputScripts then
        VFXReplaceOnUseDebug("Recipe has no inputs: " .. tostring(recipe:getName()))
        return
    end

    for inputIndex = 0, inputScripts:size() - 1 do
        local inputScript = inputScripts:get(inputIndex)

        if inputScript and inputScript:getResourceType() == ResourceType.Item then
            local matchingItems = {}

            for itemIndex = 0, consumedItems:size() - 1 do
                local item = consumedItems:get(itemIndex)

                if not usedConsumedIndexes[itemIndex]
                    and not VFXShouldSkipReplaceOnUseItem(item, options)
                    and VFXItemHasReplaceOnUse(item)
                    and VFXReplaceOnUseChecks.inputScriptMatchesItem(inputScript, item) then

                    table.insert(matchingItems, {
                        index = itemIndex,
                        item = item,
                    })
                end
            end

            if #matchingItems > 0 then
                local firstItem = matchingItems[1].item
                local inputCode = firstItem:getFullType()
                local inputAmount = VFXReplaceOnUseChecks.getInputAmount(inputScript, firstItem)

                if inputScript:isItemCount() then
                    local remainingCount = inputAmount

                    VFXReplaceOnUseDebug("Input: "
                        .. tostring(inputCode)
                        .. " | Whole Items Needed: "
                        .. VFXFormatReplaceOnUseNumber(inputAmount))

                    for i = 1, #matchingItems do
                        if remainingCount <= 0 then
                            break
                        end

                        local itemData = matchingItems[i]
                        local item = itemData.item

                        usedConsumedIndexes[itemData.index] = true
                        remainingCount = remainingCount - 1

                        VFXReplaceOnUseDebug("Consumed whole item: "
                            .. tostring(item:getFullType())
                            .. " ["
                            .. tostring(i)
                            .. "]")

                        VFXHandleFullyConsumedItem(item, character)
                    end
                else
                    local remainingUnits = inputAmount

                    VFXReplaceOnUseDebug("Input: "
                        .. tostring(inputCode)
                        .. " | Units Needed: "
                        .. VFXFormatReplaceOnUseNumber(inputAmount))

                    for i = 1, #matchingItems do
                        if remainingUnits <= 0 then
                            break
                        end

                        local itemData = matchingItems[i]
                        local item = itemData.item
                        local itemUnits = VFXReplaceOnUseChecks.getItemUnits(item)
                        local usedUnits = math.min(itemUnits, remainingUnits)
                        local itemUnitsRemaining = itemUnits - usedUnits
                        local fullyConsumed = itemUnits > 0 and itemUnitsRemaining < 1

                        usedConsumedIndexes[itemData.index] = true
                        remainingUnits = remainingUnits - usedUnits

                        VFXReplaceOnUseDebug("Input item: "
                            .. tostring(item:getFullType())
                            .. " ["
                            .. tostring(i)
                            .. "]"
                            .. " | itemUnits="
                            .. VFXFormatReplaceOnUseNumber(itemUnits)
                            .. " | usedUnits="
                            .. VFXFormatReplaceOnUseNumber(usedUnits)
                            .. " | itemUnitsRemaining="
                            .. VFXFormatReplaceOnUseNumber(itemUnitsRemaining)
                            .. " | fullyConsumed="
                            .. tostring(fullyConsumed))

                        if fullyConsumed then
                            VFXHandleFullyConsumedItem(item, character)
                        else
                            VFXReplaceOnUseDebug("Skipping ReplaceOnUse; item was not consumed 100%: "
                                .. tostring(item:getFullType()))
                        end
                    end
                end
            end
        end
    end
end

function VFX.ReturnReplaceOnUseSkipWortPot(craftRecipeData, character)
    VFX.ReturnReplaceOnUse(craftRecipeData, character, {
        skipItems = {
            ["VFX.WortPot"] = true,
            ["VFX.WortPotForged"] = true,
        },
    })
end

function VFX.ReturnReplaceOnUseSkipYogurtPreparationPan(craftRecipeData, character)
    VFX.ReturnReplaceOnUse(craftRecipeData, character, {
        skipItems = {
            ["VFX.YogurtPreparationPan"] = true,
            ["VFX.YogurtPreparationPanCopper"] = true,
        },
    })
end

function VFX.TransferNutritionReturnReplaceOnUse(craftRecipeData, character)
    VFX.ReturnReplaceOnUse(craftRecipeData, character)
    VFX.TransferNutrition(craftRecipeData, character)
end

function VFX.TransferNutritionTagReturnReplaceOnUse(craftRecipeData, character)
    VFX.ReturnReplaceOnUse(craftRecipeData, character)
    VFX.TransferNutritionTag(craftRecipeData, character)
end
