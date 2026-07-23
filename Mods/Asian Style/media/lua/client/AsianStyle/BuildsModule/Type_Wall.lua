if not getAsianStyleInstance then
  require('AsianStyle/AsianStyle_Main')
end

local AsianStyle = getAsianStyleInstance()

--[[AsianStyle.wallsMenuBuilder = function(subMenu, player, context)
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
 
	local _wallsFullWoodData = AsianStyle.getWallsFullWoodData()
	local _currentOption
	local _currentSubMenu

  for _subsectionName, _subsectionData in pairs(_wallsFullWoodData) do
    _currentOption = subMenu:addOption(_subsectionName)
    _currentSubMenu = subMenu:getNew(subMenu)
    context:addSubMenu(_currentOption, _currentSubMenu)

    for _, _currentList in pairs(_subsectionData) do
      _sprite = {}
      _sprite.sprite = _currentList[1]
      _sprite.northSprite = _currentList[2]
	  _sprite.eastSprite = _currentList[3]
	  _sprite.southSprite = _currentList[4]
	  _sprite.corner = _currentList[5]

	  _name = _currentList[6]

      _option = _currentSubMenu:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)

      _tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
      _tooltip:setName(_name)
      _tooltip:setTexture(_sprite.sprite)
      
    end
  end
	
	AsianStyle.neededMaterials = {
    {
      Material = 'Base.Plank',
      Amount = 4
    },
    {
      Material = 'Base.Screws',
      Amount = 4
    }
  }
  
    AsianStyle.neededTools = {'Hammer'}
	
	local _wallsWindowedData = AsianStyle.getWallsWindowedData()
	local _currentOption
	local _currentSubMenu
		
	for _subsectionName, _subsectionData in pairs(_wallsWindowedData) do
		_currentOption = subMenu:addOption(_subsectionName)
		_currentSubMenu = subMenu:getNew(subMenu)
		context:addSubMenu(_currentOption, _currentSubMenu)
	
		for _, _currentList in pairs(_subsectionData) do
			_sprite = {}
			_sprite.sprite = _currentList[1]
			_sprite.northSprite = _currentList[2]
			_sprite.eastSprite = _currentList[3]
			_sprite.southSprite = _currentList[4]
			_sprite.corner = _currentList[5]

			_name = _currentList[6]

			_option = _currentSubMenu:addOption(_name, nil, AsianStyle.onBuildWindowWall, _sprite, player, _name)

			_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
			_tooltip:setName(_name)
			_tooltip:setTexture(_sprite.sprite)
		end
	end  
end]]

AsianStyle.wallsMenuBuilder = function(subMenu, player)
  local _sprite
  local _option
  local _tooltip
  local _name = ''

--*******************WALLS**************

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


--********************"Interior" Walls********************
 
	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_01_8'
	_sprite.northSprite = 'fixtures_asianwalls_01_9'
	_sprite.corner = 'fixtures_asianwalls_01_11'
	_name = getText 'ContextMenu_Framed'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_Interior']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
    _tooltip:setTexture(_sprite.sprite)
	
	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_01_12'
	_sprite.northSprite = 'fixtures_asianwalls_01_13'
	_sprite.corner = 'fixtures_asianwalls_01_15'
	_name = getText 'ContextMenu_NoFrames'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_Interior']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)

	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_01_18'
	_sprite.northSprite = 'fixtures_asianwalls_01_17'
	_sprite.corner = 'fixtures_asianwalls_01_11'
	_name = getText 'ContextMenu_LeftFrame'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_Interior']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)
	
	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_01_16'
	_sprite.northSprite = 'fixtures_asianwalls_01_19'
	_sprite.corner = 'fixtures_asianwalls_01_11'
	_name = getText 'ContextMenu_RightFrame'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_Interior']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)
	
	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_01_96'
	_sprite.northSprite = 'fixtures_asianwalls_01_98'
	_sprite.corner = 'fixtures_asianwalls_01_11'
	_name = getText 'ContextMenu_HalfWall_Left'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_Interior']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)  

	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_01_97'
	_sprite.northSprite = 'fixtures_asianwalls_01_99'
	_sprite.corner = 'fixtures_asianwalls_01_11'
	_name = getText 'ContextMenu_HalfWall_Right'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_Interior']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)  



