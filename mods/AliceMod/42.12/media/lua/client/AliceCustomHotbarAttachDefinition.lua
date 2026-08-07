local RightCanteenSlot = {
	type = "RightCanteenSlot",
	name = "Right Canteen Slot",
	animset = "holster right",
	attachments = {
		AliceCanteenSlot = "RightCanteenSlot",
	},
}
local LeftCanteenSlot = {
	type = "LeftCanteenSlot",
	name = "Left Canteen Slot",
	animset = "holster left",
	attachments = {
		AliceCanteenSlot = "LeftCanteenSlot",
	},
}
local RightGrenadeSlot = {
	type = "RightGrenadeSlot",
	name = "Right Grenade Slot",
	animset = "holster right",
	attachments = {
		GrenadePouch = "RightGrenadeSlot",
	},
}
local LeftGrenadeSlot = {
	type = "LeftGrenadeSlot",
	name = "Left Grenade Slot",
	animset = "holster left",
	attachments = {
		GrenadePouch = "LeftGrenadeSlot",
	},
}
local M9BayonetSlot = {
	type = "M9BayonetSlot",
	name = "M9 Bayonet Slot",
	animset = "holster right",
	attachments = {
		M9Sheath = "M9BayonetSlot",
	},
}
table.insert(ISHotbarAttachDefinition, RightCanteenSlot)
table.insert(ISHotbarAttachDefinition, LeftCanteenSlot)
table.insert(ISHotbarAttachDefinition, RightGrenadeSlot)
table.insert(ISHotbarAttachDefinition, LeftGrenadeSlot)
table.insert(ISHotbarAttachDefinition, M9BayonetSlot)