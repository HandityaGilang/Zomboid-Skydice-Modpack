LSK_NetSchema = LSK_NetSchema or {}

LSK_NetSchema.VERSION = "KardinalTest-secure-core-1"
LSK_NetSchema.MAX_PAYLOAD_DEPTH = 6
LSK_NetSchema.MAX_PAYLOAD_ENTRIES = 160
LSK_NetSchema.MAX_STRING_LENGTH = 512

LSK_NetSchema.GROUPS = {
    ADMIN = "admin",
    ACTION = "action",
    INVENTORY = "inventory",
    SELF = "self",
    SOCIAL = "social",
    SYNC = "sync",
    WORLD = "world",
}

local policies = {}
LSK_NetSchema.POLICIES = policies

local function finiteNumber(value)
    return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

function LSK_NetSchema.isFiniteNumber(value)
    return finiteNumber(value)
end

function LSK_NetSchema.number(value, minimum, maximum, integer)
    if not finiteNumber(value) then
        return false
    end
    if minimum ~= nil and value < minimum then
        return false
    end
    if maximum ~= nil and value > maximum then
        return false
    end
    if integer and value ~= math.floor(value) then
        return false
    end
    return true
end

function LSK_NetSchema.string(value, minimumLength, maximumLength, pattern)
    if type(value) ~= "string" then
        return false
    end
    local length = string.len(value)
    if minimumLength and length < minimumLength then
        return false
    end
    if maximumLength and length > maximumLength then
        return false
    end
    if pattern and not string.match(value, pattern) then
        return false
    end
    return true
end

function LSK_NetSchema.table(value)
    return type(value) == "table"
end

function LSK_NetSchema.identifier(value, maximumLength)
    return LSK_NetSchema.string(value, 1, maximumLength or 96, "^[%w_%.:%-]+$")
end

function LSK_NetSchema.itemType(value)
    return LSK_NetSchema.string(value, 3, 96, "^[%w_]+%.[%w_]+$")
end

function LSK_NetSchema.boolean(value)
    return type(value) == "boolean"
end

function LSK_NetSchema.oneOf(value, allowed)
    return allowed[value] == true
end

local function validateValue(value, rule)
    if value == nil then
        return rule.optional == true
    end
    if rule.kind == "number" then
        return LSK_NetSchema.number(value, rule.min, rule.max, rule.integer)
    elseif rule.kind == "string" then
        return LSK_NetSchema.string(value, rule.minLength, rule.maxLength, rule.pattern)
    elseif rule.kind == "identifier" then
        return LSK_NetSchema.identifier(value, rule.maxLength)
    elseif rule.kind == "item" then
        return LSK_NetSchema.itemType(value)
    elseif rule.kind == "table" then
        return type(value) == "table"
    elseif rule.kind == "boolean" then
        return type(value) == "boolean"
    elseif rule.kind == "userdata" then
        return type(value) == "userdata"
    elseif rule.kind == "any" then
        return true
    end
    return false
end

function LSK_NetSchema.validatePolicy(policy, player, args)
    if type(args) ~= "table" then
        return false, "args_not_table"
    end
    local highestIndex = 0
    for key, _ in pairs(args) do
        if type(key) == "number" and key > highestIndex then
            highestIndex = key
        end
    end
    if highestIndex < policy.minArgs then
        return false, "missing_args"
    end
    if policy.args then
        for index, rule in pairs(policy.args) do
            if not validateValue(args[index], rule) then
                return false, "arg_" .. tostring(index)
            end
        end
    end
    if policy.validate then
        return policy.validate(player, args)
    end
    return true
end

local function policy(name, group, options)
    options = options or {}
    options.name = name
    options.group = group
    options.rate = options.rate or 4
    options.burst = options.burst or 8
    if options.minArgs == nil then
        options.minArgs = 1
    end
    policies[name] = options
end

local function basic(names, group, options)
    for _, name in ipairs(names) do
        policy(name, group, options)
    end
end

local G = LSK_NetSchema.GROUPS

