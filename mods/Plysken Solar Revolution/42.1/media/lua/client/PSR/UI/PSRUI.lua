local string, math, getText = string, math, getText

---@class PSR
local PSR = require "PSR/Utilities"
require "PSR/TimedActions/DisconnectPanel"
require "PSR/TimedActions/LinkBanks"
require "PSR/TimedActions/UnlinkBanks"
require "PSR/TimedActions/LinkComputer"
require "PSR/TimedActions/UnlinkComputer"
require "PSR/TimedActions/ConnectStructure"
require "PSR/UI/PSRComputerPanel"

-- Desktop Computer vanilla sprites — la famille `GroupName = Desktop` COMPLÈTE (8 sprites).
--
-- 🔴 AJOUT 2026-08-05 : `_76.._79` manquaient depuis l'origine. Relevé dans
-- `<vanilla>\media\newtiledefinitions.tiles.txt` (source de vérité, pas une supposition) :
--   · `_72.._75` = version MOVEABLE — `Facing = S/E/N/W`, `IsMoveAble`, `PickUpWeight = 100`.
--     C'est l'ordinateur que le joueur POSE lui-même.
--   · `_76.._79` = version DÉCOR DE CARTE — même `GroupName = Desktop`, mêmes matériaux, même
--     `Surface = 34`, mais NI `Facing` NI `IsMoveAble` (donc ni pose ni ramassage possible), et
--     `CustomName = CustomName` (placeholder resté dans le vanilla).
--   · `tileDepthTextureAssignments.txt` les apparie UN POUR UN : 76→72, 77→73, 78→74, 79→75
--     ⇒ même objet, mêmes 4 orientations. Ce ne sont pas d'autres meubles.
-- ⚠️ PORTÉE RÉELLE, MESURÉE (ne pas la surestimer, je l'ai fait le jour même) : comptage sur les
--    4 112 `.lotheader` du jeu — `_72.._75` apparaissent dans **121 à 141 cellules** chacun,
--    `_76.._79` dans **6 cellules réelles** au total (Muldraugh 23_20, 25_20, 25_21, 25_29,
--    41_40, 59_0) + la map tutoriel. La carte place donc massivement la variante que la table
--    connaissait DÉJÀ. Ceci ferme un trou authentique mais MARGINAL — ce n'est PAS
--    « les ordinateurs de la carte ne marchaient pas » (testé : poste de police de Rosewood, OK
--    avant comme après). 📌 8 sprites dans le tiledef ne dit rien de leur FRÉQUENCE sur la carte.
-- 🔑 7ᵉ motif `Sword` de la série : la couverture s'arrête à l'objet qu'on a sous la main et jamais
--    à sa FAMILLE. Le geste qui trouve ces trous est toujours le même — énumérer la famille dans
--    les données du jeu (ici `GroupName = Desktop` ⇒ 8 sprites) et la croiser avec notre table.
-- ⚠️ Cette table est le POINT UNIQUE d'identification par sprite : le serveur re-résout
--    l'ordinateur par coordonnées + nom de sprite (`LinkComputer:complete()`), et tout le reste du
--    mod le reconnaît par son TAG `PSR_linkedBank`. Aucun jumeau à synchroniser — mais si un jour
--    une seconde liste apparaît, c'est ce trou-ci qui se rouvre.
local PSR_COMPUTER_SPRITES = {
    -- moveable (posé par le joueur)
    ["appliances_com_01_72"] = true,
    ["appliances_com_01_73"] = true,
    ["appliances_com_01_74"] = true,
    ["appliances_com_01_75"] = true,
    -- décor de carte (déjà posé dans le monde)
    ["appliances_com_01_76"] = true,
    ["appliances_com_01_77"] = true,
    ["appliances_com_01_78"] = true,
    ["appliances_com_01_79"] = true,
}

-- Returns the first PSR PowerBank found within Chebyshev ≤ 1 (inclut la même case).
-- Prend l'IsoObject directement et utilise getX/getY/getZ pour éviter getSquare() nil
-- (getSquare() peut retourner nil quand un moveable est posé sur un meuble en B42).
-- Renvoie EN PRIORITÉ une bank encore LIBRE (sans ordinateur lié). À défaut, la première trouvée —
-- pour pouvoir expliquer au joueur qu'elle est déjà prise, au lieu de le laisser cliquer dans le vide.
-- 🔴 Ajouté 2026-08-04 : l'ancienne version rendait la première bank rencontrée sans regarder si
-- elle était disponible. Avec deux banks adjacentes dont la première était prise, l'option
-- « Connect » s'affichait, l'animation jouait, et `LinkComputer:complete()` sortait en silence —
-- alors qu'une bank libre était juste à côté.
local function findAdjacentBank(obj)
    local x = obj:getX()
    local y = obj:getY()
    local z = obj:getZ()
    local firstTaken
    for dx = -1, 1 do
        for dy = -1, 1 do
            local adj = getSquare(x + dx, y + dy, z)
            if adj then
                local bank = PSR.WorldUtil.findTypeOnSquare(adj, "PowerBank")
                if bank then
                    if not bank:getModData().PSR_computer then return bank end   -- libre : on la prend
                    firstTaken = firstTaken or bank
                end
            end
        end
    end
    return firstTaken
end

local function onLinkComputer(player, computer, bankIso)
    local character = getSpecificPlayer(player)
    local sq = getSquare(computer:getX(), computer:getY(), computer:getZ())
    if luautils.walkAdj(character, sq, true) then
        ISTimedActionQueue.add(PSR.LinkComputer:new(character, computer, bankIso))
    end
end

local function onUnlinkComputer(player, computer)
    local character = getSpecificPlayer(player)
    local sq = getSquare(computer:getX(), computer:getY(), computer:getZ())
    if luautils.walkAdj(character, sq, true) then
        ISTimedActionQueue.add(PSR.UnlinkComputer:new(character, computer))
    end
end

-- Déliaison DEPUIS LA BANK. On marche jusqu'à la BANK, pas jusqu'à l'ordinateur : dans le cas qui
-- a motivé cette option, l'ordinateur n'existe plus (ou n'est plus le bon), et sa case peut être
-- à l'autre bout de la base. La bank, elle, est sous les yeux du joueur.
local function onUnlinkComputerFromBank(player, bankIso, comp)
    local character = getSpecificPlayer(player)
    local sq = getSquare(bankIso:getX(), bankIso:getY(), bankIso:getZ())
    if luautils.walkAdj(character, sq, true) then
        ISTimedActionQueue.add(PSR.UnlinkComputer:newFromBank(character, bankIso, comp))
    end
end

local function onOpenDeviceManagement(player, computer)
    PSR.ComputerPanel.OnOpen(player, computer)
end

local UI = {}

local rgbDefault, rgbGood, rgbBad = { r = 1, g = 1, b = 1, rich = " <RGB:1,1,1> " }, {}, {}
UI.rgbDefault, UI.rgbGood, UI.rgbBad = rgbDefault, rgbGood, rgbBad

function UI.updateColours()
    local core = getCore()
    local good = core:getGoodHighlitedColor()
    rgbGood.ColorInfo = good
    rgbGood.r, rgbGood.g, rgbGood.b = good:getR(), good:getG(), good:getB()
    rgbGood.rich = string.format(" <RGB:%.2f,%.2f,%.2f> ", rgbGood.r, rgbGood.g, rgbGood.b)
    local bad = core:getBadHighlitedColor()
    rgbBad.ColorInfo = bad
    rgbBad.r, rgbBad.g, rgbBad.b = bad:getR(), bad:getG(), bad:getB()
    rgbBad.rich = string.format(" <RGB:%.2f,%.2f,%.2f> ", rgbBad.r, rgbBad.g, rgbBad.b)
end

function UI.onConnectPanel(player,panel,luaPb)
    local character = getSpecificPlayer(player)
    if luautils.walkAdj(character, panel:getSquare(), true) then
        ISTimedActionQueue.add(PSR.ConnectPanel:new(character, panel, luaPb, luaPb.x, luaPb.y, luaPb.z, panel:getX(), panel:getY(), panel:getZ(), panel:getTextureName()))
    end
end

function UI.onDisconnectPanel(player, panel, luaPb)
    local character = getSpecificPlayer(player)
    if luautils.walkAdj(character, panel:getSquare(), true) then
        ISTimedActionQueue.add(PSR.DisconnectPanel:new(character, panel, luaPb))
    end
end

local function ActivatePowerbank(player,powerbank,activate)
    local character = getSpecificPlayer(player)
    -- ⚠️ Garde ajoutée 2026-08-04 (audit) : ce handler s'exécute au CLIC, pas à l'ouverture du
    -- menu. Entre les deux, la bank peut avoir été ramassée — en MP par un autre joueur. Un
    -- `getSquare()` nil partait alors dans `walkAdj`. La fenêtre est étroite mais réelle, et le
    -- coût de la garde est nul.
    local sq = powerbank and powerbank.getSquare and powerbank:getSquare()
    if not (character and sq) then return end
    if luautils.walkAdj(character, sq, true) then
        ISTimedActionQueue.add(PSR.ActivatePowerbank:new(character, powerbank, activate, powerbank:getX(), powerbank:getY(), powerbank:getZ()))
    end
end

local function onConnectPanelCursor(player, square, powerbank)
    return PSR.ConnectPanelCursor:new(player, square, powerbank)
end

local function onLinkBank(player, bankIso, targetIso)
    local character = getSpecificPlayer(player)
    if luautils.walkAdj(character, bankIso:getSquare(), true) then
        ISTimedActionQueue.add(PSR.LinkBanks:new(character, bankIso, targetIso))
    end
end

local function onUnlinkAll(player, bankIso)
    local character = getSpecificPlayer(player)
    if luautils.walkAdj(character, bankIso:getSquare(), true) then
        ISTimedActionQueue.add(PSR.UnlinkBanks:new(character, bankIso, nil))
    end
end

local function onUnlinkOne(player, bankIso, targetIso)
    local character = getSpecificPlayer(player)
    if luautils.walkAdj(character, bankIso:getSquare(), true) then
        ISTimedActionQueue.add(PSR.UnlinkBanks:new(character, bankIso, targetIso))
    end
end

-- Toggle-connect a player-built extension square to the nearest Power Bank (accounting only).
local function onToggleStructure(player, ax, ay, az)
    local character = getSpecificPlayer(player)
    local sq = getSquare(ax, ay, az)
    if sq and luautils.walkAdj(character, sq, true) then
        ISTimedActionQueue.add(PSR.ConnectStructure:new(character, ax, ay, az))
    end
end

local _powerbank

function UI.OnPreFillWorldObjectContextMenu(player, context, worldobjects, test)
    local generator = ISWorldObjectContextMenu.fetchVars.generator
    if generator ~= nil and PSR.WorldUtil.objectIsType(generator, "PowerBank") then
        _powerbank = generator
        ISWorldObjectContextMenu.fetchVars.generator = nil
    end
end

function UI.OnFillWorldObjectContextMenu(player, context, worldobjects, test)
    if test and ISWorldObjectContextMenu.Test then return true end
    local powerbank = _powerbank
    local panel
    local computer
    --local panels = {}

    for _, obj in ipairs(worldobjects) do
        local sprite = obj:getTextureName()
        local type = PSR.WorldUtil.PSRTypes[sprite]
        if type == "PowerBank" then
            powerbank = obj
        elseif type == "Panel" then
            panel = obj
            --table.insert(panels,obj)
        elseif PSR_COMPUTER_SPRITES[sprite] then
            computer = obj
        end
    end

    if powerbank then
        _powerbank = nil
        local square = powerbank:getSquare()
        -- ⚠️ Garde ajoutée 2026-08-04 (audit) : `getSquare()` rend nil si l'objet a été retiré du
        -- monde entre-temps. `square` est ensuite passée à 2 options du menu et lue plus bas ⇒
        -- sans cette sortie, on construisait un menu dont les entrées plantent au clic. On
        -- n'affiche simplement pas le menu d'une bank qui n'est plus posée.
        if not square then return end

        if test then return ISWorldObjectContextMenu.setTest() end
        local PSRSubMenu = context:getNew(context)
        context:addSubMenu(context:addOption(getText("ContextMenu_PSR_BatteryBank")), PSRSubMenu)
        if test then return ISWorldObjectContextMenu.setTest() end
        PSRSubMenu:addOption(getText("ContextMenu_PSR_BatteryBankStatus"), player, PSR.StatusWindow.OnOpenPanel, square)
        local isOn = powerbank:getModData()["on"]
        local textOn = isOn and getText("ContextMenu_Turn_Off") or getText("ContextMenu_Turn_On")
        if test then return ISWorldObjectContextMenu.setTest() end
        PSRSubMenu:addOption(textOn, player, ActivatePowerbank, powerbank, not isOn)
        if test then return ISWorldObjectContextMenu.setTest() end
        PSRSubMenu:addOption(getText("ContextMenu_PSR_ConnectPanels"), player, onConnectPanelCursor, square, powerbank)

        -- Link / Unlink bank options
        local bankX, bankY, bankZ = powerbank:getX(), powerbank:getY(), powerbank:getZ()
        local pbModData    = powerbank:getModData()
        local linkedBanks  = pbModData.PSR_linkedBanks or {}
        local adjSquares   = PSR.WorldUtil.getAdjacentBankSquares(bankX, bankY, bankZ)
        for _, adjSq in ipairs(adjSquares) do
            local adjIso = PSR.WorldUtil.findTypeOnSquare(adjSq, "PowerBank")
            if adjIso then
                local ax, ay, az = adjSq:getX(), adjSq:getY(), adjSq:getZ()
                local alreadyLinked = false
                for _, link in ipairs(linkedBanks) do
                    if link.x == ax and link.y == ay and link.z == az then alreadyLinked = true; break end
                end
                if not alreadyLinked then
                    local dir = PSR.WorldUtil.getDirection(bankX, bankY, ax, ay)
                    if test then return ISWorldObjectContextMenu.setTest() end
                    PSRSubMenu:addOption(getText("ContextMenu_PSR_LinkBank") .. " (" .. dir .. ")", player, onLinkBank, powerbank, adjIso)
                end
            end
        end
        for _, link in ipairs(linkedBanks) do
            local linkedSq = getSquare(link.x, link.y, link.z)
            local linkedIso = linkedSq and PSR.WorldUtil.findTypeOnSquare(linkedSq, "PowerBank")
            if linkedIso then
                local dir = PSR.WorldUtil.getDirection(bankX, bankY, link.x, link.y)
                if test then return ISWorldObjectContextMenu.setTest() end
                PSRSubMenu:addOption(getText("ContextMenu_PSR_UnlinkBank") .. " (" .. dir .. ")", player, onUnlinkOne, powerbank, linkedIso)
            end
        end
        if #linkedBanks > 1 then
            if test then return ISWorldObjectContextMenu.setTest() end
            PSRSubMenu:addOption(getText("ContextMenu_PSR_UnlinkAll"), player, onUnlinkAll, powerbank)
        end

        -- Déliaison de l'ordinateur DEPUIS LA BANK (signal joueur Zephyrum, 2026-08-04).
        -- Jusqu'ici la seule option de déliaison vivait sur l'ORDINATEUR : quand celui-ci
        -- disparaissait (démontage), l'entrée côté bank survivait et plus rien ne pouvait l'effacer
        -- — la bank refusait alors SILENCIEUSEMENT tout nouvel ordinateur, définitivement.
        -- 🔑 Une issue de secours ne doit pas vivre sur l'objet qui peut disparaître.
        -- Affichée dès que la bank porte l'entrée, que l'ordinateur soit encore là ou non : c'est
        -- précisément quand il n'est plus là qu'elle est indispensable.
        local comp = pbModData.PSR_computer
        if comp then
            if test then return ISWorldObjectContextMenu.setTest() end
            PSRSubMenu:addOption(getText("ContextMenu_PSR_DisconnectComputerFromBank"), player,
                onUnlinkComputerFromBank, powerbank, comp)
        end
    end

    if panel then
            if test then return ISWorldObjectContextMenu.setTest() end
            local panelOption = context:addOption(getText("ContextMenu_PSR_SolarPanel"))
            local options = PSR.PBSystem_Client.canConnectPanelTo(panel)
            if #options > 0 then
                local PSRSubMenu = context:getNew(context)
                context:addSubMenu(panelOption, PSRSubMenu)
                for i,opt in ipairs(options) do
                    if test then return ISWorldObjectContextMenu.setTest() end
                    local isConnected = opt[4]
                    local optText = isConnected and getText("ContextMenu_PSR_Disconnect_Panel") or getText("ContextMenu_PSR_Connect_Panel")
                    local optFn = isConnected and UI.onDisconnectPanel or UI.onConnectPanel
                    local option = PSRSubMenu:addOption(optText, player, optFn, panel, opt[1])
                    local tooltip = ISWorldObjectContextMenu.addToolTip()
                    tooltip:setName(getText("ContextMenu_PSR_BatteryBank"))
                    tooltip.description = isConnected and rgbGood.rich .. getText("ContextMenu_PSR_Connect_Panel_toolTip_isConnected") or rgbBad.rich .. getText("ContextMenu_PSR_Connect_Panel_toolTip_isConnected_false")
                    tooltip.description = tooltip.description .. (rgbDefault.rich .. "<BR>" .. "( "..opt[2].." : "..opt[3].." )" .. getText("ContextMenu_PSR_Connect_Panel_toolTip"))
                    option.toolTip = tooltip
                end
            else
                if test then return ISWorldObjectContextMenu.setTest() end
                local tooltip = ISWorldObjectContextMenu.addToolTip()
                if options.inside then
                    tooltip.description = rgbBad.rich .. getText("ContextMenu_PSR_Connect_Panel_toolTip_isOutside")
                else
                    tooltip.description = rgbBad.rich .. getText("ContextMenu_PSR_Connect_Panel_NoPowerbank")
                end
                panelOption.toolTip = tooltip
                panelOption.notAvailable = true
                panelOption.onSelect = nil
            end
        end

    if computer then
        local compModData = computer:getModData()
        local isLinked    = compModData.PSR_linkedBank ~= nil
        if test then return ISWorldObjectContextMenu.setTest() end
        local compOption  = context:addOption(getText("ContextMenu_PSR_Computer"))
        local compSubMenu = context:getNew(context)
        context:addSubMenu(compOption, compSubMenu)
        if isLinked then
            if test then return ISWorldObjectContextMenu.setTest() end
            compSubMenu:addOption(getText("ContextMenu_PSR_OpenDeviceManagement"), player, onOpenDeviceManagement, computer)
            if test then return ISWorldObjectContextMenu.setTest() end
            compSubMenu:addOption(getText("ContextMenu_PSR_DisconnectComputer"), player, onUnlinkComputer, computer)
        else
            local adjBank = findAdjacentBank(computer)
            -- 🔴 REFUS MUET FERMÉ (audit 2026-08-04). Mon correctif du matin avait supprimé l'état
            -- BLOQUÉ (entrée fantôme) mais laissé le refus silencieux : `LinkComputer:complete()`
            -- sort sur `if pb.PSR_computer then return true end`, et le menu décidait d'afficher
            -- « Connect » en regardant UNIQUEMENT le côté ordinateur. Poser un 2ᵉ ordinateur près
            -- d'une bank déjà liée affichait donc une option active, jouait l'animation, et ne
            -- faisait rien — sans un mot. *J'avais corrigé la moitié du bug.*
            -- Le menu interroge désormais le côté BANK, qui est celui que le serveur consulte.
            local bankTaken = adjBank and adjBank:getModData().PSR_computer ~= nil
            if test then return ISWorldObjectContextMenu.setTest() end
            local canLink = adjBank and not bankTaken
            local connectOpt = compSubMenu:addOption(getText("ContextMenu_PSR_ConnectComputer"), player, canLink and onLinkComputer or nil, computer, adjBank)
            if not canLink then
                connectOpt.notAvailable = true
                local tooltip = ISWorldObjectContextMenu.addToolTip()
                tooltip.description = rgbBad.rich .. getText(adjBank
                    and "ContextMenu_PSR_Computer_BankHasComputer"
                    or  "ContextMenu_PSR_Computer_NoBankAdjacent")
                connectOpt.toolTip = tooltip
            end
        end
    end

    -- Connect / disconnect a PLAYER-BUILT extension to the PSR network (opt-in accounting only —
    -- the extension is already powered by the vanilla generator radius). Eligible square = built by
    -- the player: getBuilding()==nil AND not a map-baked building (metagrid), with a Thumpable floor/
    -- wall present. The owning bank is resolved server-side (nearest in range) when clicked.
    local structSq = worldobjects and worldobjects[1] and worldobjects[1]:getSquare()
    if structSq and structSq:getBuilding() == nil then
        local mg = getWorld() and getWorld():getMetaGrid()
        local mapBaked = mg and mg:getBuildingAt(structSq:getX(), structSq:getY()) ~= nil
        if not mapBaked then
            -- Un IsoThumpable seul ne suffit pas : n'importe quel mod tiers peut poser une entite
            -- Thumpable (etabli, meuble...) sur une case hors batiment, ce qui faisait apparaitre
            -- l'option a tort (signal Commandeur 2026-07-26 : etabli de chantier PUR). On exige en
            -- plus que le sprite du thumpable porte un flag mur/sol reel (meme API que la vanilla
            -- ISPaintAction.lua : sprite:getProperties():has("WallN"/"WallW"/"WallNW") ou solidfloor).
            local function psrIsStructural(o)
                local sprite = o.getSprite and o:getSprite()
                local props = sprite and sprite:getProperties()
                if not props then return false end
                return props:has("WallN") or props:has("WallW") or props:has("WallNW")
                    or (IsoFlagType and props:has(IsoFlagType.solidfloor))
            end
            local hasThump, tagged = false, false
            local sObjs = structSq:getObjects()
            if sObjs then
                for i = 0, sObjs:size() - 1 do
                    local o = sObjs:get(i)
                    if o and instanceof(o, "IsoThumpable") and psrIsStructural(o) then
                        hasThump = true
                        if o:getModData().PSR_structBank then tagged = true end
                    end
                end
            end
            if hasThump then
                if test then return ISWorldObjectContextMenu.setTest() end
                local label = tagged and getText("ContextMenu_PSR_DisconnectStructure")
                                       or getText("ContextMenu_PSR_ConnectStructure")
                context:addOption(label, player, onToggleStructure, structSq:getX(), structSq:getY(), structSq:getZ())
            end
        end
    end
end

function UI.ISInventoryPane_drawItemDetails_patch(drawItemDetails)
    local NewColorInfo = ColorInfo:new()

    return function(self,item, y, xoff, yoff, red,...)
        if not item then return end
        if not (item:getModData().PSR_maxCapacity) then
            return drawItemDetails(self,item, y, xoff, yoff, red,...)
        else
            local hdrHgt = self.headerHgt
            local top = hdrHgt + y * self.itemHgt + yoff
            rgbBad.ColorInfo:interp(rgbGood.ColorInfo, item:getCondition()/100, NewColorInfo)
            local fgBar = {r=NewColorInfo:getR(),g=NewColorInfo:getG(),b=NewColorInfo:getB(),a=1}
            local fgText = red and {r=0.0, g=0.0, b=0.5, a=0.7} or {r=0.6, g=0.8, b=0.5, a=0.6}
            self:drawTextAndProgressBar(getText("Tooltip_weapon_Condition") .. ":", item:getCondition()/100, xoff, top, fgText, fgBar)
        end
    end
end

function UI.DoTooltip_patch(DoTooltip)
    return function(item,tooltip)
        local maxCapacity = item:getModData().PSR_maxCapacity
        if not maxCapacity then
            return DoTooltip(item,tooltip)
        else
            local lineHeight = tooltip:getLineSpacing()
            local font = tooltip:getFont()
            local y = 5
            --tooltip:render()
            tooltip:DrawText(font, item:getName(), 5, 5, 1, 1, 0.8, 1)
            y = y + lineHeight + 5
            --adjustWidth(5, name;
            local layout = tooltip:beginLayout()
            --setminwidth
            local option
            if tooltip:getWeightOfStack() > 0 then
                option = layout:addItem()
                option:setLabel(getText("Tooltip_item_StackWeight")..":",1,1,0.8,1)
                option:setValueRightNoPlus(tooltip:getWeightOfStack())
            else
                option = layout:addItem()
                option:setLabel(getText("Tooltip_item_Weight")..":",1,1,0.8,1)
                option:setValue(string.format("%.2f",item:isEquipped() and item:getEquippedWeight() or item:getUnequippedWeight()),1,1,0.8,1)
                option = layout:addItem()
                option:setLabel(getText("IGUI_invpanel_Remaining")..":",1,1,0.8,1)
                option:setValue(string.format("%d%%",item:getCurrentUsesFloat()*100),1,1,0.8,1)
                option = layout:addItem()
                option:setLabel(getText("Tooltip_weapon_Condition")..":",1,1,0.8,1)
                option:setValue(string.format("%d%%",item:getCondition()),1,1,0.8,1)
                option = layout:addItem()
                option:setLabel(getText("Tooltip_container_Capacity")..":",1,1,0.8,1)
                option:setValue(string.format("%d / %d",maxCapacity * (1 - math.pow((1 - (item:getCondition()/100)),6)),maxCapacity),1,1,0.8,1)
            end
            y = layout:render(5,y,tooltip)
            tooltip:endLayout(layout)
            --if width < 150 -- tooltip:setWidth(tooltip:getWidth())
            tooltip:setHeight(y+5)
        end
    end
end

UI.updateColours()

Events.OnPreFillWorldObjectContextMenu.Add(UI.OnPreFillWorldObjectContextMenu)
Events.OnFillWorldObjectContextMenu.Add(UI.OnFillWorldObjectContextMenu)

Events.OnServerCommand.Add(function(module, command, args)
    if module ~= "PSR" or command ~= "notification" then return end
    local players = IsoPlayer.getPlayers()
    if players and players:size() > 0 then
        -- B42 : addText(char, text, ColorInfo) n'existe plus → 2-arg / addGoodText / addBadText.
        -- Gardes d'existence = convention de la gamme (cf. PIP PIPClientCommands / PIPEnrichAction).
        local pl  = players:get(0)
        local txt = getText(args.key)
        if pl and HaloTextHelper then
            if args.kind == "bad" and HaloTextHelper.addBadText then HaloTextHelper.addBadText(pl, txt)
            elseif args.kind == "good" and HaloTextHelper.addGoodText then HaloTextHelper.addGoodText(pl, txt)
            elseif HaloTextHelper.addText then HaloTextHelper.addText(pl, txt) end
        end
    end
end)

--------------------------------------------------------------------------------
-- 🖱️ CLIC GAUCHE SUR LE SOLAR COMPUTER = OUVRIR LA GESTION D'APPAREILS
--------------------------------------------------------------------------------
-- Demande Commandeur 2026-08-04, calquée sur l'établi de PUR (`PUR_Bench.lua:410`) :
-- le vanilla route le clic gauche objet vers `ISObjectClickHandler.doClick` ; on ne le
-- détourne pas, on s'abonne à l'event public à côté — s'insérer, pas s'imposer.
--
-- Trois gardes, et chacune évite un faux positif :
--   1. C'est bien un Solar Computer LIÉ — reconnu par son `PSR_linkedBank` (un TAG), jamais par
--      son sprite. Un ordinateur quelconque, ou lié à rien, ne déclenche pas : la fenêtre n'a
--      alors rien à piloter (`ComputerPanel.OnOpen` le revérifie de son côté, défense en profondeur).
--   2. AUCUN curseur de pose actif — sinon un clic destiné à poser un panneau ou une bank
--      ouvrirait le panneau par-dessus le curseur qu'on vient d'armer.
--   3. Le joueur est À PORTÉE (2 cases, même niveau) : un clic sur un ordinateur à l'autre bout
--      de l'écran est un clic de DÉPLACEMENT, pas une intention d'ouvrir un menu.
Events.OnObjectLeftMouseButtonUp.Add(function(obj)
    if not (obj and obj.getModData and obj:getModData().PSR_linkedBank) then return end
    if not (PSR.ComputerPanel and PSR.ComputerPanel.OnOpen) then return end

    local pl = getSpecificPlayer(0); if not pl then return end
    if getCell() and getCell().getDrag and getCell():getDrag(pl:getPlayerNum()) then return end

    local sq = obj.getSquare and obj:getSquare(); if not sq then return end
    local dx = math.abs(sq:getX() - pl:getX())
    local dy = math.abs(sq:getY() - pl:getY())
    if sq:getZ() ~= math.floor(pl:getZ()) or math.max(dx, dy) > 2 then return end

    PSR.ComputerPanel.OnOpen(pl:getPlayerNum(), obj)
end)

PSR.UI = UI
