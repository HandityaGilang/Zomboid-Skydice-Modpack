require("MDFT_CharacterCreationProfession")
require("XpSystem/ISUI/ISCharacterScreen")

ISCharacterScreen = ISCharacterScreen or {}

render_old = ISCharacterScreen.render;
loadTraits_old = ISCharacterScreen.loadTraits;


ISCharacterScreen.loadTraits = function(self)
    for _,image in ipairs(self.traits) do
		self:removeChild(image)
	end
	table.wipe(self.traits);
	self:setDisplayedTraits()
	for _,trait in ipairs(self.displayedTraits) do
		local textImage = ISImage:new(0, 0, trait:getTexture():getWidthOrig(), trait:getTexture():getHeightOrig(), trait:getTexture());
		textImage:initialise();

		local setMouseOverText = trait:getLabel() .. getText(" : <br>") .. trait:getDescription();
		setMouseOverText = MDFT.addDescriptionToTooltip(trait, setMouseOverText)
		textImage:setMouseOverText(setMouseOverText)

		textImage:setVisible(false);
		textImage.trait = trait;
		self:addChild(textImage);
		table.insert(self.traits, textImage);
	end
	self.Strength = self.char:getPerkLevel(Perks.Strength)
	self.Fitness = self.char:getPerkLevel(Perks.Fitness)
end



ISCharacterScreen.render = function(self)
    render_old(self);
    if self.profImage and self.profession and self.professionDescription then
        self.profImage:setMouseOverText(self.profession .. getText(" : <br>") .. self.professionDescription);
    end 
end

ISCharacterScreen.loadProfession = function(self)
	self.professionTexture = nil;
	self.profession = nil;
	self.professionDescription = nil;
	-- Use new 42.13 API: getCharacterProfession() and CharacterProfessionDefinition
	if self.char:getDescriptor() and self.char:getDescriptor():getCharacterProfession() then
		local characterProfessionDefinition = CharacterProfessionDefinition.getCharacterProfessionDefinition(self.char:getDescriptor():getCharacterProfession());
		if characterProfessionDefinition then
			self.profession = characterProfessionDefinition:getUIName();
			self.professionDescription = MDFT.addDescriptionToTooltip(characterProfessionDefinition, characterProfessionDefinition:getDescription());
			self.professionTexture = characterProfessionDefinition:getTexture();
		end
	end
end