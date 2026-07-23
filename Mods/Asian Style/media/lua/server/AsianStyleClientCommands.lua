AsianStyleClientCommands = {}
local BuildCommands = {}
AsianStyleClientCommands.Lightpoles = {}
BuildCommands.object = {}

AsianStyleClientCommands.wantNoise = getDebug()
local noise = function(msg)
  if (AsianStyleClientCommands.wantNoise) then
    print('ClientCommand: ' .. msg)
  end
end

local getThumpableElectricLight = function(x, y, z)
  local gs = getCell():getGridSquare(x, y, z)
  if not gs then
    return nil
  end
  for i = 0, gs:getSpecialObjects():size() - 1 do
    local o = gs:getSpecialObjects():get(i)
    if o and instanceof(o, 'IsoThumpable') then
      if not o:haveFuel() then
        if o:getModData()['IsLighting'] then
          return o
        end
      end
    end
  end
  return nil
end

BuildCommands.object.toggleElectricLight = function(player, args)
  local o = getThumpableElectricLight(args.x, args.y, args.z)
  if o then
    if o:getSquare():haveElectricity() or (SandboxVars.ElecShutModifier > -1 and GameTime:getInstance():getNightsSurvived() < SandboxVars.ElecShutModifier) then
      o:toggleLightSource(not o:isLightSourceOn())
      o:sendObjectChange('lightSource')
    else
      o:toggleLightSource(false)
      o:sendObjectChange('lightSource')
    end
    if o:isLightSourceOn() then
      AsianStyleClientCommands.addPole(o:getSquare())
    else
      AsianStyleClientCommands.removePole(o:getSquare())
    end
  end
end

function AsianStyleClientCommands.removePole(square)
  for i, v in ipairs(AsianStyleClientCommands.Lightpoles) do
    if v.x == square:getX() and v.y == square:getY() and v.z == square:getZ() then
      table.remove(AsianStyleClientCommands.Lightpoles, i)
      break
    end
  end
end

function AsianStyleClientCommands.addPole(square)
  local Lightpole = {}
  Lightpole.x = square:getX()
  Lightpole.y = square:getY()
  Lightpole.z = square:getZ()
  table.insert(AsianStyleClientCommands.Lightpoles, Lightpole)
end

AsianStyleClientCommands.OnClientCommand = function(module, command, player, args)
  if BuildCommands[module] and BuildCommands[module][command] then
    local argStr = ''
    for k, v in pairs(args) do
      argStr = argStr .. ' ' .. k .. '=' .. tostring(v)
    end
    noise('received ' .. module .. ' ' .. command .. ' ' .. tostring(player) .. argStr)
    BuildCommands[module][command](player, args)
  end
end

function AsianStyleClientCommands.findObject(square)
  if not square then
    return nil
  end
  for i = 0, square:getSpecialObjects():size() - 1 do
    local o = square:getSpecialObjects():get(i)
    if o and instanceof(o, 'IsoThumpable') then
      if not o:haveFuel() then
        if o:getModData()['IsLighting'] then
          return o
        end
      end
    end
  end
  return nil
end

function AsianStyleClientCommands.checkPower()
  if isClient() then
    return
  end
  local temptable = AsianStyleClientCommands.Lightpoles
  for i, v in ipairs(temptable) do
    local square = getCell():getGridSquare(v.x, v.y, v.z)
    if square then
      if not (square:haveElectricity() or (SandboxVars.ElecShutModifier > -1 and GameTime:getInstance():getNightsSurvived() < SandboxVars.ElecShutModifier)) then
        local obj = AsianStyleClientCommands.findObject(square)
        if obj then
          obj:toggleLightSource(false)
          obj:sendObjectChange('lightSource')
          AsianStyleClientCommands.removePole(square)
        else
          AsianStyleClientCommands.removePole(square)
        end
      end
    end
  end
end

AsianStyleClientCommands.OnObjectAdded = function(o)
  if isClient() then
    return
  end

  if o and instanceof(o, 'IsoThumpable') then
    if not o:haveFuel() then
      if o:getModData()['IsLighting'] then
        if o:isLightSourceOn() then
          AsianStyleClientCommands.addPole(o:getSquare())
        end
      end
    end
  end
end

function AsianStyleClientCommands.OnDestroyIsoThumpable(o, player)
  if isClient() then
    return
  end
  if not o:getSquare() or not (o:getModData()['IsLighting']) then
    return
  end
  local sq = o:getSquare()
  AsianStyleClientCommands.removePole(sq)
end

Events.EveryTenMinutes.Add(AsianStyleClientCommands.checkPower)
Events.OnObjectAdded.Add(AsianStyleClientCommands.OnObjectAdded)
Events.OnDestroyIsoThumpable.Add(AsianStyleClientCommands.OnDestroyIsoThumpable)
Events.OnClientCommand.Add(AsianStyleClientCommands.OnClientCommand)