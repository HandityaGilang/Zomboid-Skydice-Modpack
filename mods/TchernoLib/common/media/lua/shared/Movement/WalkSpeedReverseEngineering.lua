
local lcl = {}

lcl.player_base = __classmetatables[IsoPlayer.class].__index
lcl.player_setVariable          = lcl.player_base.setVariable
lcl.player_isRunning            = lcl.player_base.isRunning
lcl.player_isSprinting          = lcl.player_base.isSprinting
lcl.player_getPerkLevel         = lcl.player_base.getPerkLevel
lcl.player_getSlowFactor        = lcl.player_base.getSlowFactor
lcl.player_getBodyDamage        = lcl.player_base.getBodyDamage
lcl.player_isAiming             = lcl.player_base.isAiming
lcl.player_isInTreesNoBush      = lcl.player_base.isInTreesNoBush
lcl.player_getCurrentSquare     = lcl.player_base.getCurrentSquare
lcl.player_getTraits            = lcl.player_base.getTraits
lcl.player_getMoodles           = lcl.player_base.getMoodles
lcl.player_getWornItems         = lcl.player_base.getWornItems
lcl.player_getPrimaryHandItem   = lcl.player_base.getPrimaryHandItem
lcl.player_getSecondaryHandItem = lcl.player_base.getSecondaryHandItem

lcl.WornItems_base           = __classmetatables[WornItems.class].__index
lcl.WornItems_size           = lcl.WornItems_base.size
lcl.WornItems_getItemByIndex = lcl.WornItems_base.getItemByIndex
lcl.WornItems_getItem        = lcl.WornItems_base.getItem

lcl.InvItem_base                 = __classmetatables[InventoryItem.class].__index
lcl.InvItem_getCondition         = lcl.InvItem_base.getCondition
lcl.InvItem_getScriptItem        = lcl.InvItem_base.getScriptItem
lcl.InvItem_getFullType          = lcl.InvItem_base.getFullType

lcl.InvCont_base                 = __classmetatables[InventoryContainer.class].__index
lcl.InvCont_getContentsWeight    = lcl.InvCont_base.getContentsWeight
lcl.InvCont_getEffectiveCapacity = lcl.InvCont_base.getEffectiveCapacity


lcl.BodyDamage_base                 = __classmetatables[BodyDamage.class].__index
lcl.BodyDamage_getBodyPart          = lcl.BodyDamage_base.getBodyPart
lcl.BodyDamage_getThermoregulator   = lcl.BodyDamage_base.getThermoregulator


lcl.bp_base           = __classmetatables[BodyPart.class].__index
lcl.bp_haveBullet                 = lcl.bp_base.haveBullet
lcl.bp_getScratchSpeedModifier    = lcl.bp_base.getScratchSpeedModifier
lcl.bp_getCutSpeedModifier        = lcl.bp_base.getCutSpeedModifier
lcl.bp_getBurnSpeedModifier       = lcl.bp_base.getBurnSpeedModifier
lcl.bp_getDeepWoundSpeedModifier  = lcl.bp_base.getDeepWoundSpeedModifier
lcl.bp_getType                    = lcl.bp_base.getType
lcl.bp_getBurnTime                = lcl.bp_base.getBurnTime
lcl.bp_getBiteTime                = lcl.bp_base.getBiteTime
lcl.bp_deepWounded                = lcl.bp_base.deepWounded
lcl.bp_isSplint                   = lcl.bp_base.isSplint
lcl.bp_getFractureTime            = lcl.bp_base.getFractureTime
lcl.bp_haveGlass                  = lcl.bp_base.haveGlass
lcl.bp_bandaged                   = lcl.bp_base.bandaged
lcl.bp_getScratchTime             = lcl.bp_base.getScratchTime
lcl.bp_getCutTime                 = lcl.bp_base.getCutTime
lcl.bp_getDeepWoundTime           = lcl.bp_base.getDeepWoundTime
lcl.bp_getPain                    = lcl.bp_base.getPain
lcl.bp_HasInjury                  = lcl.bp_base.HasInjury
lcl.bp_getSplintFactor            = lcl.bp_base.getSplintFactor
lcl.bp_getAdditionalPain          = lcl.bp_base.getAdditionalPain


