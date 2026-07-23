if isServer() and not isClient() then return end

if not ISAdminPanelUI then
    print("[DCS] ISAdminPanelUI not found, skipping admin panel hook")
    return
end

local _originalCreate = ISAdminPanelUI.create
local _originalOnOptionMouseDown = ISAdminPanelUI.onOptionMouseDown

local ADMIN_OPTION_FIELDS = {
    "checkStatsBtn", "adminPowerBtn", "itemListBtn", "seeOptionsBtn", "nonpvpzoneBtn",
    "seeFactionBtn", "seeRolesBtn", "seeUsersBtn", "seeSafehousesBtn", "safezoneBtn",
    "seeTicketsBtn", "miniScoreboardBtn", "sandboxOptionsBtn", "climateOptionsBtn",
    "showStatisticsBtn", "pvpLogTool", "zoneEditor",
}

local function placeAdminButton(self, btn)
    local midX = self:getWidth() / 2
    local rightX, bw, bh, bottomY
    for _, fld in ipairs(ADMIN_OPTION_FIELDS) do
        local b = self[fld]
        if b and b.getX then
            local bx, by = b:getX(), b:getY()
            if bx > midX and not rightX then rightX = bx end
            if not bw then bw, bh = b:getWidth(), b:getHeight() end
            if not bottomY or by > bottomY then bottomY = by end
        end
    end
    if not (rightX and bw and bh and bottomY) then
        DCS_dprint("[DCS] adminBtn: could not locate vanilla option buttons (field names changed?)")
        return
    end
    btn:setX(rightX)
    btn:setY(bottomY)
    btn:setWidth(bw)
    btn:setHeight(bh)
end

function ISAdminPanelUI:create()
    _originalCreate(self)

    self.dcsAdminBtn = ISButton:new(
        0, 0, 100, 20,
        getText("IGUI_DCS_AdminPanelHook_Button"),
        self,
        ISAdminPanelUI.onOptionMouseDown
    )
    self.dcsAdminBtn.internal = "DCS_ADMIN"
    self.dcsAdminBtn:initialise()
    self.dcsAdminBtn:instantiate()
    self.dcsAdminBtn.borderColor = self.buttonBorderColor
    self:addChild(self.dcsAdminBtn)

    placeAdminButton(self, self.dcsAdminBtn)
end

function ISAdminPanelUI:onOptionMouseDown(button, x, y)
    if button.internal == "DCS_ADMIN" then
        if DCS_UI_Debug and DCS_UI_Debug.open then
            if DCS_UI_Debug.markAdminVerified then DCS_UI_Debug.markAdminVerified() end
            DCS_UI_Debug.open()
        else
            print("[DCS] DCS_UI_Debug not loaded yet")
        end
        return
    end
    _originalOnOptionMouseDown(self, button, x, y)
end

DCS_dprint("[DCS] Admin panel hook installed")
