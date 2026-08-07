-- PK42HookUI.lua

local SU = require "Utils/PK42SharedUtils"

local function getSandboxCFG()
    local opts = SandboxVars.PK42
    return {
        ALLOW_PATCH = opts and opts.EnableButcherHookPatch ~= false,
        BUTCHER_LVL = opts and opts.ButcherCorpseUnlockLevel or 3,
    }
end

local function patchISButcherHookUI()

    require "ISUI/Animal/ISButcherHookUI"

    local cfg = getSandboxCFG()
    if cfg.ALLOW_PATCH == true then

        -- Helpers
        local FONT_HGT_SMALL    = getTextManager():getFontHeight(UIFont.NewSmall)
        local BUTTON_HGT        = FONT_HGT_SMALL + 6
        local UI_BORDER_SPACING = 10
        -- =========================================================================
        local UNLOCK_HOOK_LEVEL = math.min(cfg.BUTCHER_LVL + 1, 10)
        -- =========================================================================
        local function isHumanDeadBody(v)
            if not instanceof(v, "IsoDeadBody") then return false end
            local ok, isAnimal = pcall(function() return v:isAnimal() end)
            return not (ok and isAnimal)
        end
        
        local function hookHasPK42Corpse(hook)
            return hook and SU.hook_GetStatus(hook) ~= "Empty"
        end
        
        local function hookHasAnimal(hook)
            return hook and hook:getAnimal() ~= nil
        end

        local function pkGetAvailableBuckets(chr)
            local result = {}
            local items  = chr:getInventory():getItems()
            for i = 0, items:size() - 1 do
                local item = items:get(i)
                local fc   = item.getFluidContainer and item:getFluidContainer()
                if fc and not fc:isFull() then
                    if fc:isEmpty() then
                        table.insert(result, item)
                    else
                        local primary = fc:getPrimaryFluid()
                        if primary then
                            local name = primary:getFluidTypeString()
                            if name == "HumanBlood" or name == "ZombieBlood" then
                                table.insert(result, item)
                            end
                        end
                    end
                end
            end
            return result
        end

        -- Avatar em .PNG
        -- Gancho originalmente usa um modelo 3D, porém como não há modelo 3D para humanos pendurasdos
        -- no gancho, foi necessário criar um painel customizado para renderizar uma imagem representando o humano no gancho.
        -- É mais simples do que criar um modelo 3D novo, e o resultado visual é satisfatório para o propósito do mod.
        local AVATAR_TEXTURES = {}

        local function getPK42AvatarTexture(status)
            local key = status or "Corpse"
            if AVATAR_TEXTURES[key] == nil then
                local tex = getTexture("media/ui/HookPanel/Hook_" .. key .. ".png")
                if not tex then
                    tex = getTexture("media/ui/HookPanel/Hook_Corpse.png")
                end
                AVATAR_TEXTURES[key] = tex or false
            end
            return AVATAR_TEXTURES[key] or nil
        end

        -- render
        -- Modificado: adiciona suporte ao painel PK42 (corpo humano no gancho).
        function ISButcherHookUI:render()
            ISCollapsableWindowJoypad.render(self)
        
            if self.chr:getVehicle() then
                self:close()
                return
            end
        
            self:setHeight(320)
        
            local hasPK42 = hookHasPK42Corpse(self.hook) and not hookHasAnimal(self.hook)
        
            if hasPK42 then
                if not self.pkPanel then return end
        
                if self.noAnimalPanel:isVisible() or self.animalPanel:isVisible() then
                    self.noAnimalPanel:setVisible(false)
                    self.animalPanel:setVisible(false)
                    self.pkPanel:setVisible(true)
                    self.configJoypadLater = true
                end
        
                local status = self.hook:getModData().PK42HookStatus or SU.hook_GetStatus(self.hook)
                local tex = getPK42AvatarTexture(status)
                if tex then
                    local ax = UI_BORDER_SPACING + 3
                    local ay = UI_BORDER_SPACING + 3
                    local aw = self.avatarWidth  or 148
                    local ah = self.avatarHeight or 230
                    self.pkPanel:drawRectBorder(ax - 2, ay - 2, aw + 4, ah + 4, 1, 0.3, 0.3, 0.3)
                    self.pkPanel:drawTextureScaled(tex, ax, ay, aw, ah, 1)
                end
        
                self:pkUpdateButtons()
                self:checkDistance()
                if self.configJoypadLater then
                    self.configJoypadLater = false
                    self:configJoypad()
                end
        
                if self.pkProgressBar then
                    if self.doingAction then
                        local ax = UI_BORDER_SPACING + 3
                        local aw = self.avatarWidth or 148
                        local ay = UI_BORDER_SPACING + 3
                        local ah = self.avatarHeight or 230
                        self.pkProgressBar:setVisible(true)
                        self.pkProgressBar:setX(ax + aw + 10)
                        self.pkProgressBar:setY(ay + ah - self.pkProgressBar:getHeight() + 2)
                        self.pkProgressBar:setText(self.actionText or "")
                        local rightX = self.pkSkinBtn:getX() + self.pkSkinBtn:getWidth()
                        self.pkProgressBar:setWidth(math.max(60, rightX - self.pkProgressBar:getX()))
                        self.pkSkinBtn:setVisible(false)
                        self.pkBleedBtn:setVisible(false)
                        self.pkMeatBtn:setVisible(false)
                        self.pkBonesBtn:setVisible(false)
                    else
                        self.pkProgressBar:setVisible(false)
                        self.doingAction = false
                        self.actionText  = nil
                    end
                end
        
                return
            end
        
            if self.pkPanel and self.pkPanel:isVisible() then
                self.pkPanel:setVisible(false)
                if self.hook:getAnimal() then
                    self.noAnimalPanel:setVisible(false)
                    self.animalPanel:setVisible(true)
                else
                    self.noAnimalPanel:setVisible(true)
                    self.animalPanel:setVisible(false)
                end
                self.configJoypadLater = true
            end
        
            self:checkAnimalOnHook()
        
            if not self.animal3D then
                if not self.noAnimalPanel:isVisible() then
                    self.noAnimalPanel:setVisible(true)
                    self.animalPanel:setVisible(false)
                    self.configJoypadLater = true
                end
                if isPlayerDoingActionThatCanBeCancelled(self.chr) or self.hook:getUsingPlayer() ~= nil then
                    self.addCorpseBtn:setEnable(false)
                else
                    self.addCorpseBtn:setEnable(true)
                end
                if self.configJoypadLater then
                    self.configJoypadLater = false
                    self:configJoypad()
                end
                self:checkDistance()
                return
            end
        
            if self.noAnimalPanel:isVisible() then
                self.noAnimalPanel:setVisible(false)
                self.animalPanel:setVisible(true)
                self.configJoypadLater = true
            end

            local x, y, w, h = self.avatarX, self.avatarY, self.avatarWidth, self.avatarHeight
            self.animalPanel:drawRectBorder(x - 2, y - 2, w + 4, h + 4, 1, 0.3, 0.3, 0.3)
        
            self:updateLabelAndButtons()
            self:checkDistance()
        
            if self.configJoypadLater then
                self.configJoypadLater = false
                self:configJoypad()
            end
        end

        -- configJoypad
        -- Modificado: adiciona botões PK42 ao joypad quando há humano no gancho.
        function ISButcherHookUI:configJoypad()
            local joypadData = getJoypadData(self.playerNum)
            self:clearISButtons()
            if not joypadData then return end
            self:clearJoypadFocus(joypadData)
            self.joypadIndexY   = 1
            self.joypadIndex    = 1
            self.joypadButtonsY = {}
            self.joypadButtons  = {}

            local hasPK42 = hookHasPK42Corpse(self.hook) and not hookHasAnimal(self.hook)

            if hasPK42 then
                if self.pkSkinBtn  and self.pkSkinBtn:isVisible()  then self:insertNewLineOfButtons(self.pkSkinBtn)  end
                if self.pkBleedBtn and self.pkBleedBtn:isVisible() then self:insertNewLineOfButtons(self.pkBleedBtn) end
                if self.pkMeatBtn  and self.pkMeatBtn:isVisible()  then self:insertNewLineOfButtons(self.pkMeatBtn)  end
                if self.pkBonesBtn and self.pkBonesBtn:isVisible() then self:insertNewLineOfButtons(self.pkBonesBtn) end
                self.joypadIndexY = self:getMinVisibleRow()
                self:setISButtonForX(self.pkRemoveBtn)
            elseif self.animal3D then
                self:insertNewLineOfButtons(self.removeLeatherBtn)
                self:insertNewLineOfButtons(self.removeBloodBtn)
                self:insertNewLineOfButtons(self.removeHeadBtn)
                self:insertNewLineOfButtons(self.removeMeatBtn)
                self.joypadIndexY = self:getMinVisibleRow()
                self:setISButtonForX(self.removeCorpseBtn)
            else
                self:insertNewLineOfButtons(self.addCorpseBtn)
            end

            self:restoreJoypadFocus(joypadData)
        end

        -- checkAnimalOnHook
        function ISButcherHookUI:checkAnimalOnHook()
            if self.hook == nil or self.hook:getAnimal() == self.animal3D then return end
            self.animal3D = self.hook:getAnimal()
            self:setAnimalAvatar()
            self:updateCorpseDatas()
        end

        -- updateProgressBar
        -- Modificado: alimenta a barra do painel ativo (vanilla ou PK42).
        function ISButcherHookUI:updateProgressBar(progress)
            if self.pkPanel and self.pkPanel:isVisible() and self.pkProgressBar then
                self.pkProgressBar.progress = progress
            else
                self.progressBar.progress = progress
            end
        end

        -- create
        -- Modificado: cria o painel PK42 ao final do create() vanilla.
        function ISButcherHookUI:create()
            self.animal3D = self.hook:getAnimal()
            self.hook:setLuaHook(self)

            local titleBarHeight     = self:titleBarHeight()
            local resizeWidgetHeight = self.resizable and self:resizeWidgetHeight() or 0
            local height = self.height - resizeWidgetHeight - titleBarHeight

            -- Painel "sem animal"
            self.noAnimalPanel = ISPanel:new(0, titleBarHeight, self.width, height)
            self:addChild(self.noAnimalPanel)
            self.originalHeight = self.noAnimalPanel:getHeight()
            self.originalWidth  = self.noAnimalPanel:getWidth()

            local btnWid = getTextManager():MeasureStringX(UIFont.Small, getText("ContextMenu_AddCorpse")) + UI_BORDER_SPACING
            self.addCorpseBtn = ISButton:new(
                (self.width - btnWid) / 2, (self.noAnimalPanel.height - BUTTON_HGT) / 2,
                btnWid, BUTTON_HGT,
                getText("ContextMenu_AddCorpse"), self, ISButcherHookUI.onClickAddCorpse
            )
            self.addCorpseBtn:initialise()
            self.addCorpseBtn:instantiate()
            self.addCorpseBtn:setVisible(true)
            self.noAnimalPanel:addChild(self.addCorpseBtn)

            -- Painel animal (vanilla)
            self.animalPanel = ISPanel:new(0, titleBarHeight - 1, self.width, height)
            self.animalPanel.anchorRight = true
            self:addChild(self.animalPanel)

            local removeCorpseBtnWid = getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_ButcherHook_RemoveCorpse")) + UI_BORDER_SPACING

            self.avatarX      = UI_BORDER_SPACING + 3
            self.avatarY      = UI_BORDER_SPACING + 3
            self.avatarWidth  = math.max(148, removeCorpseBtnWid - 4)
            self.avatarHeight = 230
            local avatarRight  = self.avatarX + self.avatarWidth
            local avatarBottom = self.avatarY + self.avatarHeight

            self.removeCorpseBtn = ISButton:new(
                self.avatarX - 2, avatarBottom + UI_BORDER_SPACING + 2,
                removeCorpseBtnWid, BUTTON_HGT,
                getText("IGUI_ButcherHook_RemoveCorpse"), self, ISButcherHookUI.removeCorpseAction
            )
            self.removeCorpseBtn:initialise()
            self.removeCorpseBtn:instantiate()
            self.removeCorpseBtn:setVisible(true)
            self.animalPanel:addChild(self.removeCorpseBtn)

            self.leatherLabel = ISLabel:new(avatarRight + UI_BORDER_SPACING, 16, BUTTON_HGT, "", 1,1,1,1, UIFont.Medium, false)
            self.leatherLabel:initialise()
            self.animalPanel:addChild(self.leatherLabel)

            self.leatherInfoLabel = ISLabel:new(self.width / 3, 16, BUTTON_HGT, "", 1,1,1,1, UIFont.Medium, false)
            self.leatherInfoLabel:initialise()
            self.animalPanel:addChild(self.leatherInfoLabel)

            local actionBtnWid = UI_BORDER_SPACING + math.max(
                getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_ButcherHook_Gather")),
                getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_ButcherHook_Bleed"))
            )

            self.removeLeatherBtn = ISButton:new(30, 30, actionBtnWid, BUTTON_HGT, getText("IGUI_ButcherHook_Gather"), self, ISButcherHookUI.onRemoveLeather)
            self.removeLeatherBtn:initialise()
            self.removeLeatherBtn:instantiate()
            self.removeLeatherBtn.borderColor = {r=0.3, g=0.3, b=0.3, a=1}
            self.removeLeatherBtn:setVisible(false)
            self.animalPanel:addChild(self.removeLeatherBtn)

            self.bloodLabel = ISLabel:new(self.width / 3, 16, BUTTON_HGT, "", 1,1,1,1, UIFont.Medium, false)
            self.bloodLabel:initialise()
            self.animalPanel:addChild(self.bloodLabel)

            self.bloodInfoLabel = ISLabel:new(self.width / 3, 16, BUTTON_HGT, "", 1,1,1,1, UIFont.Medium, false)
            self.bloodInfoLabel:initialise()
            self.animalPanel:addChild(self.bloodInfoLabel)

            self.removeBloodBtn = ISButton:new(30, 30, actionBtnWid, BUTTON_HGT, getText("IGUI_ButcherHook_Gather"), self, ISButcherHookUI.onRemoveBlood)
            self.removeBloodBtn:initialise()
            self.removeBloodBtn:instantiate()
            self.removeBloodBtn.borderColor = {r=0.3, g=0.3, b=0.3, a=1}
            self.removeBloodBtn:setVisible(false)
            self.animalPanel:addChild(self.removeBloodBtn)

            self.headLabel = ISLabel:new(self.width / 3, 16, BUTTON_HGT, "", 1,1,1,1, UIFont.Medium, false)
            self.headLabel:initialise()
            self.animalPanel:addChild(self.headLabel)

            self.headInfoLabel = ISLabel:new(self.width / 3, 16, BUTTON_HGT, "", 1,1,1,1, UIFont.Medium, false)
            self.headInfoLabel:initialise()
            self.animalPanel:addChild(self.headInfoLabel)

            self.removeHeadBtn = ISButton:new(30, 30, actionBtnWid, BUTTON_HGT, getText("IGUI_ButcherHook_Gather"), self, ISButcherHookUI.onRemoveHead)
            self.removeHeadBtn:initialise()
            self.removeHeadBtn:instantiate()
            self.removeHeadBtn.borderColor = {r=0.3, g=0.3, b=0.3, a=1}
            self.removeHeadBtn:setVisible(false)
            self.animalPanel:addChild(self.removeHeadBtn)

            self.meatLabel = ISLabel:new(self.width / 3, 16, BUTTON_HGT, "", 1,1,1,1, UIFont.Medium, false)
            self.meatLabel:initialise()
            self.animalPanel:addChild(self.meatLabel)

            self.meatInfoLabel = ISLabel:new(self.width / 3, 16, BUTTON_HGT, "", 1,1,1,1, UIFont.Medium, false)
            self.meatInfoLabel:initialise()
            self.animalPanel:addChild(self.meatInfoLabel)

            self.removeMeatBtn = ISButton:new(30, 30, actionBtnWid, BUTTON_HGT, getText("IGUI_ButcherHook_Gather"), self, ISButcherHookUI.onRemoveMeat)
            self.removeMeatBtn:initialise()
            self.removeMeatBtn:instantiate()
            self.removeMeatBtn.borderColor = {r=0.3, g=0.3, b=0.3, a=1}
            self.removeMeatBtn:setVisible(false)
            self.animalPanel:addChild(self.removeMeatBtn)

            self.progressBar = ISProgressBar:new(self.avatarX + 20, self.avatarY, 100, FONT_HGT_SMALL, "", UIFont.NewSmall)
            self.progressBar:setVisible(false)
            self.animalPanel:addChild(self.progressBar)

            self:updateCorpseDatas()

            self.animal3D = self.hook:getAnimal()
            if self.animal3D then
                self.noAnimalPanel:setVisible(false)
                self:setAnimalAvatar()
            else
                self.animalPanel:setVisible(false)
            end

            -- Painel PK42 (humano no gancho) — criado ao final
            self:pkCreatePanel()

            if hookHasPK42Corpse(self.hook) and not hookHasAnimal(self.hook) then
                self.noAnimalPanel:setVisible(false)
                self.animalPanel:setVisible(false)
                self.pkPanel:setVisible(true)
                self:pkUpdateButtons()
            end
        end

        -- isCorpseValid
        -- Modificado: humanos são sempre válidos para o gancho PK42.
        function ISButcherHookUI:isCorpseValid(corpse)
            if isHumanDeadBody(corpse) then
                -- Guard de nível: humanos no gancho só a partir de UNLOCK_HOOK_LEVEL
                local player  = self.chr
                local insanity = player and player:getPerkLevel(Perks.Insanity) or 0
                if insanity < UNLOCK_HOOK_LEVEL then return false end
                return true
            end
        
            local modData = corpse:getModData()
            if not modData then return false end
            if instanceof(corpse, "Food") and corpse:isFrozen() then return false end
            if not AnimalAvatarDefinition[modData["AnimalType"]] or not AnimalAvatarDefinition[modData["AnimalType"]].hook then return false end
            if modData["animalSize"] < 0.4 then return false end
            return not modData["skeleton"]
        end

        -- onClickAddCorpse
        -- Modificado: bloqueia se já há algo no gancho; exibe corpos humanos na lista.
        function ISButcherHookUI:onClickAddCorpse()
            if hookHasAnimal(self.hook) or hookHasPK42Corpse(self.hook) then return end
        
            local context = ISContextMenu.get(
                self.playerNum,
                self.addCorpseBtn:getAbsoluteX() + 10,
                self.addCorpseBtn:getAbsoluteY() + 10
            )
        
            local insanity = self.chr and self.chr:getPerkLevel(Perks.Insanity) or 0
            local corpseList = self:lookForCorpse()
        
            for _, v in ipairs(corpseList) do
                local text
                if instanceof(v, "InventoryItem") then
                    text = v:getDisplayName()
                end
                if instanceof(v, "IsoDeadBody") then
                    if v:isAnimal() then
                        text = v:isAnimalSkeleton()
                            and getText("IGUI_Item_AnimalSkeleton", v:getCustomName())
                            or  getText("IGUI_Item_AnimalCorpse",   v:getCustomName())
                    else
                        local name = v:getCustomName()
                        if not name or name == "" then
                            local okZ, isZombie = pcall(function() return v:isZombie() end)
                            name = (okZ and isZombie)
                                and (getText("IGUI_PK42_Zombie"))
                                or  (getText("IGUI_PK42_Human"))
                        end
                        local okS, isSkel = pcall(function() return v:isSkeleton() end)
                        if okS and isSkel then
                            name = getText("IGUI_PK42_Skeleton")
                        end
                        text = name
                    end
                end
        
                if text then
                    local option = context:addOption(text, self, ISButcherHookUI.addCorpseAction, v)
                    option.iconTexture = self:getAnimalCorpseItemTexture(v)
        
                    local valid = self:isCorpseValid(v)
                    if not valid then
                        option.notAvailable = true
                        local tooltip = ISWorldObjectContextMenu.addToolTip()
                        -- Se for humano bloqueado por nível, tooltip específico
                        if isHumanDeadBody(v) and insanity < UNLOCK_HOOK_LEVEL then
                            tooltip:setName(getText("Tooltip_HookHumanLocked") .. UNLOCK_HOOK_LEVEL)
                        end
                        option.toolTip = tooltip
                    end
        
                    if instanceof(v, "IsoDeadBody") then
                        ISWorldObjectContextMenu.initWorldItemHighlightOption(option, v)
                    end
                end
            end
        
            if #corpseList == 0 then
                local option = context:addOption(getText("IGUI_ButcherHook_NoAnimalFound"), self, nil)
                option.notAvailable = true
                local tooltip = ISWorldObjectContextMenu.addToolTip()
                tooltip:setName(getText("Tooltip_ButcherUI_AddAnimalCorpse"))
                option.toolTip = tooltip
            end
        
            if getJoypadData(self.playerNum) then
                context.mouseOver = 1
                context.origin    = self
                setJoypadFocus(self.playerNum, context)
            end
        end

        -- getAnimalCorpseItemTexture
        -- Modificado: detecta ícone para humanos (esqueleto, masculino, feminino).
        function ISButcherHookUI:getAnimalCorpseItemTexture(itemOrCorpse)
            if instanceof(itemOrCorpse, "InventoryItem") then
                return itemOrCorpse:getTex()
            end
            if instanceof(itemOrCorpse, "IsoDeadBody") then
                if itemOrCorpse:isAnimal() then
                    local icon = itemOrCorpse:getInvIcon()
                    return (icon and icon ~= "") and getTexture(icon) or nil
                end
                -- esqueleto humano
                local okS, isSkel = pcall(function() return itemOrCorpse:isSkeleton() end)
                if okS and isSkel then
                    local scriptItem = ScriptManager.instance:FindItem("Base.Hominid_Skull")
                    if scriptItem then
                        local tex = scriptItem:getNormalTexture()
                        if scriptItem.getIconsForTexture
                            and scriptItem:getIconsForTexture()
                            and not scriptItem:getIconsForTexture():isEmpty()
                        then
                            tex = scriptItem:getIconsForTexture():get(0)
                        end
                        return tex
                    end
                    return nil
                end

                -- humano normal: detecta sexo
                local fullType = "Base.CorpseMale"
                if itemOrCorpse.isFemale and itemOrCorpse:isFemale() then
                    fullType = "Base.CorpseFemale"
                end
                local scriptItem = ScriptManager.instance:FindItem(fullType)
                if not scriptItem then return nil end
                local tex = scriptItem:getNormalTexture()
                if scriptItem.getIconsForTexture
                    and scriptItem:getIconsForTexture()
                    and not scriptItem:getIconsForTexture():isEmpty()
                then
                    tex = scriptItem:getIconsForTexture():get(0)
                end
                return tex
            end
            return nil
        end

        -- addCorpseAction
        -- Modificado: humano = ação PK42; animal = vanilla.
        function ISButcherHookUI:addCorpseAction(corpse)
            if isHumanDeadBody(corpse) then
                if luautils.walkAdj(self.chr, self.hook:getSquare(), false) then
                    ISTimedActionQueue.add(PK42ActionPutCorpseOnHook:new(self.chr, corpse, self.hook))
                end
                return
            end
            if luautils.walkAdj(self.chr, self.hook:getSquare(), false) then
                ISTimedActionQueue.add(ISPutAnimalOnHook:new(self.chr, corpse, self.hook, self))
            end
        end

        -- lookForCorpse
        -- Modificado: inclui corpos humanos próximos além dos animais vanilla.
        function ISButcherHookUI:lookForCorpse()
            local result = {}

            local corpses = self.chr:getInventory():FindAll("CorpseAnimal")
            if corpses then
                for i = 0, corpses:size() - 1 do
                    table.insert(result, corpses:get(i))
                end
            end

            local radius = 2
            local cx = self.chr:getCurrentSquare():getX()
            local cy = self.chr:getCurrentSquare():getY()
            local cz = self.chr:getCurrentSquare():getZ()
            local seen = {}

            for x = cx - radius, cx + radius do
                for y = cy - radius, cy + radius do
                    local sq = getCell():getGridSquare(x, y, cz)
                    if sq then
                        local statics = sq:getStaticMovingObjects()
                        if statics then
                            for i = 0, statics:size() - 1 do
                                local obj = statics:get(i)
                                if instanceof(obj, "IsoDeadBody") and obj:isAnimal() then
                                    local id = tostring(obj)
                                    if not seen[id] then
                                        seen[id] = true
                                        table.insert(result, obj)
                                    end
                                end
                            end
                        end
                        local bodies = sq:getDeadBodys()
                        if bodies then
                            for i = 0, bodies:size() - 1 do
                                local body = bodies:get(i)
                                if isHumanDeadBody(body) then
                                    local id = tostring(body)
                                    if not seen[id] then
                                        seen[id] = true
                                        table.insert(result, body)
                                    end
                                end
                            end
                        end
                    end
                end
            end

            return result
        end

        -- Funções exclusivamente novas
        function ISButcherHookUI:pkCreatePanel()
            local titleH = self:titleBarHeight()
            local h      = self.height - titleH

            self.pkPanel = ISPanel:new(0, titleH, self.width, h)
            self.pkPanel.anchorRight = true
            self:addChild(self.pkPanel)   -- SEM :initialise()
            self.pkPanel:setVisible(false)

            local avatarX      = UI_BORDER_SPACING + 3
            local avatarY      = UI_BORDER_SPACING + 3
            local avatarWidth  = self.avatarWidth  or 148
            local avatarHeight = self.avatarHeight or 230
            local avatarBottom = avatarY + avatarHeight

            local btnWid = getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_ButcherHook_RemoveCorpse")) + UI_BORDER_SPACING
            self.pkRemoveBtn = ISButton:new(
                avatarX - 2, avatarBottom + UI_BORDER_SPACING + 2,
                btnWid, BUTTON_HGT,
                getText("IGUI_ButcherHook_RemoveCorpse"),
                self, ISButcherHookUI.pkOnRemove
            )
            self.pkRemoveBtn:initialise()
            self.pkPanel:addChild(self.pkRemoveBtn)

            local btnWid2 = UI_BORDER_SPACING + math.max(
                getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_ButcherHook_Gather")),
                getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_ButcherHook_Bleed"))
            )

            -- Leather (Skin)
            self.pkLeatherLabel = ISLabel:new(avatarX + avatarWidth + UI_BORDER_SPACING, 16, BUTTON_HGT, "", 1,1,1,1, UIFont.Medium, false)
            self.pkLeatherLabel:initialise()
            self.pkPanel:addChild(self.pkLeatherLabel)

            self.pkLeatherInfoLabel = ISLabel:new(self.width / 3, 16, BUTTON_HGT, "", 1,1,1,1, UIFont.Medium, false)
            self.pkLeatherInfoLabel:initialise()
            self.pkPanel:addChild(self.pkLeatherInfoLabel)

            self.pkSkinBtn = ISButton:new(30, 30, btnWid2, BUTTON_HGT, getText("IGUI_ButcherHook_Gather"), self, ISButcherHookUI.pkOnSkin)
            self.pkSkinBtn:initialise()
            self.pkSkinBtn.borderColor = {r=0.3, g=0.3, b=0.3, a=1}
            self.pkSkinBtn:setVisible(false)
            self.pkPanel:addChild(self.pkSkinBtn)

            -- Blood
            self.pkBloodLabel = ISLabel:new(self.width / 3, 16, BUTTON_HGT, "", 1,1,1,1, UIFont.Medium, false)
            self.pkBloodLabel:initialise()
            self.pkPanel:addChild(self.pkBloodLabel)

            self.pkBloodInfoLabel = ISLabel:new(self.width / 3, 16, BUTTON_HGT, "", 1,1,1,1, UIFont.Medium, false)
            self.pkBloodInfoLabel:initialise()
            self.pkPanel:addChild(self.pkBloodInfoLabel)

            self.pkBleedBtn = ISButton:new(30, 30, btnWid2, BUTTON_HGT, getText("IGUI_ButcherHook_Bleed"), self, ISButcherHookUI.pkOnBleed)
            self.pkBleedBtn:initialise()
            self.pkBleedBtn.borderColor = {r=0.3, g=0.3, b=0.3, a=1}
            self.pkBleedBtn:setVisible(false)
            self.pkPanel:addChild(self.pkBleedBtn)

            -- Meat
            self.pkMeatLabel = ISLabel:new(self.width / 3, 16, BUTTON_HGT, "", 1,1,1,1, UIFont.Medium, false)
            self.pkMeatLabel:initialise()
            self.pkPanel:addChild(self.pkMeatLabel)

            self.pkMeatInfoLabel = ISLabel:new(self.width / 3, 16, BUTTON_HGT, "", 1,1,1,1, UIFont.Medium, false)
            self.pkMeatInfoLabel:initialise()
            self.pkPanel:addChild(self.pkMeatInfoLabel)

            self.pkMeatBtn = ISButton:new(30, 30, btnWid2, BUTTON_HGT, getText("IGUI_ButcherHook_Gather"), self, ISButcherHookUI.pkOnButcher)
            self.pkMeatBtn:initialise()
            self.pkMeatBtn.borderColor = {r=0.3, g=0.3, b=0.3, a=1}
            self.pkMeatBtn:setVisible(false)
            self.pkPanel:addChild(self.pkMeatBtn)

            -- Bones
            self.pkBonesLabel = ISLabel:new(self.width / 3, 16, BUTTON_HGT, "", 1,1,1,1, UIFont.Medium, false)
            self.pkBonesLabel:initialise()
            self.pkPanel:addChild(self.pkBonesLabel)

            self.pkBonesInfoLabel = ISLabel:new(self.width / 3, 16, BUTTON_HGT, "", 1,1,1,1, UIFont.Medium, false)
            self.pkBonesInfoLabel:initialise()
            self.pkPanel:addChild(self.pkBonesInfoLabel)

            self.pkBonesBtn = ISButton:new(30, 30, btnWid2, BUTTON_HGT,
                getText("ContextMenu_PK42_CollectBones"),
                self, ISButcherHookUI.pkOnCollectBones
            )
            self.pkBonesBtn:initialise()
            self.pkBonesBtn.borderColor = {r=0.3, g=0.3, b=0.3, a=1}
            self.pkBonesBtn:setVisible(false)
            self.pkPanel:addChild(self.pkBonesBtn)

            -- Barra de progresso
            self.pkProgressBar = ISProgressBar:new(
                avatarX + avatarWidth + 10,
                avatarY + avatarHeight - FONT_HGT_SMALL + 2,
                100, FONT_HGT_SMALL, "", UIFont.NewSmall
            )
            self.pkProgressBar:setVisible(false)
            self.pkPanel:addChild(self.pkProgressBar)
        end

        function ISButcherHookUI:pkUpdateButtons()
            if not self.pkPanel then return end

            local md     = self.hook:getModData()
            local status = md.PK42HookStatus or SU.hook_GetStatus(self.hook)

            local isCorpse   = status == "Corpse"   or status == "CorpseBleeded"
            local isSkinned  = status == "Skinned"  or status == "SkinnedBleeded"
            local isSkel     = status == "Skeleton"
            local hasMeat    = isCorpse or isSkinned
            local hasBlood   = hasMeat and (tonumber(md.PK42BloodQty) or 0) > 0
            local hasLeather = status == "Corpse"   or status == "CorpseBleeded"
            local hasBones   = isSkel

            self.knife = SU.findButcherTool(self.chr:getInventory())

            local biggestWidth      = 0
            local biggestLabelWidth = 0

            local function measureRow(label, infoLabel, labelText, infoText)
                label:setName(labelText)
                infoLabel:setName(infoText)
                biggestWidth      = math.max(biggestWidth,      label:getWidth() + infoLabel:getWidth())
                biggestLabelWidth = math.max(biggestLabelWidth, label:getWidth())
            end

            measureRow(self.pkLeatherLabel, self.pkLeatherInfoLabel,
                getText("IGUI_ButcherHook_Leather"),
                hasLeather and getText("IGUI_Yes") or getText("IGUI_No"))

            local bloodText = getText("IGUI_No")
            if hasBlood then
                bloodText = getText("IGUI_Yes") .. " (" .. round(tonumber(md.PK42BloodQty) or 0, 2) .. "L)"
            end
            measureRow(self.pkBloodLabel, self.pkBloodInfoLabel,
                getText("IGUI_ButcherHook_Blood"), bloodText)

            measureRow(self.pkMeatLabel, self.pkMeatInfoLabel,
                getText("IGUI_ButcherHook_Meat"),
                hasMeat and getText("IGUI_Yes") or getText("IGUI_No"))

            measureRow(self.pkBonesLabel, self.pkBonesInfoLabel,
                getText("IGUI_ButcherHook_Bones"),
                hasBones and getText("IGUI_Yes") or getText("IGUI_No"))

            local xoffset      = (self.avatarX or UI_BORDER_SPACING + 3) + (self.avatarWidth or 148)
            local buttonOffset = 70

            local function layoutRow(visible, btn, label, infoLabel, yoffset)
                label:setX(xoffset + UI_BORDER_SPACING)
                label:setY(yoffset)
                label:setVisible(true)
                infoLabel:setX(xoffset + biggestLabelWidth + UI_BORDER_SPACING * 2)
                infoLabel:setY(yoffset)
                infoLabel:setVisible(true)
                btn:setX(xoffset + biggestWidth + buttonOffset)
                btn:setWidth(self.width - btn.x - UI_BORDER_SPACING - 1)
                btn:setY(label:getY())
                btn:setVisible(visible == true)
                if not self.knife then
                    btn.enable  = false
                    btn.tooltip = getText("Tooltip_Animal_NoKnifeButcher")
                else
                    btn.enable  = true
                    btn.tooltip = nil
                end
                return infoLabel:getY() + BUTTON_HGT + UI_BORDER_SPACING
            end

            local yoffset = (self.avatarY or UI_BORDER_SPACING + 3) - 2
            yoffset = layoutRow(hasLeather, self.pkSkinBtn,  self.pkLeatherLabel, self.pkLeatherInfoLabel, yoffset)
            yoffset = layoutRow(hasBlood,   self.pkBleedBtn, self.pkBloodLabel,   self.pkBloodInfoLabel,   yoffset)
            yoffset = layoutRow(hasMeat,    self.pkMeatBtn,  self.pkMeatLabel,    self.pkMeatInfoLabel,    yoffset)
            yoffset = layoutRow(hasBones,   self.pkBonesBtn, self.pkBonesLabel,   self.pkBonesInfoLabel,   yoffset)

            -- Bones não exige faca
            if hasBones then
                self.pkBonesBtn.enable  = true
                self.pkBonesBtn.tooltip = nil
            end

            self.pkRemoveBtn:setVisible(true)
            self.pkRemoveBtn.enable = true
        end

        function ISButcherHookUI:pkOnSkin()
            if not luautils.walkAdj(self.chr, self.hook:getSquare(), false) then return end
            local tool = SU.findButcherTool(self.chr:getInventory())
            if not tool then return end
            ISInventoryPaneContextMenu.transferIfNeeded(self.chr, tool)
            ISWorldObjectContextMenu.equip(self.chr, self.chr:getPrimaryHandItem(), tool, true)
            ISTimedActionQueue.add(PK42SkinAction:new(self.chr, nil, nil, self.hook))
        end

        function ISButcherHookUI:pkOnBleed()
            local context = ISContextMenu.get(
                0,
                self.pkBleedBtn:getAbsoluteX() + 10,
                self.pkBleedBtn:getAbsoluteY() + 10
            )

            context:addOption(getText("IGUI_None"), self, ISButcherHookUI.pkOnBleedDrop)

            local bucketList = pkGetAvailableBuckets(self.chr)
            for _, bucket in ipairs(bucketList) do
                local fc    = bucket:getFluidContainer()
                local label = bucket:getDisplayName()
                        .. " " .. fc:getAmount()
                        .. "/" .. fc:getCapacity()
                context:addOption(label, self, ISButcherHookUI.pkOnBleedIntoBucket, bucket)
            end

            if getJoypadData(self.playerNum) then
                context.mouseOver = 1
                context.origin    = self
                setJoypadFocus(self.playerNum, context)
            end
        end

        function ISButcherHookUI:pkOnBleedDrop()
            if not luautils.walkAdj(self.chr, self.hook:getSquare(), false) then return end
            local tool = SU.findButcherTool(self.chr:getInventory())
            if not tool then return end
            ISInventoryPaneContextMenu.transferIfNeeded(self.chr, tool)
            ISWorldObjectContextMenu.equip(self.chr, self.chr:getPrimaryHandItem(), tool, true)
            ISTimedActionQueue.add(PK42ActionBleedCorpseOnHook:new(self.chr, self.hook, self, nil))
        end

        function ISButcherHookUI:pkOnBleedIntoBucket(bucket)
            if not luautils.walkAdj(self.chr, self.hook:getSquare(), false) then return end
            local tool = SU.findButcherTool(self.chr:getInventory())
            if not tool then return end
            ISInventoryPaneContextMenu.transferIfNeeded(self.chr, tool)
            ISWorldObjectContextMenu.equip(self.chr, self.chr:getPrimaryHandItem(), tool, true)
            ISTimedActionQueue.add(PK42ActionBleedCorpseOnHook:new(self.chr, self.hook, self, bucket))
            ISTimedActionQueue.add(PK42GatherBloodFromCorpse:new(self.chr, self.hook, self, bucket))
        end

        function ISButcherHookUI:pkOnButcher()
            if not luautils.walkAdj(self.chr, self.hook:getSquare(), false) then return end
            local tool = SU.findButcherTool(self.chr:getInventory())
            if not tool then return end
            ISInventoryPaneContextMenu.transferIfNeeded(self.chr, tool)
            ISWorldObjectContextMenu.equip(self.chr, self.chr:getPrimaryHandItem(), tool, true)
            ISTimedActionQueue.add(PK42ButcheringAction:new(self.chr, nil, nil, self.hook))
        end

        function ISButcherHookUI:pkOnCollectBones()
            if not luautils.walkAdj(self.chr, self.hook:getSquare(), false) then return end
            ISTimedActionQueue.add(PK42CollectBonesAction:new(self.chr, nil, nil, self.hook))
        end

        function ISButcherHookUI:pkOnRemove()
            if not luautils.walkAdj(self.chr, self.hook:getSquare(), false) then return end
            ISTimedActionQueue.add(PK42ActionRemoveCorpseFromHook:new(self.chr, self.hook))
        end

        -- Listener: atualiza botões após confirmação do servidor
        local function onServerCommand(module, command, args)
            if module ~= "PK42" then return end
            if command ~= "HookUpdated" then return end

            for _, ui in pairs(ISButcherHookUI.ui) do
                if ui and ui.hook then
                    local newStatus = args and args.status
                    if newStatus and SU.hook_SwapSprite then
                        SU.hook_SwapSprite(ui.hook, newStatus)
                    end
                    if ui.pkPanel and ui.pkPanel:isVisible() then
                        ui.doingAction = false
                        ui:pkUpdateButtons()
                    end
                end
            end
        end

        Events.OnServerCommand.Add(onServerCommand)
    else 
        return 
    end
end

Events.OnInitWorld.Add(patchISButcherHookUI)