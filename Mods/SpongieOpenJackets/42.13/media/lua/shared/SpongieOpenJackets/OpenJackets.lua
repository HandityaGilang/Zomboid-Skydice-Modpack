
local OpenJackets_ItemTweaker = require("SpongieOpenJackets/OpenJackets_ItemTweaker")



local openAndRolledShirts = {
    --jackets
	"Jacket_WhiteTINT",
	"Jacket_NavyBlue",
	"Jacket_Fireman",
	"Jacket_Chef",
	"Jacket_ArmyCamoDesert",
	"Jacket_ArmyCamoGreen",
	"Jacket_CoatArmy",
	"Jacket_Police",
	"Jacket_Ranger",
	"Jacket_Varsity",
	"JacketLong_Doctor",
	"JacketLong_Random",
	"JacketLong_Santa",
	"JacketLong_SantaGreen",
	"Jacket_Black",
	"Jacket_LeatherWildRacoons",
	"Jacket_LeatherIronRodent",
	"Jacket_LeatherBarrelDogs",
	"WeddingJacket",
	"Suit_Jacket",
	"Suit_JacketTINT",
	"Jacket_Shellsuit_Black",
	"Jacket_Shellsuit_Blue",
	"Jacket_Shellsuit_Green",
	"Jacket_Shellsuit_Pink",
	"Jacket_Shellsuit_Teal",
	"Jacket_Shellsuit_TINT",

    --shirts
    "Shirt_CamoUrban",
    "Shirt_CamoDesert",
    "Shirt_CamoGreen",
    "Shirt_Denim",
    "Shirt_Lumberjack",
    "Shirt_OfficerWhite",
    "Shirt_PoliceBlue",
    "Shirt_PoliceGrey",
    "Shirt_PrisonGuard",
    "Shirt_Priest",
    "Shirt_Ranger",
    "Shirt_FormalTINT",
    "Shirt_FormalWhite",
    "Shirt_Workman",
    "Shirt_Jockey01",
    "Shirt_Jockey02",
    "Shirt_Jockey03",
    "Shirt_Jockey04",
    "Shirt_Jockey05",
    "Shirt_Jockey06",
}

local OpenAndTiedCoveralls = {
    "Boilersuit",
    "Boilersuit_BlueRed",
    "Boilersuit_Yellow",
    "Boilersuit_Flying",
    "Boilersuit_Prisoner",
    "Boilersuit_PrisonerKhaki",
}

local TuckedPants = {
    "Trousers",
    "TrousersMesh_DenimLight",
    "Trousers_LeatherBlack",
    "Trousers_CamoDesert",
    "Trousers_CamoGreen",
    "Trousers_CamoUrban",
    "Trousers_Chef",
    "Trousers_Denim",
    "Trousers_Fireman",
    "Trousers_JeanBaggy",
    "Trousers_Padded",
    "Trousers_Police",
    "Trousers_PoliceGrey",
    "Trousers_PrisonGuard",
    "Trousers_Ranger",
    "Trousers_Scrubs",
    "Trousers_Scrubs",
    "Trousers_Suit",
    "Trousers_SuitWhite",
    "Trousers_WhiteTINT",
    "Trousers_ArmyService",
    "Trousers_Black",
    "Trousers_NavyBlue",
}

local OpenShirts = {
    -- shirts
    "Shirt_Bowling_Blue",
    "Shirt_Bowling_Brown",
    "Shirt_Bowling_Green",
    "Shirt_Bowling_LimeGreen",
    "Shirt_Bowling_Pink",
    "Shirt_Bowling_White",
    "Shirt_Baseball_KY",
    "Shirt_Baseball_Rangers",
    "Shirt_Baseball_Z",
    "Shirt_FormalWhite_ShortSleeve",
    "Shirt_FormalWhite_ShortSleeveTINT",
    "Shirt_HawaiianRed",
    "Shirt_HawaiianTINT",
    "Tshirt_PoliceBlue",
    "Tshirt_PoliceGrey",
    "Tshirt_Ranger",
    
    -- ripped vests
    "Shirt_DenimVest",
    "Shirt_LumberjackVest",
    
    -- vests
    "Vest_HighViz",
    "Vest_Foreman",
    "Vest_Hunting_CamoGreen",
    "Vest_Hunting_Camo",
    "Vest_Hunting_Orange",
    "Vest_Hunting_Grey",
    "Vest_Waistcoat_GigaMart",
    "Vest_WaistcoatTINT",
    "Vest_Waistcoat",
}

local RolledShirts = {
    "Tshirt_WhiteLongSleeve",
    "Tshirt_WhiteLongSleeveTINT",
    "Shirt_Scrubs",
}

local RolledAndTiedSweaters = {
    "Jumper_DiamondPatternTINT",
    "Jumper_PoloNeck",
    "Jumper_RoundNeck",
    "Jumper_VNeck",
}

local UpAndDownDungarees = {
    "Dungarees",
}


-- hoodies dont follow name format
OpenJackets_ItemTweaker.AddOpenAndTiedHoodie("HoodieUP_WhiteTINT", "HoodieDOWN_WhiteTINT", "Hoodie_WhiteTINTTIED");


for i,v in ipairs(openAndRolledShirts) do
	OpenJackets_ItemTweaker.AddOpenAndRolledShirt(v);
end
for i,v in ipairs(OpenAndTiedCoveralls) do
	OpenJackets_ItemTweaker.AddOpenAndTiedCoveralls(v);
end
for i,v in ipairs(TuckedPants) do
	OpenJackets_ItemTweaker.AddTuckedPants(v);
end
for i,v in ipairs(OpenShirts) do
	OpenJackets_ItemTweaker.AddOpenShirt(v);
end
for i,v in ipairs(RolledShirts) do
	OpenJackets_ItemTweaker.AddRolledShirt(v);
end
for i,v in ipairs(RolledAndTiedSweaters) do
	OpenJackets_ItemTweaker.AddRolledAndTiedSweater(v);
end
for i,v in ipairs(UpAndDownDungarees) do
	OpenJackets_ItemTweaker.AddUpAndDownDungarees(v);
end
