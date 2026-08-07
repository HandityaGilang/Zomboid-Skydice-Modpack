--***********************************************************
--**                    THE INDIE STONE                    **
--***********************************************************

Refill = {}
Refill.OnCreate = {}
Refill.OnTest = {}

-- check when refilling the blowtorch that blowtorch is not full and propane tank not empty
function Refill.OnTest.RefillBlowTorch(item)
    if item:getType() == "BlowTorch" then
        if item:getUsedDelta() == 1 then return false; end
    elseif item:getType() == "PropaneTank" then
        if item:getUsedDelta() == 0 then return false; end
    end
    return true;
end

-- Fill entirely the blowtorch with the remaining propane
function Refill.OnCreate.RefillBlowTorch(items, result, player)
    local previousBT = nil;
    local propaneTank = nil;
    for i=0, items:size()-1 do
       if items:get(i):getType() == "BlowTorch" then
           previousBT = items:get(i);
       elseif items:get(i):getType() == "PropaneTank" then
           propaneTank = items:get(i);
       end
    end
    result:setUsedDelta(1);

end
