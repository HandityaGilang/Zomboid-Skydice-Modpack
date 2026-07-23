require 'ISUI/ISEmoteRadialMenu'
local ISEmoteRadialMenu_fillMenu_old = ISEmoteRadialMenu.fillMenu


local function TAD_isRecipeActuallyLearned(character, recipe)--TwistOnFire
    local known = character and character:getKnownRecipes()
    return known and known.contains and known:contains(recipe)
end


local textures={}
local function addTADDance2RadialMenu(character,recipe)--ordinary based on recipe
    local texture = textures[recipe]
    if not texture then
        texture = getTexture('media/ui/tadordinary/'..recipe..'.png')
        textures[recipe] = texture
    end
    local text = 'IGUI_Emote_'..recipe
	if TAD_isRecipeActuallyLearned(character,recipe) then
		ISEmoteRadialMenu.menu['TAD'].subMenu[recipe] = getText(text);
		ISEmoteRadialMenu.icons[recipe] = texture
	end
end


function ISEmoteRadialMenu:fillMenu(submenu)
	ISEmoteRadialMenu.menu['TAD'] = {};
	ISEmoteRadialMenu.menu['TAD'].name = getText('IGUI_Emote_TAD');
	ISEmoteRadialMenu.menu['TAD'].subMenu = {};	
	ISEmoteRadialMenu.icons['TAD'] = getTexture('media/ui/UI_TAD.png');

    TAD.initTAD()
    
    for i=1, #TAD.OrdinaryDanceBook do
        addTADDance2RadialMenu(self.character,TAD.OrdinaryDanceBook[i])
    end

	local allItems = self.character:getInventory():getAllTag(TAD.TAG_DanceCard)
	local taddif = false
	for i=1,allItems:size() do
		local item = allItems:get(i-1)
        local difficultDanceConf = TAD.DifficultDanceBookMap[item:getFullType()]
		if difficultDanceConf then
			if not taddif then
				taddif = true
				ISEmoteRadialMenu.menu['TADdif'] = { name = getText('IGUI_Emote_TADdif'), subMenu = {} };
				ISEmoteRadialMenu.icons['TADdif'] = getTexture('media/ui/UI_TADdif.png');
			end
			ISEmoteRadialMenu.menu['TADdif'].subMenu[difficultDanceConf] = getText('IGUI_Emote_' .. difficultDanceConf);
			ISEmoteRadialMenu.icons[difficultDanceConf] = getTexture('media/ui/taddifficult/' .. difficultDanceConf .. '.png');
		end
	end
	ISEmoteRadialMenu_fillMenu_old(self, submenu)
end

function TADOnCreatePlayer(playerNum, playerObj)
	if not playerObj:getModData()['tad'] then
        TAD.initTAD()
		playerObj:getModData()['tad'] = true
        local randA = ZombRand(#TAD.OrdinaryDanceBook)+1
        local randB = ZombRand(#TAD.OrdinaryDanceBook)
        local randC = ZombRand(#TAD.OrdinaryDanceBook)-1
        if randA == randB then randB = #TAD.OrdinaryDanceBook end
        if randA == randC then randC = #TAD.OrdinaryDanceBook-1 end
        if randB == randC then randC = #TAD.OrdinaryDanceBook end
		local a = TAD.OrdinaryDanceBook[randA]
		local b = TAD.OrdinaryDanceBook[randB]
		local c = TAD.OrdinaryDanceBook[randC]
        --print('TAD add known recipe '..tostring(a)..' '..tostring(b)..' '..tostring(c))
        playerObj:getKnownRecipes():add(a)
		playerObj:getKnownRecipes():add(b)
		playerObj:getKnownRecipes():add(c)
	end
end

Events.OnCreatePlayer.Add(TADOnCreatePlayer)


