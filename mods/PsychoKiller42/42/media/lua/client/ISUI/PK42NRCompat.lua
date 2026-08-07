-- Compat: adiciona suporte a corpo humano no gancho quando o NeatRocco UI
-- (NR_ButcherHookPanel) está ativo, já que ele SUBSTITUI ISButcherHookUI
-- por uma classe própria e não herda o patch feito em PK42HookUI.lua.

if isServer() then return end

local SU = require "Utils/PK42SharedUtils"

-- Config (espelha PK42HookUI.lua)
local function getSandboxCFG()
    local opts = SandboxVars.PK42
    return {
        ALLOW_PATCH = opts and opts.EnableButcherHookPatch ~= false,
        BUTCHER_LVL = opts and opts.ButcherCorpseUnlockLevel or 3,
    }
end

local cfg = getSandboxCFG()
if cfg.ALLOW_PATCH ~= true then return end

local UNLOCK_HOOK_LEVEL = math.min(cfg.BUTCHER_LVL + 1, 10)

-- Detecção do mod
local function isModActive(targetIds)
    local mods = getActivatedMods and getActivatedMods() or nil
    if not mods or mods:size() == 0 then return false end
    local want = {}
    for _, tid in ipairs(targetIds) do
        want[tostring(tid):lower()] = true
    end
    for i = 0, mods:size() - 1 do
        if want[tostring(mods:get(i)):lower()] then return true end
    end
    return false
end

if not isModActive({ "Neat_Rocco" }) then
    return
end

-- Helpers (idênticos aos de PK42HookUI.lua)
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
    local items = chr:getInventory():getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local fc = item.getFluidContainer and item:getFluidContainer()
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

