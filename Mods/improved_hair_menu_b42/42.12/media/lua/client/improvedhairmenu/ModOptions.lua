--[[
    Improved Hair Menu — Build 42
    ModOptions.lua

    Goal:
      - Do NOT create a Mod Options page anymore (Build 42 doesn't need "legacy" ModOptions).
      - If users previously had values stored in the native ModOptions page, migrate them ONCE into
        ImprovedHairMenu.settings and persist to IHM_live.ini.
      - From now on, only IHM_LiveConfig (your live sliders) should control the settings.

    Notes:
      - This file is defensive: every external reference is guarded (PZAPI, events, IHM_LiveConfig).
      - All comments in English (as requested).
]]

-- ============================================================================
-- IHM_LiveConfig  (restored minimal implementation for Build 42)
-- Persists live sliders to <Zomboid>/IHM_live.ini and feeds ImprovedHairMenu.settings
-- ============================================================================

if not _G.IHM_LiveConfig then
    local LC = {}
    LC.cache = {}

    local function _getIniPath()
        local dir = (type(getZomboidDir) == "function") and getZomboidDir() or ""
        if dir and dir ~= "" then return dir .. "/IHM_live.ini" end
        return "IHM_live.ini" -- extreme fallback
    end
    LC._path = _getIniPath()

    local function _toBool(v)
        if type(v) == "boolean" then return v end
        if type(v) == "number"  then return v ~= 0 end
        if type(v) == "string"  then
            v = v:lower()
            return (v == "1" or v == "true" or v == "yes" or v == "on")
        end
        return false
    end

    local function _clampInt(n, lo, hi)
        n = tonumber(n)
        if not n then return lo end
        n = math.floor(n + 0.5)
        if n < lo then n = lo end
        if n > hi then n = hi end
        return n
    end

    -- ---- file helpers -------------------------------------------------------
    local function _openReader(path)
        if type(getFileReader) == "function" then
            local ok, rd = pcall(function() return getFileReader(path, true) end)
            if ok and rd then return rd end
        end
        return nil
    end

    local function _openWriter(path)
        if type(getFileWriter) == "function" then
            -- try with createDirs=true first; fallback if needed
            local ok, wr = pcall(function() return getFileWriter(path, true, false) end)
            if ok and wr then return wr end
            ok, wr = pcall(function() return getFileWriter(path, false, false) end)
            if ok and wr then return wr end
        end
        return nil
    end
    -- ------------------------------------------------------------------------

    function LC:load()
        local rd = _openReader(self._path)
        if not rd then return self.cache end
        local line = rd:readLine()
        while line do
            local k, v = string.match(line, "^%s*([%w_]+)%s*=%s*(.-)%s*$")
            if k then
                if k == "use_modal" then
                    self.cache.use_modal = _toBool(v)
                elseif k == "modal_rows" then
                    self.cache.modal_rows = _clampInt(v, 1, 10)
                elseif k == "modal_cols" then
                    self.cache.modal_cols = _clampInt(v, 1, 10)
                elseif k == "avatar_size" then
                    self.cache.avatar_size = _clampInt(v, 1, 7)
                end
            end
            line = rd:readLine()
        end
        rd:close()
        self.cache.use_modal = true   -- force modal regardless of stored value
		return self.cache
    end

    function LC:_writeAll(tbl)
        local wr = _openWriter(self._path)
        if not wr then return end
        local t = tbl or self.cache

        -- defaults to stay compatible with your previous behavior
        local rows = _clampInt(t.modal_rows or 4, 1, 10)
        local cols = _clampInt(t.modal_cols or 8, 1, 10)
        local asz  = _clampInt(t.avatar_size or 7, 1, 7)
        -- Force modal on for all users
		local useM = 1
		-- (optional) keep the flag in sync if other code reads it:
		t.use_modal = true

        wr:write("modal_rows="  .. tostring(rows) .. "\n")
        wr:write("modal_cols="  .. tostring(cols) .. "\n")
        wr:write("avatar_size=" .. tostring(asz)  .. "\n")
        wr:write("use_modal="   .. tostring(useM) .. "\n")
        wr:close()
    end

    function LC:save()
        self:_writeAll(self.cache)
    end

    function LC:update(key, val)
        if key == "modal_rows" then
            self.cache.modal_rows = _clampInt(val, 1, 10)
        elseif key == "modal_cols" then
            self.cache.modal_cols = _clampInt(val, 1, 10)
        elseif key == "avatar_size" then
            self.cache.avatar_size = _clampInt(val, 1, 7)
        elseif key == "use_modal" then
            self.cache.use_modal = _toBool(val)
        else
            self.cache[key] = val
        end
        return self.cache[key]
    end

    function LC:updateAndSave(key, val)
        local v = self:update(key, val)
        self:save()
        -- keep persisted table in sync if present (helps on rebuilds)
        if _G.ImprovedHairMenu and _G.ImprovedHairMenu.settings then
            _G.ImprovedHairMenu.settings[key] = v
        end
        return v
    end

    -- Copy cached values into your settings table
    function LC:applyToSettings(S)
        if not S then return end
        if self.cache.modal_rows  ~= nil then S.modal_rows  = self.cache.modal_rows  end
        if self.cache.modal_cols  ~= nil then S.modal_cols  = self.cache.modal_cols  end
        if self.cache.avatar_size ~= nil then S.avatar_size = self.cache.avatar_size end
        if self.cache.use_modal   ~= nil then S.use_modal   = self.cache.use_modal   end
    end

    -- Persist from settings -> INI (used by one-shot migration or defaults)
    function LC:saveFromSettings(S)
        if not S then return end
        self.cache.modal_rows  = _clampInt(S.modal_rows  or self.cache.modal_rows  or 8, 1, 10)
        self.cache.modal_cols  = _clampInt(S.modal_cols  or self.cache.modal_cols  or 6, 1, 10)
        self.cache.avatar_size = _clampInt(S.avatar_size or self.cache.avatar_size or 5, 1, 7)
        self.cache.use_modal = true
        self:save()
    end

    _G.IHM_LiveConfig = LC

    -- Load once on module load so live cache is available immediately
    pcall(function() LC:load() end)
end
-- ============================================================================


---------------------------------------
-- Safe globals / fallbacks
---------------------------------------
local function hasNativeOptions()
    return _G.PZAPI
       and _G.PZAPI.ModOptions
       and type(_G.PZAPI.ModOptions.getOptions) == "function"
end

-- Ensure the global table exists
_G.ImprovedHairMenu = _G.ImprovedHairMenu or {}
local S = _G.ImprovedHairMenu.settings

-- Create default settings if missing (kept conservative; live sliders will override)
if not S then
    S = {
        use_modal   = true, -- default to modal UI on B42
        avatar_size = 7,    -- 1..7 -> (32..128 px step 16)
        modal_rows  = 4,
        modal_cols  = 8,
        hair_rows   = 3,
        hair_cols   = 2,
        beard_rows  = 3,
        beard_cols  = 1,
    }
    _G.ImprovedHairMenu.settings = S
end

---------------------------------------
-- Disable ModOptions UI (B42) + one-shot migration
---------------------------------------
local DISABLE_MODOPTIONS_UI = true

-- Clamp helpers
local function clampInt(v, lo, hi)
    v = tonumber(v) or lo
    if v < lo then return lo end
    if v > hi then return hi end
    return math.floor(v + 0.5)
end

-- Read helpers (from native ModOptions page)
local function _readBool(page, id, def)
    local o = page and page:getOption(id)
    if not o then return def end
    local v = (o.getValue and o:getValue()) or nil
    if type(v) == "boolean" then return v end
    if type(v) == "number"  then return v ~= 0 end
    return def
end

local function _readInt(page, id, def, lo, hi)
    local o = page and page:getOption(id)
    if not o then return def end
    local v = (o.getValue and o:getValue()) or nil
    if type(v) ~= "number" then return def end
    return clampInt(v, lo, hi)
end

-- One-shot migration: read existing native ModOptions WITHOUT creating a page,
-- and write values into ImprovedHairMenu.settings, then persist via IHM_LiveConfig.
local function migrateExistingOptionsNoUI()
    if not (DISABLE_MODOPTIONS_UI and hasNativeOptions()) then return end

    local ok, page = pcall(function()
        return _G.PZAPI.ModOptions:getOptions("ImprovedHairMenu")
    end)
    if not ok or not page then
        return -- nothing to migrate
    end

    -- Pull whatever exists; fall back to existing settings in S.
    S.use_modal = true   -- always modal
    S.avatar_size = _readInt (page, "avatar_size", S.avatar_size, 1, 7)
    S.modal_rows  = _readInt (page, "modal_rows",  S.modal_rows,  1, 10)
    S.modal_cols  = _readInt (page, "modal_cols",  S.modal_cols,  1, 10)
    S.hair_rows   = _readInt (page, "hair_rows",   S.hair_rows,   1, 10)
    S.hair_cols   = _readInt (page, "hair_cols",   S.hair_cols,   1, 10)
    S.beard_rows  = _readInt (page, "beard_rows",  S.beard_rows,  1, 10)
    S.beard_cols  = _readInt (page, "beard_cols",  S.beard_cols,  1, 10)

    -- Persist migrated values to our live file so the new UI uses them going forward.
    if _G.IHM_LiveConfig and type(_G.IHM_LiveConfig.saveFromSettings) == "function" then
        pcall(function() _G.IHM_LiveConfig:saveFromSettings(S) end)
    end
end

---------------------------------------
-- Live config bridge (load/apply)
---------------------------------------
local function applyLiveConfigToSettings()
    if not _G.IHM_LiveConfig then return end

    -- load() and applyToSettings() are part of your live-controls pipeline
    if type(_G.IHM_LiveConfig.load) == "function" then
        pcall(function() _G.IHM_LiveConfig:load() end)
    end
    if type(_G.IHM_LiveConfig.applyToSettings) == "function" then
        pcall(function() _G.IHM_LiveConfig:applyToSettings(S) end)
    end
end
local function _forceModal()
    S.use_modal = true
    if _G.IHM_LiveConfig and type(_G.IHM_LiveConfig.update) == "function" then
        pcall(function() _G.IHM_LiveConfig:update("use_modal", true) end)
    end
end
---------------------------------------
-- Entry: NO ModOptions UI, but migrate if legacy values exist
---------------------------------------
if DISABLE_MODOPTIONS_UI and hasNativeOptions() then
    migrateExistingOptionsNoUI()
end

-- Always apply live overrides at load time
applyLiveConfigToSettings()
_forceModal()

-- Also apply on main menu enter (covers transitions and first load)
if _G.Events and _G.Events.OnMainMenuEnter and type(_G.Events.OnMainMenuEnter.Add) == "function" then
    _G.Events.OnMainMenuEnter.Add(function()
        applyLiveConfigToSettings()
		_forceModal()
    end)
end

-- And apply once game starts (in case someone launches straight into a save)
if _G.Events and _G.Events.OnGameStart and type(_G.Events.OnGameStart.Add) == "function" then
    _G.Events.OnGameStart.Add(function()
        applyLiveConfigToSettings()
		_forceModal()
    end)
end

-- (Optional) Uncomment for debugging:
-- print("[IHM] ModOptions disabled. Legacy values (if any) migrated. LiveConfig active.")