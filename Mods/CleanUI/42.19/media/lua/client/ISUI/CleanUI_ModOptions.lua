local MOD_ID = "CleanUI"
local NAME_COLOR_ID = "itemNameColor"
local CATEGORY_COLOR_ID = "itemCategoryColor"
local USE_CLEANUI_INVENTORY_ID = "useCleanUIInventory"
local CATEGORY_TEXT_ALIGNMENT_ID = "categoryTextAlignment"
local TIMED_ACTION_FIX_NOTIFY_ID = "notifyTimedActionFix"
local TRANSFER_BUTTON_LAYOUT_ID = "transferButtonLayout"

local defaultNameColor = {r=0.8, g=0.8, b=0.8, a=1.0}
local defaultCategoryColor = {r=0.8, g=0.7, b=0.3, a=1.0}

CLEANUI_INVENTORY_UI_TOGGLE_CALLBACKS = CLEANUI_INVENTORY_UI_TOGGLE_CALLBACKS or {}
CLEANUI_MODOPTIONS_LOADED = CLEANUI_MODOPTIONS_LOADED or false
CLEANUI_PENDING_INVENTORY_UI_MODE = CLEANUI_PENDING_INVENTORY_UI_MODE
CLEANUI_INVENTORY_UI_TOGGLE_TICK_INSTALLED = CLEANUI_INVENTORY_UI_TOGGLE_TICK_INSTALLED or false

local function CleanUI_toBool(value)
    -- Accept booleans, strings, and numeric values returned by ModOptions.
    return value == true or value == 1 or value == "1" or value == "true"
end

local function CleanUI_loadModOptionsOnce()
    -- ModOptions.ini is only loaded by vanilla after opening the options menu.
    -- Load it once ourselves so saved values apply immediately in-game.
    if CLEANUI_MODOPTIONS_LOADED then
        return
    end
    if PZAPI and PZAPI.ModOptions and type(PZAPI.ModOptions.load) == "function" then
        pcall(function()
            PZAPI.ModOptions:load()
        end)
    end
    CLEANUI_MODOPTIONS_LOADED = true
end

function CleanUI_isCleanInventoryUIEnabled()
    -- Default to CleanUI enabled when the option is missing.
    CleanUI_loadModOptionsOnce()

    local options = PZAPI and PZAPI.ModOptions and PZAPI.ModOptions:getOptions(MOD_ID)
    local option = options and options:getOption(USE_CLEANUI_INVENTORY_ID)
    if not option then
        return true
    end
    return CleanUI_toBool(option:getValue())
end

function CleanUI_RegisterInventoryUiToggleCallback(callback)
    -- Register a callback that receives the enabled state as a boolean.
    if type(callback) ~= "function" then
        return
    end

    table.insert(CLEANUI_INVENTORY_UI_TOGGLE_CALLBACKS, callback)
    pcall(function()
        callback(CleanUI_isCleanInventoryUIEnabled())
    end)
end

local function CleanUI_callInventoryUiToggleCallbacks(enabled)
    -- Notify all runtime listeners when the UI mode changes.
    for _, callback in ipairs(CLEANUI_INVENTORY_UI_TOGGLE_CALLBACKS) do
        if type(callback) == "function" then
            pcall(function()
                callback(enabled)
            end)
        end
    end
end


local function CleanUI_isOptionsMenuOpen()
    -- Detect the in-game options screen so live inventory window rebuilds can
    -- be deferred until after the menu closes. Rebuilding immediately while
    -- MainOptions is visible can leave the inventory windows in front of it.
    if not MainOptions or not MainOptions.instance then
        return false
    end

    local instance = MainOptions.instance
    if instance.getIsVisible then
        local ok, visible = pcall(function()
            return instance:getIsVisible()
        end)
        if ok then
            return visible == true
        end
    end

    return instance.visible == true
end

