-- NB_InputPickerPanel.lua
-- Shows alternative item types for a Build InputScript and lets the user pick a preferred type.

require "ISUI/ISPanel"

NB_InputPickerPanel = ISPanel:derive("NB_InputPickerPanel")

-- Global weak-key store for per-BuildLogic selections.
-- BuildLogic is a Java userdata, so attaching new fields to it is not reliable.
NB_INPUT_SELECTIONS = NB_INPUT_SELECTIONS or setmetatable({}, { __mode = "k" })

function NB_getInputSelectionMap(logic)
    -- Return the selection map for this BuildLogic instance (or nil).
    if not logic then return nil end
    return NB_INPUT_SELECTIONS[logic]
end

function NB_ensureInputSelectionMap(logic)
    -- Create (if needed) and return the selection map for this BuildLogic instance.
    if not logic then return nil end
    local map = NB_INPUT_SELECTIONS[logic]
    if not map then
        map = {}
        NB_INPUT_SELECTIONS[logic] = map
    end
    return map
end

function NB_clearInputSelectionMap(logic)
    -- Clear all selections for this BuildLogic instance.
    if not logic then return end
    NB_INPUT_SELECTIONS[logic] = nil
end

local function NB_safeCall(obj, methodName)
    -- Call a method if it exists, return nil otherwise
    if not obj then return nil end
    local fn = obj[methodName]
    if not fn then return nil end
    local ok, result = pcall(fn, obj)
    if ok then return result end
    return nil
end

local function NB_getInputKey(inputScript)
    -- Prefer stable keys if the API exists; fallback to tostring(userdata)
    local name = NB_safeCall(inputScript, "getName")
    if name then return "name:" .. tostring(name) end
    local id = NB_safeCall(inputScript, "getID")
    if id then return "id:" .. tostring(id) end
    return "ud:" .. tostring(inputScript)
end

function NB_InputPickerPanel:initialise()
    ISPanel.initialise(self)
end

function NB_InputPickerPanel:new(x, y, w, h, player, logic)
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self

    o.player = player
    o.logic = logic

    -- Current context
    o.inputScript = nil
    o.inputKey = nil
    o.ownerSlot = nil

    -- UI data
    o.rows = {} -- { fullType, displayName, texture, availableBool }
    o.padding = 6
    o.rowH = 26
    o.iconSize = 22
    o.maxH = 260

    o.background = true
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.85 }
    o.borderColor = { r = 1, g = 1, b = 1, a = 0.25 }

    return o
end

function NB_InputPickerPanel:_ensureSelectionTable()
    -- Store selections in the global weak-key map (not inside the Java userdata).
    return NB_ensureInputSelectionMap(self.logic)
end

function NB_InputPickerPanel:_getSelectedFullType()
    local t = self:_ensureSelectionTable()
    if not t or not self.inputKey then return nil end
    return t[self.inputKey]
end

function NB_InputPickerPanel:_setSelectedFullType(fullType)
    local t = self:_ensureSelectionTable()
    if not t or not self.inputKey then return end
    t[self.inputKey] = fullType
end

