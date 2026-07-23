if isServer() then return end

local function spn_getSandbox()
	local sandbox = SandboxVars and SandboxVars.SPNCharCustom
	if sandbox then
		return sandbox
	end

	return {
		MuscleVisuals = 3,
		BodyHairGrowthEnabled = 3,
	}
end

local function spn_tryInstall()
	if type(CharacterCreationMain) ~= "table" then
		return false
	end

	-- We need the helper methods from your existing fix file to already exist.
	if type(CharacterCreationMain.createCharacterCustomisationWindow) ~= "function" then
		return false
	end
	if type(CharacterCreationMain.refreshCustomisationWindow) ~= "function" then
		return false
	end

	if CharacterCreationMain._SPNCC_LATE_MP_INSTALLED then
		return true
	end
	CharacterCreationMain._SPNCC_LATE_MP_INSTALLED = true

	CharacterCreationMain.bodyHairOptions = CharacterCreationMain.bodyHairOptions or {
		stubbleHead = false,
		stubbleBeard = false,
		bodyHair = false,
	}

	local baseCreate = CharacterCreationMain.create
	local baseSetVisible = CharacterCreationMain.setVisible
	local baseDisableBtn = CharacterCreationMain.disableBtn
	local baseOnResolutionChange = CharacterCreationMain.onResolutionChange

	function CharacterCreationMain.onBeardStubbleSelected(self, index, selected)
		self.bodyHairOptions.stubbleBeard = selected
		if self.spn_update_character_customisation then
			self:spn_update_character_customisation()
		end
	end

	function CharacterCreationMain.onShavedHairSelected(self, index, selected)
		self.bodyHairOptions.stubbleHead = selected
		if self.spn_update_character_customisation then
			self:spn_update_character_customisation()
		end
	end

	function CharacterCreationMain.onChestHairSelected(self, index, selected)
		self.bodyHairOptions.bodyHair = selected
		if self.spn_update_character_customisation then
			self:spn_update_character_customisation()
		end
	end

	function CharacterCreationMain:syncUIWithTorso()
		local desc = MainScreen.instance and MainScreen.instance.desc
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

	---@diagnostic disable-next-line: duplicate-set-field
	function CharacterCreationMain.create(self)
		baseCreate(self)

		if not self.customisationButton then
			self:createCharacterCustomisationWindow()
		else
			-- Existing helper already repositions when button exists.
			self:createCharacterCustomisationWindow()
		end

		if self.spn_update_character_customisation then
			self:spn_update_character_customisation()
		end
	end

	---@diagnostic disable-next-line: duplicate-set-field
	function CharacterCreationMain:setVisible(bVisible, joypadData)
		baseSetVisible(self, bVisible, joypadData)

		if not bVisible or not MainScreen.instance or not MainScreen.instance.desc then
			return
		end

		local sandbox = spn_getSandbox()

		if not self.customisationButton then
			self:createCharacterCustomisationWindow()
		else
			self:createCharacterCustomisationWindow()
		end

		if self.characterCustomisationPanel then
			if self.characterCustomisationPanel.muscleButton then
				self.characterCustomisationPanel.muscleButton:setSelected((sandbox.MuscleVisuals or 3) ~= 2)
			end
			if self.characterCustomisationPanel.hairButton then
				self.characterCustomisationPanel.hairButton:setSelected((sandbox.BodyHairGrowthEnabled or 3) ~= 2)
			end
		end

		self:disableBtn()
		self:refreshCustomisationWindow()
	end

	---@diagnostic disable-next-line: duplicate-set-field
	function CharacterCreationMain:disableBtn()
		baseDisableBtn(self)

		if not self.chestHairLbl then
			return
		end

		self.chestHairLbl:setVisible(true)
		if self.chestHairTickBox then
			self.chestHairTickBox:setVisible(true)
		end

		-- Re-run your existing button placement helper through the existing method.
		self:createCharacterCustomisationWindow()
	end

	---@diagnostic disable-next-line: duplicate-set-field
	function CharacterCreationMain:onResolutionChange(oldw, oldh, neww, newh)
		if baseOnResolutionChange then
			baseOnResolutionChange(self, oldw, oldh, neww, newh)
		end

		if self.createCharacterCustomisationWindow then
			self:createCharacterCustomisationWindow()
		end
	end

	print("[SPNCC] Late MP installer applied.")
	return true
end

local function spn_tryInstallTick()
	if spn_tryInstall() then
		Events.OnTick.Remove(spn_tryInstallTick)
	end
end

Events.OnTick.Add(spn_tryInstallTick)

if Events.OnGameBoot then
	Events.OnGameBoot.Add(spn_tryInstallTick)
end

Events.OnMainMenuEnter.Add(spn_tryInstallTick)