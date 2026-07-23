-- RGMNeatXPCompat: NeatUI XP Drop compatibility patch.
--
-- In PZ B42 multiplayer, Events.AddXP does NOT fire on the client —
-- XP is awarded server-side and sent over the network.  NeatUI's drop
-- display and icon-switching both rely on Events.AddXP, so in MP the
-- bar icon is stuck and no floating drops appear.
--
-- Fix: patch NeatXPBar.update() to compare each tracked skill's XP
-- against the previous frame.  When XP increases, we switch the icon
-- and insert a floating drop entry — identical to what Events.AddXP
-- would have done.  This works in both SP and MP.

local function patchBar(bar)
    if bar._rgmPatched then return end
    bar._rgmPatched = true

    local _lastXP = {}   -- skillType → float, previous-frame XP snapshot
    local _ready  = false -- skip first frame (init snapshot, no drops)

    local _origUpdate = bar.update

    function bar:update()
        _origUpdate(self)

        local player = self.player
        if not player then return end

        local xpObj = type(player.getXp) == "function" and player:getXp()
        if not xpObj then return end

        for _, skillType in ipairs(self.skillOrder) do
            if self:isTracked(skillType) then
                local perk = self:getPerk(skillType)
                if perk then
                    local ok, cur = pcall(function() return xpObj:getXP(perk) end)
                    if ok and cur then
                        local prev = _lastXP[skillType]
                        if _ready and prev and cur > prev then
                            local delta = cur - prev
                            self:setSkill(skillType)
                            if not self.collapsed then
                                local merged = false
                                for i = #self.drops, 1, -1 do
                                    local d = self.drops[i]
                                    if d.skill == skillType and d.age < 0.15 then
                                        d.amount = d.amount + delta
                                        merged = true
                                        break
                                    end
                                end
                                if not merged then
                                    table.insert(self.drops, {
                                        skill  = skillType,
                                        name   = perk:getName(),
                                        amount = delta,
                                        age    = 0,
                                    })
                                end
                            end
                        end
                        _lastXP[skillType] = cur
                    end
                end
            end
        end
        _ready = true
    end

    print("[RGM NeatXP] bar patched via update() polling")
end

-- Patch after OnCreatePlayer, deferred one tick so NeatUI creates its bar first.
Events.OnCreatePlayer.Add(function()
    local function deferredPatch()
        if NeatXPDrops and NeatXPDrops.bar then
            patchBar(NeatXPDrops.bar)
        end
        Events.OnTick.Remove(deferredPatch)
    end
    Events.OnTick.Add(deferredPatch)
end)
