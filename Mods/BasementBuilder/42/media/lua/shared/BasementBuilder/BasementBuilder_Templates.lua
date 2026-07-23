BasementBuilder = BasementBuilder or {}

BasementBuilder.Templates = BasementBuilder.Templates or {}
BasementBuilder.WallStylePresets = BasementBuilder.WallStylePresets or {}
BasementBuilder.WallMaterialPresets = BasementBuilder.WallMaterialPresets or {}
BasementBuilder.FloorMaterialPresets = BasementBuilder.FloorMaterialPresets or {}

local function buildRectCells(width, height, startX, startY)
    local cells = {}
    for offsetY = 0, height - 1 do
        for offsetX = 0, width - 1 do
            table.insert(cells, {
                x = startX + offsetX,
                y = startY - offsetY,
            })
        end
    end
    return cells
end

local function makeTemplate(def)
    def.palette = def.palette or {}
    def.palette.floor = def.palette.floor or "carpentry_02_57"
    def.palette.wallWest = def.palette.wallWest or "carpentry_02_80"
    def.palette.wallNorth = def.palette.wallNorth or "carpentry_02_81"
    def.palette.corner = def.palette.corner or "TileWalls_51"
    def.markers = def.markers or {}
    def.decor = def.decor or {}
    return def
end

local function makeWallStyle(def)
    def.palette = def.palette or {}
    def.palette.floor = def.palette.floor or "carpentry_02_57"
    def.palette.wallWest = def.palette.wallWest or "carpentry_02_80"
    def.palette.wallNorth = def.palette.wallNorth or "carpentry_02_81"
    def.palette.corner = def.palette.corner or "TileWalls_51"
    def.label = def.label or def.id or "Style"
    def.summary = def.summary or ""
    return def
end

local function makeWallMaterial(def)
    def.label = def.label or def.id or "Wall"
    def.summary = def.summary or ""
    def.wallWest = def.wallWest or "carpentry_02_80"
    def.wallNorth = def.wallNorth or "carpentry_02_81"
    def.corner = def.corner or "TileWalls_51"
    return def
end

local function makeFloorMaterial(def)
    def.label = def.label or def.id or "Floor"
    def.summary = def.summary or ""
    def.floor = def.floor or "carpentry_02_57"
    return def
end

local function registerWallMaterial(key, def)
    BasementBuilder.WallMaterialPresets[key] = makeWallMaterial(def)
    return BasementBuilder.WallMaterialPresets[key]
end

local function registerFloorMaterial(key, def)
    BasementBuilder.FloorMaterialPresets[key] = makeFloorMaterial(def)
    return BasementBuilder.FloorMaterialPresets[key]
end

BasementBuilder.Templates.STARTER_2X6 = makeTemplate({
    id = "starter_2x6",
    binmapName = "base",
    width = 2,
    height = 6,
    anchorX = 0,
    anchorY = 0,
    stairs = {
        x = 0,
        y = -2,
        north = true,
        landing = { x = 0, y = -1 },
    },
    cells = buildRectCells(2, 6, 0, 0),
    palette = {
        floor = "carpentry_02_57",
        wallWest = "carpentry_02_80",
        wallNorth = "carpentry_02_81",
        corner = "TileWalls_51",
    },
    markers = {
        surfaceFloor = "carpentry_02_57",
    },
    decor = {
        basement = {
        },
    },
})

BasementBuilder.Templates.EXPAND_1X1 = makeTemplate({
    id = "expand_1x1",
    binmapName = "room",
    width = 1,
    height = 1,
    anchorX = 0,
    anchorY = 0,
    cells = buildRectCells(1, 1, 0, 0),
    palette = {
        floor = "carpentry_02_57",
        wallWest = "carpentry_02_80",
        wallNorth = "carpentry_02_81",
        corner = "TileWalls_51",
    },
})

BasementBuilder.WallStylePresets.DEFAULT_WOOD = makeWallStyle({
    id = "default_wood",
    label = "Rough Wood",
    summary = "Log walls + Carpentry floor",
    palette = {
        floor = "carpentry_02_57",
        wallWest = "carpentry_02_80",
        wallNorth = "carpentry_02_81",
        corner = "TileWalls_51",
    },
})

BasementBuilder.WallStylePresets.WHITE_PLASTER = makeWallStyle({
    id = "white_plaster",
    label = "White Plaster",
    summary = "White walls + Dark wood floor",
    palette = {
        floor = "floors_interior_tilesandwood_01_40",
        wallWest = "walls_interior_house_02_48",
        wallNorth = "walls_interior_house_02_49",
        corner = "walls_interior_house_02_50",
    },
})

