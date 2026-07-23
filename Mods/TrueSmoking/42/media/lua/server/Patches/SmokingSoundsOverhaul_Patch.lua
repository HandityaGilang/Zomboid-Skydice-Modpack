if getActivatedMods():contains('\\SmokingSoundsOverhaul') then
    SSO_last_puff_sound = -1;

    --Support for True Smoking
    function SmokingSoundsOverhaul:getPuffSound(isFemale)
        local gender = isFemale and "f" or "m"

        local sound_rand = ZombRand(1, 1) -- roll 1-1

        while SSO_last_puff_sound ~= sound_rand do
            SSO_last_puff_sound = sound_rand
        end

        -- print("Smoking_puff" .. sound_rand .. gender)

        return "Smoking_puff" .. sound_rand .. gender
    end

    function SmokingSoundsOverhaul:getLightingSound(player)
        local playerInv = player:getInventory()
        local lighter = playerInv:getFirstTag("Lighter") or playerInv:getFirstType("Base.Lighter");
        local matches = playerInv:getFirstTag("Matches") or playerInv:getFirstType("Base.Matches");
        local matchbox = playerInv:getFirstTag("MatchBox") or playerInv:getFirstType("Base.Matchbox");

        --Smoker support
        local SM_foil_lighter = playerInv:getFirstType("SM.SMFoil_Lighter")
        local SM_Matchbox = playerInv:getFirstType("SM.Matches")

        local sound_rand = 0;
        local current_sound = "";

        --Randomly select one of the 3 sounds
        if lighter or SM_foil_lighter then
            -- print('found lighter')
            while sound_rand == SSO_last_lighter_sound or sound_rand == 0 do
                -- print('got sound')
                sound_rand = ZombRand(1, 4)
            end

            SSO_last_lighter_sound = sound_rand

            current_sound = "Smoking_lighter" .. sound_rand
        elseif matches or matchbox or SM_Matchbox then
            while sound_rand == SSO_last_match_sound or sound_rand == 0 do
                sound_rand = ZombRand(1, 4)
            end

            SSO_last_match_sound = sound_rand

            current_sound = "Smoking_matches" .. sound_rand
        end

        local gender = "m";

        --Determine f or m
        if player:isFemale() then
            gender = "f";
        end

        -- print('lighting sound selected: ' .. current_sound .. gender)

        return current_sound .. gender
    end
end
