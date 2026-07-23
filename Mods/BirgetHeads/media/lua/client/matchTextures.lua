local function matchFaceAndBody(player)
    local skinTextureIndex = player:getVisual():getSkinTextureIndex()
    local head = player:getWornItem('Face_Model')
    local wrinkles = player:getWornItem('Wrinkles')
    local eyeContacts = player:getWornItem('EyeContacts')
    local skinOld = player:getVisual():getSkinTextureIndex() + 5

    if head == nil then
        return
    end

    if player:isFemale() then
        if head:getVisual():getTextureChoice() ~= skinTextureIndex or skinOld then
            head:getVisual():setTextureChoice(skinTextureIndex)
        end
        --морщины отдельно
        if wrinkles ~= nil and wrinkles:getVisual():getClothingItemName() == 'Wrinkles/MakeUp_Wrinkles_maximum' then
            head:getVisual():setTextureChoice(skinOld)
            print("It's a match!")
        end
        --линзы
        if eyeContacts == nil then
            head:getVisual():setDecal('MakeUp_EyeContacts_None')
        else
			local eyeContactsName = eyeContacts:getVisual():getClothingItemName()
            head:getVisual():setDecal(eyeContactsName)
        end
    else
		if head:getVisual():getTextureChoice() ~= skinTextureIndex or skinOld then
			head:getVisual():setTextureChoice(skinTextureIndex)
		end
		--линзы
		if eyeContacts == nil then
			head:getVisual():setDecal('MakeUp_EyeContacts_None')
		else
			local eyeContactsName = eyeContacts:getVisual():getClothingItemName()
			head:getVisual():setDecal(eyeContactsName)
		end
		--морщины отдельно
		if wrinkles ~= nil and wrinkles:getVisual():getClothingItemName() == 'Wrinkles/MakeUp_Wrinkles_maximum' then
			if skinTextureIndex == 1 then head:getVisual():setTextureChoice(skinOld) end
			if skinTextureIndex == 2 then head:getVisual():setTextureChoice(skinOld) end
			if skinTextureIndex == 3 then head:getVisual():setTextureChoice(skinOld) end
			if skinTextureIndex == 4 then head:getVisual():setTextureChoice(skinOld) end
			if skinTextureIndex == 5 then head:getVisual():setTextureChoice(skinOld) end
		end
            
	
    end

    player:resetModelNextFrame()
end

local function createOnClothingUpdatedHandler(playerNum)
    local player = getSpecificPlayer(playerNum)

    local function OnClothingUpdated()
        matchFaceAndBody(player)
    end

    Events.OnClothingUpdated.Add(OnClothingUpdated)

    Events.OnPlayerDeath.Add(function(player)
        if player:getPlayerNum() == playerNum then
            Events.OnClothingUpdated.Remove(OnClothingUpdated)
        end
    end)
end

Events.OnCreatePlayer.Add(createOnClothingUpdatedHandler)

	
	
		
		
		


