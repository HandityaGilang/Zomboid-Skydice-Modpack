if not getAsianStyleInstance then
  require('AsianStyle/AsianStyle_Main')
end

local AsianStyle = getAsianStyleInstance()

AsianStyle.smallTablesMenuBuilder = function(subMenu, player)
  local _sprite
  local _option
  local _tooltip
  local _name = ''

  local _tableData = AsianStyle.getSmallTableData()

  AsianStyle.neededMaterials = {
    {
      Material = 'Base.Plank',
      Amount = 5
    },
    {
      Material = 'Base.Nails',
      Amount = 4
    }
  }

  AsianStyle.neededTools = {'Hammer'}

  local needSkills = {
    Woodwork = AsianStyle.skillLevel.simpleFurniture
  }

  for _, _currentList in pairs(_tableData) do
    _sprite = {}
    _sprite.sprite = _currentList[1]
    _sprite.northSprite = _currentList[2]

    _name = _currentList[3]

    _option = subMenu:addOption(_name, nil, AsianStyle.onBuildSingleTileWoodenTable, _sprite, player, _name)

    _tooltip = AsianStyle.canBuildObject(needSkills, _option, player)

    _tooltip:setName(_name)
    _tooltip:setTexture(_sprite.sprite)
  end
end

AsianStyle.getSmallTableData = function()
  local _smallTableData = {
    {'fixtures_asianfurniture_01_0', 'fixtures_asianfurniture_01_0', getText 'ContextMenu_Low_Table', AsianStyle.textSmallTableDescription},
    {'fixtures_asianfurniture_01_5', 'fixtures_asianfurniture_01_5', getText 'ContextMenu_Kotatsu', AsianStyle.textSmallTableDescription},

  }

  return _smallTableData
end

AsianStyle.onBuildSingleTileWoodenTable = function(ignoreThisArgument, sprite, player, name)
  local _table = ISSimpleFurniture:new(name, sprite.sprite, sprite.northSprite)

  _table.player = player
  _table.name = name

  _table.modData['need:Base.Plank'] = 5
  _table.modData['need:Base.Nails'] = 4
  _table.modData['xp:Woodwork'] = 5

  getCell():setDrag(_table, player)
end

AsianStyle.largeTablesMenuBuilder = function(subMenu, player)
  local _sprite
  local _option
  local _tooltip
  local _name = ''

  local _tableData = AsianStyle.getLargeTableData()

  AsianStyle.neededMaterials = {
    {
      Material = 'Base.Plank',
      Amount = 6
    },
    {
      Material = 'Base.Nails',
      Amount = 4
    }
  }

  AsianStyle.neededTools = {'Hammer'}

  local needSkills = {
    Woodwork = AsianStyle.skillLevel.complexFurniture
  }

  for _, _currentList in pairs(_tableData) do
    _sprite = {}
    _sprite.sprite = _currentList[1]
    _sprite.sprite2 = _currentList[2]
    _sprite.northSprite = _currentList[3]
    _sprite.northSprite2 = _currentList[4]

    _name = _currentList[5]

    _option = subMenu:addOption(_name, nil, AsianStyle.onBuildDoubleTileWoodenTable, _sprite, player, _name)

    _tooltip = AsianStyle.canBuildObject(needSkills, _option, player)

    _tooltip:setName(_name)
    _tooltip:setTexture(_sprite.sprite)
  end
end

AsianStyle.getLargeTableData = function()
  local _largeTableData = {
    {'fixtures_asianfurniture_01_2', 'fixtures_asianfurniture_01_1', 'fixtures_asianfurniture_01_3', 'fixtures_asianfurniture_01_4', getText 'ContextMenu_Low_Table', AsianStyle.textLargeTableDescription},
	   
  }

  return _largeTableData
end

AsianStyle.onBuildDoubleTileWoodenTable = function(ignoreThisArgument, sprite, player, name)
  local _table = ISDoubleTileFurniture:new(name, sprite.sprite, sprite.sprite2, sprite.northSprite, sprite.northSprite2)

  _table.player = player
  _table.name = name

  _table.modData['need:Base.Plank'] = 6
  _table.modData['need:Base.Nails'] = 4
  _table.modData['xp:Woodwork'] = 5

  getCell():setDrag(_table, player)
end