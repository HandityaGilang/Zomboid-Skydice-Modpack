-- PK42MainCreationMethods.lua (Shared)
-- Inicialização de traits e estado do personagem Psychopath.

PK42CharacterDetails = PK42CharacterDetails or {}

PK42CharacterDetails.DoNewCharacterInitializations = function(player)
    if not player then
        print("[PK42|Init] player nil: aborting...")
        return
    end

    print("[PK42|Init] iniciando para player=" .. tostring(player:getUsername()))

    if isClient() then
        print("[PK42|Init] isClient=true: aborting...")
        return
    end

    local psychopathTrait = PK42 and PK42.CharacterTrait and PK42.CharacterTrait.PSYCHOPATH
    if not psychopathTrait then
        print("[PK42|Init] PSYCHOPATH nil: aborting...")
        return
    end

    if not player:hasTrait(psychopathTrait) then
        print("[PK42|Init] player doesn't have PSYCHOPATH trait: aborting...")
        return
    end

    local modData = player:getModData()
    if modData.PK42Initialized then
        print("[PK42|Init] Already initialized: aborting...")
        return
    end

    local desensitized = CharacterTrait.DESENSITIZED
    if not desensitized then
        print("[PK42|Init] DESENSITIZED nil: skipping trait addition...")
    elseif not player:hasTrait(desensitized) then
        player:getCharacterTraits():add(desensitized)
        print("[PK42|Init] DESENSITIZED added to " .. tostring(player:getUsername()))
    else
        print("[PK42|Init] DESENSITIZED already present")
    end

    modData.PK42Initialized = true
    print("[PK42|Init] initialization completed for " .. tostring(player:getUsername()))
end

Events.OnNewGame.Add(PK42CharacterDetails.DoNewCharacterInitializations)