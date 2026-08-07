-- FOR DEBUGGING PURPOSES ONLY
--[[

local LAUGHS_FEMALE = {
    "female_laugh_01",
    "female_laugh_02",
    "female_laugh_03",
    "female_laugh_04",
    "female_laugh_05",
    "female_laugh_06",
    "female_laugh_07",
    "female_laugh_08",
}

local LAUGHS_MALE = {
    "male_laugh_01",
    "male_laugh_02",
    "male_laugh_03",
    "male_laugh_04",
}

local function onPlayDebugLaugh(player, soundName)
    if not player then return end
    player:playSoundLocal(soundName)
end

local function addLaughSubMenu(context, player, label, soundList)
    local parent = context:addOption(label, {}, nil)
    local subMenu = ISContextMenu:getNew(context)
    context:addSubMenu(parent, subMenu)

    for _, soundName in ipairs(soundList) do
        subMenu:addOption(soundName, player, onPlayDebugLaugh, soundName)
    end
end

local function buildPK42DebugLaughMenu(playerNum, context, worldobjects, test)
    if test and ISWorldObjectContextMenu.Test then return true end

    local player = getSpecificPlayer(playerNum)
    if not player then return end

    addLaughSubMenu(context, player, "[DEBUG] laugh male", LAUGHS_MALE)
    addLaughSubMenu(context, player, "[DEBUG] laugh female", LAUGHS_FEMALE)
end

Events.OnFillWorldObjectContextMenu.Add(buildPK42DebugLaughMenu)
]]