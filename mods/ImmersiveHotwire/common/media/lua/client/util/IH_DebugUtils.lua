Events.OnGameStart.Add(function()
    if not ISVehicleMechanics or not ISVehicleMechanics.onRightMouseUp then
        return
    end
    if ISVehicleMechanics._IH_wrapped_onRightMouseUp then
        return
    end
    ISVehicleMechanics._IH_wrapped_onRightMouseUp = true

    local _orig = ISVehicleMechanics.onRightMouseUp

    function ISVehicleMechanics:onRightMouseUp(x, y)
        local part = self:getMouseOverPart(x, y)
        local ret = _orig(self, x, y)

        local playerObj = getSpecificPlayer(self.playerNum)
        if not playerObj or (not playerObj:isAccessLevel("admin") and not isDebugEnabled()) then
            return ret
        end
        if not self.vehicle then
            return ret
        end

        if not self.context and not part then
            self.context = ISContextMenu.get(
                self.playerNum,
                x + self:getAbsoluteX(),
                y + self:getAbsoluteY()
            )
        end

        local context = self.context
        if not context then
            return ret
        end

        local top = context:addOption("CHEAT: Immersive Hotwire")
        local sub = ISContextMenu:getNew(context)
        context:addSubMenu(top, sub)

        sub:addOption("Clear", self.vehicle, function(v, p)
            sendClientCommand("IH", "ClearVehicleModData", { vehicleId = v:getId() })
            p:Say("Vehicle restored.")
        end, playerObj)

        context:setVisible(true)
        return ret
    end
end)
