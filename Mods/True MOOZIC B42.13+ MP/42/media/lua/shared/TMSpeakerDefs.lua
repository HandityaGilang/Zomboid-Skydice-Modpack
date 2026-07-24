-- TM_SpeakerDefs: register all speaker rotation sprites as vinyl music emitters
local function registerSpeakerDefs()
    if TCMusic and TCMusic.WorldMusicPlayer and TCMusic.WorldMusicPlayer["Tsarcraft.TCVinylplayer"] then
        local mapped = TCMusic.WorldMusicPlayer["Tsarcraft.TCVinylplayer"]
        -- Wood Speaker Cabinet  (S / N / E / W)
        TCMusic.WorldMusicPlayer["Base.recreational_01_76"] = mapped
        TCMusic.WorldMusicPlayer["Base.recreational_01_77"] = mapped
        TCMusic.WorldMusicPlayer["Base.recreational_01_78"] = mapped
        TCMusic.WorldMusicPlayer["Base.recreational_01_79"] = mapped
        TCMusic.WorldMusicPlayer["Base.Mov_WoodSpeakerCabinet"] = mapped
        -- Black Speaker Cabinet (S / N / W / E)
        TCMusic.WorldMusicPlayer["Base.recreational_01_80"] = mapped
        TCMusic.WorldMusicPlayer["Base.recreational_01_81"] = mapped
        TCMusic.WorldMusicPlayer["Base.recreational_01_82"] = mapped
        TCMusic.WorldMusicPlayer["Base.recreational_01_83"] = mapped
        TCMusic.WorldMusicPlayer["Base.Mov_BlackSpeakerCabinet"] = mapped
        -- Small Speaker (inventory item placed in world)
        TCMusic.WorldMusicPlayer["Base.Speaker"] = mapped
    else
        if not registerSpeakerDefs.retryAdded then
            Events.OnGameStart.Add(registerSpeakerDefs)
            registerSpeakerDefs.retryAdded = true
        end
    end
end

registerSpeakerDefs()


