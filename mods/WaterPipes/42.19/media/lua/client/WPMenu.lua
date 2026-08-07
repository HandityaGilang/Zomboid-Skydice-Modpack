local TATurnOnPump = require("Actions/TATurnOnPump")
local TATurnOffPump = require("Actions/TATurnOffPump")
local TAAddFilterPump = require("Actions/TAAddFilterPump")
local TARepairPump = require("Actions/TARepairPump")
local TAInfoPump = require("Actions/TAInfoPump")
local TASwitchValve = require("Actions/TASwitchValve")
local TAInfoFlowmeter = require("Actions/TAInfoFlowmeter")

local function TimedPumpTurnOn (playerObj, square, object)
    if luautils.walkAdj(playerObj, square) then
        ISTimedActionQueue.add(TATurnOnPump:new(playerObj, square, object))
    end
end

local function TimedPumpTurnOff (playerObj, square, object, fresh, fuel)
    if luautils.walkAdj(playerObj, square) then
        ISTimedActionQueue.add(TATurnOffPump:new(playerObj, square, object))
    end
end

local function TimedPumpAddFilter (playerObj, square, object, charcoal)
    if luautils.walkAdj(playerObj, square) then
        ISTimedActionQueue.add(TAAddFilterPump:new(playerObj, square, object, charcoal))
    end
end

local function TimedPumpRepair (playerObj, square, object)
    if luautils.walkAdj(playerObj, square) then
        ISTimedActionQueue.add(TARepairPump:new(playerObj, square, object))
    end
end

local function TimedPumpInfo (playerObj, square, object)
    if luautils.walkAdj(playerObj, square) then
        ISTimedActionQueue.add(TAInfoPump:new(playerObj, object))
    end
end

local function TimedValveSwitch (playerObj, square, object, closed)
    if luautils.walkAdj(playerObj, square) then
        ISTimedActionQueue.add(TASwitchValve:new(playerObj, square, object, closed))
    end
end

local function TimedFlowmeterInfo (playerObj, square, object)
    if luautils.walkAdj(playerObj, square) then
        ISTimedActionQueue.add(TAInfoFlowmeter:new(playerObj, object))
    end
end

local function onFillWorldObjectContextMenu(playerNum, context, worldObjects, test)
    context:removeOptionByName("Water Pump")
    context:removeOptionByName("Wasserpumpe")
    context:removeOptionByName("Bomba")
    context:removeOptionByName("Pompa")
    context:removeOptionByName("Bomba de Água")
    context:removeOptionByName("Водяной насос")
    context:removeOptionByName("Su Pompası")
end

