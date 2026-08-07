-- Require the InventoryUI module so we can use it.
local InventoryUI = require("Starlit/client/ui/InventoryUI")


-- Create the event listener.
-- If your IDE supports LuaCATS annotations, the following line tells it the function is an event listener.
---@type Starlit.InventoryUI.Callback_OnFillItemTooltip
local function addAdvLongBluntTooltip(tooltip, layout, item)
    if item:getFullType() ~= "LG.Advanced_LongBlunt_LEGION" then
        return
    end



    -- Adds the key-value pair "Grown at: Sweet Apple Acres" to every apple's tooltip.
    InventoryUI.addTooltipKeyValue(layout, "Faction:", "Legion")

    -- Adds a half-full progress bar for sweetness to every apple's tooltip.
    InventoryUI.addTooltipBar(layout, "Lethality:", 0.68)

    -- Adds a bites taken counter to every apple's tooltip, with the value 1.
    InventoryUI.addTooltipBar(layout, "Endurance Drain:", 0.25)

    -- Adds a bites taken counter to every apple's tooltip, with the value 1.
    InventoryUI.addTooltipInteger(layout, "Multi-hit:", 5, true)

    -- Finds and returns the Vanilla tooltip element showing the item's encumbrance.
    local encumbrance = InventoryUI.getTooltipElementByLabel(layout, getText("Tooltip_item_Weight") .. ":")
    -- If encumbrance is nil, then it's already been removed by another mod.
    if encumbrance then

    local AdvLongBluntTooltip = LayoutItem.new()
    layout.items:add(AdvLongBluntTooltip)

    -- text, r, g, b, a (0–1 floats)
    AdvLongBluntTooltip:setLabel("A piece of railing torn free during the city bombings,", 1, 1, 1, 1) 

    local AdvLongBluntTooltip = LayoutItem.new()
    layout.items:add(AdvLongBluntTooltip)
    AdvLongBluntTooltip:setLabel("a last-ditch effort to slow the Knox virus. Somehow, it", 1, 1, 1, 1) 

    local AdvLongBluntTooltip = LayoutItem.new()
    layout.items:add(AdvLongBluntTooltip)
    AdvLongBluntTooltip:setLabel("became someone’s trusted weapon.", 1, 1, 1, 1) 

    local AdvLongBluntTooltip = LayoutItem.new()
    layout.items:add(AdvLongBluntTooltip)
    AdvLongBluntTooltip:setLabel("Long blunt      Rare      Craftable", 0.4, 0.65, 1.0, 1) 


    end
end

-- Adds the event listener to the event, so that it will be called when the event is triggered.
InventoryUI.onFillItemTooltip:addListener(addAdvLongBluntTooltip)





-- Create the event listener.
-- If your IDE supports LuaCATS annotations, the following line tells it the function is an event listener.
---@type Starlit.InventoryUI.Callback_OnFillItemTooltip
local function addAdvAxeTooltip(tooltip, layout, item)
    if item:getFullType() ~= "LG.Advanced_Axe_LEGION" then
        return
    end



    -- Adds the key-value pair "Grown at: Sweet Apple Acres" to every apple's tooltip.
    InventoryUI.addTooltipKeyValue(layout, "Faction:", "Legion")

    -- Adds a half-full progress bar for sweetness to every apple's tooltip.
    InventoryUI.addTooltipBar(layout, "Lethality:", 0.60)

    -- Adds a bites taken counter to every apple's tooltip, with the value 1.
    InventoryUI.addTooltipBar(layout, "Endurance Drain:", 0.38)

    -- Adds a bites taken counter to every apple's tooltip, with the value 1.
    InventoryUI.addTooltipInteger(layout, "Multi-hit:", 3, true)

    -- Finds and returns the Vanilla tooltip element showing the item's encumbrance.
    local encumbrance = InventoryUI.getTooltipElementByLabel(layout, getText("Tooltip_item_Weight") .. ":")
    -- If encumbrance is nil, then it's already been removed by another mod.
    if encumbrance then

    local AdvAxeTooltip = LayoutItem.new()
    layout.items:add(AdvAxeTooltip)
    -- text, r, g, b, a (0–1 floats)
    AdvAxeTooltip:setLabel("This sign can stop the zeds, trust me.                 ", 1, 1, 1, 1) 



    local AdvAxeTooltip = LayoutItem.new()
    layout.items:add(AdvAxeTooltip)
    AdvAxeTooltip:setLabel("Axe      Rare      Craftable", 0.4, 0.65, 1.0, 1) 


    end
