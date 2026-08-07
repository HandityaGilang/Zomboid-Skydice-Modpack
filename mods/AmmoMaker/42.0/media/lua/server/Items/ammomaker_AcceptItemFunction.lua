--Ammo Maker by STIMP_TM

function AcceptItemFunction.BrassCatcher(container, item)
	return item:hasTag("ammomaker_FiredCasing") or ammoMakerGetDropExtraDataItemTypes()[item:getFullType()]
end