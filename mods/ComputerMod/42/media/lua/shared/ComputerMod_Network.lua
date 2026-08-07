ComputerModNetwork = ComputerModNetwork or {}

ComputerModNetwork.storeName = "ComputerModNetworkDB"

function ComputerModNetwork.getStore()
    local store = ModData.getOrCreate(ComputerModNetwork.storeName)
    if store.internetDisabled == nil then
        store.internetDisabled = false
    end
    if store.terminals == nil then
        store.terminals = {}
    end
    return store
end

function ComputerModNetwork.isInternetEnabled()
    if isClient and isClient() and ComputerModNetwork.clientInternetEnabled ~= nil then
        return ComputerModNetwork.clientInternetEnabled == true
    end
    local store = ComputerModNetwork.getStore()
    return store.internetDisabled ~= true
end

function ComputerModNetwork.setInternetEnabled(enabled)
    local store = ComputerModNetwork.getStore()
    store.internetDisabled = enabled ~= true
    if ModData and ModData.transmit then
        ModData.transmit(ComputerModNetwork.storeName)
    end
    return ComputerModNetwork.isInternetEnabled()
end

function ComputerModNetwork.getTerminalStore(terminalId)
    if not terminalId then return nil end
    local store = ComputerModNetwork.getStore()
    store.terminals = store.terminals or {}
    store.terminals[terminalId] = store.terminals[terminalId] or {}
    return store.terminals[terminalId]
end

function ComputerModNetwork.setActiveTerminal(terminalId)
    local store = ComputerModNetwork.getStore()
    store.activeTerminalId = terminalId
    if ModData and ModData.transmit then
        ModData.transmit(ComputerModNetwork.storeName)
    end
end
