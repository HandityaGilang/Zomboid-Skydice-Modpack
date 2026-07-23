local SPNCC_Data = require("CharacterCustomisation/SPNCC_Data")
require("CharacterCustomisation/CharacterCreation/CC_UpdateCharacterPreview")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local BUTTON_HGT = FONT_HGT_SMALL + 6

local function spn_getClientData()
	local ok, data = pcall(require, "CharacterCustomisation/CharacterCreation/StoredCharacterData")
	if ok and type(data) == "table" then
		return data
	end
	return nil
end

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

local function spn_getAppearanceAnchor(self)
	if self.skinColorButton then
		return self.skinColorButton
	end
	if self.voiceDemoButton then
		return self.voiceDemoButton
	end
	if self.randomButton then
		return self.randomButton
	end
	if self.backButton then
		return self.backButton
	end
	return nil
end

local function spn_getCustomisationButtonWidth()
	return math.max(
		110,
		getTextManager():MeasureStringX(UIFont.Small, getText("UI_characreation_charapanel")) + 24
	)
end

local function spn_positionCustomisationButton(self)
	local button = rawget(self, "customisationButton")
	if not button then
		return
	end

	local x = 0
	local y = 0

	if self.skinColorButton then
		x = self.skinColorButton:getRight() + 10
		y = self.skinColorButton.y
	else
		local anchor = spn_getAppearanceAnchor(self)
		if not anchor then
			return
		end

		x = anchor.x
		y = anchor.y
	end

	local width = spn_getCustomisationButtonWidth()

	if self.characterPanel then
		local maxWidth = self.characterPanel.width - x - 20
		if maxWidth > 60 then
			width = math.min(width, maxWidth)
		end
	end

	button:setWidth(width)
	button:setHeight(BUTTON_HGT)
	button:setX(x)
	button:setY(y)
	button:setVisible(true)
end

function CharacterCreationMain:ensureCharacterCustomisationPanel()
	local panel = rawget(self, "characterCustomisationPanel")
	if type(panel) == "table" then
		return true
	end

	if panel ~= nil then
		self.characterCustomisationPanel = nil
	end

	if not CharacterCustomisationPanel then
		print("[SPNCC] CharacterCustomisationPanel is missing.")
		return false
	end

	self.characterCustomisationPanel = CharacterCustomisationPanel:new()

	self.characterCustomisationPanel.onBodyDetailSelected = function()
		self:spn_update_character_customisation()
	end

	self.characterCustomisationPanel:initialise()

	if MainScreen.instance and MainScreen.instance.desc then
		self.characterCustomisationPanel:setDesc(MainScreen.instance.desc)
	end

	self.characterCustomisationPanel.onClose = function()
		if CharacterCreationMain.instance and self.characterCustomisationPanel then
			CharacterCreationMain.instance:removeChild(self.characterCustomisationPanel)
			self.characterCustomisationPanel:setCapture(false)
		end

		if self.customisationButton then
			self.customisationButton.expanded = false
			self.customisationButton.attachedMenu = self.characterCustomisationPanel
		end
	end

	self:spn_populate_customisation_window()

	local clientData = spn_getClientData()
	if clientData then
		if self.characterCustomisationPanel.faceMenu and clientData.face and clientData.face.name then
			self.characterCustomisationPanel.faceMenu:setSelectedOption(clientData.face.name)
		end

		if self.characterCustomisationPanel.bodyDetailMenu and clientData.bodyDetails then
			local names = {}
			for _, v in ipairs(clientData.bodyDetails) do
				if v and v.name then
					table.insert(names, v.name)
				end
			end
			self.characterCustomisationPanel.bodyDetailMenu:setSelectedOptions(names)
		end

		if self.characterCustomisationPanel.muscleButton then
			self.characterCustomisationPanel.muscleButton:setSelected(clientData.muscleVisuals ~= false)
		end

		if self.characterCustomisationPanel.hairButton then
			self.characterCustomisationPanel.hairButton:setSelected(clientData.bodyHairGrowth ~= false)
		end
	end

	return true
end

--When the gender or skintone is changed we need to re-fill all the windows and then update the character with new customisation items
function CharacterCreationMain:refreshCustomisationWindow()
	if not MainScreen.instance or not MainScreen.instance.desc then
		return
	end

	local desc = MainScreen.instance.desc
	local panel = rawget(self, "characterCustomisationPanel")

	if type(panel) == "table" then
		local lockedVisible = isDebugEnabled()
		if isClient() then
			local ok, admin = pcall(isAdmin)
			if ok and admin then
				lockedVisible = true
			end
		end

		panel:setLockedOptionsVisible(lockedVisible)
		self:spn_populate_customisation_window()
	else
		local clientData = spn_getClientData()
		if clientData then
			local faces = SPNCC_Data.GetFacesForCharacter(desc)
			local details = SPNCC_Data.GetBodyDetailsForCharacter(desc)

			clientData.face = clientData.face or { name = "DefaultFace", id = "DefaultFace", texture = 0 }
			clientData.bodyDetails = clientData.bodyDetails or {}

			if clientData.face.name and clientData.face.name ~= "DefaultFace" then
				local f = faces and faces[clientData.face.name]
				if f and f.id and f.id ~= "" then
					clientData.face.id = f.id
					clientData.face.texture = f.texture or 0
				else
					clientData.face = { name = "DefaultFace", id = "DefaultFace", texture = 0 }
				end
			end

			local newList = {}
			for _, bd in ipairs(clientData.bodyDetails) do
				if bd and bd.name and details then
					local d = details[bd.name]
					if d and d.id and d.id ~= "" then
						table.insert(newList, {
							name = d.name,
							id = d.id,
							texture = d.texture or 0,
						})
					end
				end
			end
			clientData.bodyDetails = newList
		end
	end

	self:spn_update_character_customisation()
