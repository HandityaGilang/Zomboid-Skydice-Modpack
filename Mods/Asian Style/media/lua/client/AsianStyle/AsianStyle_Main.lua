--
-- Created by IntelliJ IDEA.
-- User: ProjectSky
-- Date: 2017/7/11
-- Time: 13:10
-- Project Zomboid More Builds Mod
--

-- pull global functions to local
local getSpecificPlayer = getSpecificPlayer
local pairs = pairs
local split = string.split
local getItemNameFromFullType = getItemNameFromFullType
local PerkFactory = PerkFactory
local getMoveableDisplayName = Translator.getMoveableDisplayName
local getSprite = getSprite
local getFirstTypeEval = getFirstTypeEval
local getItemCountFromTypeRecurse = getItemCountFromTypeRecurse
local getText = getText

local AsianStyle = {}
AsianStyle.NAME = 'More Builds'
AsianStyle.AUTHOR = 'ProjectSky, SiderisAnon'
AsianStyle.VERSION = '1.1.6'

print('Mod Loaded: ' .. AsianStyle.NAME .. ' by ' .. AsianStyle.AUTHOR .. ' (v' .. AsianStyle.VERSION .. ')')

AsianStyle.neededMaterials = {}
AsianStyle.neededTools = {}
AsianStyle.toolsList = {}
AsianStyle.playerSkills = {}
AsianStyle.textSkillsRed = {}
AsianStyle.textSkillsGreen = {}
AsianStyle.playerCanPlaster = false
AsianStyle.textTooltipHeader = ' <RGB:2,2,2> <LINE> <LINE>' .. getText('Tooltip_craft_Needs') .. ' : <LINE> '
AsianStyle.textCanRotate = '<LINE> <RGB:1,1,1>' .. getText('Tooltip_craft_pressToRotate', Keyboard.getKeyName(getCore():getKey('Rotate building')))
AsianStyle.textPlasterRed = '<RGB:1,0,0> <LINE> <LINE>' .. getText('Tooltip_PlasterRed_Description')
AsianStyle.textPlasterGreen = '<RGB:1,1,1> <LINE> <LINE>' .. getText('Tooltip_PlasterGreen_Description')
AsianStyle.textPlasterNever = '<RGB:1,0,0> <LINE> <LINE>' .. getText('Tooltip_PlasterNever_Description')

AsianStyle.textWallDescription = getText('Tooltip_Wall_Description')
AsianStyle.textPillarDescription = getText('Tooltip_Pillar_Description')
AsianStyle.textDoorFrameDescription = getText('Tooltip_DoorFrame_Description')
AsianStyle.textWindowFrameDescription = getText('Tooltip_WindowFrame_Description')
AsianStyle.textFenceDescription = getText('Tooltip_Fence_Description')
AsianStyle.textFencePostDescription = getText('Tooltip_FencePost_Description')
AsianStyle.textDoorGenericDescription = getText('Tooltip_craft_woodenDoorDesc')
AsianStyle.textDoorIndustrial = getText('Tooltip_DoorIndustrial_Description')
AsianStyle.textDoorExterior = getText('Tooltip_DoorExterior_Description')
AsianStyle.textStairsDescription = getText('Tooltip_craft_stairsDesc')
AsianStyle.textFloorDescription = getText('Tooltip_Floor_Description')
AsianStyle.textBarElementDescription = getText('Tooltip_BarElement_Description')
AsianStyle.textBarCornerDescription = getText('Tooltip_BarCorner_Description')
AsianStyle.textTrashCanDescription = getText('Tooltip_TrashCan_Description')
AsianStyle.textLightPoleDescription = getText('Tooltip_LightPole_Description')
AsianStyle.textSmallTableDescription = getText('Tooltip_SmallTable_Description')
AsianStyle.textLargeTableDescription = getText('Tooltip_LargeTable_Description')
AsianStyle.textCouchFrontDescription = getText('Tooltip_CouchFront_Description')
AsianStyle.textCouchRearDescription = getText('Tooltip_CouchRear_Description')
AsianStyle.textDresserDescription = getText('Tooltip_Dresser_Description')
AsianStyle.textBedDescription = getText('Tooltip_Bed_Description')
AsianStyle.textFlowerBedDescription = getText('Tooltip_FlowerBed_Description')

