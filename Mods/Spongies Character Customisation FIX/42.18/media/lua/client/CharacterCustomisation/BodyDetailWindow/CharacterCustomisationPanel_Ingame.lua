--[[
	Derivative of the character creation window but with functions for handling customisation ingame
]]

require("CharacterCustomisation/BodyDetailWindow/CharacterCustomisationPanel")
local base = CharacterCustomisationPanel
CharacterCustomisationPanel_Ingame = base:derive("CharacterCustomisationPanel_Ingame")

local FaceManager_Shared = require("CharacterCustomisation/FaceManager_Shared")
local SPNCC_Data = require("CharacterCustomisation/SPNCC_Data")
local FaceManager_Local = require("CharacterCustomisation/FaceManager_Local")

local function _useLocalSingleplayerPath()
	return not isClient() and not isServer()
end

local function _safeField(obj, key, default)
	if obj == nil then return default end
	local ok, value = pcall(function() return obj[key] end)
	if ok and value ~= nil then return value end
	return default
end

local function _copyFaceOption(face)
	if face == nil then
		return { name = "DefaultFace", id = "", texture = 0 }
	end

	local name = _safeField(face, "name", "DefaultFace")
	local id = _safeField(face, "id", "")
	local texture = tonumber(_safeField(face, "texture", 0)) or 0

	if name == "DefaultFace" or id == "DefaultFace" then
		id = ""
	end

	if not name or name == "" then
		name = "DefaultFace"
	end

	return {
		name = name,
		id = id or "",
		texture = texture,
	}
end

local function _copyBodyDetailList(details)
	local list = {}
	if details == nil then return list end

	local isJavaList = type(details) ~= "table" and type(details.size) == "function" and type(details.get) == "function"
	if isJavaList then
		for i = 0, details:size() - 1 do
			local entry = details:get(i)
			local name = _safeField(entry, "name", nil)
			local id = _safeField(entry, "id", nil)
			if name and id then
				list[#list + 1] = {
					name = name,
					id = id,
					texture = tonumber(_safeField(entry, "texture", 0)) or 0,
				}
			end
		end
		return list
	end

	if type(details) == "table" then
		for _, entry in pairs(details) do
			if entry ~= nil then
				local name = _safeField(entry, "name", nil)
				local id = _safeField(entry, "id", nil)
				if name and id then
					list[#list + 1] = {
						name = name,
						id = id,
						texture = tonumber(_safeField(entry, "texture", 0)) or 0,
					}
				end
			end
		end
	end

	return list
end

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

function CharacterCustomisationPanel_Ingame:new()
	local o = base.new(self)
	o.lockedOptionsVisible = false
	o.faceMenuVisible = true
	o.bodyDetailMenuVisible = true
	o.isIngame = true
	o.canClose = false
	o.hideCancelButton = false
	o.previewItems = {}
	o.oldItems = {}
	o.otherItems = {}
	return o
end

--initialise the menu when it is opened
function CharacterCustomisationPanel_Ingame:OpenMenu(player)

	-- sendClientCommand(player, "SPNCC", "RequestSyncModData", { })
	
    self.backgroundColor = {r=0,g=0,b=0,a=0.8}


	self.faceMenu:setVisible(self.faceMenuVisible)
	self.bodyDetailMenu:setVisible(self.bodyDetailMenuVisible)


	--hide the muscle tickbox if player choice is disabled
	self.muscleButton:setVisible(SandboxVars.SPNCharCustom.MuscleVisuals == 3)

	--hide the body hair tickbox if player choice is disabled
	self.hairButton:setVisible(SandboxVars.SPNCharCustom.BodyHairGrowthEnabled == 3)

	--tell the menus whether to show or hide locked options
	self:setLockedOptionsVisible(self.lockedOptionsVisible)


	self:setChar(player)
	self:syncDescVisuals()
	self:FillCustomisationWindow()
	self:SetPlayerCustomisationFromData()
end

