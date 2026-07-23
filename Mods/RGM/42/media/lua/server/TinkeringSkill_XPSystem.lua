
RGMManager = RGMManager or {}
if RGMManager.XPSystemLoaded then return end
RGMManager.XPSystemLoaded = true

-- Register at file load time, same as vanilla XPSystem_SkillBook.lua.
-- Events.OnGameStart does not fire on the server in B42.
if SkillBook then
    SkillBook["Tinkering"] = {
        perk           = Perks.Tinkering,
        maxMultiplier1 = 3,
        maxMultiplier2 = 5,
        maxMultiplier3 = 8,
        maxMultiplier4 = 12,
        maxMultiplier5 = 16,
    }
    print("[RGM] SkillBook[Tinkering] registered on server")
end

local rarityXp = {
    [RarityColors.shitty]    = 1,
    [RarityColors.bad]       = 3,
    [RarityColors.common]    = 8,
    [RarityColors.good]      = 15,
    [RarityColors.great]     = 30,
    [RarityColors.epic]      = 60,
    [RarityColors.insane]    = 100,
    [RarityColors.legendary] = 150,
}
-- RarityColors.rare is optional (not defined by default)
if RarityColors.rare then rarityXp[RarityColors.rare] = 100 end

function RGMManager.awardTinkeringXP(_player, _modifier, multiplier)
    local xp = rarityXp[_modifier.fontColor] or 10
    xp = xp * multiplier * SandboxVars.RGM.TinkeringSkillXpMultiplier

    local wb = _player and instanceof(_player, "IsoPlayer") and RGMManager.getWornXpBonuses(_player) or nil

    local tinkBonus = 1 + (wb and wb["xp Tinkering"]   or 0)
    local maintBonus = 1 + (wb and wb["xp Maintenance"] or 0)

    addXp(_player, Perks.Tinkering, xp * tinkBonus)

    if _modifier.statsMultipliers["durability"] and _modifier.statsMultipliers["durability"] > 1 then
        addXp(_player, Perks.Maintenance, 10 * multiplier * maintBonus)
    end

    if RGMManager.testMode then
        local name = _player and _player.getUsername and _player:getUsername() or tostring(_player)
        print(string.format("[RGM] TinkeringXP: %s modifier=[%s] rarity_xp=%d multiplier=x%.2f sandbox=x%.2f total=+%.1f (tinkBonus=x%.2f maintBonus=x%.2f)",
            name,
            tostring(_modifier.modifierName),
            rarityXp[_modifier.fontColor] or 10,
            multiplier,
            SandboxVars.RGM.TinkeringSkillXpMultiplier,
            xp,
            tinkBonus,
            maintBonus))
    end

    return xp
end



