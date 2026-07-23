
local old_ISEnterVehicle_isValid = ISEnterVehicle.isValid
local old_ISEnterVehicle_start = ISEnterVehicle.start
local old_ISEnterVehicle_stop = ISEnterVehicle.stop
local old_ISEnterVehicle_perform = ISEnterVehicle.perform

local old_ISExitVehicle_start = ISExitVehicle.start
local old_ISExitVehicle_stop = ISExitVehicle.stop
local old_ISExitVehicle_perform = ISExitVehicle.perform

local old_ISSwitchVehicleSeat_start = ISSwitchVehicleSeat.start
local old_ISSwitchVehicleSeat_perform = ISSwitchVehicleSeat.perform

--local old_ISVehicleMenu_processEnter = ISVehicleMenu.processEnter
--ISVehicleMenu.processEnter = function (playerObj, vehicle, seat)
--    --print ('ISVehicleMenu.processEnter ',playerObj,' ', vehicle,' ', seat,' ', vehicle:isEnterBlocked(playerObj, seat))
--    old_ISVehicleMenu_processEnter(playerObj, vehicle, seat)
--end

local old_ISVehicleMenu_onEnterAux = ISVehicleMenu.onEnterAux
ISVehicleMenu.onEnterAux = function (playerObj, vehicle, seat)
    local doorPart = vehicle:getPassengerDoor(seat)
    --print ('ISVehicleMenu.onEnterAux ',playerObj,' ', vehicle,' ', seat,' ', tab2str(doorPart))
    if doorPart then
        local conf = vehicle:getPartById("AMCConfig")
        local motoInfo = conf and conf:getTable("AMCConfig")
        if motoInfo then
            --print ('ISVehicleMenu.onEnterAux AMCConfig ', tab2str(motoInfo))
            if motoInfo.noDoor then--bypass ISVehicleMenu.onEnterAux
                --ISTimedActionQueue.add(ISPathFindAction:pathToVehicleSeat(playerObj, vehicle, seat))
                ISTimedActionQueue.add(ISEnterVehicle:new(playerObj, vehicle, seat))
                return
            end
        end
    end
    old_ISVehicleMenu_onEnterAux(playerObj, vehicle, seat)
end

function ISEnterVehicle:isValid()
    --print ('ISEnterVehicle:isValid ',self.vehicle,' ', self.character:getX(),',',self.character:getY(),',',self.character:getZ())
    if self.vehicle and self.vehicle:getPartById("AMCConfig") then
        if self.started then
            --print ('ISEnterVehicle:isValid started ',self.vehicle:getCharacter(self.seat),' ',self.character)
            return self.vehicle:getCharacter(self.seat) == self.character
        else
            --print ('ISEnterVehicle:isValid ',self.character:getVehicle() == nil,' ', not self.vehicle:isSeatOccupied(self.seat))
            return self.character:getVehicle() == nil and not self.vehicle:isSeatOccupied(self.seat)
        end
    end
    return old_ISEnterVehicle_isValid(self)
end

function ISEnterVehicle:start()
    --print ('ISEnterVehicle:start ',self.vehicle)
    old_ISEnterVehicle_start(self)
    if self.vehicle and self.vehicle:getPartById("AMCConfig") then
        local motoInfo = self.vehicle:getPartById("AMCConfig"):getTable("AMCConfig")
        if motoInfo then
            --Quad distance entering hack
            local outside = self.vehicle:getPassengerPosition(self.seat, "outside")
            local worldPos = Vector3f.new()
            self.vehicle:getWorldPos(outside:getOffset(), worldPos)
            if self.character:DistTo(worldPos:x(), worldPos:y()) > 2 then
                self.action:setBlockMovementEtc(true) -- ignore 'E' while entering
                self.vehicle:enter(self.seat, self.character)
                self.vehicle:playPassengerSound(self.seat, "enter")
                self.character:SetVariable("bEnteringVehicle", "true")
                self.character:triggerMusicIntensityEvent("VehicleEnter")

                if (self.character:getPrimaryHandItem() and self.character:getPrimaryHandItem():hasTag(ItemTag.HEAVY_ITEM)) or (self.character:getSecondaryHandItem() and self.character:getSecondaryHandItem():hasTag(ItemTag.HEAVY_ITEM)) then
                    if isClient() then
                        local args = { id = self.character:getOnlineID() }
                        sendClientCommand(self.character, 'player', 'onDropHeavyItem', args)
                    else
                        forceDropHeavyItems(self.character)
                    end
                end
            end
            --end Quad distance entering hack
            
            self.character:setVariable("ATVehicleType", motoInfo.type .. self.seat)
            if motoInfo.hideWeapon == "1" then
                self.character:setHideWeaponModel(true)
            end
            if isClient() and self.character:isLocalPlayer() then
                ModData.getOrCreate("tsaranimations")[self.character:getOnlineID()] = true
                ModData.transmit("tsaranimations")
            end
            sendClientCommand(self.character, 'autotsaranim', 'updateVariables', {vehicle = self.vehicle:getId(), seatId = self.seat, status = "enter",})
        end
    end
