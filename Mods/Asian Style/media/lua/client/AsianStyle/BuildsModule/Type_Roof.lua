if not getAsianStyleInstance then
  require('AsianStyle/AsianStyle_Main')
end

local AsianStyle = getAsianStyleInstance()

AsianStyle.roofMenuBuilder = function(subMenu, player, context)
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
      Amount = 2
    }
  }

  AsianStyle.neededTools = {'Hammer'}

  local needSkills = {
    Woodwork = 2
  }
	local _roofData = AsianStyle.getRoofData()
	local _currentOption
	local _currentSubMenu

	for _subsectionName, _subsectionData in pairs(_roofData) do
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
			_option = _currentSubMenu:addOption(_name, nil, AsianStyle.onBuildRoof, _sprite, player, _name)
			_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
			_tooltip:setName(_name)
			_tooltip:setTexture(_sprite.sprite)

		end
	end
			 
end


AsianStyle.onBuildRoof = function(ignoreThisArgument, sprite, player, name)
	  local _sign = ISSimpleFurniture:new(name, sprite.sprite, sprite.northSprite)

	  _sign.player = player
	  _sign.name = name
	  _sign.eastSprite = sprite.eastSprite
	  _sign.southSprite = sprite.southSprite
	  _sign.northSprite = sprite.northSprite
	  _sign.canPassThrough = true
	  _sign.blockAllTheSquare = false
	  _sign.isCorner = true
	  _sign.renderFloorHelper = true

	  _sign.modData['need:Base.Plank'] = 1
	  _sign.modData['need:Base.Nails'] = 2
	  _sign.modData['xp:Woodwork'] = 5

	  getCell():setDrag(_sign, player)
end

AsianStyle.onBuildFlatRoof = function(ignoreThisArgument, sprite, player, name)
	  local _floor = ISWoodenFloor:new(sprite.sprite, sprite.northSprite)

	  _floor.player = player
	  _floor.name = name

	  _floor.modData['need:Base.Plank'] = 1
	  _floor.modData['need:Base.Nails'] = 2
	  _floor.modData['xp:Woodwork'] = 5

	  getCell():setDrag(_floor, player)
