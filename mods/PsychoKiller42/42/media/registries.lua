-----------------------
--- PK42 REGISTRIES ---
-----------------------
PK42 = PK42 or {}
PK42.CharacterTrait = PK42.CharacterTrait or {}

-- ====================
-- CHARACTER TRAITS
-- ====================
if not PK42.CharacterTrait.PSYCHOPATH then
    PK42.CharacterTrait.PSYCHOPATH = CharacterTrait.register("pk42:psychopath")
end

if not PK42.CharacterTrait.CANNIBALIST then
    PK42.CharacterTrait.CANNIBALIST = CharacterTrait.register("pk42:cannibalist")
end

-- ====================
-- ITEM TAGS
-- ====================
PK42.ItemTag = {}
-- SMALL
PK42.ItemTag.HUMAN_LEATHER_FULL_SMALL         = ItemTag.register("pk42:humanleatherfullsmall")
PK42.ItemTag.HUMAN_LEATHER_CRUDE_SMALL        = ItemTag.register("pk42:humanleathercrudesmall")
PK42.ItemTag.HUMAN_LEATHER_CRUDE_WET_SMALL    = ItemTag.register("pk42:humanleathercrudewetsmall")
PK42.ItemTag.HUMAN_LEATHER_CRUDE_TANNED_SMALL = ItemTag.register("pk42:humanleathercrudetannedsmall")

-- MEDIUM
PK42.ItemTag.HUMAN_LEATHER_FULL_MEDIUM        = ItemTag.register("pk42:humanleatherfullmedium")
PK42.ItemTag.HUMAN_LEATHER_CRUDE_MEDIUM       = ItemTag.register("pk42:humanleathercrudemedium")
PK42.ItemTag.HUMAN_LEATHER_CRUDE_WET_MEDIUM   = ItemTag.register("pk42:humanleathercrudewetmedium")
PK42.ItemTag.HUMAN_LEATHER_CRUDE_TANNED_MEDIUM = ItemTag.register("pk42:humanleathercrudetannedmedium")

-- LARGE
PK42.ItemTag.HUMAN_LEATHER_FULL_LARGE         = ItemTag.register("pk42:humanleatherfulllarge")
PK42.ItemTag.HUMAN_LEATHER_CRUDE_LARGE        = ItemTag.register("pk42:humanleathercrudelarge")
PK42.ItemTag.HUMAN_LEATHER_CRUDE_WET_LARGE    = ItemTag.register("pk42:humanleathercrudewetlarge")
PK42.ItemTag.HUMAN_LEATHER_CRUDE_TANNED_LARGE = ItemTag.register("pk42:humanleathercrudetannedlarge")

-- BRAIN
PK42.ItemTag.HUMAN_BRAIN                      = ItemTag.register("pk42:humanbrain")

-- BONES
PK42.ItemTag.HUMAN_LARGE_BONE                 = ItemTag.register("pk42:humanlargebone")
PK42.ItemTag.HUMAN_REGULAR_BONE               = ItemTag.register("pk42:humanregularbone")
PK42.ItemTag.HUMAN_SMALL_BONE                 = ItemTag.register("pk42:humansmallbone")

-- ====================
-- FLIERS
-- ====================
PK42.Flier = {}

PK42.Flier.PSYCHOFLIER1 = Flier.register("pk42:PsychoFlierPage1") -- takes too long to spawn

-- ====================
-- MOODLE TYPES
-- Na realidade nem é usado, porque a TIS coloca esses registries, mas não expõe nada útil em lua para realmente
-- manipular os MoodleType. Deixei aqui pra referência futura, caso a TIS mude algo mais para frente.
-- Os moodles são desenhados pelo render via lua (PK42Moodles.lua)
-- ====================
PK42.MoodleType = {}

PK42.MoodleType.FRENZY_LVL1 = MoodleType.register("pk42:adrenalinefrenzy_lvl1")
PK42.MoodleType.FRENZY_LVL2 = MoodleType.register("pk42:adrenalinefrenzy_lvl2")
PK42.MoodleType.FRENZY_LVL3 = MoodleType.register("pk42:adrenalinefrenzy_lvl3")
PK42.MoodleType.FRENZY_LVL4 = MoodleType.register("pk42:adrenalinefrenzy_lvl4")