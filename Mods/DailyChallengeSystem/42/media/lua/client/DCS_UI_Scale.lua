if isServer() and not isClient() then return end

DCS_UI_Scale = {}

local tmgr = getTextManager()
local FONT_SM = UIFont.Small
local FONT_MD = UIFont.Medium
local fontHgt = tmgr:getFontHeight(FONT_SM)
local fontHgtMd = tmgr:getFontHeight(FONT_MD)

local BASE_SM = 19
local SCALE = fontHgt / BASE_SM

DCS_UI_Scale.FONT_SM = FONT_SM
DCS_UI_Scale.FONT_MD = FONT_MD
DCS_UI_Scale.fontHgt = fontHgt
DCS_UI_Scale.fontHgtMd = fontHgtMd
DCS_UI_Scale.SCALE = SCALE

function DCS_UI_Scale.s(px)
    return math.floor(px * SCALE + 0.5)
end

DCS_dprint(string.format("[DCS] UI scale: fontHgt=%d fontHgtMd=%d SCALE=%.3f",
    fontHgt, fontHgtMd, SCALE))
