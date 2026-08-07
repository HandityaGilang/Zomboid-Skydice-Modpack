require "Moveables/ISMoveablesAction"

local complete = ISMoveablesAction.complete

function ISMoveablesAction:complete()
    complete(self)
	triggerEvent("OnMoveablesActionComplete", self)
end