lcl.moodles_base       = __classmetatables[Moodles.class].__index
lcl.getMoodleLevel     = lcl.moodles_base.getMoodleLevel

lcl.tc_base            = __classmetatables[TraitCollection.class].__index
lcl.tc_contains        = lcl.tc_base.contains

lcl.Thermoregulator_base    = __classmetatables[Thermoregulator.class].__index
lcl.tr_getMovementModifier  = lcl.Thermoregulator_base.getMovementModifier

lcl.tree_base            = __classmetatables[IsoTree.class].__index
lcl.tree_getSlowFactor   = lcl.tree_base.getSlowFactor

lcl.sq_base       = __classmetatables[IsoGridSquare.class].__index
lcl.sq_Has        = lcl.sq_base.Has
lcl.sq_getTree    = lcl.sq_base.getTree

lcl.getAnimSpeedFix     = GameTime.getAnimSpeedFix
lcl.bpType2Index        = BodyPartType.ToIndex
lcl.bpIndex2Type        = BodyPartType.FromIndex
lcl.min = math.min
lcl.max = math.max
lcl.abs = math.abs



RE = RE or {}
function RE.calculateWalkSpeed(isoPlayer,args)
    
    --injury, (should be computed outside of and before that)
    local walkInjury = 0.0F
    if not (args and args.inhibitLimping) then
        walkInjury = RE.getFootInjurySpeedModifier(isoPlayer,args);
    end
    lcl.player_setVariable(isoPlayer, "WalkInjury", walkInjury);
    
    --walk
    local speed, fullSpeedMod = RE.calculateBaseSpeed(isoPlayer,args);
    if not lcl.player_isRunning(isoPlayer) and not lcl.player_isSprinting(isoPlayer) then
        speed = speed * RE.getShoesModifier(isoPlayer,args);
    else
        speed = speed - 0.15F;
        speed = speed * fullSpeedMod;
        speed = speed + lcl.player_getPerkLevel(isoPlayer, Perks.Sprinting) / 20.0F;
        speed = speed - lcl.abs(walkInjury / 1.5D);
        if getCore():getGameMode() == "Tutorial" or args and args.unimpeded then
           speed = lcl.max(1.0F, speed);--unimpeded movements
        end
    end

    --bullet time ?
    if lcl.player_getSlowFactor(isoPlayer) > 0.0F then
        speed = speed * 0.05F;
    end

    --saturation
    if not (args and args.noSaturateSpeed) then
        speed = lcl.min(1.0F, speed);--saturate speed at 1.0
    end
    
    --body temperature impact on speed
    local bd = lcl.player_getBodyDamage(isoPlayer)
    local tr = nil
    if bd then tr = lcl.BodyDamage_getThermoregulator(bd) end
    if tr and not (args and args.noTemperatureEffect) then
        speed = speed * lcl.tr_getMovementModifier(tr);
    end

    --strafe speed
    if lcl.player_isAiming(isoPlayer) then
        local strafeSpeed = 0.9F + lcl.player_getPerkLevel(isoPlayer, Perks.Nimble) / 10.0F
        if not (args and args.noNimbleCapOnStrafeSpeed) then
            strafeSpeed = lcl.min(strafeSpeed, args and args.maxSpeedForStrafeSpeed or 1.5F);--nimble effect on strafe speed saturates at level 6
        end
        
        local strafeSpeedGain = speed * 2.5F--speed gain on strafe speed
        if not (args and args.noSpeedCapOnStrafeSpeed) then
            strafeSpeedGain = lcl.min(strafeSpeedGain, args and args.maxSpeedForStrafeSpeed or 1.0F);--saturation of speed effect on strafe speed
        end
        strafeSpeed = strafeSpeed * strafeSpeedGain;--speed effect on strafe speed
        
        if not (args and args.noSaturateStrafeSpeed) then
            strafeSpeed = lcl.max(strafeSpeed, args and args.maxStrafeSpeed or 0.6F);--strafe speed saturation
        end
        lcl.player_setVariable(isoPlayer, "StrafeSpeed", strafeSpeed * lcl.getAnimSpeedFix());
    end

    --inTrees
    if not (args and args.noTreeSlowdown) and lcl.player_isInTreesNoBush(isoPlayer) then
        local currentSquare = lcl.player_getCurrentSquare(isoPlayer);
        if currentSquare and lcl.sq_Has(currentSquare, IsoObjectType.tree) then
           local tree = lcl.sq_getTree(currentSquare);
           if tree then
              speed = speed * lcl.tree_getSlowFactor(tree, isoPlayer);
           end
        end
    end

    return speed * lcl.getAnimSpeedFix();
