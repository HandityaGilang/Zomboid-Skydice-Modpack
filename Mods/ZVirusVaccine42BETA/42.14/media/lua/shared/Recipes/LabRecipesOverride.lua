-- LabRecipesOverride.lua
-- THIS FILE OVERRIDES THE INPUTS OF BONE-RELATED RECIPES TO INCLUDE THE NEW HUMAN BONE ITEMS FROM THE LAB.
-- REPLICATING THE RECIPES AND ADDING THE NEW ITEMS IN THE SCRIPT RATHER THAN USING LUA WOULD BE IDEAL FOR COMPATIBILITY WITH OTHER MODS THAT ALSO ALTER RECIPES, AVOIDING CONFLICTS.
-- HOWEVER, THIS WOULD IMPLY CREATING TOOLTIPS, NAMES, AND TRANSLATIONS FOR EACH RECIPE, IN ADDITION TO HAVING DUPLICATE RECIPES. SO IT'S BETTER TO JUST ALTER THE EXISTING ONES THIS WAY.

-- ============================
-- HELPER
-- ============================
local function patchRecipe(recipeName, newInputs)
    local recipe = getScriptManager():getCraftRecipe(recipeName)
    if not recipe then
        print("[ZVirusVaccine] WARNING: Recipe '" .. recipeName .. "' not found. It may have been renamed or removed by a game update. Skipping patch.")
        return
    end
    recipe:getInputs():clear()
    recipe:Load(recipeName, newInputs)
end

local function patchRecipeFull(recipeName, newBody) -- for recipes with itemMappers
    local recipe = getScriptManager():getCraftRecipe(recipeName)
    if not recipe then
        print("[PK42] WARNING: Recipe '" .. recipeName .. "' not found.")
        return
    end

    recipe:PreReload()

    recipe:Load(recipeName, newBody)
end

-- ============================
-- SHARPENLONGBONE
-- ============================
patchRecipe("SharpenLongBone", [[{ inputs { 
            item 1 tags[base:whetstone;base:file] mode:keep flags[MayDegradeLight],
            item 1 tags[base:saw;base:smallsaw;base:crudesaw;base:sharpknife;base:meatcleaver] mode:keep flags[MayDegradeLight],
            item 1 [Base.AnimalBone;Base.LargeAnimalBone;LabItems.LabRegularHumanBoneWP;LabItems.LabHumanBoneLargeWP] flags[Prop2;AllowDestroyedItem],
} }]])

-- ============================
-- SHARPENBONE
-- ============================
patchRecipe("SharpenBone", [[{ inputs { 
            item 1 tags[base:whetstone;base:file] mode:keep flags[MayDegradeLight],
            item 1 tags[base:saw;base:smallsaw;base:crudesaw;base:sharpknife;base:meatcleaver] mode:keep flags[MayDegradeLight],
            item 1 [Base.BoneBead_Large;Base.HatchetHead_Bone;Base.SharpBone_Long;Base.SmallAnimalBone;LabItems.LabSmallRandomHumanBones] flags[Prop2;AllowDestroyedItem],
} }]])

-- ============================
-- MAKEBONEFOREARMARMOR
-- ============================
patchRecipe("MakeBoneForearmArmor", [[{ inputs {
            item 5 [Base.SmallAnimalBone;LabItems.LabSmallRandomHumanBones] flags[Prop2],
            item 2 [Base.LeatherStrips] mode:destroy,
            item 1 tags[base:sharpknife] mode:keep flags[IsNotDull;MayDegradeLight],
            item 1 [Base.Twine],
            item 1 tags[base:awl] mode:keep flags[MayDegradeLight;Prop1],
} }]])

-- ============================
-- MAKELARGEBONEBEADS
-- ============================
patchRecipe("MakeLargeBoneBeads", [[{ inputs {
            item 1 tags[base:sharpknife;base:meatcleaver] mode:keep flags[MayDegradeLight;IsNotDull],
            item 1 tags[base:whetstone;base:file] mode:keep flags[MayDegradeLight],
            item 1 [Base.AnimalBone;Base.LargeAnimalBone;Base.JawboneBovide;LabItems.LabRegularHumanBoneWP;LabItems.LabHumanBoneLargeWP] flags[AllowDestroyedItem],
            item 1 tags[base:drillwood;base:drillmetal;base:drillwoodpoor] mode:keep flags[MayDegradeLight],
} }]])

