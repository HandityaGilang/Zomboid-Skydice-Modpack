PP_SkillCategory = PP_SkillCategory or {}

PP_SkillCategory.ID = "Minigames"
PP_SkillCategory.LABEL = "Minigames"

function PP_SkillCategory.tryNewPerk(id, parent)
    if not PerkFactory or not PerkFactory.Perk then
        return nil
    end

    local ok, perk = pcall(function()
        if parent then
            return PerkFactory.Perk.new(id, parent)
        end
        return PerkFactory.Perk.new(id)
    end)
    if ok and perk then
        return perk
    end

    ok, perk = pcall(function()
        if parent then
            return PerkFactory.Perk(id, parent)
        end
        return PerkFactory.Perk(id)
    end)
    if ok then
        return perk
    end
    return nil
end

function PP_SkillCategory.find(id)
    local existing = Perks and Perks[id] or nil
    if not existing and PerkFactory and PerkFactory.getPerkFromName then
        pcall(function()
            existing = PerkFactory.getPerkFromName(id)
        end)
    end
    return existing
end

function PP_SkillCategory.rootParent()
    return Perks and Perks.None or nil
end

function PP_SkillCategory.ensure()
    if PP_SkillCategory.perk then
        return PP_SkillCategory.perk
    end

    local id = PP_SkillCategory.ID
    local existing = PP_SkillCategory.find(id)
    if existing then
        PP_SkillCategory.perk = existing
        if Perks then
            Perks[id] = existing
        end
        return existing
    end
    if not PerkFactory then
        return nil
    end

    local rootParent = PP_SkillCategory.rootParent()
    local perk = PP_SkillCategory.tryNewPerk(id, rootParent) or PP_SkillCategory.tryNewPerk(id, nil)
    if not perk then
        print("[PlayablePool] Could not create Minigames perk category.")
        return nil
    end
    if perk.setCustom then
        pcall(function()
            perk:setCustom()
        end)
    end

    local ok, registered = pcall(function()
        return PerkFactory.AddPerk(perk, PP_SkillCategory.LABEL, rootParent, 50, 100, 200, 400, 800, 1500, 3000, 4500, 5000, 6000)
    end)
    if not ok or not registered then
        print("[PlayablePool] Could not register Minigames perk category.")
        return nil
    end

    PP_SkillCategory.perk = registered
    if Perks then
        Perks[id] = registered
    end
    return registered
end