end



-----------------------------------------------------
function RE.calculateBaseSpeed(isoPlayer, args)
    local moodles = lcl.player_getMoodles(isoPlayer)
    local bd      = lcl.player_getBodyDamage(isoPlayer)
    
    local baseSpeed = 0.8F;
    if moodles then
        if not (args and args.noEnduranceSlowdown) then
            baseSpeed = baseSpeed - lcl.getMoodleLevel(moodles, MoodleType.Endurance) * 0.15F;
        end
        if not (args and args.noHeavyLoadSlowdown) then
            baseSpeed = baseSpeed - lcl.getMoodleLevel(moodles, MoodleType.HeavyLoad) * 0.15F;
        end
    end

    local panicLevel = lcl.getMoodleLevel(moodles, MoodleType.Panic)
    if panicLevel >= 3 then
        local traits  = lcl.player_getTraits(isoPlayer)
        if traits and lcl.tc_contains(traits, "AdrenalineJunkie") then
            baseSpeed = baseSpeed + (panicLevel + 1) / 20.0F;
        end
    end

    for bpIt = lcl.bpType2Index(BodyPartType.Torso_Upper), lcl.bpType2Index(BodyPartType.Neck) do
        local bp = lcl.BodyDamage_getBodyPart(bd, lcl.bpIndex2Type(bpIt));
       if lcl.bp_HasInjury(bp) and not (args and args.noInjurySlowdown) then
            baseSpeed = baseSpeed - 0.1F;
        end

        if lcl.bp_bandaged(bp) and not (args and args.noBandageSpeedup) then
            baseSpeed = baseSpeed + 0.05F;--keep bandage from upper torso to neck ?
        end
    end

    --that specific upper leg left code is fishy
    if not (args and args.noUpperLeftLegPainSlowdown) then
        local upperLegLeftPartAdditionalPain = lcl.bp_getAdditionalPain(lcl.BodyDamage_getBodyPart(bd,BodyPartType.UpperLeg_L), true);
        if upperLegLeftPartAdditionalPain > 20.0F then
            baseSpeed = baseSpeed - (upperLegLeftPartAdditionalPain - 20.0F) / 100.0F;
        end
    end

    local runSpeed = 1.0F;
    local wornItems = lcl.player_getWornItems(isoPlayer)
    for itemIt=0, lcl.WornItems_size(wornItems)-1 do
        local inventoryItem = lcl.WornItems_getItemByIndex(wornItems,itemIt);
        local applyMod = true
        if args and args.restrictRunSpeedModifierByItemType then
            applyMod = RE.filterType(inventoryItem,args.restrictRunSpeedModifierByItemType)
        end
        if applyMod then
            runSpeed = runSpeed + RE.calcRunSpeedMod(inventoryItem, isoPlayer, args);
        end
    end
    
    local phItem = lcl.player_getPrimaryHandItem(isoPlayer)
    if phItem then
        local applyMod = true
        if args and args.restrictRunSpeedModifierByItemType then
            applyMod = RE.filterType(phItem,args.restrictRunSpeedModifierByItemType)
        end
        if applyMod then
            runSpeed = runSpeed + RE.calcRunSpeedMod(phItem, isoPlayer, args);
        end
    end

    local shItem = lcl.player_getSecondaryHandItem(isoPlayer)
    if shItem then
        local applyMod = true
        if args and args.restrictRunSpeedModifierByItemType then
            applyMod = RE.filterType(shItem,args.restrictRunSpeedModifierByItemType)
        end
        if applyMod then
            runSpeed = runSpeed + RE.calcRunSpeedMod(shItem, isoPlayer, args);
        end
    end

    local fullSpeedMod = RE.getShoesModifier(isoPlayer,args) + (runSpeed - 1.0F);
    return baseSpeed * (1.0F+fullSpeedMod) * (args and args.runSpeedModifierWalkGain or 0.5F), fullSpeedMod * (args and args.runSpeedModifierRunGain or 1.0F);--modif from vanilla here. I do accept fullSpeedMod > 1
