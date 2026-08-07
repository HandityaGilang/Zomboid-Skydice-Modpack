-- TMBanListHooks.lua (client)
-- Enforces the BAN MUSIC LIST on every TrueMoozic device interaction:
--   * blocks inserting a banned song/album into boombox / portable CD / HiFi
--   * blocks pressing PLAY on a banned song already in a device
--   * always allows STOP (so a device caught mid-song can be shut off)
-- Admins/debug keep access while the bypass toggle in the Ban UI is ON.
-- Hooks are installed on OnGameBoot (after all class files are loaded) so we
-- always wrap the final client-side definitions.
require "TMBanListDefs"

local hooked = false

local function blockedForPlayer(player, name)
    if not name then return false end
    if TMBanList.canUseName(player, name) then return false end
    TMBanList.blockNote(player)
    return true
end

local function blockedItemForPlayer(player, item)
    if not item then return false end
    if TMBanList.canUseItem(player, item) then return false end
    TMBanList.blockNote(player)
    return true
end

local function installHooks()
    if hooked then return end
    hooked = true

    ------------------------------------------------------------------
    -- Boombox / walkman / world jukebox-mode devices
    ------------------------------------------------------------------
    if ISTCBoomboxAction then
        local origAdd = ISTCBoomboxAction.isValidAddMedia
        function ISTCBoomboxAction:isValidAddMedia()
            if not origAdd(self) then return false end
            if blockedItemForPlayer(self.character, self.secondaryItem) then return false end
            return true
        end

        local origToggle = ISTCBoomboxAction.isValidTogglePlayMedia
        function ISTCBoomboxAction:isValidTogglePlayMedia()
            if not origToggle(self) then return false end
            local tcm = self.device and self.device.getModData and self.device:getModData().tcmusic or nil
            -- Stopping a playing device is always allowed (sessions hold the
            -- live play state for walkmans/boomboxes; the item flag is legacy).
            local devId = self.device and self.device.getID and self.device:getID() or nil
            local ws = TCMusic and TCMusic.WalkmanSession or nil
            local bs = TCMusic and TCMusic.BoomboxSession or nil
            if devId and ((ws and ws.itemId == devId) or (bs and bs.itemId == devId)) then return true end
            if tcm and tcm.isPlaying then return true end
            if tcm and blockedForPlayer(self.character, tcm.mediaItem) then return false end
            return true
        end
    end

    ------------------------------------------------------------------
    -- Portable CD player (SWTC)
    ------------------------------------------------------------------
    if SWTCPlayerAction then
        local origAdd = SWTCPlayerAction.isValidAddMedia
        function SWTCPlayerAction:isValidAddMedia()
            if not origAdd(self) then return false end
            if blockedItemForPlayer(self.character, self.secondaryItem) then return false end
            return true
        end

        local origToggle = SWTCPlayerAction.isValidTogglePlayMedia
        function SWTCPlayerAction:isValidTogglePlayMedia()
            if not origToggle(self) then return false end
            local cm = self.device and self.device:getModData().customMusic or nil
            if cm and cm.isPlaying then return true end
            local name = cm and (cm.fullItemType or cm.cdType) or nil
            if blockedForPlayer(self.character, name) then return false end
            return true
        end
    end

    ------------------------------------------------------------------
    -- HiFi (CD / cassette / vinyl decks)
    ------------------------------------------------------------------
    if HiFiTimedAction then
        for _, fn in ipairs({ "isValidAddCD", "isValidAddCassette", "isValidAddVinyl" }) do
            local orig = HiFiTimedAction[fn]
            if orig then
                HiFiTimedAction[fn] = function(self)
                    if not orig(self) then return false end
                    if blockedItemForPlayer(self.character, self.secondaryItem) then return false end
                    return true
                end
            end
        end

        local toggles = {
            isValidTogglePlayCD = function(md)
                local d = md.hifiCD
                return d, d and (d.fullItemType or d.cdType) or nil
            end,
            isValidTogglePlayCassette = function(md)
                local d = md.hifiTape
                return d, d and d.mediaItem or nil
            end,
            isValidTogglePlayVinyl = function(md)
                local d = md.hifiVinyl
                return d, d and d.mediaItem or nil
            end,
        }
        for fn, getSlot in pairs(toggles) do
            local orig = HiFiTimedAction[fn]
            if orig then
                HiFiTimedAction[fn] = function(self)
                    if not orig(self) then return false end
                    local md = self.device and self.device:getModData() or nil
                    if not md then return true end
                    local slot, name = getSlot(md)
                    if slot and slot.isPlaying then return true end
                    if blockedForPlayer(self.character, name) then return false end
                    return true
                end
            end
        end
    end
end

Events.OnGameBoot.Add(installHooks)
Events.OnGameStart.Add(installHooks)