BasementBuilder.WallStylePresets.BLUE_STRIPE = makeWallStyle({
    id = "blue_stripe",
    label = "Blue Stripe",
    summary = "Striped walls + Pale tile floor",
    palette = {
        floor = "floors_interior_tilesandwood_01_0",
        wallWest = "walls_interior_house_01_0",
        wallNorth = "walls_interior_house_01_1",
        corner = "walls_interior_house_01_2",
    },
})

BasementBuilder.WallStylePresets.GREEN_DIAMOND = makeWallStyle({
    id = "green_diamond",
    label = "Green Diamond",
    summary = "Pattern walls + Check tile floor",
    palette = {
        floor = "floors_interior_tilesandwood_01_14",
        wallWest = "walls_interior_house_03_16",
        wallNorth = "walls_interior_house_03_17",
        corner = "walls_interior_house_03_18",
    },
})

BasementBuilder.WallStylePresets.PINK_FLORAL = makeWallStyle({
    id = "pink_floral",
    label = "Pink Floral",
    summary = "Floral walls + Warm wood floor",
    palette = {
        floor = "floors_interior_tilesandwood_01_48",
        wallWest = "walls_interior_house_04_52",
        wallNorth = "walls_interior_house_04_53",
        corner = "walls_interior_house_04_54",
    },
})

BasementBuilder.WallMaterialPresets.ROUGH_WOOD = makeWallMaterial({
    id = "rough_wood",
    label = "Rough Wood",
    summary = "Log wall",
    wallWest = "carpentry_02_80",
    wallNorth = "carpentry_02_81",
    corner = "TileWalls_51",
})

BasementBuilder.WallMaterialPresets.WHITE_PLASTER = makeWallMaterial({
    id = "white_plaster",
    label = "White Plaster",
    summary = "Plain painted wall",
    wallWest = "walls_interior_house_02_48",
    wallNorth = "walls_interior_house_02_49",
    corner = "walls_interior_house_02_50",
})

BasementBuilder.WallMaterialPresets.BLUE_STRIPE = makeWallMaterial({
    id = "blue_stripe",
    label = "Blue Stripe",
    summary = "Striped wallpaper",
    wallWest = "walls_interior_house_01_0",
    wallNorth = "walls_interior_house_01_1",
    corner = "walls_interior_house_01_2",
})

BasementBuilder.WallMaterialPresets.GREEN_DIAMOND = makeWallMaterial({
    id = "green_diamond",
    label = "Green Diamond",
    summary = "Pattern wallpaper",
    wallWest = "walls_interior_house_03_16",
    wallNorth = "walls_interior_house_03_17",
    corner = "walls_interior_house_03_18",
})

BasementBuilder.WallMaterialPresets.PINK_FLORAL = makeWallMaterial({
    id = "pink_floral",
    label = "Pink Floral",
    summary = "Floral wallpaper",
    wallWest = "walls_interior_house_04_52",
    wallNorth = "walls_interior_house_04_53",
    corner = "walls_interior_house_04_54",
})

BasementBuilder.FloorMaterialPresets.CARPENTRY = makeFloorMaterial({
    id = "carpentry",
    label = "Carpentry Floor",
    summary = "Workshop boards",
    floor = "carpentry_02_57",
})

BasementBuilder.FloorMaterialPresets.DARK_WOOD = makeFloorMaterial({
    id = "dark_wood",
    label = "Dark Wood",
    summary = "Clean wooden floor",
    floor = "floors_interior_tilesandwood_01_40",
})

BasementBuilder.FloorMaterialPresets.PALE_TILE = makeFloorMaterial({
    id = "pale_tile",
    label = "Pale Tile",
    summary = "Light tile floor",
    floor = "floors_interior_tilesandwood_01_0",
})

BasementBuilder.FloorMaterialPresets.CHECK_TILE = makeFloorMaterial({
    id = "check_tile",
    label = "Check Tile",
    summary = "Pattern tile floor",
    floor = "floors_interior_tilesandwood_01_14",
})

BasementBuilder.FloorMaterialPresets.WARM_WOOD = makeFloorMaterial({
    id = "warm_wood",
    label = "Warm Wood",
    summary = "Soft wooden floor",
    floor = "floors_interior_tilesandwood_01_48",
})