policy("LSK_BeginAction", G.ACTION, {
    rate = 2,
    burst = 4,
    args = {
        [1] = { kind = "identifier", maxLength = 64 },
        [2] = { kind = "string", minLength = 12, maxLength = 128, pattern = "^[%w_%-]+$" },
        [3] = { kind = "number", min = 5000, max = 3600000, integer = true },
    },
})

policy("LSK_EndAction", G.ACTION, {
    rate = 4,
    burst = 8,
    args = {
        [1] = { kind = "identifier", maxLength = 64 },
        [2] = { kind = "string", minLength = 12, maxLength = 128, pattern = "^[%w_%-]+$" },
    },
})

basic({
    "dropHeavyItems", "RemoveMakeup",
}, G.SELF, { rate = 2, burst = 4 })

basic({
    "SetMirrorMakeup", "MakeWellFed", "learnRecipes", "Character_Explosion",
    "Character_MakeWet", "Character_CleanSelf", "reduceAllStiffness",
    "AddGeneralHealth", "addPainBodyPart", "ChangeCharacterMoodGroup",
    "ChangeCharacterMood", "AddXPBatch",
}, G.SELF, { rate = 3, burst = 6 })

basic({
    "SyncItemData_FromPlayer", "SyncItemData_FromObj", "SyncObjMovData",
    "CreateFluidCont_Obj", "UseFluid_Obj", "ModifyItemData", "AdjustFluidItem",
    "ChangeTexture_Item", "UseItem_Player", "CreateFluidCont_Item", "renameItem",
}, G.SYNC, { rate = 8, burst = 16 })

basic({
    "RemoveItems", "TransferItemWorld", "TransferItem", "TransferItemFrom",
    "TransferItemTo", "RemoveItemFromPlayer",
}, G.INVENTORY, { rate = 6, burst = 12 })

basic({
    "Social_sendInfo", "Social_requestInfo", "InteractionStart",
    "StopOrStartInteraction", "makeNauseous", "SendGetEmbarrassed",
    "IsPlayingMusic", "IsStartingDuet", "IsPlayingDJ", "AskIfIsDancing",
    "OtherPlayerIsDancing", "AskToDance", "AcceptedDance", "StopDance",
    "FaceDanceProposer",
}, G.SOCIAL, {
    rate = 5,
    burst = 10,
    target = { index = 1, maximum = 30 },
})

basic({
    "ChangeAnimVarMulti", "ChangeAnimVar",
}, G.SOCIAL, { rate = 10, burst = 20 })

basic({
    "RemoveBrokenGlass", "AddDirtPuddle", "RemoveDirtTile",
    "ChangeDiscoStyle", "TurnDiscoBallOff", "JukeboxStart",
    "TurnJukeboxOff", "JukeboxStyleChangePlayerPlaylist",
    "JukeboxStyleChange", "StopJukeSong", "isPlayingJuke", "JukeTurnedOn",
}, G.WORLD, { rate = 3, burst = 7 })

policy("AddXP", G.SELF, {
    rate = 2,
    burst = 5,
    requiresAction = true,
    args = {
        [1] = { kind = "identifier", maxLength = 48 },
        [2] = { kind = "number", min = 0, max = 100 },
    },
    validate = function(_, args)
        local allowedPerks = {
            Art = true,
            Cleaning = true,
            Dancing = true,
            Fitness = true,
            Maintenance = true,
            Meditation = true,
            Music = true,
            Nimble = true,
        }
        return allowedPerks[args[1]] == true and Perks
            and Perks[args[1]] ~= nil, "perk_not_allowed"
    end,
})

-- NeuralHat bonus/penalty outside Lifestyle timed actions (no action proof).
policy("LSK_NeuralHatXP", G.SELF, {
    rate = 0.25,
    burst = 2,
    requiresAction = false,
    validate = function(_, args)
        if type(args) ~= "table" or #args < 1 or #args > 12 then
            return false, "neural_hat_batch"
        end
        for index = 1, #args do
            local entry = args[index]
            if type(entry) ~= "table"
                or not LSK_NetSchema.identifier(entry[1], 48)
                or not Perks or not Perks[entry[1]]
                or not LSK_NetSchema.number(entry[2], -50, 50) then
                return false, "invalid_neural_hat_xp"
            end
        end
        return true
    end,
})

