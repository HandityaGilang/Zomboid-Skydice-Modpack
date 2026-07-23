if getActivatedMods():contains('\\DynamicTraits') and TrueSmoking.Options.UseNicotineSystem then
    function DTEMsmokerTrait(player)
        --print("DT Logger: running smokerTrait function");
        -- local currentTimeSinceLastSmoke = player:getTimeSinceLastSmoke();
        -- if currentTimeSinceLastSmoke == 10 then
        --     player:getModData().DTEMdaysSinceLastSmoke = player:getModData().DTEMdaysSinceLastSmoke + 1;
        --     if ZombRand(25) == 0 then
        --         player:getModData().DTEMdaysSinceLastSmoke = player:getModData().DTEMdaysSinceLastSmoke + DTEMluckyUnluckyModifier(player, 7);
        --     end
        -- else
        --     player:getModData().DTEMdaysSinceLastSmoke = player:getModData().DTEMdaysSinceLastSmoke - 5;
        --     if ZombRand(25) == 0 then
        --         player:getModData().DTEMdaysSinceLastSmoke = player:getModData().DTEMdaysSinceLastSmoke + DTEMluckyUnluckyModifier(player, 7);
        --     end
        -- end
        -- -- CHECK THE VALUE TO KEEP IT INTO THE LIMITS
        -- if player:getModData().DTEMdaysSinceLastSmoke < 0 then
        --     player:getModData().DTEMdaysSinceLastSmoke = 0;
        -- end
        -- -- CHECK IF THE PLAYER ACHIEVED THE REQUIREMENTS TO REMOVE SMOKER
        -- if player:getModData().DTEMdaysSinceLastSmoke >= 1080 then
        --     player:setTimeSinceLastSmoke(0);
        --     player:getStats():setStressFromCigarettes(0);
        --     player:getTraits():remove("Smoker");
        --     HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Smoker"), false, HaloTextHelper.getColorGreen());
        -- end
        --print("DT Logger: DTdaysSinceLastSmoke value is " .. player:getModData().DTEMdaysSinceLastSmoke);
        print('Overriding smokerTrait function from DTEMAddictions_Patch.lua');
end
end