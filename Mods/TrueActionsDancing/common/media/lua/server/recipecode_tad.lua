
TAD = TAD or {}

function TAD.OnStartEatFood(sourceItem, playerObj)
    if sourceItem and sourceItem:hasTag(TAD.TAG_CardGiver) then
        local md = sourceItem:getModData()
        if md and not md.TADCardFound and playerObj then
            
            TAD.initTAD()
            
            local container = playerObj and playerObj:getInventory()
            local randPicked = ZombRand(#TAD.DifficultDanceBook)+1
            local randomCard = TAD.DifficultDanceBook[randPicked]
            local cardItem = instanceItem(randomCard)
            container:AddItem(cardItem);
            sendAddItemToContainer(container,cardItem)
            
            md.TADCardFound = true
            syncItemModData(playerObj, sourceItem)
        end
    end
end


local startUpperLayer = ISEatFoodAction.start
function ISEatFoodAction:start()
    startUpperLayer(self)
    
    if not isClient() then
        TAD.OnStartEatFood(self.item, self.character)--solo
    end
end

local serverStartUpperLayer = ISEatFoodAction.serverStart
function ISEatFoodAction:serverStart()
    if isServer() then
        TAD.OnStartEatFood(self.item, self.character)--mp
    end
    
    if serverStartUpperLayer then
        serverStartUpperLayer(self)
    end
end