if isServer() and not isClient() then return end

local ANIMAL_GROUPS = {
    rabkitten = "rabbit",
    rabdoe = "rabbit",
    rabbuck = "rabbit",
    fawn = "deer",
    doe = "deer",
    buck = "deer",
    raccoonkit = "raccoon",
    raccoonsow = "raccoon",
    raccoonboar = "raccoon",
    ratbaby = "rat",
    rat = "rat",
    ratfemale = "rat",
    mousepups = "mouse",
    mouse = "mouse",
    mousefemale = "mouse",
    turkeypoult = "turkey",
    turkeyhen = "turkey",
    gobblers = "turkey",
}

local originalPickupFishPerform = ISPickupFishAction.perform

function ISPickupFishAction:perform()
    originalPickupFishPerform(self)

    if not self.isFish then return end
    if not self.character then return end
    if not self.character:isLocalPlayer() then return end

    local fishType = self.item and self.item:getFullType() or nil
    if not fishType then return end

    local today = os.date("!%Y%m%d")

    for _, ch in ipairs(DCS_Sync.getTodayChallenges()) do
        if ch.type == "fishing"
        and not DCS_Sync.isCompleted(ch.id) then
            if ch.targetFish == fishType or not ch.targetFish then
                DCS_dprint("[DCS] Fishing match: " .. ch.id .. " fish=" .. fishType)
                sendClientCommand(self.character, "DailyChallengeSystem", "reportChallengeProgress", {
                    challengeId = ch.id,
                    day = today,
                    amount = 1,
                })
            end
        end
    end
end

local function onCharacterDeath(character)
    if not character then return end
    if not instanceof(character, "IsoAnimal") then return end

    local animalType = character:getAnimalType()
    if not animalType then return end

    local group = ANIMAL_GROUPS[animalType]
    if not group then return end

    local killer = nil
    if character.getAttackedBy then
        killer = character:getAttackedBy()
    end

    if (not killer or not instanceof(killer, "IsoPlayer")) and DCS_Env.isSP() then
        local player = getPlayer and getPlayer() or nil
        if player then
            local dist = math.max(
                math.abs(player:getX() - character:getX()),
                math.abs(player:getY() - character:getY())
            )
            if dist <= 10 then
                killer = player
            end
        end
    end

    if not killer or not instanceof(killer, "IsoPlayer") then return end
    if not killer:isLocalPlayer() then return end

    local today = os.date("!%Y%m%d")

    for _, ch in ipairs(DCS_Sync.getTodayChallenges()) do
        if ch.type == "hunting"
        and not DCS_Sync.isCompleted(ch.id)
        and (ch.targetAnimal == group or not ch.targetAnimal) then
            DCS_dprint("[DCS] Hunting match: " .. ch.id .. " animal=" .. animalType .. " group=" .. group)
            sendClientCommand(killer, "DailyChallengeSystem", "reportChallengeProgress", {
                challengeId = ch.id,
                day = today,
                amount = 1,
            })
        end
    end
end

Events.OnCharacterDeath.Add(onCharacterDeath)
