local TABAS_AnimVariables = {}

TABAS_AnimVariables["BATH"] = {}

TABAS_AnimVariables["BATH"].Variables = {
    -- @BoolValue
    PERFORM = "TABAS_TakeBath",
    STARTED = "TABAS_BathStarted",
    STOPPING = "TABAS_BathStopping",
    ENDED = "TABAS_BathEnded",
    WASH_PART_FINISHED = "TABAS_WashPartFinished",
    ACTION_FINISHED = "TABAS_BathActionFinished",
    STANCE_CHANGE_FINISHED = "TABAS_BathStanceChangeFinished",
    HAS_TIMED_ACTIONS = "TABAS_HasBathTimedActions",
    -- @StringValue
    ACTION = "TABAS_BathAction",
    WASH_PART = "TABAS_WashPart",
    STANCE = "TABAS_BathStance",
    EXT = "Ext"
}

TABAS_AnimVariables["BATH"].Actions = {
    GETUP = "Getup",
    ACTION = "Action",
    WAIT = "WaitToAction",
}

TABAS_AnimVariables["BATH"].Stances = {
    {"ElbowLF", "ElbowRF", "LookUpF", "Relax", "SitF"}, -- isFemale
    {"ElbowL", "ElbowR", "LookUp", "Relax", "Sit"}
}

TABAS_AnimVariables["BATH"].Exts = {
    "BathExtLookUp", "BathExtShoulder", "BathExtStretch",
    "PainArmL", "PainArmR", "WipeHead", "PainHandL", "PainHandR", "WipeBrow", "Yawn" -- from vanilla
}

TABAS_AnimVariables["BATH"].WashParts = {
    {"FaceF", "Arms", "LegsF"}, -- isFemale
    {"Face", "Arms", "Legs"}
}

TABAS_AnimVariables["SHOWER"] = {}

TABAS_AnimVariables["SHOWER"].Variables = {
    -- @BoolValue
    PERFORM = "TABAS_TakeShower",
    STARTED = "TABAS_ShowerStarted",
    STOPPING = "TABAS_ShowerStopping",
    ENDED = "TABAS_ShowerEnded",
    WASH_PART_FINISHED = "TABAS_WashPartFinished",
    -- @StringValue
    ACTION = "TABAS_ShowerAction",
    WASH_PART = "TABAS_WashPart",
}

TABAS_AnimVariables["SHOWER"].Actions = {
    START = "ShowerStart",
    STOP = "ShowerStop",
    WASH = "Wash",
    NO_WATER = "ShowerNoWater"
}

TABAS_AnimVariables["SHOWER"].WashParts = {
    {"HeadF", "Face", "Arms", "Torso"}, -- isFemale
    {"Head", "Face", "Arms", "Torso"}
}

local function copyArray(t)
    local new = {}
    if not t then return new end
    for i = 1, #t do
        new[i] = t[i]
    end
    return new
end

local function shuffleArray(t)
    for i = #t, 2, -1 do
        local j = ZombRand(i) + 1
        t[i], t[j] = t[j], t[i]
    end
    return t
end

function TABAS_AnimVariables.getArray(animType, key, isFemale, doShuffle)
    local animData = TABAS_AnimVariables[animType]
    if not animData then
        print("TABAS_AnimVariables.getArray: invalid animType " .. tostring(animType))
        return {}
    end

    local source = animData[key]
    if not source then
        print("TABAS_AnimVariables.getArray: invalid key " .. tostring(key))
        return {}
    end

    local list
    if isFemale == nil then
        list = source
    else
        list = source[isFemale and 1 or 2]
    end

    local result = copyArray(list)

    if doShuffle then
        shuffleArray(result)
    end
    return result
end

function TABAS_AnimVariables.getWashParts(animType, isFemale, doShuffle)
    return TABAS_AnimVariables.getArray(animType, "WashParts", isFemale, doShuffle)
end

function TABAS_AnimVariables.getStances(animType, isFemale, doShuffle)
    return TABAS_AnimVariables.getArray(animType, "Stances", isFemale, doShuffle)
end

function TABAS_AnimVariables.getExts(animType, doShuffle)
    return TABAS_AnimVariables.getArray(animType, "Exts", nil, doShuffle)
end

function TABAS_AnimVariables.setVariables(character, animType, args)
    local vars = TABAS_AnimVariables[animType].Variables
    if not vars then
        print("TABAS_AnimVariables: Included invalid type name!")
        return
    end

    if args.CLEAR then
        for _, variable in pairs(vars) do
            if character:getVariable(variable) ~= nil then
                character:clearVariable(variable)
            end
        end
        return
    end

    for k, v in pairs(args) do
        if vars[k] ~= nil then
            local animVariable = vars[k]
            if character:getVariable(animVariable) ~= v then
                character:setVariable(animVariable, v)
            end
        end
    end
end

function TABAS_AnimVariables.syncAnim(character, animType, args, isOneself)
    if not character then return end

    if isOneself then
        TABAS_AnimVariables.setVariables(character, animType, args)
    end

    if isServer() then
        args.onlineID = character:getOnlineID()
        args.animType = animType
        sendServerCommand("tabas_bathing", "syncVariables", args)
    elseif isClient() then
        args.animType = animType
        sendClientCommand(character, "tabas_bathing", "syncAnim", args)
    end
end

function TABAS_AnimVariables.clearVariables(character, animType)
    TABAS_AnimVariables.syncAnim(character, animType, {CLEAR = true}, true)
end

return TABAS_AnimVariables