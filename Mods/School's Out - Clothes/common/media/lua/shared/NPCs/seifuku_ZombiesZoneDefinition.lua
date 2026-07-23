require 'NPCs/ZombiesZoneDefinition'
require "seifuku_defines"

Events.OnInitGlobalModData.Add(function()

	local Sandbox_DefaultRatio = SandboxVars.SchoolsOut.DefaultRatio
	local Sandbox_GenderRatio = SandboxVars.SchoolsOut.GenderRatio
	local Sandbox_SeifukuStyle = SandboxVars.SchoolsOut.SeifukuStyle
	local Sandbox_BlazerStyle = SandboxVars.SchoolsOut.BlazerStyle
	local Sandbox_BlazerColor = SandboxVars.SchoolsOut.BlazerColor
	local Sandbox_SailorColor = SandboxVars.SchoolsOut.SailorColor
	local Sandbox_SweaterColor = SandboxVars.SchoolsOut.SweaterColor
	local Sandbox_BottomStyle = SandboxVars.SchoolsOut.BottomStyle
	local Sandbox_BottomColor = SandboxVars.SchoolsOut.BottomColor
	local Sandbox_SailorRibbonStyle = SandboxVars.SchoolsOut.RibbonStyleSailor
	local Sandbox_BlazerRibbonStyle = SandboxVars.SchoolsOut.RibbonStyleBlazer
	local Sandbox_RibbonColor = SandboxVars.SchoolsOut.RibbonColor
	local Sandbox_GymsuitStyle = SandboxVars.SchoolsOut.GymsuitStyle
	local Sandbox_SwimsuitStyle = SandboxVars.SchoolsOut.SwimsuitStyle

	local tbl_outfits_to_spawn = {}
	local tbl_outfit_styles = seifuku.outfit.styles
	local tbl_blazer_colors = seifuku.outfit.blazer.colors
	local tbl_sailor_colors = seifuku.outfit.sailor.colors
	local tbl_sweater_colors = seifuku.outfit.sweater.colors
	local tbl_bottom_colors = seifuku.outfit.skirt.colors -- Skirt colors as gen. bottom color table b/c they (will) have more variety and outfits.
	local tbl_ribbon_styles = seifuku.ribbon.styles
	local tbl_ribbon_colors = seifuku.ribbon.colors

	if SandboxVars.SchoolsOut.UseSeifukuZombies then

		-- Should add to 100.
		local INT_CHANCE_TO_SPAWN_VANILLA_STUDENTS_AT_SCHOOL = 50
		local INT_CHANCE_TO_SPAWN_SEIFUKU_STUDENTS_AT_SCHOOL = 30
		local INT_CHANCE_TO_SPAWN_SEIFUKU_ATHLETES_AT_SCHOOL = 10
		local INT_CHANCE_TO_SPAWN_SEIFUKU_SWIMMERS_AT_SCHOOL = 10

		-- Should add to 100.
		if not SandboxVars.SchoolsOut.UseVanillaZombies then
			INT_CHANCE_TO_SPAWN_VANILLA_STUDENTS_AT_SCHOOL = 0
			INT_CHANCE_TO_SPAWN_SEIFUKU_STUDENTS_AT_SCHOOL = 70
			INT_CHANCE_TO_SPAWN_SEIFUKU_ATHLETES_AT_SCHOOL = 20
			-- INT_CHANCE_TO_SPAWN_SEIFUKU_SWIMMERS_AT_SCHOOL = 10
		end

		-- For ZombiesZoneDefinition.Default.
		local INT_CHANCE_TO_SPAWN_SEIFUKU_STUDENTS_RANDOMLY = 1
		local INT_CHANCE_TO_SPAWN_SEIFUKU_ATHLETES_RANDOMLY = 0.25
		local INT_CHANCE_TO_SPAWN_SEIFUKU_SWIMMERS_RANDOMLY = 0.05

		local defaultStudentSpawnModifier = Sandbox_DefaultRatio

		INT_CHANCE_TO_SPAWN_SEIFUKU_STUDENTS_RANDOMLY = INT_CHANCE_TO_SPAWN_SEIFUKU_STUDENTS_RANDOMLY * defaultStudentSpawnModifier
		INT_CHANCE_TO_SPAWN_SEIFUKU_ATHLETES_RANDOMLY = INT_CHANCE_TO_SPAWN_SEIFUKU_ATHLETES_RANDOMLY * defaultStudentSpawnModifier
		INT_CHANCE_TO_SPAWN_SEIFUKU_SWIMMERS_RANDOMLY = INT_CHANCE_TO_SPAWN_SEIFUKU_SWIMMERS_RANDOMLY * defaultStudentSpawnModifier

		-- We overwrite the "SwimmingPool" and "Beach" zones to reduce the odds of vanilla tourists/swimmers spawning.
		-- The chance(s) in each zone below + the related CHANCE_TO_SPAWN_SEIFUKU_SWIMMERS should add to 100.

		local INT_CHANCE_TO_SPAWN_SEIFUKU_SWIMMERS_AT_POOL = 30
		ZombiesZoneDefinition.SwimmingPool = {
			Swimmer = {
				name="Swimmer",
				chance=70,
			},
		}

		local INT_CHANCE_TO_SPAWN_SEIFUKU_SWIMMERS_AT_BEACH = 20
		ZombiesZoneDefinition.Beach = {
			Tourist = {
				name="Tourist",
				chance=30,
			},
			Swimmer = {
				name="Swimmer",
				chance=50,
			},
		}

		-- We divide the SEIFUKU_SWIMMERS chance by this to determine how many will wear comp swimsuits.
		local FRACTION_OF_SUKUMIZU_THAT_ARE_COMP_DENOM = 5

		-- Must match outfit names defined in clothing.xml.
		local str_swim_outfit = "StudentSwimmer"
		local str_swim_outfit_alt_type = "StudentSwimmerNewType"
		local str_swim_outfit_comp = "StudentSwimmerComp"

		if SandboxVars.SchoolsOut.WhiteSwimsuitToggle then
			str_swim_outfit = "StudentSwimmerWhite"
			str_swim_outfit_alt_type = "StudentSwimmerWhiteNewType"
			str_swim_outfit_comp = "StudentSwimmerWhiteComp"
		end

		local function seifuku_set_genderRatio()
			if Sandbox_GenderRatio == 4 then
				ZombiesZoneDefinition.School.femaleChance = 65  -- Mostly Female
			elseif Sandbox_GenderRatio == 5 then
				ZombiesZoneDefinition.School.femaleChance = 100    -- All Female
			elseif Sandbox_GenderRatio == 2 then
				ZombiesZoneDefinition.School.maleChance = 65      -- Mostly Male
			elseif Sandbox_GenderRatio == 1 then
				ZombiesZoneDefinition.School.maleChance = 100        -- All Male
			end
			-- 50/50 (Sandbox_GenderRatio == 3) is default behavior, so no elif.
		end

		local function seifuku_set_swimmers()
			if Sandbox_GenderRatio ~= 1 then

				local function calculateSwimmerChance(int_total_swimmer_chance)
					local int_comp_chance = int_total_swimmer_chance / FRACTION_OF_SUKUMIZU_THAT_ARE_COMP_DENOM
					local int_chance = (int_total_swimmer_chance - int_comp_chance)
					if Sandbox_SwimsuitStyle ~= 1 then
						return int_chance
					else
						return int_chance / 2 -- We /2 so that there is room for the alt type swimsuits as well.
					end
				end

				if Sandbox_SwimsuitStyle == 3 then
					str_swim_outfit = str_swim_outfit_alt_type
				end

				table.insert(tbl_outfits_to_spawn, str_swim_outfit)
				table.insert(tbl_outfits_to_spawn, str_swim_outfit_comp)
				table.insert(ZombiesZoneDefinition.School,{name = str_swim_outfit, chance=calculateSwimmerChance(INT_CHANCE_TO_SPAWN_SEIFUKU_SWIMMERS_AT_SCHOOL)})
				table.insert(ZombiesZoneDefinition.School,{name = str_swim_outfit_comp, chance=(INT_CHANCE_TO_SPAWN_SEIFUKU_SWIMMERS_AT_SCHOOL / FRACTION_OF_SUKUMIZU_THAT_ARE_COMP_DENOM)})
				table.insert(ZombiesZoneDefinition.SwimmingPool,{name = str_swim_outfit, chance=calculateSwimmerChance(INT_CHANCE_TO_SPAWN_SEIFUKU_SWIMMERS_AT_POOL)})
				table.insert(ZombiesZoneDefinition.SwimmingPool,{name = str_swim_outfit_comp, chance=(INT_CHANCE_TO_SPAWN_SEIFUKU_SWIMMERS_AT_POOL / FRACTION_OF_SUKUMIZU_THAT_ARE_COMP_DENOM)})
				table.insert(ZombiesZoneDefinition.Beach,{name = str_swim_outfit, chance=calculateSwimmerChance(INT_CHANCE_TO_SPAWN_SEIFUKU_SWIMMERS_AT_BEACH)})
				table.insert(ZombiesZoneDefinition.Beach,{name = str_swim_outfit_comp, chance=(INT_CHANCE_TO_SPAWN_SEIFUKU_SWIMMERS_AT_BEACH / FRACTION_OF_SUKUMIZU_THAT_ARE_COMP_DENOM)})
				table.insert(ZombiesZoneDefinition.Default,{name = str_swim_outfit, chance=calculateSwimmerChance(INT_CHANCE_TO_SPAWN_SEIFUKU_SWIMMERS_RANDOMLY)})
				table.insert(ZombiesZoneDefinition.Default,{name = str_swim_outfit_comp, chance=(INT_CHANCE_TO_SPAWN_SEIFUKU_SWIMMERS_RANDOMLY / FRACTION_OF_SUKUMIZU_THAT_ARE_COMP_DENOM)})

				if Sandbox_SwimsuitStyle == 1 then
					table.insert(tbl_outfits_to_spawn, str_swim_outfit_alt_type)
					table.insert(ZombiesZoneDefinition.School,{name = str_swim_outfit_alt_type, chance=calculateSwimmerChance(INT_CHANCE_TO_SPAWN_SEIFUKU_SWIMMERS_AT_SCHOOL)})
					table.insert(ZombiesZoneDefinition.SwimmingPool,{name = str_swim_outfit_alt_type, chance=calculateSwimmerChance(INT_CHANCE_TO_SPAWN_SEIFUKU_SWIMMERS_AT_POOL)})
					table.insert(ZombiesZoneDefinition.Beach,{name = str_swim_outfit_alt_type, chance=calculateSwimmerChance(INT_CHANCE_TO_SPAWN_SEIFUKU_SWIMMERS_AT_BEACH)})
					table.insert(ZombiesZoneDefinition.Default,{name = str_swim_outfit_alt_type, chance=calculateSwimmerChance(INT_CHANCE_TO_SPAWN_SEIFUKU_SWIMMERS_RANDOMLY)})
				end

			else -- If students are "All Male", we don't need to calculate chances, add different types, etc. as there is only one type of male sukumizu.
				table.insert(tbl_outfits_to_spawn, str_swim_outfit)
				table.insert(ZombiesZoneDefinition.School,{name = str_swim_outfit, chance=INT_CHANCE_TO_SPAWN_SEIFUKU_SWIMMERS_AT_SCHOOL})
				table.insert(ZombiesZoneDefinition.SwimmingPool,{name = str_swim_outfit, chance=INT_CHANCE_TO_SPAWN_SEIFUKU_SWIMMERS_AT_POOL})
				table.insert(ZombiesZoneDefinition.Beach,{name = str_swim_outfit, chance=INT_CHANCE_TO_SPAWN_SEIFUKU_SWIMMERS_AT_BEACH})
				table.insert(ZombiesZoneDefinition.Default,{name = str_swim_outfit, chance=INT_CHANCE_TO_SPAWN_SEIFUKU_SWIMMERS_RANDOMLY})
			end
		end

		local function seifuku_set_athletes()

			local tbl_gym_outfits = {"StudentAthlete", "StudentAthletePolo", "StudentAthleteTracksuitRed", "StudentAthleteTracksuitBlue"}

			if Sandbox_GymsuitStyle == 1 then
				for _, str_outfit in pairs(tbl_gym_outfits) do
					-- By the time this fn runs, tbl_outfits_to_spawn is no longer being used for zombies. However, it's used for hairstyles, so we update it.
					table.insert(tbl_outfits_to_spawn, str_outfit)
					table.insert(ZombiesZoneDefinition.School,{name = str_outfit, chance = INT_CHANCE_TO_SPAWN_SEIFUKU_ATHLETES_AT_SCHOOL / #tbl_gym_outfits})
					table.insert(ZombiesZoneDefinition.Default,{name = str_outfit, chance = INT_CHANCE_TO_SPAWN_SEIFUKU_ATHLETES_RANDOMLY / #tbl_gym_outfits})
				end
			elseif Sandbox_GymsuitStyle == 4 then
				for i = 3, 4 do
					local str_tracksuit = tbl_gym_outfits[i]
					table.insert(tbl_outfits_to_spawn, str_tracksuit)
					table.insert(ZombiesZoneDefinition.School, {name = str_tracksuit, chance = INT_CHANCE_TO_SPAWN_SEIFUKU_ATHLETES_AT_SCHOOL / 2})
					table.insert(ZombiesZoneDefinition.Default, {name = str_tracksuit, chance = INT_CHANCE_TO_SPAWN_SEIFUKU_ATHLETES_RANDOMLY / 2})
				end
			else
				local str_gym_uniform_outfit = tbl_gym_outfits[Sandbox_GymsuitStyle - 1]
				table.insert(tbl_outfits_to_spawn, str_gym_uniform_outfit)
				table.insert(ZombiesZoneDefinition.School,{name = str_gym_uniform_outfit, chance = INT_CHANCE_TO_SPAWN_SEIFUKU_ATHLETES_AT_SCHOOL})
				table.insert(ZombiesZoneDefinition.Default,{name = str_gym_uniform_outfit, chance = INT_CHANCE_TO_SPAWN_SEIFUKU_ATHLETES_RANDOMLY})
			end
		end

		local function seifuku_set_uniforms()

			local function init_tbl_outfit_names()

				local function add_var_color_outfit(str_outfit_style_wo_color, SandboxColor, tbl_colors, tbl_outfit_names_init, isSailor)
					if SandboxColor == 1 then
						for _, str_color in pairs(tbl_colors) do
							if isSailor and (str_color == "WhiteBlack") then
								table.insert(tbl_outfit_names_init, str_outfit_style_wo_color)
							else
								local str_outfit_name_wo_ribbons_or_ribbon_color = str_outfit_style_wo_color .. str_color
								table.insert(tbl_outfit_names_init, str_outfit_name_wo_ribbons_or_ribbon_color)
							end
						end
					else
						if isSailor and (SandboxColor == 2) then
							table.insert(tbl_outfit_names_init, str_outfit_style_wo_color)
						else
							local str_outfit_name_wo_ribbons_or_ribbon_color = str_outfit_style_wo_color .. tbl_colors[SandboxColor - 1]
							table.insert(tbl_outfit_names_init, str_outfit_name_wo_ribbons_or_ribbon_color)
						end
					end
					return tbl_outfit_names_init
				end

				local tbl_outfit_names_init = {}
				local STR_OUTFIT_PREFIX = "StudentSeifuku"

				local styleIsAll = Sandbox_SeifukuStyle == 1
				local styleIsBlazer = Sandbox_SeifukuStyle == 2
				local styleIsSailor = Sandbox_SeifukuStyle == 3
				local styleIsSweater = Sandbox_SeifukuStyle == 4

				for int_outfit_style_index, str_outfit_style in pairs(tbl_outfit_styles) do
					local str_outfit_style_wo_color = STR_OUTFIT_PREFIX .. str_outfit_style
					if (styleIsAll or styleIsSailor) and int_outfit_style_index == 1 then
						tbl_outfit_names_init = add_var_color_outfit(str_outfit_style_wo_color, Sandbox_SailorColor, tbl_sailor_colors, tbl_outfit_names_init, true)
					elseif (styleIsAll or styleIsBlazer) and (int_outfit_style_index == 2 or int_outfit_style_index == 3 or int_outfit_style_index == 4) then
						if Sandbox_BlazerStyle == 1
						or Sandbox_BlazerStyle == int_outfit_style_index then
							if int_outfit_style_index ~= 2 then -- If not Nyancat's blazer...
								tbl_outfit_names_init = add_var_color_outfit(str_outfit_style_wo_color, Sandbox_BlazerColor, tbl_blazer_colors, tbl_outfit_names_init, false)
							else
								table.insert(tbl_outfit_names_init, str_outfit_style_wo_color)
							end
						end
					elseif (styleIsAll or styleIsSweater) and int_outfit_style_index == 5 then
						tbl_outfit_names_init = add_var_color_outfit(str_outfit_style_wo_color, Sandbox_SweaterColor, tbl_sweater_colors, tbl_outfit_names_init, false)
					end
				end

				return tbl_outfit_names_init

			end

			local function append_bottom_color_to_tbl_outfit_names(tbl_outfit_names_init)

				local tbl_outfit_names_bottoms = {}

				for _, str_outfit_name_wo_bottom_color in pairs(tbl_outfit_names_init) do
					for int_bottom_color_index, str_bottom_color in pairs (tbl_bottom_colors) do
						local str_outfit_name_w_bottom_color = str_outfit_name_wo_bottom_color .. "Btm" .. str_bottom_color
						local str_outfit_name_w_bottom_color_long = str_outfit_name_w_bottom_color .. "Long"
						if Sandbox_BottomStyle == 3 then str_outfit_name_w_bottom_color = str_outfit_name_w_bottom_color_long end
						if Sandbox_BottomColor == 1 or int_bottom_color_index == Sandbox_BottomColor - 1 then
							table.insert(tbl_outfit_names_bottoms, str_outfit_name_w_bottom_color)
							if Sandbox_BottomStyle == 1 and not str_outfit_name_wo_bottom_color:find("StudentSeifukuBlazerBtm") then
								table.insert(tbl_outfit_names_bottoms, str_outfit_name_w_bottom_color_long)
							end
							if Sandbox_BottomColor == 1 then break end
						end
					end
				end

				return tbl_outfit_names_bottoms

			end

			local function append_ribbon_style_to_tbl_outfit_names(tbl_outfit_names_bottoms)

				-- This function will not be called if they have not requested a specific style, so we assume the RibbonStyle options correctly map to tbl_ribbon_styles.
				local function append_ribbon_style_to_individual_outfit(str_outfit_name)
					if string.match(str_outfit_name, "Sailor") then
						return str_outfit_name .. tbl_ribbon_styles[Sandbox_SailorRibbonStyle - 2]
					end
					if string.match(str_outfit_name, "Blazer") or string.match(str_outfit_name, "Sweater") then
						if Sandbox_BlazerRibbonStyle == 2 then
							return str_outfit_name .. tbl_ribbon_styles[7]
						else
							return str_outfit_name .. tbl_ribbon_styles[Sandbox_BlazerRibbonStyle + 1]
						end
					end
				end

				local tbl_outfit_names_ribbons = {}

				for _, str_outfit_name_wo_ribbon_or_ribbon_color in pairs(tbl_outfit_names_bottoms) do
					if not str_outfit_name_wo_ribbon_or_ribbon_color:find("StudentSeifukuBlazerBtm") then -- Ignore the black sheep legacy outfit, which has a painted-on ribbon.
						if string.match(str_outfit_name_wo_ribbon_or_ribbon_color, "Sailor") then -- For any sailor suits awaiting ribbons...
							if Sandbox_SailorRibbonStyle > 2 then -- ...if a specific ribbon style (i.e., not "Any" or "Any Triangle Tie") has been selected, add it.
								table.insert(tbl_outfit_names_ribbons, append_ribbon_style_to_individual_outfit(str_outfit_name_wo_ribbon_or_ribbon_color))
							elseif Sandbox_SailorRibbonStyle == 2 then -- ...if "Any Triangle Tie" is selected, add all the triangle ties.
								for _, str_ribbon_style in pairs(tbl_ribbon_styles) do
									if str_ribbon_style:find("^Triangle") then
										table.insert(tbl_outfit_names_ribbons, str_outfit_name_wo_ribbon_or_ribbon_color .. str_ribbon_style)
									end
								end
							else -- ...no tie style was selected, so...
								for _, str_ribbon_style in pairs(tbl_ribbon_styles) do -- ...for every possible ribbon style...
									if str_ribbon_style ~= "Necktie" then -- ...so long as it is not a necktie (they cannot be worn w/ sailor suits), add it.
										table.insert(tbl_outfit_names_ribbons, str_outfit_name_wo_ribbon_or_ribbon_color .. str_ribbon_style)
									end
								end
							end
							-- Same idea but for blazers/sweaters.
						elseif string.match(str_outfit_name_wo_ribbon_or_ribbon_color, "Blazer") or string.match(str_outfit_name_wo_ribbon_or_ribbon_color, "Sweater") then
							if Sandbox_BlazerRibbonStyle ~= 1 then
								table.insert(tbl_outfit_names_ribbons, append_ribbon_style_to_individual_outfit(str_outfit_name_wo_ribbon_or_ribbon_color))
							else
								for _, str_ribbon_style in pairs(tbl_ribbon_styles) do
									if not string.match(str_ribbon_style, "Triangle") then -- We exclude triangle ties instead (they cannot be worn w/ blazers).
										table.insert(tbl_outfit_names_ribbons, str_outfit_name_wo_ribbon_or_ribbon_color .. str_ribbon_style)
									end
								end
							end
						end
					else
						table.insert(tbl_outfit_names_ribbons, str_outfit_name_wo_ribbon_or_ribbon_color) -- The legacy outfit needs no ribbons and goes in raw.
					end
				end

				return tbl_outfit_names_ribbons

			end

			local function append_ribbon_color_to_tbl_outfit_names(tbl_outfit_names_ribbons)

				local tbl_complete_outfit_names = {}

				for _, str_outfit_name_wo_ribbon_color in pairs(tbl_outfit_names_ribbons) do
					if not str_outfit_name_wo_ribbon_color:find("StudentSeifukuBlazerBtm") then -- Again, ignore the black sheep legacy outfit.
						if Sandbox_RibbonColor == 1 then -- If user wants all ribbon colors, then we give them all ribbon colors.
							for _, str_ribbon_color in pairs(tbl_ribbon_colors) do
								table.insert(tbl_complete_outfit_names, str_outfit_name_wo_ribbon_color .. str_ribbon_color)
							end
						else -- A specific ribbon color has been selected.
							-- tbl_ribbon_colors is in order, and we know the first sandbox option is "Both", so we can get the correct color index by subtracting 1 from the sandbox option.
							table.insert(tbl_complete_outfit_names, str_outfit_name_wo_ribbon_color .. tbl_ribbon_colors[(Sandbox_RibbonColor - 1)])
						end
					else
						table.insert(tbl_complete_outfit_names, str_outfit_name_wo_ribbon_color) -- The legacy outfit stands alone.
					end
				end

				return tbl_complete_outfit_names

			end

			-- OUTFIT NAME FORMAT: StudentSeifuku[outfit_style][outfit_color]Btm[bottom_color][ribbon_style][ribbon_color]
			tbl_outfits_to_spawn = append_ribbon_color_to_tbl_outfit_names(append_ribbon_style_to_tbl_outfit_names(append_bottom_color_to_tbl_outfit_names(init_tbl_outfit_names())))

			-- We determine the chance for each outfit to spawn as a fraction of its larger type chance.
			-- This prevents outfits with a large # of variations (e.g. blazers) from overwhelming the spawn pool.
			local INT_STYLE_COUNT = 3 -- The number of distinct outfit styles, e.g. "Blazer", "Sweater", etc. The various blazer sub-styles don't count.
			local int_blazer_outfit_count, int_sailor_outfit_count, int_sweater_outfit_count = 0, 0, 0

			for _, str_outfit_to_spawn in pairs(tbl_outfits_to_spawn) do
				if str_outfit_to_spawn:find("Blazer") then
					int_blazer_outfit_count = int_blazer_outfit_count + 1
				elseif str_outfit_to_spawn:find("Sailor") then
					int_sailor_outfit_count = int_sailor_outfit_count + 1
				elseif str_outfit_to_spawn:find("Sweater") then
					int_sweater_outfit_count = int_sweater_outfit_count + 1
				end
			end

			if Sandbox_SeifukuStyle == 1 then

				local int_chance_to_spawn_each_blazer_outfit_at_school = (INT_CHANCE_TO_SPAWN_SEIFUKU_STUDENTS_AT_SCHOOL / INT_STYLE_COUNT) / int_blazer_outfit_count
				local int_chance_to_spawn_each_blazer_outfit_in_default = (INT_CHANCE_TO_SPAWN_SEIFUKU_STUDENTS_RANDOMLY / INT_STYLE_COUNT) / int_blazer_outfit_count
				local int_chance_to_spawn_each_sailor_outfit_at_school = (INT_CHANCE_TO_SPAWN_SEIFUKU_STUDENTS_AT_SCHOOL / INT_STYLE_COUNT) / int_sailor_outfit_count
				local int_chance_to_spawn_each_sailor_outfit_in_default = (INT_CHANCE_TO_SPAWN_SEIFUKU_STUDENTS_RANDOMLY / INT_STYLE_COUNT) / int_sailor_outfit_count
				local int_chance_to_spawn_each_sweater_outfit_at_school = (INT_CHANCE_TO_SPAWN_SEIFUKU_STUDENTS_AT_SCHOOL / INT_STYLE_COUNT) / int_sweater_outfit_count
				local int_chance_to_spawn_each_sweater_outfit_in_default = (INT_CHANCE_TO_SPAWN_SEIFUKU_STUDENTS_RANDOMLY / INT_STYLE_COUNT) / int_sweater_outfit_count

				-- And voila, we run our final ZoneDefinition table inserts.
				for _, str_outfit_to_spawn in pairs(tbl_outfits_to_spawn) do

					local int_outfit_chance_at_school = 0
					local int_outfit_chance_in_default = 0

					if str_outfit_to_spawn:find("Blazer") then
						int_outfit_chance_at_school = int_chance_to_spawn_each_blazer_outfit_at_school
						int_outfit_chance_in_default = int_chance_to_spawn_each_blazer_outfit_in_default
					elseif str_outfit_to_spawn:find("Sailor") then
						int_outfit_chance_at_school = int_chance_to_spawn_each_sailor_outfit_at_school
						int_outfit_chance_in_default = int_chance_to_spawn_each_sailor_outfit_in_default
					elseif str_outfit_to_spawn:find("Sweater") then
						int_outfit_chance_at_school = int_chance_to_spawn_each_sweater_outfit_at_school
						int_outfit_chance_in_default = int_chance_to_spawn_each_sweater_outfit_in_default
					end

					-- If spawning both long and normal dresses, make the latter appear twice as often (since there is only one long dress but the mid dress can be worn long or short)
					if Sandbox_BottomStyle == 1 then
						if str_outfit_to_spawn:find("Long") then
							int_outfit_chance_at_school = (int_outfit_chance_at_school / 3) * 2 -- Multiply result by 2 because long and normal make two "versions" of each outfit
							int_outfit_chance_in_default = (int_outfit_chance_in_default / 3) * 2
						else
							int_outfit_chance_at_school = (int_outfit_chance_at_school * 2 / 3) * 2
							int_outfit_chance_in_default = (int_outfit_chance_in_default * 2 / 3) * 2
						end
					end

					table.insert(ZombiesZoneDefinition.School, {name = str_outfit_to_spawn, chance = int_outfit_chance_at_school})
					table.insert(ZombiesZoneDefinition.Default, {name = str_outfit_to_spawn, chance = int_outfit_chance_in_default})
				end
			else
				for _, str_outfit_to_spawn in pairs(tbl_outfits_to_spawn) do
					table.insert(ZombiesZoneDefinition.School, {name = str_outfit_to_spawn, chance = INT_CHANCE_TO_SPAWN_SEIFUKU_STUDENTS_AT_SCHOOL / #tbl_outfits_to_spawn})
					table.insert(ZombiesZoneDefinition.Default, {name = str_outfit_to_spawn, chance = INT_CHANCE_TO_SPAWN_SEIFUKU_STUDENTS_RANDOMLY / #tbl_outfits_to_spawn})
				end
			end


			if INT_CHANCE_TO_SPAWN_VANILLA_STUDENTS_AT_SCHOOL ~= 0 then
				table.insert(ZombiesZoneDefinition.School,{name = "Student", chance = INT_CHANCE_TO_SPAWN_VANILLA_STUDENTS_AT_SCHOOL})
			end

		end

		-- We also entirely overwrite the "School" zone, to shape it in our image.
		-- (I do this down here and not up with the SwimmingPool / Beach zone overwrites because this one doesn't need #s defined.)
		ZombiesZoneDefinition.School = {}

		seifuku_set_genderRatio()
		seifuku_set_uniforms()
		seifuku_set_athletes()
		seifuku_set_swimmers()
		seifuku.outfit.list = tbl_outfits_to_spawn
	end
end)