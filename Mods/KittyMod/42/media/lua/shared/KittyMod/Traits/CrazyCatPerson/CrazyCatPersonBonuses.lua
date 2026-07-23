local CrazyCatPersonBonuses = {}

CrazyCatPersonBonuses.PROFESSION_ID = "crazycatperson"

CrazyCatPersonBonuses.BONUSES = {
    TAMED_ANIMAL_LIMIT_BONUS = 12,          
    COMMAND_SUCCESS_MULTIPLIER = 1.5,       
    FRIENDLINESS_GAIN_MULTIPLIER = 2.5,     
    INVENTORY_STORAGE_MULTIPLIER = 1.3,     
    PETTING_BOOST_MULTIPLIER = 2.0          
}

function CrazyCatPersonBonuses.HasProfession(player)
    if not player then return false end
    
    local success, result = pcall(function()
        local descriptor = player:getDescriptor()
        if descriptor then
            local profession = descriptor:getProfession()
            return profession == CrazyCatPersonBonuses.PROFESSION_ID
        end
        return false
    end)
    
    return success and result
end

function CrazyCatPersonBonuses.GetBonus(player, bonusType)
    if not CrazyCatPersonBonuses.HasProfession(player) then
        return 1.0  
    end
    
    return CrazyCatPersonBonuses.BONUSES[bonusType] or 1.0
end

function CrazyCatPersonBonuses.GetTamedAnimalLimitBonus(player)
    if not CrazyCatPersonBonuses.HasProfession(player) then
        return 0
    end
    
    return CrazyCatPersonBonuses.BONUSES.TAMED_ANIMAL_LIMIT_BONUS
end

return CrazyCatPersonBonuses