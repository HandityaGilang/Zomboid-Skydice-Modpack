if isServer() and not isClient() then return end

local lastCheckpoint = {}
local stepDistFrac = {}
local stepAccumulators = {
    walkSteps = {},
    runSteps = {},
    sprintSteps = {},
}
local STEP_REPORT_CHUNK = 10
local STEP_JITTER = 0.05
local STEP_CAP = 10
local lastStepResetDay = ""

local function getMovementType(player)
    if player:isSprinting() then return "sprintSteps" end
    if player:isRunning() then return "runSteps" end
    return "walkSteps"
end

local function onStepTick()
    local player = getPlayer and getPlayer() or nil
    if not player then return end
    if not player:isLocalPlayer() then return end
    if player:isDead() then return end
    if player:getVehicle() then return end
    if not player:isPlayerMoving() then return end

    local id = player:getPlayerNum()
    local px = player:getX()
    local py = player:getY()

    local today = os.date("!%Y%m%d")
    if today ~= lastStepResetDay then
        lastStepResetDay = today
        lastCheckpoint = {}
        stepDistFrac = {}
        stepAccumulators = { walkSteps = {}, runSteps = {}, sprintSteps = {} }
        return
    end

    if not lastCheckpoint[id] then
        lastCheckpoint[id] = { x = px, y = py }
        return
    end

    local dx = px - lastCheckpoint[id].x
    local dy = py - lastCheckpoint[id].y
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist >= STEP_CAP then
        lastCheckpoint[id] = { x = px, y = py }
        return
    end
    if dist <= STEP_JITTER then return end
    lastCheckpoint[id] = { x = px, y = py }

    local moveType = getMovementType(player)

    stepDistFrac[id] = (stepDistFrac[id] or 0) + dist
    local whole = math.floor(stepDistFrac[id])
    if whole < 1 then return end
    stepDistFrac[id] = stepDistFrac[id] - whole

    if DCS_Sync and DCS_Sync.getTodayChallenges then
        for _, ch in ipairs(DCS_Sync.getTodayChallenges()) do
            if ch.type == moveType and not DCS_Sync.isCompleted(ch.id) then
                DCS_Sync.addLocalProgress(ch.id, whole)
            end
        end
    end

    local acc = (stepAccumulators[moveType][id] or 0) + whole
    while acc >= STEP_REPORT_CHUNK do
        acc = acc - STEP_REPORT_CHUNK
        local today = os.date("!%Y%m%d")
        if DCS_Sync and DCS_Sync.getTodayChallenges then
            for _, ch in ipairs(DCS_Sync.getTodayChallenges()) do
                if ch.type == moveType and not DCS_Sync.isCompleted(ch.id) then
                    sendClientCommand(player, "DailyChallengeSystem", "reportChallengeProgress", {
                        challengeId = ch.id,
                        day = today,
                        amount = STEP_REPORT_CHUNK,
                    })
                end
            end
        end
    end
    stepAccumulators[moveType][id] = acc
end

Events.OnTick.Add(onStepTick)

local lastHairModel = {}

local function onClothingUpdated(character)
    if not character then return end
    if not instanceof(character, "IsoPlayer") then return end
    if not character:isLocalPlayer() then return end

    local id = character:getPlayerNum()
    local currentHair = character:getHumanVisual():getHairModel()

    if lastHairModel[id] and lastHairModel[id] ~= currentHair then
        local today = os.date("!%Y%m%d")

        if not DCS_Sync or not DCS_Sync.getTodayChallenges then return end
            for _, ch in ipairs(DCS_Sync.getTodayChallenges()) do
            if ch.type == "hairstyle"
            and not DCS_Sync.isCompleted(ch.id) then
                DCS_dprint("[DCS] Hairstyle match: " .. ch.id)
                sendClientCommand(character, "DailyChallengeSystem", "reportChallengeProgress", {
                    challengeId = ch.id,
                    day = today,
                    amount = 1,
                })
            end
        end
    end

    lastHairModel[id] = currentHair
end

Events.OnClothingUpdated.Add(onClothingUpdated)