registerWallMaterial("PAINT_BLACK", {
    id = "paint_black",
    label = "Paint Black",
    summary = "Painted wall",
    wallWest = "walls_interior_house_03_36",
    wallNorth = "walls_interior_house_03_37",
    corner = "walls_interior_house_03_38",
})

registerWallMaterial("PAINT_BLUE", {
    id = "paint_blue",
    label = "Paint Blue",
    summary = "Painted wall",
    wallWest = "walls_interior_house_02_32",
    wallNorth = "walls_interior_house_02_33",
    corner = "walls_interior_house_02_34",
})

registerWallMaterial("PAINT_BROWN", {
    id = "paint_brown",
    label = "Paint Brown",
    summary = "Painted wall",
    wallWest = "walls_interior_house_02_20",
    wallNorth = "walls_interior_house_02_21",
    corner = "walls_interior_house_02_22",
})

registerWallMaterial("PAINT_CYAN", {
    id = "paint_cyan",
    label = "Paint Cyan",
    summary = "Painted wall",
    wallWest = "walls_interior_house_04_84",
    wallNorth = "walls_interior_house_04_85",
    corner = "walls_interior_house_04_86",
})

registerWallMaterial("PAINT_GREEN", {
    id = "paint_green",
    label = "Paint Green",
    summary = "Painted wall",
    wallWest = "walls_interior_house_04_32",
    wallNorth = "walls_interior_house_04_33",
    corner = "walls_interior_house_04_34",
})

registerWallMaterial("PAINT_GREY", {
    id = "paint_grey",
    label = "Paint Grey",
    summary = "Painted wall",
    wallWest = "walls_interior_house_04_64",
    wallNorth = "walls_interior_house_04_65",
    corner = "walls_interior_house_04_66",
})

registerWallMaterial("PAINT_LIGHT_BLUE", {
    id = "paint_light_blue",
    label = "Paint Light Blue",
    summary = "Painted wall",
    wallWest = "walls_interior_house_02_52",
    wallNorth = "walls_interior_house_02_53",
    corner = "walls_interior_house_02_54",
})

registerWallMaterial("PAINT_LIGHT_BROWN", {
    id = "paint_light_brown",
    label = "Paint Light Brown",
    summary = "Painted wall",
    wallWest = "walls_interior_house_02_36",
    wallNorth = "walls_interior_house_02_37",
    corner = "walls_interior_house_02_38",
})

registerWallMaterial("PAINT_ORANGE", {
    id = "paint_orange",
    label = "Paint Orange",
    summary = "Painted wall",
    wallWest = "walls_interior_house_02_16",
    wallNorth = "walls_interior_house_02_17",
    corner = "walls_interior_house_02_18",
})

registerWallMaterial("PAINT_PINK", {
    id = "paint_pink",
    label = "Paint Pink",
    summary = "Painted wall",
    wallWest = "walls_interior_house_04_4",
    wallNorth = "walls_interior_house_04_5",
    corner = "walls_interior_house_04_6",
})

registerWallMaterial("PAINT_PURPLE", {
    id = "paint_purple",
    label = "Paint Purple",
    summary = "Painted wall",
    wallWest = "walls_interior_house_04_48",
    wallNorth = "walls_interior_house_04_49",
    corner = "walls_interior_house_04_50",
})

registerWallMaterial("PAINT_RED", {
    id = "paint_red",
    label = "Paint Red",
    summary = "Painted wall",
    wallWest = "walls_interior_house_01_32",
    wallNorth = "walls_interior_house_01_33",
    corner = "walls_interior_house_01_34",
})

registerWallMaterial("PAINT_TURQUOISE", {
    id = "paint_turquoise",
    label = "Paint Turquoise",
    summary = "Painted wall",
    wallWest = "walls_interior_house_04_36",
    wallNorth = "walls_interior_house_04_37",
    corner = "walls_interior_house_04_38",
})

registerWallMaterial("PAINT_YELLOW", {
    id = "paint_yellow",
    label = "Paint Yellow",
    summary = "Painted wall",
    wallWest = "walls_interior_house_01_52",
    wallNorth = "walls_interior_house_01_53",
    corner = "walls_interior_house_01_54",
})

registerWallMaterial("WALLPAPER_BEIGE_STRIPE", {
    id = "wallpaper_beige_stripe",
    label = "Wallpaper Beige Stripe",
    summary = "Wallpaper wall",
    wallWest = "walls_interior_house_01_36",
    wallNorth = "walls_interior_house_01_37",
    corner = "walls_interior_house_01_38",
})

