--[[--------------------------------------------------------------------
  Improved Hair Menu — CharacterUpdateHook.lua
  Purpose: Install late, safe hooks into CharacterCreationHeader and
           its AvatarPanel so we can react to survivor desc changes
           without touching vanilla files directly.

  Fixes:
   - Prevents "attempted index: create of non-table: null" by delaying
     any access to CharacterCreationHeader until it actually exists.
   - Uses nil-safe checks and pcall to avoid cascading errors.
----------------------------------------------------------------------]]

local TAG = "[IHM/CharacterUpdateHook] "

-- Install the header hook once CharacterCreationHeader is defined.
local function installHeaderHook()
    -- Already installed?
    if CharacterCreationHeader and CharacterCreationHeader._IHM_hooked then
        return true
    end

    -- Not ready yet?
    if type(CharacterCreationHeader) ~= "table" or type(CharacterCreationHeader.create) ~= "function" then
        return false
    end

    local original_create = CharacterCreationHeader.create

    -- Wrap CharacterCreationHeader:create so we can hook the avatarPanel afterwards.
    function CharacterCreationHeader:create(...)
        -- Call vanilla / previously wrapped create first
        original_create(self, ...)

        -- Guard: avatarPanel may not exist on some paths
        if not self.avatarPanel then
            return
        end

        -- Only hook once per avatarPanel instance
        if self.avatarPanel._IHM_hooked then
            return
        end
        self.avatarPanel._IHM_hooked = true

        -- Wrap setSurvivorDesc to notify our UI (if present)
        local original_set = self.avatarPanel.setSurvivorDesc
        if type(original_set) == "function" then
            self.avatarPanel.setSurvivorDesc = function(panel, desc, ...)
                -- Call vanilla first
                original_set(panel, desc, ...)

                -- If our CharacterCreationMain instance exposes a preview-update method, call it
                local CCM = rawget(_G, "CharacterCreationMain")
                local ok, err = pcall(function()
                    if CCM and CCM.instance and type(CCM.instance.ihm_update_preview_model) == "function" then
                        CCM.instance:ihm_update_preview_model(desc)
                    end
                end)
                if not ok and err then
                    print(TAG .. "ihm_update_preview_model failed: " .. tostring(err))
                end
            end
        end
    end

    CharacterCreationHeader._IHM_hooked = true
    print(TAG .. "Header hook installed.")
    return true
end

-- Re-try installation every tick until it succeeds, then remove itself.
local function tryInstallHeaderHook()
    local ok = installHeaderHook()
    if ok then
        Events.OnTick.Remove(tryInstallHeaderHook)
    end
end

-- Register the retry on tick (fires in main menu and in-game)
Events.OnTick.Add(tryInstallHeaderHook)

-- Extra: also attempt at safe lifecycle points (redundant but cheap)
Events.OnMainMenuEnter.Add(function() tryInstallHeaderHook() end)
Events.OnCreatePlayer.Add(function() tryInstallHeaderHook() end)

print(TAG .. "loaded (waiting for CharacterCreationHeader)...")