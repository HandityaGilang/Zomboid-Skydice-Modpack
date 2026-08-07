--------------------------------------------------------------------------------
-- Better Sorting Reborn — data: WepBomb (Weapon - Bomb).
--
-- Applies on both builds: B42 vanilla lumps these under the broad "Explosives"
-- category; WepBomb ("Weapon - Bomb") keeps thrown/placed explosive weapons
-- grouped with the other Weapon - * categories. Every item still exists in
-- B42 42.19, so none are build-gated.
--
-- Item list migrated from Better Sorting v2.0.4 (Item_Categories.lua,
-- WEAPONS section — Bomb).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.Data = BSR.Data or {}

BSR.Data.WepBomb = {
    items = {
        "Base.Aerosolbomb",
        "Base.AerosolbombRemote",
        "Base.AerosolbombSensorV1",
        "Base.AerosolbombSensorV2",
        "Base.AerosolbombSensorV3",
        "Base.AerosolbombTriggered",
        "Base.FlameTrap",
        "Base.FlameTrapRemote",
        "Base.FlameTrapSensorV1",
        "Base.FlameTrapSensorV2",
        "Base.FlameTrapSensorV3",
        "Base.FlameTrapTriggered",
        "Base.Molotov",
        "Base.PipeBomb",
        "Base.PipeBombRemote",
        "Base.PipeBombSensorV1",
        "Base.PipeBombSensorV2",
        "Base.PipeBombSensorV3",
        "Base.PipeBombTriggered",
        "Base.SmokeBomb",
        "Base.SmokeBombRemote",
        "Base.SmokeBombSensorV1",
        "Base.SmokeBombSensorV2",
        "Base.SmokeBombSensorV3",
        "Base.SmokeBombTriggered",
    },
}
