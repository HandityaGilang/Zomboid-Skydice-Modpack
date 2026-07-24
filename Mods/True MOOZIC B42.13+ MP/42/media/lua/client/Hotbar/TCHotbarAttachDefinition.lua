require "Hotbar/ISHotbarAttachDefinition"

if not ISHotbarAttachDefinition then
    return
end

local MOD_DATA = {
	SmallBeltLeft = {
		TCWalkman = "TCWalkman Belt Left",
	},
	SmallBeltRight = {
		TCWalkman = "TCWalkman Belt Right",
	},
}
for _,t in pairs(ISHotbarAttachDefinition) do
	if t.type and MOD_DATA[t.type] then
		for k,v in pairs(MOD_DATA[t.type]) do
			if v == 0 and t.replacement then
				t.replacement[k] = nil
			elseif t.attachments then
				t.attachments[k] = v ~= 0 and v or nil
			end
		end
	end
end 