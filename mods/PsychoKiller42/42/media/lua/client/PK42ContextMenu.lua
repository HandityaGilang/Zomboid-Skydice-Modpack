-- PK42ContextMenu.lua (Client)
local SU = require "Utils/PK42SharedUtils"

-- ============================================================
-- UNLOCK LEVELS
-- ============================================================
local function getUnlock()
    local opts    = SandboxVars.PK42
    local butcher = opts and opts.ButcherCorpseUnlockLevel or 3
    local skin    = opts and opts.SkinCorpseUnlockLevel    or 4
    local bones   = opts and opts.CollectBonesUnlockLevel  or 4
    return {
        BUTCHER      = butcher,
        SKIN         = skin,
        BONES        = bones,
        MENU_VISIBLE = math.min(butcher, skin, bones),
    }
end
-- ============================================================

local function getCorpsesFromSquare(sq)
    local result = {}
    local seen   = {}
    if not sq then return result end

    local function addBodies(col)
        if not col or col:size() == 0 then return end
        for i = 0, col:size() - 1 do
            local db = col:get(i)
            if instanceof(db, "IsoDeadBody") and not db:isAnimal() then
                local id = tostring(db)
                if not seen[id] then
                    seen[id] = true
                    table.insert(result, db)
                end
            end
        end
    end

    addBodies(sq:getDeadBodys())
    if #result == 0 then addBodies(sq:getStaticMovingObjects()) end
    return result
end

local function applyItemIcon(option, item)
    if not item then return end
    local scriptItem = item.getScriptItem and item:getScriptItem()
    if scriptItem and scriptItem.getNormalTexture then
        local tex = scriptItem:getNormalTexture()
        if tex then option.iconTexture = tex end
    end
end

local function applyScriptItemIcon(option, fullType)
    local scriptItem = ScriptManager.instance:FindItem(fullType)
    if not scriptItem then return end
    local tex = scriptItem:getNormalTexture()
    if scriptItem.getIconsForTexture and scriptItem:getIconsForTexture() and not scriptItem:getIconsForTexture():isEmpty() then
        tex = scriptItem:getIconsForTexture():get(0)
    end
    if tex then option.iconTexture = tex end
end

-- Tooltips
local function createButcheringTooltip(option, inv, corpse)
    local tooltip = ISInventoryPaneContextMenu.addToolTip()
    option.toolTip = tooltip

    local tool    = SU.findButcherTool(inv)
    local hasTool = tool ~= nil

    tooltip.description = getText("ContextMenu_PK42_RequiredItems") .. " <LINE>"
    tooltip.description = tooltip.description .. string.format(
        "   <%s> %s ( %d / 1 ) <RGB:1,1,1> <LINE>",
        hasTool and "GREEN" or "RED",
        hasTool and tool:getDisplayName() or getText("Tooltip_Animal_NoKnifeButcher"),
        hasTool and 1 or 0
    )
    option.notAvailable = not hasTool
end

local function createSkinTooltip(option, inv, corpse)
    local tooltip = ISInventoryPaneContextMenu.addToolTip()
    option.toolTip = tooltip

    local tool         = SU.findButcherTool(inv)
    local hasTool      = tool ~= nil
    local alreadySkinned = corpse:getModData()["PK42Skinned"] == true

    if alreadySkinned then
        tooltip.description = getText("ContextMenu_PK42_AlreadySkinned")
        option.notAvailable = true
        return
    end

    tooltip.description = getText("ContextMenu_PK42_RequiredItems") .. " <LINE>"
    tooltip.description = tooltip.description .. string.format(
        "   <%s> %s ( %d / 1 ) <RGB:1,1,1> <LINE>",
        hasTool and "GREEN" or "RED",
        hasTool and tool:getDisplayName() or getText("Tooltip_Animal_NoKnifeButcher"),
        hasTool and 1 or 0
    )
    option.notAvailable = not hasTool
end

local function createCollectBonesToolTip(option, inv, corpse)
    local tooltip = ISInventoryPaneContextMenu.addToolTip()
    option.toolTip = tooltip
    tooltip.description = getText("ContextMenu_PK42_CollectBonesDesc") or "Collect the bones from the remains."
    option.notAvailable = false
end

-- Handlers de clique
local function onButcherCorpse(player, corpse, sq)
    if not corpse or not sq then return end
    if not luautils.walkAdj(player, sq) then return end

    local inv  = player:getInventory()
    local tool = SU.findButcherTool(inv)
    if not tool then return end

    ISInventoryPaneContextMenu.transferIfNeeded(player, tool)
    ISInventoryPaneContextMenu.equipWeapon(tool, true, false, player:getPlayerNum())
    ISTimedActionQueue.add(PK42ButcheringAction:new(player, corpse, sq))
end

local function onSkinCorpse(player, corpse, sq)
    if not corpse or not sq then return end
    if corpse:getModData()["PK42Skinned"] then return end
    if not luautils.walkAdj(player, sq) then return end

    local inv  = player:getInventory()
    local tool = SU.findButcherTool(inv)
    if not tool then return end

    ISInventoryPaneContextMenu.transferIfNeeded(player, tool)
    ISInventoryPaneContextMenu.equipWeapon(tool, true, false, player:getPlayerNum())
    ISTimedActionQueue.add(PK42SkinAction:new(player, corpse, sq))
end

local function onCollectBones(player, corpse, sq)
    if not corpse or not sq then return end
    if not luautils.walkAdj(player, sq) then return end
    ISTimedActionQueue.add(PK42CollectBonesAction:new(player, corpse, sq))
end

