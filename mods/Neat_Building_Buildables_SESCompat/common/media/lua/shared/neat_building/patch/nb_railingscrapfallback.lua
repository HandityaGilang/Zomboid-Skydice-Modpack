-- NB_RailingScrapFallback.lua
-- Adds dismantle/scrap metadata to Neat Building railing sprites that
-- otherwise fall back to ISThumpableSpriteProps in B42.16.x.
--
-- In B42.16.1 the context-menu disassemble list is built from
-- ISMoveableSpriteProps.fromObject(), which requires craftValid to be set.
-- Some Neat Building railings were reaching the lightweight thumpable path,
-- so they could exist in-world but never appear in the disassemble menu.

local NB_RAILING_SPRITE_PATCHES = {
    -- Wooden railings
    ["fixtures_railings_01_24"]  = { Material = "Wood",      Material2 = "Nails",     CanScrap = true, DisplayNameKey = "NBEntityName_RawRailingFence" },
    ["fixtures_railings_01_25"]  = { Material = "Wood",      Material2 = "Nails",     CanScrap = true, DisplayNameKey = "NBEntityName_RawRailingFence" },
    ["fixtures_railings_01_27"]  = { Material = "Wood",      Material2 = "Nails",     CanScrap = true, DisplayNameKey = "NBEntityName_RawRailingFence" },
    ["fixtures_railings_01_64"]  = { Material = "Wood",      Material2 = "Nails",     CanScrap = true, DisplayNameKey = "NBEntityName_WhiteRailingFence" },
    ["fixtures_railings_01_65"]  = { Material = "Wood",      Material2 = "Nails",     CanScrap = true, DisplayNameKey = "NBEntityName_WhiteRailingFence" },
    ["fixtures_railings_01_67"]  = { Material = "Wood",      Material2 = "Nails",     CanScrap = true, DisplayNameKey = "NBEntityName_WhiteRailingFence" },
    ["fixtures_railings_01_88"]  = { Material = "Wood",      Material2 = "Nails",     CanScrap = true, DisplayNameKey = "NBEntityName_FancyBrownRailingFence" },
    ["fixtures_railings_01_89"]  = { Material = "Wood",      Material2 = "Nails",     CanScrap = true, DisplayNameKey = "NBEntityName_FancyBrownRailingFence" },
    ["fixtures_railings_01_91"]  = { Material = "Wood",      Material2 = "Nails",     CanScrap = true, DisplayNameKey = "NBEntityName_FancyBrownRailingFence" },
    ["fixtures_railings_01_128"] = { Material = "Wood",      Material2 = "Nails",     CanScrap = true, DisplayNameKey = "NBEntityName_FancyWhiteRailingFence" },
    ["fixtures_railings_01_129"] = { Material = "Wood",      Material2 = "Nails",     CanScrap = true, DisplayNameKey = "NBEntityName_FancyWhiteRailingFence" },
    ["fixtures_railings_01_131"] = { Material = "Wood",      Material2 = "Nails",     CanScrap = true, DisplayNameKey = "NBEntityName_FancyWhiteRailingFence" },

    -- Metal railings
    ["fixtures_railings_01_28"]  = { Material = "MetalBars", Material2 = "Wood",      CanScrap = true, DisplayNameKey = "NBEntityName_RailroadRailingFence" },
    ["fixtures_railings_01_29"]  = { Material = "MetalBars", Material2 = "Wood",      CanScrap = true, DisplayNameKey = "NBEntityName_RailroadRailingFence" },
    ["fixtures_railings_01_31"]  = { Material = "MetalBars", Material2 = "Wood",      CanScrap = true, DisplayNameKey = "NBEntityName_RailroadRailingFence" },
    ["fixtures_railings_01_36"]  = { Material = "MetalBars",                          CanScrap = true, DisplayNameKey = "NBEntityName_BlackMetalRailingFence" },
    ["fixtures_railings_01_37"]  = { Material = "MetalBars",                          CanScrap = true, DisplayNameKey = "NBEntityName_BlackMetalRailingFence" },
    ["fixtures_railings_01_39"]  = { Material = "MetalBars",                          CanScrap = true, DisplayNameKey = "NBEntityName_BlackMetalRailingFence" },
    ["fixtures_railings_01_48"]  = { Material = "MetalBars",                          CanScrap = true, DisplayNameKey = "NBEntityName_WhiteMetalRailingFence" },
    ["fixtures_railings_01_49"]  = { Material = "MetalBars",                          CanScrap = true, DisplayNameKey = "NBEntityName_WhiteMetalRailingFence" },
    ["fixtures_railings_01_50"]  = { Material = "MetalBars",                          CanScrap = true, DisplayNameKey = "NBEntityName_WhiteMetalRailingFence" },
    ["fixtures_railings_01_108"] = { Material = "MetalBars",                          CanScrap = true, DisplayNameKey = "NBEntityName_MixRailingFence" },
    ["fixtures_railings_01_109"] = { Material = "MetalBars",                          CanScrap = true, DisplayNameKey = "NBEntityName_MixRailingFence" },
    ["fixtures_railings_01_111"] = { Material = "MetalBars",                          CanScrap = true, DisplayNameKey = "NBEntityName_MixRailingFence" },

    -- Concrete / plaster railings
    ["walls_garage_02_20"]       = { Material = "Brick",     Material2 = "MetalBars", CanScrap = true, DisplayNameKey = "NBEntityName_RawConcreteRailingFence" },
    ["walls_garage_02_21"]       = { Material = "Brick",     Material2 = "MetalBars", CanScrap = true, DisplayNameKey = "NBEntityName_RawConcreteRailingFence" },
    ["walls_garage_02_23"]       = { Material = "Brick",     Material2 = "MetalBars", CanScrap = true, DisplayNameKey = "NBEntityName_RawConcreteRailingFence" },
    ["fixtures_railings_01_112"] = { Material = "Brick",     Material2 = "MetalBars", CanScrap = true, DisplayNameKey = "NBEntityName_WhiteConcreteRailingFence" },
    ["fixtures_railings_01_113"] = { Material = "Brick",     Material2 = "MetalBars", CanScrap = true, DisplayNameKey = "NBEntityName_WhiteConcreteRailingFence" },
    ["fixtures_railings_01_115"] = { Material = "Brick",     Material2 = "MetalBars", CanScrap = true, DisplayNameKey = "NBEntityName_WhiteConcreteRailingFence" },
    ["fixtures_railings_01_116"] = { Material = "Brick",     Material2 = "MetalBars", CanScrap = true, DisplayNameKey = "NBEntityName_BlackConcreteRailingFence" },
    ["fixtures_railings_01_117"] = { Material = "Brick",     Material2 = "MetalBars", CanScrap = true, DisplayNameKey = "NBEntityName_BlackConcreteRailingFence" },
    ["fixtures_railings_01_119"] = { Material = "Brick",     Material2 = "MetalBars", CanScrap = true, DisplayNameKey = "NBEntityName_BlackConcreteRailingFence" },
    ["location_shop_mall_01_24"] = { Material = "Glass",     Material2 = "Brick",     Material3 = "MetalBars", CanScrap = true, DisplayNameKey = "NBEntityName_GlassConcreteRailingFence" },
    ["location_shop_mall_01_25"] = { Material = "Glass",     Material2 = "Brick",     Material3 = "MetalBars", CanScrap = true, DisplayNameKey = "NBEntityName_GlassConcreteRailingFence" },
    ["location_shop_mall_01_27"] = { Material = "Glass",     Material2 = "Brick",     Material3 = "MetalBars", CanScrap = true, DisplayNameKey = "NBEntityName_GlassConcreteRailingFence" },

    -- Fancy plaster railing (name cleanup only, already scrap-valid in older builds)
    ["fencing_01_104"]           = { Material = "Brick",     CanScrap = true, DisplayNameKey = "NBEntityName_FancyPlasterRailingFence" },
    ["fencing_01_105"]           = { Material = "Brick",     CanScrap = true, DisplayNameKey = "NBEntityName_FancyPlasterRailingFence" },
    ["fencing_01_107"]           = { Material = "Brick",     CanScrap = true, DisplayNameKey = "NBEntityName_FancyPlasterRailingFence" },

    -- Simple farm wooden fence (name cleanup only, already scrap-valid)
    ["fencing_01_120"]           = { Material = "Wood",      Material2 = "Nails", CanScrap = true, DisplayNameKey = "NBEntityName_SimpleFarmWoodenFence" },
    ["fencing_01_121"]           = { Material = "Wood",      Material2 = "Nails", CanScrap = true, DisplayNameKey = "NBEntityName_SimpleFarmWoodenFence" },
    ["fencing_01_123"]           = { Material = "Wood",      Material2 = "Nails", CanScrap = true, DisplayNameKey = "NBEntityName_SimpleFarmWoodenFence" },
}