--- 建筑技能需求定义
--- @todo: 优化结构
AsianStyle.skillLevel = {
  simpleObject = 1,
  waterwellObject = 7,
  simpleDecoration = 1,
  landscaping = 1,
  lighting = 4,
  simpleContainer = 3,
  complexContainer = 5,
  advancedContainer = 7,
  simpleFurniture = 3,
  basicContainer = 1,
  basicFurniture = 1,
  moderateFurniture = 2,
  counterFurniture = 3,
  complexFurniture = 4,
  logObject = 0,
  floorObject = 1,
  wallObject = 2,
  doorObject = 3,
  garageDoorObject = 6,
  stairsObject = 6,
  stoneArchitecture = 5,
  metalArchitecture = 5,
  architecture = 5,
  complexArchitecture = 5,
  nearlyimpossible = 5,
  barbecueObject = 4,
  fridgeObject = 3,
  lightingObject = 2,
  generatorObject = 3,
  windowsObject = 2,
}

--- 建筑耐久定义
--- @todo: 优化结构
AsianStyle.healthLevel = {
  stoneWall = 300,
  metalWall = 700,
  metalStairs = 400,
  woodContainer = 200,
  stoneContainer = 250,
  metalContainer = 350,
  wallDecoration = 50,
  woodenFence = 100,
  metalDoor = 700
}