if ISEatFoodAction and ISEatFoodAction.perform then
    local originalEatPerform = ISEatFoodAction.perform

    function ISEatFoodAction:perform()
        DCS_dprint("[DCS] ISEatFoodAction:perform fired")
        originalEatPerform(self)

        if not self.character then return end
        if not self.character:isLocalPlayer() then return end
        if not self.item then return end

        local foodType = self.item:getFullType()
        if not foodType then return end

        local today = os.date("!%Y%m%d")

        if not DCS_Sync or not DCS_Sync.getTodayChallenges then return end
            for _, ch in ipairs(DCS_Sync.getTodayChallenges()) do
            if ch.type == "eat"
            and not DCS_Sync.isCompleted(ch.id) then
                local matched = false
                if not ch.targetFood and not ch.targetFoods then
                    matched = true
                elseif ch.targetFood == foodType then
                    matched = true
                elseif ch.targetFoods then
                    for _, ft in ipairs(ch.targetFoods) do
                        if ft == foodType then
                            matched = true
                            break
                        end
                    end
                end
                if matched then
                    DCS_dprint("[DCS] Eat match: " .. ch.id .. " food=" .. foodType)
                    sendClientCommand(self.character, "DailyChallengeSystem", "reportChallengeProgress", {
                        challengeId = ch.id,
                        day = today,
                        amount = 1,
                    })
                end
            end
        end
    end
end
DCS_dprint("[DCS] ISEatFoodAction override applied: " .. tostring(ISEatFoodAction and ISEatFoodAction.perform ~= nil))

local function DCS_getActiveReadChallenge()
    if not DCS_Sync or not DCS_Sync.getTodayChallenges then return nil end
    for _, ch in ipairs(DCS_Sync.getTodayChallenges()) do
        if ch.type == "read" and not DCS_Sync.isCompleted(ch.id) then
            return ch
        end
    end
    return nil
end