local function CleanUI_installDeferredInventoryToggleTick()
    if CLEANUI_INVENTORY_UI_TOGGLE_TICK_INSTALLED or not Events or not Events.OnTick then
        return
    end

    CLEANUI_INVENTORY_UI_TOGGLE_TICK_INSTALLED = true

    Events.OnTick.Add(function()
        if CLEANUI_PENDING_INVENTORY_UI_MODE == nil then
            return
        end

        if CleanUI_isOptionsMenuOpen() then
            return
        end

        local enabled = CLEANUI_PENDING_INVENTORY_UI_MODE == true
        CLEANUI_PENDING_INVENTORY_UI_MODE = nil
        CleanUI_callInventoryUiToggleCallbacks(enabled)
    end)
end

local function CleanUI_requestInventoryUiToggle(enabled, deferWhileOptionsOpen)
    if deferWhileOptionsOpen and CleanUI_isOptionsMenuOpen() then
        CLEANUI_PENDING_INVENTORY_UI_MODE = enabled == true
        CleanUI_installDeferredInventoryToggleTick()
        return
    end

    -- Apply immediately when we are not inside the options menu.
    -- This avoids recursive re-entry and keeps the runtime toggle logic simple.
    CLEANUI_PENDING_INVENTORY_UI_MODE = nil
    CleanUI_callInventoryUiToggleCallbacks(enabled == true)
end

function CleanUI_setCleanInventoryUIEnabled(enabled)
    -- Persist the option and apply it immediately.
    CleanUI_loadModOptionsOnce()

    local options = PZAPI and PZAPI.ModOptions and PZAPI.ModOptions:getOptions(MOD_ID)
    local option = options and options:getOption(USE_CLEANUI_INVENTORY_ID)
    if option and type(option.setValue) == "function" then
        pcall(function()
            option:setValue(enabled)
        end)
    end

    if PZAPI and PZAPI.ModOptions and type(PZAPI.ModOptions.save) == "function" then
        pcall(function()
            PZAPI.ModOptions:save()
        end)
    end

    CleanUI_callInventoryUiToggleCallbacks(enabled == true)
end

local function InitCleanUIModOptions()
    if not (PZAPI and PZAPI.ModOptions) then
        return
    end

    local options = PZAPI.ModOptions:create(MOD_ID, getText("UI_CleanUI_ModName"))

