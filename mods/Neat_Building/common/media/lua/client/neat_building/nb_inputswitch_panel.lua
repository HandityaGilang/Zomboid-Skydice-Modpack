-- NB_InputSwitch_Panel.lua
-- A Neat-Crafting-style ingredient picker for Neat Building.
-- Groups possible inputs by ScriptItem, shows status, and allows selecting real InventoryItems
-- via BaseCraftingLogic:offerInputItem/removeInputItem (vanilla behavior).

require "ISUI/ISPanel"
require "neatui_framework/scrollview/niscrollview"

local NB_InputSwitch_Box = require "neat_building/nb_inputswitch_box"
local NB_InputSwitch_Expanded = require "neat_building/nb_inputswitch_expanded"

NB_InputSwitch_Panel = ISPanel:derive("NB_InputSwitch_Panel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- Small helper to safely call optional methods
local function safeCall(obj, fnName, ...)
    -- Safe wrapper around optional methods (no vararg leakage into closures)
    if not obj or not obj[fnName] then return nil, false end
    local ok, res = pcall(obj[fnName], obj, ...)
    return res, ok
end

-- ----------------------------------------------------------------------------------------------------- --
-- MP sync (client -> server): send the chosen alternative items so the server consumes the same ones.
-- Notes:
-- - In coop-hosted MP, the server may otherwise pick the first available alternative (e.g., Rag over RagDirty).
-- - Avoid ':' in log text because print() may truncate messages containing ':'.
-- ----------------------------------------------------------------------------------------------------- --
local NB_DEBUG = false

local function dprint(...)
    if NB_DEBUG then
        print(...)
    end
end

local function _makeRecipeKey(recipe)
    -- Prefer modID when available because modName can differ between client/server or be localized.
    local name = safeCall(recipe, "getName") or ""
    local modID = safeCall(recipe, "getModID") or ""
    local modName = safeCall(recipe, "getModName") or ""
    local modPart = (modID and modID ~= "" and modID) or (modName or "")
    return tostring(name) .. "|" .. tostring(modPart)
end

local function _getInputIndex(recipe, inputScript)
    if not recipe or not inputScript then return nil end
    local inputs = safeCall(recipe, "getInputs")
    if not inputs then return nil end
    for i = 0, inputs:size() - 1 do
        if inputs:get(i) == inputScript then
            return i
        end
    end
    return nil
end

local function _sendSelectionToServer(panel)
    -- Only relevant in multiplayer client context.
    if not isClient() then return end
    if not sendClientCommand then return end

    local logic = panel and panel.logic
    local inputScript = panel and panel.inputScript
    if not logic or not inputScript then return end

    local recipeData = safeCall(logic, "getRecipeData")
    local recipe = recipeData and safeCall(recipeData, "getRecipe") or nil
    if not recipe then return end

    local inputIndex = _getInputIndex(recipe, inputScript)
    if inputIndex == nil then return end

    local selected = safeCall(logic, "getSatisfiedInputInventoryItems", inputScript)
    local ids = {}
    local fullType = nil

    if selected then
        for j = 0, selected:size() - 1 do
            local it = selected:get(j)
            if it and it.getID then
                table.insert(ids, it:getID())
            end
            if (not fullType) and it and it.getFullType then
                fullType = it:getFullType()
            end
        end
    end

    
    -- Determine how many "units" this input needs (items for item-count inputs, uses for drainables).
    local need = 1
    if fullType and fullType ~= "" then
        need = safeCall(inputScript, "getIntAmount", fullType) or safeCall(inputScript, "getIntAmount") or 1
        need = math.ceil(tonumber(need) or 1)
    end

    local isItemCount = true
    local ic = safeCall(inputScript, "isItemCount")
    if ic ~= nil then
        isItemCount = ic
    end

    -- IMPORTANT: In MP, the server-side BuildLogic manual-selection typically expects ONE entry per required unit.
    -- For drainables (uses-based), a single selected item may represent multiple required uses.
    -- If the player selected one drainable item with enough uses, duplicate its ID so the server can consume multiple uses.
    if (not isItemCount) and need > #ids and #ids > 0 and selected and selected.size then
        local first = selected:get(0)
        local availUses = (first and first.getCurrentUses and first:getCurrentUses()) or 0
        local maxCopies = math.min(need, math.max(1, math.floor(tonumber(availUses) or 0)))
        while #ids < maxCopies do
            table.insert(ids, ids[1])
        end
    end

local args = {
        recipeKey = _makeRecipeKey(recipe),
        inputIndex = inputIndex,
        fullType = fullType or "",
        itemIDs = ids,
        need = need,
        isItemCount = isItemCount,

    }

    local playerObj = getPlayer() or getSpecificPlayer(0)
    if playerObj then
        sendClientCommand(playerObj, "XP_NB", "SetBuildInputSelection", args)
        dprint("[XP_NB] [MP Sync] sent selection")
    end
end



function NB_InputSwitch_Panel:new(x, y, width, height, player, logic)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    -- Context
    o.player = player
    o.logic = logic
    o.inputScript = nil
    o.ownerSlot = nil

    -- Data
    o.InputscriptItems = {}
    o.expandedStates = {}
    o.itemStates = {}
    o.savedScrollY = 0

    -- Layout (NC-style, scale-safe)
    o.boxPadding = math.max(2, math.floor(FONT_HGT_SMALL * 0.2))
    o.panelPadding = o.boxPadding * 2
    -- Reserve space for the scrollbar and a small right gap (NC-style)
    o.scrollbarW = math.max(1, math.floor(FONT_HGT_SMALL * 0.6))
    o.rightGap = math.max(1, math.floor(FONT_HGT_SMALL * 0.2))
    -- Child row width inside the scroll view (prevents scrollbar overlap)
    o.BoxWidth = math.max(40, math.floor(width - o.boxPadding * 2 - o.scrollbarW - o.rightGap))
    o.BoxHeight = math.max(48, math.floor(FONT_HGT_SMALL * 2.5))
    o.BoxSpacing = math.max(2, math.floor(FONT_HGT_SMALL * 0.3))
    o.BoxIndent = 0
    o.maxH = 420-- Textures (Neat Building theme)
    o.bgIconSide = getTexture("media/ui/Neat_Building/Button/SlotBG_IconSide.png")
    o.bgLeft = getTexture("media/ui/Neat_Building/Button/SlotBG_LEFT.png")
    o.border = getTexture("media/ui/Neat_Building/Button/SlotBoarder.png")

    o:setAnchorLeft(true)
    o:setAnchorTop(true)
    o:setAnchorRight(false)
    o:setAnchorBottom(false)

    return o
end

function NB_InputSwitch_Panel:initialise()
    ISPanel.initialise(self)
end


-- ----------------------------------------------------------------------------------------------------- --
-- Layout (NC-style): keep scrollview + child widths consistent and leave room for the scrollbar.
-- ----------------------------------------------------------------------------------------------------- --
function NB_InputSwitch_Panel:calculateLayout(_preferredWidth, _preferredHeight)
    local width = _preferredWidth or self.width
    local height = _preferredHeight or self.height

    -- Compute the effective row width so the scrollbar never overlays the rows.
    self.BoxWidth = math.max(40, math.floor(width - self.boxPadding * 2 - self.scrollbarW - self.rightGap))

    if self.contentScrollView then
        local contentHeight = height - self.panelPadding * 2
        -- IMPORTANT: match NC behavior: no right padding so the scrollbar can live "on top" of empty space.
        local contentWidth = width - self.panelPadding

        self.contentScrollView:setX(self.panelPadding)
        self.contentScrollView:setY(self.panelPadding)
        self.contentScrollView:setWidth(contentWidth)
        self.contentScrollView:setHeight(contentHeight)
        self.contentScrollView:setScrollSensitivity(self.BoxHeight + self.BoxSpacing)
    end

    self:setWidth(width)
    self:setHeight(height)
end

function NB_InputSwitch_Panel:onResize()
    -- Recalculate sizes when the user drags the resize handle or resolution changes.
    if ISPanel.onResize then ISPanel.onResize(self) end
    self:calculateLayout(self.width, self.height)
    self:populate()
end

function NB_InputSwitch_Panel:createChildren()
    -- Create a scroll view that will hold all the group boxes and expanded item lists.
    local contentHeight = self.height - self.panelPadding * 2
    local contentWidth = self.width - self.panelPadding

    self.contentScrollView = NIScrollView:new(
        self.panelPadding,
        self.panelPadding,
        contentWidth,
        contentHeight
    )
    self.contentScrollView:initialise()
    self.contentScrollView:setScrollDirection("vertical")
    self.contentScrollView:setScrollSensitivity(self.BoxHeight + self.BoxSpacing)
    self:addChild(self.contentScrollView)


    -- Ensure BoxWidth/content sizes are consistent with NC-style layout.
    self:calculateLayout(self.width, self.height)
    -- If context already exists, build UI once.
    if self.inputScript then
        self:loadInputscriptItems()
    end
end

-- Public API used by the patch: refresh content for the given InputScript.
function NB_InputSwitch_Panel:setContext(inputScript, ownerSlot)
    self.inputScript = inputScript
    self.ownerSlot = ownerSlot

    if not self.logic or not self.inputScript then
        self:setVisible(false)
        return
    end

    -- Enable "manual select inputs" mode like vanilla does for the inventory panel.
    safeCall(self.logic, "setManualSelectInputs", true)
    safeCall(self.logic, "setManualSelectInputScriptFilter", self.inputScript)
    safeCall(self.logic, "setShowManualSelectInputs", true)

    self:loadInputscriptItems()
end

-- ----------------------------------------------------------------------------------------------------- --
-- Load InputScript -> build group list (available first, then possible).
-- ----------------------------------------------------------------------------------------------------- --
function NB_InputSwitch_Panel:loadInputscriptItems()
    self.InputscriptItems = {}
    self.savedScrollY = 0

    if self.contentScrollView then
        self.savedScrollY = self.contentScrollView:getYScroll()
    end

    if not self.logic or not self.inputScript then
        return
    end

    local existingItemTypes = {}

    -- 1) Add groups that have items in inventory (via nodes).
    local inputItemNodes, okNodes = safeCall(self.logic, "getInputItemNodesForInput", self.inputScript)
    if okNodes and inputItemNodes then
        for i = 0, inputItemNodes:size() - 1 do
            local node = inputItemNodes:get(i)
            local scriptItem = node and node:getScriptItem() or nil
            local nodeItems = node and node:getItems() or nil

            if scriptItem and nodeItems then
                local AvailableItems = {}
                for j = 0, nodeItems:size() - 1 do
                    table.insert(AvailableItems, nodeItems:get(j))
                end

                local InputInfo = {
                    scriptItem = scriptItem,
                    AvailableItems = AvailableItems,
                    Count = nodeItems:size(),
                    inInventory = true
                }

                table.insert(self.InputscriptItems, InputInfo)
                existingItemTypes[scriptItem:getFullName()] = true
            end
        end
    end

    -- 2) Add possible script items that are not currently in inventory (grey groups).
    local possibleItems = self.inputScript:getPossibleInputItems()
    if possibleItems and possibleItems:size() > 0 then
        for i = 0, possibleItems:size() - 1 do
            local scriptItem = possibleItems:get(i)
            if scriptItem then
                local itemType = scriptItem:getFullName()
                if not existingItemTypes[itemType] then
                    local InputInfo = {
                        scriptItem = scriptItem,
                        inInventory = false
                    }
                    table.insert(self.InputscriptItems, InputInfo)
                    existingItemTypes[itemType] = true
                end
            end
        end
    end

    self:calculateItemStates()
    self:populate()
    _sendSelectionToServer(self)
