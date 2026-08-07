if not ISHotbarAttachDefinition then return end


local KATTAJ1_HipRightHolster = {
	type = "KATTAJ1hipRightHolster",
	name = "KATTAJ1 Right Hip Holster Slot",
	animset = "holster right",
	attachments = {
		Holster = "KATTAJ1 Hip Holster Right",
	},
}
table.insert(ISHotbarAttachDefinition, KATTAJ1_HipRightHolster);

local KATTAJ1_HipLeftHolster = {
	type = "KATTAJ1hipLeftHolster", -- The same name with attachment type in scripts/Items/AttachmentsProvided 
	name = "KATTAJ1 Left Hip Holster Slot", -- Name of slot in Game
	animset = "holster left", -- Animation
	attachments = {
		Holster = "KATTAJ1 Hip Holster Left", --  Holster is location property of an item. What attachment type can fit into this slot. KATTAJ1 Hip Holster Left is property of holster itself. Defined into shared.
	},
}
table.insert(ISHotbarAttachDefinition, KATTAJ1_HipLeftHolster);

local KATTAJ1_HipArmorRightHolster = {
	type = "KATTAJ1hipArmorRightHolster",
	name = "KATTAJ1 Right Hip Armor Holster Slot",
	animset = "holster right",
	attachments = {
		Holster = "KATTAJ1 Hip Armor Holster Right",
	},
}
table.insert(ISHotbarAttachDefinition, KATTAJ1_HipArmorRightHolster);

local KATTAJ1_HipArmorLeftHolster = {
	type = "KATTAJ1hipArmorLeftHolster",
	name = "KATTAJ1 Left Hip Armor Holster Slot",
	animset = "holster left",
	attachments = {
		Holster = "KATTAJ1 Hip Armor Holster Left",
	},	
}
table.insert(ISHotbarAttachDefinition, KATTAJ1_HipArmorLeftHolster);

local KATTAJ1_BeltRightHolster = {
	type = "KATTAJ1beltRightHolster",
	name = "KATTAJ1 Right Belt Holster Slot",
	animset = "holster right",
	attachments = {
		Holster = "KATTAJ1 Belt Holster Right",
	},
}
table.insert(ISHotbarAttachDefinition, KATTAJ1_BeltRightHolster);

local KATTAJ1_BeltLeftHolster = {
	type = "KATTAJ1beltLeftHolster", -- The same name with attachment type in scripts/Items/AttachmentsProvided 
	name = "KATTAJ1 Left Belt Holster Slot", -- Name of slot in Game
	animset = "holster left", -- Animation
	attachments = {
		Holster = "KATTAJ1 Belt Holster Left", --  Holster is location property of an item. What attachment type can fit into this slot. KATTAJ1 Hip Holster Left is property of holster itself. Defined into shared.
	},
}
table.insert(ISHotbarAttachDefinition, KATTAJ1_BeltLeftHolster);


local KATTAJ1_HipRightSheath = {
	type = "KATTAJ1hipRightSheath",
	name = "KATTAJ1 Right Hip Sheath Slot",
	animset = "holster right",
	attachments = {
		Knife = "KATTAJ1 Hip Sheath Right",
	},
}
table.insert(ISHotbarAttachDefinition, KATTAJ1_HipRightSheath);

local KATTAJ1_HipLeftSheath = {
	type = "KATTAJ1hipLeftSheath", -- The same name with attachment type in scripts/Items/AttachmentsProvided 
	name = "KATTAJ1 Left Hip Sheath Slot", -- Name of slot in Game
	animset = "holster left", -- Animation
	attachments = {
		Knife = "KATTAJ1 Hip Sheath Left", --  Knife is location property of an item. What attachment type can fit into this slot. KATTAJ1 Hip Sheath Left is property of holster itself. Defined into shared.
	},
}
table.insert(ISHotbarAttachDefinition, KATTAJ1_HipLeftSheath);

local KATTAJ1_HipArmorRightSheath = {
	type = "KATTAJ1hipArmorRightSheath",
	name = "KATTAJ1 Right Hip Armor Sheath Slot",
	animset = "holster right",
	attachments = {
		Knife = "KATTAJ1 Hip Armor Sheath Right",
	},
}
table.insert(ISHotbarAttachDefinition, KATTAJ1_HipArmorRightSheath);

local KATTAJ1_HipArmorLeftSheath = {
	type = "KATTAJ1hipArmorLeftSheath",
	name = "KATTAJ1 Left Hip Armor Sheath Slot",
	animset = "holster left",
	attachments = {
		Knife = "KATTAJ1 Hip Armor Sheath Left",
	},	
}
table.insert(ISHotbarAttachDefinition, KATTAJ1_HipArmorLeftSheath);

local KATTAJ1_BeltRightSheath = {
	type = "KATTAJ1beltRightSheath",
	name = "KATTAJ1 Right Belt Sheath Slot",
	animset = "holster right",
	attachments = {
		Knife = "KATTAJ1 Belt Sheath Right",
	},
}
table.insert(ISHotbarAttachDefinition, KATTAJ1_BeltRightSheath);

local KATTAJ1_BeltLeftSheath = {
	type = "KATTAJ1beltLeftSheath", -- The same name with attachment type in scripts/Items/AttachmentsProvided 
	name = "KATTAJ1 Left Belt Sheath Slot", -- Name of slot in Game
	animset = "holster left", -- Animation
	attachments = {
		Knife = "KATTAJ1 Belt Sheath Left", --  Knife is location property of an item. What attachment type can fit into this slot. KATTAJ1 Hip Sheath Left is property of holster itself. Defined into shared.
	},
}
table.insert(ISHotbarAttachDefinition, KATTAJ1_BeltLeftSheath);


local KATTAJ1_BackSheath = {
	type = "KATTAJ1BackSheath", -- The same name with attachment type in scripts/Items/AttachmentsProvided 
	name = "KATTAJ1 Back Sheath Slot", -- Name of slot in Game
	animset = "holster left", -- Animation
	attachments = {
		Knife = "KATTAJ1 Belt Sheath Back", --  Knife is location property of an item. What attachment type can fit into this slot. KATTAJ1 Hip Sheath Left is property of holster itself. Defined into shared.
	},
}
table.insert(ISHotbarAttachDefinition, KATTAJ1_BackSheath);