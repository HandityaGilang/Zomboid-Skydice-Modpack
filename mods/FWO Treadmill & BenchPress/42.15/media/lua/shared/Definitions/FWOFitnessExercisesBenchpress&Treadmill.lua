--[[
    FWO Working Bench Press & Treadmill - Exercise Definitions
    Version: 42.15.3
    
    Adds treadmill and benchpress exercises to the vanilla fitness system
    Load order safe - checks if FitnessExercises exists before modifying
]]

-- Ensure vanilla FitnessExercises is loaded first
require "Definitions/FitnessExercises"

-- Safety check: Ensure the table exists
if not FitnessExercises or not FitnessExercises.exercisesType then
    print("ERROR: FWO Treadmill & BenchPress - FitnessExercises.exercisesType not found!")
    return
end

-- Add benchpress exercise
FitnessExercises.exercisesType.benchpress = {
    type = "benchpress",
    name = getText("IGUI_BenchPress"),
    tooltip = getText("IGUI_BenchPress_Tooltip"),
    stiffness = "arms,chest",
    metabolics = Metabolics.FitnessHeavy,
    xpMod = 2.2,  -- Premium strength: highest combined XP (requires bench + barbell)
}

-- Add treadmill exercise
FitnessExercises.exercisesType.treadmill = {
    type = "treadmill",
    name = getText("IGUI_Treadmill"),
    tooltip = getText("IGUI_Treadmill_Tooltip"),
    stiffness = "legs",
    metabolics = Metabolics.Fitness,
    xpMod = 1.5,  -- Premium cardio: highest Fitness XP (requires equipment + electricity)
}
