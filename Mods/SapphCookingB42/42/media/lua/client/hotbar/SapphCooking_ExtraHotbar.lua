require "Hotbar/ISHotbarAttachDefinition"
if not ISHotbarAttachDefinition then
    return
end

--this code is for custom hotbars.

local ChefApronLeft = {
	type = "ChefApronLeft",
	name =  getText("IGUI_HotbarAttachment_ChefApronLeft"), -- Name shown in the slot icon
	animset = "belt right", --i did an goof ç~ç
	attachments = {
		Hammer = "ChefApronLeftHammer",-- defined in AttachedLocations.lua
		Screwdriver = "ChefApronLeftTools",
		Knife = "ChefApronLeft",
		MeatCleaver = "ChefApronLeftCleaver",
		Holster = "ChefApronLeftHolster",
	},
}

local ChefApronRight= {
	type = "ChefApronRight",
	name = getText("IGUI_HotbarAttachment_ChefApronRight"), -- Name shown in the slot icon
	animset = "belt left",
	attachments = {
		Hammer = "ChefApronRightHammer",-- defined in AttachedLocations.lua
		Screwdriver = "ChefApronRightTools",
		Knife = "ChefApronRight",
		MeatCleaver = "ChefApronRightCleaver",
	},
}

local ChefApronPencil = {
	type = "ChefApronPencil",
	name = getText("IGUI_HotbarAttachment_ChefApronPencil"), -- Name shown in the slot icon
	animset = "belt left",
	attachments = {
		Pencil = "ChefApronPencil",-- defined in AttachedLocations.lua
	},
}


table.insert(ISHotbarAttachDefinition, ChefApronLeft);
table.insert(ISHotbarAttachDefinition, ChefApronRight);
table.insert(ISHotbarAttachDefinition, ChefApronPencil);