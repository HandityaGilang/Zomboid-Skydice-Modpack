--Ammo Maker by STIMP_TM

local ammomakerRegistries = require("ammomaker_Registries");

function AcceptItemFunction.BrassCatcher(container, item)
	return item:hasTag(ammomakerRegistries.tags.FIREDCASING) or ammoMakerGetDropExtraDataItemTypes()[item:getFullType()]
end