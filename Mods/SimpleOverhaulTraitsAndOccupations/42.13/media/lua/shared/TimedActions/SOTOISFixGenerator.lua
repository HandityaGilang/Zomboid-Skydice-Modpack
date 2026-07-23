require "TimedActions/ISFixGenerator"

local oldISFixGenerator_perform = ISFixGenerator.perform
function ISFixGenerator:perform()
	player = self.character
	oldISFixGenerator_perform(self)
	if player:hasTrait(SOTO.CharacterTrait.GENERATOR_EXPERT) or player:hasTrait(SOTO.CharacterTrait.GENERATOR_EXPERT2) then
		self.generator:setCondition(self.generator:getCondition() + 5)
		player:getXp():AddXP(Perks.Electricity, 5);		
	end
end