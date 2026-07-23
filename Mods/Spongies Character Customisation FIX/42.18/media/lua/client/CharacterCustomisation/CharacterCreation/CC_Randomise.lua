---@diagnostic disable: duplicate-set-field
require("CharacterCustomisation/CharacterCreation/CC_UpdateCharacterPreview")
local SPNCC_Data = require("CharacterCustomisation/SPNCC_Data")

local function spn_getClientData()
	local ok, data = pcall(require, "CharacterCustomisation/CharacterCreation/StoredCharacterData")
	if ok and type(data) == "table" then
		return data
	end
	return nil
end

local oldOnRandomCharacter = CharacterCreationMain.onRandomCharacter
function CharacterCreationMain:onRandomCharacter()
	oldOnRandomCharacter(self)

	if self.characterCustomisationPanel then
		self:spn_populate_customisation_window()
	end

	self:spn_randomise_face()
	self:spn_randomise_details()
	self:spn_update_character_customisation()
end

function CharacterCreationMain:spn_randomise_face()
	if not MainScreen.instance or not MainScreen.instance.desc then
		return
	end

	local desc = MainScreen.instance.desc
	local list = SPNCC_Data.GetFacesForCharacter(desc)

	local keys = {}
	for k, v in pairs(list) do
		if v and v.randomExcluded ~= true and v.locked ~= true then
			table.insert(keys, k)
		end
	end

	local chosenKey = "DefaultFace"
	if #keys > 0 then
		chosenKey = keys[ZombRand(#keys) + 1]
	end

	if self.characterCustomisationPanel and self.characterCustomisationPanel.faceMenu then
		self.characterCustomisationPanel.faceMenu:setSelectedOption(chosenKey)
		return
	end

	local clientData = spn_getClientData()
	if not clientData then return end

	local chosen = list[chosenKey]
	if not chosen or chosenKey == "DefaultFace" then
		clientData.face = { name = "DefaultFace", id = "DefaultFace", texture = 0 }
		return
	end

	clientData.face = { name = chosen.name, id = chosen.id, texture = chosen.texture or 0 }
end

function CharacterCreationMain:spn_randomise_details()
	if not MainScreen.instance or not MainScreen.instance.desc then
		return
	end

	local desc = MainScreen.instance.desc
	local list = SPNCC_Data.GetBodyDetailsForCharacter(desc)

	local keys = {}
	for k, v in pairs(list) do
		if v and v.randomExcluded ~= true and v.locked ~= true then
			table.insert(keys, k)
		end
	end

	local maxRolls = math.min(#keys, 3)
	local rolls = (maxRolls > 0) and ZombRand(0, maxRolls + 1) or 0

	local picked = {}
	local pickedKeys = {}

	for i = 1, rolls do
		local tries = 0
		while tries < 50 do
			tries = tries + 1
			local k = keys[ZombRand(#keys) + 1]
			if k and not picked[k] then
				picked[k] = true
				table.insert(pickedKeys, k)
				break
			end
		end
	end

	if self.characterCustomisationPanel and self.characterCustomisationPanel.bodyDetailMenu then
		self.characterCustomisationPanel.bodyDetailMenu:setSelectedOptions(pickedKeys)
		return
	end

	local clientData = spn_getClientData()
	if not clientData then return end

	local bodyDetails = {}
	for _, k in ipairs(pickedKeys) do
		local v = list[k]
		if v then
			table.insert(bodyDetails, {
				name = v.name,
				id = v.id,
				texture = v.texture or 0,
			})
		end
	end
	clientData.bodyDetails = bodyDetails
end