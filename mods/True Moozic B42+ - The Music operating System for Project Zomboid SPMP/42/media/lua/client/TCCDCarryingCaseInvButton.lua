--- Adds an inventory tab button for the CD Carrying Case whenever it is
--- accessible to the player (main inventory un-equipped, on the ground, or
--- inside any nearby container the inventory window is showing).
---
--- Vanilla ISInventoryPage:refreshBackpacks only creates a sub-tab for a
--- container item in the player's main inventory if it is currently equipped
--- (worn). Floor / vehicle paths already create a tab for each container
--- item they iterate.
---
--- We register on the vanilla "OnRefreshInventoryWindowContainers" event in
--- the "buttonsAdded" phase. That phase fires AFTER vanilla has populated
--- self.backpacks with all buttons, but BEFORE the page's "find selected
--- inventory" scan that decides whether to keep the user's current
--- selection. Hooking here ensures clicks on our extra button stick (a
--- post-refreshBackpacks wrap would run too late and the page would reset
--- inventoryPane.inventory back to the main player inv).

local TARGET_TYPE = "Tsarcraft.TM_CDCarryingCase"

local function isAlreadyAdded(self, inv)
    if not inv then return true end
    for i = 1, #self.backpacks do
        if self.backpacks[i].inventory == inv then
            return true
        end
    end
    return false
end

local function scanInventoryForCases(self, inv)
    if not inv then return end
    local items = inv.getItems and inv:getItems() or nil
    if not items then return end
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and item.getFullType and item:getFullType() == TARGET_TYPE then
            local subInv = item.getInventory and item:getInventory() or nil
            if subInv and not isAlreadyAdded(self, subInv) then
                local ok, btn = pcall(self.addContainerButton, self, subInv, item:getTex(), item:getName(), item:getName())
                if ok and btn and item.getVisual and item:getVisual() and item.getClothingItem and item:getClothingItem() then
                    local tint = item:getVisual():getTint(item:getClothingItem())
                    if tint then
                        btn:setTextureRGBA(tint:getRedFloat(), tint:getGreenFloat(), tint:getBlueFloat(), 1.0)
                    end
                end
            end
        end
    end
end

local function addCDCarryingCaseButtons(self)
    if not self or not self.backpacks then return end
    -- snapshot the inventories that already have buttons; iterate the snapshot
    -- so newly added buttons (sub-inventories) don't get re-scanned themselves.
    local snapshot = {}
    for i = 1, #self.backpacks do
        local btn = self.backpacks[i]
        if btn and btn.inventory then
            snapshot[#snapshot + 1] = btn.inventory
        end
    end
    for i = 1, #snapshot do
        scanInventoryForCases(self, snapshot[i])
    end
end

local function onRefreshContainers(page, phase)
    if phase ~= "buttonsAdded" then return end
    local ok, err = pcall(addCDCarryingCaseButtons, page)
    if not ok then
        print("[TrueMusic] CDCarryingCase inv button hook error: " .. tostring(err))
    end
end

local function applyHook()
    if Events and Events.OnRefreshInventoryWindowContainers then
        if not Events.OnRefreshInventoryWindowContainers._tcCDCarryingCaseHook then
            Events.OnRefreshInventoryWindowContainers._tcCDCarryingCaseHook = true
            Events.OnRefreshInventoryWindowContainers.Add(onRefreshContainers)
        end
    end
end

applyHook()
if Events and Events.OnGameBoot then
    Events.OnGameBoot.Add(applyHook)
end