--******************"Exterior" Walls******************--
  
    _sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_01_52'
	_sprite.northSprite = 'fixtures_asianwalls_01_53'
	_sprite.corner = 'fixtures_asianwalls_01_11'
	_name = getText 'ContextMenu_Framed'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_Half_Wood']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)

	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_01_48'
	_sprite.northSprite = 'fixtures_asianwalls_01_49'
	_sprite.corner = 'fixtures_asianwalls_01_11'
	_name = getText 'ContextMenu_NoFrames'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_Half_Wood']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)

	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_01_54'
	_sprite.northSprite = 'fixtures_asianwalls_01_51'
	_sprite.corner = 'fixtures_asianwalls_01_11'
	_name = getText 'ContextMenu_LeftFrame'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_Half_Wood']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)	

	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_01_50'
	_sprite.northSprite = 'fixtures_asianwalls_01_55'
	_sprite.corner = 'fixtures_asianwalls_01_11'
	_name = getText 'ContextMenu_RightFrame'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_Half_Wood']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)	
	
	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_03_64'
	_sprite.northSprite = 'fixtures_asianwalls_03_65'
	_sprite.corner = 'fixtures_asianwalls_03_67'
	_name = getText 'ContextMenu_Siding'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_Half_Wood']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)

--*********************Wood Trims***************
  
	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_02_6'
	_sprite.northSprite = 'fixtures_asianwalls_02_7'
	_sprite.corner = 'fixtures_asianwalls_01_11'
	_name = getText 'ContextMenu_Framed'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_WoodTrims']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)
  
	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_02_2'
	_sprite.northSprite = 'fixtures_asianwalls_02_3'
	_sprite.corner = 'fixtures_asianwalls_01_11'
	_name = getText 'ContextMenu_LeftFrame'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_WoodTrims']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)
	
	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_02_4'
	_sprite.northSprite = 'fixtures_asianwalls_02_5'
	_sprite.corner = 'fixtures_asianwalls_01_11'
	_name = getText 'ContextMenu_RightFrame'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_WoodTrims']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)
	
	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_02_0'
	_sprite.northSprite = 'fixtures_asianwalls_02_1'
	_sprite.corner = 'fixtures_asianwalls_01_11'
	_name = getText 'ContextMenu_NoFrames'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_WoodTrims']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)

 	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_03_0'
	_sprite.northSprite = 'fixtures_asianwalls_03_1'
	_sprite.corner = 'fixtures_asianwalls_01_11'
	_name = getText 'ContextMenu_MiddlePlank_NoFrames'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_WoodTrims']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)
	
	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_03_2'
	_sprite.northSprite = 'fixtures_asianwalls_03_3'
	_sprite.corner = 'fixtures_asianwalls_01_11'
	_name = getText 'ContextMenu_MiddlePlank_LeftFrame'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_WoodTrims']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)
	
	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_03_4'
	_sprite.northSprite = 'fixtures_asianwalls_03_5'
	_sprite.corner = 'fixtures_asianwalls_01_11'
	_name = getText 'ContextMenu_MiddlePlank_RightFrame'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_WoodTrims']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)
	
	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_03_6'
	_sprite.northSprite = 'fixtures_asianwalls_03_7'
	_sprite.corner = 'fixtures_asianwalls_01_11'
	_name = getText 'ContextMenu_MiddlePlank_Framed'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_WoodTrims']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)