if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.doLiteratureMenu then
    local originalDoLiteratureMenu = ISInventoryPaneContextMenu.doLiteratureMenu

    ISInventoryPaneContextMenu.doLiteratureMenu = function(context, items, player)
        local playerObj = getSpecificPlayer(player)
        local actualItems = ISInventoryPane.getActualUniqueItems(items)
        local picture = false
        local picturebook = false
        local recentlyRead = false
        local uninteresting = false
        local recipeItem = false
        local canBeRead = true
        local dcs_challengeReread = nil

        for i, k in ipairs(actualItems) do
            if playerObj:tooDarkToRead() then
                local nopeText = getText("ContextMenu_Read")
                local darkText = getText("ContextMenu_TooDark")
                if (playerObj:hasTrait(CharacterTrait.ILLITERATE) and (k:hasTag(ItemTag.PICTUREBOOK)) or k:hasTag(ItemTag.PICTURE)) then
                    nopeText = getText("ContextMenu_Look_at_pictures")
                    darkText = getText("ContextMenu_TooDarkToSee")
                end
                local nope = context:addOption(nopeText)
                nope.notAvailable = true
                local tooltip = ISInventoryPaneContextMenu.addToolTip()
                tooltip.description = darkText
                nope.toolTip = tooltip
                return
            end
            if playerObj:hasTrait(CharacterTrait.ILLITERATE) and (not k:hasTag(ItemTag.PICTUREBOOK) and not k:hasTag(ItemTag.PICTURE)) then
                local nope = context:addOption(getText("ContextMenu_Read"))
                nope.notAvailable = true
                local tooltip = ISInventoryPaneContextMenu.addToolTip()
                tooltip.description = getText("ContextMenu_Illiterate")
                nope.toolTip = tooltip
                canBeRead = false
            elseif k:getLvlSkillTrained() ~= -1 and SkillBook[k:getSkillTrained()].perk and k:getLvlSkillTrained() > playerObj:getPerkLevel(SkillBook[k:getSkillTrained()].perk) + 1 then
                local nope = context:addOption(getText("ContextMenu_Read"))
                nope.notAvailable = true
                local tooltip = ISInventoryPaneContextMenu.addToolTip()
                tooltip.description = getText("ContextMenu_TooComplicated")
                nope.toolTip = tooltip
                canBeRead = false
            elseif k:getMaxLevelTrained() ~= -1 and SkillBook[k:getSkillTrained()].perk and k:getMaxLevelTrained() <= playerObj:getPerkLevel(SkillBook[k:getSkillTrained()].perk) then
                local ch = DCS_getActiveReadChallenge()
                if ch then
                    dcs_challengeReread = ch
                    canBeRead = false
                else
                    local nope = context:addOption(getText("ContextMenu_Read"))
                    nope.notAvailable = true
                    local tooltip = ISInventoryPaneContextMenu.addToolTip()
                    tooltip.description = getText("ContextMenu_TooSimple")
                    nope.toolTip = tooltip
                    canBeRead = false
                end
            end
            if k:hasTag(ItemTag.PICTURE) then picture = true end
            if k:hasTag(ItemTag.PICTUREBOOK) then picturebook = true end
            if k:hasTag(ItemTag.UNINTERESTING) then uninteresting = true end
            if k:getModData().literatureTitle and playerObj:isLiteratureRead(k:getModData().literatureTitle) then recentlyRead = true end

            if #actualItems == 1 and k:getLearnedRecipes() and k:getLearnedRecipes():size() > 0 then
                recipeItem = k
            end
        end

        local readOption
        if canBeRead then
            if playerObj:hasTrait(CharacterTrait.ILLITERATE) and picturebook and not recentlyRead then
                readOption = context:addOption(getText("ContextMenu_Look_at_pictures"), items, ISInventoryPaneContextMenu.onLiteratureItems, player)
            elseif playerObj:hasTrait(CharacterTrait.ILLITERATE) and picturebook and recentlyRead then
                readOption = context:addOption(getText("ContextMenu_ReLook_at_pictures"), items, ISInventoryPaneContextMenu.onLiteratureItems, player)
                local tooltip = ISInventoryPaneContextMenu.addToolTip()
                tooltip.description = getText("ContextMenu_RecentlyRead")
                readOption.toolTip = tooltip
            elseif picture and recentlyRead then
                readOption = context:addOption(getText("ContextMenu_ReLook_at_picture"), items, ISInventoryPaneContextMenu.onLiteratureItems, player)
                local tooltip = ISInventoryPaneContextMenu.addToolTip()
                tooltip.description = getText("ContextMenu_RecentlyRead")
                readOption.toolTip = tooltip
            elseif picture then
                readOption = context:addOption(getText("ContextMenu_Look_at_picture"), items, ISInventoryPaneContextMenu.onLiteratureItems, player)
            elseif recentlyRead then
                readOption = context:addOption(getText("ContextMenu_ReRead"), items, ISInventoryPaneContextMenu.onLiteratureItems, player)
                local tooltip = ISInventoryPaneContextMenu.addToolTip()
                tooltip.description = getText("ContextMenu_RecentlyRead")
                readOption.toolTip = tooltip
            else
                readOption = context:addOption(getText("ContextMenu_Read"), items, ISInventoryPaneContextMenu.onLiteratureItems, player)
                if #actualItems == 1 then
                    readOption.itemForTexture = actualItems[1]
                end
                if uninteresting then
                    local tooltip = ISInventoryPaneContextMenu.addToolTip()
                    tooltip.description = getText("ContextMenu_EmptyNotebook")
                    readOption.toolTip = tooltip
                    readOption.notAvailable = true
                end
            end
        end

        if dcs_challengeReread then
            local rereadOption = context:addOption(getText("ContextMenu_ReRead"), items, ISInventoryPaneContextMenu.onLiteratureItems, player)
            local tooltip = ISInventoryPaneContextMenu.addToolTip()
            tooltip.description = "Reread this Skillbook to complete: '" .. dcs_challengeReread.title .. "' Daily Challenge"
            rereadOption.toolTip = tooltip
            readOption = rereadOption
        end

        if readOption and playerObj:isAsleep() then
            readOption.notAvailable = true
            local tooltip = ISInventoryPaneContextMenu.addToolTip()
            tooltip.description = getText("ContextMenu_NoOptionSleeping")
            readOption.toolTip = tooltip
        end
        if recipeItem then
            local canRead = (recipeItem:hasTag(ItemTag.PICTUREBOOK) or recipeItem:hasTag(ItemTag.PICTURE) or not playerObj:hasTrait(CharacterTrait.ILLITERATE))
            local SeeARecipe = getSandboxOptions():getOptionByName("SeeNotLearntRecipe"):getValue() == true or recipeItem:getKnownRecipes(playerObj):size() > 0
            if canRead and SeeARecipe then
                local text = getText("ContextMenu_ShowKnownRecipes")
                local recipeList
                if getSandboxOptions():getOptionByName("SeeNotLearntRecipe"):getValue() == true then
                    recipeList = recipeItem:getLearnedRecipes()
                    text = getText("ContextMenu_ShowRecipes")
                else recipeList = recipeItem:getKnownRecipes(playerObj) end
                ISInventoryPaneContextMenu.doRecipeList(context, text, recipeItem, recipeList, playerObj, true)
            end
        end
    end
    DCS_dprint("[DCS] ISInventoryPaneContextMenu.doLiteratureMenu override applied (skill book bypass)")
