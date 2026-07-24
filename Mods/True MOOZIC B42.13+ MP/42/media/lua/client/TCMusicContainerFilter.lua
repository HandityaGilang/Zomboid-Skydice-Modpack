local function shouldHideContainer(container)
    if not container then
        return false
    end

    local ctype = container.getType and container:getType() or nil
    if ctype == "tcmusic" or ctype == "tcmusicboombox" or ctype == "tcmusicvinyl" then
        return true
    end

    local parent = container.getParent and container:getParent() or nil
    if parent and instanceof(parent, "InventoryItem") then
        local fullType = parent.getFullType and parent:getFullType() or nil
        if fullType and (
            (TCMusic and TCMusic.ItemMusicPlayer and TCMusic.ItemMusicPlayer[fullType]) or
            (TCMusic and TCMusic.WorldMusicPlayer and TCMusic.WorldMusicPlayer[fullType]) or
            (TCMusic and TCMusic.WalkmanPlayer and TCMusic.WalkmanPlayer[fullType])
        ) then
            return true
        end
    end

    return false
end

local function hookInventoryPage()
    if not ISInventoryPage or not ISInventoryPage.addContainerButton then
        return false
    end

    if ISInventoryPage._tcmusicContainerFilter then
        return true
    end

    ISInventoryPage._tcmusicContainerFilter = true
    local originalAddContainerButton = ISInventoryPage.addContainerButton

    ISInventoryPage.addContainerButton = function(self, container, texture, name, tooltip)
        local button = originalAddContainerButton(self, container, texture, name, tooltip)
        if shouldHideContainer(container) and button then
            self.containerButtonPanel:removeChild(button)
            self.backpacks[#self.backpacks] = nil
            self.buttonPool = self.buttonPool or {}
            table.insert(self.buttonPool, 1, button)
        end
        return button
    end

    return true
end

local function applyHooks()
    hookInventoryPage()
end

applyHooks()
if Events and Events.OnGameBoot then
    Events.OnGameBoot.Add(applyHooks)
end