policy("AddXPBatch", G.SELF, {
    rate = 0.1,
    burst = 1,
    requiresAction = true,
    validate = function(_, args)
        if #args > 16 then
            return false, "xp_batch_too_large"
        end
        for index = 1, #args do
            local entry = args[index]
            if type(entry) ~= "table"
                or not LSK_NetSchema.identifier(entry[1], 48)
                or not Perks or not Perks[entry[1]]
                or not LSK_NetSchema.number(entry[2], -100, 100) then
                return false, "invalid_xp_batch"
            end
        end
        return true
    end,
})

-- Lifestyle traits the client may add/remove via ChangeTrait (dynamic + music taste).
local CHANGE_TRAIT_ALLOWED = {
    ARTISTIC = true,
    CLEANFREAK = true,
    COUCHPOTATO = true,
    DISCIPLINED = true,
    KILLJOY = true,
    OUTDOORSMAN = true,
    PARTYANIMAL = true,
    SLOPPY = true,
    TIDY = true,
    TONEDEAF = true,
    VIRTUOSO = true,
}

local MUSIC_TASTE_TRAITS = {
    "disco", "discono", "beach", "beachno", "classical", "classicalno",
    "country", "countryno", "holiday", "holidayno", "jazz", "jazzno",
    "metal", "metalno", "muzak", "muzakno", "pop", "popno", "rap", "rapno",
    "rbsoul", "rbsoulno", "reggae", "reggaeno", "rock", "rockno",
    "salsa", "salsano", "world", "worldno",
}
for i = 1, #MUSIC_TASTE_TRAITS do
    local name = MUSIC_TASTE_TRAITS[i]
    CHANGE_TRAIT_ALLOWED[name] = true
    CHANGE_TRAIT_ALLOWED[string.upper(name)] = true
end

function LSK_NetSchema.resolveChangeTrait(name)
    if type(name) ~= "string" or name == "" or not CharacterTrait then
        return nil, nil
    end
    if CHANGE_TRAIT_ALLOWED[name] ~= true
        and CHANGE_TRAIT_ALLOWED[string.upper(name)] ~= true
        and CHANGE_TRAIT_ALLOWED[string.lower(name)] ~= true then
        return nil, nil
    end
    if CharacterTrait[name] then
        return CharacterTrait[name], name
    end
    local upper = string.upper(name)
    if CharacterTrait[upper] then
        return CharacterTrait[upper], upper
    end
    local lower = string.lower(name)
    if CharacterTrait[lower] then
        return CharacterTrait[lower], lower
    end
    return nil, nil
end

policy("ChangeTrait", G.SELF, {
    rate = 0.5,
    burst = 4,
    args = {
        [1] = { kind = "identifier", maxLength = 48 },
        [2] = { kind = "string", minLength = 3, maxLength = 6 },
    },
    validate = function(_, args)
        local allowedMethods = { add = true, remove = true }
        if allowedMethods[args[2]] ~= true then
            return false, "trait_not_allowed"
        end
        local traitObj = LSK_NetSchema.resolveChangeTrait(args[1])
        return traitObj ~= nil, "trait_not_allowed"
    end,
})

policy("ChangeMaxWeight", G.ADMIN, { admin = true, rate = 1, burst = 2 })
policy("SavePlayerData", G.SELF, { rate = 0.2, burst = 2 })
policy("ChangePlayerState", G.SELF, { rate = 0.5, burst = 2 })
policy("dropHeavyItems", G.SELF, { rate = 1, burst = 2, minArgs = 0 })

policy("reduceAllStiffness", G.SELF, {
    rate = 0.5,
    burst = 2,
    requiresAction = true,
    args = { [1] = { kind = "number", min = 0, max = 10 } },
})
policy("AddGeneralHealth", G.SELF, {
    rate = 0.2,
    burst = 1,
    requiresAction = true,
    args = { [1] = { kind = "number", min = 0, max = 10 } },
})

basic({
    "Character_Explosion",
    "Character_MakeWet",
    "Character_CleanSelf",
}, G.SELF, {
    rate = 1,
    burst = 3,
    requiresAction = true,
})