--- OnFillWorldObjectContextMenu回调
--- @param player number: IsoPlayer索引
--- @param context ISContextMenu: 上下文菜单实例
--- @param worldobjects table: 世界对象表
--- @param test boolean: 如果是测试附近对象则返回true, 否则返回false
--- @todo 优化性能, ISContextMenu性能过差, 经测试, 注册300+ISContextMenu实例会导致游戏主线程冻结0.24秒左右, 这是非常严重的性能问题, 需要官方解决
AsianStyle.OnFillWorldObjectContextMenu = function(player, context, worldobjects, test)
  if getCore():getGameMode() == 'LastStand' then
    return
  end

  if test and ISWorldObjectContextMenu.Test then
    return true
  end

	local playerObj = getSpecificPlayer(player)
	if playerObj:getVehicle() then
    return
	end

  if AsianStyle.haveAToolToBuild(player) then

    AsianStyle.buildSkillsList(player)

    if AsianStyle.playerSkills["Woodwork"] > 0 or ISBuildMenu.cheat then
      AsianStyle.playerCanPlaster = true
    else
      AsianStyle.playerCanPlaster = false
    end

    local _firstTierMenu = context:addOption(getText('ContextMenu_AsianStyle'))
    local _secondTierMenu = ISContextMenu:getNew(context)
    context:addSubMenu(_firstTierMenu, _secondTierMenu)
	
	local _architectureOption = _secondTierMenu:addOption(getText('ContextMenu_Builds_Menu'))
    local _architectureThirdTierMenu = _secondTierMenu:getNew(_secondTierMenu)
    context:addSubMenu(_architectureOption, _architectureThirdTierMenu)

    local _wallsOption = _architectureThirdTierMenu:addOption(getText('ContextMenu_Wall_Menu'))
    local _wallsSubMenu = _architectureThirdTierMenu:getNew(_architectureThirdTierMenu)

    context:addSubMenu(_wallsOption, _wallsSubMenu)
    AsianStyle.wallStylesMenuBuilder(_wallsSubMenu, player, context)
	
    local _doorsOption = _architectureThirdTierMenu:addOption(getText('ContextMenu_Door'))
    local _doorsSubMenu = _architectureThirdTierMenu:getNew(_architectureThirdTierMenu)

    context:addSubMenu(_doorsOption, _doorsSubMenu)
    AsianStyle.doorsMenuBuilder(_doorsSubMenu, player, context)
	
	local _floorsOption = _architectureThirdTierMenu:addOption(getText('ContextMenu_Floor'))
    local _floorsSubMenu = _architectureThirdTierMenu:getNew(_architectureThirdTierMenu)

    context:addSubMenu(_floorsOption, _floorsSubMenu)
    AsianStyle.floorsMenuBuilder(_floorsSubMenu, player, context)
	
	local _PodiumOption = _architectureThirdTierMenu:addOption(getText('ContextMenu_Podium_Menu'))
    local _PodiumSubMenu = _architectureThirdTierMenu:getNew(_architectureThirdTierMenu)

    context:addSubMenu(_PodiumOption, _PodiumSubMenu)
    AsianStyle.podiumMenuBuilder(_PodiumSubMenu, player, context)
	
	local _pillarsOption = _architectureThirdTierMenu:addOption(getText('ContextMenu_Pillars_Menu'))
    local _pillarsSubMenu = _architectureThirdTierMenu:getNew(_architectureThirdTierMenu)

    context:addSubMenu(_pillarsOption, _pillarsSubMenu)
    AsianStyle.pillarsMenuBuilder(_pillarsSubMenu, player, context)
	
	local _roofOption = _architectureThirdTierMenu:addOption(getText('ContextMenu_Roofs_Menu'))
    local _roofSubMenu = _architectureThirdTierMenu:getNew(_architectureThirdTierMenu)

    context:addSubMenu(_roofOption, _roofSubMenu)
    AsianStyle.roofMenuBuilder(_roofSubMenu, player, context)
	
	--[[local _roofWallsOption = _architectureThirdTierMenu:addOption(getText('ContextMenu_RoofsWalls_Menu'))
    local _roofWallsSubMenu = _architectureThirdTierMenu:getNew(_architectureThirdTierMenu)

    context:addSubMenu(_roofWallsOption, _roofWallsSubMenu)
    AsianStyle.roofWallsMenuBuilder(_roofWallsSubMenu, player, context)]]
	
	local _fencesOption = _architectureThirdTierMenu:addOption(getText('ContextMenu_Fence_Menu'))
    local _fencesSubMenu = _architectureThirdTierMenu:getNew(_architectureThirdTierMenu)

    context:addSubMenu(_fencesOption, _fencesSubMenu)
    AsianStyle.fencesMenuBuilder(_fencesSubMenu, player, context)
	
	local _furnitureOption = _secondTierMenu:addOption(getText('ContextMenu_Furniture'))
    local _furnitureThirdTierMenu = _secondTierMenu:getNew(_secondTierMenu)
    context:addSubMenu(_furnitureOption, _furnitureThirdTierMenu)

    local _smallTablesOption = _furnitureThirdTierMenu:addOption(getText('ContextMenu_SmallTable_Menu'))
    local _smallTablesSubMenu = _furnitureThirdTierMenu:getNew(_furnitureThirdTierMenu)

    context:addSubMenu(_smallTablesOption, _smallTablesSubMenu)
    AsianStyle.smallTablesMenuBuilder(_smallTablesSubMenu, player)
	    
	local _largeTablesOption = _furnitureThirdTierMenu:addOption(getText('ContextMenu_LargeTable_Menu'))
    local _largeTablesSubMenu = _furnitureThirdTierMenu:getNew(_furnitureThirdTierMenu)

    context:addSubMenu(_largeTablesOption, _largeTablesSubMenu)
    AsianStyle.largeTablesMenuBuilder(_largeTablesSubMenu, player)
	
	local _bedsOption = _furnitureThirdTierMenu:addOption(getText('ContextMenu_Bed'))
    local _bedsSubMenu = _furnitureThirdTierMenu:getNew(_furnitureThirdTierMenu)

    context:addSubMenu(_bedsOption, _bedsSubMenu)
    AsianStyle.bedsMenuBuilder(_bedsSubMenu, player)
	


  end
end

--- 检查物品是否损坏
--- @param item string: 需检查的物品名称
--- @return boolean: 如果物品未损坏返回true, 否则返回false
local function predicateNotBroken(item)
  return not item:isBroken()
end

--- 获取可移动家具本地化字符串
--- @param sprite string: Sprite名称
--- @return string: 获取的本地化字符串
AsianStyle.getMoveableDisplayName = function(sprite)
  local props = getSprite(sprite):getProperties()
  if props:Is('CustomName') then
    local name = props:Val('CustomName')
    if props:Is('GroupName') then
      name = props:Val('GroupName') .. ' ' .. name
    end
    return getMoveableDisplayName(name)
  end
