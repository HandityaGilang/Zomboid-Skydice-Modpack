local function EditRecipes()
    local recipeList = {

        ["PlaceInBox"] = {
            inputs = [[
			item 6 [Base.Candle;Base.Coldpack;Base.LightBulb;10:Base.FishingHook;12:Base.Scotchtape;12:Base.PillsAntiDep;12:Base.PillsBeta;12:Base.PillsSleepingTablets;12:Base.PillsVitamins;12:Base.Antibiotics;12:Base.Pills;12:Base.Bandage;12:Base.Battery;12:Base.CottonBalls;12:Base.DuctTape;12:Base.SutureNeedle;20:Base.TongueDepressor;24:Base.Bandaid;40:Base.Paperclip;100:Base.Nails;100:Base.Screws;100:Base.CapGunCap;12:Base.AlcoholBandage;12:Base.AlcoholedCottonBalls;12:Base.AlcoholWipes;12:Base.ElectricWire;12:Base.ElectronicsScrap;12:Base.MotionSensor;12:Base.RadioReceiver;12:Base.RadioTransmitter;12:Base.Receiver;12:Base.Amplifier;12:Base.Pager;12:Base.Remote;12:Base.NutsBolts;Base.Woodglue;12:Base.Soap2;12:Base.Epoxy;Base.FiberglassTape;12:Base.Glue;Base.WeldingRods;12:Base.Twine;12:Base.Buckle;12:Base.Button;Base.Pillow;Base.ToiletPaper;12:Base.Hinge;Base.Doorknob;12:Base.Sponge;12:Base.JarLid;12:Base.TimerCrafted;12:Base.TriggerCrafted;12:Base.Timer;12:Base.SmallHandle;12:Base.Thread_Aramid;12:Base.Thread_Sinew;Base.Hairspray2;12:Base.Sparklers;12:Base.SmallAnimalBone;12:Base.Aluminum;12:Base.Whetstone;12:Base.Zipties;12:Base.Fork;12:Base.Spoon;12:Base.ButterKnife;12:Base.Toothbrush] mappers[itemType] flags[AllowFavorite;InheritFavorite;IsExclusive;ItemCount],
        ]]
        },

        ["UnpackBox12"] = {
            inputs = [[
            item 1 [Base.AdhesiveTapeBox;Base.AntibioticsBox;Base.BandageBox;Base.BatteryBox;OCP.PillsBox;OCP.PillsAntiDepBox;OCP.PillsBetaBox;OCP.PillsSleepingTabletsBox;OCP.PillsVitaminsBox;Base.CottonBallsBox;Base.DuctTapeBox;Base.SutureNeedleBox;OCP.AlcoholBandageBox;OCP.AlcoholedCottonBallsBox;OCP.AlcoholWipesBox;OCP.ElectricWireBox;OCP.ElectronicsScrapBox;OCP.MotionSensorBox;OCP.RadioReceiverBox;OCP.RadioTransmitterBox;OCP.ReceiverBox;OCP.AmplifierBox;OCP.PagerBox;OCP.RemoteBox;OCP.NutsBoltsBox;OCP.Soap2Box;OCP.EpoxyBox;OCP.GlueBox;OCP.TwineBox;OCP.BuckleBox;OCP.ButtonBox;OCP.HingeBox;OCP.SpongeBox;OCP.JarLidBox;OCP.TimerCraftedBox;OCP.TriggerCraftedBox;OCP.TimerBox;OCP.SmallHandleBox;OCP.Thread_AramidBox;OCP.Thread_SinewBox;OCP.SmallAnimalBoneBox;OCP.SparklersBox;OCP.AluminumBox;OCP.WhetstoneBox;OCP.ZiptiesBox;OCP.ForkBox;OCP.SpoonBox;OCP.ButterKnifeBox;OCP.ToothbrushBox] mappers[itemType] flags[AllowFavorite;InheritFavorite],
        ]]
        },

        ["UnpackBox6"] = {
            inputs = [[
            item 1 [Base.CandleBox;OCP.ToiletPaperBox;Base.ColdpackBox;Base.LightBulbBox;OCP.WoodglueBox;OCP.WeldingRodsBox;OCP.PillowBox;OCP.FiberglassTapeBox;OCP.DoorknobBox;OCP.Hairspray2Box] mappers[itemType] flags[AllowFavorite;InheritFavorite],
        ]]
        },
    }

    for recipeName, recipeDef in pairs(recipeList) do
        local recipe = getScriptManager():getCraftRecipe(recipeName)

        if recipe then
            local wrappedScript = "{"

            if recipeDef.inputs then
                recipe:getInputs():clear()
                wrappedScript = wrappedScript .. " inputs { " .. recipeDef.inputs .. " }"
            end

            if recipeDef.outputs then
                recipe:getOutputs():clear()
                wrappedScript = wrappedScript .. " outputs { " .. recipeDef.outputs .. " }"
            end

            wrappedScript = wrappedScript .. " }"

            recipe:Load(recipeName, wrappedScript)
        end
    end
end

Events.OnInitWorld.Add(EditRecipes)