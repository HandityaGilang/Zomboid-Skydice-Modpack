-- Temporary runtime overrides for walkman belt attachments.
-- Edit values below, then press F11 (Reload Lua) in-game.

local WALKMAN_MODELS = {
    "Tsarcraft.TCWalkman",
    "Tsarcraft.TCWalkmanPurple",
    "Tsarcraft.TCWalkmanRed",
    "Tsarcraft.TCWalkmanBlack",
    "Tsarcraft.TCWalkmanPink",
    "Tsarcraft.TCWalkmanGreen",
    "Tsarcraft.TCWalkmanCamoGreen",
}

local BOOMBOX_MODELS = {
    "Tsarcraft.TCBoombox",
    "Tsarcraft.TCBoomboxBlue",
    "Tsarcraft.TCBoomboxCamo",
    "Tsarcraft.TCBoomboxBlack",
    "Tsarcraft.TCBoomboxGreen",
    "Tsarcraft.TCBoomboxPink",
    "Tsarcraft.TCBoomboxRed",
    "Tsarcraft.TMB42_TCBoombox",
    "Tsarcraft.TMB42_TCBoomboxBase",
    "Tsarcraft.TMB42_TCBoomboxBlue",
    "Tsarcraft.TMB42_TCBoomboxCamo",
    "Tsarcraft.TMB42_TCBoomboxBlack",
    "Tsarcraft.TMB42_TCBoomboxGreen",
    "Tsarcraft.TMB42_TCBoomboxPink",
    "Tsarcraft.TMB42_TCBoomboxRed",
}

-- Item-model attachment offsets (relative to the walkie belt attachment point).
local ITEM_ATTACHMENTS = {
    walkie_belt_left = {
        offset = { x = 0.0, y = 0.01, z = 0.01 },
        rotate = { x = 20.0, y = -95.0, z = 20.0 },
        scale = 9.2,
    },
    walkie_belt_right = {
        offset = { x = 0.01, y = 0.01, z = -0.01 },
        rotate = { x = -20.0, y = -95.0, z = -20.0 },
        scale = 9.2,
    },
    webbing_left_walkie = {
        offset = { x = -0.015, y = 0.0, z = 0.0 },
        rotate = { x = 0.0, y = -90.0, z = 0.0 },
        scale = 8.5,
    },
    webbing_right_walkie = {
        offset = { x = -0.015, y = 0.0, z = 0.0 },
        rotate = { x = 0.0, y = -90.0, z = 0.0 },
        scale = 8.5,
    },
}

-- Boombox back attachments (big weapon slot).
local BOOMBOX_ATTACHMENTS = {
    big_w_back = {
        offset = { x = -0.03, y = 0.11, z = -0.09 },
        rotate = { x = 155.0, y = 0.0, z = 0.0 },
        scale = 1.0,
    },
    big_w_back_bag = {
        offset = { x = 0.0, y = 0.28, z = -0.12 },
        rotate = { x = 90.0, y = 0.0, z = 0.0 },
        scale = 1.0,
    },
}

local function ensureAttachment(modelName, attachId, boneName)
    local script = getScriptManager():getModelScript(modelName)
    if not script then return nil end
    local attach = script:getAttachmentById(attachId)
    if not attach and ModelAttachment then
        attach = script:addAttachment(ModelAttachment.new(attachId))
        if boneName then
            attach:setBone(boneName)
        end
    end
    return attach
end

local function applyAttachment(modelName, attachId, data, boneName)
    local attach = ensureAttachment(modelName, attachId, boneName)
    if not attach then return end
    attach:getOffset():set(data.offset.x, data.offset.y, data.offset.z)
    attach:getRotate():set(data.rotate.x, data.rotate.y, data.rotate.z)
    if data.scale then
        attach:setScale(data.scale)
    end
end

local function applyAll()
    -- Update item-model attachments.
    for _, modelName in ipairs(WALKMAN_MODELS) do
        for attachId, data in pairs(ITEM_ATTACHMENTS) do
            applyAttachment(modelName, attachId, data)
        end
    end
    -- Update boombox back attachments.
    for _, modelName in ipairs(BOOMBOX_MODELS) do
        for attachId, data in pairs(BOOMBOX_ATTACHMENTS) do
            applyAttachment(modelName, attachId, data)
        end
    end
end

-- Apply on game start and immediately on Lua reload.
Events.OnGameStart.Add(applyAll)
applyAll()