end

-- Adds the event listener to the event, so that it will be called when the event is triggered.
InventoryUI.onFillItemTooltip:addListener(addAdvAxeTooltip)




-- Create the event listener.
-- If your IDE supports LuaCATS annotations, the following line tells it the function is an event listener.
---@type Starlit.InventoryUI.Callback_OnFillItemTooltip
local function addAdvSpearTooltip(tooltip, layout, item)
    if item:getFullType() ~= "LG.Advanced_Spear_LEGION" then
        return
    end



    -- Adds the key-value pair "Grown at: Sweet Apple Acres" to every apple's tooltip.
    InventoryUI.addTooltipKeyValue(layout, "Faction:", "Legion")

    -- Adds a half-full progress bar for sweetness to every apple's tooltip.
    InventoryUI.addTooltipBar(layout, "Lethality:", 0.55)

    -- Adds a bites taken counter to every apple's tooltip, with the value 1.
    InventoryUI.addTooltipBar(layout, "Endurance Drain:", 0.65)

    -- Adds a bites taken counter to every apple's tooltip, with the value 1.
    InventoryUI.addTooltipInteger(layout, "Multi-hit:", 2, true)

    -- Finds and returns the Vanilla tooltip element showing the item's encumbrance.
    local encumbrance = InventoryUI.getTooltipElementByLabel(layout, getText("Tooltip_item_Weight") .. ":")
    -- If encumbrance is nil, then it's already been removed by another mod.
    if encumbrance then

    local AdvSpearTooltip = LayoutItem.new()
    layout.items:add(AdvSpearTooltip)
    AdvSpearTooltip:setLabel("A spear made from scrap steel and various vehicle ", 1, 1, 1, 1) 

    local AdvSpearTooltip = LayoutItem.new()
    layout.items:add(AdvSpearTooltip)
    AdvSpearTooltip:setLabel("components, often used as decoration. It is the", 1, 1, 1, 1) 

    local AdvSpearTooltip = LayoutItem.new()
    layout.items:add(AdvSpearTooltip)
    AdvSpearTooltip:setLabel("closest thing the Legion has to a standardized spear.", 1, 1, 1, 1) 

    local AdvSpearTooltip = LayoutItem.new()
    layout.items:add(AdvSpearTooltip)
    AdvSpearTooltip:setLabel("Spear      Rare      Craftable", 0.4, 0.65, 1.0, 1) 


    end
end

-- Adds the event listener to the event, so that it will be called when the event is triggered.
InventoryUI.onFillItemTooltip:addListener(addAdvSpearTooltip)



-- Create the event listener.
-- If your IDE supports LuaCATS annotations, the following line tells it the function is an event listener.
---@type Starlit.InventoryUI.Callback_OnFillItemTooltip
local function addAdvShortBluntTooltip(tooltip, layout, item)
    if item:getFullType() ~= "LG.Advanced_ShortBlunt_LEGION" then
        return
    end



    -- Adds the key-value pair "Grown at: Sweet Apple Acres" to every apple's tooltip.
    InventoryUI.addTooltipKeyValue(layout, "Faction:", "Legion")

    -- Adds a half-full progress bar for sweetness to every apple's tooltip.
    InventoryUI.addTooltipBar(layout, "Lethality:", 0.48)

    -- Adds a bites taken counter to every apple's tooltip, with the value 1.
    InventoryUI.addTooltipBar(layout, "Endurance Drain:", 0.60)

    -- Adds a bites taken counter to every apple's tooltip, with the value 1.
    InventoryUI.addTooltipInteger(layout, "Multi-hit:", 3, true)

    -- Finds and returns the Vanilla tooltip element showing the item's encumbrance.
    local encumbrance = InventoryUI.getTooltipElementByLabel(layout, getText("Tooltip_item_Weight") .. ":")
    -- If encumbrance is nil, then it's already been removed by another mod.
    if encumbrance then

    local AdvShortBluntTooltip = LayoutItem.new()
    layout.items:add(AdvShortBluntTooltip)
    -- text, r, g, b, a (0–1 floats)
    AdvShortBluntTooltip:setLabel("A bat reinforced with scrap metal plating, a design", 1, 1, 1, 1) 

    local AdvShortBluntTooltip = LayoutItem.new()
    layout.items:add(AdvShortBluntTooltip)
    AdvShortBluntTooltip:setLabel("favored by the Bone Seekers Clan.", 1, 1, 1, 1) 

    local AdvShortBluntTooltip = LayoutItem.new()
    layout.items:add(AdvShortBluntTooltip)
    AdvShortBluntTooltip:setLabel("Short blunt      Rare      Craftable", 0.4, 0.65, 1.0, 1) 


    end
