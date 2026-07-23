SpecialLootSpawns.OnCreateFortuneMessage= function(item)
    if not item then return; end;
	local text
	local bookList = PrintMediaDefinitions.FortuneMessage
	local book = bookList[ZombRand(#bookList)+1]
	local text = getText(item:getDisplayName())
	item:setName(text)
    item:getModData().printMedia = book
end