-- KnoxDetectionKit_Tests.lua
-- Automated tests for Knox Detection Kit.
-- Requires: PZTestRunner mod enabled alongside KnoxDetectionKit.
--
-- Place at:
--   KnoxDetectionKit/Contents/mods/KnoxDetectionKit/42/media/lua/client/tests/KnoxDetectionKit_Tests.lua
--
-- Cooldown note: The server has a 5-second anti-spam cooldown on RunTest.
-- OnPlayerUpdate fires at ~60 fps, so waitFrames = 360 (~6 s) ensures each
-- test's command arrives after the previous cooldown has expired.

_PZTestRegistrations = _PZTestRegistrations or {}

table.insert(_PZTestRegistrations, function()
    local T = PZTest

    return {

        -- ── Test 1: kit is removed after use ────────────────────────────────
        {
            name = "KnoxDetectionKit: kit is removed after use",

            sandbox = {
                ["KnoxDetectionKit.WaitMinutes"] = 120,
            },

            setup = function(player)
                -- Clear stale ModData from previous sessions
                local modData = player:getModData()
                modData.KnoxDetectionKit_resultReady = nil
                modData.KnoxDetectionKit_infected = nil
                T.removeItems(player, "Base.KnoxDetectionKit")
                T.giveItem(player, "Base.KnoxDetectionKit")
            end,

            setupWaitFrames = 60,

            run = function(player)
                local item = T.findItem(player, "Base.KnoxDetectionKit")
                T.assertNotNil(item, "kit must be in inventory")
                sendClientCommand(player, "KnoxDetectionKit", "RunTest", { itemID = item:getID() })
            end,

            waitFrames = 360,

            assert = function(player)
                T.assertNil(T.findItem(player, "Base.KnoxDetectionKit"),
                    "kit should be consumed after RunTest")
            end,
        },

        -- ── Test 2: invalid item ID is handled gracefully ───────────────────
        {
            name = "KnoxDetectionKit: invalid item ID is handled gracefully",

            setup = function(player) end,

            setupWaitFrames = 60,

            run = function(player)
                -- Send a request with a nonexistent item ID.
                -- Server should respond with error without crashing.
                sendClientCommand(player, "KnoxDetectionKit", "RunTest", { itemID = -1 })
            end,

            waitFrames = 360,

            assert = function(player)
                -- Server handled invalid ID without crashing. Reaching here = pass.
                T.assertTrue(true)
            end,
        },

        -- ── Test 3: non-kit item is rejected ────────────────────────────────
        {
            name = "KnoxDetectionKit: non-kit item is rejected",

            setup = function(player)
                T.removeItems(player, "Base.Bandage")
                T.giveItem(player, "Base.Bandage")
            end,

            setupWaitFrames = 60,

            run = function(player)
                local item = T.findItem(player, "Base.Bandage")
                T.assertNotNil(item, "bandage must be in inventory")
                -- Send RunTest with a Bandage ID — server should reject it
                sendClientCommand(player, "KnoxDetectionKit", "RunTest", { itemID = item:getID() })
            end,

            waitFrames = 360,

            assert = function(player)
                T.assertNotNil(T.findItem(player, "Base.Bandage"),
                    "bandage should still be in inventory (server rejects wrong item type)")
            end,
        },

        -- ── Test 4: cooldown blocks rapid second use ────────────────────────
        {
            name = "KnoxDetectionKit: cooldown blocks rapid second use",

            sandbox = {
                ["KnoxDetectionKit.WaitMinutes"] = 120,
            },

            setup = function(player)
                T.removeItems(player, "Base.KnoxDetectionKit")
                T.giveItem(player, "Base.KnoxDetectionKit")
                T.giveItem(player, "Base.KnoxDetectionKit")
            end,

            setupWaitFrames = 60,

            run = function(player)
                -- Collect both kit instances
                local items = {}
                local inv = player:getInventory():getItems()
                for i = 0, inv:size() - 1 do
                    local it = inv:get(i)
                    if it:getFullType() == "Base.KnoxDetectionKit" then
                        items[#items + 1] = it
                    end
                end
                T.assertEqual(#items, 2, "should have 2 kits before use")

                -- Fire two RunTest commands in the same frame.
                -- The server's 5-second cooldown should block the second one.
                sendClientCommand(player, "KnoxDetectionKit", "RunTest", { itemID = items[1]:getID() })
                sendClientCommand(player, "KnoxDetectionKit", "RunTest", { itemID = items[2]:getID() })
            end,

            waitFrames = 360,

            assert = function(player)
                -- First command succeeds (item consumed), second is rate-limited (item remains).
                T.assertNotNil(T.findItem(player, "Base.KnoxDetectionKit"),
                    "one kit should remain (second command was rate-limited)")
            end,
        },

        -- ── Test 5: test detects zombie infection ───────────────────────────
        {
            name = "KnoxDetectionKit: test detects zombie infection",

            -- WaitMinutes=360 (matching test 8) so the result isn't auto-revealed during waitFrames.
            -- Why: at default day length, 1 game minute ≈ 0.04 sec real, so a 120-minute wait
            -- elapses in ~5 seconds — within waitFrames=360 (~6 sec). When the reveal fires,
            -- modData.KnoxDetectionKit_infected gets cleared, breaking the assertion below.
            -- 360 game minutes (~15 sec real) safely exceeds waitFrames so modData persists.
            sandbox = {
                ["KnoxDetectionKit.WaitMinutes"] = 360,
            },

            setup = function(player)
                T.removeItems(player, "Base.KnoxDetectionKit")
                T.giveItem(player, "Base.KnoxDetectionKit")
                T.setInfectionLevel(player, 50)
            end,

            setupWaitFrames = 120,

            run = function(player)
                -- Do NOT assert client-side infection here. PZTestRunner's SetInfection sets
                -- CharacterStat.ZOMBIE_INFECTION server-side, but in 42.1.17 the value doesn't
                -- propagate to the client's stats within reasonable wait windows (tested 240+ frames).
                -- The kit reads server-side via `stats:get(CharacterStat.ZOMBIE_INFECTION)`, so the
                -- end-to-end assertion below (modData.KnoxDetectionKit_infected == 1) is what actually
                -- validates the test detected infection correctly.
                local item = T.findItem(player, "Base.KnoxDetectionKit")
                T.assertNotNil(item, "kit must be in inventory")
                sendClientCommand(player, "KnoxDetectionKit", "RunTest", { itemID = item:getID() })
            end,

            waitFrames = 360,

            assert = function(player)
                T.assertNil(T.findItem(player, "Base.KnoxDetectionKit"),
                    "kit should be consumed")
                -- Result is stored in ModData — verify infected flag was set
                local modData = player:getModData()
                T.assertEqual(modData.KnoxDetectionKit_infected, 1,
                    "ModData should record infected=1")
            end,
        },

        -- ── Test 6: test detects clean player ───────────────────────────────
        {
            name = "KnoxDetectionKit: test detects clean player",

            sandbox = {
                ["KnoxDetectionKit.WaitMinutes"] = 120,
            },

            setup = function(player)
                T.removeItems(player, "Base.KnoxDetectionKit")
                T.giveItem(player, "Base.KnoxDetectionKit")
                T.setInfectionLevel(player, 0)
            end,

            setupWaitFrames = 120,

            run = function(player)
                T.assertEqual(T.getInfectionLevel(player), 0,
                    "player should not be infected")
                local item = T.findItem(player, "Base.KnoxDetectionKit")
                T.assertNotNil(item, "kit must be in inventory")
                sendClientCommand(player, "KnoxDetectionKit", "RunTest", { itemID = item:getID() })
            end,

            waitFrames = 360,

            assert = function(player)
                T.assertNil(T.findItem(player, "Base.KnoxDetectionKit"),
                    "kit should be consumed")
                local modData = player:getModData()
                T.assertEqual(modData.KnoxDetectionKit_infected, 0,
                    "ModData should record infected=0")
            end,
        },

        -- ── Test 7: instant results with WaitHours=0 + ModData cleared ───────
        {
            name = "KnoxDetectionKit: instant results when WaitHours=0",

            sandbox = {
                ["KnoxDetectionKit.WaitMinutes"] = 0,
            },

            setup = function(player)
                T.removeItems(player, "Base.KnoxDetectionKit")
                T.giveItem(player, "Base.KnoxDetectionKit")
                T.setInfectionLevel(player, 50)
            end,

            setupWaitFrames = 120,

            run = function(player)
                local item = T.findItem(player, "Base.KnoxDetectionKit")
                T.assertNotNil(item, "kit must be in inventory")
                sendClientCommand(player, "KnoxDetectionKit", "RunTest", { itemID = item:getID() })
            end,

            waitFrames = 360,

            assert = function(player)
                T.assertNil(T.findItem(player, "Base.KnoxDetectionKit"),
                    "kit should be consumed")
                -- With instant results, showResult fires immediately and clears ModData
                local modData = player:getModData()
                T.assertNil(modData.KnoxDetectionKit_resultReady,
                    "ModData resultReady should be cleared after instant result")
                T.assertNil(modData.KnoxDetectionKit_infected,
                    "ModData infected should be cleared after instant result")
            end,
        },

        -- ── Test 8: delayed results keep ModData until shown ──────────────────
        {
            name = "KnoxDetectionKit: delayed results preserve ModData",

            sandbox = {
                ["KnoxDetectionKit.WaitMinutes"] = 360,
            },

            setup = function(player)
                T.removeItems(player, "Base.KnoxDetectionKit")
                T.giveItem(player, "Base.KnoxDetectionKit")
                T.setInfectionLevel(player, 0)
            end,

            setupWaitFrames = 120,

            run = function(player)
                local item = T.findItem(player, "Base.KnoxDetectionKit")
                T.assertNotNil(item, "kit must be in inventory")
                sendClientCommand(player, "KnoxDetectionKit", "RunTest", { itemID = item:getID() })
            end,

            waitFrames = 360,

            assert = function(player)
                -- With 6-hour wait, result is NOT ready yet — ModData should persist
                local modData = player:getModData()
                T.assertNotNil(modData.KnoxDetectionKit_resultReady,
                    "ModData resultReady should persist while waiting")
            end,
        },

        -- ── Test 9: empty args handled gracefully ─────────────────────────────
        {
            name = "KnoxDetectionKit: empty args handled gracefully",

            setup = function(player)
                T.setInfectionLevel(player, 0)
            end,

            setupWaitFrames = 60,

            run = function(player)
                -- Send RunTest with no itemID — server should respond with error, not crash
                sendClientCommand(player, "KnoxDetectionKit", "RunTest", {})
            end,

            waitFrames = 360,

            assert = function(player)
                -- Server handled empty args without crashing. Reaching here = pass.
                T.assertTrue(true)
            end,
        },

    }
end)
