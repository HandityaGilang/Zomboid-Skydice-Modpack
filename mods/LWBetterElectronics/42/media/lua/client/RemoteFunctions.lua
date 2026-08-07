RemoteFunctions =  {};


RemoteFunctions.createMenu = function(player, context, items)
	local isARemote = item;

	
	for i, v in ipairs(items) do
		local item = v;
--		print("Item: ", item)
		if not instanceof(v, "InventoryItem") then
			item = v.items[1];
		end
			
		if item:getRemoteRange() >= 1 then
--			print(item:getRemoteRange())
--			print("Item is a Remote!!!")
			Remote = item;
--			print(Remote)
		end
	end

	if Remote then		

			context:addOption(getText("ContextMenu_renameRemote"), Remote, RemoteFunctions.onRenameItem, player);
			context:addOption(getText("ContextMenu_ChangeRemoteID"), Remote, RemoteFunctions.onChangeID, player);
			Remote = nil
	end
end

RemoteFunctions.onRenameItem = function(item, player)

	print("RENAME ITEM: ", item:getRemoteControlID())
	print("Player: ", player)
    local modal = ISTextBox:new(0, 0, 500, 100, getText("ContextMenu_newNameRemote"), item:getName(), nil, RemoteFunctions.onRenameItemClick, player, getSpecificPlayer(player), item);
    modal:initialise();
    modal:addToUIManager();
    modal.entry:focus();
	
end


function RemoteFunctions:onRenameItemClick(button, player, item)
	
    if button.internal == "OK" then
        if button.parent.entry:getText() and button.parent.entry:getText() ~= "" then
        	newName = button.parent.entry:getText()
        	item:setName(button.parent.entry:getText());
        	
			if isServer() then
        		sendClientCommand('RenameRemote', 'ChangeRemoteName', {item})
        	end
        
            item:setCustomName(true)
            local pdata = getPlayerData(player:getPlayerNum());
            pdata.playerInventory:refreshBackpacks();
            pdata.lootInventory:refreshBackpacks();
        end
    end
end

RemoteFunctions.onChangeID = function(item, player)

--	print("CHANGE ID ITEM: ", item:getRemoteControlID())
--	print("Player: ", player)
	local ControlID= tostring(item:getRemoteControlID())
	
    local idBox = ISTextBox:new(0, 0, 300, 100, getText("ContextMenu_newIDRemote"), ControlID, nil, RemoteFunctions.onChangeIDClick, player, getSpecificPlayer(player), item);
    idBox:initialise();
    idBox:addToUIManager();
    idBox.entry:focus();
end

function RemoteFunctions.onChangeIDClick(test, button, player,item)
	
	buttonInput = tonumber(button.parent.entry:getText())

	if button.internal == "OK" then
		if button.parent.entry:getText() and button.parent.entry:getText() ~= "" then        	

			if buttonInput ~= nil then
		--		
				if string.len(button.parent.entry:getText()) == 5 then
	
					item:setRemoteControlID(buttonInput)
					player:Say("67158") 
				
					local pdata = getPlayerData(player:getPlayerNum());
					pdata.playerInventory:refreshBackpacks();
					pdata.lootInventory:refreshBackpacks();
				else
					
					player:Say("The Frequency has to be 5 digits")
				end
			else
				player:Say("I can only enter 5-Digit Numbers as frequency")
				
			end								
		end
	end
end




Events.OnFillInventoryObjectContextMenu.Add(RemoteFunctions.createMenu);