end

-- ----------------------------------------------------------------------------------------------------- --
-- States (status line + expanded row states)
-- ----------------------------------------------------------------------------------------------------- --
function NB_InputSwitch_Panel:calculateItemStates()
    self.itemStates = {}

    if not self.logic then return end

    -- Prefer logic filter (vanilla), fallback to our context.
    local currentInputScript = nil
    local filtered, okFilter = safeCall(self.logic, "getManualSelectInputScriptFilter")
    if okFilter and filtered then
        currentInputScript = filtered
    else
        currentInputScript = self.inputScript
    end
    if not currentInputScript then return end

    -- Fetch recipe data for "used by other input" detection.
    local recipeData, okRD = safeCall(self.logic, "getRecipeData")
    local inputFilterData = nil
    if okRD and recipeData then
        local d, okD = safeCall(recipeData, "getDataForInputScript", currentInputScript)
        if okD then inputFilterData = d end
    end

    local satisfiedItems, okSat = safeCall(self.logic, "getSatisfiedInputInventoryItems", currentInputScript)
    if not (okSat and satisfiedItems) then
        satisfiedItems = nil
    end

    local TXT_AVAILABLE = getText("UI_NB_InputStatusAvailable")
    local TXT_USED = getText("UI_NB_InputStatusUsedByOther")
    local TXT_SELECTED = getText("UI_NB_InputStatusSelected")
    local TXT_POSSIBLE = getText("UI_NB_InputStatusPossible")

    for i, InputInfo in ipairs(self.InputscriptItems) do
        local itemState = {
            hasSelectedItems = false,
            statusText = TXT_POSSIBLE,
            expandedItemStates = {}
        }

        if InputInfo.inInventory and InputInfo.AvailableItems then
            -- Determine status for this group.
            local hasSelectedByCurrentInput = false
            local hasSelectedByOtherInput = false

            for _, invItem in ipairs(InputInfo.AvailableItems) do
                -- Detect assignment via recipeData when available.
                if recipeData and inputFilterData then
                    local usedAny, okAny = safeCall(recipeData, "containsInputItem", invItem)
                    if okAny and usedAny then
                        local usedThis, okThis = safeCall(recipeData, "containsInputItem", inputFilterData, invItem)
                        if okThis and usedThis then
                            hasSelectedByCurrentInput = true
                        else
                            hasSelectedByOtherInput = true
                        end
                    end
                else
                    -- Fallback: only detect "selected by current input" using satisfied list.
                    if satisfiedItems then
                        for j = 0, satisfiedItems:size() - 1 do
                            if satisfiedItems:get(j) == invItem then
                                hasSelectedByCurrentInput = true
                                break
                            end
                        end
                    end
                end

                -- Compute expanded row status.
                local st = "normal"
                if recipeData and inputFilterData then
                    local usedAny, okAny = safeCall(recipeData, "containsInputItem", invItem)
                    if okAny and usedAny then
                        local usedThis, okThis = safeCall(recipeData, "containsInputItem", inputFilterData, invItem)
                        st = (okThis and usedThis) and "selected" or "usedByOther"
                    end
                else
                    if satisfiedItems then
                        for j = 0, satisfiedItems:size() - 1 do
                            if satisfiedItems:get(j) == invItem then
                                st = "selected"
                                break
                            end
                        end
                    end
                end

                itemState.expandedItemStates[invItem] = st
            end

            if hasSelectedByCurrentInput then
                itemState.statusText = TXT_SELECTED
            elseif hasSelectedByOtherInput then
                itemState.statusText = TXT_USED
            else
                itemState.statusText = TXT_AVAILABLE
            end
        end

        self.itemStates[i] = itemState
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Expand/collapse groups
-- ----------------------------------------------------------------------------------------------------- --
function NB_InputSwitch_Panel:toggleItemExpanded(itemIndex)
    -- Preserve scroll position (NC behavior) so expand/collapse doesn't jump.
    if self.contentScrollView then
        self.savedScrollY = self.contentScrollView:getYScroll()
    end

    local wasExpanded = self.expandedStates[itemIndex] == true
    self.expandedStates[itemIndex] = not wasExpanded
    self:populate()