-- ------------------------------------------------- --
-- Add options
-- ------------------------------------------------- --
    options:addTickBox(
        USE_CLEANUI_INVENTORY_ID,
        getText("UI_CleanUI_UseCleanUIInventory"),
        true,
        getText("UI_CleanUI_UseCleanUIInventory_Tooltip")
    )

    options:addTickBox(
        TIMED_ACTION_FIX_NOTIFY_ID,
        getText("UI_CleanUI_TimedActionFixNotifications"),
        true,
        getText("UI_CleanUI_TimedActionFixNotifications_Tooltip")
    )

    local transferMethodOption = options:addComboBox("transferMethod", getText("UI_CleanUI_TransferMethod"))
    transferMethodOption:addItem(getText("UI_CleanUI_TransferTargetContainer"), true)
    transferMethodOption:addItem(getText("UI_CleanUI_TransferNearbyContainer"), false)

    local transferButtonLayoutOption = options:addComboBox(TRANSFER_BUTTON_LAYOUT_ID, getText("UI_CleanUI_TransferButtonLayout"))
    transferButtonLayoutOption:addItem(getText("UI_CleanUI_TransferButtonLayoutMenu"), false)
    transferButtonLayoutOption:addItem(getText("UI_CleanUI_TransferButtonLayoutSplit"), true)

    local playerContainerPositionOption = options:addComboBox("playerContainerPosition",getText("UI_CleanUI_PlayerContainerPosition"))
    playerContainerPositionOption:addItem(getText("UI_CleanUI_ContainerPositionLeft"), false)
    playerContainerPositionOption:addItem(getText("UI_CleanUI_ContainerPositionRight"), true)

    local lootContainerPositionOption = options:addComboBox("lootContainerPosition",getText("UI_CleanUI_LootContainerPosition"))
    lootContainerPositionOption:addItem(getText("UI_CleanUI_ContainerPositionLeft"), true)
    lootContainerPositionOption:addItem(getText("UI_CleanUI_ContainerPositionRight"), false)

    local categoryTextAlignmentOption = options:addComboBox(CATEGORY_TEXT_ALIGNMENT_ID, getText("UI_CleanUI_CategoryTextAlignment"))
    categoryTextAlignmentOption:addItem(getText("UI_CleanUI_TextAlignLeft"), false)
    categoryTextAlignmentOption:addItem(getText("UI_CleanUI_TextAlignRight"), true)

    local buttonScaleOption = options:addComboBox("containerButtonScale",getText("UI_CleanUI_ContainerButtonScale"))
    buttonScaleOption:addItem("1x (default)", true)
    buttonScaleOption:addItem("1.2x", false)
    buttonScaleOption:addItem("1.5x", false)
    buttonScaleOption:addItem("1.8x", false)
    buttonScaleOption:addItem("2x", false)
    buttonScaleOption:addItem("0.9x", false)
    buttonScaleOption:addItem("0.8x", false)
    buttonScaleOption:addItem("0.7x", false)

    options:addSlider("backgroundOpacity", getText("UI_CleanUI_BackgroundOpacity").."(%)", 0.1, 1.0, 0.05, 0.65, nil)
    options:addSlider("containerBackgroundOpacity", getText("UI_CleanUI_ContainerBackgroundOpacity").."(%)", 0.1, 1.0, 0.05, 0.9, nil)

    options:addColorPicker(NAME_COLOR_ID,getText("UI_CleanUI_ItemNameColor"),defaultNameColor.r, defaultNameColor.g, defaultNameColor.b, defaultNameColor.a)
    options:addColorPicker(CATEGORY_COLOR_ID,getText("UI_CleanUI_ItemCategoryColor"),defaultCategoryColor.r, defaultCategoryColor.g, defaultCategoryColor.b, defaultCategoryColor.a)

    CleanUI_loadModOptionsOnce()

    local cleanInventoryOption = options:getOption(USE_CLEANUI_INVENTORY_ID)
    if cleanInventoryOption then
        cleanInventoryOption.onChange = function(self, selected)
            CleanUI_requestInventoryUiToggle(CleanUI_toBool(selected), true)
        end
        cleanInventoryOption.onChangeApply = function(self, selected)
            CleanUI_requestInventoryUiToggle(CleanUI_toBool(selected), true)
        end
    end

    CleanUI_requestInventoryUiToggle(CleanUI_isCleanInventoryUIEnabled(), false)
end

Events.OnGameBoot.Add(InitCleanUIModOptions)

-- ------------------------------------------------- --
-- Get Modoption
-- ------------------------------------------------- --


function CleanUI_shouldNotifyTimedActionFix()
    -- Return whether the optional diagnostic Halo Note is enabled.
    -- The gameplay fix itself always runs; this only controls debug visibility.
    if not (PZAPI and PZAPI.ModOptions) then
        return false
    end

    CleanUI_loadModOptionsOnce()

    local options = PZAPI.ModOptions:getOptions(MOD_ID)
    local option = options and options:getOption(TIMED_ACTION_FIX_NOTIFY_ID)
    if not option then
        return false
    end
    return CleanUI_toBool(option:getValue())
end

function CleanUI_getTransferMethod()
    local options = PZAPI.ModOptions:getOptions(MOD_ID)
    if options then
        local transferOption = options:getOption("transferMethod")
        if transferOption then
            local value = transferOption:getValue()
            return tostring(value) -- 1 = TransferTargetContainer, 2 = TransferNearbyContainer
        end
    end
    return "1"
end