function NB_InputPickerPanel:setContext(inputScript, ownerSlot)
    self.inputScript = inputScript
    self.ownerSlot = ownerSlot
    self.inputKey = inputScript and NB_getInputKey(inputScript) or nil
    self.rows = {}

    if not self.inputScript then
        self:setVisible(false)
        return
    end    -- Build availability map from viable inventory items (NOT from already-satisfied items).
    -- This makes the picker highlight items the player actually has, even if auto-selection picked another type.
    local required = 1
    local isItemCount = true

    -- Determine how much this InputScript requires.
    -- For item-count inputs this is "number of items"; for drainable-like inputs it is "uses".
    if self.inputScript then
        if self.inputScript.isItemCount then
            isItemCount = self.inputScript:isItemCount()
        end
        if self.inputScript.getIntAmount then
            required = self.inputScript:getIntAmount()
        elseif self.inputScript.getAmount then
            -- getAmount() is float in Java; ceil is safer for display/validation.
            required = math.ceil(self.inputScript:getAmount() - 1e-6)
        end
    end
    if required < 1 then required = 1 end

    -- Count how many items/uses of each FullType are viable for this recipe.
    local stock = {}
    if self.logic and self.logic.getAllViableInputInventoryItems then
        local ok, all = pcall(function() return self.logic:getAllViableInputInventoryItems() end)
        if ok and all and all.size then
            for i = 0, all:size() - 1 do
                local invIt = all:get(i)
                if invIt and invIt.getFullType then
                    local ft = invIt:getFullType()
                    local add = 1

                    -- For drainables, use current uses so "available" matches crafting logic semantics.
                    if (not isItemCount) and invIt.getCurrentUses then
                        add = invIt:getCurrentUses()
                    end

                    stock[ft] = (stock[ft] or 0) + (add or 0)
                end
            end
        end
    end

    -- Decide if we have enough stock for a given fullType to satisfy this input.
    local function hasEnough(fullType)
        return (stock[fullType] or 0) >= required
    end



    -- Build list from possible script items
    local possible = self.inputScript:getPossibleInputItems()
    if possible and possible.size and possible:size() > 0 then
        for i = 0, possible:size() - 1 do
            local scriptItem = possible:get(i)
            if scriptItem then
                local fullName = scriptItem:getFullName()
                local displayName = scriptItem:getDisplayName()
                local tex = scriptItem:getNormalTexture()
                table.insert(self.rows, {
                    fullType = fullName,
                    displayName = displayName or fullName,
                    texture = tex,
                    available = hasEnough(fullName),
                })
            end
        end
    end

    -- Resize height to fit rows
    -- NOTE: rows are rendered starting at (padding + titleH), so titleH MUST be included
    -- in the panel height, otherwise the last row gets clipped and becomes unclickable.
    local fontH = getTextManager():getFontHeight(UIFont.Small)
    self.titleH = self.titleH or (fontH + 8) -- Same rule used in prerender()

    local wantedH = (self.padding * 2) + self.titleH + (#self.rows * self.rowH)

    -- Ensure a minimum height so the panel is visible even if the list is empty
    self:setHeight(math.max(60, math.min(wantedH, self.maxH)))

end

function NB_InputPickerPanel:onMouseDown(x, y)
    -- Select the clicked row
    local top = self.padding + (self.titleH or 0)
    for idx, row in ipairs(self.rows) do
        local ry = top + (idx - 1) * self.rowH
        if y >= ry and y <= (ry + self.rowH) then
            self:_setSelectedFullType(row.fullType)

            -- Apply manual selection to the underlying crafting logic (must use InventoryItem objects).
            self:_applySelectionToLogic(row.fullType)

            -- Ask the slot to refresh its displayed info (icon/name)
            if self.ownerSlot and self.ownerSlot.updateInputInfo then
                self.ownerSlot:updateInputInfo()
            end

			-- Keep the picker open after choosing so NB doesn't collapse the requirements panel
			-- and the player can confirm the selection visually.
			self:bringToTop()
			return true
        end
    end
    return true
end


function NB_InputPickerPanel:_applySelectionToLogic(fullType)
    -- Apply the chosen fullType to the underlying crafting logic (manual select),
    -- using InventoryItem instances (NOT script Items).
    if not fullType then return end
    local logic = self.logic
    if not logic or not self.inputScript then return end

    -- Enable manual-select mode for this specific InputScript.
    if logic.setManualSelectInputScriptFilter then
        pcall(function() logic:setManualSelectInputScriptFilter(self.inputScript) end)
    end
    if logic.setManualSelectInputs then
        pcall(function() logic:setManualSelectInputs(true) end)
    end

    -- Remove currently applied InventoryItems for this input (so the new choice actually replaces them).
    if logic.getSatisfiedInputInventoryItems and logic.removeInputItem then
        local ok, cur = pcall(function() return logic:getSatisfiedInputInventoryItems(self.inputScript) end)
        if ok and cur then
            for i = 0, cur:size() - 1 do
                local invIt = cur:get(i)
                if invIt then
                    pcall(function() logic:removeInputItem(invIt) end)
                end
            end
        end
    end

    -- Find viable inventory items matching the chosen fullType.
    local candidates = {}
    if logic.getAllViableInputInventoryItems then
        local ok, all = pcall(function() return logic:getAllViableInputInventoryItems() end)
        if ok and all then
            for i = 0, all:size() - 1 do
                local invIt = all:get(i)
                if invIt and invIt.getFullType and invIt:getFullType() == fullType then
                    table.insert(candidates, invIt)
                end
            end
        end
    end

    if #candidates == 0 then
        -- Nothing to offer (player doesn't currently have that item).
        return
    end    -- Offer up to the required amount (items or uses) for this InputScript.
    -- DO NOT use logic:getInputCount() here: that returns what is currently applied, not what is required.
    local need = 1
    local isItemCount = true
    if self.inputScript then
        if self.inputScript.isItemCount then
            isItemCount = self.inputScript:isItemCount()
        end
        if self.inputScript.getIntAmount then
            need = self.inputScript:getIntAmount()
        elseif self.inputScript.getAmount then
            need = math.ceil(self.inputScript:getAmount() - 1e-6)
        end
    end
    if need < 1 then need = 1 end



    if logic.offerInputItem then
        local offeredItems = 0
        local offeredUses = 0

        for _, invIt in ipairs(candidates) do
            -- Vanilla pattern: remove then offer, so items assigned elsewhere can be moved.
            if logic.removeInputItem then
                pcall(function() logic:removeInputItem(invIt) end)
            end

            local ok, success = pcall(function() return logic:offerInputItem(invIt) end)
            if ok and success then
                if isItemCount then
                    offeredItems = offeredItems + 1
                    if offeredItems >= need then break end
                else
                    -- For drainables, count uses if possible.
                    local u = (invIt.getCurrentUses and invIt:getCurrentUses()) or 0
                    offeredUses = offeredUses + u
                    if offeredUses >= need then break end
                end
            end
        end
    end
end


local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

function NB_InputPickerPanel:prerender()
    -- Render a rounded NeatUI panel background using NinePatch textures.
    -- This mimics the look used by Neat Crafting panels.
    local bg = NinePatchTexture.getSharedTexture("media/ui/NeatUI/DefaultPanel/ContentPanel_BG.png")
    local title = NinePatchTexture.getSharedTexture("media/ui/NeatUI/DefaultPanel/InnerTitle_BG.png")

    if bg then
        bg:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.height, 0.10, 0.10, 0.10, 1)
    end

    -- Optional title bar (keeps it closer to NC style)
    self.titleH = self.titleH or (FONT_HGT_SMALL + 8)
    if title then
        title:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.titleH, 0.20, 0.20, 0.20, 1)
        -- Reuse an existing vanilla text key to avoid adding new translations
        local txt = getText("IGUI_CraftingWindow_Requires") or "Requires"
        self:drawText(txt, self.padding, math.floor((self.titleH - FONT_HGT_SMALL) / 2), 1, 1, 1, 0.9, UIFont.Small)
    end
