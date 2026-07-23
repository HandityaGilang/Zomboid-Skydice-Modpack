--[[
    Spongie's Open Jackets - Build 42.19 compatibility fix
    --------------------------------------------------------
    This file REPLACES (overrides, by identical relative path) the broken
    SpongieOpenJackets/SpongieCopy_BodyLocationsTweaker.lua shipped by
    "Spongie's Open Jackets".

    Why the original breaks on 42.19.0:
        The original tweaker reaches the private hideModel / exclusive lists of
        each zombie.characters.WornItems.BodyLocation via the Lua reflection
        helpers getClassField()/getClassFieldVal(). In 42.19.0 both helpers throw
        "Not in debug" (zombie.Lua.LuaManager$GlobalObject) unless the game is run
        with -debug, so every call fails:
            - "expected 2 arguments, got 1" / "Not in debug" at top level (line 18)
            - "attempted index: unhideModel of non-table: null" in RemoveSweaterHide

    How this fix works (no reflection, no debug needed):
        BodyLocationGroup / BodyLocation expose no public "remove" for hideModel,
        but they DO expose readers (isHideModel/isExclusive/isAltModel/isMultiItem,
        getAllLocations, getId) and builders (getOrCreateLocation, setHideModel,
        setExclusive, setAltModel, setMultiItem). So we:
            1. let RemoveSweaterHide queue the (loc -> loc) hide pairs it wants gone
               through our unhideModel()/unsetExclusive() (now harmless, no reflection),
            2. on OnGameBoot (after every shared file - vanilla + mods - has finished
               populating the "Human" group) snapshot every relationship,
            3. BodyLocations.reset() and rebuild the "Human" group identically, minus
               the queued pairs.
        The rebuild faithfully preserves everything every other mod added; only the
        explicitly-queued pairs are dropped. Verified against the decompiled
        42.19.0 BodyLocation / BodyLocationGroup / BodyLocations sources.
--]]

require "NPCs/BodyLocations" -- ensure vanilla BodyLocations has populated the group

-- Singleton: the file can be executed more than once (LoadDirBase auto-run AND
-- require from RemoveSweaterHide). We must hand back the SAME table both times so
-- the queue RemoveSweaterHide fills is the queue apply() reads, and so we only
-- register a single OnGameBoot handler.
if _G.__SpongieBLTweaker then return _G.__SpongieBLTweaker end

local BodyLocationsTweaker = {}
BodyLocationsTweaker.group        = BodyLocations.getGroup("Human")
BodyLocationsTweaker._removeHide  = {} -- list of { fromLoc, toLoc }
BodyLocationsTweaker._removeExcl  = {} -- list of { locA, locB }

local function pairKey(a, b) return tostring(a) .. "|" .. tostring(b) end

-- queue a hideModel removal (matches the original call signature/intent)
function BodyLocationsTweaker:unhideModel(loc1, loc2)
    if loc1 ~= nil and loc2 ~= nil then
        self._removeHide[#self._removeHide + 1] = { loc1, loc2 }
    end
    return loc1
end

-- queue a mutual-exclusive removal (kept for API parity; RemoveSweaterHide
-- never calls this, but other consumers of the original file might)
function BodyLocationsTweaker:unsetExclusive(loc1, loc2)
    if loc1 ~= nil and loc2 ~= nil then
        self._removeExcl[#self._removeExcl + 1] = { loc1, loc2 }
    end
    return loc1
end

-- Snapshot a single BodyLocationGroup into a plain table.
local function snapshotGroup(group)
    local all   = group:getAllLocations()
    local count = all:size()

    -- ordered list of ItemBodyLocation ids (order matters: BodyLocationGroup.indexOf
    -- drives worn-item layering, so we recreate locations in their original order)
    local ids = {}
    for i = 0, count - 1 do
        ids[i + 1] = all:get(i):getId()
    end

    local multi, hides, excls, alts = {}, {}, {}, {}
    for i = 1, count do
        local locA = group:getLocation(ids[i])
        if locA ~= nil then
            if locA:isMultiItem() then multi[#multi + 1] = ids[i] end
            for j = 1, count do
                local b = ids[j]
                if locA:isHideModel(b) then hides[#hides + 1] = { ids[i], b } end
                if locA:isExclusive(b) then excls[#excls + 1] = { ids[i], b } end
                if locA:isAltModel(b)  then alts[#alts  + 1] = { ids[i], b } end
            end
        end
    end

    return { id = group:getId(), ids = ids, multi = multi, hides = hides, excls = excls, alts = alts }
end

-- Snapshot EVERY body-location group (Human, Animal, and any modded group), then
-- rebuild them all. BodyLocations.reset() clears every group, so we cannot rebuild
-- only "Human" without losing the others. Removals are applied to our own group.
function BodyLocationsTweaker:apply()
    if #self._removeHide == 0 and #self._removeExcl == 0 then
        return -- nothing requested (e.g. Spongie Clothing handled it) -> don't touch anything
    end

    local targetGroupId = self.group:getId() -- "Human"

    -- build removal lookups (only applied to the target group)
    local removeHide = {}
    for _, p in ipairs(self._removeHide) do
        removeHide[pairKey(p[1], p[2])] = true
    end
    local removeExcl = {}
    for _, p in ipairs(self._removeExcl) do
        removeExcl[pairKey(p[1], p[2])] = true
        removeExcl[pairKey(p[2], p[1])] = true -- exclusivity is symmetric
    end

    -- snapshot all groups BEFORE we reset anything
    local groups = BodyLocations.getAllGroups()
    local snapshots = {}
    for i = 0, groups:size() - 1 do
        snapshots[#snapshots + 1] = snapshotGroup(groups:get(i))
    end

    -- rebuild every group; drop the queued pairs only from the target group
    BodyLocations.reset()
    for _, snap in ipairs(snapshots) do
        local applyRemovals = (snap.id == targetGroupId)
        local g = BodyLocations.getGroup(snap.id)
        for _, id in ipairs(snap.ids) do
            g:getOrCreateLocation(id)
        end
        for _, id in ipairs(snap.multi) do
            g:setMultiItem(id, true)
        end
        for _, p in ipairs(snap.hides) do
            if not (applyRemovals and removeHide[pairKey(p[1], p[2])]) then
                g:setHideModel(p[1], p[2])
            end
        end
        for _, p in ipairs(snap.excls) do
            if not (applyRemovals and removeExcl[pairKey(p[1], p[2])]) then
                g:setExclusive(p[1], p[2])
            end
        end
        for _, p in ipairs(snap.alts) do
            g:setAltModel(p[1], p[2])
        end
    end
end

_G.__SpongieBLTweaker = BodyLocationsTweaker

-- Defer the rebuild until every shared file (vanilla BodyLocations + this mod's
-- RemoveSweaterHide + any other clothing mod) has finished queuing.
Events.OnGameBoot.Add(function()
    BodyLocationsTweaker:apply()
end)

return BodyLocationsTweaker
