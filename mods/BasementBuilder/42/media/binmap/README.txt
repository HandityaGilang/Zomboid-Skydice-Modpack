BasementBuilder binary basement templates

base.pzby
- exported from media/tbx/base.tbx
- intended starter room template
- footprint: 2x6
- stair anchor: 0,0 facing north

room.pzby
- exported from media/tbx/room.tbx
- intended 1x1 expansion module template

Current mod runtime still uses the Lua generation pipeline for stability.
These files are kept here so the next integration step can migrate the mod
to real binary basement spawning when a usable runtime hook is available.
