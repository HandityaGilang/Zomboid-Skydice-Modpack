local original_onNoteAdded = ISWorldMapSymbolTool_AddNote.onNoteAdded
local original_addSymbol = ISWorldMapSymbolTool_AddSymbol.addSymbol

local function shareNewestElement(symbolsAPI, countBefore)
    local countAfter = symbolsAPI:getSymbolCount()
    
    if countAfter > countBefore then
        local lastSymbol = symbolsAPI:getSymbolByIndex(countAfter - 1)
        
        if lastSymbol then
            lastSymbol:setSharing({everyone = true})
            --print("Nouvel element partage !")
        end
    end
end

function ISWorldMapSymbolTool_AddNote:onNoteAdded(button, playerNum)
    local countBefore = self.symbolsAPI:getSymbolCount()
    original_onNoteAdded(self, button, playerNum)
    
    if button.internal == "OK" then
        shareNewestElement(self.symbolsAPI, countBefore)
    end
end

function ISWorldMapSymbolTool_AddSymbol:addSymbol(x, y)
    local countBefore = self.symbolsAPI:getSymbolCount()
    original_addSymbol(self, x, y)
    shareNewestElement(self.symbolsAPI, countBefore)
end