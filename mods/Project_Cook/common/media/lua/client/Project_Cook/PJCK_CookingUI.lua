require "Project_Cook/PJCK_Window"
require "Project_Cook/PJCK_CookingEligibility"
PJCK_CookingUI = {}
PJCK_CookingUI.players = {}
-- print("Reload Lua")

function PJCK_CookingUI.GetWindowInstance(playerNum, windowKey)
    windowKey = windowKey or "CookingWindow"
    local playerData = PJCK_CookingUI.players[playerNum]
    if playerData and playerData.windows and playerData.windows[windowKey] then
        return playerData.windows[windowKey].instance
    end
    return nil
end

function PJCK_CookingUI.IsWindowOpen(playerNum, windowKey)
    return PJCK_CookingUI.GetWindowInstance(playerNum, windowKey) ~= nil
end
-- ----------------------------------------------------------------------------------------------------- --
-- SideBar
-- ----------------------------------------------------------------------------------------------------- --

-- Keep Project Cook's ISEquippedItem patch idempotent. This prevents nested wrappers when Lua is reloaded
-- and makes the patch safer when other mods wrap the same vanilla methods.
local PJCK_SidebarPatch = PJCK_SidebarPatch or {}

local function getTextureWidth()
    local size = getCore():getOptionSidebarSize()
    if size == 6 then
        size = getCore():getOptionFontSizeReal() - 1
    end

    local textureWidth = 48
    if size == 2 then
        textureWidth = 64
    elseif size == 3 then
        textureWidth = 80
    elseif size == 4 then
        textureWidth = 96
    elseif size == 5 then
        textureWidth = 128
    end

    return textureWidth
end

local function isCurrentEquippedItemPanel(panel)
    if not panel or not panel.playerNum then
        return false
    end

    local playerData = getPlayerData(panel.playerNum)
    if playerData and playerData.equipped and playerData.equipped ~= panel then
        return false
    end

    return true
end

function PJCK_SidebarPatch.updatePopupGeometry(panel)
    if not panel or not panel.craftingPopup or not panel.craftingBtn then
        return
    end

    local textureWidth = getTextureWidth()
    local textureHeight = textureWidth * 0.75

    -- Keep the popup aligned with the vanilla crafting button even after resolution/UI-size changes.
    panel.craftingPopup:setX(panel:getAbsoluteX() + panel.craftingBtn:getX())
    panel.craftingPopup:setY(panel:getAbsoluteY() + panel.craftingBtn:getY())
    panel.craftingPopup:setWidth(textureWidth * 2)
    panel.craftingPopup:setHeight(textureHeight)
    panel.craftingPopup.TEXTURE_WIDTH = textureWidth
    panel.craftingPopup.TEXTURE_HEIGHT = textureHeight
    panel.craftingPopup.cookingIcon = getTexture("media/ui/Sidebar/" .. textureWidth .. "/Cooking_Off_" .. textureWidth .. ".png")
    panel.craftingPopup.cookingIconOn = getTexture("media/ui/Sidebar/" .. textureWidth .. "/Cooking_On_" .. textureWidth .. ".png")
end

function PJCK_SidebarPatch.ensurePopup(panel)
    if not panel or not panel.chr or panel.chr:getPlayerNum() ~= 0 or not panel.craftingBtn then
        return
    end

    if not isCurrentEquippedItemPanel(panel) then
        return
    end

    if not panel.craftingPopup then
        local textureWidth = getTextureWidth()
        local textureHeight = textureWidth * 0.75
        local absX = panel:getAbsoluteX() + panel.craftingBtn:getX()
        local absY = panel:getAbsoluteY() + panel.craftingBtn:getY()

        panel.craftingPopup = ISCraftingPopup:new(absX, absY, textureWidth * 2, textureHeight, panel.chr)
        panel.craftingPopup.owner = panel
        panel.craftingPopup:addToUIManager()
        panel.craftingPopup:setVisible(false)
    end

    PJCK_SidebarPatch.updatePopupGeometry(panel)
end

