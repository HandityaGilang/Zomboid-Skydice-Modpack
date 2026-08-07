-- Shared definitions for TCCassetteDisassemble (used by server and client)
TCCassetteDisassembleDefinitions = TCCassetteDisassembleDefinitions or {}

TCCassetteDisassembleDefinitions.Failure = {
    BaseChance = 0.60,         -- Base failure chance (60%)
    SkillReduction = 0.10,     -- Per-skill-level reduction (10% per level)
    MinChance = 0.0,
}

TCCassetteDisassembleDefinitions.ExpGain = {
    Electrical = 15,
    Cassette = 4,
    -- fallback or other categories can be added here
}

TCCassetteDisassembleDefinitions.ComponentsReceived = {
    -- Components that can be received on success. Each entry: { item = <fullType>, chance = <0-1>, count = <n> }
    { item = "Base.ElectronicsScrap", chance = 1.0, count = 1 },
    { item = "Base.ElectricWire", chance = 0.2, count = 1 },
}

return TCCassetteDisassembleDefinitions
