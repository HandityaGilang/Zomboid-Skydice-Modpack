TwisTonFire_MHP = TwisTonFire_MHP or {}

local MODID = "MiniHealthPlus"

local function TXT(key)
	if getText then
		local ok, value = pcall(getText, key)
		if ok and value then
			return value
		end
	end
	return key
end

local function normMod(id)
	return tostring(id or ""):lower():gsub("[_%-%s/\\]", "")
end

local function isModActive(wantId)
	local mods = getActivatedMods and getActivatedMods() or nil
	if not mods then
		return false
	end

	wantId = normMod(wantId)
	for i = 0, mods:size() - 1 do
		local raw = tostring(mods:get(i) or "")
		if normMod(raw) == wantId then
			return true
		end
	end

	return false
end

function TwisTonFire_MHP_IsBetterCharacterInfoActive()
	return isModActive("twistbettercharacterinfo")
end

local function getOpts()
	if not (PZAPI and PZAPI.ModOptions and PZAPI.ModOptions.getOptions) then
		return nil
	end
	return PZAPI.ModOptions:getOptions(MODID)
end

local function getBoolOption(key, defaultValue)
	local opts = getOpts()
	if opts then
		local opt = opts:getOption(key)
		if opt and opt.getValue then
			return opt:getValue() == true
		end
	end
	return defaultValue == true
end

function TwisTonFire_MHP_IsDisabled()
	return getBoolOption("DisableMod", false)
end

function TwisTonFire_MHP_ShouldOnlyShowTreatmentNeeded()
	return getBoolOption("OnlyShowTreatmentNeeded", false)
end

local function requestRefresh()
	if TwisTonFire_MHP_RequestFullRefresh then
		TwisTonFire_MHP_RequestFullRefresh()
	elseif MHP_RequestFullRefresh then
		MHP_RequestFullRefresh()
	end

	if TwisTonFire_MHP_RefreshModOptions then
		TwisTonFire_MHP_RefreshModOptions()
	end
end

local function attachOnChange(option)
	if not option then
		return
	end

	if option.setOnChange then
		option:setOnChange(requestRefresh)
	elseif option.onChange then
		option:onChange(requestRefresh)
	end
end

local function registerOptions()
	if TwisTonFire_MHP._gameOptionsRegistered then
		return
	end

	if not (PZAPI and PZAPI.ModOptions and PZAPI.ModOptions.create) then
		return
	end

	local options = PZAPI.ModOptions:create(MODID, TXT("UI_MHP_ModFullName"))
	if not options then
		print("[Mini Health Plus] Failed to create game ModOptions page.")
		return
	end

	local disableMod = options:addTickBox(
		"DisableMod",
		TXT("UI_MHP_DisableMod"),
		false,
		TXT("UI_MHP_DisableMod_TT")
	)

	local onlyShowTreatmentNeeded = options:addTickBox(
		"OnlyShowTreatmentNeeded",
		TXT("UI_MHP_OnlyShowTreatmentNeeded"),
		false,
		TXT("UI_MHP_OnlyShowTreatmentNeeded_TT")
	)

	attachOnChange(disableMod)
	attachOnChange(onlyShowTreatmentNeeded)

	TwisTonFire_MHP._gameOptionsRegistered = true
	print("[Mini Health Plus] Game ModOptions registered.")
end

registerOptions()

if Events and Events.OnGameBoot then
	Events.OnGameBoot.Add(registerOptions)
end

if Events and Events.OnMainMenuEnter then
	Events.OnMainMenuEnter.Add(registerOptions)
end