function PJCK_SidebarPatch.updatePopupVisibility(panel)
    if not panel or not panel.craftingBtn or not panel.craftingPopup then
        return
    end

    if not isCurrentEquippedItemPanel(panel) then
        return
    end

    local isCookingPanelOpen = PJCK_CookingUI.IsWindowOpen(panel.chr:getPlayerNum())
    local showPopup = false

    if panel.craftingBtn:isMouseOver() then
        showPopup = true
    elseif panel.craftingPopup:isMouseOver() then
        showPopup = true
    elseif isCookingPanelOpen then
        showPopup = true
    end

    if "Tutorial" == getCore():getGameMode() then
        showPopup = false
    end

    panel.craftingPopup:setVisible(showPopup)

    if showPopup then
        panel.craftingPopup:bringToTop()
    elseif panel.craftingPopup.tooltip then
        panel.craftingPopup:hideTooltip()
    end
end


local function PJCK_PatchISEntityUIReadIni()
    -- Project Cook calls the vanilla ISEquippedItem prerender method, which in turn can trigger
    -- ISEntityUI.ReadIni() on the first UI frame. If entityLayout.ini contains malformed or
    -- orphaned entries, the vanilla parser can throw before the sidebar finishes rendering.
    if not ISEntityUI then
        pcall(require, "Entity/ISEntityUI")
    end

    if not ISEntityUI or ISEntityUI.PJCK_SafeReadIniApplied then
        return
    end

    ISEntityUI.PJCK_SafeReadIniApplied = true
    ISEntityUI.PJCK_original_ReadIni = ISEntityUI.ReadIni

    function ISEntityUI.ReadIni()
        ISEntityUI.players = {}

        if getCore():getGameMode() == "Tutorial" then
            return
        end

        local reader = getFileReader("entityLayout.ini", true)
        if not reader then
            return
        end

        local currentPlayer = nil
        local currentWindowKey = nil

        -- Parse the vanilla layout file defensively. Valid entries are preserved, while malformed
        -- entries are ignored instead of breaking the whole left-hand equipped-item sidebar.
        local ok, err = pcall(function()
            while true do
                local line = reader:readLine()
                if line == nil then
                    break
                end

                line = string.trim(line)
                if line == "" then
                    -- Ignore blank lines.
                elseif luautils.stringStarts(line, "player") then
                    local values = string.split(line, ":")
                    currentPlayer = tonumber(values[2])
                    currentWindowKey = nil

                    if currentPlayer ~= nil then
                        ISEntityUI.players[currentPlayer] = ISEntityUI.players[currentPlayer] or {}
                        ISEntityUI.players[currentPlayer].windows = ISEntityUI.players[currentPlayer].windows or {}
                    end
                elseif luautils.stringStarts(line, "windowKey") then
                    local values = string.split(line, ":")
                    currentWindowKey = values[2]

                    if currentPlayer ~= nil and currentWindowKey and currentWindowKey ~= "" then
                        ISEntityUI.players[currentPlayer] = ISEntityUI.players[currentPlayer] or {}
                        ISEntityUI.players[currentPlayer].windows = ISEntityUI.players[currentPlayer].windows or {}
                        ISEntityUI.players[currentPlayer].windows[currentWindowKey] = ISEntityUI.players[currentPlayer].windows[currentWindowKey] or {}
                    else
                        currentWindowKey = nil
                    end
                else
                    local values = string.split(line, "=")
                    local key = values[1]
                    local value = values[2]
                    local windowLayout = nil

                    if currentPlayer ~= nil and currentWindowKey ~= nil and ISEntityUI.players[currentPlayer] and ISEntityUI.players[currentPlayer].windows then
                        windowLayout = ISEntityUI.players[currentPlayer].windows[currentWindowKey]
                    end

                    if windowLayout then
                        if key == "x" then windowLayout.x = tonumber(value) end
                        if key == "y" then windowLayout.y = tonumber(value) end
                        if key == "width" then windowLayout.width = tonumber(value) end
                        if key == "height" then windowLayout.height = tonumber(value) end
                        if key == "locked" then windowLayout.locked = (value == "true" and true or false) end
                    end
                end
            end
        end)

        pcall(function()
            reader:close()
        end)

        if not ok then
            -- Keep a valid table so vanilla callers can continue rendering even if the layout file
            -- contains unexpected data.
            ISEntityUI.players = ISEntityUI.players or {}
            print("Project Cook: ignored invalid entityLayout.ini data: " .. tostring(err))
        end
    end
