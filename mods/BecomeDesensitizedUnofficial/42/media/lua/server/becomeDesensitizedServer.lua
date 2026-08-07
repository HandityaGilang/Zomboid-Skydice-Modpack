local function onUpdateCommand(module, command, player, args)
    if module ~= "updateModule" then return end
    if command == "updateCommand" then
        local player = getPlayerByOnlineID(args.onlineID)
		local traitsArray = {
			CharacterTrait.BRAVE,
			CharacterTrait.COWARDLY,
			CharacterTrait.AGORAPHOBIC,
			CharacterTrait.CLAUSTROPHOBIC,
			CharacterTrait.HEMOPHOBIC,
			CharacterTrait.ADRENALINE_JUNKIE
		}
		for _,value in ipairs(traitsArray) do
			player:getCharacterTraits():remove(value);
		end
    end
end

local function onDesensitizedCommand(module, command, player, args)
    if module ~= "becomeDesensitizedModule" then return end
    if command == "becomeDesensitizedCommand" then
        local player = getPlayerByOnlineID(args.onlineID)
        player:getCharacterTraits():add(CharacterTrait.DESENSITIZED);
    end
end

Events.OnClientCommand.Add(onUpdateCommand)
Events.OnClientCommand.Add(onDesensitizedCommand)