end
AsianStyle.getRoofData = function()
  local _roofData = {
    [getText 'ContextMenu_Roofs'] = {
      {
	  'recolor_melos_tiles_roofs_04_5', 
	  'recolor_melos_tiles_roofs_04_8', 
	  'recolor_melos_tiles_roofs_04_16', 
	  'recolor_melos_tiles_roofs_04_29', 
	  getText 'ContextMenu_RoofLevel_1'
	  },
      {
	  'recolor_melos_tiles_roofs_04_4', 
	  'recolor_melos_tiles_roofs_04_9', 
	  'recolor_melos_tiles_roofs_04_17', 
	  'recolor_melos_tiles_roofs_04_28', 
	  getText 'ContextMenu_RoofLevel_2'
	  },
	  {
	  'recolor_melos_tiles_roofs_04_3', 
	  'recolor_melos_tiles_roofs_04_10', 
	  'recolor_melos_tiles_roofs_04_18', 
	  'recolor_melos_tiles_roofs_04_27', 
	  getText 'ContextMenu_RoofLevel_3'
	  },
	  {
	  'recolor_melos_tiles_roofs_04_2', 
	  'recolor_melos_tiles_roofs_04_11', 
	  'recolor_melos_tiles_roofs_04_19', 
	  'recolor_melos_tiles_roofs_04_26', 
	  getText 'ContextMenu_RoofLevel_4'
	  },
	  {
	  'recolor_melos_tiles_roofs_04_101', 
	  'recolor_melos_tiles_roofs_04_100', 
	  'recolor_melos_tiles_roofs_04_99', 
	  'recolor_melos_tiles_roofs_04_98', 
	  getText 'ContextMenu_MidRoofNorth'
	  },
	  {
	  'recolor_melos_tiles_roofs_04_104', 
	  'recolor_melos_tiles_roofs_04_105', 
	  'recolor_melos_tiles_roofs_04_106', 
	  'recolor_melos_tiles_roofs_04_107', 
	  getText 'ContextMenu_MidRoofWest'
	  },
	  
    },
	[getText 'ContextMenu_RoofTrims'] = {
	{
	  'recolor_melos_tiles_roofs_04a_5', 
	  'recolor_melos_tiles_roofs_04a_4', 
	  'recolor_melos_tiles_roofs_04a_3', 
	  'recolor_melos_tiles_roofs_04a_2', 
	  getText 'ContextMenu_RoofTrimNorth1'
	  },
 	  {
	  'recolor_melos_tiles_roofs_04a_16', 
	  'recolor_melos_tiles_roofs_04a_17', 
	  'recolor_melos_tiles_roofs_04a_18', 
	  'recolor_melos_tiles_roofs_04a_19', 
	  getText 'ContextMenu_RoofTrimNorth2'
	  },
	  {
	  'recolor_melos_tiles_roofs_04a_32', 
	  'recolor_melos_tiles_roofs_04a_33', 
	  'recolor_melos_tiles_roofs_04a_34', 
	  'recolor_melos_tiles_roofs_04a_35', 
	  getText 'ContextMenu_RoofTrimWest1'
	  },
 	  {
	  'recolor_melos_tiles_roofs_04a_53', 
	  'recolor_melos_tiles_roofs_04a_52', 
	  'recolor_melos_tiles_roofs_04a_51', 
	  'recolor_melos_tiles_roofs_04a_50', 
	  getText 'ContextMenu_RoofTrimWest2'
	  },
	  {
	  'recolor_melos_tiles_roofs_04a_80', 
	  'recolor_melos_tiles_roofs_04a_81', 
	  'recolor_melos_tiles_roofs_04a_82', 
	  'recolor_melos_tiles_roofs_04a_83', 
	  getText 'ContextMenu_RoofTrimMidWest'
	  },
 	  {
	  'recolor_melos_tiles_roofs_04a_69', 
	  'recolor_melos_tiles_roofs_04a_68', 
	  'recolor_melos_tiles_roofs_04a_67', 
	  'recolor_melos_tiles_roofs_04a_66', 
	  getText 'ContextMenu_RoofTrimMidNorth'
	  },
	  {
	  'recolor_melos_tiles_roofs_04a_6', 
	  'recolor_melos_tiles_roofs_04a_70', 
	  'recolor_melos_tiles_roofs_04a_38', 
	  'recolor_melos_tiles_roofs_04a_86', 
	  getText 'ContextMenu_RoofTrimEdge'
	  },
	}
	
   
  }

  return _roofData
end






