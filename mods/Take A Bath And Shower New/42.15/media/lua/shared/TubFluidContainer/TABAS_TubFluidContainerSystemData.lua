TFCSystem_GlobalData = {}

--[[
TFC Global ModData ("tubFluidContainerSystem")

Key format:
  id = TFC_Utils.getIdByCoords(x, y, z)  -- e.g. "1234-5678-0"
  All tables below use id as the primary key (string).

1) md.Registered (Persistent Snapshot)
  Purpose:
    - Persistent, server-authoritative snapshot for UI/client access.
    - Used to reverse-lookup "is there a TFC at this square?" from coordinates (id).
    - Must remain valid even when the actual TFC IsoObject is not loaded.

  Ownership / Updates:
    - Written/updated by server (register/unregister, SyncManager snapshots, periodic decay like EveryHours).
    - Replicated to clients via ModData.transmit/request.

  Contents:
    - Summary state only (e.g. amount/capacity/temperature/dirtyLevel/lastUpdate/bathSalt/rainCatcher...).
    - Link metadata allowed (e.g. linkedX/linkedY absolute coords OR linked marker {isLinked/mainId}).
    - Must NOT contain runtime tick counters (_soundTick/_phaseTick), object references (bath/tfc),
      or temporary control flags used only during active operations.
      
  Link metadata:
    - Linked marker entry (Registered[lid]) should contain only {isLinked=true, mainId="<main id>"}.
    - Main entry may contain linkedX/linkedY for absolute coords if needed for debugging/UI.
      
  Lifetime:
    - Exists as long as the TFC is considered registered (may outlive loaded chunks).
    - Removed when TFC is removed/unregistered, or via cleanup routines if needed.

    *) pendedRemove (Flags Of Deferred Removal Queue) 
    - It is flagged if the TFC could not be safely deleted.
    - TFC data and objects with this flag will be deleted when square loading.

2) md.Activated (Runtime Operation State)
  Purpose:
    - Runtime-only state machine entries for active server-side operations (fill/empty/reheat).
    - This table represents "what is currently running right now".

  Ownership / Updates:
    - Written/updated by server tick (tubWaterServerTick) and related server commands.
    - Entries are short-lived and self-cleaning.

  Contents:
    - Control/state fields (state, activate, phase, _lastState) and runtime counters (_soundTick/_phaseTick).
    - Cached refs may be stored transiently (bath/tfc) but MUST NOT be relied on across ticks without validation.

  Lifetime / Cleanup:
    - If activate becomes false OR bath/tfc cannot be confirmed, the entry is removed (Activated[id]=nil) immediately.
    - Activated does not need to be perfectly persistent; 1-tick delay cleanup is acceptable.

Notes:
  - Registered and Activated are intentionally independent:
      * Registered answers "exists / snapshot".
      * Activated answers "currently running operation".
  - Any code that adds new fields should follow the above rules to prevent data bloat and sync bugs.
]]--

local TFC = "tubFluidContainerSystem"

local function onInitGlobalModData(isNewGame)
    local md = ModData.getOrCreate(TFC)
    if isClient() then
        ModData.request(TFC)
    end
    md.Registered = md.Registered or {}
    md.Activated = md.Activated or {}
    TFCSystem_GlobalData = md
end
Events.OnInitGlobalModData.Add(onInitGlobalModData)

local function wipe(t)
    for k in pairs(t) do t[k] = nil end
end

local function copyInto(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            dst[k] = dst[k] or {}
            wipe(dst[k])
            copyInto(dst[k], v)
        else
            dst[k] = v
        end
    end
end

local function onReceiveGlobalModData(key, data)
    if not (isClient() and key == TFC and type(data) == "table") then return end

    data.Registered = data.Registered or {}
    data.Activated = data.Activated or {}

    local md = ModData.getOrCreate(TFC)
    wipe(md)
    copyInto(md, data)

    TFCSystem_GlobalData = md
end
Events.OnReceiveGlobalModData.Add(onReceiveGlobalModData)


function UpdateTFCSystemData()
    if isClient() then
        ModData.request("tubFluidContainerSystem")
    end
end

function TransmitTFCSystemData(_reason)
    ModData.transmit("tubFluidContainerSystem")
end

function GetTFCSystemData()
    return TFCSystem_GlobalData
end

function ClearTFCSystemData()
    ModData.remove("tubFluidContainerSystem")
end

Events.OnGameStart.Add(UpdateTFCSystemData)
Events.OnCreatePlayer.Add(UpdateTFCSystemData)