end

local function PJCK_PatchISEquippedItem()
    PJCK_PatchISEntityUIReadIni()

    -- Delay the ISEquippedItem hook until game start. On some Linux MP clients, wrapping this class
    -- while the UI is still booting can leave the vanilla sidebar partially initialised.
    if not ISEquippedItem then
        require "ISUI/ISEquippedItem"
    end

    if not ISEquippedItem or ISEquippedItem.PJCK_ProjectCookPatchApplied then
        return
    end

    ISEquippedItem.PJCK_ProjectCookPatchApplied = true
    ISEquippedItem.PJCK_original_initialise = ISEquippedItem.initialise
    ISEquippedItem.PJCK_original_prerender = ISEquippedItem.prerender
    ISEquippedItem.PJCK_original_removeFromUIManager = ISEquippedItem.removeFromUIManager
    ISEquippedItem.PJCK_original_checkSidebarSizeOption = ISEquippedItem.checkSidebarSizeOption

    function ISEquippedItem:initialise()
        if ISEquippedItem.PJCK_original_initialise then
            ISEquippedItem.PJCK_original_initialise(self)
        end
        PJCK_SidebarPatch.ensurePopup(self)
    end

    function ISEquippedItem:prerender()
        if ISEquippedItem.PJCK_original_prerender then
            ISEquippedItem.PJCK_original_prerender(self)
        end

        -- The vanilla method can rebuild the sidebar when the size option changes; do not touch stale panels.
        if not isCurrentEquippedItemPanel(self) then
            return
        end

        PJCK_SidebarPatch.ensurePopup(self)
        PJCK_SidebarPatch.updatePopupVisibility(self)
    end

    function ISEquippedItem:removeFromUIManager()
        if self.craftingPopup then
            self.craftingPopup:hideTooltip()
            self.craftingPopup:removeFromUIManager()
            self.craftingPopup = nil
        end

        if ISEquippedItem.PJCK_original_removeFromUIManager then
            ISEquippedItem.PJCK_original_removeFromUIManager(self)
        else
            -- Match the vanilla cleanup path if the original method is unavailable for any reason.
            if self.movablePopup then
                self.movablePopup:removeFromUIManager()
            end
            if self.mapPopup then
                self.mapPopup:removeFromUIManager()
            end
            ISPanel.removeFromUIManager(self)
        end
    end

    function ISEquippedItem:checkSidebarSizeOption()
        if ISEquippedItem.PJCK_original_checkSidebarSizeOption then
            ISEquippedItem.PJCK_original_checkSidebarSizeOption(self)
        end

        if isCurrentEquippedItemPanel(self) then
            PJCK_SidebarPatch.updatePopupGeometry(self)
        end
    end
end

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(PJCK_PatchISEquippedItem)
end

-- ----------------------------------------------------------------------------------------------------- --
-- Popup Button
-- ----------------------------------------------------------------------------------------------------- --

ISCraftingPopup = ISPanel:derive("ISCraftingPopup")
function ISCraftingPopup:initialise()
    ISPanel.initialise(self)
end

function ISCraftingPopup:new(x, y, width, height, chr)
    local TEXTURE_WIDTH = getTextureWidth()
    local TEXTURE_HEIGHT = TEXTURE_WIDTH * 0.75
    
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.chr = chr
    o.playerNum = chr:getPlayerNum()
    o.TEXTURE_WIDTH = TEXTURE_WIDTH
    o.TEXTURE_HEIGHT = TEXTURE_HEIGHT
    o.backgroundColor = {r=0, g=0, b=0, a=0}
    o.borderColor = {r=0, g=0, b=0, a=0}

    o.cookingIcon = getTexture("media/ui/Sidebar/" .. TEXTURE_WIDTH .."/Cooking_Off_" .. TEXTURE_WIDTH .. ".png")
    o.cookingIconOn = getTexture("media/ui/Sidebar/" .. TEXTURE_WIDTH .."/Cooking_On_" .. TEXTURE_WIDTH .. ".png")
    
    return o
