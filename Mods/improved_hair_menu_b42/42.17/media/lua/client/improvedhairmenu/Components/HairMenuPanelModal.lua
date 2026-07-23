--[[
	A menu with an additional close button and event for the popout dialog in the character creation screen
]]
if isServer() then return end
require "ISUI/ISButton"

-- Load order can differ across platforms; ensure HairMenuPanel exists before deriving.
if not rawget(_G, "HairMenuPanel") then
    pcall(require, "improvedhairmenu/HairMenuPanel")
end

local base = rawget(_G, "HairMenuPanel")
if not base then
    print("[IHM] HairMenuPanelModal: HairMenuPanel not available (load order). Modal disabled.")
    return
end

HairMenuPanelModal = base:derive("HairMenuPanelModal")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

function HairMenuPanelModal:close()
	if self.onClose then self.onClose() end
end

function HairMenuPanelModal:initialise()
    base.initialise(self)
    ImprovedHairMenu = ImprovedHairMenu or {}
    ImprovedHairMenu._activeCCModal = self

    self.backgroundColor = { r = 0, g = 0, b = 0, a = 1 }

    local smallH = getTextManager():getFontHeight(UIFont.Small)
    local pad = math.max(6, math.floor(smallH * 0.4))
    local btnH = math.max(smallH * 2, smallH + 8)

    self.closeButton = ISButton:new(0, self.offset_y + pad, self:getWidth(), btnH, getText("UI_Close"), self, HairMenuPanelModal.close)
    self.closeButton:initialise()
    self.closeButton:instantiate()
    self:addChild(self.closeButton)

    self:setHeight(self:getHeight() + pad + btnH)
end

function HairMenuPanelModal:close()
    if ImprovedHairMenu and ImprovedHairMenu._activeCCModal == self then
        ImprovedHairMenu._activeCCModal = nil
    end
    if self.onClose then self.onClose() end
end

function HairMenuPanelModal:onMouseUp(x,y)
	base.onMouseUp(self,x,y)
	if not (0 < x and 0 < y and x < self:getWidth() and y < self:getHeight()) then self:close() end
end