policy("addPainBodyPart", G.SELF, {
    rate = 1,
    burst = 3,
    requiresAction = true,
    args = {
        [1] = { kind = "identifier", maxLength = 48 },
        [2] = { kind = "number", min = 0, max = 100 },
    },
})
policy("ChangeCharacterMood", G.SELF, {
    rate = 3,
    burst = 6,
    args = {
        [1] = { kind = "string", minLength = 3, maxLength = 6 },
        [2] = { kind = "identifier", maxLength = 48 },
        [3] = { kind = "number", min = 0, max = 100 },
    },
    validate = function(_, args)
        local methods = { add = true, remove = true, set = true }
        return methods[args[1]] == true and CharacterStat
            and CharacterStat[args[2]] ~= nil, "mood_not_allowed"
    end,
})
policy("ChangeCharacterMoodGroup", G.SELF, {
    rate = 2,
    burst = 4,
    validate = function(_, args)
        local list = args[1]
        if type(list) ~= "table" or #list > 12 then
            return false, "invalid_mood_group"
        end
        local methods = { add = true, remove = true, set = true }
        for index = 1, #list do
            local entry = list[index]
            if type(entry) ~= "table" or not methods[entry[1]]
                or not LSK_NetSchema.identifier(entry[2], 48)
                or not CharacterStat or not CharacterStat[entry[2]]
                or not LSK_NetSchema.number(entry[3], 0, 100) then
                return false, "invalid_mood_group"
            end
        end
        return true
    end,
})

local function validateItemAmount(_, args)
    if not LSK_NetSchema.itemType(args[1]) then
        return false, "item_type"
    end
    if not LSK_NetSchema.number(args[2], 1, 20, true) then
        return false, "item_amount"
    end
    return true
end

policy("AddItems_Player", G.INVENTORY, {
    admin = true,
    rate = 0.2,
    burst = 1,
    validate = validateItemAmount,
})
policy("AddItemToPlayer", G.INVENTORY, {
    rate = 0.5,
    burst = 2,
    validate = function(player, args)
        local valid, reason = validateItemAmount(player, args)
        if not valid then
            return false, reason
        end
        return args[1] == "Base.RippedSheetsDirty", "item_not_allowed"
    end,
})
policy("AddWorldItem", G.WORLD, {
    rate = 0.1,
    burst = 1,
    requiresAction = true,
    args = {
        [1] = { kind = "item" },
        [2] = { kind = "number", min = 1, max = 1, integer = true },
        [6] = { kind = "number" },
        [7] = { kind = "number" },
        [8] = { kind = "number", min = 0, max = 32, integer = true },
    },
    distance = { indices = { 6, 7, 8 }, maximum = 8 },
    validate = function(_, args)
        return args[1] == "Base.Log", "world_item_not_allowed"
    end,
})

policy("MakeWellFed", G.SELF, {
    rate = 0.05,
    burst = 1,
    requiresAction = true,
    minArgs = 0,
    validate = function(_, args)
        local value = args[1]
        return value == nil or value == "Lifestyle.DebugFoodTest"
            or value == "Lifestyle.DebugFoodMediumTest"
            or value == "Lifestyle.DebugFoodSmallTest", "food_not_allowed"
    end,
})

policy("CreateArtworkItem", G.INVENTORY, {
    rate = 0.1,
    burst = 1,
    requiresAction = true,
})
policy("ModifyItemStat", G.ADMIN, { admin = true, rate = 1, burst = 2 })

