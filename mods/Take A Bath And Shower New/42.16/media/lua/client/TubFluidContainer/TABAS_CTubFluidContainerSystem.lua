local TFC_Utils = require("TubFluidContainer/TABAS_TubFluidContainerSystemUtils")
local TABAS_Utils = require("TABAS_Utils")
local TABAS_Iso = require("TABAS_Iso")
local TABAS_Sounds = require("TABAS_Sounds")

-- local TABAS_GT = require("TABAS_GameTimes")

-------------------------- Sound --------------------------------

local runtime = {} -- [id] = { emitter=..., bath=..., tfc=..., state=... }

local function getRuntime(id)
    runtime[id] = runtime[id] or {}
    return runtime[id]
end

local function stopRuntime(id)
    local r = runtime[id]
    if not r then return end
    if r.emitter then
        r.emitter:stopAll()
        r.emitter = nil
    end
    runtime[id] = nil
end

local function ensureEmitter(r, x, y, z, bath)
    if r.emitter then return r.emitter end
    local emitter = getWorld():getFreeEmitter(x, y, z)
    getWorld():setEmitterOwner(emitter, bath)
    r.emitter = emitter
    return emitter
end

local function tubWaterClientTick()
    if isServer() then return end

    local gData = GetTFCSystemData()
    local activated = gData.Activated
    for id, _ in pairs(runtime) do
        if not activated[id] or not activated[id].activate then
            stopRuntime(id)
        end
    end

    for id, v in pairs(activated) do
        if v.activate then
            local r = getRuntime(id)
            local bath = TABAS_Iso.getBathObjectAt(v.x, v.y, v.z)
            if not bath or bath:isDestroyed() then
                stopRuntime(id)
            else
                local tfc = TFC_Utils.getTfcBaseOnClient(v.x, v.y, v.z, bath)
                if not tfc then
                    stopRuntime(id)
                else
                    local emitter = ensureEmitter(r, v.x, v.y, v.z, bath)
                    if r.state ~= v.state then
                        emitter:stopAll()
                        r.state = v.state
                    end
                    if v.state == "fill" then
                        if v.phase == "runout" then
                            if not emitter:isPlaying("tabas_tubwater_runout") then
                                emitter:stopAll()
                                TABAS_Sounds.playEmitterSoundImpl(emitter, "tabas_tubwater_runout", bath)
                                -- emitter:playSoundImpl("tabas_tubwater_runout", bath)
                            end
                        else
                            if not emitter:isPlaying("tabas_tubwater_fill") then
                                emitter:stopAll()
                                TABAS_Sounds.playEmitterSoundImpl(emitter, "tabas_tubwater_fill", bath)
                                -- emitter:playSoundLoopedImpl("tabas_tubwater_fill")
                            end
                        end
                    elseif v.state == "empty" then
                        if v.phase == "finish" then
                            if not emitter:isPlaying("tabas_tubwater_drain_finish") then
                                emitter:stopAll()
                                TABAS_Sounds.playEmitterSoundImpl(emitter, "tabas_tubwater_drain_finish", bath)
                                -- emitter:playSoundImpl("tabas_tubwater_drain_finish", bath)
                            end
                        else
                            if not emitter:isPlaying("tabas_tubwater_drain_loop") then
                                emitter:stopAll()
                                TABAS_Sounds.playEmitterSoundImpl(emitter, "tabas_tubwater_drain_loop", bath)
                                -- emitter:playSoundLoopedImpl("tabas_tubwater_drain_loop")
                            end
                        end
                    elseif v.state == "reheat" then
                        if not emitter:isPlaying("tabas_tubwater_reheat") then
                            emitter:stopAll()
                            TABAS_Sounds.playEmitterSoundImpl(emitter, "tabas_tubwater_reheat", bath)
                            -- emitter:playSoundLoopedImpl("tabas_tubwater_reheat")
                        end
                    end
                end
            end
        end
    end
end
Events.OnTick.Add(tubWaterClientTick)



-------------------------- Special Tooltip --------------------------------

local function tfcSpecialTooltip(tooltip, tfc_Base)
    if not tfc_Base then return end

    local amount = tfc_Base:getAmount() or 0
    local temperature = tfc_Base:getWaterTemperature()
    local capacity = tfc_Base:getCapacity() or 0
    if amount > 0 then
        amount = round(amount, 2)
    end
    local temperatureText = TABAS_Utils.formatedCelsiusOrFahrenheit(temperature, 2)
    tooltip:DrawTextureScaled(tooltip:getTexture(), 0, 0, tooltip:getWidth(), tooltip:getHeight(), 0.75)
    tooltip:DrawTextCentre(tooltip:getFont(), getText("Fluid_Container_TubFluidContainer"), tooltip:getWidth() / 2, 5, 1, 1, 1, 1)
    tooltip:adjustWidth(120, getText("Fluid_Container_TubFluidContainer"))
    local font = tooltip:getFont()

    local layout = tooltip:beginLayout()

    local layoutItem = layout:addItem()
    layoutItem:setLabel(getText("IGUI_TABAS_BathtubInfo_Amount") .. ": ", 1, 1, 1, 1)
    layoutItem:setValue(amount .. " / " .. capacity .. "L", 1, 1, 1, 1)

    local layoutItem = layout:addItem()
    layoutItem:setLabel(getText("IGUI_TABAS_BathtubInfo_Temperature") .. ": ", 1, 1, 1, 1)
    layoutItem:setValue(temperatureText, 1, 1, 1, 1)

    local height = layout:render(5, 5 + getTextManager():getFontHeight(font), tooltip)
    tooltip:setHeight(height + 15)
	tooltip:endLayout(layout)
end

local function doSpecialTooltip(tooltip, square)
    if not TABAS_Utils.ModOptionsValue("DisplayTubSpacialTooltip") then return end

    local x, y, z = square:getX(), square:getY(), square:getZ()
    local bathObj = TABAS_Iso.getBathObjectAt(x, y, z)
    local tfc_Base = bathObj and TABAS_Iso.getTfcBaseOnBathObject(bathObj) or nil
    if not tfc_Base then return end

	tooltip:setWidth(100)
	tooltip:setMeasureOnly(true)
	tfcSpecialTooltip(tooltip, tfc_Base)
	tooltip:setMeasureOnly(false)
	tfcSpecialTooltip(tooltip, tfc_Base)
end
Events.DoSpecialTooltip.Add(doSpecialTooltip)