-- ============================
-- MAKELARGEBONEBEAD
-- ============================
patchRecipe("MakeLargeBoneBead", [[{ inputs {
            item 1 tags[base:drillwood;base:drillmetal;base:drillwoodpoor] mode:keep flags[MayDegradeLight],
            item 1 tags[base:sharpknife;base:meatcleaver] mode:keep flags[MayDegradeLight;IsNotDull],
            item 1 [Base.SmallAnimalBone;LabItems.LabSmallRandomHumanBones;Base.SharpBone_Long] flags[AllowDestroyedItem],
} }]])

-- ============================
-- MAKEBONEMASK
-- ============================
patchRecipe("MakeBoneMask", [[{ inputs {
            item 6 [Base.SmallAnimalBone;LabItems.LabSmallRandomHumanBones] flags[Prop2],
            item 1 [Base.LeatherStrips] mode:destroy,
            item 1 tags[base:sharpknife] mode:keep flags[IsNotDull;MayDegradeLight],
            item 1 [Base.Twine],
            item 1 tags[base:awl] mode:keep flags[MayDegradeLight;Prop1],
} }]])

-- ============================
-- MAKEBONEPECTORAL
-- ============================
patchRecipe("MakeBonePectoral", [[{ inputs {
            item 6 [Base.SmallAnimalBone;LabItems.LabSmallRandomHumanBones] flags[Prop2],
            item 2 [Base.LeatherStrips] mode:destroy,
            item 1 tags[base:sharpknife] mode:keep flags[IsNotDull;MayDegradeLight],
            item 1 [Base.Twine],
            item 1 tags[base:awl] mode:keep flags[MayDegradeLight;Prop1],
} }]])

-- ============================
-- MAKEBONESHINARMOR
-- ============================
patchRecipe("MakeBoneShinArmor", [[{ inputs {
            item 3 [Base.AnimalBone;LabItems.LabRegularHumanBoneWP] flags[Prop2],
            item 2 [Base.LeatherStrips] mode:destroy,
            item 1 tags[base:sharpknife] mode:keep flags[IsNotDull;MayDegradeLight;Prop1],
            item 1 tags[base:saw;base:smallsaw;base:crudesaw] mode:keep flags[MayDegradeLight],
            item 1 [Base.Twine],
            item 1 tags[base:awl] mode:keep flags[MayDegradeLight],
} }]])

-- ============================
-- MAKEBONESHOULDERARMOR
-- ============================
patchRecipe("MakeBoneShoulderArmor", [[{ inputs {
            item 5 [Base.SmallAnimalBone;LabItems.LabSmallRandomHumanBones] flags[Prop2],
            item 2 [Base.LeatherStrips] mode:destroy,
            item 1 tags[base:sharpknife] mode:keep flags[IsNotDull;MayDegradeLight],
            item 1 [Base.Twine],
            item 1 tags[base:awl] mode:keep flags[MayDegradeLight;Prop1],
} }]])

-- ============================
-- MAKEBONETHIGHARMOR
-- ============================
patchRecipe("MakeBoneThighArmor", [[{ inputs {
            item 3 [Base.AnimalBone;LabItems.LabRegularHumanBoneWP] flags[Prop2],
            item 2 [Base.LeatherStrips] mode:destroy,
            item 1 tags[base:sharpknife] mode:keep flags[IsNotDull;MayDegradeLight;Prop1],
            item 1 tags[base:saw;base:smallsaw;base:crudesaw] mode:keep flags[MayDegradeLight],
            item 1 [Base.Twine],
            item 1 tags[base:awl] mode:keep flags[MayDegradeLight],
} }]])

-- ============================
-- MAKEBONEARMOREDGLOVES
-- ============================
patchRecipe("MakeBoneArmoredGloves", [[{ inputs {
            item 4 [Base.SmallAnimalBone;LabItems.LabSmallRandomHumanBones] flags[Prop2],
            item 1 [Base.Gloves_FingerlessGloves;Base.Gloves_FingerlessLeatherGloves;Base.Gloves_FingerlessLeatherGloves_Black;Base.Gloves_FingerlessLeatherGloves_Brown;Base.Gloves_LeatherGloves;Base.Gloves_LeatherGlovesBlack;Base.Gloves_LeatherGlovesBrown],
            item 1 tags[base:sharpknife] mode:keep flags[IsNotDull;MayDegradeLight],
            item 1 [Base.Twine],
            item 1 tags[base:awl] mode:keep flags[MayDegradeLight;Prop1],
} }]])

