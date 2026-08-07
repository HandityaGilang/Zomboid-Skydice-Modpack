Tch = Tch or {}
Tch.prefix = "Tch"
Tch.inhibitedControlKeys = {
"Forward" ,
"Backward",
"Left"    ,
"Right"   ,
"Run"     ,
"Interact",
"Sprint"  
}

Tch.keyControlClient ={}
local getCore = getCore

local function getKeyBinding2POD(core, keyCore)
    return {k = core:getKey(keyCore), j = core:getAltKey(keyCore)}--we got no way to get shift ctrl alt from core (but we could parse lua keyBinding struct)
end

local function serializeKeyBinding2POD(playerObj, core, keyCore, clearCore)
    local keyPlayer = Tch.prefix..keyCore
    playerObj:getModData()[keyPlayer] = getKeyBinding2POD(core,keyCore)
    if clearCore then
        core:addKeyBinding(keyCore, Keyboard.KEY_NONE, Keyboard.KEY_NONE, false, false, false)
    end
end

local function deserializePOD2KeyBinding(core, keyCore, playerObj, consumeMD)
    local key = Keyboard.KEY_NONE
    local altKey = Keyboard.KEY_NONE
    local shiftB = false
    local ctrl = false
    local alt = false
    local keyPlayer = Tch.prefix..keyCore
    local md = playerObj and playerObj:getModData()[keyPlayer]
    if md then
        key = md.k or key
        altKey = md.j or altKey
        shiftB = md.s or shiftB
        ctrl = md.c or ctrl
        alt = md.a or alt
        if consumeMD then playerObj:getModData()[keyPlayer] = nil end
    end
    local keyBefore = core:getKey(keyCore)
    --print('Reload key binding '..tostring(keyCore)..' '..tostring(key))
    core:addKeyBinding(keyCore, key, altKey, shiftB, ctrl, alt)
end

function Tch.getInteractionControl(playerObj)
    local md = playerObj and playerObj:getModData()
    return md and md[Tch.prefix.."Interact"]
end

function Tch.istKeyInteraction(playerObj, key)
    return Tch.istKey(playerObj, "Interact", key)
end
function Tch.istKeyForward(playerObj, key)
    return Tch.istKey(playerObj, "Forward", key)
end
function Tch.istKeyBackward(playerObj, key)
    return Tch.istKey(playerObj, "Backward", key)
end
function Tch.istKeyLeft(playerObj, key)
    return Tch.istKey(playerObj, "Left", key)
end
function Tch.istKeyRight(playerObj, key)
    return Tch.istKey(playerObj, "Right", key)
end
function Tch.istKeyRun(playerObj, key)
    return Tch.istKey(playerObj, "Run", key)
end
function Tch.istKeySprint(playerObj, key)
    return Tch.istKey(playerObj, "Sprint", key)
end
function Tch.istKey(playerObj, keyStr, key)
    local md = playerObj and playerObj:getModData()
    local keyBinding = md and keyStr and md[Tch.prefix..keyStr]
    return keyBinding and (keyBinding.k == key or keyBinding.k == key)
end

function Tch.hasKeyControl(playerObj)
    local core = getCore()
    local keyCore = "Interact"
    local kCore = core:getKey(keyCore)
    local altKCore = core:getAltKey(keyCore)
    local result = (not kCore or kCore==Keyboard.KEY_NONE) and (not altKCore or altKCore==Keyboard.KEY_NONE)
    --print ('Tch.hasKeyControl Interact: '..tostring(core:getKey(keyCore))..' '..tostring(core:getAltKey(keyCore))..' '..tostring(result))
    return result--this would break with players having no key there
end


function Tch.activateKeyControl(playerObj)
    if Tch.hasKeyControl(playerObj) then
        return false
    end
    local core = getCore()
    for itKeys = 1, #Tch.inhibitedControlKeys do
        serializeKeyBinding2POD(playerObj, core, Tch.inhibitedControlKeys[itKeys], true)
    end
    --print ('Tch.activateKeyControl '..'lose Core keybinds')
    return true
end

function Tch.deactivateKeyControl(playerObj)
    if not Tch.hasKeyControl(playerObj) then return false end
    local core = getCore()
    for itKeys = 1, #Tch.inhibitedControlKeys do
        deserializePOD2KeyBinding(core, Tch.inhibitedControlKeys[itKeys], playerObj, true)
    end
    --print ('Tch.activateKeyControl '..'retrieve Core keybinds')
    return true
end

--like activateKeyControl but does not touch the Core keybindings, only remembers them for Tch.istKeyXXX comparisons
function Tch.recordKeyBindings(playerObj)
    local core = getCore()
    for itKeys = 1, #Tch.inhibitedControlKeys do
        serializeKeyBinding2POD(playerObj, core, Tch.inhibitedControlKeys[itKeys], false)
    end
end

function Tch.clearRecordedKeyBindings(playerObj)
    local md = playerObj and playerObj:getModData()
    if not md then return end
    for itKeys = 1, #Tch.inhibitedControlKeys do
        md[Tch.prefix..Tch.inhibitedControlKeys[itKeys]] = nil
    end
end