end

function NB_InputPickerPanel:render()
    ISPanel.render(self)

    local selected = self:_getSelectedFullType()

    local x0 = self.padding
    local y0 = self.padding + (self.titleH or 0)

    for idx, row in ipairs(self.rows) do
        local ry = y0 + (idx - 1) * self.rowH

        -- Selected highlight
        if selected and selected == row.fullType then
            self:drawRect(x0 - 2, ry, self.width - (self.padding * 2) + 4, self.rowH, 0.20, 0.2, 0.8, 0.2)
        end
		
		-- Make available items brighter and unavailable items greyed-out (NC-like)
        local iconA = row.available and 1.0 or 0.35
        local textA = row.available and 0.95 or 0.45
        local textRGB = row.available and 1.0 or 0.70

        -- Availability hint (left bar)
        if row.available then
            self:drawRect(x0 - 4, ry + 2, 3, self.rowH - 4, 0.35, 0.2, 0.8, 0.2)
        else
            self:drawRect(x0 - 4, ry + 2, 3, self.rowH - 4, 0.20, 0.8, 0.2, 0.2)
        end

        -- Icon
        if row.texture then
            self:drawTextureScaledAspect(row.texture, x0, ry + 2, self.iconSize, self.iconSize, iconA, 1, 1, 1)
        end

        -- Text
        self:drawText(row.displayName, x0 + self.iconSize + 8, ry + 5, textRGB, textRGB, textRGB, textA, UIFont.Small)

        -- Separator
        self:drawRect(x0, ry + self.rowH - 1, self.width - (self.padding * 2), 1, 0.12, 1, 1, 1)
    end
end
