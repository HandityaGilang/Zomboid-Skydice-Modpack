
RGMManager = RGMManager or {}
if RGMManager.InventoryLoaded then return end
RGMManager.InventoryLoaded = true

-- B42: All trait-checking methods (HasTrait, hasTrait, getTraits) throw Java exceptions
-- in Kahlua that cannot be caught by pcall. Return false to prevent crashes.
-- Trait-based rarity bonuses are disabled until a working B42 API is found.
function RSW_hasTrait(p, trait)
    return false
end

function RGMManager.getRarityTweakerForPlayer(_player, _item)
    local weaponLevel = 0
    if _item:isRanged() then
        weaponLevel = math.floor( (_player:getPerkLevel(Perks.Aiming)*2 +_player:getPerkLevel(Perks.Reloading)) / 3 + 0.5)
    else
        -- B42: getPerk() returns perk name = category name directly
        local perk = type(_item.getPerk) == "function" and tostring(_item:getPerk()) or nil
        if perk == "Axe"       then weaponLevel = _player:getPerkLevel(Perks.Axe)
        elseif perk == "LongBlade"  then weaponLevel = _player:getPerkLevel(Perks.LongBlade)
        elseif perk == "SmallBlade" then weaponLevel = _player:getPerkLevel(Perks.SmallBlade)
        elseif perk == "SmallBlunt" then weaponLevel = _player:getPerkLevel(Perks.SmallBlunt)
        elseif perk == "Blunt"      then weaponLevel = _player:getPerkLevel(Perks.Blunt)
        elseif perk == "Spear"      then weaponLevel = _player:getPerkLevel(Perks.Spear)
        end
    end
    local maintenanceLevel = _player:getPerkLevel(Perks.Maintenance)
    local tinkeringLevel = _player:getPerkLevel(Perks.Tinkering)
    local rarityTweaker = 1 - weaponLevel*0.005 - maintenanceLevel*0.01 - tinkeringLevel*0.03
    if RSW_hasTrait(_player,"Lucky") then
        rarityTweaker = rarityTweaker - 0.03
    elseif RSW_hasTrait(_player,"Unlucky") then
        rarityTweaker = rarityTweaker + 0.03
    end
    if RSW_hasTrait(_player,"Clumsy") then
        rarityTweaker = rarityTweaker + 0.01
    end
    if RSW_hasTrait(_player,"AllThumbs") then
        rarityTweaker = rarityTweaker + 0.01
    end
    if RSW_hasTrait(_player,"Handy") then
        rarityTweaker = rarityTweaker - 0.02
    end
    if RSW_hasTrait(_player,"Mechanics") or RSW_hasTrait(_player,"Mechanics2") then
        rarityTweaker = rarityTweaker - 0.02
    end
    return rarityTweaker or 1
end



local function checkPlayerInventoryForWeaponModifiers()
    local player = getPlayer() or getSpecificPlayer(0)
    if not player then return end
    local inventory = player:getInventory()
    if not inventory then return end
    local containerItems = inventory:getItems()
    if not containerItems then return end
    local craftMult = (SandboxVars.RGM and SandboxVars.RGM.ChanceMultiplierForCraftedItems) or 0.75
    for i = 0, containerItems:size()-1 do
        local item = containerItems:get(i)
        local newModifier = nil
        if item and instanceof(item, "HandWeapon") then
            local rarityTweaker = RGMManager.getRarityTweakerForPlayer(player, item)
            newModifier = RGMManager.checkItem(item, player, rarityTweaker + 0.1, craftMult)
        else
            newModifier = RGMManager.checkItem(item, player, 1, craftMult)
        end
        -- For magazines: also call applyMagazineStats so getText()-based translation runs
        -- in the client Lua context (getText works here, unlike in server-Lua / ISEjectMagazine).
        -- This ensures name and MaxAmmo are applied after server syncs modData.
        if item and item:getModData().modifierChecked and item:getModData().modifier then
            if type(item.getAmmoType) == "function" and item:getAmmoType() ~= nil
                and not (type(item.isRanged) == "function" and item:isRanged()) then
                pcall(function() RGMManager.applyMagazineStats(item) end)
            end
        end
        if getActivatedMods():contains("WeaponModifiersReforge") then
            if newModifier and newModifier.modifierName ~= getText("Tooltip_modifier_standard") then
                RGMManager.awardTinkeringXP(player, newModifier, 0.25)
            end
        end
    end
