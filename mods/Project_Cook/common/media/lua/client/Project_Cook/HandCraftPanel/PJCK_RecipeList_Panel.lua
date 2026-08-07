require "ISUI/ISPanel"

PJCK_RecipeList_Panel = ISPanel:derive("PJCK_RecipeList_Panel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- Convert both older Java recipe lists and newer CraftRecipeListNodeCollection values
-- into a flat Lua table of CraftRecipe objects. B42.19 returns grouped recipe nodes,
-- while the old Project Cook tab expected a simple list with size()/get().
local function PJCK_recipeCollectionToTable(recipeCollection)
    local result = {}
    if not recipeCollection then
        return result
    end

    local collection = recipeCollection
    local okAllRecipes, allRecipes = pcall(function()
        if collection.getAllRecipes then
            return collection:getAllRecipes()
        end
        return nil
    end)

    if okAllRecipes and allRecipes then
        collection = allRecipes
    end

    local okSize, size = pcall(function()
        if collection.size then
            return collection:size()
        end
        return nil
    end)

    if okSize and size then
        for i = 0, size - 1 do
            local okGet, recipe = pcall(function()
                return collection:get(i)
            end)
            if okGet and recipe then
                table.insert(result, recipe)
            end
        end
        return result
    end

    if type(collection) == "table" then
        for _, recipe in ipairs(collection) do
            if recipe then
                table.insert(result, recipe)
            end
        end
    end

    return result
end

-- ---------------------------------------------------------- --
-- 构造函数与初始化
-- ---------------------------------------------------------- --

function PJCK_RecipeList_Panel:initialise()
    ISPanel.initialise(self)
end

function PJCK_RecipeList_Panel:new(x, y, width, height, HandCraftPanel)
    local o = ISPanel.new(self, x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.HandCraftPanel = HandCraftPanel
    o.player = HandCraftPanel.player
    o.logic = HandCraftPanel.logic
    o.scrollBarWidth = FONT_HGT_SMALL * 0.6
    o.filterHeight = FONT_HGT_SMALL*1.6
    o.allRecipes = {}
    
    -- 筛选相关变量
    o.showOnlyCanMake = false
    o.showOnlyKnown = false
    o.showOnlySkillMet = false
    o.searchText = ""
    o.filteredRecipes = {}

    o.searchMode = "RecipeName"
    
    -- 项目样式配置
    o.padding = FONT_HGT_SMALL * 0.2
    o.itemHeight = FONT_HGT_SMALL * 3 + FONT_HGT_SMALL * 0.2

    o.UIElementBGTextures = {
        left = getTexture("media/ui/Project_Cook/Button/Button_BG_L.png"),
        middle = getTexture("media/ui/Project_Cook/Button/Button_BG_M.png"),
        right = getTexture("media/ui/Project_Cook/Button/Button_BG_R.png")
    }

    o.contentBgTextures = {
        topLeft = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_LT2.png"),
        top = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_T2.png"),
        topRight = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_RT2.png"),
        left = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_L.png"),
        middle = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_M.png"),
        right = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_R.png"),
        bottomLeft = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_LB.png"),
        bottom = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_B.png"),
        bottomRight = getTexture("media/ui/Project_Cook/Panel/Panel_InsideBG_RB.png")
    }
    
    return o
end

-- ---------------------------------------------------------- --
-- 创建子元素
-- ---------------------------------------------------------- --

function PJCK_RecipeList_Panel:createChildren()
    
    -- 创建filterBar
    self.filterBar = ISPanel:new(0, 0, self.width, self.filterHeight)
    self.filterBar:initialise()
    self.filterBar.backgroundColor.a = 0
    self.filterBar.borderColor.a = 0
    self:addChild(self.filterBar)
    
    local buttonSize = FONT_HGT_SMALL*1.2
    local buttonSpacing = FONT_HGT_SMALL * 0.3
    local buttonY = (self.filterHeight - buttonSize) / 2 +1
    
    -- 可制作筛选按钮
    local canMakeButtonX = buttonSpacing
    self.CanMakeFilterButton = PJCK_SquareButton.createCanMakeFilterButton(canMakeButtonX, buttonY, buttonSize, self, self.onCanMakeFilterButtonClick)
    self.CanMakeFilterButton:initialise()
    self.filterBar:addChild(self.CanMakeFilterButton)
    
    -- 技能等级筛选按钮
    local skillButtonX = canMakeButtonX + buttonSize + buttonSpacing
    self.skillFilterButton = PJCK_SquareButton.createSkillFilterButton(skillButtonX, buttonY, buttonSize, self, self.onSkillFilterButtonClick)
    self.skillFilterButton:initialise()
    self.filterBar:addChild(self.skillFilterButton)
    
    -- 已知配方筛选按钮
    local knownButtonX = skillButtonX + buttonSize + buttonSpacing
    self.knownFilterButton = PJCK_SquareButton.createKnownFilterButton(knownButtonX, buttonY, buttonSize, self, self.onKnownFilterButtonClick)
    self.knownFilterButton:initialise()
    self.filterBar:addChild(self.knownFilterButton)

    local searchCategoryButtonX = knownButtonX + buttonSize + buttonSpacing
    self.searchCategoryButton = PJCK_SquareButton.createSearchCategoryButton(searchCategoryButtonX, buttonY, buttonSize, self, self.onSearchCategoryButtonClick)
    self.searchCategoryButton:initialise()
    self.filterBar:addChild(self.searchCategoryButton)
    
    -- 搜索框
    local searchBoxX = searchCategoryButtonX + buttonSize + buttonSpacing*2
    local searchBoxWidth = self.width - searchBoxX -buttonSpacing*2
    local searchBoxHeight = buttonSize
    
    self.searchBox = ISTextEntryBox:new("", searchBoxX, buttonY, searchBoxWidth, searchBoxHeight)
    self.searchBox:initialise()
    self.searchBox.font = UIFont.Small
    self.searchBox.onTextChange = function()
        self:onSearchTextChanged()
    end
    self.searchBox.backgroundColor.a = 0
    self.searchBox.borderColor.a = 0
    self.searchBox.prerender = function(searchBox)
        PJCK_UIHelper.drawThreeSlice(
            searchBox,
            -buttonSpacing, 0, searchBox.width + buttonSpacing*2, searchBox.height,
            self.UIElementBGTextures.left,
            self.UIElementBGTextures.middle,
            self.UIElementBGTextures.right,
            0.8, 0.4, 0.4, 0.4
        )
    end
    self.filterBar:addChild(self.searchBox)
    
    -- 创建虚拟滚动视图
    local ScrollViewPadding = FONT_HGT_SMALL/8
    local contentHeight = self.height - self.filterHeight  - ScrollViewPadding*2
    self.virtualScrollView = PJCK_VirtualScrollView:new(0, self.filterHeight + ScrollViewPadding, self.width, contentHeight)
    self.virtualScrollView:initialise()
    local itemWidth = self.width - self.scrollBarWidth - self.padding
    self.virtualScrollView:setConfig(self.itemHeight, self.padding)
    self:addChild(self.virtualScrollView)
    
    -- 设置项目创建回调
    self.virtualScrollView:setOnCreateItem(function()
        return PJCK_RecipeList_Box:new(self.padding, 0, itemWidth, nil, self)
    end)
    
    -- 设置项目更新回调
    self.virtualScrollView:setOnUpdateItem(function(itemObject, recipe)
        local canMake = false
        local okCanMake, canMakeResult = pcall(function()
            return self.logic:canCharacterPerformRecipe(recipe)
        end)
        if okCanMake then
            canMake = canMakeResult
        end
        itemObject:setRecipe(recipe, canMake)
    end)
    
    self:loadAllRecipes()
end

-- ---------------------------------------------------------- --
-- 加载与更新配方
-- ---------------------------------------------------------- --

function PJCK_RecipeList_Panel:loadAllRecipes()
    self.allRecipes = {}
    local CookingRecipes = CraftRecipeManager.queryRecipes("Cooking")
    local filteredRecipes = ArrayList.new()

    if CookingRecipes then
        for i = 0, CookingRecipes:size() - 1 do
            local recipe = CookingRecipes:get(i)
            local includeRecipe = false

            if recipe then
                local okHand, inHandCraft = pcall(function()
                    return recipe:isInHandCraftCraft()
                end)
                local okSurface, anySurface = pcall(function()
                    return recipe:isAnySurfaceCraft()
                end)
                includeRecipe = (okHand and inHandCraft) or (okSurface and anySurface)
            end

            if includeRecipe then
                filteredRecipes:add(recipe)
            end
        end
    end

    self.logic:setRecipes(filteredRecipes)
    self.allRecipes = PJCK_recipeCollectionToTable(self.logic:getRecipeList())
    self:updateRecipeList()
    print("Loaded " .. #self.allRecipes .. " recipes")
end

-- ---------------------------------------------------------- --
-- 过滤列表
-- ---------------------------------------------------------- --

-- 过滤可制作
function PJCK_RecipeList_Panel:onCanMakeFilterButtonClick()
    self.showOnlyCanMake = not self.showOnlyCanMake
    self.CanMakeFilterButton:setFilterActive(self.showOnlyCanMake)
    self:updateRecipeList()
end

-- 过滤只有已知配方
function PJCK_RecipeList_Panel:onKnownFilterButtonClick()
    self.showOnlyKnown = not self.showOnlyKnown
    self.knownFilterButton:setFilterActive(self.showOnlyKnown)
    self:updateRecipeList()
end

-- 过滤技能等级
function PJCK_RecipeList_Panel:onSkillFilterButtonClick()
    self.showOnlySkillMet = not self.showOnlySkillMet
    self.skillFilterButton:setFilterActive(self.showOnlySkillMet)
    self:updateRecipeList()
end

-- 检查配方是否已知
function PJCK_RecipeList_Panel:isRecipeKnown(recipe)
    if not recipe or not self.player then
        return false
    end

    if not recipe:needToBeLearn() then
        return true
    end

    return self.player:isRecipeKnown(recipe, true)
end

-- 检查配方是否满足技能要求
function PJCK_RecipeList_Panel:isRecipeSkillMet(recipe)
    if not recipe or not self.player then
        return false
    end
    
    if recipe:getRequiredSkillCount() > 0 then
        for i = 0, recipe:getRequiredSkillCount() - 1 do
            local requiredSkill = recipe:getRequiredSkill(i)
            if not CraftRecipeManager.hasPlayerRequiredSkill(requiredSkill, self.player) then
                return false
            end
        end
    end
    
    return true
end

function PJCK_RecipeList_Panel:onSearchCategoryButtonClick()
    local context = ISContextMenu.get(0, self.searchCategoryButton:getAbsoluteX(), self.searchCategoryButton:getAbsoluteY() + self.searchCategoryButton:getHeight())
    
    local option1 = context:addOption("Recipe Name", self, self.setSearchMode, "RecipeName", getText("IGUI_FilterType_RecipeName"))
    option1.iconTexture = getTexture("media/ui/Project_Cook/ICON/Grey.png")
    local option2 = context:addOption("Input Items", self, self.setSearchMode, "InputName", getText("IGUI_FilterType_InputName"))
    option2.iconTexture = getTexture("media/ui/Project_Cook/ICON/Blue.png")
    local option3 = context:addOption("Output Items", self, self.setSearchMode, "OutputName", getText("IGUI_FilterType_OutputName"))
    option3.iconTexture = getTexture("media/ui/Project_Cook/ICON/Orange.png")

end

function PJCK_RecipeList_Panel:setSearchMode(mode)
    self.searchMode = mode

    self.searchCategoryButton:setSearchMode(mode)

    if self.searchText and self.searchText ~= "" then
        self:performSearch()
    end
end

function PJCK_RecipeList_Panel:onSearchTextChanged()
    self.searchText = self.searchBox:getInternalText()
    self:performSearch()
end

function PJCK_RecipeList_Panel:performSearch()
    local searchString = self.searchText or ""
    
    if self.searchMode and self.searchMode ~= "RecipeName" and searchString ~= "" then
        searchString = searchString .. "-@-" .. self.searchMode
    end

    self.logic:filterRecipeList(searchString, nil, false, self.player)
end

-- ---------------------------------------------------------- --
-- 更新配方列表
-- ---------------------------------------------------------- --

function PJCK_RecipeList_Panel:updateRecipeList()
    local sortedRecipes = PJCK_recipeCollectionToTable(self.logic:getRecipeList())

    self.filteredRecipes = {}
    for _, recipe in ipairs(sortedRecipes) do
        local canMake = false
        local okCanMake, canMakeResult = pcall(function()
            return self.logic:canCharacterPerformRecipe(recipe)
        end)
        if okCanMake then
            canMake = canMakeResult
        end

        local isKnown = self:isRecipeKnown(recipe)
        local skillMet = self:isRecipeSkillMet(recipe)
        
        local shouldInclude = true
        
        -- 应用本地过滤条件
        if self.showOnlyCanMake and not canMake then
            shouldInclude = false
        end
        if self.showOnlyKnown and not isKnown then
            shouldInclude = false
        end
        if self.showOnlySkillMet and not skillMet then
            shouldInclude = false
        end
        
        if shouldInclude then
            table.insert(self.filteredRecipes, recipe)
        end
    end
    
    local currentList
    if self.showOnlyCanMake or self.showOnlyKnown or self.showOnlySkillMet then
        currentList = self.filteredRecipes
    else
        currentList = sortedRecipes
    end

    if self.virtualScrollView then
        self.virtualScrollView:setDataSource(currentList, true)
    end
    
    print("Updated recipe list: " .. #currentList .. " recipes")
end

-- ---------------------------------------------------------- --
-- 渲染函数
-- ---------------------------------------------------------- --

function PJCK_RecipeList_Panel:prerender()
    -- 绘制标题栏
    PJCK_UIHelper.drawThreeSlice(
        self,
        0,
        0,
        self.width,
        self.filterHeight,
        self.HandCraftPanel.titleBarTextures.left,
        self.HandCraftPanel.titleBarTextures.middle,
        self.HandCraftPanel.titleBarTextures.right,
        1.0, 0.2, 0.2, 0.2
    )

    -- 绘制内容区域背景
    PJCK_UIHelper.drawNineSlice(
        self,
        0,
        self.filterHeight,
        self.width,
        self.height-self.filterHeight,
        self.HandCraftPanel.contentBgTextures,
        1.0, 0.1, 0.1, 0.1
    )
end

function PJCK_RecipeList_Panel:render()
end

return PJCK_RecipeList_Panel