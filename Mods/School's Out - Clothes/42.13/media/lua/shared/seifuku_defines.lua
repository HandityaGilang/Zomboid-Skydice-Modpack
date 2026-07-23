Events.OnInitGlobalModData.Add(function()
    seifuku = {
        -- Values must match outfit/item name "fragments", as they are used to programmatically assemble full names.
        -- They must also follow the same order as in the sandbox options.
        outfit = {
            list = {}, -- List of outfits that will be spawned; this is built programmatically.
            styles = {
                "Sailor",
                "Blazer", -- NyanCat's Blazer
                "Blazer2Btn",
                "Blazer3Btn",
                "Sweater",
            },
            sailor = {
                items = {
                    "Base.FemaleUniform_Shirt", -- Shirts go here because, for item-spawning purposes, it is stored in the same containers and should appear w/ same chance as a sailor suit.
                    "Base.FemaleUniform_ShirtShort",
                    "Base.FemaleUniform_SailorWhiteBlack",
                    "Base.FemaleUniform_SailorShortWhiteBlack",
                    "Base.FemaleUniform_SailorWhiteBlue",
                    "Base.FemaleUniform_SailorShortWhiteBlue",
                    "Base.FemaleUniform_SailorBlackBlack",
                    "Base.FemaleUniform_SailorShortBlackBlack",
                },
                colors = {
                    "WhiteBlack",
                    "WhiteBlue",
                    "BlackBlack"
                }
            },
            blazer = {
                items = {
                    -- We don't include the unbuttoned versions b/c people can button/unbutton as they like.
                    "Base.Cute_Blazer",
                    "Base.FemaleUniform_Blazer3ButtonBlack",
                    "Base.FemaleUniform_Blazer3ButtonBlackCrest",
                    "Base.FemaleUniform_Blazer2ButtonBlack",
                    "Base.FemaleUniform_Blazer2ButtonBlackCrest",
                    "Base.FemaleUniform_Blazer3ButtonBlackWhite",
                    "Base.FemaleUniform_Blazer3ButtonBlackWhiteCrest",
                    "Base.FemaleUniform_Blazer2ButtonBlackWhite",
                    "Base.FemaleUniform_Blazer2ButtonBlackWhiteCrest",
                    "Base.FemaleUniform_Blazer3ButtonBlue",
                    "Base.FemaleUniform_Blazer3ButtonBlueCrest",
                    "Base.FemaleUniform_Blazer2ButtonBlue",
                    "Base.FemaleUniform_Blazer2ButtonBlueCrest",
                    "Base.FemaleUniform_Blazer3ButtonBeige",
                    "Base.FemaleUniform_Blazer3ButtonBeigeCrest",
                    "Base.FemaleUniform_Blazer2ButtonBeige",
                    "Base.FemaleUniform_Blazer2ButtonBeigeCrest"
                },
                colors = {
                    "Black",
                    "BlackWhite",
                    "Blue",
                    "Beige"
                },
            },
            sweater = {
                items = {
                    "Base.FemaleUniform_SweaterBlack",
                    "Base.FemaleUniform_SweaterShortBlack",
                    "Base.FemaleUniform_SweaterGrey",
                    "Base.FemaleUniform_SweaterShortGrey",
                    "Base.FemaleUniform_SweaterNavyBlue",
                    "Base.FemaleUniform_SweaterShortNavyBlue",
                    "Base.FemaleUniform_SweaterBabyBlue",
                    "Base.FemaleUniform_SweaterShortBabyBlue",
                    "Base.FemaleUniform_SweaterBeige",
                    "Base.FemaleUniform_SweaterShortBeige",
                },
                colors = {
                    "Black",
                    "Grey",
                    "NavyBlue",
                    "BabyBlue",
                    "Beige",
                }
            },
            skirt = {
                items = {
                    -- We don't include the short versions b/c people can shorten as they like.
                    "Base.FemaleUniform_SkirtBlack",
                    "Base.FemaleUniform_SkirtBlackLong",
                    "Base.FemaleUniform_SkirtBlue",
                    "Base.FemaleUniform_SkirtBlueLong",
                },
                colors = {
                    "Black",
                    "Blue"
                },
            },
            trousers = {
                items = {
                    "Base.MaleUniform_Trousers",
                    "Base.MaleUniform_TrousersBlue",
                },
                colors = {
                    "Black",
                    "Blue"
                },
            },
            socks = {
                items = {
                    "Base.Socks_KneeHighBlack",
                    "Base.Socks_KneeHighWhite",
                    "Base.Socks_OverKneeBlack",
                    "Base.Socks_OverKneeWhite",
                    "Base.Socks_CrewWhite",
                },
            },
            swimsuitItems = {
                str_sukumizu_item = "Base.FemaleUniform_Sukumizu",
                str_sukumizu_alt_color = "Base.FemaleUniform_SukumizuWhite",
                str_sukumizu_alt_type = "Base.FemaleUniform_SukumizuNewType",
                str_sukumizu_alt_type_alt_color = "Base.FemaleUniform_SukumizuWhiteNewType",
                str_sukumizu_comp = "Base.FemaleUniform_SukumizuComp",
                str_sukumizu_comp_alt_color = "Base.FemaleUniform_SukumizuWhiteComp"
            },
        },
        ribbon = {
            styles = {
                "Triangle",
                "TriangleButterfly",
                "TriangleSmall",
                "Ribbon",
                "RibbonSingle",
                "String",
                "Necktie"
            },
            colors = {
                "Black",
                "White",
                "Blue",
                "Pink",
                "Red",
                "Yellow",
            },
            items = {
                "Base.Tie_NecktieBlack",
                "Base.Tie_NecktieWhite",
                "Base.Tie_NecktieBlue",
                "Base.Tie_NecktiePink",
                "Base.Tie_NecktieRed",
                "Base.Tie_NecktieYellow",
                "Base.Tie_RibbonBlack",
                "Base.Tie_RibbonWhite",
                "Base.Tie_RibbonBlue",
                "Base.Tie_RibbonPink",
                "Base.Tie_RibbonRed",
                "Base.Tie_RibbonYellow",
                "Base.Tie_RibbonSingleBlack",
                "Base.Tie_RibbonSingleWhite",
                "Base.Tie_RibbonSingleBlue",
                "Base.Tie_RibbonSinglePink",
                "Base.Tie_RibbonSingleRed",
                "Base.Tie_RibbonSingleYellow",
                "Base.Tie_StringBlack",
                "Base.Tie_StringWhite",
                "Base.Tie_StringBlue",
                "Base.Tie_StringPink",
                "Base.Tie_StringRed",
                "Base.Tie_StringYellow",
                "Base.Tie_TriangleBlack",
                "Base.Tie_TriangleWhite",
                "Base.Tie_TriangleBlue",
                "Base.Tie_TrianglePink",
                "Base.Tie_TriangleRed",
                "Base.Tie_TriangleYellow",
                "Base.Tie_TriangleButterflyBlack",
                "Base.Tie_TriangleButterflyWhite",
                "Base.Tie_TriangleButterflyBlue",
                "Base.Tie_TriangleButterflyPink",
                "Base.Tie_TriangleButterflyRed",
                "Base.Tie_TriangleButterflyYellow",
                "Base.Tie_TriangleSmallBlack",
                "Base.Tie_TriangleSmallWhite",
                "Base.Tie_TriangleSmallBlue",
                "Base.Tie_TriangleSmallPink",
                "Base.Tie_TriangleSmallRed",
                "Base.Tie_TriangleSmallYellow",
            },
        },
        cute = {
            items = {
                collars = {
                    "Base.Cute_CollarBlack",
                    "Base.Cute_CollarBlue",
                    "Base.Cute_CollarRed"
                },
                stockings = {
                    "Base.Stockings_CuteWhite",
                    "Base.Stockings_CuteBlack",
                    "Base.Stockings_CuteBlackSemiTrans",
                    "Base.Stockings_CuteBlackTrans"
                },
            },
        },
        addToDistroTable = function(tbl_container_items, str_item, int_chance)
            table.insert(tbl_container_items, str_item)
            table.insert(tbl_container_items, int_chance * SandboxVars.SchoolsOut.SpawnChanceModifier)
        end,
        distributeCuteClothes = function(tbl_container_items, int_mask_chance, int_collar_chance, int_stocking_chance, int_hoodie_chance, int_gura_chance)
            local addToDistroTable = seifuku.addToDistroTable
            if int_mask_chance ~= 0 then
                addToDistroTable(tbl_container_items, "Base.Cute_Facemask", int_mask_chance)
            end
            if int_collar_chance ~= 0 then
                for _, str_collar_item_name in pairs(seifuku.cute.items.collars) do
                    addToDistroTable(tbl_container_items, str_collar_item_name, int_collar_chance)
                end
            end
            if int_stocking_chance ~= 0 then
                for _, str_stocking_item_name in pairs(seifuku.cute.items.stockings) do
                    addToDistroTable(tbl_container_items, str_stocking_item_name, int_stocking_chance)
                end
            end
            if int_hoodie_chance ~= 0 then
                addToDistroTable(tbl_container_items, "Base.Cute_Hoodie", int_hoodie_chance)
            end
            if int_gura_chance ~= 0 then
                addToDistroTable(tbl_container_items, "Base.Cute_PonchoGura", int_gura_chance)
            end
        end,
        distributeSchoolUniform = function(tbl_container_items, int_blazer_chance, int_sailor_chance, int_skirt_chance, int_gakuran_chance, int_trousers_chance)

            local addToDistroTable = seifuku.addToDistroTable

            if int_blazer_chance ~= 0 or int_gakuran_chance ~= 0 then

                local tbl_blazer_colors = seifuku.outfit.blazer.colors
                local int_blazer_colors = #tbl_blazer_colors
                local int_blazer_items = #seifuku.outfit.blazer.items
                local INT_BLAZER_STYLES = 3 -- Set to the # of values in seifuku.outfit.styles that are blazers (i.e., not sailor, etc.).

                local function addBlazers(int_spawn_chance)

                    local Sandbox_BlazerColor = SandboxVars.SchoolsOut.BlazerColor
                    local Sandbox_BlazerStyle = SandboxVars.SchoolsOut.BlazerStyle

                    for int_blazer_item_index, str_blazer_item in pairs(seifuku.outfit.blazer.items) do

                        if Sandbox_BlazerStyle ~= 1 or Sandbox_BlazerColor ~=1 then

                            local isChosenColor = (Sandbox_BlazerColor ~= 1 and str_blazer_item:find(tbl_blazer_colors[Sandbox_BlazerColor - 1]))
                            local isChosenStyle = (Sandbox_BlazerStyle == 3 and str_blazer_item:find("2B"))
                            or (Sandbox_BlazerStyle == 4 and str_blazer_item:find("3B"))
                            or (Sandbox_BlazerStyle == 2 and int_blazer_item_index == 1)

                            -- We divide the chances all by 2 to account for the fact that there is a crested and non-crested blazer that can appear.
                            if isChosenColor and isChosenStyle then
                                addToDistroTable(tbl_container_items, str_blazer_item, int_spawn_chance / 2)
                                -- print("SEIFUKU: " .. str_blazer_item .. " is chosen color and style.")
                                -- print("SEIFUKU: Added " .. str_blazer_item .. " to " .. tostring(tbl_container_items) .. "w/ chance " .. (int_spawn_chance / 2))
                            elseif isChosenStyle then
                                addToDistroTable(tbl_container_items, str_blazer_item, (int_spawn_chance / int_blazer_colors) / 2)
                                -- print("SEIFUKU: " .. str_blazer_item .. " is chosen style.")
                                -- print("SEIFUKU: Added " .. str_blazer_item .. " to " .. tostring(tbl_container_items) .. "w/ chance " .. ((int_spawn_chance / int_blazer_colors) / 2))
                            elseif isChosenColor then
                                addToDistroTable(tbl_container_items, str_blazer_item, (int_spawn_chance / INT_BLAZER_STYLES) / 2)
                                -- print("SEIFUKU: " .. str_blazer_item .. " is chosen color.")
                                -- print("SEIFUKU: Added " .. str_blazer_item .. " to " .. tostring(tbl_container_items) .. "w/ chance " .. ((int_spawn_chance / INT_BLAZER_STYLES) / 2))
                            end

                        else
                            -- We don't need to divide by 2 here b/c the crested blazers are counted in the total blazer item count.
                            addToDistroTable(tbl_container_items, str_blazer_item, int_spawn_chance / int_blazer_items)
                            -- print("SEIFUKU: " .. str_blazer_item .. " is neither chosen color nor style.")
                            -- print("SEIFUKU: Added " .. str_blazer_item .. " to " .. tostring(tbl_container_items) .. "w/ chance " .. (int_spawn_chance / int_blazer_items))
                        end
                    end
                end

                -- We will always spawn blazers based on the blazer chance, even if the user has selected "Sailor Suits / Gakuran" as their preferred uniform style.
                -- This is b/c blazers and sailor suits "coexist": no one will be surprised to find a sailor suit and a blazer in someone's closet (and they generally occupy dif. containers anyway).
                if int_blazer_chance ~= 0 then
                    addBlazers(int_blazer_chance)
                end

                -- Gakuran are a different story. They essentially act as the "male uniform chance" and so, if men are set to wear blazers, we need to hijack the gakuran chance to spawn some blazers.
                if int_gakuran_chance ~= 0 then
                    local Sandbox_SeifukuStyle = SandboxVars.SchoolsOut.SeifukuStyle
                    if Sandbox_SeifukuStyle == 3 then -- Gakuran are the male uniform style, so spawn gakuran. No problem!
                        addToDistroTable(tbl_container_items, "Base.MaleUniform_Gakuran", int_gakuran_chance)
                        -- print("SEIFUKU: Added seifuku.MaleUniform_Gakuran to " .. tostring(tbl_container_items) .. "w/ chance " .. int_gakuran_chance)
                    else -- Blazers are a male uniform style (or no uniform style is set).
                        if int_blazer_chance == 0 then -- If we didn't already spawn blazers above, we'll spawn some instead of gakuran. (This will put blazers in boys closets, for example.)
                            addBlazers(int_gakuran_chance)
                        end
                        -- Still, we want a small chance to find gakuran in the wild. So, we spawn it with odds similar to a wrong-style, wrong-color blazer.
                        addToDistroTable(tbl_container_items, "Base.MaleUniform_Gakuran", int_gakuran_chance / (int_blazer_items + 1))
                        -- print("SEIFUKU: Added seifuku.MaleUniform_Gakuran to " .. tostring(tbl_container_items) .. "w/ chance " .. (int_gakuran_chance / (int_blazer_items + 1)))
                    end
                end
            end

            if int_sailor_chance ~= 0 then
                local addToDistroTable = seifuku.addToDistroTable

                local tbl_sailor_items = seifuku.outfit.sailor.items
                local tbl_sailor_colors = seifuku.outfit.sailor.colors
                local Sandbox_SailorColor = SandboxVars.SchoolsOut.SailorColor

                for int_sailor_item_index, str_sailor_item in pairs(tbl_sailor_items) do
                    if Sandbox_SailorColor == 1 then
                        addToDistroTable(tbl_container_items, str_sailor_item, int_sailor_chance / #tbl_sailor_items)
                    elseif str_sailor_item:find(tbl_sailor_colors[Sandbox_SailorColor - 1])
                    or (Sandbox_SailorColor == 2 and (int_sailor_item_index == 3 or 4)) then
                        addToDistroTable(tbl_container_items, str_sailor_item, int_sailor_chance / 2) -- Divide by 2 due to long/short sleeve ver
                    else
                        addToDistroTable(tbl_container_items, str_sailor_item, (int_sailor_chance / #tbl_sailor_colors) / 2) -- Divide by 2 due to long/short sleeve ver
                    end
                end
            end

            if int_skirt_chance ~= 0 or int_trousers_chance ~= 0 then

                local Sandbox_BottomColor = SandboxVars.SchoolsOut.BottomColor
                local Sandbox_BottomStyle = SandboxVars.SchoolsOut.BottomStyle

                local function addBottom(tbl_items, tbl_colors, int_chance)
                    for int_bottom_item_index, str_bottom_item in pairs(tbl_items) do

                        -- local isLong = str_bottom_item:find("Long")
                        local isChosenColor = Sandbox_BottomColor ~= 1
                        and ((Sandbox_BottomColor == 2 and int_bottom_item_index == 1) -- The black skirt/trousers have no color in the item name, but they are first in their lists.
                        or str_bottom_item:find(tbl_colors[Sandbox_BottomColor - 1]))

                        -- TODO: Modify spawn chances for long vs. short skirts (currently they are treated the same)
                        if isChosenColor then
                            addToDistroTable(tbl_container_items, str_bottom_item, int_chance / 2) -- Divide by 2 due to long/short ver
                            -- print("SEIFUKU: Added " .. str_bottom_item .. " to " .. tostring(tbl_container_items) .. "w/ chance " .. int_chance)
                        else
                            addToDistroTable(tbl_container_items, str_bottom_item, (int_chance / #tbl_colors) / 2) -- Divide by 2 due to long/short ver
                            -- print("SEIFUKU: Added " .. str_bottom_item .. " to " .. tostring(tbl_container_items) .. "w/ chance " .. (int_chance / #tbl_colors))
                        end
                    end
                end

                if int_skirt_chance ~= 0 then
                    addBottom(seifuku.outfit.skirt.items, seifuku.outfit.skirt.colors, int_skirt_chance)
                end

                if int_trousers_chance ~= 0 then
                    addBottom(seifuku.outfit.trousers.items, seifuku.outfit.trousers.colors, int_trousers_chance)
                end
            end
        end,
        distributeSweaters = function(tbl_container_items, int_sweater_chance)
            local addToDistroTable = seifuku.addToDistroTable

            local tbl_sweater_items = seifuku.outfit.sweater.items
            local tbl_sweater_colors = seifuku.outfit.sweater.colors
            local Sandbox_SweaterColor = SandboxVars.SchoolsOut.SweaterColor

            for _, str_sweater_item in pairs(tbl_sweater_items) do
                if Sandbox_SweaterColor == 1 then
                    addToDistroTable(tbl_container_items, str_sweater_item, int_sweater_chance / #tbl_sweater_items)
                elseif str_sweater_item:find(tbl_sweater_colors[Sandbox_SweaterColor - 1]) then
                    addToDistroTable(tbl_container_items, str_sweater_item, int_sweater_chance / 2) -- Divide by 2 due to vest/long ver
                else
                    addToDistroTable(tbl_container_items, str_sweater_item, (int_sweater_chance / #tbl_sweater_colors) / 2) -- Divide by 2 due to vest/long ver
                end
            end
        end,
        distributeTies = function(tbl_container_items, int_base_tie_chance)

            local Sandbox_RibbonStyleSailor = SandboxVars.SchoolsOut.RibbonStyleSailor
            local Sandbox_RibbonStyleBlazer = SandboxVars.SchoolsOut.RibbonStyleBlazer

            local function insertTiesIntoTable(listOfRibbonsToSpawn)
                local addToDistroTable = seifuku.addToDistroTable

                local function ribbonIsCorrectStyleAndColor(str_ribbon_item, tbl_pref_ribbon_colors)
                    for _, str_ribbon_color in pairs(tbl_pref_ribbon_colors) do
                        for _, str_ribbon_style in pairs(listOfRibbonsToSpawn) do
                            if string.match(str_ribbon_item, str_ribbon_style .. str_ribbon_color) then
                                return true
                            end
                        end
                    end
                    return false
                end

                local str_pref_ribbon_color
                if SandboxVars.SchoolsOut.RibbonColor ~= 1 then
                    str_pref_ribbon_color = seifuku.ribbon.colors[(SandboxVars.SchoolsOut.RibbonColor - 1)]
                end

                -- Add the unfolded triangle tie item instead of one of the folded clothing variants
                for _, str_color in pairs(seifuku.ribbon.colors) do
                    str_tie_item_name = "Base.TriangleTie" .. str_color
                    if listOfRibbonsToSpawn[1] == 'Triangle' then -- str_desired_sailor_ribbon comes first in listOfRibbonsToSpawn, so we check @ 1.
                        if str_color == str_pref_ribbon_color then
                            addToDistroTable(tbl_container_items, str_tie_item_name, int_base_tie_chance)
                        else
                            addToDistroTable(tbl_container_items, str_tie_item_name, int_base_tie_chance / #seifuku.ribbon.colors)
                        end
                    else
                        addToDistroTable(tbl_container_items, str_tie_item_name, int_base_tie_chance / #seifuku.ribbon.items)
                    end
                end

                for _, str_ribbon_item in pairs(seifuku.ribbon.items) do
                    if not str_ribbon_item:find("Triangle") then -- Ribbon is not a triangle tie (see above)
                        if str_pref_ribbon_color and ribbonIsCorrectStyleAndColor(str_ribbon_item, {str_pref_ribbon_color}) then
                            -- This is the color and type of ribbon we want to spawn, so spawn w/ int_base_tie_chance
                            addToDistroTable(tbl_container_items, str_ribbon_item, int_base_tie_chance)
                        else
                            if ribbonIsCorrectStyleAndColor(str_ribbon_item, seifuku.ribbon.colors) then
                                -- This is the right style of ribbon, but the wrong color (or no preferred color has been selected), so spawn it w/ int_base_tie_chance adjusted for # of color variants
                                addToDistroTable(tbl_container_items, str_ribbon_item, int_base_tie_chance / #seifuku.ribbon.colors)
                            else -- This is not the right style of ribbon, so spawn w/ much smaller int_base_tie_chance (adjusted for # of ribbons)
                                addToDistroTable(tbl_container_items, str_ribbon_item, int_base_tie_chance / #seifuku.ribbon.items)
                            end
                        end
                    end
                end
            end

            -- Note that this will set the item spawns based on ribbon style options regardless of whether the user has selected a matching seifukuStyle.
            -- This is (for now) intentional: even if zombies are, e.g., only wearing sailor suits, neckties can still spawn w/ chance subject to prefs.
            local str_desired_sailor_ribbon
            if Sandbox_RibbonStyleSailor == 1 then
                str_desired_sailor_ribbon = "None"
            elseif Sandbox_RibbonStyleSailor < 5 then
                str_desired_sailor_ribbon = "Triangle"
            elseif Sandbox_RibbonStyleSailor == 6 then
                str_desired_sailor_ribbon = "Ribbon"
            elseif Sandbox_RibbonStyleSailor == 7 then
                str_desired_sailor_ribbon = "RibbonSingle"
            elseif Sandbox_RibbonStyleSailor == 8 then
                str_desired_sailor_ribbon = "String"
            end

            local str_desired_blazer_ribbon
            if Sandbox_RibbonStyleBlazer == 1 then
                str_desired_blazer_ribbon = "None"
            elseif Sandbox_RibbonStyleBlazer == 2 then
                str_desired_blazer_ribbon = "Necktie"
            elseif Sandbox_RibbonStyleBlazer == 3 then
                str_desired_blazer_ribbon = "Ribbon"
            elseif Sandbox_RibbonStyleBlazer == 4 then
                str_desired_blazer_ribbon = "RibbonSingle"
            elseif Sandbox_RibbonStyleBlazer == 5 then
                str_desired_blazer_ribbon = "String"
            end

            if (Sandbox_RibbonStyleSailor == 1 and Sandbox_RibbonStyleBlazer == 1) then
                insertTiesIntoTable({'All'})
            elseif (Sandbox_RibbonStyleSailor ~= 1 and Sandbox_RibbonStyleBlazer == 1) then
                insertTiesIntoTable({str_desired_sailor_ribbon})
            elseif (Sandbox_RibbonStyleSailor == 1 and Sandbox_RibbonStyleBlazer ~= 1) then
                insertTiesIntoTable({str_desired_blazer_ribbon})
            else
                insertTiesIntoTable({str_desired_sailor_ribbon, str_desired_blazer_ribbon})
            end
        end,
        distributeSocks = function(tbl_container_items, int_sock_chance)
            local addToDistroTable = seifuku.addToDistroTable

            local tbl_sock_items = seifuku.outfit.socks.items

            for _, str_sock_item in pairs(tbl_sock_items) do
                if str_sock_item:find("KneeHigh") then
                    addToDistroTable(tbl_container_items, str_sock_item, int_sock_chance / 2)
                end
                if str_sock_item:find("OverKnee") then
                    addToDistroTable(tbl_container_items, str_sock_item, int_sock_chance / 2)
                end
                if str_sock_item:find("Crew") then
                    addToDistroTable(tbl_container_items, str_sock_item, int_sock_chance)
                end
            end
        end,
        distributeGymUniform = function(tbl_container_items, int_shirt_chance, int_pants_chance)
            local addToDistroTable = seifuku.addToDistroTable
            local Sandbox_GymUniformStyle = SandboxVars.SchoolsOut.GymsuitStyle

            local function addToTable(item, chance)
                addToDistroTable(tbl_container_items, item, chance)
            end

            local int_gymItemDivisorDefault = 4 -- Set equal to number of items, not counting variants (e.g. short sleeves)
            local int_gymItemDivisorDefaultHasAlt = int_gymItemDivisorDefault * 2 -- For unselected items w/ a variant
            local int_gymItemDivisorSelectedHasAlt = int_gymItemDivisorDefault / 2 -- For selected items w/ a variant

            if int_shirt_chance ~= 0 then
                if Sandbox_GymUniformStyle == 1 then
                    addToTable("Base.GymUniform_Shirt", int_shirt_chance / int_gymItemDivisorDefault)
                    addToTable("Base.GymUniform_PoloShirt", int_shirt_chance / int_gymItemDivisorDefaultHasAlt)
                    addToTable("Base.GymUniform_PoloShirtShort", int_shirt_chance / int_gymItemDivisorDefaultHasAlt)
                    addToTable("Base.GymUniform_TracksuitTopRed", int_shirt_chance / int_gymItemDivisorDefaultHasAlt)
                    addToTable("Base.GymUniform_TracksuitTopBlue", int_shirt_chance / int_gymItemDivisorDefaultHasAlt)
                elseif Sandbox_GymUniformStyle == 2 then
                    addToTable("Base.GymUniform_Shirt", int_shirt_chance)
                    addToTable("Base.GymUniform_PoloShirt", int_shirt_chance / int_gymItemDivisorDefault)
                    addToTable("Base.GymUniform_PoloShirtShort", int_shirt_chance / int_gymItemDivisorDefault)
                    addToTable("Base.GymUniform_TracksuitTopRed", int_shirt_chance / int_gymItemDivisorDefaultHasAlt)
                    addToTable("Base.GymUniform_TracksuitTopBlue", int_shirt_chance / int_gymItemDivisorDefaultHasAlt)
                elseif Sandbox_GymUniformStyle == 3 then
                    addToTable("Base.GymUniform_Shirt", int_shirt_chance / int_gymItemDivisorDefault)
                    addToTable("Base.GymUniform_PoloShirt", int_shirt_chance / int_gymItemDivisorSelectedHasAlt)
                    addToTable("Base.GymUniform_PoloShirtShort", int_shirt_chance / int_gymItemDivisorSelectedHasAlt)
                    addToTable("Base.GymUniform_TracksuitTopRed", int_shirt_chance / int_gymItemDivisorDefaultHasAlt)
                    addToTable("Base.GymUniform_TracksuitTopBlue", int_shirt_chance / int_gymItemDivisorDefaultHasAlt)
                else
                    addToTable("Base.GymUniform_Shirt", int_shirt_chance / int_gymItemDivisorDefault)
                    addToTable("Base.GymUniform_PoloShirt", int_shirt_chance / int_gymItemDivisorDefault)
                    addToTable("Base.GymUniform_PoloShirtShort", int_shirt_chance / int_gymItemDivisorDefault)
                    addToTable("Base.GymUniform_TracksuitTopRed", int_shirt_chance / int_gymItemDivisorSelectedHasAlt)
                    addToTable("Base.GymUniform_TracksuitTopBlue", int_shirt_chance / int_gymItemDivisorSelectedHasAlt)
                end
            end

            if int_pants_chance ~= 0 then
                if Sandbox_GymUniformStyle == 1 then
                    addToTable("Base.GymUniform_Shorts", int_pants_chance / int_gymItemDivisorDefaultHasAlt)
                    addToTable("Base.GymUniform_Bloomers", int_pants_chance / int_gymItemDivisorDefaultHasAlt)
                    addToTable("Base.FemaleUniform_SkirtWhiteShort", int_pants_chance / int_gymItemDivisorDefault)
                    addToTable("Base.GymUniform_TracksuitPantsRed", int_pants_chance / int_gymItemDivisorDefaultHasAlt)
                    addToTable("Base.GymUniform_TracksuitPantsBlue", int_pants_chance / int_gymItemDivisorDefaultHasAlt)
                elseif Sandbox_GymUniformStyle == 2 then
                    addToTable("Base.GymUniform_Shorts", int_pants_chance / int_gymItemDivisorSelectedHasAlt)
                    addToTable("Base.GymUniform_Bloomers", int_pants_chance / int_gymItemDivisorSelectedHasAlt)
                    addToTable("Base.FemaleUniform_SkirtWhiteShort", int_pants_chance / int_gymItemDivisorDefault)
                    addToTable("Base.GymUniform_TracksuitPantsRed", int_pants_chance / int_gymItemDivisorDefaultHasAlt)
                    addToTable("Base.GymUniform_TracksuitPantsBlue", int_pants_chance / int_gymItemDivisorDefaultHasAlt)
                elseif Sandbox_GymUniformStyle == 3 then
                    addToTable("Base.GymUniform_Shorts", int_pants_chance / int_gymItemDivisorSelectedHasAlt)
                    addToTable("Base.GymUniform_Bloomers", int_pants_chance / int_gymItemDivisorDefault)
                    addToTable("Base.FemaleUniform_SkirtWhiteShort", int_pants_chance / int_gymItemDivisorSelectedHasAlt)
                    addToTable("Base.GymUniform_TracksuitPantsRed", int_pants_chance / int_gymItemDivisorDefaultHasAlt)
                    addToTable("Base.GymUniform_TracksuitPantsBlue", int_pants_chance / int_gymItemDivisorDefaultHasAlt)
                else
                    addToTable("Base.GymUniform_Shorts", int_pants_chance / int_gymItemDivisorDefaultHasAlt)
                    addToTable("Base.GymUniform_Bloomers", int_pants_chance / int_gymItemDivisorDefaultHasAlt)
                    addToTable("Base.FemaleUniform_SkirtWhiteShort", int_pants_chance / int_gymItemDivisorDefault)
                    addToTable("Base.GymUniform_TracksuitPantsRed", int_pants_chance / int_gymItemDivisorSelectedHasAlt)
                    addToTable("Base.GymUniform_TracksuitPantsBlue", int_pants_chance / int_gymItemDivisorSelectedHasAlt)
                end
            end
        end,
        distributeSwimsuits = function(tbl_container_items, int_standard_chance, int_comp_chance, int_alt_color_divisor, int_alt_type_divisor)

            local addToDistroTable = seifuku.addToDistroTable
            local str_sukumizu_item = seifuku.outfit.swimsuitItems["str_sukumizu_item"]
            local str_sukumizu_alt_color = seifuku.outfit.swimsuitItems["str_sukumizu_alt_color"]
            local str_sukumizu_alt_type = seifuku.outfit.swimsuitItems["str_sukumizu_alt_type"]
            local str_sukumizu_alt_type_alt_color = seifuku.outfit.swimsuitItems["str_sukumizu_alt_type_alt_color"]
            local str_sukumizu_comp = seifuku.outfit.swimsuitItems["str_sukumizu_comp"]
            local str_sukumizu_comp_alt_color = seifuku.outfit.swimsuitItems["str_sukumizu_comp_alt_color"]

            if SandboxVars.SchoolsOut.WhiteSwimsuitToggle then
                -- Swap the "alt color" for normal (and vice versa).
                local t = str_sukumizu_item
                str_sukumizu_item = str_sukumizu_alt_color
                str_sukumizu_alt_color = t

                t = str_sukumizu_alt_type
                str_sukumizu_alt_type = str_sukumizu_alt_type_alt_color
                str_sukumizu_alt_type_alt_color = t

                t = str_sukumizu_comp
                str_sukumizu_comp = str_sukumizu_comp_alt_color
                str_sukumizu_comp_alt_color = t
            end

            if SandboxVars.SchoolsOut.SwimsuitStyle == 3 then
                -- New type becomes standard, so do the ol' switcharoo...
                str_sukumizu_item, str_sukumizu_alt_type,
                str_sukumizu_alt_color, str_sukumizu_alt_type_alt_color =
                str_sukumizu_alt_type, str_sukumizu_item,
                str_sukumizu_alt_type_alt_color, str_sukumizu_alt_color
            end

            if int_standard_chance ~= 0 then
                addToDistroTable(tbl_container_items, str_sukumizu_item, int_standard_chance)
                addToDistroTable(tbl_container_items, "Base.MaleUniform_Sukumizu", int_standard_chance)
            end
            if int_comp_chance ~= 0 then
                addToDistroTable(tbl_container_items, str_sukumizu_comp, int_comp_chance)
            end
            if int_alt_color_divisor ~= 0 or int_alt_type_divisor ~= 0 then
                local int_alt_chance = int_standard_chance / int_alt_type_divisor
                if int_alt_color_divisor ~= 0 then
                    addToDistroTable(tbl_container_items, str_sukumizu_alt_color, int_standard_chance / int_alt_color_divisor)
                    addToDistroTable(tbl_container_items, str_sukumizu_alt_type_alt_color, int_alt_chance / int_alt_color_divisor)
                    addToDistroTable(tbl_container_items, str_sukumizu_comp_alt_color, int_comp_chance / int_alt_color_divisor)
                end
                if int_alt_type_divisor ~= 0 then
                    addToDistroTable(tbl_container_items, str_sukumizu_alt_type, int_alt_chance)
                end
            end
            addToDistroTable(tbl_container_items, "Base.FemaleUniform_Rashguard", int_standard_chance / 5)

        end,
        distributeShoes = function(tbl_container_items, int_loafers_chance, int_uwabaki_chance)
            local addToDistroTable = seifuku.addToDistroTable
            if int_loafers_chance ~= 0 then
                addToDistroTable(tbl_container_items, "Base.Shoes_Loafers", int_loafers_chance)
            end
            if int_uwabaki_chance ~= 0 then
                addToDistroTable(tbl_container_items, "Base.Shoes_Uwabaki", int_uwabaki_chance)
            end
        end
    }
end)