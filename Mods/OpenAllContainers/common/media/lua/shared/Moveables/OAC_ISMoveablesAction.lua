-- From "Open All Containers [B42]" mod -- Author = carlesturo

-- **************** MOVEABLES ACTION - OPEN ALL CONTAINERS ****************

local originalStart = ISMoveablesAction.start
function ISMoveablesAction:start(...)
    if self.mode == "scrap" then
        OAC_isMoveableAction = true
    end
    originalStart(self, ...)
end

local originalStop = ISMoveablesAction.stop
function ISMoveablesAction:stop(...)
    if self.mode == "scrap" then
        OAC_isMoveableAction = false
    end
    originalStop(self, ...)
end

local originalComplete = ISMoveablesAction.complete
function ISMoveablesAction:complete(...)
    local result = originalComplete(self, ...)
    if self.mode == "scrap" then
        OAC_isMoveableAction = false
    end
    return result
end