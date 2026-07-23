local oldOnTakeEngineParts = ISVehicleMechanics.onTakeEngineParts
local oldOnRepairEngine = ISVehicleMechanics.onRepairEngine
local olddoDrawItem = ISVehicleMechanics.doDrawItem

function ISVehicleMechanics.onTakeEngineParts(playerObj, part)
	if not part:getVehicle():getModData().tuning or not part:getVehicle():getModData().tuning[part:getId()] then
		oldOnTakeEngineParts(playerObj, part)
	elseif part:getVehicle():getModData().tuning[part:getId()].health then
		playerObj:Say(getText("IGUI_PlayerText_ATA_Engine"))
	end
end


function ISVehicleMechanics.onRepairEngine(playerObj, part)
	if not part:getVehicle():getModData().tuning or not part:getVehicle():getModData().tuning[part:getId()] then
		oldOnRepairEngine(playerObj, part)
	elseif part:getVehicle():getModData().tuning[part:getId()].health then
		playerObj:Say(getText("IGUI_PlayerText_ATA_Engine"))
	end
end

ATA = ATA or {}

ATA.moddedBatteries = ATA.moddedBatteries or {}
function ATA.isModdedBattery(partID)
    return ATA.moddedBatteries[partID]
end

ATA.moddedFuelTanks = ATA.moddedFuelTanks or {}
ATA.moddedFuelTanks["500FuelTank"] = true
ATA.moddedFuelTanks["1000FuelTank"] = true

function ATA.isModdedFuelTank(partID)
    return ATA.moddedFuelTanks[partID]
end

function ISVehicleMechanics:doDrawItem(y, item, alt)
    local partID = not item.item.cat and item.item.part and item.item.part:getId()
    local isModdedBattery = partID and ATA.isModdedBattery(partID)
    local isModdedFuelTank = not isModdedBattery and ATA.isModdedFuelTank(partID)
    if isModdedBattery or isModdedFuelTank then
        if not item.item.cat then
            if item.itemindex == self.selected then
                self:drawRect(0, y, self:getWidth(), item.height, 0.1, 1.0, 1.0, 1.0);
            elseif item.itemindex == self.mouseoverselected and ((self.parent.context and not self.parent.context:isVisible()) or not self.parent.context) then
                self:drawRect(0, y, self:getWidth(), item.height, 0.05, 1.0, 1.0, 1.0);
            end
        end

        if item.item.cat then
            self:drawText(item.item.name, 0, y, self.parent.partCatRGB.r, self.parent.partCatRGB.g, self.parent.partCatRGB.b, self.parent.partCatRGB.a, UIFont.Medium);
            y = y + 5;
        else
            local rgb = self.parent.partRGB;
            if not item.item.part:getInventoryItem() and item.item.part:getTable("install") then
                local badColor = getCore():getBadHighlitedColor()
                self:drawText(item.item.name, 20, y, badColor:getR(), badColor:getG(), badColor:getB(), 1, UIFont.Small);
            else
                self:drawText(item.item.name, 20, y, rgb.r, rgb.g, rgb.b, rgb.a, UIFont.Small);
                local charge = ""
                local tm = getTextManager()
                if isModdedBattery then
                    local amount = (math.floor(item.item.part:getInventoryItem():getCurrentUsesFloat() * 100))
                    charge = ": " .. amount .. "% " .. getText("IGUI_invpanel_Remaining")
                    self:drawText(charge, tm:MeasureStringX(UIFont.Small, item.item.name) + 20, y, rgb.r, rgb.g, rgb.b, rgb.a, UIFont.Small);
                elseif isModdedFuelTank then
                    local amount = (math.floor(item.item.part:getContainerContentAmount() / item.item.part:getContainerCapacity() * 100))
                    charge = ": " .. amount .. "% " .. getText("IGUI_invpanel_Remaining")
                    self:drawText(charge, tm:MeasureStringX(UIFont.Small, item.item.name) + 20, y, rgb.r, rgb.g, rgb.b, rgb.a, UIFont.Small);
                end
                -- print("NAME..................  " .. tostring(item.item.name))
                local condition = item.item.part:getCondition();
                local invItm = item.item.part:getInventoryItem();
                local condRGB = self.parent:getConditionRGB(condition);
                -- self:drawText(" (" .. condition .. "%)", tm:MeasureStringX(UIFont.Small, item.item.name) + 22, y, condRGB.r, condRGB.g, condRGB.b, rgb.a, UIFont.Small)
                self:drawText(" (" .. condition .. "%)", tm:MeasureStringX(UIFont.Small, item.item.name) + tm:MeasureStringX(UIFont.Small, charge) + 22, y, condRGB.r, condRGB.g, condRGB.b, rgb.a, UIFont.Small)
            end
        end

        return y + self.itemheight;
    else
        return olddoDrawItem(self, y, item, alt)
    end
end