end

-----------------------------------------------------
function RE.filterType(instance, filter)
    if not filter then return true end
    for it=1, #filter do
        if instanceof(instance,filter[it]) then
            return true
        end
    end
    if WalkSpeedTuning.Verbose then print('RE.filterType filter out '..lcl.InvItem_getFullType(instance)..' '..tab2str(filter)) end
    return false
end
-----------------------------------------------------
function RE.getRunSpeedModifier(inventoryItem)
    local runSpeedModifier = getPublicFieldValue(lcl.InvItem_getScriptItem(inventoryItem),'runSpeedModifier')
    if not runSpeedModifier or runSpeedModifier <=0 then
        print('Missing RunSpeedModifier for item '..lcl.InvItem_getFullType(inventoryItem))
        runSpeedModifier = 1.0F
    end
    return runSpeedModifier
end

function RE.calcRunSpeedMod(inventoryItem, isoPlayer, args)
    local speedMod = RE.getRunSpeedModifier(inventoryItem) - 1.0F;
    if instanceof(inventoryItem, 'InventoryContainer') then
        local contentWeight = lcl.InvCont_getContentsWeight(inventoryItem)
        local effectiveCapacity = lcl.InvCont_getEffectiveCapacity(inventoryItem, isoPlayer)
        local contentGain = contentWeight / effectiveCapacity;
        speedMod = speedMod * (1.0F + contentGain / 2.0F)
        if WalkSpeedTuning.Verbose then print('RE.calcRunSpeedMod '..lcl.InvItem_getFullType(inventoryItem)..' '..contentWeight..'/'..effectiveCapacity..' '..contentGain..' '..speedMod) end
    end
    if WalkSpeedTuning.Verbose and speedMod ~= 0 then print('RE.calcRunSpeedMod '..lcl.InvItem_getFullType(inventoryItem)..' '..speedMod) end
    return speedMod;
end

-----------------------------------------------------
function RE.getShoesModifier(isoPlayer,args)
    local wornItems = lcl.player_getWornItems(isoPlayer)
    local shoes = lcl.WornItems_getItem(wornItems,"Shoes");
    if (not shoes or lcl.InvItem_getCondition(shoes) == 0) then
        return 0.85F;
    else
        return 1.0F;
    end
end

-----------------------------------------------------
function RE.getFootInjurySpeedModifier(isoPlayer,args)--returns a side coef.
    local bd = lcl.player_getBodyDamage(isoPlayer)
    
    local bpCoef = 0.0F;
    local side1 = true;
    local coefSide1 = 0.0F;
    local coefSide2 = 0.0F;

    for bpIt = lcl.bpType2Index(BodyPartType.Groin), lcl.bpType2Index(BodyPartType.MAX)-1 do
        bpCoef = RE.calculateInjurySpeed(lcl.BodyDamage_getBodyPart(bd, lcl.bpIndex2Type(bpIt)), false, args);
        if side1 then
            coefSide1 = coefSide1 + bpCoef;
        else
            coefSide2 = coefSide2 + bpCoef;
        end
        side1 = not side1;
    end

    if coefSide1 > coefSide2 then
        return -(coefSide1 + coefSide2);
    else
        return coefSide1 + coefSide2;
    end
