if isServer() and not isClient() then return end

if ISHandcraftAction and ISHandcraftAction.perform then
    local originalHandcraftPerform = ISHandcraftAction.perform

    function ISHandcraftAction:perform()
        originalHandcraftPerform(self)

        if not self.character then return end
        if not self.character:isLocalPlayer() then return end
        if not self.craftRecipe then return end

        local recipeName = self.craftRecipe:getName()
        if not recipeName then return end

        local outputAmount = 1
        local outputs = self.craftRecipe:getOutputs()
        if outputs and outputs.size then
            outputAmount = 0
            for i = 0, outputs:size() - 1 do
                local out = outputs:get(i)
                if out then
                    local amt = 0
                    if out.getIntAmount then
                        amt = out:getIntAmount()
                    elseif out.getAmount then
                        amt = math.floor(out:getAmount())
                    end
                    outputAmount = outputAmount + amt
                end
            end
            if outputAmount <= 0 then outputAmount = 1 end
        end

        local today = os.date("!%Y%m%d")
        DCS_dprint("[DCS] ISHandcraftAction:perform fired — recipe=" .. recipeName .. " outputAmount=" .. outputAmount)

        for _, ch in ipairs(DCS_Sync.getTodayChallenges()) do
            if ch.type == "craft"
            and not DCS_Sync.isCompleted(ch.id) then
                local matched = false
                if ch.targetRecipe == recipeName then
                    matched = true
                elseif ch.targetRecipes then
                    for _, name in ipairs(ch.targetRecipes) do
                        if name == recipeName then
                            matched = true
                            break
                        end
                    end
                end
                if matched then
                    DCS_dprint("[DCS] Craft match: " .. ch.id .. " recipe=" .. recipeName .. " amount=" .. outputAmount)
                    sendClientCommand(self.character, "DailyChallengeSystem", "reportChallengeProgress", {
                        challengeId = ch.id,
                        day = today,
                        amount = outputAmount,
                    })
                end
            end
        end
    end
else
    print("[DCS] WARNING: ISHandcraftAction not found — craft tracking disabled")
end

local originalBuildPerform = ISBuildAction.perform

function ISBuildAction:perform()
    originalBuildPerform(self)

    if not self.character then return end
    if not self.character:isLocalPlayer() then return end

    local today = os.date("!%Y%m%d")

    local entityName = nil
    if self.item and self.item.name then
        entityName = self.item.name
    end
    local isBarricade = entityName and entityName:find("Barricade") ~= nil

    DCS_dprint("[DCS] Build entity: name=" .. tostring(entityName) .. " barricade=" .. tostring(isBarricade))

    for _, ch in ipairs(DCS_Sync.getTodayChallenges()) do
        if not DCS_Sync.isCompleted(ch.id) then
            local matched = false

            if ch.type == "barricade" and isBarricade then
                matched = true
            elseif ch.type == "build" and not ch.targetBuild and not ch.targetBuilds then
                matched = true
            elseif ch.type == "build" and entityName then
                if ch.targetBuild == entityName then
                    matched = true
                elseif ch.targetBuilds then
                    for _, name in ipairs(ch.targetBuilds) do
                        if name == entityName then
                            matched = true
                            break
                        end
                    end
                end
            end

            if matched then
                DCS_dprint("[DCS] Build match: " .. ch.id .. " entity=" .. tostring(entityName) .. " barricade=" .. tostring(isBarricade))
                sendClientCommand(self.character, "DailyChallengeSystem", "reportChallengeProgress", {
                    challengeId = ch.id,
                    day = today,
                    amount = 1,
                })
            end
        end
    end
end
