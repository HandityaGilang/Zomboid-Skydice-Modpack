--This is written to batch inject container spawn rules for clothing and other items.
--Written by GanydeBielovzki for the Frockin' Splendor franchise and spin-offs.
--To copy,  modify or otherwise use this code the original creator must be credited.

require 'Items/ProceduralDistributions'

local function BatchRuleInjection(container, ...)
    for i = 1, select('#', ...), 2 do
        local item, weight = select(i, ...)
        table.insert(ProceduralDistributions.list[container].items, item)
        table.insert(ProceduralDistributions.list[container].items, weight)
    end
end

--Lootbox Injection
BatchRuleInjection("BedroomDresser",		"Box_FrockinStompersShoeBox", 4,		"Box_FrockinStompersShoeBoxLuxury", 3,		"Box_FrockinStompersShoeBoxLong", 2,	"Box_FrockinStompersShoeBoxLongLuxury", 2	)
BatchRuleInjection("WardrobeGeneric",		"Box_FrockinStompersShoeBox", 2,		"Box_FrockinStompersShoeBoxLuxury", 1,		"Box_FrockinStompersShoeBoxLong", 0.5,	"Box_FrockinStompersShoeBoxLongLuxury", 0.2	)
BatchRuleInjection("WardrobeRedneck",		"Box_FrockinStompersShoeBox", 4,		"Box_FrockinStompersShoeBoxLuxury", 2,		"Box_FrockinStompersShoeBoxLong", 1,	"Box_FrockinStompersShoeBoxLongLuxury", 1	)
BatchRuleInjection("WardrobeClassy",		"Box_FrockinStompersShoeBox", 4,		"Box_FrockinStompersShoeBoxLuxury", 2,		"Box_FrockinStompersShoeBoxLong", 1,	"Box_FrockinStompersShoeBoxLongLuxury", 1	)
BatchRuleInjection("ClosetShelfGeneric",	"Box_FrockinStompersShoeBox", 4,		"Box_FrockinStompersShoeBoxLuxury", 2,		"Box_FrockinStompersShoeBoxLong", 1,	"Box_FrockinStompersShoeBoxLongLuxury", 1	)

BatchRuleInjection("BackstageLockers",		"Box_FrockinStompersShoeBox", 4,		"Box_FrockinStompersShoeBoxLuxury", 2,		"Box_FrockinStompersShoeBoxLong", 3,	"Box_FrockinStompersShoeBoxLongLuxury", 3	)
BatchRuleInjection("BowlingAlleyLockers",	"Box_FrockinStompersShoeBox", 4,		"Box_FrockinStompersShoeBoxLuxury", 2,		"Box_FrockinStompersShoeBoxLong", 1,	"Box_FrockinStompersShoeBoxLongLuxury", 1	)
BatchRuleInjection("BoxingLockers",			"Box_FrockinStompersShoeBox", 4,		"Box_FrockinStompersShoeBoxLuxury", 2,		"Box_FrockinStompersShoeBoxLong", 1,	"Box_FrockinStompersShoeBoxLongLuxury", 1	)
BatchRuleInjection("GymLockers",			"Box_FrockinStompersShoeBox", 4,		"Box_FrockinStompersShoeBoxLuxury", 2,		"Box_FrockinStompersShoeBoxLong", 1,	"Box_FrockinStompersShoeBoxLongLuxury", 1	)
BatchRuleInjection("Locker",				"Box_FrockinStompersShoeBox", 4,		"Box_FrockinStompersShoeBoxLuxury", 2,		"Box_FrockinStompersShoeBoxLong", 1,	"Box_FrockinStompersShoeBoxLongLuxury", 1	)
BatchRuleInjection("BackstageDresser",		"Box_FrockinStompersShoeBox", 4,		"Box_FrockinStompersShoeBoxLuxury", 2,		"Box_FrockinStompersShoeBoxLong", 1,	"Box_FrockinStompersShoeBoxLongLuxury", 1	)

BatchRuleInjection("CrateClothesRandom",	"Box_FrockinStompersShoeBox", 20,		"Box_FrockinStompersShoeBoxLuxury", 20,		"Box_FrockinStompersShoeBoxLong", 20,	"Box_FrockinStompersShoeBoxLongLuxury", 20	)
BatchRuleInjection("CrateSports",			"Box_FrockinStompersShoeBox", 2,		"Box_FrockinStompersShoeBoxLuxury", 2,		"Box_FrockinStompersShoeBoxLong", 2,	"Box_FrockinStompersShoeBoxLongLuxury", 2	)
BatchRuleInjection("StripClubDressers",		"Box_FrockinStompersShoeBox", 10,		"Box_FrockinStompersShoeBoxLuxury", 10,		"Box_FrockinStompersShoeBoxLong", 10,	"Box_FrockinStompersShoeBoxLongLuxury", 10	)

    -- Add more containers as needed...