end

-- Adds the event listener to the event, so that it will be called when the event is triggered.
InventoryUI.onFillItemTooltip:addListener(addAdvShortBluntTooltip)






-- Create the event listener.
-- If your IDE supports LuaCATS annotations, the following line tells it the function is an event listener.
---@type Starlit.InventoryUI.Callback_OnFillItemTooltip
local function addStandardShortBluntTooltip(tooltip, layout, item)
    if item:getFullType() ~= "LG.Standard_ShortBlunt_LEGION" then
        return
    end



    -- Adds the key-value pair "Grown at: Sweet Apple Acres" to every apple's tooltip.
    InventoryUI.addTooltipKeyValue(layout, "Faction:", "Legion")

    -- Adds a half-full progress bar for sweetness to every apple's tooltip.
    InventoryUI.addTooltipBar(layout, "Lethality:", 0.23)

    -- Adds a bites taken counter to every apple's tooltip, with the value 1.
    InventoryUI.addTooltipBar(layout, "Endurance Drain:", 0.65)

    -- Adds a bites taken counter to every apple's tooltip, with the value 1.
    InventoryUI.addTooltipInteger(layout, "Multi-hit:", 2, true)

    -- Finds and returns the Vanilla tooltip element showing the item's encumbrance.
    local encumbrance = InventoryUI.getTooltipElementByLabel(layout, getText("Tooltip_item_Weight") .. ":")
    -- If encumbrance is nil, then it's already been removed by another mod.
    if encumbrance then

    local StandardShortBluntTooltip = LayoutItem.new()
    layout.items:add(StandardShortBluntTooltip)
    -- text, r, g, b, a (0–1 floats)
    StandardShortBluntTooltip:setLabel("When the old world collapsed and panic ruled, survivors", 1, 1, 1, 1) 

    local StandardShortBluntTooltip = LayoutItem.new()
    layout.items:add(StandardShortBluntTooltip)
    StandardShortBluntTooltip:setLabel("often used anything at hand as a temporary weapon.", 1, 1, 1, 1) 

    local StandardShortBluntTooltip = LayoutItem.new()
    layout.items:add(StandardShortBluntTooltip)
    StandardShortBluntTooltip:setLabel("Yet some never abandoned their first lifesavers, no", 1, 1, 1, 1) 


    local StandardShortBluntTooltip = LayoutItem.new()
    layout.items:add(StandardShortBluntTooltip)
    StandardShortBluntTooltip:setLabel("matter how ridiculous they were.", 1, 1, 1, 1) 

    local StandardShortBluntTooltip = LayoutItem.new()
    layout.items:add(StandardShortBluntTooltip)
    StandardShortBluntTooltip:setLabel("Short blunt      Common      Craftable", 0.2, 0.8, 0.2, 1) 


    end
end

-- Adds the event listener to the event, so that it will be called when the event is triggered.
InventoryUI.onFillItemTooltip:addListener(addStandardShortBluntTooltip)