end

-- ----------------------------------------------------------------------------------------------------- --
-- Selection (toggle InventoryItem assignment)
-- ----------------------------------------------------------------------------------------------------- --
function NB_InputSwitch_Panel:onItemSelected(selectedItem)
    -- Preserve scroll position so the list doesn't jump.
    if self.contentScrollView then
        self.savedScrollY = self.contentScrollView:getYScroll()
    end

    if not self.logic or not self.inputScript or not selectedItem then
        return
    end

    -- Ensure logic is in manual-select mode for this input.
    safeCall(self.logic, "setManualSelectInputs", true)
    safeCall(self.logic, "setManualSelectInputScriptFilter", self.inputScript)
    safeCall(self.logic, "setShowManualSelectInputs", true)

    local recipeData, okRD = safeCall(self.logic, "getRecipeData")
    local inputFilterData = nil
    if okRD and recipeData then
        local d, okD = safeCall(recipeData, "getDataForInputScript", self.inputScript)
        if okD then inputFilterData = d end
    end

    if recipeData and inputFilterData then
        local usedAny, okAny = safeCall(recipeData, "containsInputItem", selectedItem)
        if okAny and usedAny then
            local usedThis, okThis = safeCall(recipeData, "containsInputItem", inputFilterData, selectedItem)
            if okThis and usedThis then
                -- Selected by this input -> remove.
                safeCall(self.logic, "removeInputItem", selectedItem)
            else
                -- Used by other input -> steal it.
                safeCall(self.logic, "removeInputItem", selectedItem)
                safeCall(self.logic, "offerInputItem", selectedItem)
            end
        else
            -- Not used -> offer.
            safeCall(self.logic, "offerInputItem", selectedItem)
        end
    else
        -- Fallback: toggle based on satisfied list only.
        local satisfiedItems, okSat = safeCall(self.logic, "getSatisfiedInputInventoryItems", self.inputScript)
        local isSelected = false
        if okSat and satisfiedItems then
            for j = 0, satisfiedItems:size() - 1 do
                if satisfiedItems:get(j) == selectedItem then
                    isSelected = true
                    break
                end
            end
        end

        if isSelected then
            safeCall(self.logic, "removeInputItem", selectedItem)
        else
            safeCall(self.logic, "offerInputItem", selectedItem)
        end
    end

    -- Refresh the owning slot so BuildingInfoPanel reflects the new selection.
    if self.ownerSlot and self.ownerSlot.updateInputInfo then
        pcall(function() self.ownerSlot:updateInputInfo() end)
    end

    self:calculateItemStates()
    self:populate()
    -- Send the updated selection to the MP server so it can consume the same alternative items.
    _sendSelectionToServer(self)

