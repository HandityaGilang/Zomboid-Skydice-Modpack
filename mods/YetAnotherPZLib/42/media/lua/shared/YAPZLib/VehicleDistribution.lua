local __utils = require("YAPZLib/Utils")

local vehicleDistribution = {}

vehicleDistribution.copy = function(vehicleDistribution)
	if not __utils.checkArgs(vehicleDistribution, "string", true) then return end

	local distTable = VehicleDistributions[vehicleDistribution]
	if not distTable then return end
	
	return __utils.copyTable(distTable)
end

vehicleDistribution.find = function(vehicleDistribution, itemName, doJunk)
	if not __utils.checkArgs(
		vehicleDistribution, "string", true,
		itemName, "string", true,
		doJunk, "boolean", false
	) then return end

	if not VehicleDistributions[vehicleDistribution] then return end
	
	local distibutionTable
	if doJunk == true then
		distibutionTable = VehicleDistributions[vehicleDistribution].junk.items
	else
		distibutionTable = VehicleDistributions[vehicleDistribution].items
	end
	
	if not distibutionTable then return end
	for _, i in ipairs(distibutionTable) do
		if i == itemName then
			return true
		end
	end
	
	return false
end

vehicleDistribution.remove = function(vehicleDistribution, itemName, doJunk)
	if not __utils.checkArgs(
		vehicleDistribution, "string", true,
		itemName, "string", true,
		doJunk, "boolean", false
	) then return end

	if not VehicleDistributions[vehicleDistribution] then return end
	
	local distibutionTable
	if doJunk == true then
		distibutionTable = VehicleDistributions[vehicleDistribution].junk.items
	else
		distibutionTable = VehicleDistributions[vehicleDistribution].items
	end
	
	if not distibutionTable then return end
	
	local i = 1
    while i <= #distibutionTable do
        if distibutionTable[i] == itemName then
            table.remove(distibutionTable, i)
            table.remove(distibutionTable, i) 
        else
            i = i + 2
        end
    end
end

vehicleDistribution.add = function(vehicleDistribution, itemName, itemChance, doJunk)
	if not __utils.checkArgs(
		vehicleDistribution, "string", true,
		itemName, "string", true,
		itemChance, "number", true,
		doJunk, "boolean", false
	) then return end

	if not VehicleDistributions[vehicleDistribution] then return end
	
	local distibutionTable
	if doJunk == true then
		distibutionTable = VehicleDistributions[vehicleDistribution].junk.items
	else
		distibutionTable = VehicleDistributions[vehicleDistribution].items
	end
	
	if not distibutionTable then return end
	
	table.insert(distibutionTable, itemName)
	table.insert(distibutionTable, itemChance)
end

return vehicleDistribution