-- ============================
-- MAKEBONEHATCHETHEAD
-- ============================
patchRecipe("MakeBoneHatchetHead", [[{ inputs {
            item 1 tags[base:saw;base:smallsaw;base:crudesaw;base:sharpknife;base:meatcleaver] mode:keep flags[MayDegradeLight],
            item 1 [Base.JawboneBovide;Base.LargeAnimalBone;LabItems.LabHumanBoneLargeWP] flags[Prop2],
            item 1 tags[base:whetstone;base:file] mode:keep flags[MayDegradeLight],
} }]])

-- ============================
-- CARVEFLESHINGTOOL
-- ============================
patchRecipe("CarveFleshingTool", [[{ inputs {
            item 1 tags[base:sharpknife;base:meatcleaver;base:saw;base:smallsaw;base:crudesaw] mode:keep flags[MayDegrade;IsNotDull],
            item 1 [Base.AnimalBone;Base.LargeAnimalBone;LabItems.LabHumanBoneLargeWP;LabItems.LabRegularHumanBoneWP] flags[InheritCondition],
} }]])

-- ============================
-- CARVEWHISTLE
-- ============================
patchRecipe("CarveWhistle", [[{ inputs {
            item 1 tags[base:drillwood;base:drillmetal;base:drillwoodpoor] mode:keep flags[MayDegradeLight],
            item 1 tags[base:sharpknife] mode:keep flags[MayDegradeLight],
            item 1 [Base.SmallAnimalBone;LabItems.LabSmallRandomHumanBones] flags[Prop2;AllowDestroyedItem],
} }]])

-- ============================
-- MAKETOOTHNECKLACE
-- ============================
patchRecipe("MakeToothNecklace", [[{ inputs {
            item 1 tags[base:drillwood;base:drillmetal;base:drillwoodpoor] mode:keep flags[MayDegradeLight;Prop1],
            item 2 [Base.HerbivoreTeeth;LabItems.LabHumanTeeth] flags[Prop2],
            item 1 [Base.Twine],
} }]])

-- ============================
-- MAKELONGTOOTHNECKLACE
-- ============================
patchRecipe("MakeLongToothNecklace", [[{ inputs {
            item 1 tags[base:drillwood;base:drillmetal;base:drillwoodpoor] mode:keep flags[MayDegradeLight;Prop1],
            item 3 [Base.HerbivoreTeeth;LabItems.LabHumanTeeth] flags[Prop2],
            item 2 [Base.Twine],
} }]])

-- ============================
-- SMASHBONE
-- ============================
patchRecipe("SmashBone", [[{ inputs {
            item 1 tags[base:hammer;base:sledgehammer;base:clubhammer;base:hammerstone] mode:keep flags[Prop1;MayDegradeLight],
            item 1 [Base.AnimalBone;Base.LargeAnimalBone;LabItems.LabHumanBoneLargeWP;LabItems.LabRegularHumanBoneWP] flags[Prop2;AllowDestroyedItem],
} }]])

-- ============================
-- MAKEBONECLUB
-- ============================
patchRecipeFull("MakeBoneClub", [[{
    time = 200,
    Tags = AnySurfaceCraft,
    category = Weaponry,
    xpAward = Maintenance:10,
    SkillRequired = Maintenance:1,
    NeedToBeLearn = true,
    timedAction = CraftWeapon1H,
    AutoLearnAll = Maintenance:3;SmallBlunt:1,
    inputs
    {
        item 1 [Base.AnimalBone;Base.LargeAnimalBone;LabItems.LabRegularHumanBoneWP;LabItems.LabHumanBoneLargeWP] mappers[ClubMapper] flags[Prop2;InheritCondition],
        item 2 [Base.LeatherStrips],
    }
    outputs
    {
        item 1 mapper:ClubMapper,
    }
    itemMapper ClubMapper
    {
        Base.BoneClub = Base.AnimalBone,
        Base.LargeBoneClub = Base.LargeAnimalBone,
        Base.BoneClub = LabItems.LabRegularHumanBoneWP,
        Base.LargeBoneClub = LabItems.LabHumanBoneLargeWP,
        default = Base.LargeBoneClub,
    }
}]])

