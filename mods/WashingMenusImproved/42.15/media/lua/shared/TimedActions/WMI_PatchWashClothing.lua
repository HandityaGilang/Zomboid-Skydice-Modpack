--[[---------------------------------------------------------------------------
    Washing Menus Improved - Patch for ISWashClothing (B42.13+)
    Purpose:
      - When washing bandages/strips that use ItemAfterCleaning (BandageDirty, RippedSheetsDirty, etc.)
        the item is replaced with a NEW item on completion.
      - WMI needs to put that NEW item back into the original equipped-bag container (MP-safe).

    How it works:
      - Extend ISWashClothing:new(...) with an optional 'wmiReturnContainer' argument.
        This argument becomes part of the NetTimedAction args so the server receives it.
      - After vanilla complete() runs, detect the newly created clean item by comparing IDs
        before/after, then move it to wmiReturnContainer (server-side) and sync to clients.

    Notes:
      - This file should live in: media/lua/shared/TimedActions/WMI_PatchWashClothing.lua
      - It does NOT overwrite vanilla files; it monkey-patches at runtime.
-----------------------------------------------------------------------------]]

require "TimedActions/ISWashClothing"

if ISWashClothing and not ISWashClothing._wmiPatchedReturnContainer then
    -- Keep vanilla constructors / methods
    local _wmiOrigNew = ISWashClothing.new
    local _wmiOrigIsValid = ISWashClothing.isValid
    local _wmiOrigComplete = ISWashClothing.complete
    local _wmiOrigGetRequiredWater = ISWashClothing.GetRequiredWater

    -- Compatibility helper: 42.15+ removed the explicit `soaps` constructor argument.
    -- We detect the major/minor build once and then route old/new call shapes accordingly.
    local function _wmiIsB4215Plus()
        if not getGameVersion then return false end
        local version = tostring(getGameVersion() or "")
        local major, minor = string.match(version, "^(%d+)%.(%d+)")
        major = tonumber(major) or 0
        minor = tonumber(minor) or 0
        return (major > 42) or (major == 42 and minor >= 15)
    end

    local function _wmiBuildLegacySoapList(character)
        local inv = character and character.getInventory and character:getInventory() or nil
        if not inv then return {} end

        -- Prefer the newer inventory helper when it exists.
        if inv.getSoapList then
            local ok, soaps = pcall(inv.getSoapList, inv, nil, true)
            if ok and soaps then return soaps end
        end

        -- Fallback for older builds that still expect a Lua table.
        local soaps = {}
        local barList = inv.getItemsFromType and inv:getItemsFromType("Soap2", true) or nil
        if barList and barList.size and barList.get then
            for i = 0, barList:size() - 1 do
                soaps[#soaps + 1] = barList:get(i)
            end
        end
        return soaps
    end

    if _wmiIsB4215Plus() then
        -- 42.15+: keep vanilla parameter names so NetTimedAction serializes the correct fields in MP.
        -- Signature becomes:
        --   new(character, sink, item, bloodAmount, dirtAmount, noSoap[, wmiReturnContainer])
        function ISWashClothing:new(character, sink, item, bloodAmount, dirtAmount, noSoap, wmiReturnContainer, wmiWaterOverride)
            local o = _wmiOrigNew(self, character, sink, item, bloodAmount, dirtAmount, noSoap)
            o.wmiReturnContainer = wmiReturnContainer
            -- Only numeric overrides are valid here. Older queue code may pass booleans in extra slots.
            o.wmiWaterOverride = tonumber(wmiWaterOverride)
            return o
        end
    else
        -- 42.13 / 42.14: preserve the legacy parameter names for MP serialization.
        -- Signature becomes:
        --   new(character, sink, soaps, item, bloodAmount, dirtAmount, noSoap[, wmiReturnContainer])
        function ISWashClothing:new(character, sink, soaps, item, bloodAmount, dirtAmount, noSoap, wmiReturnContainer, wmiWaterOverride)
            local o = _wmiOrigNew(self, character, sink, soaps, item, bloodAmount, dirtAmount, noSoap)
            o.wmiReturnContainer = wmiReturnContainer
            -- Only numeric overrides are valid here. Older queue code may pass booleans in extra slots.
            o.wmiWaterOverride = tonumber(wmiWaterOverride)
            return o
        end
    end


    function ISWashClothing:isValid()
        if not _wmiOrigIsValid then return true end
        local overrideWater = tonumber(self.wmiWaterOverride)
        if overrideWater then
            if self.sink:getFluidAmount() < overrideWater then
                return false
            end
            if not isClient() and self.item:getContainer() ~= self.character:getInventory() then
                return false
            end
            return true
        end
        return _wmiOrigIsValid(self)
    end

    function ISWashClothing:complete()
        -- Detect "transforming" washes (ItemAfterCleaning defined on the dirty item)
        local afterType = nil
        if self.item and self.item.getItemAfterCleaning then
            afterType = self.item:getItemAfterCleaning()
            if afterType == "" then afterType = nil end
        end

        local inv = self.character and self.character.getInventory and self.character:getInventory() or nil
        local dest = self.wmiReturnContainer

        local shouldReturn = (afterType ~= nil) and (inv ~= nil) and (dest ~= nil) and (dest ~= inv)

        -- Snapshot existing IDs of the 'afterType' items before vanilla completion creates the new item
        local beforeIds = nil
        if shouldReturn then
            beforeIds = {}
            local all = inv:getItems()
            for i = 0, all:size() - 1 do
                local it = all:get(i)
                if it and it.getFullType and it:getFullType() == afterType then
                    if it.getID then
                        beforeIds[it:getID()] = true
                    end
                end
            end
        end

        -- Run vanilla completion logic (removes dirty item, consumes water, creates clean item, etc.)
        local _restoreGetRequiredWater = nil
        local overrideWater = tonumber(self.wmiWaterOverride)
        if overrideWater then
            _restoreGetRequiredWater = ISWashClothing.GetRequiredWater
            ISWashClothing.GetRequiredWater = function(item)
                if item == self.item then
                    return overrideWater
                end
                return _wmiOrigGetRequiredWater(item)
            end
        end

        local ok = _wmiOrigComplete(self)

        if _restoreGetRequiredWater then
            ISWashClothing.GetRequiredWater = _restoreGetRequiredWater
        end

        if shouldReturn then
            -- Find the new item created by vanilla complete() (ID wasn't present before)
            local newItem = nil
            local all = inv:getItems()
            for i = 0, all:size() - 1 do
                local it = all:get(i)
                if it and it.getFullType and it:getFullType() == afterType then
                    local id = it.getID and it:getID() or nil
                    if id and not beforeIds[id] then
                        newItem = it
                        break
                    end
                end
            end

			if newItem then
				-- IMPORTANT (MP): Only the server should mutate containers.
				-- Client-side container edits can create "ghost" items that can't be moved/consumed.
				if not isClient() then
					-- Move the newly created clean item back to the original container
					inv:Remove(newItem)
					dest:AddItem(newItem)

					-- Server must sync container changes to clients (if these helpers exist in this build).
					if sendRemoveItemFromContainer then sendRemoveItemFromContainer(inv, newItem) end
					if sendAddItemToContainer then sendAddItemToContainer(dest, newItem) end
				end
			end
        end

        return ok
    end

    ISWashClothing._wmiPatchedReturnContainer = true
end
