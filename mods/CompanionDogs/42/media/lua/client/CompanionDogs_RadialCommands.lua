require "ISUI/ISEmoteRadialMenu"

local CD = CompanionDogs

CD.RADIAL_COMMANDS = {
    cd_come    = { gesture = "comehere",  cmd = "come",     shout = false },
    cd_follow  = { gesture = "followme",  cmd = "setstate",     args = { state = CD.STATE_FOLLOW } },
    cd_stay    = { gesture = "stop",      cmd = "setstate",     args = { state = CD.STATE_STAY } },
    cd_guard   = { gesture = "stop",      cmd = "setstate",     args = { state = CD.STATE_GUARD } },
    cd_alert   = { cmd = "setalertmode",  args = { mode = "full" } },
    cd_quiet   = { cmd = "setalertmode",  args = { mode = "quiet" } },
    cd_silent  = { cmd = "setalertmode",  args = { mode = "silent" } },
    cd_attack  = { gesture = "signalfire", cmd = "attack",  shout = false },
    cd_hunt    = { cmd = "sethuntmode",   toggle = true },
    cd_openbag = { cmd = "bagopen" },
}

local LEAF_ICONS = {
    cd_come    = "media/ui/emotes/comehere.png",
    cd_follow  = "media/ui/emotes/followme.png",
    cd_stay    = "media/ui/emotes/stop.png",
    cd_guard   = "media/ui/emotes/salute.png",
    cd_alert   = "media/ui/emotes/moveout.png",
    cd_quiet   = "media/ui/emotes/freeze.png",
    cd_silent  = "media/ui/emotes/no.png",
    cd_attack  = "media/ui/emotes/fire.png",
    cd_hunt    = "media/textures/CDDogPaw_64.png",
    cd_openbag = "Item_Satchel_Leather",
}

function CD.injectDogRadialCategory(dog)
    local menu = ISEmoteRadialMenu.menu
    if not menu then return end
    menu["cd_dog"] = {
        name = (dog and CD.breedNoun(dog)) or getText("IGUI_PD_RadialCategory"),
        subMenu = {
            cd_come    = getText("IGUI_PD_CmdCome"),
            cd_follow  = getText("IGUI_PD_CmdFollow"),
            cd_stay    = getText("IGUI_PD_CmdStay"),
            cd_guard   = getText("IGUI_PD_CmdGuard"),
            cd_alert   = getText("IGUI_PD_AlertOn"),
            cd_quiet   = getText("IGUI_PD_AlertQuiet"),
            cd_silent  = getText("IGUI_PD_AlertSilent"),
            cd_attack  = getText("IGUI_PD_CmdAttack"),
            cd_hunt    = (dog and CD.getHuntMode(dog)) and getText("IGUI_PD_CmdHuntOff") or getText("IGUI_PD_CmdHunt"),
        },
    }
    if dog and CD.hasBag and CD.hasBag(dog) then
        menu["cd_dog"].subMenu.cd_openbag = getText("IGUI_PD_OpenBag")
    end
    local icons = ISEmoteRadialMenu.icons
    if icons then
        icons["cd_dog"] = getTexture("media/textures/CDDogPaw_64.png")
        for id, path in pairs(LEAF_ICONS) do
            icons[id] = getTexture(path)
        end
    end
end

function CD.runRadialDogCommand(player, spec)
    if not player then return end
    if spec.gesture then
        pcall(function() player:playEmote(spec.gesture) end)
    end
    if spec.shout then
        pcall(function() player:Callout(false) end)
    end
    local dog = CD.getCompanionAnimal(player)
    if dog then
        if spec.cmd == "bagopen" then
            if CD.openBagWindow then CD.openBagWindow(dog) end   -- guarda a ref viva (getAnimal e nil em SP)
        else
            local extra = nil
            if spec.args then
                extra = {}
                for k, v in pairs(spec.args) do extra[k] = v end
            end
            if spec.toggle and spec.cmd == "sethuntmode" then
                extra = extra or {}
                extra.on = not CD.getHuntMode(dog)
            end
            CD.request(spec.cmd, dog, extra)
        end
    end
    pcall(function() player:setJoypadIgnoreAimUntilCentered(true) end)
end

if ISEmoteRadialMenu then
    local Emote_fillMenu = ISEmoteRadialMenu.fillMenu
    function ISEmoteRadialMenu:fillMenu(submenu)
        if not submenu and self.character and ISEmoteRadialMenu.menu then
            local dog = CD.getCompanionAnimal(self.character)
            if dog then
                CD.injectDogRadialCategory(dog)
            else
                ISEmoteRadialMenu.menu["cd_dog"] = nil
            end
        end
        return Emote_fillMenu(self, submenu)
    end

    local Emote_emote = ISEmoteRadialMenu.emote
    function ISEmoteRadialMenu:emote(emote)
        local spec = CD.RADIAL_COMMANDS[emote]
        if spec then
            CD.runRadialDogCommand(self.character, spec)
            return
        end
        return Emote_emote(self, emote)
    end
end
