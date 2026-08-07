
--the spritesheet is named the same as the item names with a _X at the end X being the grid number.
--the grid number is 0-7 while the tiles they are placed on are 26-31
--so subtracting 26 from the object texture grid number will give the sprite grid number that needs to be attached to itemTexture
--the format should be itemTexture .. "_" .. gridNumber

--texture names dont work as planned, instead a lookup is made in spritelist. the top one is all of the sprite names i have
--and the bottom is the game item names and my sprites that match them
local doDebug = false
function CL_TD()
doDebug = not doDebug
end
function CLDebug(string) -- only prints to console if in debug
    if not isDebugEnabled() then return end
    if not doDebug then return end
    print("#-------> CL_Debug: " .. string)
end


--tables for sorting out parts of item names
local textFilterReplace = {
DECAL_TINT = true,
TEXTURE_TINT = true,
TEXTURE_HUE = true,
DOWN_WhiteTINT = true,
UP_WhiteTINT = true,
_TINT = true,
TINT = true,
}
local textFilterColorOnly = {
    Dress_Long = true,
    Dress_long_Straps = true,
    Dress_Knees = true,
}
local textFilterReplaceOnly = {
_TEXTURE = true,
TEXTURE = true,
}
local textureGroups = {
{"Bra","White"},
{"Boxers","White"},
{"Underpants","White"},
}


--needed to have colors not switch around
local function CL_addSprite(sprite)
    local newSprite = getSpriteManager(sprite):AddSprite(sprite)
    newSprite:setName(sprite)
    return newSprite
end

--decide if i want colorinfo from the item and also cut up some item names to make proper spritenames
local function CL_getColorInfo(itemTex,item)
    CLDebug("CL_getColorInfo Run")
    local colorInfo = nil
    colorInfo= ColorInfo.new()
    colorInfo:set(item:getColorInfo())
        for tex in pairs(textFilterReplace)do
            if string.find(itemTex,tex) then 
                
                colorInfo= ColorInfo.new()
                colorInfo:set(item:getColorInfo())
                itemTex = string.gsub(itemTex,tex,"")
              --  if string.find(itemTex,"Hoodie")then itemTex="Hoodie_White"end
                return {itemTex,colorInfo}
            end
        end
        return {itemTex,colorInfo}
    --[[
        for tex in pairs(textFilterColorOnly)do
            if string.find(itemTex,tex) then 
                colorInfo= ColorInfo.new()
                colorInfo:set(item:getColorInfo())
                return {itemTex,colorInfo}
            end
        end
        for tex in pairs(textFilterReplaceOnly)do
            if string.find(itemTex,tex) then 
                itemTex = string.gsub(itemTex,tex,"")
                return {itemTex,colorInfo}
            end
        end
        
        for _,table in pairs(textureGroups)do
            local count = 0
            for _, tex in pairs(table)do
                if string.find(itemTex,tex) then
                    count = count + 1
                    if count == #table then
                        colorInfo= ColorInfo.new()
                        colorInfo:set(item:getColorInfo())
                        return {itemTex,colorInfo}
                    end
                end
            end
        end
        
        if string.find(itemTex,"Shirt_Lumberjack") or string.find(itemTex,"Shirt_Workman")then
            local color = string.match(item:getTexture():getName(),"jack(.*)")
            itemTex = "Shirt_Lumberjack" .. color
            return{itemTex,colorInfo}
        end
        if string.find(itemTex,"Jacket_Leather_Punk")then
            local number = string.sub(item:getTexture():getName(),-1)
            itemTex = "Jacket_Leather_Punk_" .. number
            return{itemTex,colorInfo}
        end
        if string.find(itemTex,"Trousers_Denim_Punk")then
            local number = string.sub(item:getTexture():getName(),-1)
            itemTex = "Trousers_DenimBlack_Patches" .. number
            return{itemTex,colorInfo}
        end
        if string.find(itemTex,"Hoodie_Hunting")then itemTex = "Hoodie_CamoTree" return {itemTex,colorInfo}end
        if string.find(itemTex,"Tshirt_SuperColor")then
            local number = string.sub(item:getTexture():getName(),-1)
            itemTex = "Tshirt_Color_" .. number
            return{itemTex,colorInfo}
        end
        if string.find(itemTex,"Tshirt_LongSleeve_SuperColor")then
            local number = string.sub(item:getTexture():getName(),-1)
            itemTex = "TShirt_Longsleeve_Color_" .. number
            return{itemTex,colorInfo}
        end
        --]]
        --return {itemTex,colorInfo}
end

