-- Use Items While Walking (B42) By Jeilko

require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISTimedActionQueue"

local UIWW = {}

local function isAmmoBox(item)
    if not item or type(item) ~= "userdata" then return false end
    local okCat, cat = pcall(function() return item.getDisplayCategory and item:getDisplayCategory() end)
    if not okCat or cat ~= "Ammo" then return false end

    local okType, tp = pcall(function() return item.getType and item:getType() end)
    if okType and tp and tp:find("Box", 1, true) then return true end

    local okFull, ft = pcall(function() return item.getFullType and item:getFullType() end)
    if okFull and ft and ft:find("Box", 1, true) then return true end

    return false
end

local function patchAmmoBoxUse()
    pcall(require, "TimedActions/ISUseItemAction")
    local klass = _G and _G.ISUseItemAction
    if type(klass) ~= "table" or type(klass.new) ~= "function" then return end
    if klass.__UIWWAmmoPatched then return end

    local old_new = klass.new
    klass.new = function(self, character, item, ...)
        local o = old_new(self, character, item, ...)
        if type(o) == "table" and isAmmoBox(item) then
            o.stopOnWalk = false
            o.stopOnRun  = true
            o.__UIWWAmmoBox = true
        end
        return o
    end

    klass.__UIWWAmmoPatched = true
end

local function patchReadBook()
    pcall(require, "TimedActions/ISReadABook")
    local klass = _G and _G.ISReadABook
    if type(klass) ~= "table" or type(klass.new) ~= "function" then return end
    if klass.__UIWWPatched then return end

    local old_new = klass.new
    klass.new = function(self, character, item, ...)
        local o = old_new(self, character, item, ...)
        if type(o) == "table" then
            o.stopOnWalk = false
            o.stopOnRun  = true
            o.__UIWWRead = true
        end
        return o
    end

    klass.__UIWWPatched = true
end

local function patchUnequip()
    pcall(require, "TimedActions/ISUnequipAction")
    local klass = _G and _G.ISUnequipAction
    if type(klass) ~= "table" or type(klass.new) ~= "function" then return end
    if klass.__UIWWPatched then return end

    local old_new = klass.new
    klass.new = function(self, character, item, maxTime, ...)
        local o = old_new(self, character, item, maxTime, ...)
        if type(o) == "table" then
            o.stopOnWalk = false
            o.stopOnRun  = true
            o.__UIWWUnequip = true
        end
        return o
    end

    klass.__UIWWPatched = true
end

local function patchWearClothing()
    pcall(require, "TimedActions/ISWearClothing")
    local klass = _G and _G.ISWearClothing
    if type(klass) ~= "table" or type(klass.new) ~= "function" then return end
    if klass.__UIWWPatched then return end

    klass.isStopOnWalk = function(item) return false end

    local old_new = klass.new
    klass.new = function(self, character, item, ...)
        local o = old_new(self, character, item, ...)
        if type(o) == "table" then
            o.stopOnWalk = false
            o.stopOnRun  = true
            o.__UIWWWear = true
        end
        return o
    end

    klass.__UIWWPatched = true
end

local function patchHandcraft()
    pcall(require, "Entity/TimedActions/ISHandcraftAction")
    local klass = _G and _G.ISHandcraftAction
    if type(klass) ~= "table" or type(klass.new) ~= "function" then return end
    if klass.__UIWWPatched then return end

    local old_new = klass.new
    klass.new = function(self, character, craftRecipe, containers, isoObject, craftBench, manualInputs, items, recipeItem, variableInputRatio, eatPercentage, ...)
        local o = old_new(self, character, craftRecipe, containers, isoObject, craftBench, manualInputs, items, recipeItem, variableInputRatio, eatPercentage, ...)
        if type(o) == "table" then
            o.stopOnWalk = false
            o.stopOnRun  = true
            o.__UIWWHandcraft = true
        end
        return o
    end

    local old_start = klass.start
    klass.start = function(self, ...)
        if old_start then old_start(self, ...) end

        local recipe = self.craftRecipe
        if not recipe then return end

        local okName, name = pcall(function() return recipe.getName and recipe:getName() end)
        if not okName or not name then return end

        if name == "UnpackCigarettes" or name == "TakeACigarette" then
            self:setActionAnim("OpenAmmoBox")
            self:setOverrideHandModels(nil, "CigarettePack_Closed")
        elseif name == "PackCigarettes" or name == "AddACigarette" then
            self:setActionAnim("PlaceAmmoInBox")
            self:setOverrideHandModels(nil, "CigarettePack_Closed")
        end
    end

    klass.__UIWWPatched = true
