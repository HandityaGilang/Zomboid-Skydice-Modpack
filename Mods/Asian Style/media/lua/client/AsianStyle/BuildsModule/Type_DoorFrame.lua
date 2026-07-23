if not getAsianStyleInstance then
  require('AsianStyle/AsianStyle_Main')
end

local AsianStyle = getAsianStyleInstance()

AsianStyle.doorFramesMenuBuilder = function(subMenu, player)
  local _sprite
  local _option
  local _tooltip
  local _name = ''

  AsianStyle.neededMaterials = {
    {
      Material = 'Base.Plank',
      Amount = 4
    },
    {
      Material = 'Base.Nails',
      Amount = 4
    }
  }

  AsianStyle.neededTools = {'Hammer'}

  local needSkills = {
    Woodwork = AsianStyle.skillLevel.wallObject
  }
      
  _sprite = {}
  _sprite.sprite = 'fixtures_asianwalls_01_7'
  _sprite.northSprite = 'fixtures_asianwalls_01_23'
  _sprite.corner = 'fixtures_asianwalls_01_3'
  _name = getText 'ContextMenu_Doorframe'
  _option = subMenu[getText 'ContextMenu_Asian_Wall_Interior']:addOption(_name, nil, AsianStyle.onBuildWoodenDoorFrame, _sprite, player, _name)
  _tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
  _tooltip:setName(_name)
  _tooltip:setTexture(_sprite.sprite)
  
  _sprite = {}
  _sprite.sprite = 'fixtures_asianwalls_01_80'
  _sprite.northSprite = 'fixtures_asianwalls_01_81'
  _sprite.corner = 'fixtures_asianwalls_01_3'
  _name = getText 'ContextMenu_Doorframe'
  _option = subMenu[getText 'ContextMenu_Asian_Wall_Half_Wood']:addOption(_name, nil, AsianStyle.onBuildWoodenDoorFrame, _sprite, player, _name)
  _tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
  _tooltip:setName(_name)
  _tooltip:setTexture(_sprite.sprite)    
  
  _sprite = {}
  _sprite.sprite = 'fixtures_asianwalls_03_35'
  _sprite.northSprite = 'fixtures_asianwalls_03_34'
  _sprite.corner = 'fixtures_asianwalls_03_39'
  _name = getText 'ContextMenu_Doorframe'
  _option = subMenu[getText 'ContextMenu_Asian_Wall_FullWood']:addOption(_name, nil, AsianStyle.onBuildWoodenDoorFrame, _sprite, player, _name)
  _tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
  _tooltip:setName(_name)
  _tooltip:setTexture(_sprite.sprite)


end

AsianStyle.onBuildWoodenDoorFrame = function(ignoreThisArgument, sprite, player, name)
  local _doorFrame = ISWoodenDoorFrame:new(sprite.sprite, sprite.northSprite, sprite.corner)

  _doorFrame.canBePlastered = AsianStyle.playerCanPlaster
  _doorFrame.modData['wallType'] = 'doorframe'
  _doorFrame.player = player
  _doorFrame.name = name

  _doorFrame.modData['need:Base.Plank'] = 4
  _doorFrame.modData['need:Base.Nails'] = 4
  _doorFrame.modData['xp:Woodwork'] = 5

  getCell():setDrag(_doorFrame, player)
end

AsianStyle.onBuildLowDoorFrame = function(ignoreThisArgument, sprite, player, name)
  local _LowdoorFrame = ISWoodenDoorFrame:new(sprite.sprite, sprite.northSprite, sprite.corner)

  _LowdoorFrame.canBePlastered = AsianStyle.playerCanPlaster
  _LowdoorFrame.modData['wallType'] = 'doorframe'
  _LowdoorFrame.player = player
  _LowdoorFrame.name = name

  _LowdoorFrame.modData['need:Base.Plank'] = 1
  _LowdoorFrame.modData['need:Base.Nails'] = 1
  _LowdoorFrame.modData['xp:Woodwork'] = 5

  getCell():setDrag(_LowdoorFrame, player)
end

AsianStyle.onBuildStoneDoorFrame = function(ignoreThisArgument, sprite, player, name)
  local _doorFrame = ISWoodenDoorFrame:new(sprite.sprite, sprite.northSprite, sprite.corner)

  _doorFrame.canBePlastered = AsianStyle.playerCanPlaster
  _doorFrame.modData['wallType'] = 'doorframe'
  _doorFrame.player = player
  _doorFrame.name = name

  _doorFrame.modData['need:Base.Plank'] = 2
  _doorFrame.modData['need:Base.Nails'] = 3
  _doorFrame.modData['xp:Woodwork'] = 5

  function _doorFrame:getHealth()
    return AsianStyle.healthLevel.stoneWall + buildUtil.getWoodHealth(self)
  end

  AsianStyle.equipToolPrimary(_doorFrame, player, 'Hammer')

  getCell():setDrag(_doorFrame, player)
end