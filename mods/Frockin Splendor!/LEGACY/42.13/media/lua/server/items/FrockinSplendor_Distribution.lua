FrockinSplendor_Distribution = Distributions or {};
 
local distributionTable = {
	
	Bag_FrockinSplendor_Box = {
		ignoreZombieDensity = true,
		rolls = 16,
		items = {
			"Cotton_MiniDress", 15,
				"Cotton_MiniDress_LS", 8,
				"Cotton_MiniDress_HS", 8,
				"Cotton_MiniDress_DS", 8,
			"Cotton_Dress", 15,
				"Cotton_Dress_LS", 8,
				"Cotton_Dress_HS", 8,
				"Cotton_Dress_DS", 8,
			"Cotton_LongDress", 15,
				"Cotton_LongDress_LS", 8,
				"Cotton_LongDress_HS", 8,
				"Cotton_LongDress_DS", 8,
			"Cotton_MicroDress", 15,
				"Cotton_MicroDress_HS", 8,
				"Cotton_MicroDress_DS", 8,
			
			"Leather_MiniDress", 15,
				"Leather_MiniDress_HS", 8,
				"Leather_MiniDress_LS", 8,
			"Leather_LongDress_LS", 15,
				"Leather_LongDress_DS", 8,
				"Leather_LongDress_HS", 8,
			"Leather_Dress", 15,
				"Leather_Dress_HS", 8,
				"Leather_Dress_LS", 8,

			"", 8,
		},
		
	},
	
	Bag_FrockinSplendor_Box_Fancy = {
		ignoreZombieDensity = true,
		rolls = 18,
		items = {
			"zz_FancyDress_A", 8,
			"zz_FancyDress_B", 8,
			"zz_FancyDress_C", 8,
			"zz_FancyDress_D", 8,
			"zz_FancyDress_E", 8,
			"zz_FancyDress_F", 8,
			"zz_FancyDress_G", 8,
			"zz_FancyDress_H", 8,
			"zz_FancyDress_I", 8,
			"Wedding_Dress", 1,

			"", 8,
			"", 8,
		},
		
	},
	
}

table.insert(FrockinSplendor_Distribution, 1, distributionTable);