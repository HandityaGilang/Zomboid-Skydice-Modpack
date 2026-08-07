require "PlayableMinigames/PMG_Core"
require "PlayableMinigames/PMG_Core"
require "PlayablePool/PP_Core"
require "PlayablePool/PP_SkillCategory"

PMG_Skills = PMG_Skills or {}
PMG_Skills.definitions = PMG_Skills.definitions or {}
PMG_Skills.definitionOrder = PMG_Skills.definitionOrder or {}
PMG_Skills.perks = PMG_Skills.perks or {}
PMG_Skills.CATEGORY_ID = PP_SkillCategory.ID
PMG_Skills.CATEGORY_LABEL = PP_SkillCategory.LABEL

local function clamp(value, low, high)
    return PMG.clamp(value, low, high)
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

function PMG_Skills.ensureCategory()
    PMG_Skills.categoryPerk = PP_SkillCategory.ensure()
    return PMG_Skills.categoryPerk
end

local function installSkillBook(def, perk)
    if not def or not def.id then
        return
    end
    if not SkillBook then
        SkillBook = {}
    end
    if perk and Perks then
        Perks[def.id] = perk
    end
    SkillBook[def.id] = SkillBook[def.id] or {}
    SkillBook[def.id].perk = perk or SkillBook[def.id].perk
    SkillBook[def.id].maxMultiplier1 = 3
    SkillBook[def.id].maxMultiplier2 = 5
    SkillBook[def.id].maxMultiplier3 = 8
    SkillBook[def.id].maxMultiplier4 = 12
    SkillBook[def.id].maxMultiplier5 = 16
end

function PMG_Skills.define(def)
    if not def or not def.id then
        error("Minigame skill definition requires an id.")
    end
    local listed = false
    for _, existingId in ipairs(PMG_Skills.definitionOrder) do
        if existingId == def.id then
            listed = true
            break
        end
    end
    if not listed then
        table.insert(PMG_Skills.definitionOrder, def.id)
    end
    PMG_Skills.definitions[def.id] = def
    return def
end

function PMG_Skills.shouldRegisterSkill(def)
    if not def then
        return false
    end
    if def.requiresBetaMinigames and PMG.betaMinigamesEnabled and not PMG.betaMinigamesEnabled() then
        return false
    end
    return true
end

function PMG_Skills.registerSkill(id)
    local def = PMG_Skills.definitions[id]
    if not def then
        return nil
    end
    if not PMG_Skills.shouldRegisterSkill(def) then
        return nil
    end
    if PMG_Skills.perks[id] then
        installSkillBook(def, PMG_Skills.perks[id])
        return PMG_Skills.perks[id]
    end
    local existing = PP_SkillCategory.find(id)
    if existing then
        PMG_Skills.perks[id] = existing
        installSkillBook(def, existing)
        return existing
    end
    if not PerkFactory then
        installSkillBook(def, nil)
        return nil
    end
    local parent = PMG_Skills.ensureCategory()
    if not parent and Perks then
        parent = Perks[def.parent or PMG_Skills.CATEGORY_ID] or PP_SkillCategory.rootParent()
    end
    local perk = PP_SkillCategory.tryNewPerk(id, parent)
    if not perk then
        print("[PlayableMinigames] Could not create " .. tostring(id) .. " perk.")
        installSkillBook(def, nil)
        return nil
    end
    if perk.setCustom then
        pcall(function()
            perk:setCustom()
        end)
    end
    local ok, registered = pcall(function()
        return PerkFactory.AddPerk(perk, def.label or id, parent, 50, 100, 200, 400, 800, 1500, 3000, 4500, 5000, 6000)
    end)
    if not ok or not registered then
        print("[PlayableMinigames] Could not register " .. tostring(id) .. " perk.")
        installSkillBook(def, nil)
        return nil
    end
    PMG_Skills.perks[id] = registered
    installSkillBook(def, registered)
    return registered
end

function PMG_Skills.ensureAll()
    for _, id in ipairs(PMG_Skills.definitionOrder) do
        local def = PMG_Skills.definitions[id]
        if PMG_Skills.shouldRegisterSkill(def) then
            PMG_Skills.ensureCategory()
            PMG_Skills.registerSkill(id)
        end
    end
    if PerkFactory and PerkFactory.initTranslations then
        pcall(function()
            PerkFactory.initTranslations()
        end)
    end
end