registerWallMaterial("WALLPAPER_BLACK_FLORAL", {
    id = "wallpaper_black_floral",
    label = "Wallpaper Black Floral",
    summary = "Wallpaper wall",
    wallWest = "walls_interior_house_03_52",
    wallNorth = "walls_interior_house_03_53",
    corner = "walls_interior_house_03_54",
})

registerWallMaterial("WALLPAPER_GREEN_FLORAL", {
    id = "wallpaper_green_floral",
    label = "Wallpaper Green Floral",
    summary = "Wallpaper wall",
    wallWest = "location_hospitality_sunstarmotel_01_4",
    wallNorth = "location_hospitality_sunstarmotel_01_5",
    corner = "location_hospitality_sunstarmotel_01_6",
})

registerWallMaterial("WALLPAPER_PINK_CHEVRON", {
    id = "wallpaper_pink_chevron",
    label = "Wallpaper Pink Chevron",
    summary = "Wallpaper wall",
    wallWest = "location_hospitality_sunstarmotel_01_0",
    wallNorth = "location_hospitality_sunstarmotel_01_1",
    corner = "location_hospitality_sunstarmotel_01_2",
})

registerFloorMaterial("CARPENTRY_56", {
    id = "carpentry_56",
    label = "carpentry_02_56",
    summary = "Vanilla floor",
    floor = "carpentry_02_56",
})

registerFloorMaterial("CARPENTRY_58", {
    id = "carpentry_58",
    label = "carpentry_02_58",
    summary = "Vanilla floor",
    floor = "carpentry_02_58",
})

registerFloorMaterial("STONE_01_1", { id = "stone_01_1", label = "floors_exterior_tilesandstone_01_1", summary = "Vanilla floor", floor = "floors_exterior_tilesandstone_01_1" })
registerFloorMaterial("STONE_01_2", { id = "stone_01_2", label = "floors_exterior_tilesandstone_01_2", summary = "Vanilla floor", floor = "floors_exterior_tilesandstone_01_2" })
registerFloorMaterial("STONE_01_3", { id = "stone_01_3", label = "floors_exterior_tilesandstone_01_3", summary = "Vanilla floor", floor = "floors_exterior_tilesandstone_01_3" })
registerFloorMaterial("STONE_01_4", { id = "stone_01_4", label = "floors_exterior_tilesandstone_01_4", summary = "Vanilla floor", floor = "floors_exterior_tilesandstone_01_4" })
registerFloorMaterial("STONE_01_5", { id = "stone_01_5", label = "floors_exterior_tilesandstone_01_5", summary = "Vanilla floor", floor = "floors_exterior_tilesandstone_01_5" })
registerFloorMaterial("STONE_01_6", { id = "stone_01_6", label = "floors_exterior_tilesandstone_01_6", summary = "Vanilla floor", floor = "floors_exterior_tilesandstone_01_6" })
registerFloorMaterial("STONE_01_7", { id = "stone_01_7", label = "floors_exterior_tilesandstone_01_7", summary = "Vanilla floor", floor = "floors_exterior_tilesandstone_01_7" })