AsianStyle.roofWallsMenuBuilder = function(subMenu, player)
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
      Amount = 2
    }
  }

  AsianStyle.neededTools = {'Hammer'}

  local needSkills = {
    Woodwork = 2
  }
	_sprite = {}
	_sprite.sprite = 'asianroofwalls_01_80'
	_sprite.northSprite = 'asianroofwalls_01_88'
	_sprite.corner = 'fixtures_asianwalls_03_39'
	_name = getText 'ContextMenu_RoofWall_1_Left'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_WoodRoofWalls']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)  
	_tooltip:setTexture(_sprite.sprite)
	
	_sprite = {}
	_sprite.sprite = 'asianroofwalls_01_87'
	_sprite.northSprite = 'asianroofwalls_01_95'
	_sprite.corner = 'fixtures_asianwalls_03_39'
	_name = getText 'ContextMenu_RoofWall_1_Right'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_WoodRoofWalls']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)  
	_tooltip:setTexture(_sprite.sprite)
	
	_sprite = {}
	_sprite.sprite = 'asianroofwalls_01_81'
	_sprite.northSprite = 'asianroofwalls_01_89'
	_sprite.corner = 'fixtures_asianwalls_03_39'
	_name = getText 'ContextMenu_RoofWall_2_Left'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_WoodRoofWalls']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)  
	_tooltip:setTexture(_sprite.sprite)

	_sprite = {}
	_sprite.sprite = 'asianroofwalls_01_86'
	_sprite.northSprite = 'asianroofwalls_01_94'
	_sprite.corner = 'fixtures_asianwalls_03_39'
	_name = getText 'ContextMenu_RoofWall_2_Right'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_WoodRoofWalls']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)  
	_tooltip:setTexture(_sprite.sprite)

	_sprite = {}
	_sprite.sprite = 'asianroofwalls_01_82'
	_sprite.northSprite = 'asianroofwalls_01_90'
	_sprite.corner = 'fixtures_asianwalls_03_39'
	_name = getText 'ContextMenu_RoofWall_3_Left'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_WoodRoofWalls']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)  
	_tooltip:setTexture(_sprite.sprite)

	_sprite = {}
	_sprite.sprite = 'asianroofwalls_01_85'
	_sprite.northSprite = 'asianroofwalls_01_93'
	_sprite.corner = 'fixtures_asianwalls_03_39'
	_name = getText 'ContextMenu_RoofWall_3_Right'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_WoodRoofWalls']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)  
	_tooltip:setTexture(_sprite.sprite)

	_sprite = {}
	_sprite.sprite = 'asianroofwalls_01_83'
	_sprite.northSprite = 'asianroofwalls_01_91'
	_sprite.corner = 'fixtures_asianwalls_03_39'
	_name = getText 'ContextMenu_RoofWall_4_Left'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_WoodRoofWalls']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)  
	_tooltip:setTexture(_sprite.sprite)
 
	_sprite = {}
	_sprite.sprite = 'asianroofwalls_01_84'
	_sprite.northSprite = 'asianroofwalls_01_92'
	_sprite.corner = 'fixtures_asianwalls_03_39'
	_name = getText 'ContextMenu_RoofWall_4_Right'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_WoodRoofWalls']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)  
	_tooltip:setTexture(_sprite.sprite)
 
 	_sprite = {}
	_sprite.sprite = 'asianroofwalls_01_99'
	_sprite.northSprite = 'asianroofwalls_01_103'
	_sprite.corner = 'fixtures_asianwalls_03_39'
	_name = getText 'ContextMenu_RoofMid_1'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_WoodRoofWalls']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)  

	_sprite = {}
	_sprite.sprite = 'asianroofwalls_01_98'
	_sprite.northSprite = 'asianroofwalls_01_102'
	_sprite.corner = 'fixtures_asianwalls_03_39'
	_name = getText 'ContextMenu_RoofMid_2'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_WoodRoofWalls']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)  
	

 	_sprite = {}
	_sprite.sprite = 'asianroofwalls_01_97'
	_sprite.northSprite = 'asianroofwalls_01_101'
	_sprite.corner = 'fixtures_asianwalls_03_39'
	_name = getText 'ContextMenu_RoofMid_3'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_WoodRoofWalls']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)  

	_sprite = {}
	_sprite.sprite = 'asianroofwalls_01_96'
	_sprite.northSprite = 'asianroofwalls_01_100'
	_sprite.corner = 'fixtures_asianwalls_03_39'
	_name = getText 'ContextMenu_RoofMid_4'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_WoodRoofWalls']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)  
	
	
	
	
	
	
	
	_sprite = {}
	_sprite.sprite = 'asianroofwalls_01_40'
	_sprite.northSprite = 'asianroofwalls_01_56'
	_sprite.corner = 'fixtures_asianwalls_01_11'
	_name = getText 'ContextMenu_RoofWall_1_Left'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_BaseRoofWalls']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)  

	_sprite = {}
	_sprite.sprite = 'asianroofwalls_01_69'
	_sprite.northSprite = 'asianroofwalls_01_53'
	_sprite.corner = 'fixtures_asianwalls_01_11'
	_name = getText 'ContextMenu_RoofWall_1_Right'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_BaseRoofWalls']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)  

	_sprite = {}
	_sprite.sprite = 'asianroofwalls_01_41'
	_sprite.northSprite = 'asianroofwalls_01_57'
	_sprite.corner = 'fixtures_asianwalls_01_11'
	_name = getText 'ContextMenu_RoofWall_2_Left'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_BaseRoofWalls']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)  

	_sprite = {}
	_sprite.sprite = 'asianroofwalls_01_68'
	_sprite.northSprite = 'asianroofwalls_01_52'
	_sprite.corner = 'fixtures_asianwalls_01_11'
	_name = getText 'ContextMenu_RoofWall_2_Right'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_BaseRoofWalls']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)  

	_sprite = {}
	_sprite.sprite = 'asianroofwalls_01_42'
	_sprite.northSprite = 'asianroofwalls_01_58'
	_sprite.corner = 'fixtures_asianwalls_01_11'
	_name = getText 'ContextMenu_RoofWall_3_Left'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_BaseRoofWalls']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)  

	_sprite = {}
	_sprite.sprite = 'asianroofwalls_01_67'
	_sprite.northSprite = 'asianroofwalls_01_51'
	_sprite.corner = 'fixtures_asianwalls_01_11'
	_name = getText 'ContextMenu_RoofWall_3_Right'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_BaseRoofWalls']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)  

	_sprite = {}
	_sprite.sprite = 'asianroofwalls_01_43'
	_sprite.northSprite = 'asianroofwalls_01_59'
	_sprite.corner = 'fixtures_asianwalls_01_11'
	_name = getText 'ContextMenu_RoofWall_4_Left'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_BaseRoofWalls']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)  

	_sprite = {}
	_sprite.sprite = 'asianroofwalls_01_66'
	_sprite.northSprite = 'asianroofwalls_01_50'
	_sprite.corner = 'fixtures_asianwalls_01_11'
	_name = getText 'ContextMenu_RoofWall_4_Right'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_BaseRoofWalls']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)  

	_sprite = {}
	_sprite.sprite = 'asianroofwalls_01_79'
	_sprite.northSprite = 'asianroofwalls_01_75'
	_sprite.corner = 'fixtures_asianwalls_01_11'
	_name = getText 'ContextMenu_RoofMid_1'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_BaseRoofWalls']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)  

	_sprite = {}
	_sprite.sprite = 'asianroofwalls_01_78'
	_sprite.northSprite = 'asianroofwalls_01_74'
	_sprite.corner = 'fixtures_asianwalls_01_11'
	_name = getText 'ContextMenu_RoofMid_2'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_BaseRoofWalls']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)  

	_sprite = {}
	_sprite.sprite = 'asianroofwalls_01_47'
	_sprite.northSprite = 'asianroofwalls_01_71'
	_sprite.corner = 'fixtures_asianwalls_01_11'
	_name = getText 'ContextMenu_RoofMid_3'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_BaseRoofWalls']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)  

	_sprite = {}
	_sprite.sprite = 'asianroofwalls_01_46'
	_sprite.northSprite = 'asianroofwalls_01_70'
	_sprite.corner = 'fixtures_asianwalls_01_11'
	_name = getText 'ContextMenu_RoofMid_4'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_BaseRoofWalls']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)  
	
end	
	
--[[AsianStyle.onBuildWoodenWall = function(ignoreThisArgument, sprite, player, name)
  local _wall = ISWoodenWall:new(sprite.sprite, sprite.northSprite, sprite.corner)

  _wall.canBePlastered = AsianStyle.playerCanPlaster
  _wall.canBarricade = false
  _wall.modData['wallType'] = 'wall'
  _wall.player = player
  _wall.name = name

  _wall.corner = sprite.corner

  _wall.modData['need:Base.Plank'] = 4
  _wall.modData['need:Base.Nails'] = 4
  _wall.modData['xp:Woodwork'] = 5

  AsianStyle.equipToolPrimary(_wall, player, 'Hammer')

  getCell():setDrag(_wall, player)
end]]