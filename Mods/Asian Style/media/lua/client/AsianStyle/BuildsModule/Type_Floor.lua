if not getAsianStyleInstance then
  require('AsianStyle/AsianStyle_Main')
end

local AsianStyle = getAsianStyleInstance()

AsianStyle.floorsMenuBuilder = function(subMenu, player, context)
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
    Woodwork = AsianStyle.skillLevel.floorObject
  }

  local _floorData = AsianStyle.getFloorsData()
  local _currentOption
  local _currentSubMenu

  for _subsectionName, _subsectionData in pairs(_floorData) do
    _currentOption = subMenu:addOption(_subsectionName)
    _currentSubMenu = subMenu:getNew(subMenu)
    context:addSubMenu(_currentOption, _currentSubMenu)

    for _, _currentList in pairs(_subsectionData) do
      _sprite = {}
      _sprite.sprite = _currentList[1]
      _sprite.northSprite = _currentList[2]
	  _sprite.eastSprite = _currentList[3]
	  _sprite.southSprite = _currentList[4]

      _name = _currentList[5]

      _option = _currentSubMenu:addOption(_name, nil, AsianStyle.onBuildFourSpriteFloor, _sprite, player, _name)

      _tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
      _tooltip:setName(_name)
      _tooltip:setTexture(_sprite.sprite)
      
    end
  end
end

AsianStyle.onBuildFourSpriteFloor = function(ignoreThisArgument, sprite, player, name)
  local _floor = ISWoodenFloor:new(sprite.sprite, sprite.northSprite)

  _floor.player = player
  _floor.name = name
 
  _floor.eastSprite = sprite.eastSprite
  _floor.southSprite = sprite.southSprite

  _floor.modData['need:Base.Plank'] = 1
  _floor.modData['need:Base.Nails'] = 1
  _floor.modData['xp:Woodwork'] = 5

  getCell():setDrag(_floor, player)
end


AsianStyle.getFloorsData = function()
  local _floorData = {
    [getText 'ContextMenu_Tatami'] = {
		{'interior_asianfloor_01_28', 'interior_asianfloor_01_29', 'interior_asianfloor_01_28', 'interior_asianfloor_01_29', getText 'ContextMenu_TatamiNoBorders'},
		{'interior_asianfloor_01_3', 'interior_asianfloor_01_5', 'interior_asianfloor_01_6', 'interior_asianfloor_01_4', getText 'ContextMenu_TatamiVertCorners'},
		{'interior_asianfloor_01_19', 'interior_asianfloor_01_16', 'interior_asianfloor_01_18', 'interior_asianfloor_01_17',  getText 'ContextMenu_TatamiHoriCorners'},
		{'interior_asianfloor_01_0', 'interior_asianfloor_01_21', 'interior_asianfloor_01_1', 'interior_asianfloor_01_20', getText 'ContextMenu_TatamiMid'},
		{'interior_asianfloor_01_8', 'interior_asianfloor_01_10', 'interior_asianfloor_01_11', 'interior_asianfloor_01_13',  getText 'ContextMenu_TatamiNarrowEnds'},
		{'interior_asianfloor_01_9', 'interior_asianfloor_01_12', 'interior_asianfloor_01_9', 'interior_asianfloor_01_12', getText 'ContextMenu_TatamiNarrowMid'},

     },
	[getText 'ContextMenu_WoodenFloors'] = {
		{'interior_asianfloor_01_24', 'interior_asianfloor_01_25', 'interior_asianfloor_01_24', 'interior_asianfloor_01_25', getText 'ContextMenu_LongPlanks'},
		{'interior_asianfloor_01_26', 'interior_asianfloor_01_27', 'interior_asianfloor_01_26', 'interior_asianfloor_01_27',  getText 'ContextMenu_ShortPlanks'},
    },
  }

  return _floorData
end