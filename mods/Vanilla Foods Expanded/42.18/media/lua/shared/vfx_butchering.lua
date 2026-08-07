AnimalPartsDefinitions = AnimalPartsDefinitions or {};
AnimalPartsDefinitions.animals = AnimalPartsDefinitions.animals or {};

--- /* <<<<<  Cow  >>>>> */ ---

    local cowangus = AnimalPartsDefinitions.animals["cowangus"] or {};
    cowangus.parts = cowangus.parts or {};
    table.insert(cowangus.parts, {item = "VFX.BeefBrisket", nb = 1})
    table.insert(cowangus.parts, {item = "VFX.BeefShortRibs", minNb = 2, maxNb = 4})
    table.insert(cowangus.parts, {item = "VFX.BeefShank", minNb = 2, maxNb = 4})
    AnimalPartsDefinitions.animals["cowangus"] = cowangus;

--- /* <<<<<  Calves  >>>>> */ ---

    local cowcalfangus = AnimalPartsDefinitions.animals["cowcalfangus"] or {};
    cowcalfangus.parts = cowcalfangus.parts or {};
    table.insert(cowcalfangus.parts, {item = "VFX.VealCutlet", minNb = 3, maxNb = 6})
    table.insert(cowcalfangus.parts, {item = "VFX.Rennet", nb = 1})
    AnimalPartsDefinitions.animals["cowcalfangus"] = cowcalfangus;

--- /* <<<<<  Pig  >>>>> */ ---

    local sowlandrace = AnimalPartsDefinitions.animals["sowlandrace"] or {};
    sowlandrace.parts = sowlandrace.parts or {};
    table.insert(sowlandrace.parts, {item = "VFX.PorkBelly", nb = 1})
    table.insert(sowlandrace.parts, {item = "VFX.PorkRibs", minNb = 2, maxNb = 3})
    AnimalPartsDefinitions.animals["sowlandrace"] = sowlandrace;

--- /* <<<<<  Sheep  >>>>> */ ---

    local lambsuffolk = AnimalPartsDefinitions.animals["lambsuffolk"] or {};
    lambsuffolk.parts = lambsuffolk.parts or {};
    table.insert(lambsuffolk.parts, {item = "VFX.LambLeg", nb = 2})
    table.insert(lambsuffolk.parts, {item = "VFX.Rennet", nb = 1})
    AnimalPartsDefinitions.animals["lambsuffolk"] = lambsuffolk;
