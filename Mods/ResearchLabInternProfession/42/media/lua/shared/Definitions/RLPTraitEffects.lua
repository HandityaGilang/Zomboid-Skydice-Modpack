----------------------------------------------
---- RLP TRAIT EFFECTS                    ----
----------------------------------------------

local RLPTraitEffects = {}

--- Modifica o tempo de autópsia para quem tem o trait Autopsy Specialist
function RLPTraitEffects.ModifyAutopsyDuration(character, originalTime)
    if character:hasTrait(RLP.CharacterTrait.AUTOPSY_SPECIALIST) then
        -- Reduz o tempo em 40% para Autopsy Specialist
        return math.floor(originalTime * 0.60)
    end
    
    return originalTime
end

--- Modifica o multiplicador de XP da autópsia
function RLPTraitEffects.ModifyAutopsyXPMultiplier(character, baseMultiplier)
    if character:hasTrait(RLP.CharacterTrait.AUTOPSY_SPECIALIST) then
        return 1.20 -- 20%
    end
    
    return baseMultiplier
end

--- Modifica a quantidade de amostras obtidas na autópsia em mesa
function RLPTraitEffects.ModifyAutopsySampleCount(character, baseSampleCount)
    if character:hasTrait(RLP.CharacterTrait.AUTOPSY_SPECIALIST) then
        return 6
    end
    
    return baseSampleCount
end

--- Modifica a chance de obter sangue infectado (bom) vs sangue contaminado (ruim)
function RLPTraitEffects.ModifyAutopsyInfectedBloodChance(character, baseChance)
    if character:hasTrait(RLP.CharacterTrait.AUTOPSY_SPECIALIST) then
        return baseChance + 15
    end
    
    return baseChance
end

--- Modifica a redução de chance de contaminação ao fazer autópsia no chão
function RLPTraitEffects.ModifyGroundAutopsyNothingReduction(character, baseReduction)
    if character:hasTrait(RLP.CharacterTrait.AUTOPSY_SPECIALIST) then
        return baseReduction + 4
    end
    
    return baseReduction
end

-- Registra a função globalmente para o mod principal usar
_G.RLPTraitEffects = RLPTraitEffects