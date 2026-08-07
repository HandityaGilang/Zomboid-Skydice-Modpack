local overlayMap = {}
overlayMap.VERSION = 1

local TABAS_Sprites = require("TABAS_Sprites")

local DIR_KEYS = {"spriteS","spriteE","spriteN","spriteW"}

local TEMPLATE_BY_INDEX = {
    [24] = {{ name="other", chance=3, usage="", tiles={"fixtures_01_24","fixtures_01_28"} }},
    [25] = {{ name="other", chance=2, usage="", tiles={"fixtures_01_25","fixtures_01_29"} }},
    [26] = {{ name="other", chance=2, usage="", tiles={"fixtures_01_26","fixtures_01_30"} }},
    [27] = {{ name="other", chance=3, usage="", tiles={"fixtures_01_27","fixtures_01_31"} }},
    [52] = {{ name="other", chance=2, usage="", tiles={"fixtures_01_32","fixtures_01_36"} }},
    [53] = {{ name="other", chance=3, usage="", tiles={"fixtures_01_33","fixtures_01_37"} }},
    [54] = {{ name="other", chance=3, usage="", tiles={"fixtures_01_34","fixtures_01_38"} }},
    [55] = {{ name="other", chance=2, usage="", tiles={"fixtures_01_35","fixtures_01_39"} }},
}

local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local r = {}
    for k,v in pairs(t) do
		 r[k] = deepCopy(v)
	end
    return r
end

local function addOverlaysToBathtubModels(modelType)
    local def = TABAS_Sprites.Bathtub and TABAS_Sprites.Bathtub[modelType]
    if not def then return end

    for _, dirKey in ipairs(DIR_KEYS) do
        local dir = def[dirKey]

        if type(dir) == "table" then
            local bathtub = { dir.faucet, dir.tub }
            for i = 1, #bathtub do
                local sprite = bathtub[i]
                if type(sprite) == "string" then
                    local index = tonumber(sprite:match("_(%d+)$"))
                    local templ = index and TEMPLATE_BY_INDEX[index]
                    if templ then
                        overlayMap[sprite] = deepCopy(templ)
                    end
                end
            end

        elseif type(dir) == "string" then
            local sprite = dir
            local index = tonumber(sprite:match("_(%d+)$"))
            local templ = index and TEMPLATE_BY_INDEX[index]
            if templ then
                overlayMap[sprite] = deepCopy(templ)
            end
        end
    end
end

addOverlaysToBathtubModels("Large Deluxe Clean")
addOverlaysToBathtubModels("Large Deluxe Fixed")
addOverlaysToBathtubModels("Improved Large Deluxe")
addOverlaysToBathtubModels("Improved Large Deluxe Clean")

if not TILEZED then
    getTileOverlays():addOverlays(overlayMap)
end

return overlayMap
