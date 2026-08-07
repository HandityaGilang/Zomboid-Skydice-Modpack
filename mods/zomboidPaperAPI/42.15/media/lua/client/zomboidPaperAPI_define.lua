local dndPaper = {}

require 'ISUI/Maps/ISMapDefinitions'

dndPaper.types = {}


function dndPaper.isValid(itemType) return (dndPaper.types[itemType] ~= nil) end


function dndPaper.applyPaperInit(itemType, maxPage)
    maxPage = maxPage or 1

    local buffer = 10
    local texPath = "media/textures/zomboidPaper/"..itemType.."1.png"
    local texture = getTexture(texPath)

    if not texture then print("ZOMBOID PAPER API: NO TEXTURE FOUND FOR "..itemType.."("..texPath..")") return end

    local x2, y2 = texture:getWidth()+buffer, texture:getHeight()+buffer

    LootMaps.Init["paperAPI_"..itemType] = function(mapUI)
        local mapAPI = mapUI.javaObject:getAPIv1()
        MapUtils.initDirectoryMapData(mapUI, 'media/maps/Muldraugh, KY')
        mapAPI:setBoundsInSquares(buffer, buffer, x2, y2)
        MapUtils.initDefaultTextLayersV3(mapUI)
    end
    dndPaper.types[itemType] = { maxPage = maxPage }
end


return dndPaper
