local items = {
    "Base.CatToy",
}
function kittylootdistro(zombie)
    if (ZombRand(1000) <= 25) then
            local randomItem = items[ZombRand(1, #items)]
            local item = instanceItem(randomItem)
            local inv = zombie:getInventory()
            inv:getInventory():AddItem(item)
            sendAddItemToContainer(inv, item)
    end
end