local objectDistance = { nestedIndex = 1, maximum = 12 }
policy("ModifyOverlaySprite", G.WORLD, {
    rate = 4,
    burst = 10,
    distance = objectDistance,
    args = {
        [1] = { kind = "table" },
        [2] = { kind = "string", optional = true, maxLength = 128 },
    },
})
policy("SyncItemData_FromObj", G.SYNC, {
    rate = 6,
    burst = 12,
    distance = { nestedIndex = 2, maximum = 12 },
})
policy("SyncObjMovData", G.SYNC, {
    rate = 6,
    burst = 12,
    distance = { nestedIndex = 1, maximum = 12 },
})
policy("CreateFluidCont_Obj", G.SYNC, {
    rate = 2,
    burst = 4,
    distance = { nestedIndex = 1, maximum = 10 },
})
policy("UseFluid_Obj", G.SYNC, {
    rate = 4,
    burst = 8,
    distance = { nestedIndex = 1, maximum = 10 },
})
policy("ModifyObjData", G.WORLD, {
    rate = 3,
    burst = 8,
    distance = objectDistance,
    args = { [1] = { kind = "table" } },
})
policy("ModifySprite", G.ADMIN, { admin = true, rate = 2, burst = 4 })
policy("RemoveObject", G.WORLD, {
    rate = 0.5,
    burst = 2,
    distance = { indices = { 1, 2, 3 }, maximum = 8 },
})
policy("SyncSqrData", G.ADMIN, { admin = true, rate = 2, burst = 4 })

policy("RemoveBrokenGlass", G.WORLD, {
    rate = 0.5,
    burst = 2,
    distance = { indices = { 1, 2, 3 }, maximum = 8 },
})
policy("AddDirtPuddle", G.WORLD, {
    rate = 1,
    burst = 3,
    distance = { nestedIndex = 1, maximum = 10 },
})
policy("RemoveDirtTile", G.WORLD, {
    -- Room clean chains many tiles; old rate=1 caused silent rejects mid-loop.
    rate = 6,
    burst = 16,
    distance = { indices = { 1, 2, 3 }, maximum = 12 },
    args = {
        [1] = { kind = "number" },
        [2] = { kind = "number" },
        [3] = { kind = "number" },
        [4] = { kind = "boolean", optional = true },
    },
})

policy("ChangeDiscoStyle", G.WORLD, {
    rate = 2,
    burst = 4,
    distance = { indices = { 2, 3, 4 }, maximum = 15 },
})
policy("TurnDiscoBallOff", G.WORLD, {
    rate = 2,
    burst = 4,
    distance = { indices = { 2, 3, 4 }, maximum = 15 },
})
basic({
    "JukeboxStart", "TurnJukeboxOff", "JukeboxStyleChangePlayerPlaylist",
    "JukeboxStyleChange", "StopJukeSong",
}, G.WORLD, {
    rate = 2,
    burst = 5,
    distance = { indices = { 1, 2, 3 }, maximum = 20 },
})
policy("isPlayingJuke", G.WORLD, {
    rate = 3,
    burst = 6,
    distance = { indices = { 3, 4, 5 }, maximum = 25 },
})
policy("JukeTurnedOn", G.WORLD, {
    rate = 2,
    burst = 4,
    distance = { indices = { 2, 3, 4 }, maximum = 20 },
})

policy("TransferItemWorld", G.INVENTORY, {
    rate = 4,
    burst = 8,
    distance = { nestedIndex = 4, maximum = 8 },
})
policy("TransferItem", G.INVENTORY, {
    rate = 4,
    burst = 8,
    distance = { nestedIndex = 4, maximum = 8 },
})
policy("TransferItemFrom", G.INVENTORY, {
    rate = 4,
    burst = 8,
    distance = { nestedIndex = 3, maximum = 8 },
})
policy("TransferItemTo", G.INVENTORY, {
    rate = 4,
    burst = 8,
    distance = { nestedIndex = 2, maximum = 8 },
})
policy("RemoveItems", G.INVENTORY, {
    rate = 4,
    burst = 8,
    distance = { nestedIndex = 2, maximum = 8, optional = true },
})

policy("TeleportSittingLocation", G.SOCIAL, {
    rate = 1,
    burst = 3,
    target = { index = 1, maximum = 8 },
    validate = function(player, args)
        return player and player.getDisplayName and args[2] == player:getDisplayName(),
            "source_identity"
    end,
})
policy("InteractionStart", G.SOCIAL, {
    rate = 2,
    burst = 4,
    target = { index = 1, maximum = 8 },
    validate = function(player, args)
        return player and player.getDisplayName and args[2] == player:getDisplayName(),
            "source_identity"
    end,
})
policy("ChangeAnimVarMulti", G.SOCIAL, {
    rate = 8,
    burst = 16,
    validate = function(player, args)
        return player and player.getDisplayName and args[1] == player:getDisplayName(),
            "source_identity"
    end,
})
policy("ChangeAnimVar", G.SOCIAL, {
    rate = 8,
    burst = 16,
    target = { index = 1, maximum = 30 },
    validate = function(player, args)
        return player and player.getDisplayName and args[2] == player:getDisplayName(),
            "source_identity"
    end,
})
policy("logAmbition", G.ACTION, { rate = 0.2, burst = 2 })

