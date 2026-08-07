--------------------------------------------------------------------------------
-- Better Sorting Reborn — data: Elec (Electronics).
--
-- Applies on both builds. On B42 vanilla scatters these across Electronics,
-- Explosives, Accessory, Junk, Household and Memento (only 11/44 are already
-- "Electronics"), so the override consolidates them — including the radios,
-- TVs and walkie-talkies vanilla B42 files under "Communications". Items
-- genuinely absent from B42 scripts (the base AlarmClock/Radio) are marked
-- only = "41".
--
-- B42 folded the `Radio` and `farming` modules into `Base`: the entries below
-- that carry both spellings, gated by build, are ONE item that was renamed —
-- not an item added and an item removed.
--
-- Item list migrated from Better Sorting v2.0.4 (Item_Categories.lua,
-- ELECTRONICS section).
--
-- As with Cook, the leftovers of the vanilla "Electronics" key (hair dryer,
-- flat iron, microphone, pager, power bar) are swept in by the
-- `label-collision` rule rather than listed. Spelled out elsewhere: the
-- crafting components in CraftElec, the generators in Mech.
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.Data = BSR.Data or {}

BSR.Data.Elec = {
    items = {
        { "Base.AlarmClock", only = "41" },
        "Base.AlarmClock2",
        "Base.CDplayer",
        "Base.Camera",
        "Base.CameraDisposable",
        "Base.CameraExpensive",
        "Base.CordlessPhone",
        "Base.Earbuds",
        { "Base.HamRadio1", only = "42" },
        { "Base.HamRadio2", only = "42" },
        { "Base.HamRadioMakeShift", only = "42" },
        "Base.Headphones",
        "Base.NoiseTrap",
        "Base.NoiseTrapRemote",
        "Base.NoiseTrapSensorV1",
        "Base.NoiseTrapSensorV2",
        "Base.NoiseTrapSensorV3",
        "Base.NoiseTrapTriggered",
        { "Base.Radio", only = "41" },
        { "Base.RadioBlack", only = "42" },
        { "Base.RadioMakeShift", only = "42" },
        { "Base.RadioRed", only = "42" },
        "Base.Remote",
        "Base.RemoteCraftedV1",
        "Base.RemoteCraftedV2",
        "Base.RemoteCraftedV3",
        "Base.Speaker",
        "Base.TimerCrafted",
        { "Base.TvAntique", only = "42" },
        { "Base.TvBlack", only = "42" },
        { "Base.TvWideScreen", only = "42" },
        "Base.VideoGame",
        { "Base.WalkieTalkie1", only = "42" },
        { "Base.WalkieTalkie2", only = "42" },
        { "Base.WalkieTalkie3", only = "42" },
        { "Base.WalkieTalkie4", only = "42" },
        { "Base.WalkieTalkie5", only = "42" },
        { "Base.WalkieTalkieMakeShift", only = "42" },
        "Base.WristWatch_Left_DigitalBlack",
        "Base.WristWatch_Left_DigitalDress",
        "Base.WristWatch_Left_DigitalRed",
        "Base.WristWatch_Right_DigitalBlack",
        "Base.WristWatch_Right_DigitalDress",
        "Base.WristWatch_Right_DigitalRed",
        { "Radio.HamRadio1", only = "41" },
        { "Radio.HamRadio2", only = "41" },
        { "Radio.HamRadioMakeShift", only = "41" },
        { "Radio.RadioBlack", only = "41" },
        { "Radio.RadioMakeShift", only = "41" },
        { "Radio.RadioRed", only = "41" },
        { "Radio.TvAntique", only = "41" },
        { "Radio.TvBlack", only = "41" },
        { "Radio.TvWideScreen", only = "41" },
        { "Radio.WalkieTalkie1", only = "41" },
        { "Radio.WalkieTalkie2", only = "41" },
        { "Radio.WalkieTalkie3", only = "41" },
        { "Radio.WalkieTalkie4", only = "41" },
        { "Radio.WalkieTalkie5", only = "41" },
        { "Radio.WalkieTalkieMakeShift", only = "41" },
    },
}
