--Codebase by Yuhiko and his/her mod BodyLocationsTweaker API. All credit of this functionality goes to him/her. 
require "NPCs/BodyLocations" 



local function customGetVal(obj, int) return getClassFieldVal(obj, getClassField(obj, int)); end
local BodyLocationsTweaker = {}; 

BodyLocationsTweaker.group = BodyLocations.getGroup("Human");
BodyLocationsTweaker.list = customGetVal(BodyLocationsTweaker.group, 1); 

function BodyLocationsTweaker:moveOrCreateBeforeOrAfter(toRelocateOrCreate, locationElement, afterBoolean)

    if type(locationElement) ~= "string" then error("Argument 2 is not of type string. Please re-check!", 2); end
    local itemToMoveTo = self.group:getLocation(locationElement); 
    if itemToMoveTo ~= nil then
        
        if type(toRelocateOrCreate) ~= "string" then error("Argument 1 is not of type string. Please re-check!", 2) end
        local curItem = self.group:getOrCreateLocation(toRelocateOrCreate); 
        self.list:remove(curItem); 
        local index = self.group:indexOf(locationElement); 
        if afterBoolean then index = index + 1; end 
        self.list:add(index, curItem); 
        return curItem;
    else 
        error("Could not find the BodyLocation [",locationElement,"] - please check the passed arguments!", 2);
    end
end


function BodyLocationsTweaker:moveOrCreateBefore(toRelocateOrCreate, locationElement) -- for simpler and clearer usage
    return self:moveOrCreateBeforeOrAfter(toRelocateOrCreate, locationElement, false);
end

 BodyLocationsTweaker:moveOrCreateBefore("KIU3", "UnderwearExtra1");
 BodyLocationsTweaker:moveOrCreateBefore("KIU2", "UnderwearExtra1");
 BodyLocationsTweaker:moveOrCreateBefore("KIU1", "UnderwearExtra1");
 BodyLocationsTweaker:moveOrCreateBefore("KIU0", "UnderwearExtra1");
 BodyLocationsTweaker:moveOrCreateBefore("KIUA", "Hat");
 BodyLocationsTweaker:moveOrCreateBefore("KIUB", "Hat");
 BodyLocationsTweaker:moveOrCreateBefore("KIUC", "Hat");
 
 BodyLocationsTweaker:moveOrCreateBefore("KIUX", "Sweater");



 local group = BodyLocations.getGroup("Human")
 group:setExclusive("TankTop", "KIUX")