registerFloorMaterial("TILEWOOD_01_1", { id = "tilewood_01_1", label = "floors_interior_tilesandwood_01_1", summary = "Vanilla floor", floor = "floors_interior_tilesandwood_01_1" })
registerFloorMaterial("TILEWOOD_01_2", { id = "tilewood_01_2", label = "floors_interior_tilesandwood_01_2", summary = "Vanilla floor", floor = "floors_interior_tilesandwood_01_2" })
registerFloorMaterial("TILEWOOD_01_3", { id = "tilewood_01_3", label = "floors_interior_tilesandwood_01_3", summary = "Vanilla floor", floor = "floors_interior_tilesandwood_01_3" })
registerFloorMaterial("TILEWOOD_01_4", { id = "tilewood_01_4", label = "floors_interior_tilesandwood_01_4", summary = "Vanilla floor", floor = "floors_interior_tilesandwood_01_4" })
registerFloorMaterial("TILEWOOD_01_5", { id = "tilewood_01_5", label = "floors_interior_tilesandwood_01_5", summary = "Vanilla floor", floor = "floors_interior_tilesandwood_01_5" })
registerFloorMaterial("TILEWOOD_01_6", { id = "tilewood_01_6", label = "floors_interior_tilesandwood_01_6", summary = "Vanilla floor", floor = "floors_interior_tilesandwood_01_6" })
registerFloorMaterial("TILEWOOD_01_8", { id = "tilewood_01_8", label = "floors_interior_tilesandwood_01_8", summary = "Vanilla floor", floor = "floors_interior_tilesandwood_01_8" })
registerFloorMaterial("TILEWOOD_01_9", { id = "tilewood_01_9", label = "floors_interior_tilesandwood_01_9", summary = "Vanilla floor", floor = "floors_interior_tilesandwood_01_9" })
registerFloorMaterial("TILEWOOD_01_10", { id = "tilewood_01_10", label = "floors_interior_tilesandwood_01_10", summary = "Vanilla floor", floor = "floors_interior_tilesandwood_01_10" })
registerFloorMaterial("TILEWOOD_01_11", { id = "tilewood_01_11", label = "floors_interior_tilesandwood_01_11", summary = "Vanilla floor", floor = "floors_interior_tilesandwood_01_11" })
registerFloorMaterial("TILEWOOD_01_12", { id = "tilewood_01_12", label = "floors_interior_tilesandwood_01_12", summary = "Vanilla floor", floor = "floors_interior_tilesandwood_01_12" })
registerFloorMaterial("TILEWOOD_01_13", { id = "tilewood_01_13", label = "floors_interior_tilesandwood_01_13", summary = "Vanilla floor", floor = "floors_interior_tilesandwood_01_13" })
registerFloorMaterial("TILEWOOD_01_20", { id = "tilewood_01_20", label = "floors_interior_tilesandwood_01_20", summary = "Vanilla floor", floor = "floors_interior_tilesandwood_01_20" })
registerFloorMaterial("TILEWOOD_01_21", { id = "tilewood_01_21", label = "floors_interior_tilesandwood_01_21", summary = "Vanilla floor", floor = "floors_interior_tilesandwood_01_21" })
registerFloorMaterial("TILEWOOD_01_22", { id = "tilewood_01_22", label = "floors_interior_tilesandwood_01_22", summary = "Vanilla floor", floor = "floors_interior_tilesandwood_01_22" })
registerFloorMaterial("TILEWOOD_01_23", { id = "tilewood_01_23", label = "floors_interior_tilesandwood_01_23", summary = "Vanilla floor", floor = "floors_interior_tilesandwood_01_23" })
registerFloorMaterial("TILEWOOD_01_28", { id = "tilewood_01_28", label = "floors_interior_tilesandwood_01_28", summary = "Vanilla floor", floor = "floors_interior_tilesandwood_01_28" })
registerFloorMaterial("TILEWOOD_01_29", { id = "tilewood_01_29", label = "floors_interior_tilesandwood_01_29", summary = "Vanilla floor", floor = "floors_interior_tilesandwood_01_29" })
registerFloorMaterial("TILEWOOD_01_30", { id = "tilewood_01_30", label = "floors_interior_tilesandwood_01_30", summary = "Vanilla floor", floor = "floors_interior_tilesandwood_01_30" })
registerFloorMaterial("TILEWOOD_01_31", { id = "tilewood_01_31", label = "floors_interior_tilesandwood_01_31", summary = "Vanilla floor", floor = "floors_interior_tilesandwood_01_31" })
registerFloorMaterial("TILEWOOD_01_41", { id = "tilewood_01_41", label = "floors_interior_tilesandwood_01_41", summary = "Vanilla floor", floor = "floors_interior_tilesandwood_01_41" })
registerFloorMaterial("TILEWOOD_01_42", { id = "tilewood_01_42", label = "floors_interior_tilesandwood_01_42", summary = "Vanilla floor", floor = "floors_interior_tilesandwood_01_42" })
registerFloorMaterial("TILEWOOD_01_43", { id = "tilewood_01_43", label = "floors_interior_tilesandwood_01_43", summary = "Vanilla floor", floor = "floors_interior_tilesandwood_01_43" })
registerFloorMaterial("TILEWOOD_01_44", { id = "tilewood_01_44", label = "floors_interior_tilesandwood_01_44", summary = "Vanilla floor", floor = "floors_interior_tilesandwood_01_44" })
registerFloorMaterial("TILEWOOD_01_45", { id = "tilewood_01_45", label = "floors_interior_tilesandwood_01_45", summary = "Vanilla floor", floor = "floors_interior_tilesandwood_01_45" })
registerFloorMaterial("TILEWOOD_01_46", { id = "tilewood_01_46", label = "floors_interior_tilesandwood_01_46", summary = "Vanilla floor", floor = "floors_interior_tilesandwood_01_46" })
registerFloorMaterial("TILEWOOD_01_47", { id = "tilewood_01_47", label = "floors_interior_tilesandwood_01_47", summary = "Vanilla floor", floor = "floors_interior_tilesandwood_01_47" })
registerFloorMaterial("TILEWOOD_01_49", { id = "tilewood_01_49", label = "floors_interior_tilesandwood_01_49", summary = "Vanilla floor", floor = "floors_interior_tilesandwood_01_49" })
registerFloorMaterial("TILEWOOD_01_50", { id = "tilewood_01_50", label = "floors_interior_tilesandwood_01_50", summary = "Vanilla floor", floor = "floors_interior_tilesandwood_01_50" })
registerFloorMaterial("TILEWOOD_01_51", { id = "tilewood_01_51", label = "floors_interior_tilesandwood_01_51", summary = "Vanilla floor", floor = "floors_interior_tilesandwood_01_51" })
registerFloorMaterial("TILEWOOD_01_52", { id = "tilewood_01_52", label = "floors_interior_tilesandwood_01_52", summary = "Vanilla floor", floor = "floors_interior_tilesandwood_01_52" })

