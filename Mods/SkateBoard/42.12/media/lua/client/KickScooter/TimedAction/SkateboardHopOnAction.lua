require "TimedActions/ISBaseTimedAction"

SkateboardHopOnAction = ISBaseTimedAction:derive("SkateboardHopOnAction")
SkateboardHopOnAction.instance = nil

function SkateboardHopOnAction.isValid(args)
  local character = args and args["character"]
  if not character then
      return false
  end

  local primaryItem = character:getPrimaryHandItem()
  local secondaryItem = character:getSecondaryHandItem()

  for _, typeName in ipairs(SkateboardMenu.typesTable) do
      typeName = tostring(typeName)
      if (primaryItem and primaryItem:getType() == typeName)
              or (secondaryItem and secondaryItem:getType() == typeName) then
          return false
      end
  end
  return true
end

function SkateboardHopOnAction:waitToStart()
	return false
end

function SkateboardHopOnAction:update()

end

function SkateboardHopOnAction.squareHasObject(square)
    local objects = square:getObjects()  -- returns a Java ArrayList
    for i = 0, objects:size()-1 do
        local obj = objects:get(i)
        if obj and obj.isHoppable then
            local hoppable = obj:isHoppable()
            if hoppable then
                return true, obj
            end
        end
    end
    return false, nil
end

function SkateboardHopOnAction.squareIsRough(square)
    local roughMaterials = {
        Sand = true,
        Grass = true,
        Gravel = true,
        Dirt = true
    }
    local function isRoughMaterial(mat)
        return roughMaterials[mat] or false
    end
    local objects = square:getObjects()  -- returns a Java ArrayList
    for i = 0, objects:size()-1 do
        local obj = objects:get(i)
        local mat = obj:getProperties():Val("FootstepMaterial")
        if obj and mat and isRoughMaterial(mat) then
            return true
        end
    end
    return false, nil
end

function SkateboardHopOnAction.nearbySquareHasObject(square)
    local squares = {
        square,
        square:getN(),
        square:getS(),
        square:getE(),
        square:getW(),
    }
    for _, s in ipairs(squares) do
        if s then
            local found, obj = SkateboardHopOnAction.squareHasObject(s)
            if found then
                return true, obj
            end
        end
    end
    return false, nil
end

local lastAddSoundTimestamp = 0

-- return the (possibly updated) timestamp
function ThrottleAddSound(lastTs, player, radius)
    local now = getTimestampMs()
    if now - lastTs >= 2000 then
        addSound(nil, player:getX(), player:getY(), player:getZ(), radius, radius)
        return now
    end
    return lastTs
end

function UpdateSkateboardAudio(player)
    local skateboardActive = player:getVariableBoolean("SkateboardActive")
    local emitter = player:getEmitter()
    local options = PZAPI.ModOptions:getOptions("SkateboardMod")
    local soundVolume = options:getOption("SkateboardSoundVolume"):getValue()
    local soundRange = options:getOption("SkateboardSoundRange"):getValue()

    if not skateboardActive then
        if emitter:isPlaying('SkateboardRolling') then
            emitter:stopSoundByName('SkateboardRolling')
        end
        player:setVariable("SkateboardRolling", "false")
        player:setVariable("SkateboardRollingTimestamp", "0")
        player:setVariable("SkateboardToHandPlayed", "false")
        return
    end

    if not player:getVariableBoolean("SkateboardRolling") then
        player:setVariable("SkateboardRollingTimestamp", "0")
    end

    local isAiming = player:getVariableBoolean("aim")
    local isMoving = player:getVariableBoolean("ismoving")

    if isAiming == true then
        player:setVariable("SkateboardRollingTimestamp", "0")
        if emitter:isPlaying('SkateboardRolling') then
            emitter:stopSoundByName('SkateboardRolling')
        end
        -- Only trigger SkateboardToHand once
        if not player:getVariableBoolean("SkateboardToHandPlayed") then
            local sound = emitter:playSound('SkateboardToHand')
            emitter:setVolume(sound, soundVolume * 0.8)
            if isMoving == false then
                player:setBlockMovement(true)
                TinyTimer(800, function()
                    player:setBlockMovement(false)
                end)
            end
            player:setVariable("SkateboardToHandPlayed", "true")
        end
        return
    else
        -- Reset the flag when not aiming so it can be triggered next time.
        player:setVariable("SkateboardToHandPlayed", "false")
    end

    if emitter:isPlaying('SkateboardRolling') and player:isPlayerMoving() then
        lastAddSoundTimestamp = ThrottleAddSound(lastAddSoundTimestamp, player, soundRange)
        return
    elseif not player:isPlayerMoving() then
        emitter:stopSoundByName('SkateboardRolling')
        return
    end

    if tonumber(player:getVariableString("SkateboardRollingTimestamp")) < 1 then
        local ts = getTimestampMs()
        player:setVariable("SkateboardRollingTimestamp", tostring(ts))
    end

    local startTs = tonumber(player:getVariableString("SkateboardRollingTimestamp"))
    local currentTs = getTimestampMs()

    if currentTs - startTs >= 750 and not emitter:isPlaying('SkateboardRolling') and player:getVariableBoolean("aim") == false then
        if not emitter:isPlaying('SkateboardOllie') then
            local sound = emitter:playSound('SkateboardRolling')
            emitter:setVolume(sound, soundVolume)
        end
    end
