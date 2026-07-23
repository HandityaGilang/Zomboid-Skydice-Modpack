local authenticZEnabled = getActivatedMods():contains('Authentic Z - Current') or getActivatedMods():contains('AuthenticZBackpacks+') or getActivatedMods():contains('AuthenticZLite') or getActivatedMods():contains('nattachments')

local scriptManager = getScriptManager()

local attachmentOverrides = {
    ['PompsItems_FNAF.PIMangleFigure'] = 'TeddyBear',
    ['PompsItems_FNAF.PIChicaCupcakePlushie'] = 'RubberDuck',
}

--don't worry... not an item tweaker derivative
local function doItemParams(type, ...)
    local item = scriptManager:getItem(type)
    if item then
        for _,param in ipairs({...}) do
            item:DoParam(param)
        end
    end
end

Events.OnInitGlobalModData.Add(function()
    local items = require 'PI_FNAFList'.getAllFNAF() -- evil syntax
    if authenticZEnabled then
        for _,type in ipairs(items) do
            local attachmentType = attachmentOverrides[type] or 'SpiffoPlushie'
            doItemParams(type, 'AttachmentType = '..attachmentType)
        end
    end
end)