end

Events.EveryOneMinute.Add(checkPlayerInventoryForWeaponModifiers)

-- Colored inventory names: color the item name by modifier rarity (always enabled).
-- Works with both vanilla ISInventoryPane and Neat Clean UI (CleanUI mod).
local RGM_InventoryColorHookInstalled = false

-- Scan one inventory container and fill the name→color lookup.
local function RGM_scanInventoryForColors(inv, lookup)
    if not inv or type(inv.getItems) ~= "function" then return end
    local items = inv:getItems()
    if not items then return end
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item then
            local mod = item:getModData().modifier
            if mod and mod.fontColor and mod.translationChecked then
                local name = item:getName()
                if name then lookup[name] = mod.fontColor end
            end
        end
    end
end

-- Build per-render lookup: itemName → fontColor from actual item modData.
-- Covers all modifier types including dynamic XP/elite ones.
-- Both vanilla and CleanUI ISInventoryPane store the container as self.inventory.
local function RGM_buildColorLookup(self)
    local lookup = {}
    if self.inventory then
        RGM_scanInventoryForColors(self.inventory, lookup)
    end
    return lookup
end

-- Find modifier color for a drawn text string.
-- Handles CleanUI specifics: NeatTool truncates long names with "...",
-- and stacked items get " (N)" appended before truncation.
local function RGM_findColor(str, lookup)
    -- 1. Exact match (vanilla path, or short names that fit without truncation)
    local c = lookup[str]
    if c then return c end
    -- 2. Strip CleanUI stack-count suffix " (N)" and retry
    local base = str:match("^(.+) %(%d+%)$")
    if base then
        c = lookup[base]
        if c then return c end
    end
    -- 3. Prefix-match for "..." truncation by NeatTool.truncateText
    if str:sub(-3) == "..." then
        local prefix = str:sub(1, -4)
        for name, nc in pairs(lookup) do
            if name:sub(1, #prefix) == prefix then return nc end
        end
    end
    -- 4. Same but with count suffix already stripped (truncated stack row)
    if base and base:sub(-3) == "..." then
        local prefix = base:sub(1, -4)
        for name, nc in pairs(lookup) do
            if name:sub(1, #prefix) == prefix then return nc end
        end
    end
    return nil
end

local function installRGMInventoryNameColorHook()
    if not ISInventoryPane or RGM_InventoryColorHookInstalled then return end
    local oldRenderDetails = ISInventoryPane.renderdetails
    if not oldRenderDetails then return end
    RGM_InventoryColorHookInstalled = true

    function ISInventoryPane:renderdetails(doDragged)
        local colorLookup = RGM_buildColorLookup(self)
        local oldDrawText = self.drawText
        self.drawText = function(pane, str, x, y, r, g, b, a, font)
            local color = RGM_findColor(tostring(str or ""), colorLookup)
            if color then
                return oldDrawText(pane, str, x, y, color[1], color[2], color[3], a or 1.0, font)
            end
            return oldDrawText(pane, str, x, y, r, g, b, a, font)
        end
        local ok, result = pcall(oldRenderDetails, self, doDragged)
        self.drawText = oldDrawText
        if not ok then error(result) end
        return result
    end
end

installRGMInventoryNameColorHook()

Events.OnGameStart.Add(installRGMInventoryNameColorHook)

local function RGM_isMagFullyRead(mag)
    if not mag then return false end
    local totalPages = mag:getNumberOfPages()
    if not totalPages or totalPages <= 0 then return false end
    local readPages = mag:getAlreadyReadPages()
    return readPages and readPages >= totalPages
end

-- Helper used by context menu and timed action.
-- Returns true if player has permanent tinkering knowledge (modData flag)
-- OR has a fully-read TinkeringMag in their inventory right now.
function RGM_playerHasTinkerKnowledge(player)
    if not player then return false end
    local md = player:getModData()
    if md and md.RGM_tinkerKnown then return true end
    local inv = player:getInventory()
    if not inv then return false end
    local mag = inv:getItemFromType("TinkeringMag")
    return RGM_isMagFullyRead(mag)
end

-- Persist knowledge permanently in modData so it survives losing the magazine
local function RGM_checkTinkerMagazine()
    local player = getPlayer() or getSpecificPlayer(0)
    if not player then return end
    local modData = player:getModData()
    if modData.RGM_tinkerKnown then return end
    if RGM_playerHasTinkerKnowledge(player) then
        modData.RGM_tinkerKnown = true
        if type(player.transmitModData) == "function" then player:transmitModData() end
    end
end

Events.EveryOneMinute.Add(RGM_checkTinkerMagazine)

-- Dispatch client-side modifier apply for a single item (no rolling, name translation only).
-- Called from both the inventory-window and floor-item handlers below.
local function RGM_applyClientItem(item)
    if not item or not item:getModData().modifierChecked then return end
    if not item:getModData().modifier then return end
    if instanceof(item, "HandWeapon") then
        pcall(function() RGMManager.applyModifierStatsToItem(item, item:getModData().modifier) end)
    elseif instanceof(item, "InventoryContainer") then
        pcall(function() RGMManager.applyContainerStats(item) end)
    elseif instanceof(item, "Clothing") then
        pcall(function() RGMManager.applyClothingStats(item) end)
    elseif type(item.getAmmoType) == "function" and item:getAmmoType() ~= nil
        and not (type(item.isRanged) == "function" and item:isRanged()) then
        pcall(function() RGMManager.applyMagazineStats(item) end)
    elseif type(item.getDisplayCategory) == "function"
        and item:getDisplayCategory() == "LightSource" then
        pcall(function() RGMManager.applyFlashlightStats(item) end)
    end
end

-- Apply translated modifier names to all items in currently open inventory/loot windows.
-- Server-side handlers are in RGMManager.lua and not available on dedicated MP clients.
local function RGM_applyModifiersInVisibleContainers(_iSInventoryPage, _state)
    if _state ~= "end" or not _iSInventoryPage then return end
    for _, v in ipairs(_iSInventoryPage.backpacks) do
        local inv = v and v.inventory
        if inv and type(inv.getItems) == "function" then
            local items = inv:getItems()
            if items then
                for j = 0, items:size() - 1 do
                    RGM_applyClientItem(items:get(j))
                end
            end
        end
    end
end
Events.OnRefreshInventoryWindowContainers.Add(RGM_applyModifiersInVisibleContainers)

local function RGM_applyModifiersForFloorItems(square)
    if not square then return end
    local worldObjects = square:getWorldObjects()
    if not worldObjects then return end
    for i = 0, worldObjects:size() - 1 do
        local obj = worldObjects:get(i)
        if obj and instanceof(obj, "IsoWorldInventoryObject") then
            RGM_applyClientItem(obj:getItem())
        end
    end
end
Events.LoadGridsquare.Add(RGM_applyModifiersForFloorItems)
Events.ReuseGridsquare.Add(RGM_applyModifiersForFloorItems)

-- Server sends "ApplyMagStats" after magazine eject. Modifier data is in the payload so we
-- don't need to wait for transmitModData (which arrives asynchronously on the client).
-- getText() works in client-Lua context, so resolveModifierName can translate the name here.
local function RGM_onServerCommand(module, command, args)
    if module ~= "RGM" or command ~= "ApplyMagStats" then return end
    if not args or not args.modifierName or not args.statsMultipliers then return end
    local player = getPlayer() or getSpecificPlayer(0)
    if not player then return end
    local items = player:getInventory():getItems()
    if not items then return end
    -- Find the newly ejected magazine (no modifierChecked = fresh instanceItem from PZ)
    for i = items:size() - 1, 0, -1 do
        local item = items:get(i)
        if item and not item:getModData().modifierChecked
            and type(item.getAmmoType) == "function" and item:getAmmoType() ~= nil
            and not (type(item.isRanged) == "function" and item:isRanged())
        then
            local si = type(item.getScriptItem) == "function" and item:getScriptItem()
            local baseName = args.scriptName or (si and si:getDisplayName()) or item:getDisplayName()
            item:getModData().modifier    = { modifierName = args.modifierName, statsMultipliers = args.statsMultipliers, fontColor = args.fontColor }
            item:getModData().scriptStats = { MaxAmmo = args.scriptMaxAmmo, ScriptName = baseName }
            item:getModData().modifierChecked = true
            pcall(function() RGMManager.applyMagazineStats(item) end)
            break
        end
    end
end
Events.OnServerCommand.Add(RGM_onServerCommand)

-- Clothing XP bonuses ("xp PerkName" keys) are handled server-side in XpUpdate.lua
-- via Events.AddXP, same pattern as weapon experience multiplier.