-- Highlight helper
local function makeHighlightCallbacks(entry)
    local hc = getCore():getGoodHighlitedColor()
    return {
        onHighlightParams = { entry.corpse, hc },
        onHighlight = function(_opt, _menu, _isHL, _obj, _col)
            if not _obj then return end
            if _isHL then
                _obj:setHighlightColor(_menu.player, _col)
                _obj:setOutlineHighlightCol(_menu.player, _col)
            end
            _obj:setHighlighted(_menu.player, _isHL, false)
            _obj:setOutlineHighlight(_menu.player, _isHL)
            _obj:setOutlineHlAttached(_menu.player, _isHL)
        end
    }
end

-- Adiciona as opções ao contexto
local function addActionOptions(context, player, inv, entries, actionLabel, handler, tooltipFn, iconFullType, filterFn, parentIconFullType)
    local filtered = {}
    for _, e in ipairs(entries) do
        if not filterFn or filterFn(e) then
            table.insert(filtered, e)
        end
    end
    if #filtered == 0 then return end

    if #filtered == 1 then
        local entry = filtered[1]
        local opt = context:addOption(
            getText(actionLabel),
            player, handler,
            entry.corpse, entry.sq
        )
        if parentIconFullType then
            applyScriptItemIcon(opt, parentIconFullType)
        elseif iconFullType then
            applyScriptItemIcon(opt, iconFullType)
        else
            applyItemIcon(opt, SU.findButcherTool(inv))
        end
        tooltipFn(opt, inv, entry.corpse)
    else
        local parent = context:addOption(getText(actionLabel), {}, nil)
        if parentIconFullType then
            applyScriptItemIcon(parent, parentIconFullType)
        elseif iconFullType then
            applyScriptItemIcon(parent, iconFullType)
        else
            applyItemIcon(parent, SU.findButcherTool(inv))
        end

        local subMenu = ISContextMenu:getNew(context)
        context:addSubMenu(parent, subMenu)

        for idx, entry in ipairs(filtered) do
            local opt = subMenu:addOption(
                getText("IGUI_ContainerTitle_inventorymale", idx),
                player, handler,
                entry.corpse, entry.sq
            )
            applyScriptItemIcon(opt, iconFullType or "Base.CorpseMale")
            tooltipFn(opt, inv, entry.corpse)

            local hl = makeHighlightCallbacks(entry)
            opt.onHighlightParams = hl.onHighlightParams
            opt.onHighlight       = hl.onHighlight
        end
    end
end

-- Builder principal
local lastContextBuild = 0

local function buildPK42WorldCM(playerNum, context, worldobjects, test)
    if test and ISWorldObjectContextMenu.Test then return true end
 
    local player = getSpecificPlayer(playerNum)
    if not player then return end
 
    local insanity = player:getPerkLevel(Perks.Insanity)
    local UNLOCK   = getUnlock()

    -- Guard principal: menu só aparece no nível MENU_VISIBLE+
    if not SU.hasPsychopathTrait(player) or insanity < UNLOCK.MENU_VISIBLE then return end
 
    local now = getTimestampMs()
    if lastContextBuild == now then return end
    lastContextBuild = now
 
    local inv        = player:getInventory()
    local allEntries = {}
    local seen       = {}
 
    local function addEntry(dead, sq)
        local id = tostring(dead)
        if not seen[id] then
            seen[id] = true
            table.insert(allEntries, { corpse = dead, sq = sq })
        end
    end
 
    for _, v in ipairs(worldobjects) do
        if instanceof(v, "IsoDeadBody") and not v:isAnimal() then
            local ok, sq = pcall(function() return v:getSquare() end)
            if ok and sq then addEntry(v, sq) end
        end
    end
 
    if #allEntries == 0 then
        for _, v in ipairs(worldobjects) do
            if v and type(v.getSquare) == "function" then
                local ok, sq = pcall(function() return v:getSquare() end)
                if ok and sq then
                    for dy = -1, 1 do
                        for dx = -1, 1 do
                            local sq2 = getCell():getGridSquare(sq:getX()+dx, sq:getY()+dy, sq:getZ())
                            if sq2 then
                                for _, dead in ipairs(getCorpsesFromSquare(sq2)) do
                                    addEntry(dead, sq2)
                                end
                            end
                        end
                    end
                    break
                end
            end
        end
    end
 
    if #allEntries == 0 then return end
 
    -- Opção 1: Butcher
    if insanity >= UNLOCK.BUTCHER then
        addActionOptions(
            context, player, inv, allEntries,
            "ContextMenu_ButcherAnimal",
            onButcherCorpse,
            createButcheringTooltip,
            nil,
            function(e) return SU.isHumanCorpse(e.corpse) end
        )
    end
 
    -- Opção 2: Skin
    if insanity >= UNLOCK.SKIN then
        addActionOptions(
            context, player, inv, allEntries,
            "ContextMenu_PK42_SkinCorpse",
            onSkinCorpse,
            createSkinTooltip,
            nil,
            function(e) return SU.isHumanCorpse(e.corpse) end
        )
    end
 
    -- Opção 3: Collect Bones
    if insanity >= UNLOCK.BONES then
        addActionOptions(
            context, player, inv, allEntries,
            "ContextMenu_PK42_CollectBones",
            onCollectBones,
            createCollectBonesToolTip,
            "Base.CorpseMale",      -- filhos do submenu: cadáver
            function(e) return SU.isHumanSkeleton(e.corpse) end,
            "Base.SmallAnimalBone"  -- pai: ossinho
        )
    end
end
 
Events.OnFillWorldObjectContextMenu.Add(buildPK42WorldCM)