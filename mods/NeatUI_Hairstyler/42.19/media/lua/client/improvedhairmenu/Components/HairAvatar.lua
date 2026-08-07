if isServer() then return end
require("improvedhairmenu/Components/VisualAvatar")

HairAvatar = VisualAvatar:derive("HairAvatar")

function HairAvatar:select()
	-- Don't allow selection of hairs missing a requirement.
	if self.visualItem.requirements then
		local req = self.visualItem.requirements

		-- Hairgel is always a strict requirement when present.
		if req.hairgel == false then return end

		local hasScissors = req.scissors
		local hasRazor    = req.razor

		-- If BOTH are present in the requirements table, treat them as an OR requirement.
		-- (Used by beard trimming + shaving hair to Bald in vanilla logic.)
		if hasScissors ~= nil and hasRazor ~= nil then
			if hasScissors == false and hasRazor == false then return end
		else
			-- Otherwise treat any present tool requirement as strict.
			if hasScissors == false then return end
			if hasRazor == false then return end
		end
	end

	VisualAvatar.select(self)
end

local texture_scissors = getTexture("media/ui/Scissors.png")
local texture_razor    = getTexture("media/ui/Razor.png")
local texture_gel      = getTexture("media/ui/HairGel.png")

function HairAvatar:render()
	VisualAvatar.render(self)
	if self.visualItem.requirements then
		local x_pos = self:getWidth()-20
		local y_pos = 0
		local size = 20
	
		if self.visualItem.requirements.scissors ~= nil then
			if self.visualItem.requirements.scissors then
				self:drawTextureScaled(texture_scissors, x_pos,y_pos, size,size, 1, 1, 1, 1);
			else
				self:drawTextureScaled(texture_scissors, x_pos,y_pos, size,size, 1, 1, 0.5, 0.5);
			end
		end
	
		if self.visualItem.requirements.razor ~= nil then
			-- HACK: Razor only appears for "Bald" which also has scissors so we always draw the razor below regardless.
			if self.visualItem.requirements.razor then
				self:drawTextureScaled(texture_razor, x_pos,y_pos+size, size,size, 1, 1, 1, 1);
			else
				self:drawTextureScaled(texture_razor, x_pos,y_pos+size, size,size, 1, 1, 0.5, 0.5);
			end
		end
	
		if self.visualItem.requirements.hairgel ~= nil then
			if self.visualItem.requirements.hairgel then
				self:drawTextureScaled(texture_gel, x_pos,y_pos, size,size, 1, 1, 1, 1);
			else
				self:drawTextureScaled(texture_gel, x_pos,y_pos, size,size, 1, 1, 0.5, 0.5);
			end
		end
	end
end

function HairAvatar:instantiate()
	VisualAvatar.instantiate(self)
	-- NOTE: Aims at the face.
	self:setZoom(18);
	self:setYOffset(-0.9);
	self:setXOffset(0);
end