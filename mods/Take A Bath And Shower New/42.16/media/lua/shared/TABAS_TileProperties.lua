local TABAS_TileProperties = {}

local TABAS_Sprites = require("TABAS_Sprites")
local DIR_KEYS = { "spriteS", "spriteE", "spriteN", "spriteW" }

local function SetProperty(props, property, val)
    if props:has(property) then
        if props:get(property) ~= val then
            props:set(property, val, true)
        end
    else
        props:set(property, val)
    end
end

local function UnSetProperty(props, property)
    if props:has(property) then
        props:unset(property)
    end
end

local function SetAttachedWall(props)
    local facing = props:get("Facing")
    if facing == "S" then
        SetProperty(props, "attachedN", "")
    elseif facing == "E" then
        SetProperty(props, "attachedW", "")
    elseif facing == "W" then
        SetProperty(props, "attachedE", "")
    else -- facing == "N" then
        SetProperty(props, "attachedS", "")
    end
end

local function GetSpriteProperties(spriteManager, spriteName)
    if not spriteManager or not spriteName or spriteName == "" then
        return nil
    end

    local sprite = spriteManager:getSprite(spriteName)
    return sprite and sprite:getProperties() or nil
end

TABAS_TileProperties.applied = false

function TABAS_TileProperties.invalidate()
    TABAS_TileProperties.applied = false
end

function TABAS_TileProperties.apply(force)
    if force then
        TABAS_TileProperties.invalidate()
    end
    if TABAS_TileProperties.applied then return true end

--- Bath Tub Properties ---
    local spriteManager = IsoSpriteManager.instance
    local props
    local remainTubWater = SandboxVars.TakeABathAndShower.RemainTubFaucetWater
    local remainShowerWater = SandboxVars.TakeABathAndShower.RemainShowerFaucetWater
    for name, value in pairs(TABAS_Sprites.Bathtub) do
        for _, dirKey in ipairs(DIR_KEYS) do
            local bath = value[dirKey]
            local faucetSprite = bath and bath.faucet or nil
            local tubSprite = bath and bath.tub or nil

            if faucetSprite then
                props = GetSpriteProperties(spriteManager, faucetSprite)
                if props then
                    -- setHoppables(props, true)
                    props:unset(IsoFlagType.solidtrans)
                    if string.find(name, "Large Deluxe") or value.isLargeDeluxe then
                        SetProperty(props, "ItemHeight", "20")
                        SetProperty(props, "IsLow", "")
                        SetProperty(props, "waterPiped", "")
                        SetProperty(props, "waterMaxAmount", tostring(remainTubWater))
                        SetProperty(props, "waterAmount", tostring(remainTubWater))
                    end
                else
                    DebugLog.log("TABAS_OnGameStart: Fetch Bath Sprites Failed!")
                end
            end

            if tubSprite then
                props = GetSpriteProperties(spriteManager, tubSprite)
                if props then
                    -- setHoppables(props, false)
                    props:unset(IsoFlagType.solidtrans)
                    if string.find(name, "Large Deluxe") or value.isLargeDeluxe then
                        SetProperty(props, "ItemHeight", "20")
                        SetProperty(props, "IsLow", "")
                        UnSetProperty(props, "waterPiped")
                        UnSetProperty(props, IsoFlagType.waterPiped)
                        UnSetProperty(props, "waterAmount")
                        UnSetProperty(props, "waterMaxAmount")
                    end
                else
                    DebugLog.log("TABAS_OnGameStart: Fetch Bath Sprites Failed!")
                end
            end
        end
    end

    --- Shower Properties ---
    for name, value in pairs(TABAS_Sprites.Shower) do
        for _, dirKey in ipairs(DIR_KEYS) do
            local shower = value[dirKey]
            if shower then
                props = GetSpriteProperties(spriteManager, shower)
                if props then
                    if name == "Deluxe" or value.isDeluxe then
                        SetProperty(props, "ItemHeight", "8")
                    elseif name == "Wall" then
                        SetProperty(props, "CustomItem", "Base.Mov_WallShower")
                    end
                    SetProperty(props, "PickUpTool", "Wrench") -- not hummer
                    SetProperty(props, "PlaceTool", "Wrench") -- not hummer
                    UnSetProperty(props, "PickUpLevel")
                    SetProperty(props, "waterPiped", "")
                    SetProperty(props, "waterMaxAmount", tostring(remainShowerWater))
                    SetProperty(props, "waterAmount", tostring(remainShowerWater))
                    SetAttachedWall(props)
                else
                    DebugLog.log("TABAS_OnGameStart: Fetch Shower Sprites Failed!")
                end
            end
        end
    end

    -- Dummy Tub Edge (Blocked)
    props = GetSpriteProperties(spriteManager, "tabas_fixtures_bathroom_01_2")
    if props then
        props:set(IsoFlagType.transparentN)
        props:set(IsoFlagType.CantClimb)
        props:set("IsLow", "")
    end
    props = GetSpriteProperties(spriteManager, "tabas_fixtures_bathroom_01_3")
    if props then
        props:set(IsoFlagType.transparentW)
        props:set(IsoFlagType.CantClimb)
        props:set("IsLow", "")
    end

    TABAS_TileProperties.applied = true
    return true
end

Events.OnGameStart.Add(TABAS_TileProperties.apply)
Events.OnServerStarted.Add(TABAS_TileProperties.apply)

return TABAS_TileProperties