end

-- Fill all combo boxes
function CharacterCreationMain:spn_populate_customisation_window()
	local desc = MainScreen.instance.desc
	
	local list = SPNCC_Data.GetFacesForCharacter(desc)
	self.characterCustomisationPanel:setFaceOptions(list)
	
	local list = SPNCC_Data.GetBodyDetailsForCharacter(desc)
	self.characterCustomisationPanel:setBodyDetailOptions(list)
end

function CharacterCreationMain:createCharacterCustomisationWindow()
	if self.customisationButton and self.customisationButton.parent == self.characterPanel then
		spn_positionCustomisationButton(self)
		return
	end

	local function showMenu()
		if not self:ensureCharacterCustomisationPanel() then
			return
		end

		local sandbox = spn_getSandbox()

		self.customisationButton.expanded = true

		self.characterCustomisationPanel.muscleButton:setVisible((sandbox.MuscleVisuals or 3) == 3)
		self.characterCustomisationPanel.hairButton:setVisible((sandbox.BodyHairGrowthEnabled or 3) == 3)

		if MainScreen.instance and MainScreen.instance.desc then
			self.characterCustomisationPanel:setDesc(MainScreen.instance.desc)
		end

		self.characterCustomisationPanel:syncDescVisuals()
		self.characterCustomisationPanel:setAvatarDescs()
		self.characterCustomisationPanel:setPreviewBodyDetails(self.wornCustomisationItems or {})

		self:removeChild(self.characterCustomisationPanel)
		self:addChild(self.characterCustomisationPanel)

		local width = CharacterCreationMain.instance:getWidth()
		local height = CharacterCreationMain.instance:getHeight()
		self.characterCustomisationPanel:setX((width / 2) - (self.characterCustomisationPanel:getWidth() / 2))
		self.characterCustomisationPanel:setY((height / 2) - (self.characterCustomisationPanel:getHeight() / 2))
		self.characterCustomisationPanel:setCapture(true)
	end

	self.customisationButton = ISButton:new(
		0,
		0,
		spn_getCustomisationButtonWidth(),
		BUTTON_HGT,
		getText("UI_characreation_charapanel"),
		self,
		showMenu
	)
	self.customisationButton:initialise()
	self.customisationButton:instantiate()
	self.customisationButton.isButton = nil
	self.customisationButton.expanded = false
	self.customisationButton.attachedMenu = nil

	self.characterPanel:addChild(self.customisationButton)
	spn_positionCustomisationButton(self)
end


	-- ----------------------
	-- -- ADD BUTTONS TO MENU
	-- ----------------------
local originalCharacterCreationMainCreate = CharacterCreationMain.create
---@diagnostic disable-next-line: duplicate-set-field
function CharacterCreationMain.create(self)
	originalCharacterCreationMainCreate(self)

	self:createCharacterCustomisationWindow()

	self:spn_randomise_face()
	self:spn_update_character_customisation()
end


-- Set customisation when the char creation menu is opened
local originalCharacterCreationMainSetVisible = CharacterCreationMain.setVisible
---@diagnostic disable-next-line: duplicate-set-field
function CharacterCreationMain:setVisible(bVisible, joypadData)
	originalCharacterCreationMainSetVisible(self, bVisible, joypadData)

	if not bVisible or not MainScreen.instance or not MainScreen.instance.desc then
		return
	end

	local sandbox = spn_getSandbox()
	local clientData = spn_getClientData()

	if clientData then
		if clientData.muscleVisuals == nil then
			clientData.muscleVisuals = (sandbox.MuscleVisuals or 3) ~= 2
		end
		if clientData.bodyHairGrowth == nil then
			clientData.bodyHairGrowth = (sandbox.BodyHairGrowthEnabled or 3) ~= 2
		end
	end

	if not self.customisationButton then
		self:createCharacterCustomisationWindow()
	end

	if self.characterCustomisationPanel then
		self.characterCustomisationPanel.muscleButton:setSelected(clientData == nil or clientData.muscleVisuals ~= false)
		self.characterCustomisationPanel.hairButton:setSelected(clientData == nil or clientData.bodyHairGrowth ~= false)
	end

	self:disableBtn()
	spn_positionCustomisationButton(self)
	self:refreshCustomisationWindow()
end

local vanilla_spn_disableBtn = CharacterCreationMain.disableBtn
---@diagnostic disable-next-line: duplicate-set-field
function CharacterCreationMain:disableBtn()
	vanilla_spn_disableBtn(self)

	if self.chestHairLbl and self.chestHairTickBox then
		self.chestHairLbl:setVisible(true)
		self.chestHairTickBox:setVisible(true)

		if self.characterPanel then
			local scrollHeight = math.max(
				self.characterPanel:getScrollHeight(),
				self.chestHairTickBox:getBottom() + 10
			)
			self.characterPanel:setScrollHeight(scrollHeight)
		end
	end

	if not self.customisationButton then
		self:createCharacterCustomisationWindow()
	end

	spn_positionCustomisationButton(self)
end

local vanilla_spn_onResolutionChange = CharacterCreationMain.onResolutionChange
---@diagnostic disable-next-line: duplicate-set-field
function CharacterCreationMain:onResolutionChange(oldw, oldh, neww, newh)
	vanilla_spn_onResolutionChange(self, oldw, oldh, neww, newh)
	spn_positionCustomisationButton(self)
end