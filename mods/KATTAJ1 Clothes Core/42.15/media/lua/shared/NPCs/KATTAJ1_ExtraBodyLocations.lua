-- ============================================================================
-- KATTAJ1 Clothes Core – Body Locations
-- ============================================================================

require "NPCs/BodyLocations"

local group = BodyLocations.getGroup("Human")



    
    -- Belt
    group:getOrCreateLocation(KATTAJ1_BodyLocation.KATTAJ1_BeltLeft)
    group:getOrCreateLocation(KATTAJ1_BodyLocation.KATTAJ1_BeltRight)
    group:getOrCreateLocation(KATTAJ1_BodyLocation.KATTAJ1_BeltBackLeft)
    group:getOrCreateLocation(KATTAJ1_BodyLocation.KATTAJ1_BeltBackRight)

    -- Legs
    group:getOrCreateLocation(KATTAJ1_BodyLocation.KATTAJ1_UpperLegs)
    group:getOrCreateLocation(KATTAJ1_BodyLocation.KATTAJ1_LowerLegs)
    group:getOrCreateLocation(KATTAJ1_BodyLocation.KATTAJ1_Knees)

    -- Arms
    group:getOrCreateLocation(KATTAJ1_BodyLocation.KATTAJ1_UpperArms)
    group:getOrCreateLocation(KATTAJ1_BodyLocation.KATTAJ1_LowerArms)
    group:getOrCreateLocation(KATTAJ1_BodyLocation.KATTAJ1_Elbows)

    -- Back / Head
    group:getOrCreateLocation(KATTAJ1_BodyLocation.KATTAJ1_BackFanny)
    group:getOrCreateLocation(KATTAJ1_BodyLocation.KATTAJ1_Balaclava)
    group:getOrCreateLocation(KATTAJ1_BodyLocation.KATTAJ1_Headsets)
    group:getOrCreateLocation(KATTAJ1_BodyLocation.KATTAJ1_Mandible)

    -- Chest / Rig
    group:getOrCreateLocation(KATTAJ1_BodyLocation.KATTAJ1_ChestRig)

    -- Fanny packs
    group:getOrCreateLocation(KATTAJ1_BodyLocation.KATTAJ1_TacticalFannyPack)
    group:getOrCreateLocation(KATTAJ1_BodyLocation.KATTAJ1_TacticalFannyPackFront)

    -- Pants
    group:getOrCreateLocation(KATTAJ1_BodyLocation.KATTAJ1_SkinnyPants)

    -- Protection
    group:getOrCreateLocation(KATTAJ1_BodyLocation.KATTAJ1_ShoulderPads)
    group:getOrCreateLocation(KATTAJ1_BodyLocation.KATTAJ1_HipProtection)

    -- Torso Extra
    group:getOrCreateLocation(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraPelvic)
    group:getOrCreateLocation(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraShoulder)
    group:getOrCreateLocation(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraShoulderPelvic)
    group:getOrCreateLocation(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraFull)



    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TacticalFannyPack,ItemBodyLocation.FANNY_PACK_BACK)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TacticalFannyPackFront,ItemBodyLocation.FANNY_PACK_FRONT)

    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_Balaclava,ItemBodyLocation.MASK)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_Mandible,ItemBodyLocation.MASK_FULL)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_Mandible,ItemBodyLocation.FULL_HAT)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_Mandible,ItemBodyLocation.FULL_SUIT_HEAD)



    -- KATTAJ1_TorsoExtraPelvic
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraPelvic, KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraShoulder)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraPelvic, KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraShoulderPelvic)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraPelvic, KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraFull)

    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraPelvic, ItemBodyLocation.FULL_SUIT_HEAD)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraPelvic, ItemBodyLocation.FULL_SUIT)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraPelvic, ItemBodyLocation.FULL_TOP)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraPelvic, ItemBodyLocation.BOILERSUIT)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraPelvic, ItemBodyLocation.BATH_ROBE)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraPelvic, ItemBodyLocation.BODY_COSTUME)

    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraPelvic, ItemBodyLocation.TORSO_EXTRA_VEST)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraPelvic, ItemBodyLocation.TORSO_EXTRA)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraPelvic, ItemBodyLocation.TORSO_EXTRA_VEST_BULLET)


    -- KATTAJ1_TorsoExtraShoulder
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraShoulder, KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraPelvic)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraShoulder, KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraShoulderPelvic)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraShoulder, KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraFull)

    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraShoulder, ItemBodyLocation.SHOULDERPAD_RIGHT)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraShoulder, ItemBodyLocation.SHOULDERPAD_LEFT)

    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraShoulder, ItemBodyLocation.FULL_SUIT_HEAD)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraShoulder, ItemBodyLocation.FULL_SUIT)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraShoulder, ItemBodyLocation.FULL_TOP)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraShoulder, ItemBodyLocation.BOILERSUIT)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraShoulder, ItemBodyLocation.BATH_ROBE)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraShoulder, ItemBodyLocation.BODY_COSTUME)

    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraShoulder, ItemBodyLocation.TORSO_EXTRA_VEST)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraShoulder, ItemBodyLocation.TORSO_EXTRA)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraShoulder, ItemBodyLocation.TORSO_EXTRA_VEST_BULLET)


    -- KATTAJ1_TorsoExtraShoulderPelvic
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraShoulderPelvic, KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraShoulder)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraShoulderPelvic, KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraPelvic)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraShoulderPelvic, KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraFull)

    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraShoulderPelvic, ItemBodyLocation.SHOULDERPAD_RIGHT)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraShoulderPelvic, ItemBodyLocation.SHOULDERPAD_LEFT)

    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraShoulderPelvic, ItemBodyLocation.FULL_SUIT_HEAD)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraShoulderPelvic, ItemBodyLocation.FULL_SUIT)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraShoulderPelvic, ItemBodyLocation.FULL_TOP)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraShoulderPelvic, ItemBodyLocation.BOILERSUIT)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraShoulderPelvic, ItemBodyLocation.BATH_ROBE)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraShoulderPelvic, ItemBodyLocation.BODY_COSTUME)

    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraShoulderPelvic, ItemBodyLocation.TORSO_EXTRA_VEST)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraShoulderPelvic, ItemBodyLocation.TORSO_EXTRA)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraShoulderPelvic, ItemBodyLocation.TORSO_EXTRA_VEST_BULLET)


    -- KATTAJ1_TorsoExtraFull
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraFull, KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraPelvic)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraFull, KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraShoulder)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraFull, KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraShoulderPelvic)

    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraFull, ItemBodyLocation.SHOULDERPAD_RIGHT)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraFull, ItemBodyLocation.SHOULDERPAD_LEFT)

    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraFull, ItemBodyLocation.THIGH_RIGHT)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraFull, ItemBodyLocation.THIGH_LEFT)

    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraFull, ItemBodyLocation.FULL_SUIT_HEAD)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraFull, ItemBodyLocation.FULL_SUIT)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraFull, ItemBodyLocation.FULL_TOP)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraFull, ItemBodyLocation.BOILERSUIT)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraFull, ItemBodyLocation.BATH_ROBE)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraFull, ItemBodyLocation.BODY_COSTUME)

    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraFull, ItemBodyLocation.TORSO_EXTRA_VEST)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraFull, ItemBodyLocation.TORSO_EXTRA)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraFull, ItemBodyLocation.TORSO_EXTRA_VEST_BULLET)


    -- Hide Models
    group:setHideModel(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraPelvic,KATTAJ1_BodyLocation.KATTAJ1_TacticalFannyPackFront)
    group:setHideModel(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraShoulderPelvic,KATTAJ1_BodyLocation.KATTAJ1_TacticalFannyPackFront)
    group:setHideModel(KATTAJ1_BodyLocation.KATTAJ1_TorsoExtraFull,KATTAJ1_BodyLocation.KATTAJ1_TacticalFannyPackFront)


    -- Legs
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_UpperLegs, ItemBodyLocation.THIGH_RIGHT)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_UpperLegs, ItemBodyLocation.THIGH_LEFT)

    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_LowerLegs, ItemBodyLocation.KNEE_RIGHT)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_LowerLegs, ItemBodyLocation.KNEE_LEFT)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_LowerLegs, ItemBodyLocation.CALF_RIGHT)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_LowerLegs, ItemBodyLocation.CALF_LEFT)

    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_Knees, ItemBodyLocation.KNEE_RIGHT)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_Knees, ItemBodyLocation.KNEE_LEFT)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_Knees, KATTAJ1_BodyLocation.KATTAJ1_LowerLegs)



    -- Arms
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_UpperArms,ItemBodyLocation.SHOULDERPAD_LEFT)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_UpperArms,ItemBodyLocation.SHOULDERPAD_RIGHT)

    -- Lower Arms
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_LowerArms,ItemBodyLocation.ELBOW_LEFT)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_LowerArms,ItemBodyLocation.ELBOW_RIGHT)
    group:setExclusive( KATTAJ1_BodyLocation.KATTAJ1_LowerArms,ItemBodyLocation.FORE_ARM_LEFT)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_LowerArms,ItemBodyLocation.FORE_ARM_RIGHT)

    -- Elbows
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_Elbows,ItemBodyLocation.ELBOW_LEFT)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_Elbows,ItemBodyLocation.ELBOW_RIGHT)
    group:setExclusive(KATTAJ1_BodyLocation.KATTAJ1_Elbows,KATTAJ1_BodyLocation.KATTAJ1_LowerArms)
   