local NB_railingPatchState = {
    spritesPatched = false,
    moveableFromObjectPatched = false,
    moveableFromObjectForRepairPatched = false,
    thumpableNewPatched = false,
    thumpableCanScrapPatched = false,
}

local function NB_getRailingPatch(spriteName)
    if not spriteName then return nil end
    return NB_RAILING_SPRITE_PATCHES[spriteName]
end

local function NB_getValidScrapMaterial(materialName)
    if not materialName or not ISMoveableDefinitions or not ISMoveableDefinitions.getInstance then
        return nil
    end

    local moveDefs = ISMoveableDefinitions:getInstance()
    if moveDefs and moveDefs.isScrapDefinitionValid and moveDefs.isScrapDefinitionValid(materialName) then
        return materialName
    end

    return nil
end

local function NB_setSpriteProperty(props, propertyName, propertyValue)
    if not props or not propertyName then return false end

    -- B42.12 uses PropertyContainer:Set(...), while B42.13+ uses set(...).
    -- Always pass a textual value so the call works on both signatures.
    local setter = props.set or props.Set
    if not setter then
        return false
    end

    local valueText = propertyValue == true and "true" or tostring(propertyValue)
    setter(props, propertyName, valueText)
    return true
end

local function NB_applyPropertiesToSpriteObject(sprite, propertyTable)
    if not sprite or not propertyTable then return false end

    local props = sprite:getProperties()
    if not props then return false end

    for propertyName, propertyValue in pairs(propertyTable) do
        if propertyName ~= "DisplayNameKey" and propertyName ~= "DisplayNameText" and propertyValue ~= nil and propertyValue ~= false then
            NB_setSpriteProperty(props, propertyName, propertyValue)
        end
    end

    return true