else
    print("[DCS] WARNING: ISInventoryPaneContextMenu.doLiteratureMenu not found — skill book bypass disabled")
end

if ISReadABook and ISReadABook.perform then
    local originalReadPerform = ISReadABook.perform
    local originalReadStart = ISReadABook.start
    local originalReadStop = ISReadABook.stop

    if ISReadABook.start then
        function ISReadABook:start()
            if originalReadStart then
                originalReadStart(self)
            end
            if self.item then
                local pages = self.item.getNumberOfPages and self.item:getNumberOfPages() or "N/A"
                DCS_dprint("[DCS] ISReadABook:start — item=" .. tostring(self.item:getFullType())
                    .. " pages=" .. tostring(pages))
            end
        end
    end

    function ISReadABook:stop()
        if originalReadStop then
            originalReadStop(self)
        end

        if not self.item then return end
        if not self.character then return end
        if not self.character:isLocalPlayer() then return end

        local itemStillInInventory = self.character:getInventory()
            and self.character:getInventory():containsID(self.item:getID())

        if itemStillInInventory then
            DCS_dprint("[DCS] ISReadABook:stop — item still in inventory, action interrupted: " .. tostring(self.item:getFullType()))
            return
        end

        local bookType = self.item:getFullType()
        if not bookType then return end

        local today = os.date("!%Y%m%d")
        DCS_dprint("[DCS] ISReadABook:stop — item consumed by server (completed): " .. bookType)

        if not DCS_Sync or not DCS_Sync.getTodayChallenges then return end
            for _, ch in ipairs(DCS_Sync.getTodayChallenges()) do
            if ch.type == "read"
            and not DCS_Sync.isCompleted(ch.id) then
                local matched = false
                if not ch.targetBook and not ch.targetBooks then
                    matched = true
                elseif ch.targetBook and ch.targetBook == bookType then
                    matched = true
                elseif ch.targetBooks then
                    for _, tb in ipairs(ch.targetBooks) do
                        if tb == bookType then matched = true; break end
                    end
                end
                if matched then
                    DCS_dprint("[DCS] Read match (via stop): " .. ch.id .. " book=" .. bookType)
                    sendClientCommand(self.character, "DailyChallengeSystem", "reportChallengeProgress", {
                        challengeId = ch.id,
                        day = today,
                        amount = 1,
                    })
                end
            end
        end
    end

    function ISReadABook:perform()
        originalReadPerform(self)

        if not self.item then
            DCS_dprint("[DCS] ISReadABook:perform abort: no self.item")
            return
        end

        local player = nil
        if self.character then
            player = self.character
        elseif self.playerNum ~= nil then
            player = getSpecificPlayer(self.playerNum)
        end
        if not player then return end
        if not player:isLocalPlayer() then return end

        local bookType = self.item:getFullType()
        if not bookType then return end

        local today = os.date("!%Y%m%d")
        local pages = self.item.getNumberOfPages and self.item:getNumberOfPages() or "N/A"
        DCS_dprint("[DCS] ISReadABook:perform fired — item=" .. bookType
            .. " pages=" .. tostring(pages))

        if not DCS_Sync or not DCS_Sync.getTodayChallenges then return end
            for _, ch in ipairs(DCS_Sync.getTodayChallenges()) do
            if ch.type == "read"
            and not DCS_Sync.isCompleted(ch.id) then
                local matched = false
                if not ch.targetBook and not ch.targetBooks then
                    matched = true
                elseif ch.targetBook and ch.targetBook == bookType then
                    matched = true
                elseif ch.targetBooks then
                    for _, tb in ipairs(ch.targetBooks) do
                        if tb == bookType then matched = true; break end
                    end
                end
                if matched then
                    DCS_dprint("[DCS] Read match: " .. ch.id .. " book=" .. bookType)
                    sendClientCommand(player, "DailyChallengeSystem", "reportChallengeProgress", {
                        challengeId = ch.id,
                        day = today,
                        amount = 1,
                    })
                end
            end
        end
    end

    local originalReadUpdate = ISReadABook.update
    function ISReadABook:update()
        if self.item and DCS_getActiveReadChallenge() then
            local trained = SkillBook[self.item:getSkillTrained()]
            if trained and self.item:getMaxLevelTrained() ~= -1 then
                local playerLevel = self.character:getPerkLevel(trained.perk)
                if self.item:getMaxLevelTrained() <= playerLevel then
                    self.pageTimer = self.pageTimer + getGameTime():getMultiplier()
                    self.item:setJobDelta(self:getJobDelta())
                    if not isClient() then
                        if self.item:getNumberOfPages() > 0 then
                            local pagesRead = math.floor(self.item:getNumberOfPages() * self:getJobDelta())
                            self.item:setAlreadyReadPages(pagesRead)
                            if self.item:getAlreadyReadPages() > self.item:getNumberOfPages() then
                                self.item:setAlreadyReadPages(self.item:getNumberOfPages())
                            end
                            self.character:setAlreadyReadPages(self.item:getFullType(), self.item:getAlreadyReadPages())
                        end
                    end
                    local bodyDamage = self.character:getBodyDamage()
                    local stats = self.character:getStats()
                    if self.stats and (self.item:getUnhappyChange() < 0.0) then
                        if stats:get(CharacterStat.UNHAPPINESS) > self.stats.unhappiness then
                            stats:set(CharacterStat.UNHAPPINESS, self.stats.unhappiness)
                        end
                    end
                    return
                end
            end
        end
        originalReadUpdate(self)
    end

    local originalReadAnimEvent = ISReadABook.animEvent
    function ISReadABook:animEvent(event, parameter)
        if event == "ReadAPage" and isServer() and self.item and DCS_getActiveReadChallenge() then
            local trained = SkillBook[self.item:getSkillTrained()]
            if trained and self.item:getMaxLevelTrained() ~= -1 then
                local playerLevel = self.character:getPerkLevel(trained.perk)
                if self.item:getMaxLevelTrained() <= playerLevel then
                    if self.item:getNumberOfPages() > 0 and self.startPage then
                        local pagesRead = math.floor(self.item:getNumberOfPages() * self.netAction:getProgress()) + self.startPage
                        self.item:setAlreadyReadPages(pagesRead)
                        if self.item:getAlreadyReadPages() > self.item:getNumberOfPages() then
                            self.item:setAlreadyReadPages(self.item:getNumberOfPages())
                            self.netAction:forceComplete()
                        end
                        self.character:setAlreadyReadPages(self.item:getFullType(), self.item:getAlreadyReadPages())
                        syncItemFields(self.character, self.item)
                    end
                    return
                end
            end
        end
        originalReadAnimEvent(self, event, parameter)
    end