--*******************FULLY WOODEN******************
  
	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_03_36'
	_sprite.northSprite = 'fixtures_asianwalls_03_37'
	_sprite.eastSprite = 'fixtures_asianwalls_03_38'
	_sprite.southSprite = 'fixtures_asianwalls_03_39'
	_sprite.corner = 'fixtures_asianwalls_03_39'
	_name = getText 'ContextMenu_Asian_Wall_FullWood_Plain'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_FullWood']:addOption(_name, nil, AsianStyle.onBuildWoodenWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)  
	_tooltip:setTexture(_sprite.sprite)
	

 --************************************************************
 --							WINDOW WALLS
 --************************************************************
 
 AsianStyle.neededMaterials = {
    {
      Material = 'Base.Plank',
      Amount = 4
    },
    {
      Material = 'Base.Screws',
      Amount = 4
    }
  }
  
    AsianStyle.neededTools = {'Hammer'}
	
	--********************"Interior" Walls********************
	
	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_01_0'
	_sprite.northSprite = 'fixtures_asianwalls_01_1'
	_name = getText 'ContextMenu_Traditional_Window_Wall'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_Interior']:addOption(_name, nil, AsianStyle.onBuildWindowWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)

	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_01_24'
	_sprite.northSprite = 'fixtures_asianwalls_01_26'
	_name = getText 'ContextMenu_NoFrames_Left'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_Interior']:addOption(_name, nil, AsianStyle.onBuildWindowWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)

	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_01_25'
	_sprite.northSprite = 'fixtures_asianwalls_01_27'
	_name = getText 'ContextMenu_NoFrames_Right'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_Interior']:addOption(_name, nil, AsianStyle.onBuildWindowWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)

	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_01_28'
	_sprite.northSprite = 'fixtures_asianwalls_01_30'
	_name = getText 'ContextMenu_Framed_Left'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_Interior']:addOption(_name, nil, AsianStyle.onBuildWindowWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)

	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_01_29'
	_sprite.northSprite = 'fixtures_asianwalls_01_31'
	_name = getText 'ContextMenu_Framed_Right'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_Interior']:addOption(_name, nil, AsianStyle.onBuildWindowWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)

--****************************Wood Trims***********************
	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_03_40'
	_sprite.northSprite = 'fixtures_asianwalls_03_42'
	_name = getText 'ContextMenu_NoFrames_BLINDLeft'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_WoodTrims']:addOption(_name, nil, AsianStyle.onBuildWindowWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)

	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_03_41'
	_sprite.northSprite = 'fixtures_asianwalls_03_43'
	_name = getText 'ContextMenu_NoFrames_BLINDRight'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_WoodTrims']:addOption(_name, nil, AsianStyle.onBuildWindowWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)

	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_03_44'
	_sprite.northSprite = 'fixtures_asianwalls_03_46'
	_name = getText 'ContextMenu_Framed_BLINDLeft'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_WoodTrims']:addOption(_name, nil, AsianStyle.onBuildWindowWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)

	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_03_45'
	_sprite.northSprite = 'fixtures_asianwalls_03_47'
	_name = getText 'ContextMenu_Framed_BLINDRight'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_WoodTrims']:addOption(_name, nil, AsianStyle.onBuildWindowWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)
	
	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_02_8'
	_sprite.northSprite = 'fixtures_asianwalls_02_10'
	_name = getText 'ContextMenu_NoFrames_Left'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_WoodTrims']:addOption(_name, nil, AsianStyle.onBuildWindowWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)

	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_02_9'
	_sprite.northSprite = 'fixtures_asianwalls_02_11'
	_name = getText 'ContextMenu_NoFrames_Right'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_WoodTrims']:addOption(_name, nil, AsianStyle.onBuildWindowWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)

	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_02_12'
	_sprite.northSprite = 'fixtures_asianwalls_02_14'
	_name = getText 'ContextMenu_Framed_Left'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_WoodTrims']:addOption(_name, nil, AsianStyle.onBuildWindowWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)

	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_02_13'
	_sprite.northSprite = 'fixtures_asianwalls_02_15'
	_name = getText 'ContextMenu_Framed_Right'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_WoodTrims']:addOption(_name, nil, AsianStyle.onBuildWindowWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)

