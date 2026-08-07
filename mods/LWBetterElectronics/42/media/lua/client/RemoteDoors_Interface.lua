require('keyBinding.lua');

local CUSTOM_SECTION = 'BetterElectronics';

local CUSTOM_KEYS = {    
	{ value = 'Toggle_Remote', key = 79 },
--	{ value = 'Toggle_Remote1', key = 80 },
--	{ value = 'Toggle_Remote2', key = 81 },	
}

local function injectKeys(sectionName, keys)
    keyBinding[#keyBinding + 1] = { value = string.format('[%s]', sectionName) };
    for i = 1, #keys do
        keyBinding[#keyBinding + 1] = keys[i];
    end
end


local function initKeyInjector()
    injectKeys(CUSTOM_SECTION, CUSTOM_KEYS);
end

Events.OnGameBoot.Add(initKeyInjector);