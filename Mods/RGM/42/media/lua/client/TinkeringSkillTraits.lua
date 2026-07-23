
-- B42: traits are defined in media/scripts/characters/RGM_character_traits.txt
-- and registered in media/registries.lua via CharacterTrait.register()
-- This file handles runtime bonuses for professions and dynamic trait unlock.

RGM = RGM or {}
if RGM.TinkeringTraitsLoaded then return end
RGM.TinkeringTraitsLoaded = true

local function initProfessionBoosts()
    if not ProfessionFactory then return end
    pcall(function()
        local repairman = ProfessionFactory.getProfession("repairman")
        if repairman then repairman:addXPBoost(Perks.Tinkering, 1) end
        local engineer = ProfessionFactory.getProfession("engineer")
        if engineer then engineer:addXPBoost(Perks.Tinkering, 1) end
    end)
end

Events.OnGameBoot.Add(initProfessionBoosts)
Events.preAddSkillDefs.Add(initProfessionBoosts)


local function hasTinkererTrait(player)
    if RGM and RGM.CharacterTrait and RGM.CharacterTrait.TINKERER then
        local ok, result = pcall(function() return player:hasTrait(RGM.CharacterTrait.TINKERER) end)
        if ok then return result end
    end
    return false
end

local function checkTinkererOnSkillUp(player, perk, perkLevel, addBuffer)
    if not player then return end
    if not getGameTime or not getGameTime() then return end
    if hasTinkererTrait(player) or not SandboxVars.RGM.DynamicTinkerer then return end
    if not Perks.Tinkering or not Perks.Maintenance then return end
    if perk == Perks.Maintenance or perk == Perks.Tinkering then
        if player:getPerkLevel(Perks.Tinkering) + player:getPerkLevel(Perks.Maintenance) >= 8 then
            local itemsTinkered = player:getModData().itemsTinkered
            if itemsTinkered and itemsTinkered >= 15 then
                pcall(function() player:getTraits():add(RGM.CharacterTrait.TINKERER) end)
            end
        end
    end
end

Events.LevelPerk.Add(checkTinkererOnSkillUp)