-- Create the event listener.
-- If your IDE supports LuaCATS annotations, the following line tells it the function is an event listener.
---@type Starlit.InventoryUI.Callback_OnFillItemTooltip
local function addStandardSpearTooltip(tooltip, layout, item)
    if item:getFullType() ~= "LG.Standard_Spear_LEGION" then
        return
    end



    -- Adds the key-value pair "Grown at: Sweet Apple Acres" to every apple's tooltip.
    InventoryUI.addTooltipKeyValue(layout, "Faction:", "Legion")

    -- Adds a half-full progress bar for sweetness to every apple's tooltip.
    InventoryUI.addTooltipBar(layout, "Lethality:", 0.28)

    -- Adds a bites taken counter to every apple's tooltip, with the value 1.
    InventoryUI.addTooltipBar(layout, "Endurance Drain:", 0.75)

    -- Adds a bites taken counter to every apple's tooltip, with the value 1.
    InventoryUI.addTooltipInteger(layout, "Multi-hit:", 2, true)

    -- Finds and returns the Vanilla tooltip element showing the item's encumbrance.
    local encumbrance = InventoryUI.getTooltipElementByLabel(layout, getText("Tooltip_item_Weight") .. ":")
    -- If encumbrance is nil, then it's already been removed by another mod.
    if encumbrance then

    local StandardSpearTooltip = LayoutItem.new()
    layout.items:add(StandardSpearTooltip)
    StandardSpearTooltip:setLabel("A makeshift spear made from a combination of", 1, 1, 1, 1) 

    local StandardSpearTooltip = LayoutItem.new()
    layout.items:add(StandardSpearTooltip)
    StandardSpearTooltip:setLabel("accessible tools. Many weapons like this were", 1, 1, 1, 1) 

    local StandardSpearTooltip = LayoutItem.new()
    layout.items:add(StandardSpearTooltip)
    StandardSpearTooltip:setLabel("hastily assembled in the early stages of the", 1, 1, 1, 1) 

    local StandardSpearTooltip = LayoutItem.new()
    layout.items:add(StandardSpearTooltip)
    StandardSpearTooltip:setLabel("outbreak, saving the lives of those who wielded", 1, 1, 1, 1) 

    local StandardSpearTooltip = LayoutItem.new()
    layout.items:add(StandardSpearTooltip)
    StandardSpearTooltip:setLabel("them.", 1, 1, 1, 1) 

    local StandardSpearTooltip = LayoutItem.new()
    layout.items:add(StandardSpearTooltip)
    StandardSpearTooltip:setLabel("Spear      Common      Craftable", 0.2, 0.8, 0.2, 1) 


    end
end

-- Adds the event listener to the event, so that it will be called when the event is triggered.
InventoryUI.onFillItemTooltip:addListener(addStandardSpearTooltip)






-- Create the event listener.
-- If your IDE supports LuaCATS annotations, the following line tells it the function is an event listener.
---@type Starlit.InventoryUI.Callback_OnFillItemTooltip
local function addStandardLongBluntTooltip(tooltip, layout, item)
    if item:getFullType() ~= "LG.Standard_LongBlunt_LEGION" then
        return
    end



    -- Adds the key-value pair "Grown at: Sweet Apple Acres" to every apple's tooltip.
    InventoryUI.addTooltipKeyValue(layout, "Faction:", "Legion")

    -- Adds a half-full progress bar for sweetness to every apple's tooltip.
    InventoryUI.addTooltipBar(layout, "Lethality:", 0.35)

    -- Adds a bites taken counter to every apple's tooltip, with the value 1.
    InventoryUI.addTooltipBar(layout, "Endurance Drain:", 0.65)

    -- Adds a bites taken counter to every apple's tooltip, with the value 1.
    InventoryUI.addTooltipInteger(layout, "Multi-hit:", 3, true)

    -- Finds and returns the Vanilla tooltip element showing the item's encumbrance.
    local encumbrance = InventoryUI.getTooltipElementByLabel(layout, getText("Tooltip_item_Weight") .. ":")
    -- If encumbrance is nil, then it's already been removed by another mod.
    if encumbrance then

    local StandardLongBluntTooltip = LayoutItem.new()
    layout.items:add(StandardLongBluntTooltip)
    StandardLongBluntTooltip:setLabel("A deadly Legion weapon decorated with the ashes and", 1, 1, 1, 1) 

    local StandardLongBluntTooltip = LayoutItem.new()
    layout.items:add(StandardLongBluntTooltip)
    StandardLongBluntTooltip:setLabel("nails. It originates from a survivor tribe residing deep", 1, 1, 1, 1) 

    local StandardLongBluntTooltip = LayoutItem.new()
    layout.items:add(StandardLongBluntTooltip)
    StandardLongBluntTooltip:setLabel("inside woods between West Point and Muldraugh.", 1, 1, 1, 1) 


    local StandardLongBluntTooltip = LayoutItem.new()
    layout.items:add(StandardLongBluntTooltip)
    StandardLongBluntTooltip:setLabel("Long blunt      Common      Craftable", 0.2, 0.8, 0.2, 1) 


    end
end

-- Adds the event listener to the event, so that it will be called when the event is triggered.
InventoryUI.onFillItemTooltip:addListener(addStandardLongBluntTooltip)