--last resort in picking sprites completely random
local function getRandomSprite(lineNumber)
    CLDebug("getRandomSprite Run")
    local getSprite = getSprite
    local ran = ZombRand(1,#CL.fullSpriteNames)
    CLDebug("getting Random Sprite: " .. CL.fullSpriteNames[ran].."_"..lineNumber)
    local sprite = CL.fullSpriteNames[ran]..lineNumber
    sprite = CL_addSprite(sprite)
    return sprite
end


--unused for right now. new sprite lookup system implemented
--[[
local function spriteLookup(itemTex,lineNumber,colorInfo)
    CLDebug("spriteLookup Run")
    local sprite
    local getSprite = getSprite
    local textureWords = {}
    local itemTextureWords = {}
    local count = 1
    for texture in pairs(CL.SpriteList) do
        textureWords[count] = {}
        for word in  string.gmatch(texture, '([^_]+)')do
             table.insert(textureWords[count],word)
        end
        count = count+1
    end
    for iWord in string.gmatch(itemTex, '([^_]+)')do
        table.insert(itemTextureWords,word)
    end
    local matchcount = 0 
    
    for i, table in pairs(textureWords)do
        matchcount = 0
                for index, value in pairs(table) do
                        for x,xword in pairs(itemTextureWords)do
                            if matchcount >= 2 then break end
                            local tex = string.upper(value)
                            local iTex = string.upper(xword)
                            if index == 1 and x == 1 and not(string.find(iTex,tex)) then break
                            elseif string.find(iTex,tex) then
                                matchcount = matchcount + 1
                            end
                        end
                        if matchcount >= 2 then
                            sprite = CL.fullSpriteNames[i]..lineNumber
                            sprite = CL_addSprite(sprite)
                            if sprite and not sprite:hasNoTextures() then 
                                CLDebug("spriteLookup: " .. CL.fullSpriteNames[i] .. lineNumber .. " [PASSED]") 
                                return sprite
                            end
                        end
                        matchcount=0
                end
    end
    if not sprite or (sprite and sprite:hasNoTextures()) then
        CLDebug("All Sprite lookups failed: Getting random sprite")
        sprite = getRandomSprite(lineNumber)
    end
    return sprite
end--]]




--main sprite picking function
local function pickSprite(obj,container)
    --if string.find(obj:getTextureName(),"clothesHorse"
    CLDebug("pickSprite Run")

        --most of the logic and functions for picking the sprites in this function
    local function getSpriteAttempt(itemTex,lineNumber,colorInfo,item)
        local sprite
        local function setColor(colorInfo,sprite)
            CLDebug("setColor Run")
            if not item:getModData().CLcolorInfo and colorInfo and sprite then 
                sprite:setTintMod(colorInfo)
                item:getModData().CLcolorInfo = colorInfo
            elseif item:getModData().CLcolorInfo and sprite then
                sprite:setTintMod(item:getModData().CLcolorInfo)
            end
        end
        for name in pairs(CL.SpriteList)do
            local upperTex = string.upper(itemTex)
            local uppername = string.upper(name)
            CLDebug("upperTex: "..upperTex )
            CLDebug("upperName: "..uppername )
            if string.find(uppername,upperTex) then
                sprite = name .. "_" .. lineNumber
                sprite = CL_addSprite(sprite)
                break
            end
            if sprite and not sprite:hasNoTextures() then CLDebug("CL.SpriteList getsprite: " .. name.."_"..lineNumber  .. " [PASSED]")end
        end
        if not sprite or (sprite and sprite:hasNoTextures()) and CL.SpriteLookup[itemTex] then
            local itemLookup = CL.SpriteLookup[itemTex]
            if itemLookup ~= nil then
                CLDebug("CL.SpriteList getSpriteAttempt: "..itemLookup.."_"..lineNumber)
                sprite = itemLookup .. "_" .. lineNumber
                sprite = CL_addSprite(sprite)
                if sprite and not sprite:hasNoTextures() then CLDebug("CL.SpriteList getsprite: " .. itemLookup.."_"..lineNumber  .. " [PASSED]")end
            end
        end

        if not sprite or (sprite and sprite:hasNoTextures()) then 
            sprite = itemTex.."_"..lineNumber
            sprite =  CL_addSprite(sprite)
            CLDebug("Direct getSpriteAttempt: "..itemTex.."_"..lineNumber)
            if not sprite:hasNoTextures() then CLDebug("Direct getsprite: " .. itemTex.."_"..lineNumber  .. " [PASSED]")end
        end
        if not sprite or (sprite and sprite:hasNoTextures()) then
            CLDebug("spriteLookup getSpriteAttempt: "..itemTex.."_"..lineNumber)
          --  sprite = spriteLookup(itemTex,lineNumber)
            sprite = getRandomSprite(lineNumber)
        end

    
    setColor(colorInfo,sprite)
    return sprite
    end



    --variables and object sprite sorted here 
    local colorInfo = nil
    local itemAmount = container:size()
    local gridNumber = string.sub(obj:getTextureName(),-2)
    CLDebug("ObjTexture: " .. obj:getTextureName())
    CLDebug("gridNumber: " .. gridNumber)
    local lineNumber = tonumber(gridNumber)
    lineNumber = lineNumber - 26
    CLDebug("lineNumber: " .. lineNumber)
    local spriteList = {}
    local items = {}
    if lineNumber and itemAmount > 0 then
        --4 for first item 6 for 2nd ----but lineNumber is either 4 or 5
        --5 --> 7
        for i = 0, itemAmount-1 do
            local item = container:get(i)
            if not item:getModData().ClothesSpriteSet then
                local itemTex
                local clothingItem = item:getClothingItem()
                if clothingItem then
                    itemTex = clothingItem:GetATexture()
                end

                if itemTex then itemTex = itemTex:match("([^/]+)$")end

                if not itemTex or  itemTex == "" then itemTex = item:getType() end
                
                    CLDebug("item texture: "..itemTex)
                    local colorinfo = CL_getColorInfo(itemTex,item)
                        itemTex,colorInfo = colorinfo[1],colorinfo[2]
                    
                    local sprite
                    if i == 0 then
                        sprite = getSpriteAttempt(itemTex,lineNumber,colorInfo,item)
                        if sprite then
                            table.insert(spriteList,sprite)
                        else print(CLDebug("getSpriteAttempt: "..itemTex.."_"..lineNumber.." [FAILED]"))
                        end
                    elseif lineNumber == 4 then
                        sprite = getSpriteAttempt(itemTex,6,colorInfo,item)
                        if sprite then
                            table.insert(spriteList,sprite)
                        else print(CLDebug("getSpriteAttempt: "..itemTex.."_6 [FAILED]"))
                        end
                    elseif lineNumber == 5 then
                        sprite = getSpriteAttempt(itemTex,7,colorInfo,item)
                        if sprite then
                            table.insert(spriteList,sprite)
                        else print(CLDebug("getSpriteAttempt: "..itemTex.."_7 [FAILED]"))
                        end
                    end
                    item:getModData().ClothesSpriteSet = sprite
            else
                table.insert(spriteList,item:getModData().ClothesSpriteSet)
            end
        end
    end
    if #spriteList < 1 then return nil end
    return spriteList
end
    

--the function called every minute that updates the sprites.
function CL.UpdateSprite()
    if CL.ClothesLinesInSquare then
        for obj in pairs(CL.ClothesLinesInSquare)do
            if obj:getTextureName() then
                if  not CL.textureNames[obj:getTextureName()] then
                    CL.ClothesLinesInSquare[obj] = nil
                elseif CL.textureNames[obj:getTextureName()] and not string.find(obj:getTextureName(),"clothesHorse") then

                    local spriteCount = obj:getAttachedAnimSpriteCount()
                    local container = obj:getItemContainer():getItems()
                    local itemCount = obj:getItemContainer():getItems():size()
                    local hasItems = not obj:getItemContainer():isEmpty()
                    local isEmpty = obj:getItemContainer():isEmpty()
                    local itemContainer = obj:getItemContainer()
                    --added to increase center line capacity so if a jacket is placed another item can be placed as well
                    local objTexture = obj:getTextureName()
                    local contentsWeight = itemContainer:getContentsWeight()
                    local isCenterLine = string.find(objTexture,"appliances_laundry_01_30") or string.find(objTexture,"appliances_laundry_01_31")
                    if itemCount == 0 and isCenterLine then
                        itemContainer:setCapacity(8)
                    elseif isCenterLine and itemCount ==1 then
                        itemContainer:setCapacity(toInt(contentsWeight) + 4)
                    elseif  isCenterLine and itemCount > 1 then
                        itemContainer:setCapacity(.01)
                    end

                        --if there are sprites but no items then clear sprites
                    if spriteCount > 0 and isEmpty then
                        CLDebug(obj:getTextureName() .. ": clearAttachedAnimSprite")
                        obj:clearAttachedAnimSprite()
                        --if there are items but the itemcount doesnt match the spritecount
                    elseif hasItems and (spriteCount ~= itemCount) then
                            obj:clearAttachedAnimSprite()
                            --returns a table of sprites
                        local spriteList = pickSprite(obj,container)
                        if spriteList then
                            --dumb way to randomize placement so overlapping isnt always the same
                            if #spriteList == 1 then
                                obj:addAttachedAnimSprite(spriteList[1])
                                CLDebug(obj:getTextureName() .. ": addAttachedAnimSprite" .. ": "..spriteList[1]:getName())
                            else
                                local r = ZombRand(1,#spriteList)
                                obj:addAttachedAnimSprite(spriteList[r])
                                CLDebug(obj:getTextureName() .. ": addAttachedAnimSprite" .. ": "..spriteList[r]:getName())
                                if r == 1 then 
                                r = r + 1 
                                else
                                r = r-1
                                end
                                obj:addAttachedAnimSprite(spriteList[r])
                                CLDebug(obj:getTextureName() .. ": addAttachedAnimSprite" .. ": "..spriteList[r]:getName())
                            end
                        end
                    end
                end
            end
        end
    end
end
Events.EveryOneMinute.Add(CL.UpdateSprite)

 return CL