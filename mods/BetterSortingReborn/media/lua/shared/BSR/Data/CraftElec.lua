--------------------------------------------------------------------------------
-- Better Sorting Reborn — data: CraftElec (Crafting - Electronics).
--
-- Applies on both builds. A more specific electronics-crafting bucket than
-- vanilla's generic "Electronics"/"Material".
--
-- The four Radio.* crafting components were not removed in B42: the whole
-- `Radio` module was folded into `Base`. Both spellings are listed, gated by
-- build, so the item is covered on either side.
--
-- Item list migrated from Better Sorting v2.0.4 (Item_Categories.lua,
-- CRAFTING section — Electronics).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.Data = BSR.Data or {}

BSR.Data.CraftElec = {
    items = {
        "Base.Aluminum",
        "Base.Amplifier",
        "Base.Battery",
        "Base.BatteryBox",
        "Base.Coldpack",
        { "Base.ElectricWire", only = "42" },
        "Base.ElectronicsScrap",
        "Base.HomeAlarm",
        "Base.LightBulb",
        "Base.LightBulbBlue",
        "Base.LightBulbBox",
        "Base.LightBulbCyan",
        "Base.LightBulbGreen",
        "Base.LightBulbMagenta",
        "Base.LightBulbOrange",
        "Base.LightBulbPink",
        "Base.LightBulbPurple",
        "Base.LightBulbRed",
        "Base.LightBulbYellow",
        "Base.MotionSensor",
        { "Base.RadioReceiver", only = "42" },
        { "Base.RadioTransmitter", only = "42" },
        "Base.Receiver",
        { "Base.ScannerModule", only = "42" },
        "Base.Timer",
        "Base.TriggerCrafted",
        { "Radio.ElectricWire", only = "41" },
        { "Radio.RadioReceiver", only = "41" },
        { "Radio.RadioTransmitter", only = "41" },
        { "Radio.ScannerModule", only = "41" },
    },
}
