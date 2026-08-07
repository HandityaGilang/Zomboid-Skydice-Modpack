--[[B42 COMPATIBILITY: ProfessionFactory.addProfession API unavailable in B42
local function createCrazyCatPersonProfession()
    local profession = ProfessionFactory.addProfession(
        "crazycatperson",
        getText("UI_prof_crazycatperson"),
        "prof_crazycatperson",
        -8
    )
    
    if profession then
        profession:setDescription(getText("UI_profdesc_crazycatperson"))
        profession:addXPBoost(Perks.Husbandry, 3)
        profession:addXPBoost(Perks.Nimble, 2)
        profession:addFreeTrait("CrazyCatPersonCatEyes")
    else
        print("[CATTOWO] ERROR: Failed to create profession")
    end
end

Events.OnGameBoot.Add(createCrazyCatPersonProfession)
--]]