end

-- ----------------------------------------------------------------------------------------------------- --
-- Scroll children management
-- ----------------------------------------------------------------------------------------------------- --
function NB_InputSwitch_Panel:clearAllScrollChildren()
    if not self.contentScrollView then return end
    for i = #self.contentScrollView.scrollChildren, 1, -1 do
        local child = self.contentScrollView.scrollChildren[i]
        self.contentScrollView:removeScrollChild(child)
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Build/rebuild visible list
-- ----------------------------------------------------------------------------------------------------- --
function NB_InputSwitch_Panel:populate()
    if not self.contentScrollView then return end

    self:clearAllScrollChildren()

    local currentY = 0
    local totalH = 0

    for i, InputInfo in ipairs(self.InputscriptItems) do
        local box = NB_InputSwitch_Box:new(
            0,
            currentY,
            self.BoxWidth,
            self.BoxHeight,
            self.player,
            InputInfo,
            self,
            i
        )
        box:initialise()
        box.padding = self.boxPadding
        self.contentScrollView:addScrollChild(box)

        currentY = currentY + self.BoxHeight + self.BoxSpacing
        totalH = currentY

        -- Expanded list (only if inventory exists for this group).
        if self.expandedStates[i] and InputInfo.inInventory and InputInfo.AvailableItems and #InputInfo.AvailableItems > 0 then
            local exp = NB_InputSwitch_Expanded:new(
                0,
                currentY,
                self.BoxWidth,
                InputInfo.AvailableItems,
                self,
                i
            )
            exp:initialise()
            self.contentScrollView:addScrollChild(exp)

            currentY = currentY + exp:getHeight() + self.BoxSpacing
            totalH = currentY
        end
    end

    -- Update scroll view size + panel height so patch clamping uses correct height.
    self.contentScrollView:setScrollHeight(totalH)

    -- Clamp scroll so it stays within valid range after content height changes.
    local maxScroll = math.max(0, totalH - self.contentScrollView:getHeight())
    local newScroll = math.max(0, math.min(self.savedScrollY or 0, maxScroll))
    self.contentScrollView:setYScroll(newScroll)

    local wantedH = totalH + self.panelPadding * 2
    local finalH = math.min(self.maxH, math.max(120, wantedH))
    self:setHeight(finalH)

    -- Keep scrollview height synced with panel height (and re-clamp scroll).
    self.contentScrollView:setHeight(self.height - self.panelPadding * 2)
    local maxScroll2 = math.max(0, totalH - self.contentScrollView:getHeight())
    self.contentScrollView:setYScroll(math.max(0, math.min(self.contentScrollView:getYScroll(), maxScroll2)))
end

return NB_InputSwitch_Panel
