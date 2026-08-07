require "Items/Distributions"

local vendItems = {};

local function locate(t,value)
    for k,_ in pairs(t) do
        if k == value then
			return true
		end
    end
end

if locate(Distributions,"all") then -- default distribution table
	if locate(Distributions["all"],"vendingpop") and locate(Distributions["all"],"vendingsnack") then
		vendItems = Distributions["all"]["vendingpop"]["items"];
		for i=#vendItems-1,1,-2 do
			table.remove(vendItems,i);
			table.remove(vendItems,i);
		end
		vendItems = Distributions["all"]["vendingsnack"]["items"];
		for i=#vendItems-1,1,-2 do
			table.remove(vendItems,i);
			table.remove(vendItems,i);
		end
	end
else -- nested distribution table
	for k,_ in pairs(Distributions) do
		if locate(Distributions[k],"all") then
			if locate(Distributions[k]["all"],"vendingpop") and locate(Distributions[k]["all"],"vendingsnack") then
				vendItems = Distributions[k]["all"]["vendingpop"]["items"];
				for i=#vendItems-1,1,-2 do
					table.remove(vendItems,i);
					table.remove(vendItems,i);
				end
				vendItems = Distributions[k]["all"]["vendingsnack"]["items"];
				for i=#vendItems-1,1,-2 do
					table.remove(vendItems,i);
					table.remove(vendItems,i);
				end
				break
			end
		end
	end
end