function CharacterCustomisationPanel_Ingame:render()
	base.render(self)
	
	--we display text telling the player that changing face or details is disabled in sandbox settings
	local offset_x = self.faceMenu:getX() + (self.faceMenu:getWidth()/2)

	if not self.faceMenu:isVisible() then
		local offset_y = self.faceMenu:getY() + (self.faceMenu:getHeight()/2)
	
		self:drawTextCentre(getText("UI_characreation_facedisabled"), offset_x, offset_y, 1, 1, 1, 0.5, UIFont.Medium)
	end
	if not self.bodyDetailMenu:isVisible() then
		local offset_y = self.bodyDetailMenu:getY() + (self.bodyDetailMenu:getHeight()/2)
	
		self:drawTextCentre(getText("UI_characreation_detailsdisabled"), offset_x, offset_y, 1, 1, 1, 0.5, UIFont.Medium)
	end

end


--replace close buttons with save and cancel
function CharacterCustomisationPanel_Ingame:createCloseButton()
	-- Close button
	local hgt = FONT_HGT_SMALL*2
	local btnpadding = hgt/4
	local yoffset = self.avatarPanel:getBottom() + btnpadding

	local btnwidth = self:getWidth()/8
	-- local btnpadding = btnwidth/4

	self.saveButton = ISButton:new(self:getWidth()-btnwidth-btnpadding, yoffset, btnwidth,hgt, getText("UI_characreation_BuildSave"), self, self.closeSave)
	self.saveButton:initialise()
	self.saveButton:instantiate()
	self.saveButton:enableAcceptColor()
	self:addChild(self.saveButton)

	self.cancelButton = ISButton:new(0+btnpadding, yoffset, btnwidth,hgt, getText("UI_Cancel"), self, self.closeCancel)
	self.cancelButton:initialise()
	self.cancelButton:instantiate()
	self.cancelButton:enableCancelColor()
	self:addChild(self.cancelButton)
	
	if self.hideCancelButton then 
		self.cancelButton:setVisible(false)
	end
	
	self:setHeight(self:getHeight() + btnpadding + hgt + btnpadding)
end

--when this menu is closed we reset everything and then call the function assigned to self.onClose
function CharacterCustomisationPanel_Ingame:closeSave()
	self:close()
	--when we close the menu we apply the customisation to the player
	self:UpdatePlayerCustomisation()

	if self.onCloseSave then self.onCloseSave() end
end
function CharacterCustomisationPanel_Ingame:closeCancel()
	self:close()
	if self.onCloseCancel then self.onCloseCancel() end
end
function CharacterCustomisationPanel_Ingame:close()
    self:setVisible(false)
    self:removeFromUIManager()
	if self.onClose then self.onClose() end
	
	if isClient() or isServer() then return end

    if UIManager.getSpeedControls() and UIManager.getSpeedControls():getCurrentGameSpeed() == 0 then
        UIManager.getSpeedControls():SetCurrentGameSpeed(1)
		UIManager.setShowPausedMessage(false)
    end
end


-- close menu when clicking outside of it (disabled)
function CharacterCustomisationPanel_Ingame:onMouseUp(x,y)
	if not self.canClose then return end
	
	if not (0 < x and 0 < y and x < self:getWidth() and y < self:getHeight()) then self:closeCancel() end
end

--when the player clicks an option in the menu we update the preview
function CharacterCustomisationPanel_Ingame:BodyDetailSelected()
	self:UpdatePreviewCustomisation()
end

--create temporary customisation items and then add them to the preview
function CharacterCustomisationPanel_Ingame:UpdatePreviewCustomisation()
	self.previewItems = {}
	
	local face = self.faceMenu:getSelectedOption()

	if face ~= nil and face.name ~= "DefaultFace" then
		local item = FaceManager_Shared.CreateItem(face.id, face.texture)
		table.insert(self.previewItems, item)
	end

	local selectedBodyDetails = self.bodyDetailMenu:getSelectedOptions()
	if selectedBodyDetails ~= nil then
		for i, v in pairs(selectedBodyDetails) do
			local item = FaceManager_Shared.CreateItem(v.id, v.texture)
			table.insert(self.previewItems, item)
		end
	end
	
	if self.otherPreviewItems ~= nil then
		for i, item in pairs(self.otherPreviewItems) do
			table.insert(self.previewItems, item)
		end
	end

	if self.muscleButton:isSelected() then
		table.insert(self.previewItems, self.musclePreviewItem)
	end

	--send the worn customisation items to the preview avatars
	self:setPreviewBodyDetails(self.previewItems)
