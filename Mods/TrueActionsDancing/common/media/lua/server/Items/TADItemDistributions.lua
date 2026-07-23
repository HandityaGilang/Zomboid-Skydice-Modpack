-- TADItemDistributions.lua by TwistOnFire
 
-- Adds TAD dance magazines anywhere comics can spawn (ComicBook / ComicBook_Retail),
-- while avoiding interference with skill-book spawns by inserting into the "junk" pool.
 
 
-- adjust this to your liking 
local CHANCE = 0.1
 
-- Deduped magazine list (45 unique items)
local DANCE_MAGS = {
    "TAD.BobTA_African_Noodle_Mag",
    "TAD.BobTA_African_Rainbow_Mag",
    "TAD.BobTA_Arm_Push_Mag",
    "TAD.BobTA_Arm_Wave_One_Mag",
    "TAD.BobTA_Arm_Wave_Two_Mag",
    "TAD.BobTA_Arms_Hip_Hop_Mag",
    "TAD.BobTA_Around_The_World_Mag",
    "TAD.BobTA_Bboy_Hip_Hop_One_Mag",
    "TAD.BobTA_Bboy_Hip_Hop_Three_Mag",
    "TAD.BobTA_Bboy_Hip_Hop_Two_Mag",
    "TAD.BobTA_Body_Wave_Mag",
    "TAD.BobTA_Booty_Step_Mag",
    "TAD.BobTA_Breakdance_Brooklyn_Uprock_Mag",
    "TAD.BobTA_Cabbage_Patch_Mag",
    "TAD.BobTA_Can_Can_Mag",
    "TAD.BobTA_Chicken_Mag",
    "TAD.BobTA_Crazy_Legs_Mag",
    "TAD.BobTA_Defile_De_Samba_Parade_Mag",
    "TAD.BobTA_Hokey_Pokey_Mag",
    "TAD.BobTA_Kick_Step_Mag",
    "TAD.BobTA_Macarena_Mag",
    "TAD.BobTA_Maraschino_Mag",
    "TAD.BobTA_MoonWalk_One_Mag",
    "TAD.BobTA_Northern_Soul_Spin_Mag",
    "TAD.BobTA_Northern_Soul_Spin_On_Floor_Mag",
    "TAD.BobTA_Raise_The_Roof_Mag",
    "TAD.BobTA_Really_Twirl_Mag",
    "TAD.BobTA_Rib_Pops_Mag",
    "TAD.BobTA_Rockette_Kick_Mag",
    "TAD.BobTA_Rumba_Dancing_Mag",
    "TAD.BobTA_Running_Man_One_Mag",
    "TAD.BobTA_Running_Man_Three_Mag",
    "TAD.BobTA_Running_Man_Two_Mag",
    "TAD.BobTA_Salsa_Double_Twirl_Mag",
    "TAD.BobTA_Salsa_Double_Twirl_and_Clap_Mag",
    "TAD.BobTA_Salsa_Mag",
    "TAD.BobTA_Salsa_Side_to_Side_Mag",
    "TAD.BobTA_Shim_Sham_Mag",
    "TAD.BobTA_Shimmy_Mag",
    "TAD.BobTA_Shuffling_Mag",
    "TAD.BobTA_Side_to_Side_Mag",
    "TAD.BobTA_Twist_One_Mag",
    "TAD.BobTA_Twist_Two_Mag",
    "TAD.BobTA_Uprock_Indian_Step_Mag",
    "TAD.BobTA_YMCA_Mag"
}
 
local function _listHasComic(items)
    if type(items) ~= "table" then return false end
    for i = 1, #items, 2 do
        local it = items[i]
        if it == "ComicBook" or it == "ComicBook_Retail" then
            return true
        end
    end
    return false
end
 
local function _hasItem(items, itemName)
    if type(items) ~= "table" then return false end
    for i = 1, #items, 2 do
        if items[i] == itemName then
            return true
        end
    end
    return false
end
 
-- Clone/ensure a per-distribution junk table so we never mutate shared vanilla tables (e.g. ClutterTables.*).
local function _ensureOwnJunk(container)
    if type(container) ~= "table" then return nil end
 
    local j = container.junk
    if type(j) ~= "table" then
        container.junk = { rolls = 1, items = {} }
        return container.junk
    end
 
    -- Shallow clone + clone items array
    local clone = {}
    for k, v in pairs(j) do
        if k == "items" and type(v) == "table" then
            local copied = {}
            for i = 1, #v do copied[i] = v[i] end
            clone.items = copied
        else
            clone[k] = v
        end
    end
 
    if type(clone.items) ~= "table" then clone.items = {} end
    if clone.rolls == nil then clone.rolls = j.rolls or 1 end
 
    container.junk = clone
    return clone
end
 
local function _addAllMagsToJunk(container, danceMags)
    local junk = _ensureOwnJunk(container)
    if not junk then return end
    local items = junk.items
    if type(items) ~= "table" then
        junk.items = {}
        items = junk.items
    end
 
    for _, mag in ipairs(danceMags) do
        if not _hasItem(items, mag) then
            table.insert(items, mag)
            table.insert(items, CHANCE)
        end
    end
end


local function PatchComicSpawns()
    local apply = (not getActivatedMods():contains("\TrueActionsDancingVHS") and not getActivatedMods():contains("\TrueActionsDancingVHS_test")) or
        getActivatedMods():contains("\TrueActionsDancingVHS_MAG") or
        getActivatedMods():contains("\TrueActionsDancingVHS_MAG_test")
    if not apply then return end
    
    -- TODO init dance mag from ScriptManager to handle those from other mods
    local danceMags = DANCE_MAGS
    
    -- ProceduralDistributions (procLists like MagazineRackMixed, CrateComics, ComicStoreShelfComics, etc.)
    if type(ProceduralDistributions) == "table" and type(ProceduralDistributions.list) == "table" then
        for _, dist in pairs(ProceduralDistributions.list) do
            if type(dist) == "table" then
                local hasComic = _listHasComic(dist.items) or (type(dist.junk) == "table" and _listHasComic(dist.junk.items))
                if hasComic then
                    _addAllMagsToJunk(dist, danceMags)
                end
            end
        end
    end
 
    -- SuburbsDistributions (room/container distributions and bag distributions)
    if type(SuburbsDistributions) == "table" then
        for _, roomOrGroup in pairs(SuburbsDistributions) do
            if type(roomOrGroup) == "table" then
                for _, container in pairs(roomOrGroup) do
                    if type(container) == "table" then
                        local hasComic = _listHasComic(container.items) or (type(container.junk) == "table" and _listHasComic(container.junk.items))
                        if hasComic then
                            _addAllMagsToJunk(container,danceMags)
                        end
                    end
                end
            end
        end
    end
end
 
-- Run at the safest time if available, otherwise run immediately.
if Events and Events.OnPreDistributionMerge and Events.OnPreDistributionMerge.Add then
    Events.OnPreDistributionMerge.Add(PatchComicSpawns)
else
    PatchComicSpawns()
end

