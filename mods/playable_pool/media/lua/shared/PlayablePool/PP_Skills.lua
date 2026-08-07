PP = PP or {}
require "PlayablePool/PP_SkillCategory"

PP.BILLIARDS_PERK_ID = "Billiards"
PP.BILLIARDS_PERK_LABEL = "Billiards"

local function clamp(value, low, high)
    if value < low then
        return low
    end
    if value > high then
        return high
    end
    return value
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function logSkill(message)
    print("[PlayablePool] " .. tostring(message))
end

local function installBilliardsSkillBook(perk)
    if not SkillBook then
        SkillBook = {}
    end
    if perk and Perks then
        Perks.Billiards = perk
    end

    SkillBook[PP.BILLIARDS_PERK_ID] = SkillBook[PP.BILLIARDS_PERK_ID] or {}
    SkillBook[PP.BILLIARDS_PERK_ID].perk = perk or SkillBook[PP.BILLIARDS_PERK_ID].perk
    SkillBook[PP.BILLIARDS_PERK_ID].maxMultiplier1 = 3
    SkillBook[PP.BILLIARDS_PERK_ID].maxMultiplier2 = 5
    SkillBook[PP.BILLIARDS_PERK_ID].maxMultiplier3 = 8
    SkillBook[PP.BILLIARDS_PERK_ID].maxMultiplier4 = 12
    SkillBook[PP.BILLIARDS_PERK_ID].maxMultiplier5 = 16
end

function PP.registerBilliardsSkill()
    if PP.BILLIARDS_PERK then
        installBilliardsSkillBook(PP.BILLIARDS_PERK)
        return PP.BILLIARDS_PERK
    end
    if not PerkFactory then
        installBilliardsSkillBook(nil)
        return nil
    end

    local existing = nil
    if Perks and Perks.Billiards then
        existing = Perks.Billiards
    end
    if PerkFactory.getPerkFromName then
        pcall(function()
            existing = existing or PerkFactory.getPerkFromName(PP.BILLIARDS_PERK_ID)
        end)
    end
    if existing then
        PP.BILLIARDS_PERK = existing
    else
        local parent = PP_SkillCategory.ensure() or PP_SkillCategory.rootParent()
        local perk = PP_SkillCategory.tryNewPerk(PP.BILLIARDS_PERK_ID, parent)
        if not perk then
            installBilliardsSkillBook(nil)
            logSkill("Could not create Billiards perk.")
            return nil
        end
        if perk.setCustom then
            pcall(function()
                perk:setCustom()
            end)
        end
        local ok, registered = pcall(function()
            return PerkFactory.AddPerk(perk, PP.BILLIARDS_PERK_LABEL, parent, 50, 100, 200, 400, 800, 1500, 3000, 4500, 5000, 6000)
        end)
        if not ok or not registered then
            installBilliardsSkillBook(nil)
            logSkill("Could not register Billiards perk.")
            return nil
        end
        PP.BILLIARDS_PERK = registered
    end

    installBilliardsSkillBook(PP.BILLIARDS_PERK)

    if PerkFactory.initTranslations then
        pcall(function()
            PerkFactory.initTranslations()
        end)
    end
    return PP.BILLIARDS_PERK
end

function PP.getBilliardsPerk()
    return PP.BILLIARDS_PERK or PP.registerBilliardsSkill()
end

function PP.getPlayerBilliardsLevel(playerObj)
    local perk = PP.getBilliardsPerk()
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

function PP.getBilliardsSkillProfile(level)
    level = clamp(tonumber(level) or 0, 0, 10)
    local t = level / 10
    return {
        level = level,
        t = t,
        previewLength = lerp(180, 420, t),
        previewAlpha = lerp(0.35, 0.90, t),
        previewVectorScale = lerp(0.78, 1.12, t),
        keyboardAngleRate = math.rad(lerp(2.4, 1.55, t)),
        keyboardFineAngleRate = math.rad(0.75),
        keyboardPowerRate = lerp(220, 150, t),
        keyboardFinePowerRate = lerp(70, 48, t),
        moodScale = lerp(1.0, 1.25, t),
        spinStrength = lerp(0.0, 1.0, math.max(0, (level - 1) / 9)),
    }
end

function PP.clampCueSpin(spinX, spinY, level)
    local profile = PP.getBilliardsSkillProfile(level)
    local maxFollowDraw = profile.spinStrength or 0
    local maxEnglish = level >= 4 and profile.spinStrength or 0
    return clamp(tonumber(spinX) or 0, -maxEnglish, maxEnglish), clamp(tonumber(spinY) or 0, -maxFollowDraw, maxFollowDraw)
end

function PP.applyBilliardsShotSkill(angle, power, level)
    local profile = PP.getBilliardsSkillProfile(level)
    angle = tonumber(angle) or 0
    power = tonumber(power) or 0
    return angle, math.max(0, power), profile
end

function PP.calculateBilliardsShotXp(playerName, result, nextState, multiplier)
    if not result then
        return 0
    end

    local xp = 2
    if result.legal and not result.scratch then
        xp = xp + 3
    end
    if result.required and result.firstHit == result.required then
        xp = xp + 4
    end
    if result.sunk then
        xp = xp + (#result.sunk * 8)
    end
    if nextState and playerName and nextState.winner == playerName then
        xp = xp + 50
    end

    multiplier = tonumber(multiplier) or 1
    return math.max(0, math.floor(xp * multiplier + 0.5))
end

function PP.ensureBilliardsSkill()
    PP.registerBilliardsSkill()
    installBilliardsSkillBook(PP.BILLIARDS_PERK)
    return PP.BILLIARDS_PERK
end

local function ensureBilliardsSkill()
    PP.ensureBilliardsSkill()
end

if Events then
    if Events.OnGameBoot then
        Events.OnGameBoot.Add(ensureBilliardsSkill)
    end
    if Events.OnGameStart then
        Events.OnGameStart.Add(ensureBilliardsSkill)
    end
    if Events.OnCreatePlayer then
        Events.OnCreatePlayer.Add(ensureBilliardsSkill)
    end
    if Events.OnPreFillInventoryObjectContextMenu then
        Events.OnPreFillInventoryObjectContextMenu.Add(ensureBilliardsSkill)
    end
end

PP.ensureBilliardsSkill()
