local M = {}

M.HOVER_ALPHA = 0.8

M.WIRE_ROLE_COLORS = {
    battery   = { "red" },
    ignition  = { "white", "pink", "orange" },
    starter   = { "yellow", "brown", "orange" },
    accessory = { "green", "blue", "purple" },
}

M.WIRE_TINTS = {
    red = { 1.0, 0.1, 0.1 },
    gray = { 0.6, 0.6, 0.6 },
    white = { 1.0, 1.0, 1.0 },
    pink = { 1.0, 0.5, 0.7 },
    yellow = { 1.0, 1.0, 0.2 },
    brown = { 0.6, 0.4, 0.2 },
    green = { 0.2, 1.0, 0.2 },
    blue = { 0.2, 0.4, 1.0 },
    orange = { 1.0, 0.6, 0.2 },
    purple = { 0.6, 0.3, 0.9 },
}

M.UI = {
    PAD = 40,
    HEADER_H = 20,
    FOOTER_H = 0,
    TITLE_Y = 16,
    CLOSE_BTN_OFFSET_Y = 20,
    CLOSE_BTN_W = 120,
    CLOSE_BTN_H = 28,
    PANEL_W = 901,
    PANEL_H = 599,
    SCALE_MIN = 0.1,
    SCALE_MAX = 1.0,
    SCREW_W = 30,
    SCREW_H = 30,
    SCREW_POS_X1 = 275,
    SCREW_POS_X2 = 596,
    SCREW_POS_Y = 250,
    MAX_W_RATIO = 0.25,
    MAX_W = 900,
    MIN_W = 500,
    DEFAULT_WIRE_SLOT_W = 254,
    DEFAULT_WIRE_SLOT_H = 393,
    DRAG_FALLBACK_ALPHA = 0.2,
    DRAG_FALLBACK_BORDER_ALPHA = 0.8,
}

M.WIRES = {
    STACK_START_X = 40,
    STACK_START_Y = 68,
    STACK_STEP_X = 25,
    STACK_STEP_Y = 0,
    PIVOT_X = 20,
    PIVOT_Y = 80,
    ROTATE_EASE_MS = 500,
    DRAG_ANCHORS = {
        [1] = { x = 41, y = 163 },
        [2] = { x = 70, y = 175 },
        [3] = { x = 42, y = 189 },
        [4] = { x = 49, y = 202 },
    },
    DRAG_ANCHOR_MERGED2 = { x = 48, y = 173 },
    DRAG_ANCHOR_MERGED3 = { x = 42, y = 173 },
}

M.ANGLES = {
    BASE = {
        [1] = -4,
        [2] = -12,
        [3] = -5,
        [4] = -6,
    },
    MERGED2 = -4,
    MERGED3 = -4,
    LIMIT = 40,
}

M.SPARK = {
    KICK_MIN = 20,
    KICK_MAX = 40,
}

function M.getTextTable()
    if M.TEXT then
        return M.TEXT
    end

    M.TEXT = {
        TITLE = getText("IGUI_IH_Title"),
        CLOSE = getText("IGUI_IH_Close"),
        CUT = getText("IGUI_IH_Cut"),
        UNTAPE = getText("IGUI_IH_Untape"),
        CONNECT = getText("IGUI_IH_Connect"),
        UNSCREW = getText("IGUI_IH_Unscrew"),
        DRAG = getText("IGUI_IH_Drag"),
        NEED_SCREWDRIVER = getText("IGUI_IH_Need_Screwdriver"),
        NEED_PLIERS = getText("IGUI_IH_Need_Pliers"),
        TAPE = getText("IGUI_IH_Tape"),
        NEED_DUCT_TAPE = getText("IGUI_IH_Need_DuctTape"),
        DISCONNECT = getText("IGUI_IH_Disconnect"),
        LABEL_SEP_MIDDLE = getText("IGUI_IH_Label_Sep_Middle"),
        LABEL_SEP_LAST = getText("IGUI_IH_Label_Sep_Last"),
        LABEL_POSSIBLY_PREFIX = getText("IGUI_IH_Label_Possibly_Prefix"),
        FORMAT_ACTION_BATTERY_WIRE = getText("IGUI_IH_Format_Action_Battery_Wire"),
        FORMAT_ACTION_WIRE_POSSIBLY = getText("IGUI_IH_Format_Action_Wire_Possibly"),
        FORMAT_ACTION_WIRE_LABELED = getText("IGUI_IH_Format_Action_Wire_Labeled"),
        ROLE_LABELS = {
            battery = getText("IGUI_IH_Role_Battery"),
            ignition = getText("IGUI_IH_Role_Ignition"),
            starter = getText("IGUI_IH_Role_Starter"),
            accessory = getText("IGUI_IH_Role_Accessory"),
        },
    }

    return M.TEXT
end

return M
