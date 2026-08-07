local TABAS_Sprites = require("TABAS_Sprites")

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

local function TABAS_TileProperties()
--- Bath Tub Properties ---
    local spriteManager = IsoSpriteManager.instance
    local props
    local remainTubWater = SandboxVars.TakeABathAndShower.RemainTubFaucetWater
    local remainShowerWater = SandboxVars.TakeABathAndShower.RemainShowerFaucetWater
    for name, value in pairs(TABAS_Sprites.Bathtub) do
        for dir, bath in pairs(value) do
            props = spriteManager:getSprite(bath.faucet):getProperties()
            if props then
                -- setHoppables(props, true)
                props:unset(IsoFlagType.solidtrans)
                if string.find(name, "Large Deluxe") then
                    SetProperty(props, "ItemHeight", "20")
                    SetProperty(props, "IsLow", "")
                    SetProperty(props, "waterPiped", "")
                    SetProperty(props, "waterMaxAmount", tostring(remainTubWater))
                    SetProperty(props, "waterAmount", tostring(remainTubWater))
                end
            else
                DebugLog.log("TABAS_OnGameStart: Fetch Bath Sprites Failed!")
            end
            props = spriteManager:getSprite(bath.tub):getProperties()
            if props then
                -- setHoppables(props, false)
                props:unset(IsoFlagType.solidtrans)
                if string.find(name, "Large Deluxe") then
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

    --- Shower Properties ---
    for name, value in pairs(TABAS_Sprites.Shower) do
        for dir, shower in pairs(value) do
            props = spriteManager:getSprite(shower):getProperties()
            if props then
                if name == "Deluxe" then
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

    -- Dummy Tub Edge (Blocked)
    props = spriteManager:getSprite("tabas_fixtures_bathroom_01_2"):getProperties()
    if props then
        props:set(IsoFlagType.transparentN)
        props:set(IsoFlagType.CantClimb)
        props:set("IsLow", "")
    end
    props = spriteManager:getSprite("tabas_fixtures_bathroom_01_3"):getProperties()
    if props then 
        props:set(IsoFlagType.transparentW)
        props:set(IsoFlagType.CantClimb)
        props:set("IsLow", "")
    end
end

Events.OnGameStart.Add(TABAS_TileProperties)
Events.OnServerStarted.Add(TABAS_TileProperties)