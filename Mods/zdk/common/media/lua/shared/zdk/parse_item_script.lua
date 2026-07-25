zdk = zdk or {}

-- XXX getScriptLines() returns scripts in reverse/random order
local function parseItemScriptV1(item)
    local lines = nil
    if item.getScriptLines then
        lines = item:getScriptLines()
    end

    if not lines or lines:size() == 0 and item.getScriptItem then
        local scriptItem = item:getScriptItem()
        if scriptItem then
            lines = scriptItem:getScriptLines()
        end
    end

    if not lines or lines:size() == 0 then
        if item and item.getFullName and item:getFullName() == "Base.HunkZ" then
            -- silence warning about missing script lines for Base.HunkZ, which is a copy of Base.HottieZ with no script lines of its own
            return zdk.parse_item_script("Base.HottieZ")
        end
        zdk.logger:warn("parse_item_script(): no script lines for %s", item)
        return {}
    end

    local result = {}
    for i=0,lines:size()-1 do
        local line = lines:get(i):gsub("[\t ,}]", "")
        local a = line:split("=")
        if a and #a == 2 then
            result[a[1]:lower()] = a[2]
        end
    end
    return result
end

-- parses all bodies in correct order
local function parseItemScriptV2(item)
    local bodies = nil
    if item.getLoadedScriptBodies then
        bodies = item:getLoadedScriptBodies()
    end

    if not bodies or bodies:size() == 0 and item.getScriptItem then
        local scriptItem = item:getScriptItem()
        if scriptItem then
            bodies = scriptItem:getLoadedScriptBodies()
        end
    end

    if not bodies or bodies:size() == 0 then
        if item and item.getFullName and item:getFullName() == "Base.HunkZ" then
            -- silence warning about missing script bodies for Base.HunkZ, which is a copy of Base.HottieZ with no script bodies of its own
            return zdk.parse_item_script("Base.HottieZ")
        end
        zdk.logger:warn("parse_item_script(): no script bodies for %s", item)
        return {}
    end

    local result = {}
    for i=0,bodies:size()-1 do
        local body = bodies:get(i)
        if body then
            local key = nil
            local lines = body:split("\n")
            for _, line in ipairs(lines) do
                line = line:gsub("\t", " "):gsub("[\r,}]", ""):trim()
                local a = line:split("=")
                if #a == 2 then
                    key = a[1]:lower():trim()
                    result[key] = a[2]:trim()
                elseif #a == 1 and key and result[key] and luautils.stringEnds(result[key], ";") then
                    -- handle multi-line values:
                    --   TeachedRecipes = Assemble Steel Nun-Chucks;
                    --                    Assemble Polymer Nun-Chucks;
                    --                    Assemble Wooden Nun-Chucks,
                    result[key] = result[key] .. a[1]
                end
            end
        end
    end
    return result
end

-- Parses the item script lines into a table of key-value pairs.
-- NB: keys are lowercased, values are not modified.
--
-- lua> zdk.parse_item_script("Base.Belt2")
-- {
--               "itemtype" = "base:clothing",
--           "bodylocation" = "base:belt",
--       "worldstaticmodel" = "Belt_Ground",
--    "researchablerecipes" = "Forge_Buckle",
--                   "icon" = "Belt",
--           "clothingitem" = "Belt",
--                 "weight" = "0.2",
--    "attachmentsprovided" = "SmallBeltLeft;SmallBeltRight",
--        "displaycategory" = "Accessory",
--             "fabrictype" = "Leather",
--                   "tags" = "base:hasmetal;base:buckle;base:scrapasbelt",
-- }
function zdk.parse_item_script(item)
    if type(item) == "string" then
        item = getItem(item)
    end
    if not item then return {} end

    local result = parseItemScriptV2(item)
    if result and not table.isempty(result) then return result end

    return parseItemScriptV1(item)
end
