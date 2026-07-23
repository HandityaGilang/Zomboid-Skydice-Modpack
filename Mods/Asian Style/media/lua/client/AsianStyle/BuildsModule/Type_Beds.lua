if not getAsianStyleInstance then
  require('AsianStyle/AsianStyle_Main')
end

local AsianStyle = getAsianStyleInstance()

AsianStyle.bedsMenuBuilder = function(subMenu, player)
  local _sprite
  local _option
  local _tooltip
  local _name = ''

  AsianStyle.neededMaterials = {
    {
      Material = 'Base.RippedSheets',
      Amount = 6
    },
    {
      Material = 'Base.Thread',
      Amount = 2
    },

  }

  AsianStyle.neededTools = {'Needle'}

  local needSkills = {
    Tailoring = AsianStyle.skillLevel.complexFurniture
  }

  local _bedsData = AsianStyle.getBedData()

  for _, _currentList in pairs(_bedsData) do
    _sprite = {}
    _sprite.sprite = _currentList[1]
    _sprite.sprite2 = _currentList[2]
    _sprite.northSprite = _currentList[3]
    _sprite.northSprite2 = _currentList[4]

    _name = _currentList[5]

    _option = subMenu:addOption(_name, nil, AsianStyle.onBuildBed, _sprite, player, _name)

    _tooltip = AsianStyle.canBuildObject(needSkills, _option, player)

    _tooltip:setName(_name)
    _tooltip:setTexture(_sprite.sprite)
  end
end

AsianStyle.getBedData = function()
  local _bedData = {
    {'fixtures_asianfurniture_01_9', 'fixtures_asianfurniture_01_8', 'fixtures_asianfurniture_01_10', 'fixtures_asianfurniture_01_11', getText 'ContextMenu_Futon'},
    
  }

  return _bedData
end

AsianStyle.onBuildBed = function(ignoreThisArgument, sprite, player, name)
  local _bed = ISDoubleTileFurniture:new(name, sprite.sprite, sprite.sprite2, sprite.northSprite, sprite.northSprite2)

  _bed.player = player
  _bed.name = name

  _bed.modData['need:Base.RippedSheets'] = 6
  _bed.modData['need:Base.Thread'] = 2
  _bed.modData['xp:Tailoring'] = 10

  getCell():setDrag(_bed, player)
end