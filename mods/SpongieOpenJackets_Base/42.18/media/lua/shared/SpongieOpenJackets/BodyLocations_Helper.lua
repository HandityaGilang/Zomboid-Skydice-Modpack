local BodyLocations_Helper = {}

BodyLocations_Helper.group = BodyLocations.getGroup("Human")
function BodyLocations_Helper:AddLocation(name, i)
	self.group:getOrCreateLocation(name)
	self.group:moveLocationToIndex(name, i)
end
function BodyLocations_Helper:SetExclusive(name, list)
    for i, v in ipairs(list) do
        self.group:setExclusive(name, v)
    end
end
function BodyLocations_Helper:SetHidden(name, list)
    for i, v in ipairs(list) do
        self.group:setHideModel(name, v)
    end
end
function BodyLocations_Helper:SetAltModel(name, list)
    for i, v in ipairs(list) do
        self.group:setAltModel(name, v)
    end
end

return BodyLocations_Helper