function PMG_Skills.getPerk(id)
    return PMG_Skills.perks[id] or PMG_Skills.registerSkill(id)
end

function PMG_Skills.getPlayerLevel(playerObj, id)
    local perk = PMG_Skills.getPerk(id)
    if not playerObj or not perk then
        return 0
    end
    local ok, level = pcall(function()
        return playerObj:getPerkLevel(perk)
    end)
    if ok and level then
        return clamp(tonumber(level) or 0, 0, 10)
    end
    return 0
end

function PMG_Skills.profile(id, level)
    level = clamp(tonumber(level) or 0, 0, 10)
    local t = level / 10
    local def = PMG_Skills.definitions[id] or {}
    return {
        level = level,
        t = t,
        stressScale = lerp(1.0, tonumber(def.stressMasteryScale) or 1.35, t),
        unhappinessScale = lerp(1.0, tonumber(def.unhappinessMasteryScale) or 1.35, t),
    }
end

function PMG_Skills.addXp(playerObj, id, amount)
    amount = math.floor(tonumber(amount) or 0)
    local perk = PMG_Skills.getPerk(id)
    if not playerObj or not perk or amount <= 0 then
        return false
    end
    return PMG.addXp(playerObj, perk, amount)
end

local function scaledMoodRelief(playerObj, id, configName, reward)
    if not PP or not PP.getConfigNumber then
        return 0
    end
    local configuredAmount = PP.getConfigNumber(configName)
    if not configuredAmount or configuredAmount <= 0 then
        return 0
    end
    local profile = PMG_Skills.profile(id, PMG_Skills.getPlayerLevel(playerObj, id))
    local rewardScale = reward and tonumber(reward.moodScale) or 1
    local profileScale = 1
    if configName == "StressReliefPerTurn" then
        profileScale = profile.stressScale or 1
    elseif configName == "UnhappinessReliefPerTurn" then
        profileScale = profile.unhappinessScale or 1
    end
    local scaledAmount = configuredAmount * (PP.MOOD_RELIEF_SCALE or 1) * profileScale * (rewardScale or 1)
    return math.max(1, math.floor(scaledAmount + 0.5))
end

function PMG_Skills.applyMoodRelief(playerObj, id, reward)
    if not PP or not PP.applyCharacterStat then
        return false
    end
    local changed = false
    changed = PP.applyCharacterStat(playerObj, "STRESS", scaledMoodRelief(playerObj, id, "StressReliefPerTurn", reward)) or changed
    changed = PP.applyCharacterStat(playerObj, "UNHAPPINESS", scaledMoodRelief(playerObj, id, "UnhappinessReliefPerTurn", reward)) or changed
    return changed
end

function PMG_Skills.rewardPlayer(playerObj, id, amount, reward)
    local awarded = PMG_Skills.addXp(playerObj, id, amount)
    local relieved = PMG_Skills.applyMoodRelief(playerObj, id, reward)
    if awarded then
        print("[PlayableMinigames] Awarded " .. tostring(math.floor(tonumber(amount) or 0)) .. " " .. tostring(id) .. " XP.")
    end
    if relieved then
        print("[PlayableMinigames] Playing minigames helped " .. tostring(id) .. " mood.")
    end
    return awarded or relieved
end

PMG_Skills.define({ id = "Darts", label = "Darts", parent = PMG_Skills.CATEGORY_ID, requiresBetaMinigames = true })
PMG_Skills.define({ id = "Cards", label = "Cards", parent = PMG_Skills.CATEGORY_ID, requiresBetaMinigames = true })
PMG_Skills.define({ id = "Chess", label = "Chess", parent = PMG_Skills.CATEGORY_ID, requiresBetaMinigames = true, stressMasteryScale = 1.40, unhappinessMasteryScale = 1.40 })
PMG_Skills.define({ id = "Checkers", label = "Checkers", parent = PMG_Skills.CATEGORY_ID, requiresBetaMinigames = true, stressMasteryScale = 1.35, unhappinessMasteryScale = 1.35 })

if Events then
    local function ensureSkills()
        PMG_Skills.ensureAll()
    end
    if Events.OnGameBoot then
        Events.OnGameBoot.Add(ensureSkills)
    end
    if Events.OnGameStart then
        Events.OnGameStart.Add(ensureSkills)
    end
    if Events.OnCreatePlayer then
        Events.OnCreatePlayer.Add(ensureSkills)
    end
end

PMG_Skills.ensureAll()
