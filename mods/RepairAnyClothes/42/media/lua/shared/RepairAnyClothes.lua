function RepairAnyClothes()


    local items = getAllItems();
    for i = 0, items:size() - 1 do
        local item = items:get(i);

 
        local fabricType = nil;
        if item.getFabricType and type(item.getFabricType) == "function" then
            fabricType = item:getFabricType();
        end

        if item.getBloodClothingType and type(item.getBloodClothingType) == "function" then
            local bloodClothingType = item:getBloodClothingType();
            if BloodClothingType and BloodClothingType.getCoveredPartCount then
                local NbrOfCoveredParts = BloodClothingType.getCoveredPartCount(bloodClothingType);
                if fabricType == nil and NbrOfCoveredParts > 0 then
                    item:DoParam("FabricType = Leather")
                end
            end
        end
    end
end
    Events.OnGameBoot.Add(RepairAnyClothes);

