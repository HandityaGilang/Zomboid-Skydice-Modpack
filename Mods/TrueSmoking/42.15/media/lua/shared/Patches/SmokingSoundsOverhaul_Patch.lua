--[[
    SmokingSoundsOverhaul_Patch.lua - SSO Integration for TrueSmoking

    Provides external functions for SSO to integrate with TrueSmoking's
    smoking actions (lighting and puffing sounds).

    Deferred initialization via OnGameStart to ensure getActivatedMods() is ready.
]]

require 'Core'

-- Initialize SSO integration (called on game start)
local function initSSO()
    if not getActivatedMods():contains('\\SmokingSoundsOverhaul') then
        return
    end

    SmokingSoundsOverhaul = SmokingSoundsOverhaul or {}

    -- Track last played sounds to avoid repetition
    SSO_last_puff_sound = -1
    SSO_last_lighter_sound = -1
    SSO_last_match_sound = -1

    --- Get a puff sound name based on gender
    -- @param isFemale boolean Whether the player is female
    -- @return string Sound name like "Smoking_puff1f" or "Smoking_puff1m"
    function SmokingSoundsOverhaul:getPuffSound(isFemale)
        local gender = isFemale and "f" or "m"
        local sound_rand = ZombRand(1, 4)

        -- Avoid repeating the same sound
        local attempts = 0
        while sound_rand == SSO_last_puff_sound and attempts < 10 do
            sound_rand = ZombRand(1, 4)
            attempts = attempts + 1
        end

        SSO_last_puff_sound = sound_rand
        return "smoking_puff1"
    end

    --- Get a lighting sound name based on lighter type and gender
    -- @param player IsoPlayer The player lighting the smoke
    -- @param ignitionItem InventoryItem Optional - the lighter/matches item already found
    -- @return string Sound name like "Smoking_lighter1m" or "Smoking_matches2f"
    function SmokingSoundsOverhaul:getLightingSound(player, ignitionItem)
        if not player then return "" end

        local isLighter = false
        local isMatch = false

        -- If ignition item was passed, determine its type
        if ignitionItem then
            local fullType = ignitionItem:getFullType() or ""
            local fullTypeLower = fullType:lower()

            -- Check by type name (most reliable)
            if string.find(fullTypeLower, "lighter") then
                isLighter = true
            elseif string.find(fullTypeLower, "match") then
                isMatch = true
            end

            -- Check by tags if type name didn't match
            if not isLighter and not isMatch then
                local itemTags = ignitionItem:getTags()
                if itemTags then
                    if itemTags:contains("Lighter") or itemTags:contains("FireSource") then
                        isLighter = true
                    elseif itemTags:contains("Matches") or itemTags:contains("MatchBox") then
                        isMatch = true
                    end
                end
            end
        end

        -- Fallback: search player inventory if no item passed or detection failed
        if not isLighter and not isMatch then
            local playerInv = player:getInventory()

            -- Check for lighters
            local lighter = playerInv:getFirstTypeRecurse("Base.Lighter")
                or playerInv:getFirstTypeRecurse("Base.DisposableLighter")
                or playerInv:getFirstTypeRecurse("Base.LighterBBQ")
                or playerInv:getFirstTagRecurse("Lighter")

            -- Check for matches
            local matches = playerInv:getFirstTypeRecurse("Base.Matches")
                or playerInv:getFirstTypeRecurse("Base.Matchbox")
                or playerInv:getFirstTagRecurse("Matches")
                or playerInv:getFirstTagRecurse("MatchBox")

            isLighter = lighter ~= nil
            isMatch = matches ~= nil
        end

        local sound_rand = 0
        local current_sound = ""

        -- Select sound based on ignition source
        if isLighter then
            sound_rand = ZombRand(1, 4)
            local attempts = 0
            while sound_rand == SSO_last_lighter_sound and attempts < 10 do
                sound_rand = ZombRand(1, 4)
                attempts = attempts + 1
            end
            SSO_last_lighter_sound = sound_rand
            current_sound = "Smoking_lighter" .. sound_rand

        elseif isMatch then
            sound_rand = ZombRand(1, 4)
            local attempts = 0
            while sound_rand == SSO_last_match_sound and attempts < 10 do
                sound_rand = ZombRand(1, 4)
                attempts = attempts + 1
            end
            SSO_last_match_sound = sound_rand
            current_sound = "Smoking_matches" .. sound_rand
        end

        -- No ignition source found
        if current_sound == "" then
            return ""
        end

        -- Add gender suffix
        local gender = player:isFemale() and "f" or "m"
        return current_sound .. gender
    end
end

-- Initialize on game start when getActivatedMods() is reliable
Events.OnGameStart.Add(initSSO)