end

--- 检查玩家是否拥有某些工具
--- @param player number: IsoPlayer索引
--- @return boolean: 如果满足工具条件需求则返回true否则返回false
AsianStyle.haveAToolToBuild = function(player)
  -- 多个工具在表内添加即可 [类型] {工具1, 工具2, ...}
  AsianStyle.toolsList['Hammer'] = {"Base.Hammer", "Base.HammerStone", "Base.BallPeenHammer", "Base.WoodenMallet", "Base.ClubHammer"}
  AsianStyle.toolsList['Screwdriver'] = {"Base.Screwdriver"}
  AsianStyle.toolsList['HandShovel'] = {"farming.HandShovel"}
  AsianStyle.toolsList['Saw'] = {"Base.Saw"}
  AsianStyle.toolsList['Spade'] = {"Base.Shovel"}
  AsianStyle.toolsList['Needle'] = {"Base.Needle"}

  local havaTools = nil

  havaTools = AsianStyle.getAvailableTools(player, 'Hammer')

  return havaTools or ISBuildMenu.cheat
end

--- 获取玩家库存内的可用工具
--- @param player number: IsoPlayer索引
--- @param tool string: 工具类型
--- @return InventoryItem: 获取的工具实例, 如空或已损坏返回nil
AsianStyle.getAvailableTools = function(player, tool)
  local tools = nil
  local toolList = AsianStyle.toolsList[tool]
  local inv = getSpecificPlayer(player):getInventory()
  for _, type in pairs (toolList) do
    tools = inv:getFirstTypeEval(type, predicateNotBroken)
    if tools then
      return tools
    end
  end
end

--- 装备主要工具
--- @param object IsoObject: IsoObject实例
--- @param player number: IsoPlayer索引
--- @param tool string: 工具类型
AsianStyle.equipToolPrimary = function(object, player, tool)
  local tools = nil
  tools = AsianStyle.getAvailableTools(player, tool)
  if tools then
    ISInventoryPaneContextMenu.equipWeapon(tools, true, false, player)
    object.noNeedHammer = true
  end
end

--- 装备次要工具
--- @param object Isoobject: Isoobject实例
--- @param player number: IsoPlayer索引
--- @param tool string: 工具类型
--- @info 未使用
AsianStyle.equipToolSecondary = function(object, player, tool)
  local tools = nil
  tools = AsianStyle.getAvailableTools(player, tool)
  if tools then
    ISInventoryPaneContextMenu.equipWeapon(tools, false, false, player)
  end
end

--- 构造技能文本
--- @param player number: IsoPlayer索引
AsianStyle.buildSkillsList = function(player)
  local perks = PerkFactory.PerkList
  local perkID = nil
  local perkType = nil
  for i = 0, perks:size() - 1 do
    perkID = perks:get(i):getId()
    perkType = perks:get(i):getType()
    AsianStyle.playerSkills[perkID] = getSpecificPlayer(player):getPerkLevel(perks:get(i))
    AsianStyle.textSkillsRed[perkID] = ' <RGB:1,0,0>' .. PerkFactory.getPerkName(perkType) .. ' ' .. AsianStyle.playerSkills[perkID] .. '/'
    AsianStyle.textSkillsGreen[perkID] = ' <RGB:1,1,1>' .. PerkFactory.getPerkName(perkType) .. ' '
  end
end