-- ============================
-- MAKESCRAPMORNINGSTAR
-- ============================
patchRecipeFull("MakeScrapMorningstar", [[{
    time = 600,
    Tags = AnySurfaceCraft,
    NeedToBeLearn = false,
    SkillRequired = MetalWelding:7,
    timedAction = Welding_Surface,
    xpAward = MetalWelding:70,
    category = Weaponry,
    inputs
    {
        item 1 [Base.AnimalBone;Base.BoneClub;Base.LargeAnimalBone;Base.LargeBoneClub;LabItems.LabRegularHumanBoneWP;LabItems.LabHumanBoneLargeWP;Base.MetalBar;Base.MetalPipe;Base.MetalPipe_Broken;Base.SteelRodHalf] mappers[HandleMapper] flags[Prop2;InheritCondition],
        item 8 [Base.BlowTorch],
        item 1 tags[base:weldingmask] mode:keep,
        item 1 tags[base:sheetmetalsnips;base:metalsaw] mode:keep flags[Prop1;MayDegradeLight],
        item 1 [Base.SmallSheetMetal],
        item 1 [Base.RippedSheets;Base.DenimStrips;Base.LeatherStrips] mode:destroy,
    }
    outputs
    {
        item 1 mapper:HandleMapper,
    }
    itemMapper HandleMapper
    {
        Base.BoneClub_Spiked = Base.AnimalBone,
        Base.BoneClub_Spiked = Base.BoneClub,
        Base.LargeBoneClub_Spiked = Base.LargeAnimalBone,
        Base.LargeBoneClub_Spiked = Base.LargeBoneClub,
        Base.BoneClub_Spiked = LabItems.LabRegularHumanBoneWP,
        Base.LargeBoneClub_Spiked = LabItems.LabHumanBoneLargeWP,
        Base.Morningstar_Scrap = Base.MetalBar,
        Base.Morningstar_Scrap = Base.MetalPipe,
        Base.Morningstar_Scrap_Short = Base.MetalPipe_Broken,
        Base.Morningstar_Scrap_Short = Base.SteelRodHalf,
        default = Base.Morningstar_Scrap,
    }
}]])

-- ============================
-- MAKESPIKEDCLUB
-- ============================
patchRecipeFull("MakeSpikedClub", [[{
    
    time = 500,
    SkillRequired = Blacksmith:5,
    NeedToBeLearn = true,
    AutoLearnAll = Blacksmith:8,
    timedAction = HammerMetalStanding,
    xpAward = Blacksmith:50,
    Tags = Forge,
    category = Weaponry,
    inputs
    {
        item 4 tags[base:charcoal],
        item 1 [Base.IronBandSmall],
        item 5 tags[base:metalpiece],
        item 1 tags[base:smithinghammer] mode:keep flags[Prop1;MayDegradeLight],
        item 1 tags[base:tongs] mode:keep flags[Prop2;MayDegradeLight],
        item 1 tags[base:metalworkingpunch] mode:keep flags[MayDegradeLight],
        item 1 [Base.AnimalBone;Base.BoneClub;Base.LargeAnimalBone;LabItems.LabRegularHumanBoneWP;LabItems.LabHumanBoneLargeWP;Base.LargeBoneClub;Base.LongHandle;Base.ShortBat] flags[InheritCondition] mappers[ClubMapper],
    }
    outputs
    {
        item 1 mapper:ClubMapper,
    }
    itemMapper ClubMapper
    {
        Base.BoneClub_Spiked = Base.AnimalBone,
        Base.BoneClub_Spiked = Base.BoneClub,
        Base.BoneClub_Spiked = LabItems.LabRegularHumanBoneWP,
        Base.LargeBoneClub_Spiked = Base.LargeAnimalBone,
        Base.LargeBoneClub_Spiked = Base.LargeBoneClub,
        Base.LargeBoneClub_Spiked = LabItems.LabHumanBoneLargeWP,
        Base.SpikedShortBat = Base.ShortBat,
        Base.LongSpikedClub = Base.LongHandle,
        default = Base.SpikedShortBat,
    }
}]])