-- Create the event listener.
-- If your IDE supports LuaCATS annotations, the following line tells it the function is an event listener.
---@type Starlit.InventoryUI.Callback_OnFillItemTooltip
local function addLegendaryAxeTooltip(tooltip, layout, item)
    if item:getFullType() ~= "LG.Legendary_Axe_LEGION" then
        return
    end



    -- Adds the key-value pair "Grown at: Sweet Apple Acres" to every apple's tooltip.
    InventoryUI.addTooltipKeyValue(layout, "Faction:", "Legion")

    -- Adds a half-full progress bar for sweetness to every apple's tooltip.
    InventoryUI.addTooltipBar(layout, "Lethality:", 0.90)

    -- Adds a bites taken counter to every apple's tooltip, with the value 1.
    InventoryUI.addTooltipBar(layout, "Endurance Drain:", 0.55)

    -- Adds a bites taken counter to every apple's tooltip, with the value 1.
    InventoryUI.addTooltipInteger(layout, "Multi-hit:", 4, true)

    -- Finds and returns the Vanilla tooltip element showing the item's encumbrance.
    local encumbrance = InventoryUI.getTooltipElementByLabel(layout, getText("Tooltip_item_Weight") .. ":")
    -- If encumbrance is nil, then it's already been removed by another mod.
    if encumbrance then

    local LegendaryAxeTooltip = LayoutItem.new()
    layout.items:add(LegendaryAxeTooltip)
    LegendaryAxeTooltip:setLabel("A custom circular saw used by the leader of the", 1, 1, 1, 1) 

    local LegendaryAxeTooltip = LayoutItem.new()
    layout.items:add(LegendaryAxeTooltip)
    LegendaryAxeTooltip:setLabel("Coryerdon cannibals. Despite its crude design,", 1, 1, 1, 1) 

    local LegendaryAxeTooltip = LayoutItem.new()
    layout.items:add(LegendaryAxeTooltip)
    LegendaryAxeTooltip:setLabel("it is remarkably well constructed and extremely", 1, 1, 1, 1)

    local LegendaryAxeTooltip = LayoutItem.new()
    layout.items:add(LegendaryAxeTooltip)
    LegendaryAxeTooltip:setLabel("effective.", 1, 1, 1, 1)

    local LegendaryAxeTooltip = LayoutItem.new()
    layout.items:add(LegendaryAxeTooltip)
    LegendaryAxeTooltip:setLabel("Axe      Legendary      Non-craftable", 1.0, 0.6, 0.1, 1.0) 


    end
end

-- Adds the event listener to the event, so that it will be called when the event is triggered.
InventoryUI.onFillItemTooltip:addListener(addLegendaryAxeTooltip)





-- Create the event listener.
-- If your IDE supports LuaCATS annotations, the following line tells it the function is an event listener.
---@type Starlit.InventoryUI.Callback_OnFillItemTooltip
local function addStandardAxeTooltip(tooltip, layout, item)
    if item:getFullType() ~= "LG.Standard_Axe_LEGION" then
        return
    end



    -- Adds the key-value pair "Grown at: Sweet Apple Acres" to every apple's tooltip.
    InventoryUI.addTooltipKeyValue(layout, "Faction:", "Legion")

    -- Adds a half-full progress bar for sweetness to every apple's tooltip.
    InventoryUI.addTooltipBar(layout, "Lethality:", 0.32)

    -- Adds a bites taken counter to every apple's tooltip, with the value 1.
    InventoryUI.addTooltipBar(layout, "Endurance Drain:", 0.48)

    -- Adds a bites taken counter to every apple's tooltip, with the value 1.
    InventoryUI.addTooltipInteger(layout, "Multi-hit:", 2, true)

    -- Finds and returns the Vanilla tooltip element showing the item's encumbrance.
    local encumbrance = InventoryUI.getTooltipElementByLabel(layout, getText("Tooltip_item_Weight") .. ":")
    -- If encumbrance is nil, then it's already been removed by another mod.
    if encumbrance then

    local StandardAxeTooltip = LayoutItem.new()
    layout.items:add(StandardAxeTooltip)
    StandardAxeTooltip:setLabel("A distinctive axe design used by the bandits", 1, 1, 1, 1) 

    local StandardAxeTooltip = LayoutItem.new()
    layout.items:add(StandardAxeTooltip)
    StandardAxeTooltip:setLabel("from the east. Its suprisingly reliable.", 1, 1, 1, 1) 


    local StandardAxeTooltip = LayoutItem.new()
    layout.items:add(StandardAxeTooltip)
    StandardAxeTooltip:setLabel("Axe      Common      Craftable", 0.2, 0.8, 0.2, 1) 


    end
