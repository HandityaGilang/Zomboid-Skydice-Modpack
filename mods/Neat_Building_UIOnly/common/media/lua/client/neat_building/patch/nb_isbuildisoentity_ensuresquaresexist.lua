-- NB_ISBuildIsoEntity_EnsureSquaresExist.lua
-- Ensures ISBuildIsoEntity:ensureSquaresExist() (added in B42.13.2) is called before any render logic.
-- Safe on older builds because it checks method existence.

local function NB_Patch_RenderEnsureSquaresExist()
    -- Guard: class must exist
    if not ISBuildIsoEntity or not ISBuildIsoEntity.render then return end

    -- Avoid double-wrapping: if our wrapper is already the current render, do nothing
    if ISBuildIsoEntity._NB_RenderEnsureSquaresExistWrapper
        and ISBuildIsoEntity.render == ISBuildIsoEntity._NB_RenderEnsureSquaresExistWrapper then
        return
    end

    local oldRender = ISBuildIsoEntity.render

    local function wrappedRender(self, x, y, z, square)
        -- Only call the new vanilla helper if it exists (B42.13.2+)
        if self and self.ensureSquaresExist then
            -- pcall protects against edge cases if some mod replaces ensureSquaresExist incorrectly
            pcall(function() self:ensureSquaresExist(x, y, z) end)
        end

        -- Delegate to previous render implementation (vanilla or another mod)
        return oldRender(self, x, y, z, square)
    end

    ISBuildIsoEntity._NB_RenderEnsureSquaresExistWrapper = wrappedRender
    ISBuildIsoEntity.render = wrappedRender
end

-- Apply on the first tick after game boot, so other mods have already patched ISBuildIsoEntity.render.
local function NB_ApplyEnsureSquaresExistOnce()
    NB_Patch_RenderEnsureSquaresExist()

    -- Remove ourselves after one run
    if Events and Events.OnTick and Events.OnTick.Remove then
        Events.OnTick.Remove(NB_ApplyEnsureSquaresExistOnce)
    end
end

if Events and Events.OnGameBoot and Events.OnTick and Events.OnTick.Add then
    Events.OnGameBoot.Add(function()
        Events.OnTick.Add(NB_ApplyEnsureSquaresExistOnce)
    end)
else
    -- Fallback for unusual environments
    NB_Patch_RenderEnsureSquaresExist()
end
