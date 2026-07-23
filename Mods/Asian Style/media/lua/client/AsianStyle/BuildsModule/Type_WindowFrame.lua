if not getAsianStyleInstance then
  require('AsianStyle/AsianStyle_Main')
end

local AsianStyle = getAsianStyleInstance()

AsianStyle.windowFramesMenuBuilder = function(subMenu, player)
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
--*****************************"Interior" Walls********************
	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_01_92'
	_sprite.northSprite = 'fixtures_asianwalls_01_93'
	_sprite.corner = 'fixtures_asianwalls_01_11'
	_name = getText 'ContextMenu_Framed_WindowFrame'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_Interior']:addOption(_name, nil, AsianStyle.onBuildWoodenWindowFrame, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)

	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_01_90'
	_sprite.northSprite = 'fixtures_asianwalls_01_91'
	_sprite.corner = 'fixtures_asianwalls_01_11'
	_name = getText 'ContextMenu_noFrames_WindowFrame'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_Interior']:addOption(_name, nil, AsianStyle.onBuildWoodenWindowFrame, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)
--****************************** Half Wood *****************	
	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_01_84'
	_sprite.northSprite = 'fixtures_asianwalls_01_85'
	_sprite.corner = 'fixtures_asianwalls_01_11'
	_name = getText 'ContextMenu_Framed_WindowFrame'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_Half_Wood']:addOption(_name, nil, AsianStyle.onBuildWoodenWindowFrame, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)

	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_01_82'
	_sprite.northSprite = 'fixtures_asianwalls_01_83'
	_sprite.corner = 'fixtures_asianwalls_01_11'
	_name = getText 'ContextMenu_noFrames_WindowFrame'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_Half_Wood']:addOption(_name, nil, AsianStyle.onBuildWoodenWindowFrame, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)
  
    _sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_01_88'
	_sprite.northSprite = 'fixtures_asianwalls_01_86'
	_sprite.corner = 'fixtures_asianwalls_01_11'
	_name = getText 'ContextMenu_LeftFrame_WindowFrame'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_Half_Wood']:addOption(_name, nil, AsianStyle.onBuildWoodenWindowFrame, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)
    
    _sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_01_87'
	_sprite.northSprite = 'fixtures_asianwalls_01_89'
	_sprite.corner = 'fixtures_asianwalls_01_11'
	_name = getText 'ContextMenu_RightFrame_WindowFrame'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_Half_Wood']:addOption(_name, nil, AsianStyle.onBuildWoodenWindowFrame, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)
    
--*****************************Wood Trims**************************  
	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_02_32'
	_sprite.northSprite = 'fixtures_asianwalls_02_33'
	_sprite.corner = 'fixtures_asianwalls_01_11'
	_name = getText 'ContextMenu_noFrames_WindowFrame'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_WoodTrims']:addOption(_name, nil, AsianStyle.onBuildWoodenWindowFrame, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)

	_sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_02_34'
	_sprite.northSprite = 'fixtures_asianwalls_02_35'
	_sprite.corner = 'fixtures_asianwalls_01_11'
	_name = getText 'ContextMenu_Framed_WindowFrame'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_WoodTrims']:addOption(_name, nil, AsianStyle.onBuildWoodenWindowFrame, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)
  
  --*******************************Full Wood****************************
    _sprite = {}
	_sprite.sprite = 'fixtures_asianwalls_03_32'
	_sprite.northSprite = 'fixtures_asianwalls_03_33'
	_sprite.corner = 'fixtures_asianwalls_03_39'
	_name = getText 'ContextMenu_Asian_Wall_FullWood_WindowFrame'
	_option = subMenu[getText 'ContextMenu_Asian_Wall_FullWood']:addOption(_name, nil, AsianStyle.onBuildWoodenWindowFrame, _sprite, player, _name)
	_tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
	_tooltip:setName(_name)
	_tooltip:setTexture(_sprite.sprite)
end

AsianStyle.onBuildWoodenWindowFrame = function(ignoreThisArgument, sprite, player, name)
  local _windowFrame = ISWoodenWall:new(sprite.sprite, sprite.northSprite, sprite.corner)

  _windowFrame.canBePlastered = AsianStyle.playerCanPlaster
  _windowFrame.hoppable = true
  _windowFrame.isThumpable = false
  _windowFrame.player = player
  _windowFrame.name = name
  
  _windowFrame.corner = sprite.corner

  _windowFrame.modData['need:Base.Plank'] = 4
  _windowFrame.modData['need:Base.Nails'] = 4
  _windowFrame.modData['xp:Woodwork'] = 5

  getCell():setDrag(_windowFrame, player)
end

