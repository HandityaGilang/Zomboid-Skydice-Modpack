require('NPCs/MainCreationMethods')

--[[
local MusicFan = {
	[musiclover] = {
		{IsProfessionTrait = false},
		{DisabledInMultiplayer = false},
		{CharacterTrait = base:musiclover},
		{Cost = 1},
		{UIName = UI_trait_musiclover},
		{UIDescription = UI_trait_musicloverdesc},
		{MutuallyExclusiveTraits = base:deaf}
	}
}
local function musicFan_RegisterTrait()
	MusicFan[musiclover]:setType
	CharacterTraitDefinition.addTrait(MusicFan[musiclover])
end
pztm_RegisterTraits = function()
	CharacterTraitDefinition.addTrait("MusicFan", getText("IGUI_trait_MusicFan"), 1, getText("IGUI_trait_MusicFan_desc"), false, false)
	CharacterTraitDefinition.setMutualExclusive("MusicFan", "Deaf")
	CharacterTraitDefinition.sortList()
end
	local function safeSetIcon(traitObj, iconName)
		if traitObj and traitObj.setIcon then
			traitObj:setIcon(iconName)
		end
	end

	local tRel = CharacterTraitDefinition.addTrait(
		"MusicFan",
		getText("IGUI_trait_MusicFan"),
		1,
		getText("IGUI_trait_MusicFan_desc"),
		false,
		false
	)
	safeSetIcon(tRel, "MusicFan")

	CharacterTraitDefinition.setMutualExclusive(
		"MusicFan",
		"HardOfHearing"
	)
	CharacterTraitDefinition.setMutualExclusive(
		"MusicFan",
		"Deaf"
	)
	CharacterTraitDefinition.sortList()
end

Events.OnGameBoot.Add(musicFan_RegisterTrait)
--]]