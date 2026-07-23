-- ************************************************************************
-- **        ██████  ██████   █████  ██    ██ ███████ ███    ██          **
-- **        ██   ██ ██   ██ ██   ██ ██    ██ ██      ████   ██          **
-- **        ██████  ██████  ███████ ██    ██ █████   ██ ██  ██          **
-- **        ██   ██ ██   ██ ██   ██  ██  ██  ██      ██  ██ ██          **
-- **        ██████  ██   ██ ██   ██   ████   ███████ ██   ████          **
-- ************************************************************************
-- ** All rights reserved. This content is protected by © Copyright law. **
-- ************************************************************************

local function flashlightOnBelt()

    local compatifyIDs = { "LightOnBelt", "FixedLightOnBeltAF", "BetterFlashlightsFixed" }
    local flashlightList = {
        ScriptManager.instance:getItem("Base.HandTorch"),
        ScriptManager.instance:getItem("Base.Flashlight_Crafted"),
        
        ScriptManager.instance:getItem("AuthenticZClothing.Torch2"),
    }

    if BB_CS_Utils.needToCompatify(compatifyIDs) then return end

    for _, flashlight in ipairs(flashlightList) do
        flashlight:DoParam("AttachmentType = Screwdriver")
    end
end

local function onInitWorld()

    local bathTowelItem = ScriptManager.instance:getItem("Base.BathTowel")
    if bathTowelItem then
        bathTowelItem:DoParam("UseDelta = 0.03")
    end

    local dishClothItem = ScriptManager.instance:getItem("Base.DishCloth")
    if dishClothItem then
        dishClothItem:DoParam("UseDelta = 0.05")
    end

    flashlightOnBelt()
end

Events.OnInitWorld.Add(onInitWorld)