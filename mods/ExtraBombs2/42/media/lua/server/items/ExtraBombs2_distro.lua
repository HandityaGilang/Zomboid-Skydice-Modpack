require 'Items/ProceduralDistributions'

ExtraBombs2 = ExtraBombs2 or {};

ExtraBombs2.Procedural_Mag  = function(x,count)
    ProceduralDistributions = ProceduralDistributions or {};
    ProceduralDistributions.list = ProceduralDistributions.list or {};
    ProceduralDistributions.list[x] = ProceduralDistributions.list[x] or {};
    ProceduralDistributions.list[x].items = ProceduralDistributions.list[x].items or {};
    table.insert(ProceduralDistributions.list[x].items,"ExtraBombs.ExtraBombsMag");
    table.insert(ProceduralDistributions.list[x].items, count); 
end


ExtraBombs2.Procedural_Mag("BookstoreBooks",2.0);
ExtraBombs2.Procedural_Mag("BookstoreMisc",2.0);
ExtraBombs2.Procedural_Mag("CrateMagazines",1.0);
ExtraBombs2.Procedural_Mag("ElectronicStoreMagazines",0.8);
ExtraBombs2.Procedural_Mag("ClassroomMisc",0.8);
ExtraBombs2.Procedural_Mag("ClassroomShelves",0.8);
ExtraBombs2.Procedural_Mag("LibraryBooks",0.8);
ExtraBombs2.Procedural_Mag("UniversityLibraryBooks",2.0);
ExtraBombs2.Procedural_Mag("LivingRoomShelf",0.1);
ExtraBombs2.Procedural_Mag("LivingRoomShelfRedneck",0.1);
ExtraBombs2.Procedural_Mag("LivingRoomShelfClassy",0.1);
ExtraBombs2.Procedural_Mag("MagazineRackMixed",0.1);
ExtraBombs2.Procedural_Mag("PostOfficeMagazines",0.1);