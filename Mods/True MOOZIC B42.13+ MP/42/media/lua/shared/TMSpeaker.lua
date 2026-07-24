-- TM_Speaker: register base Wooden Speaker Cabinet as a world music emitter
local function registerSpeaker()
    if TCMusic and TCMusic.WorldMusicPlayer then
        local vinylKey = "Tsarcraft.TCVinylplayer"
        local vinylMap = TCMusic.WorldMusicPlayer[vinylKey]
        if vinylMap then
            TCMusic.WorldMusicPlayer["Base.recreational_01_76"] = vinylMap
        else
            if GlobalMusic and GlobalMusic["tsarcraft_music_01_36"] then
                TCMusic.WorldMusicPlayer["Base.recreationl_01_76"] = GlobalMusic["tsarcraft_music_01_36"]
            end
        end
    else
        if not registerSpeaker.retryAdded then
            Events.OnGameStart.Add(registerSpeaker)
            registerSpeaker.retryAdded = true
        end
    end
end

Events.OnGameBoot.Add(registerSpeaker)

return nil
