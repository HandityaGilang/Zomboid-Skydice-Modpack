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
		Knife = "RightGrenadeSlotOther",
		Hammer = "RightGrenadeSlotOther",
		HammerRotated = "RightGrenadeSlotOther",
		Nightstick = "RightGrenadeSlotOther",
		Screwdriver  = "RightGrenadeSlotOther",
		Wrench = "RightGrenadeSlotOther",
		MeatCleaver = "RightGrenadeSlotOther",
		Walkie = "RightGrenadeSlotOther",
	},
}
local LeftGrenadeSlot = {
	type = "LeftGrenadeSlot",
	name = "Left Grenade Slot",
	animset = "holster left",
	attachments = {
		GrenadePouch = "LeftGrenadeSlot",
		Knife = "LeftGrenadeSlotOther",
		Hammer = "LeftGrenadeSlotOther",
		HammerRotated = "LeftGrenadeSlotOther",
		Nightstick = "LeftGrenadeSlotOther",
		Screwdriver  = "LeftGrenadeSlotOther",
		Wrench = "LeftGrenadeSlotOther",
		MeatCleaver = "LeftGrenadeSlotOther",
		Walkie = "LeftGrenadeSlotOther",
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