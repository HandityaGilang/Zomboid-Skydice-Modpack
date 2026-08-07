
local lcl = {}
lcl.player_base = __classmetatables[IsoPlayer.class].__index
lcl.player_getCurrentBuilding         = lcl.player_base.getCurrentBuilding

lcl.room_base = __classmetatables[IsoRoom.class].__index
lcl.room_getSquares  = lcl.room_base.getSquares
lcl.room_getBuilding = lcl.room_base.getBuilding
lcl.room_getRoomDef  = lcl.room_base.getRoomDef

lcl.roomDef_base        = __classmetatables[RoomDef.class].__index
lcl.roomDef_getID       = lcl.roomDef_base.getID
lcl.roomDef_isExplored  = lcl.roomDef_base.isExplored

lcl.building_base    = __classmetatables[IsoBuilding.class].__index
lcl.building_getDef  = lcl.building_base.getDef

lcl.buildingDef_base              = __classmetatables[BuildingDef.class].__index
lcl.buildingDef_getID             = lcl.buildingDef_base.getID
lcl.buildingDef_isHasBeenVisited  = lcl.buildingDef_base.isHasBeenVisited


lcl.ArrayList_base   = __classmetatables[ArrayList.class].__index
lcl.ArrayList_size   = lcl.ArrayList_base.size
lcl.ArrayList_get    = lcl.ArrayList_base.get
lcl.ArrayList_add    = lcl.ArrayList_base.add

lcl.PZArrayList_base        = __classmetatables[PZArrayList.class].__index
lcl.PZArrayList_size        = lcl.PZArrayList_base.size
lcl.PZArrayList_get         = lcl.PZArrayList_base.get
lcl.PZArrayList_add         = lcl.PZArrayList_base.add

lcl.getCell = getCell
lcl.cell_base          = __classmetatables[IsoCell.class].__index
lcl.cell_getRoomList   = lcl.cell_base.getRoomList
lcl.cell_roomSpotted   = lcl.cell_base.roomSpotted
lcl.cell_getGridSquare = lcl.cell_base.getGridSquare

lcl.igs_base = __classmetatables[IsoGridSquare.class].__index
lcl.igs_getX              = lcl.igs_base.getX
lcl.igs_getY              = lcl.igs_base.getY
lcl.igs_getZ              = lcl.igs_base.getZ
lcl.igs_getFloor          = lcl.igs_base.getFloor
lcl.igs_addFloor          = lcl.igs_base.addFloor
lcl.igs_disableErosion    = lcl.igs_base.disableErosion
lcl.igs_RemoveTileObject  = lcl.igs_base.RemoveTileObject
lcl.igs_isOutside         = lcl.igs_base.isOutside
lcl.igs_getObjects        = lcl.igs_base.getObjects
lcl.igs_getSpecialObjects = lcl.igs_base.getSpecialObjects

lcl.io_base = __classmetatables[IsoObject.class].__index
lcl.io_getProperties     = lcl.io_base.getProperties
lcl.io_getObjectName     = lcl.io_base.getObjectName
lcl.io_getTextureName    = lcl.io_base.getTextureName
lcl.io_getType           = lcl.io_base.getType
lcl.io_transmitCompleteItemToServer     = lcl.io_base.transmitCompleteItemToServer


lcl.pc_base = __classmetatables[PropertyContainer.class].__index
lcl.pc_Is     = lcl.pc_base.Is
lcl.pc_Val    = lcl.pc_base.Val

function getLocalJavaFuncPointers()
    return lcl
end