function CleanUI_toggleTransferMethod()
    -- Toggle the persistent transfer target mode from the title-bar quick button.
    CleanUI_loadModOptionsOnce()

    local options = PZAPI and PZAPI.ModOptions and PZAPI.ModOptions:getOptions(MOD_ID)
    local transferOption = options and options:getOption("transferMethod")
    if not transferOption then
        return "1"
    end

    local currentValue = tostring(transferOption:getValue())
    local newValue = currentValue == "2" and 1 or 2

    if type(transferOption.setValue) == "function" then
        pcall(function()
            transferOption:setValue(newValue)
        end)
    end

    if PZAPI and PZAPI.ModOptions and type(PZAPI.ModOptions.save) == "function" then
        pcall(function()
            PZAPI.ModOptions:save()
        end)
    end

    return tostring(newValue)
end

function CleanUI_getTransferButtonLayout()
    local options = PZAPI and PZAPI.ModOptions and PZAPI.ModOptions:getOptions(MOD_ID)
    if options then
        local layoutOption = options:getOption(TRANSFER_BUTTON_LAYOUT_ID)
        if layoutOption then
            return tostring(layoutOption:getValue()) -- 1 = single menu button, 2 = split quick buttons
        end
    end
    return "2"
end

function CleanUI_getContainerPosition(inventoryPage)
    local options = PZAPI.ModOptions:getOptions(MOD_ID)
    if not options then
        return inventoryPage and (inventoryPage.onCharacter and "2" or "1") or "2"
    end

    if not inventoryPage then
        local playerOption = options:getOption("playerContainerPosition")
        if playerOption then
            local value = playerOption:getValue()
            return tostring(value)
        end
        return "2"
    end

    if inventoryPage.onCharacter then
        local playerOption = options:getOption("playerContainerPosition")
        if playerOption then
            local value = playerOption:getValue()
            return tostring(value) -- 1 = left, 2 = right
        end
        return "2"
    else
        local lootOption = options:getOption("lootContainerPosition")
        if lootOption then
            local value = lootOption:getValue()
            return tostring(value) -- 1 = left, 2 = right
        end
        return "1"
    end
end


function CleanUI_getCategoryTextAlignment()
    local options = PZAPI and PZAPI.ModOptions and PZAPI.ModOptions:getOptions(MOD_ID)
    if options then
        local alignOption = options:getOption(CATEGORY_TEXT_ALIGNMENT_ID)
        if alignOption then
            local value = alignOption:getValue()
            return tostring(value) -- 1 = left, 2 = right
        end
    end
    return "2"
end

function CleanUI_getItemNameColor()
    local options = PZAPI.ModOptions:getOptions(MOD_ID)
    if options then
        local colorOption = options:getOption(NAME_COLOR_ID)
        if colorOption and colorOption.color then
            return colorOption.color
        end
    end
    return defaultNameColor
end

function CleanUI_getItemCategoryColor()
    local options = PZAPI.ModOptions:getOptions(MOD_ID)
    if options then
        local colorOption = options:getOption(CATEGORY_COLOR_ID)
        if colorOption and colorOption.color then
            return colorOption.color
        end
    end
    return defaultCategoryColor
end

function CleanUI_getContainerButtonScaleMultiplier()
    local options = PZAPI.ModOptions:getOptions(MOD_ID)
    if options then
        local scaleOption = options:getOption("containerButtonScale")
        if scaleOption then
            local value = scaleOption:getValue()
            if value == 1 then return 1.0 end
            if value == 2 then return 1.2 end
            if value == 3 then return 1.5 end
            if value == 4 then return 1.8 end
            if value == 5 then return 2.0 end
            if value == 6 then return 0.9 end
            if value == 7 then return 0.8 end
            if value == 8 then return 0.7 end
        end
    end
    return 1.0
end

function CleanUI_getBackgroundOpacity()
    local options = PZAPI.ModOptions:getOptions(MOD_ID)
    if options then
        local opacityOption = options:getOption("backgroundOpacity")
        if opacityOption then
            return opacityOption:getValue()
        end
    end
    return 0.65
end

function CleanUI_getContainerBackgroundOpacity()
    local options = PZAPI.ModOptions:getOptions(MOD_ID)
    if options then
        local opacityOption = options:getOption("containerBackgroundOpacity")
        if opacityOption then
            return opacityOption:getValue()
        end
    end
    return 0.9
end
