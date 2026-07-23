if not getAsianStyleInstance then
  require('AsianStyle/AsianStyle_Main')
end

local AsianStyle = getAsianStyleInstance()

AsianStyle.fencesMenuBuilder = function(subMenu, player)
  local _sprite
  local _option
  local _tooltip
  local _name = ''

  AsianStyle.neededMaterials = {
    {
      Material = 'Base.Plank',
      Amount = 2
    },
    {
      Material = 'Base.Nails',
      Amount = 2
    }
  }

  AsianStyle.neededTools = {'Hammer'}

local needSkills = {
    Woodwork = AsianStyle.skillLevel.wallObject
  }

  local _fencesData = AsianStyle.getfencesData()

  for _, _currentList in pairs(_fencesData) do
    _sprite = {}
    _sprite.sprite = _currentList[1]
    _sprite.northSprite = _currentList[2]
	_sprite.corner = _currentList[3]

    _name = _currentList[4]

    _option = subMenu:addOption(_name, nil, AsianStyle.onBuildfences, _sprite, player, _name)

    _tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
    --_tooltip.description = _currentList[6] .. _tooltip.description
    _tooltip:setName(_name)
    _tooltip:setTexture(_sprite.sprite)
  end
end

AsianStyle.getfencesData = function()
  local _fencesData = {

	{
      'asianfence_0_0',
      'asianfence_0_1',
	  'asianfence_0_3',
      getText('ContextMenu_BrownWood_Fence_Less_Posts')
    },
	
		{
      'asianfence_0_4',
      'asianfence_0_5',
	  'asianfence_0_3',
      getText('ContextMenu_BrownWood_Fence_More_Posts')
    },
	
		{
      'asianfence_0_2',
      'asianfence_0_2',
	  'asianfence_0_3',
      getText('ContextMenu_BrownWood_Fence_Corner')
    },
	
			{
      'asianfence_0_3',
      'asianfence_0_3',
	  'asianfence_0_3',
      getText('ContextMenu_BrownWood_Fence_Pillar')
    },

	
  }
  return _fencesData
end


AsianStyle.onBuildfences = function(ignoreThisArgument, sprite, player, name)
  local _pillar = ISWoodenWall:new(sprite.sprite, sprite.northSprite, nil)

  _pillar.canPassThrough = true
  _pillar.canBarricade = false
  _pillar.isCorner = true
  _pillar.player = player
  _pillar.name = name

  _pillar.modData['need:Base.Plank'] = 2
  _pillar.modData['need:Base.Nails'] = 3
  _pillar.modData['xp:Woodwork'] = 5
  _pillar.modData['wallType'] = 'pillar'

  function _pillar:getHealth()
    return AsianStyle.healthLevel.stoneWall + buildUtil.getWoodHealth(self)
  end

  AsianStyle.equipToolPrimary(_pillar, player, 'Hammer')

  getCell():setDrag(_pillar, player)
end

