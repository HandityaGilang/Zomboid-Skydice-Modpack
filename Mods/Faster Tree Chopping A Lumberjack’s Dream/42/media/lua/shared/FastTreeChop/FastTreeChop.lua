-- Faster Tree Chopping: A Lumberjack’s Dream
-- Build 42.x
-- Makes trees break in one proper chop by lowering tree health right before the axe hit is applied.
-- This patches the vanilla ISChopTreeAction instead of replacing the whole file, making it safer with updates.

require "TimedActions/ISChopTreeAction"

FastTreeChop = FastTreeChop or {}
FastTreeChop.VERSION = "1.0"

if ISChopTreeAction and not ISChopTreeAction.FastTreeChopPatched then
    ISChopTreeAction.FastTreeChopPatched = true

    local vanilla_animEvent = ISChopTreeAction.animEvent

    function ISChopTreeAction:animEvent(event, parameter)
        -- Only the real/server-side hit should change tree health.
        -- Client-side still gets the normal visual hit effects from vanilla code.
        if event == "ChopTree"
                and not isClient()
                and self.tree
                and self.tree:getObjectIndex() >= 0
                and self.axe then
            self.tree:setHealth(1)
        end

        return vanilla_animEvent(self, event, parameter)
    end
end
