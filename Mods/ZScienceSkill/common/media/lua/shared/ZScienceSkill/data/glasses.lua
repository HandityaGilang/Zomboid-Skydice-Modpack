require "ZScienceSkill/Data"

local logger = zdk.Logger.new("ZScienceSkill")

local XP_BOOST_KEYWORDS = {
    "3D",
    "Bifocal",
    "Prescription",
    "Protect",
    "VR",
}

local function collectGlasses()
    local nAdded = 0
    local items = ScriptManager.instance:getAllItems()
    for i=0,items:size()-1 do
        local item = items:get(i)
        if item:getItemType() == ItemType.CLOTHING and item:getBodyLocation() == ItemBodyLocation.EYES then
            local dispName = item:getDisplayName()
            local fullType = item:getFullName()
            local xp = 5
    
            for _, keyword in ipairs(XP_BOOST_KEYWORDS) do
                if dispName:contains(keyword) then
                    xp = xp * 2
                    break
                end
            end

            ZScienceSkill.Data.add({ specimens = {
                [fullType] = { Science = xp, Glassmaking = xp },
            }})
            nAdded = nAdded + 1
        end
    end
    logger:info("added %d glasses types", nAdded)
end

Events.OnGameBoot.Add(collectGlasses)
