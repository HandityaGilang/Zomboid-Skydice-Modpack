
local overlayMap = {}
overlayMap.VERSION = 1
--edited out with new sprite system added
--[[
overlayMap["appliances_laundry_01_26"] = {{ name = "other", tiles = {"clothingLineTiles_0","clothingLineTiles_0"}},{ name = "other", tiles = {"clothingLineTiles_1","clothingLineTiles_1"}},{ name = "other", tiles = {"clothingLineTiles_2","clothingLineTiles_2"}},{ name = "other", tiles = {"clothingLineTiles_3","clothingLineTiles_3"}},{ name = "other", tiles = {"clothingLineTiles_4","clothingLineTiles_4"}},{ name = "other", tiles = {"clothingLineTiles_5","clothingLineTiles_5"}},{ name = "other", tiles = {"clothingLineTiles_6","clothingLineTiles_6"}},{ name = "other", tiles = {"clothingLineTiles_7","clothingLineTiles_7"}}}
overlayMap["appliances_laundry_01_27"] = {{ name = "other", tiles = {"clothingLineTiles_8","clothingLineTiles_8"}},{ name = "other", tiles = {"clothingLineTiles_9","clothingLineTiles_9"}},{ name = "other", tiles = {"clothingLineTiles_10","clothingLineTiles_10"}},{ name = "other", tiles = {"clothingLineTiles_11","clothingLineTiles_11"}},{ name = "other", tiles = {"clothingLineTiles_12","clothingLineTiles_12"}},{ name = "other", tiles = {"clothingLineTiles_13","clothingLineTiles_13"}},{ name = "other", tiles = {"clothingLineTiles_14","clothingLineTiles_14"}},{ name = "other", tiles = {"clothingLineTiles_15","clothingLineTiles_15"}}}
overlayMap["appliances_laundry_01_28"] = {{ name = "other", tiles = {"clothingLineTiles_16","clothingLineTiles_16"}},{ name = "other", tiles = {"clothingLineTiles_17","clothingLineTiles_17"}},{ name = "other", tiles = {"clothingLineTiles_18","clothingLineTiles_18"}},{ name = "other", tiles = {"clothingLineTiles_19","clothingLineTiles_19"}},{ name = "other", tiles = {"clothingLineTiles_20","clothingLineTiles_20"}},{ name = "other", tiles = {"clothingLineTiles_21","clothingLineTiles_21"}},{ name = "other", tiles = {"clothingLineTiles_22","clothingLineTiles_22"}},{ name = "other", tiles = {"clothingLineTiles_23","clothingLineTiles_23"}}}
overlayMap["appliances_laundry_01_29"] = {{ name = "other", tiles = {"clothingLineTiles_24","clothingLineTiles_24"}},{ name = "other", tiles = {"clothingLineTiles_25","clothingLineTiles_25"}},{ name = "other", tiles = {"clothingLineTiles_26","clothingLineTiles_26"}},{ name = "other", tiles = {"clothingLineTiles_27","clothingLineTiles_27"}},{ name = "other", tiles = {"clothingLineTiles_28","clothingLineTiles_28"}},{ name = "other", tiles = {"clothingLineTiles_29","clothingLineTiles_29"}},{ name = "other", tiles = {"clothingLineTiles_30","clothingLineTiles_30"}},{ name = "other", tiles = {"clothingLineTiles_31","clothingLineTiles_31"}}}
overlayMap["appliances_laundry_01_30"] = {{ name = "other", tiles = {"clothingLineTiles_32","clothingLineTiles_32"}},{ name = "other", tiles = {"clothingLineTiles_33","clothingLineTiles_33"}},{ name = "other", tiles = {"clothingLineTiles_34","clothingLineTiles_34"}},{ name = "other", tiles = {"clothingLineTiles_35","clothingLineTiles_35"}},{ name = "other", tiles = {"clothingLineTiles_36","clothingLineTiles_36"}},{ name = "other", tiles = {"clothingLineTiles_37","clothingLineTiles_37"}},{ name = "other", tiles = {"clothingLineTiles_38","clothingLineTiles_38"}},{ name = "other", tiles = {"clothingLineTiles_39","clothingLineTiles_39"}}}
overlayMap["appliances_laundry_01_31"] = {{ name = "other", tiles = {"clothingLineTiles_40","clothingLineTiles_40"}},{ name = "other", tiles = {"clothingLineTiles_41","clothingLineTiles_41"}},{ name = "other", tiles = {"clothingLineTiles_42","clothingLineTiles_42"}},{ name = "other", tiles = {"clothingLineTiles_43","clothingLineTiles_43"}},{ name = "other", tiles = {"clothingLineTiles_44","clothingLineTiles_44"}},{ name = "other", tiles = {"clothingLineTiles_45","clothingLineTiles_45"}},{ name = "other", tiles = {"clothingLineTiles_46","clothingLineTiles_46"}},{ name = "other", tiles = {"clothingLineTiles_47","clothingLineTiles_47"}}}
--]]
--clotheshorse will use this system until more sprites are made for it
overlayMap["clothesHorse_0"] = {{ name = "other", tiles = {"clothesHorse_1"}}}
overlayMap["clothesHorse_2"] = {{ name = "other", tiles = {"clothesHorse_3"}}}
if not TILEZED then
	getContainerOverlays():addOverlays(overlayMap)
end
return overlayMap



