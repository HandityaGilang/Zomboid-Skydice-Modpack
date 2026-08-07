local paperContext = {}

local activeModIDs = getActivatedMods()
if activeModIDs:contains("DRAW_ON_MAP") then
    require "DrawOnMap/WorldMapSymbolTool_FreeHandEraser"
    require "DrawOnMap/Patches/IsWorldMapSymbols_patch_add_spline_tool"
    require "DrawOnMap/Patches/ISMap_patch_create_free_hand_ui"

    paperContext.paperFreeHand = FreeHandUI:derive("paperContext.PaperFreeHand")

    function paperContext.paperFreeHand:prerender()
        local ui = self.symbolsUI
        self:setX(ui:getX())
        self:setY(ui:getY()+ui:getHeight()+8)
        FreeHandUI.prerender(self)
    end
end

local paperAPI = require "zomboidPaperAPI_define"

paperContext.paperUI = ISMap:derive("paperContext.paperUI")
paperContext.paperWrapper = ISMapWrapper:derive("paperContext.paperWrapper")
paperContext.paperSymbols = ISWorldMapSymbols:derive("paperContext.paperSymbols")


function paperContext.paperSymbols:renderSymbol(symbol, x, y) end

function paperContext.paperWrapper:close()
    if self.mapUI.symbolsUI then self.mapUI.symbolsUI:removeFromUIManager() end
    if self.mapUI.freeHandUI then self.mapUI.freeHandUI:removeFromUIManager() end
    ISMapWrapper.close(self)
end


function paperContext.paperSymbols:prerender()
    local ui = self.mapUI.wrap
    self:setX(ui:getX()+ui:getWidth()+8)
    self:setY(ui:getY())
    ISWorldMapSymbols.prerender(self)
end


function paperContext.paperUI:render()
    if self.symbolsUI:isVisible() then

        if self:isMouseOver() then
            local sym = self.symbolsUI.selectedSymbol
            if sym then
                local scale = ISMap.SCALE * self.mapAPI:getWorldScale()
                local symW = sym.image:getWidth() / 2 * scale
                local symH = sym.image:getHeight() / 2 * scale
                self:drawTextureScaled(sym.image, self:getMouseX()-symW, self:getMouseY()-symH,
                        sym.image:getWidth() * scale, sym.image:getHeight() * scale,
                        1, sym.textureColor.r, sym.textureColor.g, sym.textureColor.b)
            end
        end
    end
    ISMap.render(self)
end


local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
function paperContext.paperUI:createChildren()

    local symbolsWidth = paperContext.paperSymbols.RequiredWidth()
    self.symbolsUI = paperContext.paperSymbols:new(self.width - 10 - symbolsWidth, 10, symbolsWidth, 200, self)
    --self:addChild(self.symbolsUI)
    self.symbolsUI:addToUIManager()
    self.symbolsUI:setVisible(false)

    if activeModIDs:contains("DRAW_ON_MAP") then
        self.freeHandUI = paperContext.paperFreeHand:new(self.symbolsUI:getX(), self.symbolsUI:getY()+self.symbolsUI:getHeight()+8, self.symbolsUI:getWidth(), 150, self.symbolsUI)
        self.freeHandUI:setAnchorLeft(true)
        self.freeHandUI:setAnchorRight(false)
        self.freeHandUI:init()
        self.freeHandUI:setVisible(false)
        self.freeHandUI:addToUIManager()
    end

    local buttonHgt = FONT_HGT_SMALL + 6
    local buttonPadBottom = 4
    local buttonY = self.height - buttonPadBottom - buttonHgt

    self.ok = ISButton:new(10, buttonY, 100, buttonHgt, getText("UI_Close"), self, ISMap.onButtonClick)
    self.ok.internal = "OK"
    self.ok:initialise()
    self.ok:instantiate()
    self.ok.borderColor = {r=1, g=1, b=1, a=0.4}
    self:addChild(self.ok)

    self.editSymbolsBtn = ISButton:new(self.ok:getRight() + 10, buttonY, 150, buttonHgt, getText("IGUI_Map_EditMarkings"), self, ISMap.onButtonClick)
    self.editSymbolsBtn.internal = "SYMBOLS"
    self.editSymbolsBtn:initialise()
    self.editSymbolsBtn:instantiate()
    self.editSymbolsBtn.borderColor = {r=1, g=1, b=1, a=0.4}
    self:addChild(self.editSymbolsBtn)

    self.scaleBtn = ISButton:new(self.editSymbolsBtn:getRight() + 10, buttonY, 50, buttonHgt, getText("IGUI_Map_Scale"), self, ISMap.onButtonClick)
    self.scaleBtn.internal = "SCALE"
    self.scaleBtn:initialise()
    self.scaleBtn:instantiate()
    self.scaleBtn.borderColor = {r=1, g=1, b=1, a=0.4}
    self:addChild(self.scaleBtn)

    -- Joypad only
    self.placeSymbBtn = ISButton:new(self.editSymbolsBtn:getRight() + 10, buttonY, 150, buttonHgt, getText("IGUI_Map_PlaceSymbol"), self, ISMap.onButtonClick)
    self.placeSymbBtn.internal = "PLACESYMBOL"
    self.placeSymbBtn:initialise()
    self.placeSymbBtn:instantiate()
    self.placeSymbBtn.borderColor = {r=1, g=1, b=1, a=0.4}
    self.placeSymbBtn:setVisible(false)
    self:addChild(self.placeSymbBtn)

    self.pageLabel = ISLabel:new(self:getWidth()-35, self.ok.y-20, 16, self.paperPage.."/"..self.maxPage, 0, 0, 0, 0.8, UIFont.Small, true)
    self.pageLabel:initialise()
    self.pageLabel:instantiate()
    self:addChild(self.pageLabel)

    self.nextPage = ISButton:new(self:getWidth()-35, self.ok.y, 25, self.ok.height, ">", self, paperContext.onNextPage)
    self.nextPage:initialise()
    self.nextPage:instantiate()
    self.nextPage.borderColor = {r=1, g=1, b=1, a=0.4}
    self:addChild(self.nextPage)

    self.prevPage = ISButton:new(self.nextPage.x-29, self.ok.y, 25, self.ok.height, "<", self, paperContext.onPrevPage)
    self.prevPage:initialise()
    self.prevPage:instantiate()
    self.prevPage.borderColor = {r=1, g=1, b=1, a=0.4}
    self:addChild(self.prevPage)
