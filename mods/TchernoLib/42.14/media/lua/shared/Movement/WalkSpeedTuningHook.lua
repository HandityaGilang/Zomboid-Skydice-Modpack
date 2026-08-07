
WalkSpeedTuning = WalkSpeedTuning or {}
WalkSpeedTuning.activated = false

function WalkSpeedTuning.activate(doActivate)
    if doActivate ~= WalkSpeedTuning.activated then
        WalkSpeedTuning.activated = doActivate
        if doActivate then
            Events.OnPlayerMove.Add(WalkSpeedTuning.update)
        else
            Events.OnPlayerMove.Remove(WalkSpeedTuning.update)
        end
    end
end