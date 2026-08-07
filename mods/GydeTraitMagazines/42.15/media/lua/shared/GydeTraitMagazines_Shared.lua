GydeTraitMags = GydeTraitMags or {}

GydeTraitMags.magazineTraits = {
    ["Base.NutritionistMag"] = CharacterTrait.NUTRITIONIST,
    ["Base.OutdoorsmanMag"]  = CharacterTrait.OUTDOORSMAN,
    ["Base.HandyMag"]        = CharacterTrait.HANDY,
    ["Base.AxeManMag"]       = CharacterTrait.AXEMAN,
    ["Base.BurglarMag"]      = CharacterTrait.BURGLAR,

    ["Base.SpeedDemonMag"]   = { positive = CharacterTrait.SPEED_DEMON, negative = CharacterTrait.SUNDAY_DRIVER },
    ["Base.OrganizedMag"]    = { positive = CharacterTrait.ORGANIZED, negative = CharacterTrait.DISORGANIZED },
    ["Base.FastLearnerMag"]  = { positive = CharacterTrait.FAST_LEARNER, negative = CharacterTrait.SLOW_LEARNER },
    ["Base.FastReaderMag"]   = { positive = CharacterTrait.FAST_READER, negative = CharacterTrait.SLOW_READER },
    ["Base.GracefulMag"]     = { positive = CharacterTrait.GRACEFUL, negative = CharacterTrait.CLUMSY },
    ["Base.DextrousMag"]     = { positive = CharacterTrait.DEXTROUS, negative = CharacterTrait.ALL_THUMBS },
    ["Base.InconspicuousMag"]= { positive = CharacterTrait.INCONSPICUOUS, negative = CharacterTrait.CONSPICUOUS },
    ["Base.KeenHearingMag"]  = { positive = CharacterTrait.KEEN_HEARING, negative = CharacterTrait.HARD_OF_HEARING }
}

function GydeTraitMags.applyMagazineTraits(player, magType)
    local traitData = GydeTraitMags.magazineTraits[magType]

    if not traitData then return end

    local traits = player:getCharacterTraits()
    local used = false
    local md = player:getModData()
    md.CuredNegativeTraits = md.CuredNegativeTraits or {}

    local function markCured(trait)
        md.CuredNegativeTraits[tostring(trait)] = true
    end

    local function wasCured(trait)
        return md.CuredNegativeTraits[tostring(trait)]
    end

    -- Handle traits with counterparts.
    if type(traitData) == "table" then
        -- 1: Check if player has negative trait.
        if player:hasTrait(traitData.negative) then
            traits:remove(traitData.negative)
            markCured(traitData.negative)
            used = true
            -- If magazines aren't consumed and NegToPos is allowed, add the pos stat immediately.
            if SandboxVars.GydeTraitMags.NegativeToPositive and not SandboxVars.GydeTraitMags.ReadDelete then
                traits:add(traitData.positive)
            end

        -- 2. Check if player has the positive trait.
        elseif not player:hasTrait(traitData.positive) then
            -- If player did not have negative trait, grant positive trait.
            if not wasCured(traitData.negative) or SandboxVars.GydeTraitMags.NegativeToPositive then
                traits:add(traitData.positive)
                used = true
            end

        -- 3. If pos trait remove is enabled, remove trait.
        elseif SandboxVars.GydeTraitMags.ReadRemove then
            traits:remove(traitData.positive)
            used = true
        end

    -- Handle simple traits.
    else
        if not player:hasTrait(traitData) then
            traits:add(traitData)
            used = true
        elseif SandboxVars.GydeTraitMags.ReadRemove then
            traits:remove(traitData)
            used = true
        end
    end

    -- Delete the magazine after reading if enabled in sandbox settings.
    if used and SandboxVars.GydeTraitMags.ReadDelete then
        local inv = player:getInventory()
        local item = inv:FindAndReturn(magType)

        if item then
            local container = item:getContainer()
            if container then
                container:Remove(item)
                sendRemoveItemFromContainer(container, item)
            end
        end
    end
end