end



function paperContext:onPageSelect(pageChange)
    local map = self.mapObj
    local maxPage = map:getModData()["paperAPI_paperPageMax"] or 1
    local page = math.min(maxPage, math.max(1,(map:getModData()["paperAPI_paperPage"] or 1) + (pageChange or 0)))

    local texPath = "common/media/textures/zomboidPaper/"..map:getType()..page..".png"
    ---@type UIWorldMapV1
    local mapAPI = self.javaObject:getAPIv1()
    ---@type WorldMapStyleV1
    local styleAPI = mapAPI:getStyleAPI()
    ---@type WorldMapStyleV1.WorldMapTextureStyleLayerV1
    local layer = styleAPI:getLayerByName("paperAPI")
    layer:removeAllTexture()
    layer:addTexture(0, texPath)

    local symbolsAPI = mapAPI:getSymbolsAPI()
    paperContext.loadSymbols(map, symbolsAPI, page)

    map:getModData()["paperAPI_paperPage"] = page
    paperContext.updatePageButtons(self)
end


function paperContext:updatePageButtons()
    local map = self.mapObj
    local page = map:getModData()["paperAPI_paperPage"] or 1
    local maxPage = map:getModData()["paperAPI_paperPageMax"] or 1

    self.prevPage:setVisible(maxPage>1)
    self.nextPage:setVisible(maxPage>1)
    self.pageLabel:setVisible(maxPage>1)

    self.prevPage.enable = not (page == 1)
    self.nextPage.enable = not (page == maxPage)
    self.pageLabel:setName(page.."/"..maxPage)
end
function paperContext:onNextPage() paperContext.onPageSelect(self,1) end
function paperContext:onPrevPage() paperContext.onPageSelect(self,-1) end


---@param symbolsAPI WorldMapSymbolsV1
function paperContext.loadSymbols(map, symbolsAPI, newPage, noSave)

    local currentPage = map:getModData()["paperAPI_paperPage"] or 1
    map:getModData()["paperAPI_symbolsOnPage"] = map:getModData()["paperAPI_symbolsOnPage"] or {}

    if noSave~=true then
        map:getModData()["paperAPI_symbolsOnPage"][currentPage] = {}

        for i=0, symbolsAPI:getSymbolCount()-1 do
            ---@type WorldMapSymbolsV1.WorldMapBaseSymbolV1|WorldMapSymbolsV1.WorldMapTextSymbolV1|WorldMapSymbolsV1.WorldMapTextureSymbolV1
            local symbol = symbolsAPI:getSymbolByIndex(i)

            local symbolAdded = {
                r = symbol:getRed(),
                g = symbol:getGreen(),
                b = symbol:getBlue(),
                a = symbol:getAlpha(),
                x = symbol:getWorldX(),
                y = symbol:getWorldY()
            }

            if symbol:isTexture() then symbolAdded.symbolID = symbol:getSymbolID() end
            if symbol:isText() then symbolAdded.text = symbol:getTranslatedText() end

            table.insert(map:getModData()["paperAPI_symbolsOnPage"][currentPage], symbolAdded)
        end
    end

    if newPage then
        symbolsAPI:clear()
        local newPageSymbols = map:getModData()["paperAPI_symbolsOnPage"][newPage]
        if newPageSymbols then
            for _,symbol in ipairs(newPageSymbols) do

                local addedSymbol

                if symbol.symbolID then addedSymbol = symbolsAPI:addTexture(symbol.symbolID, symbol.x, symbol.y) end
                if symbol.text then addedSymbol = symbolsAPI:addTranslatedText(symbol.text, UIFont.Handwritten, symbol.x, symbol.y) end

                if addedSymbol then
                    addedSymbol:setRGBA(symbol.r, symbol.g, symbol.b, 1.0)
                    addedSymbol:setAnchor(0.5, 0.5)
                    addedSymbol:setScale(ISMap.SCALE)
                end
            end
        end
    end
