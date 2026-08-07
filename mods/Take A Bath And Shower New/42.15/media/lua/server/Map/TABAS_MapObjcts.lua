local PRIORITY = 5

local TABAS_TubEdge = require("BuildingObjects/TABAS_TubEdge")

local function OnLoadBathObjectFaucet(isoObject)
    local square = isoObject:getSquare()
    local facing = isoObject:getFacing()
	TABAS_TubEdge.createTubEdge(square, facing, true, true)
end

local function OnLoadBathObjectTub(isoObject)
    local square = isoObject:getSquare()
    local facing = isoObject:getFacing()
	TABAS_TubEdge.createTubEdge(square, facing, false, true)
end

-- for migrated old version.
local function LoadDestroyedShower(isoObject)
    local destroy = false
    local sprite = isoObject:getSprite()
    if sprite then
        local props = sprite:getProperties()
        if props and props:has("CustomName") and props:get("CustomName") == "Shower" then
            destroy = true
        end
    else
        destroy = true
    end
    if destroy then
        local sq = isoObject:getSquare()
        if not sq then return end
        sq:transmitRemoveItemFromSquare(isoObject, false)
    end
end

-- * For now, it use OnLoadWithSprite from the perspective of version migration,
-- * but in the future should probably use OnNewWithSprite.

-- to S (for S & N ) 
-- ===== Vanilla =====
MapObjects.OnLoadWithSprite("fixtures_bathroom_01_24", OnLoadBathObjectTub, PRIORITY) -- tub S
MapObjects.OnLoadWithSprite("fixtures_bathroom_01_25", OnLoadBathObjectFaucet, PRIORITY) -- faucet S
MapObjects.OnLoadWithSprite("fixtures_bathroom_01_53", OnLoadBathObjectTub, PRIORITY) -- tub N
MapObjects.OnLoadWithSprite("fixtures_bathroom_01_52", OnLoadBathObjectFaucet, PRIORITY) -- faucet N
-- ===== tabas 01 =====
MapObjects.OnLoadWithSprite("tabas_fixtures_bathroom_01_24", OnLoadBathObjectTub, PRIORITY)
MapObjects.OnLoadWithSprite("tabas_fixtures_bathroom_01_25", OnLoadBathObjectFaucet, PRIORITY)
MapObjects.OnLoadWithSprite("tabas_fixtures_bathroom_01_53", OnLoadBathObjectTub, PRIORITY)
MapObjects.OnLoadWithSprite("tabas_fixtures_bathroom_01_52", OnLoadBathObjectFaucet, PRIORITY)
-- ===== tabas 02 =====
MapObjects.OnLoadWithSprite("tabas_fixtures_bathroom_02_24", OnLoadBathObjectTub, PRIORITY)
MapObjects.OnLoadWithSprite("tabas_fixtures_bathroom_02_25", OnLoadBathObjectFaucet, PRIORITY)
MapObjects.OnLoadWithSprite("tabas_fixtures_bathroom_02_53", OnLoadBathObjectTub, PRIORITY)
MapObjects.OnLoadWithSprite("tabas_fixtures_bathroom_02_52", OnLoadBathObjectFaucet, PRIORITY)
-- ===== tabas 03 =====
MapObjects.OnLoadWithSprite("tabas_fixtures_bathroom_03_24", OnLoadBathObjectTub, PRIORITY)
MapObjects.OnLoadWithSprite("tabas_fixtures_bathroom_03_25", OnLoadBathObjectFaucet, PRIORITY)
MapObjects.OnLoadWithSprite("tabas_fixtures_bathroom_03_53", OnLoadBathObjectTub, PRIORITY)
MapObjects.OnLoadWithSprite("tabas_fixtures_bathroom_03_52", OnLoadBathObjectFaucet, PRIORITY)

-- to E (for E & W) 
-- ===== Vanilla =====
MapObjects.OnLoadWithSprite("fixtures_bathroom_01_27", OnLoadBathObjectTub, PRIORITY) -- tub E
MapObjects.OnLoadWithSprite("fixtures_bathroom_01_26", OnLoadBathObjectFaucet, PRIORITY) -- faucet E
MapObjects.OnLoadWithSprite("fixtures_bathroom_01_54", OnLoadBathObjectTub, PRIORITY) -- tub W
MapObjects.OnLoadWithSprite("fixtures_bathroom_01_55", OnLoadBathObjectFaucet, PRIORITY) -- faucet W
-- ===== tabas 01 =====
MapObjects.OnLoadWithSprite("tabas_fixtures_bathroom_01_27", OnLoadBathObjectTub, PRIORITY)
MapObjects.OnLoadWithSprite("tabas_fixtures_bathroom_01_26", OnLoadBathObjectFaucet, PRIORITY)
MapObjects.OnLoadWithSprite("tabas_fixtures_bathroom_01_54", OnLoadBathObjectTub, PRIORITY)
MapObjects.OnLoadWithSprite("tabas_fixtures_bathroom_01_55", OnLoadBathObjectFaucet, PRIORITY)
-- ===== tabas 02 =====
MapObjects.OnLoadWithSprite("tabas_fixtures_bathroom_02_27", OnLoadBathObjectTub, PRIORITY)
MapObjects.OnLoadWithSprite("tabas_fixtures_bathroom_02_26", OnLoadBathObjectFaucet, PRIORITY)
MapObjects.OnLoadWithSprite("tabas_fixtures_bathroom_02_54", OnLoadBathObjectTub, PRIORITY)
MapObjects.OnLoadWithSprite("tabas_fixtures_bathroom_02_55", OnLoadBathObjectFaucet, PRIORITY)
-- ===== tabas 03 =====
MapObjects.OnLoadWithSprite("tabas_fixtures_bathroom_03_27", OnLoadBathObjectTub, PRIORITY)
MapObjects.OnLoadWithSprite("tabas_fixtures_bathroom_03_26", OnLoadBathObjectFaucet, PRIORITY)
MapObjects.OnLoadWithSprite("tabas_fixtures_bathroom_03_54", OnLoadBathObjectTub, PRIORITY)
MapObjects.OnLoadWithSprite("tabas_fixtures_bathroom_03_55", OnLoadBathObjectFaucet, PRIORITY)

-- Destroyed N/W Deluxe Shower From Old Version
MapObjects.OnLoadWithSprite("fixtures_bathroom_01_70", LoadDestroyedShower, PRIORITY)
MapObjects.OnLoadWithSprite("fixtures_bathroom_01_71", LoadDestroyedShower, PRIORITY)