end

function UpdateSkateboardFlag(player)
    -- Accept either hand; tolerate one-frame nil during equip.
    local primaryItem   = player:getPrimaryHandItem()
    local secondaryItem = player:getSecondaryHandItem()
    local handItem      = primaryItem or secondaryItem

    if not handItem then
        -- While equipping, keep the stance/vars alive so we don't get reset.
        if SkateboardEquipping then
            player:setVariable("SkateboardActive", true)
            player:setIgnoreAutoVault(true)
            return
        end
        return
    end

    -- From here on, use 'handItem' instead of 'primaryItem'
    if not SkateboardMenu or not SkateboardMenu.isSkateboardItem(handItem) then
        if SkateboardMenu and SkateboardMenu.resetPlayerState then
            SkateboardMenu.resetPlayerState(player)
        else
            player:setVariable("SkateboardActive", false)
            player:setIgnoreAutoVault(false)
        end
        return
    end
    if SkateboardMenu.isSkateboardItem(handItem) then
        -- ISHealthPanel.instance is no longer guaranteed to exist, so query the player's
        -- BodyDamage directly to determine the state of leg/foot injuries.
        local bodyDamage = player.getBodyDamage and player:getBodyDamage() or nil
        player:setVariable("SkateboardActive", true)
        player:setIgnoreAutoVault(true)

        if bodyDamage then
            local bodyParts = bodyDamage:getBodyParts()
            if bodyParts then
                for index = 1, bodyParts:size() do
                    local part = bodyParts:get(index - 1)
                    if part then
                        local partType = string.lower(tostring(part:getType()))
                        if string.find(partType, "leg") or string.find(partType, "foot") then
                            if part:HasInjury() and part:getFractureTime() > 0 then
                                player:setVariable("SkateboardSpeed", 0.01)
                                return
                            end

                            if part:getHealth() < 75 then
                                player:setVariable("SkateboardSpeed", (part:getHealth() / 100) * 0.8)
                                return
                            end
                        end
                    end
                end
            end
        end

        local options = PZAPI.ModOptions:getOptions("SkateboardMod")
        local speedMultSlow = options:getOption("SpeedMultSlow"):getValue()
        local speedMultFast = options:getOption("SpeedMultFast"):getValue()

        player:setVariable("SkateboardSpeed", 1.00)
        player:setVariable("SkateboardWalkSpeed", speedMultSlow)
        player:setVariable("SkateboardRunSpeed", speedMultFast)
        local skateboardImmersive = options:getOption("SkateboardImmersive"):getValue()
        local sq = player:getSquare()
        local isRough = SkateboardHopOnAction.squareIsRough(sq)
        if isRough and skateboardImmersive then
            player:setVariable("SkateboardSpeed", 0.20)
        else
            player:setVariable("SkateboardSpeed", 1.00)
        end
        return
    end
end


function SkateboardHopOnAction:start()
    self.character:setVariable("SkateboardActive", true)
    UpdateSkateboardFlag(self.character)
end

function SkateboardHopOnAction:stop()

end

function SkateboardHopOnAction:perform()
    SkateboardHopOnAction.equipWeapon(self.item, true, true, self.character:getPlayerNum())
    self.character:setIgnoreAutoVault(true)
    Events.OnPlayerUpdate.Add(UpdateSkateboardFlag)
    Events.OnPlayerUpdate.Add(UpdateSkateboardAudio)

    ISBaseTimedAction.perform(self)
end

SkateboardHopOnAction.equipWeapon = function(weapon, primary, twoHands, player)
    local playerObj = getSpecificPlayer(player)
    if isForceDropHeavyItem(playerObj:getPrimaryHandItem()) then
        ISTimedActionQueue.add(ISUnequipAction:new(playerObj, playerObj:getPrimaryHandItem(), 0));
    end
    SkateboardEquipping = true
    ISTimedActionQueue.add(ISEquipWeaponAction:new(playerObj, weapon, 0, primary, twoHands));
    playerObj:setVariable("SkateboardHeld", true)
end

function SkateboardHopOnAction:new( item, player)
    local o = {}
    setmetatable( o, self)
    self.__index = self
    o.maxTime = 0
    o.useProgressBar = false
    o.character = player
    o.inventory = player:getInventory()
    o.item = item
    o.stopOnWalk = false
    o.stopOnRun = false
    o.options = PZAPI.ModOptions:getOptions("SkateboardMod")
    o.speedMultSlow = o.options:getOption("SpeedMultSlow"):getValue()
    o.speedMultFast = o.options:getOption("SpeedMultFast"):getValue()

    o.character:setVariable("SkateboardActive", true)
    o.character:setVariable("IdleToAimPlaying", false)
    o.character:setVariable("SkateboardWalkSpeed", o.speedMultSlow)
    o.character:setVariable("SkateboardRunSpeed", o.speedMultFast)

    SkateboardHopOnAction.instance = o

    return o
end