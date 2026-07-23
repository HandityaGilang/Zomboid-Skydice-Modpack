local SPNCC_Data = require("CharacterCustomisation/SPNCC_Data")
-- Main
CharacterCreationMain.spn_character_customisation_saved = "spncharcustom_saved_outfits.txt";


local OUTFIT_CHARACTER_CUSTOMISATION_FILE_VERSION = 1;

function CharacterCreationMain.readCharacterCustomisationSaveFile()
    local retVal = {};
    local saveFile = getFileReader(CharacterCreationMain.spn_character_customisation_saved, true);
    local version = 0;
    local line = saveFile:readLine();
    while line ~= nil do
        if luautils.stringStarts(line, "VERSION=") then
---@diagnostic disable-next-line: cast-local-type, undefined-field
            version = tonumber(string.split(line, "=")[2])
        elseif version == OUTFIT_CHARACTER_CUSTOMISATION_FILE_VERSION then
            local s = luautils.split(line, ":");
            retVal[s[1]] = s[2];
        end
        line = saveFile:readLine();
    end
    saveFile:close();

    return retVal;
end

function CharacterCreationMain.writeCharacterCustomisationSaveFile(options)
    local saveFile = getFileWriter(CharacterCreationMain.spn_character_customisation_saved, true, false); -- overwrite
    saveFile:write("VERSION="..tostring(OUTFIT_CHARACTER_CUSTOMISATION_FILE_VERSION).."\n")
    for key,val in pairs(options) do
        saveFile:write(key..":"..val.."\n");
    end
    saveFile:close();
end

local originalMainLoadOutfit = CharacterCreationMain.loadOutfit;
---@diagnostic disable-next-line: duplicate-set-field
function CharacterCreationMain:loadOutfit(box)
	originalMainLoadOutfit(self, box)

	local name = box and box.options and box.options[box.selected]
	if name == nil then return end

	local function getClientData()
		local ok, data = pcall(require, "CharacterCustomisation/CharacterCreation/StoredCharacterData")
		if ok and type(data) == "table" then
			return data
		end
		return nil
	end

	local useUI = self.characterCustomisationPanel
		and type(self.characterCustomisationPanel.setSelectedFace) == "function"
		and type(self.characterCustomisationPanel.clearSelectedBodyDetails) == "function"
		and type(self.characterCustomisationPanel.setSelectedBodyDetails) == "function"

	if useUI then
		self:spn_populate_customisation_window()
		self.characterCustomisationPanel:setSelectedFace("DefaultFace")
		self.characterCustomisationPanel:clearSelectedBodyDetails()
	else
		local clientData = getClientData()
		if clientData then
			clientData.face = { name = "DefaultFace", id = "DefaultFace", texture = 0 }
			clientData.bodyDetails = {}
		end
	end

	local saved_builds = CharacterCreationMain.readCharacterCustomisationSaveFile()
	local build = saved_builds[name]

	if build then
		local items = luautils.split(build, ";")
		for _, v in pairs(items) do
			local location = luautils.split(v, "=")
			local options = nil
			if location[2] then
				options = luautils.split(location[2], "|")
			end

			if location[1] == "face" then
				local faceName = options and options[1] or "DefaultFace"

				if useUI then
					self.characterCustomisationPanel:setSelectedFace(faceName)
				else
					local clientData = getClientData()
					if clientData then
						local faces = SPNCC_Data.GetFacesForCharacter(MainScreen.instance.desc)
						local f = faces and faces[faceName]
						if f and f.id and f.id ~= "" then
							clientData.face = { name = f.name, id = f.id, texture = f.texture or 0 }
						else
							clientData.face = { name = "DefaultFace", id = "DefaultFace", texture = 0 }
						end
					end
				end

			elseif location[1] == "bodyhair" then
				local chestHair = options and tonumber(options[1]) == 1 or false
				self.chestHairTickBox:setSelected(1, chestHair)

			elseif location[1] == "bodydetails" then
				local list = {}
				if options ~= nil then
					for _, name2 in pairs(options) do
						table.insert(list, name2)
					end
				end

				if useUI then
					self.characterCustomisationPanel:setSelectedBodyDetails(list)
				else
					local clientData = getClientData()
					if clientData then
						clientData.bodyDetails = {}
						local details = SPNCC_Data.GetBodyDetailsForCharacter(MainScreen.instance.desc)
						for _, detailName in ipairs(list) do
							local d = details and details[detailName]
							if d and d.id and d.id ~= "" then
								table.insert(clientData.bodyDetails, {
									name = d.name,
									id = d.id,
									texture = d.texture or 0,
								})
							end
						end
					end
				end
			end
		end
	end

	self:spn_update_character_customisation()
end

local originalMainSaveBuildStep2 = CharacterCreationMain.saveBuildStep2;
---@diagnostic disable-next-line: duplicate-set-field
function CharacterCreationMain.saveBuildStep2(self, button, joypadData, param2)
	originalMainSaveBuildStep2(self, button, joypadData, param2)

	local savename = button and button.parent and button.parent.entry and button.parent.entry:getText() or ""
	if savename == "" then return end

	local function getClientData()
		local ok, data = pcall(require, "CharacterCustomisation/CharacterCreation/StoredCharacterData")
		if ok and type(data) == "table" then
			return data
		end
		return nil
	end

	local faceName = "DefaultFace"
	local bodyDetailNames = {}

	if self.characterCustomisationPanel and self.characterCustomisationPanel.faceMenu and self.characterCustomisationPanel.bodyDetailMenu then
		local face = self.characterCustomisationPanel.faceMenu:getSelectedOption()
		if face and face.name then
			faceName = face.name
		end

		local list = self.characterCustomisationPanel.bodyDetailMenu:getSelectedOptionList()
		if list then
			for _, n in pairs(list) do
				if n and n ~= "" then
					table.insert(bodyDetailNames, n)
				end
			end
		end
	else
		local clientData = getClientData()
		if clientData and clientData.face and clientData.face.name then
			faceName = clientData.face.name
		end
		if clientData and clientData.bodyDetails then
			for _, v in ipairs(clientData.bodyDetails) do
				if v and v.name and v.name ~= "" then
					table.insert(bodyDetailNames, v.name)
				end
			end
		end
	end

	local builds = CharacterCreationMain.readCharacterCustomisationSaveFile()
	local savestring = ""

	savestring = savestring .. "face=" .. tostring(faceName) .. ";"
	savestring = savestring .. "bodyhair=" .. (self.chestHairTickBox:isSelected(1) and "1" or "2") .. ";"

	savestring = savestring .. "bodydetails="
	for i = 1, #bodyDetailNames do
		if i == 1 then
			savestring = savestring .. bodyDetailNames[i]
		else
			savestring = savestring .. "|" .. bodyDetailNames[i]
		end
	end
	savestring = savestring .. ";"

	builds[savename] = savestring
	CharacterCreationMain.writeCharacterCustomisationSaveFile(builds)
end

local originalMainDeleteBuildStep2 = CharacterCreationMain.deleteBuildStep2;
---@diagnostic disable-next-line: duplicate-set-field
function CharacterCreationMain.deleteBuildStep2(self, button, joypadData)
    originalMainDeleteBuildStep2(self, button, joypadData)
	
    local delBuild = self.savedBuilds.options[self.savedBuilds.selected]
    --if delBuild == '' then return end
	
    local builds = CharacterCreationMain.readCharacterCustomisationSaveFile()
	builds[delBuild] = nil
	
	CharacterCreationMain.writeCharacterCustomisationSaveFile(builds)
end
