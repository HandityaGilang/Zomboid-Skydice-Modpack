local DEBUG = false
local function dlog(msg)
    if DEBUG then
        print(msg)
    end
end

TrueMusicOnInitGlobalModData = function(_module, _packet)
    if not ModData.exists("trueMusicData") then
        local t = ModData.create("trueMusicData")
        t["now_play"] = {};
    end
end

TrueMusicOnReceiveGlobalModData = function(_module, _packet)
    if _module ~= "trueMusicData" then return; end;
    if (not _packet) then
        dlog("aborted OnReceiveGlobalModData in trueClient " .. (_packet or "missing _packet."));
    else
        ModData.add(_module, _packet);
    end;
end

Events.OnInitGlobalModData.Add(TrueMusicOnInitGlobalModData);
Events.OnReceiveGlobalModData.Add(TrueMusicOnReceiveGlobalModData);
