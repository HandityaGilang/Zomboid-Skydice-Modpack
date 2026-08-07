local TABAS_BathTransformDefs = {}

local TABAS_Sprites = require("TABAS_Sprites")

TABAS_BathTransformDefs.TUB_MODE = {
        INSTALL = "install",
        UNINSTALL = "uninstall",
        DISASSEMBLE = "disassemble",
        CLEAN = "clean",
}

TABAS_BathTransformDefs.SHOWER_MODE = {
    UPGRADE = "upgrade",
    UNINSTALL = "uninstall",
    IMPROVE = "improve",
}

TABAS_BathTransformDefs.Bathtub = {
    install = {
        textKey = "ContextMenu_TABAS_InstallShower",
        tooltipKey = "ContextMenu_TABAS_InstallShower_tooltip",
        toolTag = ItemTag.PIPE_WRENCH,
        actionAnim = "Loot",
        sound = "RepairWithWrench",
        jobTypeKey = "ContextMenu_TABAS_InstallShower",
        duration = 400,
        metabolicTarget = Metabolics.HeavyWork,
        dirtyUI = true,
        skills = {["Woodwork"] = 3},
        targetByModel = {
            ["Improved Large Deluxe"] = "Large Deluxe",
            ["Improved Large Deluxe Clean"] = "Large Deluxe Clean",
        },
    },
    uninstall = {
        textKey = "ContextMenu_TABAS_UninstallShower",
        tooltipKey = "ContextMenu_TABAS_UninstallShower_tooltip",
        toolTag = ItemTag.PIPE_WRENCH,
        actionAnim = "Loot",
        sound = "RepairWithWrench",
        duration = 400,
        metabolicTarget = Metabolics.HeavyWork,
        dirtyUI = true,
        skills = {["Woodwork"] = 3},
        targetByModel = {
            ["Large Deluxe"] = "Improved Large Deluxe",
            ["Large Deluxe Clean"] = "Improved Large Deluxe Clean",
        },
    },
    disassemble = {
        textKey = "ContextMenu_TABAS_DisassembleShower",
        tooltipKey = "ContextMenu_TABAS_DisassembleShower_tooltip",
        toolTag = ItemTag.PIPE_WRENCH,
        actionAnim = "Loot",
        sound = "RepairWithWrench",
        duration = 400,
        metabolicTarget = Metabolics.HeavyWork,
        dirtyUI = false,
        skills = {["Woodwork"] = 3, ["MetalWelding"] = 1},
        targetByModel = {
            ["Large Deluxe"] = "Improved Large Deluxe",
            ["Large Deluxe Clean"] = "Improved Large Deluxe Clean",
        },
    },
    clean = {
        textKey = "ContextMenu_TABAS_CleanTub",
        tooltipKey = "ContextMenu_TABAS_CleanTub_tooltip",
        icon = "media/ui/Icons/tabas_cleantub.png",
        actionAnim = "ScrubFloor",
        sound = "CleanBloodBleach",
        jobTypeKey = "ContextMenu_TABAS_CleanTub",
        duration = 500,
        metabolicTarget = Metabolics.LightWork,
        dirtyUI = true,
        targetByModel = {
            ["Large Deluxe"] = "Large Deluxe Clean",
            ["Improved Large Deluxe"] = "Improved Large Deluxe Clean",
        },
    },
}