--******************Half Wood******************

	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_01_56'
	_sprite.northSprite = 'fixtures_asianwalls_01_58'
	_name = getText 'ContextMenu_NoFrames_Left'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_Half_Wood']:addOption(_name, nil, AsianStyle.onBuildWindowWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)	

	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_01_57'
	_sprite.northSprite = 'fixtures_asianwalls_01_59'
	_name = getText 'ContextMenu_NoFrames_Right'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_Half_Wood']:addOption(_name, nil, AsianStyle.onBuildWindowWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)	

	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_01_60'
	_sprite.northSprite = 'fixtures_asianwalls_01_62'
	_name = getText 'ContextMenu_Framed_Left'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_Half_Wood']:addOption(_name, nil, AsianStyle.onBuildWindowWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)	
	
	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_01_61'
	_sprite.northSprite = 'fixtures_asianwalls_01_63'
	_name = getText 'ContextMenu_Framed_Right'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_Half_Wood']:addOption(_name, nil, AsianStyle.onBuildWindowWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)	
	
--**********************Fully Wooden*************--	

	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_03_8'
	_sprite.northSprite = 'fixtures_asianwalls_03_10'
	_name = getText 'ContextMenu_Blind_Left'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_FullWood']:addOption(_name, nil, AsianStyle.onBuildWindowWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)	
	
	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_03_9'
	_sprite.northSprite = 'fixtures_asianwalls_03_11'
	_name = getText 'ContextMenu_Blind_Right'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_FullWood']:addOption(_name, nil, AsianStyle.onBuildWindowWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)	
	
	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_03_12'
	_sprite.northSprite = 'fixtures_asianwalls_03_14'
	_sprite.corner = 'fixtures_asianwalls_03_39'
	_name = getText 'ContextMenu_TransparentWindow_Left'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_FullWood']:addOption(_name, nil, AsianStyle.onBuildWindowWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)	

	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_03_13'
	_sprite.northSprite = 'fixtures_asianwalls_03_15'
	_name = getText 'ContextMenu_TransparentWindow_Right'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_FullWood']:addOption(_name, nil, AsianStyle.onBuildWindowWall, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)	

end

AsianStyle.onBuildWoodenWall = function(ignoreThisArgument, sprite, player, name)
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
end


AsianStyle.onBuildWindowWall = function(ignoreThisArgument, sprite, player, name)
  local _window = ISWindowWallObj:new(sprite.sprite, sprite.northSprite, getSpecificPlayer(player))

  _window.player = player
  _window.name = name
	
  _window.eastSprite = sprite.eastSprite
  _window.southSprite = sprite.southSprite
  _window.corner = sprite.corner

  _window.modData['need:Base.Plank'] = 4
  _window.modData['need:Base.Screws'] = 4
  _window.modData['xp:Woodwork'] = 15
  
  getCell():setDrag(_window, player)
end



AsianStyle.wallStylesMenuBuilder = function(subMenu, player, context)
  local _stylesOptions = {}
  local _stylesSubMenus = {}
  local _styleList = {
	getText 'ContextMenu_Asian_Wall_Interior',	
	getText 'ContextMenu_Asian_Wall_WoodTrims',	
	getText 'ContextMenu_Asian_Wall_Half_Wood',
	getText 'ContextMenu_Asian_Wall_FullWood',
	getText 'ContextMenu_Asian_Wall_BaseRoofWalls',
	getText 'ContextMenu_Asian_Wall_WoodRoofWalls',
  }

  for _, _style in pairs(_styleList) do
    _stylesOptions[_style] = subMenu:addOption(_style)
    _stylesSubMenus[_style] = subMenu:getNew(subMenu)
    context:addSubMenu(_stylesOptions[_style], _stylesSubMenus[_style])
  end
	AsianStyle.wallsMenuBuilder(_stylesSubMenus, player)
    AsianStyle.doorFramesMenuBuilder(_stylesSubMenus, player)
	AsianStyle.windowFramesMenuBuilder(_stylesSubMenus, player)
	AsianStyle.roofWallsMenuBuilder(_stylesSubMenus, player)
end