end

local function patchCraftAction()
    pcall(require, "TimedActions/ISCraftAction")
    local klass = _G and _G.ISCraftAction
    if type(klass) ~= "table" or type(klass.new) ~= "function" then return end
    if klass.__UIWWPatched then return end

    local old_new = klass.new
    klass.new = function(self, character, item, recipe, container, containersIn, ...)
        local o = old_new(self, character, item, recipe, container, containersIn, ...)
        if type(o) == "table" then
            o.stopOnWalk = false
            o.stopOnRun  = true
            o.__UIWWRip  = true
        end
        return o
    end

    local old_start = klass.start
    klass.start = function(self, ...)
        if old_start then old_start(self, ...) end

        local recipe = self.recipe
        if not recipe then return end

        local name = nil
        if recipe.getOriginalname then
            local ok, val = pcall(function() return recipe:getOriginalname() end)
            if ok then name = val end
        end
        if not name and recipe.getName then
            local ok, val = pcall(function() return recipe:getName() end)
            if ok then name = val end
        end
        if not name then return end

        if name == "UnpackCigarettes" or name == "TakeACigarette" then
            self:setActionAnim("OpenAmmoBox")
            self:setOverrideHandModels(nil, "CigarettePack_Closed")
        elseif name == "PackCigarettes" or name == "AddACigarette" then
            self:setActionAnim("PlaceAmmoInBox")
            self:setOverrideHandModels(nil, "CigarettePack_Closed")
        end
    end

    klass.__UIWWPatched = true
end

local function hookOnPlayerUpdate()
    pcall(require, "TimedActions/ISTimedActionQueue")
    if not Events or not Events.OnPlayerUpdate then return end
    if UIWW._onUpdateHooked then return end
    UIWW._onUpdateHooked = true

    Events.OnPlayerUpdate.Add(function(player)
        if not player or player:isDead() then return end

        local okQ, queue = pcall(function() return ISTimedActionQueue.getTimedActionQueue(player) end)
        if not okQ or not queue or not queue.queue then return end
        local a = queue.queue[1]
        if not a then return end

        local isSprint = false
        local okS, spr = pcall(function() return player.isSprinting and player:isSprinting() end)
        if okS and spr then isSprint = true end

        if isSprint and (a.__UIWWWear or a.__UIWWUnequip or a.__UIWWHandcraft or a.__UIWWRip or a.__UIWWAmmoBox or a.__UIWWRead or a.__UIWWCigarette) then
            pcall(function() a:stop() end)
            return
        end
    end)
end

function UIWW.TryPatch()
    patchWearClothing()
    patchUnequip()
    patchHandcraft()
    patchCraftAction()
    patchAmmoBoxUse()
    patchReadBook()
    Events.OnFillInventoryObjectContextMenu.Add(function(playerIndex, context, items)
        if not items or not context then return end
        local actualItems = {}
        if ISInventoryPane and ISInventoryPane.getActualItems then
            local ok, res = pcall(function() return ISInventoryPane.getActualItems(items) end)
            if ok and type(res) == "table" then actualItems = res end
        end
        if #actualItems == 0 then
            for _, entry in ipairs(items) do
                if instanceof(entry, "InventoryItem") then
                    table.insert(actualItems, entry)
                elseif entry.items and #entry.items > 0 then
                    for _, it in ipairs(entry.items) do
                        if instanceof(it, "InventoryItem") then
                            table.insert(actualItems, it)
                        end
                    end
                end
            end
        end
        local hasPack = false
        for _, it in ipairs(actualItems) do
            if it.getFullType and it:getFullType() == "Base.CigarettePack" then
                hasPack = true
                break
            end
        end
        if not hasPack then return end
        local opts = context.options
        if opts then
            for i = #opts, 1, -1 do
                local opt = opts[i]
                if opt and (opt.name == getText("ContextMenu_Smoke") or opt.name == "Smoke") then
                    table.remove(opts, i)
                end
            end
        end
    end)
    hookOnPlayerUpdate()
end

Events.OnGameBoot.Add(function()
    UIWW.TryPatch()
end)

Events.OnGameStart.Add(function()
    UIWW.TryPatch()
end)

return UIWW
