local M = {}

M.ALARM = {
    RISK_MAX = 100,
    ADD_SPARK = 20,
    ADD_FAIL_START = 5,
    ADD_SCREW = 2,
    ADD_CUT = 10,
}

M.SPARK = {
    BATTERY_DRAIN = 5,
    PANIC_DELTA = 25,
    DISCOMFORT_DELTA = 35,
    HAND_DAMAGE_MIN = 12,
    HAND_DAMAGE_MAX = 20,
}

M.ROLES = {
    LABEL_ORDER = { "battery", "ignition", "starter", "accessory" },
    BASE = { "battery", "ignition", "starter" },
    EXTRA = { "accessory" },
}

return M