registerFloorMaterial("PIE_01_7", { id = "pie_01_7", label = "location_restaurant_pie_01_7", summary = "Vanilla floor", floor = "location_restaurant_pie_01_7" })
registerFloorMaterial("PILEOCREPE_01_14", { id = "pileocrepe_01_14", label = "location_restaurant_pileocrepe_01_14", summary = "Vanilla floor", floor = "location_restaurant_pileocrepe_01_14" })
registerFloorMaterial("PIZZAWHIRLED_01_16", { id = "pizzawhirled_01_16", label = "location_restaurant_pizzawhirled_01_16", summary = "Vanilla floor", floor = "location_restaurant_pizzawhirled_01_16" })
registerFloorMaterial("SPIFFOS_01_38", { id = "spiffos_01_38", label = "location_restaurant_spiffos_01_38", summary = "Vanilla floor", floor = "location_restaurant_spiffos_01_38" })
registerFloorMaterial("SPIFFOS_01_39", { id = "spiffos_01_39", label = "location_restaurant_spiffos_01_39", summary = "Vanilla floor", floor = "location_restaurant_spiffos_01_39" })
registerFloorMaterial("MALL_01_20", { id = "mall_01_20", label = "location_shop_mall_01_20", summary = "Vanilla floor", floor = "location_shop_mall_01_20" })
registerFloorMaterial("MALL_01_21", { id = "mall_01_21", label = "location_shop_mall_01_21", summary = "Vanilla floor", floor = "location_shop_mall_01_21" })
registerFloorMaterial("MALL_01_22", { id = "mall_01_22", label = "location_shop_mall_01_22", summary = "Vanilla floor", floor = "location_shop_mall_01_22" })
registerFloorMaterial("MALL_01_23", { id = "mall_01_23", label = "location_shop_mall_01_23", summary = "Vanilla floor", floor = "location_shop_mall_01_23" })

BasementBuilder.WallStylePresetList = BasementBuilder.WallStylePresetList or {
    BasementBuilder.WallStylePresets.DEFAULT_WOOD,
    BasementBuilder.WallStylePresets.WHITE_PLASTER,
    BasementBuilder.WallStylePresets.BLUE_STRIPE,
    BasementBuilder.WallStylePresets.GREEN_DIAMOND,
    BasementBuilder.WallStylePresets.PINK_FLORAL,
}

