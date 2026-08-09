require("SimpleStatus")

-- local utils = require("ss.utils")

return function()
    -- ========================================================
    -- !! NOT COMPATIBLE WITH B42, JUST FOR MODDING SHOWCASE !!
    -- ========================================================

    -- -- Urination 
    -- if getActivatedMods():contains("Urination") then
    --     local function round(num, numDecimalPlaces)
    --         local mult = 10 ^ (numDecimalPlaces or 0)
    --         return math.floor(num * mult + 0.5) / mult
    --     end

    --     local mod_urination_u = {}
    --     mod_urination_u.name = "mod_urination_u"
    --     mod_urination_u.type = "simple,negative"
    --     mod_urination_u.shown = true

    --     mod_urination_u.valueFn = function(p)
    --         local u = p:getModData()["Urinate"]
    --         if (type(u) ~= "number") then
    --             u = 0.0
    --         end
    --         return round(u * 100 * 1.66667, 1)
    --     end

    --     SimpleStatus:addStat("mod_urination_u", mod_urination_u, nil)
    -- end

end
