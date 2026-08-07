-- WMI_PatchWashClothing.lua (B42.12 legacy)
-- Purpose:
--   Patch ISWashClothing to support WMI's "Clean Bandages" workflow:
--     1) Optional per-action water override (sandbox-configured water per bandage/strip).
--     2) Returning transformed items (ItemAfterCleaning) back to the original equipped bag/container.
--
-- Why this patch is needed:
--   * Vanilla ISWashClothing uses ISWashClothing.GetRequiredWater(item) (minimum 4) for bandages/strips.
--   * When an item has ItemAfterCleaning, vanilla removes the dirty item and creates a NEW clean item in inventory.
--     WMI needs to move that NEW item back to the source bag so batch-cleaning works across equipped bags.
--
-- Compatibility:
--   * This patch is additive: vanilla calls to ISWashClothing:new(...) (7 args) still work unchanged.
--   * Only actions created by WMI pass the extra args, so other washing mechanics are unaffected.

require "TimedActions/ISWashClothing"

if ISWashClothing and not ISWashClothing._wmiPatched then
    ISWashClothing._wmiPatched = true

    -- Keep original references so other mods can still call vanilla behavior if needed.
    local _orig_new     = ISWashClothing.new
    local _orig_isValid = ISWashClothing.isValid
    local _orig_complete = ISWashClothing.complete
    local _orig_getRequiredWater = ISWashClothing.GetRequiredWater

    -- -----------------------------------------------------------------------
    -- Extend constructor: accept optional return container and water override.
    -- Signature becomes:
    --   ISWashClothing:new(character, sink, soaps, item, blood, dirt, noSoap, wmiReturnContainer, wmiWaterOverride)
    -- -----------------------------------------------------------------------
    function ISWashClothing:new(character, sink, soaps, item, bloodAmount, dirtAmount, noSoap, wmiReturnContainer, wmiWaterOverride)
        -- Create the vanilla action first.
        local o = _orig_new(self, character, sink, soaps, item, bloodAmount, dirtAmount, noSoap)

        -- Store WMI extras on the action instance.
        o.wmiReturnContainer = wmiReturnContainer
        o.wmiWaterOverride   = wmiWaterOverride

        -- If this item will transform, snapshot current inventory IDs so we can detect the new item later.
        o.wmiBeforeIds = nil
        o.wmiExpectedFullType = nil

        if item and item.getItemAfterCleaning and item:getItemAfterCleaning() then
            o.wmiExpectedFullType = item:getItemAfterCleaning()
            o.wmiBeforeIds = {}

            local inv = character and character.getInventory and character:getInventory() or nil
            if inv and inv.getItems then
                local all = inv:getItems()
                for i = 0, all:size() - 1 do
                    local it = all:get(i)
                    if it and it.getID then
                        o.wmiBeforeIds[it:getID()] = true
                    end
                end
            end
        end

        return o
    end

    -- -----------------------------------------------------------------------
    -- Patch validity: use per-action water override when present.
    -- -----------------------------------------------------------------------
    function ISWashClothing:isValid()
        -- Preserve vanilla inventory check.
        if self.item:getContainer() ~= self.character:getInventory() then
            return false
        end

        -- Respect per-action override if provided.
        local req = self.wmiWaterOverride or _orig_getRequiredWater(self.item)
        if self.sink:getFluidAmount() < req then
            return false
        end

        return true
    end

    -- -----------------------------------------------------------------------
    -- Patch completion:
    --   * Temporarily override GetRequiredWater for THIS action so vanilla uses our override.
    --   * After vanilla completes, move the newly created clean item back to wmiReturnContainer.
    -- -----------------------------------------------------------------------
    function ISWashClothing:complete()
        -- Inject per-action water override by temporarily wrapping GetRequiredWater.
        local restoreFn = nil
        if self.wmiWaterOverride then
            restoreFn = ISWashClothing.GetRequiredWater
            ISWashClothing.GetRequiredWater = function(item)
                if item == self.item then
                    return self.wmiWaterOverride
                end
                return _orig_getRequiredWater(item)
            end
        end

        -- Run vanilla completion logic.
        local ok = _orig_complete(self)

        -- Restore GetRequiredWater immediately.
        if restoreFn then
            ISWashClothing.GetRequiredWater = restoreFn
        end

        -- If no return container was provided, nothing else to do.
        if not ok or not self.wmiReturnContainer or not self.wmiExpectedFullType or not self.wmiBeforeIds then
            return ok
        end

        local character = self.character
        local inv = character and character.getInventory and character:getInventory() or nil
        local dest = self.wmiReturnContainer
        if not inv or not dest or not dest.AddItem then return ok end

        -- Find the newly created item by scanning inventory for expected type with a new ID.
        local newItem = nil
        local all = inv:getItems()
        for i = 0, all:size() - 1 do
            local it = all:get(i)
            if it and it.getFullType and it:getFullType() == self.wmiExpectedFullType then
                local id = it.getID and it:getID() or nil
                if id and not self.wmiBeforeIds[id] then
                    newItem = it
                    break
                end
            end
        end

        if not newItem then return ok end

        -- Move it into the original container and sync if helper functions exist (MP).
        inv:Remove(newItem)
        if sendRemoveItemFromContainer then sendRemoveItemFromContainer(inv, newItem) end

        dest:AddItem(newItem)
        if sendAddItemToContainer then sendAddItemToContainer(dest, newItem) end

        return ok
    end
end
