local TABAS_RadialMenuPatch = {}

local TABAS_BathRadialMenu = require("UI/TABAS_BathRadialMenu")
local TABAS_BathRadialUtils = require("UI/TABAS_BathRadialUtils")
local TABAS_BathingUtils = require("Bathing/TABAS_BathingUtils")

local function getPlayerFromJoypad(joypadData)
    if not joypadData then return nil end
    return getSpecificPlayer(joypadData.player)
end

function TABAS_RadialMenuPatch.apply()
    if TABAS_RadialMenuPatch._applied then
        return
    end

    if ISJoystickButtonRadialMenu then
        local old_onJoypadDown = ISJoystickButtonRadialMenu.onJoypadDown
        local old_onJoypadButtonReleased = ISJoystickButtonRadialMenu.onJoypadButtonReleased
        local old_onRepeatLeftStickButton = ISJoystickButtonRadialMenu.onRepeatLeftStickButton

        ISJoystickButtonRadialMenu.onJoypadDown = function(button, joypadData)
            local playerObj = getPlayerFromJoypad(joypadData)
            if TABAS_BathingUtils.isTakingBath(playerObj) then
                return
            end
            return old_onJoypadDown(button, joypadData)
        end

        ISJoystickButtonRadialMenu.onJoypadButtonReleased = function(button, joypadData)
            local playerObj = getPlayerFromJoypad(joypadData)
            if TABAS_BathingUtils.isTakingBath(playerObj) then
                return
            end
            return old_onJoypadButtonReleased(button, joypadData)
        end

        ISJoystickButtonRadialMenu.onRepeatLeftStickButton = function(joypadData)
            local playerObj = getPlayerFromJoypad(joypadData)
            if TABAS_BathingUtils.isTakingBath(playerObj) then
                return
            end
            return old_onRepeatLeftStickButton(joypadData)
        end
    end

    if ISDPadWheels then
        local old_onDisplayUp = ISDPadWheels.onDisplayUp

        ISDPadWheels.onDisplayUp = function(joypadData)
            local playerObj = getPlayerFromJoypad(joypadData)
            if TABAS_BathRadialUtils.canOpen(playerObj) then
                return TABAS_BathRadialMenu.display(playerObj)
            end
            return old_onDisplayUp(joypadData)
        end
    end

    TABAS_RadialMenuPatch._applied = true
end

return TABAS_RadialMenuPatch
