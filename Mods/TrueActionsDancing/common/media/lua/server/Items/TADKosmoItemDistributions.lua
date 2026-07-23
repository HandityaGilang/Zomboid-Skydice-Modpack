require 'Items/ProceduralDistributions'

local logDistrib = false
local function recplaceDistrib(distrib, newType, existingTypes)
    if not tab2str then tab2str = tostring end

    local replaced = 0
    if not distrib then
        print('ERROR replacing in distribution. Distribution list does not exist for location '..tostring(newType)..' '..tab2str(existingTypes))
    else
        for nameLocation, loc in pairs(distrib) do
            local items = loc.items
            local nbItems = items and #items or 0
            if nbItems > 1 then
                for i = nbItems-1, 1, -2 do
                    local itemName = items[i]
                    local ratioReplace = existingTypes[itemName]
                    if ratioReplace ~= nil and ratioReplace > 0 then
                        if ratioReplace > 1 then ratioReplace = 1 end
                        local weight = items[i + 1]
                        local newItemWeight = ratioReplace * weight
                        local existingItemNewWeight = weight-newItemWeight
                        
                        --replace existing item s weight
                        items[i + 1] = existingItemNewWeight
                        
                        -- Insert replacement right after the existing pair.
                        table.insert(items, i + 2, newType)
                        table.insert(items, i + 3, newItemWeight)
                        
                        replaced = replaced + 1
      if logDistrib then print('INFO replace distribution. '..tostring(nameLocation)..' from '..tostring(itemName)..' to '..tostring(newType)..': Moved '..tostring(newItemWeight)) end
                    end
                end
            end
        end
    end

    return replaced
end

local function addToDistrib(distrib,location,itemType,occurenceWeight)
    if not distrib then
        print('ERROR adding to distribution. Distribution list does not exist for location '..tostring(location)..' '..tostring(itemType))
    else
        local loc = distrib[location]
        if not loc then
            print('ERROR adding to distribution Location '..tostring(location)..' does not exist. Failing for '..tostring(itemType))
        else
            if not loc.items then
                print('WARNING adding to distribution Location '..tostring(location)..' item list empty. Failing for '..tostring(itemType))
                loc.items = {}
            end
            table.insert(loc.items,itemType)
            table.insert(loc.items,occurenceWeight)
        end
    end
end



local function backupDistrib()
    addToDistrib(ProceduralDistributions.list,"BreakRoomCounter","TAD.Kosmotsars",5)
    addToDistrib(ProceduralDistributions.list,"BreakRoomShelves","TAD.Kosmotsars",5)
    addToDistrib(ProceduralDistributions.list,"GigamartDryGoods","TAD.Kosmotsars",10)
    addToDistrib(ProceduralDistributions.list,"KitchenBreakfast","TAD.Kosmotsars",5)
    addToDistrib(ProceduralDistributions.list,"PrisonCellRandom","TAD.Kosmotsars",5)
    addToDistrib(ProceduralDistributions.list,"StoreShelfSnacks","TAD.Kosmotsars",5)
    addToDistrib(ProceduralDistributions.list,"TheatreSnacks","TAD.Kosmotsars",3)
    addToDistrib(VehicleDistributions,"SurvivalistTruckBed","TAD.Kosmotsars",8)
end


local function applyCerealReplacement()--TwistOnFire distrib replacement
    -- Replace 25% of all Cereal spawns with TAD.Kosmotsars (no extra loot added; weight is split).
    local total = 0
    local newType = "TAD.Kosmotsars"
    local existingTypes = {
        ["Cereal"] = 0.25,
        ["Base.Cereal"] = 0.25, -- just in case any table uses module prefix
    }
    if SuburbsDistributions then
        total = total + recplaceDistrib(SuburbsDistributions, newType, existingTypes)
    end
 
    if ProceduralDistributions and ProceduralDistributions.list then
        total = total + recplaceDistrib(ProceduralDistributions.list, newType, existingTypes)
    end
 
    if VehicleDistributions then
        total = total + recplaceDistrib(VehicleDistributions, newType, existingTypes)
    end
    
    if ClutterTables then
        total = total + recplaceDistrib(ClutterTables, newType, existingTypes)
    end

    if logDistrib then print("[TAD] Kosmotsars: replaced 25% of Cereal spawns (patched entries: "..tostring(total)..")") end
    if total <= 0 then--missing cereal item
        backupDistrib()
    end

end


Events.OnPostDistributionMerge.Add(applyCerealReplacement)