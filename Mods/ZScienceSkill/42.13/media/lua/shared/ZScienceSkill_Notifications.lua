ZScienceSkill = ZScienceSkill or {}
ZScienceSkill.Notifications = ZScienceSkill.Notifications or {}

local MOD_ID = "ZScienceSkill"
local logger = zdk.Logger.new(MOD_ID)

-- 'metal' / 'metals'
local function getResearchNoun(traitName, remaining)
    local numberKey = (remaining == 1) and "singular" or "plural"
    local traitKey = tostring(traitName or ""):lower()
    local perTraitKey = "IGUI_TraitResearch_" .. traitKey .. "_" .. numberKey
    local perTrait = getTextOrNull and getTextOrNull(perTraitKey) or nil
    if perTrait then return perTrait end

    local fallbackKey = "IGUI_TraitResearch_" .. numberKey
    return getText(fallbackKey)
end

local function show_traitUnlocked(player, trait)
    player:playSound("GainExperienceLevel")
    local traitDef   = CharacterTraitDefinition.getCharacterTraitDefinition(trait)
    local traitLabel = traitDef:getLabel() -- "Herbalist"
    local text = getText("IGUI_TraitUnlockedByResearch", traitLabel)
    logger:info(text)
    HaloTextHelper.addTextWithArrow(player, text, true, HaloTextHelper.getColorGreen())
end

local function show_traitProgress(player, trait, count, required)
    local remaining = math.max(0, required - count)
    local traitName = trait:getName() -- "herbalist"
    local noun = getResearchNoun(traitName, remaining)
    local transKey = "IGUI_TraitResearchRemaining" .. ((remaining == 1) and "1" or "")
    local text = getText(transKey, remaining, noun)
    logger:info(text)
    player:Say(text)
end

-------------------------

if isServer() then
    -- MP server only
    ZScienceSkill.Notifications.traitUnlocked = function(player, trait)
        local traitKey = tostring(trait) -- "base:herbalist"

        sendServerCommand(self.character, MOD_ID, "traitUnlocked", {
            traitKey = traitKey, -- "base:herbalist"
        })
    end

    ZScienceSkill.Notifications.traitProgress = function(player, trait, count, required)
        sendServerCommand(self.character, MOD_ID, "traitProgress", {
            traitName = trait:getName(), -- "herbalist"
            count     = count,
            required  = required,
            remaining = math.max(0, required - count)
        })
    end
else
    -- common for SP and MP client
    ZScienceSkill.Notifications.traitUnlocked = show_traitUnlocked
    ZScienceSkill.Notifications.traitProgress = show_traitProgress

    if isClient() then
        -- MP client only
        Events.OnServerCommand.Add(function(module, command, args)
            if module ~= MOD_ID then return end

            local player = getPlayer()
            if not player then return end

            if command == "traitUnlocked" then
                show_traitUnlocked(player, args.traitKey)

            elseif command == "traitProgress" then
                show_traitProgress(player, args.traitName, args.count, args.required)
            end
        end)
    end
end


