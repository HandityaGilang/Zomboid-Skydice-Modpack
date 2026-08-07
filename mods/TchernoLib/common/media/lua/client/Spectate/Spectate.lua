
require 'Spectate/ShSpectate'

--Mouse only
function Spectate.onSpectateStart()
    --kills ourselves if not already dead
    --local playerBefore = getPlayer()
    --if playerBefore and not playerBefore:isDead() then
    --    playerBefore:Kill(nil)
    --end
    
    setPlayerMouse(nil)--Vanilla: creates a nude default player at default position so the world loads and we got a camera to control
    ---wait until it is a local player and then make it a ghost
    function delaySpectateFunc(player)
        if player == getSpecificPlayer(0) and player:isLocalPlayer() then
            Spectate.doSpectatePlayer()--activates spectating mode on the default player
            Events.OnPlayerUpdate.Remove(delaySpectateFunc)
        end
    end
    Events.OnPlayerUpdate.Add(delaySpectateFunc)
end

local spectators = {}
function Spectate.doSpectatePlayer(playerObj)
    if not playerObj then playerObj = getPlayer() end
    if not playerObj then return end
    
    local playerKey = tostring(playerObj)
    if not spectators[playerKey] then--deactivate at reload
        Spectate.setSpectatePlayer(playerObj,true)
        spectators[playerKey] = true
    end
end

function Spectate.setSpectateMD(playerObj,isSpectate)
    if playerObj and playerObj.getModData then
        local changed = false
        if isSpectate ~= playerObj:getModData().isSpectate then
            playerObj:getModData().isSpectate = isSpectate;
            changed = true
            --sendPlayerExtraInfo(playerObj)--provokes AntiCheat Type8
        end
        if Spectate.Verbose then print('DBG Spectate.setSpectateMD(playerObj,isSpectate). '..p2str(playerObj)..' '..b2str(changed)..' '..b2str(isSpectate)..' '..b2str(playerObj:isLocalPlayer())..' '..b2str(Spectate.isSpectatorOther(playerObj))..' ') end
        if playerObj:isLocalPlayer() and (changed or not isSpectate or isSpectate ~= Spectate.isSpectatorOther(playerObj)) then
            Spectate.transmitSpectate(playerObj)
        end
    else
        print('Error Spectate.setSpectateMD(playerObj,isSpectate).')
    end
end

function Spectate.setInvisible(playerObj,forceInvis)
    if playerObj and forceInvis ~= playerObj:getSprite():getProperties():Is(IsoFlagType.invisible) then
        if forceInvis then
            if Spectate.Verbose then print('Spectate.SetInvisible '..p2str(playerObj)) end
            playerObj:getSprite():getProperties():Set(IsoFlagType.invisible)
        else
            if Spectate.Verbose then print('Spectate.UnsetInvisible '..p2str(playerObj)) end
            playerObj:getSprite():getProperties():UnSet(IsoFlagType.invisible)
        end
        --todo hide shadow
    end
end

function Spectate.isSpectatorLocal(playerObj)
    return playerObj and playerObj:getModData().isSpectate or false
end

function Spectate.isSpectating(playerObj)
    if Spectate.Verbose then print ("Spectate.isSpectating 1 "..p2str(playerObj)) end
    if playerObj then
        if playerObj:isLocalPlayer() then
            if Spectate.Verbose then print ("Spectate.isSpectating 2 "..p2str(playerObj)) end
            if Spectate.isSpectatorLocal(playerObj) then
                if Spectate.Verbose then print ("Spectate.isSpectating 4 "..p2str(playerObj)) end
                return true
            end
        else
            if Spectate.Verbose then print ("Spectate.isSpectating 3 "..p2str(playerObj)) end
            return Spectate.isSpectatorOther(playerObj)
        end
    end
    return false
end

----
function Spectate.transmitSpectate(playerObj)
    if not playerObj then return end
    local isSpectate = Spectate.isSpectatorLocal(playerObj)
    local args={userName=playerObj:getUsername(), id=playerObj:getOnlineID()}
    if isSpectate then args.spectate=isSpectate end
    if Spectate.Verbose then print ("Spectate.transmitSpectate "..p2str(playerObj)..' '..Spectate.ModId..' '..Spectate.CmdSpectate..' '..tab2str(args)) end
    sendClientCommand(playerObj, Spectate.ModId, Spectate.CmdSpectate, args)
end


function Spectate.setSpectatePlayer(playerObj,doit)
    if Spectate.Verbose then print ("Spectate.setSpectatePlayer 1 "..p2str(playerObj)..' '..b2str(doit)) end

    ISFastTeleportMove.cheat = doit;
    getDebugOptions():setBoolean("Cheat.Player.SeeEveryone",doit)
    getDebugOptions():setBoolean("Cheat.Player.InvisibleSprint",doit)
    getDebugOptions():setBoolean("Cheat.Player.StartInvisible",doit)
    
    if doit then
        Spectate.inhibitKeyBinding()
    else
        Spectate.exhibitKeyBinding()
    end
    
    if playerObj then
        Spectate.setInvisible(playerObj,doit)
        playerObj:setCanSeeAll(doit);
        playerObj:setNoClip(doit);
        playerObj:setGodMod(doit);
        playerObj:setInvincible(doit);
        playerObj:setInvisible(doit);
        playerObj:setZombiesDontAttack(doit);
        Spectate.setSpectateMD(playerObj,doit)
    end
