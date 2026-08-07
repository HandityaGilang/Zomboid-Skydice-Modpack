---Returns a numerically indexed table that is the combination of the two input tables.
---@param a table
---@param b table
---@return table
local function MergeTables(a, b)
    if not a then return b elseif not b then return a end
    local result = {}
    for _,v in pairs(a) do
        table.insert(result, v)
    end
    for _,v in pairs(b) do
        table.insert(result, v)
    end
    return result
end

local FNAFS = {}

FNAFS.allFNAF = {'PompsItems_FNAF.PIFoxyPlushie', 'PompsItems_FNAF.PIBonniePlushie', 'PompsItems_FNAF.PIChicaCupcakePlushie', 'PompsItems_FNAF.PIChicaPlushie', 'PompsItems_FNAF.PIGoldenFreddyPlushie', 'PompsItems_FNAF.PIFreddyPlushie', 'PompsItems_FNAF.PIPopgoesPlushie',
'PompsItems_FNAF.PIBlakeBadgerPlushie', 'PompsItems_FNAF.PICandyCatPlushie', 'PompsItems_FNAF.PIMontyPlush', 'PompsItems_FNAF.PIGlamFreddyPlushie', 'PompsItems_FNAF.PIGlamChicaPlushie', 'PompsItems_FNAF.PIRoxyPlush', 'PompsItems_FNAF.PIVannyPlush', 'PompsItems_FNAF.PIToyBonniePlush', 'PompsItems_FNAF.PIToyFreddyPlush', 'PompsItems_FNAF.PIToyChicaPlush',
'PompsItems_FNAF.PIFuntimeFoxyPlush', 'PompsItems_FNAF.PIMangleFigure', 'PompsItems_FNAF.PIBalloonBoyPlush', 'PompsItems_FNAF.PISpringBonniePlushie', 'PompsItems_FNAF.PIFredbearPlushie', 'PompsItems_FNAF.PISpringtrapPlushie', 'PompsItems_FNAF.PICircusBabyPlushie', 'PompsItems_FNAF.PIBalloraPlushie',
'PompsItems_FNAF.PIMarionettePlushie', 'PompsItems_FNAF.PILeftyPlushie', 'PompsItems_FNAF.PIHelpyPlushie', 'PompsItems_FNAF.PIMusicMan', 'PompsItems_FNAF.PIIgnitedFreddyPlushie', 'PompsItems_FNAF.PIIgnitedChicaPlushie', 'PompsItems_FNAF.PIIgnitedBonniePlushie', 'PompsItems_FNAF.PIIgnitedFoxyPlushie',
'PompsItems_FNAF.PILolbitPlushie', 'PompsItems_FNAF.PISunPlushie', 'PompsItems_FNAF.PIMoonPlushie', 'PompsItems_FNAF.PIRockstarChicaPlush', 'PompsItems_FNAF.PIRockstarFreddyPlush', 'PompsItems_FNAF.PIRockstarBonniePlush', 'PompsItems_FNAF.PIRockstarFoxyPlush', 'PompsItems_FNAF.PIHappyFrogPlush', 'PompsItems_FNAF.PIGlamBonniePlush', 'PompsItems_FNAF.PIOrvilleElephantPlush',
'PompsItems_FNAF.PIMrHippoPlush', 'PompsItems_FNAF.PIPigpatchPlush', 'PompsItems_FNAF.PINeddBearPlush', 'PompsItems_FNAF.PICindyCatPlush', 'PompsItems_FNAF.PIElChipPlush', 'PompsItems_FNAF.PIFuntimeChicaPlush', 'PompsItems_FNAF.PIShadowBonniePlush', 'PompsItems_FNAF.PIShadowFreddyPlush', 'PompsItems_FNAF.PITwistedWolf', 'PompsItems_FNAF.PIFreddlePlush',
'PompsItems_FNAF.PIGlitchtrapPlush', 'PompsItems_FNAF.PIGoldenCupcakePlush', 'PompsItems_FNAF.PIRuinMontyPlush', 'PompsItems_FNAF.PIRuinRoxyPlush', 'PompsItems_FNAF.PIRuinChicaPlush', 'PompsItems_FNAF.PIRuinFreddyPlush', 'PompsItems_FNAF.PIMXESModel', 'PompsItems_FNAF.PIPlushtrapPlush'}

function FNAFS.getAllFNAF()
    return MergeTables(MergeTables(MergeTables(FNAFS.allFNAF)))
end

return FNAFS