end

function ISCraftingPopup:onMouseMove(dx, dy)
    local index = math.floor(self:getMouseX() / self.TEXTURE_WIDTH)
    if index >= 0 and index < 2 then
        local texts = { getText("IGUI_CraftingTooltip"), getText("IGUI_PJCK_CookingTooltip") }
        local text = texts[index + 1]
        
        if text then
            self:showTooltip(text)
        end
    else
        self:hideTooltip()
    end
    return true
end

function ISCraftingPopup:onMouseDown(x, y)
    self:hideTooltip()
    
    local index = math.floor(x / self.TEXTURE_WIDTH)
    
    if index == 0 then
        if ISEntityUI.players[self.playerNum] and ISEntityUI.players[self.playerNum].windows["HandcraftWindow"] and ISEntityUI.players[self.playerNum].windows["HandcraftWindow"].instance then
            ISEntityUI.players[self.playerNum].windows["HandcraftWindow"].instance:close()
        else
            if isKeyDown(Keyboard.KEY_LMENU) then
                ISEntityUI.OpenHandcraftWindow(self.chr, nil, "*")
            else
                ISEntityUI.OpenHandcraftWindow(self.chr, nil)
            end
        end
    elseif index == 1 then
        if PJCK_CookingUI.IsWindowOpen(self.playerNum) then
            local window = PJCK_CookingUI.GetWindowInstance(self.playerNum)
            window:onCloseClick()
        else
            if PJCK_CookingUI and PJCK_CookingUI.OnOpenPanel then
                PJCK_CookingUI.OnOpenPanel(self.chr)
            end
        end
    end
    
    return true
end

function ISCraftingPopup:onMouseMoveOutside(dx, dy)
    self:hideTooltip()
    return true
end

function ISCraftingPopup:showTooltip(text)
    if not text then return end

    if not self.tooltip then
        self.tooltip = ISToolTip:new()
        self.tooltip:initialise()
        self.tooltip:instantiate()
        self.tooltip:setOwner(self)
    end

    self.tooltip:setName(text)
    self.tooltip:setVisible(true)
    self.tooltip:addToUIManager()
    self.tooltip:bringToTop()
end

function ISCraftingPopup:hideTooltip()
    if self.tooltip and self.tooltip:isVisible() then
        self.tooltip:removeFromUIManager()
        self.tooltip:setVisible(false)
    end
end

function ISCraftingPopup:render()
    local cookingTex = self.cookingIcon
    if PJCK_CookingUI.IsWindowOpen(self.playerNum) then
        cookingTex = self.cookingIconOn
    end

    -- Skip drawing if a texture failed to load instead of breaking the whole sidebar render pass.
    if cookingTex then
        self:drawTexture(cookingTex, self.TEXTURE_WIDTH, 0, 1, 1, 1, 1)
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- ContextMenu
-- ----------------------------------------------------------------------------------------------------- --

local function onPJCKContextMenu(playerID, context, items)
    if not items or #items < 1 then
        return
    end
    
    local player = getSpecificPlayer(playerID)
    if not player then return end

    local baseItem = items[1]
    if not baseItem then return end
    
    if not instanceof(baseItem, "InventoryItem") then
        if baseItem.items and #baseItem.items > 0 then
            baseItem = baseItem.items[1]
        else
            return
        end
    end

    local containerList = ISInventoryPaneContextMenu.getContainers(player)
    local evorecipes = RecipeManager.getEvolvedRecipe(baseItem, player, containerList, false)
    local hasCookingEntry = PJCK_CookingEligibility.shouldShowContextOption(baseItem, player, containerList)

    if hasCookingEntry then
        local tex = getTexture("media/ui/Project_Cook/ICON/Icon_Option.png")
        local option = context:addOption(getText("IGUI_PJCK_CookingTooltip"), player, PJCK_CookingUI.OnOpenPanel, baseItem)
        option.iconTexture = tex
    end
