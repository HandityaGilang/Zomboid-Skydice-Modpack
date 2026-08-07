-- TODO:make all the config match XUI
-- Need to find a common unit

NCConfig = {}
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

NCConfig = {
    -- Main Panel Config
    -- Background opacity values used by the main Neat Crafting panels.
    -- Keep text and icons fully opaque while making large UI surfaces less solid.
    windowBackgroundAlpha = 0.82,
    titleBackgroundAlpha = 0.88,
    contentBackgroundAlpha = 0.76,
    innerBackgroundAlpha = 0.78,
    categoryBackgroundAlpha = 0.78,
    categoryPinnedAlpha = 0.84,
    popupBackgroundAlpha = 0.84,
    -- Secondary empty-area opacity values.
    -- These are lower because the area mostly frames slots/recipe boxes/buttons instead of text.
    recipeListBackgroundAlpha = 0.62,
    slotPanelBackgroundAlpha = 0.62,
    slotPopupBackgroundAlpha = 0.70,
    actionBackgroundAlpha = 0.62,

    padding = math.floor(FONT_HGT_SMALL*0.4),
    scrollBarWidth = math.floor(FONT_HGT_SMALL * 0.6),
    titleHeight = math.floor((FONT_HGT_MEDIUM * 1.2 )/ 2) * 2,
    scrollViewSpacing = math.max(math.floor(FONT_HGT_SMALL/19),1),

    -- CategoryListPanel,
    categoryListItemHeight = math.floor(FONT_HGT_MEDIUM * 1.5), -- depends on word

    --recipeListPanel
    recipeListWidth = math.floor(FONT_HGT_SMALL * 16),
    recipeListItemHeight = (FONT_HGT_SMALL * 3 + FONT_HGT_SMALL * 0.2), -- depends on word

    --inputPanel
    inputSlotHeight = math.floor(FONT_HGT_SMALL * 2.8),
}

NCConfig.categoryListWidth = NCConfig.categoryListItemHeight + NCConfig.padding * 2 + NCConfig.scrollBarWidth
NCConfig.craftInputHeight = math.floor(NCConfig.titleHeight + NCConfig.scrollViewSpacing*2 + (NCConfig.inputSlotHeight + NCConfig.padding)*4 + NCConfig.padding)
NCConfig.inputslotWidth = NCConfig.inputSlotHeight * 3
NCConfig.inputPanelWidth = NCConfig.inputslotWidth * 2 + NCConfig.padding * 3 + NCConfig.scrollBarWidth
NCConfig.minPanelWidth = NCConfig.categoryListWidth+ NCConfig.recipeListWidth + NCConfig.padding + NCConfig.inputPanelWidth + NCConfig.padding

-- Calculate minimum height of each panel
NCConfig.recipeInfoMinHeight = math.floor(NCConfig.padding/2 + FONT_HGT_MEDIUM + (FONT_HGT_SMALL * 3) + NCConfig.padding/2)

NCConfig.craftOutputMinHeight = math.floor(FONT_HGT_SMALL * 2.5) + NCConfig.padding * 4 + NCConfig.titleHeight

NCConfig.craftInputMinHeight = math.floor(NCConfig.titleHeight + NCConfig.scrollViewSpacing*2 + (NCConfig.inputSlotHeight + NCConfig.padding)*4 + NCConfig.padding)

NCConfig.recipeListMinHeight = math.floor((FONT_HGT_SMALL * 1.6) + (FONT_HGT_SMALL / 8)*2 + (NCConfig.recipeListItemHeight * 7) + NCConfig.padding)

-- Calculate window minimum height
NCConfig.headerHeight = math.floor(FONT_HGT_MEDIUM * 1.5)

-- Calculate total height of the right area
NCConfig.rightAreaTotalHeight = NCConfig.craftInputMinHeight + NCConfig.recipeInfoMinHeight + NCConfig.craftOutputMinHeight + NCConfig.padding*5

-- Total height of the left area
NCConfig.leftAreaTotalHeight = NCConfig.recipeListMinHeight + NCConfig.padding*2

-- Use the maximum as the content area height
NCConfig.contentMinHeight = math.max(NCConfig.rightAreaTotalHeight, NCConfig.leftAreaTotalHeight)

-- Calculate overall minimum window height
NCConfig.windowMinHeight = NCConfig.headerHeight + NCConfig.contentMinHeight