policy("LSK_WellnessBegin", G.ACTION, {
    rate = 2,
    burst = 4,
    args = {
        [1] = { kind = "identifier", maxLength = 32 },
        [2] = { kind = "number", min = 5000, max = 1800000, integer = true },
    },
})
policy("LSK_WellnessComplete", G.ACTION, {
    rate = 2,
    burst = 4,
    -- Own Wellness session nonce is authoritative; ActionClient proof may already be ended.
    args = {
        [1] = { kind = "string", minLength = 12, maxLength = 128 },
        [2] = { kind = "table", optional = true },
    },
})
policy("LSK_LearnTrack", G.ACTION, {
    rate = 1,
    burst = 3,
    requiresAction = true,
    args = {
        [1] = { kind = "identifier", maxLength = 32 },
        [2] = { kind = "identifier", maxLength = 64 },
    },
})
policy("LSK_AmbitionProgress", G.ACTION, {
    rate = 4,
    burst = 10,
    args = {
        [1] = { kind = "identifier", maxLength = 64 },
        [2] = { kind = "number", min = 1, max = 6, integer = true },
        [3] = { kind = "number", min = 0, max = 100000000 },
    },
})
policy("LSGoodEatingLoot", G.WORLD, {
    rate = 0.2,
    burst = 2,
    requiresAction = true,
    args = {
        [1] = { kind = "number", min = 1, max = 3, integer = true },
        [2] = { kind = "number" },
        [3] = { kind = "number" },
        [4] = { kind = "number", min = 0, max = 32, integer = true },
    },
    distance = { indices = { 2, 3, 4 }, maximum = 12 },
})
policy("LSK_ComfortSavePreset", G.SELF, {
    rate = 1,
    burst = 3,
    args = {
        [1] = { kind = "identifier", maxLength = 32 },
        [2] = { kind = "table" },
    },
})
policy("LSK_InventionBegin", G.ACTION, {
    rate = 1,
    burst = 2,
    args = {
        [1] = { kind = "identifier", maxLength = 32 },
        [2] = { kind = "identifier", maxLength = 64 },
        [3] = { kind = "number", min = 5000, max = 3600000, integer = true },
        [4] = { kind = "table", optional = true },
    },
})
policy("LSK_InventionComplete", G.ACTION, {
    rate = 1,
    burst = 2,
    -- Own Invention session nonce is authoritative.
    args = {
        [1] = { kind = "string", minLength = 12, maxLength = 128 },
    },
})
policy("LSK_HygieneClaimFixture", G.WORLD, {
    rate = 1,
    burst = 3,
    distance = { indices = { 1, 2, 3 }, maximum = 8 },
    args = {
        [1] = { kind = "number" },
        [2] = { kind = "number" },
        [3] = { kind = "number" },
        [4] = { kind = "string", maxLength = 128 },
        [5] = { kind = "identifier", optional = true, maxLength = 32 },
    },
})

basic({
    "CompleteTargetAmbt", "ResetTargetAmbt", "UpdateAmbt",
    "UpdateServerBeauty", "ImportServerBeauty", "UpdateOuthouseRangeMap",
    "DebugAddLitter", "RemoveDirtTileDebug", "LSSCTest",
}, G.ADMIN, { admin = true, rate = 1, burst = 3 })

policy("ImportServerBeauty", G.ADMIN, {
    admin = true,
    rate = 0.1,
    burst = 1,
    minArgs = 0,
})
policy("LSSCTest", G.ADMIN, {
    admin = true,
    rate = 0.2,
    burst = 1,
    minArgs = 0,
})

function LSK_NetSchema.getPolicy(command)
    return policies[command]
end

return LSK_NetSchema