end

function ISEnterVehicle:stop()
    --print ('ISEnterVehicle:stop ',self.vehicle)
    if self.vehicle and self.vehicle:getPartById("AMCConfig") then
        local motoInfo = self.vehicle:getPartById("AMCConfig"):getTable("AMCConfig")
        if motoInfo then
            self.character:ClearVariable("ATVehicleType")
            self.character:setHideWeaponModel(false)
            if isClient() then
                ModData.getOrCreate("tsaranimations")[self.character:getOnlineID()] = nil
                ModData.transmit("tsaranimations")
            end
            sendClientCommand(self.character, 'autotsaranim', 'updateVariables', {vehicle = self.vehicle:getId(), seatId = self.seat, status = "none",})
        end
    end
    old_ISEnterVehicle_stop(self)
end

function ISEnterVehicle:perform()
    --print ('ISEnterVehicle:perform ',self.vehicle)
    if self.vehicle and self.vehicle:getPartById("AMCConfig") then
        local motoInfo = self.vehicle:getPartById("AMCConfig"):getTable("AMCConfig")
        if motoInfo then
            sendClientCommand(self.character, 'autotsaranim', 'updateVariables', {vehicle = self.vehicle:getId(), seatId = self.seat, status = "stop",})
        end
    end
    old_ISEnterVehicle_perform(self)
end


function ISExitVehicle:start()
    --print ('ISExitVehicle:start ',self.vehicle)
    old_ISExitVehicle_start(self)
    if self.character:getVehicle() and self.character:getVehicle():getPartById("AMCConfig") then
        local motoInfo = self.character:getVehicle():getPartById("AMCConfig"):getTable("AMCConfig")
        if motoInfo then
            sendClientCommand(self.character, 'autotsaranim', 'updateVariables', {vehicle = self.character:getVehicle():getId(), seatId = self.character:getVehicle():getSeat(self.character), status = "exit",})
        end
    end
end

function ISExitVehicle:stop()
    --print ('ISExitVehicle:stop ',self.vehicle)
    if self.character:getVehicle() and self.character:getVehicle():getPartById("AMCConfig") then
        local motoInfo = self.character:getVehicle():getPartById("AMCConfig"):getTable("AMCConfig")
        if motoInfo then
            sendClientCommand(self.character, 'autotsaranim', 'updateVariables', {vehicle = self.character:getVehicle():getId(), seatId = self.character:getVehicle():getSeat(self.character), status = "stop",})
        end
    end
    old_ISExitVehicle_stop(self)
end

function ISExitVehicle:perform()
    --print ('ISExitVehicle:perform ',self.vehicle)
    if self.character:getVehicle() and self.character:getVehicle():getPartById("AMCConfig") then
        local motoInfo = self.character:getVehicle():getPartById("AMCConfig"):getTable("AMCConfig")
        if motoInfo then
            self.character:setHideWeaponModel(false)
            self.character:clearVariable("ATVehicleType")
            self.character:clearVariable("ATVehicleStatus")
            self.character:clearVariable("ATPassengerStatus")
            if isClient() then
                ModData.getOrCreate("tsaranimations")[self.character:getOnlineID()] = nil
                ModData.transmit("tsaranimations")
            end
            sendClientCommand(self.character, 'autotsaranim', 'updateVariables', {vehicle = self.character:getVehicle():getId(), seatId = self.character:getVehicle():getSeat(self.character), status = "none",})
        end
    end
    old_ISExitVehicle_perform(self)
end

-- Смена сиденья не успевает синхронизироваться
-- function ISSwitchVehicleSeat:start()
    -- old_ISSwitchVehicleSeat_start(self)
    -- sendClientCommand(self.character, 'autotsaranim', 'updateVariables', {vehicle = self.character:getVehicle():getId(), seatId = self.seatTo, status = "switchseat",})
-- end

function ISSwitchVehicleSeat:perform()
    local motoInfo = nil
    if self.character:getVehicle() and self.character:getVehicle():getPartById("AMCConfig") then
        motoInfo = self.character:getVehicle():getPartById("AMCConfig"):getTable("AMCConfig")
    end
    if motoInfo then
        sendClientCommand(self.character, 'autotsaranim', 'updateVariables', {vehicle = self.character:getVehicle():getId(), seatId = self.character:getVehicle():getSeat(self.character), status = "none",})
        self.character:setVariable("ATVehicleType", motoInfo.type .. self.seatTo)
    end
    old_ISSwitchVehicleSeat_perform(self)
    if motoInfo then
        sendClientCommand(self.character, 'autotsaranim', 'updateVariables', {vehicle = self.character:getVehicle():getId(), seatId = self.seatTo, status = "stop",})
    end
end