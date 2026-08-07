require 'WorldChat/WorldChat'

local defaultParam = {
            offsetIsoX       = 0,
            offsetIsoY       = 0,
            offsetIsoZ       = 0,
            offsetUIX        = 0,
            offsetUIY        = 0,
            offsetUIYPerLine = 15,
            font             = UIFont.Dialogue,
            r                = 1.0D,
            g                = 1.0D,
            b                = 1.0D,
            a                = 1.0D,
        }

function WorldChat.getDefaultParams(isoObject)
    if isoObject == nil then
        return defaultParam
    else
        local params = WorldChat.getDefaultParams(nil)
        WorldChat.overrideParams(params, WorldChat.computeClassParams(isoObject))
        return params
    end
end

function WorldChat.overrideParams(base, override)
    for key,value in pairs(override) do
        base[key] = value
    end
    return base
end

-- Overload (hook, following FWolf's guide) this function to add your own default params
function WorldChat.computeClassParams(isoObject)
    local params = {}
    local wc = nil
    local md = nil
    if isoObject and isoObject.getModData then
        md = isoObject:getModData()
        if md then wc = md.WorldChat end
    end
    if instanceof(isoObject, 'IsoGameCharacter') then
        if not wc then 
            md.WorldChat = {r=ZombRand(0,256)/255, g=ZombRand(0,256)/255, b=ZombRand(0,256)/255}--player color generated once and then saved in mod data
            wc = md.WorldChat
        end
        params = {offsetIsoZ=0.66, offsetUIY=-30}--player size
    end
    
    if wc then
        WorldChat.overrideParams(params, wc)
    end
    
    return params
end