BasementBuilder.WallMaterialPresetList = BasementBuilder.WallMaterialPresetList or {
    BasementBuilder.WallMaterialPresets.ROUGH_WOOD,
    BasementBuilder.WallMaterialPresets.WHITE_PLASTER,
    BasementBuilder.WallMaterialPresets.BLUE_STRIPE,
    BasementBuilder.WallMaterialPresets.GREEN_DIAMOND,
    BasementBuilder.WallMaterialPresets.PINK_FLORAL,
    BasementBuilder.WallMaterialPresets.PAINT_BLACK,
    BasementBuilder.WallMaterialPresets.PAINT_BLUE,
    BasementBuilder.WallMaterialPresets.PAINT_BROWN,
    BasementBuilder.WallMaterialPresets.PAINT_CYAN,
    BasementBuilder.WallMaterialPresets.PAINT_GREEN,
    BasementBuilder.WallMaterialPresets.PAINT_GREY,
    BasementBuilder.WallMaterialPresets.PAINT_LIGHT_BLUE,
    BasementBuilder.WallMaterialPresets.PAINT_LIGHT_BROWN,
    BasementBuilder.WallMaterialPresets.PAINT_ORANGE,
    BasementBuilder.WallMaterialPresets.PAINT_PINK,
    BasementBuilder.WallMaterialPresets.PAINT_PURPLE,
    BasementBuilder.WallMaterialPresets.PAINT_RED,
    BasementBuilder.WallMaterialPresets.PAINT_TURQUOISE,
    BasementBuilder.WallMaterialPresets.PAINT_YELLOW,
    BasementBuilder.WallMaterialPresets.WALLPAPER_BEIGE_STRIPE,
    BasementBuilder.WallMaterialPresets.WALLPAPER_BLACK_FLORAL,
    BasementBuilder.WallMaterialPresets.WALLPAPER_GREEN_FLORAL,
    BasementBuilder.WallMaterialPresets.WALLPAPER_PINK_CHEVRON,
}

BasementBuilder.FloorMaterialPresetList = BasementBuilder.FloorMaterialPresetList or {
    BasementBuilder.FloorMaterialPresets.CARPENTRY,
    BasementBuilder.FloorMaterialPresets.DARK_WOOD,
    BasementBuilder.FloorMaterialPresets.PALE_TILE,
    BasementBuilder.FloorMaterialPresets.CHECK_TILE,
    BasementBuilder.FloorMaterialPresets.WARM_WOOD,
    BasementBuilder.FloorMaterialPresets.CARPENTRY_56,
    BasementBuilder.FloorMaterialPresets.CARPENTRY_58,
    BasementBuilder.FloorMaterialPresets.STONE_01_1,
    BasementBuilder.FloorMaterialPresets.STONE_01_2,
    BasementBuilder.FloorMaterialPresets.STONE_01_3,
    BasementBuilder.FloorMaterialPresets.STONE_01_4,
    BasementBuilder.FloorMaterialPresets.STONE_01_5,
    BasementBuilder.FloorMaterialPresets.STONE_01_6,
    BasementBuilder.FloorMaterialPresets.STONE_01_7,
    BasementBuilder.FloorMaterialPresets.TILEWOOD_01_1,
    BasementBuilder.FloorMaterialPresets.TILEWOOD_01_2,
    BasementBuilder.FloorMaterialPresets.TILEWOOD_01_3,
    BasementBuilder.FloorMaterialPresets.TILEWOOD_01_4,
    BasementBuilder.FloorMaterialPresets.TILEWOOD_01_5,
    BasementBuilder.FloorMaterialPresets.TILEWOOD_01_6,
    BasementBuilder.FloorMaterialPresets.TILEWOOD_01_8,
    BasementBuilder.FloorMaterialPresets.TILEWOOD_01_9,
    BasementBuilder.FloorMaterialPresets.TILEWOOD_01_10,
    BasementBuilder.FloorMaterialPresets.TILEWOOD_01_11,
    BasementBuilder.FloorMaterialPresets.TILEWOOD_01_12,
    BasementBuilder.FloorMaterialPresets.TILEWOOD_01_13,
    BasementBuilder.FloorMaterialPresets.TILEWOOD_01_20,
    BasementBuilder.FloorMaterialPresets.TILEWOOD_01_21,
    BasementBuilder.FloorMaterialPresets.TILEWOOD_01_22,
    BasementBuilder.FloorMaterialPresets.TILEWOOD_01_23,
    BasementBuilder.FloorMaterialPresets.TILEWOOD_01_28,
    BasementBuilder.FloorMaterialPresets.TILEWOOD_01_29,
    BasementBuilder.FloorMaterialPresets.TILEWOOD_01_30,
    BasementBuilder.FloorMaterialPresets.TILEWOOD_01_31,
    BasementBuilder.FloorMaterialPresets.TILEWOOD_01_41,
    BasementBuilder.FloorMaterialPresets.TILEWOOD_01_42,
    BasementBuilder.FloorMaterialPresets.TILEWOOD_01_43,
    BasementBuilder.FloorMaterialPresets.TILEWOOD_01_44,
    BasementBuilder.FloorMaterialPresets.TILEWOOD_01_45,
    BasementBuilder.FloorMaterialPresets.TILEWOOD_01_46,
    BasementBuilder.FloorMaterialPresets.TILEWOOD_01_47,
    BasementBuilder.FloorMaterialPresets.TILEWOOD_01_49,
    BasementBuilder.FloorMaterialPresets.TILEWOOD_01_50,
    BasementBuilder.FloorMaterialPresets.TILEWOOD_01_51,
    BasementBuilder.FloorMaterialPresets.TILEWOOD_01_52,
    BasementBuilder.FloorMaterialPresets.PIE_01_7,
    BasementBuilder.FloorMaterialPresets.PILEOCREPE_01_14,
    BasementBuilder.FloorMaterialPresets.PIZZAWHIRLED_01_16,
    BasementBuilder.FloorMaterialPresets.SPIFFOS_01_38,
    BasementBuilder.FloorMaterialPresets.SPIFFOS_01_39,
    BasementBuilder.FloorMaterialPresets.MALL_01_20,
    BasementBuilder.FloorMaterialPresets.MALL_01_21,
    BasementBuilder.FloorMaterialPresets.MALL_01_22,
    BasementBuilder.FloorMaterialPresets.MALL_01_23,
}