end

local function NB_applyProperties(spriteName, propertyTable)
    local sprite = getSprite and getSprite(spriteName) or nil
    if not sprite then return false end
    return NB_applyPropertiesToSpriteObject(sprite, propertyTable)
end

local function NB_getLocalizedDisplayName(patch, object, fallbackName)
    local localizedName = nil

    if patch and patch.DisplayNameKey then
        if Translator and Translator.getRecipeName then
            localizedName = Translator.getRecipeName(patch.DisplayNameKey)
            if localizedName == patch.DisplayNameKey then
                localizedName = nil
            end
        end

        if not localizedName and getText then
            localizedName = getText(patch.DisplayNameKey)
            if localizedName == patch.DisplayNameKey then
                localizedName = nil
            end
        end
    end

    if not localizedName and fallbackName and fallbackName ~= "" and fallbackName ~= "Moveable object" and fallbackName ~= "Scrapable object" and fallbackName ~= "Disassemblable Object" then
        localizedName = fallbackName
    end

    if not localizedName and object and object.getName then
        local objectName = object:getName()
        if objectName and objectName ~= "" and objectName ~= "Moveable object" and objectName ~= "Scrapable object" and objectName ~= "Disassemblable Object" then
            localizedName = objectName
        end
    end

    return localizedName
end

local function NB_fillMovePropsFromPatch(moveProps, object, patch)
    if not moveProps or not object or not patch then
        return moveProps
    end

    local sprite = object:getSprite()
    local validMaterial = NB_getValidScrapMaterial(patch.Material)
    local localizedName = NB_getLocalizedDisplayName(patch, object, moveProps.name)

    moveProps.sprite = sprite
    moveProps.spriteName = sprite and sprite:getName() or moveProps.spriteName
    moveProps.isFromObject = true
    moveProps.object = object
    moveProps.material = patch.Material
    moveProps.material2 = patch.Material2
    moveProps.material3 = patch.Material3
    moveProps.canScrap = validMaterial ~= nil
    moveProps.scrapThumpable = moveProps.canScrap
    moveProps.scrapUseTool = true
    moveProps.scrapUseSkill = true
    moveProps.scrapSize = moveProps.scrapSize or "Medium"

    if localizedName then
        moveProps.name = localizedName
    elseif (not moveProps.name or moveProps.name == "Moveable object" or moveProps.name == "Scrapable object") and object:getName() and object:getName() ~= "" then
        moveProps.name = object:getName()
    end

    return moveProps
end

local function NB_buildFallbackMoveProps(object)
    if not object then return nil end

    local sprite = object:getSprite()
    local spriteName = sprite and sprite:getName() or nil
    local patch = NB_getRailingPatch(spriteName)
    if not patch then return nil end

    if sprite then
        NB_applyPropertiesToSpriteObject(sprite, patch)
    end

    local moveProps = ISMoveableSpriteProps.new(sprite)
    return NB_fillMovePropsFromPatch(moveProps, object, patch)
end

