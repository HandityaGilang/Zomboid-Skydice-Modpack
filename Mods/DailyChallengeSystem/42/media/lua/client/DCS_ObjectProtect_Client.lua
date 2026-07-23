if isServer() and not isClient() then return end

local function installDestroyGuard()
    if not (ISDestroyCursor and ISDestroyCursor.canDestroy) then return end
    if ISDestroyCursor.__dcsDestroyGuard then return end
    ISDestroyCursor.__dcsDestroyGuard = true

    local origCanDestroy = ISDestroyCursor.canDestroy
    function ISDestroyCursor:canDestroy(object)
        if object then
            local md = object:getModData()
            if md and md.IsDCSObject then
                return false
            end
        end
        return origCanDestroy(self, object)
    end
end

Events.OnGameStart.Add(installDestroyGuard)