end

-- Adds the event listener to the event, so that it will be called when the event is triggered.
InventoryUI.onFillItemTooltip:addListener(addStandardAxeTooltip)




-- Create the event listener.
-- If your IDE supports LuaCATS annotations, the following line tells it the function is an event listener.
---@type Starlit.InventoryUI.Callback_OnFillItemTooltip
local function addLEGIONIngotMagTooltip(tooltip, layout, item)
    if item:getFullType() ~= "LG.LEGIONIngotMag" then
        return
    end



    -- Adds the key-value pair "Grown at: Sweet Apple Acres" to every apple's tooltip.
    InventoryUI.addTooltipKeyValue(layout, "Faction:", "Legion")



    -- Finds and returns the Vanilla tooltip element showing the item's encumbrance.
    local encumbrance = InventoryUI.getTooltipElementByLabel(layout, getText("Tooltip_item_Weight") .. ":")
    -- If encumbrance is nil, then it's already been removed by another mod.
    if encumbrance then

    local LEGIONIngotMagTooltip = LayoutItem.new()
    layout.items:add(LEGIONIngotMagTooltip)
    LEGIONIngotMagTooltip:setLabel("An old world magazine that teaches how to", 1, 1, 1, 1) 

    local LEGIONIngotMagTooltip = LayoutItem.new()
    layout.items:add(LEGIONIngotMagTooltip)
    LEGIONIngotMagTooltip:setLabel("make low-quality scrap steel. It looks like", 1, 1, 1, 1) 

    local LEGIONIngotMagTooltip = LayoutItem.new()
    layout.items:add(LEGIONIngotMagTooltip)
    LEGIONIngotMagTooltip:setLabel("some of the pages are heavily annotated for", 1, 1, 1, 1) 

    local LEGIONIngotMagTooltip = LayoutItem.new()
    layout.items:add(LEGIONIngotMagTooltip)
    LEGIONIngotMagTooltip:setLabel("more efficient results.", 1, 1, 1, 1) 

    local LEGIONIngotMagTooltip = LayoutItem.new()
    layout.items:add(LEGIONIngotMagTooltip)
    LEGIONIngotMagTooltip:setLabel("Magazine      Common      Recipe", 0.2, 0.8, 0.2, 1) 


    end
end

-- Adds the event listener to the event, so that it will be called when the event is triggered.
InventoryUI.onFillItemTooltip:addListener(addLEGIONIngotMagTooltip)






-- Create the event listener.
-- If your IDE supports LuaCATS annotations, the following line tells it the function is an event listener.
---@type Starlit.InventoryUI.Callback_OnFillItemTooltip
local function addLEGIONcommonMagTooltip(tooltip, layout, item)
    if item:getFullType() ~= "LG.LEGIONcommonMag" then
        return
    end



    -- Adds the key-value pair "Grown at: Sweet Apple Acres" to every apple's tooltip.
    InventoryUI.addTooltipKeyValue(layout, "Faction:", "Legion")



    -- Finds and returns the Vanilla tooltip element showing the item's encumbrance.
    local encumbrance = InventoryUI.getTooltipElementByLabel(layout, getText("Tooltip_item_Weight") .. ":")
    -- If encumbrance is nil, then it's already been removed by another mod.
    if encumbrance then

    local LEGIONcommonMagTooltip = LayoutItem.new()
    layout.items:add(LEGIONcommonMagTooltip)
    LEGIONcommonMagTooltip:setLabel("An old DIY magazine, heavily altered and missing", 1, 1, 1, 1) 

    local LEGIONcommonMagTooltip = LayoutItem.new()
    layout.items:add(LEGIONcommonMagTooltip)
    LEGIONcommonMagTooltip:setLabel("many of its pages. It now shows only a handful of", 1, 1, 1, 1) 

    local LEGIONcommonMagTooltip = LayoutItem.new()
    layout.items:add(LEGIONcommonMagTooltip)
    LEGIONcommonMagTooltip:setLabel("weapons deemed effective enough to survive the", 1, 1, 1, 1) 

    local LEGIONcommonMagTooltip = LayoutItem.new()
    layout.items:add(LEGIONcommonMagTooltip)
    LEGIONcommonMagTooltip:setLabel("outbreak.", 1, 1, 1, 1) 

    local LEGIONcommonMagTooltip = LayoutItem.new()
    layout.items:add(LEGIONcommonMagTooltip)
    LEGIONcommonMagTooltip:setLabel("Magazine      Common      Recipe", 0.2, 0.8, 0.2, 1) 


    end
