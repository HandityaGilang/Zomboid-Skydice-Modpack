if not getAsianStyleInstance then
  require('AsianStyle/AsianStyle_Main')
end

local AsianStyle = getAsianStyleInstance()

AsianStyle.doorsMenuBuilder = function(subMenu, player, context)

	  local _glassDoorsOption = subMenu:addOption(getText 'ContextMenu_Sliding_Doors')
	  local _glassDoorsSubMenu = subMenu:getNew(subMenu)

	  context:addSubMenu(_glassDoorsOption, _glassDoorsSubMenu)
	  AsianStyle.glassDoorsMenuBuilder(_glassDoorsSubMenu, player)
  end

AsianStyle.glassDoorsMenuBuilder = function(subMenu, player)
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
    Woodwork = AsianStyle.skillLevel.doorObject
  }

  _sprite = {}
  _sprite.sprite = 'fixtures_asianwalls_02_49'
  _sprite.northSprite = 'fixtures_asianwalls_02_48'
  _sprite.corner = ''

  _name = getText 'ContextMenu_DoorFrameSim'

  _option = subMenu:addOption(_name, nil, AsianStyle.onBuildWoodenDoorFrame, _sprite, player, _name)
  _tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
  _tooltip:setName(_name)
  _tooltip.description = getText 'Tooltip_DoorFrameSim' .. _tooltip.description
  _tooltip:setTexture(_sprite.sprite)

  AsianStyle.neededMaterials = {
    {
      Material = 'Base.Plank',
      Amount = 4
    },
    {
      Material = 'Base.Nails',
      Amount = 4
    },
    {
      Material = 'Base.Doorknob',
      Amount = 1
    },
    {
      Material = 'Base.Hinge',
      Amount = 2
    }
  }

  AsianStyle.neededTools = {'Hammer'}

  local needSkills = {
    Woodwork = AsianStyle.skillLevel.doorObject
  }

  local _data = {
   

    Wooden_Sliding_Door = {
      sprites = {
        sprite = 'fixtures_asiandoors_01_4',
        northSprite = 'fixtures_asiandoors_01_5',
        openSprite = 'fixtures_asiandoors_01_6',
        openNorthSprite = 'fixtures_asiandoors_01_7',
      },
      action = AsianStyle.onBuildGlassDoor,
    },
	
	    Wooden_Bath_Door = {
      sprites = {
        sprite = 'fixtures_asiandoors_01_8',
        northSprite = 'fixtures_asiandoors_01_9',
        openSprite = 'fixtures_asiandoors_01_10',
        openNorthSprite = 'fixtures_asiandoors_01_11',
      },
      action = AsianStyle.onBuildGlassDoor,
    },
	
	    Wooden_Sliding__Exterior_Door = {
      sprites = {
        sprite = 'fixtures_asiandoors_01_20',
        northSprite = 'fixtures_asiandoors_01_21',
        openSprite = 'fixtures_asiandoors_01_22',
        openNorthSprite = 'fixtures_asiandoors_01_23',
      },
      action = AsianStyle.onBuildGlassDoor,
    },
	
	    Wooden_Transperent_Sliding_Door = {
      sprites = {
        sprite = 'fixtures_asiandoors_01_28',
        northSprite = 'fixtures_asiandoors_01_29',
        openSprite = 'fixtures_asiandoors_01_30',
        openNorthSprite = 'fixtures_asiandoors_01_31',
      },
      action = AsianStyle.onBuildGlassDoor,
    },
	
		White_Sliding_Door = {
      sprites = {
        sprite = 'fixtures_asiandoors_01_40',
        northSprite = 'fixtures_asiandoors_01_41',
        openSprite = 'fixtures_asiandoors_01_42',
        openNorthSprite = 'fixtures_asiandoors_01_43',
      },
      action = AsianStyle.onBuildGlassDoor,
    },
	
		K_Wooden_Sliding_Door = {
      sprites = {
        sprite = 'fixtures_asiandoors_01_32',
        northSprite = 'fixtures_asiandoors_01_33',
        openSprite = 'fixtures_asiandoors_01_34',
        openNorthSprite = 'fixtures_asiandoors_01_35',
      },
      action = AsianStyle.onBuildGlassDoor,
    },
   
   
  }

  for key, data in pairs(_data) do
    _name = getText('ContextMenu_' .. key)
    _option = subMenu:addOption(_name, nil, data.action, data.sprites, player, _name)
    _tooltip = AsianStyle.canBuildObject(needSkills, _option, player)
    _tooltip:setName(_name)
    _tooltip:setTexture(data.sprites.sprite)
  end
end


AsianStyle.onBuildGlassDoor = function(ignoreThisArgument, sprite, player, name)
  local _door = ISWoodenDoor:new(sprite.sprite, sprite.northSprite, sprite.openSprite, sprite.openNorthSprite)

  _door.dontNeedFrame = true
  _door.player = player
  _door.name = name

  _door.modData['need:Base.Plank'] = 4
  _door.modData['need:Base.Nails'] = 4
  _door.modData['need:Base.Hinge'] = 2
  _door.modData['need:Base.Doorknob'] = 1
  _door.modData['xp:Woodwork'] = 5

  getCell():setDrag(_door, player)
end
