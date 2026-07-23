local old_ISOpenCloseVehicleWindow_perform = ISOpenCloseVehicleWindow.perform

function ISOpenCloseVehicleWindow:perform()
    -- TODO удалить после перевода всех машин на тюнинг 2.0
    self.Wprotection = self.vehicle:getPartById("ATAProtection" .. self.part:getId())
    if self.Wprotection then
        if self.open then
            self.vehicle:playPartAnim(self.Wprotection, "Open")
            local args = { vehicle = self.vehicle:getId(), part = self.Wprotection:getId(), open = true }
            sendClientCommand(self.character, 'vehicle', 'setDoorOpen', args)
            print('ISOpenCloseVehicleWindow common vehicle setDoorOpen Open for ATAProtection '..self.part:getId())
        else
            self.vehicle:playPartAnim(self.Wprotection, "Close")
            local args = { vehicle = self.vehicle:getId(), part = self.Wprotection:getId(), open = false }
            sendClientCommand(self.character, 'vehicle', 'setDoorOpen', args)
            print('ISOpenCloseVehicleWindow common vehicle setDoorOpen Close for ATAProtection '..self.part:getId())
        end
    end
    
    self.Wprotection = self.vehicle:getPartById("ATA2Protection" .. self.part:getId())
    if self.Wprotection then
        if self.open then
            self.vehicle:playPartAnim(self.Wprotection, "Open")
            local args = { vehicle = self.vehicle:getId(), part = self.Wprotection:getId(), open = true }
            sendClientCommand(self.character, 'vehicle', 'setDoorOpen', args)
            print('ISOpenCloseVehicleWindow common vehicle setDoorOpen Open for ATA2Protection '..self.part:getId())
        else
            self.vehicle:playPartAnim(self.Wprotection, "Close")
            local args = { vehicle = self.vehicle:getId(), part = self.Wprotection:getId(), open = false }
            sendClientCommand(self.character, 'vehicle', 'setDoorOpen', args)
            print('ISOpenCloseVehicleWindow common vehicle setDoorOpen Close for ATA2Protection '..self.part:getId())
        end
    end
    old_ISOpenCloseVehicleWindow_perform(self)
end