else
    print("[DCS] WARNING: ISReadABook not found — read tracking disabled")
end

if ISApplyMakeUp and ISApplyMakeUp.perform then
    local originalMakeupPerform = ISApplyMakeUp.perform

    function ISApplyMakeUp:perform()
        originalMakeupPerform(self)

        if not self.character then return end
        if not self.character:isLocalPlayer() then return end

        local today = os.date("!%Y%m%d")

        if not DCS_Sync or not DCS_Sync.getTodayChallenges then return end
            for _, ch in ipairs(DCS_Sync.getTodayChallenges()) do
            if ch.type == "makeup"
            and not DCS_Sync.isCompleted(ch.id) then
                DCS_dprint("[DCS] Makeup match: " .. ch.id)
                sendClientCommand(self.character, "DailyChallengeSystem", "reportChallengeProgress", {
                    challengeId = ch.id,
                    day = today,
                    amount = 1,
                })
            end
        end
    end
else
    print("[DCS] WARNING: ISApplyMakeUp not found — makeup tracking disabled")
end

if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.onDrinkFluid then
    local origOnDrinkFluid = ISInventoryPaneContextMenu.onDrinkFluid
    ISInventoryPaneContextMenu.onDrinkFluid = function(item, percent, playerObj, openingRecipe, realItem)
        origOnDrinkFluid(item, percent, playerObj, openingRecipe, realItem)

        if not playerObj then return end
        if not playerObj:isLocalPlayer() then return end
        if not item then return end

        local fluidType = nil
        if item.getFluidContainer then
            local fc = item:getFluidContainer()
            if fc and fc.getPrimaryFluid then
                local rawFluid = fc:getPrimaryFluid()
                fluidType = tostring(rawFluid)
            end
        end

        DCS_dprint("[DCS] Drink fluid: fluidType=" .. tostring(fluidType) .. " item=" .. tostring(item:getFullType()))

        if not fluidType then return end

        local today = os.date("!%Y%m%d")
        if not DCS_Sync or not DCS_Sync.getTodayChallenges then return end; local todayChallenges = DCS_Sync.getTodayChallenges()
        DCS_dprint("[DCS] Drink: todayChallenges count=" .. #todayChallenges)

        for _, ch in ipairs(todayChallenges) do
            DCS_dprint("[DCS] Drink: checking ch.id=" .. ch.id .. " ch.type=" .. ch.type)
            if ch.type == "drink"
            and not DCS_Sync.isCompleted(ch.id) then
                DCS_dprint("[DCS] Drink: ch.targetFluid=" .. tostring(ch.targetFluid) .. " ch.targetFluids=" .. tostring(ch.targetFluids))
                local matched = false
                if ch.targetFluid == fluidType then
                    matched = true
                elseif ch.targetFluids then
                    DCS_dprint("[DCS] Drink: checking targetFluids array...")
                    for i, ft in ipairs(ch.targetFluids) do
                        DCS_dprint("[DCS] Drink:   [" .. i .. "]=" .. tostring(ft) .. " vs " .. tostring(fluidType) .. " match=" .. tostring(ft == fluidType))
                        if ft == fluidType then
                            matched = true
                            break
                        end
                    end
                end
                if matched then
                    DCS_dprint("[DCS] Drink match: " .. ch.id .. " fluid=" .. fluidType)
                    sendClientCommand(playerObj, "DailyChallengeSystem", "reportChallengeProgress", {
                        challengeId = ch.id,
                        day = today,
                        amount = 1,
                    })
                end
            end
        end
    end
    DCS_dprint("[DCS] Drink tracking registered via context menu hook")
else
    print("[DCS] WARNING: ISInventoryPaneContextMenu.onDrinkFluid not found")
end

if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.onDrinkForThirst then
    local origOnDrinkForThirst = ISInventoryPaneContextMenu.onDrinkForThirst
    ISInventoryPaneContextMenu.onDrinkForThirst = function(waterContainer, playerObj, percent, openingRecipe)
        origOnDrinkForThirst(waterContainer, playerObj, percent, openingRecipe)

        if not playerObj then return end
        if not playerObj:isLocalPlayer() then return end
        if not waterContainer then return end

        local fluidType = nil
        if waterContainer.getFluidContainer then
            local fc = waterContainer:getFluidContainer()
            if fc and fc.getPrimaryFluid then
                local rawFluid = fc:getPrimaryFluid()
                fluidType = tostring(rawFluid)
            end
        end

        DCS_dprint("[DCS] Drink from bottle: fluidType=" .. tostring(fluidType) .. " item=" .. tostring(waterContainer:getFullType()))

        if not fluidType then return end

        local today = os.date("!%Y%m%d")

        if not DCS_Sync or not DCS_Sync.getTodayChallenges then return end
            for _, ch in ipairs(DCS_Sync.getTodayChallenges()) do
            if ch.type == "drink"
            and not DCS_Sync.isCompleted(ch.id) then
                local matched = false
                if ch.targetFluid == fluidType then
                    matched = true
                elseif ch.targetFluids then
                    for _, ft in ipairs(ch.targetFluids) do
                        if ft == fluidType then
                            matched = true
                            break
                        end
                    end
                end
                if matched then
                    DCS_dprint("[DCS] Drink match: " .. ch.id .. " fluid=" .. fluidType)
                    sendClientCommand(playerObj, "DailyChallengeSystem", "reportChallengeProgress", {
                        challengeId = ch.id,
                        day = today,
                        amount = 1,
                    })
                end
            end
        end
    end
    DCS_dprint("[DCS] Drink from bottle tracking registered via context menu hook")
else
    print("[DCS] WARNING: ISInventoryPaneContextMenu.onDrinkForThirst not found")
end

if ISTakeWaterAction and ISTakeWaterAction.perform then
    local origTakeWaterPerform = ISTakeWaterAction.perform
    function ISTakeWaterAction:perform()
        origTakeWaterPerform(self)

        if self.item then return end
        if not self.character then return end
        if not self.character:isLocalPlayer() then return end
        if not self.waterObject then return end

        local fluidType = nil
        if self.waterObject.getPrimaryFluid then
            local rawFluid = self.waterObject:getPrimaryFluid()
            fluidType = tostring(rawFluid)
        end

        DCS_dprint("[DCS] ISTakeWaterAction:perform (drink from source) fluidType=" .. tostring(fluidType))

        if not fluidType or fluidType == "nil" then return end

        local today = os.date("!%Y%m%d")
        local found = false
        if not DCS_Sync or not DCS_Sync.getTodayChallenges then return end
            for _, ch in ipairs(DCS_Sync.getTodayChallenges()) do
            if ch.type == "drink"
            and not DCS_Sync.isCompleted(ch.id) then
                local matched = false
                if ch.targetFluid == fluidType then
                    matched = true
                elseif ch.targetFluids then
                    for _, ft in ipairs(ch.targetFluids) do
                        if ft == fluidType then
                            matched = true
                            break
                        end
                    end
                end
                if matched then
                    found = true
                    DCS_dprint("[DCS] Drink from source match: " .. ch.id .. " fluid=" .. fluidType)
                    sendClientCommand(self.character, "DailyChallengeSystem", "reportChallengeProgress", {
                        challengeId = ch.id,
                        day = today,
                        amount = 1,
                    })
                end
            end
        end
        if not found then
            DCS_dprint("[DCS] Drink from source — no active drink challenge for fluid=" .. tostring(fluidType))
        end
    end
    DCS_dprint("[DCS] Drink from water source tracking registered via ISTakeWaterAction:perform()")
else
    print("[DCS] WARNING: ISTakeWaterAction.perform not found")
end

if ISMoveablesAction and ISMoveablesAction.perform then
    local origMoveablesPerform = ISMoveablesAction.perform
    function ISMoveablesAction:perform()
        origMoveablesPerform(self)

        if not self or not self.mode then
            DCS_dprint("[DCS] ISMoveablesAction:perform() abort: no self or no mode")
            return
        end
        if not self.character then
            DCS_dprint("[DCS] ISMoveablesAction:perform() abort: no character")
            return
        end
        if not self.character:isLocalPlayer() then
            DCS_dprint("[DCS] ISMoveablesAction:perform() abort: not local player")
            return
        end

        DCS_dprint("[DCS] ISMoveablesAction:perform() mode=" .. tostring(self.mode))

        local actionType = nil
        if self.mode == "pickup" then
            actionType = "pickupFurniture"
        elseif self.mode == "place" then
            actionType = "placeFurniture"
        else
            DCS_dprint("[DCS] ISMoveablesAction:perform() skip: mode=" .. tostring(self.mode) .. " (not pickup/place)")
            return
        end

        local today = os.date("!%Y%m%d")
        local found = false
        if not DCS_Sync or not DCS_Sync.getTodayChallenges then return end
            for _, ch in ipairs(DCS_Sync.getTodayChallenges()) do
            if ch.type == actionType
            and not DCS_Sync.isCompleted(ch.id) then
                found = true
                DCS_dprint("[DCS] Furniture " .. actionType .. " match: " .. ch.id .. " -> reportChallengeProgress")
                sendClientCommand(self.character, "DailyChallengeSystem", "reportChallengeProgress", {
                    challengeId = ch.id,
                    day = today,
                    amount = 1,
                })
            end
        end
        if not found then
            DCS_dprint("[DCS] Furniture " .. actionType .. " — no active challenge of that type")
        end
    end
    DCS_dprint("[DCS] Furniture pickup/place tracking registered via ISMoveablesAction:perform()")
else
    print("[DCS] WARNING: ISMoveablesAction.perform not found")
end
