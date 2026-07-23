require("SimpleStatus")

local utils = require("ss.utils")

return function()
    -- Urination
    if getActivatedMods():contains("Urination") then

        local function round(num, numDecimalPlaces)
            local mult = 10^(numDecimalPlaces or 0)
            return math.floor(num * mult + 0.5) / mult
        end

        local mod_urination_u = {}
        mod_urination_u.name = "mod_urination_u"
        mod_urination_u.type = "simple,negative"
        mod_urination_u.shown = true

        mod_urination_u.valueFn = function(p)
            local u = p:getModData()["Urinate"]
            if (type(u) ~= "number") then
                u = 0.0
            end
            return round(u * 100 * 1.66667, 1)
        end
            
        SimpleStatus:addStat("mod_urination_u", mod_urination_u, nil)
    end



    -- Excrementum
    if getActivatedMods():contains("Excrementum41") then
        
        local color = utils.color
        
        local function getPercStrUrine()
            local urinate = Excrementum.urine
            return tostring(urinate >= 1.1
                and math.floor(urinate * 10) / 10 .. " L"
                or (urinate >= 1.0
                    and "1.0 L"
                    or math.floor(urinate * 1000) .. " mL"
                )
            );
        end
        
        local function getPercStrFeces()
            local defecate = Excrementum.feces
            return tostring((defecate > 0.99499)
                and math.floor(defecate * 100 + 0.5)
                or round(defecate * 100, 1)
            ) .. '%'
        end

        -- Excrementum_Urine
        -- bartitle: IGUI_SS_BARTITLE_EXCREMENTUM_URINE
        local tbl_Urine = {}
        tbl_Urine.name = "Excrementum_Urine"
        tbl_Urine.type = "custom"
        tbl_Urine.shown = false
    
        tbl_Urine.valueFn = function()
            return math.floor(Excrementum.urine * 100 + 0.9) 
        end
        tbl_Urine.percentFn = function()
            return math.min(1, Excrementum.urine * 1.25)
        end
        tbl_Urine.colorFn = function()
            local X = 0.3 + Excrementum.Ms
            local Y = X + 0.15
    
            local u = Excrementum.urine
    
            if u <= 0.3 then
                return color.green
            elseif u <= X  then
                return color.yellow
            else
                return color.red
            end
        end
        -- tbl_Urine.textFn = nil
        tbl_Urine.textFn = getPercStrUrine
    
        -- Excrementum_Feces
        --  bartitle: IGUI_SS_BARTITLE_EXCREMENTUM_FECES
        local tbl_Feces = {}
        tbl_Feces.name = "Excrementum_Feces"
        tbl_Feces.type = "custom"
        tbl_Feces.shown = false
    
        tbl_Feces.valueFn = function() 
            return math.min(100, math.floor(Excrementum.feces * 100)) 
        end
        tbl_Feces.percentFn = function()
            return math.min(1, Excrementum.feces)
        end
        tbl_Feces.colorFn = function()
            if Excrementum.exc and Excrementum.exc.col.td then
                return color.red
            elseif Excrementum.feces >= 0.3 then
                return color.yellow
            else
                return color.green
            end
        end
        -- tbl_Feces.textFn = nil
        tbl_Feces.textFn = getPercStrFeces


        SimpleStatus:addStat("Excrementum_Urine", tbl_Urine, nil)
        SimpleStatus:addStat("Excrementum_Feces", tbl_Feces, nil)
    end

    if getActivatedMods():contains("LifestyleHobbies") then
        -- print("find life mod")

        -- init aim table
        local statuses = {
            {name = "mod_bathroomNeed", type = "simple,negative", shown = true},
            {name = "mod_hygieneNeed", type = "simple,negative", shown = true},
        }
    
        -- ipairs statuses and getData
        for _, status in ipairs(statuses) do
            status.valueFn = function(player)
                local modData = player:getModData()
                local v = modData[status.name:match("mod_(.*)")]
                if v == nil then
                    return 0
                else
                    return round(v, 0)
                end
            end
    
            -- addStat
            SimpleStatus:addStat(status.name, status, nil)
        end
    end

    if getActivatedMods():contains("Defecation") then
        
        print("find Defecation mod")

        local statuses = {
            {name = "mod_Defecate", type = "simple,negative", shown = true},
        }
        for _, status in ipairs(statuses) do
            status.valueFn = function(player)
                local modData = player:getModData()
                local v = modData[status.name:match("mod_(.*)")]
                if v == nil then
                    return 0
                else
                    return round((v/0.6)*100, 1)
                end
            end
    
            -- addStat
            SimpleStatus:addStat(status.name, status, nil)
        end


    end
end