local function NB_patchRailingSprites()
    if NB_railingPatchState.spritesPatched then
        return
    end

    for spriteName, propertyTable in pairs(NB_RAILING_SPRITE_PATCHES) do
        NB_applyProperties(spriteName, propertyTable)
    end

    NB_railingPatchState.spritesPatched = true
end

local function NB_patchMoveableFromObject()
    if not ISMoveableSpriteProps or NB_railingPatchState.moveableFromObjectPatched then
        return
    end

    local oldFromObject = ISMoveableSpriteProps.fromObject
    if not oldFromObject then return end

    ISMoveableSpriteProps.fromObject = function(object)
        NB_patchRailingSprites()

        local moveProps = oldFromObject(object)
        local sprite = object and object:getSprite() or nil
        local spriteName = sprite and sprite:getName() or nil
        local patch = NB_getRailingPatch(spriteName)

        if patch and moveProps then
            moveProps = NB_fillMovePropsFromPatch(moveProps, object, patch)
        end

        if patch and (not moveProps or not moveProps.canScrap or not moveProps.material or moveProps.material == "Undefined") then
            local fallbackProps = NB_buildFallbackMoveProps(object)
            if fallbackProps and fallbackProps.canScrap then
                return fallbackProps
            end
        end

        return moveProps
    end

    NB_railingPatchState.moveableFromObjectPatched = true
end

local function NB_patchMoveableFromObjectForRepair()
    if not ISMoveableSpriteProps or NB_railingPatchState.moveableFromObjectForRepairPatched then
        return
    end

    local oldFromObjectForRepair = ISMoveableSpriteProps.fromObjectForRepair
    if not oldFromObjectForRepair then return end

    ISMoveableSpriteProps.fromObjectForRepair = function(object)
        NB_patchRailingSprites()

        local moveProps = oldFromObjectForRepair(object)
        local sprite = object and object:getSprite() or nil
        local spriteName = sprite and sprite:getName() or nil
        local patch = NB_getRailingPatch(spriteName)

        if patch and moveProps then
            moveProps = NB_fillMovePropsFromPatch(moveProps, object, patch)
        end

        if patch and (not moveProps or not moveProps.canScrap or not moveProps.material or moveProps.material == "Undefined") then
            local fallbackProps = NB_buildFallbackMoveProps(object)
            if fallbackProps and fallbackProps.canScrap then
                return fallbackProps
            end
        end

        return moveProps
    end

    NB_railingPatchState.moveableFromObjectForRepairPatched = true
end

local function NB_patchThumpableNew()
    if not ISThumpableSpriteProps or NB_railingPatchState.thumpableNewPatched then
        return
    end

    local oldNew = ISThumpableSpriteProps.new
    if not oldNew then return end

    ISThumpableSpriteProps.new = function(object)
        NB_patchRailingSprites()

        local props = oldNew(object)
        local spriteName = props and props.spriteName or nil
        local patch = NB_getRailingPatch(spriteName)
        if patch then
            return NB_fillMovePropsFromPatch(props, object, patch)
        end

        return props
    end

    NB_railingPatchState.thumpableNewPatched = true
end

local function NB_patchThumpableCanScrapObject()
    if not ISThumpableSpriteProps or NB_railingPatchState.thumpableCanScrapPatched then
        return
    end

    local oldCanScrapObject = ISThumpableSpriteProps.canScrapObject
    if not oldCanScrapObject then return end

    ISThumpableSpriteProps.canScrapObject = function(self, playerObj)
        local result, chance, perkName = oldCanScrapObject(self, playerObj)
        local patch = self and self.spriteName and NB_getRailingPatch(self.spriteName) or nil
        if patch then
            local craftValid = NB_getValidScrapMaterial(patch.Material) ~= nil
            local localizedName = NB_getLocalizedDisplayName(patch, self and self.object or nil, self and self.name or nil)
            result = result or {}
            result.craftValid = craftValid
            result.canScrap = result.canScrap and craftValid
            self.material = patch.Material
            self.material2 = patch.Material2
            self.material3 = patch.Material3
            self.canScrap = craftValid
            self.scrapThumpable = craftValid
            if localizedName then
                self.name = localizedName
            end
        end
        return result, chance, perkName
    end

    NB_railingPatchState.thumpableCanScrapPatched = true
end

local function NB_applyRailingScrapFallbackPatch()
    NB_patchRailingSprites()
    NB_patchMoveableFromObject()
    NB_patchMoveableFromObjectForRepair()
    NB_patchThumpableNew()
    NB_patchThumpableCanScrapObject()
end

NB_applyRailingScrapFallbackPatch()

if Events and Events.OnGameBoot then
    Events.OnGameBoot.Add(NB_applyRailingScrapFallbackPatch)
end