local function onPreFillWorldObjectContextMenu(player, context, worldobjects, test)
    local fetch = ISWorldObjectContextMenu.fetchVars
    local square = fetch.clickedSquare
    if not square then return end

    local playerObj = getSpecificPlayer(player)
    local sx, sy, sz = square:getX(), square:getY(), square:getZ()
    local isoPump = WPIso.GetPump(square)
    -- local isoPipe = WPIso.GetPipe(square)

    

    if isoPump then
        local pump = WPVirtual.PumpGet(sx, sy, sz)
        if pump then

            -- TURN ON / OFF
            if pump.active then
                local optionPumpTurnOff = context:addOption(getText("ContextMenu_Turn_Off"), playerObj, TimedPumpTurnOff, square, isoPump)
            else
                local optionPumpTurnOn = context:addOption(getText("ContextMenu_Turn_On"), playerObj, TimedPumpTurnOn, square, isoPump)
                if pump.efficiency < 10 then
                    local tooltipTurnOn = ISToolTip:new()
                    tooltipTurnOn.description = getText("Tooltip_WP_ThePumpWornHazard")
                    optionPumpTurnOn.toolTip = tooltipTurnOn
                elseif pump.efficiency == 0 then
                    local tooltipTurnOn = ISToolTip:new()
                    tooltipTurnOn.description = getText("Tooltip_WP_ThePumpIsWornOut")
                    optionPumpTurnOn.notAvailable = true
                    optionPumpTurnOn.toolTip = tooltipTurnOn
                elseif not square:haveElectricity() then
                    local tooltipTurnOn = ISToolTip:new()
                    tooltipTurnOn.description = getText("Tooltip_WP_NeedsPowerToOperate")
                    optionPumpTurnOn.notAvailable = true
                    optionPumpTurnOn.toolTip = tooltipTurnOn
                end
            end

            -- REPAIR
            local scrapMetal = playerObj:getInventory():getFirstTypeRecurse("ScrapMetal")
            local optionPumpRepair = context:addOption(getText("ContextMenu_WP_FixPump"), playerObj, TimedPumpRepair, square, isoPump)
            if pump.efficiency > 95 then
                local tooltipRepair = ISToolTip:new()
                optionPumpRepair.notAvailable = true
                tooltipRepair.description = getText("ContextMenu_WP_FixPumpPerfect")
                optionPumpRepair.toolTip = tooltipRepair
            elseif not scrapMetal then
                local tooltipRepair = ISToolTip:new()
                optionPumpRepair.notAvailable = true
                tooltipRepair.description = getText("ContextMenu_WP_FixPumpNoMaterial")
                optionPumpRepair.toolTip = tooltipRepair
            elseif pump.active then
                local tooltipRepair = ISToolTip:new()
                optionPumpRepair.notAvailable = true
                tooltipRepair.description = getText("ContextMenu_WP_FixPumpTurnOn")
                optionPumpRepair.toolTip = tooltipRepair
            end

            -- ADD FILTER
            local charcoal = playerObj:getInventory():getFirstTagRecurse(ItemTag.CHARCOAL)
            local optionCharcoal = context:addOption(getText("ContextMenu_WP_AddCharcoal"), playerObj, TimedPumpAddFilter, square, isoPump, charcoal)
            if not charcoal then    
                local tooltipCharcoal = ISToolTip:new()
                tooltipCharcoal.description = getText("Tooltip_WP_NeedsCharcoal")
                optionCharcoal.notAvailable = true
                optionCharcoal.toolTip = tooltipCharcoal
            end

            -- INFO
            local tooltipPump = ISToolTip:new()
            tooltipPump:setName(getText("ContextMenu_WP_PumpInfo"))
            tooltipPump.description = ISWaterPumpInfoWindow.getRichText(isoPump)

            local optionPumpInfo = context:addOption(getText("ContextMenu_WP_PumpInfo"), playerObj, TimedPumpInfo, square, isoPump)
            optionPumpInfo.toolTip = tooltipPump
        end
    end

    -- VALVE
    local isoValve = WPIso.GetValve(square)
    if isoValve then
        local valve = WPVirtual.ValveGet(sx, sy, sz)
        if valve then
            if valve.c then
                local optionValveOpen = context:addOption(getText("ContextMenu_WP_ValveOpen"), playerObj, TimedValveSwitch, square, isoValve, false)
            else
                local optionValveClose = context:addOption(getText("ContextMenu_WP_ValveClose"), playerObj, TimedValveSwitch, square, isoValve, true)
            end
        end
    end


    -- FLOWMETER
    local isoFlowmeter = WPIso.GetFlowmeter(square)
    if isoFlowmeter then
        local flowmeter = WPVirtual.FlowmeterGet(sx, sy, sz)
        if flowmeter then
            local tooltipFlowmeter = ISToolTip:new()
            tooltipFlowmeter:setName(getText("ContextMenu_WP_FlowmeterInfo"))
            tooltipFlowmeter.description = ISFlowmeterInfoWindow.getRichText(isoFlowmeter)

            local optionFlowmeterInfo = context:addOption(getText("ContextMenu_WP_FlowmeterInfo"), playerObj, TimedFlowmeterInfo, square, isoFlowmeter)
            optionFlowmeterInfo.toolTip = tooltipFlowmeter
        end
    end
end

Events.OnPreFillWorldObjectContextMenu.Remove(onPreFillWorldObjectContextMenu)
Events.OnPreFillWorldObjectContextMenu.Add(onPreFillWorldObjectContextMenu)

Events.OnFillWorldObjectContextMenu.Remove(onFillWorldObjectContextMenu)
Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)