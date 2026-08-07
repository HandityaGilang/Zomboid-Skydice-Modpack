--at 988, 6900 is a "" (parkingstall), ParkingStall that is a TRAPEZOID VEHICLE ZONE IN THE MIDDLE OF NO WHERE! It auto fills the corners to turn it into a rectangle in the code somewhere.

--test
	--{ name = "null", type = "ParkingStall", x = 17106, y = 532, z = 0, width = 288, height = 5, properties = { Direction = "N", FaceDirection = true } },

--LV

local newTrafficLV = {
--ROADS TO LV
	{ name = "trafficjamn", type = "ParkingStall", x = 12506, y = 4362, z = 0, width = 3, height = 115, properties = { Direction = "N", FaceDirection = true } },
	{ name = "modified_trfjm", type = "ParkingStall", x = 12509, y = 4367, z = 0, width = 3, height = 125, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 12509, y = 4367, z = 0, width = 3, height = 125, properties = { Direction = "N", FaceDirection = true } }, --dupe to fill gaps
	{ name = "modified_trfjm", type = "ParkingStall", x = 12512, y = 4372, z = 0, width = 3, height = 120, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 12512, y = 4372, z = 0, width = 3, height = 120, properties = { Direction = "N", FaceDirection = true } }, --dupe to fill gaps
	{ name = "modified_trfjm", type = "ParkingStall", x = 12515, y = 4372, z = 0, width = 3, height = 120, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 12515, y = 4372, z = 0, width = 3, height = 120, properties = { Direction = "N", FaceDirection = true } }, --dupe to fill gaps
	{ name = "trafficjamn", type = "ParkingStall", x = 12518, y = 4367, z = 0, width = 3, height = 110, properties = { Direction = "N", FaceDirection = true } },

	{ name = "trafficjamn", type = "ParkingStall", x = 13418, y = 4091, z = 0, width = 12, height = 18, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 13418, y = 4115, z = 0, width = 3, height = 12, properties = { Direction = "N", FaceDirection = true } },
	{ name = "modified_trfjm", type = "ParkingStall", x = 13421, y = 4115, z = 0, width = 3, height = 24, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 13421, y = 4115, z = 0, width = 3, height = 24, properties = { Direction = "N", FaceDirection = true } }, --dupe to fill gaps
	{ name = "modified_trfjm", type = "ParkingStall", x = 13424, y = 4115, z = 0, width = 3, height = 24, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 13424, y = 4115, z = 0, width = 3, height = 24, properties = { Direction = "N", FaceDirection = true } }, --dupe to fill gaps
	{ name = "trafficjamn", type = "ParkingStall", x = 13427, y = 4115, z = 0, width = 3, height = 12, properties = { Direction = "N", FaceDirection = true } },

	{ name = "trafficjamn", type = "ParkingStall", x = 14529, y = 4037, z = 0, width = 12, height = 24, properties = { Direction = "N", FaceDirection = true } },

--NORTH BRIDGE
	{ name = "modified_trfjm", type = "ParkingStall", x = 12599, y = 1274, z = 0, width = 6, height = 1000, properties = { Direction = "N", FaceDirection = true } },
	{ name = "modified_trfjm", type = "ParkingStall", x = 12593, y = 1274, z = 0, width = 6, height = 1000, properties = { Direction = "S", FaceDirection = true } },
	{ name = "modified_trfjm", type = "ParkingStall", x = 12506, y = 1241, z = 0, width = 5, height = 1100, properties = { Direction = "N", FaceDirection = true } },
	{ name = "modified_trfjm", type = "ParkingStall", x = 12501, y = 1241, z = 0, width = 5, height = 1100, properties = { Direction = "S", FaceDirection = true } },

--SOUTH HIGHWAY
	{ name = "trafficjams", type = "ParkingStall", x = 14532, y = 3700, z = 0, width = 6, height = 50, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 15297, y = 3615, z = 0, width = 6, height = 90, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 15294, y = 3707, z = 0, width = 10, height = 40, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 15320, y = 3307, z = 0, width = 10, height = 15, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 15595, y = 3288, z = 0, width = 10, height = 50, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 15595, y = 3338, z = 0, width = 10, height = 260, properties = { Direction = "S", FaceDirection = true } },

	{ name = "trafficjame", type = "ParkingStall", x = 12569, y = 3452, z = 0, width = 64, height = 6, properties = { Direction = "E", FaceDirection = true } },
	{ name = "modified_trfjm", type = "ParkingStall", x = 12635, y = 3452, z = 0, width = 2516, height = 6, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 12635, y = 3450, z = 0, width = 2516, height = 8, properties = { Direction = "E", FaceDirection = true } },
	{ name = "modified_trfjm", type = "ParkingStall", x = 15311, y = 3332, z = 0, width = 452, height = 6, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 15311, y = 3330, z = 0, width = 452, height = 8, properties = { Direction = "E", FaceDirection = true } },
	{ name = "rtrafficjame", type = "ParkingStall", x = 12635, y = 3458, z = 0, width = 2516, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "rtrafficjame", type = "ParkingStall", x = 15311, y = 3338, z = 0, width = 452, height = 3, properties = { Direction = "E", FaceDirection = true } },

	{ name = "trafficjamw", type = "ParkingStall", x = 12552, y = 3442, z = 0, width = 80, height = 6, properties = { Direction = "W", FaceDirection = true } },
	{ name = "modified_trfjm", type = "ParkingStall", x = 12635, y = 3442, z = 0, width = 2516, height = 6, properties = { Direction = "W", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 12635, y = 3442, z = 0, width = 2516, height = 8, properties = { Direction = "W", FaceDirection = true } },
	{ name = "modified_trfjm", type = "ParkingStall", x = 15303, y = 3322, z = 0, width = 452, height = 6, properties = { Direction = "W", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 15303, y = 3322, z = 0, width = 452, height = 8, properties = { Direction = "W", FaceDirection = true } },
	{ name = "rtrafficjamw", type = "ParkingStall", x = 12635, y = 3439, z = 0, width = 2516, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "rtrafficjamw", type = "ParkingStall", x = 15303, y = 3319, z = 0, width = 452, height = 3, properties = { Direction = "W", FaceDirection = true } },

--N
	{ name = "trafficjamn", type = "ParkingStall", x = 12388, y = 1357, z = 0, width = 10, height = 672, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 12295, y = 1357, z = 0, width = 10, height = 1160, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 12680, y = 1357, z = 0, width = 10, height = 292, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 12680, y = 1661, z = 0, width = 6, height = 60, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 12682, y = 1805, z = 0, width = 6, height = 452, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 12797, y = 1357, z = 0, width = 6, height = 288, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 12897, y = 1357, z = 0, width = 6, height = 740, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 12994, y = 1357, z = 0, width = 10, height = 136, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 13048, y = 1241, z = 0, width = 10, height = 104, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 13096, y = 1505, z = 0, width = 6, height = 444, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 13195, y = 1357, z = 0, width = 10, height = 592, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 13277, y = 1430, z = 0, width = 6, height = 420, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 13358, y = 1390, z = 0, width = 6, height = 524, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 13495, y = 1268, z = 0, width = 10, height = 280, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 13490, y = 1734, z = 0, width = 6, height = 60, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 13797, y = 2706, z = 0, width = 6, height = 60, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 13847, y = 2706, z = 0, width = 6, height = 28, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 12931, y = 3458, z = 0, width = 10, height = 28, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 12701, y = 3004, z = 0, width = 6, height = 20, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 13197, y = 3003, z = 0, width = 6, height = 100, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 12868, y = 3458, z = 0, width = 6, height = 20, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 12895, y = 2198, z = 0, width = 10, height = 60, properties = { Direction = "N", FaceDirection = true } },

--S
	{ name = "trafficjams", type = "ParkingStall", x = 13158, y = 1253, z = 0, width = 10, height = 92, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 13197, y = 1253, z = 0, width = 5, height = 52, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 13490, y = 1669, z = 0, width = 6, height = 60, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 13641, y = 1505, z = 0, width = 10, height = 292, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 13641, y = 1799, z = 0, width = 6, height = 44, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 13736, y = 1799, z = 0, width = 6, height = 44, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 13861, y = 1864, z = 0, width = 6, height = 176, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 14010, y = 2120, z = 0, width = 6, height = 140, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 13930, y = 2266, z = 0, width = 6, height = 80, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 13823, y = 2352, z = 0, width = 6, height = 44, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 13976, y = 2421, z = 0, width = 10, height = 1020, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 13797, y = 2405, z = 0, width = 6, height = 292, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 13797, y = 3003, z = 0, width = 6, height = 60, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 13922, y = 3029, z = 0, width = 6, height = 32, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 13628, y = 2706, z = 0, width = 10, height = 360, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 13647, y = 3075, z = 0, width = 10, height = 368, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 13346, y = 2202, z = 0, width = 10, height = 100, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 13497, y = 1960, z = 0, width = 6, height = 988, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 13411, y = 2898, z = 0, width = 6, height = 208, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 13197, y = 3113, z = 0, width = 6, height = 12, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 12932, y = 2703, z = 0, width = 8, height = 740, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 12768, y = 3410, z = 0, width = 6, height = 32, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 13195, y = 1960, z = 0, width = 10, height = 232, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 13030, y = 1960, z = 0, width = 10, height = 232, properties = { Direction = "S", FaceDirection = true } },

--E
	{ name = "trafficjame", type = "ParkingStall", x = 12162, y = 1232, z = 0, width = 429, height = 10, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 12305, y = 1347, z = 0, width = 284, height = 10, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 12273, y = 1495, z = 0, width = 316, height = 10, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 13364, y = 1498, z = 0, width = 132, height = 6, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 12398, y = 1569, z = 0, width = 192, height = 10, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 12273, y = 1651, z = 0, width = 316, height = 10, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 12305, y = 1795, z = 0, width = 284, height = 10, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 12305, y = 1950, z = 0, width = 284, height = 10, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 13205, y = 1950, z = 0, width = 300, height = 10, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 12305, y = 2094, z = 0, width = 196, height = 9, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 12511, y = 2150, z = 0, width = 80, height = 10, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 12305, y = 2323, z = 0, width = 196, height = 10, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 12607, y = 2258, z = 0, width = 288, height = 10, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 12826, y = 2217, z = 0, width = 68, height = 6, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 12905, y = 2192, z = 0, width = 444, height = 10, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 13346, y = 2302, z = 0, width = 148, height = 10, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 13504, y = 1549, z = 0, width = 136, height = 6, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 13505, y = 1495, z = 0, width = 136, height = 10, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 13496, y = 1728, z = 0, width = 144, height = 6, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 13647, y = 1797, z = 0, width = 92, height = 6, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 13483, y = 1844, z = 0, width = 364, height = 6, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 13506, y = 2395, z = 0, width = 88, height = 10, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 13899, y = 2567, z = 0, width = 76, height = 6, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 13504, y = 2696, z = 0, width = 472, height = 10, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 13504, y = 2861, z = 0, width = 124, height = 6, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 13504, y = 2948, z = 0, width = 124, height = 6, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 13202, y = 2995, z = 0, width = 208, height = 10, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 13800, y = 3061, z = 0, width = 176, height = 6, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 13575, y = 3065, z = 0, width = 80, height = 10, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 13418, y = 3106, z = 0, width = 228, height = 10, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 13613, y = 3239, z = 0, width = 36, height = 6, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 13608, y = 3298, z = 0, width = 40, height = 6, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 13618, y = 3343, z = 0, width = 32, height = 6, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 12903, y = 2996, z = 0, width = 28, height = 6, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 12903, y = 3230, z = 0, width = 28, height = 6, properties = { Direction = "E", FaceDirection = true } },

--W
	{ name = "trafficjamw", type = "ParkingStall", x = 12607, y = 1232, z = 0, width = 448, height = 10, properties = { Direction = "W", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 13058, y = 1259, z = 0, width = 48, height = 6, properties = { Direction = "W", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 12607, y = 1347, z = 0, width = 592, height = 10, properties = { Direction = "W", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 12607, y = 1495, z = 0, width = 592, height = 10, properties = { Direction = "W", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 12607, y = 1651, z = 0, width = 592, height = 10, properties = { Direction = "W", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 12607, y = 1795, z = 0, width = 592, height = 10, properties = { Direction = "W", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 12607, y = 1950, z = 0, width = 592, height = 10, properties = { Direction = "W", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 13202, y = 1262, z = 0, width = 300, height = 6, properties = { Direction = "W", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 13168, y = 1303, z = 0, width = 112, height = 6, properties = { Direction = "W", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 13205, y = 1420, z = 0, width = 116, height = 10, properties = { Direction = "W", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 13287, y = 1380, z = 0, width = 208, height = 10, properties = { Direction = "W", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 12940, y = 2996, z = 0, width = 256, height = 6, properties = { Direction = "W", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 13203, y = 3106, z = 0, width = 208, height = 10, properties = { Direction = "W", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 12940, y = 3126, z = 0, width = 256, height = 6, properties = { Direction = "W", FaceDirection = true } },

}

local newTrafficExtra = {

--Echo Creek
--Bridge
	{ name = "trafficjame", type = "ParkingStall", x = 3600, y = 10926, z = 0, width = 44, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 3630, y = 10921, z = 0, width = 28, height = 3, properties = { Direction = "W", FaceDirection = true } },

--Intersection Mad Dan's Den
	{ name = "trafficjamn", type = "ParkingStall", x = 4338, y = 9895, z = 0, width = 3, height = 50, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 4342, y = 9895, z = 0, width = 3, height = 50, properties = { Direction = "N", FaceDirection = true } },

	{ name = "trafficjams", type = "ParkingStall", x = 4330, y = 9845, z = 0, width = 3, height = 50, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 4334, y = 9845, z = 0, width = 3, height = 50, properties = { Direction = "S", FaceDirection = true } },

	{ name = "trafficjame", type = "ParkingStall", x = 4286, y = 9895, z = 0, width = 52, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 4322, y = 9898, z = 0, width = 16, height = 3, properties = { Direction = "E", FaceDirection = true } },

	{ name = "trafficjamw", type = "ParkingStall", x = 4280, y = 9886, z = 0, width = 12, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 4267, y = 9889, z = 0, width = 20, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 4263, y = 9892, z = 0, width = 64, height = 3, properties = { Direction = "W", FaceDirection = true } },

--Guns Unlimited
	{ name = "trafficjams", type = "ParkingStall", x = 2633, y = 10855, z = 0, width = 7, height = 20, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 2623, y = 10851, z = 0, width = 10, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 2639, y = 10852, z = 0, width = 10, height = 3, properties = { Direction = "W", FaceDirection = true } },

	{ name = "trafficjamw", type = "ParkingStall", x = 2572, y = 10915, z = 0, width = 36, height = 11, properties = { Direction = "W", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 2603, y = 10909, z = 0, width = 30, height = 8, properties = { Direction = "W", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 2577, y = 10909, z = 0, width = 26, height = 6, properties = { Direction = "W", FaceDirection = true } },


--Irvington
--GasStation
	{ name = "trafficjamn", type = "ParkingStall", x = 2500, y = 14501, z = 0, width = 3, height = 10, properties = { Direction = "N", FaceDirection = true } },

	{ name = "trafficjams", type = "ParkingStall", x = 2495, y = 14449, z = 0, width = 3, height = 50, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 2499, y = 14469, z = 0, width = 3, height = 30, properties = { Direction = "S", FaceDirection = true } },

	{ name = "trafficjame", type = "ParkingStall", x = 2480, y = 14500, z = 0, width = 20, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 2460, y = 14503, z = 0, width = 40, height = 3, properties = { Direction = "E", FaceDirection = true } },

	{ name = "trafficjamw", type = "ParkingStall", x = 2495, y = 14496, z = 0, width = 50, height = 3, properties = { Direction = "W", FaceDirection = true } },

--Stripmall
	{ name = "trafficjamn", type = "ParkingStall", x = 1798, y = 14838, z = 0, width = 3, height = 10, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 1795, y = 14818, z = 0, width = 3, height = 20, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 1768, y = 14838, z = 0, width = 30, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 1798, y = 14835, z = 0, width = 40, height = 3, properties = { Direction = "W", FaceDirection = true } },


--Brandenburg
--Checkpoint
	{ name = "trafficjamn", type = "ParkingStall", x = 1492, y = 5632, z = 0, width = 3, height = 100, properties = { Direction = "N", FaceDirection = true } },
	{ name = "modified_trfjm", type = "ParkingStall", x = 1495, y = 5632, z = 0, width = 3, height = 120, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 1495, y = 5632, z = 0, width = 3, height = 120, properties = { Direction = "N", FaceDirection = true } }, --dupe to fill gaps
	{ name = "modified_trfjm", type = "ParkingStall", x = 1498, y = 5632, z = 0, width = 3, height = 140, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 1498, y = 5632, z = 0, width = 3, height = 140, properties = { Direction = "N", FaceDirection = true } }, --dupe to fill gaps
	{ name = "modified_trfjm", type = "ParkingStall", x = 1501, y = 5632, z = 0, width = 3, height = 125, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 1501, y = 5632, z = 0, width = 3, height = 125, properties = { Direction = "N", FaceDirection = true } }, --dupe to fill gaps
	{ name = "modified_trfjm", type = "ParkingStall", x = 1504, y = 5632, z = 0, width = 3, height = 125, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 1504, y = 5632, z = 0, width = 3, height = 125, properties = { Direction = "N", FaceDirection = true } }, --dupe to fill gaps
	{ name = "trafficjamn", type = "ParkingStall", x = 1507, y = 5632, z = 0, width = 3, height = 120, properties = { Direction = "N", FaceDirection = true } },

	{ name = "trafficjamn", type = "ParkingStall", x = 1502, y = 5757, z = 0, width = 3, height = 50, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 1505, y = 5757, z = 0, width = 3, height = 50, properties = { Direction = "N", FaceDirection = true } },

--	{ name = "trafficjamn", type = "ParkingStall", x = 1494, y = 5757, z = 0, width = 3, height = 20, properties = { Direction = "N", FaceDirection = true } },
--	{ name = "trafficjamn", type = "ParkingStall", x = 1497, y = 5757, z = 0, width = 3, height = 20, properties = { Direction = "N", FaceDirection = true } },

	{ name = "trafficjamw", type = "ParkingStall", x = 1509, y = 5769, z = 0, width = 30, height = 3, properties = { Direction = "W", FaceDirection = true } },

--Intersection
	{ name = "trafficjamn", type = "ParkingStall", x = 1972, y = 6472, z = 0, width = 3, height = 88, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 1975, y = 6472, z = 0, width = 3, height = 88, properties = { Direction = "N", FaceDirection = true } },

	{ name = "trafficjams", type = "ParkingStall", x = 1964, y = 6406, z = 0, width = 3, height = 68, properties = { Direction = "S", FaceDirection = true } },

	{ name = "trafficjame", type = "ParkingStall", x = 1920, y = 6474, z = 0, width = 52, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 1920, y = 6477, z = 0, width = 52, height = 3, properties = { Direction = "E", FaceDirection = true } },

	{ name = "trafficjamw", type = "ParkingStall", x = 1970, y = 6463, z = 0, width = 24, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 1970, y = 6466, z = 0, width = 116, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 1970, y = 6469, z = 0, width = 116, height = 3, properties = { Direction = "W", FaceDirection = true } },


--Riverside
	{ name = "trafficjamn", type = "ParkingStall", x = 5881, y = 5400, z = 0, width = 3, height = 20, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 5878, y = 5380, z = 0, width = 3, height = 20, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 5871, y = 5400, z = 0, width = 10, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 5881, y = 5397, z = 0, width = 10, height = 3, properties = { Direction = "W", FaceDirection = true } },

	{ name = "trafficjame", type = "ParkingStall", x = 6088, y = 5283, z = 0, width = 20, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 6101, y = 5280, z = 0, width = 20, height = 3, properties = { Direction = "W", FaceDirection = true } },

	{ name = "trafficjame", type = "ParkingStall", x = 6284, y = 5283, z = 0, width = 30, height = 6, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 6297, y = 5277, z = 0, width = 30, height = 6, properties = { Direction = "W", FaceDirection = true } },

	{ name = "trafficjamn", type = "ParkingStall", x = 6387, y = 5283, z = 0, width = 3, height = 20, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 6384, y = 5263, z = 0, width = 3, height = 20, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 6347, y = 5283, z = 0, width = 40, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 6387, y = 5280, z = 0, width = 40, height = 3, properties = { Direction = "W", FaceDirection = true } },

	{ name = "trafficjams", type = "ParkingStall", x = 6446, y = 5264, z = 0, width = 6, height = 15, properties = { Direction = "S", FaceDirection = true } },

	{ name = "trafficjamn", type = "ParkingStall", x = 6531, y = 5283, z = 0, width = 3, height = 20, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 6528, y = 5263, z = 0, width = 3, height = 20, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 6491, y = 5283, z = 0, width = 40, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 6531, y = 5280, z = 0, width = 40, height = 3, properties = { Direction = "W", FaceDirection = true } },

	{ name = "trafficjame", type = "ParkingStall", x = 6322, y = 5537, z = 0, width = 30, height = 6, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 6339, y = 5531, z = 0, width = 30, height = 6, properties = { Direction = "W", FaceDirection = true } },


--Fallas Lake
--Train Station
	{ name = "trafficjamn", type = "ParkingStall", x = 7277, y = 8154, z = 0, width = 3, height = 30, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 7257, y = 8154, z = 0, width = 20, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 7277, y = 8151, z = 0, width = 20, height = 3, properties = { Direction = "W", FaceDirection = true } },

--Intersection
	{ name = "trafficjamn", type = "ParkingStall", x = 7277, y = 8412, z = 0, width = 3, height = 20, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 7274, y = 8392, z = 0, width = 3, height = 20, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 7267, y = 8412, z = 0, width = 10, height = 3, properties = { Direction = "E", FaceDirection = true } },


--Rosewood
--Intersection
	{ name = "trafficjamn", type = "ParkingStall", x = 8106, y = 11204, z = 0, width = 3, height = 35, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 8110, y = 11204, z = 0, width = 3, height = 15, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 8103, y = 11169, z = 0, width = 3, height = 35, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 8099, y = 11189, z = 0, width = 3, height = 15, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 8066, y = 11204, z = 0, width = 40, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 8056, y = 11208, z = 0, width = 50, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 8091, y = 11212, z = 0, width = 20, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 8106, y = 11201, z = 0, width = 40, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 8106, y = 11197, z = 0, width = 50, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 8106, y = 11193, z = 0, width = 20, height = 3, properties = { Direction = "W", FaceDirection = true } },

	{ name = "trafficjamn", type = "ParkingStall", x = 8106, y = 11382, z = 0, width = 3, height = 40, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 8103, y = 11342, z = 0, width = 3, height = 40, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 8081, y = 11382, z = 0, width = 25, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 8106, y = 11379, z = 0, width = 25, height = 3, properties = { Direction = "W", FaceDirection = true } },

	{ name = "trafficjamn", type = "ParkingStall", x = 8106, y = 11476, z = 0, width = 3, height = 40, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 8103, y = 11436, z = 0, width = 3, height = 40, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 8081, y = 11476, z = 0, width = 25, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 8106, y = 11473, z = 0, width = 25, height = 3, properties = { Direction = "W", FaceDirection = true } },

	{ name = "trafficjamn", type = "ParkingStall", x = 8106, y = 11579, z = 0, width = 3, height = 40, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 8103, y = 11539, z = 0, width = 3, height = 40, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 8081, y = 11579, z = 0, width = 25, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 8106, y = 11576, z = 0, width = 25, height = 3, properties = { Direction = "W", FaceDirection = true } },


--March Ridge
--Entrance
	{ name = "trafficjamn", type = "ParkingStall", x = 10358, y = 12400, z = 0, width = 12, height = 100, properties = { Direction = "N", FaceDirection = true } },


--Muldraugh
--McCoy Estate (why? because of the insane zombie pop there, that's why!)
	{ name = "trafficjamn", type = "ParkingStall", x = 10144, y = 8261, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 10139, y = 8256, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "rtrafficjamw", type = "ParkingStall", x = 10125, y = 8271, z = 0, width = 15, height = 6, properties = { Direction = "W", FaceDirection = true } },
	{ name = "rtrafficjams", type = "ParkingStall", x = 10058, y = 8145, z = 0, width = 9, height = 10, properties = { Direction = "S", FaceDirection = true } },
	{ name = "rtrafficjams", type = "ParkingStall", x = 10086, y = 8186, z = 0, width = 3, height = 10, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 10060, y = 8214, z = 0, width = 6, height = 20, properties = { Direction = "S", FaceDirection = true } },
	{ name = "rtrafficjame", type = "ParkingStall", x = 10005, y = 8227, z = 0, width = 10, height = 3, properties = { Direction = "W", FaceDirection = true } },

--Nolan's Used Cars Intersection
	{ name = "trafficjamn", type = "ParkingStall", x = 11645, y = 8328, z = 0, width = 6, height = 50, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 11637, y = 8278, z = 0, width = 6, height = 50, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 11625, y = 8328, z = 0, width = 20, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 11643, y = 8325, z = 0, width = 20, height = 3, properties = { Direction = "W", FaceDirection = true } },

--Intersection
	{ name = "trafficjamn", type = "ParkingStall", x = 10593, y = 9737, z = 0, width = 6, height = 50, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 10585, y = 9687, z = 0, width = 6, height = 50, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 10573, y = 9737, z = 0, width = 20, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 10591, y = 9734, z = 0, width = 30, height = 3, properties = { Direction = "W", FaceDirection = true } },

	{ name = "trafficjamw", type = "ParkingStall", x = 10600, y = 9624, z = 0, width = 35, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 10600, y = 9857, z = 0, width = 30, height = 3, properties = { Direction = "W", FaceDirection = true } },

--South Gas Station
	{ name = "rtrafficjams", type = "ParkingStall", x = 10585, y = 10563, z = 0, width = 9, height = 45, properties = { Direction = "S", FaceDirection = true } },
	{ name = "rtrafficjamn", type = "ParkingStall", x = 10593, y = 10608, z = 0, width = 6, height = 110, properties = { Direction = "N", FaceDirection = true } },

	{ name = "trafficjamw", type = "ParkingStall", x = 10599, y = 10599, z = 0, width = 20, height = 6, properties = { Direction = "W", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 10599, y = 10606, z = 0, width = 25, height = 6, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 10624, y = 10605, z = 0, width = 25, height = 8, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 10627, y = 10605, z = 0, width = 20, height = 15, properties = { Direction = "E", FaceDirection = true } },

	{ name = "trafficjams", type = "ParkingStall", x = 10629, y = 10612, z = 0, width = 6, height = 20, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 10638, y = 10607, z = 0, width = 3, height = 30, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 10641, y = 10607, z = 0, width = 3, height = 25, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 10644, y = 10607, z = 0, width = 3, height = 20, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 10647, y = 10607, z = 0, width = 3, height = 25, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 10650, y = 10607, z = 0, width = 3, height = 30, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 10656, y = 10621, z = 0, width = 6, height = 15, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 10656, y = 10636, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "trafficjamw", type = "ParkingStall", x = 10599, y = 10671, z = 0, width = 50, height = 6, properties = { Direction = "W", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 10646, y = 10649, z = 0, width = 6, height = 20, properties = { Direction = "S", FaceDirection = true } },

--The TRUE Cross Roads
	{ name = "trafficjams", type = "ParkingStall", x = 10585, y = 11154, z = 0, width = 3, height = 55, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 10588, y = 11144, z = 0, width = 3, height = 65, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 10593, y = 11154, z = 0, width = 3, height = 55, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 10596, y = 11164, z = 0, width = 3, height = 45, properties = { Direction = "S", FaceDirection = true } },

	{ name = "trafficjame", type = "ParkingStall", x = 10571, y = 11196, z = 0, width = 25, height = 4, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 10561, y = 11200, z = 0, width = 35, height = 4, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 10541, y = 11204, z = 0, width = 55, height = 4, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 10551, y = 11208, z = 0, width = 45, height = 4, properties = { Direction = "E", FaceDirection = true } },

	{ name = "trafficjamn", type = "ParkingStall", x = 10593, y = 11199, z = 0, width = 3, height = 25, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 10596, y = 11199, z = 0, width = 3, height = 25, properties = { Direction = "N", FaceDirection = true } },

	{ name = "trafficjamw", type = "ParkingStall", x = 10588, y = 11196, z = 0, width = 25, height = 4, properties = { Direction = "W", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 10588, y = 11200, z = 0, width = 25, height = 4, properties = { Direction = "W", FaceDirection = true } },


--West Point
--NW Bridge
	{ name = "trafficjams", type = "ParkingStall", x = 12309, y = 6686, z = 0, width = 6, height = 15, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 12317, y = 6763, z = 0, width = 5, height = 35, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjamn", type = "ParkingStall", x = 12293, y = 6740, z = 0, width = 3, height = 25, properties = { Direction = "N", FaceDirection = true } },

--SE Bridge
	{ name = "trafficjame", type = "ParkingStall", x = 12877, y = 6897, z = 0, width = 25, height = 6, properties = { Direction = "W", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 12907, y = 6897, z = 0, width = 15, height = 6, properties = { Direction = "E", FaceDirection = true } },

--Train Exit
	{ name = "trafficjamn", type = "ParkingStall", x = 12233, y = 6900, z = 0, width = 6, height = 30, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 12225, y = 6890, z = 0, width = 6, height = 10, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 12213, y = 6900, z = 0, width = 20, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 12231, y = 6897, z = 0, width = 10, height = 3, properties = { Direction = "W", FaceDirection = true } },

--Fossoil Exit
	{ name = "trafficjams", type = "ParkingStall", x = 12103, y = 7151, z = 0, width = 3, height = 25, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 12055, y = 7183, z = 0, width = 50, height = 8, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 12106, y = 7176, z = 0, width = 30, height = 6, properties = { Direction = "W", FaceDirection = true } },

--Intersection Butcher
	--South
	{ name = "trafficjamn", type = "ParkingStall", x = 11773, y = 6900, z = 0, width = 3, height = 20, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 11770, y = 6880, z = 0, width = 3, height = 20, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 11753, y = 6900, z = 0, width = 20, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 11773, y = 6897, z = 0, width = 20, height = 3, properties = { Direction = "W", FaceDirection = true } },
	--North
	{ name = "trafficjamn", type = "ParkingStall", x = 11773, y = 6836, z = 0, width = 3, height = 20, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 11770, y = 6816, z = 0, width = 3, height = 20, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 11753, y = 6836, z = 0, width = 20, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 11773, y = 6833, z = 0, width = 20, height = 3, properties = { Direction = "W", FaceDirection = true } },

--Intersection Gas
	--South
	{ name = "trafficjamn", type = "ParkingStall", x = 11848, y = 6900, z = 0, width = 3, height = 20, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 11845, y = 6880, z = 0, width = 3, height = 20, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 11828, y = 6900, z = 0, width = 20, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 11848, y = 6897, z = 0, width = 20, height = 3, properties = { Direction = "W", FaceDirection = true } },
	--North
	{ name = "trafficjamn", type = "ParkingStall", x = 11848, y = 6836, z = 0, width = 3, height = 20, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 11845, y = 6816, z = 0, width = 3, height = 20, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 11828, y = 6836, z = 0, width = 20, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 11848, y = 6833, z = 0, width = 20, height = 3, properties = { Direction = "W", FaceDirection = true } },

--Intersection Town Hall
	--South
	{ name = "trafficjamn", type = "ParkingStall", x = 11921, y = 6900, z = 0, width = 3, height = 30, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 11918, y = 6870, z = 0, width = 3, height = 30, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 11891, y = 6900, z = 0, width = 30, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 11921, y = 6897, z = 0, width = 30, height = 3, properties = { Direction = "W", FaceDirection = true } },
	--North
	{ name = "trafficjamn", type = "ParkingStall", x = 11921, y = 6836, z = 0, width = 3, height = 30, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 11918, y = 6816, z = 0, width = 3, height = 30, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 11891, y = 6836, z = 0, width = 30, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 11921, y = 6833, z = 0, width = 30, height = 3, properties = { Direction = "W", FaceDirection = true } },

--Intersection Giga Mart
	--South
	{ name = "trafficjamn", type = "ParkingStall", x = 12000, y = 6900, z = 0, width = 3, height = 20, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 11997, y = 6880, z = 0, width = 3, height = 20, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 11980, y = 6900, z = 0, width = 20, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 12000, y = 6897, z = 0, width = 20, height = 3, properties = { Direction = "W", FaceDirection = true } },
	--North
	{ name = "trafficjamn", type = "ParkingStall", x = 12000, y = 6836, z = 0, width = 3, height = 20, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trafficjams", type = "ParkingStall", x = 11997, y = 6816, z = 0, width = 3, height = 20, properties = { Direction = "S", FaceDirection = true } },
	{ name = "trafficjame", type = "ParkingStall", x = 11980, y = 6836, z = 0, width = 20, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "trafficjamw", type = "ParkingStall", x = 12000, y = 6833, z = 0, width = 20, height = 3, properties = { Direction = "W", FaceDirection = true } },


--LV Airport
	{ name = "trafficjams", type = "ParkingStall", x = 15545, y = 2928, z = 0, width = 10, height = 58, properties = { Direction = "S", FaceDirection = true } },

	
--Other (testing for occasional taffic jams on the main highways for maybe a 10 years later type playthrough, the whole traffic jam portion of the mod in general is like, a 6 months later typa thing)
--	{ name = "rtrafficjamw", type = "ParkingStall", x = 2686, y = 6144, z = 0, width = 700, height = 3, properties = { Direction = "W", FaceDirection = true } },
--	{ name = "rtrafficjame", type = "ParkingStall", x = 2686, y = 6155, z = 0, width = 700, height = 3, properties = { Direction = "E", FaceDirection = true } },

--	{ name = "rtrafficjams", type = "ParkingStall", x = 3747, y = 6054, z = 0, width = 3, height = 2660, properties = { Direction = "S", FaceDirection = true } },
--	{ name = "rtrafficjamn", type = "ParkingStall", x = 3758, y = 6054, z = 0, width = 3, height = 2660, properties = { Direction = "N", FaceDirection = true } },

--	{ name = "rtrafficjamw", type = "ParkingStall", x = 5302, y = 11197, z = 0, width = 5280, height = 3, properties = { Direction = "W", FaceDirection = true } },
--	{ name = "rtrafficjame", type = "ParkingStall", x = 5302, y = 11208, z = 0, width = 5280, height = 3, properties = { Direction = "E", FaceDirection = true } },

--	{ name = "rtrafficjams", type = "ParkingStall", x = 10585, y = 8858, z = 0, width = 3, height = 5250, properties = { Direction = "S", FaceDirection = true } },
--	{ name = "rtrafficjamn", type = "ParkingStall", x = 10596, y = 8858, z = 0, width = 3, height = 5250, properties = { Direction = "N", FaceDirection = true } },

--	{ name = "rtrafficjams", type = "ParkingStall", x = 11637, y = 7235, z = 0, width = 3, height = 1465, properties = { Direction = "S", FaceDirection = true } },
--	{ name = "rtrafficjamn", type = "ParkingStall", x = 11648, y = 7235, z = 0, width = 3, height = 1465, properties = { Direction = "N", FaceDirection = true } },

--	{ name = "rtrafficjams", type = "ParkingStall", x = 12674, y = 4859, z = 0, width = 3, height = 960, properties = { Direction = "S", FaceDirection = true } },
--	{ name = "rtrafficjamn", type = "ParkingStall", x = 12685, y = 4859, z = 0, width = 3, height = 960, properties = { Direction = "N", FaceDirection = true } },

}

local newParkingStalls = {
--Parking Garages
	{ name = "bad", type = "ParkingStall", x = 12318, y = 1388, z = 0, width = 27, height = 5, properties = { Direction = "N" } },
	{ name = "bad", type = "ParkingStall", x = 12318, y = 1402, z = 0, width = 24, height = 5, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 12635, y = 1762, z = 0, width = 5, height = 15, properties = { Direction = "W" } },
	{ name = "bad", type = "ParkingStall", x = 12641, y = 1782, z = 0, width = 24, height = 5, properties = { Direction = "S" } },
	{ name = "bad", type = "ParkingStall", x = 12671, y = 1761, z = 0, width = 5, height = 21, properties = { Direction = "E" } },
	{ name = "bad", type = "ParkingStall", x = 12645, y = 1765, z = 0, width = 9, height = 5, properties = { Direction = "N" } },
	{ name = "bad", type = "ParkingStall", x = 12645, y = 1770, z = 0, width = 9, height = 5, properties = { Direction = "S" } },
	{ name = "bad", type = "ParkingStall", x = 12655, y = 1765, z = 0, width = 9, height = 5, properties = { Direction = "N" } },
	{ name = "bad", type = "ParkingStall", x = 12655, y = 1770, z = 0, width = 9, height = 5, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 12772, y = 1832, z = 0, width = 15, height = 5, properties = { Direction = "N" } },
	{ name = "bad", type = "ParkingStall", x = 12772, y = 1843, z = 0, width = 15, height = 5, properties = { Direction = "S" } },
	{ name = "bad", type = "ParkingStall", x = 12772, y = 1849, z = 0, width = 15, height = 5, properties = { Direction = "N" } },
	{ name = "bad", type = "ParkingStall", x = 12772, y = 1860, z = 0, width = 15, height = 5, properties = { Direction = "S" } },
	{ name = "bad", type = "ParkingStall", x = 12788, y = 1832, z = 0, width = 15, height = 5, properties = { Direction = "N" } },
	{ name = "bad", type = "ParkingStall", x = 12788, y = 1843, z = 0, width = 15, height = 5, properties = { Direction = "S" } },
	{ name = "bad", type = "ParkingStall", x = 12788, y = 1849, z = 0, width = 15, height = 5, properties = { Direction = "N" } },
	{ name = "bad", type = "ParkingStall", x = 12788, y = 1860, z = 0, width = 15, height = 5, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 12972, y = 1869, z = 0, width = 5, height = 15, properties = { Direction = "E" } },
	{ name = "bad", type = "ParkingStall", x = 12972, y = 1887, z = 0, width = 5, height = 15, properties = { Direction = "E" } },
	{ name = "bad", type = "ParkingStall", x = 12972, y = 1905, z = 0, width = 5, height = 15, properties = { Direction = "E" } },
	{ name = "bad", type = "ParkingStall", x = 13016, y = 1869, z = 0, width = 5, height = 15, properties = { Direction = "W" } },
	{ name = "bad", type = "ParkingStall", x = 13016, y = 1887, z = 0, width = 5, height = 15, properties = { Direction = "W" } },
	{ name = "bad", type = "ParkingStall", x = 13016, y = 1905, z = 0, width = 5, height = 15, properties = { Direction = "W" } },

	{ name = "bad", type = "ParkingStall", x = 12942, y = 1203, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "bad", type = "ParkingStall", x = 12947, y = 1203, z = 0, width = 6, height = 5, properties = { Direction = "N" } },
	{ name = "bad", type = "ParkingStall", x = 12947, y = 1219, z = 0, width = 6, height = 5, properties = { Direction = "S" } },
	{ name = "bad", type = "ParkingStall", x = 12950, y = 1212, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "bad", type = "ParkingStall", x = 12982, y = 1203, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "bad", type = "ParkingStall", x = 12987, y = 1203, z = 0, width = 6, height = 5, properties = { Direction = "N" } },
	{ name = "bad", type = "ParkingStall", x = 12987, y = 1219, z = 0, width = 6, height = 5, properties = { Direction = "S" } },
	{ name = "bad", type = "ParkingStall", x = 12990, y = 1212, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "bad", type = "ParkingStall", x = 13017, y = 1467, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "bad", type = "ParkingStall", x = 13022, y = 1467, z = 0, width = 6, height = 5, properties = { Direction = "N" } },
	{ name = "bad", type = "ParkingStall", x = 13022, y = 1483, z = 0, width = 6, height = 5, properties = { Direction = "S" } },
	{ name = "bad", type = "ParkingStall", x = 13025, y = 1476, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "bad", type = "ParkingStall", x = 13126, y = 1620, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "bad", type = "ParkingStall", x = 13126, y = 1613, z = 0, width = 5, height = 6, properties = { Direction = "W" } },
	{ name = "bad", type = "ParkingStall", x = 13142, y = 1613, z = 0, width = 5, height = 6, properties = { Direction = "E" } },
	{ name = "bad", type = "ParkingStall", x = 13134, y = 1611, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "bad", type = "ParkingStall", x = 13372, y = 1462, z = 0, width = 18, height = 5, properties = { Direction = "N" } },
	{ name = "bad", type = "ParkingStall", x = 13372, y = 1473, z = 0, width = 12, height = 5, properties = { Direction = "S" } },
	{ name = "bad", type = "ParkingStall", x = 13372, y = 1478, z = 0, width = 12, height = 5, properties = { Direction = "N" } },

	{ name = "bad", type = "ParkingStall", x = 13513, y = 1515, z = 0, width = 5, height = 24, properties = { Direction = "W" } },
	{ name = "bad", type = "ParkingStall", x = 13536, y = 1514, z = 0, width = 5, height = 18, properties = { Direction = "E" } },

	{ name = "bad", type = "ParkingStall", x = 13561, y = 1573, z = 0, width = 18, height = 5, properties = { Direction = "N" } },
	{ name = "bad", type = "ParkingStall", x = 13561, y = 1580, z = 0, width = 18, height = 5, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 13705, y = 1527, z = 0, width = 5, height = 15, properties = { Direction = "W" } },
	{ name = "bad", type = "ParkingStall", x = 13705, y = 1508, z = 0, width = 5, height = 15, properties = { Direction = "W" } },
	{ name = "bad", type = "ParkingStall", x = 13714, y = 1527, z = 0, width = 5, height = 9, properties = { Direction = "E" } },
	{ name = "bad", type = "ParkingStall", x = 13719, y = 1527, z = 0, width = 5, height = 9, properties = { Direction = "W" } },
	{ name = "bad", type = "ParkingStall", x = 13714, y = 1514, z = 0, width = 5, height = 9, properties = { Direction = "E" } },
	{ name = "bad", type = "ParkingStall", x = 13719, y = 1514, z = 0, width = 5, height = 9, properties = { Direction = "W" } },

	{ name = "bad", type = "ParkingStall", x = 13564, y = 1694, z = 0, width = 5, height = 18, properties = { Direction = "W" } },
	{ name = "bad", type = "ParkingStall", x = 13575, y = 1695, z = 0, width = 5, height = 21, properties = { Direction = "E" } },


	{ name = "postal", type = "ParkingStall", x = 12657, y = 2060, z = 0, width = 12, height = 5, properties = { Direction = "N" } },
	{ name = "postal", type = "ParkingStall", x = 12657, y = 2072, z = 0, width = 9, height = 5, properties = { Direction = "S" } },
--Garages
--W Side
	{ name = "good", type = "ParkingStall", x = 12031, y = 2121, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "good", type = "ParkingStall", x = 12030, y = 2164, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "good", type = "ParkingStall", x = 12028, y = 2206, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "good", type = "ParkingStall", x = 12029, y = 2268, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "good", type = "ParkingStall", x = 12030, y = 2314, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "good", type = "ParkingStall", x = 12029, y = 2380, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "sport", type = "ParkingStall", x = 12043, y = 2365, z = 0, width = 3, height = 4, properties = { Direction = "S" } },

	{ name = "good", type = "ParkingStall", x = 12025, y = 2427, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "medium", type = "ParkingStall", x = 12025, y = 2597, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "sport", type = "ParkingStall", x = 12039, y = 2583, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "sport", type = "ParkingStall", x = 12044, y = 2583, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "sport", type = "ParkingStall", x = 12049, y = 2583, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "good", type = "ParkingStall", x = 12024, y = 2661, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "good", type = "ParkingStall", x = 12027, y = 2710, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "good", type = "ParkingStall", x = 12027, y = 2782, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "good", type = "ParkingStall", x = 12027, y = 2830, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "good", type = "ParkingStall", x = 12028, y = 2901, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "good", type = "ParkingStall", x = 12028, y = 2948, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "good", type = "ParkingStall", x = 12028, y = 3008, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

--E Side
	{ name = "good", type = "ParkingStall", x = 14149, y = 2603, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "good", type = "ParkingStall", x = 14181, y = 2629, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "good", type = "ParkingStall", x = 14150, y = 2656, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

--LV Airport
	{ name = "airportshuttle", type = "ParkingStall", x = 15577, y = 2871, z = 0, width = 5, height = 4, properties = { Direction = "E", FaceDirection = true } },
	{ name = "airportshuttle", type = "ParkingStall", x = 15577, y = 2879, z = 0, width = 5, height = 4, properties = { Direction = "E", FaceDirection = true } },
	{ name = "airportshuttle", type = "ParkingStall", x = 15577, y = 2887, z = 0, width = 5, height = 4, properties = { Direction = "E", FaceDirection = true } },
	{ name = "airportshuttle", type = "ParkingStall", x = 15586, y = 2870, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "airportshuttle", type = "ParkingStall", x = 15590, y = 2870, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "airportshuttle", type = "ParkingStall", x = 15594, y = 2870, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "airportshuttle", type = "ParkingStall", x = 15586, y = 2877, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "airportshuttle", type = "ParkingStall", x = 15590, y = 2877, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "airportshuttle", type = "ParkingStall", x = 15594, y = 2877, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },

	{ name = "medium", type = "ParkingStall", x = 15498, y = 2944, z = 0, width = 5, height = 24, properties = { Direction = "W" } },
	{ name = "medium", type = "ParkingStall", x = 15508, y = 2944, z = 0, width = 5, height = 30, properties = { Direction = "E" } },
	
	{ name = "parkingstall", type = "ParkingStall", x = 15604, y = 2999, z = 0, width = 5, height = 60, properties = { Direction = "E" } },

	{ name = "postal", type = "ParkingStall", x = 15474, y = 3141, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "postal", type = "ParkingStall", x = 15474, y = 3147, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "postal", type = "ParkingStall", x = 15474, y = 3153, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "postal", type = "ParkingStall", x = 15474, y = 3159, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "postal", type = "ParkingStall", x = 15474, y = 3165, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "postal", type = "ParkingStall", x = 15474, y = 3171, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "postal", type = "ParkingStall", x = 15474, y = 3177, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "postal", type = "ParkingStall", x = 15474, y = 3183, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },

	{ name = "postal", type = "ParkingStall", x = 15485, y = 3141, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "postal", type = "ParkingStall", x = 15485, y = 3147, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "postal", type = "ParkingStall", x = 15485, y = 3153, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "postal", type = "ParkingStall", x = 15485, y = 3159, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "postal", type = "ParkingStall", x = 15485, y = 3165, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "postal", type = "ParkingStall", x = 15485, y = 3171, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "postal", type = "ParkingStall", x = 15485, y = 3177, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "postal", type = "ParkingStall", x = 15485, y = 3183, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },

	{ name = "postal", type = "ParkingStall", x = 15522, y = 3166, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "postal", type = "ParkingStall", x = 15522, y = 3172, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "postal", type = "ParkingStall", x = 15522, y = 3178, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "postal", type = "ParkingStall", x = 15522, y = 3184, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },

	{ name = "postal", type = "ParkingStall", x = 15511, y = 3166, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "postal", type = "ParkingStall", x = 15511, y = 3172, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "postal", type = "ParkingStall", x = 15511, y = 3178, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "postal", type = "ParkingStall", x = 15511, y = 3184, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },

	{ name = "scarlet", type = "ParkingStall", x = 15292, y = 3268, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "scarlet", type = "ParkingStall", x = 15292, y = 3273, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },

	{ name = "trades", type = "ParkingStall", x = 15392, y = 3174, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trades", type = "ParkingStall", x = 15392, y = 3179, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trades", type = "ParkingStall", x = 15392, y = 3184, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trades", type = "ParkingStall", x = 15392, y = 3189, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trades", type = "ParkingStall", x = 15392, y = 3194, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trades", type = "ParkingStall", x = 15392, y = 3199, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },

--Defined by Central Park
	{ name = "radio", type = "ParkingStall", x = 12352, y = 2044, z = 0, width = 3, height = 4, properties = { Direction = "N" } },
	{ name = "radio", type = "ParkingStall", x = 12358, y = 2044, z = 0, width = 3, height = 4, properties = { Direction = "N" } },

	{ name = "network3", type = "ParkingStall", x = 12648, y = 1885, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "network3", type = "ParkingStall", x = 12654, y = 1885, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "network3", type = "ParkingStall", x = 12654, y = 1890, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "medium", type = "ParkingStall", x = 12255, y = 1694, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "medium", type = "ParkingStall", x = 12255, y = 1700, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },

	{ name = "medium", type = "ParkingStall", x = 12651, y = 2122, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "medium", type = "ParkingStall", x = 12656, y = 2122, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "medium", type = "ParkingStall", x = 13271, y = 2961, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "medium", type = "ParkingStall", x = 13277, y = 2961, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },

--Dealer1
	{ name = "good", type = "ParkingStall", x = 13157, y = 1398, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "good", type = "ParkingStall", x = 13152, y = 1403, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },

	{ name = "good", type = "ParkingStall", x = 13162, y = 1402, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "good", type = "ParkingStall", x = 13164, y = 1399, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "good", type = "ParkingStall", x = 13170, y = 1402, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "good", type = "ParkingStall", x = 13171, y = 1398, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "good", type = "ParkingStall", x = 13176, y = 1401, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "good", type = "ParkingStall", x = 13162, y = 1390, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "good", type = "ParkingStall", x = 13166, y = 1394, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "good", type = "ParkingStall", x = 13171, y = 1389, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "good", type = "ParkingStall", x = 13176, y = 1392, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "good", type = "ParkingStall", x = 13161, y = 1369, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "good", type = "ParkingStall", x = 13164, y = 1366, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "good", type = "ParkingStall", x = 13165, y = 1370, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },

--Dealer2
	{ name = "good", type = "ParkingStall", x = 13244, y = 1317, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "good", type = "ParkingStall", x = 13244, y = 1320, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "good", type = "ParkingStall", x = 13249, y = 1318, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "good", type = "ParkingStall", x = 13252, y = 1317, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "good", type = "ParkingStall", x = 13252, y = 1320, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },

	{ name = "good", type = "ParkingStall", x = 13256, y = 1332, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "good", type = "ParkingStall", x = 13259, y = 1333, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },

--Dealer3
	{ name = "good", type = "ParkingStall", x = 13158, y = 1451, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "good", type = "ParkingStall", x = 13157, y = 1457, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "good", type = "ParkingStall", x = 13162, y = 1457, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },

--Dealer4
	{ name = "good", type = "ParkingStall", x = 12382, y = 2532, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "good", type = "ParkingStall", x = 12381, y = 2538, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "good", type = "ParkingStall", x = 12386, y = 2538, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },

--Police
	{ name = "prison", type = "ParkingStall", x = 13227, y = 3075, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },

--Fire
	{ name = "firegarage", type = "ParkingStall", x = 13942, y = 3046, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "firegarage", type = "ParkingStall", x = 13946, y = 3046, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "firetruck", type = "ParkingStall", x = 13942, y = 3054, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "firetruck", type = "ParkingStall", x = 13946, y = 3054, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },

	{ name = "firegarage", type = "ParkingStall", x = 13692, y = 1778, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "firegarage", type = "ParkingStall", x = 13698, y = 1778, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "firegarage", type = "ParkingStall", x = 13704, y = 1778, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "firetruck", type = "ParkingStall", x = 13692, y = 1789, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "firetruck", type = "ParkingStall", x = 13698, y = 1789, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "firetruck", type = "ParkingStall", x = 13704, y = 1789, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },

	{ name = "firegarage", type = "ParkingStall", x = 12360, y = 1764, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "firegarage", type = "ParkingStall", x = 12360, y = 1770, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "firegarage", type = "ParkingStall", x = 12360, y = 1776, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "firetruck", type = "ParkingStall", x = 12371, y = 1764, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "firetruck", type = "ParkingStall", x = 12371, y = 1770, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "firetruck", type = "ParkingStall", x = 12371, y = 1776, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },

	{ name = "firegarage", type = "ParkingStall", x = 15553, y = 2492, z = 0, width = 4, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "firegarage", type = "ParkingStall", x = 15560, y = 2492, z = 0, width = 4, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "firegarage", type = "ParkingStall", x = 15567, y = 2492, z = 0, width = 4, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "firetruck", type = "ParkingStall", x = 15553, y = 2504, z = 0, width = 4, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "firetruck", type = "ParkingStall", x = 15560, y = 2504, z = 0, width = 4, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "firetruck", type = "ParkingStall", x = 15567, y = 2504, z = 0, width = 4, height = 5, properties = { Direction = "S", FaceDirection = true } },

--Other
	{ name = "carpenter", type = "ParkingStall", x = 13770, y = 1587, z = 0, width = 18, height = 5, properties = { Direction = "N" } },
	{ name = "parkingstall", type = "ParkingStall", x = 13746, y = 1600, z = 0, width = 39, height = 5, properties = { Direction = "S" } },
	{ name = "mccoy", type = "ParkingStall", x = 13761, y = 1628, z = 0, width = 27, height = 5, properties = { Direction = "N" } },

	{ name = "junkyard", type = "ParkingStall", x = 12224, y = 1379, z = 0, width = 6, height = 15, properties = { Direction = "N" } },

	{ name = "knoxtelecomms", type = "ParkingStall", x = 12576, y = 4317, z = 0, width = 5, height = 9, properties = { Direction = "E", FaceDirection = true } },

	{ name = "lectromax", type = "ParkingStall", x = 12076, y = 1754, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "lectromax", type = "ParkingStall", x = 12096, y = 1768, z = 0, width = 17, height = 3, properties = { Direction = "E", FaceDirection = true } },

	{ name = "lectromax", type = "ParkingStall", x = 14730, y = 4090, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "lectromax", type = "ParkingStall", x = 14793, y = 4070, z = 0, width = 3, height = 30, properties = { Direction = "N", FaceDirection = true } },

--West Point
--Fire
	{ name = "firetruck", type = "ParkingStall", x = 12262, y = 7026, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "firetruck", type = "ParkingStall", x = 12262, y = 7031, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "firetruck", type = "ParkingStall", x = 12262, y = 7036, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "firegarage", type = "ParkingStall", x = 12272, y = 7026, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "firegarage", type = "ParkingStall", x = 12272, y = 7031, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "firegarage", type = "ParkingStall", x = 12272, y = 7036, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "parkingstall", type = "ParkingStall", x = 12287, y = 7024, z = 0, width = 5, height = 21, properties = { Direction = "E" } },

--Garages
	{ name = "good", type = "ParkingStall", x = 12266, y = 6938, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "good", type = "ParkingStall", x = 12266, y = 6945, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "medium", type = "ParkingStall", x = 12273, y = 6938, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "medium", type = "ParkingStall", x = 12273, y = 6945, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },

	{ name = "bad", type = "ParkingStall", x = 12261, y = 6915, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "bad", type = "ParkingStall", x = 12267, y = 6915, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "bad", type = "ParkingStall", x = 12273, y = 6915, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 12310, y = 6931, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "bad", type = "ParkingStall", x = 12310, y = 6936, z = 0, width = 5, height = 3, properties = { Direction = "W" } },


	{ name = "sport", type = "ParkingStall", x = 12146, y = 7001, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },

--Farms
	{ name = "farm", type = "ParkingStall", x = 10723, y = 7000, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "bad", type = "ParkingStall", x = 10726, y = 7005, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "bad", type = "ParkingStall", x = 10647, y = 7193, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "bad", type = "ParkingStall", x = 10584, y = 7186, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "bad", type = "ParkingStall", x = 10574, y = 7196, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "farm", type = "ParkingStall", x = 10430, y = 7379, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "bad", type = "ParkingStall", x = 10471, y = 7390, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "farm", type = "ParkingStall", x = 10341, y = 7417, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "farm", type = "ParkingStall", x = 10077, y = 7377, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },

	{ name = "farm", type = "ParkingStall", x = 9843, y = 7818, z = 0, width = 9, height = 5, properties = { Direction = "S", FaceDirection = true } },

	{ name = "farm", type = "ParkingStall", x = 9771, y = 7601, z = 0, width = 5, height = 9, properties = { Direction = "W", FaceDirection = true } },

	{ name = "bad", type = "ParkingStall", x = 9816, y = 7618, z = 0, width = 6, height = 5, properties = { Direction = "N" } },
	{ name = "bad", type = "ParkingStall", x = 9819, y = 7621, z = 0, width = 6, height = 5, properties = { Direction = "N" } },

	{ name = "bad", type = "ParkingStall", x = 9856, y = 7665, z = 0, width = 6, height = 5, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 9296, y = 7779, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "bad", type = "ParkingStall", x = 9296, y = 7785, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "bad", type = "ParkingStall", x = 9296, y = 7791, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },

	{ name = "farm", type = "ParkingStall", x = 12063, y = 6779, z = 0, width = 9, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "farm", type = "ParkingStall", x = 10277, y = 7784, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "parkingstall", type = "ParkingStall", x = 11743, y = 6940, z = 0, width = 5, height = 3, properties = { Direction = "S" } },
	{ name = "parkingstall", type = "ParkingStall", x = 11757, y = 6955, z = 0, width = 5, height = 3, properties = { Direction = "N" } },

--Other
	{ name = "knoxtelecomms", type = "ParkingStall", x = 12000, y = 7165, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },

	{ name = "parkingstall", type = "ParkingStall", x = 8072, y = 7624, z = 0, width = 3, height = 5, properties = { Direction = "E" } },

	{ name = "bad", type = "ParkingStall", x = 10221, y = 6808, z = 0, width = 4, height = 4, properties = { Direction = "NE", FaceDirection = true } },

	{ name = "bad", type = "ParkingStall", x = 9509, y = 6618, z = 0, width = 4, height = 4, properties = { Direction = "NW", FaceDirection = true } },
	{ name = "bad", type = "ParkingStall", x = 9503, y = 6615, z = 0, width = 4, height = 4, properties = { Direction = "NW", FaceDirection = true } },
	{ name = "farm", type = "ParkingStall", x = 9493, y = 6611, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "bad", type = "ParkingStall", x = 9496, y = 6628, z = 0, width = 4, height = 4, properties = { Direction = "SE", FaceDirection = true } },

--Muldraugh
--Garages
	{ name = "bad", type = "ParkingStall", x = 10179, y = 10935, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "bad", type = "ParkingStall", x = 10179, y = 10944, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "bad", type = "ParkingStall", x = 10185, y = 10944, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },

	{ name = "bad", type = "ParkingStall", x = 10608, y = 9404, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "bad", type = "ParkingStall", x = 10608, y = 9409, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },

	{ name = "bad", type = "ParkingStall", x = 10475, y = 10065, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "medium", type = "ParkingStall", x = 10495, y = 10075, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "farm", type = "ParkingStall", x = 10482, y = 10083, z = 0, width = 5, height = 9, properties = { Direction = "E", FaceDirection = true } },

	{ name = "sport", type = "ParkingStall", x = 10912, y = 10074, z = 0, width = 4, height = 3, properties = { Direction = "W", FaceDirection = true } },

	{ name = "bad", type = "ParkingStall", x = 10881, y = 9961, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },

	{ name = "bad", type = "ParkingStall", x = 10644, y = 10259, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "bad", type = "ParkingStall", x = 10707, y = 10399, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "sport", type = "ParkingStall", x = 10672, y = 9845, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

--Police
	{ name = "prison", type = "ParkingStall", x = 10652, y = 10403, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "prison", type = "ParkingStall", x = 10661, y = 10403, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },

--McCoy Estate
	{ name = "parkingstall", type = "ParkingStall", x = 10728, y = 8234, z = 0, width = 9, height = 5, properties = { Direction = "N" } },
	{ name = "ranger", type = "ParkingStall", x = 10734, y = 8243, z = 0, width = 9, height = 5, properties = { Direction = "S" } },

	{ name = "sport", type = "ParkingStall", x = 10081, y = 8262, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "sport", type = "ParkingStall", x = 10110, y = 8240, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "farm", type = "ParkingStall", x = 10071, y = 8243, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "medium", type = "ParkingStall", x = 10087, y = 8273, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "medium", type = "ParkingStall", x = 10096, y = 8273, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "medium", type = "ParkingStall", x = 10103, y = 8273, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },

--Other
	{ name = "knoxtelecomms", type = "ParkingStall", x = 10577, y = 9757, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },

	{ name = "lectromax", type = "ParkingStall", x = 11585, y = 8233, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "lectromax", type = "ParkingStall", x = 11590, y = 8230, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "radio", type = "ParkingStall", x = 10272, y = 8756, z = 0, width = 9, height = 5, properties = { Direction = "S" } },

	{ name = "medium", type = "ParkingStall", x = 10856, y = 8968, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "parkingstall", type = "ParkingStall", x = 10042, y = 10829, z = 0, width = 5, height = 21, properties = { Direction = "W" } },
	{ name = "parkingstall", type = "ParkingStall", x = 10055, y = 10829, z = 0, width = 5, height = 21, properties = { Direction = "E" } },

	{ name = "parkingstall", type = "ParkingStall", x = 10105, y = 11122, z = 0, width = 18, height = 5, properties = { Direction = "N" } },
	{ name = "parkingstall", type = "ParkingStall", x = 10108, y = 11135, z = 0, width = 15, height = 5, properties = { Direction = "S" } },
	{ name = "parkingstall", type = "ParkingStall", x = 10095, y = 11127, z = 0, width = 5, height = 9, properties = { Direction = "W" } },

	{ name = "lectromax", type = "ParkingStall", x = 10394, y = 10067, z = 0, width = 6, height = 5, properties = { Direction = "S" } },

	{ name = "farm", type = "ParkingStall", x = 10772, y = 9523, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "parkingstall", type = "ParkingStall", x = 10895, y = 9752, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "parkingstall", type = "ParkingStall", x = 10893, y = 9761, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 12699, y = 8749, z = 0, width = 6, height = 5, properties = { Direction = "S" } },
	{ name = "bad", type = "ParkingStall", x = 12711, y = 8738, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "advertising", type = "ParkingStall", x = 10606, y = 10552, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "advertising", type = "ParkingStall", x = 9458, y = 9779, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "advertising", type = "ParkingStall", x = 10578, y = 8909, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "advertising", type = "ParkingStall", x = 9350, y = 8064, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "advertising", type = "ParkingStall", x = 8652, y = 8134, z = 0, width = 6, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "advertising", type = "ParkingStall", x = 8652, y = 8152, z = 0, width = 6, height = 5, properties = { Direction = "N", FaceDirection = true } },

--March Ridge
--Houses
	{ name = "bad", type = "ParkingStall", x = 10243, y = 12761, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "bad", type = "ParkingStall", x = 10243, y = 12776, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "bad", type = "ParkingStall", x = 10243, y = 12792, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "bad", type = "ParkingStall", x = 10243, y = 12810, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "bad", type = "ParkingStall", x = 10276, y = 12819, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "bad", type = "ParkingStall", x = 10295, y = 12819, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "good", type = "ParkingStall", x = 10005, y = 12983, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "good", type = "ParkingStall", x = 10005, y = 12988, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

--Rosewood
--Fire
	{ name = "firetruck", type = "ParkingStall", x = 8148, y = 11719, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "firetruck", type = "ParkingStall", x = 8152, y = 11719, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "firegarage", type = "ParkingStall", x = 8148, y = 11730, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "firegarage", type = "ParkingStall", x = 8152, y = 11730, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "firegarage", type = "ParkingStall", x = 8148, y = 11739, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "firegarage", type = "ParkingStall", x = 8152, y = 11739, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "firetruck", type = "ParkingStall", x = 8148, y = 11750, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "firetruck", type = "ParkingStall", x = 8152, y = 11750, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },

--Garages


--Houses


--Farmer's Market
	{ name = "parkingstall", type = "ParkingStall", x = 9002, y = 12305, z = 0, width = 12, height = 5, properties = { Direction = "S" } },
	{ name = "bad", type = "ParkingStall", x = 8996, y = 12298, z = 0, width = 4, height = 4, properties = { Direction = "SW", FaceDirection = true } },

	{ name = "parkingstall", type = "ParkingStall", x = 9046, y = 12162, z = 0, width = 5, height = 33, properties = { Direction = "W" } },
	{ name = "parkingstall", type = "ParkingStall", x = 9060, y = 12162, z = 0, width = 5, height = 30, properties = { Direction = "E" } },
	
	{ name = "farm", type = "ParkingStall", x = 8887, y = 12105, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "farm", type = "ParkingStall", x = 8902, y = 12105, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "farm", type = "ParkingStall", x = 9186, y = 12145, z = 0, width = 6, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "farm", type = "ParkingStall", x = 9188, y = 12176, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "farm", type = "ParkingStall", x = 9187, y = 12181, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },

--Other
	{ name = "prison", type = "ParkingStall", x = 8064, y = 11749, z = 0, width = 6, height = 5, properties = { Direction = "N" } },

	{ name = "knoxtelecomms", type = "ParkingStall", x = 7260, y = 12510, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "knoxtelecomms", type = "ParkingStall", x = 8334, y = 12317, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },

	{ name = "lectromax", type = "ParkingStall", x = 7271, y = 12510, z = 0, width = 5, height = 6, properties = { Direction = "E" } },

--Riverside
--Police
	{ name = "prison", type = "ParkingStall", x = 6089, y = 5235, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "prison", type = "ParkingStall", x = 6089, y = 5239, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },

	{ name = "ranger", type = "ParkingStall", x = 6075, y = 5220, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "prison", type = "ParkingStall", x = 6080, y = 5220, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },

--Fire
	{ name = "firegarage", type = "ParkingStall", x = 6131, y = 5249, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "firegarage", type = "ParkingStall", x = 6135, y = 5249, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "firegarage", type = "ParkingStall", x = 6131, y = 5257, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "firegarage", type = "ParkingStall", x = 6135, y = 5257, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "firetruck", type = "ParkingStall", x = 6131, y = 5267, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "firetruck", type = "ParkingStall", x = 6135, y = 5267, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },

--Garages
	{ name = "bad", type = "ParkingStall", x = 5842, y = 5377, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "sport", type = "ParkingStall", x = 7458, y = 6083, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },

--Other
	{ name = "knoxtelecomms", type = "ParkingStall", x = 5421, y = 6762, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },

	{ name = "lectromax", type = "ParkingStall", x = 5552, y = 5962, z = 0, width = 11, height = 27, properties = { Direction = "W", FaceDirection = true } },

	{ name = "radio", type = "ParkingStall", x = 4839, y = 6275, z = 0, width = 5, height = 6, properties = { Direction = "E" } },

	{ name = "ranger", type = "ParkingStall", x = 6399, y = 5655, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "farm", type = "ParkingStall", x = 5968, y = 6513, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "farm", type = "ParkingStall", x = 5968, y = 6517, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "ranger", type = "ParkingStall", x = 5986, y = 6514, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "ranger", type = "ParkingStall", x = 5986, y = 6514, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },

--Brandenburg
--Garages
	{ name = "medium", type = "ParkingStall", x = 1942, y = 6403, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "medium", type = "ParkingStall", x = 1942, y = 6410, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },

	{ name = "bad", type = "ParkingStall", x = 1473, y = 6312, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "bad", type = "ParkingStall", x = 1473, y = 6331, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "bad", type = "ParkingStall", x = 1538, y = 6273, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "medium", type = "ParkingStall", x = 1685, y = 5683, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "bad", type = "ParkingStall", x = 1668, y = 5745, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "medium", type = "ParkingStall", x = 1763, y = 5748, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "medium", type = "ParkingStall", x = 1727, y = 5791, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "medium", type = "ParkingStall", x = 1728, y = 5835, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "medium", type = "ParkingStall", x = 1725, y = 5869, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "medium", type = "ParkingStall", x = 1727, y = 5939, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "medium", type = "ParkingStall", x = 1727, y = 5970, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "medium", type = "ParkingStall", x = 1704, y = 5963, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "bad", type = "ParkingStall", x = 1829, y = 6303, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "bad", type = "ParkingStall", x = 1910, y = 5815, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "medium", type = "ParkingStall", x = 1981, y = 5841, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "medium", type = "ParkingStall", x = 1947, y = 5896, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "medium", type = "ParkingStall", x = 1949, y = 5977, z = 0, width = 4, height = 3, properties = { Direction = "E" } },

	{ name = "medium", type = "ParkingStall", x = 2020, y = 6109, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 2016, y = 5837, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "bad", type = "ParkingStall", x = 2023, y = 5837, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 2109, y = 5870, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "bad", type = "ParkingStall", x = 2134, y = 5826, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "bad", type = "ParkingStall", x = 2134, y = 5855, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "bad", type = "ParkingStall", x = 2134, y = 5858, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "bad", type = "ParkingStall", x = 2185, y = 5826, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "bad", type = "ParkingStall", x = 2185, y = 5829, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "bad", type = "ParkingStall", x = 2185, y = 5855, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "bad", type = "ParkingStall", x = 2185, y = 5858, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "bad", type = "ParkingStall", x = 2200, y = 5826, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "bad", type = "ParkingStall", x = 2200, y = 5829, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "bad", type = "ParkingStall", x = 2200, y = 5855, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "bad", type = "ParkingStall", x = 2200, y = 5858, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "bad", type = "ParkingStall", x = 2251, y = 5826, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "bad", type = "ParkingStall", x = 2251, y = 5829, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "bad", type = "ParkingStall", x = 2251, y = 5856, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "bad", type = "ParkingStall", x = 2251, y = 5859, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "medium", type = "ParkingStall", x = 2139, y = 6043, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "medium", type = "ParkingStall", x = 2150, y = 6057, z = 0, width = 4, height = 3, properties = { Direction = "E" } },

	{ name = "medium", type = "ParkingStall", x = 2208, y = 6016, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "medium", type = "ParkingStall", x = 2751, y = 5896, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "bad", type = "ParkingStall", x = 2444, y = 6714, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "bad", type = "ParkingStall", x = 2476, y = 6732, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "parkingstall", type = "ParkingStall", x = 3057, y = 6414, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "parkingstall", type = "ParkingStall", x = 3091, y = 6572, z = 0, width = 3, height = 5, properties = { Direction = "N" } },


	{ name = "sport", type = "ParkingStall", x = 1992, y = 6489, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "sport", type = "ParkingStall", x = 2007, y = 6489, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "sport", type = "ParkingStall", x = 2012, y = 6489, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "sport", type = "ParkingStall", x = 2002, y = 6503, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "sport", type = "ParkingStall", x = 2017, y = 6503, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "sport", type = "ParkingStall", x = 2002, y = 6510, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "sport", type = "ParkingStall", x = 2007, y = 6510, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "sport", type = "ParkingStall", x = 2007, y = 6531, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "sport", type = "ParkingStall", x = 2012, y = 6531, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

--Dealer5
	{ name = "good", type = "ParkingStall", x = 2041, y = 6489, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "good", type = "ParkingStall", x = 2041, y = 6494, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },

--Farms
	{ name = "farm", type = "ParkingStall", x = 102, y = 8936, z = 0, width = 5, height = 6, properties = { Direction = "E", FaceDirection = true } },
	{ name = "good", type = "ParkingStall", x = 114, y = 8974, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "good", type = "ParkingStall", x = 118, y = 8974, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "bad", type = "ParkingStall", x = 1529, y = 6401, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "farm", type = "ParkingStall", x = 1508, y = 6377, z = 0, width = 12, height = 5, properties = { Direction = "S", FaceDirection = true } },

	{ name = "farm", type = "ParkingStall", x = 1726, y = 6523, z = 0, width = 6, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "farm", type = "ParkingStall", x = 1708, y = 6505, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "farm", type = "ParkingStall", x = 1718, y = 6555, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "farm", type = "ParkingStall", x = 1484, y = 6804, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "farm", type = "ParkingStall", x = 1494, y = 6804, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "bad", type = "ParkingStall", x = 1563, y = 6839, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "farm", type = "ParkingStall", x = 1544, y = 6846, z = 0, width = 9, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "farm", type = "ParkingStall", x = 1460, y = 7947, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },

	{ name = "bad", type = "ParkingStall", x = 1625, y = 7945, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "bad", type = "ParkingStall", x = 1625, y = 7949, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "farm", type = "ParkingStall", x = 2408, y = 5964, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "medium", type = "ParkingStall", x = 2420, y = 5973, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "bad", type = "ParkingStall", x = 2720, y = 6068, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "farm", type = "ParkingStall", x = 2723, y = 6068, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "bad", type = "ParkingStall", x = 2453, y = 6815, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "medium", type = "ParkingStall", x = 2439, y = 6860, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "farm", type = "ParkingStall", x = 2458, y = 6845, z = 0, width = 9, height = 5, properties = { Direction = "N", FaceDirection = true } },

--Police
	{ name = "prison", type = "ParkingStall", x = 2028, y = 5969, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },

--Fire
	{ name = "firegarage", type = "ParkingStall", x = 2070, y = 6286, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "firegarage", type = "ParkingStall", x = 2070, y = 6281, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },

--Other
	{ name = "good", type = "ParkingStall", x = 1295, y = 7412, z = 0, width = 18, height = 5, properties = { Direction = "N" } },
	{ name = "medium", type = "ParkingStall", x = 1295, y = 7423, z = 0, width = 18, height = 5, properties = { Direction = "S" } },
	{ name = "trades", type = "ParkingStall", x = 1291, y = 7423, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },

--Irvington
--Garages
	{ name = "bad", type = "ParkingStall", x = 1825, y = 13434, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "medium", type = "ParkingStall", x = 1828, y = 15125, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "bad", type = "ParkingStall", x = 2474, y = 14025, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "bad", type = "ParkingStall", x = 2474, y = 14030, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },

	{ name = "medium", type = "ParkingStall", x = 1777, y = 14630, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "medium", type = "ParkingStall", x = 1777, y = 14635, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "medium", type = "ParkingStall", x = 1777, y = 14644, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "medium", type = "ParkingStall", x = 1777, y = 14649, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "medium", type = "ParkingStall", x = 1777, y = 14670, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "medium", type = "ParkingStall", x = 1777, y = 14675, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "medium", type = "ParkingStall", x = 1777, y = 14684, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "medium", type = "ParkingStall", x = 1777, y = 14689, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "medium", type = "ParkingStall", x = 1777, y = 14710, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "medium", type = "ParkingStall", x = 1777, y = 14715, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "medium", type = "ParkingStall", x = 1777, y = 14724, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "medium", type = "ParkingStall", x = 1777, y = 14729, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "bad", type = "ParkingStall", x = 1811, y = 14576, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 1877, y = 14572, z = 0, width = 4, height = 3, properties = { Direction = "E" } },

	{ name = "medium", type = "ParkingStall", x = 1914, y = 14581, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 1936, y = 14537, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 1896, y = 14274, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "medium", type = "ParkingStall", x = 2014, y = 14270, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 2096, y = 14274, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 1982, y = 14350, z = 0, width = 4, height = 3, properties = { Direction = "E" } },

	{ name = "bad", type = "ParkingStall", x = 2026, y = 14378, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "medium", type = "ParkingStall", x = 2155, y = 14379, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 2117, y = 14414, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "bad", type = "ParkingStall", x = 1923, y = 14464, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "medium", type = "ParkingStall", x = 2230, y = 14022, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "medium", type = "ParkingStall", x = 2227, y = 14120, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "medium", type = "ParkingStall", x = 2237, y = 14156, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "medium", type = "ParkingStall", x = 2234, y = 14205, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "medium", type = "ParkingStall", x = 2234, y = 14209, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "medium", type = "ParkingStall", x = 2235, y = 14226, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "medium", type = "ParkingStall", x = 2226, y = 14265, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "medium", type = "ParkingStall", x = 2280, y = 14131, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "medium", type = "ParkingStall", x = 2267, y = 14170, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "medium", type = "ParkingStall", x = 2266, y = 14207, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "medium", type = "ParkingStall", x = 2265, y = 14240, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "medium", type = "ParkingStall", x = 2280, y = 14273, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "medium", type = "ParkingStall", x = 2322, y = 14123, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "medium", type = "ParkingStall", x = 2324, y = 14169, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "medium", type = "ParkingStall", x = 2322, y = 14195, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "medium", type = "ParkingStall", x = 2323, y = 14230, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "medium", type = "ParkingStall", x = 2322, y = 14271, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "medium", type = "ParkingStall", x = 2378, y = 14131, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "medium", type = "ParkingStall", x = 2378, y = 14161, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "medium", type = "ParkingStall", x = 2376, y = 14206, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "medium", type = "ParkingStall", x = 2380, y = 14230, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "medium", type = "ParkingStall", x = 2379, y = 14264, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "bad", type = "ParkingStall", x = 2415, y = 14389, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "medium", type = "ParkingStall", x = 2387, y = 14721, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "medium", type = "ParkingStall", x = 2684, y = 13862, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 2720, y = 13864, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "medium", type = "ParkingStall", x = 2814, y = 13964, z = 0, width = 4, height = 3, properties = { Direction = "E" } },

	{ name = "bad", type = "ParkingStall", x = 2525, y = 14271, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "bad", type = "ParkingStall", x = 2564, y = 14256, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "bad", type = "ParkingStall", x = 2665, y = 14270, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "medium", type = "ParkingStall", x = 2669, y = 14316, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "bad", type = "ParkingStall", x = 2831, y = 14560, z = 0, width = 4, height = 3, properties = { Direction = "E" } },

	{ name = "bad", type = "ParkingStall", x = 2825, y = 14637, z = 0, width = 4, height = 3, properties = { Direction = "E" } },

	{ name = "bad", type = "ParkingStall", x = 2921, y = 14649, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 2937, y = 14678, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "bad", type = "ParkingStall", x = 2974, y = 14651, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "medium", type = "ParkingStall", x = 2978, y = 14710, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "bad", type = "ParkingStall", x = 3003, y = 14824, z = 0, width = 4, height = 3, properties = { Direction = "E" } },

	{ name = "bad", type = "ParkingStall", x = 3045, y = 14823, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "bad", type = "ParkingStall", x = 3086, y = 14583, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 3324, y = 14596, z = 0, width = 4, height = 3, properties = { Direction = "E" } },


	{ name = "sport", type = "ParkingStall", x = 2434, y = 13910, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "sport", type = "ParkingStall", x = 2448, y = 13904, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "sport", type = "ParkingStall", x = 2448, y = 13907, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "sport", type = "ParkingStall", x = 2461, y = 13920, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

--Irvington Speedway
	{ name = "racecar", type = "ParkingStall", x = 966, y = 12938, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "racecar", type = "ParkingStall", x = 971, y = 12938, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "racecar", type = "ParkingStall", x = 976, y = 12938, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "racecar", type = "ParkingStall", x = 981, y = 12938, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "racecar", type = "ParkingStall", x = 986, y = 12938, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "racecar", type = "ParkingStall", x = 991, y = 12938, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "racecar", type = "ParkingStall", x = 996, y = 12938, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "racecar", type = "ParkingStall", x = 1001, y = 12938, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "racecar", type = "ParkingStall", x = 1006, y = 12938, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "racecar", type = "ParkingStall", x = 1011, y = 12938, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "racecar", type = "ParkingStall", x = 1016, y = 12938, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "racecar", type = "ParkingStall", x = 1021, y = 12938, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "racecar", type = "ParkingStall", x = 1026, y = 12938, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "racecar", type = "ParkingStall", x = 1031, y = 12938, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "racecar", type = "ParkingStall", x = 1036, y = 12938, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	
	{ name = "racecar", type = "ParkingStall", x = 966, y = 12929, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "racecar", type = "ParkingStall", x = 971, y = 12929, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "racecar", type = "ParkingStall", x = 976, y = 12929, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "racecar", type = "ParkingStall", x = 981, y = 12929, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "racecar", type = "ParkingStall", x = 986, y = 12929, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "racecar", type = "ParkingStall", x = 991, y = 12929, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "racecar", type = "ParkingStall", x = 996, y = 12929, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "racecar", type = "ParkingStall", x = 1001, y = 12929, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "racecar", type = "ParkingStall", x = 1006, y = 12929, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "racecar", type = "ParkingStall", x = 1011, y = 12929, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "racecar", type = "ParkingStall", x = 1016, y = 12929, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "racecar", type = "ParkingStall", x = 1021, y = 12929, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "racecar", type = "ParkingStall", x = 1026, y = 12929, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "racecar", type = "ParkingStall", x = 1031, y = 12929, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "racecar", type = "ParkingStall", x = 1036, y = 12929, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	
	{ name = "racecar", type = "ParkingStall", x = 966, y = 12906, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "racecar", type = "ParkingStall", x = 971, y = 12906, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "racecar", type = "ParkingStall", x = 976, y = 12906, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "racecar", type = "ParkingStall", x = 981, y = 12906, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "racecar", type = "ParkingStall", x = 986, y = 12906, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "racecar", type = "ParkingStall", x = 991, y = 12906, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "racecar", type = "ParkingStall", x = 996, y = 12906, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "racecar", type = "ParkingStall", x = 1001, y = 12906, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "racecar", type = "ParkingStall", x = 1006, y = 12906, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "racecar", type = "ParkingStall", x = 1011, y = 12906, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "racecar", type = "ParkingStall", x = 1016, y = 12906, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "racecar", type = "ParkingStall", x = 1021, y = 12906, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "racecar", type = "ParkingStall", x = 1026, y = 12906, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "racecar", type = "ParkingStall", x = 1031, y = 12906, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "racecar", type = "ParkingStall", x = 1036, y = 12906, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "racecar", type = "ParkingStall", x = 967, y = 12971, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "racecar", type = "ParkingStall", x = 967, y = 12983, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "racecar", type = "ParkingStall", x = 967, y = 12995, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "racecar", type = "ParkingStall", x = 967, y = 13007, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "racecar", type = "ParkingStall", x = 967, y = 13019, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "racecar", type = "ParkingStall", x = 967, y = 13031, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "racecar", type = "ParkingStall", x = 967, y = 13043, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "racecar", type = "ParkingStall", x = 967, y = 13055, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "racecar", type = "ParkingStall", x = 967, y = 13067, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "racecar", type = "ParkingStall", x = 967, y = 13079, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "racecar", type = "ParkingStall", x = 967, y = 13091, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "racecar", type = "ParkingStall", x = 967, y = 13103, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "racecar", type = "ParkingStall", x = 967, y = 13115, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "racecar", type = "ParkingStall", x = 967, y = 13127, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "racecar", type = "ParkingStall", x = 967, y = 13139, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "racecar", type = "ParkingStall", x = 967, y = 13151, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "parkingstall", type = "ParkingStall", x = 986, y = 12967, z = 0, width = 5, height = 48, properties = { Direction = "W" } },
	{ name = "parkingstall", type = "ParkingStall", x = 997, y = 12967, z = 0, width = 5, height = 48, properties = { Direction = "E" } },
	{ name = "parkingstall", type = "ParkingStall", x = 1002, y = 12967, z = 0, width = 5, height = 48, properties = { Direction = "W" } },
	{ name = "parkingstall", type = "ParkingStall", x = 1013, y = 12961, z = 0, width = 5, height = 60, properties = { Direction = "E" } },

--Dealer6
	{ name = "good", type = "ParkingStall", x = 2370, y = 14530, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "good", type = "ParkingStall", x = 2370, y = 14535, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },

--Farms
	{ name = "good", type = "ParkingStall", x = 1335, y = 13771, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "farm", type = "ParkingStall", x = 1323, y = 13752, z = 0, width = 5, height = 12, properties = { Direction = "W", FaceDirection = true } },

	{ name = "medium", type = "ParkingStall", x = 960, y = 14277, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "medium", type = "ParkingStall", x = 970, y = 14277, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "farm", type = "ParkingStall", x = 929, y = 14281, z = 0, width = 5, height = 18, properties = { Direction = "E", FaceDirection = true } },

	{ name = "farm", type = "ParkingStall", x = 1025, y = 14815, z = 0, width = 6, height = 5, properties = { Direction = "W", FaceDirection = true } },

	{ name = "medium", type = "ParkingStall", x = 1302, y = 14645, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "sport", type = "ParkingStall", x = 1545, y = 14463, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "good", type = "ParkingStall", x = 1545, y = 14467, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "farm", type = "ParkingStall", x = 1558, y = 14417, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "farm", type = "ParkingStall", x = 1558, y = 14429, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "farm", type = "ParkingStall", x = 1558, y = 14441, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "farm", type = "ParkingStall", x = 1733, y = 14479, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },

	{ name = "bad", type = "ParkingStall", x = 3160, y = 13765, z = 0, width = 4, height = 3, properties = { Direction = "E" } },
	{ name = "farm", type = "ParkingStall", x = 3188, y = 13799, z = 0, width = 5, height = 12, properties = { Direction = "E", FaceDirection = true } },

	{ name = "sport", type = "ParkingStall", x = 4008, y = 13649, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "good", type = "ParkingStall", x = 4012, y = 13651, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

--Police
	{ name = "prison", type = "ParkingStall", x = 2485, y = 13914, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "prison", type = "ParkingStall", x = 2485, y = 13918, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "prison", type = "ParkingStall", x = 2485, y = 13922, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },

--Fire
	{ name = "firegarage", type = "ParkingStall", x = 1037, y = 12995, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "firegarage", type = "ParkingStall", x = 1037, y = 13003, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },

	{ name = "firegarage", type = "ParkingStall", x = 2477, y = 14065, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "firetruck", type = "ParkingStall", x = 2486, y = 14065, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },

--Ekron
--Fire
	{ name = "firetruck", type = "ParkingStall", x = 757, y = 9754, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "firetruck", type = "ParkingStall", x = 761, y = 9754, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "firegarage", type = "ParkingStall", x = 757, y = 9764, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "firegarage", type = "ParkingStall", x = 761, y = 9764, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "firegarage", type = "ParkingStall", x = 757, y = 9773, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "firegarage", type = "ParkingStall", x = 761, y = 9773, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },

--Garages/Houses
	{ name = "bad", type = "ParkingStall", x = 320, y = 9821, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "bad", type = "ParkingStall", x = 323, y = 9821, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "medium", type = "ParkingStall", x = 367, y = 9705, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "medium", type = "ParkingStall", x = 377, y = 9820, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "medium", type = "ParkingStall", x = 368, y = 9865, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "trailerpark", type = "ParkingStall", x = 419, y = 9658, z = 0, width = 6, height = 5, properties = { Direction = "N" } },

	{ name = "medium", type = "ParkingStall", x = 408, y = 9751, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "bad", type = "ParkingStall", x = 414, y = 9835, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "bad", type = "ParkingStall", x = 418, y = 9835, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "medium", type = "ParkingStall", x = 454, y = 9770, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "medium", type = "ParkingStall", x = 464, y = 9657, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "farm", type = "ParkingStall", x = 467, y = 9655, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },

	{ name = "medium", type = "ParkingStall", x = 487, y = 9739, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "medium", type = "ParkingStall", x = 521, y = 9703, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "medium", type = "ParkingStall", x = 523, y = 9910, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "mccoy", type = "ParkingStall", x = 529, y = 9911, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "good", type = "ParkingStall", x = 508, y = 9304, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "farm", type = "ParkingStall", x = 513, y = 9312, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "medium", type = "ParkingStall", x = 502, y = 9318, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "good", type = "ParkingStall", x = 443, y = 9408, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "farm", type = "ParkingStall", x = 452, y = 9387, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "medium", type = "ParkingStall", x = 452, y = 9394, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "sport", type = "ParkingStall", x = 562, y = 9652, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 581, y = 9720, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "bad", type = "ParkingStall", x = 581, y = 9727, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "farm", type = "ParkingStall", x = 624, y = 9727, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "bad", type = "ParkingStall", x = 625, y = 9730, z = 0, width = 4, height = 4, properties = { Direction = "SW", FaceDirection = true } },

	{ name = "parkingstall", type = "ParkingStall", x = 649, y = 9617, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "medium", type = "ParkingStall", x = 691, y = 9611, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "medium", type = "ParkingStall", x = 687, y = 9821, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "medium", type = "ParkingStall", x = 721, y = 9612, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "medium", type = "ParkingStall", x = 1007, y = 9662, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "medium", type = "ParkingStall", x = 1024, y = 9666, z = 0, width = 3, height = 4, properties = { Direction = "S" } },

	{ name = "good", type = "ParkingStall", x = 959, y = 9819, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "bad", type = "ParkingStall", x = 966, y = 9819, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "farm", type = "ParkingStall", x = 971, y = 9803, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },

	{ name = "good", type = "ParkingStall", x = 927, y = 9906, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "good", type = "ParkingStall", x = 932, y = 9939, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

--Farms
	{ name = "good", type = "ParkingStall", x = 64, y = 9428, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "farm", type = "ParkingStall", x = 70, y = 9431, z = 0, width = 6, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "medium", type = "ParkingStall", x = 56, y = 9438, z = 0, width = 5, height = 6, properties = { Direction = "E" } },

	{ name = "sport", type = "ParkingStall", x = 246, y = 9748, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "farm", type = "ParkingStall", x = 251, y = 9765, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "farm", type = "ParkingStall", x = 288, y = 9837, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },

	{ name = "bad", type = "ParkingStall", x = 1976, y = 8584, z = 0, width = 5, height = 6, properties = { Direction = "E" } },
	{ name = "bad", type = "ParkingStall", x = 1977, y = 8577, z = 0, width = 5, height = 6, properties = { Direction = "N" } },
	{ name = "farm", type = "ParkingStall", x = 2064, y = 8544, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },

	{ name = "good", type = "ParkingStall", x = 1716, y = 8622, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "farm", type = "ParkingStall", x = 1728, y = 8665, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "farm", type = "ParkingStall", x = 1925, y = 8823, z = 0, width = 5, height = 9, properties = { Direction = "W", FaceDirection = true } },
	{ name = "farm", type = "ParkingStall", x = 1895, y = 8849, z = 0, width = 9, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "medium", type = "ParkingStall", x = 1950, y = 8854, z = 0, width = 12, height = 5, properties = { Direction = "S" } },

	{ name = "farm", type = "ParkingStall", x = 959, y = 9074, z = 0, width = 5, height = 6, properties = { Direction = "W", FaceDirection = true } },
	{ name = "medium", type = "ParkingStall", x = 985, y = 9072, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "farm", type = "ParkingStall", x = 1414, y = 9094, z = 0, width = 5, height = 6, properties = { Direction = "W", FaceDirection = true } },
	{ name = "medium", type = "ParkingStall", x = 1417, y = 9116, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "medium", type = "ParkingStall", x = 1410, y = 9116, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "farm", type = "ParkingStall", x = 1622, y = 9016, z = 0, width = 12, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "bad", type = "ParkingStall", x = 1680, y = 9049, z = 0, width = 6, height = 5, properties = { Direction = "N" } },
	{ name = "sport", type = "ParkingStall", x = 1641, y = 9080, z = 0, width = 5, height = 6, properties = { Direction = "E" } },
	{ name = "sport", type = "ParkingStall", x = 1641, y = 9085, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "medium", type = "ParkingStall", x = 1467, y = 9867, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "medium", type = "ParkingStall", x = 1467, y = 9877, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "farm", type = "ParkingStall", x = 885, y = 10353, z = 0, width = 6, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "farm", type = "ParkingStall", x = 882, y = 10397, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "farm", type = "ParkingStall", x = 867, y = 10397, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "farm", type = "ParkingStall", x = 864, y = 10428, z = 0, width = 6, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "farm", type = "ParkingStall", x = 894, y = 10438, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "farm", type = "ParkingStall", x = 831, y = 10487, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "medium", type = "ParkingStall", x = 868, y = 10696, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "farm", type = "ParkingStall", x = 880, y = 10697, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },

	{ name = "medium", type = "ParkingStall", x = 762, y = 10822, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "farm", type = "ParkingStall", x = 924, y = 11446, z = 0, width = 5, height = 12, properties = { Direction = "E", FaceDirection = true } },
	{ name = "medium", type = "ParkingStall", x = 924, y = 11500, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "medium", type = "ParkingStall", x = 929, y = 11500, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "good", type = "ParkingStall", x = 955, y = 11475, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "farm", type = "ParkingStall", x = 1213, y = 11643, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "medium", type = "ParkingStall", x = 1239, y = 11649, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "bad", type = "ParkingStall", x = 1252, y = 12024, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "bad", type = "ParkingStall", x = 1257, y = 12024, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "medium", type = "ParkingStall", x = 1240, y = 12074, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "medium", type = "ParkingStall", x = 1246, y = 12074, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "farm", type = "ParkingStall", x = 1246, y = 12101, z = 0, width = 9, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "good", type = "ParkingStall", x = 1645, y = 11911, z = 0, width = 3, height = 4, properties = { Direction = "S" } },
	{ name = "parkingstall", type = "ParkingStall", x = 1660, y = 11913, z = 0, width = 6, height = 5, properties = { Direction = "N" } },

	{ name = "medium", type = "ParkingStall", x = 855, y = 12100, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "good", type = "ParkingStall", x = 861, y = 12100, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "medium", type = "ParkingStall", x = 857, y = 12156, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "good", type = "ParkingStall", x = 863, y = 12156, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "medium", type = "ParkingStall", x = 854, y = 12199, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "good", type = "ParkingStall", x = 860, y = 12199, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "farm", type = "ParkingStall", x = 876, y = 12482, z = 0, width = 6, height = 5, properties = { Direction = "S", FaceDirection = true } },

--Other
	{ name = "parkingstall", type = "ParkingStall", x = 336, y = 9907, z = 0, width = 15, height = 5, properties = { Direction = "S" } },
	{ name = "farm", type = "ParkingStall", x = 352, y = 9907, z = 0, width = 6, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "parkingstall", type = "ParkingStall", x = 389, y = 9907, z = 0, width = 5, height = 9, properties = { Direction = "W" } },

	{ name = "parkingstall", type = "ParkingStall", x = 881, y = 9870, z = 0, width = 5, height = 12, properties = { Direction = "W" } },

--Echo Creek
--Intersection Mad Dan's Den
	{ name = "medium", type = "ParkingStall", x = 4298, y = 9512, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "good", type = "ParkingStall", x = 4302, y = 9512, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 4239, y = 9571, z = 0, width = 6, height = 5, properties = { Direction = "S" } },

	{ name = "good", type = "ParkingStall", x = 4249, y = 9610, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "bad", type = "ParkingStall", x = 4254, y = 9619, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "good", type = "ParkingStall", x = 4384, y = 9789, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "bad", type = "ParkingStall", x = 4374, y = 9792, z = 0, width = 6, height = 5, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 4169, y = 9941, z = 0, width = 5, height = 6, properties = { Direction = "W" } },

	{ name = "bad", type = "ParkingStall", x = 4095, y = 9930, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "bad", type = "ParkingStall", x = 4086, y = 9931, z = 0, width = 6, height = 5, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 3857, y = 9945, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "medium", type = "ParkingStall", x = 3857, y = 9951, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "bad", type = "ParkingStall", x = 3940, y = 9836, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "medium", type = "ParkingStall", x = 3962, y = 9860, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "bad", type = "ParkingStall", x = 3962, y = 9868, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 4031, y = 9875, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 4084, y = 9873, z = 0, width = 5, height = 6, properties = { Direction = "E" } },

	{ name = "bad", type = "ParkingStall", x = 4106, y = 9867, z = 0, width = 5, height = 9, properties = { Direction = "E" } },

	{ name = "bad", type = "ParkingStall", x = 3454, y = 10144, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "medium", type = "ParkingStall", x = 3459, y = 10148, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "bad", type = "ParkingStall", x = 3180, y = 9823, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "sport", type = "ParkingStall", x = 3187, y = 9829, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

--Garages
	{ name = "bad", type = "ParkingStall", x = 3578, y = 10897, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "bad", type = "ParkingStall", x = 3582, y = 10897, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "sport", type = "ParkingStall", x = 3672, y = 10894, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "sport", type = "ParkingStall", x = 3676, y = 10894, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "bad", type = "ParkingStall", x = 3681, y = 10894, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "bad", type = "ParkingStall", x = 3469, y = 11008, z = 0, width = 3, height = 4, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 3538, y = 11128, z = 0, width = 4, height = 3, properties = { Direction = "E" } },

	{ name = "bad", type = "ParkingStall", x = 3718, y = 10953, z = 0, width = 3, height = 4, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 3751, y = 11224, z = 0, width = 3, height = 4, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 4174, y = 11595, z = 0, width = 4, height = 3, properties = { Direction = "E" } },

	{ name = "bad", type = "ParkingStall", x = 4214, y = 11641, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "bad", type = "ParkingStall", x = 4211, y = 11676, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "bad", type = "ParkingStall", x = 1843, y = 9273, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "sport", type = "ParkingStall", x = 1850, y = 9273, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "parkingstall", type = "ParkingStall", x = 1552, y = 9959, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "medium", type = "ParkingStall", x = 1563, y = 9959, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "sport", type = "ParkingStall", x = 1999, y = 9840, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

--Meadshire
	{ name = "good", type = "ParkingStall", x = 4098, y = 9436, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "medium", type = "ParkingStall", x = 4140, y = 9420, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "good", type = "ParkingStall", x = 4165, y = 9436, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "good", type = "ParkingStall", x = 4087, y = 9364, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "sport", type = "ParkingStall", x = 4121, y = 9363, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "medium", type = "ParkingStall", x = 4106, y = 9414, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "good", type = "ParkingStall", x = 4140, y = 9414, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "sport", type = "ParkingStall", x = 4174, y = 9414, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "sport", type = "ParkingStall", x = 4106, y = 9461, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "medium", type = "ParkingStall", x = 4142, y = 9461, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "medium", type = "ParkingStall", x = 4178, y = 9462, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "good", type = "ParkingStall", x = 4097, y = 9390, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "good", type = "ParkingStall", x = 4098, y = 9441, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "good", type = "ParkingStall", x = 4133, y = 9442, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "good", type = "ParkingStall", x = 4165, y = 9441, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "medium", type = "ParkingStall", x = 4066, y = 9392, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "medium", type = "ParkingStall", x = 4065, y = 9426, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

--Farms
	{ name = "farm", type = "ParkingStall", x = 2430, y = 10045, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "medium", type = "ParkingStall", x = 2495, y = 9952, z = 0, width = 5, height = 6, properties = { Direction = "E" } },

	{ name = "medium", type = "ParkingStall", x = 2863, y = 10408, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "medium", type = "ParkingStall", x = 2871, y = 10408, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "farm", type = "ParkingStall", x = 2902, y = 10398, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },

	{ name = "medium", type = "ParkingStall", x = 4020, y = 10110, z = 0, width = 5, height = 9, properties = { Direction = "E" } },
	{ name = "farm", type = "ParkingStall", x = 4027, y = 10147, z = 0, width = 9, height = 5, properties = { Direction = "N", FaceDirection = true } },

--Valley Station
	{ name = "parkingstall", type = "ParkingStall", x = 12568, y = 5397, z = 0, width = 5, height = 12, properties = { Direction = "W" } },
	{ name = "junkyard", type = "ParkingStall", x = 12583, y = 5391, z = 0, width = 6, height = 20, properties = { Direction = "S" } },
	{ name = "junkyard", type = "ParkingStall", x = 12583, y = 5412, z = 0, width = 20, height = 6, properties = { Direction = "W" } },
	{ name = "junkyard", type = "ParkingStall", x = 12597, y = 5391, z = 0, width = 6, height = 20, properties = { Direction = "S" } },
	{ name = "junkyard", type = "ParkingStall", x = 12576, y = 5363, z = 0, width = 20, height = 6, properties = { Direction = "E" } },
	{ name = "junkyard", type = "ParkingStall", x = 12597, y = 5363, z = 0, width = 6, height = 20, properties = { Direction = "N" } },
	{ name = "junkyard", type = "ParkingStall", x = 12576, y = 5377, z = 0, width = 20, height = 6, properties = { Direction = "E" } },

	{ name = "bad", type = "ParkingStall", x = 12794, y = 6383, z = 0, width = 5, height = 42, properties = { Direction = "W" } },
	{ name = "bad", type = "ParkingStall", x = 12811, y = 6400, z = 0, width = 5, height = 24, properties = { Direction = "E" } },
	{ name = "sport", type = "ParkingStall", x = 12832, y = 6269, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "sport", type = "ParkingStall", x = 12850, y = 6239, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "sport", type = "ParkingStall", x = 12832, y = 6204, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "sport", type = "ParkingStall", x = 12832, y = 6194, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },

	{ name = "parkingstall", type = "ParkingStall", x = 13307, y = 4963, z = 0, width = 12, height = 5, properties = { Direction = "N" } },
	{ name = "parkingstall", type = "ParkingStall", x = 13307, y = 4982, z = 0, width = 12, height = 5, properties = { Direction = "S" } },
	{ name = "parkingstall", type = "ParkingStall", x = 13302, y = 4965, z = 0, width = 5, height = 21, properties = { Direction = "W" } },

	{ name = "rtrafficjams", type = "ParkingStall", x = 13252, y = 5416, z = 0, width = 18, height = 15, properties = { Direction = "S", FaceDirection = true } },
	{ name = "parkingstall", type = "ParkingStall", x = 13250, y = 5433, z = 0, width = 3, height = 20, properties = { Direction = "N", FaceDirection = true } },
	{ name = "farm", type = "ParkingStall", x = 13252, y = 5461, z = 0, width = 12, height = 5, properties = { Direction = "N" } },
	{ name = "bad", type = "ParkingStall", x = 13244, y = 5472, z = 0, width = 21, height = 5, properties = { Direction = "S" } },
	{ name = "burnt", type = "ParkingStall", x = 13328, y = 5436, z = 0, width = 6, height = 20, properties = { Direction = "N" } },

	{ name = "bad", type = "ParkingStall", x = 13092, y = 5312, z = 0, width = 6, height = 5, properties = { Direction = "N" } },
	{ name = "bad", type = "ParkingStall", x = 13122, y = 5312, z = 0, width = 9, height = 5, properties = { Direction = "N" } },

	{ name = "parkingstall", type = "ParkingStall", x = 13085, y = 5457, z = 0, width = 18, height = 5, properties = { Direction = "N" } },
	{ name = "parkingstall", type = "ParkingStall", x = 13095, y = 5468, z = 0, width = 18, height = 5, properties = { Direction = "S" } },

	{ name = "medium", type = "ParkingStall", x = 13612, y = 4807, z = 0, width = 4, height = 3, properties = { Direction = "W" } },
	{ name = "farm", type = "ParkingStall", x = 13555, y = 4730, z = 0, width = 5, height = 27, properties = { Direction = "W", FaceDirection = true } },

	{ name = "medium", type = "ParkingStall", x = 13557, y = 4617, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "medium", type = "ParkingStall", x = 13555, y = 5045, z = 0, width = 5, height = 9, properties = { Direction = "E" } },
	{ name = "farm", type = "ParkingStall", x = 13519, y = 5048, z = 0, width = 21, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "medium", type = "ParkingStall", x = 13383, y = 5062, z = 0, width = 5, height = 6, properties = { Direction = "E" } },

	{ name = "farm", type = "ParkingStall", x = 13859, y = 4629, z = 0, width = 21, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "medium", type = "ParkingStall", x = 14400, y = 4566, z = 0, width = 5, height = 6, properties = { Direction = "E" } },
	{ name = "farm", type = "ParkingStall", x = 14400, y = 4586, z = 0, width = 5, height = 21, properties = { Direction = "W", FaceDirection = true } },

	{ name = "medium", type = "ParkingStall", x = 14535, y = 4968, z = 0, width = 5, height = 15, properties = { Direction = "W" } },

	{ name = "farm", type = "ParkingStall", x = 14292, y = 5072, z = 0, width = 5, height = 6, properties = { Direction = "W", FaceDirection = true } },

	{ name = "medium", type = "ParkingStall", x = 14355, y = 5451, z = 0, width = 6, height = 5, properties = { Direction = "S" } },
	{ name = "farm", type = "ParkingStall", x = 14317, y = 5414, z = 0, width = 5, height = 18, properties = { Direction = "W", FaceDirection = true } },

--Garages
	{ name = "sport", type = "ParkingStall", x = 12959, y = 4877, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "sport", type = "ParkingStall", x = 12967, y = 4877, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "sport", type = "ParkingStall", x = 12970, y = 4894, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

--Other
	{ name = "knoxtelecomms", type = "ParkingStall", x = 13397, y = 4906, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },

	{ name = "knoxtelecomms", type = "ParkingStall", x = 13560, y = 5713, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },

--Fallas Lake
--Garages
	{ name = "bad", type = "ParkingStall", x = 7343, y = 8187, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "bad", type = "ParkingStall", x = 7331, y = 8223, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "bad", type = "ParkingStall", x = 7331, y = 8228, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "bad", type = "ParkingStall", x = 7434, y = 8350, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "bad", type = "ParkingStall", x = 7311, y = 8473, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "sport", type = "ParkingStall", x = 7310, y = 8537, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "sport", type = "ParkingStall", x = 7248, y = 8480, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

--Surrounding Area
	{ name = "parkingstall", type = "ParkingStall", x = 6110, y = 8051, z = 0, width = 5, height = 9, properties = { Direction = "W", FaceDirection = true } },
	{ name = "farm", type = "ParkingStall", x = 6104, y = 8038, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "bad", type = "ParkingStall", x = 6370, y = 7677, z = 0, width = 10, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "farm", type = "ParkingStall", x = 6364, y = 7674, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "good", type = "ParkingStall", x = 6360, y = 7619, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "bad", type = "ParkingStall", x = 6376, y = 7623, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "farm", type = "ParkingStall", x = 6392, y = 7574, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "good", type = "ParkingStall", x = 6400, y = 7579, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "bad", type = "ParkingStall", x = 6386, y = 7581, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "farm", type = "ParkingStall", x = 6431, y = 7525, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "good", type = "ParkingStall", x = 6431, y = 7547, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "bad", type = "ParkingStall", x = 6447, y = 7535, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "bad", type = "ParkingStall", x = 6441, y = 7538, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "good", type = "ParkingStall", x = 6477, y = 7567, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "bad", type = "ParkingStall", x = 6499, y = 7558, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "bad", type = "ParkingStall", x = 6496, y = 7548, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "bad", type = "ParkingStall", x = 5466, y = 9651, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "bad", type = "ParkingStall", x = 5466, y = 9660, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },

	{ name = "bad", type = "ParkingStall", x = 5547, y = 9725, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 5587, y = 9718, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 5647, y = 9743, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "bad", type = "ParkingStall", x = 5714, y = 9744, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "bad", type = "ParkingStall", x = 5753, y = 9714, z = 0, width = 5, height = 6, properties = { Direction = "W" } },

	{ name = "bad", type = "ParkingStall", x = 5735, y = 9676, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "parkingstall", type = "ParkingStall", x = 5846, y = 9420, z = 0, width = 5, height = 15, properties = { Direction = "W" } },
	{ name = "parkingstall", type = "ParkingStall", x = 5855, y = 9422, z = 0, width = 5, height = 12, properties = { Direction = "E" } },
	{ name = "parkingstall", type = "ParkingStall", x = 5924, y = 9449, z = 0, width = 21, height = 5, properties = { Direction = "N" } },

	{ name = "bad", type = "ParkingStall", x = 5979, y = 9361, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "bad", type = "ParkingStall", x = 5810, y = 9630, z = 0, width = 5, height = 6, properties = { Direction = "E" } },

	{ name = "bad", type = "ParkingStall", x = 5877, y = 9604, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 5952, y = 9601, z = 0, width = 5, height = 6, properties = { Direction = "W" } },

	{ name = "bad", type = "ParkingStall", x = 5798, y = 9839, z = 0, width = 5, height = 6, properties = { Direction = "E" } },

	{ name = "bad", type = "ParkingStall", x = 6820, y = 7225, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "bad", type = "ParkingStall", x = 6820, y = 7229, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "bad", type = "ParkingStall", x = 6850, y = 7193, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "bad", type = "ParkingStall", x = 6888, y = 7223, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "junkyard", type = "ParkingStall", x = 6931, y = 8073, z = 0, width = 5, height = 6, properties = { Direction = "E" } },

	{ name = "bad", type = "ParkingStall", x = 6645, y = 8701, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "bad", type = "ParkingStall", x = 6645, y = 8713, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 6819, y = 8879, z = 0, width = 5, height = 6, properties = { Direction = "E" } },

	{ name = "bad", type = "ParkingStall", x = 6962, y = 9350, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 7208, y = 9713, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "bad", type = "ParkingStall", x = 7182, y = 97420, z = 0, width = 6, height = 5, properties = { Direction = "N" } },

	{ name = "bad", type = "ParkingStall", x = 6907, y = 10593, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "bad", type = "ParkingStall", x = 6972, y = 10636, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "bad", type = "ParkingStall", x = 7236, y = 10553, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "bad", type = "ParkingStall", x = 7276, y = 10723, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "bad", type = "ParkingStall", x = 7345, y = 10748, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "bad", type = "ParkingStall", x = 7309, y = 10862, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 7458, y = 10803, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "bad", type = "ParkingStall", x = 7679, y = 11072, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 7683, y = 11117, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "bad", type = "ParkingStall", x = 7942, y = 8676, z = 0, width = 6, height = 5, properties = { Direction = "S" } },
	{ name = "bad", type = "ParkingStall", x = 7950, y = 8743, z = 0, width = 3, height = 10, properties = { Direction = "N" } },
	{ name = "bad", type = "ParkingStall", x = 7973, y = 8716, z = 0, width = 10, height = 3, properties = { Direction = "W" } },

	{ name = "bad", type = "ParkingStall", x = 7887, y = 10180, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "bad", type = "ParkingStall", x = 7919, y = 10182, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 8424, y = 8531, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 8492, y = 8550, z = 0, width = 12, height = 5, properties = { Direction = "N" } },

	{ name = "bad", type = "ParkingStall", x = 8455, y = 8591, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "bad", type = "ParkingStall", x = 8428, y = 8608, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "bad", type = "ParkingStall", x = 8474, y = 8640, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "bad", type = "ParkingStall", x = 8478, y = 8638, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "bad", type = "ParkingStall", x = 8545, y = 8636, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "bad", type = "ParkingStall", x = 8561, y = 8603, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 8581, y = 8717, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "bad", type = "ParkingStall", x = 8703, y = 9257, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "bad", type = "ParkingStall", x = 8711, y = 9286, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "bad", type = "ParkingStall", x = 8544, y = 9423, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "bad", type = "ParkingStall", x = 8544, y = 9427, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "bad", type = "ParkingStall", x = 9038, y = 8740, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "bad", type = "ParkingStall", x = 9119, y = 9342, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

--Farms
	{ name = "farm", type = "ParkingStall", x = 5507, y = 9982, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "bad", type = "ParkingStall", x = 5505, y = 9998, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "farm", type = "ParkingStall", x = 5272, y = 10105, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "medium", type = "ParkingStall", x = 5262, y = 10124, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "medium", type = "ParkingStall", x = 5372, y = 10234, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "medium", type = "ParkingStall", x = 5322, y = 10316, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "farm", type = "ParkingStall", x = 5323, y = 10327, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "medium", type = "ParkingStall", x = 5277, y = 10486, z = 0, width = 6, height = 5, properties = { Direction = "S" } },
	{ name = "bad", type = "ParkingStall", x = 5320, y = 10463, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "farm", type = "ParkingStall", x = 5330, y = 10475, z = 0, width = 6, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "farm", type = "ParkingStall", x = 5310, y = 10532, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "farm", type = "ParkingStall", x = 5321, y = 10542, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "medium", type = "ParkingStall", x = 5316, y = 10560, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "farm", type = "ParkingStall", x = 6103, y = 9546, z = 0, width = 6, height = 5, properties = { Direction = "S", FaceDirection = true } },

	{ name = "farm", type = "ParkingStall", x = 6151, y = 9622, z = 0, width = 6, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "farm", type = "ParkingStall", x = 6931, y = 7265, z = 0, width = 5, height = 6, properties = { Direction = "E", FaceDirection = true } },

	{ name = "medium", type = "ParkingStall", x = 6823, y = 7697, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "mccoy", type = "ParkingStall", x = 6827, y = 7720, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "bad", type = "ParkingStall", x = 6830, y = 7720, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "farm", type = "ParkingStall", x = 6853, y = 7833, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },

	{ name = "medium", type = "ParkingStall", x = 6608, y = 8850, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "medium", type = "ParkingStall", x = 6666, y = 8893, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "medium", type = "ParkingStall", x = 6646, y = 8943, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "medium", type = "ParkingStall", x = 6507, y = 9144, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "medium", type = "ParkingStall", x = 6507, y = 9168, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "farm", type = "ParkingStall", x = 6514, y = 9162, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },

	{ name = "farm", type = "ParkingStall", x = 7128, y = 9127, z = 0, width = 5, height = 12, properties = { Direction = "E", FaceDirection = true } },

	{ name = "farm", type = "ParkingStall", x = 7147, y = 9607, z = 0, width = 6, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "medium", type = "ParkingStall", x = 7156, y = 9619, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "bad", type = "ParkingStall", x = 7155, y = 9626, z = 0, width = 5, height = 9, properties = { Direction = "W" } },
	{ name = "medium", type = "ParkingStall", x = 7167, y = 9677, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "farm", type = "ParkingStall", x = 7984, y = 11055, z = 0, width = 9, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "medium", type = "ParkingStall", x = 7976, y = 11050, z = 0, width = 3, height = 15, properties = { Direction = "N" } },

	{ name = "medium", type = "ParkingStall", x = 7921, y = 8740, z = 0, width = 9, height = 5, properties = { Direction = "N" } },
	{ name = "farm", type = "ParkingStall", x = 7923, y = 8748, z = 0, width = 9, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "farm", type = "ParkingStall", x = 7532, y = 10276, z = 0, width = 5, height = 9, properties = { Direction = "E", FaceDirection = true } },
	{ name = "bad", type = "ParkingStall", x = 7664, y = 10134, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "farm", type = "ParkingStall", x = 7657, y = 10176, z = 0, width = 18, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "trailerpark", type = "ParkingStall", x = 7703, y = 10136, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "trailerpark", type = "ParkingStall", x = 7705, y = 10150, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "trailerpark", type = "ParkingStall", x = 7727, y = 10139, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "farm", type = "ParkingStall", x = 8023, y = 10172, z = 0, width = 5, height = 6, properties = { Direction = "W", FaceDirection = true } },

	{ name = "medium", type = "ParkingStall", x = 8587, y = 8820, z = 0, width = 5, height = 12, properties = { Direction = "W" } },
	{ name = "farm", type = "ParkingStall", x = 8574, y = 8855, z = 0, width = 5, height = 15, properties = { Direction = "E", FaceDirection = true } },

	{ name = "farm", type = "ParkingStall", x = 8491, y = 9463, z = 0, width = 5, height = 9, properties = { Direction = "E", FaceDirection = true } },

	{ name = "farm", type = "ParkingStall", x = 8906, y = 9140, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "farm", type = "ParkingStall", x = 8881, y = 9165, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "farm", type = "ParkingStall", x = 8862, y = 9208, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "medium", type = "ParkingStall", x = 8918, y = 9205, z = 0, width = 6, height = 5, properties = { Direction = "N" } },
	{ name = "farm", type = "ParkingStall", x = 8965, y = 9134, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "farm", type = "ParkingStall", x = 8981, y = 9142, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "bad", type = "ParkingStall", x = 8975, y = 9182, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "medium", type = "ParkingStall", x = 8983, y = 9188, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

--Other
	{ name = "postal", type = "ParkingStall", x = 7259, y = 8473, z = 0, width = 6, height = 5, properties = { Direction = "S" } },

	{ name = "knoxtelecomms", type = "ParkingStall", x = 6742, y = 6853, z = 0, width = 4, height = 4, properties = { Direction = "NE", FaceDirection = true } },

	{ name = "lectromax", type = "ParkingStall", x = 6748, y = 6852, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

--Doe Valley
	{ name = "parkingstall", type = "ParkingStall", x = 3668, y = 5778, z = 0, width = 5, height = 33, properties = { Direction = "W" } },
	{ name = "parkingstall", type = "ParkingStall", x = 3683, y = 5778, z = 0, width = 5, height = 12, properties = { Direction = "E" } },
	{ name = "parkingstall", type = "ParkingStall", x = 3683, y = 5799, z = 0, width = 5, height = 12, properties = { Direction = "E" } },

	{ name = "parkingstall", type = "ParkingStall", x = 3661, y = 5959, z = 0, width = 5, height = 12, properties = { Direction = "W" } },

	{ name = "parkingstall", type = "ParkingStall", x = 4109, y = 6427, z = 0, width = 48, height = 5, properties = { Direction = "S" } },
	{ name = "parkingstall", type = "ParkingStall", x = 3998, y = 6485, z = 0, width = 33, height = 5, properties = { Direction = "N" } },
	{ name = "parkingstall", type = "ParkingStall", x = 4060, y = 6500, z = 0, width = 21, height = 5, properties = { Direction = "S" } },
	{ name = "parkingstall", type = "ParkingStall", x = 4010, y = 6538, z = 0, width = 18, height = 5, properties = { Direction = "N" } },
	{ name = "parkingstall", type = "ParkingStall", x = 4061, y = 6538, z = 0, width = 18, height = 5, properties = { Direction = "N" } },
	{ name = "parkingstall", type = "ParkingStall", x = 4029, y = 6557, z = 0, width = 39, height = 5, properties = { Direction = "N" } },
	{ name = "parkingstall", type = "ParkingStall", x = 4029, y = 6572, z = 0, width = 57, height = 5, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 3959, y = 5775, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "bad", type = "ParkingStall", x = 3959, y = 5782, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },

	{ name = "medium", type = "ParkingStall", x = 4110, y = 5876, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "bad", type = "ParkingStall", x = 4242, y = 5895, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "farm", type = "ParkingStall", x = 4251, y = 5894, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "farm", type = "ParkingStall", x = 4525, y = 5730, z = 0, width = 6, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "bad", type = "ParkingStall", x = 4561, y = 5743, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },

	{ name = "medium", type = "ParkingStall", x = 4731, y = 5709, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

	{ name = "bad", type = "ParkingStall", x = 4802, y = 5753, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "medium", type = "ParkingStall", x = 4832, y = 5734, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "farm", type = "ParkingStall", x = 4858, y = 5761, z = 0, width = 6, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "medium", type = "ParkingStall", x = 4883, y = 5759, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "bad", type = "ParkingStall", x = 5156, y = 5526, z = 0, width = 3, height = 4, properties = { Direction = "S" } },
	{ name = "medium", type = "ParkingStall", x = 5188, y = 5524, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "medium", type = "ParkingStall", x = 5197, y = 5493, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "medium", type = "ParkingStall", x = 5403, y = 5448, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "farm", type = "ParkingStall", x = 5427, y = 5579, z = 0, width = 6, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "bad", type = "ParkingStall", x = 5428, y = 5959, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "medium", type = "ParkingStall", x = 5428, y = 5964, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },

	{ name = "medium", type = "ParkingStall", x = 6070, y = 6718, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "medium", type = "ParkingStall", x = 6056, y = 6660, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "medium", type = "ParkingStall", x = 6122, y = 6640, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "good", type = "ParkingStall", x = 6167, y = 6645, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "good", type = "ParkingStall", x = 6224, y = 6652, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "medium", type = "ParkingStall", x = 6229, y = 6652, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "good", type = "ParkingStall", x = 6122, y = 6724, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "medium", type = "ParkingStall", x = 6113, y = 6724, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "medium", type = "ParkingStall", x = 6117, y = 6724, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "good", type = "ParkingStall", x = 6179, y = 6723, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "medium", type = "ParkingStall", x = 6185, y = 6723, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "medium", type = "ParkingStall", x = 6222, y = 6714, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "bad", type = "ParkingStall", x = 6231, y = 6719, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "good", type = "ParkingStall", x = 6266, y = 6675, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "medium", type = "ParkingStall", x = 6266, y = 6669, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "good", type = "ParkingStall", x = 6280, y = 6728, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "medium", type = "ParkingStall", x = 6271, y = 6727, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "ranger", type = "ParkingStall", x = 3379, y = 9664, z = 0, width = 9, height = 5, properties = { Direction = "S", FaceDirection = true } },

	{ name = "ranger", type = "ParkingStall", x = 4056, y = 8165, z = 0, width = 5, height = 6, properties = { Direction = "W", FaceDirection = true } },

	{ name = "ranger", type = "ParkingStall", x = 4738, y = 7993, z = 0, width = 3, height = 10, properties = { Direction = "S", FaceDirection = true } },
	
	{ name = "bad", type = "ParkingStall", x = 4997, y = 8026, z = 0, width = 30, height = 5, properties = { Direction = "S" } },
	{ name = "bad", type = "ParkingStall", x = 4997, y = 8031, z = 0, width = 30, height = 5, properties = { Direction = "N" } },
	{ name = "bad", type = "ParkingStall", x = 4997, y = 8042, z = 0, width = 30, height = 5, properties = { Direction = "S" } },
	{ name = "bad", type = "ParkingStall", x = 4997, y = 8047, z = 0, width = 30, height = 5, properties = { Direction = "N" } },

	{ name = "ranger", type = "ParkingStall", x = 4685, y = 8598, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "ranger", type = "ParkingStall", x = 4685, y = 8604, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },

	{ name = "knoxtelecomms", type = "ParkingStall", x = 3542, y = 6098, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "knoxtelecomms", type = "ParkingStall", x = 4496, y = 6069, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "knoxtelecomms", type = "ParkingStall", x = 4194, y = 9888, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },

--Dark Wallow Lake
--Houses
	{ name = "bad", type = "ParkingStall", x = 7724, y = 14540, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "bad", type = "ParkingStall", x = 7727, y = 14581, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "bad", type = "ParkingStall", x = 7727, y = 14709, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "bad", type = "ParkingStall", x = 7787, y = 14561, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "bad", type = "ParkingStall", x = 7788, y = 14596, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "bad", type = "ParkingStall", x = 7783, y = 14660, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "bad", type = "ParkingStall", x = 7794, y = 14660, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "bad", type = "ParkingStall", x = 7773, y = 14704, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "medium", type = "ParkingStall", x = 8938, y = 14851, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "good", type = "ParkingStall", x = 8866, y = 14954, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "medium", type = "ParkingStall", x = 8874, y = 14954, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "good", type = "ParkingStall", x = 8832, y = 15132, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "medium", type = "ParkingStall", x = 8718, y = 15322, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

--Farms
	{ name = "farm", type = "ParkingStall", x = 7365, y = 13673, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },

	{ name = "farm", type = "ParkingStall", x = 7496, y = 14320, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "farm", type = "ParkingStall", x = 7664, y = 14341, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },

	{ name = "farm", type = "ParkingStall", x = 7715, y = 14308, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "farm", type = "ParkingStall", x = 7728, y = 14308, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },

	{ name = "farm", type = "ParkingStall", x = 7926, y = 14308, z = 0, width = 6, height = 5, properties = { Direction = "S", FaceDirection = true } },

	{ name = "farm", type = "ParkingStall", x = 7646, y = 14635, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },

	{ name = "farm", type = "ParkingStall", x = 8187, y = 13987, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },

	{ name = "farm", type = "ParkingStall", x = 8417, y = 13910, z = 0, width = 6, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "good", type = "ParkingStall", x = 8413, y = 13886, z = 0, width = 3, height = 5, properties = { Direction = "S" } },

--Other
	{ name = "ranger", type = "ParkingStall", x = 5708, y = 14542, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "parkingstall", type = "ParkingStall", x = 6056, y = 14539, z = 0, width = 5, height = 21, properties = { Direction = "W" } },
	{ name = "parkingstall", type = "ParkingStall", x = 6066, y = 14539, z = 0, width = 5, height = 21, properties = { Direction = "E" } },

--Jefferson Forest
	{ name = "ranger", type = "ParkingStall", x = 12047, y = 7351, z = 0, width = 12, height = 3, properties = { Direction = "E" } },
	{ name = "parkingstall", type = "ParkingStall", x = 12051, y = 7390, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "parkingstall", type = "ParkingStall", x = 12048, y = 7401, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "parkingstall", type = "ParkingStall", x = 12067, y = 7401, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "parkingstall", type = "ParkingStall", x = 12073, y = 7401, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "parkingstall", type = "ParkingStall", x = 12076, y = 7401, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "ranger", type = "ParkingStall", x = 12168, y = 7406, z = 0, width = 5, height = 6, properties = { Direction = "E" } },

	{ name = "parkingstall", type = "ParkingStall", x = 13742, y = 6686, z = 0, width = 5, height = 18, properties = { Direction = "E" } },
	{ name = "ranger", type = "ParkingStall", x = 13854, y = 6778, z = 0, width = 6, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "parkingstall", type = "ParkingStall", x = 13843, y = 6790, z = 0, width = 15, height = 5, properties = { Direction = "S" } },

}

local newArmyMilitary = {

--LV Checkpoints
	{ name = "military_vehicles", type = "ParkingStall", x = 12508, y = 4351, z = 0, width = 4, height = 4, properties = { Direction = "SE", FaceDirection = true } },
	{ name = "military_vehicles", type = "ParkingStall", x = 12517, y = 4354, z = 0, width = 4, height = 4, properties = { Direction = "SW", FaceDirection = true } },
	{ name = "military_vehicles", type = "ParkingStall", x = 12518, y = 4346, z = 0, width = 3, height = 6, properties = { Direction = "S", FaceDirection = true } },

	{ name = "military_vehicles", type = "ParkingStall", x = 12600, y = 4165, z = 0, width = 3, height = 12, properties = { Direction = "N", FaceDirection = true } },
	{ name = "military_vehicles", type = "ParkingStall", x = 12600, y = 4139, z = 0, width = 3, height = 12, properties = { Direction = "S", FaceDirection = true } },

	{ name = "military", type = "ParkingStall", x = 12601, y = 4065, z = 0, width = 6, height = 3, properties = { Direction = "W", FaceDirection = true } },

	{ name = "military", type = "ParkingStall", x = 12693, y = 3964, z = 0, width = 3, height = 6, properties = { Direction = "N" } },
	{ name = "military", type = "ParkingStall", x = 12698, y = 3962, z = 0, width = 6, height = 3, properties = { Direction = "E" } },
	{ name = "military", type = "ParkingStall", x = 12727, y = 3964, z = 0, width = 3, height = 6, properties = { Direction = "S" } },
	{ name = "military", type = "ParkingStall", x = 12735, y = 3964, z = 0, width = 3, height = 6, properties = { Direction = "N" } },
	{ name = "military", type = "ParkingStall", x = 12746, y = 3962, z = 0, width = 6, height = 3, properties = { Direction = "E" } },
	{ name = "military", type = "ParkingStall", x = 12756, y = 3962, z = 0, width = 6, height = 3, properties = { Direction = "E" } },

	{ name = "military", type = "ParkingStall", x = 12900, y = 3995, z = 0, width = 4, height = 4, properties = { Direction = "NE", FaceDirection = true } },

	{ name = "military_vehicles", type = "ParkingStall", x = 13427, y = 3956, z = 0, width = 3, height = 6, properties = { Direction = "N", FaceDirection = true } },

	{ name = "military_vehicles", type = "ParkingStall", x = 13416, y = 3782, z = 0, width = 3, height = 6, properties = { Direction = "N", FaceDirection = true } },

	{ name = "military_vehicles", type = "ParkingStall", x = 13442, y = 4067, z = 0, width = 3, height = 12, properties = { Direction = "N", FaceDirection = true } },
	{ name = "military", type = "ParkingStall", x = 13447, y = 4076, z = 0, width = 6, height = 3, properties = { Direction = "W" } },

	{ name = "military_vehicles", type = "ParkingStall", x = 13611, y = 4090, z = 0, width = 3, height = 12, properties = { Direction = "S", FaceDirection = true } },

	{ name = "military", type = "ParkingStall", x = 14538, y = 4020, z = 0, width = 6, height = 3, properties = { Direction = "W" } },
	{ name = "military_vehicles", type = "ParkingStall", x = 14528, y = 4032, z = 0, width = 6, height = 3, properties = { Direction = "E" } },
	{ name = "military_vehicles", type = "ParkingStall", x = 14536, y = 4032, z = 0, width = 6, height = 3, properties = { Direction = "E" } },

	{ name = "military_vehicles", type = "ParkingStall", x = 14538, y = 3772, z = 0, width = 3, height = 6, properties = { Direction = "N", FaceDirection = true } },

	{ name = "military", type = "ParkingStall", x = 15584, y = 3902, z = 0, width = 3, height = 6, properties = { Direction = "S", FaceDirection = false } },
	{ name = "military_vehicles", type = "ParkingStall", x = 15585, y = 3960, z = 0, width = 4, height = 4, properties = { Direction = "SW", FaceDirection = true } },
	{ name = "military_vehicles", type = "ParkingStall", x = 15591, y = 3971, z = 0, width = 4, height = 4, properties = { Direction = "NE", FaceDirection = true } },
	{ name = "military_vehicles", type = "ParkingStall", x = 15597, y = 3965, z = 0, width = 4, height = 4, properties = { Direction = "NE", FaceDirection = true } },
	{ name = "military", type = "ParkingStall", x = 15604, y = 3924, z = 0, width = 3, height = 6, properties = { Direction = "N", FaceDirection = true } },
	{ name = "military", type = "ParkingStall", x = 15604, y = 3932, z = 0, width = 3, height = 6, properties = { Direction = "N", FaceDirection = true } },
	{ name = "military", type = "ParkingStall", x = 15650, y = 3916, z = 0, width = 3, height = 24, properties = { Direction = "S", FaceDirection = true } },
	{ name = "military_vehicles", type = "ParkingStall", x = 15529, y = 3894, z = 0, width = 6, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "military_vehicles", type = "ParkingStall", x = 15529, y = 3903, z = 0, width = 6, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "military_vehicles", type = "ParkingStall", x = 15592, y = 3864, z = 0, width = 3, height = 6, properties = { Direction = "N", FaceDirection = true } },
	{ name = "military_vehicles", type = "ParkingStall", x = 15605, y = 3864, z = 0, width = 3, height = 6, properties = { Direction = "N", FaceDirection = true } },

	{ name = "military_vehicles", type = "ParkingStall", x = 15605, y = 3615, z = 0, width = 3, height = 6, properties = { Direction = "N", FaceDirection = true } },

	{ name = "military_vehicles", type = "ParkingStall", x = 15673, y = 3670, z = 0, width = 6, height = 3, properties = { Direction = "E", FaceDirection = true } },

	{ name = "military_vehicles", type = "ParkingStall", x = 15294, y = 3761, z = 0, width = 3, height = 6, properties = { Direction = "N", FaceDirection = true } },

--Mil Red Fac
	{ name = "military", type = "ParkingStall", x = 5576, y = 12435, z = 0, width = 6, height = 21, properties = { Direction = "E" } },
	{ name = "military_vehicles", type = "ParkingStall", x = 5807, y = 12478, z = 0, width = 18, height = 3, properties = { Direction = "W", FaceDirection = true } },

--Brandenburg Checkpoint
	{ name = "military", type = "ParkingStall", x = 1495, y = 5518, z = 0, width = 6, height = 6, properties = { Direction = "S", FaceDirection = true } },
	{ name = "military", type = "ParkingStall", x = 1495, y = 5528, z = 0, width = 6, height = 6, properties = { Direction = "S", FaceDirection = true } },
	{ name = "military_vehicles", type = "ParkingStall", x = 1497, y = 5543, z = 0, width = 3, height = 12, properties = { Direction = "S", FaceDirection = true } },
	{ name = "military_vehicles", type = "ParkingStall", x = 1504, y = 5619, z = 0, width = 3, height = 6, properties = { Direction = "S", FaceDirection = true } },

}

--newConstructionSites
local newGasStation = {

--LV
	--THE FOSSOIL HQ
	{ name = "fossoil", type = "ParkingStall", x = 12035, y = 1584, z = 0, width = 5, height = 48, properties = { Direction = "W" } },
	{ name = "fossoil", type = "ParkingStall", x = 12133, y = 1623, z = 0, width = 5, height = 9, properties = { Direction = "E" } },
	{ name = "fossoil", type = "ParkingStall", x = 12035, y = 1737, z = 0, width = 5, height = 24, properties = { Direction = "W" } },
	{ name = "fossoil", type = "ParkingStall", x = 12029, y = 1762, z = 0, width = 5, height = 30, properties = { Direction = "W" } },

	{ name = "special_gasstation", type = "ParkingStall", x = 12087, y = 2088, z = 0, width = 3, height = 10, properties = { Direction = "N" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12093, y = 2088, z = 0, width = 3, height = 10, properties = { Direction = "N" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12101, y = 2088, z = 0, width = 3, height = 10, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12107, y = 2088, z = 0, width = 3, height = 10, properties = { Direction = "S" } },

	{ name = "special_gasstation", type = "ParkingStall", x = 12272, y = 1628, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12272, y = 1632, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12278, y = 1628, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12278, y = 1632, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12272, y = 1635, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12272, y = 1639, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12278, y = 1635, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12278, y = 1639, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "special_gasstation", type = "ParkingStall", x = 12451, y = 3521, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12451, y = 3527, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12457, y = 3521, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12457, y = 3527, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12451, y = 3533, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12451, y = 3539, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12457, y = 3533, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12457, y = 3539, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "fossoil", type = "ParkingStall", x = 12450, y = 3553, z = 0, width = 3, height = 11, properties = { Direction = "N" } },

	{ name = "special_gasstation", type = "ParkingStall", x = 12535, y = 2536, z = 0, width = 3, height = 10, properties = { Direction = "N", FaceDirection = true } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12541, y = 2536, z = 0, width = 3, height = 10, properties = { Direction = "N", FaceDirection = true } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12546, y = 2536, z = 0, width = 3, height = 10, properties = { Direction = "N", FaceDirection = true } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12552, y = 2536, z = 0, width = 3, height = 10, properties = { Direction = "N", FaceDirection = true } },

	{ name = "special_gasstation", type = "ParkingStall", x = 12704, y = 2235, z = 0, width = 3, height = 10, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12708, y = 2235, z = 0, width = 3, height = 10, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12717, y = 2235, z = 0, width = 3, height = 10, properties = { Direction = "N" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12721, y = 2235, z = 0, width = 3, height = 10, properties = { Direction = "N" } },

	{ name = "special_gasstation", type = "ParkingStall", x = 12908, y = 3013, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12908, y = 3017, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12914, y = 3013, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12914, y = 3017, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12908, y = 3020, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12908, y = 3024, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12914, y = 3020, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12914, y = 3024, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "fossoil", type = "ParkingStall", x = 12926, y = 3007, z = 0, width = 3, height = 11, properties = { Direction = "N" } },

	{ name = "special_gasstation", type = "ParkingStall", x = 12988, y = 2151, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12994, y = 2151, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12988, y = 2155, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12994, y = 2155, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12988, y = 2158, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12994, y = 2158, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12988, y = 2162, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12994, y = 2162, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12988, y = 2166, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12994, y = 2166, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12988, y = 2170, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12994, y = 2170, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12988, y = 2173, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12994, y = 2173, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12988, y = 2177, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12994, y = 2177, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "fossoil", type = "ParkingStall", x = 13021, y = 2145, z = 0, width = 6, height = 5, properties = { Direction = "N" } },

	{ name = "special_gasstation", type = "ParkingStall", x = 13128, y = 1329, z = 0, width = 3, height = 10, properties = { Direction = "N" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 13132, y = 1329, z = 0, width = 3, height = 10, properties = { Direction = "N" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 13139, y = 1329, z = 0, width = 3, height = 10, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 13143, y = 1329, z = 0, width = 3, height = 10, properties = { Direction = "S" } },

	{ name = "special_gasstation", type = "ParkingStall", x = 13376, y = 2969, z = 0, width = 3, height = 10, properties = { Direction = "N" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 13382, y = 2969, z = 0, width = 3, height = 10, properties = { Direction = "N" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 13388, y = 2969, z = 0, width = 3, height = 10, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 13394, y = 2969, z = 0, width = 3, height = 10, properties = { Direction = "S" } },

	{ name = "special_gasstation", type = "ParkingStall", x = 13390, y = 1412, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 13394, y = 1412, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 13397, y = 1412, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 13401, y = 1412, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 13390, y = 1418, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 13394, y = 1418, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 13397, y = 1418, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 13401, y = 1418, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	
	{ name = "special_gasstation", type = "ParkingStall", x = 13551, y = 2141, z = 0, width = 10, height = 3, properties = { Direction = "W" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 13551, y = 2145, z = 0, width = 10, height = 3, properties = { Direction = "W" } },

	{ name = "special_gasstation", type = "ParkingStall", x = 13623, y = 1514, z = 0, width = 3, height = 10, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 13627, y = 1514, z = 0, width = 3, height = 10, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 13623, y = 1529, z = 0, width = 3, height = 10, properties = { Direction = "N" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 13627, y = 1529, z = 0, width = 3, height = 10, properties = { Direction = "N" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 13629, y = 1529, z = 0, width = 3, height = 10, properties = { Direction = "N" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 13633, y = 1529, z = 0, width = 3, height = 10, properties = { Direction = "N" } },

	{ name = "special_gasstation", type = "ParkingStall", x = 13952, y = 3275, z = 0, width = 3, height = 10, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 13956, y = 3275, z = 0, width = 3, height = 10, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 13962, y = 3275, z = 0, width = 3, height = 10, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 13966, y = 3275, z = 0, width = 3, height = 10, properties = { Direction = "S" } },

--Valley Station
	{ name = "special_gasstation", type = "ParkingStall", x = 12656, y = 6511, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12662, y = 6511, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12668, y = 6511, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12674, y = 6511, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12656, y = 6519, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12662, y = 6519, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12668, y = 6519, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12674, y = 6519, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12654, y = 6525, z = 0, width = 24, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12654, y = 6530, z = 0, width = 21, height = 5, properties = { Direction = "NE", FaceDirection = true } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12651, y = 6535, z = 0, width = 15, height = 4, properties = { Direction = "NE", FaceDirection = true } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12648, y = 6540, z = 0, width = 12, height = 4, properties = { Direction = "NE", FaceDirection = true } },

	{ name = "special_gasstation", type = "ParkingStall", x = 12742, y = 5051, z = 0, width = 3, height = 10, properties = { Direction = "N" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12748, y = 5051, z = 0, width = 3, height = 10, properties = { Direction = "N" } },

	{ name = "special_gasstation", type = "ParkingStall", x = 13726, y = 5662, z = 0, width = 3, height = 10, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 13732, y = 5662, z = 0, width = 3, height = 10, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 13740, y = 5662, z = 0, width = 3, height = 10, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 13746, y = 5662, z = 0, width = 3, height = 10, properties = { Direction = "S" } },

--West Point
	{ name = "special_gasstation", type = "ParkingStall", x = 11822, y = 6877, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 11828, y = 6877, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 11822, y = 6881, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 11828, y = 6881, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "special_gasstation", type = "ParkingStall", x = 12062, y = 7145, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12062, y = 7153, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12068, y = 7145, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12068, y = 7153, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12074, y = 7145, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12074, y = 7153, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12080, y = 7145, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 12080, y = 7153, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

--Muldraugh
	{ name = "special_gasstation", type = "ParkingStall", x = 11607, y = 8299, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 11612, y = 8299, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 11607, y = 8305, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 11612, y = 8305, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 11607, y = 8308, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 11612, y = 8308, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 11607, y = 8314, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 11612, y = 8314, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "special_gasstation", type = "ParkingStall", x = 11505, y = 8823, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 11511, y = 8823, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 11505, y = 8829, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 11511, y = 8829, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "special_gasstation", type = "ParkingStall", x = 10611, y = 9757, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 10618, y = 9757, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 10611, y = 9761, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 10618, y = 9761, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 10611, y = 9764, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 10618, y = 9764, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 10611, y = 9768, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 10618, y = 9768, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "fossoil", type = "ParkingStall", x = 10630, y = 9774, z = 0, width = 12, height = 3, properties = { Direction = "W" } },

	{ name = "special_gasstation", type = "ParkingStall", x = 10632, y = 10620, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 10632, y = 10628, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 10638, y = 10620, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 10638, y = 10628, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 10650, y = 10620, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 10650, y = 10628, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 10656, y = 10620, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 10656, y = 10628, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

--March Ridge
	{ name = "special_gasstation", type = "ParkingStall", x = 10136, y = 12803, z = 0, width = 3, height = 10, properties = { Direction = "N" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 10142, y = 12803, z = 0, width = 3, height = 10, properties = { Direction = "N" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 10147, y = 12803, z = 0, width = 3, height = 10, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 10153, y = 12803, z = 0, width = 3, height = 10, properties = { Direction = "S" } },

--Dark Wallow Lake
	{ name = "special_gasstation", type = "ParkingStall", x = 8723, y = 14096, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 8730, y = 14096, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 8724, y = 14100, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 8731, y = 14100, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

--Rosewood
	{ name = "special_gasstation", type = "ParkingStall", x = 8065, y = 11131, z = 0, width = 6, height = 3 },
	{ name = "special_gasstation", type = "ParkingStall", x = 8065, y = 11135, z = 0, width = 6, height = 3 },
	{ name = "special_gasstation", type = "ParkingStall", x = 8065, y = 11140, z = 0, width = 6, height = 3 },
	{ name = "special_gasstation", type = "ParkingStall", x = 8065, y = 11144, z = 0, width = 6, height = 3 },
	{ name = "special_gasstation", type = "ParkingStall", x = 8065, y = 11149, z = 0, width = 6, height = 3 },
	{ name = "special_gasstation", type = "ParkingStall", x = 8065, y = 11153, z = 0, width = 6, height = 3 },
	{ name = "special_gasstation", type = "ParkingStall", x = 8065, y = 11158, z = 0, width = 6, height = 3 },
	{ name = "special_gasstation", type = "ParkingStall", x = 8065, y = 11162, z = 0, width = 6, height = 3 },

	{ name = "special_gasstation", type = "ParkingStall", x = 8258, y = 12212, z = 0, width = 6, height = 3 },
	{ name = "special_gasstation", type = "ParkingStall", x = 8258, y = 12216, z = 0, width = 6, height = 3 },
	{ name = "special_gasstation", type = "ParkingStall", x = 8258, y = 12221, z = 0, width = 6, height = 3 },
	{ name = "special_gasstation", type = "ParkingStall", x = 8258, y = 12225, z = 0, width = 6, height = 3 },
	{ name = "special_gasstation", type = "ParkingStall", x = 8258, y = 12230, z = 0, width = 6, height = 3 },
	{ name = "special_gasstation", type = "ParkingStall", x = 8258, y = 12234, z = 0, width = 6, height = 3 },
	{ name = "special_gasstation", type = "ParkingStall", x = 8258, y = 12239, z = 0, width = 6, height = 3 },
	{ name = "special_gasstation", type = "ParkingStall", x = 8258, y = 12243, z = 0, width = 6, height = 3 },
	{ name = "special_gasstation", type = "ParkingStall", x = 8258, y = 12248, z = 0, width = 6, height = 3 },
	{ name = "special_gasstation", type = "ParkingStall", x = 8258, y = 12252, z = 0, width = 6, height = 3 },
	{ name = "fossoil", type = "ParkingStall", x = 8245, y = 12209, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "fossoil", type = "ParkingStall", x = 8245, y = 12216, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "fossoil", type = "ParkingStall", x = 8245, y = 12223, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "fossoil", type = "ParkingStall", x = 8245, y = 12230, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "fossoil", type = "ParkingStall", x = 8245, y = 12237, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "fossoil", type = "ParkingStall", x = 8245, y = 12244, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },

--Doe Valley
	{ name = "special_gasstation", type = "ParkingStall", x = 3658, y = 5947, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 3659, y = 5951, z = 0, width = 5, height = 3, properties = { Direction = "E" } },

	{ name = "special_gasstation", type = "ParkingStall", x = 3707, y = 8487, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 3713, y = 8487, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 3707, y = 8493, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 3713, y = 8493, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

	{ name = "special_gasstation", type = "ParkingStall", x = 5454, y = 9706, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 5454, y = 9711, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 5460, y = 9706, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 5460, y = 9711, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

--Fallas Lake
	{ name = "special_gasstation", type = "ParkingStall", x = 7306, y = 8175, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 7306, y = 8179, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 7315, y = 8175, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 7315, y = 8179, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

--Riverside
	{ name = "special_gasstation", type = "ParkingStall", x = 5428, y = 5863, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 5428, y = 5868, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 5434, y = 5863, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 5434, y = 5868, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 5428, y = 5872, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 5428, y = 5877, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 5434, y = 5872, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 5434, y = 5877, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "special_gasstation", type = "ParkingStall", x = 5864, y = 5367, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 5864, y = 5372, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 5870, y = 5367, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 5870, y = 5372, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "special_gasstation", type = "ParkingStall", x = 6053, y = 5300, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 6053, y = 5306, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 6057, y = 5300, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 6057, y = 5306, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 6060, y = 5300, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 6060, y = 5306, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 6064, y = 5300, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 6064, y = 5306, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

	{ name = "special_gasstation", type = "ParkingStall", x = 7179, y = 6107, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 7179, y = 6113, z = 0, width = 3, height = 5, properties = { Direction = "N" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 7183, y = 6107, z = 0, width = 3, height = 5, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 7183, y = 6113, z = 0, width = 3, height = 5, properties = { Direction = "N" } },

--Echo Creek
	{ name = "special_gasstation", type = "ParkingStall", x = 3567, y = 10910, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 3573, y = 10910, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 3567, y = 10914, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 3573, y = 10914, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

--Irvington
	{ name = "special_gasstation", type = "ParkingStall", x = 2322, y = 14475, z = 0, width = 3, height = 10, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 2326, y = 14475, z = 0, width = 3, height = 10, properties = { Direction = "S" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 2330, y = 14475, z = 0, width = 3, height = 10, properties = { Direction = "N" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 2334, y = 14475, z = 0, width = 3, height = 10, properties = { Direction = "N" } },

	{ name = "special_gasstation", type = "ParkingStall", x = 2520, y = 14481, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 2526, y = 14481, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 2520, y = 14485, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 2526, y = 14485, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

--Ekron
	{ name = "special_gasstation", type = "ParkingStall", x = 642, y = 9915, z = 0, width = 10, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "special_gasstation", type = "ParkingStall", x = 642, y = 9921, z = 0, width = 10, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "special_gasstation", type = "ParkingStall", x = 642, y = 9924, z = 0, width = 10, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "special_gasstation", type = "ParkingStall", x = 642, y = 9930, z = 0, width = 10, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "special_gasstation", type = "ParkingStall", x = 625, y = 9912, z = 0, width = 5, height = 15, properties = { Direction = "SE", FaceDirection = true } },
	{ name = "special_gasstation", type = "ParkingStall", x = 630, y = 9914, z = 0, width = 5, height = 18, properties = { Direction = "SE", FaceDirection = true } },
	{ name = "special_gasstation", type = "ParkingStall", x = 635, y = 9915, z = 0, width = 5, height = 18, properties = { Direction = "E", FaceDirection = true } },
	{ name = "fossoil", type = "ParkingStall", x = 652, y = 9909, z = 0, width = 22, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "parkingstall", type = "ParkingStall", x = 656, y = 9915, z = 0, width = 5, height = 18, properties = { Direction = "E" } },

--Brandenburg
	{ name = "special_gasstation", type = "ParkingStall", x = 1658, y = 5761, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 1663, y = 5761, z = 0, width = 5, height = 3, properties = { Direction = "W" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 1658, y = 5757, z = 0, width = 5, height = 3, properties = { Direction = "E" } },
	{ name = "special_gasstation", type = "ParkingStall", x = 1663, y = 5757, z = 0, width = 5, height = 3, properties = { Direction = "W" } },

}

local specialLargeTrucks = {

--LV
	{ name = "special_schoolbus", type = "ParkingStall", x = 12242, y = 3066, z = 0, width = 5, height = 15, properties = { Direction = "W", FaceDirection = true } },

	{ name = "special_schoolbus", type = "ParkingStall", x = 12421, y = 2401, z = 0, width = 5, height = 12, properties = { Direction = "E", FaceDirection = true } },	

	{ name = "special_schoolbus", type = "ParkingStall", x = 12487, y = 1883, z = 0, width = 6, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "special_schoolbus", type = "ParkingStall", x = 13074, y = 1772, z = 0, width = 5, height = 18, properties = { Direction = "W", FaceDirection = true } },

	{ name = "parkingstall", type = "ParkingStall", x = 13017, y = 3109, z = 0, width = 18, height = 5, properties = { Direction = "N" } },
	{ name = "special_schoolbus", type = "ParkingStall", x = 13032, y = 3108, z = 0, width = 12, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "special_schoolbus", type = "ParkingStall", x = 13562, y = 2824, z = 0, width = 9, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "parkingstall", type = "ParkingStall", x = 13571, y = 2824, z = 0, width = 36, height = 5, properties = { Direction = "S" } },

	{ name = "special_prisonbus", type = "ParkingStall", x = 12415, y = 1677, z = 0, width = 6, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "special_prisonbus", type = "ParkingStall", x = 12415, y = 1688, z = 0, width = 6, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "special_boxtruck", type = "ParkingStall", x = 12732, y = 2139, z = 0, width = 12, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "special_boxtruck", type = "ParkingStall", x = 13628, y = 1392, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "special_boxtruck", type = "ParkingStall", x = 13628, y = 1398, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },

	{ name = "special_banktruck", type = "ParkingStall", x = 12548, y = 2575, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	
	{ name = "special_banktruck", type = "ParkingStall", x = 12553, y = 1684, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "special_banktruck", type = "ParkingStall", x = 12605, y = 1578, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "special_banktruck", type = "ParkingStall", x = 13411, y = 1336, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },

	{ name = "special_banktruck", type = "ParkingStall", x = 13603, y = 3043, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },

--Rosewood
	{ name = "special_prisonbus", type = "ParkingStall", x = 7540, y = 11830, z = 0, width = 9, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "special_prisonbus", type = "ParkingStall", x = 7540, y = 11859, z = 0, width = 18, height = 5, properties = { Direction = "S", FaceDirection = true } },

	{ name = "special_prisonbus", type = "ParkingStall", x = 7695, y = 11800, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "special_prisonbus", type = "ParkingStall", x = 7695, y = 11807, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "special_prisonbus", type = "ParkingStall", x = 7695, y = 11814, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "special_prisonbus", type = "ParkingStall", x = 7693, y = 11822, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "special_prisonbus", type = "ParkingStall", x = 7716, y = 11883, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },--This vehicle is flipped on it's side

	{ name = "special_schoolbus", type = "ParkingStall", x = 8401, y = 11623, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "special_schoolbus", type = "ParkingStall", x = 8401, y = 11627, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "special_schoolbus", type = "ParkingStall", x = 8401, y = 11631, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "special_schoolbus", type = "ParkingStall", x = 8401, y = 11635, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "special_schoolbus", type = "ParkingStall", x = 8401, y = 11639, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "special_schoolbus", type = "ParkingStall", x = 8401, y = 11643, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "special_schoolbus", type = "ParkingStall", x = 8401, y = 11647, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },

	{ name = "special_boxtruck", type = "ParkingStall", x = 7979, y = 11284, z = 0, width = 5, height = 6, properties = { Direction = "W", FaceDirection = true } },

	{ name = "special_banktruck", type = "ParkingStall", x = 8066, y = 11602, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },

--Muldraugh
	{ name = "special_schoolbus", type = "ParkingStall", x = 10653, y = 9313, z = 0, width = 12, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "special_schoolbus", type = "ParkingStall", x = 10614, y = 10016, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },

	{ name = "special_boxtruck", type = "ParkingStall", x = 10710, y = 10100, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "special_boxtruck", type = "ParkingStall", x = 10049, y = 11026, z = 0, width = 6, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "special_banktruck", type = "ParkingStall", x = 10619, y = 9690, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },

--West Point
	{ name = "special_schoolbus", type = "ParkingStall", x = 11347, y = 6761, z = 0, width = 30, height = 3, properties = { Direction = "E", FaceDirection = true } },

	{ name = "special_boxtruck", type = "ParkingStall", x = 11884, y = 6945, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "special_boxtruck", type = "ParkingStall", x = 12039, y = 6841, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },

--March Ridge
	{ name = "special_schoolbus", type = "ParkingStall", x = 10018, y = 12670, z = 0, width = 5, height = 6, properties = { Direction = "W", FaceDirection = true } },	

	{ name = "special_boxtruck", type = "ParkingStall", x = 10048, y = 12758, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },

--Riverside
	{ name = "special_schoolbus", type = "ParkingStall", x = 6465, y = 5463, z = 0, width = 50, height = 3, properties = { Direction = "W", FaceDirection = true } },

	{ name = "special_banktruck", type = "ParkingStall", x = 6500, y = 5309, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "parkingstall", type = "ParkingStall", x = 6500, y = 5312, z = 0, width = 5, height = 6, properties = { Direction = "E" } },

	{ name = "special_boxtruck", type = "ParkingStall", x = 6494, y = 5362, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },

--Brandenburg
	{ name = "special_prisonbus", type = "ParkingStall", x = 1428, y = 5867, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "special_prisonbus", type = "ParkingStall", x = 1428, y = 5877, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "special_prisonbus", type = "ParkingStall", x = 1428, y = 5887, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "special_prisonbus", type = "ParkingStall", x = 1428, y = 5897, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },

	{ name = "special_schoolbus", type = "ParkingStall", x = 2066, y = 6243, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "special_schoolbus", type = "ParkingStall", x = 2075, y = 6243, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },

	{ name = "special_boxtruck", type = "ParkingStall", x = 1852, y = 6327, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "special_boxtruck", type = "ParkingStall", x = 1858, y = 6327, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "special_boxtruck", type = "ParkingStall", x = 1864, y = 6327, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "special_boxtruck", type = "ParkingStall", x = 1870, y = 6327, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "special_boxtruck", type = "ParkingStall", x = 2032, y = 6347, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },

--Ekron
	{ name = "special_banktruck", type = "ParkingStall", x = 409, y = 9873, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	
--Irvington
	{ name = "special_schoolbus", type = "ParkingStall", x = 2474, y = 14519, z = 0, width = 9, height = 5, properties = { Direction = "N", FaceDirection = true } },
	{ name = "special_schoolbus", type = "ParkingStall", x = 2474, y = 14529, z = 0, width = 9, height = 5, properties = { Direction = "N", FaceDirection = true } },

	{ name = "special_boxtruck", type = "ParkingStall", x = 1814, y = 14764, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },

	{ name = "special_banktruck", type = "ParkingStall", x = 2407, y = 13970, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },

--Valley Station
	{ name = "special_schoolbus", type = "ParkingStall", x = 12937, y = 4843, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "special_schoolbus", type = "ParkingStall", x = 12950, y = 4843, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "special_schoolbus", type = "ParkingStall", x = 12963, y = 4843, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "special_schoolbus", type = "ParkingStall", x = 12976, y = 4843, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },
	{ name = "special_schoolbus", type = "ParkingStall", x = 12989, y = 4843, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },

	{ name = "special_boxtruck", type = "ParkingStall", x = 13588, y = 5743, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },

	{ name = "special_boxtruck", type = "ParkingStall", x = 14004, y = 5799, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } },

	{ name = "special_banktruck", type = "ParkingStall", x = 13672, y = 5743, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },

--LV Airport
	{ name = "special_boxtruck", type = "ParkingStall", x = 15324, y = 3067, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "special_boxtruck", type = "ParkingStall", x = 15334, y = 3067, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "special_boxtruck", type = "ParkingStall", x = 15344, y = 3067, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "special_boxtruck", type = "ParkingStall", x = 15354, y = 3067, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "special_boxtruck", type = "ParkingStall", x = 15364, y = 3067, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "special_boxtruck", type = "ParkingStall", x = 15374, y = 3067, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "special_boxtruck", type = "ParkingStall", x = 15384, y = 3067, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "special_boxtruck", type = "ParkingStall", x = 15394, y = 3067, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "special_boxtruck", type = "ParkingStall", x = 15404, y = 3067, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },
	{ name = "special_boxtruck", type = "ParkingStall", x = 15414, y = 3067, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } },

	{ name = "special_boxtruck", type = "ParkingStall", x = 15339, y = 3177, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "special_boxtruck", type = "ParkingStall", x = 15339, y = 3185, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "special_boxtruck", type = "ParkingStall", x = 15339, y = 3193, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "special_boxtruck", type = "ParkingStall", x = 15339, y = 3201, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	
	{ name = "special_boxtruck", type = "ParkingStall", x = 15340, y = 3240, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "special_boxtruck", type = "ParkingStall", x = 15340, y = 3246, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },
	{ name = "special_boxtruck", type = "ParkingStall", x = 15340, y = 3252, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } },

}

local specialLargeContainers = {

--LV Airport
	{ name = "special_kntnr", type = "ParkingStall", x = 15282, y = 3026, z = 0, width = 3, height = 6, properties = { Direction = "N", FaceDirection = true } },
	{ name = "special_kntnr", type = "ParkingStall", x = 15289, y = 3026, z = 0, width = 3, height = 6, properties = { Direction = "N", FaceDirection = true } },
	{ name = "special_kntnr", type = "ParkingStall", x = 15296, y = 3026, z = 0, width = 3, height = 6, properties = { Direction = "N", FaceDirection = true } },
	{ name = "special_kntnr", type = "ParkingStall", x = 15310, y = 3026, z = 0, width = 3, height = 6, properties = { Direction = "N", FaceDirection = true } },
	{ name = "special_kntnr", type = "ParkingStall", x = 15317, y = 3026, z = 0, width = 3, height = 6, properties = { Direction = "N", FaceDirection = true } },
	
	{ name = "special_kntnr", type = "ParkingStall", x = 15332, y = 3089, z = 0, width = 90, height = 6, properties = { Direction = "S", FaceDirection = true } },

--BB Airport
	{ name = "special_kntnr", type = "ParkingStall", x = 970, y = 6117, z = 0, width = 6, height = 30, properties = { Direction = "W", FaceDirection = true } },
	{ name = "special_kntnr", type = "ParkingStall", x = 977, y = 6117, z = 0, width = 6, height = 30, properties = { Direction = "W", FaceDirection = true } },
	{ name = "special_kntnr", type = "ParkingStall", x = 984, y = 6117, z = 0, width = 6, height = 30, properties = { Direction = "W", FaceDirection = true } },

}


NewVehicleZones = NewVehicleZones or {}

local function specialTrafficJamsSandboxSet()
	if SandboxVars.GamestaVehicleZones.trafficjamsLV then
		for _, v in ipairs(newTrafficLV) do
			table.insert(NewVehicleZones, v)
		end
	end
	if SandboxVars.GamestaVehicleZones.trafficjamsExtra then
		for _, v in ipairs(newTrafficExtra) do
			table.insert(NewVehicleZones, v)
		end
	end
end
Events.OnInitGlobalModData.Add(specialTrafficJamsSandboxSet)

local activatedMods = getActivatedMods()
if activatedMods:contains("87fordB700") or activatedMods:contains("PzkVanillaPlusCarPack") then
	for _, v in ipairs(specialLargeTrucks) do
		table.insert(NewVehicleZones, v)
	end
end

if activatedMods:contains("isoContainers") then
	for _, v in ipairs(specialLargeContainers) do
		table.insert(NewVehicleZones, v)
	end
end

if not activatedMods:contains("VMZNEW") then
	for _, v in ipairs(newArmyMilitary) do
		table.insert(NewVehicleZones, v)
	end
end

for _, v in ipairs(newParkingStalls) do
	table.insert(NewVehicleZones, v)
end

for _, v in ipairs(newGasStation) do
	table.insert(NewVehicleZones, v)
end