end


function paperContext.onCheckPaper(map, player)

    if paperAPI.instance and paperAPI.instance:isVisible() then return end

    local playerObj = getSpecificPlayer(player)
    if luautils.haveToBeTransfered(playerObj, map) then
        local action = ISInventoryTransferAction:new(playerObj, map, map:getContainer(), playerObj:getInventory())
        action:setOnComplete(paperContext.onCheckPaper, map, player)
        ISTimedActionQueue.add(action)
        return
    end

    if JoypadState.players[player+1] then
        local inv = getPlayerInventory(player)
        local loot = getPlayerLoot(player)
        inv:setVisible(false)
        loot:setVisible(false)
    end

    local titleBarHgt = ISCollapsableWindow.TitleBarHeight()

    map:getModData()["paperAPI_paperPage"] = map:getModData()["paperAPI_paperPage"] or 1
    local paperPage = map:getModData()["paperAPI_paperPage"]
    local maxPage = map:getModData()["paperAPI_paperPageMax"] or 1

    local texPath = "common/media/textures/zomboidPaper/"..map:getType()..paperPage..".png"
    local texture = getTexture(texPath)
    if not texture then return end

    local paperX2, paperY2 = texture:getWidth()+10, texture:getHeight()+10+titleBarHgt
    local ratio = paperX2/paperY2
    local height = getPlayerScreenHeight(player)*0.66
    local width = (height * ratio)

    local centerX, centerY = (getPlayerScreenWidth(player)/2)-(width/2), (getPlayerScreenHeight(player)/2)-(height/2)

    local mapUI = paperContext.paperUI:new(centerX, centerY, width+40, height+40, map, player)
    mapUI.paperPage = paperPage
    mapUI.maxPage = maxPage
    mapUI:initialise()

    paperAPI.instance = mapUI

    local wrap = mapUI:wrapInCollapsableWindow(map:getName(), false, paperContext.paperWrapper)
    wrap:setInfo(getText("IGUI_Map_Info"))
    wrap:setWantKeyEvents(true)
    mapUI.wrap = wrap
    wrap.mapUI = mapUI

    wrap:setVisible(true)
    wrap:addToUIManager()
    wrap.infoButton:setVisible(false)

    ---@type UIWorldMapV1
    local mapAPI = mapUI.javaObject:getAPIv1()
    ---@type WorldMapStyleV1
    local styleAPI = mapAPI:getStyleAPI()

    --local symbolsAPI = mapAPI:getSymbolsAPI()
    --paperContext.loadSymbols(map, symbolsAPI, paperPage, true)

    local layer = styleAPI:newTextureLayer("paperAPI")
    layer:setMinZoom(0)
    layer:addFill(0, 255, 255, 255, 255)
    layer:addTexture(0, texPath)
    layer:setBoundsInSquares(10, 10, 10 + paperX2, 10 + paperY2)

    paperContext.updatePageButtons(mapUI)

    if JoypadState.players[player+1] then setJoypadFocus(player, mapUI) end
end



---@param context ISContextMenu
function paperContext.addInventoryItemContext(playerID, context, items)
    local playerObj = getSpecificPlayer(playerID)

    for _, v in ipairs(items) do

        ---@type InventoryItem
        local item = v
        local stack
        if not instanceof(v, "InventoryItem") then
            stack = v
            item = v.items[1]
        end

        local isPaper = paperAPI.isValid(item:getType())
        if isPaper then

            local readOption = context:getOptionFromName(getText("ContextMenu_CheckMap"))
            readOption.name = getText("ContextMenu_Read")
            readOption.onSelect = paperContext.onCheckPaper
            --context:addOption(getText("ContextMenu_CheckMap"), map, ISInventoryPaneContextMenu.onCheckMap, player)

            local renameOption = context:getOptionFromName(getText("ContextMenu_RenameMap"))
            renameOption.name = getText("ContextMenu_RenameBag")
            readOption.onSelect = paperContext.onCheckPaper
            --context:addOption(getText("ContextMenu_RenameMap"), map, ISInventoryPaneContextMenu.onRenameMap, player)
        end
        break
    end
end

Events.OnFillInventoryObjectContextMenu.Add(paperContext.addInventoryItemContext)