end

Events.OnPreFillInventoryObjectContextMenu.Add(onPJCKContextMenu)


-- ----------------------------------------------------------------------------------------------------- --
-- Panel Manager
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_CookingUI.OnCloseWindow(window)
    local playerNum = window.player:getPlayerNum()
    local windowKey = "CookingWindow"
    
    if window and playerNum ~= nil and PJCK_CookingUI.players[playerNum] and PJCK_CookingUI.players[playerNum].windows[windowKey] then
        if PJCK_CookingUI.players[playerNum].windows[windowKey].instance == window then
            PJCK_CookingUI.players[playerNum].windows[windowKey].x = window:getX()
            PJCK_CookingUI.players[playerNum].windows[windowKey].y = window:getY()

            PJCK_CookingUI.players[playerNum].windows[windowKey].instance = nil
            PJCK_CookingUI.players[playerNum].windows[windowKey].playerObj = nil
        end
    end
end

function PJCK_CookingUI.OnOpenPanel(player, baseItem)
    local playerNum = player:getPlayerNum()
    local windowKey = "CookingWindow"

    if PJCK_CookingUI.IsWindowOpen(playerNum) then
        local existingPanel = PJCK_CookingUI.GetWindowInstance(playerNum)
        existingPanel:setVisible(true)
        existingPanel:bringToTop()

        if baseItem and existingPanel.EvoPanel then
            local containerList = ISInventoryPaneContextMenu.getContainers(player)
            local evorecipes = RecipeManager.getEvolvedRecipe(baseItem, player, containerList, false)

            if evorecipes and evorecipes:size() > 0 then
                existingPanel.EvoPanel:setBaseItem(baseItem)
            end
        end
        return
    end

    local x = getMouseX() + 10
    local y = getMouseY() + 10
    local adjustPos = true

    if PJCK_CookingUI.players[playerNum] and PJCK_CookingUI.players[playerNum].windows[windowKey] then
        local windowData = PJCK_CookingUI.players[playerNum].windows[windowKey]
        if windowData.x and windowData.y then
            x = windowData.x
            y = windowData.y
            adjustPos = false
        end
    else
        PJCK_CookingUI.players[playerNum] = PJCK_CookingUI.players[playerNum] or {}
        PJCK_CookingUI.players[playerNum].windows = PJCK_CookingUI.players[playerNum].windows or {}
        PJCK_CookingUI.players[playerNum].windows[windowKey] = {}
    end

    -- Open Window
    local window = PJCK_Window:new(0, 0, 50, 50, player)
    window:initialise()
    window:instantiate()

    window:setX(x)
    window:setY(y)
    window:setVisible(true)

    window:calculateLayout(0,0)
    window:addToUIManager()

    PJCK_CookingUI.players[playerNum].windows[windowKey].instance = window
    PJCK_CookingUI.players[playerNum].windows[windowKey].playerObj = player

    if baseItem and window.EvoPanel then
        local containerList = ISInventoryPaneContextMenu.getContainers(player)
        local evorecipes = RecipeManager.getEvolvedRecipe(baseItem, player, containerList, false)
        if evorecipes and evorecipes:size() > 0 then
            window.EvoPanel:setBaseItem(baseItem)
        end
    end

    if adjustPos then
        local leftBottomY = getCore():getScreenHeight() - window:getHeight()
        window:setX(0)
        window:setY(leftBottomY)
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Player Death Handler
-- ----------------------------------------------------------------------------------------------------- --
function PJCK_CookingUI.onPlayerDeath(player)
    local playerNum = player:getPlayerNum()
    
    if PJCK_CookingUI.IsWindowOpen(playerNum) then
        local window = PJCK_CookingUI.GetWindowInstance(playerNum)
        if window then
            window:onCloseClick()
        end
    end
end

Events.OnPlayerDeath.Add(PJCK_CookingUI.onPlayerDeath)

return PJCK_CookingUI
