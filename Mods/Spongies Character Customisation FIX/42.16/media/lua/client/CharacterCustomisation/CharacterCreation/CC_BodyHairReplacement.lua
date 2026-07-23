---@diagnostic disable: duplicate-set-field

CharacterCreationMain.bodyHairOptions = CharacterCreationMain.bodyHairOptions or {
	stubbleHead = false,
	stubbleBeard = false,
	bodyHair = false,
}

function CharacterCreationMain.onBeardStubbleSelected(self, index, selected)
	self.bodyHairOptions.stubbleBeard = selected
	self:spn_update_character_customisation()
end

function CharacterCreationMain.onShavedHairSelected(self, index, selected)
	self.bodyHairOptions.stubbleHead = selected
	self:spn_update_character_customisation()
end

function CharacterCreationMain.onChestHairSelected(self, index, selected)
	self.bodyHairOptions.bodyHair = selected
	self:spn_update_character_customisation()
end

function CharacterCreationMain:syncUIWithTorso()
	local desc = MainScreen.instance.desc
	if not desc then return end

	self.skinColor = desc:getHumanVisual():getSkinTextureIndex() + 1

	if desc:isFemale() then
		self.bodyHairOptions.stubbleBeard = false
	end

	if self.chestHairTickBox then
		self.chestHairTickBox:setSelected(1, self.bodyHairOptions.bodyHair)
	end
	if self.beardStubbleTickBox then
		self.beardStubbleTickBox:setSelected(1, self.bodyHairOptions.stubbleBeard)
	end
	if self.hairStubbleTickBox then
		self.hairStubbleTickBox:setSelected(1, self.bodyHairOptions.stubbleHead)
	end
end