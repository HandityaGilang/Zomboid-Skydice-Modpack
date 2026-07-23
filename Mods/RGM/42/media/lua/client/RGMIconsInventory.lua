-- Integration with Icons Inventory mod (3718412967):
-- draws a colored "*" in the top-left corner of item cells that have an RGM modifier.
--
-- Must patch Cell (not CellRender) because Cell.lua copies CellRender methods into
-- itself at load time, so patching CellRender after the fact has no effect on Cell instances.
if not getActivatedMods():contains("IconsInventory") then return end

local Cell = require("IconsInventory/Cell")

local orig_renderDetails = Cell.renderDetails

function Cell:renderDetails()
    orig_renderDetails(self)

    local ok, modifier = pcall(function() return self.item:getModData().modifier end)
    if not ok or not modifier or not modifier.fontColor then return end

    local color = modifier.fontColor
    local halfPadding = self.padding / 2
    self.pane:drawText("*", self.x + halfPadding, self.y + halfPadding,
        color[1], color[2], color[3], 1, UIFont.Small)
end

local orig_renderStack = Cell.renderStack

function Cell:renderStack()
    orig_renderStack(self)

    local ok, modifier = pcall(function() return self.item:getModData().modifier end)
    if not ok or not modifier or not modifier.fontColor then return end

    local color = modifier.fontColor
    local halfPadding = self.padding / 2
    self.pane:drawText("*", self.x + halfPadding, self.y + halfPadding,
        color[1], color[2], color[3], 1, UIFont.Small)
end
