AnimalPartsDefinitions = AnimalPartsDefinitions or {};
AnimalPartsDefinitions.animals = AnimalPartsDefinitions.animals or {};

--- ANNOTATE ALL ID INFO HERE.
--- CyberDoggyMod
--- CyberDog
--- 
--- 
--- 
--- cyberdogpup
--- cyberdog
--- cyberdoggirl

local CyberDogparts = {};
table.insert(CyberDogparts, {item = "Base.Steak", minNb = 10, maxNb = 18})
table.insert(CyberDogparts, {item = "Base.Beef", minNb = 10, maxNb = 18})
table.insert(CyberDogparts, {item = "Base.AnimalSinew", minNb = 3, maxNb = 7})

--- all id's here must be all lowercase at all times. 
local cyberdogpup = AnimalPartsDefinitions.animals["cyberdogpup"] or {};
cyberdogpup.parts = cyberdogpup.parts or CyberDogparts;
cyberdogpup.bones = cyberdogpup.bones or {};
table.insert(cyberdogpup.bones, {item = "Base.AnimalBone", minNb = 7, maxNb = 10})
table.insert(cyberdogpup.bones, {item = "Base.LargeAnimalBone", minNb = 3, maxNb = 5})
cyberdogpup.leather = "Base.CowLeather_Holstein_Full";
cyberdogpup.head = "Base.Cow_Head_Holstein";
cyberdogpup.skull = "Base.Cow_Skull";
cyberdogpup.xpPerItem = 25;
AnimalPartsDefinitions.animals["cyberdogpup"] = cyberdogpup;










local cyberdog = AnimalPartsDefinitions.animals["cyberdog"] or {};
cyberdog.parts = cyberdog.parts or CyberDogparts;
cyberdog.bones = cyberdog.bones or {};
table.insert(cyberdog.bones, {item = "Base.AnimalBone", minNb = 7, maxNb = 10})
table.insert(cyberdog.bones, {item = "Base.LargeAnimalBone", minNb = 3, maxNb = 5})
cyberdog.leather = "Base.CowLeather_Holstein_Full";
cyberdog.head = "Base.Cow_Head_Holstein";
cyberdog.skull = "Base.Cow_Skull";
cyberdog.xpPerItem = 25;
AnimalPartsDefinitions.animals["cyberdog"] = cyberdog;







local cyberdoggirl = AnimalPartsDefinitions.animals["cyberdoggirl"] or {};
cyberdoggirl.parts = cyberdoggirl.parts or CyberDogparts;
cyberdoggirl.bones = cyberdoggirl.bones or {};
table.insert(cyberdoggirl.bones, {item = "Base.AnimalBone", minNb = 7, maxNb = 10})
table.insert(cyberdoggirl.bones, {item = "Base.LargeAnimalBone", minNb = 3, maxNb = 5})
cyberdoggirl.leather = "Base.CowLeather_Holstein_Full";
cyberdoggirl.head = "Base.Cow_Head_Holstein";
cyberdoggirl.skull = "Base.Cow_Skull";
cyberdoggirl.xpPerItem = 25;
AnimalPartsDefinitions.animals["cyberdoggirl"] = cyberdoggirl;