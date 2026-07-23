require "ISUI/ISButton"
require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISTimedActionQueue"
require "client/ui/shared/slots/NMPortableMediaInteraction"

_G.NMMediaSlot = _G.NMMediaSlot or {}
_G.NMMediaSlotEnv = _G.NMMediaSlotEnv or {}
local env = _G.NMMediaSlotEnv
if getmetatable(env) == nil then
    setmetatable(env, { __index = _G })
end

env.NMMediaSlot = _G.NMMediaSlot
env.playSlotUISound = env.playSlotUISound or function(...)
    return NMSlotActionCommon and NMSlotActionCommon.playSlotUISound and NMSlotActionCommon.playSlotUISound(...)
end
env.safeDraggedPayload = env.safeDraggedPayload or function(...)
    if NMSlotActionCommon and NMSlotActionCommon.safeDraggedPayload then
        return NMSlotActionCommon.safeDraggedPayload(...)
    end
    return nil, false
end
env.getDraggedInventoryItems = env.getDraggedInventoryItems or function(...)
    if NMSlotActionCommon and NMSlotActionCommon.getDraggedInventoryItems then
        return NMSlotActionCommon.getDraggedInventoryItems(...)
    end
    return nil, false
end
env.clearMouseDragState = env.clearMouseDragState or function(...)
    if NMSlotActionCommon and NMSlotActionCommon.clearMouseDragState then
        return NMSlotActionCommon.clearMouseDragState(...)
    end
end
env.nextSlotTraceId = env.nextSlotTraceId or function(...)
    if NMSlotActionCommon and NMSlotActionCommon.nextSlotTraceId then
        return NMSlotActionCommon.nextSlotTraceId(...)
    end
    return "0"
end
env.canQueueSlotAction = env.canQueueSlotAction or function(...)
    if NMSlotActionCommon and NMSlotActionCommon.canQueueSlotAction then
        return NMSlotActionCommon.canQueueSlotAction(...)
    end
    return false
end
env.handlePortableMediaSlotMouseDown = env.handlePortableMediaSlotMouseDown or function(...)
    if NMPortableMediaInteraction and NMPortableMediaInteraction.handleMediaSlotMouseDown then
        return NMPortableMediaInteraction.handleMediaSlotMouseDown(...)
    end
    return true
end
env.handlePortableMediaSlotMouseUp = env.handlePortableMediaSlotMouseUp or function(...)
    if NMPortableMediaInteraction and NMPortableMediaInteraction.handleMediaSlotMouseUp then
        return NMPortableMediaInteraction.handleMediaSlotMouseUp(...)
    end
    return true
end
env.handlePortableMediaSlotRightClick = env.handlePortableMediaSlotRightClick or function(...)
    if NMPortableMediaInteraction and NMPortableMediaInteraction.handleMediaSlotRightClick then
        return NMPortableMediaInteraction.handleMediaSlotRightClick(...)
    end
    return true
end
env.finalizePortableMediaExtract = env.finalizePortableMediaExtract or function(...)
    if NMPortableMediaInteraction and NMPortableMediaInteraction.finalizePendingExtract then
        return NMPortableMediaInteraction.finalizePendingExtract(...)
    end
    return false
end

env.DRAG_THRESHOLD = env.DRAG_THRESHOLD or 4
env.MEDIA_TEXTURE_CACHE = env.MEDIA_TEXTURE_CACHE or {}
env.SLOT_PROGRESS_FILL = env.SLOT_PROGRESS_FILL or { a = 0.60, r = 0.26, g = 0.78, b = 0.22 }
env.EMPTY_MEDIA_ICON_SCALE = env.EMPTY_MEDIA_ICON_SCALE or 0.82
env.EMPTY_MEDIA_ICON_SCALE_CD = env.EMPTY_MEDIA_ICON_SCALE_CD or 0.77
env.EMPTY_MEDIA_ICON_SCALE_CASSETTE = env.EMPTY_MEDIA_ICON_SCALE_CASSETTE or 0.74
env.EMPTY_MEDIA_TEXTURE_SCALE_CASSETTE = env.EMPTY_MEDIA_TEXTURE_SCALE_CASSETTE or 0.90
env.EMPTY_SLOT_VECTOR_COLOR = env.EMPTY_SLOT_VECTOR_COLOR or { r = 0.11, g = 0.11, b = 0.11, a = 1.00 }
env.EMPTY_MEDIA_VECTOR_CACHE = env.EMPTY_MEDIA_VECTOR_CACHE or {}
env.EMPTY_MEDIA_PLACEHOLDER_TEXTURES = env.EMPTY_MEDIA_PLACEHOLDER_TEXTURES or {}
env.CARRIER_KEYS = env.CARRIER_KEYS or ((NMMediaContract and NMMediaContract.getLegacyCarriers and NMMediaContract.getLegacyCarriers()) or {
    cassette = "tsarcraft_music_01_62",
    vinyl = "tsarcraft_music_01_63",
    cd = "tsarcraft_music_01_64"
})

return env
