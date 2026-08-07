-- DeadMansDossier_Tests.lua
-- Automated tests for Dead Man's Dossier.
-- Requires: PZTestRunner mod enabled alongside DeadMansDossier.

-- Guard: only register tests if PZTestRunner is loaded (provides PZTest global)
if not PZTest then return end

require "deadmansdossier_shared"

_PZTestRegistrations = _PZTestRegistrations or {}

table.insert(_PZTestRegistrations, function()
    local T = PZTest
    local MOD = DeadMansDossier.MOD_ID
    local WALLET = "Base.Wallet"
    local DUFFELBAG = "Base.Duffelbag"
    local FIRSTAID = "Base.FirstAidKit"

    -- Helper: clean up all dossier items from inventory AND clear mission/cooldown
    local function cleanupTier(player, tierKey)
        local tier = DeadMansDossier.TIERS[tierKey]
        if not tier then return end
        for _, pageType in ipairs(tier.pages) do
            T.removeItems(player, pageType)
        end
        T.removeItems(player, tier.result)
        T.removeItems(player, WALLET)
        T.removeItems(player, DUFFELBAG)
        T.removeItems(player, FIRSTAID)
        -- Clear any leftover mission and reset anti-spam cooldown
        sendClientCommand(player, MOD, DeadMansDossier.CMD_CLEAR_TEST_DATA, { tierKey = tierKey })
        -- Remove client-side map marker so tests don't leave stale markers
        DeadMansDossier.removeStashMarker(tierKey)
    end

    -- Helper: find item recursively (PZTest.findItem only checks top-level)
    local function findItemRecurse(player, fullType)
        return player:getInventory():getFirstTypeRecurse(fullType)
    end

    return {

        -- ── 1. Basic Police assembly (2 pages, main inventory) ───────────
        {
            name = "DMD: Police assembly consumes pages and creates dossier",
            setup = function(player)
                cleanupTier(player, "Police")
                T.giveItem(player, "Base.PoliceDossierPage1")
                T.giveItem(player, "Base.PoliceDossierPage2")
            end,
            setupWaitFrames = 60,
            run = function(player)
                T.assertNotNil(T.findItem(player, "Base.PoliceDossierPage1"), "page1 must exist")
                T.assertNotNil(T.findItem(player, "Base.PoliceDossierPage2"), "page2 must exist")
                sendClientCommand(player, MOD, DeadMansDossier.CMD_ASSEMBLE, { tierKey = "Police" })
            end,
            waitFrames = 120,
            assert = function(player)
                T.assertNil(T.findItem(player, "Base.PoliceDossierPage1"), "page1 should be consumed")
                T.assertNil(T.findItem(player, "Base.PoliceDossierPage2"), "page2 should be consumed")
                T.assertNotNil(findItemRecurse(player, "Base.PoliceDossierComplete"), "dossier should exist")
            end,
        },

        -- ── 2. Military assembly (3 pages, main inventory) ───────────────
        {
            name = "DMD: Military assembly consumes 3 pages and creates dossier",
            setup = function(player)
                cleanupTier(player, "Military")
                T.giveItem(player, "Base.MilitaryDossierPage1")
                T.giveItem(player, "Base.MilitaryDossierPage2")
                T.giveItem(player, "Base.MilitaryDossierPage3")
            end,
            setupWaitFrames = 120,
            run = function(player)
                sendClientCommand(player, MOD, DeadMansDossier.CMD_ASSEMBLE, { tierKey = "Military" })
            end,
            waitFrames = 120,
            assert = function(player)
                T.assertNil(T.findItem(player, "Base.MilitaryDossierPage1"), "page1 consumed")
                T.assertNil(T.findItem(player, "Base.MilitaryDossierPage2"), "page2 consumed")
                T.assertNil(T.findItem(player, "Base.MilitaryDossierPage3"), "page3 consumed")
                T.assertNotNil(findItemRecurse(player, "Base.MilitaryDossierComplete"), "dossier created")
            end,
        },

        -- ── 3. Incomplete assembly fails ─────────────────────────────────
        {
            name = "DMD: assembly fails with missing pages",
            setup = function(player)
                cleanupTier(player, "Medical")
                T.giveItem(player, "Base.MedicalDossierPage1")
                -- only 1 of 2 pages
            end,
            setupWaitFrames = 60,
            run = function(player)
                sendClientCommand(player, MOD, DeadMansDossier.CMD_ASSEMBLE, { tierKey = "Medical" })
            end,
            waitFrames = 120,
            assert = function(player)
                -- Page should still be there (not consumed)
                T.assertNotNil(T.findItem(player, "Base.MedicalDossierPage1"), "page should not be consumed")
                T.assertNil(findItemRecurse(player, "Base.MedicalDossierComplete"), "dossier should not exist")
            end,
        },

        -- ── 4. Assembly with pages in wallet ─────────────────────────────
        {
            name = "DMD: assembly consumes pages from inside a wallet",
            setup = function(player)
                cleanupTier(player, "Firefighter")
                T.giveItemInContainer(player, "Base.FirefighterDossierPage1", WALLET)
                T.giveItemInContainer(player, "Base.FirefighterDossierPage2", WALLET)
            end,
            setupWaitFrames = 120,
            run = function(player)
                -- Pages should be findable recursively but NOT in top-level inventory
                T.assertNotNil(findItemRecurse(player, "Base.FirefighterDossierPage1"), "page1 in wallet")
                T.assertNotNil(findItemRecurse(player, "Base.FirefighterDossierPage2"), "page2 in wallet")
                T.assertNil(T.findItem(player, "Base.FirefighterDossierPage1"), "page1 not in top-level")
                sendClientCommand(player, MOD, DeadMansDossier.CMD_ASSEMBLE, { tierKey = "Firefighter" })
            end,
            waitFrames = 120,
            assert = function(player)
                T.assertNil(findItemRecurse(player, "Base.FirefighterDossierPage1"), "page1 consumed from wallet")
                T.assertNil(findItemRecurse(player, "Base.FirefighterDossierPage2"), "page2 consumed from wallet")
                T.assertNotNil(findItemRecurse(player, "Base.FirefighterDossierComplete"), "dossier created")
            end,
        },

        -- ── 5. Assembly with pages in different containers ───────────────
        {
            name = "DMD: assembly consumes pages from mixed locations",
            setup = function(player)
                cleanupTier(player, "Ranger")
                -- One page in main inventory, one in wallet
                T.giveItem(player, "Base.RangerDossierPage1")
                T.giveItemInContainer(player, "Base.RangerDossierPage2", WALLET)
            end,
            setupWaitFrames = 120,
            run = function(player)
                T.assertNotNil(T.findItem(player, "Base.RangerDossierPage1"), "page1 in main inv")
                T.assertNil(T.findItem(player, "Base.RangerDossierPage2"), "page2 not in main inv")
                T.assertNotNil(findItemRecurse(player, "Base.RangerDossierPage2"), "page2 in wallet")
                sendClientCommand(player, MOD, DeadMansDossier.CMD_ASSEMBLE, { tierKey = "Ranger" })
            end,
            waitFrames = 120,
            assert = function(player)
                T.assertNil(findItemRecurse(player, "Base.RangerDossierPage1"), "page1 consumed")
                T.assertNil(findItemRecurse(player, "Base.RangerDossierPage2"), "page2 consumed from wallet")
                T.assertNotNil(findItemRecurse(player, "Base.RangerDossierComplete"), "dossier created")
            end,
        },

        -- ── 6. Assemble dossier for stash verification ─────────────────────
        --    (test 7 depends on this test's active mission)
        {
            name = "DMD: assemble Medical dossier for stash test",
            setup = function(player)
                cleanupTier(player, "Medical")
                -- Clear all other tiers' missions so handleProximity won't find a
                -- different mission at the same random stash coordinates
                cleanupTier(player, "Police")
                cleanupTier(player, "Military")
                cleanupTier(player, "Firefighter")
                cleanupTier(player, "Ranger")
                T.giveItem(player, "Base.MedicalDossierPage1")
                T.giveItem(player, "Base.MedicalDossierPage2")
            end,
            setupWaitFrames = 120,
            run = function(player)
                sendClientCommand(player, MOD, DeadMansDossier.CMD_ASSEMBLE, { tierKey = "Medical" })
            end,
            waitFrames = 120,
            assert = function(player)
                T.assertNotNil(findItemRecurse(player, "Base.MedicalDossierComplete"), "Medical dossier must exist")
            end,
        },

        -- ── 7. Verify stash grants rewards and consumes dossier ─────────
        {
            name = "DMD: stash verification grants rewards and consumes dossier",
            setup = function(player)
                -- No cleanup — relies on test 6's active Medical mission
            end,
            setupWaitFrames = 30,
            run = function(player)
                T.assertNotNil(findItemRecurse(player, "Base.MedicalDossierComplete"), "dossier must exist before verify")
                sendClientCommand(player, MOD, DeadMansDossier.CMD_TEST_VERIFY_STASH, { tierKey = "Medical" })
            end,
            waitFrames = 120,
            assert = function(player)
                T.assertNil(findItemRecurse(player, "Base.MedicalDossierComplete"), "dossier should be consumed after stash verify")
            end,
        },

        -- ── 8. Assemble Ranger dossier for abandon / marker tests ──────
        {
            name = "DMD: assemble Ranger dossier for abandon and marker tests",
            setup = function(player)
                cleanupTier(player, "Ranger")
                cleanupTier(player, "Police")
                cleanupTier(player, "Military")
                cleanupTier(player, "Medical")
                cleanupTier(player, "Firefighter")
                T.giveItem(player, "Base.RangerDossierPage1")
                T.giveItem(player, "Base.RangerDossierPage2")
            end,
            setupWaitFrames = 120,
            run = function(player)
                sendClientCommand(player, MOD, DeadMansDossier.CMD_ASSEMBLE, { tierKey = "Ranger" })
            end,
            waitFrames = 120,
            assert = function(player)
                T.assertNotNil(findItemRecurse(player, "Base.RangerDossierComplete"), "Ranger dossier must exist")
                T.assertNotNil(DeadMansDossier.activeMarkers["Ranger"], "Ranger marker should be active after assembly")
            end,
        },

        -- ── 9. Map marker restoration on verify ────────────────────────
        --    Clears the client marker, then sends a proximity check far away.
        --    The server responds with mission data, and the client restores the marker.
        {
            name = "DMD: verify stash location restores missing map marker",
            setup = function(player)
                -- Simulate marker loss (e.g. after server restart)
                DeadMansDossier.removeStashMarker("Ranger")
            end,
            setupWaitFrames = 10,
            run = function(player)
                T.assertNil(DeadMansDossier.activeMarkers["Ranger"], "marker should be cleared before test")
                -- Send proximity check far from any stash — server will respond with NOT_CLOSE + missions
                sendClientCommand(player, MOD, DeadMansDossier.CMD_CHECK_PROXIMITY, { x = 0, y = 0, z = 0 })
            end,
            waitFrames = 120,
            assert = function(player)
                T.assertNotNil(DeadMansDossier.activeMarkers["Ranger"], "marker should be restored after verify")
            end,
        },

        -- ── 10. Abandon mission removes dossier and marker ─────────────
        {
            name = "DMD: abandon mission removes dossier and clears marker",
            setup = function(player)
                -- Relies on test 8's active Ranger mission
            end,
            setupWaitFrames = 10,
            run = function(player)
                T.assertNotNil(findItemRecurse(player, "Base.RangerDossierComplete"), "dossier must exist before abandon")
                sendClientCommand(player, MOD, DeadMansDossier.CMD_ABANDON_MISSION, { tierKey = "Ranger" })
            end,
            waitFrames = 120,
            assert = function(player)
                T.assertNil(findItemRecurse(player, "Base.RangerDossierComplete"), "dossier should be removed after abandon")
                T.assertNil(DeadMansDossier.activeMarkers["Ranger"], "marker should be removed after abandon")
            end,
        },

        -- ── 11. Re-assemble same tier after abandon ────────────────────
        --    Verifies a player can collect pages and assemble the same tier
        --    again after abandoning a previous mission.
        {
            name = "DMD: re-assembly works after abandoning same tier",
            setup = function(player)
                -- Test 10 already abandoned Ranger — mission is cleared
                cleanupTier(player, "Ranger")
                T.giveItem(player, "Base.RangerDossierPage1")
                T.giveItem(player, "Base.RangerDossierPage2")
            end,
            setupWaitFrames = 120,
            run = function(player)
                sendClientCommand(player, MOD, DeadMansDossier.CMD_ASSEMBLE, { tierKey = "Ranger" })
            end,
            waitFrames = 120,
            assert = function(player)
                T.assertNil(findItemRecurse(player, "Base.RangerDossierPage1"), "page1 consumed on re-assembly")
                T.assertNil(findItemRecurse(player, "Base.RangerDossierPage2"), "page2 consumed on re-assembly")
                T.assertNotNil(findItemRecurse(player, "Base.RangerDossierComplete"), "dossier created on re-assembly")
                T.assertNotNil(DeadMansDossier.activeMarkers["Ranger"], "marker should be active after re-assembly")
            end,
        },

        -- ── 12. Orphan dossier abandon (no mission data) ───────────────
        --    Simulates a server rollback where mission data is lost but the
        --    player still has the dossier. Abandon should still destroy it.
        {
            name = "DMD: abandon works for orphaned dossier without mission data",
            setup = function(player)
                -- Clear mission data server-side but keep the dossier from test 11
                sendClientCommand(player, MOD, DeadMansDossier.CMD_CLEAR_TEST_DATA, { tierKey = "Ranger" })
                -- Clear client marker to simulate full rollback state
                DeadMansDossier.removeStashMarker("Ranger")
            end,
            setupWaitFrames = 60,
            run = function(player)
                T.assertNotNil(findItemRecurse(player, "Base.RangerDossierComplete"), "orphaned dossier must exist")
                T.assertNil(DeadMansDossier.activeMarkers["Ranger"], "marker should be gone (simulated rollback)")
                sendClientCommand(player, MOD, DeadMansDossier.CMD_ABANDON_MISSION, { tierKey = "Ranger" })
            end,
            waitFrames = 120,
            assert = function(player)
                T.assertNil(findItemRecurse(player, "Base.RangerDossierComplete"), "orphaned dossier should be removed")
                T.assertNil(DeadMansDossier.activeMarkers["Ranger"], "marker should remain cleared")
            end,
        },

        -- ── 13. Death clears missions (assemble, then simulate death) ────
        {
            name = "DMD: assemble Police dossier for death-clear test",
            setup = function(player)
                cleanupTier(player, "Police")
                cleanupTier(player, "Military")
                cleanupTier(player, "Medical")
                cleanupTier(player, "Firefighter")
                cleanupTier(player, "Ranger")
                T.giveItem(player, "Base.PoliceDossierPage1")
                T.giveItem(player, "Base.PoliceDossierPage2")
            end,
            setupWaitFrames = 120,
            run = function(player)
                sendClientCommand(player, MOD, DeadMansDossier.CMD_ASSEMBLE, { tierKey = "Police" })
            end,
            waitFrames = 120,
            assert = function(player)
                T.assertNotNil(findItemRecurse(player, "Base.PoliceDossierComplete"), "Police dossier must exist before death")
                T.assertNotNil(DeadMansDossier.activeMarkers["Police"], "Police marker should be active before death")
            end,
        },

        -- ── 14. Simulate death clears missions, then re-assembly works ──
        {
            name = "DMD: death clears missions allowing re-assembly of same tier",
            setup = function(player)
                -- Simulate player death — clears all mission data server-side
                sendClientCommand(player, MOD, DeadMansDossier.CMD_TEST_SIMULATE_DEATH, {})
                -- Clear client-side markers (in real death, new character starts fresh)
                DeadMansDossier.removeStashMarker("Police")
                -- Remove the dossier (on real death it's on the corpse)
                T.removeItems(player, "Base.PoliceDossierComplete")
                -- Give fresh pages for re-assembly
                T.giveItem(player, "Base.PoliceDossierPage1")
                T.giveItem(player, "Base.PoliceDossierPage2")
            end,
            setupWaitFrames = 120,
            run = function(player)
                T.assertNil(DeadMansDossier.activeMarkers["Police"], "marker should be cleared after death")
                -- Re-assemble same tier — should succeed since mission was cleared
                sendClientCommand(player, MOD, DeadMansDossier.CMD_ASSEMBLE, { tierKey = "Police" })
            end,
            waitFrames = 120,
            assert = function(player)
                T.assertNotNil(findItemRecurse(player, "Base.PoliceDossierComplete"), "re-assembly should work after death")
                T.assertNotNil(DeadMansDossier.activeMarkers["Police"], "new marker should appear after re-assembly")
            end,
        },

        -- ── 15. Distribution injection verification ─────────────────────
        --    Checks that all expected distribution tables have dossier pages.
        {
            name = "DMD: distribution tables have dossier pages injected",
            setup = function(player)
                DeadMansDossier._testDistResult = nil
            end,
            setupWaitFrames = 10,
            run = function(player)
                sendClientCommand(player, MOD, DeadMansDossier.CMD_TEST_CHECK_DISTRIBUTIONS, {})
            end,
            waitFrames = 120,
            assert = function(player)
                local result = DeadMansDossier._testDistResult
                T.assertNotNil(result, "should have received distribution check result from server")
                T.assertEqual(result.success, 1, "all distributions should be injected"
                    .. (result.details and result.details ~= "" and (": " .. result.details) or ""))
                T.assertEqual(result.missingCount, 0, "no distributions should be missing")
            end,
        },

        -- ── 16. Custom rewards config: generation, parsing, validation ──
        --    Tests that the config file is generated correctly, parsed with
        --    proper handling of comments/bad lines/unknown tiers, and that
        --    the override mechanism works.
        {
            name = "DMD: custom rewards config generation and parsing",
            setup = function(player)
                DeadMansDossier._testCustomRewardsResult = nil
            end,
            setupWaitFrames = 10,
            run = function(player)
                sendClientCommand(player, MOD, DeadMansDossier.CMD_TEST_CUSTOM_REWARDS, {})
            end,
            waitFrames = 120,
            assert = function(player)
                local result = DeadMansDossier._testCustomRewardsResult
                T.assertNotNil(result, "should have received custom rewards test result from server")
                T.assertEqual(result.success, 1, "custom rewards tests should pass"
                    .. (result.details and result.details ~= "" and (": " .. result.details) or ""))
                T.assertEqual(result.errorCount, 0, "no custom rewards test errors expected")
            end,
        },

        -- ── 17. Cleanup: clear all test missions and items ──────────────
        --    Runs last to avoid polluting real gameplay state on rejoin.
        {
            name = "DMD: cleanup all test data",
            setup = function(player)
                cleanupTier(player, "Police")
                cleanupTier(player, "Military")
                cleanupTier(player, "Medical")
                cleanupTier(player, "Firefighter")
                cleanupTier(player, "Ranger")
                DeadMansDossier._testDistResult = nil
                DeadMansDossier._testCustomRewardsResult = nil
            end,
            setupWaitFrames = 60,
            run = function(player)
                -- Nothing to run — cleanup is in setup
            end,
            waitFrames = 30,
            assert = function(player)
                -- Verify no test dossiers remain
                T.assertNil(findItemRecurse(player, "Base.PoliceDossierComplete"), "Police dossier cleaned up")
                T.assertNil(findItemRecurse(player, "Base.MilitaryDossierComplete"), "Military dossier cleaned up")
                T.assertNil(findItemRecurse(player, "Base.MedicalDossierComplete"), "Medical dossier cleaned up")
                T.assertNil(findItemRecurse(player, "Base.FirefighterDossierComplete"), "Firefighter dossier cleaned up")
                T.assertNil(findItemRecurse(player, "Base.RangerDossierComplete"), "Ranger dossier cleaned up")
            end,
        },

    }
end)
