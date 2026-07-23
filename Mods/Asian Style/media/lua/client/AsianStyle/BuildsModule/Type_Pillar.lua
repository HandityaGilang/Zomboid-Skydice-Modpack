if not getAsianStyleInstance then
  require('AsianStyle/AsianStyle_Main')
end

local AsianStyle = getAsianStyleInstance()

AsianStyle.pillarsMenuBuilder = function(subMenu, player)
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

  local _pillarsData = AsianStyle.getpillarsData()

  for _, _currentList in pairs(_pillarsData) do
    _sprite = {}
    _sprite.sprite = _currentList[1]
    _sprite.northSprite = _currentList[2]


    _name = _currentList[3]

    _option = subMenu:addOption(_name, nil, AsianStyle.onBuildpillars, _sprite, player, _name)

    _tooltip = AsianStyle.canBuildObject(needSkills, _option, player)

    _tooltip:setName(_name)
    _tooltip:setTexture(_sprite.sprite)
  end
end

AsianStyle.getpillarsData = function()
  local _pillarsData = {

	{
      'fixtures_asianwalls_01_11',
      'fixtures_asianwalls_01_11',
      getText('ContextMenu_Wooden_Pillar')
    },
	{
      'fixtures_asianwalls_03_39',
      'fixtures_asianwalls_03_39',
      getText('ContextMenu_FullyWooden_Pillar')
    },
	{
      'fixtures_asianwalls_03_67',
      'fixtures_asianwalls_03_67',
      getText('ContextMenu_Siding_Pillar')
    },

	
  }
  return _pillarsData
end


AsianStyle.onBuildpillars = function(ignoreThisArgument, sprite, player, name)
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

