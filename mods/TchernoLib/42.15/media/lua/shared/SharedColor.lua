
Sh = Sh or {}
Sh.Colors = {}
Sh.Colors.Black      = {r=0,g=0,b=0}
Sh.Colors.White      = {r=255,g=255,b=255}
Sh.Colors.Red        = {r=255,g=0,b=0}
Sh.Colors.Lime       = {r=0,g=255,b=0}
Sh.Colors.Blue       = {r=0,g=0,b=255}
Sh.Colors.Yellow     = {r=255,g=255,b=0}
Sh.Colors.Cyan       = {r=0,g=255,b=255}
Sh.Colors.Magenta    = {r=255,g=0,b=255}
Sh.Colors.Silver     = {r=192,g=192,b=192}
Sh.Colors.Gray       = {r=128,g=128,b=128}
Sh.Colors.Maroon     = {r=128,g=0,b=0}
Sh.Colors.Olive      = {r=128,g=128,b=0}
Sh.Colors.Green      = {r=0,g=128,b=0}
Sh.Colors.Purple     = {r=128,g=0,b=128}
Sh.Colors.Teal       = {r=0,g=128,b=128}
Sh.Colors.Navy       = {r=0,g=0,b=128}
Sh.Colors.OrangeRed  = {r=255,g=69,b=0}
Sh.Colors.DarkOrange = {r=255,g=140,b=0}
Sh.Colors.Orange     = {r=255,g=165,b=0}
Sh.Colors.Gold       = {r=255,g=215,b=0}
Sh.Colors.Azure      = {r=0,g=128,b=255}
Sh.NbColors = 22
--https://www.rapidtables.com/web/color/RGB_Color.html
--basic colors + oranges


function Sh.getColorFromEnum(enum)
    if enum ==  1 then return nil end
    if enum ==  2 then return Sh.Colors.Black      end
    if enum ==  3 then return Sh.Colors.White      end
    if enum ==  4 then return Sh.Colors.Red        end
    if enum ==  5 then return Sh.Colors.Lime       end
    if enum ==  6 then return Sh.Colors.Blue       end
    if enum ==  7 then return Sh.Colors.Yellow     end
    if enum ==  8 then return Sh.Colors.Cyan       end
    if enum ==  9 then return Sh.Colors.Magenta    end
    if enum == 10 then return Sh.Colors.Silver     end
    if enum == 11 then return Sh.Colors.Gray       end
    if enum == 12 then return Sh.Colors.Maroon     end
    if enum == 13 then return Sh.Colors.Olive      end
    if enum == 14 then return Sh.Colors.Green      end
    if enum == 15 then return Sh.Colors.Purple     end
    if enum == 16 then return Sh.Colors.Teal       end
    if enum == 17 then return Sh.Colors.Navy       end
    if enum == 18 then return Sh.Colors.OrangeRed  end
    if enum == 19 then return Sh.Colors.DarkOrange end
    if enum == 20 then return Sh.Colors.Orange     end
    if enum == 21 then return Sh.Colors.Gold       end
    if enum == 22 then return Sh.Colors.Azure      end
    return nil
end

--use exemples: see Battle Royale mod for full use on multiple variables
--function BattleRoyale.getCircleDisplayedOnMapRed()
--    local color = Sh.getColorFromEnum(SandboxVars.BattleRoyale.CircleDisplayedOnMap)
--    return color and color.r or nil
--end

--in sandbox-options.txt for your color variable:
--set type = enum, numValues = 22 and valueTranslation = ColorEnum
--option BattleRoyale.CircleDisplayedOnMap
--{
--    type = enum,
--    numValues = 22,
--    default = 2,
--    page = BattleRoyale,
--    translation = BattleRoyale_CircleDisplayedOnMap,
--    valueTranslation = ColorEnum,
--}