end

-----------------------------------------------------
function RE.calculateInjurySpeed(bodyPart, includePain, args)
    if args and args.noInjurySlowdown then return 0.0F end
    
    if lcl.bp_haveBullet(bodyPart) then
        return 1.0F;
    end
    
    local injurySpeed = 0.0F;
    local fractureTime = lcl.bp_getFractureTime(bodyPart)
    if fractureTime > 0.0F then
        injurySpeed = RE.calcFractureInjurySpeed(bodyPart, args);
    else
        local bpType     = lcl.bp_getType(bodyPart)
        local burnTime   = lcl.bp_getBurnTime(bodyPart)
        local biteTime   = lcl.bp_getBiteTime(bodyPart)
        local isSplint   = lcl.bp_isSplint(bodyPart)
        if (bpType == BodyPartType.Foot_L or bpType == BodyPartType.Foot_R)
          and (burnTime > 5.0F or biteTime > 0.0F or lcl.bp_deepWounded(bodyPart) or isSplint or lcl.bp_haveGlass(bodyPart)) then
            if lcl.bp_bandaged(bodyPart) then
                injurySpeed = 0.7F;
            else
                injurySpeed = 1.0F;
            end
        end
        local scratchTime = lcl.bp_getScratchTime(bodyPart)
        local cutTime = lcl.bp_getCutTime(bodyPart)
        local dwTime = lcl.bp_getDeepWoundTime(bodyPart)
        if (scratchTime > 2.0F or cutTime > 5.0F or burnTime > 0.0F or dwTime > 0.0F or isSplint or biteTime > 0.0F) then
            local scratchMod = lcl.bp_getScratchSpeedModifier(bodyPart);
            local cutMod     = lcl.bp_getCutSpeedModifier(bodyPart);
            local burnMod    = lcl.bp_getBurnSpeedModifier(bodyPart);
            local deepMod    = lcl.bp_getDeepWoundSpeedModifier(bodyPart);
            injurySpeed = injurySpeed + scratchTime / scratchMod + cutTime / cutMod + burnTime / burnMod + dwTime / deepMod + biteTime / 20.0F;
            if lcl.bp_bandaged(bodyPart) then--bandaging applied twice on feet part injury speed, that's probably an error.
                injurySpeed = injurySpeed / 2.0F;
            end
        end
    end

    if includePain then
        local pain = lcl.bp_getPain(bodyPart)
        if pain > 20.0F then
            injurySpeed = injurySpeed + pain / 10.0F;
        end
    end

    return injurySpeed;
end

-----------------------------------------------------
function RE.calcFractureInjurySpeed(bodyPart, args)
    local ft = lcl.bp_getFractureTime(bodyPart)
    local sf = lcl.bp_getSplintFactor(bodyPart)
    local fractureCoef = 0.4F;
    if ft > 20.0F then
        fractureCoef = 1.0F;
    elseif ft > 10.0F then
        fractureCoef = 0.7F;
    end

    if sf > 0.0F then
        fractureCoef = fractureCoef -0.2F;
        fractureCoef = fractureCoef - lcl.min(sf / 10.0F, 0.8F);
    end

    return lcl.max(0.0F, fractureCoef);
end


-------------------------------------------------
function RE.calculateIdleSpeed(isoPlayer,args)
    local speed = 0.01F
    if not (args and args.noHeavyBreath) then
        local moodles = lcl.player_getMoodles(isoPlayer)
        speed = speed + lcl.getMoodleLevel(moodles, MoodleType.Endurance) * 2.5D / 10.0D
    end
    return speed * lcl.getAnimSpeedFix();
end