BasementBuilder.WallStylePresetById = BasementBuilder.WallStylePresetById or {}
for _, style in ipairs(BasementBuilder.WallStylePresetList) do
    BasementBuilder.WallStylePresetById[style.id] = style
end

BasementBuilder.WallMaterialPresetById = BasementBuilder.WallMaterialPresetById or {}
for _, wallMaterial in ipairs(BasementBuilder.WallMaterialPresetList) do
    BasementBuilder.WallMaterialPresetById[wallMaterial.id] = wallMaterial
end

BasementBuilder.FloorMaterialPresetById = BasementBuilder.FloorMaterialPresetById or {}
for _, floorMaterial in ipairs(BasementBuilder.FloorMaterialPresetList) do
    BasementBuilder.FloorMaterialPresetById[floorMaterial.id] = floorMaterial
end

BasementBuilder.TemplateById = BasementBuilder.TemplateById or {}
BasementBuilder.TemplateById[BasementBuilder.Templates.STARTER_2X6.id] = BasementBuilder.Templates.STARTER_2X6
BasementBuilder.TemplateById[BasementBuilder.Templates.EXPAND_1X1.id] = BasementBuilder.Templates.EXPAND_1X1

function BasementBuilder.getTemplateById(templateId)
    return BasementBuilder.TemplateById[tostring(templateId or "")]
end

function BasementBuilder.getStarterTemplate()
    return BasementBuilder.Templates.STARTER_2X6
end

function BasementBuilder.getExpandTemplate()
    return BasementBuilder.Templates.EXPAND_1X1
end

function BasementBuilder.getWallStylePresets()
    return BasementBuilder.WallStylePresetList
end

function BasementBuilder.getWallStylePreset(styleId)
    return BasementBuilder.WallStylePresetById[tostring(styleId or "")]
end

function BasementBuilder.getWallMaterialPresets()
    return BasementBuilder.WallMaterialPresetList
end

function BasementBuilder.getWallMaterialPreset(materialId)
    return BasementBuilder.WallMaterialPresetById[tostring(materialId or "")]
end

function BasementBuilder.getFloorMaterialPresets()
    return BasementBuilder.FloorMaterialPresetList
end

function BasementBuilder.getFloorMaterialPreset(materialId)
    return BasementBuilder.FloorMaterialPresetById[tostring(materialId or "")]
end

function BasementBuilder.buildPaletteFromMaterials(wallMaterialId, floorMaterialId)
    local wallMaterial = BasementBuilder.getWallMaterialPreset(wallMaterialId)
    local floorMaterial = BasementBuilder.getFloorMaterialPreset(floorMaterialId)
    return {
        styleId = nil,
        floor = floorMaterial and floorMaterial.floor or nil,
        wallWest = wallMaterial and wallMaterial.wallWest or nil,
        wallNorth = wallMaterial and wallMaterial.wallNorth or nil,
        corner = wallMaterial and wallMaterial.corner or nil,
        wallMaterialId = wallMaterial and wallMaterial.id or nil,
        floorMaterialId = floorMaterial and floorMaterial.id or nil,
    }
end