TABAS_BathTransformDefs.Shower = {
    upgrade = {
        textKey = "ContextMenu_TABAS_UpgradeShower",
        tooltipKey = "ContextMenu_TABAS_UpgradeShower_tooltip",
        toolTag = ItemTag.HAMMER,
        actionAnim = "BuildLow",
        jobTypeKey = "ContextMenu_TABAS_UpgradeShower",
        duration = 400,
        metabolicTarget = Metabolics.HeavyWork,
        dirtyUI = true,
        skills = {["Woodwork"] = 3},
        targetByModel = {
            ["Wall"] = "Improved Deluxe",
        },
    },
    uninstall = {
        textKey = "ContextMenu_TABAS_UninstallShower",
        tooltipKey = "ContextMenu_TABAS_UninstallShower_tooltip2",
        toolTag = ItemTag.PIPE_WRENCH,
        actionAnim = "Loot",
        sound = "RepairWithWrench",
        duration = 400,
        metabolicTarget = Metabolics.HeavyWork,
        dirtyUI = true,
        skills = {["Woodwork"] = 3},
        targetByModel = {},
    },
    improve = {
        textKey = "ContextMenu_TABAS_ImproveShower",
        tooltipKey = "ContextMenu_TABAS_ImproveShower_tooltip",
        toolTag = ItemTag.SAW,
        actionAnim = "SawLog",
        sound = "Sawing",
        duration = 400,
        metabolicTarget = Metabolics.HeavyWork,
        dirtyUI = false,
        skills = {["Woodwork"] = 1},
        targetByModel = {
            ["Deluxe"] = "Improved Deluxe",
        },
    },
    revert = {
        targetByModel = {
            ["Improved Deluxe"] = "Deluxe",
        },
    },
}

local function getCurrentDef(objectType, modelTypeOrDef)
    if type(modelTypeOrDef) == "table" then
        return modelTypeOrDef
    end
    local defs = TABAS_Sprites[objectType]
    return defs and defs[modelTypeOrDef] or nil
end

local function getModeDef(objectType, mode)
    local defs = TABAS_BathTransformDefs[objectType]
    return defs and defs[mode] or nil
end

local function getModeTarget(objectType, mode, modelTypeOrDef)
    local currentDef = getCurrentDef(objectType, modelTypeOrDef)
    local modeDef = getModeDef(objectType, mode)
    if not currentDef or not currentDef.modelType or not modeDef or not modeDef.targetByModel then
        return currentDef, nil, modeDef
    end

    return currentDef, modeDef.targetByModel[currentDef.modelType], modeDef
end

function TABAS_BathTransformDefs.getBathtubModeDef(mode)
    return getModeDef("Bathtub", mode)
end

function TABAS_BathTransformDefs.getShowerModeDef(mode)
    return getModeDef("Shower", mode)
end

function TABAS_BathTransformDefs.canUseBathtubTransform(mode, modelTypeOrDef)
    local _, targetModelType = getModeTarget("Bathtub", mode, modelTypeOrDef)
    return targetModelType ~= nil
end

function TABAS_BathTransformDefs.canUseShowerTransform(mode, modelTypeOrDef)
    local _, targetModelType = getModeTarget("Shower", mode, modelTypeOrDef)
    return targetModelType ~= nil
end

function TABAS_BathTransformDefs.resolveBathtubTargetModelDef(mode, modelTypeOrDef)
    local _, targetModelType = getModeTarget("Bathtub", mode, modelTypeOrDef)
    if not targetModelType then
        return nil
    end
    return TABAS_Sprites.Bathtub[targetModelType]
end

function TABAS_BathTransformDefs.resolveShowerTargetModelDef(mode, modelTypeOrDef)
    local _, targetModelType = getModeTarget("Shower", mode, modelTypeOrDef)
    if not targetModelType then
        return nil
    end
    return TABAS_Sprites.Shower[targetModelType]
end

function TABAS_BathTransformDefs.getBathtubDebugModelDefs()
    local ordered = {}
    for _, def in pairs(TABAS_Sprites.Bathtub) do
        ordered[#ordered + 1] = def
    end

    table.sort(ordered, function(a, b)
        local aOrder = a.sortOrder or 9999
        local bOrder = b.sortOrder or 9999
        if aOrder == bOrder then
            return tostring(a.modelType) < tostring(b.modelType)
        end
        return aOrder < bOrder
    end)

    return ordered
end

function TABAS_BathTransformDefs.getShowerDebugModelDefs()
    local ordered = {}
    for _, def in pairs(TABAS_Sprites.Shower) do
        ordered[#ordered + 1] = def
    end

    table.sort(ordered, function(a, b)
        local aOrder = a.sortOrder or 9999
        local bOrder = b.sortOrder or 9999
        if aOrder == bOrder then
            return tostring(a.modelType) < tostring(b.modelType)
        end
        return aOrder < bOrder
    end)

    return ordered
end

return TABAS_BathTransformDefs
