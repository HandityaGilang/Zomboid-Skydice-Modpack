--[[
    CookingSync - Shared utilities (v7.2)

    Common functions used by both client and server components.

    v7.2: Simplified - back to basic item stat syncing without aggressive
          container manipulation that was interrupting cooking UI.
    v6.0: Server sync fix - using sendItemStats() for world containers
    v5.0: Updated for evolved recipe ingredient sync fix
]]

CookingSyncShared = CookingSyncShared or {}

---------------------------------------------------------------------------
-- COOKING APPLIANCE DETECTION
---------------------------------------------------------------------------

function CookingSyncShared.isCookingAppliance(obj)
    if not obj then return false end
    
    local ok, result = pcall(function()
        -- Check by class type first (fastest)
        if instanceof(obj, "IsoStove") then return true end
        if instanceof(obj, "IsoBarbecue") then return true end
        if instanceof(obj, "IsoFireplace") then return true end
        
        -- Fallback to sprite name check for modded appliances
        local sprite = obj:getSprite()
        if not sprite then return false end
        
        local name = sprite:getName()
        if not name then return false end
        
        local lname = string.lower(name)
        return string.find(lname, "stove") ~= nil or
               string.find(lname, "oven") ~= nil or
               string.find(lname, "campfire") ~= nil or
               string.find(lname, "firepit") ~= nil or
               string.find(lname, "barbecue") ~= nil or
               string.find(lname, "grill") ~= nil or
               string.find(lname, "smoker") ~= nil or
               string.find(lname, "fireplace") ~= nil
    end)
    
    return ok and result == true
end

---------------------------------------------------------------------------
-- APPLIANCE STATE CHECK
---------------------------------------------------------------------------

function CookingSyncShared.isApplianceActive(obj)
    if not obj then return false end
    
    local ok, result = pcall(function()
        -- Check container temperature (most reliable)
        local container = obj:getContainer()
        if container then
            local temp = container:getTemprature()
            if temp and temp > 0.1 then 
                return true 
            end
        end
        
        -- Check various activation states
        if obj.Activated then
            local activated = obj:Activated()
            if activated then return true end
        end
        
        if obj.isLit then
            local lit = obj:isLit()
            if lit then return true end
        end
        
        if obj.isSmouldering then
            local smouldering = obj:isSmouldering()
            if smouldering then return true end
        end
        
        return false
    end)
    
    return ok and result == true
end

