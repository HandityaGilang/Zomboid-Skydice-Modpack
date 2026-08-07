AE_VirtualTracker = {}

local AE_DataService = require("AnimalsEssentials/DataServices/AE_DataService")

local virtualStates = {}

function AE_VirtualTracker.Initialize(animal, animalID)
    if not animal or not animalID then return false end
    
    virtualStates[animalID] = {
        inRender = false,
        virtualPosition = { x = 0, y = 0, z = 0 }
    }
    
    return true
end

function AE_VirtualTracker.UpdateRenderState(animal, animalID)
    if not animal or not animalID then return end
end

function AE_VirtualTracker.GetState(animalID)
    if not animalID then return nil end
    return virtualStates[animalID]
end

function AE_VirtualTracker.UpdateVirtualPosition(animalID, deltaSeconds)
    if not animalID then return end
end

function AE_VirtualTracker.SetVirtualTarget(animalID, targetX, targetY, speed)
    if not animalID then return end
end

function AE_VirtualTracker.MarkUpdated(animalID, tickCount)
    if not animalID then return end
end

function AE_VirtualTracker.Remove(animalID)
    if not animalID then return end
    virtualStates[animalID] = nil
end

function AE_VirtualTracker.GetStats()
    return {
        inRender = 0,
        outRender = 0
    }
end

_G.AE_VirtualTracker = AE_VirtualTracker

return AE_VirtualTracker