end

--create and equip all the customisation to the player
function CharacterCustomisationPanel_Ingame:UpdatePlayerCustomisation()
	local data = {}

	data.face = _copyFaceOption(self.faceMenu:getSelectedOption())
	data.bodyDetails = _copyBodyDetailList(self.bodyDetailMenu:getSelectedOptions())
	data.muscleVisuals = self.muscleButton:isSelected()
	data.bodyHairGrowth = self.hairButton:isSelected()

	if _useLocalSingleplayerPath() then
		FaceManager_Local.SetCustomisation(self.char, data)
	else
		sendClientCommand(self.char, "SPNCC", "SetCustomisation", { data = data })
	end
end

--when the menu is opened we read the players mod data to set the selected customisation options
function CharacterCustomisationPanel_Ingame:SetPlayerCustomisationFromData()
	self.data = self.char:getModData().SPNCharCustom
	if not self.data then return end

	self.skintone = self.char:getHumanVisual():getSkinTextureIndex()

	self:GetPlayerCustomisationItems()

	self.data.face = _copyFaceOption(self.data.face)
	self.data.bodyDetails = _copyBodyDetailList(self.data.bodyDetails)

	local list = {}
	for _, detail in ipairs(self.data.bodyDetails) do
		if detail and detail.name then
			table.insert(list, detail.name)
		end
	end

	self.bodyDetailMenu:setSelectedOptions(list)
	self.faceMenu:setSelectedOption(self.data.face.name or "DefaultFace")

	self.muscleButton:setSelected(self.data.muscleVisuals ~= false)
	self.hairButton:setSelected(self.data.bodyHairGrowthEnabled == true)

	self.otherPreviewItems = {}
	if self.otherItems ~= nil then
		for _, v in pairs(self.otherItems) do
			if v then
				local item = FaceManager_Shared.CreateItem(v:getType(), v:getVisual():getBaseTexture())
				table.insert(self.otherPreviewItems, item)
			end
		end
	end

	self.musclePreviewItem = self:CreatePreviewMuscleItem()
	self:UpdatePreviewCustomisation()
end

-- grab the body hair to copy them onto the preview
function CharacterCustomisationPanel_Ingame:GetPlayerCustomisationItems()
	self.otherItems = {}
	--STUBBLE HEAD
	local item = FaceManager_Shared.GetWornItem(self.char, SPNCC.ItemBodyLocation.StubbleHead)
	table.insert(self.otherItems, item)

	--STUBBLE BEARD
	local item = FaceManager_Shared.GetWornItem(self.char, SPNCC.ItemBodyLocation.StubbleBeard)
	table.insert(self.otherItems, item)

	--BODY HAIR
	local item = FaceManager_Shared.GetWornItem(self.char, SPNCC.ItemBodyLocation.BodyHair)
	table.insert(self.otherItems, item)
end

function CharacterCustomisationPanel_Ingame:CreatePreviewMuscleItem()
	
	local muscleLevel = FaceManager_Shared.GetMuscleLevel(self.char:getPerkLevel(Perks.Strength))
	
	if muscleLevel <= 0 then return nil end

	local id = self.char:isFemale() and SPNCC_Data.Muscle[2] or SPNCC_Data.Muscle[1]
	
	local textureOffset = 0
	if muscleLevel == 2 then textureOffset = 5 end
	local texture = self.char:getHumanVisual():getSkinTextureIndex() + textureOffset
	
	local item = FaceManager_Shared.CreateItem(id, texture)

	return item
end


function CharacterCustomisationPanel_Ingame:FillCustomisationWindow()
	self:setFaceOptions(SPNCC_Data.GetFacesForCharacter(self.char))
	self:setBodyDetailOptions(SPNCC_Data.GetBodyDetailsForCharacter(self.char))
end