end

function Spectate.stopSpectate(playerObj)
    if Spectate.Verbose then print ("Spectate.stopSpectate 1 "..p2str(playerObj)) end
    if Spectate.isSpectating(playerObj) then
        if Spectate.Verbose then print ("Spectate.stopSpectate 2 "..p2str(playerObj)) end
        Spectate.setSpectatePlayer(playerObj,false)
    elseif playerObj and playerObj:isLocalPlayer() and Spectate.isSpectatorOther(playerObj) then
        --correct server desynchro
        Spectate.setSpectateMD(playerObj,false)
    end
end

--release spectate I'm pretty sure it does nothing
function Spectate.releaseSpectate()
    if Spectate.Verbose then print ("Spectate.releaseSpectate 1 "..p2str(getPlayer())) end
    if spectators then
        Spectate.setSpectatePlayer(nil,false)
        spectators = {}
    end
end
Events.OnMainMenuEnter.Add(Spectate.releaseSpectate)


--INHIBIT Spectate assert at game load => clear it instead
--ensure spectate is reset at game join time
function Spectate.assertSpectate(playerObj)
    Spectate.stopSpectate(playerObj)
    if not Spectate.isSpectatorOther(playerObj) then
        Events.OnPlayerUpdate.Remove(Spectate.assertSpectate)
    end
end
Events.OnPlayerUpdate.Add(Spectate.assertSpectate)


--keybinding restrictions. TODO: replace by a fine tuning of altered keybindings
function Spectate.isKeyInhibited(keyName)
    if not keyName then return false end
    if keyName == "Forward" then return false end
    if keyName == "Backward" then return false end
    if keyName == "Left" then return false end
    if keyName == "Right" then return false end
    if keyName == "Zoom in" then return false end
    if keyName == "Zoom out" then return false end
    if keyName == "Pause" then return false end
    if keyName == "Normal Speed" then return false end
    if keyName == "Fast Forward x1" then return false end
    if keyName == "Fast Forward x2" then return false end
    if keyName == "Fast Forward x3" then return false end
    if keyName == "Take screenshot" then return false end
    if keyName == "Toggle Safety" then return false end
    if keyName == "Toggle chat" then return false end
    if keyName == "Alt toggle chat" then return false end
    if keyName == "Switch chat stream" then return false end
    if keyName == "Enable voice transmit" then return false end
    if keyName == "Toggle Lua Debugger" then return false end
    if keyName == "ToggleLuaConsole" then return false end
    if keyName == "ToggleGodModeInvisible" then return false end
    if keyName == "ToggleModelsEnabled" then return false end
    if keyName == "ToggleAnimationText" then return false end
    if keyName == "Toggle Survival Guide" then return false end
    if keyName == "Display FPS" then return false end
    if keyName == "Run" then return false end
    if keyName == "Sprint" then return false end
    if keyName == "Toggle Inventory" then return false end
    --if keyName == "Aim" then return false end
    --if keyName == "surrender" then return false end
    --if keyName == "emote" then return false end
    --if keyName == "Crouch" then return false end
    --if keyName == "Shout" then return false end
    --if keyName == "Interact" then return false end--this inhibits everything called with mouse click & 'E' key. with the exception of lights
    return true;
end
Spectate.keyBindingMemo = nil
function Spectate.inhibitKeyBinding()
    if not Spectate.keyBindingMemo then
        Spectate.keyBindingMemo = {}
        for i,v in ipairs(keyBinding) do
            if v.key and v.key ~= 0 and Spectate.isKeyInhibited(v.value) then
                Spectate.keyBindingMemo[v.value] = v.key;
                v.key = 0
                getCore():addKeyBinding(v.value, v.key)
                if Spectate.Verbose then print ("inhibitKeyBinding "..v.value.." from "..Spectate.keyBindingMemo[v.value].." to "..v.key) end
            end
        end
    end
end
function Spectate.exhibitKeyBinding()
    if Spectate.keyBindingMemo then
        for i,v in ipairs(keyBinding) do
            if v.key == 0 and v.value and Spectate.keyBindingMemo[v.value] then
                v.key = Spectate.keyBindingMemo[v.value];
                getCore():addKeyBinding(v.value, v.key)
                if Spectate.Verbose then print ("exhibitKeyBinding "..v.value.." from ".. 0 .." to "..v.key) end
            end
        end
        Spectate.keyBindingMemo = nil
    end
end

