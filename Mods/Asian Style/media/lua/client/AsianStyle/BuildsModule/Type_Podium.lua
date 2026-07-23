if not getAsianStyleInstance then
  require('AsianStyle/AsianStyle_Main')
end

local AsianStyle = getAsianStyleInstance()

AsianStyle.podiumMenuBuilder = function(subMenu, player)
  local _sprite
  local _option
  local _tooltip
  local _name = ''

  AsianStyle.neededMaterials = {
    {
      Material = 'Base.Plank',
      Amount = 1
    },
    {
      Material = 'Base.Nails',
      Amount = 1
    }
  }

  AsianStyle.neededTools = {'Hammer'}

  local needSkills = {
    Woodwork = 2
  }

  local _podiumData = AsianStyle.getPodiumData()

  for _, _currentList in pairs(_podiumData) do
    _sprite = {}
    _sprite.sprite = _currentList[1]
    _sprite.northSprite = _currentList[2]

    _name = _currentList[3]

    _option = subMenu:addOption(_name, nil, AsianStyle.onBuildPodium, _sprite, player, _name)

    _tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
    _tooltip:setName(_name)
    _tooltip:setTexture(_sprite.sprite)
  end
end

AsianStyle.getPodiumData = function()
  local _podiumData = {

    
    
    {
      'location_trailer_01_17',
      'location_trailer_01_18',
      getText 'ContextMenu_Middle_Section',
      
    },
    {
      'location_trailer_01_19',
      'location_trailer_01_20',
      getText 'ContextMenu_Corners'

    },
    {
      'location_trailer_01_21',
      'location_trailer_01_22',
      getText 'ContextMenu_Ends'
    },
    
	
  }
  return _podiumData
end


AsianStyle.onBuildPodium = function(ignoreThisArgument, sprite, player, name)
  local _sign = ISSimpleFurniture:new(name, sprite.sprite, sprite.northSprite)

  _sign.player = player
  _sign.name = name
  _sign.eastSprite = sprite.eastSprite
  _sign.southSprite = sprite.southSprite
  _sign.northSprite = sprite.northSprite
  _sign.canPassThrough = false
  _sign.blockAllTheSquare = false
  _sign.isCorner = true

  _sign.modData['need:Base.Plank'] = 1
  _sign.modData['need:Base.Nails'] = 1
  _sign.modData['xp:Woodwork'] = 7.5

  getCell():setDrag(_sign, player)
end