-- Wiring principal
local function patchNRButcherHookPanel()
    if not rawget(_G, "NR_ButcherHookPanel") then
        return false
    end
    if NR_ButcherHookPanel._pk42Patched then
        return true
    end
    NR_ButcherHookPanel._pk42Patched = true

    local NI_SquareButton = require("NeatUI_Framework/UI/NI_SquareButton")
    local FONT_HGT_SMALL  = getTextManager():getFontHeight(UIFont.Small)

    -- criação do painel PK42
    function NR_ButcherHookPanel:pkCreatePanel()
        local bsz = NR_Config.buttonSize
        local pad = NR_Config.padding

        self.pkPanel = ISPanel:new(0, NR_Config.headerHeight, self.width, self.animalPanel:getHeight())
        self.pkPanel:noBackground()
        self.pkPanel:initialise()
        self:addChild(self.pkPanel)
        self.pkPanel:setVisible(false)

        local avatarBottom = self.avatarY + self.avatarHeight

        self.pkRemoveBtn = NI_SquareButton:new(
            self.avatarX, avatarBottom + pad, bsz,
            getTexture("media/ui/NeatRocco/ICON/Icon_DropDown.png"),
            self, NR_ButcherHookPanel.pkOnRemove
        )
        self.pkRemoveBtn:initialise()
        self.pkRemoveBtn:setActive(true)
        self.pkRemoveBtn:setActiveColor(0.8, 0.2, 0.2)
        self.pkPanel:addChild(self.pkRemoveBtn)

        self.pkLeatherLabel     = ISLabel:new(0, 0, FONT_HGT_SMALL, "", 1,   1,   1,   0.9, UIFont.Small, false)
        self.pkLeatherInfoLabel = ISLabel:new(0, 0, FONT_HGT_SMALL, "", 0.7, 0.7, 0.7, 0.9, UIFont.Small, false)
        self.pkBloodLabel       = ISLabel:new(0, 0, FONT_HGT_SMALL, "", 1,   1,   1,   0.9, UIFont.Small, false)
        self.pkBloodInfoLabel   = ISLabel:new(0, 0, FONT_HGT_SMALL, "", 0.7, 0.7, 0.7, 0.9, UIFont.Small, false)
        self.pkMeatLabel        = ISLabel:new(0, 0, FONT_HGT_SMALL, "", 1,   1,   1,   0.9, UIFont.Small, false)
        self.pkMeatInfoLabel    = ISLabel:new(0, 0, FONT_HGT_SMALL, "", 0.7, 0.7, 0.7, 0.9, UIFont.Small, false)
        self.pkBonesLabel       = ISLabel:new(0, 0, FONT_HGT_SMALL, "", 1,   1,   1,   0.9, UIFont.Small, false)
        self.pkBonesInfoLabel   = ISLabel:new(0, 0, FONT_HGT_SMALL, "", 0.7, 0.7, 0.7, 0.9, UIFont.Small, false)

        for _, lbl in ipairs({
            self.pkLeatherLabel, self.pkLeatherInfoLabel,
            self.pkBloodLabel,   self.pkBloodInfoLabel,
            self.pkMeatLabel,    self.pkMeatInfoLabel,
            self.pkBonesLabel,   self.pkBonesInfoLabel,
        }) do
            lbl:initialise()
            self.pkPanel:addChild(lbl)
        end

        local gatherIcon = getTexture("media/ui/NeatRocco/ICON/Icon_Gather.png")
        local bleedIcon  = self.iconBleed or gatherIcon

        self.pkSkinBtn = NI_SquareButton:new(0, 0, bsz, gatherIcon, self, NR_ButcherHookPanel.pkOnSkin)
        self.pkSkinBtn:initialise()
        self.pkSkinBtn:setActive(true)
        self.pkSkinBtn:setActiveColor(0.95, 0.5, 0.1)
        self.pkSkinBtn:setVisible(false)
        self.pkPanel:addChild(self.pkSkinBtn)

        self.pkBleedBtn = NI_SquareButton:new(0, 0, bsz, bleedIcon, self, NR_ButcherHookPanel.pkOnBleed)
        self.pkBleedBtn:initialise()
        self.pkBleedBtn:setActive(true)
        self.pkBleedBtn:setActiveColor(0.95, 0.5, 0.1)
        self.pkBleedBtn:setVisible(false)
        self.pkPanel:addChild(self.pkBleedBtn)

        self.pkMeatBtn = NI_SquareButton:new(0, 0, bsz, gatherIcon, self, NR_ButcherHookPanel.pkOnButcher)
        self.pkMeatBtn:initialise()
        self.pkMeatBtn:setActive(true)
        self.pkMeatBtn:setActiveColor(0.95, 0.5, 0.1)
        self.pkMeatBtn:setVisible(false)
        self.pkPanel:addChild(self.pkMeatBtn)

        self.pkBonesBtn = NI_SquareButton:new(0, 0, bsz, gatherIcon, self, NR_ButcherHookPanel.pkOnCollectBones)
        self.pkBonesBtn:initialise()
        self.pkBonesBtn:setActive(true)
        self.pkBonesBtn:setActiveColor(0.95, 0.5, 0.1)
        self.pkBonesBtn:setVisible(false)
        self.pkPanel:addChild(self.pkBonesBtn)
    end

    -- createChildren: cria o pkPanel depois do original
    local oldCreateChildren = NR_ButcherHookPanel.createChildren
    function NR_ButcherHookPanel:createChildren()
        oldCreateChildren(self)
        self:pkCreatePanel()

        if hookHasPK42Corpse(self.hook) and not hookHasAnimal(self.hook) then
            self.noAnimalPanel:setVisible(false)
            self.animalPanel:setVisible(false)
            self.pkPanel:setVisible(true)
        end
    end

    -- render
    local oldRender = NR_ButcherHookPanel.render
    function NR_ButcherHookPanel:render()
        if not self.hook then return end

        local hasPK42 = hookHasPK42Corpse(self.hook) and not hookHasAnimal(self.hook)

        if not hasPK42 then
            if self.pkPanel and self.pkPanel:isVisible() then
                self.pkPanel:setVisible(false)
                if self.hook:getAnimal() then
                    self.noAnimalPanel:setVisible(false)
                    self.animalPanel:setVisible(true)
                else
                    self.noAnimalPanel:setVisible(true)
                    self.animalPanel:setVisible(false)
                end
            end
            return oldRender(self)
        end

        ISPanelJoypad.render(self)
        self:setHeight(NR_Config.headerHeight + self.animalPanel:getHeight())

        if self.noAnimalPanel:isVisible() or self.animalPanel:isVisible() then
            self.noAnimalPanel:setVisible(false)
            self.animalPanel:setVisible(false)
            self.pkPanel:setVisible(true)
        end

        local x, y, w, h = self.avatarX, self.avatarY, self.avatarWidth, self.avatarHeight
        self.pkPanel:drawRectBorder(x - 2, y - 2, w + 4, h + 4, 1, 0.3, 0.3, 0.3)

        local status = self.hook:getModData().PK42HookStatus or SU.hook_GetStatus(self.hook)
        local tex = getPK42AvatarTexture(status)
        if tex then
            self.pkPanel:drawTextureScaled(tex, x, y, w, h, 1)
        end

        self:pkUpdateButtons()
        self:drawProgressBar()
        self:checkDistance()
    end

    -- pkUpdateButtons: equivalente ao updateLabelAndButtons, só que
    -- pro painel PK42, reaproveitando o updatePositions genérico do NR
    function NR_ButcherHookPanel:pkUpdateButtons()
        local md     = self.hook:getModData()
        local status = md.PK42HookStatus or SU.hook_GetStatus(self.hook)

        local isCorpse   = status == "Corpse"  or status == "CorpseBleeded"
        local isSkinned  = status == "Skinned" or status == "SkinnedBleeded"
        local isSkel     = status == "Skeleton"
        local hasMeat    = isCorpse or isSkinned
        local hasBlood   = hasMeat and (tonumber(md.PK42BloodQty) or 0) > 0
        local hasLeather = status == "Corpse" or status == "CorpseBleeded"
        local hasBones   = isSkel

        self.knife = SU.findButcherTool(self.chr:getInventory())

        self.pkLeatherLabel:setName(getText("IGUI_ButcherHook_Leather"))
        self.pkBloodLabel:setName(getText("IGUI_ButcherHook_Blood"))
        self.pkMeatLabel:setName(getText("IGUI_ButcherHook_Meat"))
        self.pkBonesLabel:setName(getText("IGUI_ButcherHook_Bones"))

        self.pkLeatherInfoLabel:setName(hasLeather and getText("IGUI_Yes") or getText("IGUI_No"))

        local bloodText = getText("IGUI_No")
        if hasBlood then
            bloodText = getText("IGUI_Yes") .. " (" .. round(tonumber(md.PK42BloodQty) or 0, 2) .. "L)"
        end
        self.pkBloodInfoLabel:setName(bloodText)
        self.pkMeatInfoLabel:setName(hasMeat and getText("IGUI_Yes") or getText("IGUI_No"))
        self.pkBonesInfoLabel:setName(hasBones and getText("IGUI_Yes") or getText("IGUI_No"))

        self.biggestLabelWidth = math.max(
            self.pkLeatherLabel:getWidth(), self.pkBloodLabel:getWidth(),
            self.pkMeatLabel:getWidth(),    self.pkBonesLabel:getWidth()
        )
        self.biggestWidth = math.max(
            self.pkLeatherLabel:getWidth() + self.pkLeatherInfoLabel:getWidth(),
            self.pkBloodLabel:getWidth()   + self.pkBloodInfoLabel:getWidth(),
            self.pkMeatLabel:getWidth()    + self.pkMeatInfoLabel:getWidth(),
            self.pkBonesLabel:getWidth()   + self.pkBonesInfoLabel:getWidth()
        )

        local yoffset = self.avatarY - 2
        yoffset = self:updatePositions(hasLeather, self.pkSkinBtn,  self.pkLeatherLabel, self.pkLeatherInfoLabel, yoffset)
        yoffset = self:updatePositions(hasBlood,   self.pkBleedBtn, self.pkBloodLabel,   self.pkBloodInfoLabel,   yoffset)
        yoffset = self:updatePositions(hasMeat,    self.pkMeatBtn,  self.pkMeatLabel,    self.pkMeatInfoLabel,    yoffset)
        yoffset = self:updatePositions(hasBones,   self.pkBonesBtn, self.pkBonesLabel,   self.pkBonesInfoLabel,   yoffset)

        -- Bones não exige faca (igual ao patch vanilla)
        if hasBones then
            self.pkBonesBtn.enable = true
            self.pkBonesBtn:setActive(true)
            self.pkBonesBtn.tooltip = nil
        end

        if self.doingAction or self.hook:getUsingPlayer() ~= nil then
            self.pkSkinBtn:setVisible(false)
            self.pkBleedBtn:setVisible(false)
            self.pkMeatBtn:setVisible(false)
            self.pkBonesBtn:setVisible(false)
            self.pkRemoveBtn:setVisible(false)
        else
            self.pkRemoveBtn:setVisible(true)
            self.pkRemoveBtn.enable = true
        end

        local pad = NR_Config.padding
        if self.doingAction then
            self.progressBarX = self.avatarX + self.avatarWidth + pad
            self.progressBarY = self.avatarY + self.avatarHeight - math.floor(FONT_HGT_SMALL * 1.2) + 2
            self.progressBarW = self.width - pad - self.progressBarX
        else
            self.actionText       = nil
            self.progress         = 0
            self._displayProgress = 0
        end
    end

    -- lookForCorpse: soma corpos humanos próximos aos animais do NR
    local oldLookForCorpse = NR_ButcherHookPanel.lookForCorpse
    function NR_ButcherHookPanel:lookForCorpse()
        local result = oldLookForCorpse(self)

        local seen = {}
        for _, v in ipairs(result) do seen[tostring(v)] = true end

        local radius = 2
        local cx = self.chr:getCurrentSquare():getX()
        local cy = self.chr:getCurrentSquare():getY()
        local cz = self.chr:getCurrentSquare():getZ()

        for x = cx - radius, cx + radius do
            for y = cy - radius, cy + radius do
                local sq = getCell():getGridSquare(x, y, cz)
                if sq then
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

    -- isCorpseValid: humano válido a partir do nível de Insanity
    local oldIsCorpseValid = NR_ButcherHookPanel.isCorpseValid
    function NR_ButcherHookPanel:isCorpseValid(corpse)
        if isHumanDeadBody(corpse) then
            local insanity = self.chr and self.chr:getPerkLevel(Perks.Insanity) or 0
            return insanity >= UNLOCK_HOOK_LEVEL
        end
        return oldIsCorpseValid(self, corpse)
    end

    -- getAnimalCorpseItemTexture: ícone pra humano (esqueleto/M/F)
    local oldGetTex = NR_ButcherHookPanel.getAnimalCorpseItemTexture
    function NR_ButcherHookPanel:getAnimalCorpseItemTexture(itemOrCorpse)
        if instanceof(itemOrCorpse, "IsoDeadBody") and isHumanDeadBody(itemOrCorpse) then
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
        return oldGetTex(self, itemOrCorpse)
    end

    -- onClickAddCorpse: substitui (não só complementa) o menu de contexto, pra incluir texto/ícone/tooltip de corpos humanos
    function NR_ButcherHookPanel:onClickAddCorpse()
        local context = ISContextMenu.get(
            self.playerNum,
            self.addCorpseBtn:getAbsoluteX() + 10,
            self.addCorpseBtn:getAbsoluteY() + 10
        )

        local insanity    = self.chr and self.chr:getPerkLevel(Perks.Insanity) or 0
        local corpseList  = self:lookForCorpse()

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
                            and getText("IGUI_PK42_Zombie")
                            or  getText("IGUI_PK42_Human")
                    end
                    local okS, isSkel = pcall(function() return v:isSkeleton() end)
                    if okS and isSkel then
                        name = getText("IGUI_PK42_Skeleton")
                    end
                    text = name
                end
            end

            if text then
                local option = context:addOption(text, self, NR_ButcherHookPanel.addCorpseAction, v)
                option.iconTexture = self:getAnimalCorpseItemTexture(v)

                if not self:isCorpseValid(v) then
                    option.notAvailable = true
                    local tooltip = ISWorldObjectContextMenu.addToolTip()
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

    -- addCorpseAction: humano vai pra ação PK42, animal segue o NR
    local oldAddCorpseAction = NR_ButcherHookPanel.addCorpseAction
    function NR_ButcherHookPanel:addCorpseAction(corpse)
        if isHumanDeadBody(corpse) then
            if luautils.walkAdj(self.chr, self.hook:getSquare(), false) then
                ISTimedActionQueue.add(PK42ActionPutCorpseOnHook:new(self.chr, corpse, self.hook))
            end
            return
        end
        return oldAddCorpseAction(self, corpse)
    end

    -- Ações do painel PK42 (idênticas às de PK42HookUI.lua)
    function NR_ButcherHookPanel:pkOnSkin()
        if not luautils.walkAdj(self.chr, self.hook:getSquare(), false) then return end
        local tool = SU.findButcherTool(self.chr:getInventory())
        if not tool then return end
        ISInventoryPaneContextMenu.transferIfNeeded(self.chr, tool)
        ISWorldObjectContextMenu.equip(self.chr, self.chr:getPrimaryHandItem(), tool, true)
        ISTimedActionQueue.add(PK42SkinAction:new(self.chr, nil, nil, self.hook))
    end

    function NR_ButcherHookPanel:pkOnBleed()
        local context = ISContextMenu.get(
            0,
            self.pkBleedBtn:getAbsoluteX() + 10,
            self.pkBleedBtn:getAbsoluteY() + 10
        )

        context:addOption(getText("IGUI_None"), self, NR_ButcherHookPanel.pkOnBleedDrop)

        local bucketList = pkGetAvailableBuckets(self.chr)
        for _, bucket in ipairs(bucketList) do
            local fc    = bucket:getFluidContainer()
            local label = bucket:getDisplayName()
                    .. " " .. fc:getAmount()
                    .. "/" .. fc:getCapacity()
            context:addOption(label, self, NR_ButcherHookPanel.pkOnBleedIntoBucket, bucket)
        end

        if getJoypadData(self.playerNum) then
            context.mouseOver = 1
            context.origin    = self
            setJoypadFocus(self.playerNum, context)
        end
    end

    function NR_ButcherHookPanel:pkOnBleedDrop()
        if not luautils.walkAdj(self.chr, self.hook:getSquare(), false) then return end
        local tool = SU.findButcherTool(self.chr:getInventory())
        if not tool then return end
        ISInventoryPaneContextMenu.transferIfNeeded(self.chr, tool)
        ISWorldObjectContextMenu.equip(self.chr, self.chr:getPrimaryHandItem(), tool, true)
        ISTimedActionQueue.add(PK42ActionBleedCorpseOnHook:new(self.chr, self.hook, self, nil))
    end

    function NR_ButcherHookPanel:pkOnBleedIntoBucket(bucket)
        if not luautils.walkAdj(self.chr, self.hook:getSquare(), false) then return end
        local tool = SU.findButcherTool(self.chr:getInventory())
        if not tool then return end
        ISInventoryPaneContextMenu.transferIfNeeded(self.chr, tool)
        ISWorldObjectContextMenu.equip(self.chr, self.chr:getPrimaryHandItem(), tool, true)
        ISTimedActionQueue.add(PK42ActionBleedCorpseOnHook:new(self.chr, self.hook, self, bucket))
        ISTimedActionQueue.add(PK42GatherBloodFromCorpse:new(self.chr, self.hook, self, bucket))
    end

    function NR_ButcherHookPanel:pkOnButcher()
        if not luautils.walkAdj(self.chr, self.hook:getSquare(), false) then return end
        local tool = SU.findButcherTool(self.chr:getInventory())
        if not tool then return end
        ISInventoryPaneContextMenu.transferIfNeeded(self.chr, tool)
        ISWorldObjectContextMenu.equip(self.chr, self.chr:getPrimaryHandItem(), tool, true)
        ISTimedActionQueue.add(PK42ButcheringAction:new(self.chr, nil, nil, self.hook))
    end

    function NR_ButcherHookPanel:pkOnCollectBones()
        if not luautils.walkAdj(self.chr, self.hook:getSquare(), false) then return end
        ISTimedActionQueue.add(PK42CollectBonesAction:new(self.chr, nil, nil, self.hook))
    end

    function NR_ButcherHookPanel:pkOnRemove()
        if not luautils.walkAdj(self.chr, self.hook:getSquare(), false) then return end
        ISTimedActionQueue.add(PK42ActionRemoveCorpseFromHook:new(self.chr, self.hook))
    end

    -- Listener: PK42HookUI.lua só atualiza ISButcherHookUI.ui.
    -- Com o Rocco ativo, os painéis abertos vivem em NR_ButcherHookPanel.ui,
    -- então precisam do próprio listener pra refletir a confirmação do servidor.
    local function onServerCommandNR(module, command, args)
        if module ~= "PK42" then return end
        if command ~= "HookUpdated" then return end

        for _, ui in pairs(NR_ButcherHookPanel.ui) do
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
    Events.OnServerCommand.Add(onServerCommandNR)

    return true
end

-- Late init com retry (NR_ButcherHookPanel pode carregar depois deste arquivo)
local function lateInit()
    if patchNRButcherHookPanel() then return end

    local retries, maxRetries = 0, 300
    local function tick()
        retries = retries + 1
        if patchNRButcherHookPanel() or retries >= maxRetries then
            Events.OnTick.Remove(tick)
        end
    end
    Events.OnTick.Add(tick)
end

if Events.OnGameBoot then
    Events.OnGameBoot.Add(lateInit)
else
    Events.OnGameStart.Add(lateInit)
end