--- 检查&构造材料提示文本
--- @param player number: IsoPlayer索引
--- @param material string: 材料类型
--- @param amount number: 需要的材料数量
--- @param tooltip ISToolTip: 工具提示实例
--- @return boolean: 如果满足检查条件则返回true否则返回false
--- @info ISBuildMenu.countMaterial性能过低, 如果玩家库存中物品过多会卡游戏主线程, 不建议使用
AsianStyle.tooltipCheckForMaterial = function(player, material, amount, tooltip)
  local inv = getSpecificPlayer(player):getInventory()
  local type = split(material, '\\.')[2]
  local invItemCount = 0
  local groundItem = ISBuildMenu.materialOnGround
  if amount > 0 then
    invItemCount = inv:getItemCountFromTypeRecurse(material)

    if material == "Base.Nails" then
      invItemCount = invItemCount + inv:getItemCountFromTypeRecurse("Base.NailsBox") * 100
      if groundItem["Base.NailsBox"] then
        invItemCount = invItemCount + groundItem["Base.NailsBox"] * 100
      end
    end


    -- why #groundItem 0?
    for groundItemType, groundItemCount in pairs(groundItem) do
      if groundItemType == type then
        invItemCount = invItemCount + groundItemCount
      end
    end

    if invItemCount < amount then
      tooltip.description = tooltip.description .. ' <RGB:1,0,0>' .. getItemNameFromFullType(material) .. ' ' .. invItemCount .. '/' .. amount .. ' <LINE>'
      return false
    else
      tooltip.description = tooltip.description .. ' <RGB:1,1,1>' .. getItemNameFromFullType(material) .. ' ' .. invItemCount .. '/' .. amount .. ' <LINE>'
      return true
    end
  end
end

--- 检查&构造工具提示文本
--- @param player number: IsoPlayer索引
--- @param tool string: 工具类型
--- @param tooltip ISToolTip: 工具提示实例
--- @return boolean: 如果满足检查条件则返回true否则返回false
AsianStyle.tooltipCheckForTool = function(player, tool, tooltip)
  local tools = AsianStyle.getAvailableTools(player, tool)
  if tools then
    tooltip.description = tooltip.description .. ' <RGB:1,1,1>' .. tools:getName() .. ' <LINE>'
    return true
  else
    for _, type in pairs (AsianStyle.toolsList[tool]) do
      tooltip.description = tooltip.description .. ' <RGB:1,0,0>' .. getItemNameFromFullType(type) .. ' <LINE>'
      return false
    end
  end
end

--- 检查是否满足建造条件
--- @param skills table: 技能等级需求表, 支持被动技能 {Woodwork = 1, Strength = 2, ...}
--- @param option ISContextMenu: 上下文菜单实例
--- @return ISToolTip: 返回工具提示实例
AsianStyle.canBuildObject = function(skills, option, player)
  local _tooltip = ISToolTip:new()
  _tooltip:initialise()
  _tooltip:setVisible(false)
  option.toolTip = _tooltip

  local _canBuildResult = true

  _tooltip.description = AsianStyle.textTooltipHeader

  local _currentResult = true

  for _, _currentMaterial in pairs(AsianStyle.neededMaterials) do
    if _currentMaterial['Material'] and _currentMaterial['Amount'] then
      _currentResult = AsianStyle.tooltipCheckForMaterial(player, _currentMaterial['Material'], _currentMaterial['Amount'], _tooltip)
    else
      _tooltip.description = _tooltip.description .. ' <RGB:1,0,0> Error in required material definition. <LINE>'
      _canBuildResult = false
    end

    if not _currentResult then
      _canBuildResult = false
    end
  end

  for _, _currentTool in pairs(AsianStyle.neededTools) do
    _currentResult = AsianStyle.tooltipCheckForTool(player, _currentTool, _tooltip)

    if not _currentResult then
      _canBuildResult = false
    end
  end

  for skill, level in pairs (skills) do
    if (AsianStyle.playerSkills[skill] < level) then
      _tooltip.description = _tooltip.description .. AsianStyle.textSkillsRed[skill]
      _canBuildResult = false
    else
      _tooltip.description = _tooltip.description .. AsianStyle.textSkillsGreen[skill]
    end
    _tooltip.description = _tooltip.description .. level .. ' <LINE>'
  end

  if not _canBuildResult and not ISBuildMenu.cheat then
    option.onSelect = nil
    option.notAvailable = true
  end
  return _tooltip
end

--- 获取AsianStyle实例
--- @return table: AsianStyle table
function getAsianStyleInstance()
  return AsianStyle
end

--- 注册OnFillWorldObjectContextMenu事件
-- @callback1 player number: 调用的IsoPlayer索引
-- @callback2 context ISContextMenu: 上下文菜单实例
-- @callback3 worldobjects table: 世界对象表
-- @callback4 test Boolean: 如果是测试附近对象则返回true, 否则返回false
Events.OnFillWorldObjectContextMenu.Add(AsianStyle.OnFillWorldObjectContextMenu)