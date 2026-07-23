require 'Definitions/HairOutfitDefinitions'
require 'NPCs/seifuku_ZombiesZoneDefinition'
require 'seifuku_defines'

Events.OnInitGlobalModData.Add(function()
    local tbl_outfit_names = seifuku.outfit.list
    for _, str_outfit_name in pairs(tbl_outfit_names) do
        local cat = {};
        cat.outfit = str_outfit_name;
        cat.haircutColor = "0.20,0.19,0.19:30;0.22,0.16,0.11:20;0.34,0.21,0.13:10;0.34,0.26,0.18:10;0.43,0.34,0.24:5;0.57,0.47,0.35:5;0.60,0.44,0.30:5;0.61,0.51,0.34:5;0.66,0.52,0.32:5;0.83,0.67,0.27:5";
        cat.beard = "None:100";
        table.insert(HairOutfitDefinitions.haircutOutfitDefinition, cat);
    end
end)

-- Just storing these for later...

-- STANDARD
-- maleHairStyles="CentreParting:5;PonyTail:5;Donny:20;GreasedBack:15;LeftParting:15;RightParting:15;CentrePartingLong:5;Short:20",
-- femaleHairStyles="Bob:5;Grungey:5;GrungeyBehindEars:5;Grungey02:10;GrungeyParted:5;Long:20;Long2:15;OverEye:5;OverLeftEye:5;PonyTail:5;Rachel:15;CentrePartingLong:5",

-- ATHLETIC
-- femaleHairStyles="Bun:30;Ponytail:20;OverEye:20;OverLeftEye:15;GrungeyParted:10",