end

-- Adds the event listener to the event, so that it will be called when the event is triggered.
InventoryUI.onFillItemTooltip:addListener(addLEGIONcommonMagTooltip)






-- Create the event listener.
-- If your IDE supports LuaCATS annotations, the following line tells it the function is an event listener.
---@type Starlit.InventoryUI.Callback_OnFillItemTooltip
local function addLEGIONadvancedMagTooltip(tooltip, layout, item)
    if item:getFullType() ~= "LG.LEGIONadvancedMag" then
        return
    end



    -- Adds the key-value pair "Grown at: Sweet Apple Acres" to every apple's tooltip.
    InventoryUI.addTooltipKeyValue(layout, "Faction:", "Legion")



    -- Finds and returns the Vanilla tooltip element showing the item's encumbrance.
    local encumbrance = InventoryUI.getTooltipElementByLabel(layout, getText("Tooltip_item_Weight") .. ":")
    -- If encumbrance is nil, then it's already been removed by another mod.
    if encumbrance then

    local LEGIONadvancedMagTooltip = LayoutItem.new()
    layout.items:add(LEGIONadvancedMagTooltip)
    LEGIONadvancedMagTooltip:setLabel("A standardized weaponry booklet of the", 1, 1, 1, 1) 

    local LEGIONadvancedMagTooltip = LayoutItem.new()
    layout.items:add(LEGIONadvancedMagTooltip)
    LEGIONadvancedMagTooltip:setLabel("Legion. It contains many weapon blueprints", 1, 1, 1, 1) 

    local LEGIONadvancedMagTooltip = LayoutItem.new()
    layout.items:add(LEGIONadvancedMagTooltip)
   LEGIONadvancedMagTooltip:setLabel(" from various allied clans.", 1, 1, 1, 1) 


    local LEGIONadvancedMagTooltip = LayoutItem.new()
    layout.items:add(LEGIONadvancedMagTooltip)
    LEGIONadvancedMagTooltip:setLabel("Magazine      Rare      Recipe", 0.2, 0.8, 0.2, 1) 


    end
end

-- Adds the event listener to the event, so that it will be called when the event is triggered.
InventoryUI.onFillItemTooltip:addListener(addLEGIONadvancedMagTooltip)




-- Create the event listener.
-- If your IDE supports LuaCATS annotations, the following line tells it the function is an event listener.
---@type Starlit.InventoryUI.Callback_OnFillItemTooltip
local function addScrap__Steel_IngotTooltip(tooltip, layout, item)
    if item:getFullType() ~= "LG.Scrap__Steel_Ingot" then
        return
    end



    -- Adds the key-value pair "Grown at: Sweet Apple Acres" to every apple's tooltip.
    InventoryUI.addTooltipKeyValue(layout, "Faction:", "Legion")



    -- Finds and returns the Vanilla tooltip element showing the item's encumbrance.
    local encumbrance = InventoryUI.getTooltipElementByLabel(layout, getText("Tooltip_item_Weight") .. ":")
    -- If encumbrance is nil, then it's already been removed by another mod.
    if encumbrance then

    local Scrap__Steel_IngotTooltip = LayoutItem.new()
    layout.items:add(Scrap__Steel_IngotTooltip)
    Scrap__Steel_IngotTooltip:setLabel("A crude scrap steel ingot. Forged from low-grade ", 1, 1, 1, 1) 

    local Scrap__Steel_IngotTooltip = LayoutItem.new()
    layout.items:add(Scrap__Steel_IngotTooltip)
    Scrap__Steel_IngotTooltip:setLabel("metals, yet surprisingly resilient... and oddly sharp.", 1, 1, 1, 1) 



    local Scrap__Steel_IngotTooltip = LayoutItem.new()
    layout.items:add(Scrap__Steel_IngotTooltip)
    Scrap__Steel_IngotTooltip:setLabel("Material      Common      Craftable", 0.2, 0.8, 0.2, 1) 


    end
end

-- Adds the event listener to the event, so that it will be called when the event is triggered.
InventoryUI.onFillItemTooltip:addListener(addScrap__Steel_IngotTooltip)